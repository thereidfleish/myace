"""Routes that pertain to courtships."""

import json

from sqlalchemy import or_, and_
import flask_login
from . import routes, success_response, failure_response
from ..models import User, UserRelationship


@routes.route("/users/search")
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
        {"users": [u.serialize(me) for u in found if u != me]}
    )


@routes.route("/courtships/requests/", methods=["POST"])
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
    if me.get_relationship_with(other) is not None:
        return failure_response(
            "A courtship already exists with this user.", 400
        )

    # Create courtship request
    db.session.add(courtship)
    db.session.commit()

    return success_response(other.serialize(me), code=201)


@routes.route("/courtships/requests")
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

    return success_response(
        {"requests": [c.get_other(me).serialize(me) for c in courtships]}
    )


@routes.route("/courtships/requests/<int:other_user_id>/", methods=["PUT"])
@flask_login.login_required
def update_incoming_courtship_request(other_user_id):
    me = flask_login.current_user

    other = User.query.filter_by(id=other_user_id).first()
    if other is None:
        return failure_response("User not found.")

    # Verify incoming courtship request exists
    rel = me.get_relationship_with(other)
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


@routes.route("/courtships/requests/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def delete_outgoing_courtship_request(other_user_id):
    user = flask_login.current_user

    other = User.query.filter_by(id=other_user_id).first()
    if other is None:
        return failure_response("User not found.")

    # Verify outgoing courtship request exists
    rel = user.get_relationship_with(other)
    if rel is None or not rel.type.is_request() or rel.user_a_id != user.id:
        return failure_response("Outgoing courtship request not found.", 404)

    # Delete relationship
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)


@routes.route("/users/<user_id>/courtships")
@flask_login.login_required
def get_all_courtships(user_id):
    me = flask_login.current_user
    if user_id == "me":
        user_id = me.id
    # Get all UserRelationships involving the specified user
    courtships = UserRelationship.query.filter(
        or_(
            UserRelationship.user_a_id == user_id,
            UserRelationship.user_b_id == user_id,
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
                type=RelationshipType.A_COACHES_B, user_b_id=user_id
            )
        elif type == "student":
            courtships = courtships.filter_by(
                type=RelationshipType.A_COACHES_B, user_a_id=user_id
            )
        else:
            return failure_response("Invalid type.", 400)

    return success_response(
        {"courtships": [c.get_other(me).serialize(me) for c in courtships]}
    )


@routes.route("/courtships/<int:other_user_id>/", methods=["DELETE"])
@flask_login.login_required
def remove_courtship(other_user_id):
    user = flask_login.current_user

    other = User.query.filter_by(id=other_user_id).first()
    if other is None:
        return failure_response("User not found.")

    # Verify courtship exists
    rel = user.get_relationship_with(other)
    if rel is None or rel.type not in (
        RelationshipType.FRIENDS,
        RelationshipType.A_COACHES_B,
    ):
        return failure_response("Courtship not found.", 404)

    # Delete courtship 💔
    db.session.delete(rel)
    db.session.commit()

    return success_response(code=204)
