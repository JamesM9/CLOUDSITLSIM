#!/bin/bash
set -e

echo "Installing MAVLink Router from source..."
echo "======================================="

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git build-essential meson ninja-build pkg-config libsystemd-dev

# Clone and build mavlink-router
echo "Cloning MAVLink router repository..."
cd /tmp
git clone https://github.com/mavlink/mavlink-router.git
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
