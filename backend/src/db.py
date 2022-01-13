import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

# TODO: transition from exposing primary keys in routes to using UUIDs or IDENTITY or SERIAL


# User Table
class User(db.Model):
    __tablename__ = 'user'

    # Local User ID and Google Account ID combine to make primary key.
    id = db.Column(db.Integer, primary_key=True)
    google_id = db.Column(db.String, nullable=False)
    display_name = db.Column(db.String, nullable=False)
    email = db.Column(db.String, nullable=False)
    # 0 = player, 1 = coach
    type = db.Column(db.Integer, nullable=False) # Player vs coach...See API docs for interpretation
    uploads = db.relationship("Upload", cascade="delete")
    comments = db.relationship("Comment", cascade="delete")
    buckets = db.relationship("Bucket", cascade="delete")

    # flask_sqlalchemy has an implicit constructor with column names

    def serialize(self):
        return {
            "id": self.id,
            "display_name": self.display_name,
            "email": self.email,
            "type": self.type
        }

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


# Upload Table
class Upload(db.Model):
    __tablename__ = 'upload'
    id = db.Column(db.Integer, primary_key=True)
    created = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow())
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    filename = db.Column(db.String, nullable=False)
    display_title = db.Column(db.String, nullable=False)
    # Mediaconvert
    mediaconvert_job_id = db.Column(db.String, nullable=True)
    stream_ready = db.Column(db.Boolean, nullable=False, default=False)
    # Bucket (each upload has to be created in a bucket)
    bucket_id = db.Column(db.Integer, db.ForeignKey("bucket.id"), nullable=False)
    # Comments
    comments = db.relationship("Comment", cascade="delete")

    def serialize(self, aws):
        if not self.stream_ready and self.mediaconvert_job_id is not None:
            status = aws.get_mediaconvert_status(self.mediaconvert_job_id)
            if status == 'COMPLETE':
                self.stream_ready = True
            print("fetching status. status=" + status)
            db.session.commit()
        return {
            "id": self.id,
            "created": self.created.isoformat(),
            "display_title": self.display_title,
            "stream_ready": self.stream_ready,
            "bucket_id": self.bucket_id,
            "comments": [c.serialize(show_upload_id=False) for c in self.comments],
        }


# Comment Table
class Comment(db.Model):
    __tablename__ = 'comment'
    id = db.Column(db.Integer, primary_key=True)
    author_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    upload_id = db.Column(db.Integer, db.ForeignKey("upload.id"), nullable=False)
    created = db.Column(db.DateTime, nullable=False, default=datetime.datetime.utcnow())
    text = db.Column(db.String, nullable=False)

    def serialize(self, show_upload_id=True):
        res = {
            "id": self.id,
            "created": self.created.isoformat(),
            "author_id": self.author_id,
        }
        if show_upload_id:
            res["upload_id"] = self.upload_id
        res["text"] = self.text
        return res


# Bucket Table
class Bucket(db.Model):
    __tablename__ = "bucket"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    uploads = db.relationship("Upload", cascade="delete")

    def serialize(self, aws, show_uploads=False):
        res = {
            "id": self.id,
            "name": self.name,
            "user_id": self.user_id,
        }
        last_modified = self.__get_last_modified()
        if last_modified is not None:
            res["last_modified"] = last_modified
        if show_uploads:
            res["uploads"] = [u.serialize(aws) for u in self.uploads]
        return res

    def __get_last_modified(self) -> datetime.datetime:
        """:return: the most recent upload's creation date in ISO format or None if there are no uploads"""
        most_recent = Upload.query.filter_by(bucket_id=self.id).order_by(Upload.created.desc()).first()
        if most_recent is None:
            return None
        return most_recent.created.isoformat()
