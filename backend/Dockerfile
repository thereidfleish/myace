# Used for deployment only. Trying to run this w/ docker compose will take forever to compile deps.

# General rule of thumb is cheapest operations should go at the bottom
# to optimize build caching

# Set base image (host OS)
FROM rust:latest as builder

# Set the working directory in the container
WORKDIR /app

# To be used with offline mode
RUN cargo install sqlx-cli

COPY . .

# build binary
RUN cargo build --release

# create a new, smaller image that only ships w/ the binary installed (and none of the source code)
FROM debian:buster-slim
RUN apt-get update && apt-get install -y libssl-dev
COPY --from=builder /app/target/release/myace myace

# Specify the command to run on container start
CMD ["/myace"]

# listen on port 8080
EXPOSE 8080/tcp
