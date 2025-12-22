# Coder Full Development Container

This Docker image provides a comprehensive development environment with various tools pre-installed including Docker, Node.js, Go, Kubernetes tools, and more.

## Features

- **Docker-in-Docker (DinD)**: Docker daemon runs automatically inside the container when started with `--privileged` flag
- **Node.js** with NVM for version management
- **Go** programming language
- **Kubernetes tools**: kubectl, helm, k9s
- **Hasura CLI** for GraphQL development
- **Yarn** package manager
- **GitHub Copilot CLI** for AI-powered command line assistance
- **PostgreSQL client (psql)** for database interactions
- And many other development tools

## Running the Container

To use Docker-in-Docker functionality, you **must** run the container with the `--privileged` flag:

```bash
docker run --privileged -it ghcr.io/frantche/coder-full:latest
```

The Docker daemon will start automatically and be ready for use within seconds.

### Without Privileged Mode

If you run the container without `--privileged`:

```bash
docker run -it ghcr.io/frantche/coder-full:latest
```

You'll see a warning message that the Docker daemon failed to start. The container will still start normally, and all other tools will be available. However, Docker commands will not work until you restart the container with the `--privileged` flag.

## Docker-in-Docker

The container includes an entrypoint script that automatically starts the Docker daemon when the container starts (with `--privileged` flag). This allows you to:

- Build Docker images inside the container
- Run Docker containers within the container
- Use docker-compose
- Access the full Docker CLI and API

**Note**: The Docker daemon requires privileged mode to function. This is a security requirement of Docker-in-Docker and cannot be bypassed.

## Pre-installed Software

Check the `dockerfile` for the complete list of installed tools and their versions.

## Development

All tools are available to the `coder` user (UID 1000) who has sudo privileges without password.

## Testing Note

The automated container structure tests verify that the Docker CLI is installed and properly configured. Since these tests run without privileged mode (by design), they expect the Docker daemon connection to fail, which is normal and correct behavior. When you run the container with `--privileged` flag, Docker will work correctly.
