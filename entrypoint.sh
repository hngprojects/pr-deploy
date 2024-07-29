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

    # Ensure docker is installed
    if [ ! command -v docker &> /dev/null ]; then
        sudo apt-get update
        sudo apt-get install docker.io -y
    fi

    # Ensure python is installed
    if [ ! command -v python3 &> /dev/null ]; then
        sudo apt-get update
        sudo apt-get install python3 -y
    fi
    
    # image name
    IMAGE_NAME="${REPO_DIR}-${PR}"

    # free port
    FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
    
    mkdir -p srv/hngprojects
    cd srv/hngprojects

    # remove existing folder path
    rm -rf $REPO_DIR

    # clone the repository
    # mkdir $REPO_DIR
    git clone -b $GITHUB_HEAD_REF $REPO_URL $REPO_DIR
    cd $REPO_DIR

    # Checks if context exist
    if [ ! -d "$CONTEXT" ]; then
        echo "Directory not found or does not exist: $CONTEXT does not exist."
        exit 1
    fi

    # Checks exposed port is provided
    if [ ! -n "$EXPOSED_PORT" ]; then
        echo "Exposed port not provided, You must provide an exposed port..."
        exit 1
    fi
    
    cd $CONTEXT
    if [ -n "$DOCKERFILE" ]; then
        if [ -f "$DOCKERFILE" ]; then
            echo "Dockerfile detected..."
            sudo docker build --label branch=$GITHUB_HEAD_REF -t \$IMAGE_NAME .
            sudo docker run -d --label branch=$GITHUB_HEAD_REF -p $FREE_PORT:$EXPOSED_PORT \$IMAGE_NAME
        else
            echo "Docker file does not exist"
        fi
    else
        echo "Dockerfile variable is empty, you must provide a Dockerfile..."
    fi

    # Set up tunneling using Serveo with a random high-numbered port
    nohup ssh -tt -o StrictHostKeyChecking=no -R 80:$SERVER_HOST:\$FREE_PORT serveo.net | sudo tee -a /var/log/serveo_output.log 2>&1 &
    sleep 30
    SERVEO_URL=$(grep -oP 'Forwarding.*?https://\K[^ ]+' /var/log/serveo_output.log | tail -n 1)
    echo "Deployment URL: \$SERVEO_URL"
    
EOF

echo "Deployment script executed."
