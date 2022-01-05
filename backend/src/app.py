#!/usr/bin/env python3
import datetime
import json
import os

import media

from botocore.client import Config

from flask import Flask
from flask import request
from werkzeug.utils import secure_filename
import flask_login

from db import User
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
DB_ENDPOINT = str(os.environ.get("DB_ENDPOINT")).strip()
DB_NAME = str(os.environ.get("DB_NAME")).strip()
DB_USERNAME = str(os.environ.get("DB_USERNAME")).strip()
DB_PASSWORD = str(os.environ.get("DB_PASSWORD")).strip()
DB_ENDPOINT = str(os.environ.get("DB_ENDPOINT")).strip() # localhost or server URL
G_CLIENT_ID = str(os.environ.get("G_CLIENT_ID")).strip()
AWS_ACCESS_KEY_ID = str(os.environ.get("AWS_ACCESS_KEY_ID")).strip()
AWS_SECRET_ACCESS_KEY = str(os.environ.get("AWS_SECRET_ACCESS_KEY")).strip()
CF_PUBLIC_KEY_ID = str(os.environ.get("CF_PUBLIC_KEY_ID")).strip()
CF_PRIVATE_KEY_FILE = str(os.environ.get("CF_PRIVATE_KEY_FILE")).strip()

# To use on your local machine, you must configure postgres at port 5432 and put your credentials in your .env.
app.config["SQLALCHEMY_DATABASE_URI"] = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
app.config["SQLALCHEMY_ECHO"] = ENV == "dev"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)
with app.app_context():
    db.create_all()

# global AWS instance TODO: check if multiple Flask clients share this instance
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
@app.route("/api/user/login/", methods=["POST"])
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

        gid = idinfo["sub"]
        email = idinfo["email"]
        display_name = idinfo["name"]

        if gid is None or email is None or display_name is None:
            return failure_response("Could not retrieve required fields (Google Account ID, email, and name) from"
                                    "Google token. Unauthorized.", 401)

        # Check if user exists
        user = User.query.filter_by(google_id=gid, type=user_type).first()
        user_created = user == None

        if user is None:
            # User does not exist, add them.
            user = User(google_id=gid, display_name=display_name, email=email, type=user_type)
            db.session.add(user)
            db.session.commit()

        # Begin user session
        login_user(user, remember=True)

        return success_response(user.serialize(), 201 if user_created else 200)

    except ValueError:
        return failure_response("Could not authenticate user. Unauthorized.", 401)


@app.route("/api/user/logout/", methods=["POST"])
@flask_login.login_required
def logout():
    logout_user()
    return success_response()

@app.route("/api/user/<int:user_id>/uploads/")
@flask_login.login_required
def get_all_user_uploads(user_id):
    user = User.query.filter_by(id=user_id).first()
    if user is None:
        return failure_response("User not found.")

    return success_response(
        {"uploads": [u.serialize(aws) for u in Upload.query.filter_by(user_id=user_id)]}
    )


@app.route("/api/user/<int:user_id>/upload/<int:upload_id>/")
@flask_login.login_required
def get_specific_user_upload(user_id, upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    if user_id != upload.user_id:
        return failure_response("User forbidden to access upload.", 403)

    # Create response
    res = upload.serialize(aws)

    if upload.stream_ready:
        # TODO: cache url in database to avoid expensive signing
        expire_date = datetime.datetime.utcnow() + datetime.timedelta(hours=3)
        url = aws.get_presigned_hls_url(upload_id, expire_date)
        if url is None:
            return failure_response("An error occurred when presigning the HLS URL.", 500)
        res["url"] = url

    return success_response(res)


@app.route("/api/user/<int:user_id>/upload/", methods=['POST'])
@flask_login.login_required
def create_upload_url(user_id):
    user = User.query.filter_by(id=user_id).first()

    if user is None:
        return failure_response("User not found.")

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

    # Create upload row
    new_upload = Upload(filename=filename, display_title=display_title, user_id=user_id, bucket_id=bucket_id)
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


@app.route("/api/user/<int:user_id>/upload/<int:upload_id>/", methods=['PUT'])
@flask_login.login_required
def edit_upload(user_id, upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    if user_id != upload.user_id:
        return failure_response("User forbidden to access upload.", 403)

    body = json.loads(request.data)

    # Update title
    new_title = body.get("display_title")
    if new_title is not None:
        if new_title.isspace():
            return failure_response("Invalid title.", 400)
        upload.display_title = new_title

    db.session.commit()
    return success_response(upload.serialize(aws))


@app.route("/api/user/<int:user_id>/upload/<int:upload_id>/convert/", methods=['POST'])
@flask_login.login_required
def start_convert(user_id, upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    if user_id != upload.user_id:
        return failure_response("User forbidden to access upload.", 403)

    # create convert job
    convert_job_id = aws.create_mediaconvert_job(upload_id, upload.filename)
    upload.mediaconvert_job_id = convert_job_id
    db.session.commit()

    return success_response()


# TODO: autodetect S3 uploads
# @app.route("/api/callback/s3upload/", methods=['POST'])
# def upload_callback():
#     """Called by AWS after a successful upload to the S3 bucket"""
#     # TODO: create mediaconvert job and add upload to database
#     pass


@app.route("/api/upload/<int:upload_id>/comment/", methods=['POST'])
@flask_login.login_required
def create_comment(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    # Check for valid fields
    body = json.loads(request.data)

    # Check for valid author
    author_id = body.get("author_id")
    if author_id is None:
        return failure_response("Missing author ID.", 400)
    author = User.query.filter_by(id=author_id).first()
    if author is None:
        return failure_response("Author not found.")
    # Check if user is allowed to comment
    # TODO: allow coaches to comment
    if author_id != upload.user_id:
        return failure_response("User forbidden to comment on upload.", 403)

    # Check for valid text
    text = body.get("text")
    if text is None or text.isspace():
        return failure_response("Invalid comment text.", 400)

    # Create comment row
    comment = Comment(author_id=author_id, upload_id=upload_id, text=text)
    db.session.add(comment)
    db.session.commit()

    return success_response(comment.serialize(), 201)


@app.route("/api/user/<int:user_id>/buckets/", methods=['POST'])
@flask_login.login_required
def create_bucket(user_id):
    # Check of user exists
    user = User.query.filter_by(id=user_id).first()
    if user is None:
        return failure_response("User does not exist.")

    # Get name from request body
    body = json.loads(request.data)
    name = body.get("name")
    if name is None:
        return failure_response("Could not get bucket name from request body.", 400)

    bucket = Bucket(user_id=user_id, name=name)
    db.session.add(bucket)
    db.session.commit()

    return success_response(bucket.serialize(aws=aws), 201)


@app.route("/api/user/<int:user_id>/bucket/<int:bucket_id>/")
@flask_login.login_required
def get_uploads_in_bucket(user_id, bucket_id):
    bucket = Bucket.query.filter_by(id=bucket_id).first()
    if bucket is None:
        return failure_response("Bucket not found.")
    elif bucket.user_id != user_id:
        return failure_response("User forbidden to access this bucket.", 403)

    return success_response(bucket.serialize(aws=aws, show_uploads=True))


@app.route("/api/user/<int:user_id>/buckets/")
@flask_login.login_required
def get_buckets(user_id):
    user = User.query.filter_by(id=user_id).first()
    if user is None:
        return failure_response("User not found.")

    return success_response({"buckets": [b.serialize(aws=aws) for b in user.buckets]})


@app.route("/health/")
def health_check():
    return success_response({"status": "OK"})

#@app.route("/api/")
def create_test_user():
    user = User(google_id="testGID", display_name="Foo Bar", email="ilovetennis@gmail.com", type=0)
    db.session.add(user)
    db.session.commit()
    return success_response(user.serialize())


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
