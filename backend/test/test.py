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


def test_upload():
    path_to_file = "./samplevids/fullcourtstock.mp4"
    filename = os.path.basename(path_to_file)

    print("Requesting presigned upload URL")
    create_url_endpoint = "http://0.0.0.0:5000/api/user/1/upload/"
    body = {
        "filename": filename,
        "display_title": "My cool full court clip 😎"
    }
    create_url_res = requests.post(url=create_url_endpoint, json=body)
    log_response(create_url_res)
    assert create_url_res.status_code == 200
    create_url_res = create_url_res.json()
    id = create_url_res['id']
    print(f"The new post ID is:\n{id}")

    print("Uploading file to presigned URL")
    with open(path_to_file, 'rb') as f:
        files = {'file': (filename, f)}
        upload_res = requests.post(create_url_res['url'], data=create_url_res['fields'], files=files)
        log_response(upload_res)
        assert upload_res.status_code == 204


if __name__ == '__main__':
    test_upload()
