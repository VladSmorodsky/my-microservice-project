#!/bin/bash

install_docker() {
    echo "Docker installation starts..."

    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        echo "Docker is already installed"
        docker --version
        return 0
    fi

    # Install prerequisites
    install_prerequisites

    # Add Docker's official GPG key
    echo "Adding Docker GPG key..."
    run_as_root mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | run_as_root gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo "Setting up Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | run_as_root tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    echo "Installing Docker Engine..."
    run_as_root apt-get update
    run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker service
    echo "Starting Docker service..."
    run_as_root systemctl start docker
    run_as_root systemctl enable docker

    # Add current user to docker group (avoids needing sudo for docker commands)
    echo "Adding user to docker group..."
    run_as_root usermod -aG docker $USER

    echo "Docker installed successfully!"
    docker --version
    echo "Please log out and back in for group changes to take effect."
    echo "Docker installation finished."
}
