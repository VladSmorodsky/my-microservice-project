#!/bin/bash

install_docker_compose() {
    echo "Docker compose installation starts..."

    # Check if Docker is installed first
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install Docker first."
        echo "Docker compose installation aborted."
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo "Docker is installed but not running. Please start Docker."
        return 1
    fi

    # Check if Docker Compose is available
    if docker compose version &> /dev/null; then
        echo "Docker Compose is already installed"
        docker compose version
        return 0
    fi

    # Install Docker Compose plugin
    echo "Installing Docker Compose plugin..."
    run_as_root apt-get update
    run_as_root apt-get install -y docker-compose-plugin

    # Verify installation
    if docker compose version &> /dev/null; then
        echo "Docker Compose installed successfully"
        docker compose version
    else
        echo "Docker Compose installation failed"
        return 1
    fi

    echo "Docker compose finished."
}
