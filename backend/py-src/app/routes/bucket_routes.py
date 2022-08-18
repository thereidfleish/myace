"""Routes that pertain to buckets."""

from dataclasses import dataclass
import json

from flask import request
import flask_login
from . import routes, success_response, failure_response
from .. import aws, email
from ..models import Bucket
from ..extensions import db


@dataclass
class InvalidBucketName(Exception):
    """The name of a bucket is invalid, containing a helpful message."""

    message: str


def test_valid_bucket_name(bucket_name: str) -> None:
    """Test if a bucket name is valid.

    :raise InvalidBucketName: if invalid
    """
    if bucket_name is None:
        raise InvalidBucketName("Missing bucket name.")
    if bucket_name == "" or bucket_name.isspace():
        raise InvalidBucketName("Invalid bucket name.")


@routes.route("/buckets/", methods=["POST"])
@flask_login.login_required
@email.email_conf_required
def create_bucket():
    me = flask_login.current_user

    # Get name from request body
    body = json.loads(request.data)
    name = body.get("name")
    try:
        test_valid_bucket_name(name)
    except InvalidBucketName as e:
        return failure_response(e.message, 400)

    if Bucket.query.filter_by(name=name, user_id=me.id).first() is not None:
        return failure_response("A bucket of this name already exists.", 400)

    # Create the bucket
    bucket = Bucket(user_id=me.id, name=name)
    db.session.add(bucket)
    db.session.commit()

    return success_response(bucket.serialize(me), 201)


@routes.route("/users/<user_id>/buckets")
@flask_login.login_required
@email.email_conf_required
def get_buckets(user_id):
    me = flask_login.current_user
    user_id = me.id if user_id == "me" else user_id
    buckets = Bucket.query.filter_by(user_id=user_id)

    return success_response(
        {
            "buckets": [
                b.serialize(me) for b in buckets if me.can_view_bucket(b)
            ]
        }
    )


@routes.route("/buckets/<int:bucket_id>/", methods=["PUT"])
@flask_login.login_required
@email.email_conf_required
def edit_bucket(bucket_id):
    me = flask_login.current_user
    bucket = Bucket.query.filter_by(id=bucket_id, user_id=me.id).first()

    if bucket is None:
        return failure_response("Bucket by user not found.")

    if not me.can_modify_bucket(bucket):
        return failure_response("User forbidden to modify bucket.", 403)

    body = json.loads(request.data)

    # Update name
    new_name = body.get("name")
    if new_name is not None and bucket.name != new_name:
        try:
            test_valid_bucket_name(new_name)
        except InvalidBucketName as e:
            return failure_response(e.message, 400)
        if (
            Bucket.query.filter_by(name=new_name, user_id=me.id).first()
            is not None
        ):
            return failure_response(
                "A bucket of this name already exists.", 400
            )
        bucket.name = new_name

    db.session.commit()
    return success_response(bucket.serialize(me))


@routes.route("/buckets/<int:bucket_id>/", methods=["DELETE"])
@flask_login.login_required
@email.email_conf_required
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
    aws.delete_uploads([u.id for u in bucket.uploads])
    db.session.delete(bucket)
    db.session.commit()

    return success_response(code=204)
