#!/bin/bash

install_django() {
    echo "Django installation starts..."

    # Check if Python is installed first
    if ! command -v python3 &> /dev/null; then
        echo "Python is not installed. Please install Python first."
        return 1
    fi

    # Check if pip is installed
    if ! command -v pip3 &> /dev/null; then
        echo "Installing pip..."
        run_as_root apt-get update
        run_as_root apt-get install -y python3-pip
    fi

    # Check if Django is already installed
    if python3 -c "import django" &> /dev/null; then
        echo "Django is already installed"
        python3 -m django --version
        return 0
    fi

    # Install Django globally
    echo "Installing Django..."
    pip3 install django

    # Verify installation
    if python3 -c "import django" &> /dev/null; then
        echo "Django installed successfully"
        python3 -m django --version
    else
        echo "Django installation failed"
        return 1
    fi

    echo "Django installation finished."
}
