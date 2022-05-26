"""Provides helper functions to interact with backend server."""
import os
import datetime
from dataclasses import dataclass
from requests import Session, Response
from typing import Iterable
from models import *

HOST = "localhost"


def log_response(res: Response) -> str:
    """:return: a string-formatted response."""
    return f"Response status code: {res.status_code}\nContent:\n{res.text}"


@dataclass
class User:
    """User model."""

    id: int
    username: str
    dname: str
    bio: str
    email: str


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


@dataclass
class CourtshipRequest:
    """Courtship request model."""

    type: str
    dir: str
    user: User


@dataclass
class Courtship:
    """Courtship request model."""

    type: str
    user: User


def parse_user_json(j: dict) -> User:
    """Parse a dict into its user object."""
    return User(
        j["id"],
        j["username"],
        j["display_name"],
        j["biography"],
        j["email"],
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


def parse_courtship_req_json(j: dict) -> CourtshipRequest:
    """Parse a dict into its courtship request object."""
    return CourtshipRequest(j["type"], j["dir"], parse_user_json(j["user"]))


def parse_courtship_json(j: dict) -> Courtship:
    """Parse a dict into its courtship object."""
    return Courtship(j["type"], parse_user_json(j["user"]))


def get_user_opt(s: Session) -> User | None:
    """Retrieve the currently logged in user if logged in or None if not."""
    res = s.get(f"{HOST}/users/me/")
    if res.status_code == 401:
        return None
    assert res.status_code == 200, log_response(res)
    return parse_user_json(res.json())


def get_user(s: Session) -> User:
    """Retrieve the currently logged in user.

    Raises exception if not logged in.
    """
    user = get_user_opt(s)
    assert user is not None
    return user


def is_logged_in(s: Session) -> bool:
    """Check if any user is logged in."""
    return get_user_opt(s) is not None


def is_user_logged_in(s: Session, user: User) -> bool:
    """Check if a given user is logged in."""
    check = get_user_opt(s)
    return check is not None and check == user


def login(s: Session, google_token: str) -> User:
    """Create app session by logging in with google."""
    body = {
        "token": google_token,
        "type": 0,
    }
    res = s.post(url=f"{HOST}/login/", json=body)
    assert res.status_code == 200 or res.status_code == 201, log_response(res)
    return parse_user_json(res.json())


def logout(s: Session) -> None:
    """Logout of session."""
    res = s.post(f"{HOST}/logout/")
    assert res.status_code == 200, log_response(res)
    assert not is_logged_in(s)


def update_user(s: Session, username=None, display_name=None, biography=None):
    """Update a user with current information."""
    body = dict()
    if username is not None:
        body["username"] = username
    if display_name is not None:
        body["display_name"] = display_name
    if biography is not None:
        body["biography"] = biography
    res = s.put(f"{HOST}/users/me/", json=body)
    assert res.status_code == 200, log_response(res)
    # Verify change was successful # TODO: move to test
    user = get_user(s)
    if username is not None:
        assert user.username == username
    if display_name is not None:
        assert user.dname == display_name
    if biography is not None:
        assert user.bio == biography


def delete_user(s: Session) -> None:
    """Delete the logged in user."""
    res = s.delete(f"{HOST}/users/me/")
    assert res.status_code == 204, log_response(res)
    assert not is_logged_in(s)


def search(s: Session, q: str) -> list[User]:
    """Perform a user search query."""
    res = s.get(f"{HOST}/users/search?q={q}")
    assert res.status_code == 200, log_response(res)
    return [parse_user_json(u) for u in res.json()]


def get_all_uploads(
    s: Session, bucket_id: int | None = None, shared_with: int | None = None
) -> list[Upload]:
    """Get the current user's uploads."""
    params = dict()
    if bucket_id is not None:
        params["bucket"] = bucket_id
    if shared_with is not None:
        params["shared-with"] = shared_with
    res = s.get(f"{HOST}/users/me/uploads", params=params)
    assert res.status_code == 200, log_response(res)
    return [parse_upload_json(u) for u in res.json()]


def get_other_users_uploads(
    s: Session,
    other_id: int,
    bucket_id: int | None = None,
) -> list[Upload]:
    """Get another user's uploads."""
    params = dict()
    if bucket_id is not None:
        params["bucket"] = bucket_id
    res = s.get(f"{HOST}/users/{other_id}/uploads", params=params)
    assert res.status_code == 200, log_response(res)
    return [parse_upload_json(u) for u in res.json()]


def get_upload(
    s: Session,
    id: int,
) -> Upload:
    """Get an upload by ID."""
    res = s.get(f"{HOST}/uploads/{id}/")
    assert res.status_code == 200, log_response(res)
    return parse_upload_json(res.json())


def edit_upload(
    s: Session,
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
    res = s.put(f"{HOST}/uploads/{id}/", json=body)
    assert res.status_code == 200, log_response(res)
    return parse_upload_json(res.json())


def delete_upload(s: Session, id: int) -> None:
    """Delete an upload by ID."""
    res = s.delete(f"{HOST}/uploads/{id}/")
    assert res.status_code == 204, log_response(res)


def create_upload_url(
    s: Session,
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
    res = s.post(url=f"{HOST}/uploads/", json=body)
    assert res.status_code == 201, log_response(res)
    j = res.json()
    # replace underscores with hyphens
    fields = j["fields"]
    for old_key in list(fields):
        new_key = old_key.replace("_", "-")
        fields[new_key] = fields.pop(old_key)
    return j["id"], j["url"], fields


def create_upload(
    s: Session,
    path_to_file: str,
    display_title: str,
    bucket_id: int,
    visibility: VisibilitySetting,
) -> Upload:
    """Upload a file, convert to stream_ready, and return that upload model."""
    filename = os.path.basename(path_to_file)
    id, presigned_url, fields = create_upload_url(
        s, filename, display_title, bucket_id, visibility
    )
    with open(path_to_file, "rb") as f:
        files = {"file": (filename, f)}
        upload_res = s.post(presigned_url, data=fields, files=files)
        assert (
            upload_res.status_code == 204
        ), "Failed to upload file to presigned URL!"

    # Convert to stream_ready
    create_url_res = s.post(url=f"{HOST}/uploads/{id}/convert/")
    assert create_url_res.status_code == 200
    return get_upload(s, id)


def get_download_url(s: Session, upload_id: int) -> str:
    """Get a presigned URL to download a specified upload."""
    res = s.get(f"{HOST}/uploads/{upload_id}/download/")
    assert res.status_code == 200, log_response(res)
    return res.json()["url"]


def get_all_comments(
    s: Session, upload_id: int | None = None
) -> list[Comment]:
    """Get all comments authored by the current user."""
    params = dict()
    if upload_id is not None:
        params["upload"] = upload_id
    res = s.get(f"{HOST}/comments", params=params)
    assert res.status_code == 200
    return [parse_comment_json(c) for c in res.json()]


def create_comment(s: Session, text: str, upload_id: int) -> Comment:
    """Create a comment under an upload."""
    body = {"text": text, "upload_id": upload_id}
    res = s.post(f"{HOST}/comments/", json=body)
    assert res.status_code == 201
    return parse_comment_json(res.json())


def delete_comment(s: Session, comment_id: int) -> None:
    """Delete a comment by ID."""
    res = s.delete(f"{HOST}/comments/{comment_id}/")
    assert res.status_code == 204


def create_bucket(s: Session, name: str) -> Bucket:
    """Create a bucket under the current user."""
    res = s.post(f"{HOST}/buckets/", json={"name": name})
    assert res.status_code == 201
    return parse_bucket_json(res.json())


def get_all_buckets(s: Session, user_id: int | None) -> list[Bucket]:
    """Get a list of all buckets owned by any user."""
    params = dict()
    if user_id is not None:
        params["user"] = user_id
    res = s.get(f"{HOST}/buckets", params=params)
    assert res.status_code == 200
    return [parse_bucket_json(b) for b in res.json()]


def edit_bucket(s: Session, bucket_id: int, name: str | None) -> Bucket:
    """Update the properties of a bucket."""
    body = dict()
    if name is not None:
        body["name"] = name
    res = s.put(f"{HOST}/buckets/{bucket_id}/", json=body)
    assert res.status_code == 200
    return parse_bucket_json(res.json())


def delete_bucket(s: Session, bucket_id: int) -> None:
    """Delete a bucket by ID."""
    res = s.delete(f"{HOST}/buckets/{bucket_id}/")
    assert res.status_code == 204


def create_courtship_req(
    s: Session, other_id: int, type: str
) -> CourtshipRequest:
    """Create a courtship request of a certain type to another user."""
    body = {"user_id": other_id, "type": type}
    res = s.post(f"{HOST}/courtships/requests/", json=body)
    assert res.status_code == 201
    return parse_courtship_req_json(res.json())


def get_courtship_reqs(
    s: Session,
    type: str | None = None,
    dir: str | None = None,
    users: Iterable[int] | None = None,
) -> list[CourtshipRequest]:
    """Get all courtship requests involving the current user."""
    params = dict()
    if type is not None:
        params["type"] = type
    if dir is not None:
        params["dir"] = dir
    if users is not None:
        params["users"] = ",".join(str(id) for id in users)
    res = s.get(f"{HOST}/courtships/requests", params=params)
    assert res.status_code == 200
    return [parse_courtship_req_json(cr) for cr in res.json()]


def update_incoming_court_req(s: Session, other_id: int, status: str) -> None:
    """Respond to an incoming courtship request."""
    res = s.put(
        f"{HOST}/courtships/requests/{other_id}/", json={"status": status}
    )
    assert res.status_code == 204


def delete_outgoing_court_req(s: Session, other_id: int) -> None:
    """Delete an outgoing courtship request."""
    res = s.delete(f"{HOST}/courtships/requests/{other_id}/")
    assert res.status_code == 204


def get_all_courtships(
    s: Session, type: str | None = None, users: Iterable[int] | None = None
) -> list[Courtship]:
    """Get all established courtships involving the current user."""
    params = dict()
    if type is not None:
        params["type"] = type
    if users is not None:
        params["users"] = ",".join(str(id) for id in users)
    res = s.get(f"{HOST}/courtships", params=params)
    assert res.status_code == 200
    return [parse_courtship_json(c) for c in res.json()]


def delete_courtship(s: Session, other_id: int) -> None:
    """Delete an established courtship by ID."""
    res = s.delete(f"{HOST}/courtships/{other_id}/")
    assert res.status_code == 204
