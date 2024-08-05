#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Ensure sshpass is installed
if [ ! command -v sshpass &> /dev/null ]; then
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

# Copy the script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh >/dev/null

# Check if PR_ACTION is not 'closed'
if [ "$PR_ACTION" != "closed" ]; then
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT "/tmp/${PR_ID}.tar.gz" $SERVER_USERNAME@$SERVER_HOST:"/tmp/${PR_ID}.tar.gz" >/dev/null
fi

# Stream the output from the remote script to local terminal and save it to a log file
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST \
  "GITHUB_TOKEN='$GITHUB_TOKEN' \
  CONTEXT='$CONTEXT' \
  DOCKERFILE='$DOCKERFILE' \
  EXPOSED_PORT='$EXPOSED_PORT' \
  ENVS='$ENVS' \
  COMMENT='$COMMENT' \
  REPO_OWNER='$REPO_OWNER' \
  REPO_NAME='$REPO_NAME' \
  REPO_URL='$REPO_URL' \
  REPO_ID='$REPO_ID' \
  BRANCH='$GITHUB_HEAD_REF' \
  PR_ID='$PR_ID' \
  PR_ACTION='$PR_ACTION' \
  PR_NUMBER='$PR_NUMBER' \
  COMMENT_ID='$COMMENT_ID' \
  bash -c 'echo $SERVER_PASSWORD | sudo -SE bash /srv/pr-deploy.sh'" | tee "/tmp/preview_${GITHUB_RUN_ID}.txt"

PREVIEW_URL=$(tail -n 1 "/tmp/preview_${GITHUB_RUN_ID}.txt")
echo "preview-url=${PREVIEW_URL}" >> $GITHUB_OUTPUT
