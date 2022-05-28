"""Defines fixtures available to all tests."""
import logging

import pytest

from app import create_app
from app.models import db as _db

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


@pytest.fixture
def test_client(app):
    """Create test client for functional tests. Client is shared across module."""
    with app.test_client() as client:
        # must be inside application context
        yield client


@pytest.fixture
def user(test_client):
    """Supply tests with a logged-in user."""
    user = login(test_client, "backendtesttoken1")
    assert is_user_logged_in(test_client, user)
    return user


@pytest.fixture
def login_user_a(test_client):
    """:return: client in which user A is logged in and the user"""
    user = login(test_client, "backendtesttoken1")
    assert is_user_logged_in(test_client, user)
    return test_client, user


@pytest.fixture
def login_user_b(test_client):
    """:return: client in which user B is logged in and the user"""
    user = login(test_client, "backendtesttoken2")
    assert is_user_logged_in(test_client, user)
    return test_client, user


@pytest.fixture
def login_user_c(test_client):
    """:return: client in which user C is logged in and the user"""
    user = login(test_client, "backendtesttoken3")
    assert is_user_logged_in(test_client, user)
    return test_client, user
