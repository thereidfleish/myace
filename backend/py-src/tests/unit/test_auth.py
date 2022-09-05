"""Unit tests for user authentication helpers."""
import pytest

from app.routes import user_routes
from app.routes.user_routes import (
    verify_password,
    salt_and_hash,
    InvalidStr,
)


def test_hash():
    """Ensure passwords hash into different strings and are verifiable."""
    plaintext1 = "Mypassword"
    plaintext2 = "mypassword"
    h1 = salt_and_hash(plaintext1)
    h2 = salt_and_hash(plaintext2)
    assert h1 != h2
    assert h1 != plaintext1
    assert h2 != plaintext2
    assert verify_password(plaintext1, h1)
    assert verify_password(plaintext2, h2)


def test_invalid_pwds():
    """Ensure invalid passwords fail."""
    invalid_pwds = (
        "abcdefghijklm",
        "ABCDEFGHIJKLM",
        "1111111111111",
        "!!!!!!!!!!!!!",
        "Abc1",  # valid but too short
        "Abc!",  # valid but too short
        "ABCDEFGH!",  # needs one lowercase
        "ABC-EFGH1",  # needs one lowercase
        'abc-"fgh!',  # needs one uppercase
        "abcdefgh1",  # needs one uppercase
        "abcDEFG",  # needs symbol/number
        "Abc123!🥴",  # must only contain alphanumeric/symbol
    )
    for pwd in invalid_pwds:
        with pytest.raises(InvalidStr) as e_info:
            user_routes.test_valid_password(pwd)


def test_valid_pwds():
    """Ensure valid passwords succeed."""
    valid_pwds = (
        "aA1111",
        "aA!!!!",
        "Th1sIs4ReallyLongButValidP&$$W()rdTh1sIs4ReallyLongButValidP&$$W()rd",
    )
    for pwd in valid_pwds:
        user_routes.test_valid_password(pwd)
