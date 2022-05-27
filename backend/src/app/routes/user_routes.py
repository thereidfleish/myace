import json
import re

import flask_login
from . import routes, success_response, failure_response

from ..cookiesigner import CookieSigner
from ..models import User
from ..settings import G_CLIENT_IDS
from ..extensions import db

from flask import request

from google.oauth2 import id_token
from google.auth.transport import requests


@routes.route("/login/", methods=["POST"])
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

    # TODO: Find a better way to test. This is godawful.
    test_tokens = {
        "backendtesttoken1": {
            "gid": "test_gid_1",
            "email": "john@email.com",
            "display_name": "John Smith",
        },
        "backendtesttoken2": {
            "gid": "test_gid_2",
            "email": "sarah@email.com",
            "display_name": "Sarah Silverman",
        },
        "backendtesttoken3": {
            "gid": "test_gid_3",
            "email": "peter@email.com",
            "display_name": "Peter Piper",
        },
    }
    if token in test_tokens:
        gid, email, display_name = (
            test_tokens[token]["gid"],
            test_tokens[token]["email"],
            test_tokens[token]["display_name"],
        )
    else:
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
        user.serialize(user, show_private=True), 201 if user_created else 200
    )


@routes.route("/logout/", methods=["POST"])
@flask_login.login_required
def logout():
    flask_login.logout_user()
    return success_response()


@routes.route("/users/me/")
@flask_login.login_required
def get_me():
    me = flask_login.current_user
    return success_response(me.serialize(me, show_private=True))


@routes.route("/users/me/", methods=["PUT"])
@flask_login.login_required
def edit_me():
    me = flask_login.current_user

    body = json.loads(request.data)

    # Update username if it changed
    new_username = body.get("username")
    if new_username is not None and me.username != new_username:
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
        me.username = new_username

    # Update display name if it changed
    new_display_name = body.get("display_name")
    if new_display_name is not None and me.display_name != new_display_name:
        if new_display_name.isspace():
            return failure_response("Invalid display name.", 400)
        me.display_name = new_display_name

    # Update bio if it changed
    new_bio = body.get("biography")
    if new_bio is not None:
        new_bio = new_bio.strip()
        if me.biography != new_bio:
            me.biography = new_bio

    db.session.commit()
    return success_response(me.serialize(me, show_private=True))


@routes.route("/users/me/", methods=["DELETE"])
@flask_login.login_required
def delete_me():
    me: User = flask_login.current_user

    # TODO: delete profile picture
    aws.delete_uploads(me.uploads)
    # Delete user.
    # It is the DB's responsibility to ensure deletion of rows containing
    # foreign keys.
    db.session.delete(me)
    db.session.commit()
    return success_response(code=204)
