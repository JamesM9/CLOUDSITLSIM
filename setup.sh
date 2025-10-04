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

# Make all shell scripts executable
echo "Setting up script permissions..."
chmod +x *.sh

# Install system dependencies
echo "Installing system dependencies..."
bash ./setup_dependencies.sh

# Install PX4 toolchain
echo "Installing PX4 toolchain..."
echo "⚠️  WARNING: PX4 build can take 10-30 minutes. Please be patient!"
bash ./setup_px4.sh

# Verify PX4 installation
echo "Verifying PX4 installation..."
if [ -f "sitl_engines/px4/PX4-Autopilot/build/px4_sitl_default/bin/px4" ]; then
    echo "✅ PX4 installation verified successfully"
else
    echo "❌ Error: PX4 installation failed"
    echo "Please check the output above for error messages"
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
if command -v python3 > /dev/null; then
    echo "Python 3 found: $(python3 --version)"
    
    # Check if pip3 is available
    if command -v pip3 > /dev/null; then
        echo "Installing Python packages with pip3..."
        pip3 install --user -r requirements.txt
    else
        echo "Installing Python packages with python3 -m pip..."
        python3 -m pip install --user -r requirements.txt
    fi
    
    # Verify Flask installation
    if python3 -c "import flask" 2>/dev/null; then
        echo "✅ Flask installation verified"
    else
        echo "❌ Flask installation failed, trying alternative method..."
        pip3 install --user flask psutil pyyaml requests gunicorn
    fi
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
