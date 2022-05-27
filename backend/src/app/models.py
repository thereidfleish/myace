# Allow forward declaration type hints
from __future__ import annotations

import datetime
import enum
import random
import re
import string
from sqlalchemy import or_, and_
from typing import List, Optional

from .extensions import db
from .aws import AWS

# TODO: transition from exposing primary keys in routes to using UUIDs or IDENTITY or SERIAL


# User Table
class User(db.Model):
    __tablename__ = "user"

    id = db.Column(db.Integer, primary_key=True)
    google_id = db.Column(db.String, nullable=False, unique=True)

    # Matches all characters disallowed in usernames. Allow alphanumeric, underscores, & periods.
    ILLEGAL_UNAME_PATTERN = r"[^\w\.]"
    username = db.Column(db.String, nullable=False, unique=True)

    display_name = db.Column(db.String, nullable=False)
    biography = db.Column(db.String, nullable=False, default="")
    email = db.Column(db.String, nullable=False, unique=True)
    uploads = db.relationship("Upload", back_populates="user")
    comments = db.relationship("Comment", back_populates="author")
    buckets = db.relationship("Bucket", back_populates="user")

    def __init__(self, google_id, display_name, email):
        self.google_id = google_id
        self.username = self._generate_unique_username(display_name)
        self.display_name = display_name
        self.email = email

    def serialize(self, client: User, show_private=False):
        """:return: a serialized User from the perspective of the client"""
        # public profile information
        response = {
            "id": self.id,
            "username": self.username,
            "display_name": self.display_name,
            "biography": self.biography,
            "n_uploads": self.n_uploads_visible_to(client),
            "n_courtships": {
                "friends": self.count_friends(),
                "coaches": self.count_coaches(),
                "students": self.count_students(),
            },
        }
        # private profile information
        # I believe the show_private param helps reduce the odds of data leaks
        if show_private and self.id == client.id:
            response["email"] = self.email
        return response

    def n_uploads_visible_to(self, client: User) -> int:
        """:return: The number of this user's uploads visible to the client."""
        return 0
        # visible = 0
        # for u in self.uploads:
        # TODO: fix this: raise TypeError("Boolean value of this clause is not defined")
        #     if client.can_view_upload(u):
        #         visible += 1
        # return visible

    def count_friends(self) -> int:
        """:return: the user's nonnegative friend count."""
        return UserRelationship.query.filter(
            and_(
                or_(
                    self.id == UserRelationship.user_a_id,
                    self.id == UserRelationship.user_b_id,
                ),
                UserRelationship.type == RelationshipType.FRIENDS,
            )
        ).count()

    def count_coaches(self) -> int:
        """:return: the user's nonnegative coach count."""
        return UserRelationship.query.filter(
            and_(
                self.id == UserRelationship.user_a_id,
                UserRelationship.type == RelationshipType.A_COACHES_B,
            )
        ).count()

    def count_students(self) -> int:
        """:return: the user's nonnegative student count."""
        return UserRelationship.query.filter(
            and_(
                self.id == UserRelationship.user_b_id,
                UserRelationship.type == RelationshipType.A_COACHES_B,
            )
        ).count()

    def get_relationship_with(self, other: User) -> Optional[UserRelationship]:
        """:return: a relationship with another user, or None if DNE"""
        a_to_b = db.session.query(UserRelationship).get((self.id, other.id))
        if a_to_b is not None:
            return a_to_b
        b_to_a = db.session.query(UserRelationship).get((other.id, self.id))
        return b_to_a

    def coaches(self, other: User) -> bool:
        """:return: True if this user coaches other."""
        return UserRelationship.query.filter_by(
            user_a_id=self.id,
            user_b_id=other.id,
            type=RelationshipType.A_COACHES_B,
        ).exists()

    def friends_with(self, other: User) -> bool:
        """:return: True if this user is friends with other."""
        rel = self.get_relationship_with(other)
        return rel is not None and rel.type == RelationshipType.FRIENDS

    def can_view_upload(self, upload: Upload) -> bool:
        """:return: True if the user is allowed to view a given upload."""
        # upload owners can always view their uploads
        if self.id == upload.user_id:
            return True
        # individual sharing trumps default visibility
        if self in upload.get_shared_with():
            return True
        # default visibility
        coaches_uploader = self.coaches(upload.user)
        friends_w_uploader = self.friends_with(upload.user)
        if upload.visibility == VisibilityDefault.PUBLIC:
            return True
        elif upload.visibility == VisibilityDefault.FRIENDS_AND_COACHES:
            return coaches_uploader or friends_w_uploader
        elif upload.visibility == VisibilityDefault.COACHES_ONLY:
            return coaches_uploader
        elif upload.visibility == VisibilityDefault.FRIENDS_ONLY:
            return friends_w_uploader
        else:
            return False

    def can_modify_upload(self, upload: Upload) -> bool:
        """:return: True if the user is allowed to modify an upload's properties."""
        return self.id == upload.user_id

    def can_comment_on_upload(self, upload: Upload) -> bool:
        """:return: True if the user is allowed to comment on a given upload."""
        return self.can_view_upload(upload)

    def can_view_comment(self, comment: Comment) -> bool:
        """:return: True if the user is allowed to view a given comment."""
        if not self.can_view_upload(comment.upload):
            return False
        # Prohibit viewing coach comments on uploads that the user doesn't own
        # TODO: fix can_view_comment
        # if comment.author.type == 1 and self.id != comment.upload.user_id:
        #     return False
        return True

    def can_modify_comment(self, comment: Comment) -> bool:
        """:return: True if the user is allowed to modify a given comment."""
        # Upload owners can modify all comments under upload. Commenters can modify their comments.
        owns_upload = self.id == comment.upload.user_id
        owns_comment = self.id == comment.author_id
        return owns_upload or owns_comment

    def can_view_bucket(self, bucket: Bucket) -> bool:
        """:return: True if the user is allowed to view a given bucket."""
        # Bucket owners can view all their buckets
        if self.id == bucket.user_id:
            return True
        # A bucket is viewable if it contains >=1 viewable uploads
        for u in bucket.uploads:
            if self.can_view_upload(u):
                return True
        return False

    def can_modify_bucket(self, bucket: Bucket) -> bool:
        """:return: True if the user is allowed to edit a given bucket's contents and properties"""
        return self.id == bucket.user_id

    @classmethod
    def _generate_unique_username(cls, display_name: str) -> str:
        """:return: a unique, legal username based off the user's display name."""
        # Santitize user's display name to use as root of username
        sanitized = re.sub(cls.ILLEGAL_UNAME_PATTERN, "", display_name).lower()
        # If sanitized display name is empty, use 3 random characters
        if sanitized == "":
            sanitized = "".join(
                random.choice(string.ascii_lowercase) for _ in range(3)
            )
        # Add random digit
        username = sanitized + random.choice(string.digits)
        # Continue adding digits until unique
        while not cls.is_username_unique(username):
            username += random.choice(string.digits)
        return username

    @staticmethod
    def is_username_unique(username: str) -> bool:
        """:return: if a username is unique."""
        return User.query.filter_by(username=username).first() is None

    @staticmethod
    def get_users_by_ids(user_ids: List[int]) -> List[User]:
        """:return: a list of ids to a list of users.

        Invalid IDs are ignored.
        """
        # naive implementation. TODO: optimize query
        users = []
        for id in user_ids:
            u = User.query.filter_by(id=id).first()
            if u is not None:
                users.append(u)
        return users

    # Methods required by Flask-Login

    @property
    def is_authenticated(self):
        # If the user model is accessible then the user is authenticated
        return True

    @property
    def is_active(self):
        # We don't support inactive/banned accounts
        return True

    @property
    def is_anonymous(self):
        # We don't support anonymous users
        return False

    def get_id(self):
        """:return: unicode representation of user ID"""
        return str(self.id)


@enum.unique
class RelationshipType(enum.Enum):
    """Exclusive states that may exist between two users"""

    # If you ever modify these values, the database type must be recreated:
    #   `DROP TYPE "typename";`
    # I'm using enum.auto() because the names are stored in the DB as strings.
    # The values are never stored in the DB.
    # user A has a pending friend request to user B
    FRIEND_REQUESTED = enum.auto()
    # user A and B are mutual friends
    FRIENDS = enum.auto()
    # user A is requesting that user B become their coach
    COACH_REQUESTED = enum.auto()
    # user A is requesting that user B become their student
    STUDENT_REQUESTED = enum.auto()
    # user A has user B as a student
    A_COACHES_B = enum.auto()
    # user A has blocked user B
    A_BLOCKED_B = enum.auto()
    B_BLOCKED_A = enum.auto()
    # both users have blocked each other
    MUTUAL_BLOCKED = enum.auto()

    def is_request(self):
        """:return: True if this relationship type is still pending"""
        return (
            self == self.FRIEND_REQUESTED
            or self == self.COACH_REQUESTED
            or self == self.STUDENT_REQUESTED
        )


# User relationship association object
class UserRelationship(db.Model):
    __tablename__ = "user_relationship"
    # Composite primary key ensures no identical, duplicate rows (as opposed to a surrogate key)
    # However, a duplicate relationship can still be exist if the user IDs are reversed.
    # It is an invariant that this must never happen.
    user_a_id = db.Column(db.ForeignKey("user.id"), primary_key=True)
    user_b_id = db.Column(db.ForeignKey("user.id"), primary_key=True)
    # Stores enum variable names as strings in DB. For now I think this is OK
    # bc it provides readability while only slightly compromising disk space.
    type = db.Column(db.Enum(RelationshipType), nullable=False)
    # The datetime of the last type change. Interpreted differently depending
    # on the type. Ex. if type is FRIENDS then means 'when users became friends'
    last_changed = db.Column(
        db.DateTime, nullable=False, default=datetime.datetime.utcnow
    )

    def serialize(self, client: User):
        """:return: a serialized UserRelationship from the perspective of the client"""
        assert (
            client.id == self.user_a_id or client.id == self.user_b_id
        ), "Precondition failed. Cannot serialize a UserRelationship if the client isn't involved."
        res = {
            "type": self.role_of_other(client),
            "user": self.get_other(client).serialize(client),
        }
        # add "dir" field if relationship is a request
        if self.type.is_request():
            res["dir"] = "out" if self.user_a_id == client.id else "in"
        return res

    def get_other(self, client: User) -> User:
        """:return: the other User involved in this relationship"""
        other_id = (
            self.user_b_id if client.id == self.user_a_id else self.user_a_id
        )
        return db.session.query(User).get(other_id)

    def role_of_other(self, client: User) -> str:
        """:return: the string represented role of the other user in this relationship from the perspective of the client"""
        if self.type == RelationshipType.FRIENDS:
            return "friend"
        elif (
            self.type == RelationshipType.A_COACHES_B
            and self.user_a_id == client.id
        ):
            # the other user is the student
            return "student"
        elif (
            self.type == RelationshipType.A_COACHES_B
            and self.user_b_id == client.id
        ):
            # the other user is the coach
            return "coach"
        elif self.type == RelationshipType.FRIEND_REQUESTED:
            return "friend-req"
        elif self.type == RelationshipType.STUDENT_REQUESTED:
            return "student-req"
        elif self.type == RelationshipType.COACH_REQUESTED:
            return "coach-req"
        else:
            raise Exception(
                "RelationshipType does not have a corresponding string."
            )


def rel_req_of_str(s: str) -> Optional[RelationshipType]:
    """:return: the pending (requested) RelationshipType representation of a string or None if DNE"""
    if s == "friend-req":
        return RelationshipType.FRIEND_REQUESTED
    elif s == "coach-req":
        return RelationshipType.COACH_REQUESTED
    elif s == "student-req":
        return RelationshipType.STUDENT_REQUESTED
    else:
        return None


@enum.unique
class VisibilityDefault(enum.Enum):
    """Exclusive visibility modes that are assigned to uploads in addition to individual sharing"""

    # If you ever modify these values, the database type must be recreated:
    #   `DROP TYPE "typename";`
    # I'm using enum.auto() because the names are stored in the DB as strings.
    # The values are never stored in the DB.
    # shared with nobody except author
    PRIVATE = enum.auto()
    # shared with just the user's coaches
    COACHES_ONLY = enum.auto()
    # shared with just the user's friends
    FRIENDS_ONLY = enum.auto()
    # shared with the user's friends and coaches
    FRIENDS_AND_COACHES = enum.auto()
    # shared with every user
    PUBLIC = enum.auto()


_v_map = {
    VisibilityDefault.PRIVATE: "private",
    VisibilityDefault.COACHES_ONLY: "coaches-only",
    VisibilityDefault.FRIENDS_ONLY: "friends-only",
    VisibilityDefault.FRIENDS_AND_COACHES: "friends-and-coaches",
    VisibilityDefault.PUBLIC: "public",
}


def visib_to_str(v: VisibilityDefault) -> str:
    """:return: string representation of a VisibilityDefault."""
    s = _v_map.get(v)
    if s is None:
        raise Exception(
            "VisibilityDefault does not have a corresponding string."
        )
    return s


def visib_of_str(s: Optional[str]) -> Optional[VisibilityDefault]:
    """:return: a VisibilityDefault or None if DNE."""
    for k, v in _v_map.items():
        if v == s:
            return k
    return None


# Visibility settings on an individual level
class UploadAlsoSharedWith(db.Model):
    __tablename__ = "upload_shared_with"
    # Composite primary key ensures no identical, duplicate rows (as opposed to a surrogate key)
    upload_id = db.Column(db.ForeignKey("upload.id"), primary_key=True)
    user_id = db.Column(db.ForeignKey("user.id"), primary_key=True)


# Upload Table
class Upload(db.Model):
    __tablename__ = "upload"
    id = db.Column(db.Integer, primary_key=True)
    created = db.Column(
        db.DateTime, nullable=False, default=datetime.datetime.utcnow
    )
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    user = db.relationship("User", back_populates="uploads")
    filename = db.Column(db.String, nullable=False)
    display_title = db.Column(db.String, nullable=False)
    visibility = db.Column(db.Enum(VisibilityDefault), nullable=False)
    # Mediaconvert
    mediaconvert_job_id = db.Column(db.String, nullable=True)
    stream_ready = db.Column(db.Boolean, nullable=False, default=False)
    # Bucket (each upload has to be created in a bucket)
    bucket_id = db.Column(
        db.Integer, db.ForeignKey("bucket.id"), nullable=False
    )
    bucket = db.relationship("Bucket", back_populates="uploads")
    # Comments
    comments = db.relationship("Comment", back_populates="upload")

    def serialize(self, client: User, aws: AWS):
        """:return: a serialized Upload from the perspective of the client"""
        # Check stream_ready
        if not self.stream_ready and self.mediaconvert_job_id is not None:
            status = aws.get_mediaconvert_status(self.mediaconvert_job_id)
            if status == "COMPLETE":
                self.stream_ready = True
                db.session.commit()
        response = {
            "id": self.id,
            "created": self.created.isoformat(),
            "display_title": self.display_title,
            "stream_ready": self.stream_ready,
            "bucket": self.bucket.serialize(client),
            "visibility": {
                "default": visib_to_str(self.visibility),
                "also_shared_with": [
                    u.serialize(client) for u in self.get_shared_with()
                ],
            },
        }
        if self.stream_ready:
            response["thumbnail"] = aws.get_thumbnail_url(
                str(self.id), expiration_in_hours=1
            )
        return response

    def get_shared_with(self) -> List[User]:
        """:return: A list of all Users with whom this upload has been individually shared"""
        shares = UploadAlsoSharedWith.query.filter_by(upload_id=self.id)
        return [User.query.filter_by(id=s.user_id).first() for s in shares]

    def share_with(self, users: List[User]) -> None:
        """Share this upload with a list of users"""
        for u in users:
            s = UploadAlsoSharedWith(upload_id=self.id, user_id=u.id)
            db.session.add(s)
        db.session.commit()

    def unshare_with_all(self) -> None:
        """Unshare this upload with all individuals"""
        UploadAlsoSharedWith.query.filter_by(upload_id=self.id).delete()
        db.session.commit()


# Comment Table
class Comment(db.Model):
    __tablename__ = "comment"
    id = db.Column(db.Integer, primary_key=True)
    author_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    author = db.relationship("User", back_populates="comments")
    upload_id = db.Column(
        db.Integer, db.ForeignKey("upload.id"), nullable=False
    )
    upload = db.relationship("Upload", back_populates="comments")
    created = db.Column(
        db.DateTime, nullable=False, default=datetime.datetime.utcnow
    )
    text = db.Column(db.String, nullable=False)

    def serialize(self, client: User):
        return {
            "id": self.id,
            "created": self.created.isoformat(),
            "author": self.author.serialize(client),
            "text": self.text,
            "upload_id": self.upload_id,
        }


# Bucket Table
class Bucket(db.Model):
    __tablename__ = "bucket"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    user = db.relationship("User", back_populates="buckets")
    created = db.Column(
        db.DateTime, nullable=False, default=datetime.datetime.utcnow
    )
    uploads = db.relationship("Upload", back_populates="bucket")

    def serialize(self, client: User):
        """:return: a serialized Bucket from the perspective of the client"""
        response = {"id": self.id, "name": self.name, "size": self._size()}
        last_modified = self._get_last_modified()
        response["last_modified"] = (
            self.created.isoformat()
            if last_modified is None
            else last_modified
        )
        return response

    def _size(self) -> int:
        """:return: A nonnegative count of all associated uploads"""
        return Upload.query.filter_by(bucket_id=self.id).count()

    def _get_last_modified(self) -> Optional[datetime.datetime]:
        """:return: the most recent upload's creation date in ISO format or None if there are no uploads"""
        most_recent = (
            Upload.query.filter_by(bucket_id=self.id)
            .order_by(Upload.created.desc())
            .first()
        )
        if most_recent is None:
            return None
        return most_recent.created.isoformat()
