#!/bin/bash

check_python_version() {
    local min_version="3.9"
    local max_version="3.14"
    local python_cmd=$1

    if ! command -v "$python_cmd" &> /dev/null; then
        return 1
    fi

    local version=$($python_cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)

    # Check if version >= 3.9 AND version <= 3.14
    if [ "$(printf '%s\n' "$min_version" "$version" | sort -V | head -n1)" = "$min_version" ] && \
       [ "$(printf '%s\n' "$max_version" "$version" | sort -V | tail -n1)" = "$max_version" ]; then
        return 0
    else
        return 1
    fi
}

install_python() {
    echo "Python installation starts..."
    local PYTHON_VERSIONS=(3.14 3.13 3.12 3.11 3.10 3.9)
    local min_version="${PYTHON_VERSIONS[-1]}"  # Last element (3.9)
    local max_version="${PYTHON_VERSIONS[0]}"   # First element (3.14)

    # Check if Python is already installed with correct version
    if command -v python3 &> /dev/null; then
        echo "Python is already installed"
        python3 --version

        if check_python_version "python3"; then
            echo "Python version is in range $min_version - $max_version"
            return 0
        else
            echo "Warning: Python version is outside range $min_version - $max_version"
            echo "Attempting to install a suitable version..."
        fi
    fi

    # Install Python 3
    echo "Installing Python 3..."
    run_as_root apt-get update

    # Try to install specific versions if available
    for version in "${PYTHON_VERSIONS[@]}"; do
        if run_as_root apt-cache show python${version} &> /dev/null; then
            echo "Found Python ${version} in repositories, installing..."
            run_as_root apt-get install -y python${version} python${version}-venv python3-pip

            # Set python3 to point to this version
            run_as_root update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${version} 1

            if check_python_version "python3"; then
                break
            fi
        fi
    done

    # Fallback to default python3 if specific versions are not available
    if ! check_python_version "python3"; then
        echo "Installing default python3 package..."
        run_as_root apt-get install -y python3 python3-pip python3-venv
    fi

    # Verify installation
    if command -v python3 &> /dev/null; then
        python3 --version
        pip3 --version

        if check_python_version "python3"; then
            echo "Python installed successfully with version in range $min_version - $max_version"
        else
            echo "ERROR: Python installed but version is outside range $min_version - $max_version"
            echo "Consider upgrading your system or using a different repository"
            return 1
        fi
    else
        echo "Python installation failed"
        return 1
    fi

    echo "Python installation finished."
}
