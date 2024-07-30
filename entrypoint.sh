#!/bin/bash

set -e

echo "before"
ls
chmod +x deploy.sh
echo "after"

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST ./deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $PR_NUMBER $GITHUB_TOKEN
