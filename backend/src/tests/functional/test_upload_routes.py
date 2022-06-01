"""Functional tests for all routes tagged with 'Upload'."""
import pytest
from flask.testing import FlaskClient

from . import (
    routes,
    HOST,
    USER_A_TOKEN,
    USER_B_TOKEN,
    USER_C_TOKEN,
)
from .routes import Upload, establish_courtship


@pytest.fixture
def configured_client(test_client: FlaskClient) -> FlaskClient:
    """:return: a preconfigured test client w/ dummy data for user A."""
    user_c = routes.login(test_client, USER_C_TOKEN)
    user_b = routes.login(test_client, USER_B_TOKEN)
    user_a = routes.login(test_client, USER_A_TOKEN)
    bucket1 = routes.create_bucket(test_client, "bucket1")
    upload1_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "Upload1",
        bucket1.id,
        routes.VisibilitySetting("private", [user_b.id]),
    )
    comment1 = routes.create_comment(test_client, "comment1", upload1_id)
    comment2 = routes.create_comment(test_client, "comment2", upload1_id)
    upload2_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "Upload2",
        bucket1.id,
        routes.VisibilitySetting("coaches-only", []),
    )
    comment3 = routes.create_comment(test_client, "comment3", upload2_id)

    # user B
    user_b = routes.login(test_client, USER_B_TOKEN)

    return test_client


def test_get_all_uploads(configured_client: FlaskClient):
    """Test the get all uploads route."""
    user = routes.login(configured_client, USER_A_TOKEN)
    uploads = routes.get_all_uploads(configured_client)
    assert len(uploads) == 2
    # Test filter by bucket
    user = routes.get_user(configured_client)
    buckets = routes.get_all_buckets(configured_client, user.id)
    for b in buckets:
        uploads_filtered = routes.get_all_uploads(
            configured_client, bucket_id=b.id
        )
        assert len(uploads_filtered) == b.size
    # TODO test filter by shared-with
