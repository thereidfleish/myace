"""Routes that pertain to buckets."""

import json

from flask import request
import flask_login
from . import routes, success_response, failure_response
from ..models import Bucket


@routes.route("/buckets/", methods=["POST"])
@flask_login.login_required
def create_bucket():
    me = flask_login.current_user

    # Get name from request body
    body = json.loads(request.data)
    name = body.get("name")
    if name is None:
        return failure_response(
            "Could not get bucket name from request body.", 400
        )

    if Bucket.query.filter_by(name=name, user_id=me.id).first() is not None:
        return failure_response("A bucket of this name already exists.", 400)

    # Create the bucket
    bucket = Bucket(user_id=me.id, name=name)
    db.session.add(bucket)
    db.session.commit()

    return success_response(bucket.serialize(me), 201)


@routes.route("/buckets")
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
        {
            "buckets": [
                b.serialize(me) for b in buckets if me.can_view_bucket(b)
            ]
        }
    )


@routes.route("/buckets/<int:bucket_id>/", methods=["PUT"])
@flask_login.login_required
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
        if new_name.isspace():
            return failure_response("Invalid title.", 400)
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
