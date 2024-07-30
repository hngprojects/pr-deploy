#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

comment() {
    COMMENT="<strong>Here are the latest updates on your deployment.</strong> Explore the action and ⭐ star our project for more insights! 🔍
    
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
          <td><a href=\"https://github.com/hngprojects/pr-deploy\">PR Deploy</a></td>
          <td>${1} 🚀</td>
          <td><a href=\"$DEPLOYED_URL\">${2-""}</a></td>
          <td>$(date +'%b %d, %Y %I:%M%p')</td>
        </tr>  
      </tbody>
    </table>"
}

# Make the pr-deploy.sh script executable.
chmod +x pr-deploy.sh

# Define the file to store the comment ID
FILE_NAME="${REPO_OWNER}_${REPO_NAME}_${GITHUB_HEAD_REF}_${PR_NUMBER}"
# COMMENT_ID_FILE="${GITHUB_WORKSPACE}/${FILE_NAME}.txt"

# Checks if the action is opened
if [ "$PR_ACTION" == "opened" ]; then
  comment "Deploying ⏳" "#"
  curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
      -d "$(jq -n --arg body "${COMMENT}" '{body: $body}')" \
      "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" > /dev/null
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
    curl -X PATCH -H "Authorization: token $GITHUB_TOKEN" \
         -d "$(jq -n --arg body "${COMMENT}" '{body: $body}')" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/comments/$COMMENT_ID" > /dev/null
elif [ "$PR_ACTION" == "closed" ]; then
    comment "Terminated 🛑" "#"
    curl -X PATCH -H "Authorization: token $GITHUB_TOKEN" \
         -d "$(jq -n --arg body "${COMMENT}" '{body: $body}')" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/comments/$COMMENT_ID" > /dev/null
else
    comment "Deployed 🎉" $DEPLOYED_URL
    curl -X PATCH -H "Authorization: token $GITHUB_TOKEN" \
         -d "$(jq -n --arg body "${COMMENT}" '{body: $body}')" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/comments/$COMMENT_ID" > /dev/null
fi
