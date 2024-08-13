#!/bin/bash

set -e

if [ "$PR_ACTION" == "closed" ]; then
    CONTAINER_ID=$(docker ps -aq --filter "name=${PR_ID}")
    [ -n "$CONTAINER_ID" ] && docker stop -t 0 "$CONTAINER_ID" && docker rm -f "$CONTAINER_ID"

    IMAGE_ID=$(docker images -q --filter "reference=${PR_ID}")
    [ -n "$IMAGE_ID" ] && docker rmi -f "$IMAGE_ID"
    
    rm -rf ~/${PR_ID}
    
    exit 0
fi

# Update repository on the server
echo $REPO_URL
rm -rf $PR_ID
git clone -b $BRANCH $REPO_URL $PR_ID
cd $PR_ID

# Free port
FREE_PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')

# Unzip the Image file and run Docker Container
docker build -t $PR_ID -f $DOCKERFILE $CONTEXT            
echo $ENVS > "/tmp/${PR_ID}.env"
docker run -d --env-file "/tmp/${PR_ID}.env" -p $FREE_PORT:$EXPOSED_PORT --name $PR_ID $PR_ID

# Start SSH Tunnel
nohup ssh -tt -o StrictHostKeyChecking=no -R 80:localhost:$FREE_PORT serveo.net > serveo_output.log 2>&1 &
SERVEO_PID=$!
sleep 3
PREVIEW_URL=$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print $5}')
echo "$PREVIEW_URL" > "/tmp/${PR_ID}.txt"

if [ -z "$PREVIEW_URL" ]; then
    echo "Preview URL not created"
    PREVIEW_URL="http://$(curl ifconfig.me):${FREE_PORT}"
fi

echo "$PREVIEW_URL"
