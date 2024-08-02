#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Copy and execute the remote script.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST "BRANCH=$GITHUB_HEAD_REF REPO_URL=$REPO_URL bash /srv/pr-deploy.sh"
