"""Unit tests for application models."""
import pytest
from sqlalchemy import or_
from app.models import (
    User,
    UserRelationship,
    RelationshipType,
    Upload,
    VisibilityDefault,
    Bucket,
    Comment,
)


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


def add_and_commit(my_db, *objects):
    """Add and commit objects to the database."""
    for obj in objects:
        my_db.session.add(obj)
        my_db.session.commit()


def test_n_uploads(db):
    """Test the User.n_uploads_visible_to method."""
    # setup two users with bucket containing uploads
    user_1 = User("User 1", "user1@email.com", password_hash="abc")
    user_2 = User("User 2", "user2@email.com", password_hash="abc")
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


def test_delete_user(db):
    """Ensure user deletion cascades at the database level.

    No artifacts should be left.
    """
    # Setup user with all the bells and whistles
    user_1 = User(
        display_name="User 1", email="user1@email.com", google_id="test1"
    )
    user_2 = User(
        display_name="User 2", email="user2@email.com", google_id="test2"
    )
    user_3 = User(
        display_name="User 3", email="user3@email.com", google_id="test3"
    )
    add_and_commit(db, user_1, user_2, user_3)
    # setup bucket
    u1_bucket = Bucket(user_id=user_1.id, name="User 1's bucket")
    u2_bucket = Bucket(user_id=user_2.id, name="User 2's bucket")
    add_and_commit(db, u1_bucket, u2_bucket)
    # share upload_1 with the public
    upload_1 = Upload(
        filename="test.mp4",
        display_title="Test upload 1",
        user_id=user_1.id,
        bucket_id=u1_bucket.id,
        visibility=VisibilityDefault.PUBLIC,
    )
    add_and_commit(db, upload_1)
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
    # share upload_3 with friends and user_3
    upload_3 = Upload(
        filename="test.mp4",
        display_title="Test upload 3",
        user_id=user_1.id,
        bucket_id=u1_bucket.id,
        visibility=VisibilityDefault.FRIENDS_ONLY,
    )
    add_and_commit(db, upload_3)
    # user 2 owns upload 4
    u2_upload_4 = Upload(
        filename="test.mp4",
        display_title="Test upload 3",
        user_id=user_2.id,
        bucket_id=u2_bucket.id,
        visibility=VisibilityDefault.PUBLIC,
    )
    add_and_commit(db, u2_upload_4)
    # user_1 coaches user_2
    # user_1 becomes friends with user_3
    add_and_commit(
        db,
        UserRelationship(
            user_a_id=user_1.id,
            user_b_id=user_2.id,
            type=RelationshipType.A_COACHES_B,
        ),
        UserRelationship(
            user_a_id=user_1.id,
            user_b_id=user_3.id,
            type=RelationshipType.FRIENDS,
        ),
    )
    # user_3 comments on upload_1
    # user_1 comments on upload_4
    comment_1 = Comment(author_id=3, upload_id=1, text="comment 1")
    comment_2 = Comment(author_id=1, upload_id=4, text="comment 2")
    add_and_commit(db, comment_1, comment_2)
    # delete
    db.session.delete(user_1)
    # assert that no artifacts remain
    assert User.query.filter_by(id=1).count() == 0
    assert Bucket.query.filter_by(user_id=1).count() == 0
    assert Upload.query.filter_by(user_id=1).count() == 0
    assert Comment.query.filter_by(author_id=1).count() == 0
    assert (
        UserRelationship.query.filter(
            or_(
                UserRelationship.user_a_id == 1,
                UserRelationship.user_b_id == 1,
            )
        ).count()
        == 0
    )
