#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

function handle_error {
    comment "Failed ❌" "#" && exit 1
}

# Set up trap to handle errors
trap 'handle_error' ERR

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server.
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST <<EOF
GITHUB_TOKEN=$GITHUB_TOKEN
CONTEXT=$CONTEXT
DOCKERFILE=$DOCKERFILE
EXPOSED_PORT=$EXPOSED_PORT
REPO_URL=$REPO_URL
REPO_ID=$REPO_ID
GITHUB_HEAD_REF=$GITHUB_HEAD_REF
PR_ACTION=$PR_ACTION
PR_NUMBER=$PR_NUMBER
COMMENT_ID=$COMMENT_ID
bash /srv/pr-deploy.sh
EOF
