#!/usr/bin/env python3

import os
import mimetypes
import boto3
from botocore.client import Config
from botocore.exceptions import ClientError
from dotenv import load_dotenv

load_dotenv()

AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID").strip()
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY").strip()
REGION_NAME = "us-east-2" # S3 bucket region
BUCKET_NAME = "www.myace.ai"


def deploy():
    """Deploy the static My Ace AI website to S3"""
    s3_resource = boto3.resource('s3', region_name=REGION_NAME, endpoint_url=f'https://s3.{REGION_NAME}.amazonaws.com',
        aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY, config=Config(signature_version='s3v4'))
    try:
        # clear bucket
        bucket = s3_resource.Bucket(BUCKET_NAME)
        bucket.objects.delete()
        # upload files
        for root, _, files in os.walk('my-ace-ai-static'):
            for fname in files:
                full_path = os.path.join(root, fname)
                # remove root directory prefix
                sub_paths = full_path.split(os.sep)[1:]
                key = os.sep.join(sub_paths)
                # guess content type
                content_type = mimetypes.guess_type(fname)[0]
                # upload
                bucket.upload_file(full_path, key, ExtraArgs={'ContentType': content_type})
        print("Deployed!")
    except ClientError as e:
        print(e)


if __name__ == "__main__":
    deploy()
