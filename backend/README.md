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
    "type": 0,
    "email": "{User's email}"
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
    "type": 0,
    "email": "{User's email}"
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
    "type": 0,
    "email": "{User's email}"
}
```

## Uploads

### Get all uploads

**GET /uploads**

If `stream_ready` is false, the `thumbnail` field will be omitted from the response.

Optional query parameters:
- `bucket`
    - Filter response to uploads in a given bucket ID.

Response:
```json
{
    "uploads": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "display_title": "...",
            "stream_ready": true,
            "bucket": {
                ...
            },
            "thumbnail": "www.something.jpg"
        },
        ...
    ]
}
```

### Get a specific upload

**GET /uploads/{upload_id}/**

This route returns a specific upload, containing the URL to Apple's HTTP Live Streaming (HLS) playlist and setting cookies which enable temporary URL access.
If `stream_ready` is false, the `url` and `thumbnail` fields will be omitted from the response.

Request: N/A

Response:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "display_title": "...",
    "stream_ready": true,
    "bucket": {
        ...
    },
    "url": "www.something.m3u8",
    "thumbnail": "www.something.jpg"
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

All fields are optional. If `stream_ready` is false, the `thumbnail` field will be omitted from the response.

Request:
```json
{
    "display_title": "{new upload display title}",
    "bucket_id": 2
}
```

Response:
```json
{
    "id": 1,
    "created": "{ISO 8601 formatted timestamp}",
    "display_title": "{upload display title}",
    "stream_ready": true,
    "bucket": {
        ...
    },
    "thumbnail": "www.something.jpg"
}
```

### Delete upload

**DELETE /uploads/{upload_id}/**

Note: Code 204 implies that the entry was found in both the database and the S3 bucket. Code 200 implies that it was
found in the database but not the S3 bucket. The database entry is still deleted.

Request: N/A

Response:

204: N/A

200:
```json
{
  "message": "Found entry in database but not in S3."
}
```

## Comments

### Get all comments

**GET /comments**

By default, this route returns all comments authored by the logged in user.

Optional query parameters:
- `upload`
    - Return all comments under a specific upload ID. Currently the user may only view comments on their own uploads.
- `user-type`
    - Filter response to comments created by a specific user type. The user may only view coach comments on their own uploads.

Response:
```json
{
    "comments": [
        {
            "id": 1,
            "created": "{ISO 8601 formatted timestamp}",
            "author": {
                "id": 1,
                "username": "{User's username}",
                "display_name": "{User's display name}",
                "type": 0
            },
            "text": "Tennis goals!!! LOML 😍",
            "upload_id": 1
        },
        ...
    ]
}
```

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
    "author": {
        "id": 1,
        "username": "{User's username}",
        "display_name": "{User's display name}",
        "type": 0
    },
    "text": "Tennis goals!!! LOML 😍",
    "upload_id": 1
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
}
```

### Get all buckets

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
            "last_modified": "{ISO 8601 formatted timestamp}"
        },
        ...
    ]
}
```

## Friends

### Search for users

**GET /users/search**

This route returns a list of users given a search query.

Request query parameters:
- `query`
    - The search query. Currently must match usernames exactly.

Response:
```json
{
    "users": [
        {
            "id": 1,
            "username": "{User's username}",
            "display_name": "{User's display name}",
            "type": 0
        },
        ...
    ]
}
```

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
