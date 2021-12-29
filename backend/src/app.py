#!/usr/bin/env python3
import datetime
import json
import os

from botocore.client import Config

from dotenv import load_dotenv
from flask import Flask
from flask import request
from werkzeug.utils import secure_filename

import media

from db import User
from db import Upload
from db import Comment
from db import Tag
from db import db

from google.oauth2 import id_token
from google.auth.transport import requests

app = Flask(__name__)

# load environment variables
load_dotenv()

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
CF_PRIVATE_KEY_FILE = './private_key.pem'

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


# Routes
@app.route("/api/user/authenticate/", methods=["POST"])
def authenticate_user():
    body = json.loads(request.data)
    token = body.get("token")

    if token is None:
        return failure_response("Could not get token from request body.", 400)

    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), G_CLIENT_ID)

        gid = idinfo["sub"]
        email = idinfo["email"]
        display_name = idinfo["name"]

        if gid is None or email is None or display_name is None:
            return failure_response("Could not retrieve required fields (Google Account ID, email, and name) from"
                                    "Google token. Unauthorized.", 401)

        user = User.query.filter_by(google_id=gid).first()

        if user is None:
            # User does not exist, add them.
            user = User(google_id=gid, display_name=display_name, email=email)
            db.session.add(user)
            db.session.commit()

        return success_response(user.serialize(), 200)
    except ValueError:
        return failure_response("Could not authenticate user. Unauthorized.", 401)


@app.route("/api/user/<int:user_id>/uploads/")
def get_all_user_uploads(user_id):
    user = User.query.filter_by(id=user_id).first()
    if user is None:
        return failure_response("User not found.")

    return success_response(
        {"uploads": [u.serialize(aws) for u in Upload.query.filter_by(user_id=user_id)]}
    )


@app.route("/api/user/<int:user_id>/upload/<int:upload_id>/")
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

    # Create upload row
    new_upload = Upload(filename=filename, display_title=display_title, user_id=user_id)
    db.session.add(new_upload)
    db.session.commit()

    # Create URL
    res = {'id': new_upload.id}
    urldata = aws.get_presigned_url_post(new_upload.id, filename)
    res.update(urldata)
    return success_response(res)


@app.route("/api/user/<int:user_id>/upload/<int:upload_id>/", methods=['PUT'])
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

    return success_response(comment.serialize())


@app.route("/api/upload/<int:upload_id>/tags/", methods=['POST'])
def add_tag(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")

    body = json.loads(request.data)
    name = body.get("name")

    if name is None:
        return failure_response("Could not get name from request.", 400)

    tag = Tag.query.filter_by(name=name).first()

    status_code = 200

    if tag is None:
        tag = Tag(name=name)
        db.session.add(tag)
        db.session.flush()
        status_code = 201

    upload.tags.append(tag)
    db.session.commit()

    return success_response(upload.serialize(aws), status_code)


@app.route("/api/upload/<int:upload_id>/tags/")
def get_tags(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")

    return success_response({"tags": [t.serialize() for t in upload.tags]})


@app.route("/api/upload/<int:upload_id>/tag/<int:tid>/", methods=['DELETE'])
def delete_tag(upload_id, tid):
    upload = Upload.query.filter_by(id=upload_id).first()
    if upload is None:
        return failure_response("Upload not found.")

    upload.tags = [t for t in upload.tags if t.id != tid]

    db.session.commit()

    return success_response(upload.serialize(aws))


# @app.route("/api/")
def create_test_user():
    user = User(google_id="testGID", display_name="Foo Bar", email="ilovetennis@gmail.com")
    db.session.add(user)
    db.session.commit()
    return success_response(user.serialize())


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
