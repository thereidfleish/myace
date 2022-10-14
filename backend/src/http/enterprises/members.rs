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

use super::{invitations::EnterpriseRole, Enterprise};

pub fn router() -> Router {
    Router::new()
        .route(
            "/enterprises/:enterprise_id/members",
            get(enterprise_members),
        )
        .route("/memberships", get(get_all_user_memberships))
        .route(
            "/enterprises/:enterprise_id/members/:user_id",
            patch(edit_membership),
        )
        .route(
            "/enterprises/:enterprise_id/members/:user_id",
            delete(remove_member),
        )
}

/// A response containing the members of an enterprise from the perspective of an enterprise administrator.
#[derive(serde::Serialize)]
struct MembersInEnterprise {
    members: Vec<MemberInEnterprise>,
}

/// An enterprise membership from the perspective of an enterprise administrator.
#[derive(serde::Serialize)]
struct MemberInEnterprise {
    user: PublicUserWithEmail,
    role: EnterpriseRole,
    #[serde(with = "time::serde::iso8601")]
    member_since: OffsetDateTime,
}

/// All the memberships that a user has from the perspective of the member.
#[derive(serde::Serialize)]
struct MembershipsForMember {
    memberships: Vec<MembershipForMember>,
}

/// An enterprise membership from the perspective of the member
#[derive(serde::Serialize)]
pub struct MembershipForMember {
    pub enterprise: Enterprise,
    pub role: EnterpriseRole,
    #[serde(with = "time::serde::iso8601")]
    pub member_since: OffsetDateTime,
}

/// The request body to update a user's enterprise-specific information.
#[derive(serde::Deserialize)]
struct UpdateMember {
    role: EnterpriseRole,
}

/// Retrieve all members of a given enterprise
async fn enterprise_members(
    Path(enterprise_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<MembersInEnterprise>> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::RetrieveEnterpriseMembers(enterprise_id),
        )
        .await?;
    // query members
    let members: Vec<MemberInEnterprise> = sqlx::query!(
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
    .map(|db_res| MemberInEnterprise {
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
    Ok(Json(MembersInEnterprise { members }))
}

/// Get all enterprises to which the user belongs
async fn get_all_user_memberships(
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<Json<MembershipsForMember>> {
    let memberships: Vec<MembershipForMember> = sqlx::query!(
        r#"with memberships as (
            select
                enterprise_id,
                role              "role: EnterpriseRole",
                created_at         member_since
            from "enterprise_membership"
            where user_id = $1
        )
        select * from "enterprise"
           inner join "memberships"
           using (enterprise_id)
           "#,
        auth_user.user_id
    )
    .fetch_all(&ctx.db)
    .await?
    .into_iter()
    .map(|rec| MembershipForMember {
        enterprise: Enterprise {
            enterprise_id: rec.enterprise_id,
            name: rec.name,
            website: rec.website,
            support_email: rec.support_email,
            support_phone: rec.support_phone,
            logo: rec.logo,
            created_at: rec.created_at,
        },
        role: rec.role,
        member_since: rec.member_since,
    })
    .collect();
    Ok(Json(MembershipsForMember { memberships }))
}

/// Update a user's enterprise membership details
async fn edit_membership(
    Path(enterprise_id): Path<Uuid>,
    Path(user_id): Path<Uuid>,
    Json(req): Json<UpdateMember>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<MemberInEnterprise>> {
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

    Ok(Json(MemberInEnterprise {
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

/// Remove a member from an enterprise. This may be called by either the member or the enterprise manager.
async fn remove_member(
    Path((enterprise_id, user_id)): Path<(Uuid, Uuid)>,
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
