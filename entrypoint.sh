#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Make the pr-deploy.sh script executable.
chmod +x pr-deploy.sh

# Copy the pr-deploy.sh script to the remote server.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT ./pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

# Run the pr-deploy.sh script on the remote server and capture the last line of its output.
DEPLOYED_URL=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST /srv/pr-deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $PR_NUMBER | tail -n 1)

# Prepare the comment to be posted on GitHub.
COMMENT="
<table style=\"width:100%;border-collapse:collapse;\">
  <thead>
    <tr style=\"background-color:#f2f2f2;\">
      <th style=\"border:1px solid #ddd;padding:8px;text-align:left;\">Deployed Branch</th>
      <th style=\"border:1px solid #ddd;padding:8px;text-align:left;\">Status</th>
      <th style=\"border:1px solid #ddd;padding:8px;text-align:left;\">Preview URL</th>
      <th style=\"border:1px solid #ddd;padding:8px;text-align:left;\">Updated At</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style=\"border:1px solid #ddd;padding:8px;\">$GITHUB_HEAD_REF</td>
      <td style=\"border:1px solid #ddd;padding:8px;\">Deployed</td>
      <td style=\"border:1px solid #ddd;padding:8px;\"><a href=\"$DEPLOYED_URL\">$DEPLOYED_URL</a></td>
      <td style=\"border:1px solid #ddd;padding:8px;\">$(date)</td>
    </tr>
  </tbody>
</table>"

# Post the comment on the specified pull request.
curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
    -d "$(jq -n --arg body "$COMMENT" '{body: $body}')" \
    "https://api.github.com/repos/hngprojects/pr-deploy/issues/16/comments"

# Echo the deployed URL.
echo "Deployed URL: $DEPLOYED_URL"

