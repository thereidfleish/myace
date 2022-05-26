#!/usr/bin/env python3
"""
The goal of the file is to provide automated testing.

TODO: Needs a lot of work
"""
from requests import Session

from models import *
import routes


def setup_social_network(
    user_a: Session, user_b: Session, user_c: Session
) -> None:
    """Create a social network between three users.

    A is friends with B. A coaches C.
    """
    pass  # TODO


def setup_test_environ() -> None:
    """Create a general purpose environment for manual testing.

    Contains various social networks, uploads, comments, etc.
    """
    pass  # TODO


def test_upload():
    # create upload
    # delete upload
    # ensure cannot get by ID
    pass  # TODO


if __name__ == "__main__":
    token = input("Enter Google Token: ")
    with Session() as s:
        routes.login(s, token)
        routes.create_upload(
            s,
            "./samplevids/fullcourtstock.mp4",
            "this post is friends only",
            1,
            VisibilitySetting("friends-only", []),
        )
        routes.create_upload(
            s,
            "./samplevids/fullcourtstock.mp4",
            "this post is coaches only",
            2,
            VisibilitySetting("coaches-only", []),
        )
        routes.create_upload(
            s,
            "./samplevids/fullcourtstock.mp4",
            "this post is public",
            2,
            VisibilitySetting("public", []),
        )
