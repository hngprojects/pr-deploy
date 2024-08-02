#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server.
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST <<EOF
GITHUB_TOKEN=$GITHUB_TOKEN
CONTEXT=$CONTEXT
DOCKERFILE=$DOCKERFILE
EXPOSED_PORT=$EXPOSED_PORT
REPO_OWNER=$REPO_OWNER
REPO_NAME=$REPO_NAME
REPO_URL=$REPO_URL
REPO_ID=$REPO_ID
BRANCH=$GITHUB_HEAD_REF
PR_ACTION=$PR_ACTION
PR_NUMBER=$PR_NUMBER
COMMENT_ID=$COMMENT_ID
bash /srv/pr-deploy.sh
EOF
