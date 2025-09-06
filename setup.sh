#!/bin/bash

# Claude Wake-up Service Setup Script
# Universal installer for any macOS user

set -e

# Parse command line arguments
WAKE_TIME="04:20"
while [[ $# -gt 0 ]]; do
    case $1 in
        --time)
            WAKE_TIME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--time HH:MM]"
            echo ""
            echo "Options:"
            echo "  --time HH:MM    Set custom wake-up time (default: 04:20)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Use default time (04:20)"
            echo "  $0 --time 06:15      # Set wake-up time to 6:15 AM"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate time format
if [[ ! "$WAKE_TIME" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
    echo "Error: Invalid time format. Use HH:MM (e.g., 04:55, 06:15)"
    exit 1
fi

# Extract hour and minute
WAKE_HOUR=${WAKE_TIME%:*}
WAKE_MINUTE=${WAKE_TIME#*:}

# Convert to integers (remove leading zeros)
WAKE_HOUR=$((10#$WAKE_HOUR))
WAKE_MINUTE=$((10#$WAKE_MINUTE))

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
    echo -e "${BLUE}Wake-up time: $WAKE_TIME${NC}"
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

# Check if Claude CLI is installed and get its path
if ! command -v claude &> /dev/null; then
    print_error "Claude CLI not found. Please install it first:"
    echo "  https://docs.anthropic.com/en/docs/claude-code/quickstart"
    exit 1
fi

CLAUDE_PATH=$(which claude)
CLAUDE_DIR=$(dirname "$CLAUDE_PATH")
print_status "✓ Claude CLI found at: $CLAUDE_PATH"
print_status "✓ Claude directory: $CLAUDE_DIR"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is only for macOS"
    exit 1
fi
print_status "✓ Running on macOS"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"
print_status "✓ Created logs directory"

# Build dynamic PATH including Claude directory
DYNAMIC_PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if [[ ":$DYNAMIC_PATH:" != *":$CLAUDE_DIR:"* ]]; then
    DYNAMIC_PATH="$CLAUDE_DIR:$DYNAMIC_PATH"
fi

# Generate plist file from template
print_status "Generating LaunchAgent configuration..."
sed \
    -e "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR/claude-wake-up.sh|g" \
    -e "s|WORKING_DIR_PLACEHOLDER|$SCRIPT_DIR|g" \
    -e "s|LOG_DIR_PLACEHOLDER|$SCRIPT_DIR/logs|g" \
    -e "s|DYNAMIC_PATH_PLACEHOLDER|$DYNAMIC_PATH|g" \
    -e "s|<integer>4</integer>|<integer>$WAKE_HOUR</integer>|g" \
    -e "s|<integer>55</integer>|<integer>$WAKE_MINUTE</integer>|g" \
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

# Set up system wake-up (5 minutes before script execution)
print_status "Setting up automatic MacBook wake-up..."
SYSTEM_WAKE_MINUTE=$((WAKE_MINUTE - 5))
SYSTEM_WAKE_HOUR=$WAKE_HOUR
if [[ $SYSTEM_WAKE_MINUTE -lt 0 ]]; then
    SYSTEM_WAKE_MINUTE=$((SYSTEM_WAKE_MINUTE + 60))
    SYSTEM_WAKE_HOUR=$((SYSTEM_WAKE_HOUR - 1))
fi
if [[ $SYSTEM_WAKE_HOUR -lt 0 ]]; then
    SYSTEM_WAKE_HOUR=$((SYSTEM_WAKE_HOUR + 24))
fi

SYSTEM_WAKE_TIME=$(printf "%02d:%02d:00" $SYSTEM_WAKE_HOUR $SYSTEM_WAKE_MINUTE)
if sudo pmset repeat wakeorpoweron MTWRF $SYSTEM_WAKE_TIME; then
    print_status "✓ System wake-up scheduled for weekdays at $(printf "%02d:%02d" $SYSTEM_WAKE_HOUR $SYSTEM_WAKE_MINUTE)"
else
    print_warning "Failed to set system wake-up. You may need to run this manually:"
    echo "  sudo pmset repeat wakeorpoweron MTWRF $SYSTEM_WAKE_TIME"
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
echo "• Wake your Mac at $(printf "%02d:%02d" $SYSTEM_WAKE_HOUR $SYSTEM_WAKE_MINUTE) on weekdays"
echo "• Send a wake-up ping to Claude at $WAKE_TIME"
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