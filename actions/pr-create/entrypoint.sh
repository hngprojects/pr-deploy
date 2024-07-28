#!/bin/bash

set -e

echo "Starting deployment..."

ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
  set -e

  echo "Cloning the repository..."
  if [ -d "$DIR" ]; then
    rm -rf $DIR
  fi
  git clone $REPO_URL $DIR

  cd $DIR

  REPO_NAME=\$(basename -s .git $REPO_URL)
  cd \$REPO_NAME

  CONTAINER_NAME="pr_${PR_NUMBER}_container"

  echo "Checking for existing container..."
  if [ "$(docker ps -aq -f name=\$CONTAINER_NAME)" ]; then
    echo "Stopping and removing existing container..."
    docker rm -f \$CONTAINER_NAME
  fi

  if [[ -n "$DOCKERFILE" ]]; then
    echo "Dockerfile detected. Building and deploying the Docker container..."
    build_output=\$(docker build -t \$CONTAINER_NAME -f $DOCKERFILE . 2>&1)
    echo "\$build_output"
    run_output=\$(docker run -d --name \$CONTAINER_NAME -p $EXPOSED_PORT:$EXPOSED_PORT --env $ENV_VARS \$CONTAINER_NAME 2>&1)
    echo "\$run_output"
  elif [[ -f "$COMPOSE_FILE" ]]; then
    echo "docker-compose.yml detected. Building and deploying using Docker Compose..."
    down_output=\$(docker-compose down 2>&1)
    echo "\$down_output"
    up_output=\$(docker-compose up -d --build 2>&1)
    echo "\$up_output"
  else
    echo "No Dockerfile or docker-compose.yml found. Running start command..."
    start_output=\$($START_COMMAND 2>&1)
    echo "\$start_output"
  fi

  echo "Deployment completed. Container name: \$CONTAINER_NAME"
  echo "Container status:"
  status_output=\$(docker ps -f name=\$CONTAINER_NAME 2>&1)
  echo "\$status_output"

  echo "Fetching container logs..."
  logs_output=\$(docker logs \$CONTAINER_NAME 2>&1)
  echo "\$logs_output"
EOF

echo "Deployment script executed."
