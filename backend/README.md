# API Specification

## Authentication

**POST /api/user/authenticate/**

This route returns a user's information given a Google OAuth token. If the user does not exist, the user is created. A Google account may be associated with multiple user IDs as long as the user IDs have different types. Therefore it is possible for someone to be both a player and a coach.

- `type`:
  - 0: player
  - 1: coach

Request:
```json
{
    "token": "{Google ID Token}",
    "type": 0
}
```

Response:
- 200: User fetched.
- 201: User created.

```json
{
    "id": 1,
    "display_name": "{User's display name}",
    "email": "{User's email}",
    "type": 0
}
```

## Uploads

### Get all uploads

**GET /api/user/{user_id}/uploads/**

Request: N/A

Response:
```json
{
    "uploads": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "display_title": "...",
            "stream_ready": true,
            "bucket_id": 1
            "comments": [
                {
                    "id": 1,
                    "created": "{ISO 8601 formatted timestamp}",
                    "author_id": 1,
                    "text": "Tennis goals!!! LOML 😍"
                },
                ...
            ]
        }
        ...
    ]
}
```

### Get a specific upload

**GET /api/user/{user_id}/upload/{upload_id}/**

This route returns a specific upload, containing the URL to Apple's HTTP Live Streaming (HLS) playlist. If `stream_ready` is false, the `url` field will be omitted from the response.

Request: N/A

Reponse:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "display_title": "...",
    "stream_ready": true,
    "bucket_id": 1,
    "comments": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "author_id": 1,
            "text": "Tennis goals!!! LOML 😍"
        },
        ...
    ],
    "url": "www.something.m3u8"
}
```

### Upload a video

**POST /api/user/{user_id}/upload/**

This route returns a presigned URL, which can be used to upload a video file directly to AWS using a **POST** request. 
The **POST** request must contain the specified `fields`. After a successful upload, the client should request to 
convert the media to a streamable format. Note that the client must also specify a valid bucket id for the user.

Request:
```json
{
    "filename": "fullcourtstock.mp4",
    "display_title": "My cool full court clip 😎",
    "bucket_id": 1
}
```

Response:
```json
{
    "id": <upload id>,
    "url": "<upload url>",
    "fields": {
        "key": "...",
        "x_amz_algorithm": "...",
        "x_amz_credential": "...",
        "x_amz_date": "...",
        "policy": "...",
        "x_amz_signature": "..."
    }
}
```

### Begin converting upload to stream ready format

**POST /api/user/{user_id}/upload/{upload_id}/convert/**

This route begins converting an upload into a streamable format.

*Should be deprecated in the near future when upload detection is working.*

Request: N/A

Response: N/A

### Edit upload

**PUT /api/user/{user_id}/upload/{upload_id}/**

Request:
```json
{
    "display_title": "{new upload display title}"
}
```

Response:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "display_title": "{upload display title}",
    "stream_ready": true,
    "bucket_id": 1,
    "comments": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "author_id": 1,
            "text": "Tennis goals!!! LOML 😍"
        },
        ...
    ]
}
```

## Comments

### Create a comment

**POST /api/upload/{upload_id}/comment/**

This route posts a comment under a certain upload. As of now, the only user allowed to comment is the upload owner.

Request:
```json
{
    "author_id": 1,
    "text": "Tennis goals!!! LOML 😍"
}
```

Response:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "author_id": 1,
    "upload_id": 1,
    "text": "Tennis goals!!! LOML 😍"
}
```

## Buckets

### Create a bucket

**POST /api/user/{user_id}/buckets/**

This route creates a bucket with the specified name and attaches it to the specified user. A user can have multiple
buckets of the same name. A user must create at least one bucket before uploading a video.

Request:
```json
{
    "name": "backhand"
}
```

Response:
```json
{
    "id": 1,
    "name": "Example Tag 1",
    "user_id": 1,
}
```

### Get bucket contents

**GET /api/user/{user_id}/bucket/{bucket_id}/**

This route gets all the uploads for a given bucket attached to a given user. If there are no uploads in this bucket, `last_modified` will be omitted.

Request: N/A

Response:
```json
{
    "id": 1,
    "name": "Example Tag 1",
    "user_id": 1,
    "last_modified": "{ISO 8601 formatted timestamp}",
    "uploads": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "display_title": "{upload display title}",
            "stream_ready": true,
            "bucket_id": 1,
            "comments": [
                {
                    "id": 1,
                    "created": "{ISO 8601 formatted timestamp}",
                    "author_id": 1,
                    "text": "Tennis goals!!! LOML 😍"
                },
                ...
            ]
        },
        ...
    ]
}
```

### Get user's buckets

**GET api/user/{user_id}/buckets/**

This route gets all the buckets for a given user id. If there are no uploads in a bucket, `last_modified` will be omitted.

Request: N/A

Response:
```json
{
    "buckets": [
        {
            "id": 1,
            "name": "Example Tag 1",
            "user_id": 1,
            "last_modified": "{ISO 8601 formatted timestamp}"
        },
        ...
    ]
}
```
