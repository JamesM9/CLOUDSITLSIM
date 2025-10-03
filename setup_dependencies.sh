#!/bin/bash
set -e

echo "Installing system dependencies for CloudSITLSIM..."

# Update package list
sudo apt-get update

# Install essential build tools and system packages
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Python 3 and pip
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-jinja2 \
    python3-pygments \
    python3-tk \
    python3-lxml \
    python3-yaml \
    python3-six \
    python3-wheel \
    python3-psutil \
    python3-serial \
    python3-future \
    python3-requests \
    python3-setuptools

# Install PX4-specific system dependencies
sudo apt-get install -y \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-good1.0-dev \
    gstreamer1.0-libav

# Install MAVLink router
sudo apt-get install -y mavlink-router

# Install additional tools for PX4
sudo apt-get install -y \
    ninja-build \
    exiftool \
    python3-argparse \
    python3-empy \
    python3-toml \
    python3-numpy \
    python3-packaging \
    python3-pil \
    python3-pkgconfig \
    python3-pycryptodome \
    python3-pygame \
    python3-pyparsing \
    python3-pyserial \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-mock \
    python3-pytest-xdist \
    python3-pyyaml \
    python3-requests \
    python3-setuptools \
    python3-toml \
    python3-urllib3 \
    python3-wxgtk4.0 \
    python3-wxgtk-webview4.0 \
    python3-wxgtk-media4.0 \
    python3-wxgtk-common4.0

# Install Gazebo dependencies
sudo apt-get install -y \
    libignition-gazebo6-dev \
    libignition-gazebo6-plugins \
    libignition-common4-dev \
    libignition-fuel-tools7-dev \
    libignition-transport11-dev \
    libignition-msgs8-dev \
    libignition-gui6-dev \
    libignition-rendering6-dev \
    libignition-plugin1-dev \
    libignition-physics5-dev \
    libignition-math6-dev \
    libignition-cmake2-dev \
    libignition-tools1-dev \
    libsdformat12-dev \
    libgazebo-dev \
    gazebo \
    gazebo-plugin-base \
    libgazebo11-dev

# Install additional development tools
sudo apt-get install -y \
    vim \
    nano \
    htop \
    tree \
    jq \
    tmux \
    screen

echo "System dependencies installation complete!"
