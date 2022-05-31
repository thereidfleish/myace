# pip install .
from setuptools import setup

setup(
    name="app",
    packages=["app"],
    include_package_data=True,
    install_requires=[
        "boto3",
        "botocore",
        "cffi",
        "cryptography",
        "environs",
        "flask",
        "flask-login",
        "flask-sqlalchemy",
        "google-auth",
        "gunicorn",
        "psycopg2-binary",
        "requests",
    ],
)
