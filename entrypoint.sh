#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Copy the pr-deploy.sh script to the remote server.
# Create a remote script that sets the variable and runs the main script.
echo '#!/bin/bash' > remote_script.sh
echo "REPO_URL='$REPO_URL'" >> remote_script.sh
echo 'chmod +x /srv/pr-deploy.sh' >> remote_script.sh
echo '/srv/pr-deploy.sh' >> remote_script.sh

# Copy and execute the remote script.
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -P $SERVER_PORT remote_script.sh $SERVER_USERNAME@$SERVER_HOST:/root/remote_script.sh
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -p $SERVER_PORT $SERVER_USERNAME@$SERVER_HOST 'bash /root/remote_script.sh'
