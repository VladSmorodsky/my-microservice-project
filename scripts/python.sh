#!/bin/bash

install_python() {
    echo "Python installation starts..."

    # Check if Python is already installed
    if command -v python3 &> /dev/null; then
        echo "Python is already installed"
        python3 --version
        return 0
    fi

    # Install Python 3
    echo "Installing Python 3..."
    run_as_root apt-get update
    run_as_root apt-get install -y python3 python3-pip python3-venv

    # Verify installation
    if command -v python3 &> /dev/null; then
        echo "Python installed successfully"
        python3 --version
        pip3 --version
    else
        echo "Python installation failed"
        return 1
    fi

    echo "Python installation finished."
}
