#!/bin/bash
set -e

echo "Installing PX4 toolchain..."

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

# Install PX4 dependencies using their setup script
echo "Running PX4 setup script..."
bash ./Tools/setup/ubuntu.sh

# Build PX4
echo "Building PX4..."
make px4_sitl

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

echo "PX4 toolchain installation complete!"
echo ""
echo "PX4 installation location: $(pwd)/sitl_engines/px4/PX4-Autopilot"
echo "Symlink created at: $(pwd)/px4"
