#!/bin/bash

set -e

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
    # echo $PR
    # rm -rf $REPO_DIR
    # git clone $REPO_URL $REPO_DIR
    # cd $REPO_DIR
    # git branch
    # ls
    # docker ps

    # image name
    IMAGE_NAME="${REPO_DIR}-${PR}"
    FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
    mkdir -p /srv/hngprojects
    cd $_

    # clone the repository
    git clone -b $GITHUB_HEAD_REF $REPO_URL $REPO_DIR
    cd $REPO_DIR

    # Checks if context exist
    if [ ! -d "$CONTEXT" ]; then
        echo "Directory not found or does not exist: $CONTEXT does not exist."
        exit 1
    fi

    if [ ! -n "$EXPOSED_PORT"]
    cd $CONTEXT
    if [ -n "$DOCKERFILE" ]; then
        if [ -f "$DOCKERFILE" ]; then
            echo "Dockerfile detected..."
            sudo docker build --label branch=$GITHUB_HEAD_REF -t \$IMAGE_NAME .
            sudo docker run -d --label branch=$GITHUB_HEAD_REF -p $FREE_PORT:$EXPOSED_PORT
        fi
    else
        echo "Docker file not exist"
    
    
EOF

echo "Deployment script executed."
