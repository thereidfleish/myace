#!/usr/bin/env python3
"""
Utility functions to convert a .mp4 file into HlS, upload to AWS, and remove
local .mp4 and HLS files, and more.

See this guide for bash implementation:
https://ryanparman.com/posts/2018/serving-bandwidth-friendly-video-with-hls/
"""

import boto3
import json
import os

def get_hls_url(bucket_name: str, bucket_region: str, fmp4_filename: str) -> str:
    """ Get the HLS index.m3u8 object URL for a specific upload 
        Requires the object exists and is public

    :param bucket_name: The name of the S3 bucket
    :param bucket_region: The region of the S3 bucket
    :param upload_uuid: The upload UUID
    """
    return f"https://{bucket_name}.s3.{bucket_region}.amazonaws.com/uploads/{upload_uuid}/hls/index.m3u8"

def create_presigned_url_post(s3, bucket_name: str, upload_uuid: str, filename: str, expiration: int = 3600):
    """ Generate a presigned URL that allows the client to upload a file using a POST request
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
    """ Create an AWS MediaConvert job to convert a video file stored in S3 into an HLS playlist 
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
    """ Check on an AWS MediaConvert job
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
    print("Starting media convert")
    job_id = create_mediaconvert_job(mediaconvert, BUCKET_NAME, 'exampleuploaduid', 'fullcourtstock.mp4')
    while True:
        status = check_mediaconvert_status(mediaconvert, job_id)
        print(status)
        if status == 'COMPLETE':
            break
        time.sleep(0.5)

if __name__ == '__main__':
    main()
