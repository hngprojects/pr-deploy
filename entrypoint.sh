#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "REPOSITORY URL: $REPO_URL"

# Ensure sshpass is installed
if ! command -v sshpass &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

# Check if private key is provided, and if yes, set up a .pem file for auth
if [ -n "$SERVER_PRIVATE_KEY" ]; then
    echo "$SERVER_PRIVATE_KEY" > private_key.pem
    chmod 600 private_key.pem

    SSH_CMD="ssh -i private_key.pem -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"
    
    # Copy the script to the remote server.
    scp -i private_key.pem -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/tmp/pr-deploy.sh>/dev/null

    # Check if PR_ACTION is not 'closed'
    if [ "$PR_ACTION" != "closed" ]; then
        # Copy the Image build zip file to the remote server
        scp -i private_key.pem -o StrictHostKeyChecking=no -P $SERVER_PORT "/tmp/${PR_ID}.tar.gz" $SERVER_USERNAME@$SERVER_HOST:"/tmp/${PR_ID}.tar.gz" >/dev/null
    fi
else
    SSH_CMD="sshpass -p $SERVER_PASSWORD ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST"

    # Copy the script to the remote server.
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/tmp/pr-deploy.sh>/dev/null

    
    # Check if PR_ACTION is not 'closed'
    if [ "$PR_ACTION" != "closed" ]; then
        # Copy the Image build zip file to the remote server
        sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT "/tmp/${PR_ID}.tar.gz" $SERVER_USERNAME@$SERVER_HOST:"/tmp/${PR_ID}.tar.gz" >/dev/null
    fi
fi

# Stream the output from the remote script to local terminal and save it to a log file
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
