#!/bin/bash

set -e

CONTEXT=$0
DOCKERFILE=$1
EXPOSED_PORT=$2
REPO_URL=$3
REPO_OWNER=$4
REPO_NAME=$5
PR_NUMBER=$6
GITHUB_TOKEN=$7

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

# getting timestamp
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

# image name
IMAGE_NAME="${REPO_DIR}-${PR}-\${TIMESTAMP}"

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
        sudo docker run -d --label branch=$GITHUB_HEAD_REF -p \$FREE_PORT:$EXPOSED_PORT \$IMAGE_NAME
    else
        echo "Docker file does not exist"
    fi
else
    echo "Dockerfile variable is empty, you must provide a Dockerfile..."
fi

# Set up tunneling using Serveo with a random high-numbered port
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:$SERVER_HOST:\$FREE_PORT serveo.net > serveo_output.log 2>&1 &
sleep 5
export DEMO_URL=\$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print \$5}')
curl -s -H "Authorization: token $GITHUB_TOKEN" \
-X POST \
-d "{\"body\": \"\$DEMO_URL\"}" \
"https://api.github.com/repos/hngprojects/pr-deploy/issues/15/comments"

echo "Deployment script executed."
