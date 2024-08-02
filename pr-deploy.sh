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
ENVS=$9
COMMENT_ID=${10}
PR_ID="pr_${REPO_ID}${PR_NUMBER}"
# JSON file to store PIDs
PID_FILE="/srv/pr-deploy/nohup.json"
COMMENT_ID_FILE="/srv/pr-deploy/comments.json"
DEPLOY_FOLDER="/srv/pr-deploy"

function handle_error {
    echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"\"}"
    exit 1
}

# This helps to kill the process created by nohup using the process id
function kill_process_with_pid() {
    # serveo
    local key=$1
    ID=$(jq -r --arg key "$key" '.[$key]' "${PID_FILE}")
    if [ -n $ID ]; then
        kill -9 $ID
        jq --arg key "$key" 'del(.[$key])' "${PID_FILE}" > tmp && mv tmp "${PID_FILE}"
    fi
}

# Setup directory
mkdir -p ${DEPLOY_FOLDER}/

# Initialize the JSON file for nohup if it doesn't exist
if [ ! -f "$PID_FILE" ]; then
    echo "{}" > "$PID_FILE"
fi

# Initialize the JSON file for comment if it doesn't exist
if [ ! -f "$COMMENT_ID_FILE" ]; then
    echo "{}" > "$COMMENT_ID_FILE"
fi

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

cd ${DEPLOY_FOLDER}
rm -rf $PR_ID

# Handle COMMENT_ID
if [ -n "$COMMENT_ID" ]; then
    # echo "$COMMENT_ID" > "${PR_ID}.txt"
    jq --arg pr_id "$PR_ID" --arg cid "$COMMENT_ID" '.[$pr_id] = $cid' "$COMMENT_ID_FILE" > tmp.$$.json && mv tmp.$$.json "$COMMENT_ID_FILE"
else
    if [ -f "$COMMENT_ID_FILE" ]; then
        COMMENT_ID=$(jq -r --arg key "$PR_ID" '.[$key]' "${COMMENT_ID_FILE}")

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
        [ "$PR_ACTION" == "closed" ] && echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"\"}" && kill_process_with_pid $PR_ID && exit 0
        ;;
esac

# Git clone and Docker operations
echo "Git Clone ..."
git clone -b $BRANCH $REPO_URL $PR_ID
cd $PR_ID

echo "Building docker image..."
sudo docker build -t $PR_ID -f $DOCKERFILE .

echo "Running docker container..."
# sudo docker run -d -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

# ENV_ARGS=$(echo "$ENVS" | tr ',' '\n' | sed 's/^/-e /' | tr '\n' ' ')
# ENV_ARGS=$(echo "$ENVS" | sed 's/^/-e /' | tr '\n' ' ')
ENV_ARGS=$(echo "$ENVS" | sed 's/^/-e /' | sed ':a;N;$!ba;s/\n/ -e /g')
sudo docker run -d $ENV_ARGS -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

echo "Start SSH session..."

# function to check if serveo was successful
# check_serveo() {
#     grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}'
# }
# Set up tunneling using Serveo with a random high-numbered port
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
SERVEO_PID=$!
sleep 3


# Check if Serveo tunnel was set up successfully
DEPLOYED_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')

# update the nohup ids
if [ -n DEPLOYED_URL ]; then
    # jq --arg pid "$SERVEO_PID" '.serveo = $pid' "$PID_FILE" > tmp.$$.json && mv tmp.$$.json "$PID_FILE"
    jq --arg pr_id "$PR_ID" --arg pid "$SERVEO_PID" '.[$pr_id] = $pid' "$PID_FILE" > tmp.$$.json && mv tmp.$$.json "$PID_FILE"

fi


# Output the final JSON
echo "{\"COMMENT_ID\": \"$COMMENT_ID\", \"DEPLOYED_URL\": \"$DEPLOYED_URL\"}"
