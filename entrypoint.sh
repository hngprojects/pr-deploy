#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get pr_number and pr_action
PR_ACTION="$1"
PR_NUMBER="$2"

# Make the pr-deploy.sh script executable.
chmod +x pr-deploy.sh

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT ./pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server and capture the last line of its output.
DEPLOYED_URL=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST /srv/pr-deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $GITHUB_SHA $SERVER_HOST | tail -n 1)

# Prepare the comment to be posted on GitHub.
COMMENT="Here are the latest updates on your deployment. Check out the action and star our project for more insights! 🔗

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
      <td><a href=\"https://github.com/hng-projects/pr-deploy/actions\">PR Deploy</a></td>
      <td>Deployed 🚀</td>
      <td><a href=\"$DEPLOYED_URL\">Preview Link</a></td>
      <td>$(date +'%b %d, %Y %I:%M%p')</td>
    </tr>  
  </tbody>
</table>"


# Post the comment on the specified pull request.
curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
    -d "$(jq -n --arg body "$COMMENT" '{body: $body}')" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/issues/${PR_NUMBER}/comments" > /dev/null

# Echo the deployed URL.
echo "Deployed URL: $DEPLOYED_URL"

