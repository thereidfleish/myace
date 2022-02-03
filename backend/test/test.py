#!/usr/bin/env python3
"""
The goal of the file is to provide automated testing. 

TODO: Needs a lot of work
"""
import json
import os
import requests


def log_response(res):
    print("Got response:")
    print(f"Status: {res.status_code}")
    print(res.text)


def login(session, google_token):
    body = {
        "token": google_token,
        "type": 0,
    }
    response = session.post(url="http://localhost/login/", json=body)
    assert response.status_code == 200 or response.status_code == 201, "Failed to login!"


def test_upload(session, path_to_file):
    filename = os.path.basename(path_to_file)

    print("Requesting presigned upload URL")
    create_url_endpoint = "http://localhost/uploads/"
    body = {
        "filename": filename,
        "display_title": "My cool full court clip 😎",
        "bucket_id": 1
    }
    create_url_res = session.post(url=create_url_endpoint, json=body)
    log_response(create_url_res)
    assert create_url_res.status_code == 201, "Failed to get presigned upload URL!"
    create_url_res = create_url_res.json()
    id = create_url_res['id']
    print(f"The new post ID is:\n{id}")

    print("Uploading file to presigned URL")
    with open(path_to_file, 'rb') as f:
        files = {'file': (filename, f)}
        fields = create_url_res['fields']
        for old_key in list(fields):
            new_key = old_key.replace('_', '-')
            fields[new_key] = fields.pop(old_key)
        upload_res = session.post(create_url_res['url'], data=create_url_res['fields'], files=files)
        log_response(upload_res)
        assert upload_res.status_code == 204, "Failed to upload file to presigned URL!"

    print(f"Converting upload ID={id} to stream ready format.")
    create_url_res = session.post(url=f"http://localhost/uploads/{id}/convert/")
    assert create_url_res.status_code == 200, f"Failed to convert upload ID={id} to stream ready format!"


if __name__ == '__main__':
    token = input("Enter Google Token: ")
    with requests.Session() as s:
        login(s, token)
        test_upload(s, "./samplevids/fullcourtstock.mp4")
