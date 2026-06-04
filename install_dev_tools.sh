#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library files
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/docker.sh"
source "$SCRIPT_DIR/scripts/docker_compose.sh"
source "$SCRIPT_DIR/scripts/python.sh"
source "$SCRIPT_DIR/scripts/django.sh"

# Initialize system
init_system

# Define installation order
installing_order=(docker docker_compose python django)

# Track failures
failed_tools=()

# Install tools in order
for tool in "${installing_order[@]}"; do
    echo "==== Processing $tool ===="

    if install_${tool}; then
        echo "$tool setup completed successfully"
    else
        echo "$tool setup failed"
        failed_tools+=("$tool")
    fi
    echo ""
done

# Summary
if [ ${#failed_tools[@]} -eq 0 ]; then
    echo "==== Installation complete ===="
else
    echo "==== Installation finished with errors ===="
    echo "Failed tools: ${failed_tools[*]}"
    exit 1
fi
