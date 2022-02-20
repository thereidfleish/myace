import bcrypt
import json
import re

import flask_login
from . import routes, success_response, failure_response

from .. import aws
from ..cookiesigner import CookieSigner
from ..models import User, LoginMethods
from ..settings import G_CLIENT_IDS
from ..extensions import db

from flask import request

from google.oauth2 import id_token
from google.auth.transport import requests
from google.auth.exceptions import GoogleAuthError


def salt_and_hash(plaintext: str) -> str:
    """Salt and hash a plaintext password"""
    # bcrypt automatically stores the salt in the resulting string
    return bcrypt.hashpw(plaintext.encode(), bcrypt.gensalt()).decode()


def verify_password(plaintext: str, hash: str) -> bool:
    """Test if a plaintext password matches a hashed password"""
    return bcrypt.checkpw(plaintext.encode(), hash.encode())


class InvalidStr(Exception):
    """Generic exception that describes why a string is invalid."""

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


class UnavailableUsername(Exception):
    """Username is reserved by another user."""

    def __init__(self) -> None:
        super().__init__()


def test_valid_unique_username(username: str) -> None:
    """Test if a username is valid and unique.

    :raise InvalidStr: if invalid, containing a user-friendly error
    :raise UnavailableUsername: if taken
    """
    # Check for None
    if username is None:
        raise InvalidStr("Missing username.")
    # Check for capitals
    if any(c.isupper() for c in username):
        raise InvalidStr("Username must be lowercase.")
    # Check username length
    if len(username) <= 2:
        raise InvalidStr("Username must be at least 3 characters long.")
    # Check if username contains illegal characters
    regexp = re.compile(User.ILLEGAL_UNAME_PATTERN)
    illegal_match = regexp.search(username)
    if illegal_match:
        raise InvalidStr(
            f"Username contains illegal character '{illegal_match.group(0)}'.",
        )
    # Check if username exists
    if not User.is_username_unique(username):
        raise UnavailableUsername


def test_valid_display_name(display_name: str) -> None:
    """Test if a display name is valid.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    if display_name is None:
        raise InvalidStr("Missing display name.")
    if display_name.isspace():
        raise InvalidStr("Invalid display name.")


def test_valid_email(email: str) -> None:
    """Test if an email address is valid. Does NOT check if email is unique.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    # Check for None
    if email is None:
        raise InvalidStr("Missing email.")
    # Check for capitals
    if any(c.isupper() for c in email):
        raise InvalidStr("Email must be lowercase.")
    # Check email pattern
    email_regex = r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
    if not re.fullmatch(email_regex, email):
        raise InvalidStr("Invalid email address.")


def test_valid_password(password: str) -> None:
    """Check if a plaintext password is valid.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    # Check None
    if password is None:
        raise InvalidStr("Missing password.")
    # Check length
    if len(password) < 6:
        raise InvalidStr("Password must be at least 6 characters long.")
    # Check for strong password
    contains_capital = any(c.isupper() for c in password)
    contains_number = any(c.isnumeric() for c in password)
    contains_special = any(not c.isalnum() for c in password)
    if (
        int(contains_capital) + int(contains_number) + int(contains_special)
        < 2
    ):
        raise InvalidStr(
            "Password must meet at least 2/3 criteria: contains capital letters, numbers, or special characters.",
        )


@app.route("/register/", methods=["POST"])
def register():
    body = json.loads(request.data)

    # Check for valid username
    username = body.get("username")
    valid, error_msg = test_valid_unique_username(username)
    if not valid:
        return failure_response(error_msg, 400)

    # Check for valid display name
    display_name = body.get("display_name")
    if display_name is None:
        return failure_response("Missing display name.", 400)
    if display_name.isspace():
        return failure_response("Invalid display name.", 400)

    # Check for valid email
    email = body.get("email")
    valid, error_msg = test_valid_email(email)
    if not valid:
        return failure_response(error_msg, 400)

    # Check for unique email
    user_w_email = User.query.filter_by(email=email).first()
    if user_w_email is not None:
        if user_w_email.login_method == LoginMethods.GOOGLE:
            return failure_response(
                "An account with this email already exists and is using Google sign-on.",
                400,
            )
        else:
            # Generic failure
            return failure_response(
                "An account with this email already exists.", 400
            )

    # Check for valid password
    password = body.get("password")
    try:
        test_valid_password(password)
    except InvalidStr as e:
        return failure_response(e.message, 400)

    # Salt and hash password
    hash = salt_and_hash(password)

    # Add user
    user = User(
        display_name=display_name,
        email=email,
        username=username,
        password_hash=hash,
    )
    db.session.add(user)
    db.session.commit()

    # Begin user session
    flask_login.login_user(user, remember=True)

    return success_response(user.serialize(show_private=True), 201)


class LoginError(Exception):
    def __init__(self, message: str, code: int) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


def login_w_password(email: str, password: str) -> User:
    """Retrieve a user who has registered with email/password.

    :raise: LoginError if login fails
    """
    # Check if user exists
    user = User.query.filter_by(email=email).first()
    if user is None:
        raise LoginError("User not found.", 404)
    # Check for email sign in method
    if user.login_method != LoginMethods.EMAIL:
        # Give login method specific error messages
        if user.login_method == LoginMethods.GOOGLE:
            raise LoginError(
                f"This account was created via Google sign-on.", 400
            )
        else:
            # Generic response
            raise LoginError(
                "This account was created with another sign-on method.",
                400,
            )
    # Check for valid password
    if not verify_password(password, user.password_hash):
        raise LoginError("Incorrect password.", 401)
    return user


def login_w_google(token: str) -> User:
    """Retrieve or create a user who has signed in with Google.

    :raise: LoginError if login fails
    """
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
        # Verify token with specified OAuth client IDs
        try:
            idinfo = id_token.verify_oauth2_token(
                token, requests.Request(), G_CLIENT_IDS
            )
        except ValueError:
            raise LoginError("Token verification failed. Unauthorized.", 401)
        except GoogleAuthError:
            raise LoginError("Invalid token issuer. Unauthorized.", 401)
        # parse user information
        try:
            gid = idinfo["sub"]
            email = idinfo["email"]
            display_name = idinfo["name"]
        except KeyError:
            raise LoginError(
                "Failed to parse required fields (Google Account ID, email, name) from Google token. Unauthorized.",
                401,
            )

    # Check if user exists
    user_w_gid = User.query.filter_by(google_id=gid).first()
    user_w_email = User.query.filter_by(email=email).first()
    user_created = user_w_gid is None

    if user_w_gid is None:
        if user_w_email is None:
            # User does not exist, add them.
            user = User(display_name=display_name, email=email, google_id=gid)
            db.session.add(user)
            db.session.commit()
        else:
            # There is a user with this email but not the GID
            # Give login method specific error messages
            if user_w_email.login_method == LoginMethods.EMAIL:
                raise LoginError(
                    f"This account was created via email/password.", 400
                )
            else:
                # Generic response
                raise LoginError(
                    "This account was created with another sign-on method.",
                    400,
                )
    else:
        if user_w_email is None:
            # User has signed in with this Google account before but their email has changed.
            assert email != user_w_gid.email
            # Update their email to the one current with their Google account
            user_w_gid.email = email
            db.session.commit()
            user = user_w_gid
        else:
            # user_w_email is the same as user_w_gid
            assert user_w_gid == user_w_email
            user = user_w_gid
    return user


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
    user = None
    user_created = False

    method = body.get("method")
    try:
        if method == "password":
            email = body.get("email")
            if email is None:
                return failure_response("Missing email.", 400)
            password = body.get("password")
            if password is None:
                return failure_response("Missing password.", 400)
            user = login_w_password(email, password)

        elif method == "google":
            token = body.get("token")
            if token is None:
                return failure_response("Missing token.", 400)
            user = login_w_google(token)
            user_created = True

        else:
            return failure_response("Invalid login method.", 400)
    except LoginError as e:
        return failure_response(e.message, e.code)

    # Begin user session
    assert user is not None
    flask_login.login_user(user, remember=True)

    return success_response(user.serialize(user), 201 if user_created else 200)


@routes.route("/logout/", methods=["POST"])
@flask_login.login_required
def logout():
    flask_login.logout_user()
    return success_response(code=204)


@routes.route("/users/<user_id>/")
@flask_login.login_required
def get_user(user_id):
    me = flask_login.current_user
    user = me if user_id == "me" else User.query.filter_by(id=user_id).first()
    if user is None:
        return failure_response("User not found.")
    return success_response(user.serialize(me))


@routes.route("/users/me/", methods=["PUT"])
@flask_login.login_required
def edit_me():
    me = flask_login.current_user

    body = json.loads(request.data)

    # Update username if it changed
    new_username = body.get("username")
    if new_username is not None and me.username != new_username:
        try:
            test_valid_unique_username(new_username)
        except InvalidStr as e:
            return failure_response(e.message, 400)
        except UnavailableUsername:
            return failure_response("Username unavailable.", 409)
        me.username = new_username

    # Update display name if it changed
    new_display_name = body.get("display_name")
    if new_display_name is not None and me.display_name != new_display_name:
        try:
            test_valid_display_name(new_display_name)
        except InvalidStr as e:
            return failure_response(e.message, 400)
        me.display_name = new_display_name

    # Update bio if it changed
    new_bio = body.get("biography")
    if new_bio is not None:
        new_bio = new_bio.strip()
        if me.biography != new_bio:
            me.biography = new_bio

    db.session.commit()
    return success_response(me.serialize(me))


@routes.route("/users/me/", methods=["DELETE"])
@flask_login.login_required
def delete_me():
    me: User = flask_login.current_user

    # TODO: delete profile picture
    aws.delete_uploads([u.id for u in me.uploads])
    # Delete user.
    # It is the DB's responsibility to ensure deletion of rows containing
    # foreign keys.
    db.session.delete(me)
    db.session.commit()
    return success_response(code=204)
