"""Defines fixtures available to all tests."""
import logging

import pytest

from app import create_app
from app.models import db as _db

from .functional import USER_A_GID, USER_B_GID, USER_C_GID

from .functional.routes import login, is_user_logged_in


@pytest.fixture
def app():
    """Create application for the tests."""
    _app = create_app()
    _app.logger.setLevel(logging.CRITICAL)
    ctx = _app.test_request_context()
    ctx.push()
    yield _app
    ctx.pop()


@pytest.fixture
def db(app):
    """Create database for the tests."""
    _db.app = app
    with app.app_context():
        _db.create_all()

    yield _db

    # Explicitly close DB connection
    _db.session.close()
    _db.drop_all()


@pytest.fixture(scope="function")
def test_client(app, db):
    """Create test client for functional tests."""
    with app.test_client() as client:
        # must be inside application context
        yield client
