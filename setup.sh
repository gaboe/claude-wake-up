#!/bin/bash

# Claude Wake-up Service Setup Script
# Universal installer for any macOS user

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Claude Wake-up Service Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="com.user.claude-wake-up"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

print_header

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Claude CLI is installed
if ! command -v claude &> /dev/null; then
    print_error "Claude CLI not found. Please install it first:"
    echo "  https://docs.anthropic.com/en/docs/claude-code/quickstart"
    exit 1
fi
print_status "✓ Claude CLI found"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is only for macOS"
    exit 1
fi
print_status "✓ Running on macOS"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"
print_status "✓ Created logs directory"

# Generate plist file from template
print_status "Generating LaunchAgent configuration..."
sed \
    -e "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR/claude-wake-up.sh|g" \
    -e "s|WORKING_DIR_PLACEHOLDER|$SCRIPT_DIR|g" \
    -e "s|LOG_DIR_PLACEHOLDER|$SCRIPT_DIR/logs|g" \
    "$SCRIPT_DIR/com.user.claude-wake-up.plist.template" > "$SCRIPT_DIR/com.user.claude-wake-up.plist"

print_status "✓ Generated $SCRIPT_DIR/com.user.claude-wake-up.plist"

# Make scripts executable
chmod +x "$SCRIPT_DIR/claude-wake-up.sh"
chmod +x "$SCRIPT_DIR/manage-claude-wake-up.sh"
print_status "✓ Made scripts executable"

# Copy plist to LaunchAgents
cp "$SCRIPT_DIR/com.user.claude-wake-up.plist" "$PLIST_FILE"
print_status "✓ Installed LaunchAgent configuration"

# Load the service
launchctl load "$PLIST_FILE"
print_status "✓ Loaded Claude wake-up service"

# Set up system wake-up
print_status "Setting up automatic MacBook wake-up..."
if sudo pmset repeat wakeorpoweron MTWRF 04:50:00; then
    print_status "✓ System wake-up scheduled for weekdays at 4:50 AM"
else
    print_warning "Failed to set system wake-up. You may need to run this manually:"
    echo "  sudo pmset repeat wakeorpoweron MTWRF 04:50:00"
fi

# Verify installation
echo ""
print_status "Verifying installation..."

if launchctl list | grep -q "$SERVICE_NAME"; then
    print_status "✓ Service is loaded and active"
else
    print_error "✗ Service failed to load"
    exit 1
fi

# Test the service
print_status "Testing the service..."
if "$SCRIPT_DIR/claude-wake-up.sh"; then
    print_status "✓ Service test completed successfully"
else
    print_warning "Service test had issues - check logs"
fi

# Show final status
echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Your Claude wake-up service is now active and will:"
echo "• Wake your Mac at 4:50 AM on weekdays"
echo "• Send a wake-up ping to Claude at 4:55 AM"
echo "• Keep your Claude usage windows active"
echo ""
echo "Management commands:"
echo "  $SCRIPT_DIR/manage-claude-wake-up.sh status    # Check service status"
echo "  $SCRIPT_DIR/manage-claude-wake-up.sh logs      # View logs"
echo "  $SCRIPT_DIR/manage-claude-wake-up.sh test      # Test manually"
echo ""
echo "To uninstall:"
echo "  $SCRIPT_DIR/manage-claude-wake-up.sh unload    # Stop service"
echo "  sudo pmset repeat cancel                       # Cancel wake-up"
echo ""
print_status "Setup completed successfully!"