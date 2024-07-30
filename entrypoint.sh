#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

comment() {
    local status_message=$1
    local preview_url=$2

    # Construct the comment body
    COMMENT_BODY=$(jq -n --arg body "<strong>Here are the latest updates on your deployment.</strong> Explore the action and ⭐ star our project for more insights! 🔍
    
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
          <td><a href='https://github.com/hngprojects/pr-deploy'>PR Deploy</a></td>
          <td>${status_message}</td>
          <td><a href='${preview_url}'>Visit Preview</a></td>
          <td>$(date +'%b %d, %Y %I:%M%p')</td>
        </tr>  
      </tbody>
    </table>" '{body: $body}')

    if [ -z "$COMMENT_ID" ]; then
        # Create a new comment
        curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
            -d "$COMMENT_BODY" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" > /dev/null
    else
        # Update an existing comment
        curl -s -H "Authorization: token $GITHUB_TOKEN" -X PATCH \
            -d "$COMMENT_BODY" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/comments/${COMMENT_ID}" > /dev/null
    fi
}

# Make the pr-deploy.sh script executable.
chmod +x pr-deploy.sh

# Define the file to store the comment ID
FILE_NAME="${REPO_OWNER}_${REPO_NAME}_${GITHUB_HEAD_REF}_${PR_NUMBER}"
# COMMENT_ID_FILE="${GITHUB_WORKSPACE}/${FILE_NAME}.txt"

# Checks if the action is opened
if [ "$PR_ACTION" == "opened" ]; then
  comment "Deploying ⏳" "#"
fi

# Make an API request to get the comments on the pull request
RESPONSE_DATA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments")

# Parse the response to extract the ID of the first comment made by github-actions
COMMENT_ID=$(echo "$RESPONSE_DATA" | jq -r '[.[] | select(.user.login == "github-actions[bot]")] | first | .id')

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT ./pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server and capture the last line of its output.
DEPLOYED_URL=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST /srv/pr-deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $GITHUB_SHA $SERVER_HOST $PR_ACTION $PR_NUMBER | tail -n 1)

if [  -z "$DEPLOYED_URL" ]; then
    comment "Failed ❌" "#"
elif [ "$PR_ACTION" == "closed" ]; then
    comment "Terminated 🛑" "#"
else
    comment "Deployed 🎉" $DEPLOYED_URL
fi
