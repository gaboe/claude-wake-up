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
        
    *)
        echo "Claude Wake-up Service Manager"
        echo ""
        echo "Usage: $0 {status|logs|test|load|unload|enable-wake|disable-wake}"
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
        echo ""
        echo "Service will automatically wake your Mac and ping Claude"
        echo "every weekday at 4:55 AM to maintain usage windows."
        ;;
esac