#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Ensure sshpass is installed if needed
if ! command -v sshpass &> /dev/null && [ -z "$SERVER_PRIVATE_KEY" ]; then
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

# Set up SSH command and SCP options based on whether a private key or password is provided
if [ -n "$SERVER_PRIVATE_KEY" ]; then
    echo "$SERVER_PRIVATE_KEY" > private_key.pem
    chmod 600 private_key.pem
    SSH_OPTIONS="-i private_key.pem -o StrictHostKeyChecking=no"
    SSH_CMD="ssh $SSH_OPTIONS -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"
    SCP_CMD="scp $SSH_OPTIONS -P $SERVER_PORT"
else
    SSH_OPTIONS="-o StrictHostKeyChecking=no"
    SSH_CMD="sshpass -p $SERVER_PASSWORD ssh $SSH_OPTIONS -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"
    SCP_CMD="sshpass -p $SERVER_PASSWORD scp $SSH_OPTIONS -P $SERVER_PORT"
fi

# Copy the deployment script to the remote server
$SCP_CMD pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/tmp/ >/dev/null

# Copy the image build zip file if PR_ACTION is not 'closed'
if [ "$PR_ACTION" != "closed" ]; then
    $SCP_CMD "/tmp/${PR_ID}.tar.gz" $SERVER_USERNAME@$SERVER_HOST:"/tmp/${PR_ID}.tar.gz" >/dev/null
fi

$SSH_CMD \
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
  HOST_VOLUME_PATH='$HOST_VOLUME_PATH' \
  CONTAINER_VOLUME_PATH='$CONTAINER_VOLUME_PATH' \
  COMMENT_ID='$COMMENT_ID' \
  bash -c 'echo $SERVER_PASSWORD | sudo -SE bash \"/tmp/pr-deploy.sh\"'" | tee "/tmp/preview_${GITHUB_RUN_ID}.txt"

PREVIEW_URL=$(tail -n 1 "/tmp/preview_${GITHUB_RUN_ID}.txt")
echo "preview-url=${PREVIEW_URL}" >> $GITHUB_OUTPUT
