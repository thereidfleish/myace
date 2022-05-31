"""Unit tests for AWS helper module."""
import time
import os
import requests
from app import aws

UPLOAD_ID = "test_aws"
UPLOAD_FP = os.path.join(
    os.path.dirname(__file__), "..", "samplevids", "fullcourtstock.mp4"
)
UPLOAD_FILENAME = "fullcourtstock.mp4"


def setup_module(module):
    """Request a presigned URL and then upload and convert a test file."""
    # get upload URL
    urldata = aws.get_presigned_url_post(UPLOAD_ID, UPLOAD_FILENAME)
    url = urldata["url"]
    fields = urldata["fields"]
    # upload file
    with open(UPLOAD_FP, "rb") as f:
        files = {"file": (UPLOAD_FILENAME, f)}
        res = requests.post(url, data=fields, files=files)
        assert (
            res.status_code == 204
        ), "Failed to upload file to presigned URL!"
    # create a mediaconvert job
    before = time.time()
    job_id = aws.create_mediaconvert_job(UPLOAD_ID, UPLOAD_FILENAME)
    while aws.get_mediaconvert_status(job_id) in (
        aws.ConvertStatus.SUBMITTED,
        aws.ConvertStatus.PROGRESSING,
    ):
        # ensure conversion takes <= 60 seconds
        assert time.time() - before <= 60
        time.sleep(5)
    assert aws.get_mediaconvert_status(job_id) == aws.ConvertStatus.COMPLETE
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/thumbnail.0000000.jpg")
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/{UPLOAD_FILENAME}")
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/hls/index.m3u8")


def teardown_module(module):
    """Glass box test for deleting uploads."""
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/thumbnail.0000000.jpg")
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/{UPLOAD_FILENAME}")
    assert aws.s3_key_exists(f"uploads/{UPLOAD_ID}/hls/index.m3u8")
    aws.delete_uploads([UPLOAD_ID])
    assert not aws.s3_key_exists(f"uploads/{UPLOAD_ID}/thumbnail.0000000.jpg")
    assert not aws.s3_key_exists(f"uploads/{UPLOAD_ID}/{UPLOAD_FILENAME}")
    assert not aws.s3_key_exists(f"uploads/{UPLOAD_ID}/hls/index.m3u8")


def test_urls():
    """Test that thumbnail and download URLs work."""
    download_url = aws.get_download_url(UPLOAD_ID, UPLOAD_FILENAME, 1)
    assert UPLOAD_FILENAME in download_url
    thumb_url = aws.get_thumbnail_url(UPLOAD_ID, 1)
    assert "https" in download_url and "https" in thumb_url
