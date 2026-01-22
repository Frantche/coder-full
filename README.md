# Coder Full Development Container

This Docker image provides a comprehensive development environment with various tools pre-installed including Docker, Node.js, Go, Kubernetes tools, and more.

## Features

- **Docker-in-Docker (DinD)**: Docker daemon runs automatically inside the container when started with `--privileged` flag
- **Node.js** with NVM for version management
- **Go** programming language
- **Kubernetes tools**: kubectl, helm, k9s
- **Tilt** for local Kubernetes development and live updates
- **Hasura CLI** for GraphQL development
- **Yarn** package manager
- **GitHub Copilot CLI** for AI-powered command line assistance
- **opencode-ai** for AI-powered coding assistance
- **@fission-ai/openspec** for OpenAPI specification tools
- **PostgreSQL client (psql) version 18** for database interactions
- **ripgrep (rg)** for fast recursive search through files
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

## Tool Highlights

### ripgrep (rg)

ripgrep is a line-oriented search tool that recursively searches your current directory for a regex pattern. It's extremely fast and respects .gitignore rules by default.

**Basic Usage:**

```bash
# Search for a pattern in the current directory
rg "search_pattern"

# Search for a pattern in a specific directory
rg "search_pattern" /path/to/directory

# Case-insensitive search
rg -i "pattern"

# Search for whole words only
rg -w "word"

# Show file names only (without matches)
rg -l "pattern"

# Search with file type filtering
rg -t py "pattern"  # Search only in Python files
rg -t js "pattern"  # Search only in JavaScript files

# Show context around matches
rg -C 3 "pattern"  # Show 3 lines before and after

# Search and replace preview
rg "old_pattern" --replace "new_pattern"
```

For more information, run `rg --help` or visit [ripgrep documentation](https://github.com/BurntSushi/ripgrep).

### Tilt

Tilt is a modern dev tool that enables fast, iterative development for Kubernetes and Docker Compose applications. It automates the workflow of building, deploying, and monitoring your app as you make changes.

**Basic Usage:**

```bash
# Start Tilt in your project directory (requires a Tiltfile)
tilt up

# Start Tilt in the background
tilt up -- --stream=false

# Check the status of running resources
tilt get all

# View logs for a specific resource
tilt logs <resource-name>

# Stop Tilt and clean up resources
tilt down

# Check Tilt version
tilt version
```

For more information, run `tilt --help` or visit [Tilt documentation](https://docs.tilt.dev/).

## Testing

This project includes comprehensive tests to verify all installed tools work correctly:

### Container Structure Tests

Located in `image-tests.yaml`, these tests verify that all tools are installed with the correct versions and basic functionality. Tests run automatically in CI/CD for every pull request and push to main.

To run tests locally:

```bash
# Build the image
docker build -t coder-full:test -f dockerfile .

# Run container structure tests (requires container-structure-test)
container-structure-test test --image coder-full:test --config image-tests-rendered.yaml
```

## Testing Note

The automated container structure tests verify that the Docker CLI is installed and properly configured. Since these tests run without privileged mode (by design), they expect the Docker daemon connection to fail, which is normal and correct behavior. When you run the container with `--privileged` flag, Docker will work correctly.

## Dependency Management with Renovate

This project uses [Renovate](https://github.com/renovatebot/renovate) to automatically keep dependencies up-to-date. Renovate is configured via the `renovate.json` file in the repository root.

**Key Features:**

- Automatic detection of outdated dependencies in the Dockerfile
- Automated pull requests for dependency updates
- Configured to auto-merge updates when all checks pass
- Custom regex matchers for VERSION variables in Dockerfile

**Tracked Dependencies:**

Renovate monitors and creates PRs for updates to:
- Docker base image (Ubuntu)
- Docker CE
- Node.js
- Go
- Kubernetes tools (kubectl, helm, k9s)
- Tilt
- Hasura CLI
- PostgreSQL client
- ripgrep
- npm packages (GitHub Copilot CLI, opencode-ai, openspec)
- And other tools with version ARGs in the Dockerfile

All tools with `# renovate:` comments in the Dockerfile are automatically tracked for updates.

**Manual Configuration:**

To modify Renovate behavior, edit the `renovate.json` file. Refer to the [Renovate documentation](https://docs.renovatebot.com/) for configuration options.
