"""Functional tests for all routes tagged with 'User'."""
import pytest
from flask.testing import FlaskClient

from . import (
    routes,
    HOST,
    USER_A_GID,
    USER_B_GID,
)
from .routes import User


def test_login(test_client: FlaskClient):
    """Test the login route."""
    # Invalid token fails login
    with pytest.raises(AssertionError) as e_info:
        routes.login(test_client, "thisisinvalid")
    # Valid token produces user
    assert type(routes.login(test_client, USER_A_GID)) == User


def test_logout(test_client: FlaskClient):
    """Test the logout route."""
    initial = routes.login(test_client, USER_A_GID)
    assert type(initial) == User
    routes.logout(test_client)
    with pytest.raises(AssertionError) as e_info:
        routes.get_user(test_client)
    final = routes.login(test_client, USER_A_GID)
    assert initial == final
    routes.logout(test_client)


def test_get_current(test_client: FlaskClient):
    """Test get current user route."""
    user = routes.login(test_client, USER_A_GID)
    assert routes.is_user_logged_in(test_client, user)
    assert routes.get_user(test_client) == user


def test_update_current(test_client: FlaskClient):
    """Test get current user route."""
    user = routes.login(test_client, USER_A_GID)
    new_name = "Bob"
    new_username = "abcdefghijklmnop"
    new_bio = "New biography!!"
    # Ensure user does not have these attributes
    assert user.dname != new_name
    assert user.username != new_username
    assert user.bio != new_bio
    routes.update_user(test_client, new_username, new_name, new_bio)
    # Ensure updated user does have these attributes
    updated = routes.get_user(test_client)
    assert updated.dname == new_name
    assert updated.username == new_username
    assert updated.bio == new_bio
    # Revert back to old conditions and compare
    routes.update_user(test_client, user.username, user.dname, user.bio)
    assert routes.get_user(test_client) == user


def test_username_taken(test_client: FlaskClient):
    """Test that two users cannot have the same username."""
    # A cannot change username to B's username
    user_b = routes.login(test_client, USER_B_GID)
    user_a = routes.login(test_client, USER_A_GID)
    assert user_a != user_b
    with pytest.raises(AssertionError) as e_info:
        routes.update_user(test_client, username=user_b.username)
    # ensure update did not persist
    assert routes.login(test_client, USER_A_GID) == user_a


def test_delete_user(test_client: FlaskClient):
    """Test deleting current user."""
    user = routes.login(test_client, USER_A_GID)
    routes.delete_user(test_client)
    assert not routes.is_logged_in(test_client)
    body = {
        "token": USER_A_GID,
    }
    res = test_client.post(f"{HOST}/login/", json=body)
    # ensure another login attempt with return "user created"
    assert res.status_code == 201
