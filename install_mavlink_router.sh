#!/bin/bash
set -e

echo "Installing MAVLink Router from source..."
echo "======================================="

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git build-essential meson ninja-build pkg-config libsystemd-dev

# Clone and build mavlink-router
echo "Cloning MAVLink router repository with submodules..."
cd /tmp
rm -rf mavlink-router  # Clean up any incomplete repo

# Clone with submodules (this is the key fix!)
git clone --recursive https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router

echo "Building MAVLink router..."
meson setup build .
ninja -C build

echo "Installing MAVLink router..."
sudo ninja -C build install

# Verify installation
echo "Verifying installation..."
mavlink-routerd -h > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ MAVLink router installed successfully"
    echo "Location: $(which mavlink-routerd)"
else
    echo "❌ MAVLink router installation failed"
    exit 1
fi

# Clean up
cd ~
rm -rf /tmp/mavlink-router

echo "MAVLink router installation complete!"
