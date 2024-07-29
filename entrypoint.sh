#!/bin/bash

set -e

echo "Starting deployment..."
if ! command -v sshpass &> /dev/null
then
    echo "sshpass could not be found. Please install it."
    exit 1
fi
echo $SERVER_PORT
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
    rm -rf pr-deploy
    git clone $REPO_URL pr-deploy
    cd pr-deploy
    ls
    ls /home
EOF

echo "Deployment script executed."
