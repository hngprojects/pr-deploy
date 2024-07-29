#!/bin/bash

set -e

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
    echo $PR
    rm -rf $REPO_DIR
    git clone $REPO_URL $REPO_DIR
    cd $REPO_DIR
    git branch
    ls
    docker ps
EOF

echo "Deployment script executed."
