"""Application configuration.
Most configuration is set via environment variables.
For local development, use a .env file to set environment variables.
"""
import os
from environs import Env

env = Env()
env.read_env()

# Misc environment variables
AWS_ACCESS_KEY_ID = env.str("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = env.str("AWS_SECRET_ACCESS_KEY")
# replace line delimeter characters '\n' with newlines and convert to bytes
CF_PRIVATE_KEY = env.str("CF_PRIVATE_KEY").replace("\\n", "\n").encode("utf-8")
CF_PUBLIC_KEY_ID = env.str("CF_PUBLIC_KEY_ID")
DB_ENDPOINT = env.str("DB_ENDPOINT")
DB_NAME = env.str("DB_NAME")
DB_PASSWORD = env.str("DB_PASSWORD")
DB_USERNAME = env.str("DB_USERNAME")
G_CLIENT_IDS = env.str("G_CLIENT_IDS").split(",")
S3_CF_DOMAIN = env.str("S3_CF_DOMAIN")
S3_CF_SUBDOMAIN = env.str("S3_CF_SUBDOMAIN")
VIEW_DOCS_KEY = env.str("VIEW_DOCS_KEY", default=os.urandom(24))


# Application configuration
ENV = env.str("FLASK_ENV", default="production")
DEBUG = ENV == "development"
CACHE_TYPE = "simple"  # Can be "memcached", "redis", etc.
SQLALCHEMY_DATABASE_URI = (
    f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}:5432/{DB_NAME}"
)
SECRET_KEY = env.str("FLASK_SECRET_KEY", default=os.urandom(24))
SQLALCHEMY_TRACK_MODIFICATIONS = False
