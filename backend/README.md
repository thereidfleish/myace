⚠️  **Under construction**. Will be ready sometime 12/27 - 01/03 ⚠️

# API Specification

## Authentication

**POST: /api/user/authenticate/**

This route takes an encrypted Google authentication token as the request body. It then verifies the token with oauth and
decrypts it. If the user is not in the database, they are added to it. The response then contains the user's information
(such as their display name and email), as well as all their uploads.

Request:
```json
{
    "token": "{User's ID Token}"
}
```

Response:
```json
{
    "uid": "{User's local id}",
    "display_name": "{User's display name}",
    "email": "{User's email}"
    "uploads":
        [
            {
                "id": "{upload id}",
                "display_title": "..."
                "tags": [
                    {
                        "tid": 1,
                        "name": "backhand"
                    }
                    ...
                ]
            }
            ...
        ]
}
```

## Uploads

### Get all uploads

**GET: /api/user/{user_id}/uploads/**

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
            "tags": [
                ...
            ],
        }
        ...
    ]
}
```

### Get a specific upload with stream URL

**GET: /api/user/{user_id}/upload/{upload_id}/**

This route returns a specific upload, containing the URL to Apple's HTTP Live Streaming (HLS) playlist. If `stream_ready` is false, the `url` field will be omitted from the response.

Request: N/A

Reponse:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "display_title": "...",
    "stream_ready": true,
    "tags": [
        ...
    ],
    "url": "www.something.m3u8"
}
```

### Upload a video

**POST: /api/user/{user_id}/upload/**

This route returns an presigned URL, which can be used to upload a video file directly to AWS using a **POST** request. The **POST** request must contain the specified `fields`. After a successful upload, the client should request to convert the media to a streamable format.

Request:
```json
{
    "filename": "fullcourtstock.mp4",
    "display_title": "My cool full court clip 😎"
}
```

Response:
```json
{
    "id": <upload id>,
    "url": "<upload url>",
    "fields": {
        "key": "...", 
        "x-amz-algorithm": "...",
        "x-amz-credential": "...", 
        "x-amz-date": "...", 
        "policy": "...",
        "x-amz-signature": "..."
    }
}
```

### Begin converting upload to stream ready format

**POST: /api/user/{user_id}/upload/{upload_id}/convert/**

This route begins converting an upload into a streamable format.

*Should be deprecated when upload detection is working.*

Request: N/A

Response: N/A

### Edit upload

**PUT: /api/user/{user_id}/upload/{upload_id}/**

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
    "tags": [
        ...
    ]
}
```

## Tags

### Add a tag

**POST /api/upload/{upload_id}/tags/**

This route adds a tag with the specified name to a video. A new tag is only created in the database if it does
not already exist.

Request:
```json
{
    "name": "backhand"
}
```

TODO: return just serialized tag

Response:
```json
{
    "id": 1,
    "display_title": "{upload title}",
    "tags": [
        {
            "tid": 1,
            "name": "backhand"
        }
    ]
}
```

### Get all tags

**GET /api/upload/{upload_id}/tags/**

This route gets all the tags for a video identified with vid.

Request: N/A

Response:
```json
{
    "tags": [
        {
            "tid": 1,
            "name": "backhand"
        }
    ]
}
```

### Delete a tag

**DELETE /api/upload/{upload_id}/tag/{tid}/**

This route deletes a tag from a video. It does not delete the tag from the database, though.

Request: N/A

Response:
```json
{
    "id": 1,
    "display_title": "{upload title}",
    "tags": []
}
```
