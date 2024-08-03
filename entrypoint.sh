#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Copy the script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh >/dev/null

# Run the script on the remote server and capture the output
DEPLOYMENT_URL=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST \
  "GITHUB_TOKEN='$GITHUB_TOKEN' \
  CONTEXT='$CONTEXT' \
  DOCKERFILE='$DOCKERFILE' \
  EXPOSED_PORT='$EXPOSED_PORT' \
  ENVS='$ENVS' \
  REPO_OWNER='$REPO_OWNER' \
  REPO_NAME='$REPO_NAME' \
  REPO_URL='$REPO_URL' \
  REPO_ID='$REPO_ID' \
  BRANCH='$GITHUB_HEAD_REF' \
  PR_ACTION='$PR_ACTION' \
  PR_NUMBER='$PR_NUMBER' \
  COMMENT_ID='$COMMENT_ID' \
  bash /srv/pr-deploy.sh")

# Output the last line of the deployment URL
echo "$DEPLOYMENT_URL" | tail -n 1
