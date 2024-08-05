#!/bin/bash

set -e
trap 'comment "Failed ❌" && exit 1' ERR

DEPLOY_FOLDER="/srv/pr-deploy"
PID_FILE="/srv/pr-deploy/nohup.json"
COMMENT_ID_FILE="/srv/pr-deploy/comments.json"

comment() {
    # Check if comments are enabled
    if [ "$COMMENT" != true ]; then
        return
    fi
    
    local status_message=$1
    echo $status_message

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
            <td><a href='${PREVIEW_URL}'>Visit Preview</a></td>
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
        jq --arg pr_id "$PR_ID" --arg cid "$COMMENT_ID" '.[$pr_id] = $cid' "$COMMENT_ID_FILE" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "$COMMENT_ID_FILE"
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
        kill -9 "$PID" 2>/dev/null || true
        jq --arg key "$PR_ID" 'del(.[$key])' "${PID_FILE}" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "${PID_FILE}"
    fi

    CONTAINER_ID=$(docker ps -aq --filter "name=${PR_ID}")
    [ -n "$CONTAINER_ID" ] && sudo docker stop -t 0 "$CONTAINER_ID" && sudo docker rm -f "$CONTAINER_ID"

    IMAGE_ID=$(docker images -q --filter "reference=${PR_ID}")
    [ -n "$IMAGE_ID" ] && sudo docker rmi -f "$IMAGE_ID"
    rm /tmp/${PR_ID}.*
    rm -rf ${DEPLOY_FOLDER}/${PR_ID}
}

# Ensure docker is installed
if [ ! command -v docker &> /dev/null ]; then
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
fi

# Ensure python is installed
if [ ! command -v python3 &> /dev/null ]; then
    apt-get update
    apt-get install -y python3
fi

# Ensure jq is installed
if [ ! command -v jq &> /dev/null ]; then
    apt-get update
    apt-get install -y jq
fi

# Ensure curl is installed
if [ ! command -v curl &> /dev/null ]; then
    apt-get update
    apt-get install -y curl
fi

# Ensure ssh is installed
if [ ! command -v ssh &> /dev/null ]; then
    apt-get update
    apt-get install -y openssh-client
fi

# Ensure gunzip is installed
if [ ! command -v gunzip &> /dev/null ]; then
    apt-get update
    apt-get install -y gzip
fi

# Ensure git is installed
if [ ! command -v git &> /dev/null ]; then
    apt-get update
    apt-get install -y git
fi

# Setup directory
mkdir -p ${DEPLOY_FOLDER}

# Initialize the JSON file for nohup if it doesn't exist
if [ ! -f "$PID_FILE" ]; then
    echo {} > $PID_FILE
fi

# Initialize the JSON file for comment if comments are enabled and it doesn't exist
if [ "$COMMENT" == true ] && [ ! -f "$COMMENT_ID_FILE" ]; then
    echo {} > $COMMENT_ID_FILE
fi

# Handle COMMENT_ID if only comments are enabled
if [ "$COMMENT" == true ]; then
    COMMENT_ID=$(jq -r --arg key $PR_ID '.[$key] // ""' ${COMMENT_ID_FILE})
    case $PR_ACTION in
    opened | reopened | synchronize)
        comment "Deploying ⏳"
        ;;
    esac
fi

# Free port
FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

cd ${DEPLOY_FOLDER}

# Handle different PR actions
case $PR_ACTION in
    reopened | synchronize | closed)
        cleanup
        [ "$PR_ACTION" == "closed" ] && comment "Terminated 🛑" && exit 0
        ;;
esac

# Git clone and Docker operations
rm -rf $PR_ID
git clone -b $BRANCH $REPO_URL $PR_ID
cd $PR_ID/$CONTEXT

# Build and run Docker Container
# docker build -t $PR_ID -f $DOCKERFILE .
gunzip "/tmp/${PR_ID}.tar.gz"
docker load -i "/tmp/${PR_ID}.tar"
rm /tmp/${PR_ID}.tar
echo $ENVS > "/tmp/${PR_ID}.env"
docker run -d --env-file "/tmp/${PR_ID}.env" -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

# Start SSH Tunnel
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
SERVEO_PID=$!
sleep 3
PREVIEW_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')
echo "$PREVIEW_URL" > "/tmp/${PR_ID}.txt"

# update the nohup ids
jq --arg pr_id "$PR_ID" --arg pid "$SERVEO_PID" '.[$pr_id] = $pid' "$PID_FILE" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "$PID_FILE"

if [ -z "$PREVIEW_URL" ]; then
    echo "Preview URL not created"
    PREVIEW_URL="http://$(curl ifconfig.me):${FREE_PORT}"
fi

comment "Deployed 🎉"
echo "$PREVIEW_URL"
