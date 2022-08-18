/// The configuration parameters for the application.
///
/// These can either be passed on the command line or pulled from environment variables.
#[derive(clap::Parser)]
pub struct Config {
    /// The connection URL for the Postgres database this application should use.
    #[clap(long, env)]
    pub database_url: String,

    /// The HMAC signing and verification key used for login tokens (JWTs).
    ///
    /// There is no required structure or format to this key as it's just fed into a hash function.
    /// In practice, it should be a long, random string that would be infeasible to brute-force.
    #[clap(long, env)]
    pub hmac_key: String,

    #[clap(long, env)]
    pub server_password: String,
}
