use std::fmt;

use super::enterprises::invitations::EnterpriseRole;
use super::{extractor::AuthUser, Error};
use crate::http::users::MyAceTeamRole;
use crate::http::ApiContext;
use sqlx::{Pool, Postgres};
use uuid::Uuid;

/// Helps improve readability in permission logic.
trait PermissionShortcut {
    fn forbid_false(self, action: ApiPermission) -> Result<(), Error>;
}

impl PermissionShortcut for bool {
    /// Returns `Ok(())` if `true` or `Err(Error::Forbidden)` otherwise.
    fn forbid_false(self, action: ApiPermission) -> Result<(), Error> {
        self.then_some(()).ok_or_else(|| Error::Forbidden(action))
    }
}

impl AuthUser {
    /// Query the database to check the role of a user within the app team.
    ///
    /// # Errors
    /// This function will error if the query fails.
    async fn myace_team_role(&self, db: &Pool<Postgres>) -> Result<Option<MyAceTeamRole>, Error> {
        let role = sqlx::query_scalar!(
            r#"select role "role:MyAceTeamRole" from "myace_team" where user_id = $1"#,
            self.user_id
        )
        .fetch_optional(db)
        .await?;
        Ok(role)
    }

    /// Query the database to check the role of a user within an enterprise.
    ///
    /// # Errors
    /// This function will error if the query fails.
    async fn enterprise_role(
        &self,
        db: &Pool<Postgres>,
        enterprise_id: Uuid,
    ) -> Result<Option<EnterpriseRole>, Error> {
        let role = sqlx::query_scalar!(
            r#"select role "role:EnterpriseRole" from "enterprise_membership" where user_id = $1 and enterprise_id = $2"#,
            self.user_id,
            enterprise_id
        )
        .fetch_optional(db)
        .await?;
        Ok(role)
    }

    /// Check if a user has permission to perform some API action.
    /// # Errors
    /// This function errors a `403 Forbidden` if the user does not have permission or a database error if a query fails.
    pub(in crate::http) async fn check_permission(
        &self,
        ctx: &ApiContext,
        action: ApiPermission,
    ) -> Result<(), Error> {
        // Long term TODO: make these available in ApiContext and then broadcast user permissions to frontend
        match action {
            ApiPermission::ViewAPIDocumentation => match self.myace_team_role(&ctx.db).await? {
                // anyone on the team can view API docs
                Some(_) => Ok(()),
                None => Err(Error::Forbidden(action)),
            },
            ApiPermission::CreateEnterprise => match self.myace_team_role(&ctx.db).await? {
                Some(MyAceTeamRole::Backend) | Some(MyAceTeamRole::Frontend) => Ok(()),
                _ => Err(Error::Forbidden(action)),
            },
            ApiPermission::RetrieveAllEnterprises => match self.myace_team_role(&ctx.db).await? {
                Some(_) => Ok(()),
                None => Err(Error::Forbidden(action)),
            },
            // anyone can view an enterprise
            ApiPermission::RetrieveEnterprise(_) => Ok(()),
            ApiPermission::UpdateEnterprise(enterprise_id) => {
                match self.enterprise_role(&ctx.db, enterprise_id).await? {
                    Some(EnterpriseRole::Admin) => Ok(()),
                    _ => Err(Error::Forbidden(action)),
                }
            }
            ApiPermission::DeleteEnterprise(enterprise_id) => {
                let enterprise_role = self.enterprise_role(&ctx.db, enterprise_id);
                let myace_role = self.myace_team_role(&ctx.db);

                // The team can delete any enterprise they want
                if myace_role.await?.is_some() {
                    return Ok(());
                }

                match enterprise_role.await? {
                    Some(EnterpriseRole::Admin) => Ok(()),
                    _ => Err(Error::Forbidden(action)),
                }
            }
            ApiPermission::AcceptEnterpriseInvitation(invitation_id) => {
                // check invite exists and get the recipient's ID
                let recipient_id = sqlx::query_scalar!(
                    r#"select user_id
                    from "user" inner join "enterprise_invite" on email = user_email
                    where invite_id = $1"#,
                    invitation_id
                )
                .fetch_optional(&ctx.db)
                .await?
                .ok_or_else(|| Error::NotFound("invitation for user".to_string()))?;
                // ensure user IDs match
                if self.user_id == recipient_id {
                    Ok(())
                } else {
                    Err(Error::Forbidden(action))
                }
            }
            ApiPermission::DeleteEnterpriseInvitation(invite_id) => {
                // check invite exists and get the recipient's ID
                let invite = sqlx::query!(
                    r#"select user_id as recipient_id, enterprise_id
                    from "user" inner join "enterprise_invite" on email = user_email
                    where invite_id = $1"#,
                    invite_id
                )
                .fetch_optional(&ctx.db)
                .await?
                .ok_or_else(|| Error::NotFound("invitation for user".to_string()))?;

                // ensure user is either the enterprise admin or the recipient of the invitation
                let is_admin = match self.enterprise_role(&ctx.db, invite.enterprise_id).await? {
                    Some(EnterpriseRole::Admin) => true,
                    _ => false,
                };
                if is_admin || self.user_id == invite.recipient_id {
                    Ok(())
                } else {
                    Err(Error::Forbidden(action))
                }
            }
            ApiPermission::CreateEnterpriseInvitation { enterprise_id } => {
                match self.enterprise_role(&ctx.db, enterprise_id).await? {
                    Some(EnterpriseRole::Admin) => Ok(()),
                    _ => Err(Error::Forbidden(action)),
                }
            }
            ApiPermission::RetrieveOutgoingEnterpriseInvitations { enterprise_id } => {
                match self.enterprise_role(&ctx.db, enterprise_id).await? {
                    Some(EnterpriseRole::Admin) => Ok(()),
                    _ => Err(Error::Forbidden(action)),
                }
            }
            ApiPermission::RetrieveEnterpriseMembers(enterprise_id) => {
                match self.enterprise_role(&ctx.db, enterprise_id).await? {
                    Some(EnterpriseRole::Admin) => Ok(()),
                    _ => Err(Error::Forbidden(action)),
                }
            }
            ApiPermission::UpdateEnterpriseMembership {
                enterprise_id,
                user_id,
            } => match self.enterprise_role(&ctx.db, enterprise_id).await? {
                Some(EnterpriseRole::Admin) => Ok(()),
                _ => Err(Error::Forbidden(action)),
            },
            ApiPermission::DeleteEnterpriseMembership {
                enterprise_id,
                user_id,
            } => match self.enterprise_role(&ctx.db, enterprise_id).await? {
                Some(EnterpriseRole::Admin) => Ok(()),
                _ => Err(Error::Forbidden(action)),
            },
        }
    }
}

/// Actions that an authenticated user may be allowed to perform.
#[derive(Debug, Clone, Copy)]
pub enum ApiPermission {
    ViewAPIDocumentation,
    RetrieveAllEnterprises,
    CreateEnterprise,
    /// View an enterprise by its ID
    RetrieveEnterprise(Uuid),
    /// Edit an enterprise by its ID
    UpdateEnterprise(Uuid),
    /// Delete an enterprise by its ID
    DeleteEnterprise(Uuid),
    /// Send an invitation to a join a specific enterprise to a new or existing user
    CreateEnterpriseInvitation {
        enterprise_id: Uuid,
    },
    /// View all outgoing invitations from a specific enterprise
    RetrieveOutgoingEnterpriseInvitations {
        enterprise_id: Uuid,
    },
    /// Accept an enterprise invitation by its ID
    AcceptEnterpriseInvitation(Uuid),
    /// Delete an enterprise invitation by its ID
    DeleteEnterpriseInvitation(Uuid),
    /// View all enterprise members
    RetrieveEnterpriseMembers(Uuid),
    /// Edit a member's status within an enterprise
    UpdateEnterpriseMembership {
        enterprise_id: Uuid,
        user_id: Uuid,
    },
    /// Remove a member from an enterprise
    DeleteEnterpriseMembership {
        enterprise_id: Uuid,
        user_id: Uuid,
    },
}

impl fmt::Display for ApiPermission {
    /// Format a permission to be client-friendly.
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use ApiPermission::*;
        match self {
            ViewAPIDocumentation => write!(f, "view API documentation"),
            CreateEnterprise => write!(f, "create enterprise"),
            RetrieveAllEnterprises => write!(f, "view all enterprises"),
            RetrieveEnterprise(id) => {
                write!(f, "retrieve enterprise with id {}", id)
            }
            UpdateEnterprise(id) => write!(f, "update enterprise with id {}", id),
            DeleteEnterprise(id) => write!(f, "delete enterprise with id {}", id),
            AcceptEnterpriseInvitation(id) => {
                write!(f, "accept enterprise invitation with id {}", id)
            }
            DeleteEnterpriseInvitation(id) => {
                write!(f, "delete enterprise invitation with id {}", id)
            }
            CreateEnterpriseInvitation { enterprise_id: id } => {
                write!(
                    f,
                    "send enterprise invitation for enterprise with id {}",
                    id
                )
            }
            RetrieveOutgoingEnterpriseInvitations { enterprise_id: id } => {
                write!(
                    f,
                    "retrieve outgoing invitations for enterprise with id {}",
                    id
                )
            }
            RetrieveEnterpriseMembers(enterprise_id) => {
                write!(f, "retrieve all members of enterprise {}", enterprise_id)
            }
            UpdateEnterpriseMembership {
                enterprise_id,
                user_id,
            } => write!(
                f,
                "edit the membership status of user {} within enterprise {}",
                user_id, enterprise_id
            ),
            DeleteEnterpriseMembership {
                enterprise_id,
                user_id,
            } => write!(
                f,
                "remove user {} from enterprise {}",
                user_id, enterprise_id
            ),
        }
    }
}
