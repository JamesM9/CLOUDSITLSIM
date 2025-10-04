#!/bin/bash
set -e

echo "Setting up MAVLink router systemd service..."
echo "============================================="

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

echo "✅ MAVLink router systemd service installed"
echo ""
echo "Service commands:"
echo "  Start:   sudo systemctl start mavlink-router"
echo "  Stop:    sudo systemctl stop mavlink-router"
echo "  Status:  sudo systemctl status mavlink-router"
echo "  Logs:    sudo journalctl -u mavlink-router -f"
echo ""
echo "The service will start automatically on boot."
echo "To disable auto-start: sudo systemctl disable mavlink-router"
