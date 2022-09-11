use crate::config::Config;
use anyhow::Context;
use axum::{Extension, Router};
use log::info;
use sqlx::PgPool;
use std::sync::Arc;
use tower::ServiceBuilder;

// Utility modules.

/// Defines a common error type to use for all request handlers.
mod error;

/// Defines common types used for data validation.
mod types;

/// Contains logic for access control. Determines what is `403 Forbidden` for a given user and what is not.
mod permissions;

// Middleware modules.

/// Contains definitions for application-specific parameters to handler functions,
/// such as `AuthUser` which checks for the `Authorization: Token <token>` header in the request,
/// verifies `<token>` as a JWT and checks the signature,
/// then deserializes the information it contains.
mod extractor;

// Route modules.

/// Contains enterprise-related routes.
mod enterprises;
/// Contains miscellaneous routes.
mod miscroutes;
/// Contains user-related routes.
mod users;

pub use error::{Error, ResultExt};

pub type Result<T, E = Error> = std::result::Result<T, E>;

use tower_http::cors::{Any, Cors, CorsLayer};
use tower_http::trace::TraceLayer;

/// The core type through which handler functions can access common API state.
///
/// This can be accessed by adding a parameter `Extension<ApiContext>` to a handler function's
/// parameters.
#[derive(Clone)]
struct ApiContext {
    config: Arc<Config>,
    db: PgPool,
}

pub async fn serve(config: Config, db: PgPool) -> anyhow::Result<()> {
    let app = api_router().layer(
        ServiceBuilder::new()
            // Enables logging. Use `RUST_LOG=tower_http=debug`
            .layer(TraceLayer::new_for_http())
            // Enables CORS
            .layer(
                CorsLayer::new()
                    .allow_methods(Any)
                    .allow_origin(Any)
                    .allow_headers(Any),
            )
            .layer(Extension(ApiContext {
                config: Arc::new(config),
                db,
            })),
    );

    info!("Listening on localhost:8080");
    println!("Listening on localhost:8080");
    axum::Server::bind(&"0.0.0.0:8080".parse()?)
        .serve(app.into_make_service())
        .await
        .context("error running HTTP server")
}

fn api_router() -> Router {
    miscroutes::router()
        .merge(enterprises::router())
        .merge(users::router())
}
