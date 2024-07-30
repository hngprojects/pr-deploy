#!/bin/bash

set -e

chmod +x pr-deploy.sh

sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT ./pr-deploy.sh $SERVER_USERNAME@$SERVER_HOST:/srv/pr-deploy.sh

DEPLOYED_URL=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST /srv/pr-deploy.sh $CONTEXT $DOCKERFILE $EXPOSED_PORT $REPO_URL $REPO_OWNER $REPO_NAME $GITHUB_HEAD_REF $PR_NUMBER | tail -n 1)

COMMENT="
<table>
  <tr>
    <th>Deoloyed Branch</th>
    <th>Status</th>
    <th>Preview URL</th>
    <th>Updated At</th>
  </tr>
  <tr>
    <td>$GITHUB_HEAD_REF</td>
    <td>Deployed</td>
    <td><a href=\"$DEPLOYED_URL\">$DEPLOYED_URL</a></td>
    <td>$(date)</td>
  </tr>
</table>
"

curl -s -H "Authorization: token $GITHUB_TOKEN" -X POST \
    -d "$(jq -n --arg body "Deployed URL: $COMMENT" '{body: $body}')" \
    "https://api.github.com/repos/hngprojects/pr-deploy/issues/15/comments"

echo "Deployed URL: $DEPLOYED_URL"
