use crate::http::error::{Error, ResultExt};
use crate::http::{ApiContext, Result};

use axum::extract::Path;
use axum::http::StatusCode;
use axum::routing::get;
use axum::{extract::Extension, Json, Router};
use sqlx::types::time::OffsetDateTime;
use sqlx::types::Uuid;

use super::extractor::AuthUser;
use super::permissions::ApiPermission;

pub mod invitations;
pub mod members;

pub fn router() -> Router {
    Router::new()
        .route(
            "/enterprises",
            get(get_all_enterprises).post(create_enterprise),
        )
        .route(
            "/enterprises/:enterprise_id",
            get(get_enterprise)
                .patch(update_enterprise)
                .delete(delete_enterprise),
        )
        .merge(invitations::router())
        .merge(members::router())
}

#[derive(serde::Serialize, sqlx::FromRow)]
struct EnterpriseFromDB {
    enterprise_id: Uuid,
    name: String,
    website: Option<String>,
    support_email: Option<String>,
    support_phone: Option<String>,
    logo: Option<String>,
    created_at: OffsetDateTime,
    updated_at: Option<OffsetDateTime>,
}

impl From<EnterpriseFromDB> for Enterprise {
    fn from(enterprise: EnterpriseFromDB) -> Self {
        Enterprise {
            enterprise_id: enterprise.enterprise_id,
            name: enterprise.name,
            website: enterprise.website,
            support_email: enterprise.support_email,
            support_phone: enterprise.support_phone,
            logo: enterprise.logo,
            created_at: enterprise.created_at,
        }
    }
}

/// A response that contains multiple enterprises
#[derive(serde::Serialize)]
struct EnterpriseList {
    enterprises: Vec<Enterprise>,
}

#[derive(serde::Serialize)]
pub struct Enterprise {
    pub enterprise_id: Uuid,
    pub name: String,
    pub website: Option<String>,
    pub support_email: Option<String>,
    pub support_phone: Option<String>,
    pub logo: Option<String>,

    #[serde(with = "time::serde::iso8601")]
    pub created_at: OffsetDateTime,
}

#[derive(serde::Deserialize)]
struct NewEnterprise {
    name: String,
    website: Option<String>,
    support_email: Option<String>,
    support_phone: Option<String>,
}

#[derive(serde::Deserialize)]
struct UpdateEnterprise {
    name: Option<String>,
    website: Option<String>,
    support_email: Option<String>,
    support_phone: Option<String>,
}

/// Get all enterprises
async fn get_all_enterprises(
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<Json<EnterpriseList>> {
    // check permissions
    auth_user
        .check_permission(&ctx, ApiPermission::RetrieveAllEnterprises)
        .await?;

    let enterprises: Vec<Enterprise> =
        sqlx::query_as!(EnterpriseFromDB, r#"select * from "enterprise""#)
            .fetch_all(&ctx.db)
            .await?
            .into_iter()
            .map(|ent| ent.into())
            .collect();
    Ok(Json(EnterpriseList { enterprises }))
}

/// Create a new enterprise
async fn create_enterprise(
    Json(req): Json<NewEnterprise>,
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<Json<Enterprise>> {
    // check permissions
    auth_user
        .check_permission(&ctx, ApiPermission::CreateEnterprise)
        .await?;

    let new_enterprise: Enterprise = sqlx::query_as!(
        EnterpriseFromDB,
        // TODO: add `auth_user` as an admin and restrict MyAce team access from accidental deletion
        r#"insert into "enterprise" (name, website, support_email, support_phone) values ($1, $2, $3, $4) returning *"#,
        req.name,
        req.website,
        req.support_email,
        req.support_phone,
    )
    .fetch_one(&ctx.db)
    .await
    .on_constraint("phone_number_check", |_| Error::InvalidPhone(req.support_phone.unwrap()))
    .on_constraint("email_address_check", |_| Error::InvalidEmail(req.support_email.unwrap()))?.into();

    Ok(Json(new_enterprise))
}

/// Retrieve a specific enterprise by ID
async fn get_enterprise(
    Path(enterprise_id): Path<Uuid>,
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<Json<Enterprise>> {
    auth_user
        .check_permission(&ctx, ApiPermission::RetrieveEnterprise(enterprise_id))
        .await?;
    let enterprise: Enterprise = sqlx::query_as!(
        EnterpriseFromDB,
        r#"select * from "enterprise" where enterprise_id = $1;"#,
        enterprise_id
    )
    .fetch_optional(&ctx.db)
    .await?
    .ok_or_else(|| Error::NotFound("enterprise".to_string()))?
    .into();
    Ok(Json(enterprise))
}

/// Update a specific enterprise by ID
async fn update_enterprise(
    Path(enterprise_id): Path<Uuid>,
    Json(req): Json<UpdateEnterprise>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<Enterprise>> {
    auth_user
        .check_permission(&ctx, ApiPermission::UpdateEnterprise(enterprise_id))
        .await?;
    let updated: Enterprise = sqlx::query_as!(
        EnterpriseFromDB,
        r#"update "enterprise"
           set
               name          = coalesce($1, name),
               website       = coalesce($2, website),
               support_email = coalesce($3),
               support_phone = coalesce($4)
           where enterprise_id = $5 returning *"#,
        req.name,
        req.website,
        req.support_email,
        req.support_phone,
        enterprise_id
    )
    .fetch_optional(&ctx.db)
    .await
    .on_constraint("phone_number_check", |_| {
        Error::InvalidPhone(req.support_phone.unwrap())
    })
    .on_constraint("email_address_check", |_| {
        Error::InvalidEmail(req.support_email.unwrap())
    })?
    .ok_or_else(|| Error::NotFound("enterprise".to_string()))?
    .into();
    Ok(Json(updated))
}

/// Delete a specific enterprise by ID
async fn delete_enterprise(
    Path(enterprise_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<StatusCode> {
    auth_user
        .check_permission(&ctx, ApiPermission::DeleteEnterprise(enterprise_id))
        .await?;
    let res = sqlx::query!(
        r#"delete from "enterprise" where enterprise_id = $1"#,
        enterprise_id
    )
    .execute(&ctx.db)
    .await?;

    if res.rows_affected() == 0 {
        Err(Error::NotFound("enterprise".to_string()))
    } else if res.rows_affected() == 1 {
        Ok(StatusCode::NO_CONTENT)
    } else {
        unreachable!();
    }
}
