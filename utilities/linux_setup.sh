#!/usr/bin/env bash

# Automation -> BeamNG Symlink Setup Script
# This script creates a symlink to allow Automation exports to work with BeamNG on Linux

set -e

# Game Steam IDs
AUTOMATION_ID="293760"
BEAMNG_ID="284160"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main script
echo "========================================="
echo "Automation -> BeamNG Symlink Setup"
echo "========================================="
echo

# Prompt for Steam library directory
DEFAULT_STEAM="$HOME/.steam/steam"
read -p "What Steam directory to use? [$DEFAULT_STEAM]: " STEAM_DIR
STEAM_DIR="${STEAM_DIR:-$DEFAULT_STEAM}"

# Expand tilde if present
STEAM_DIR="${STEAM_DIR/#\~/$HOME}"

# Check if directory exists
if [ ! -d "$STEAM_DIR" ]; then
    print_error "Steam directory not found: $STEAM_DIR"
    exit 1
fi

print_info "Using Steam directory: $STEAM_DIR"
echo

# Find Automation installation
AUTOMATION_COMPATDATA="$STEAM_DIR/steamapps/compatdata/$AUTOMATION_ID"
if [ ! -d "$AUTOMATION_COMPATDATA" ]; then
    print_error "Automation installation not found at: $AUTOMATION_COMPATDATA"
    print_error "Make sure Automation (Steam ID: $AUTOMATION_ID) is installed."
    exit 1
fi
print_info "Found Automation at: $AUTOMATION_COMPATDATA"

# Find BeamNG installation
BEAMNG_COMPATDATA="$STEAM_DIR/steamapps/compatdata/$BEAMNG_ID"
if [ ! -d "$BEAMNG_COMPATDATA" ]; then
    print_error "BeamNG.drive installation not found at: $BEAMNG_COMPATDATA"
    print_error "Make sure BeamNG.drive (Steam ID: $BEAMNG_ID) is installed."
    exit 1
fi
print_info "Found BeamNG.drive at: $BEAMNG_COMPATDATA"
echo

# Define the paths for the symlink
AUTOMATION_DOCS="$AUTOMATION_COMPATDATA/pfx/drive_c/users/steamuser/Documents/My Games/Automation"
BEAMNG_BASE="$BEAMNG_COMPATDATA/pfx/drive_c/users/steamuser/AppData/Local/BeamNG.drive"

# Find BeamNG version directory (e.g., 0.33, 0.34, etc.)
if [ ! -d "$BEAMNG_BASE" ]; then
    print_error "BeamNG AppData directory not found at: $BEAMNG_BASE"
    print_error "Try running BeamNG at least once to create the necessary directories."
    exit 1
fi

VERSION_DIR=$(find "$BEAMNG_BASE" -maxdepth 1 -type d -name "0.*" | sort -V | tail -n 1)
if [ -z "$VERSION_DIR" ]; then
    print_error "Could not find BeamNG version directory in: $BEAMNG_BASE"
    print_error "Try running BeamNG at least once to create the necessary directories."
    exit 1
fi

print_info "Detected BeamNG version: $(basename "$VERSION_DIR")"

BEAMNG_MODS="$VERSION_DIR/mods"
BEAMNG_VEHICLES="$BEAMNG_MODS/vehicles"

# Create mods directory structure if needed
if [ ! -d "$BEAMNG_MODS" ]; then
    print_info "Creating BeamNG mods directory..."
    mkdir -p "$BEAMNG_MODS"
fi

if [ ! -d "$BEAMNG_VEHICLES" ]; then
    print_info "Creating BeamNG vehicles directory..."
    mkdir -p "$BEAMNG_VEHICLES"
fi

# Check if Automation export directory exists
if [ ! -d "$AUTOMATION_DOCS" ]; then
    print_warn "Automation documents directory not found at: $AUTOMATION_DOCS"
    print_warn "The directory will be created when you first run Automation."
fi

# Define symlink path
SYMLINK_PATH="$BEAMNG_VEHICLES/Automation"

# Check if symlink already exists
if [ -L "$SYMLINK_PATH" ]; then
    print_warn "Symlink already exists at: $SYMLINK_PATH"
    print_info "Current target: $(readlink "$SYMLINK_PATH")"
    read -p "Remove and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$SYMLINK_PATH"
        print_info "Removed existing symlink"
    else
        print_info "Keeping existing symlink. Exiting."
        exit 0
    fi
elif [ -e "$SYMLINK_PATH" ]; then
    print_error "A file or directory already exists at: $SYMLINK_PATH"
    print_error "Please remove it manually and run this script again."
    exit 1
fi

# Create the symlink
print_info "Creating symlink..."
print_info "  From: $SYMLINK_PATH"
print_info "  To:   $AUTOMATION_DOCS"
echo

ln -s "$AUTOMATION_DOCS" "$SYMLINK_PATH"

if [ $? -eq 0 ]; then
    print_info "✓ Symlink created successfully!"
    echo
    print_info "Setup complete! You can now export cars from Automation to BeamNG."
    print_info "The exported cars will appear in BeamNG's vehicle selection menu."
else
    print_error "Failed to create symlink!"
    exit 1
fi
