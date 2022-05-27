"""Unit tests for application models."""
import pytest
from app.models import User


@pytest.mark.usefixtures("db")
class TestUser:
    """User tests."""

    def test_new_user(self):
        """Ensure a new user has the expected initial state."""
        user = User(1, "John Smith", "johnsmith@email.com")
        assert user.google_id == 1
        assert user.display_name == "John Smith"
        assert user.email == "johnsmith@email.com"
        assert type(user.username) == str
