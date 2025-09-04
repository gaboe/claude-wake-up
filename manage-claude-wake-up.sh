#!/bin/bash

# Claude Wake-up Service Manager

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.claude-wake-up.plist"
LOG_FILE="$SCRIPT_DIR/logs/claude-wake-up.log"
# Note: wake-pings.log removed - everything goes to main log now
SERVICE_NAME="com.user.claude-wake-up"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

case "$1" in
    status)
        echo "=== Claude Wake-up Service Status ==="
        echo ""
        
        # Check if service is loaded
        if launchctl list | grep -q "$SERVICE_NAME"; then
            print_status "Service is loaded and active"
        else
            print_error "Service is not loaded"
        fi
        
        # Check pmset schedule
        echo ""
        echo "System wake-up schedule:"
        pmset -g sched | grep -A 5 "Repeating power events"
        
        # Show recent activity
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo "Recent activity:"
            tail -5 "$LOG_FILE"
        else
            print_warning "No activity log found yet"
        fi
        ;;
        
    logs)
        if [ -f "$LOG_FILE" ]; then
            if [ "$2" = "-f" ]; then
                tail -f "$LOG_FILE"
            elif [ "$2" = "wake" ]; then
                # Show only ping-related entries
                grep "PING:" "$LOG_FILE" || echo "No ping entries found"
            else
                tail -20 "$LOG_FILE"
            fi
        else
            print_error "Log file not found at $LOG_FILE"
        fi
        ;;
        
    test)
        print_status "Testing Claude wake-up script..."
        $SCRIPT_DIR/claude-wake-up.sh
        ;;
        
    unload)
        print_status "Unloading Claude wake-up service..."
        launchctl unload "$PLIST_FILE"
        print_status "Service unloaded"
        ;;
        
    load)
        print_status "Loading Claude wake-up service..."
        launchctl load "$PLIST_FILE"
        print_status "Service loaded"
        ;;
        
    disable-wake)
        print_warning "Disabling system wake-up schedule..."
        sudo pmset repeat cancel
        print_status "System wake-up cancelled"
        ;;
        
    enable-wake)
        print_status "Enabling system wake-up for weekdays at 4:50 AM..."
        sudo pmset repeat wakeorpoweron MTWRF 04:50:00
        print_status "System wake-up scheduled"
        ;;
        
    schedule)
        if [ -z "$2" ]; then
            print_error "Usage: $0 schedule HH:MM"
            echo "Example: $0 schedule 06:15"
            exit 1
        fi
        
        NEW_TIME="$2"
        
        # Validate time format
        if [[ ! "$NEW_TIME" =~ ^[0-2][0-9]:[0-5][0-9]$ ]]; then
            print_error "Invalid time format. Use HH:MM (e.g., 04:55, 06:15)"
            exit 1
        fi
        
        # Extract hour and minute
        WAKE_HOUR=${NEW_TIME%:*}
        WAKE_MINUTE=${NEW_TIME#*:}
        
        # Convert to integers (remove leading zeros)
        WAKE_HOUR=$((10#$WAKE_HOUR))
        WAKE_MINUTE=$((10#$WAKE_MINUTE))
        
        print_status "Updating wake-up time to $NEW_TIME..."
        
        # Check if Claude CLI is available
        if ! command -v claude &> /dev/null; then
            print_error "Claude CLI not found. Please install it first."
            exit 1
        fi
        
        CLAUDE_PATH=$(which claude)
        CLAUDE_DIR=$(dirname "$CLAUDE_PATH")
        
        # Build dynamic PATH
        DYNAMIC_PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if [[ ":$DYNAMIC_PATH:" != *":$CLAUDE_DIR:"* ]]; then
            DYNAMIC_PATH="$CLAUDE_DIR:$DYNAMIC_PATH"
        fi
        
        # Generate new plist
        sed \
            -e "s|SCRIPT_PATH_PLACEHOLDER|$SCRIPT_DIR/claude-wake-up.sh|g" \
            -e "s|WORKING_DIR_PLACEHOLDER|$SCRIPT_DIR|g" \
            -e "s|LOG_DIR_PLACEHOLDER|$SCRIPT_DIR/logs|g" \
            -e "s|DYNAMIC_PATH_PLACEHOLDER|$DYNAMIC_PATH|g" \
            -e "s|<integer>4</integer>|<integer>$WAKE_HOUR</integer>|g" \
            -e "s|<integer>55</integer>|<integer>$WAKE_MINUTE</integer>|g" \
            "$SCRIPT_DIR/com.user.claude-wake-up.plist.template" > "$SCRIPT_DIR/com.user.claude-wake-up.plist"
        
        # Reload service
        print_status "Reloading service..."
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        cp "$SCRIPT_DIR/com.user.claude-wake-up.plist" "$PLIST_FILE"
        launchctl load "$PLIST_FILE"
        
        print_status "✓ Wake-up time updated to $NEW_TIME"
        print_status "Service will now run at $NEW_TIME on weekdays"
        ;;
        
    *)
        echo "Claude Wake-up Service Manager"
        echo ""
        echo "Usage: $0 {status|logs|test|load|unload|enable-wake|disable-wake|schedule}"
        echo ""
        echo "Commands:"
        echo "  status       - Show service status and recent activity"
        echo "  logs         - Show recent logs (use 'logs -f' to follow)"
        echo "  logs wake    - Show wake-up ping entries only"
        echo "  test         - Run wake-up script manually"
        echo "  load         - Load the service"
        echo "  unload       - Unload the service"
        echo "  enable-wake  - Enable system wake-up at 4:50 AM"
        echo "  disable-wake - Disable system wake-up"
        echo "  schedule HH:MM - Change wake-up time (e.g., schedule 06:15)"
        echo ""
        echo "Service will automatically wake your Mac and ping Claude"
        echo "every weekday at 4:55 AM to maintain usage windows."
        ;;
esac