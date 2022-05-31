"""Provides utility functions to abstract interaction with AWS."""

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

from .settings import (
    S3_BUCKET_NAME,
    S3_BUCKET_REGION,
    CF_PRIVATE_KEY,
    CF_PUBLIC_KEY_ID,
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
)

_s3 = boto3.client(
    "s3",
    region_name=S3_BUCKET_REGION,
    endpoint_url=f"https://s3.{S3_BUCKET_REGION}.amazonaws.com",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    config=Config(signature_version="s3v4"),
)
cf_distribution_id = "ERPD0DBPXWVO3"
cf_domain = "https://d11b188mr2hahn.cloudfront.net"
_cloudfront = boto3.client(
    "cloudfront",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
)
_mediaconvert = boto3.client(
    "mediaconvert",
    region_name=S3_BUCKET_REGION,
    endpoint_url=f"https://mqm13wgra.mediaconvert.{S3_BUCKET_REGION}.amazonaws.com",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
)


def rsa_sign(message):
    """Sign a message with cf_private_key.

    :return: The signed message
    """
    private_key = serialization.load_pem_private_key(
        CF_PRIVATE_KEY, password=None, backend=default_backend()
    )
    return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())


def _is_invalidation_request_completed(invalidation_id: str) -> bool:
    """Check if an invalidation request has been completed.

    :param invalidation_id: The invalidation request ID
    :return: If the request has been completed
    """
    response = _cloudfront.get_invalidation(
        DistributionId=cf_distribution_id, Id=invalidation_id
    )
    return response["Invalidation"]["Status"] == "Completed"


def _get_presigned_url(object_key: str, expiration: datetime.datetime) -> str:
    """Generate a presigned Cloudfront URL for any S3 object.

    :param object_key: The S3 object to sign
    :param expiration: The datetime obj when the URL should expire
    :return: Presigned URL pointing to the object
    """
    print(f"Generating presigned URL for {object_key}")
    url = f"{cf_domain}/{object_key}"
    cloudfront_signer = CloudFrontSigner(CF_PUBLIC_KEY_ID, rsa_sign)
    # Create a signed url using a canned policy
    signed_url = cloudfront_signer.generate_presigned_url(
        url, date_less_than=expiration
    )
    return signed_url


def get_upload_url(
    upload_uuid: str, filename: str, expiration_in_hours: int
) -> str:
    """Generate a presigned Cloudfront URL to view the original upload.

       Ex. 'www.something.com/.../filename.mp4'

    :param upload_uuid: The upload UUID
    :param filename: The original media filename
    :param expiration_in_hours: The number of hours until the URLs expire
    :return: Presigned URL pointing to the originally uploaded file
    """
    td = datetime.timedelta(hours=expiration_in_hours)
    key = f"uploads/{upload_uuid}/{filename}"
    url = _get_presigned_url(key, datetime.datetime.utcnow() + td)
    return url


def get_thumbnail_url(upload_uuid: str, expiration_in_hours: int) -> str:
    """Generate a presigned Cloudfront URL to view an upload's thumbnail.

       Requires the thumbnail file exists in the S3 bucket.

    :param upload_uuid: The upload UUID
    :param expiration_in_hours: The number of hours until the URLs expire
    :return: Presigned URL pointing to the thumbnail of the given upload
    """
    td = datetime.timedelta(hours=expiration_in_hours)
    key = f"uploads/{upload_uuid}/thumbnail.0000000.jpg"
    url = _get_presigned_url(key, datetime.datetime.utcnow() + td)
    return url


def get_presigned_url_post(
    upload_uuid: str, filename: str, expiration: int = 3600
) -> dict:
    """Generate a presigned URL that allows the client to upload a file.

    :param upload_uuid: The upload UUID
    :param filename: The original media filename
    :param expiration: Time in seconds for the presigned URL to remain valid
    :return: dictionary containing url and upload POST request fields
    """
    key = f"uploads/{upload_uuid}/{filename}"
    response = _s3.generate_presigned_post(
        S3_BUCKET_NAME, key, ExpiresIn=expiration
    )
    return response


def create_mediaconvert_job(upload_uuid: str, filename: str) -> str:
    """Create an AWS MediaConvert job to convert a video file stored in S3 into an HLS playlist and generate thumbnails.

    :param upload_uuid: The upload UUID
    :param filename: The original media filename
    :return: The mediaconvert job ID
    """
    # Load json job template
    with open("mediaconvert-job-template.json", "r") as f:
        job_object = json.load(f)
    # Complete template
    job_object["Settings"]["Inputs"][0][
        "FileInput"
    ] = f"s3://{S3_BUCKET_NAME}/uploads/{upload_uuid}/{filename}"
    job_object["Settings"]["OutputGroups"][0]["OutputGroupSettings"][
        "HlsGroupSettings"
    ]["Destination"] = f"s3://{S3_BUCKET_NAME}/uploads/{upload_uuid}/hls/index"
    job_object["Settings"]["OutputGroups"][1]["OutputGroupSettings"][
        "FileGroupSettings"
    ]["Destination"] = f"s3://{S3_BUCKET_NAME}/uploads/{upload_uuid}/thumbnail"
    # Unpack the job_object and create mediaconvert job
    response = _mediaconvert.create_job(**job_object)
    id = response["Job"]["Id"]
    return id


def get_mediaconvert_status(job_id: str) -> str:
    """Get an AWS MediaConvert job's status.

    :param job_id: The MediaConvert job ID
    :return: 'SUBMITTED' | 'PROGRESSING' | 'COMPLETE' | 'CANCELED' | 'ERROR'
    """
    response = _mediaconvert.get_job(Id=job_id)
    status = response["Job"]["Status"]
    return status


def delete_uploads(*upload_ids: int) -> None:
    """Delete videos with listed upload_ids from S3.

    :param upload_ids: upload_ids of the videos to be deleted.
    """
    found = False
    # We must use a paginator since AWS will only send the first 1000 objects using list objects.
    paginator = _s3.get_paginator("list_objects")

    # Paginate for each upload id.
    for upload_id in upload_ids:
        pages = paginator.paginate(
            Bucket=S3_BUCKET_NAME, Prefix=f"uploads/{upload_id}/"
        )

        delete_keys = dict(Objects=[])
        # For each object in the contents of the paginator, append it to our list of deleted keys.
        for item in pages.search("Contents"):
            if item is None:
                return False
            delete_keys["Objects"].append(dict(Key=item["Key"]))

            # Since delete_objects also has a cap at 1000, execute when we reach this cap.
            if len(delete_keys["Objects"]) >= 1000:
                _s3.delete_objects(Bucket=S3_BUCKET_NAME, Delete=delete_keys)
                delete_keys = dict(Objects=[])
                found = True

        # Delete all remaining objects
        if len(delete_keys["Objects"]):
            _s3.delete_objects(Bucket=S3_BUCKET_NAME, Delete=delete_keys)
            found = True
    assert found, "Expected to find uploads."
