#!/bin/bash
set -e

echo "======================================"
echo "CloudSITLSIM Clean Installation Script"
echo "======================================"
echo ""
echo "This script will remove PX4 and MAVLink router installations"
echo "to prepare the repository for GitHub commit."
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script should not be run as root"
    echo "Please run as a regular user with sudo privileges"
    exit 1
fi

# Confirmation prompt
read -p "Are you sure you want to remove PX4 and MAVLink router? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup process..."
echo ""

# 1. Remove PX4 installation
echo "1. Removing PX4 installation..."
if [ -d "sitl_engines/px4" ]; then
    echo "   Removing PX4 directory..."
    rm -rf sitl_engines/px4
    echo "   ✅ PX4 directory removed"
else
    echo "   ℹ️  PX4 directory not found"
fi

# 2. Remove ArduPilot directory (if exists)
if [ -d "sitl_engines/ardupilot" ]; then
    echo "   Removing ArduPilot directory..."
    rm -rf sitl_engines/ardupilot
    echo "   ✅ ArduPilot directory removed"
fi

# 3. Remove PX4 symlink
if [ -L "px4" ]; then
    echo "   Removing PX4 symlink..."
    rm px4
    echo "   ✅ PX4 symlink removed"
fi

# 4. Remove MAVLink router installation
echo ""
echo "2. Removing MAVLink router..."
if command -v mavlink-routerd > /dev/null 2>&1; then
    echo "   MAVLink router is installed system-wide"
    echo "   ⚠️  Note: MAVLink router was installed with sudo, not removing automatically"
    echo "   To remove manually, run:"
    echo "   sudo rm -f /usr/local/bin/mavlink-routerd"
    echo "   sudo rm -f /usr/local/share/man/man1/mavlink-routerd.1"
    echo "   sudo rm -rf /usr/local/share/mavlink-router"
else
    echo "   ℹ️  MAVLink router not found in PATH"
fi

# 5. Clean up build artifacts and temporary files
echo ""
echo "3. Cleaning up build artifacts..."
if [ -d "sitl_engines" ]; then
    find sitl_engines -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
    find sitl_engines -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "   ✅ Build artifacts cleaned"
fi

# 6. Remove Python cache files
echo ""
echo "4. Cleaning up Python cache files..."
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -type f -delete 2>/dev/null || true
find . -name "*.pyo" -type f -delete 2>/dev/null || true
echo "   ✅ Python cache files cleaned"

# 7. Remove log files
echo ""
echo "5. Cleaning up log files..."
if [ -d "logs" ]; then
    rm -f logs/*.log 2>/dev/null || true
    echo "   ✅ Log files cleaned"
fi

# 8. Remove instance database (if exists)
echo ""
echo "6. Cleaning up instance data..."
if [ -f "instance/cloudsitlsim.db" ]; then
    rm -f instance/cloudsitlsim.db
    echo "   ✅ Instance database removed"
fi

# 9. Remove any temporary files
echo ""
echo "7. Cleaning up temporary files..."
rm -f /tmp/px4-sock-* 2>/dev/null || true
rm -f .ninja_deps .ninja_log 2>/dev/null || true
find . -name ".ninja_*" -delete 2>/dev/null || true
echo "   ✅ Temporary files cleaned"

# 10. Create .gitignore if it doesn't exist
echo ""
echo "8. Ensuring .gitignore is up to date..."
if [ ! -f ".gitignore" ]; then
    echo "   Creating .gitignore file..."
    cat > .gitignore << 'EOF'
# CloudSITLSIM .gitignore

# PX4 and SITL engines (should be installed locally)
sitl_engines/
px4

# Python cache
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environment
venv/
env/
ENV/

# Instance data and logs
instance/*.db
logs/*.log
*.log

# Temporary files
*.tmp
*.temp
.ninja_deps
.ninja_log
.ninja_*
/tmp/px4-sock-*

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Environment files
.env
.env.local

# Backup files
*.bak
*.backup
EOF
    echo "   ✅ .gitignore created"
else
    echo "   ℹ️  .gitignore already exists"
fi

echo ""
echo "======================================"
echo "Clean Installation Complete!"
echo "======================================"
echo ""
echo "Summary of what was removed:"
echo "✅ PX4 installation directory"
echo "✅ ArduPilot directory (if existed)"
echo "✅ PX4 symlink"
echo "✅ Build artifacts and cache files"
echo "✅ Python cache files"
echo "✅ Log files"
echo "✅ Instance database"
echo "✅ Temporary files"
echo ""
echo "Repository is now ready for GitHub commit!"
echo ""
echo "Note: MAVLink router was installed system-wide with sudo."
echo "If you want to remove it completely, run the commands shown above."
echo ""
echo "To reinstall PX4 and MAVLink router, run:"
echo "  ./setup.sh"
echo ""
