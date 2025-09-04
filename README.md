# Claude Wake-up Service 🌅

Automatic system to wake up Claude CLI every weekday at 4:55 AM to maintain 5-hour Claude usage windows.

## 🎯 Purpose

- **Problem**: Claude has 5-hour usage windows. With an 8-hour workday, you need 2-3 windows.
- **Solution**: Automatic MacBook wake-up and Claude ping at 4:55 AM on weekdays.
- **Result**: Guaranteed 3 windows daily (4:55, ~10:00, ~15:00) for uninterrupted work.

## ⚡ Quick Start

### Prerequisites
- macOS (tested on macOS 14+)
- [Claude CLI](https://docs.anthropic.com/en/docs/claude-code/quickstart) installed

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-wake-up.git
cd claude-wake-up

# Run the setup script (default: 4:55 AM)
./setup.sh

# Or set custom wake-up time
./setup.sh --time 06:15    # Wake up at 6:15 AM
```

That's it! The service is now active and will wake your Mac every weekday at your chosen time.

## 🛠 What Gets Installed

### File Structure
```
claude-wake-up/
├── claude-wake-up.sh              # Main script for Claude ping
├── manage-claude-wake-up.sh       # Service management
├── setup.sh                       # Universal installer
├── com.user.claude-wake-up.plist.template # LaunchAgent template
├── logs/                          # All logs
│   └── claude-wake-up.log         # Activity log
└── README.md                      # This file
```

### System Changes
- **LaunchAgent**: `~/Library/LaunchAgents/com.user.claude-wake-up.plist`
- **System Wake-up**: `pmset repeat wakeorpoweron MTWRF 04:50:00`

## 🎮 Usage

### Service Management
```bash
# Check service status
./manage-claude-wake-up.sh status

# View logs
./manage-claude-wake-up.sh logs
./manage-claude-wake-up.sh logs wake    # ping results only
./manage-claude-wake-up.sh logs -f      # follow logs

# Manual test
./manage-claude-wake-up.sh test

# Enable/disable service
./manage-claude-wake-up.sh unload
./manage-claude-wake-up.sh load

# System wake-up management
./manage-claude-wake-up.sh disable-wake
./manage-claude-wake-up.sh enable-wake

# Change wake-up time
./manage-claude-wake-up.sh schedule 06:15    # Change to 6:15 AM
```

## 📋 How It Works

1. **4:50 AM**: MacBook automatically wakes up (`pmset`)
2. **4:55 AM**: LaunchAgent runs `claude-wake-up.sh`
3. **Script**: 
   - Checks if it's a weekday (skips weekends)
   - Sends ping to Claude: "Good morning Claude! This is an automated wake-up ping..."
   - Claude responds "awake"
   - Everything gets logged
4. **Result**: Claude window is active, MacBook can go back to sleep

## 📊 Monitoring

### Check Logs
```bash
# Recent activity
./manage-claude-wake-up.sh status

# Full log
tail -f logs/claude-wake-up.log

# Only ping results
./manage-claude-wake-up.sh logs wake
```

### Log Format
```
[2025-01-15 04:55:01] === Claude Wake-up Script Started ===
[2025-01-15 04:55:01] Working directory: /path/to/claude-wake-up
[2025-01-15 04:55:01] Weekday detected (day 2), proceeding with wake-up
[2025-01-15 04:55:01] Sending wake-up ping to Claude...
[2025-01-15 04:55:03] ✅ Claude wake-up successful
[2025-01-15 04:55:03] Claude response: awake
[2025-01-15 04:55:03] PING: SUCCESS: Claude responded - awake
```

## ⚡ Benefits

- **Energy efficient**: MacBook sleeps, only wakes for ping
- **Automatic**: No manual intervention needed
- **Weekdays only**: Weekends = power savings  
- **Universal**: Works on any Mac with Claude CLI
- **Auditable**: Complete logs of all activities
- **Simple**: One command installation and management

## 🔧 Troubleshooting

### Service not running:
```bash
./manage-claude-wake-up.sh status
launchctl list | grep claude-wake-up
```

### MacBook not waking up:
```bash
pmset -g sched  # verify scheduled wake-up
```

### Claude ping failing:
```bash
./manage-claude-wake-up.sh test  # manual test
which claude  # verify Claude is installed

# If "claude command not found" error:
./setup.sh  # Re-run setup to fix PATH detection
```

### Complete uninstallation:
```bash
# Remove service
./manage-claude-wake-up.sh unload
rm ~/Library/LaunchAgents/com.user.claude-wake-up.plist

# Cancel automatic wake-up  
sudo pmset repeat cancel

# Remove files
cd .. && rm -rf claude-wake-up/
```

## 🏗 Development

### Testing
```bash
# Test the wake-up script
./claude-wake-up.sh

# Test on different days
date  # check current day
# Edit script temporarily to test weekend logic
```

### Customization
- **Change time**: Use `./setup.sh --time HH:MM` or `./manage-claude-wake-up.sh schedule HH:MM`
- **Change frequency**: Modify the weekday arrays in the plist template
- **Add more checks**: Extend `claude-wake-up.sh` with additional logic

## 📝 Technical Details

- **Platform**: macOS LaunchAgent
- **Schedule**: Weekdays (Mon-Fri) at configurable time (default: 4:55 AM)
- **System Wake**: 5 minutes before Claude ping via `pmset repeat`
- **Prerequisites**: Claude CLI installed (auto-detected PATH)
- **PATH Detection**: Automatically finds Claude CLI installation location
- **Security**: Uses `--dangerously-skip-permissions` only for automated ping
- **Logging**: Single log file with timestamped entries
- **Compatibility**: macOS 10.12+ (tested on macOS 14+)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test on your Mac
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

Inspired by the need for seamless Claude CLI workflow during long development sessions.