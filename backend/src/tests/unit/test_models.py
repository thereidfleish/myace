"""Unit tests for application models."""
import pytest
from app.models import User


@pytest.mark.usefixtures("db")
class TestUser:
    """User tests."""

    def test_new_user(self):
        """Ensure a new user has the expected initial state."""
        user = User("John Smith", "johnsmith@email.com", google_id="abc")
        assert user.google_id == "abc"
        assert user.display_name == "John Smith"
        assert user.email == "johnsmith@email.com"
        assert type(user.username) == str
