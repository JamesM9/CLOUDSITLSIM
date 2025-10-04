#!/bin/bash
set -e

echo "======================================"
echo "Continuing CloudSITLSIM Setup"
echo "======================================"
echo ""

# Check if PX4 is already built
if [ -f "sitl_engines/px4/PX4-Autopilot/build/px4_sitl_default/bin/px4" ]; then
    echo "✅ PX4 is already built, skipping PX4 installation"
else
    echo "Continuing PX4 installation..."
    
    # Navigate to PX4 directory
    cd sitl_engines/px4/PX4-Autopilot
    
    # PX4 dependencies should already be installed by main setup script
    echo "Checking if PX4 dependencies are installed..."
    echo "If you encounter build errors, please run the main setup.sh script first to install dependencies."
    
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
    
    # Return to project root
    cd ../../..
    
    # Create symlink for easier access
    if [ ! -L "px4" ]; then
        ln -s sitl_engines/px4/PX4-Autopilot px4
    fi
    
    # Create aircraft configuration directory
    mkdir -p config/aircraft
    
    # Copy default aircraft parameter files
    echo "Setting up default aircraft configurations..."
    cp sitl_engines/px4/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/* config/aircraft/ 2>/dev/null || true
    
    echo "✅ PX4 toolchain installation complete!"
fi

# Install Python dependencies
echo ""
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
echo ""
echo "Initializing application database..."
python3 init_db.py

# Set up permissions
echo "Setting up permissions..."
chmod +x start_cloudsitlsim.sh
chmod +x start_px4_sitl.sh

# Test PX4 SITL build
echo ""
echo "======================================"
echo "Testing PX4 SITL Build"
echo "======================================"

# Navigate to PX4 directory for testing
cd sitl_engines/px4/PX4-Autopilot

# Set environment variables for headless test
echo "Setting up environment for headless test..."
export HEADLESS=1
export PX4_SIM_HOSTNAME=localhost
export GAZEBO_IP=127.0.0.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11345
export GAZEBO_MODEL_PATH=$PWD/Tools/sitl_gazebo/models
export GAZEBO_RESOURCE_PATH=$PWD/Tools/sitl_gazebo

echo "Testing PX4 SITL build with Gazebo in headless mode..."
echo "Command: HEADLESS=1 make px4_sitl gazebo"
echo ""

# Start PX4 SITL test (run in background)
echo "Starting test PX4 SITL instance..."
timeout 30s make px4_sitl gazebo > /tmp/px4_test.log 2>&1 &
PX4_TEST_PID=$!

# Wait a moment for PX4 to start
sleep 5

# Check if PX4 process is running
if ps -p $PX4_TEST_PID > /dev/null; then
    echo "✅ PX4 SITL test started successfully (PID: $PX4_TEST_PID)"
    
    # Wait a bit more to see if it stays running
    sleep 5
    
    if ps -p $PX4_TEST_PID > /dev/null; then
        echo "✅ PX4 SITL test is running stably"
        
        # Kill the test process
        echo "Stopping test PX4 SITL instance..."
        kill $PX4_TEST_PID 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        if ps -p $PX4_TEST_PID > /dev/null; then
            kill -9 $PX4_TEST_PID 2>/dev/null || true
        fi
        
        echo "✅ PX4 SITL test completed successfully"
    else
        echo "❌ PX4 SITL test failed - process died"
        echo "Check log: /tmp/px4_test.log"
        exit 1
    fi
else
    echo "❌ PX4 SITL test failed to start"
    echo "Check log: /tmp/px4_test.log"
    if [ -f "/tmp/px4_test.log" ]; then
        echo "Last 20 lines of test log:"
        tail -20 /tmp/px4_test.log
    fi
    exit 1
fi

# Clean up any remaining processes
pkill -f "px4" 2>/dev/null || true
pkill -f "gzserver" 2>/dev/null || true
pkill -f "gzclient" 2>/dev/null || true

# Return to project root
cd ../../..

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "✅ PX4 toolchain installed and built"
echo "✅ Python dependencies installed"
echo "✅ Application initialized"
echo "✅ PX4 SITL test build successful"
echo ""
echo "Next steps:"
echo "1. Configure your settings in config/config.yaml"
echo "2. Run: ./start_cloudsitlsim.sh"
echo "3. Open your browser to http://localhost:5000"
echo ""
echo "For more information, see README.md"
