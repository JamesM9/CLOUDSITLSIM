#!/bin/bash

# Simple script to start a single PX4 SITL instance
# This is for testing purposes and direct PX4 access

AIRCRAFT_TYPE=${1:-"x500"}
PORT=${2:-"14550"}

echo "Starting PX4 SITL with $AIRCRAFT_TYPE on port $PORT"
echo "================================================"

# Check if PX4 is installed
if [ ! -d "sitl_engines/px4/PX4-Autopilot" ]; then
    echo "Error: PX4 not found. Please run ./setup.sh first"
    exit 1
fi

cd sitl_engines/px4/PX4-Autopilot

# Set environment variables for headless operation
export HEADLESS=1
export PX4_SIM_HOSTNAME=localhost

# Additional Gazebo headless settings
export GAZEBO_IP=127.0.0.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11345

# Set Gazebo paths
export GAZEBO_MODEL_PATH=$PWD/Tools/sitl_gazebo/models
export GAZEBO_RESOURCE_PATH=$PWD/Tools/sitl_gazebo

# Start PX4 SITL with the specified aircraft type in headless mode
echo "Starting PX4 SITL with $AIRCRAFT_TYPE in headless mode..."
make px4_sitl gazebo_${AIRCRAFT_TYPE} &

# Wait a moment for PX4 to start
sleep 3

# Check if MAVLink router is installed
if ! command -v mavlink-routerd &> /dev/null; then
    echo "Error: mavlink-routerd not found. Please run ./setup.sh first"
    exit 1
fi

# Start MAVLink router
echo "Starting MAVLink router on port $PORT..."
sudo mavlink-routerd 0.0.0.0:$PORT -t 5760 -v &

echo ""
echo "PX4 SITL is running!"
echo "Connection details:"
echo "  Host: 0.0.0.0"
echo "  Port: $PORT"
echo "  Protocol: UDP"
echo ""
echo "Press Ctrl+C to stop"

# Wait for user interrupt
wait
