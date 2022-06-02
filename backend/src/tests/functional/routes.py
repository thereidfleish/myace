"""Provides helper functions to interact with backend server."""
from __future__ import annotations
from typing import Any
from dataclasses import dataclass
import os
import datetime
import json

from flask.testing import FlaskClient
from . import (
    HOST,
)


def log_response(res) -> str:
    """:return: a string-formatted response."""
    return f"Response status code: {res.status_code}\nData:\n{res.data}"


def _add_params(url: str, params: dict[str, Any]) -> str:
    """Append query parameters onto URL."""
    if len(params) == 0:
        return url
    url += "?"
    for k, v in params.items():
        url += "&" + k + "=" + str(v)
    return url


@dataclass
class CourtshipRequest:
    """Courtship request model."""

    type: str
    dir: str


@dataclass
class Courtship:
    """Courtship request model."""

    type: str


@dataclass
class User:
    """User model."""

    id: int
    username: str
    dname: str
    bio: str
    n_uploads: int
    n_friends: int
    n_coaches: int
    n_students: int
    courtship: Courtship | CourtshipRequest | None
    email: str | None = None


@dataclass
class Bucket:
    """Bucket model."""

    id: int
    size: int
    last_modified: datetime.datetime
    name: str


@dataclass
class Comment:
    """Comment model."""

    id: int
    created: datetime.datetime
    author: User
    text: str
    upload_id: int


@dataclass
class VisibilitySetting:
    """Visibility Setting model. Specific to uploads."""

    default: str
    also_shared_with: list[int]


@dataclass
class Upload:
    """Upload model."""

    id: int
    created: datetime.datetime
    display_title: str
    stream_ready: bool
    bucket: Bucket
    visibility: VisibilitySetting
    thumbnail: str | None = None
    url: str | None = None


def parse_user_json(j: dict) -> User:
    """Parse a dict into its user object."""
    courtship: Courtship | CourtshipRequest | None = None
    if j["courtship"] is not None:
        cship_type = j["courtship"]["type"]
        cship_dir = j["courtship"].get("dir")
        courtship = (
            Courtship(cship_type)
            if cship_dir is None
            else CourtshipRequest(cship_type, cship_dir)
        )
    return User(
        j["id"],
        j["username"],
        j["display_name"],
        j["biography"],
        j["n_uploads"],
        j["n_courtships"]["friends"],
        j["n_courtships"]["coaches"],
        j["n_courtships"]["students"],
        courtship=courtship,
        email=j.get("email"),
    )


def parse_bucket_json(j: dict) -> Bucket:
    """Parse a dict into its Bucket object."""
    return Bucket(j["id"], j["size"], j["last_modified"], j["name"])


def parse_visib_json(j: dict) -> VisibilitySetting:
    """Parse a dict into its VisibilitySetting object."""
    return VisibilitySetting(j["default"], j["also_shared_with"])


def parse_upload_json(j: dict) -> Upload:
    """Parse a dict into its Upload object."""
    return Upload(
        j["id"],
        j["created"],
        j["display_title"],
        j["stream_ready"],
        parse_bucket_json(j["bucket"]),
        parse_visib_json(j["visibility"]),
        j.get("thumbnail"),
        j.get("url"),
    )


def parse_comment_json(j: dict) -> Comment:
    """Parse a dict into its comment object."""
    return Comment(
        j["id"],
        j["created"],
        parse_user_json(j["author"]),
        j["text"],
        j["upload_id"],
    )


def get_user_opt(client: FlaskClient, user_id_param: str | int) -> User | None:
    """Retrieve the currently logged in user if logged in or None if not."""
    res = client.get(f"{HOST}/users/{user_id_param}/")
    if res.status_code == 401:
        return None
    assert res.status_code == 200, log_response(res)
    return parse_user_json(json.loads(res.data))


def get_user(client: FlaskClient) -> User:
    """Retrieve the currently logged in user.

    Raises exception if not logged in.
    """
    user = get_user_opt(client, "me")
    assert user is not None
    return user


def get_user_by_id(client: FlaskClient, user_id: int) -> User:
    """Retrieve a user by ID.

    Raises exception if not logged in.
    """
    user = get_user_opt(client, user_id)
    assert user is not None
    return user


def is_logged_in(client: FlaskClient) -> bool:
    """Check if the current user is logged in."""
    return get_user_opt(client, "me") is not None


def is_user_logged_in(client: FlaskClient, user: User) -> bool:
    """Check if a given user is logged in."""
    check = get_user_opt(client, user.id)
    return check is not None and check == user


def login(client: FlaskClient, google_token: str) -> User:
    """Create app session by logging in with google."""
    body = {
        "token": google_token,
    }
    res = client.post(f"{HOST}/login/", json=body)
    assert res.status_code == 200 or res.status_code == 201, log_response(res)
    return parse_user_json(json.loads(res.data))


def logout(client: FlaskClient) -> None:
    """Logout of session."""
    res = client.post(f"{HOST}/logout/")
    assert res.status_code == 200, log_response(res)
    assert not is_logged_in(client)


def update_user(
    client: FlaskClient, username=None, display_name=None, biography=None
) -> None:
    """Update a user with current information."""
    body = dict()
    if username is not None:
        body["username"] = username
    if display_name is not None:
        body["display_name"] = display_name
    if biography is not None:
        body["biography"] = biography
    res = client.put(f"{HOST}/users/me/", json=body)
    assert res.status_code == 200, log_response(res)
    # Verify change was successful # TODO: move to test
    user = get_user(client)
    if username is not None:
        assert user.username == username
    if display_name is not None:
        assert user.dname == display_name
    if biography is not None:
        assert user.bio == biography


def delete_user(client: FlaskClient) -> None:
    """Delete the logged in user."""
    res = client.delete(f"{HOST}/users/me/")
    assert res.status_code == 204, log_response(res)
    assert not is_logged_in(client)


def search(client: FlaskClient, q: str) -> list[User]:
    """Perform a user search query."""
    res = client.get(f"{HOST}/users/search?q={q}")
    assert res.status_code == 200, log_response(res)
    return [parse_user_json(u) for u in json.loads(res.data)]


def get_all_uploads(
    client: FlaskClient,
    bucket_id: int | None = None,
    shared_with: int | None = None,
) -> list[Upload]:
    """Get the current user's uploads."""
    params = dict()
    if bucket_id is not None:
        params["bucket"] = bucket_id
    if shared_with is not None:
        params["shared-with"] = shared_with
    res = client.get(_add_params(f"{HOST}/users/me/uploads", params))
    assert res.status_code == 200, log_response(res)
    return [parse_upload_json(u) for u in json.loads(res.data)["uploads"]]


def get_other_users_uploads(
    client: FlaskClient,
    other_id: int,
    bucket_id: int | None = None,
) -> list[Upload]:
    """Get another user's uploads."""
    params = dict()
    if bucket_id is not None:
        params["bucket"] = bucket_id
    res = client.get(_add_params(f"{HOST}/users/{other_id}/uploads", params))
    assert res.status_code == 200, log_response(res)
    return [parse_upload_json(u) for u in json.loads(res.data)["uploads"]]


def get_upload(
    client: FlaskClient,
    id: int,
) -> Upload:
    """Get an upload by ID."""
    res = client.get(f"{HOST}/uploads/{id}/")
    assert res.status_code == 200, log_response(res)
    return parse_upload_json(json.loads(res.data))


def edit_upload(
    client: FlaskClient,
    id: int,
    display_title: str | None = None,
    bucket_id: int | None = None,
    visibility: VisibilitySetting | None = None,
) -> Upload:
    """Edit an upload by ID."""
    body: dict[str, object] = dict()
    if display_title is not None:
        body["display_title"] = display_title
    if bucket_id is not None:
        body["bucket_id"] = bucket_id
    if visibility is not None:
        body["visibility"] = {
            "default": visibility.default,
            "also_shared_with": visibility.also_shared_with,
        }
    res = client.put(f"{HOST}/uploads/{id}/", json=body)
    assert res.status_code == 200, log_response(res)
    return parse_upload_json(json.loads(res.data))


def delete_upload(client: FlaskClient, id: int) -> None:
    """Delete an upload by ID."""
    res = client.delete(f"{HOST}/uploads/{id}/")
    assert res.status_code == 204, log_response(res)


def create_upload_url(
    client: FlaskClient,
    filename: str,
    display_title: str,
    bucket_id: int,
    visibility: VisibilitySetting,
) -> tuple[int, str, dict]:
    """Create a presigned URL used to create an upload.

    :return:
        the ID of the new upload,
        the presigned URL,
        and the fields to be included in the request body when uploading.
    """
    body = {
        "filename": filename,
        "display_title": display_title,
        "bucket_id": bucket_id,
        "visibility": {
            "default": visibility.default,
            "also_shared_with": visibility.also_shared_with,
        },
    }
    res = client.post(f"{HOST}/uploads/", json=body)
    assert res.status_code == 201, log_response(res)
    j = json.loads(res.data)
    # replace underscores with hyphens
    fields = j["fields"]
    for old_key in list(fields):
        new_key = old_key.replace("_", "-")
        fields[new_key] = fields.pop(old_key)
    return j["id"], j["url"], fields


def create_upload(
    client: FlaskClient,
    path_to_file: str,
    display_title: str,
    bucket_id: int,
    visibility: VisibilitySetting,
) -> Upload:
    """Upload a file, convert to stream_ready, and return that upload model."""
    filename = os.path.basename(path_to_file)
    id, presigned_url, fields = create_upload_url(
        client, filename, display_title, bucket_id, visibility
    )
    with open(path_to_file, "rb") as f:
        files = {"file": (filename, f)}
        upload_res = client.post(presigned_url, data=fields, files=files)
        assert (
            upload_res.status_code == 204
        ), "Failed to upload file to presigned URL!"

    # Convert to stream_ready
    create_url_res = client.post(f"{HOST}/uploads/{id}/convert/")
    assert create_url_res.status_code == 200
    return get_upload(client, id)


def get_download_url(client: FlaskClient, upload_id: int) -> str:
    """Get a presigned URL to download a specified upload."""
    res = client.get(f"{HOST}/uploads/{upload_id}/download/")
    assert res.status_code == 200, log_response(res)
    return json.loads(res.data)["url"]


def get_all_comments(
    client: FlaskClient, upload_id: int | None = None
) -> list[Comment]:
    """Get all comments authored by the current user."""
    params = dict()
    if upload_id is not None:
        params["upload"] = upload_id
    res = client.get(_add_params(f"{HOST}/comments", params))
    assert res.status_code == 200
    return [parse_comment_json(c) for c in json.loads(res.data)["comments"]]


def create_comment(client: FlaskClient, text: str, upload_id: int) -> Comment:
    """Create a comment under an upload."""
    body = {"text": text, "upload_id": upload_id}
    res = client.post(f"{HOST}/comments/", json=body)
    assert res.status_code == 201
    return parse_comment_json(json.loads(res.data))


def delete_comment(client: FlaskClient, comment_id: int) -> None:
    """Delete a comment by ID."""
    res = client.delete(f"{HOST}/comments/{comment_id}/")
    assert res.status_code == 204


def create_bucket(client: FlaskClient, name: str) -> Bucket:
    """Create a bucket under the current user."""
    res = client.post(f"{HOST}/buckets/", json={"name": name})
    assert res.status_code == 201
    return parse_bucket_json(json.loads(res.data))


def get_all_buckets(client: FlaskClient, user_id: int | None) -> list[Bucket]:
    """Get a list of all buckets owned by any user."""
    res = client.get(f"{HOST}/users/{user_id}/buckets")
    assert res.status_code == 200
    return [parse_bucket_json(b) for b in json.loads(res.data)["buckets"]]


def edit_bucket(
    client: FlaskClient, bucket_id: int, name: str | None
) -> Bucket:
    """Update the properties of a bucket."""
    body = dict()
    if name is not None:
        body["name"] = name
    res = client.put(f"{HOST}/buckets/{bucket_id}/", json=body)
    assert res.status_code == 200
    return parse_bucket_json(json.loads(res.data))


def delete_bucket(client: FlaskClient, bucket_id: int) -> None:
    """Delete a bucket by ID."""
    res = client.delete(f"{HOST}/buckets/{bucket_id}/")
    assert res.status_code == 204


def create_courtship_req(
    client: FlaskClient, other_id: int, type: str
) -> User:
    """Create a courtship request of a certain type to another user."""
    body = {"user_id": other_id, "type": type}
    res = client.post(f"{HOST}/courtships/requests/", json=body)
    assert res.status_code == 201
    return parse_user_json(json.loads(res.data))


def get_courtship_reqs(
    client: FlaskClient,
    type: str | None = None,
    dir: str | None = None,
) -> list[User]:
    """Get all courtship requests involving the current user."""
    params = dict()
    if type is not None:
        params["type"] = type
    if dir is not None:
        params["dir"] = dir
    res = client.get(_add_params(f"{HOST}/courtships/requests", params))
    assert res.status_code == 200
    return [parse_user_json(u) for u in json.loads(res.data)["requests"]]


def update_incoming_court_req(
    client: FlaskClient, other_id: int, status: str
) -> None:
    """Respond to an incoming courtship request."""
    res = client.put(
        f"{HOST}/courtships/requests/{other_id}/", json={"status": status}
    )
    assert res.status_code == 204


def delete_outgoing_court_req(client: FlaskClient, other_id: int) -> None:
    """Delete an outgoing courtship request."""
    res = client.delete(f"{HOST}/courtships/requests/{other_id}/")
    assert res.status_code == 204


def get_all_courtships(
    client: FlaskClient,
    user_id: int | str,
    type: str | None = None,
) -> list[User]:
    """Get all established courtships involving the current user."""
    params = dict()
    if type is not None:
        params["type"] = type
    res = client.get(_add_params(f"{HOST}/users/{user_id}/courtships", params))
    assert res.status_code == 200
    return [parse_user_json(u) for u in json.loads(res.data)["courtships"]]


def delete_courtship(client: FlaskClient, other_id: int) -> None:
    """Delete an established courtship by ID."""
    res = client.delete(f"{HOST}/courtships/{other_id}/")
    assert res.status_code == 204


# non-route helper
def establish_courtship(
    client: FlaskClient,
    sender_token: str,
    receiver_token: str,
    type: str,
) -> None:
    """Sender creates a request to receiver and receiver accepts.

    :param type: friend-req | student-req | coach-req
    Effect: sender is logged in."""
    assert type in ("friend-req", "student-req", "coach-req")
    receiver = login(client, receiver_token)
    sender = login(client, sender_token)
    initial_cship = get_user_by_id(client, receiver.id).courtship
    assert initial_cship is None
    # create req
    create_courtship_req(client, receiver.id, type)
    # accept req
    receiver = login(client, receiver_token)
    update_incoming_court_req(client, sender.id, "accept")
    # login and assert courtship exists
    sender = login(client, sender_token)
    final_cship = get_user_by_id(client, receiver.id)
    assert final_cship is not None
