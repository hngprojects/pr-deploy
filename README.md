 # About

This GitHub Action deploys pull requests in Docker containers, allowing you to test your changes in an isolated environment before merging. This documentation has been sectioned into two; First section for Contributors and the Second section for User



## For Users

## Usage
Pull request events trigger this action. It builds the Docker image for the pull request and deploys it in a new Docker container. This step calls the action tool in the workflow script
```
steps:
- uses: hngprojects/pr-deploy@v1.0.0
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
      - name: Deploy PR
        uses: hngprojects/pr-deploy@v1.0.0
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


## For Contributors
### Overview
These tool made use of two files named:
- action.yml
- entrypoint.sh

`action.yml`:
The file declares the inputs needed to deploy the pull request in isolated docker containers. 

`entrypoint.sh`:
With the aid of the inputs retrieved by the actions.yml file, the shell script automates the deployment process.

### How to Contribute
1. **Fork the Repository**: Start by forking the repository to your GitHub account.

2. **Create a New Branch**: Create a branch for your feature or bugfix
   ```
    git checkout -b feature/your-feature-name
   ```
3. **Modify Inputs**: If adding new inputs or modifying existing ones:
   - Ensure they are documented in action.yml.
   - Update the shell script to handle these inputs appropriately.

4. **Update Documentation**: Reflect any changes in the README.md file.

5. **Commit Your Changes**: With a descriptive message:
   ```
   git commit -m 'Add feature: your-feature-name'

   ```

6. **Push to Your Branch**:
   ```
   git push origin feature/your-feature-name

   ```
 

## Troubleshooting tips:

- If the action fails, check the GitHub Actions logs for detailed error messages.
- Ensure that your server's firewall allows incoming connections on the SSH port and the random port range used for deployments.
- Verify that the server has sufficient resources (CPU, memory, disk space) to run multiple Docker containers.

## Best practices:

- Regularly update the action to the latest version to benefit from bug fixes and improvements.
- Use environment variables for sensitive information instead of hardcoding them in your Dockerfile or start command.
- Implement proper access controls on your deployment server to ensure security.
- Regularly clean up unused containers and images to conserve server resources.
