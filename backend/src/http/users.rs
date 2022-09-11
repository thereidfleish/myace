use crate::http::error::{Error, ResultExt};
use crate::http::types::Email;
use crate::http::{ApiContext, Result};

use anyhow::Context;
use axum::extract::Path;
use axum::http::StatusCode;
use axum::routing::{get, patch, post};
use axum::{extract::Extension, Json, Router};
use sqlx::types::time::OffsetDateTime;
use sqlx::types::Uuid;

use argon2::{
    password_hash::{PasswordHash, SaltString},
    Argon2,
};

use super::extractor::{AuthUser, MaybeAuthUser};

pub fn router() -> Router {
    Router::new()
        .route("/register", post(create_user))
        .route("/login", post(login))
        // .route("/users/forgot", post(forgot_password)) // TODO: implement
        .route("/users/:id", get(get_user))
        .route("/users/me", patch(update_me).delete(delete_me))
        .route("/usernames/:username/check", get(check_username))
}

#[derive(serde::Deserialize)]
#[serde(untagged)]
enum NewUser {
    TeamMember(NewMyAceTeamMember),
    User(NewAppUser),
}

#[derive(serde::Deserialize)]
struct NewMyAceTeamMember {
    email: Email,
    username: String,
    password: String,
    role: MyAceTeamRole,
    /// Credentials that allow the caller to create a MyAce team member
    server_password: String,
}

#[derive(serde::Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "myace_team_role", rename_all = "snake_case")]
pub enum MyAceTeamRole {
    Business,
    Frontend,
    Backend,
}

#[derive(serde::Deserialize)]
struct NewAppUser {
    username: String,
    display_name: Option<String>,
    biography: Option<String>,
    invite_code: String,
    password: String,
}

#[derive(serde::Deserialize)]
struct LoginUser {
    email: String,
    password: String,
}

#[derive(serde::Deserialize)]
struct UpdateUser {
    username: Option<String>,
    display_name: Option<String>,
    biography: Option<String>,
    password: Option<UpdatePassword>,
}

#[derive(serde::Deserialize)]
struct UpdatePassword {
    old_password: String,
    new_password: String,
}

/// Either a private or public user, depending on the currently authenticated user.
#[derive(serde::Serialize)]
#[serde(untagged)]
enum PrivatePublicUser {
    Private(PrivateUser),
    Public(PublicUser),
}

/// The public view of a user, which does **not** contain sensitive profile information.
#[derive(serde::Serialize)]
struct PublicUser {
    user_id: Uuid,
    username: String,
    display_name: String,
    biography: String,
}

/// The private view of a user, which **contains sensitive profile information**!
#[derive(serde::Serialize)]
struct PrivateUser {
    user_id: Uuid,
    username: String,
    display_name: String,
    biography: String,
    email: String,

    #[serde(with = "time::serde::iso8601")]
    created_at: OffsetDateTime,

    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,

    /// The user's JWT to be used for future authentication.
    #[serde(skip_serializing_if = "Option::is_none")]
    token: Option<String>,
}

#[derive(sqlx::FromRow)]
pub struct UserFromDB {
    user_id: Uuid,
    username: String,
    display_name: String,
    biography: String,
    email: String,
    password_hash: String,
    created_at: OffsetDateTime,
    updated_at: Option<OffsetDateTime>,
}

impl UserFromDB {
    /// Create a user type that **serializes sensitive fields**, such as the user's email, login
    /// token, and profile metadata.
    ///
    /// If `token` is set, the session may be automatically refreshed if the frontend updates its
    /// token based on this response.
    ///
    /// TODO: implement a more robust auth workflow with refresh tokens. Maybe something like [this](https://katifrantz.com/the-ultimate-guide-to-jwt-server-side-authentication-with-refresh-tokens)
    fn into_private(self, token: Option<String>) -> PrivateUser {
        PrivateUser {
            user_id: self.user_id,
            username: self.username,
            display_name: self.display_name,
            biography: self.biography,
            email: self.email,
            token,
            created_at: self.created_at,
            updated_at: self.updated_at,
        }
    }

    /// Create a user type that only serializes non-sensitive fields.
    fn into_public(self) -> PublicUser {
        PublicUser {
            user_id: self.user_id,
            username: self.username,
            display_name: self.display_name,
            biography: self.biography,
        }
    }
}

/// Accept an enterprise invitation and register a new user account, creating a new user session.
async fn create_user(
    ctx: Extension<ApiContext>,
    Json(req): Json<NewUser>,
) -> Result<(StatusCode, Json<PrivateUser>)> {
    let user: UserFromDB = match req {
        NewUser::TeamMember(user) => {
            let password_hash = hash_password(user.password).await?;
            // check server password matches
            if user.server_password != ctx.config.server_password {
                return Err(Error::IncorrectServerPassword);
            }
            // add team member
            sqlx::query_as!(
                UserFromDB,
                r#"
                -- create new user
                with new_user as (
                    insert into "user" (username, email, password_hash)
                    values ($1, $2, $3)
                    returning *
                ),
                -- create team entry
                cte_myace_team as (
                    insert into "myace_team" (user_id, role)
                    values ((select user_id from new_user), $4)
                )
                select * from new_user
                "#,
                user.username,
                user.email as Email,
                password_hash,
                user.role as MyAceTeamRole
            )
            .fetch_optional(&ctx.db)
            .await
            .on_constraint("uname_check", |_| {
                Error::InvalidUsername(user.username.clone())
            })
            .on_constraint("user_username_key", |_| {
                Error::UsernameTaken(user.username.clone())
            })?
            .ok_or_else(|| Error::NotFound("invite code".to_string()))?
        }
        NewUser::User(user) => {
            let password_hash = hash_password(user.password).await?;
            sqlx::query_as!(
                UserFromDB,
                r#"
                -- select enterprise invitation by code
                with cte_invite as (
                    select invite_id, enterprise_id, role, user_email
                    from "enterprise_invite"
                    where invite_code = $1
                ),
                -- insert new user row
                cte_user as (
                  insert into "user"
                  (username, display_name, biography, email, password_hash)
                  values ($2, $3, $4, (select user_email from cte_invite), $5)
                  returning *
                ),
                -- accept the enterprise invitation
                membership_id as (
                    select accept_invitation(invite_id => (select invite_id from cte_invite))
                )
                -- get the new user
                select * from cte_user"#,
                user.invite_code,
                user.username,
                user.display_name,
                user.biography,
                password_hash
            )
            .fetch_optional(&ctx.db)
            .await
            .on_constraint("uname_check", |_| {
                Error::InvalidUsername(user.username.clone())
            })
            .on_constraint("user_username_key", |_| {
                Error::UsernameTaken(user.username.clone())
            })?
            .ok_or_else(|| Error::NotFound("invite code".to_string()))?
        }
    };
    // create authentication token
    let token = AuthUser {
        user_id: user.user_id,
    }
    .to_jwt(&ctx);

    Ok((StatusCode::CREATED, Json(user.into_private(Some(token)))))
}

/// Create a user session by verifying a registered user's username and password.
async fn login(
    ctx: Extension<ApiContext>,
    Json(req): Json<LoginUser>,
) -> Result<Json<PrivateUser>> {
    let user = sqlx::query_as!(
        UserFromDB,
        r#"select * from "user" where email = $1"#,
        req.email,
    )
    .fetch_optional(&ctx.db)
    .await?
    .ok_or(Error::NotFound("account with email".to_string()))?;

    verify_password(&req.password, &user.password_hash).await?;

    // create authentication token
    let token = AuthUser {
        user_id: user.user_id,
    }
    .to_jwt(&ctx);

    Ok(Json(user.into_private(Some(token))))
}

/// Get a user by ID. Return private info only if the authenticated user requests themselves.
async fn get_user(
    auth_user: MaybeAuthUser,
    Path(id): Path<Uuid>,
    ctx: Extension<ApiContext>,
) -> Result<Json<PrivatePublicUser>> {
    let user = sqlx::query_as!(UserFromDB, r#"select * from "user" where user_id = $1"#, id)
        .fetch_optional(&ctx.db)
        .await?
        .ok_or_else(|| Error::NotFound("user".to_string()))?;

    // check if requested user is the authenticated user
    let user = match auth_user.user_id() {
        Some(_) => PrivatePublicUser::Private(user.into_private(None)),
        None => PrivatePublicUser::Public(user.into_public()),
    };

    Ok(Json(user))
}

/// Update the authorized user's account info
async fn update_me(
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
    Json(req): Json<UpdateUser>,
) -> Result<Json<PrivateUser>> {
    // handle password update
    let password_hash = if let Some(UpdatePassword {
        old_password,
        new_password,
    }) = req.password
    {
        // verify old password matches
        let old_hash = sqlx::query_scalar!(
            r#"select password_hash from "user" where user_id = $1"#,
            auth_user.user_id
        )
        .fetch_one(&ctx.db)
        .await?;
        verify_password(&old_password, &old_hash).await?;
        // hash new password
        hash_password(new_password).await.map(|hash| Some(hash))
    } else {
        Ok(None)
    }?;

    let user = sqlx::query_as!(
        UserFromDB,
        r#"update "user"
           set
               username      = coalesce($1, username),
               display_name  = coalesce($2, display_name),
               biography     = coalesce($3, biography),
               password_hash = coalesce($4, password_hash)
           where user_id = $5 returning *"#,
        req.username,
        req.display_name,
        req.biography,
        password_hash,
        auth_user.user_id
    )
    .fetch_one(&ctx.db)
    .await
    .on_constraint("uname_check", |_| {
        Error::InvalidUsername(req.username.clone().unwrap())
    })
    .on_constraint("user_username_key", |_| {
        Error::UsernameTaken(req.username.clone().unwrap())
    })?;
    Ok(Json(user.into_private(None)))
}

/// Delete the authorized user's account.
async fn delete_me(auth_user: AuthUser, ctx: Extension<ApiContext>) -> Result<StatusCode> {
    sqlx::query!(
        r#"delete from "user" where user_id = $1"#,
        auth_user.user_id
    )
    .execute(&ctx.db)
    .await?;
    Ok(StatusCode::NO_CONTENT)
}

#[derive(serde::Serialize)]
struct AvailableResponse {
    available: bool,
}

/// Check the availability of a username.
async fn check_username(
    Path(username): Path<String>,
    ctx: Extension<ApiContext>,
) -> Result<Json<AvailableResponse>> {
    let available = sqlx::query_scalar!(r#"select 1 from "user" where username = $1"#, username)
        .fetch_optional(&ctx.db)
        .await?
        .is_none();
    Ok(Json(AvailableResponse { available }))
}

/// Attempt to hash a password using Argon2
async fn hash_password(password: String) -> Result<String> {
    // Argon2 hashing is designed to be computationally intensive, so this should be done on a
    // blocking thread rather than a core tokio thread
    Ok(tokio::task::spawn_blocking(|| -> Result<String> {
        let salt = SaltString::generate(rand::thread_rng());
        Ok(
            PasswordHash::generate(Argon2::default(), password, salt.as_str())
                .map_err(|e| anyhow::anyhow!("failed to generate password hash: {}", e))?
                .to_string(),
        )
    })
    .await
    .context("panic in generating password hash")??)
}

/// Verify that an Argon2 password hash matches plaintext.
///
/// # Errors
///
/// This function will return an error if the verification fails.
async fn verify_password<'a>(password: &'a str, password_hash: &'a str) -> Result<()> {
    let password = password.to_string();
    let password_hash = password_hash.to_string();
    Ok(tokio::task::spawn_blocking(move || -> Result<()> {
        let hash = PasswordHash::new(&password_hash)
            .map_err(|e| anyhow::anyhow!("invalid password hash: {}", e))?;

        hash.verify_password(&[&Argon2::default()], password)
            .map_err(|e| match e {
                argon2::password_hash::Error::Password => Error::IncorrectPassword,
                _ => anyhow::anyhow!("failed to verify password hash: {}", e).into(),
            })
    })
    .await
    .context("panic in verifying password hash")??)
}
