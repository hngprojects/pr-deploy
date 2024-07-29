#!/bin/bash

set -e

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
    echo $GITHUB_HEAD_REF
    rm -rf $REPO_DIR
    git clone $REPO_URL $REPO_DIR
    cd $REPO_DIR
    git branch
    ls
    ls /home
EOF

echo "Deployment script executed."
