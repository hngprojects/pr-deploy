#!/bin/bash


  # GITHUB_ACTION_PATH: ${{ github.action_path }}
  #       SERVER_HOST: ${{ inputs.server_host }}
  #       SERVER_USERNAME: ${{ inputs.server_username }}
  #       SERVER_PASSWORD: ${{ inputs.server_password }}
  #       SERVER_PORT: ${{ inputs.server_port }}
  #       DIR: ${{ inputs.dir }}
  #       DOCKERFILE: ${{ inputs.dockerfile }}
  #       START_COMMAND: ${{ inputs.start_command }}
  #       COMPOSE_FILE: ${{ inputs.compose_file }}
  #       EXPOSED_PORT: ${{ inputs.exposed_port }}
  #       ENV_VARS: ${{ inputs.env }}

set -e
# path to the directory where the project will be cloned
PATH="/srv/hngprojects"
CONTAINER_NAME="${BRANCH_NAME}_${PR_NUMBER}_container"
echo "Starting deployment..."


ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST << EOF
  set -e

  echo "Cloning the repository..."
  # if [ -d "$DIR" ]; then
  #   rm -rf $DIR
  # fi
  git clone $REPO_URL $PATH

  PROJECT_NAME=$(basename -s .git $REPO_URL)
  cd $PROJECT_NAME


  # echo "Checking for existing container..."
  # if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  #   echo "Stopping and removing existing container..."
  #   docker rm -f $CONTAINER_NAME
  # fi

  if [[ ! -d "$DIR" ]]; then
    echo "Directory not found: $DIR, please check the directory path."
    exit 1
  fi

  cd $DIR
  if [ -n "$DOCKERFILE" ]; then
      if [ ! -f "$DOCKERFILE" ]; then
        echo "Dockerfile not found in the specified path: $DOCKERFILE"
        exit 1;
      fi
    build_output=$(docker build -t $CONTAINER_NAME -f $DOCKERFILE 2>&1)
    echo "$build_output"
    run_output=$(docker run -d --name $CONTAINER_NAME -p $EXPOSED_PORT:$EXPOSED_PORT --env $ENV_VARS $CONTAINER_NAME 2>&1)
    echo "$run_output"
  elif [[ -n "$COMPOSE_FILE" ]]; then
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Docker compose file not found in the specified path: $COMPOSE_FILE"
        echo "success" >> $GITHUB_OUTPUT
        exit 1;
    fi
    echo "docker-compose.yml detected. Building and deploying using Docker Compose..."
    down_output=$(docker-compose down 2>&1)
    echo "$down_output"
    up_output=$(docker-compose up -d --build 2>&1)
    echo "$up_output"
  else
    echo "No Dockerfile or docker-compose.yml found. Running start command..."
    start_output=$($START_COMMAND 2>&1)
    echo "$start_output"
    exit 1
  fi

  echo "Deployment completed. Container name: $CONTAINER_NAME"
  echo "Container status:"
  status_output=$(docker ps -f name=$CONTAINER_NAME 2>&1)
  echo "$status_output"

  echo "Fetching container logs..."
  logs_output=$(docker logs $CONTAINER_NAME 2>&1)
  echo "$logs_output"
EOF
echo "Deployment script executed."
