#!/bin/bash

set -e

CONTEXT=$1
DOCKERFILE=$2
EXPOSED_PORT=$3
REPO_URL=$4
REPO_ID=$5
BRANCH=$6
PR_ACTION=$7
PR_NUMBER=$8
COMMENT_ID=$9
PR_ID="pr_${REPO_ID}${PR_NUMBER}"

function handle_error {
    echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"\"}"
    exit 1
}

# Set up trap to handle errors
trap 'handle_error' ERR

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

# Setup directory
mkdir -p /srv/hngprojects/
cd /srv/hngprojects
rm -rf $PR_ID

# Handle COMMENT_ID
if [ -n "$COMMENT_ID" ]; then
    echo "$COMMENT_ID" > "${PR_ID}.txt"
else
    if [ -f "${PR_ID}.txt" ]; then
        COMMENT_ID=$(cat "${PR_ID}.txt")
    else
        COMMENT_ID=""
    fi
fi

# Get container and image IDs
CONTAINER_ID=$(docker ps -aq --filter "name=${PR_ID}")
IMAGE_ID=$(docker images -q --filter "reference=${PR_ID}")

# Handle different PR actions
case $PR_ACTION in
    reopened | synchronize | closed)
        # Stop and force remove containers if they exist
        [ -n "$CONTAINER_ID" ] && sudo docker stop -t 0 $CONTAINER_ID && sudo docker rm -f $CONTAINER_ID
        
        # Force remove images if they exist
        [ -n "$IMAGE_ID" ] && sudo docker rmi -f $IMAGE_ID

        # Exit early for 'closed' action
        [ "$PR_ACTION" == "closed" ] && echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"\"}" && exit 0
        ;;
esac

# Git clone and Docker operations
echo "Git Clone ..."
git clone -b $BRANCH $REPO_URL $PR_ID
cd $PR_ID

echo "Building docker image..."
sudo docker build -t $PR_ID -f $DOCKERFILE .

echo "Running docker container..."
sudo docker run -d -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

echo "Start SSH session..."

# Checks if serveo 
# check_serveo() {
#     grep -q "ssh: connect to host serveo.net port 22: Connection refused" serveo_output.log  || grep -q "ssh: connect to host serveo.net port 22: Connection timed out" serveo_output.log
# }

# # Set up tunneling using Serveo with a random high-numbered port
# nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
# sleep 3

# # Check if Serveo tunnel was set up successfully
# if [ check_serveo ]; then
#     DEPLOYED_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')
# else
    nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT ssh.localhost.run > localhost_run_output.log 2>&1 &
    sleep 30
    # if grep -q "Connect to" localhost_run_output.log; then
        DEPLOYED_URL=$(grep "tunneled with tls termination" localhost_run_output.log | awk '{print $NF}')
    # else
    #     DEPLOYED_URL=""
    # fi
# fi


# Output the final JSON
echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"$DEPLOYED_URL\"}"
