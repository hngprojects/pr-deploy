#!/bin/bash

set -e

PR_ID="pr_${REPO_ID}${PR_NUMBER}"
DEPLOY_FOLDER="/srv/pr-deploy"
PID_FILE="/srv/pr-deploy/nohup.json"
COMMENT_ID_FILE="/srv/pr-deploy/comments.json"

comment() {
    echo "comment"

}

cleanup() {
        echo "cleanup"

}

# Setup directory
mkdir -p ${DEPLOY_FOLDER}/

# Initialize the JSON file for nohup if it doesn't exist
if [ ! -f $PID_FILE ]; then
    echo {} > $PID_FILE
fi

# Initialize the JSON file for comment if it doesn't exist
if [ ! -f $COMMENT_ID_FILE ]; then
    echo {} > $COMMENT_ID_FILE
fi

# Handle COMMENT_ID
COMMENT_ID=$(jq -r --arg key $PR_ID '.[$key] // ""' ${COMMENT_ID_FILE})
comment "Deploying ⏳" "#"

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

# Free port
FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

cd ${DEPLOY_FOLDER}
rm -rf $PR_ID

# Get container and image IDs
CONTAINER_ID=$(docker ps -aq --filter "name=${PR_ID}")
IMAGE_ID=$(docker images -q --filter "reference=${PR_ID}")

# Handle different PR actions
case $PR_ACTION in
    reopened | synchronize | closed)
        cleanup
        [ "$PR_ACTION" == "closed" ] && comment "Terminated 🛑" "#" && exit 0
        ;;
esac

# Git clone and Docker operations
git clone -b $BRANCH $REPO_URL $PR_ID
cd $PR_ID/$CONTEXT

# Build and run Docker Container
sudo docker build -t $PR_ID -f $DOCKERFILE .
sudo docker run -d -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

# Start SSH Tunnel
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
SERVEO_PID=$!
sleep 3
DEPLOYED_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')

# update the nohup ids
if [ -n $SERVEO_PID ]; then
    jq --arg pr_id "$PR_ID" --arg pid "$SERVEO_PID" '.[$pr_id] = $pid' "$PID_FILE" > "$PID_FILE"
fi

if [ -z "$DEPLOYED_URL" ]; then
    comment "Failed ❌" "#" && exit 1
fi
comment "Deployed 🎉" $DEPLOYED_URL
