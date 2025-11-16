#!/bin/bash
set -e

# Function to start Docker daemon
start_docker() {
    echo "Starting Docker daemon..."
    
    # Create directory for Docker daemon logs if it doesn't exist
    sudo mkdir -p /var/log
    
    # Start Docker daemon in the background with proper settings
    sudo dockerd --host=unix:///var/run/docker.sock > /var/log/dockerd.log 2>&1 &
    
    # Wait for Docker daemon to be ready
    echo "Waiting for Docker daemon to start..."
    for i in {1..30}; do
        if docker info > /dev/null 2>&1; then
            echo "Docker daemon is ready!"
            return 0
        fi
        sleep 1
    done
    
    echo "Docker daemon failed to start within 30 seconds"
    echo "Docker daemon logs:"
    cat /var/log/dockerd.log
    return 1
}

# Start Docker daemon
start_docker || echo "Warning: Docker daemon failed to start. You may need to run this container with --privileged flag."

# Execute the command passed to docker run or start a shell
exec "$@"
