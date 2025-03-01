#!/bin/bash
set -euo pipefail

# Enable command tracing to show all commands executed
set -x

# Detect which container system we're using and set appropriate user namespace flags
CONTAINER_CMD=""
if command -v podman &> /dev/null; then
    echo "Detected Podman container system"
    CONTAINER_CMD="podman"
    export CONTAINER_USERNS="--userns keep-id"
elif command -v docker &> /dev/null; then
    echo "Detected Docker container system"
    CONTAINER_CMD="docker"
    export CONTAINER_USERNS="-u $(id -u):$(id -g)"
    
    # Add current user to docker group to avoid needing sudo for Docker
    USER=${USER:-$(whoami)}
    sudo usermod -aG docker $USER
    if ! groups | grep -q docker; then
        exec sg docker -c "$0 $*"
    fi
    
    # Make sure Docker is running
    if ! docker info &>/dev/null; then
        # Try to start docker service using service command first (works in containers)
        sudo service docker start || true
        sleep 2
    fi
else
    echo "Neither Docker nor Podman is installed. Attempting to install Docker..."
    
    # Install Docker using apt (for Debian/Ubuntu)
    sudo apt-get update
    sudo apt-get install -y docker.io
    
    # Start Docker service (use service command which works better in containers)
    sudo service docker start || true
    
    # Add current user to docker group
    USER=${USER:-$(whoami)}
    sudo usermod -aG docker $USER
    echo "Docker installed. You might need to log out and back in for group changes to take effect."
    echo "For now, we'll continue with sudo..."
    
    CONTAINER_CMD="docker"
    export CONTAINER_USERNS="-u $(id -u):$(id -g)"
fi

# Show container system info and user groups
groups
$CONTAINER_CMD info

# Create ccache directory
mkdir -p "$HOME/.ccache"

# Go to the src directory
cd "$(dirname "$0")/src"

# Run buildallprojects with all arguments passed through
./buildallprojects "$@"
