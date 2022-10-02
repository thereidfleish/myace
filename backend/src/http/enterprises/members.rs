use crate::http::{
    permissions::ApiPermission, users::PublicUserWithEmail, ApiContext, Error, Result,
};
use axum::{
    extract::Path,
    http::StatusCode,
    routing::{delete, get, patch},
    Extension, Json, Router,
};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::http::extractor::AuthUser;

use super::invitations::EnterpriseRole;

pub fn router() -> Router {
    Router::new()
        .route(
            "/enterprises/:enterprise_id/members",
            get(enterprise_members),
        )
        .route(
            "/enterprises/:enterprise_id/members/:user_id",
            patch(edit_membership),
        )
        .route(
            "/enterprises/:enterprise_id/members/:user_id",
            delete(remove_member),
        )
}

/// A response containing the members of an enterprise.
#[derive(serde::Serialize)]
struct EnterpriseMembers {
    members: Vec<EnterpriseMember>,
}

/// A member of an enterprise.
#[derive(serde::Serialize)]
struct EnterpriseMember {
    user: PublicUserWithEmail,
    role: EnterpriseRole,
    #[serde(with = "time::serde::iso8601")]
    member_since: OffsetDateTime,
}

/// The request body to update a user's enterprise-specific information.
#[derive(serde::Deserialize)]
struct UpdateMembership {
    role: EnterpriseRole,
}

/// Retrieve all members of a given enterprise
async fn enterprise_members(
    Path(enterprise_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<EnterpriseMembers>> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::RetrieveEnterpriseMembers(enterprise_id),
        )
        .await?;
    // query members
    let members: Vec<EnterpriseMember> = sqlx::query!(
        r#"
        with members as (
            select
                user_id,
                role              "role: EnterpriseRole",
                created_at         member_since
            from "enterprise_membership"
            where enterprise_id = $1
        )
        select *
        from "members"
        inner join "user" using (user_id)
        "#,
        enterprise_id
    )
    .fetch_all(&ctx.db)
    .await?
    .into_iter()
    .map(|db_res| EnterpriseMember {
        user: PublicUserWithEmail {
            user_id: db_res.user_id,
            username: db_res.username,
            display_name: db_res.display_name,
            biography: db_res.biography,
            email: db_res.email,
        },
        role: db_res.role,
        member_since: db_res.member_since,
    })
    .collect();
    Ok(Json(EnterpriseMembers { members }))
}

/// Update a user's enterprise membership details
async fn edit_membership(
    Path(enterprise_id): Path<Uuid>,
    Path(user_id): Path<Uuid>,
    Json(req): Json<UpdateMembership>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<EnterpriseMember>> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::UpdateEnterpriseMembership {
                enterprise_id,
                user_id,
            },
        )
        .await?;

    let db_res = sqlx::query!(
        r#"with member as (update "enterprise_membership"
               set role = $1
               where enterprise_id = $2 and user_id = $3
               returning
                   user_id,
                   role       "role: EnterpriseRole",
                   created_at  member_since
           )
           select *
           from "member"
           inner join "user" using (user_id)
           "#,
        req.role as EnterpriseRole,
        enterprise_id,
        user_id
    )
    .fetch_optional(&ctx.db)
    .await?
    .ok_or_else(|| Error::NotFound(format!("user {} in enterprise {}", user_id, enterprise_id)))?;

    Ok(Json(EnterpriseMember {
        user: PublicUserWithEmail {
            user_id: db_res.user_id,
            username: db_res.username,
            display_name: db_res.display_name,
            biography: db_res.biography,
            email: db_res.email,
        },
        role: db_res.role,
        member_since: db_res.member_since,
    }))
}

/// Remove a member from an enterprise
async fn remove_member(
    Path(enterprise_id): Path<Uuid>,
    Path(user_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<StatusCode> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::DeleteEnterpriseMembership {
                enterprise_id,
                user_id,
            },
        )
        .await?;
    // delete the membership
    let res = sqlx::query!(
        r#"delete from "enterprise_membership" where enterprise_id = $1 and user_id = $2"#,
        enterprise_id,
        user_id
    )
    .execute(&ctx.db)
    .await?;
    // ensure only 1 row was deleted
    if res.rows_affected() == 0 {
        Err(Error::NotFound(format!(
            "member {} in enterprise {}",
            user_id, enterprise_id
        )))
    } else if res.rows_affected() == 1 {
        Ok(StatusCode::NO_CONTENT)
    } else {
        unreachable!()
    }
}
