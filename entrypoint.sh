#!/bin/bash

set -e

chmod +x pr-deploy.sh

sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT ./pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

DEPLOYED_URL=(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST /srv/pr-deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $PR_NUMBER)

echo "Deployed URL: $DEPLOYED_URL"
