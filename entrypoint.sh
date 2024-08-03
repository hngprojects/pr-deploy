#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define a log file on the local machine
LOCAL_LOG_FILE="deployment_output.log"

# Copy the script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh >/dev/null

# Stream the output from the remote script to local terminal and save it to a log file
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST \
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
  bash /srv/pr-deploy.sh" | tee "$LOCAL_LOG_FILE"

# Output the last line of the log file, assuming it contains the deployment URL
DEPLOYMENT_URL=$(tail -n 1 "$LOCAL_LOG_FILE")

# Output the deployment URL
echo "Deployment URL: $DEPLOYMENT_URL"

