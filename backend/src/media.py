#!/usr/bin/env python3
"""
Provides a utility class to manage AWS streams.
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
from botocore.client import Config
from botocore.exceptions import ClientError

class AWS:
    def __init__(self, access_key_id: str, secret_access_key: str, cf_public_key_id: str, cf_private_key_file: str) -> None:
        """Construct an AWS object containing boto3 clients and helper methods.

        :param access_key_id: IAM access key ID
        :param secret_access_key: IAM secret access key
        :param cf_public_key_id: CloudFront public key ID
        :param cf_private_key_file: Path to file containing CloudFront private key
        """
        self.s3_region_name = 'us-east-2'
        self.s3_bucket_name = 'tennis-trainer'
        self.s3 = boto3.client('s3', region_name=self.s3_region_name, endpoint_url=f'https://s3.{self.s3_region_name}.amazonaws.com',
                      aws_access_key_id=access_key_id, aws_secret_access_key=secret_access_key, config=Config(signature_version='s3v4'))
        self.cf_distribution_id = 'ERPD0DBPXWVO3'
        self.cf_domain = 'https://d11b188mr2hahn.cloudfront.net'
        self.cf_public_key_id = cf_public_key_id
        self.cf_private_key_file = cf_private_key_file
        self.cloudfront = boto3.client('cloudfront', aws_access_key_id=access_key_id, aws_secret_access_key=secret_access_key)
        self.mediaconvert = boto3.client('mediaconvert', region_name=self.s3_region_name, endpoint_url=f'https://mqm13wgra.mediaconvert.{self.s3_region_name}.amazonaws.com',
                      aws_access_key_id=access_key_id, aws_secret_access_key=secret_access_key)
        # Invalidation requests that have not yet completed. Relevant to self.get_presigned_hls_url().
        # TODO: This could become problematic when serving multiple clients using the same class instance.
        #       For example, because get_presigned_hls_url() blocks until this list is empty, if multiple
        #       clients are continually appending, no single method call will complete until all invalidation
        #       requests are complete, including those unrelated to that call.
        #       A possible fix would be accumulating invalidation request IDs in a local var rather than member
        self.__invalidation_ids = []

    def rsa_sign(self, message):
        """Sign a message with self.cf_private_key_file.

        :return: The signed message
        """
        with open(self.cf_private_key_file, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,
                backend=default_backend()
            )
        return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())

    def __create_m3u8_invalidation(self, m3u8_object_key: str) -> str:
        """Create CloudFront cache invalidation request.

        :param m3u8_object_key: The Cloudfront client
        :return: The invalidation request ID
        """
        response = self.cloudfront.create_invalidation(
            DistributionId=self.cf_distribution_id,
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

    def __is_invalidation_request_completed(self, invalidation_id: str) -> bool:
        """Check if an invalidation request has been completed.

        :param invalidation_id: The invalidation request ID
        :return: If the request has been completed
        """
        response = self.cloudfront.get_invalidation(
            DistributionId = self.cf_distribution_id,
            Id = invalidation_id
        )
        return response['Invalidation']['Status'] == 'Completed'

    def __sign_sub_files(self, m3u8_object_key: str, expiration: datetime.datetime) -> None:
        """Modify the contents of the m3u8 file to append signed URL params to each *.m3u8 or *.ts file name.

        :param m3u8_object_key: The object key of the HLS manifest file. Typically resembles 'index.m3u8'
        :param expiration: The datetime obj when the URL should expire
        """
        print(f"Downloading {m3u8_object_key}")
        temp_filename = m3u8_object_key.replace('/', '-') + '.tmp'
        # Download m3u8
        self.s3.download_file(self.s3_bucket_name, m3u8_object_key, temp_filename)
        # Modify file TODO modify subfiles, collect list of keys, invalidate all keys at once
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
                    sub_query_params = self.__get_presigned_url(sub_object_key, expiration).split('?')[1]
                    line = filename + '?' + sub_query_params + '\n'
                modified_lines.append(line)
            f.seek(0)
            f.writelines(modified_lines)
            f.truncate()
        # Reupload file
        print(f"Uploading {m3u8_object_key}")
        response = self.s3.upload_file(temp_filename, self.s3_bucket_name, m3u8_object_key)
        # Invalidate cloudfront cache
        invalidation_id = self.__create_m3u8_invalidation(m3u8_object_key)
        self.__invalidation_ids.append(invalidation_id)
        # Remove local file
        print(f"Removing {temp_filename}")
        os.remove(temp_filename)

    def __get_presigned_url(self, object_key: str, expiration: datetime.datetime) -> str:
        """Generate a presigned Cloudfront URL for any S3 object.

           For a general idea of why this function works recursively with HLS streams, see:
           https://aws.amazon.com/blogs/networking-and-content-delivery/secure-and-cost-effective-video-streaming-using-cloudfront-signed-urls/

        :param object_key: The S3 object to sign
        :param expiration: The datetime obj when the URL should expire
        :return: Presigned URL pointing to the object
        """
        print(f"Generating presigned URL for {object_key}")
        url = f"{self.cf_domain}/{object_key}"
        cloudfront_signer = CloudFrontSigner(self.cf_public_key_id, self.rsa_sign)
        # Create a signed url using a canned policy
        signed_url = cloudfront_signer.generate_presigned_url(
            url, date_less_than=expiration)
        if '.m3u8' in object_key:
            self.__sign_sub_files(object_key, expiration)
        return signed_url

    def get_presigned_hls_url(self, upload_uuid: str, expiration: datetime.datetime) -> str:
        """Generate a presigned Cloudfront URL to view an upload's HLS stream.

           Requires the HLS files exist in the S3 bucket.

        :param upload_uuid: The upload UUID
        :param expiration: The datetime obj when the URL should expire
        :return: Presigned URL pointing to the manifest file or None if there was an error
        """
        object_key = f"uploads/{upload_uuid}/hls/index.m3u8"
        try:
            url = self.__get_presigned_url(object_key, expiration) # populates self.__invalidation_ids
        except ClientError as e:
            print(e.response['Error']['Message'])
            return None
        print(f"Waiting for {len(self.__invalidation_ids)} invalidation requests to complete...")
        for id in self.__invalidation_ids:
            if self.__is_invalidation_request_completed(id):
                self.__invalidation_ids.remove(id)
            else:
                time.sleep(0.2)
        return url

    def get_upload_url(self, upload_uuid: str, filename: str, expiration_in_hours: int) -> str:
        """Generate a presigned Cloudfront URL to view the upload's original, non-HLS URL.

           Ex. 'www.something.com/.../filename.mp4'

        :param upload_uuid: The upload UUID
        :param filename: The original media filename
        :param expiration_in_hours: The number of hours until the URLs expire
        :return: Presigned URL pointing to the originally uploaded file
        """
        td = datetime.timedelta(hours=expiration_in_hours)
        key = f"uploads/{upload_uuid}/{filename}"
        url = self.__get_presigned_url(key, datetime.datetime.utcnow() + td)
        return url

    def get_thumbnail_url(self, upload_uuid: str, expiration_in_hours: int) -> str:
        """Generate a presigned Cloudfront URL to view an upload's thumbnail.

           Requires the thumbnail file exists in the S3 bucket.

        :param upload_uuid: The upload UUID
        :param expiration_in_hours: The number of hours until the URLs expire
        :return: Presigned URL pointing to the thumbnail of the given upload
        """
        td = datetime.timedelta(hours=expiration_in_hours)
        key = f"uploads/{upload_uuid}/thumbnail.0000000.jpg"
        url = self.__get_presigned_url(key, datetime.datetime.utcnow() + td)
        return url

    def get_presigned_url_post(self, upload_uuid: str, filename: str, expiration: int = 3600) -> dict:
        """Generate a presigned URL that allows the client to upload a file using a POST request.

        :param upload_uuid: The upload UUID
        :param filename: The original media filename
        :param expiration: Time in seconds for the presigned URL to remain valid
        :return: dictionary containing url and information pertinent to POST request
        """
        key = f"uploads/{upload_uuid}/{filename}"
        response = self.s3.generate_presigned_post(self.s3_bucket_name, key, ExpiresIn=expiration)
        return response

    def create_mediaconvert_job(self, upload_uuid: str, filename: str) -> str:
        """Create an AWS MediaConvert job to convert a video file stored in S3 into an HLS playlist and generate thumbnails.

        :param upload_uuid: The upload UUID
        :param filename: The original media filename
        :return: The mediaconvert job ID
        """
        # Load json job template
        with open("mediaconvert-job-template.json", "r") as f:
            job_object = json.load(f)
        # Complete template
        job_object['Settings']['Inputs'][0]['FileInput'] = f's3://{self.s3_bucket_name}/uploads/{upload_uuid}/{filename}'
        job_object['Settings']['OutputGroups'][0]['OutputGroupSettings']['HlsGroupSettings']['Destination'] = f's3://{self.s3_bucket_name}/uploads/{upload_uuid}/hls/index'
        job_object['Settings']['OutputGroups'][1]['OutputGroupSettings']['FileGroupSettings']['Destination'] = f's3://{self.s3_bucket_name}/uploads/{upload_uuid}/thumbnail'
        # Unpack the job_object and create mediaconvert job
        response = self.mediaconvert.create_job(**job_object)
        id = response['Job']['Id']
        return id

    def get_mediaconvert_status(self, job_id: str) -> str:
        """Get an AWS MediaConvert job's status.

        :param job_id: The MediaConvert job ID
        :return: 'SUBMITTED' | 'PROGRESSING' | 'COMPLETE' | 'CANCELED' | 'ERROR'
        """
        response = self.mediaconvert.get_job(Id=job_id)
        status = response['Job']['Status']
        return status

    def delete_uploads(self, *upload_ids: int) -> bool:
        """Delete videos with listed upload_ids from S3.

        :param upload_ids: upload_ids of the videos to be deleted.
        :return: True if objects matching the upload_id were found (and most likely deleted), False if nothing was found
        """

        found = False
        # We must use a paginator since AWS will only send the first 1000 objects using list objects.
        paginator = self.s3.get_paginator('list_objects')

        # Paginate for each upload id.
        for upload_id in upload_ids:
            pages = paginator.paginate(Bucket=self.s3_bucket_name, Prefix=f'uploads/{upload_id}/')

            delete_keys = dict(Objects=[])
            # For each object in the contents of the paginator, append it to our list of deleted keys.
            for item in pages.search('Contents'):
                if item is None:
                    return False
                delete_keys['Objects'].append(dict(Key=item['Key']))

                # Since delete_objects also has a cap at 1000, execute when we reach this cap.
                if len(delete_keys['Objects']) >= 1000:
                    self.s3.delete_objects(Bucket=self.s3_bucket_name, Delete=delete_keys)
                    delete_keys = dict(Objects=[])
                    found = True

            # Delete all remaining objects
            if len(delete_keys['Objects']):
                self.s3.delete_objects(Bucket=self.s3_bucket_name, Delete=delete_keys)
                found = True

            return found


def main() -> None:
    from dotenv import load_dotenv
    # load environment variables
    load_dotenv()
    # constants
    ACCESS_KEY_ID = str(os.environ.get("AWS_ACCESS_KEY_ID")).strip()
    SECRET_ACCESS_KEY = str(os.environ.get("AWS_SECRET_ACCESS_KEY")).strip()
    CF_PUBLIC_KEY_ID = str(os.environ.get("CF_PUBLIC_KEY_ID")).strip()
    CF_PRIVATE_KEY_FILE = str(os.environ.get("CF_PRIVATE_KEY_FILE"))
    aws = AWS(ACCESS_KEY_ID, SECRET_ACCESS_KEY, CF_PUBLIC_KEY_ID, CF_PRIVATE_KEY_FILE)

    # Reset the playlist files
    print("Converting MP4 to HLS. This may take a sec...")
    job_id = aws.create_mediaconvert_job('exampleuploaduid', 'fullcourtstock.mp4')
    while True:
        status = aws.get_mediaconvert_status(job_id)
        if status == 'COMPLETE':
            print(status)
            break
        time.sleep(1)

    # Create presigned thubmnail URLs
    url = aws.get_thumbnail_url('exampleuploaduid', 1)
    print(url)

    # Create presigned upload URL
    # info = aws.get_presigned_url_post('exampleuploaduid', 'fullcourtstock.mp4')
    # print(info)


if __name__ == '__main__':
    main()
