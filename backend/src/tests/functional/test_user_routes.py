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


def test_logout(test_client: FlaskClient):
    """Test the logout route."""
    # initial = routes.get_user(test_client)
    # assert type(initial) == User
    # routes.logout(test_client)
    # with pytest.raises(AssertionError) as e_info:
    #     routes.get_user(test_client)
    # final = test_login(test_client)
    # assert initial == final
    # routes.logout(client)
