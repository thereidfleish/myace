#!/usr/bin/env python3
import datetime
import json
import os
import re

import media
from cookiesigner import CookieSigner

from botocore.client import Config

from flask import Flask
from flask import request
from flask import make_response
import flask_login

from db import User
from db import UserRelationship
from db import RelationshipType
from db import Upload
from db import Comment
from db import Bucket
from db import db

from google.oauth2 import id_token
from google.auth.transport import requests

app = Flask(__name__)

login_manager = flask_login.LoginManager()
login_manager.init_app(app)

# constants
ENV = "dev"
AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
CF_PRIVATE_KEY_FILE = os.environ.get("CF_PRIVATE_KEY_FILE")
CF_PUBLIC_KEY_ID = os.environ.get("CF_PUBLIC_KEY_ID")
DB_ENDPOINT = os.environ.get("DB_ENDPOINT")
DB_NAME = os.environ.get("DB_NAME")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_USERNAME = os.environ.get("DB_USERNAME")
G_CLIENT_ID = os.environ.get("G_CLIENT_ID")
S3_CF_DOMAIN = os.environ.get("S3_CF_DOMAIN")
S3_CF_SUBDOMAIN = os.environ.get("S3_CF_SUBDOMAIN")
app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.urandom(24)

# To use on your local machine, you must configure postgres at port 5432 and put your credentials in your .env.
app.config["SQLALCHEMY_DATABASE_URI"] = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
app.config["SQLALCHEMY_ECHO"] = ENV == "dev"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)
with app.app_context():
    db.create_all()

# global AWS instance
aws = media.AWS(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, CF_PUBLIC_KEY_ID, CF_PRIVATE_KEY_FILE)


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


@app.route("/login/", methods=["POST"])
def login():
    body = json.loads(request.data)

    # Validate type
    user_type = body.get("type")
    if user_type is None:
        return failure_response("Missing type.", 400)
    if not (user_type == 0 or user_type == 1):
        return failure_response("Invalid type.", 400)

    # Validate google auth
    token = body.get("token")
    if token is None:
        return failure_response("Missing token.", 400)

    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), G_CLIENT_ID)

        gid = idinfo.get("sub")
        email = idinfo.get("email")
        display_name = idinfo.get("name")

        if gid is None or email is None or display_name is None:
            return failure_response("Could not retrieve required fields (Google Account ID, email, and name) from"
                                    "Google token. Unauthorized.", 401)

        # Check if user exists
        user = User.query.filter_by(google_id=gid, type=user_type).first()
        user_created = user is None

        if user is None:
            # User does not exist, add them.
            user = User(google_id=gid, display_name=display_name, email=email, type=user_type)
            db.session.add(user)
            db.session.commit()

        # Begin user session
        flask_login.login_user(user, remember=True)

        return success_response(user.serialize(show_private=True), 201 if user_created else 200)

    except ValueError:
        return failure_response("Could not authenticate user. Unauthorized.", 401)


@app.route("/logout/", methods=["POST"])
@flask_login.login_required
def logout():
    flask_login.logout_user()
    return success_response()


@app.route("/users/me/")
@flask_login.login_required
def get_me():
    return success_response(flask_login.current_user.serialize(show_private=True))


@app.route("/users/me/", methods=['PUT'])
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
            return failure_response("Username must be at least 3 characters long.", 400)
        # Check if username contains illegal characters
        regexp = re.compile(User.ILLEGAL_UNAME_PATTERN)
        illegal_match = regexp.search(new_username)
        if illegal_match:
            return failure_response(f"Username contains illegal character '{illegal_match.group(0)}'.", 400)
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
    user = flask_login.current_user
    uploads = Upload.query.filter_by(user_id=user.id)

    # Optionally filter by bucket
    bucket_id = request.args.get("bucket")
    if bucket_id is not None:
        uploads = uploads.filter_by(bucket_id=bucket_id)

    return success_response({"uploads": [up.serialize(aws) for up in uploads]})


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
        signer = CookieSigner(aws=aws, expiration_in_hrs=1, cf_key_id=CF_PUBLIC_KEY_ID)
        url = "https://" + S3_CF_SUBDOMAIN + "." + S3_CF_DOMAIN + "/uploads/" + str(upload_id) + "/hls/"
        cookies = signer.generate_signed_cookies(url=(url+"*"))
        response['url'] = url + "index.m3u8"
        response = make_response(response)
        response.set_cookie(key='CloudFront-Policy', value=cookies['CloudFront-Policy'],
                            domain=S3_CF_DOMAIN, secure=True)
        response.set_cookie(key='CloudFront-Signature', value=cookies['CloudFront-Signature'],
                            domain=S3_CF_DOMAIN, secure=True)
        response.set_cookie(key='CloudFront-Key-Pair-Id', value=cookies['CloudFront-Key-Pair-Id'],
                            domain=S3_CF_DOMAIN, secure=True)
        return response

    return success_response(response)


@app.route("/uploads/", methods=['POST'])
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
        return failure_response("Missing bucket id.")
    bucket = Bucket.query.filter_by(id=bucket_id).first()
    if bucket is None:
        return failure_response("Bucket not found.")
    if not user.can_modify_bucket(bucket):
        return failure_response("User forbidden to modify bucket.", 403)

    # Create upload row
    new_upload = Upload(filename=filename, display_title=display_title, user_id=user.id, bucket_id=bucket_id)
    db.session.add(new_upload)
    db.session.commit()

    # Create upload URL
    res = {'id': new_upload.id}
    urldata = aws.get_presigned_url_post(new_upload.id, filename)

    # Replace hyphens in field names with underscores 
    # because Swift cannot decode fields with hyphens
    for old_key in list(urldata['fields']):
        new_key = old_key.replace('-', '_')
        urldata['fields'][new_key] = urldata['fields'].pop(old_key)

    res.update(urldata)
    return success_response(res, 201)


@app.route("/uploads/<int:upload_id>/convert/", methods=['POST'])
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


@app.route("/uploads/<int:upload_id>/", methods=['PUT'])
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

    db.session.commit()
    return success_response(upload.serialize(aws))


@app.route("/uploads/<int:upload_id>/", methods=['DELETE'])
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
    found = aws.delete_uploads(upload_id)
    db.session.commit()

    # Alert client of inconsistency if present.
    return success_response(code=204) if found else success_response(data={'message': 'Found entry in database but not in S3.'}, code=200)


@app.route("/uploads/<int:upload_id>/download/")
@flask_login.login_required
def get_download_url(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")
    user = flask_login.current_user
    if not user.can_view_upload(upload):
        return failure_response("User forbidden to view upload.", 403)
    return success_response({"url": aws.get_upload_url(upload.id, upload.filename, expiration_in_hours=1)})


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
    # Optionally filter by user type
    user_type = request.args.get("user-type", type=str)
    if user_type is not None:
        if user_type != "0" and user_type != "1":
            return failure_response("Invalid user type.", 400)
        comments = comments.join(Comment.author, aliased=True).filter_by(type=user_type)

    # Create response
    return success_response({"comments": [c.serialize() for c in comments if user.can_view_comment(c)]})


@app.route("/comments/", methods=['POST'])
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


@app.route("/comments/<int:comment_id>/", methods=['DELETE'])
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


@app.route("/buckets/", methods=['POST'])
@flask_login.login_required
def create_bucket():
    user = flask_login.current_user

    # Get name from request body
    body = json.loads(request.data)
    name = body.get("name")
    if name is None:
        return failure_response("Could not get bucket name from request body.", 400)

    # Create the bucket
    bucket = Bucket(user_id=user.id, name=name)
    db.session.add(bucket)
    db.session.commit()

    return success_response(bucket.serialize(), 201)


@app.route("/buckets/")
@flask_login.login_required
def get_buckets():
    user = flask_login.current_user
    return success_response({"buckets": [b.serialize() for b in user.buckets]})


@app.route("/users/search")
@flask_login.login_required
def search_users():
    # Check for query params
    query = request.args.get("query")
    if query is None:
        return failure_response("Missing query URL parameter.", 400)
    # Search
    users = []
    found = User.query.filter_by(username=query).first()
    if found is not None:
        users.append(found)
    return success_response({"users": [u.serialize() for u in users]})


@app.route("/friends/requests/", methods=['POST'])
@flask_login.login_required
def create_friend_request():
    user = flask_login.current_user

    # Check for valid request body
    body = json.loads(request.data)
    friend_id = body.get("user_id")
    if friend_id is None:
        return failure_response("Could not get user ID from request body.", 400)
    friend = User.query.filter_by(id=friend_id).first()
    if friend is None:
        return failure_response("User not found.")

    # Check if user is allowed to create friend request
    # TODO: add support for blocking users
    if friend_id == user.id:
        return failure_response("Cannot friend yourself.", 400)
    if user.get_relationship_with(friend.id) is not None:
        return failure_response("A relationship already exists with this user.", 400)

    # Create friend request
    relationship = UserRelationship(user_a_id=user.id, user_b_id=friend.id, type=RelationshipType.REQUESTED)
    db.session.add(relationship)
    db.session.commit()

    return success_response(code=201)


@app.route("/friends/requests/")
@flask_login.login_required
def get_friend_requests():
    user = flask_login.current_user
    # A list of user IDs requesting to friend the current user
    incoming_ids = [rel.user_a_id for rel in UserRelationship.query.filter_by(user_b_id=user.id, type=RelationshipType.REQUESTED)]
    # A list of user IDs that the current user is requesting to friend
    outgoing_ids = [rel.user_b_id for rel in UserRelationship.query.filter_by(user_a_id=user.id, type=RelationshipType.REQUESTED)]

    # I believe we should serialize users in the response because their
    # info is required for the end user to act on the friend request
    res = {
        "incoming": [db.session.query(User).get(id).serialize() for id in incoming_ids],
        "outgoing": [db.session.query(User).get(id).serialize() for id in outgoing_ids]
    }
    return success_response(res)


@app.route("/friends/requests/<int:other_user_id>/", methods=["PUT"])
@flask_login.login_required
def update_incoming_friend_request(other_user_id):
    user = flask_login.current_user

    # Verify friend request exists
    rel = user.get_relationship_with(other_user_id)
    if rel is None or rel.type != RelationshipType.REQUESTED or rel.user_b_id != user.id:
        return failure_response("Friend request not found.")

    # Check for valid request body
    body = json.loads(request.data)
    status = body.get("status")
    if status is None:
        return failure_response("Could not get status from request body.", 400)

    # Change relationship status
    if status == 'accepted':
        rel.set_type(RelationshipType.FRIENDS)
    elif status == 'declined':
        # Delete relationship
        db.session.delete(rel)
        db.session.commit()
    else:
        return failure_response("Invalid status.", 400)

    return success_response(code=204)


@app.route("/friends/requests/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_outgoing_friend_request(other_user_id):
    user = flask_login.current_user

    # Verify friend request exists
    rel = user.get_relationship_with(other_user_id)
    if rel is None or rel.type != RelationshipType.REQUESTED or rel.user_a_id != user.id:
        return failure_response("Friend request not found.")

    # Delete relationship
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)


@app.route("/friends/")
@flask_login.login_required
def get_all_friends():
    user = flask_login.current_user
    # The current user reached out first
    friends_the_user_made = [rel.user_b_id for rel in UserRelationship.query.filter_by(user_a_id=user.id, type=RelationshipType.FRIENDS)]
    # They reached out first
    others_who_friended_user = [rel.user_a_id for rel in UserRelationship.query.filter_by(user_b_id=user.id, type=RelationshipType.FRIENDS)]
    # Combine lists
    friends = friends_the_user_made + others_who_friended_user
    return success_response({"friends": [db.session.query(User).get(id).serialize() for id in friends]})


@app.route("/friends/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def remove_friend(other_user_id):
    user = flask_login.current_user

    # Verify friendship exists
    rel = user.get_relationship_with(other_user_id)
    if rel is None or rel.type != RelationshipType.FRIENDS:
        return failure_response("Friend not found.")

    # Delete friendship 💔
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)
