use crate::http::ApiContext;
use crate::http::Result;
use axum::response::Html;
use axum::routing::get;
use axum::{Extension, Router};

use super::extractor::AuthUser;
use super::permissions::ApiPermission;

pub fn router() -> Router {
    Router::new()
        .route("/health", get(|| async { "OK" }))
        .route("/apidocs", get(api_docs))
}

async fn api_docs(auth_user: AuthUser, ctx: Extension<ApiContext>) -> Result<Html<&'static str>> {
    auth_user
        .check_permission(&ctx, ApiPermission::ViewAPIDocumentation)
        .await?;
    Ok(Html(include_str!("../docs.html")))
}
