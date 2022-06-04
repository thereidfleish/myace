"""Module that provides helpers email and generating temporary tokens.

Tutorial followed:
https://realpython.com/handling-email-confirmation-in-flask/
"""
from __future__ import annotations
import json
from typing import Callable
from functools import wraps

from itsdangerous import URLSafeTimedSerializer
from itsdangerous.exc import BadSignature

from flask import url_for, render_template
import flask_login
import boto3
from botocore.exceptions import ClientError

from . import settings
from .models import LoginMethods, User


def email_conf_required(route: Callable) -> Callable:
    """Decorator that ensures a user confirmes their email address if they registered via email.
    Requires that the user is authenticated.
    """
    # Copy the signature, name, docstring, etc of route into wrapper function
    @wraps(route)
    def verify(*args, **kwargs):
        user = flask_login.current_user
        assert (
            user.is_authenticated
        ), "Precondition failed. Cannot check if an anonymous user has confirmed their email."
        # Only require verification if the user registered via email/password.
        if (
            user.login_method == LoginMethods.EMAIL
            and user.email_confirmed == False
        ):
            return json.dumps({"error": "User must confirm their email."}), 401
        # Call the route normally, forwarding all arguments
        return route(*args, **kwargs)

    return verify


def generate_confirmation_token(email: str) -> str | bytes:
    """Generate a confirmation token containing an email."""
    serializer = URLSafeTimedSerializer(settings.SECRET_KEY)
    return serializer.dumps(email, salt=settings.SECURITY_PASSWORD_SALT)


def confirm_token(token: str | bytes, secs_valid_for=3600) -> str | None:
    """Get the email from a token or None if expired/invalid.

    :param secs_valid_for: The number of seconds for which the token is valid.
    """
    serializer = URLSafeTimedSerializer(settings.SECRET_KEY)
    try:
        email = serializer.loads(
            token,
            salt=settings.SECURITY_PASSWORD_SALT,
            max_age=secs_valid_for,
        )
    except BadSignature:
        return None
    return email


_ses = boto3.client(
    "ses",
    region_name=settings.SES_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
)


class EmailFailed(Exception):
    """An email was unable to send."""


def send_email(to, subject, html, text) -> None:
    """Send a transactional (non-marketing) email.

    Fails with print statement if DEBUG is true.

    :param to: The recipient's email address
    :param subject: The email's subject line
    :param html: The email body, possibly containing HTML.
    :param text: The email body for recipients with non-HTML email clients.
    :raise EmailFailed: if email could not send, containing error message.
    """
    if settings.DEBUG:
        print("Did not send email because app is in DEBUG mode.")
        return
    # Note: if still in sandbox, "to" must be verified
    # email character encoding
    CHARSET = "UTF-8"
    try:
        # Provide the contents of the email.
        response = _ses.send_email(
            Destination={
                "ToAddresses": [
                    to,
                ],
            },
            Message={
                "Body": {
                    "Html": {
                        "Charset": CHARSET,
                        "Data": html,
                    },
                    "Text": {
                        "Charset": CHARSET,
                        "Data": text,
                    },
                },
                "Subject": {
                    "Charset": CHARSET,
                    "Data": subject,
                },
            },
            Source=settings.SES_SENDER,
            # ConfigurationSetName=CONFIGURATION_SET,
        )
    # Display an error if something goes wrong.
    except ClientError as e:
        error = e.response["Error"]["Message"]
        raise EmailFailed(error)
    else:
        # email sent. Keeping this here for debugging.
        message_id = response["MessageId"]


def send_conf_email(to: User) -> None:
    """Send an account confirmation email to a user.

    :param to: The recipient
    :raise EmailFailed: if email could not send, containing error message.
    """
    token = generate_confirmation_token(to.email)
    link = url_for("routes.confirm_email", token=token, _external=True)
    html_body = render_template(
        "confirm_email.html", name=to.display_name, confirm_url=link
    )
    text_body = f"""
Welcome, {to.display_name}!

Please activate your email:
{link}

Have a great day!
    """
    subject = "Activate your account! 🎾"
    send_email(to.email, subject, html_body, f"")
