"""Defines fixtures available to all tests."""
import logging

import pytest

from app import create_app
from app.models import db as _db


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


@pytest.fixture
def test_client(app, scope="module"):
    """Create test client for functional tests. Client is shared across module."""
    with app.test_client() as client:
        # must be inside application context
        yield client
