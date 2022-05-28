from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from .aws_util import AWS
from .settings import (
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
    CF_PUBLIC_KEY_ID,
    CF_PRIVATE_KEY,
)

login_manager = LoginManager()
db = SQLAlchemy()

# global AWS instance
aws = AWS(
    AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, CF_PUBLIC_KEY_ID, CF_PRIVATE_KEY
)
