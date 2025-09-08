#!/bin/bash

# Claude Wake-up Script
# Runs automatically at 4:55 AM on weekdays to maintain Claude usage windows

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/claude-wake-up.log"
# Simplified logging - everything goes to one file
# WAKE_LOG="$SCRIPT_DIR/logs/wake-pings.log"  # Removed per user request

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to log wake pings (now goes to main log)
log_ping() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PING: $1" | tee -a "$LOG_FILE"
}

log_message "=== Claude Wake-up Script Started ==="
log_message "Working directory: $SCRIPT_DIR"

# Check if it's a weekday (1=Monday, 5=Friday)
weekday=$(date +%u)
if [ "$weekday" -gt 5 ]; then
    log_message "Weekend detected (day $weekday), skipping Claude wake-up"
    log_ping "SKIPPED: Weekend (day $weekday)"
    exit 0
fi

log_message "Weekday detected (day $weekday), proceeding with wake-up"

# Check if claude command is available
if ! command -v claude &> /dev/null; then
    log_message "ERROR: claude command not found"
    log_ping "ERROR: claude command not found"
    exit 1
fi

log_message "Sending wake-up ping to Claude..."
log_message "Network check: $(ping -c 1 -W 3000 8.8.8.8 >/dev/null 2>&1 && echo "OK" || echo "FAILED")"
log_message "Start time: $(date '+%Y-%m-%d %H:%M:%S')"

# Send a simple wake-up message to Claude with 2 minute timeout
wake_response=$(echo "Good morning Claude! This is an automated wake-up ping to keep your usage window active. Please respond with just 'awake' to confirm." | perl -e 'alarm 120; exec @ARGV' claude --dangerously-skip-permissions 2>&1)
result=$?

log_message "End time: $(date '+%Y-%m-%d %H:%M:%S')"
log_message "Exit code: $result"

if [ $result -eq 0 ]; then
    log_message "✅ Claude wake-up successful"
    log_message "Claude response: $wake_response"
    log_ping "SUCCESS: Claude responded - $wake_response"
elif [ $result -eq 124 ]; then
    log_message "⏰ Claude wake-up timed out (>2 minutes)"
    log_message "Timeout error: $wake_response"
    log_ping "TIMEOUT: Command exceeded 2 minute limit"
else
    log_message "❌ Claude wake-up failed with code $result"
    log_message "Error output: $wake_response"
    log_ping "FAILED: Exit code $result - $wake_response"
fi

# Update last activity timestamp
date +%s > "$HOME/.claude-last-activity" 2>/dev/null || true

log_message "=== Claude Wake-up Script Completed ==="
log_message "Next wake-up scheduled for tomorrow at 4:55 AM"

# Script completed - Mac can go back to sleep if needed
exit $result