# pip install -e .
from setuptools import setup

setup(
    name="app",
    packages=["app"],
    include_package_data=True,
    install_requires=[
        "flask",
        "flask-sqlalchemy",
        "flask-login",
        "environs",
        "botocore",
        "boto3",
        "cryptography",
        "google-auth",
        "requests",
        "psycopg2",
        "pytest",
    ],
)
