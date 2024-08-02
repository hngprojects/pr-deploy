#!/bin/bash

set -e
PR_ID="pr_${REPO_ID}${PR_NUMBER}"
DEPLOY_FOLDER="/srv/pr-deploy"
PID_FILE="/srv/pr-deploy/nohup.json"
COMMENT_ID_FILE="/srv/pr-deploy/comments.json"

comment() {
    local status_message=$1
    local preview_url=$2

    echo "Status: $status_message"

    local comment_body=$(jq -n --arg body "<strong>Here are the latest updates on your deployment.</strong> Explore the action and ⭐ star our project for more insights! 🔍
<table>
    <thead>
        <tr>
            <th>Deployed By</th>
            <th>Status</th>
            <th>Preview URL</th>
            <th>Updated At (UTC)</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><a href='https://github.com/marketplace/actions/pull-request-deploy'>PR Deploy</a></td>
            <td>${status_message}</td>
            <td><a href='${preview_url}'>Visit Preview</a></td>
            <td>$(date +'%b %d, %Y %I:%M%p')</td>
        </tr>  
    </tbody>
</table>" '{body: $body}')

    if [ -z "$COMMENT_ID" ]; then
        # Create a new comment
        COMMENT_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
            -d "$comment_body" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" | jq -r '.id')
        echo "comment id: $COMMENT_ID"
        jq --arg pr_id "$PR_ID" --arg cid "$COMMENT_ID" '.[$pr_id] = $cid' "$COMMENT_ID_FILE" > "$COMMENT_ID_FILE"
    else
        # Update the existing comment
        curl -s -H "Authorization: token $GITHUB_TOKEN" -X PATCH \
            -d "$comment_body" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/comments/${COMMENT_ID}" > /dev/null
    fi
}

cleanup() {
    PID=$(jq -r --arg key "$PR_ID" '.[$key] // ""' "${PID_FILE}")

    if [ -n "$PID" ]; then
        echo "PID: $PID"
        kill -9 "$PID" || true
        jq --arg key "$PR_ID" 'del(.[$key])' "${PID_FILE}" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "${PID_FILE}"
    fi
    CONTAINER_ID=$(docker ps -aq --filter "name=${PR_ID}")
    [ -n "$CONTAINER_ID" ] && sudo docker stop -t 0 "$CONTAINER_ID" && sudo docker rm -f "$CONTAINER_ID"

    IMAGE_ID=$(docker images -q --filter "reference=${PR_ID}")
    [ -n "$IMAGE_ID" ] && sudo docker rmi -f "$IMAGE_ID"
}


# Setup directory
mkdir -p ${DEPLOY_FOLDER}/

# Initialize the JSON file for nohup if it doesn't exist
if [ ! -f "$PID_FILE" ]; then
    echo {} > $PID_FILE
fi

# Initialize the JSON file for comment if it doesn't exist
if [ ! -f "$COMMENT_ID_FILE" ]; then
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

# Handle different PR actions
case $PR_ACTION in
    reopened | synchronize | closed)
        cleanup
        [ "$PR_ACTION" == "closed" ] && comment "Terminated 🛑" "#" && exit 0
        ;;
esac

echo "Branch: $BRANCH, REPO_URL: $REPO_URL, PR: $PR_ID"
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
