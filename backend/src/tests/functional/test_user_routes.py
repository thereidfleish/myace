"""Functional tests for all routes tagged with 'User'."""
import pytest
from flask.testing import FlaskClient

from . import routes, HOST
from .routes import User


def test_login(test_client: FlaskClient):
    """Test the login route."""
    # Invalid token fails login
    with pytest.raises(AssertionError) as e_info:
        routes.login(test_client, "thisisinvalid")
    # Valid token produces user
    assert type(routes.login(test_client, "backendtesttoken1")) == User


def test_logout(test_client: FlaskClient, user_a: User):
    """Test the logout route."""
    print("logged in" if routes.is_logged_in(test_client) else "not logged in")
    initial = routes.get_user(test_client)
    assert type(initial) == User
    routes.logout(test_client)
    with pytest.raises(AssertionError) as e_info:
        routes.get_user(test_client)
    final = routes.login(test_client, "backendtesttoken1")
    assert initial == final
    routes.logout(test_client)


def test_get_current(test_client: FlaskClient, user_a: User):
    """Test get current user route."""
    assert routes.is_user_logged_in(test_client, user_a)
    assert routes.get_user(test_client) == user_a


def test_update_current(test_client: FlaskClient, user_a: User):
    """Test get current user route."""
    new_name = "Bob"
    new_username = "abcdefghijklmnop"
    new_bio = "New biography!!"
    # Ensure user does not have these attributes
    assert user_a.dname != new_name
    assert user_a.username != new_username
    assert user_a.bio != new_bio
    routes.update_user(test_client, new_username, new_name, new_bio)
    # Ensure updated user does have these attributes
    updated = routes.get_user(test_client)
    assert updated.dname == new_name
    assert updated.username == new_username
    assert updated.bio == new_bio
    # Revert back to old conditions and compare
    routes.update_user(test_client, user_a.username, user_a.dname, user_a.bio)
    assert routes.get_user(test_client) == user_a
