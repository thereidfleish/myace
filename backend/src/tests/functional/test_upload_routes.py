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
from .routes import Upload


def establish_courtship(
    client: FlaskClient, sender_token: str, receiver_token: str, type: str
) -> None:
    """Sender creates a request to receiver and receiver accepts.

    Effect: sender is logged in.
    """
    receiver, created_r = routes.login_w_google(client, receiver_token)
    sender, created_s = routes.login_w_google(client, sender_token)
    assert created_r and created_s
    initial_cship = routes.get_user_by_id(client, receiver.id).courtship
    assert initial_cship is None
    # create req
    routes.create_courtship_req(client, receiver.id, type)
    # accept req
    receiver, created = routes.login_w_google(client, receiver_token)
    assert not created
    routes.update_incoming_court_req(client, sender.id, "accept")
    # login and assert courtship exists
    sender, created = routes.login_w_google(client, sender_token)
    assert not created
    final_cship = routes.get_user_by_id(client, receiver.id)
    assert final_cship is not None


@pytest.fixture
def configured_client(test_client: FlaskClient) -> FlaskClient:
    """:return: a preconfigured test client w/ dummy data for user A."""
    user_c, _ = routes.login_w_google(test_client, USER_C_TOKEN)
    user_b, _ = routes.login_w_google(test_client, USER_B_TOKEN)
    user_a, _ = routes.login_w_google(test_client, USER_A_TOKEN)
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
    user_b, _ = routes.login_w_google(test_client, USER_B_TOKEN)

    return test_client


def test_get_all_uploads(configured_client: FlaskClient):
    """Test the get all uploads route."""
    user, _ = routes.login_w_google(configured_client, USER_A_TOKEN)
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
