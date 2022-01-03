#!/bin/bash
# Build the web application and push to Lightsail.
# Ensure aws-cli v2+ is installed, credentials are valid, and the lightsailctl plugin is installed.
# Application environment variables are specified within the Lightsail service.
# Run with `sudo -E ./deploy.sh`
# https://stackoverflow.com/questions/40127702/my-aws-cli-didnt-work-with-sudo

version="1.0"
#git clone https://github.com/adlrwbr/tennis-trainer-closed.git /tmp/tennistrainer \
#&& cd /tmp/tennistrainer/backend/src \
docker build -t tennistrainerprod:$version ./src \
&& aws lightsail push-container-image \
       --region us-east-2 \
       --service-name tennistrainerapi \
       --label tennistrainer \
       --image tennistrainerprod:$version
