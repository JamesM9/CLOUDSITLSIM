#!/bin/bash
set -e

echo "Complete MAVLink Router Installation"
echo "===================================="

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git build-essential meson ninja-build pkg-config libsystemd-dev

# Clean up any existing installation
echo "Cleaning up any existing MAVLink router..."
cd /tmp
rm -rf mavlink-router

# Clone with submodules (this is the key fix!)
echo "Cloning MAVLink router repository with submodules..."
git clone --recursive https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router

# Build and install
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

# Ask if user wants systemd service
echo ""
read -p "Do you want to install a systemd service for automatic startup? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing systemd service..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/mavlink-router.service > /dev/null <<EOF
[Unit]
Description=MAVLink Router Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/mavlink-routerd 0.0.0.0:14550 -t 5760 -v
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable mavlink-router.service
    
    echo "✅ MAVLink router systemd service installed and enabled"
    echo ""
    echo "Service commands:"
    echo "  Start:   sudo systemctl start mavlink-router"
    echo "  Stop:    sudo systemctl stop mavlink-router"
    echo "  Status:  sudo systemctl status mavlink-router"
    echo "  Logs:    sudo journalctl -u mavlink-router -f"
    echo "  Disable: sudo systemctl disable mavlink-router"
else
    echo "Skipping systemd service installation"
fi

echo ""
echo "🎉 MAVLink router installation complete!"
echo ""
echo "Test the installation:"
echo "  mavlink-routerd -h"
echo ""
echo "Manual start:"
echo "  sudo mavlink-routerd 0.0.0.0:14550 -t 5760 -v"
