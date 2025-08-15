#!/bin/bash

# Session Tracking Daemon
# Automatically monitors and logs all session activity

# Configuration
SESSION_DIR="${HOME}/.session-tracker"
CURRENT_SESSION_DIR="${SESSION_DIR}/current"
ARCHIVE_DIR="${SESSION_DIR}/archive"
LOG_FILE="${SESSION_DIR}/daemon.log"
PID_FILE="${SESSION_DIR}/daemon.pid"
TRACKING_INTERVAL=60  # seconds

# Create directories
mkdir -p "${SESSION_DIR}"
mkdir -p "${CURRENT_SESSION_DIR}"
mkdir -p "${ARCHIVE_DIR}"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${LOG_FILE}"
}

# Start new session
start_session() {
    local session_id="$(date +%Y%m%d-%H%M%S)-$$"
    local session_file="${CURRENT_SESSION_DIR}/session-${session_id}.json"
    
    cat > "${session_file}" << EOF
{
    "session_id": "${session_id}",
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "user": "$(whoami)",
    "hostname": "$(hostname)",
    "pwd": "$(pwd)",
    "shell": "${SHELL}",
    "terminal": "${TERM}",
    "git_branch": "$(git branch --show-current 2>/dev/null || echo 'none')",
    "commands": [],
    "files_changed": [],
    "git_commits": []
}
EOF
    
    echo "${session_file}"
}

# Track command history
track_commands() {
    local session_file="$1"
    local temp_file="${session_file}.tmp"
    
    # Get recent commands from history
    local recent_commands=$(fc -ln -10 2>/dev/null | sed 's/^[ \t]*//' | jq -Rs . 2>/dev/null || echo "[]")
    
    # Update session file with new commands
    if [ -f "${session_file}" ]; then
        jq ".commands += [${recent_commands}] | .last_update = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" \
            "${session_file}" > "${temp_file}" && mv "${temp_file}" "${session_file}"
    fi
}

# Track file changes
track_file_changes() {
    local session_file="$1"
    local temp_file="${session_file}.tmp"
    
    # Get git status if in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local changes=$(git status --porcelain 2>/dev/null | jq -Rs . 2>/dev/null || echo "\"\"")
        
        if [ -f "${session_file}" ]; then
            jq ".files_changed = ${changes} | .git_status_time = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" \
                "${session_file}" > "${temp_file}" && mv "${temp_file}" "${session_file}"
        fi
    fi
}

# Track git commits
track_git_commits() {
    local session_file="$1"
    local temp_file="${session_file}.tmp"
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local recent_commits=$(git log --oneline -5 --format="%H %s" 2>/dev/null | jq -Rs . 2>/dev/null || echo "\"\"")
        
        if [ -f "${session_file}" ]; then
            jq ".git_commits = ${recent_commits}" "${session_file}" > "${temp_file}" && \
                mv "${temp_file}" "${session_file}"
        fi
    fi
}

# Archive completed session
archive_session() {
    local session_file="$1"
    local session_id=$(basename "${session_file}" .json | sed 's/session-//')
    local archive_date=$(date +%Y-%m-%d)
    local archive_dir="${ARCHIVE_DIR}/${archive_date}"
    
    mkdir -p "${archive_dir}"
    
    # Add end time to session
    local temp_file="${session_file}.tmp"
    jq ".end_time = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "${session_file}" > "${temp_file}" && \
        mv "${temp_file}" "${session_file}"
    
    # Move to archive
    mv "${session_file}" "${archive_dir}/"
    
    log_message "Session ${session_id} archived to ${archive_dir}"
}

# Generate session report
generate_report() {
    local session_file="$1"
    local report_file="${session_file%.json}-report.md"
    
    if [ -f "${session_file}" ]; then
        local session_data=$(cat "${session_file}")
        
        cat > "${report_file}" << EOF
# Session Report

**Session ID**: $(echo "$session_data" | jq -r .session_id)
**Start Time**: $(echo "$session_data" | jq -r .start_time)
**Last Update**: $(echo "$session_data" | jq -r .last_update)
**User**: $(echo "$session_data" | jq -r .user)
**Directory**: $(echo "$session_data" | jq -r .pwd)
**Git Branch**: $(echo "$session_data" | jq -r .git_branch)

## Activity Summary

### Commands Executed
$(echo "$session_data" | jq -r '.commands | length') commands tracked

### Files Changed
\`\`\`
$(echo "$session_data" | jq -r .files_changed)
\`\`\`

### Recent Commits
\`\`\`
$(echo "$session_data" | jq -r .git_commits)
\`\`\`

---
*Generated: $(date)*
EOF
    fi
}

# Main daemon loop
run_daemon() {
    log_message "Session daemon started (PID: $$)"
    echo $$ > "${PID_FILE}"
    
    # Start initial session
    local current_session=$(start_session)
    log_message "Started session: ${current_session}"
    
    # Set up signal handlers
    trap 'cleanup' EXIT INT TERM
    
    while true; do
        # Track activity
        track_commands "${current_session}"
        track_file_changes "${current_session}"
        track_git_commits "${current_session}"
        
        # Generate periodic report
        generate_report "${current_session}"
        
        # Check for session timeout (2 hours)
        local session_start=$(stat -f %B "${current_session}" 2>/dev/null || stat -c %Y "${current_session}" 2>/dev/null)
        local current_time=$(date +%s)
        local session_duration=$((current_time - session_start))
        
        if [ ${session_duration} -gt 7200 ]; then
            log_message "Session timeout - archiving and starting new session"
            archive_session "${current_session}"
            current_session=$(start_session)
            log_message "Started new session: ${current_session}"
        fi
        
        sleep ${TRACKING_INTERVAL}
    done
}

# Cleanup function
cleanup() {
    log_message "Session daemon stopping..."
    rm -f "${PID_FILE}"
    
    # Archive any current sessions
    for session in "${CURRENT_SESSION_DIR}"/session-*.json; do
        if [ -f "${session}" ]; then
            archive_session "${session}"
        fi
    done
    
    log_message "Session daemon stopped"
    exit 0
}

# Check if daemon is already running
if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat "${PID_FILE}")
    if ps -p ${OLD_PID} > /dev/null 2>&1; then
        echo "Session daemon already running (PID: ${OLD_PID})"
        exit 1
    else
        echo "Removing stale PID file"
        rm -f "${PID_FILE}"
    fi
fi

# Command line interface
case "${1:-start}" in
    start)
        echo "Starting session daemon..."
        nohup "$0" daemon > /dev/null 2>&1 &
        echo "Session daemon started (PID: $!)"
        ;;
    stop)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            echo "Stopping session daemon (PID: ${PID})..."
            kill ${PID} 2>/dev/null
            rm -f "${PID_FILE}"
            echo "Session daemon stopped"
        else
            echo "Session daemon not running"
        fi
        ;;
    status)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            if ps -p ${PID} > /dev/null 2>&1; then
                echo "Session daemon running (PID: ${PID})"
                echo "Current sessions:"
                ls -la "${CURRENT_SESSION_DIR}"/session-*.json 2>/dev/null || echo "No active sessions"
            else
                echo "Session daemon not running (stale PID file)"
            fi
        else
            echo "Session daemon not running"
        fi
        ;;
    daemon)
        run_daemon
        ;;
    report)
        echo "Recent session reports:"
        find "${ARCHIVE_DIR}" -name "*-report.md" -mtime -7 -exec basename {} \; 2>/dev/null
        ;;
    *)
        echo "Usage: $0 {start|stop|status|report}"
        exit 1
        ;;
esac
