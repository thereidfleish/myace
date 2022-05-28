from flask.testing import FlaskClient

from . import routes, HOST
from app.settings import VIEW_DOCS_KEY


def test_docs(test_client: FlaskClient):
    """Test the login route."""
    # Invalid key -> unauthorized
    fake_key = "abc123ahhhhh"
    assert fake_key != VIEW_DOCS_KEY
    res = test_client.get(f"{HOST}/docs?key={fake_key}")
    assert res.status_code == 401
    # Valid key yields docs
    res = test_client.get(f"{HOST}/docs?key={VIEW_DOCS_KEY}")
    assert res.status_code == 200
    assert "MyAce API Documentation" in res.data.decode("utf-8")
