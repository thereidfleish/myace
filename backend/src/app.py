#!/usr/bin/env python3
import datetime
import json
import os
import re

from typing import Optional, Dict, Any, TypedDict

from aws import AWS
from cookiesigner import CookieSigner

from flask import Flask
from flask import make_response
from flask import send_file
from flask import request
import flask_login

from models import User
from models import UserRelationship
from models import RelationshipType
from models import Upload
from models import Comment
from models import Bucket
from models import VisibilityDefault
from models import db
from models import visib_of_str, rel_req_of_str

from sqlalchemy import or_
from sqlalchemy import and_

from google.oauth2 import id_token
from google.auth.transport import requests

app = Flask(__name__)
db.init_app(app)

login_manager = flask_login.LoginManager()
login_manager.init_app(app)

# constants
ENV = "dev"
AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
# replace line delimeter characters '\n' with newlines and convert to bytes
CF_PRIVATE_KEY = (
    os.environ["CF_PRIVATE_KEY"].replace("\\n", "\n").encode("utf-8")
)
CF_PUBLIC_KEY_ID = os.environ["CF_PUBLIC_KEY_ID"]
DB_ENDPOINT = os.environ["DB_ENDPOINT"]
DB_NAME = os.environ["DB_NAME"]
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_USERNAME = os.environ["DB_USERNAME"]
G_CLIENT_IDS = os.environ["G_CLIENT_IDS"].split(",")
S3_CF_DOMAIN = os.environ["S3_CF_DOMAIN"]
S3_CF_SUBDOMAIN = os.environ["S3_CF_SUBDOMAIN"]
VIEW_DOCS_KEY = os.environ.get("VIEW_DOCS_KEY") or os.urandom(24)
app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.urandom(24)

# To use on your local machine, you must configure postgres at port 5432 and put your credentials in your .env.
app.config[
    "SQLALCHEMY_DATABASE_URI"
] = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
app.config["SQLALCHEMY_ECHO"] = ENV == "dev"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)
with app.app_context():
    db.create_all()

# global AWS instance
aws = AWS(
    AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, CF_PUBLIC_KEY_ID, CF_PRIVATE_KEY
)


def success_response(data={}, code=200):
    return json.dumps(data), code


def failure_response(message, code=404):
    return json.dumps({"error": message}), code


# Flask-Login callbacks
@login_manager.user_loader
def load_user(user_id):
    # Return user object if user exists or None if DNE
    user = User.query.filter_by(id=user_id).first()
    return user


@login_manager.unauthorized_handler
def unauthorized():
    return failure_response("User not authorized.", 401)


# Routes
@app.route("/health/")
def health_check():
    return success_response({"status": "OK"})


@app.route("/host/")
def get_host():
    return request.host_url


@app.route("/docs")
def docs():
    key = request.args.get("key")
    if key != VIEW_DOCS_KEY:
        return failure_response("Invalid key!", 401)
    return send_file("docs.html")


@app.route("/login/", methods=["POST"])
def login():
    """
    SwingVision behavior:
    - When I sign in via Oauth to an account made by email, I am logged into that account.
      - IMO this is a security risk. If an actor compromises a target's Twitter account, for example, they have access to the SwingVision platform.
    - When I sign up with an email connected to an Oauth account, 500 internal server error.
    - Email addresses are immutable

    I believe our login behavior should look like this:
    - When I sign in via Oauth to an account made by email, I get an error like "This account was registered with email/password" and then prompt a password.
    - When I sign up with an email connected to an Oauth account, I get an error like "This email address is already used by an account using Google sign-on"
    - For now, email addresses are immutable
    """
    body = json.loads(request.data)

    # Validate google auth
    token = body.get("token")
    if token is None:
        return failure_response("Missing token.", 400)

    # Check if the token will verify with any of the specified oauth tokens
    valid = False
    for id in G_CLIENT_IDS:
        try:
            idinfo = id_token.verify_oauth2_token(
                token, requests.Request(), G_CLIENT_IDS
            )
            valid = True
            break
        except ValueError:
            pass  # don't set valid to True

    if not valid:
        return failure_response(
            "Could not authenticate user. Unauthorized.", 401
        )

    gid = idinfo.get("sub")
    email = idinfo.get("email")
    display_name = idinfo.get("name")

    if gid is None or email is None or display_name is None:
        return failure_response(
            "Could not retrieve required fields (Google Account ID, email, and name) from"
            "Google token. Unauthorized.",
            401,
        )

    # Check if user exists
    user = User.query.filter_by(google_id=gid).first()
    user_created = user is None

    if user is None:
        # User does not exist, add them.
        user = User(google_id=gid, display_name=display_name, email=email)
        db.session.add(user)
        db.session.commit()

    # Begin user session
    flask_login.login_user(user, remember=True)

    return success_response(
        user.serialize(show_private=True), 201 if user_created else 200
    )


@app.route("/logout/", methods=["POST"])
@flask_login.login_required
def logout():
    flask_login.logout_user()
    return success_response()


@app.route("/users/me/")
@flask_login.login_required
def get_me():
    return success_response(
        flask_login.current_user.serialize(show_private=True)
    )


@app.route("/users/me/", methods=["PUT"])
@flask_login.login_required
def edit_me():
    user = flask_login.current_user

    body = json.loads(request.data)

    # Update username if it changed
    new_username = body.get("username")
    if new_username is not None and user.username != new_username:
        # Check for valid username
        new_username = new_username.lower()
        # Check username length
        if len(new_username) <= 2:
            return failure_response(
                "Username must be at least 3 characters long.", 400
            )
        # Check if username contains illegal characters
        regexp = re.compile(User.ILLEGAL_UNAME_PATTERN)
        illegal_match = regexp.search(new_username)
        if illegal_match:
            return failure_response(
                f"Username contains illegal character '{illegal_match.group(0)}'.",
                400,
            )
        # Check if username exists
        if not User.is_username_unique(new_username):
            return failure_response(f"Username already exists.", 409)
        user.username = new_username

    # Update display name if it changed
    new_display_name = body.get("display_name")
    if new_display_name is not None and user.display_name != new_display_name:
        if new_display_name.isspace():
            return failure_response("Invalid display name.", 400)
        user.display_name = new_display_name

    db.session.commit()
    return success_response(user.serialize(show_private=True))


@app.route("/uploads")
@flask_login.login_required
def get_all_uploads():
    me = flask_login.current_user
    user_id = request.args.get("user")
    if user_id is None:
        # Default behavior: get my uploads
        uploads = Upload.query.filter_by(user_id=me.id)
    else:
        # Optionally filter by user ID
        uploads = Upload.query.filter_by(user_id=user_id)

    # Optionally filter by bucket
    bucket_id = request.args.get("bucket")
    if bucket_id is not None:
        uploads = uploads.filter_by(bucket_id=bucket_id)

    return success_response(
        {
            "uploads": [
                up.serialize(aws) for up in uploads if me.can_view_upload(up)
            ]
        }
    )


@app.route("/uploads/<int:upload_id>/")
@flask_login.login_required
def get_upload(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    user = flask_login.current_user
    if not user.can_view_upload(upload):
        return failure_response("User forbidden to view upload.", 403)

    # Create response
    response = upload.serialize(aws)

    if upload.stream_ready:
        signer = CookieSigner(
            aws=aws, expiration_in_hrs=1, cf_key_id=CF_PUBLIC_KEY_ID
        )
        url = (
            "https://"
            + S3_CF_SUBDOMAIN
            + "."
            + S3_CF_DOMAIN
            + "/uploads/"
            + str(upload_id)
            + "/hls/"
        )
        cookies = signer.generate_signed_cookies(url=(url + "*"))
        response["url"] = url + "index.m3u8"
        response = make_response(response)
        response.set_cookie(
            key="CloudFront-Policy",
            value=cookies["CloudFront-Policy"],
            domain=S3_CF_DOMAIN,
            secure=True,
        )
        response.set_cookie(
            key="CloudFront-Signature",
            value=cookies["CloudFront-Signature"],
            domain=S3_CF_DOMAIN,
            secure=True,
        )
        response.set_cookie(
            key="CloudFront-Key-Pair-Id",
            value=cookies["CloudFront-Key-Pair-Id"],
            domain=S3_CF_DOMAIN,
            secure=True,
        )
        return response

    return success_response(response)


class BadRequest(Exception):
    """Representative of the 400 HTTP response code"""


class VisibilityReq(TypedDict):
    """The request body of a visibility field. A uniform typed dictionary"""

    default: str
    also_shared_with: list[int]


def parse_visibility_req(
    visibility: VisibilityReq,
) -> tuple[VisibilityDefault, list[User]]:
    """Parse the "visibility" request obj.

    :return: a VisibilityDefault and a list of users with whom an upload is individually shared
    :raise BadRequest: if the body is incorrectly formatted
    """
    if visibility is None:
        raise BadRequest("Missing visibility.")
    t = visibility.get("default")
    default = visib_of_str(t)
    if default is None:
        raise BadRequest("Invalid default visibility.")
    also_shared_ids = visibility.get("also_shared_with")
    if also_shared_ids is None:
        raise BadRequest("Missing also_shared_with.")
    also_shared_users = User.get_users_by_ids(also_shared_ids)
    invalid_ids = set(also_shared_ids) - set([id for id in also_shared_ids])
    if len(invalid_ids) > 0:
        raise BadRequest(
            "Invalid also_shared_with. Contains invalid user IDs."
        )
    return default, also_shared_users


@app.route("/uploads/", methods=["POST"])
@flask_login.login_required
def create_upload_url():
    user = flask_login.current_user

    # Check for valid fields
    body = json.loads(request.data)
    filename = body.get("filename")
    if filename is None or filename.isspace():
        return failure_response("Invalid filename.", 400)
    display_title = body.get("display_title")
    if display_title is None or display_title.isspace():
        return failure_response("Invalid display title.", 400)
    bucket_id = body.get("bucket_id")
    if bucket_id is None:
        return failure_response("Missing bucket id.", 400)
    bucket = Bucket.query.filter_by(id=bucket_id).first()
    if bucket is None:
        return failure_response("Bucket not found.")
    if not user.can_modify_bucket(bucket):
        return failure_response("User forbidden to modify bucket.", 403)
    # parse visibility field
    visibility = body.get("visibility")
    try:
        vis_default, shared_with = parse_visibility_req(visibility)
    except BadRequest as b:
        return failure_response(b, 400)

    # Create upload
    new_upload = Upload(
        filename=filename,
        display_title=display_title,
        user_id=user.id,
        bucket_id=bucket_id,
        visibility=vis_default,
    )
    db.session.add(new_upload)
    db.session.commit()
    # Share upload
    new_upload.share_with(shared_with)

    # Create upload URL
    res = {"id": new_upload.id}
    urldata = aws.get_presigned_url_post(new_upload.id, filename)

    # Replace hyphens in field names with underscores
    # because Swift cannot decode fields with hyphens
    for old_key in list(urldata["fields"]):
        new_key = old_key.replace("-", "_")
        urldata["fields"][new_key] = urldata["fields"].pop(old_key)

    res.update(urldata)
    return success_response(res, 201)


@app.route("/uploads/<int:upload_id>/convert/", methods=["POST"])
@flask_login.login_required
def start_convert(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    user = flask_login.current_user
    if not user.can_modify_upload(upload):
        return failure_response("User forbidden to modify upload.", 403)

    # create convert job
    convert_job_id = aws.create_mediaconvert_job(upload_id, upload.filename)
    upload.mediaconvert_job_id = convert_job_id
    db.session.commit()

    return success_response()


@app.route("/uploads/<int:upload_id>/", methods=["PUT"])
@flask_login.login_required
def edit_upload(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    user = flask_login.current_user
    if not user.can_modify_upload(upload):
        return failure_response("User forbidden to modify upload.", 403)

    body = json.loads(request.data)

    # Update title
    new_title = body.get("display_title")
    if new_title is not None and upload.display_title != new_title:
        if new_title.isspace():
            return failure_response("Invalid title.", 400)
        upload.display_title = new_title

    # Update bucket
    new_bucket_id = body.get("bucket_id")
    if new_bucket_id is not None and upload.bucket_id != new_bucket_id:
        bucket = Bucket.query.filter_by(id=new_bucket_id).first()
        if bucket is None:
            return failure_response("Bucket not found.")
        if not user.can_modify_bucket(bucket):
            return failure_response("User forbidden to modify bucket.", 403)
        upload.bucket_id = new_bucket_id

    # Update visibility settting
    visibility = body.get("visibility")
    if visibility is not None:
        try:
            vis_default, shared_with = parse_visibility_req(visibility)
            upload.visibility = vis_default
            upload.unshare_with_all()
            upload.share_with(shared_with)
        except BadRequest as b:
            return failure_response(b, 400)

    db.session.commit()
    return success_response(upload.serialize(aws))


@app.route("/uploads/<int:upload_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_upload(upload_id):
    # Verify user and existence of upload.
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found in database.")

    user = flask_login.current_user
    if not user.can_modify_upload(upload):
        return failure_response("User forbidden to modify upload.", 403)

    # Delete upload
    db.session.delete(upload)
    aws.delete_uploads(upload_id)
    db.session.commit()

    return success_response(code=204)


@app.route("/uploads/<int:upload_id>/download/")
@flask_login.login_required
def get_download_url(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")
    user = flask_login.current_user
    if not user.can_view_upload(upload):
        return failure_response("User forbidden to view upload.", 403)
    return success_response(
        {
            "url": aws.get_upload_url(
                upload.id, upload.filename, expiration_in_hours=1
            )
        }
    )


# TODO: autodetect S3 uploads
# @app.route("/api/callback/s3upload/", methods=['POST'])
# def upload_callback():
#     """Called by AWS after a successful upload to the S3 bucket"""
#     # TODO: create mediaconvert job and add upload to database
#     pass


@app.route("/comments")
@flask_login.login_required
def get_all_comments():
    user = flask_login.current_user
    # Check for optional query params
    upload_id = request.args.get("upload")
    if upload_id is None:
        # Default behavior. Get all comments authored by user
        # I could use 'user.comments' here but the InstrumentedList obj does not
        # allow chaining filtering like the Query obj
        comments = Comment.query.filter_by(author_id=user.id)
    else:
        # Get all comments under upload ID
        upload = Upload.query.filter_by(id=upload_id).first()
        if upload is None:
            return failure_response("Upload not found.")
        if not user.can_view_upload(upload):
            return failure_response("User forbidden to view upload.", 403)
        comments = Comment.query.filter_by(upload_id=upload.id)
    # Optionally filter by courtship
    # TODO: fix filtering comments by courtship
    # user_type = request.args.get("courtship", type=str)
    # if user_type is not None:
    #     if user_type != "0" and user_type != "1":
    #         return failure_response("Invalid user type.", 400)
    #     comments = comments.join(Comment.author, aliased=True).filter_by(type=user_type)

    # Create response
    return success_response(
        {
            "comments": [
                c.serialize() for c in comments if user.can_view_comment(c)
            ]
        }
    )


@app.route("/comments/", methods=["POST"])
@flask_login.login_required
def create_comment():
    # Check for valid fields
    body = json.loads(request.data)

    # Check for valid upload
    upload_id = body.get("upload_id")
    if upload_id is None:
        return failure_response("Missing upload ID.", 400)
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")

    # Check for valid author
    author = flask_login.current_user
    # Check if user is allowed to comment
    if not author.can_comment_on_upload(upload):
        return failure_response("User forbidden to comment on upload.", 403)

    # Check for valid text
    text = body.get("text")
    if text is None or text.isspace():
        return failure_response("Invalid comment text.", 400)

    # Create comment row
    comment = Comment(author_id=author.id, upload_id=upload_id, text=text)
    db.session.add(comment)
    db.session.commit()

    return success_response(comment.serialize(), 201)


@app.route("/comments/<int:comment_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_comment(comment_id):
    # Check for valid comment
    comment = Comment.query.filter_by(id=comment_id).first()
    if comment is None:
        return failure_response("Comment not found.")

    # Check that user is allowed to delete comment
    user = flask_login.current_user
    if not user.can_modify_comment(comment):
        return failure_response("User forbidden to modify comment.", 403)

    # Delete
    # Note that deleting like this respects the cascades defined at the ORM level
    # Comment.query.filter_by(...).delete() does not respect cascades!
    db.session.delete(comment)
    db.session.commit()

    return success_response(code=204)


@app.route("/buckets/", methods=["POST"])
@flask_login.login_required
def create_bucket():
    user = flask_login.current_user

    # Get name from request body
    body = json.loads(request.data)
    name = body.get("name")
    if name is None:
        return failure_response(
            "Could not get bucket name from request body.", 400
        )

    if Bucket.query.filter_by(name=name, user_id=user.id).first() is not None:
        return failure_response("A bucket of this name already exists.", 400)

    # Create the bucket
    bucket = Bucket(user_id=user.id, name=name)
    db.session.add(bucket)
    db.session.commit()

    return success_response(bucket.serialize(), 201)


@app.route("/buckets")
@flask_login.login_required
def get_buckets():
    me = flask_login.current_user
    user_id = request.args.get("user")
    if user_id is None:
        # Default behavior: get my buckets
        buckets = Bucket.query.filter_by(user_id=me.id)
    else:
        # Optionally filter by user ID
        buckets = Bucket.query.filter_by(user_id=user_id)

    return success_response(
        {"buckets": [b.serialize() for b in buckets if me.can_view_bucket(b)]}
    )


@app.route("/buckets/<int:bucket_id>/", methods=["PUT"])
@flask_login.login_required
def edit_bucket(bucket_id):
    user = flask_login.current_user
    bucket = Bucket.query.filter_by(id=bucket_id, user_id=user.id).first()

    if bucket is None:
        return failure_response("Bucket by user not found.")

    if not user.can_modify_bucket(bucket):
        return failure_response("User forbidden to modify bucket.", 403)

    body = json.loads(request.data)

    # Update name
    new_name = body.get("name")
    if new_name is not None and bucket.name != new_name:
        if new_name.isspace():
            return failure_response("Invalid title.", 400)
        if (
            Bucket.query.filter_by(name=new_name, user_id=user.id).first()
            is not None
        ):
            return failure_response(
                "A bucket of this name already exists.", 400
            )
        bucket.name = new_name

    db.session.commit()
    return success_response(bucket.serialize())


@app.route("/buckets/<int:bucket_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_bucket(bucket_id):
    user = flask_login.current_user
    # Check for valid bucket
    bucket = Bucket.query.filter_by(id=bucket_id, user_id=user.id).first()
    if bucket is None:
        return failure_response("Bucket by user not found.")

    # Check that user is allowed to delete bucket
    if not user.can_modify_bucket(bucket):
        return failure_response("User forbidden to modify bucket.", 403)

    # Delete bucket and associated uploads
    # Note that deleting like this respects the cascades defined at the ORM level
    # Bucket.query.filter_by(...).delete() does not respect cascades!
    aws.delete_uploads(bucket.uploads)
    db.session.delete(bucket)
    db.session.commit()

    return success_response(code=204)


@app.route("/users/search")
@flask_login.login_required
def search_users():
    me = flask_login.current_user
    # Check for query params
    query = request.args.get("q")
    if query is None:
        return failure_response("Missing query URL parameter.", 400)
    # Search
    found = User.query.filter(User.username.startswith(query))
    # Exclude current user from search results
    return success_response(
        {"users": [u.serialize() for u in found if u != me]}
    )


@app.route("/courtships/requests/", methods=["POST"])
@flask_login.login_required
def create_courtship_request():
    me = flask_login.current_user

    # Check for valid request body
    body = json.loads(request.data)
    other_id = body.get("user_id")
    if other_id is None:
        return failure_response(
            "Could not get user ID from request body.", 400
        )
    other = User.query.filter_by(id=other_id).first()
    if other is None:
        return failure_response("User not found.")

    type = body.get("type")
    type = rel_req_of_str(body.get("type"))
    if type is None:
        return failure_response("Invalid type.", 400)
    courtship = UserRelationship(
        user_a_id=me.id, user_b_id=other.id, type=type
    )

    # Check if user is allowed to create courtship request
    # TODO: add support for blocking users
    if other_id == me.id:
        return failure_response("Cannot court yourself.", 400)
    if me.get_relationship_with(other.id) is not None:
        return failure_response(
            "A courtship already exists with this user.", 400
        )

    # Create courtship request
    db.session.add(courtship)
    db.session.commit()

    return success_response(courtship.serialize(me), code=201)


@app.route("/courtships/requests")
@flask_login.login_required
def get_courtship_requests():
    me = flask_login.current_user
    # Get all UserRelationships involving the user
    courtships = UserRelationship.query.filter(
        or_(
            UserRelationship.user_a_id == me.id,
            UserRelationship.user_b_id == me.id,
        )
    )
    # filter relationships to courtship requests only
    courtships = courtships.filter(
        or_(
            UserRelationship.type == RelationshipType.FRIEND_REQUESTED,
            UserRelationship.type == RelationshipType.COACH_REQUESTED,
            UserRelationship.type == RelationshipType.STUDENT_REQUESTED,
        )
    )
    # Optionally filter by request type
    type = request.args.get("type", type=str)
    if type is not None:
        # Ensure type string is valid enum
        type = rel_req_of_str(type)
        if type is None:
            return failure_response("Invalid request type.", 400)
        courtships = courtships.filter_by(type=type)

    # Optionally filter by request direction
    direction = request.args.get("dir", type=str)
    if direction is not None:
        if direction == "in":
            courtships = courtships.filter_by(user_b_id=me.id)
        elif direction == "out":
            courtships = courtships.filter_by(user_a_id=me.id)
        else:
            return failure_response("Invalid dir.", 400)

    # Optionally filter by user IDs
    user_ids_str = request.args.get("users", type=str)
    if user_ids_str is not None:
        # TODO: fix filtering courtship requests by UIDs
        user_ids = user_ids_str.split(",")
        courtships = courtships.filter(
            or_(
                and_(
                    UserRelationship.user_a_id != me.id,
                    UserRelationship.user_a_id.in_(user_ids),
                ),
                and_(
                    UserRelationship.user_b_id != me.id,
                    UserRelationship.user_b_id.in_(user_ids),
                ),
            )
        )

    return success_response(
        {"requests": [c.serialize(me) for c in courtships]}
    )


@app.route("/courtships/requests/<int:other_user_id>/", methods=["PUT"])
@flask_login.login_required
def update_incoming_courtship_request(other_user_id):
    me = flask_login.current_user

    # Verify incoming courtship request exists
    rel = me.get_relationship_with(other_user_id)
    if rel is None or not rel.type.is_request() or rel.user_b_id != me.id:
        return failure_response("Incoming courtship request not found.", 404)

    # Check for valid request body
    body = json.loads(request.data)
    status = body.get("status")
    if status is None:
        return failure_response("Could not get status from request body.", 400)

    # Change relationship status
    if status == "accept":
        assert rel.user_b_id == me.id, "Cannot accept an outgoing request!"

        # User A requests that current_user becomes his friend.
        if rel.type == RelationshipType.FRIEND_REQUESTED:
            rel.type = RelationshipType.FRIENDS

        # User A requests that current_user becomes his student.
        elif rel.type == RelationshipType.STUDENT_REQUESTED:
            rel.type = RelationshipType.A_COACHES_B

        # User A requests that current_user becomes his coach.
        else:
            # Swap user A and user B
            swap = rel.user_a_id
            rel.user_a_id = rel.user_b_id
            rel.user_b_id = swap
            rel.type = RelationshipType.A_COACHES_B

        rel.last_changed = datetime.datetime.utcnow()
    elif status == "decline":
        # Delete relationship
        db.session.delete(rel)
    else:
        return failure_response("Invalid status.", 400)

    db.session.commit()
    return success_response(code=204)


@app.route("/courtships/requests/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_outgoing_courtship_request(other_user_id):
    user = flask_login.current_user

    # Verify outgoing courtship request exists
    rel = user.get_relationship_with(other_user_id)
    if rel is None or not rel.type.is_request() or rel.user_a_id != user.id:
        return failure_response("Outgoing courtship request not found.", 404)

    # Delete relationship
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)


@app.route("/courtships")
@flask_login.login_required
def get_all_courtships():
    me = flask_login.current_user
    # Get all UserRelationships involving the user
    courtships = UserRelationship.query.filter(
        or_(
            UserRelationship.user_a_id == me.id,
            UserRelationship.user_b_id == me.id,
        )
    )
    # filter relationships to courtships only (no requests)
    courtships = courtships.filter(
        or_(
            UserRelationship.type == RelationshipType.FRIENDS,
            UserRelationship.type == RelationshipType.A_COACHES_B,
        )
    )
    # Optionally filter by courtship type
    type = request.args.get("type", type=str)
    if type is not None:
        if type == "friend":
            courtships = courtships.filter_by(type=RelationshipType.FRIENDS)
        elif type == "coach":
            courtships = courtships.filter_by(
                type=RelationshipType.A_COACHES_B, user_b_id=me.id
            )
        elif type == "student":
            courtships = courtships.filter_by(
                type=RelationshipType.A_COACHES_B, user_a_id=me.id
            )
        else:
            return failure_response("Invalid type.", 400)

    # Optionally filter by user ID
    user_ids_str = request.args.get("users", type=str)
    if user_ids_str is not None:
        user_ids = user_ids_str.split(",")
        # TODO: fix filtering courtships by UIDs
        courtships = courtships.filter(
            or_(
                and_(
                    UserRelationship.user_a_id != me.id,
                    UserRelationship.user_a_id.in_(user_ids),
                ),
                and_(
                    UserRelationship.user_b_id != me.id,
                    UserRelationship.user_b_id.in_(user_ids),
                ),
            )
        )

    return success_response(
        {"courtships": [c.serialize(me) for c in courtships]}
    )


@app.route("/courtships/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def remove_courtship(other_user_id):
    user = flask_login.current_user

    # Verify courtship exists
    rel = user.get_relationship_with(other_user_id)
    if rel is None or rel.type not in (
        RelationshipType.FRIENDS,
        RelationshipType.A_COACHES_B,
    ):
        return failure_response("Courtship not found.", 404)

    # Delete courtship 💔
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)
