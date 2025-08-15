# 🤖 Automated Session Tracking System

Complete programmatic and automatic session documentation system that runs continuously without manual intervention.

## 🚀 Quick Start

```bash
# One-command installation
./session-tracker/setup-all.sh install

# That's it! Everything is now tracking automatically
```

## 📊 What Gets Tracked Automatically

### Real-Time Tracking
- **Every command** you execute
- **Directory changes** as you navigate
- **Git branch** switches
- **File modifications** in git repos
- **Timestamps** for all activities
- **Session metadata** (user, hostname, shell, terminal)

### Automated Reports
- **Hourly snapshots** of session state
- **Daily reports** with activity summaries
- **Weekly analytics** with trends
- **Monthly statistics** in JSON format

## 🎯 Features

### 1. Background Daemon (`session-daemon.sh`)
- Runs continuously in background
- Monitors all session activity
- Auto-archives after 2-hour timeout
- JSON-structured data storage
- Automatic log rotation

### 2. Shell Integration (`shell-integration.sh`)
- Hooks into zsh/bash for command tracking
- No manual commands needed
- Tracks pwd changes automatically
- Monitors git branch switches
- Available aliases:
  - `st-summary` - View session summary
  - `st-export` - Export session data
  - `st-on/st-off` - Toggle tracking
  - `st-tail` - Watch live activity

### 3. Git Hooks
- **Pre-commit**: Captures staged files and context
- **Post-commit**: Logs commit details
- Automatic documentation generation
- No manual intervention required

### 4. Cron Jobs
- **Hourly**: Session snapshots (tar.gz archives)
- **Daily**: Activity reports and analytics
- **Weekly**: Cleanup and compression
- Email notifications (optional)

### 5. Analytics System
- Command frequency analysis
- Directory access patterns
- Git activity tracking
- Time distribution reports
- JSON-formatted metrics

## 📁 Directory Structure

```
~/.session-tracker/
├── current/          # Active session data
├── archive/          # Completed sessions
│   └── snapshots/    # Hourly snapshots
├── reports/          # Daily/weekly reports
├── commands.log      # Command history
├── metadata.json     # Session metadata
└── cron.log         # Cron job logs

~/.config/session-tracker/
└── config.json      # System configuration
```

## 🔧 Installation Details

The installer (`setup-all.sh`) automatically:

1. **Checks dependencies** (git, jq, tar, gzip)
2. **Creates directory structure**
3. **Installs daemon** (with systemd service if available)
4. **Sets up Git hooks** in current repository
5. **Configures shell integration** (zsh/bash)
6. **Installs cron jobs** for automated tasks
7. **Starts all services**

## 💻 Usage

### Installation
```bash
./session-tracker/setup-all.sh install
```

### Check Status
```bash
./session-tracker/setup-all.sh status
```

### Uninstall (preserves data)
```bash
./session-tracker/setup-all.sh uninstall
```

### Manual Controls
```bash
# Daemon management
./session-tracker/session-daemon.sh {start|stop|status}

# Cron management
./session-tracker/setup-cron.sh {install|uninstall|status|test}

# View live activity
tail -f ~/.session-tracker/commands.log
```

## 📈 Analytics & Reports

### Daily Report Example
```markdown
# Daily Session Report - 2025-08-15

**Commands Executed**: 342
**Directories Accessed**: 12
**Git Branches Used**: 3
**Active Hours**: 8

## Top Commands
1. git (89 times)
2. docker (67 times)
3. ls (45 times)
...
```

### JSON Analytics
```json
{
  "month": "2025-08",
  "total_commands": 8432,
  "unique_commands": 234,
  "directories_accessed": 89,
  "git_branches": 12,
  "active_days": 22
}
```

## ⚙️ Configuration

Edit `~/.config/session-tracker/config.json`:

```json
{
  "settings": {
    "session_timeout": 7200,      // 2 hours
    "snapshot_interval": 3600,    // 1 hour
    "archive_days": 30,           // Keep for 30 days
    "report_email": "you@email.com"
  }
}
```

## 🛡️ Privacy & Security

- All data stored locally in your home directory
- No external services or uploads
- Git hooks respect `.gitignore`
- Toggle tracking with `st-off` command
- Data encrypted if filesystem supports it

## 🔄 Data Management

### Export Session
```bash
st-export ~/my-session-backup
```

### Clear Current Session
```bash
st-clear
```

### Archive Old Data
```bash
find ~/.session-tracker/archive -mtime +90 -delete
```

## 🐛 Troubleshooting

### Daemon Not Starting
```bash
# Check if already running
ps aux | grep session-daemon

# Check logs
tail ~/.session-tracker/daemon.log
```

### Commands Not Tracking
```bash
# Verify shell integration
echo $SESSION_TRACKER_ENABLED  # Should be "true"

# Re-source shell config
source ~/.zshrc  # or ~/.bashrc
```

### Cron Jobs Not Running
```bash
# Check crontab
crontab -l | grep session-tracker

# Test manually
./session-tracker/cron-tasks.sh daily
```

## 📊 System Requirements

- **OS**: Linux, macOS
- **Shell**: bash or zsh
- **Dependencies**: git, jq, tar, gzip
- **Optional**: systemd (for service), mail (for notifications)

## 🎉 Benefits

1. **Zero Manual Effort** - Completely automatic
2. **Comprehensive Coverage** - Nothing gets missed
3. **Structured Data** - JSON format for analysis
4. **Historical Archive** - Review past sessions
5. **Privacy Focused** - All data stays local
6. **Lightweight** - Minimal resource usage
7. **Customizable** - Configure to your needs

## 📝 License

MIT License - Use freely for personal or commercial purposes.

## 🤝 Contributing

Improvements welcome! The system is modular and extensible.

---

**Installation:** `./session-tracker/setup-all.sh install`
**Status:** Production Ready
**Version:** 1.0.0
