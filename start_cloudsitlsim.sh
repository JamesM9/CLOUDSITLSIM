#!/bin/bash

echo "Starting CloudSITLSIM..."
echo "======================="

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Check if PX4 is installed
if [ ! -d "sitl_engines/px4/PX4-Autopilot" ]; then
    echo "Error: PX4 not found. Please run ./setup.sh first"
    exit 1
fi

# Check if configuration exists
if [ ! -f "config/config.yaml" ]; then
    echo "Error: Configuration file not found. Please run ./setup.sh first"
    exit 1
fi

# Create necessary directories
mkdir -p logs
mkdir -p instance

# Start the application
echo "Starting CloudSITLSIM web interface..."
python3 app.py
