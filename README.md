 GitHub Action Tool
 # Pr-deploy
release:v1.0.0

## About
This GitHub Action deploys pull requests in Docker containers, allowing you to test your changes in an isolated environment before merging.

## Example Workflow File
To help you get started quickly, here’s an example of how to configure your GitHub Actions workflow file to deploy pull requests in Docker containers using this GitHub Action. This setup allows you to automatically build and deploy your application whenever a pull request is opened, ensuring your changes are tested in an isolated environment.

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
          dir: '.'
          dockerfile: 'Dockerfile'
          exposed_port: '5000'
          compose_file: 'docker-compose.yml'
```
