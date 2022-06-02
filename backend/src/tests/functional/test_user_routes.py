"""Functional tests for all routes tagged with 'User'."""
import pytest
from flask.testing import FlaskClient

from . import routes, HOST, USER_A_TOKEN, USER_B_TOKEN
from .routes import User, Courtship


def test_login(test_client: FlaskClient):
    """Test the login route."""
    # Invalid token fails login
    with pytest.raises(AssertionError) as e_info:
        routes.login(test_client, "thisisinvalid")
    # Valid token produces user
    assert type(routes.login(test_client, USER_A_TOKEN)) == User


def test_logout(test_client: FlaskClient):
    """Test the logout route."""
    initial = routes.login(test_client, USER_A_TOKEN)
    assert type(initial) == User
    routes.logout(test_client)
    with pytest.raises(AssertionError) as e_info:
        routes.get_user(test_client)
    final = routes.login(test_client, USER_A_TOKEN)
    assert initial == final
    routes.logout(test_client)


def test_get_current(test_client: FlaskClient):
    """Test get current user route."""
    user = routes.login(test_client, USER_A_TOKEN)
    assert routes.is_user_logged_in(test_client, user)
    assert routes.get_user(test_client) == user


def test_get_user(test_client: FlaskClient):
    """Test getting another user with whom the client has a courtship."""
    user_a = routes.login(test_client, USER_A_TOKEN)
    # A requests that B coaches A
    routes.establish_courtship(
        test_client, USER_A_TOKEN, USER_B_TOKEN, "coach-req"
    )
    user_b = routes.login(test_client, USER_B_TOKEN)
    # user a from b's perspective
    user_a_from_b = routes.get_user_by_id(test_client, user_a.id)
    assert user_a_from_b.courtship == Courtship("student")
    assert user_a_from_b.id == user_a.id
    # check n_courtships
    assert user_a_from_b.n_coaches == 1
    assert user_a_from_b.n_friends == 0
    assert user_a_from_b.n_students == 0


def test_update_current(test_client: FlaskClient):
    """Test get current user route."""
    user = routes.login(test_client, USER_A_TOKEN)
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
    user_b = routes.login(test_client, USER_B_TOKEN)
    user_a = routes.login(test_client, USER_A_TOKEN)
    assert user_a != user_b
    with pytest.raises(AssertionError) as e_info:
        routes.update_user(test_client, username=user_b.username)
    # ensure update did not persist
    assert routes.login(test_client, USER_A_TOKEN) == user_a


def test_delete_user(test_client: FlaskClient):
    """Test deleting current user."""
    user = routes.login(test_client, USER_A_TOKEN)
    routes.delete_user(test_client)
    assert not routes.is_logged_in(test_client)
    body = {
        "token": USER_A_TOKEN,
    }
    res = test_client.post(f"{HOST}/login/", json=body)
    # ensure another login attempt with return "user created"
    assert res.status_code == 201
