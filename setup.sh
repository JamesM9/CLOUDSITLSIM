#!/bin/bash
set -e

echo "======================================"
echo "CloudSITLSIM Complete Installation Script"
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

# ==========================================
# INSTALL SYSTEM DEPENDENCIES
# ==========================================
echo ""
echo "======================================"
echo "Installing System Dependencies"
echo "======================================"

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install essential build tools and system packages
echo "Installing essential build tools..."
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Python 3 and pip
echo "Installing Python 3 and pip..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-jinja2 \
    python3-pygments \
    python3-tk \
    python3-lxml \
    python3-yaml \
    python3-six \
    python3-wheel \
    python3-psutil \
    python3-serial \
    python3-future \
    python3-requests \
    python3-setuptools

# Install PX4-specific system dependencies
echo "Installing PX4-specific dependencies..."
sudo apt-get install -y \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    gstreamer1.0-libav

# Install MAVLink router dependencies
echo "Installing MAVLink router dependencies..."
sudo apt-get install -y git build-essential meson ninja-build pkg-config libsystemd-dev

# Install MAVLink router from source
echo "Installing MAVLink router from source..."
cd /tmp
rm -rf mavlink-router  # Clean up any incomplete repo

# Clone with submodules (this is the key fix!)
git clone --recursive https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router

# Build and install
echo "Building MAVLink router..."
meson setup build .
ninja -C build
sudo ninja -C build install

# Verify installation
mavlink-routerd -h > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ MAVLink router installed successfully"
else
    echo "❌ MAVLink router installation failed"
    exit 1
fi

# Clean up
cd ~
rm -rf /tmp/mavlink-router

# Install additional tools for PX4
echo "Installing additional PX4 tools..."
sudo apt-get install -y \
    ninja-build \
    exiftool \
    python3-argparse \
    python3-empy \
    python3-toml \
    python3-numpy \
    python3-packaging \
    python3-pil \
    python3-pkgconfig \
    python3-pycryptodome \
    python3-pygame \
    python3-pyparsing \
    python3-pyserial \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-mock \
    python3-pytest-xdist \
    python3-pyyaml \
    python3-requests \
    python3-setuptools \
    python3-toml \
    python3-urllib3 \
    python3-wxgtk4.0 \
    python3-wxgtk-webview4.0 \
    python3-wxgtk-media4.0 \
    python3-wxgtk-common4.0

# Install PX4-specific dependencies that the ubuntu.sh script would install
echo "Installing PX4-specific dependencies..."
sudo apt-get install -y \
    astyle \
    ccache \
    clang \
    clang-format \
    clang-tools \
    clang-tidy \
    cmake \
    curl \
    doxygen \
    file \
    g++ \
    gcc \
    gdb \
    git \
    git-lfs \
    lcov \
    libc6-dev \
    libffi-dev \
    libgtest-dev \
    libjpeg-dev \
    libltdl-dev \
    libopencv-dev \
    libssl-dev \
    libxml2-dev \
    make \
    python3-dev \
    python3-jinja2 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    rsync \
    shellcheck \
    tar \
    unzip \
    vim-common \
    wget \
    xsltproc \
    zip

# Install NuttX toolchain dependencies
echo "Installing NuttX toolchain dependencies..."
sudo apt-get install -y \
    automake \
    binutils-dev \
    bison \
    bzip2 \
    flex \
    gdb-multiarch \
    gperf \
    libncurses-dev \
    libtool \
    pkg-config \
    vim-common

# Install cross-compilation tools for x86_64
if [[ "$(uname -m)" == "x86_64" ]]; then
    echo "Installing cross-compilation tools for x86_64..."
    sudo apt-get install -y \
        g++-multilib \
        gcc-arm-none-eabi \
        gcc-multilib
fi

# Add user to dialout group for serial port access
echo "Adding user to dialout group..."
sudo usermod -aG dialout $USER

# Install additional simulation dependencies
echo "Installing simulation dependencies..."
sudo apt-get install -y \
    bc \
    dmidecode \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libeigen3-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libopencv-dev \
    libxml2-utils \
    protobuf-compiler

# Install Gazebo dependencies
echo "Installing Gazebo dependencies..."
sudo apt-get install -y \
    libignition-gazebo6-dev \
    libignition-gazebo6-plugins \
    libignition-common4-dev \
    libignition-fuel-tools7-dev \
    libignition-transport11-dev \
    libignition-msgs8-dev \
    libignition-gui6-dev \
    libignition-rendering6-dev \
    libignition-plugin1-dev \
    libignition-physics5-dev \
    libignition-math6-dev \
    libignition-cmake2-dev \
    libignition-tools1-dev \
    libsdformat12-dev \
    libgazebo-dev \
    gazebo \
    gazebo-plugin-base \
    libgazebo11-dev

# Install additional development tools
echo "Installing development tools..."
sudo apt-get install -y \
    vim \
    nano \
    htop \
    tree \
    jq \
    tmux \
    screen

echo "✅ System dependencies installation complete!"

# ==========================================
# INSTALL PX4 TOOLCHAIN
# ==========================================
echo ""
echo "======================================"
echo "Installing PX4 Toolchain"
echo "======================================"
echo "⚠️  WARNING: PX4 build can take 10-30 minutes. Please be patient!"

# Navigate to PX4 directory
cd sitl_engines/px4

# Check if PX4-Autopilot already exists
if [ -d "PX4-Autopilot" ]; then
    echo "PX4-Autopilot directory already exists. Updating..."
    cd PX4-Autopilot
    git pull
    git submodule update --init --recursive
else
    echo "Cloning PX4-Autopilot repository..."
    git clone https://github.com/PX4/PX4-Autopilot.git --recursive
    cd PX4-Autopilot
fi

# Verify the clone was successful
if [ ! -d "Tools" ]; then
    echo "❌ Error: PX4 repository clone failed"
    exit 1
fi

# PX4 dependencies already installed above, skip ubuntu.sh script
echo "PX4 dependencies already installed, skipping ubuntu.sh script..."
echo "All required dependencies for PX4 have been installed in the system dependencies section."

# Build PX4
echo "Building PX4 (this may take 10-30 minutes)..."
echo "Please be patient..."
make px4_sitl

# Verify the build was successful
if [ ! -f "build/px4_sitl_default/bin/px4" ]; then
    echo "❌ Error: PX4 build failed"
    echo "Trying to clean and rebuild..."
    make clean
    make px4_sitl
    
    # Check again
    if [ ! -f "build/px4_sitl_default/bin/px4" ]; then
        echo "❌ Error: PX4 build failed after retry"
        exit 1
    fi
fi

# Make sure the binary is executable
chmod +x build/px4_sitl_default/bin/px4

# Create symlink for easier access
cd ../..
if [ ! -L "px4" ]; then
    ln -s sitl_engines/px4/PX4-Autopilot px4
fi

# Create aircraft configuration directory
mkdir -p config/aircraft

# Copy default aircraft parameter files
echo "Setting up default aircraft configurations..."
cp sitl_engines/px4/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/* config/aircraft/ 2>/dev/null || true

# Final verification
echo "Verifying PX4 installation..."
if [ -f "sitl_engines/px4/PX4-Autopilot/build/px4_sitl_default/bin/px4" ]; then
    echo "✅ PX4 toolchain installation complete!"
    echo ""
    echo "PX4 installation location: $(pwd)/sitl_engines/px4/PX4-Autopilot"
    echo "Symlink created at: $(pwd)/px4"
    echo "Binary location: $(pwd)/sitl_engines/px4/PX4-Autopilot/build/px4_sitl_default/bin/px4"
else
    echo "❌ Error: PX4 installation verification failed"
    exit 1
fi

# ==========================================
# INSTALL PYTHON DEPENDENCIES
# ==========================================
echo ""
echo "======================================"
echo "Installing Python Dependencies"
echo "======================================"

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

# ==========================================
# INITIALIZE APPLICATION
# ==========================================
echo ""
echo "======================================"
echo "Initializing Application"
echo "======================================"

# Initialize application database
echo "Initializing application database..."
python3 init_db.py

# Set up permissions
echo "Setting up permissions..."
chmod +x start_cloudsitlsim.sh
chmod +x start_px4_sitl.sh

# ==========================================
# START PX4 SITL INSTANCE
# ==========================================
echo ""
echo "======================================"
echo "Starting PX4 SITL Instance"
echo "======================================"

# Navigate to PX4 directory
cd sitl_engines/px4/PX4-Autopilot

# Set environment variables for headless operation
echo "Setting up environment for headless PX4 SITL..."
export HEADLESS=1
export PX4_SIM_HOSTNAME=localhost
export GAZEBO_IP=127.0.0.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11345
export GAZEBO_MODEL_PATH=$PWD/Tools/sitl_gazebo/models
export GAZEBO_RESOURCE_PATH=$PWD/Tools/sitl_gazebo

echo "Starting PX4 SITL instance with Gazebo in headless mode..."
echo "Command: HEADLESS=1 make px4_sitl gazebo"
echo ""
echo "This will start a PX4 SITL instance that will continue running after setup completes."
echo "You can connect to it with QGroundControl using:"
echo "  - Connection Type: UDP"
echo "  - Listening Port: 14550"
echo "  - Target Host: localhost (or your server IP)"
echo ""

# Start PX4 SITL instance (run in background and keep running)
echo "Starting PX4 SITL instance..."
make px4_sitl gazebo > /tmp/px4_sitl.log 2>&1 &
PX4_SITL_PID=$!

# Wait for PX4 to start up
echo "Waiting for PX4 SITL to initialize..."
sleep 10

# Check if PX4 process is running
if ps -p $PX4_SITL_PID > /dev/null; then
    echo "✅ PX4 SITL instance started successfully (PID: $PX4_SITL_PID)"
    echo "✅ PX4 SITL is running and ready for connections"
    echo ""
    echo "Connection Information:"
    echo "  - PX4 Process ID: $PX4_SITL_PID"
    echo "  - MAVLink Port: 14550 (UDP)"
    echo "  - Target Host: localhost"
    echo "  - Log File: /tmp/px4_sitl.log"
    echo ""
    echo "To connect with QGroundControl:"
    echo "  1. Open QGroundControl"
    echo "  2. Go to Application Settings > Comm Links"
    echo "  3. Add new connection: UDP"
    echo "  4. Listening Port: 14550"
    echo "  5. Target Host: localhost (or your server's IP address)"
    echo ""
else
    echo "❌ PX4 SITL instance failed to start"
    echo "Check log: /tmp/px4_sitl.log"
    if [ -f "/tmp/px4_sitl.log" ]; then
        echo "Last 20 lines of PX4 SITL log:"
        tail -20 /tmp/px4_sitl.log
    fi
    exit 1
fi

# Save PX4 process ID for later reference
echo $PX4_SITL_PID > /tmp/px4_sitl.pid
echo "PX4 SITL process ID saved to /tmp/px4_sitl.pid"

# Return to project root
cd ../../..

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "✅ System dependencies installed"
echo "✅ MAVLink router installed"
echo "✅ PX4 toolchain installed and built"
echo "✅ Python dependencies installed"
echo "✅ Application initialized"
echo "✅ PX4 SITL instance started and running"
echo ""
echo "Next steps:"
echo "1. Configure your settings in config/config.yaml"
echo "2. Run: ./start_cloudsitlsim.sh"
echo "3. Open your browser to http://localhost:5000"
echo ""
echo "For more information, see README.md"
