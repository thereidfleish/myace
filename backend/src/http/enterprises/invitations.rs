use super::Enterprise;
use crate::http::error::Error;
use crate::http::extractor::AuthUser;
use crate::http::permissions::ApiPermission;
use crate::http::{ApiContext, Result};

use axum::extract::Path;
use axum::http::StatusCode;
use axum::routing::{delete, get, post};
use axum::{extract::Extension, Json, Router};
use sqlx::types::time::OffsetDateTime;
use sqlx::types::Uuid;

pub fn router() -> Router {
    Router::new()
        .route(
            "/enterprises/:enterprise_id/invitations",
            post(create_invitation).get(invitations_for_enterprise),
        )
        .route("/enterprises/invitations", get(invitations_for_user))
        .route(
            "/enterprises/invitations/:invitation_id",
            delete(delete_invitation),
        )
        .route(
            "/enterprises/invitations/:invitation_id/accept",
            post(accept_invitation),
        )
}

/// A wrapper type for a response containing multiple invitations
#[derive(serde::Serialize)]
struct InvListBody<T> {
    invitations: Vec<T>,
}

#[derive(serde::Serialize, serde::Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "enterprise_role", rename_all = "snake_case")]
pub enum EnterpriseRole {
    Parent,
    Player,
    Instructor,
    Admin,
}

/// An invitation from the perspective of an enterprise manager.
#[derive(serde::Serialize)]
struct InvitationForEnterprise {
    invite_id: Uuid,
    user_email: String,
    role: EnterpriseRole,

    #[serde(with = "time::serde::iso8601")]
    created_at: OffsetDateTime,
}

/// An invitation from the perspective of the user to whom it is intended.
#[derive(serde::Serialize)]
struct InvitationForRecipient {
    invite_id: Uuid,
    role: EnterpriseRole,
    enterprise: Enterprise,

    #[serde(with = "time::serde::iso8601")]
    created_at: OffsetDateTime,
}

#[derive(sqlx::FromRow)]
pub(in crate::http) struct InvitationFromDB {
    invite_id: Uuid,
    user_email: String,
    role: EnterpriseRole,
    created_at: OffsetDateTime,
    enterprise_id: Uuid,
    enterprise_name: String,
    enterprise_website: Option<String>,
    enterprise_email: Option<String>,
    enterprise_phone: Option<String>,
    enterprise_logo: Option<String>,
    enterprise_created: OffsetDateTime,
}

impl From<InvitationFromDB> for InvitationForEnterprise {
    fn from(inv: InvitationFromDB) -> Self {
        InvitationForEnterprise {
            invite_id: inv.invite_id,
            user_email: inv.user_email,
            role: inv.role,
            created_at: inv.created_at,
        }
    }
}

impl From<InvitationFromDB> for InvitationForRecipient {
    fn from(inv: InvitationFromDB) -> Self {
        InvitationForRecipient {
            invite_id: inv.invite_id,
            role: inv.role,
            enterprise: Enterprise {
                enterprise_id: inv.enterprise_id,
                name: inv.enterprise_name,
                website: inv.enterprise_website,
                support_email: inv.enterprise_email,
                support_phone: inv.enterprise_phone,
                logo: inv.enterprise_logo,
                created_at: inv.enterprise_created,
            },
            created_at: inv.created_at,
        }
    }
}

#[derive(serde::Deserialize)]
struct NewInvitation {
    user_email: String,
    role: EnterpriseRole,
}

/// Invite a new or existing user to an enterprise.
async fn create_invitation(
    Path(enterprise_id): Path<Uuid>,
    Json(req): Json<NewInvitation>,
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<Json<InvitationForEnterprise>> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::CreateEnterpriseInvitation { enterprise_id },
        )
        .await?;
    // add the invitation to the database
    let invitation: InvitationForEnterprise = sqlx::query_as!(
        InvitationFromDB,
        r#"
        with new_invitation as (
            insert into "enterprise_invite"
            (enterprise_id, user_email, role)
            values ($1, $2, $3)
            returning *
        )
        select
            -- TODO: can I replace these with a wildcard?
            -- new_invitation.*,
            new_invitation.invite_id          invite_id,
            new_invitation.enterprise_id      enterprise_id,
            new_invitation.role               "role: EnterpriseRole",
            new_invitation.user_email         user_email,
            new_invitation.created_at         created_at,

            enterprise.name                   enterprise_name,
            enterprise.website                enterprise_website,
            enterprise.support_email          enterprise_email,
            enterprise.support_phone          enterprise_phone,
            enterprise.logo                   enterprise_logo,
            enterprise.created_at             enterprise_created
        from "enterprise"
        inner join "new_invitation"
        using (enterprise_id)
        --on enterprise.enterprise_id = new_invitation.enterprise_id
        ;"#,
        enterprise_id,
        req.user_email,
        req.role as EnterpriseRole
    )
    .fetch_optional(&ctx.db)
    .await?
    .ok_or_else(|| Error::NotFound("enterprise".to_string()))?
    .into();

    // TODO: send email invite
    // email should look different depending on if the user has an account or not
    todo!();

    Ok(Json(invitation))
}

/// Reject an invitation to join an enterprise.
async fn delete_invitation(
    Path(invitation_id): Path<Uuid>,
    auth_user: AuthUser,
    ctx: Extension<ApiContext>,
) -> Result<StatusCode> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::DeleteEnterpriseInvitation(invitation_id),
        )
        .await?;
    // delete the invitation
    sqlx::query!(
        r#"delete from "enterprise_invite" where invite_id = $1"#,
        invitation_id,
    )
    .fetch_one(&ctx.db)
    .await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Accept an invitation to join an enterprise.
async fn accept_invitation(
    auth_user: AuthUser,
    Path(invitation_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
) -> Result<StatusCode> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::AcceptEnterpriseInvitation(invitation_id),
        )
        .await?;
    // accept the invitation
    sqlx::query!(
        r#"select accept_invitation(invite_id => $1)"#,
        invitation_id,
    )
    .fetch_one(&ctx.db)
    .await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Get all incoming enterprise invitations for an existing user.
async fn invitations_for_user(
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<InvListBody<InvitationForRecipient>>> {
    // query invitations
    let invitations: Vec<InvitationForRecipient> = sqlx::query_as!(
        InvitationFromDB,
        r#"select
            invite_id,
            enterprise_id,
            role                              "role: EnterpriseRole",
            user_email,
            enterprise_invite.created_at      created_at,

            enterprise.name                   enterprise_name,
            enterprise.website                enterprise_website,
            enterprise.support_email          enterprise_email,
            enterprise.support_phone          enterprise_phone,
            enterprise.logo                   enterprise_logo,
            enterprise.created_at             enterprise_created
        from "enterprise"
        inner join "enterprise_invite" using (enterprise_id)
        where enterprise_invite.user_email = (select email from "user" where user_id = $1);"#,
        auth_user.user_id
    )
    .fetch_all(&ctx.db)
    .await?
    .into_iter()
    .map(|from_db| from_db.into())
    .collect();
    Ok(Json(InvListBody { invitations }))
}

/// Get all outgoing enterprise invitations for a specific enterprise.
async fn invitations_for_enterprise(
    Path(enterprise_id): Path<Uuid>,
    ctx: Extension<ApiContext>,
    auth_user: AuthUser,
) -> Result<Json<InvListBody<InvitationForEnterprise>>> {
    auth_user
        .check_permission(
            &ctx,
            ApiPermission::RetrieveOutgoingEnterpriseInvitations { enterprise_id },
        )
        .await?;
    // query invitations
    let invitations: Vec<InvitationForEnterprise> = sqlx::query_as!(
        InvitationFromDB,
        r#"select
            invite_id,
            enterprise_id,
            role                              "role: EnterpriseRole",
            user_email,
            enterprise_invite.created_at      created_at,

            enterprise.name                   enterprise_name,
            enterprise.website                enterprise_website,
            enterprise.support_email          enterprise_email,
            enterprise.support_phone          enterprise_phone,
            enterprise.logo                   enterprise_logo,
            enterprise.created_at             enterprise_created
        from "enterprise"
        inner join "enterprise_invite" using (enterprise_id)
        where enterprise_id = $1;"#,
        enterprise_id
    )
    .fetch_all(&ctx.db)
    .await?
    .into_iter()
    .map(|from_db| from_db.into())
    .collect();
    Ok(Json(InvListBody { invitations }))
}
