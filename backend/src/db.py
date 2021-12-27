from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

tag_association_table = db.Table(
    "tag_association",
    db.Model.metadata,
    db.Column("upload_id", db.Integer, db.ForeignKey("upload.id")),
    db.Column("tag_id", db.Integer, db.ForeignKey("tag.id"))
)

# TODO: transition from exposing primary keys in routes to using UUIDs or IDENTITY or SERIAL

# Player Table
class User(db.Model):
    __tablename__ = 'user'

    # Local User ID and Google Account ID combine to make primary key.
    id = db.Column(db.Integer, primary_key=True)
    google_id = db.Column(db.String, nullable=False)
    display_name = db.Column(db.String, nullable=False)
    email = db.Column(db.String, nullable=False)
    uploads = db.relationship("Upload", cascade="delete")

    # flask_sqlalchemy has an implicit constructor with column names

    def serialize(self):
        return {
            "id": self.id,
            "display_name": self.display_name,
            "email": self.email,
            "uploads": [u.serialize() for u in self.uploads]
        }


# Player Uploads Table
class Upload(db.Model):
    __tablename__ = 'upload'
    id = db.Column(db.Integer, primary_key=True)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow())
    stream_ready = db.Column(db.Boolean, nullable=False, default=False)
    display_title = db.Column(db.String, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"))
    tags = db.relationship("Tag", secondary=tag_association_table)

    def serialize(self):
        return {
            "id": self.id,
            "timestamp": self.timestamp,
            "display_title": self.display_title,
            "stream_ready": self.stream_ready,
            "tags": [t.serialize() for t in self.tags]
        }


# Global Tags Table
class Tag(db.Model):
    __tablename__ = "tag"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String, nullable=False)

    def serialize(self):
        return {
            "id": self.id,
            "name": self.name
        }
