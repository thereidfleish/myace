"""Functional tests for all routes tagged with 'User'."""
import pytest

from flask.testing import FlaskClient

from . import (
    routes,
    HOST,
    USER_A_TOKEN,
    USER_B_TOKEN,
)


def test_create_bucket(test_client: FlaskClient):
    """Test creating a bucket with invalid and valid names."""
    user, _ = routes.login_w_google(test_client, USER_A_TOKEN)
    b1 = routes.create_bucket(test_client, "serves")
    invalid_names = (" ", "", "serves")
    for name in invalid_names:
        with pytest.raises(AssertionError) as e_info:
            routes.create_bucket(test_client, name)


def test_get_other_users_buckets(test_client: FlaskClient):
    """Test getting another user's buckets."""
    user_b, _ = routes.login_w_google(test_client, USER_B_TOKEN)
    # user A has an empty bucket, a bucket w private uploads, and a bucket
    # w public and private uploads
    user_a, _ = routes.login_w_google(test_client, USER_A_TOKEN)
    user_a_empty_b = routes.create_bucket(test_client, "b1")
    user_a_private_b = routes.create_bucket(test_client, "b2")
    routes.create_upload_url(
        test_client,
        "x.mp4",
        "Test",
        user_a_private_b.id,
        routes.VisibilitySetting("private", []),
    )
    user_a_visible_b = routes.create_bucket(test_client, "b3")
    routes.create_upload_url(
        test_client,
        "x.mp4",
        "Test",
        user_a_visible_b.id,
        routes.VisibilitySetting("private", []),
    )
    routes.create_upload_url(
        test_client,
        "x.mp4",
        "Test",
        user_a_visible_b.id,
        routes.VisibilitySetting("private", [user_b.id]),
    )
    # test that B can see all their buckets
    assert len(routes.get_all_buckets(test_client)) == 3
    # test that A's only bucket from B's perspective is the one that contains
    # visible uploads
    user_b, _ = routes.login_w_google(test_client, USER_B_TOKEN)
    a_buckets_to_b = routes.get_all_buckets(test_client, user_a.id)
    assert len(a_buckets_to_b) == 1
    visible = a_buckets_to_b[0]
    assert visible.id == user_a_visible_b.id
    assert visible.size == 1


def test_delete_bucket(test_client: FlaskClient):
    user, _ = routes.login_w_google(test_client, USER_A_TOKEN)
    bucket = routes.create_bucket(test_client, "serves")
    # create uploads in bucket
    routes.create_upload_url(
        test_client,
        "x.mp4",
        "Test",
        bucket.id,
        routes.VisibilitySetting("private", []),
    )
    routes.create_upload_url(
        test_client,
        "x.mp4",
        "Test2",
        bucket.id,
        routes.VisibilitySetting("private", []),
    )
    bucket = routes.get_all_buckets(test_client)[0]
    assert bucket.size == 2
    routes.delete_bucket(test_client, bucket.id)
    assert len(routes.get_all_buckets(test_client)) == 0
