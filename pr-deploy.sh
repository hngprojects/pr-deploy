#!/bin/bash

set -e

CONTEXT=${1:-""}
DOCKERFILE=$2
EXPOSED_PORT=$3
REPO_URL=$4
REPO_OWNER=$5
REPO_NAME=$6
BRANCH=$7
COMMIT_SHA=$8
SERVER_HOST=$9
PR_ACTION="${10}"
PR_NUMBER="${11}"
REPO_DIR="${REPO_OWNER}-${REPO_NAME}"

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

# free port
FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

mkdir -p /srv/hngprojects
cd /srv/hngprojects

# remove existing folder path
rm -rf $REPO_DIR

# clone the repository
git clone -b $BRANCH $REPO_URL $REPO_DIR
cd $REPO_DIR

# Checks if the context directory exists
if [ ! -d "$CONTEXT" ]; then
    echo "Context directory does not exist..."
    exit 1
fi

# Checks exposed port is provided
if [ ! -n "$EXPOSED_PORT" ]; then
    echo "Exposed port not provided, You must provide an exposed port..."
    exit 1
fi

CONTAINERS=$(docker ps -aq --filter "label=branch=$BRANCH")
IMAGES=$(docker images -q --filter "label=branch=$BRANCH")
case $PR_ACTION in
    reopened | synchronize)
    	if [ -n "$CONTAINERS" ]; then
 	    	sudo docker stop $CONTAINERS
	     	sudo docker rm $CONTAINERS
 	       	sudo docker rmi $IMAGES
	fi
        ;;
    closed)
     	if [ -n "$CONTAINERS" ]; then
 	    	sudo docker stop $CONTAINERS
	     	sudo docker rm $CONTAINERS
	       	sudo docker rmi $IMAGES
	fi
    	exit 0
        ;;
esac

cd $CONTEXT
if [ -n "$DOCKERFILE" ]; then
    if [ -f "$DOCKERFILE" ]; then
	echo "Building docker image..."
        sudo docker build --label branch=$BRANCH -t $COMMIT_SHA -f $DOCKERFILE .
        sudo docker run -d --label branch=$BRANCH -p $FREE_PORT:$EXPOSED_PORT --name $COMMIT_SHA $COMMIT_SHA
    else
        echo "Docker file does not exist"
    fi
else
    echo "Dockerfile variable is empty, you must provide a Dockerfile..."
fi

# Set up tunneling using Serveo with a random high-numbered port
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:$SERVER_HOST:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
sleep 3

DEPLOYED_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')

echo $DEPLOYED_URL
