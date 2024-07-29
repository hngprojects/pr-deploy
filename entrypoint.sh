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
    SERVEO_URL=\$(grep "Forwarding HTTP traffic from" serveo_output.log | tail -n 1 | awk '{print \$5}')
    cat serveo_output.log

    sudo apt install jq -y
    
    # Function to add a comment to the pull request
    add_comment_to_pr() {
      export deployment_url=\${SERVEO_URL}
      echo "Deployment URL: \${deployment_url}"
    
      # Use jq to ensure proper JSON formatting
      curl -s -H "Authorization: token $GITHUB_TOKEN" \
      -X POST \
      -d \$(jq -nc --arg url "\$deployment_url" '{"body": "Deployment URL: \($url) https://212fa7c9df92163709027b045388a1cd.serveo.net/"}') \
      "https://api.github.com/repos/hngprojects/pr-deploy/issues/15/comments" 
    }
    add_comment_to_pr 
EOF
    
echo "Deployment script executed."
