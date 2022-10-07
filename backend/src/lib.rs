/// Defines the arguments required to start the server application using [`clap`].
///
/// [`clap`]: https://github.com/clap-rs/clap/
pub mod config;

/// Contains the setup code for Axum.
pub mod http;

/// Contains the logic for queuing and dispatching notifications
pub mod notifications;
