"""Unit tests for application models."""
import pytest
from app.models import (
    User,
    UserRelationship,
    RelationshipType,
    Upload,
    VisibilityDefault,
    Bucket,
)


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


def add_and_commit(my_db, obj):
    my_db.session.add(obj)
    my_db.session.commit()


def test_n_uploads(db):
    """Test the User.n_uploads_visible_to method."""
    # setup two users with bucket containing uploads
    user_1 = User(1, "User 1", "user1@email.com")
    user_2 = User(2, "User 2", "user2@email.com")
    add_and_commit(db, user_1)
    add_and_commit(db, user_2)
    # setup bucket
    u1_bucket = Bucket(user_id=user_1.id, name="User 1's bucket")
    add_and_commit(db, u1_bucket)
    # share upload_1 with the public
    upload_1 = Upload(
        filename="test.mp4",
        display_title="Test upload 1",
        user_id=user_1.id,
        bucket_id=u1_bucket.id,
        visibility=VisibilityDefault.PUBLIC,
    )
    add_and_commit(db, upload_1)
    assert user_2.can_view_upload(upload_1)
    # share upload_2 exclusively with user_2
    upload_2 = Upload(
        filename="test.mp4",
        display_title="Test upload 2",
        user_id=user_1.id,
        bucket_id=u1_bucket.id,
        visibility=VisibilityDefault.PRIVATE,
    )
    add_and_commit(db, upload_2)
    upload_2.share_with([user_2])
    assert user_2.can_view_upload(upload_2)
    # check n uploads
    assert user_1.n_uploads_visible_to(user_2) == 2
    assert user_2.n_uploads_visible_to(user_1) == 0
    upload_2.unshare_with_all()
    assert not user_2.can_view_upload(upload_2)
    assert user_1.n_uploads_visible_to(user_2) == 1
    # share upload_3 with friends only
    upload_3 = Upload(
        filename="test.mp4",
        display_title="Test upload 3",
        user_id=user_1.id,
        bucket_id=u1_bucket.id,
        visibility=VisibilityDefault.FRIENDS_ONLY,
    )
    add_and_commit(db, upload_3)
    assert user_1.can_view_upload(upload_3)
    assert not user_2.can_view_upload(upload_3)
    # become friends and check again
    add_and_commit(
        db,
        UserRelationship(
            user_a_id=user_1.id,
            user_b_id=user_2.id,
            type=RelationshipType.FRIENDS,
        ),
    )
    assert user_2.can_view_upload(upload_3)
