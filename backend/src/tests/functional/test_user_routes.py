"""Functional tests for all routes tagged with 'User'."""
import pytest
from requests import Session

from . import routes


def user_session() -> Session:
    """Yield a new user session."""
    with Session() as s:
        yield s


def test_login():
    """Test the login route."""
    # token = input("Enter Google Token: ")
    # s = user_session()
    # # Invalid token fails login
    # with pytest.raises(AssertionError) as e_info:
    #     routes.login(s, "thisisinvalid")
    # # Valid token produces user
    # assert type(routes.login(s, token)) == User


def test_logout():
    """Test the logout route."""
    pass
