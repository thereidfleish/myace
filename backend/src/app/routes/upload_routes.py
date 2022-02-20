"""Routes that pertain to uploads."""

import json
from typing import TypedDict
from flask import make_response, request
import flask_login

from . import routes, success_response, failure_response
from .. import aws
from ..models import User, Bucket, Upload, VisibilityDefault, visib_of_str
from ..extensions import db


@routes.route("/users/me/uploads")
@flask_login.login_required
def get_all_uploads():
    me = flask_login.current_user
    # Get my uploads
    uploads = Upload.query.filter_by(user_id=me.id)

    # Optionally filter by bucket
    bucket_id = request.args.get("bucket")
    if bucket_id is not None:
        uploads = uploads.filter_by(bucket_id=bucket_id)

    # Optionally filter by shared with
    sw_id = request.args.get("shared-with")
    if sw_id is not None:
        sw_user: User = User.query.filter_by(id=sw_id).first()
        if sw_user is None:
            return failure_response("User not found.")
        if sw_user == me:
            return failure_response(
                "Cannot share an upload with yourself.", 403
            )
        uploads = filter(lambda u: sw_user.can_view_upload(u), uploads)

    return success_response(
        {
            "uploads": [
                up.serialize(me) for up in uploads if me.can_view_upload(up)
            ]
        }
    )


@routes.route("/users/<int:other_id>/uploads")
@flask_login.login_required
def get_all_uploads_other_user(other_id):
    me = flask_login.current_user

    # Get other user's uploads
    uploads = Upload.query.filter_by(user_id=other_id)

    # Optionally filter by bucket
    bucket_id = request.args.get("bucket")
    if bucket_id is not None:
        uploads = uploads.filter_by(bucket_id=bucket_id)

    return success_response(
        {
            "uploads": [
                up.serialize(me) for up in uploads if me.can_view_upload(up)
            ]
        }
    )


@routes.route("/uploads/<int:upload_id>/")
@flask_login.login_required
def get_upload(upload_id):
    me = flask_login.current_user
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    user = flask_login.current_user
    if not user.can_view_upload(upload):
        return failure_response("User forbidden to view upload.", 403)

    # Create response
    response = upload.serialize(me)

    if upload.stream_ready:
        signer = CookieSigner(expiration_in_hrs=1, cf_key_id=CF_PUBLIC_KEY_ID)
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
    """Representative of the 400 HTTP response code."""


class VisibilityReq(TypedDict):
    """The request body of a visibility field. A uniform typed dictionary."""

    default: str
    also_shared_with: list[int]


def parse_visibility_req(
    visibility: VisibilityReq,
) -> tuple[VisibilityDefault, list[User]]:
    """Parse the "visibility" request obj.

    :raise BadRequest: if the body is incorrectly formatted
    :return:
        a VisibilityDefault and a list of users with whom an upload is
        individually shared
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


@routes.route("/uploads/", methods=["POST"])
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


@routes.route("/uploads/<int:upload_id>/convert/", methods=["POST"])
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

    return success_response(code=204)


@routes.route("/uploads/<int:upload_id>/", methods=["PUT"])
@flask_login.login_required
def edit_upload(upload_id):
    upload = Upload.query.filter_by(id=upload_id).first()

    if upload is None:
        return failure_response("Upload not found.")

    me = flask_login.current_user
    if not me.can_modify_upload(upload):
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
        if not me.can_modify_bucket(bucket):
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
    return success_response(upload.serialize(me))


@routes.route("/uploads/<int:upload_id>/", methods=["DELETE"])
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
    aws.delete_uploads([upload_id])
    db.session.commit()

    return success_response(code=204)


@routes.route("/uploads/<int:upload_id>/download/")
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
            "url": aws.get_download_url(
                upload.id, upload.filename, expiration_in_hours=1
            )
        }
    )


# TODO: autodetect S3 uploads
# @routes.route("/api/callback/s3upload/", methods=['POST'])
# def upload_callback():
#     """Called by AWS after a successful upload to the S3 bucket"""
#     # TODO: create mediaconvert job and add upload to database
#     pass
