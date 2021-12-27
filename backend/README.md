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
                "vid": "{video id}",
                "display_title": "{display title of video}"
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

## Videos

### Get all videos

**GET: /api/user/{user_id}/uploads/**

This route gets all the uploads for a user (identified by uid). The uploads do not contain the media but rather
their vid, display title, and tags.

Request: N/A

Response:
```json
{
    "uploads": [
        {
            "vid": 1,
            "display_title": "{the new display title for the video}",
            "tags": [
                {
                    "tid": 1,
                    "name": "backhand"
                }
            ]
        }
    ]
}
```

### Update video title

**POST: /api/upload/{upload_id}/update-title/**

This route updates the display title for an upload identified by vid.

Request:
```json
{
    "new_title": "{the new display title for the video}" or None (keeps display title the same)
}
```

Response:
```json
{
    "vid": "{video id}",
    "display_title": "{display title of video}",
    "tags": [
        {
            "tid": 1,
            "name": "backhand"
        }
    ]
}
```

### Get a specific video

**GET: /api/upload/{upload_id}/**

This route gets Apple's HTTPS livestreaming (HLS) playlist from our S3 bucket for the specified vid.

Request: N/A

Reponse:
```json
{
    "url": "www.something.m3u8",
}
```

### Upload a video

**GET: /api/upload/**

This route uses form data to post a video file to the S3 bucket in Apple's HLS format for livestreaming. This works
by first uploading the video to us and then using the vincentbernat/video2hls github repo to convert the video to the
proper HLS files. These are then uploaded to the S3 bucket.

Request encoding = form-data:
```json
{
    "file": <FILEDATA>
    "filename": "backhand.mp4",
    "display_title": "Backhand Serve 12-2-2021",
    "uid": 5
}
```

Response encoding = JSON:
```json
{
    "vid": 4
}
```

## Video tags

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

Response:
```json
{
    "vid": 1,
    "display_title": "{the new display title for the video}",
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
    "vid": 1,
    "display_title": "{the display title for the video}",
    "tags": []
}
```
