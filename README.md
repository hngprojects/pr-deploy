 # GitHub Action Tool: Pr-deploy
## Release: v1.0.0

### About

This GitHub Action deploys pull requests in Docker containers, allowing you to test your changes in an isolated environment before merging. This documentation has been sectioned into two; First section for Contributors and the Second section for User



## For Contributors
### Overview
These tool made use of two files named:
- action.yml
- entrypoint.sh

The `.yml` file declares the inputs needed to deploy the pull request in isolated docker containers. 

The shell script with the aid of the inputs retrieved by the actions.yml file automates the deployment process.

 
 
**For Users**
------------------------------------------------------------------------------------------------------------------
## Usage
Pull request events trigger this action. It builds the Docker image for the pull request and deploys it in a new Docker container. This step calls the action tool in the workflow script
```
steps:
- uses: ./
```
## Inputs
The following inputs are required to configure the GitHub Action. These inputs allow the action to connect to your server, specify the:
- context, that is where the Dockerfile is located.
- define the Dockerfile for deployment.
- set the environmental variables in Github secrets.

The environmental variables needed for this tool version are:
- SERVER_HOST
- SEVER_PASSWORD
- SEVER_USERNAME
- SERVER_PORT

### Example Workflow File
To help you get started quickly, here’s an example of configuring your GitHub Actions workflow file to deploy pull requests in Docker containers using this GitHub Action. This setup allows you to automatically build and deploy your application whenever a pull request is opened, ensuring your changes are tested in an isolated environment.
Your workflow file should be formatted as follows:
```
name: PR Deploy
on:
  pull_request

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy PR
        uses: ./
        with:
          server_host: ${{ secrets.SERVER_HOST }}
          server_username: ${{ secrets.SERVER_USERNAME }}
          server_password: ${{ secrets.SERVER_PASSWORD }}
          server_port: ${{ secrets.SERVER_PORT }}
          context: '.'
          dockerfile: 'Dockerfile'
          exposed_port: '5000'
          compose_file: 'docker-compose.yml'
```
