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
    # register users
    user_a = routes.login(test_client, USER_A_TOKEN)
    user_b = routes.login(test_client, USER_B_TOKEN)
    user_c = routes.login(test_client, USER_C_TOKEN)
    # login user A
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
    upload3_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "Upload3",
        bucket1.id,
        routes.VisibilitySetting("friends-only", []),
    )
    comment3 = routes.create_comment(test_client, "comment3", upload2_id)

    # user B coaches user A
    user_b = routes.login(test_client, USER_B_TOKEN)
    routes.establish_courtship(
        test_client, USER_B_TOKEN, USER_A_TOKEN, "student-req"
    )
    assert routes.get_user_by_id(test_client, user_a.id).n_coaches == 1

    # Login user A
    routes.login(test_client, USER_A_TOKEN)
    return test_client


def test_get_all_uploads(configured_client: FlaskClient):
    """Test the get all uploads route."""
    user_a = routes.login(configured_client, USER_A_TOKEN)
    a_uploads = routes.get_all_uploads(configured_client)
    assert len(a_uploads) == 3
    assert user_a.n_uploads == 3
    # test user A's n_uploads == 2 from B's perspective
    user_b = routes.login(configured_client, USER_B_TOKEN)
    user_a_from_b = routes.get_user_by_id(configured_client, user_a.id)
    assert user_a_from_b.n_uploads == 2, print(a_uploads)
    # Test filter by bucket
    user_a = routes.login(configured_client, USER_A_TOKEN)
    buckets = routes.get_all_buckets(configured_client, user_a.id)
    for b in buckets:
        uploads_filtered = routes.get_all_uploads(
            configured_client, bucket_id=b.id
        )
        assert len(uploads_filtered) == b.size
    # TODO test filter by shared-with
    # user B should be able to view 2 of A's uploads
    user_a = routes.login(configured_client, USER_A_TOKEN)
    uploads_filtered = routes.get_all_uploads(
        configured_client, shared_with=user_b.id
    )
    assert len(uploads_filtered) == 2
