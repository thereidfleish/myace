"""Functional tests for all routes tagged with 'User'."""
import pytest
from dataclasses import dataclass

from flask.testing import FlaskClient

from . import (
    routes,
    HOST,
    USER_A_EMAIL,
    USER_B_EMAIL,
    USER_A_TOKEN,
    USER_B_TOKEN,
)
from .routes import User

VALID_PWD = "HelloWorld1!"


def test_register_preexisitng_email(test_client: FlaskClient):
    """Test registering a user with an email associated with another user."""
    # register acc with Google
    _, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created
    # attempt registering the same email with email/password
    with pytest.raises(AssertionError) as e_info:
        routes.register(
            test_client, USER_A_EMAIL, VALID_PWD, "myusername", "Display Name"
        )
    # reset
    routes.delete_user(test_client)
    # register acc with email
    routes.register(
        test_client, USER_A_EMAIL, VALID_PWD, "johnsmith", "John Smith"
    )
    # attempt registering another acc with the same email
    with pytest.raises(AssertionError) as e_info:
        routes.register(
            test_client, USER_A_EMAIL, VALID_PWD, "adlerweber", "Adler Weber"
        )
    # attempt logging into a google acc with the same email
    with pytest.raises(AssertionError) as e_info:
        routes.login_w_google(test_client, USER_A_TOKEN)


def test_invalid_register(test_client: FlaskClient):
    """Test register routes with invalid fields."""
    # register user B with Google
    user_b, created = routes.login_w_google(test_client, USER_B_TOKEN)
    assert created
    routes.logout(test_client)
    # attempt registering new acc with invalid emails
    invalid_emails = (
        "notanemail",
        "notanemail@",
        "notanemail@com",
        "@.com",
        "@test.com",
    )
    for email in invalid_emails:
        with pytest.raises(AssertionError) as e_info:
            routes.register(
                test_client, email, VALID_PWD, "john_smith_9", "John Smith"
            )
    # attempt registering new acc with invalid passwords
    invalid_passwords = (
        "",
        "\n\n\n\n\n\n\n",
        "🎾🎾🎾🎾🎾🎾🎾",
        "Boats and Hoes 123!",
        "short",
        "noNumbersOrSpecialChars",
        "nocapitalsorspecialchars1",
        "nocapitalornumbers!",
    )
    for pwd in invalid_passwords:
        with pytest.raises(AssertionError) as e_info:
            routes.register(
                test_client, USER_A_EMAIL, pwd, "john_smith_9", "John Smith"
            )
    # attempt registering new acc with invalid usernames
    invalid_usernames = (
        "",
        " ",
        "..........",
        "!1!1!1!1!1",
        "ab",
        "ABCDEFGH",
        "adler-weber",
        "adler weber",
        "adlerweber🥴",
        user_b.username,
    )
    for uname in invalid_usernames:
        print(uname)
        with pytest.raises(AssertionError) as e_info:
            routes.register(
                test_client, USER_A_EMAIL, VALID_PWD, uname, "John Smith"
            )
    # attempt registering new acc with invalid display names
    invalid_dnames = "        "
    for dname in invalid_dnames:
        with pytest.raises(AssertionError) as e_info:
            routes.register(
                test_client, USER_A_EMAIL, VALID_PWD, "john_smith_9", dname
            )
    # attempt registering new acc with invalid biographies
    invalid_bios = (
        "         ",
        "  \n\t\n  ",
        # 151 characters:
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    )
    for bio in invalid_bios:
        with pytest.raises(AssertionError) as e_info:
            routes.register(
                test_client,
                USER_A_EMAIL,
                VALID_PWD,
                "john_smith_9",
                "John Smith",
                bio,
            )


@dataclass
class TempUser:
    """Register and delete a user."""

    client: FlaskClient
    email: str
    password: str
    username: str
    dname: str
    bio: str

    def __enter__(self):
        self.user = routes.register(
            self.client,
            self.email,
            self.password,
            self.username,
            self.dname,
            self.bio,
        )
        return self.user

    def __exit__(self, *args):
        routes.login_w_password(self.client, self.email, self.password)
        routes.delete_user(self.client)


def test_valid_register(test_client: FlaskClient):
    """Test register routes with valid fields."""
    # Register w valid emails
    valid_emails = (USER_A_EMAIL, USER_B_EMAIL, "bob_8430@t.c.co")
    for email in valid_emails:
        with TempUser(  # type: ignore
            test_client,
            email,
            VALID_PWD,
            "username",
            "Display Name",
            "Biography",
        ) as user:
            assert type(user) == User
            assert user.email == email
    # Register w valid usernames
    valid_usernames = ["john.smith.9_"]
    for uname in valid_usernames:
        with TempUser(  # type: ignore
            test_client,
            USER_A_EMAIL,
            VALID_PWD,
            uname,
            "Display Name",
            "Biography",
        ) as user:
            assert type(user) == User
            assert user.username == uname
    # Register w valid display names
    valid_dnames = ("Mr. John Smith", "Coach Mary", "🎾")
    for dname in valid_dnames:
        with TempUser(  # type: ignore
            test_client,
            USER_A_EMAIL,
            VALID_PWD,
            "johnsmith",
            dname,
            "Biography",
        ) as user:
            assert type(user) == User
            assert user.dname == dname
    # Register w valid biographies
    valid_bios = ("Things I like:\n- good students\n- tennis", "🎾", "")
    for bio in valid_bios:
        with TempUser(  # type: ignore
            test_client,
            USER_A_EMAIL,
            VALID_PWD,
            "johnsmith",
            "John Smith",
            bio,
        ) as user:
            assert type(user) == User
            assert user.bio == bio


def test_register_and_login_w_password(test_client: FlaskClient):
    """Test register and login with password routes."""
    # register user
    initial = routes.register(
        test_client, "test@gmail.com", "TestPwd!", "test_user", "Display Name"
    )
    # logout
    routes.logout(test_client)
    assert routes.get_user_opt(test_client, initial.id) != initial
    # attempt login with invalid password
    with pytest.raises(AssertionError) as e_info:
        routes.login_w_password(test_client, "test@gmail.com", "testpwd!")
    # login
    final = routes.login_w_password(test_client, "test@gmail.com", "TestPwd!")
    assert final == initial


def test_register_w_google(test_client: FlaskClient):
    """Test logging in with Google for the first time."""
    # Invalid token fails login
    with pytest.raises(AssertionError) as e_info:
        routes.login_w_google(test_client, "invalidtoken")
    # Valid token produces user
    user, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert type(user) == User
    assert created


def test_logout(test_client: FlaskClient):
    """Test the logout route."""
    initial, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert type(initial) == User
    assert created
    # ensure logout works
    routes.logout(test_client)
    with pytest.raises(AssertionError) as e_info:
        routes.get_user(test_client)
    # ensure logging in again returns the same user
    final, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert not created
    assert initial == final
    routes.logout(test_client)


def test_get_current(test_client: FlaskClient):
    """Test get current user route."""
    user, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created
    assert routes.is_user_logged_in(test_client, user)
    assert routes.get_user(test_client) == user


def test_update_current(test_client: FlaskClient):
    """Test get current user route."""
    user, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created
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
    user_b, created_b = routes.login_w_google(test_client, USER_B_TOKEN)
    user_a, created_a = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created_a and created_b
    assert user_a != user_b
    with pytest.raises(AssertionError) as e_info:
        routes.update_user(test_client, username=user_b.username)
    # ensure update did not persist
    user, created_a = routes.login_w_google(test_client, USER_A_TOKEN)
    assert not created_a
    assert user == user_a


def test_delete_user(test_client: FlaskClient):
    """Test deleting current user."""
    user, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created
    routes.delete_user(test_client)
    assert not routes.is_logged_in(test_client)
    # ensure another login attempt with return "user created"
    user, created = routes.login_w_google(test_client, USER_A_TOKEN)
    assert created
