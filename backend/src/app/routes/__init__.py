"""Provides a flask blueprint to add all routes to app."""
import json

from flask import Blueprint

# All routes will bind to this blueprint
routes: Blueprint = Blueprint("routes", __name__)


def success_response(data: dict = {}, code: int = 200) -> tuple[str, int]:
    """:return: a successful, JSON-formatted string w/ response status code"""
    return json.dumps(data), code


def failure_response(message: str, code: int = 404) -> tuple[str, int]:
    """:return: a JSON-formatted string w/ response status code"""
    return json.dumps({"error": message}), code


# Yes, this is a cyclic import.
# However, I never access any member from these modules so should be fine.
# Alternatively, create a blueprint for each module and register them
# to routes on import. This solution is just less verbose.
from . import (
    user_routes,
    upload_routes,
    comment_routes,
    bucket_routes,
    courtship_routes,
)
