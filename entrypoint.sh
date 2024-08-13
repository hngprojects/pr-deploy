#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

sshpass -p $SERVER_PASSWORD ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST \
  "GITHUB_TOKEN='$GITHUB_TOKEN' \
  CONTEXT='$CONTEXT' \
  DOCKERFILE='$DOCKERFILE' \
  EXPOSED_PORT='$EXPOSED_PORT' \
  ENVS='$ENVS' \
  REPO_URL='$REPO_URL' \
  BRANCH='$GITHUB_HEAD_REF' \
  PR_ID='$PR_ID' \
  PR_ACTION='$PR_ACTION' \
  bash -c 'sudo -SE pr-deploy' | tee "/tmp/${PR_ID}.txt"

PREVIEW_URL=$(tail -n 1 "/tmp/${PR_ID}.txt")
echo "preview-url=${PREVIEW_URL}" >> $GITHUB_OUTPUT
