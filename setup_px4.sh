#!/bin/bash
set -e

echo "Installing PX4 toolchain..."
echo "=========================="

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

# Install PX4 dependencies using their setup script
echo "Running PX4 setup script..."
if [ -f "./Tools/setup/ubuntu.sh" ]; then
    bash ./Tools/setup/ubuntu.sh
else
    echo "❌ Error: PX4 setup script not found"
    exit 1
fi

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
