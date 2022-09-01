use axum::routing::get;
use axum::Router;

pub fn router() -> Router {
    Router::new().route("/health", get(|| async { "OK" }))
}
