# Coder Full Development Container

This Docker image provides a comprehensive development environment with various tools pre-installed including Docker, Node.js, Go, Kubernetes tools, and more.

## Features

- **Docker-in-Docker (DinD)**: Docker daemon runs automatically inside the container
- **Node.js** with NVM for version management
- **Go** programming language
- **Kubernetes tools**: kubectl, helm, k9s
- **Hasura CLI** for GraphQL development
- **Yarn** package manager
- And many other development tools

## Running the Container

To use Docker-in-Docker functionality, you must run the container with the `--privileged` flag:

```bash
docker run --privileged -it ghcr.io/frantche/coder-full:latest
```

### Without Privileged Mode

If you run the container without `--privileged`:

```bash
docker run -it ghcr.io/frantche/coder-full:latest
```

You'll see a warning message, but the container will still start. Docker commands will not work until you restart the container with proper privileges.

## Docker-in-Docker

The container includes an entrypoint script that automatically starts the Docker daemon when the container starts. This allows you to:

- Build Docker images inside the container
- Run Docker containers within the container
- Use docker-compose
- Access the full Docker CLI

## Pre-installed Software

Check the `dockerfile` for the complete list of installed tools and their versions.

## Development

All tools are available to the `coder` user (UID 1000) who has sudo privileges without password.
