# API Specification

## Authentication

### Login

**POST /login/**

This route establishes a session given a Google OAuth token and returns a user. If the user does not exist, the user is created. A Google account may be associated with multiple user IDs as long as the user IDs have different types. Therefore it is possible for someone to be both a player and a coach.

Request:
```json
{
    "token": "{Google OAuth Token}",
    "type": 0
}
```

- `type`:
  - 0: player
  - 1: coach

Response:
- 200: User fetched.
- 201: User created.

```json
{
    "id": 1,
    "username": "{User's username}",
    "display_name": "{User's display name}",
    "email": "{User's email}",
    "type": 0
}
```

### Logout

**POST /logout/**

This route ends a user session. All sensitive routes will return `401` until the user's session is reestablished.

Request: N/A

Response: N/A

### Get current user

**GET /users/me/**

This route returns the user who is currently logged in.

Request: N/A

Response:

```json
{
    "id": 1,
    "username": "{User's username}",
    "display_name": "{User's display name}",
    "email": "{User's email}",
    "type": 0
}
```

### Update current user

**PUT /users/me/**

This route edits the profile of the user who is currently logged in. All fields are optional.

Request:

```json
{
    "username": "{New username}",
    "display_name": "{New display name}",
}
```

Response:

```json
{
    "id": 1,
    "username": "{User's username}",
    "display_name": "{User's display name}",
    "email": "{User's email}",
    "type": 0
}
```

## Uploads

### Get all uploads

**GET /uploads/**

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
        ...
    ]
}
```

### Get a specific upload

**GET /uploads/{upload_id}/**

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

**POST /uploads/**

This route returns a presigned URL, which must be used to upload a video file directly to AWS using a **POST** request.
The **POST** request to the AWS `url` must contain the specified `fields`. Furthermore, all field names
containing underscores within `fields`, such as `x_amz_date`, must be hyphenated (ex. `x-amz-date`) when uploading to AWS.
After a successful upload, the client should request to convert the media to a streamable format.

*TODO*: What happens if an upload fails?

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

**POST /uploads/{upload_id}/convert/**

This route begins converting an upload into a streamable format.

*Should be deprecated in the near future when upload detection is working.*

Request: N/A

Response: N/A

### Edit upload

**PUT /uploads/{upload_id}/**

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

**POST /comments/**

This route posts a comment under a certain upload. As of now, the only user allowed to comment is the upload owner.

Request:
```json
{
    "upload_id": 1,
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

### Delete a comment

**DELETE /comments/{comment_id}/**

This route deletes a comment. Upload owners may delete all comments under their uploads, and comment authors may
delete their comments.

Request: N/A

Response: N/A

## Buckets

### Create a bucket

**POST /buckets/**

This route creates a bucket with the specified name and attaches it to the logged in user. A user can have multiple
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
    "name": "{bucket name}",
    "user_id": 1
}
```

### Get bucket contents

**GET /buckets/{bucket_id}/**

This route gets all user uploads in a given bucket. If there are no uploads in this bucket, `last_modified` will be omitted.

Request: N/A

Response:
```json
{
    "id": 1,
    "name": "{bucket name}",
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

**GET /buckets/**

This route gets every bucket associated with the user. If there are no uploads in a bucket, `last_modified` will be omitted.

Request: N/A

Response:
```json
{
    "buckets": [
        {
            "id": 1,
            "name": "{bucket name}",
            "user_id": 1,
            "last_modified": "{ISO 8601 formatted timestamp}"
        },
        ...
    ]
}
```

## Friends

### Search for users

**GET /users?q=...**

This route returns a list of users given a URL encoded query. The query could include names or usernames. TODO How to handle emails? How to search by ID?

Request: N/A??

Response: N/A???

### Create a friend request

**POST /friends/requests/**

This route requests to friend a specified user. The current user cannot have an existing relationship status with the specified user.
For example, requesting to friend someone who has already requested to friend you will yield an error.

Request:
```json
{
    "user_id": 1
}
```

Response: N/A

### Get all friend requests

**GET /friends/requests/**

This route returns a list users associated with incoming and outgoing friend requests. An incoming friend is a
user who has requested to friend you, and an outgoing friend is someone who you have requested to friend.

Request: N/A

Response:
```json
{
    "incoming": [
        {
            "id": 1,
            "username": "{User's username}",
            "display_name": "{User's display name}",
            "email": "{User's email}",
            "type": 0
        },
        ...
    ],
    "outgoing": [
        ...
    ]
}
```

### Update incoming friend request

**PUT /friends/requests/{other_user_id}/**

This route responds to an incoming friend request.

Request:
```json
{
    "status": "declined"
}
```

- `status`: "accepted" | "declined"

Response: N/A

### Delete outgoing friend request

**DELETE /friends/requests/{other_user_id}/**

Request: N/A

Response: N/A

### Get all friends

**GET /friends/**

Request: N/A

Response:
```json
{
    "friends": [
        {
            "id": 1,
            "username": "{User's username}",
            "display_name": "{User's display name}",
            "email": "{User's email}",
            "type": 0
        },
        ...
    ]
}
```

### Remove friend

**DELETE /friends/{other_user_id}/**

Request: N/A

Response: N/A
