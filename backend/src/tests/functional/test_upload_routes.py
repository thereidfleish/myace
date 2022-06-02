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
    assert user_a_from_b.n_uploads == 2
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


def test_get_another_users_uploads(configured_client: FlaskClient):
    """Test the get another user's uploads route."""
    user_a = routes.login(configured_client, USER_A_TOKEN)
    user_b = routes.login(configured_client, USER_B_TOKEN)
    uploads = routes.get_other_users_uploads(configured_client, user_a.id)
    assert len(uploads) == 2
    assert (
        len(
            routes.get_other_users_uploads(
                configured_client, user_a.id, bucket_id=10000
            )
        )
        == 0
    )
    assert (
        len(
            routes.get_other_users_uploads(
                configured_client, user_a.id, bucket_id=1
            )
        )
        == 2
    )


def test_get_upload_by_id(configured_client: FlaskClient):
    """Test the get upload by ID route."""
    # get set of IDs that are not shared with user B
    user_b = routes.login(configured_client, USER_B_TOKEN)
    user_a = routes.login(configured_client, USER_A_TOKEN)
    a_uploads_sw_b = set(
        up.id
        for up in routes.get_all_uploads(
            configured_client, shared_with=user_b.id
        )
    )
    a_uploads_not_sw_b = (
        set(up.id for up in routes.get_all_uploads(configured_client))
        - a_uploads_sw_b
    )
    assert len(a_uploads_not_sw_b) > 0
    # Test invalid IDs
    user_b = routes.login(configured_client, USER_B_TOKEN)
    invalid_ids = [-1, 10000000]
    invalid_ids.extend(a_uploads_not_sw_b)
    for id in invalid_ids:
        with pytest.raises(AssertionError) as e_info:
            routes.get_upload(configured_client, id)
    # Test valid IDs
    valid_ids = a_uploads_sw_b
    for id in valid_ids:
        assert type(routes.get_upload(configured_client, id)) == Upload


def test_edit_upload(test_client):
    # user B has a bucket with nothing in it
    user_b = routes.login(test_client, USER_B_TOKEN)
    bucketb = routes.create_bucket(test_client, "bucketb")
    # user A has two buckets with one upload
    user_a = routes.login(test_client, USER_A_TOKEN)
    bucket1 = routes.create_bucket(test_client, "bucket1")
    initial_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "Upload1",
        bucket1.id,
        routes.VisibilitySetting("private", []),
    )
    bucket2 = routes.create_bucket(test_client, "bucket2")
    # Attempt adding to bucket that DNE
    invalid_bucket_ids = (-1, bucketb.id)
    for id in invalid_bucket_ids:
        with pytest.raises(AssertionError) as e_info:
            routes.edit_upload(
                test_client,
                initial_id,
                bucket_id=id,
            )
    # attempt sharing with yourself and misc invalid IDs
    invalid_share_ids = (user_a.id, 100000, -1)
    for id in invalid_share_ids:
        with pytest.raises(AssertionError) as e_info:
            routes.edit_upload(
                test_client,
                initial_id,
                visibility=routes.VisibilitySetting("private", [id]),
            )
    # Verify changes persist
    final = routes.edit_upload(
        test_client,
        initial_id,
        display_title="My new display title",
        bucket_id=bucket2.id,
        visibility=routes.VisibilitySetting("private", [user_b.id]),
    )
    assert final.display_title == "My new display title"
    assert final in routes.get_all_uploads(test_client, bucket_id=bucket2.id)
    assert final in routes.get_all_uploads(test_client, shared_with=user_b.id)


def test_delete_upload(test_client):
    """Ensure user can only delete their uploads and verify deletion works."""
    # setup two users with one upload each
    user_b = routes.login(test_client, USER_B_TOKEN)
    bucket_b = routes.create_bucket(test_client, "bucketb")
    upload_b_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "UploadB",
        bucket_b.id,
        routes.VisibilitySetting("private", []),
    )
    user_a = routes.login(test_client, USER_A_TOKEN)
    bucket_a = routes.create_bucket(test_client, "bucketa")
    upload_a_id, _, _ = routes.create_upload_url(
        test_client,
        "vid.mp4",
        "UploadA",
        bucket_a.id,
        routes.VisibilitySetting("private", []),
    )
    # attempt deleting upload user doesn't own
    with pytest.raises(AssertionError) as e_info:
        routes.delete_upload(test_client, upload_b_id)
    # verify successful deletion
    routes.delete_upload(test_client, upload_a_id)
    with pytest.raises(AssertionError) as e_info:
        routes.get_upload(test_client, upload_a_id)
