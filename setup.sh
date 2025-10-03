#!/bin/bash
set -e

echo "======================================"
echo "CloudSITLSIM Installation Script"
echo "======================================"
echo ""

# Check if running on Ubuntu 22.04
if command -v lsb_release > /dev/null; then
    OS_VERSION=$(lsb_release -rs)
    if [[ "$OS_VERSION" != "22.04" ]]; then
        echo "Warning: This script is designed for Ubuntu 22.04 LTS"
        echo "Current version: $OS_VERSION"
        echo "Proceeding anyway..."
        echo ""
    fi
else
    echo "Warning: Unable to detect Ubuntu version"
    echo "Proceeding anyway..."
    echo ""
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script should not be run as root"
    echo "Please run as a regular user with sudo privileges"
    exit 1
fi

# Check if sudo is available
if ! command -v sudo > /dev/null; then
    echo "Error: sudo is required but not installed"
    exit 1
fi

# Create project directories
echo "Creating project directories..."
mkdir -p logs
mkdir -p sitl_engines/px4
mkdir -p sitl_engines/ardupilot
mkdir -p config
mkdir -p static/css
mkdir -p static/js
mkdir -p static/images
mkdir -p templates
mkdir -p docs

# Install system dependencies
echo "Installing system dependencies..."
bash ./setup_dependencies.sh

# Install PX4 toolchain
echo "Installing PX4 toolchain..."
bash ./setup_px4.sh

# Install Python dependencies
echo "Installing Python dependencies..."
if command -v python3 > /dev/null; then
    python3 -m pip install --user -r requirements.txt
else
    echo "Error: Python 3 is required but not installed"
    exit 1
fi

# Initialize application database
echo "Initializing application..."
python3 init_db.py

# Set up permissions
echo "Setting up permissions..."
chmod +x start_cloudsitlsim.sh
chmod +x start_px4_sitl.sh

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Configure your settings in config/config.yaml"
echo "2. Run: ./start_cloudsitlsim.sh"
echo "3. Open your browser to http://localhost:5000"
echo ""
echo "For more information, see README.md"
