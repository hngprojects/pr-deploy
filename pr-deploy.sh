name: "Pull Request Deploy"
description: "A GitHub action to automate the deployment of pull requests"
branding:
  icon: "cloud"
  color: "blue"

inputs:
  context:
    description: Directory in the repository where the Dockerfile is located
    required: false
    default: .
  dockerfile:
    description: Path to the Dockerfile
    required: false
    default: Dockerfile
  exposed_port:
    description: Port to expose in the container
    required: true
  envs:
    description: Environment variables to pass to the container (multi-line string)
    required: false
  github_token:
    description: GitHub token to authenticate API requests
    required: true
  server_host:
    description: Hostname or IP address of the server
    required: true
  server_username:
    description: Username for SSH connection
    required: true
  server_password:
    description: Password for SSH connection
    required: true
  server_port:
    description: SSH port of the server
    required: false
    default: 22

outputs:
  preview-url:
    description: "Preview URL"
    value: ${{ steps.deploy.outputs.preview-url }}

runs:
  using: 'composite'
  steps:
    - id: deploy
      name: Deploy Pull Request
      shell: bash
      run: |
        sshpass -p "${{ inputs.server_password }}" ssh -o StrictHostKeyChecking=no -p "${{ inputs.server_port }}" "${{ inputs.server_username }}@${{ inputs.server_host }}" << 'EOF' | tee "/tmp/preview_${GITHUB_RUN_ID}.txt"

          export GITHUB_TOKEN="${{ inputs.github_token }}"
          export CONTEXT="${{ inputs.context }}"
          export DOCKERFILE="${{ inputs.dockerfile }}"
          export EXPOSED_PORT="${{ inputs.exposed_port }}"
          export ENVS="${{ inputs.envs }}"
          REPO_URL="${{ github.event.repository.clone_url }}"
          export REPO_URL="https://actions:${GITHUB_TOKEN}@${REPO_URL#https://}"
          export BRANCH="${{ github.head_ref }}"
          export PR_ID="pr_${{ github.event.repository.id }}_${{ github.event.number }}"
          export PR_ACTION="${{ github.event.action }}"

          echo "Branch: ${BRANCH}"
          echo "${{ inputs.server_password }}" | sudo -Sv >/dev/null 2>&1
          if [[ $? -ne 0 ]]; then
            echo "Authentication failed"
            exit 1
          fi

          sudo -sE
          wget -qO /tmp/pr-deploy.sh "https://raw.githubusercontent.com/hngprojects/pr-deploy/dev/pr-deploy.sh?$(date +%s)"
          bash /tmp/pr-deploy.sh
        EOF

        PREVIEW_URL=$(tail -n 1 "/tmp/preview_${GITHUB_RUN_ID}.txt")
        echo "preview-url=${PREVIEW_URL}"
        echo "preview-url=${PREVIEW_URL}" >> $GITHUB_OUTPUT
