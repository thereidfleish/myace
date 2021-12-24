#!/usr/bin/env python3
"""
Utility functions to convert a .mp4 file into HlS, upload to AWS, and remove
local .mp4 and HLS files, and more.

See this guide for bash implementation:
https://ryanparman.com/posts/2018/serving-bandwidth-friendly-video-with-hls/
"""

import boto3
import datetime
import json
import os
import time

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from botocore.signers import CloudFrontSigner

def get_hls_url(bucket_name: str, bucket_region: str, fmp4_filename: str) -> str:
    """Get the HLS index.m3u8 object URL for a specific upload.

       Requires the object exists and is public.

    :param bucket_name: The name of the S3 bucket
    :param bucket_region: The region of the S3 bucket
    :param upload_uuid: The upload UUID
    """
    return f"https://{bucket_name}.s3.{bucket_region}.amazonaws.com/uploads/{upload_uuid}/hls/index.m3u8"

def rsa_signer(message):
    with open('./private_key.pem', 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
    return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())

def create_m3u8_invalidation(cloudfront, distribution_id: str, m3u8_object_key: str) -> None:
    """Create CloudFront cache invalidation request 
    :param cloudfront: The Cloudfront boto3 client
    :param distribution_id: The Cloudfront distribution ID
    :param m3u8_object_key: The Cloudfront client
    :return: The invalidation request ID
    """
    response = cloudfront.create_invalidation(
        DistributionId=distribution_id,
        InvalidationBatch={
            'Paths': {
                'Quantity': 1,
                'Items': [
                    '/' + m3u8_object_key
                ]
            },
            'CallerReference': str(time.time()).replace(".", "")
        }
    )
    invalidation_id = response['Invalidation']['Id']
    return invalidation_id

def is_invalidation_request_completed(cloudfront, distribution_id: str, invalidation_id: str) -> bool:
    """Check if an invalidation request has been completed
    :param cloudfront: The Cloudfront boto3 client
    :param distribution_id: The Cloudfront distribution ID
    :param invalidation_id: The invalidation request ID
    """
    response = cloudfront.get_invalidation(
        DistributionId = distribution_id,
        Id = invalidation_id
    )
    return response['Invalidation']['Status'] == 'Completed'

def sign_sub_files(s3, bucket_name: str, m3u8_object_key: str, cloudfront_domain: str) -> None:
    """Modify the contents of the m3u8 file to append signed URL params to each *.m3u8 or *.ts file name.

    :param s3: The boto3 S3 client
    :param bucket_name: The name of the S3 bucket
    :param m3u8_object_key: The object key of the HLS manifest file. Typically resembles 'index.m3u8'.
    :param cloudfront_domain: The Cloudfront distribution domain name with S3 origin
    """
    print(f"Downloading {m3u8_object_key}")
    temp_filename = m3u8_object_key.replace('/', '-') + '.tmp'
    # Download m3u8
    try:
        s3.download_file(bucket_name, m3u8_object_key, temp_filename)
    except Exception as e:
        print(f'{bucket_name=}')
        print(f'{m3u8_object_key=}')
        print(f'{temp_filename=}')
        print(e)
        exit()

    # Modify file TODO multithread
    with open(temp_filename, 'r+') as f:
        lines = f.readlines() # Manifest files are small. It's ok to load it all into memory.
        modified_lines = []
        for line in lines:
            if '.m3u8' in line or '.ts' in line:
                # Just the filename. Ex. index-720p.m3u8
                filename = line.split('?')[0].rstrip()
                # Full key of filename. Ex. uploads/exampleuid/hls/index-720p.m3u8
                sub_object_key = m3u8_object_key.replace(os.path.basename(m3u8_object_key), filename)
                # Replace line
                sub_query_params = get_presigned_url(s3, bucket_name, sub_object_key, cloudfront_domain).split('?')[1]
                line = filename + '?' + sub_query_params + '\n'
            modified_lines.append(line)
        f.seek(0)
        f.writelines(modified_lines)
        f.truncate()
    # Reupload file
    response = s3.upload_file(temp_filename, bucket_name, m3u8_object_key)
    # Invalidate cloudfront cache
    distribution_id = 'ERPD0DBPXWVO3'
    invalidation_id = create_m3u8_invalidation(CLOUDFRONT, distribution_id, m3u8_object_key)
    while not is_invalidation_request_completed(CLOUDFRONT, distribution_id, invalidation_id):
        time.sleep(0.1)
    # TODO Remove file

def get_presigned_url(s3, bucket_name: str, object_key: str, cloudfront_domain: str, expiration: int = 3600, recursive = True) -> str:
    """Generate a presigned Cloudfront URL for any S3 object

       For a general idea of why this function works recursively with HLS streams, see:
       https://aws.amazon.com/blogs/networking-and-content-delivery/secure-and-cost-effective-video-streaming-using-cloudfront-signed-urls/

    :param s3: The boto3 S3 client
    :param bucket_name: The name of the S3 bucket
    :param object_key: The S3 object to sign
    :param cloudfront_domain: The Cloudfront distribution domain name with S3 origin
    :param expiration: Time in seconds for the presigned URL to remain valid
    :param recursive: Check if the object is a manifest file, and if so, presign its reference URLs
    :return: Presigned URL pointing to the object
    """
    print(f"Generating presigned URL for {object_key}")
    public_key_id = "KKCTRVE3DKWU7" # TODO remove me
    url = f"{cloudfront_domain}/{object_key}"
    cloudfront_signer = CloudFrontSigner(public_key_id, rsa_signer)
    # expire_date = datetime.datetime.now() + datetime.timedelta(minutes=3)
    expire_date = datetime.datetime.utcnow() + datetime.timedelta(hours=3)
    print(f"{expire_date=}")
    # Create a signed url that will be valid until the specific expiry date
    # provided using a canned policy.
    signed_url = cloudfront_signer.generate_presigned_url(
        url, date_less_than=expire_date)
    if recursive and '.m3u8' in object_key:
        sign_sub_files(s3, bucket_name, object_key, cloudfront_domain)
    return signed_url

def create_presigned_url_post(s3, bucket_name: str, upload_uuid: str, filename: str, expiration: int = 3600) -> dict:
    """Generate a presigned URL that allows the client to upload a file using a POST request.

    :param s3: The boto3 S3 client
    :param bucket_name: The name of the S3 bucket
    :param upload_uuid: The upload UUID
    :param filename: The original media filename
    :param expiration: Time in seconds for the presigned URL to remain valid
    :return: dictionary containing url and pertinent information for POST request
    """
    key = f"uploads/{upload_uuid}/{filename}"
    response = s3.generate_presigned_post(bucket_name, key, ExpiresIn=expiration)
    return response

def create_mediaconvert_job(mediaconvert, bucket_name: str, upload_uuid: str, filename: str) -> str:
    """Create an AWS MediaConvert job to convert a video file stored in S3 into an HLS playlist.

    :param mediaconvert: The boto3 mediaconvert client
    :param bucket_name: The name of the S3 bucket
    :param upload_uuid: The upload UUID
    :param filename: The original media filename
    :return: The mediaconvert job ID
    """
    # Load json job template
    with open("mediaconvert-job-template.json", "r") as f:
        job_object = json.load(f)
    # Complete template
    job_object['Settings']['Inputs'][0]['FileInput'] = f's3://tennis-trainer/uploads/{upload_uuid}/{filename}'
    job_object['Settings']['OutputGroups'][0]['OutputGroupSettings']['HlsGroupSettings']['Destination'] = f's3://tennis-trainer/uploads/{upload_uuid}/hls/index'
    # Unpack the job_object and create mediaconvert job
    response = mediaconvert.create_job(**job_object)
    id = response['Job']['Id']
    return id

def check_mediaconvert_status(mediaconvert, job_id: str) -> str:
    """Check on an AWS MediaConvert job.

    :param mediaconvert: The boto3 mediaconvert client
    :param job_id: The mediaconvert job ID
    :return: 'SUBMITTED' | 'PROGRESSING' | 'COMPLETE' | 'CANCELED' | 'ERROR'
    """
    response = mediaconvert.get_job(Id=job_id)
    status = response['Job']['Status']
    return status

def main() -> None:
    from botocore.client import Config
    from dotenv import load_dotenv
    import time
    # load environment variables
    load_dotenv()
    # constants
    ACCESS_KEY_ID = str(os.environ.get("ACCESS_KEY_ID")).strip()
    SECRET_ACCESS_KEY = str(os.environ.get("SECRET_ACCESS_KEY")).strip()
    REGION_NAME = 'us-east-2'
    BUCKET_NAME = 'tennis-trainer'
    s3 = boto3.client('s3', region_name=REGION_NAME, endpoint_url=f'https://s3.{REGION_NAME}.amazonaws.com',
                  aws_access_key_id=ACCESS_KEY_ID, aws_secret_access_key=SECRET_ACCESS_KEY,
                      config=Config(signature_version='s3v4'))
    mediaconvert = boto3.client('mediaconvert', endpoint_url='https://mqm13wgra.mediaconvert.us-east-2.amazonaws.com',
                  aws_access_key_id=ACCESS_KEY_ID, aws_secret_access_key=SECRET_ACCESS_KEY)
    global CLOUDFRONT
    CLOUDFRONT = boto3.client('cloudfront', aws_access_key_id=ACCESS_KEY_ID, aws_secret_access_key=SECRET_ACCESS_KEY)
    # Reset the playlist files
    # create_mediaconvert_job(mediaconvert, BUCKET_NAME, 'exampleuploaduid', 'fullcourtstock.mp4')
    print("Generating presigned URLs...")
    cloudfront_domain = "https://d11b188mr2hahn.cloudfront.net"
    object_key = f"uploads/exampleuploaduid/hls/index.m3u8"
    get_presigned_url(s3, BUCKET_NAME, object_key, cloudfront_domain)
    url = get_presigned_url(s3, BUCKET_NAME, object_key, cloudfront_domain, recursive=False)
    print(url)

if __name__ == '__main__':
    main()
