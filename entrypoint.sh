#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server.
echo "REPO_URL: $REPO_URL"
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST \
  "REPO_URL='$REPO_URL'; chmod +x /srv/pr-deploy.sh; /srv/pr-deploy.sh"
