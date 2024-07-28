#!/bin/bash

set -e

echo "Starting deployment..."

ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
  cd $DIR

  if [[ -n "$DOCKERFILE" ]]; then
    echo "Dockerfile detected. Building and deploying the Docker container..."
    docker build -t myapp -f $DOCKERFILE .
    docker run -d -p $EXPOSED_PORT:$EXPOSED_PORT --env $ENV_VARS myapp
  elif [[ -f "docker-compose.yml" ]]; then
    echo "docker-compose.yml detected. Building and deploying using Docker Compose..."
    docker-compose up -d --build
  else
    echo "No Dockerfile or docker-compose.yml found. Running start command..."
    $START_COMMAND
  fi
EOF

echo "Deployment completed."
