#!/usr/bin/env python3
import datetime
import json
import os
import boto3

from botocore.client import Config

from dotenv import load_dotenv
from flask import Flask
from flask import request
from werkzeug.utils import secure_filename

import media

from db import User
from db import Upload
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


def success_response(data, code=200):
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
        {"uploads": [u.serialize() for u in Upload.query.filter_by(id=user_id)]}
    )


@app.route("/api/upload/<int:upload_id>/update-title/", methods=['POST'])
def update_upload_title(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    body = json.loads(request.data)

    new_title = body.get("new_title")

    if new_title is not None:
        upload.display_title = new_title

    db.session.commit()

    return success_response(upload.serialize())


@app.route("/api/upload/<int:upload_id>/")
def get_video_url(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Could not locate video id in database.")

    vkey = upload.vkey
    expire_date = datetime.datetime.utcnow() + datetime.timedelta(hours=3)
    url = aws.get_presigned_hls_url(vkey, expire_date)

    if url is None:
        return failure_response("An error occurred when presigning the HLS URL.")

    return success_response({'url': url})


@app.route("/api/upload/")
def get_upload_url():
    filename = request.form.get("filename")
    display_title = request.form.get("display_title")
    uid = request.form.get("uid")

    if filename is None or display_title is None or uid is None:
        return failure_response("Did not provide all requested fields.", 400)

    # Sanitize filename
    filename = secure_filename(filename)

    # Check if UID is int
    if not uid.isdigit():
        return failure_response("UID is not a number.", 400)

    uid = int(uid)

    if filename.isspace() or display_title.isspace() or uid < 0:
        return failure_response("Invalid fields.", 400)

    # Check for valid file
    # For security reference, see:
    # https://blog.miguelgrinberg.com/post/handling-file-uploads-with-flask
    uploaded_file = request.files['file']
    file_ext = os.path.splitext(filename)[1]
    if file_ext not in app.config['UPLOAD_EXTENSIONS'] \
            or not verify_mp4_integrity(uploaded_file.stream):
        failure_response("Bad MP4.", 400)

    try:
        # Creates upload with vkey as filename and then changes it after using the new vid to make the vkey
        new_upload = Upload(vkey=filename, display_title=display_title, id=uid)
        db.session.add(new_upload)
        db.session.flush()
        upload_id = new_upload.id
        vkey = str(abs(hash(str(filename+str(uid)+str(upload_id)))))
        new_upload.vkey = vkey
        db.session.commit()
    except Exception as e:
        print(e)
        return failure_response("Error while trying to submit to database")

    try:
        # Save file to disk
        path_to_mp4 = os.path.join(app.config['UPLOAD_PATH'], vkey) + '.mp4'
        uploaded_file.save(path_to_mp4)

        # Convert, compress, and upload file to AWS
        path_to_fmp4 = convert_mp4_to_hsl(path_to_mp4)
        compress_fmp4(path_to_fmp4)
        object_url = upload_to_aws(s3, AWS_BUCKET_NAME, AWS_BUCKET_REGION_NAME, path_to_fmp4)
        remove_fmp4(path_to_fmp4)
    except Exception as e:
        # Delete unsuccessful upload from database
        Upload.query.filter_by(id=upload_id).delete()
        db.session.commit()
        print(e)
        return failure_response("Error while transferring video", 502)

    return success_response({'id': upload_id, 'url': object_url})


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

    return success_response(upload.serialize(), status_code)


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

    return success_response(upload.serialize())


@app.route("/api/callback/s3upload/", methods=['POST'])
def upload_callback():
    """Called by AWS after a successful upload to the S3 bucket"""
    # TODO: create mediaconvert job and add upload to database
    pass


def create_test_user():
    user = User(google_id="testGID", display_name="Foo Bar", email="ilovetennis@gmail.com")
    db.session.add(user)
    db.session.commit()
    return success_response(user.serialize())

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
