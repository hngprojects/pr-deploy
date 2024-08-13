#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Set up SSH command and SCP options based on whether a private key or password is provided
if [ -n "$SERVER_PRIVATE_KEY" ]; then
    echo "$SERVER_PRIVATE_KEY" > private_key.pem
    chmod 600 private_key.pem
    SSH_CMD="ssh -i private_key.pem -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"
else
    SSH_CMD="sshpass -p $SERVER_PASSWORD ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"
fi

$SSH_CMD \
  "GITHUB_TOKEN='$GITHUB_TOKEN' \
  CONTEXT='$CONTEXT' \
  DOCKERFILE='$DOCKERFILE' \
  EXPOSED_PORT='$EXPOSED_PORT' \
  ENVS='$ENVS' \
  REPO_URL='$REPO_URL' \
  BRANCH='$GITHUB_HEAD_REF' \
  PR_ID='$PR_ID' \
  PR_ACTION='$PR_ACTION' \
  bash -c 'echo $SERVER_PASSWORD | sudo -SE pr-deploy | tee "/tmp/${PR_ID}.txt"

PREVIEW_URL=$(tail -n 1 "/tmp/${PR_ID}.txt")
echo "preview-url=${PREVIEW_URL}" >> $GITHUB_OUTPUT
