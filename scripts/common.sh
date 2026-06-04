#!/bin/bash

# Helper function: use sudo only if not root
run_as_root() {
    if [ "$EUID" -eq 0 ]; then
        # Already root, run directly
        "$@"
    else
        # Not root, use sudo
        sudo "$@"
    fi
}

# Common initialization - runs ONCE
init_system() {
    echo "Initializing system..."
    run_as_root apt-get update
}

# Install common prerequisites for adding third-party repos
install_prerequisites() {
    echo "Installing prerequisites for third-party repositories..."
    run_as_root apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
}
