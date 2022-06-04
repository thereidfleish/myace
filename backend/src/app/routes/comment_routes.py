"""Routes that pertain to comments."""

import json

from flask import request
import flask_login
from . import routes, success_response, failure_response
from .. import email
from ..models import Comment, Upload
from ..extensions import db


@routes.route("/comments")
@flask_login.login_required
@email.email_conf_required
def get_all_comments():
    me = flask_login.current_user
    # Check for optional query params
    upload_id = request.args.get("upload")
    if upload_id is None:
        # Default behavior. Get all comments authored by user
        # I could use 'user.comments' here but the InstrumentedList obj does
        # not allow chaining filtering like the Query obj
        comments = Comment.query.filter_by(author_id=me.id)
    else:
        # Get all comments under upload ID
        upload = Upload.query.filter_by(id=upload_id).first()
        if upload is None:
            return failure_response("Upload not found.")
        if not me.can_view_upload(upload):
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
                c.serialize(me) for c in comments if me.can_view_comment(c)
            ]
        }
    )


@routes.route("/comments/", methods=["POST"])
@flask_login.login_required
@email.email_conf_required
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

    return success_response(comment.serialize(author), 201)


@routes.route("/comments/<int:comment_id>/", methods=["DELETE"])
@flask_login.login_required
@email.email_conf_required
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
    db.session.delete(comment)
    db.session.commit()

    return success_response(code=204)
