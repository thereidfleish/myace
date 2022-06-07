import bcrypt
import json
import re
import jwt
from jwt.algorithms import RSAAlgorithm
import requests
import time

import flask_login
from . import routes, success_response, failure_response

from .. import aws
from ..cookiesigner import CookieSigner
from ..email import (
    EmailFailed,
    email_conf_required,
    send_conf_email,
    confirm_token,
)
from ..models import User, LoginMethods
from ..settings import G_CLIENT_IDS, APPLE_CLIENT_ID
from ..extensions import db

from flask import request

from google.oauth2 import id_token
from google.auth.transport import requests as g_requests
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


def test_valid_username(username: str) -> None:
    """Test if a username is valid only. Does not check uniqueness.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    # Check for None
    if username is None:
        raise InvalidStr("Missing username.")
    # Check for capitals
    if any(c.isupper() for c in username):
        raise InvalidStr("Username must be lowercase.")
    # Check username regex
    if not re.fullmatch(User.USERNAME_PATTERN, username):
        raise InvalidStr("Invalid username.")


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
    email_regex = r"(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)"
    if not re.fullmatch(email_regex, email):
        raise InvalidStr("Invalid email address.")


def test_valid_password(password: str) -> None:
    """Check if a plaintext password is valid.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    # Check None
    if password is None:
        raise InvalidStr("Missing password.")
    # Regex match valid passwords
    symbols = r"\-\"[\]!#$%&'()*+,./:;<=>?@^_`{|}~"  # allowed special chars
    ge1_lower = r"(?=.*?[a-z])"  # at least 1 lowercase
    ge1_upper = r"(?=.*?[A-Z])"  # at least 1 uppercase
    ge1_num_or_sym = f"(?=.*?[0-9{symbols}])"  # at least 1 number or symbol
    only_alphanum_and_sym = f"[A-Za-z0-9{symbols}]"
    pattern = f"""^{ge1_lower}{ge1_upper}{ge1_num_or_sym}{only_alphanum_and_sym}{{6,}}$"""
    if not re.fullmatch(pattern, password):
        raise InvalidStr(
            "Password must be at least 6 characters and contain lowercase, uppercase, and either a number or a symbol.",
        )


def test_valid_bio(bio: str) -> None:
    """Check if a biography is valid.

    :raise InvalidStr: if invalid, containing a user-friendly error
    """
    if bio is None:
        raise InvalidStr("Missing biography.")
    if bio.isspace():
        raise InvalidStr("Biography cannot be only whitespace.")
    if len(bio) > 150:
        raise InvalidStr(f"Biography exceeds character limit: {len(bio)}/150.")


@routes.route("/users/resend/", methods=["POST"])
@flask_login.login_required
def resend_email_conf():
    me = flask_login.current_user
    # ensure it has been at least 60 seconds before sending another
    # TODO
    send_conf_email(me)
    return success_response(code=204)


@routes.route("/users/confirm/<token>/")
def confirm_email(token):
    email = confirm_token(token)
    if email is None:
        return failure_response(
            "This confirmation link is invalid or expired.", 400
        )
    user = User.query.filter_by(email=email).first()
    if user is None:
        return failure_response(
            "Whoops! Looks like we can't find you. Please contact support.",
            400,
        )
    if user.email_confirmed:
        return success_response("Account already confirmed. Please login.")
    else:
        user.email_confirmed = True
        db.session.commit()
        return success_response(
            "You have confirmed your account! Please login."
        )


@routes.route("/register/", methods=["POST"])
def register():
    body = json.loads(request.data)

    # Check for valid email
    email = body.get("email")
    try:
        test_valid_email(email)
    except InvalidStr as e:
        return failure_response(e.message, 400)

    # Check for unique email
    user_w_email = User.query.filter_by(email=email).first()
    if user_w_email is not None:
        if user_w_email.login_method == LoginMethods.GOOGLE:
            return failure_response(
                "An account with this email already exists and is using Google sign-on.",
                400,
            )
        elif user_w_email.login_method == LoginMethods.APPLE:
            return failure_response(
                "An account with this email already exists and is using Apple sign-on.",
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

    # Check for valid, unique username
    username = body.get("username")
    try:
        test_valid_username(username)
    except InvalidStr as e:
        return failure_response(e.message, 400)
    if not User.is_username_unique(username):
        return failure_response("Username unavailable", 409)

    # Check for valid display name
    display_name = body.get("display_name")
    try:
        test_valid_display_name(display_name)
    except InvalidStr as e:
        return failure_response(e.message, 400)

    # Check for valid bio
    bio = body.get("biography")
    try:
        if bio is not None:
            test_valid_bio(bio)
    except InvalidStr as e:
        return failure_response(e.message, 400)

    # Add user
    user = User(
        display_name=display_name,
        email=email,
        username=username,
        biography=bio,
        password_hash=salt_and_hash(password),
    )

    # Send confirmation email
    send_conf_email(user)

    db.session.add(user)
    db.session.commit()

    # Begin user session
    flask_login.login_user(user, remember=True)

    return success_response(user.serialize(user), 201)


class LoginError(Exception):
    def __init__(self, message: str, code: int) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


def login_w_password(email: str, plaintext: str) -> User:
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
    if not verify_password(plaintext, user.password_hash):
        raise LoginError("Incorrect password.", 401)
    return user


APPLE_PUBLIC_KEY = None
APPLE_KEY_CACHE_EXP = 60 * 60 * 24  # expire after 1 day
APPLE_LAST_KEY_FETCH = 0


def _fetch_apple_public_key(unverified_kid):
    """Fetch a specific public RSA key posted by Apple.

    :param unverified_kid: the unverified key ID specified in a JWT header
    :raise IndexError: if the unverified_kid does not match any public keys
    """
    # from https://gist.github.com/davidhariri/b053787aabc9a8a9cc0893244e1549fe
    # Check to see if the public key is unset or is stale before returning
    global APPLE_LAST_KEY_FETCH
    global APPLE_PUBLIC_KEY

    if (APPLE_LAST_KEY_FETCH + APPLE_KEY_CACHE_EXP) < int(
        time.time()
    ) or APPLE_PUBLIC_KEY is None:
        key_payload = requests.get(
            "https://appleid.apple.com/auth/keys"
        ).json()
        try:
            matching_key = next(
                k for k in key_payload["keys"] if k["kid"] == unverified_kid
            )
        except StopIteration:
            raise IndexError("Cannot find Key ID in Apple's public keys.")
        APPLE_PUBLIC_KEY = RSAAlgorithm.from_jwk(json.dumps(matching_key))
        APPLE_LAST_KEY_FETCH = int(time.time())

    return APPLE_PUBLIC_KEY


def login_w_apple(token: str) -> tuple[User, bool]:
    """Retrieve or create a user who has signed in with Apple.

    :return: User, user_created_flag
    :raise: LoginError if login fails
    """
    # See https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/authenticating_users_with_sign_in_with_apple#3383773
    try:
        kid_from_header = jwt.get_unverified_header(token)["kid"]
        decoded = jwt.decode(
            token,
            _fetch_apple_public_key(kid_from_header),
            audience=APPLE_CLIENT_ID,
            algorithms=["RS256"],
            options={"verify_signature": True},
        )
        apple_uuid = decoded["sub"]  # unique identifier of user
        email = decoded.get(
            "email"
        )  # email not included in ID token after initial sign in
        # As of now, 6/5/2022, Apple does not include name in the ID token
        # Although another request can retrieve it, I'm just gonna default to
        # empty display name
        display_name = decoded.get("name") or ""
        if decoded["nonce_supported"]:
            pass  # TODO: prevent replay attacks by verifying nonce
            # assert decoded["nonce"] ==
    except jwt.exceptions.ExpiredSignatureError:
        raise LoginError("Apple token has expired.", 400)
    except (
        jwt.exceptions.InvalidTokenError,
        IndexError,
        KeyError,
    ) as e:
        raise e
        raise LoginError("Failed to verify Apple token.", 400)

    # Check if user exists
    user_created = False

    if email is not None:
        user_w_email = User.query.filter_by(email=email).first()
        if (
            user_w_email is not None
            and user_w_email.login_method != LoginMethods.APPLE
        ):
            raise LoginError(
                "This email address is registered to an account using another login method.",
                400,
            )
    user_w_auuid = User.query.filter_by(apple_uuid=apple_uuid).first()
    if user_w_auuid is not None:
        user = user_w_auuid
    else:
        # User does not exist, add them.
        assert email is not None  # first time sign-in JWT must include email
        user = User(
            display_name=display_name, email=email, apple_uuid=apple_uuid
        )
        db.session.add(user)
        db.session.commit()
        user_created = True

    return user, user_created


def login_w_google(token: str) -> tuple[User, bool]:
    """Retrieve or create a user who has signed in with Google.

    :return: User, user_created_flag
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
                token, g_requests.Request(), G_CLIENT_IDS
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
    user_created = False
    user_w_gid = User.query.filter_by(google_id=gid).first()
    user_w_email = User.query.filter_by(email=email).first()

    if user_w_gid is None:
        if user_w_email is None:
            # User does not exist, add them.
            user = User(display_name=display_name, email=email, google_id=gid)
            db.session.add(user)
            db.session.commit()
            user_created = True
        else:
            # There is a user with this email but not the GID
            # Give login method specific error messages
            if user_w_email.login_method == LoginMethods.EMAIL:
                raise LoginError(
                    f"This account uses email/password sign-on.", 400
                )
            elif user_w_email.login_method == LoginMethods.APPLE:
                raise LoginError(f"This account uses Apple sign-on.", 400)
            else:
                # Generic response
                raise LoginError(
                    "This email was registered with another sign-on method.",
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
    return user, user_created


@routes.route("/callbacks/apple/", methods=["POST"])
def apple_callback():
    """The callback route for the REST 'Sign in with Apple' button.

    Dumps all forwarded information to the page.
    """
    error = request.form.get("error")
    if error is not None:
        return failure_response(error)
    else:
        return success_response(request.form)


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
            user, user_created = login_w_google(token)

        elif method == "apple":
            token = body.get("token")
            if token is None:
                return failure_response("Missing token.", 400)
            user, user_created = login_w_apple(token)

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


@routes.route("/usernames/<username>/check/")
def check_username(username):
    try:
        test_valid_username(username)
        valid = True
    except InvalidStr:
        valid = False
    available = User.is_username_unique(username)
    return success_response({"valid": valid, "available": available})


@routes.route("/users/<user_id>/")
@flask_login.login_required
def get_user(user_id):
    me = flask_login.current_user
    user = me if user_id == "me" else User.query.filter_by(id=user_id).first()
    # email confirmation required for any user who is not client
    if (
        user != me
        and me.login_method == LoginMethods.EMAIL
        and me.email_confirmed == False
    ):
        return failure_response("User must verify their email.", 401)
    if user is None:
        return failure_response("User not found.")
    return success_response(user.serialize(me))


@routes.route("/users/me/", methods=["PUT"])
@flask_login.login_required
@email_conf_required
def edit_me():
    me = flask_login.current_user

    body = json.loads(request.data)

    # Update username if it changed
    new_username = body.get("username")
    if new_username is not None and me.username != new_username:
        try:
            test_valid_username(new_username)
        except InvalidStr as e:
            return failure_response(e.message, 400)
        if not User.is_username_unique(new_username):
            return failure_response("Username unavailable", 409)
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
        # Check for valid bio
        try:
            test_valid_bio(new_bio)
        except InvalidStr as e:
            return failure_response(e.message, 400)
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
    # foreign keys. Cascades at the DB-level are signficantly faster than ORM.
    db.session.delete(me)
    db.session.commit()
    return success_response(code=204)
