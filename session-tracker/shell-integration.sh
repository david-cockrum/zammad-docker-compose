#!/bin/bash

# Shell Integration for Automatic Session Tracking
# Add this to your ~/.zshrc or ~/.bashrc

# Session tracking configuration
export SESSION_TRACKER_DIR="${HOME}/.session-tracker"
export SESSION_TRACKER_ENABLED="${SESSION_TRACKER_ENABLED:-true}"
export SESSION_LOG_FILE="${SESSION_TRACKER_DIR}/commands.log"
export SESSION_METADATA_FILE="${SESSION_TRACKER_DIR}/metadata.json"

# Initialize session tracking
init_session_tracking() {
    if [ "${SESSION_TRACKER_ENABLED}" != "true" ]; then
        return
    fi
    
    mkdir -p "${SESSION_TRACKER_DIR}"
    
    # Create or update metadata file
    cat > "${SESSION_METADATA_FILE}" << EOF
{
    "session_start": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "shell": "${SHELL}",
    "user": "$(whoami)",
    "hostname": "$(hostname)",
    "terminal": "${TERM}",
    "pid": "$$"
}
EOF
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session tracking initialized (PID: $$)" >> "${SESSION_LOG_FILE}"
}

# Track command execution (for zsh)
if [ -n "$ZSH_VERSION" ]; then
    # Zsh preexec hook - runs before command execution
    preexec() {
        if [ "${SESSION_TRACKER_ENABLED}" != "true" ]; then
            return
        fi
        
        local cmd="$1"
        local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        
        # Log command to file
        echo "[${timestamp}] CMD: ${cmd}" >> "${SESSION_LOG_FILE}"
        
        # Track in JSON format
        local json_file="${SESSION_TRACKER_DIR}/commands-$(date +%Y%m%d).json"
        if [ ! -f "${json_file}" ]; then
            echo "[]" > "${json_file}"
        fi
        
        # Append command to JSON (using jq if available)
        if command -v jq &> /dev/null; then
            local temp_file="${json_file}.tmp"
            jq ". += [{\"timestamp\": \"${timestamp}\", \"command\": \"${cmd}\", \"pwd\": \"${PWD}\", \"user\": \"${USER}\"}]" \
                "${json_file}" > "${temp_file}" && mv "${temp_file}" "${json_file}"
        fi
    }
    
    # Zsh precmd hook - runs before prompt display
    precmd() {
        if [ "${SESSION_TRACKER_ENABLED}" != "true" ]; then
            return
        fi
        
        # Track directory changes
        if [ "${SESSION_LAST_PWD}" != "${PWD}" ]; then
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] PWD: ${PWD}" >> "${SESSION_LOG_FILE}"
            export SESSION_LAST_PWD="${PWD}"
        fi
        
        # Track git branch changes
        if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
            local current_branch=$(git branch --show-current 2>/dev/null)
            if [ "${SESSION_LAST_BRANCH}" != "${current_branch}" ]; then
                echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] BRANCH: ${current_branch}" >> "${SESSION_LOG_FILE}"
                export SESSION_LAST_BRANCH="${current_branch}"
            fi
        fi
    }
fi

# Track command execution (for bash)
if [ -n "$BASH_VERSION" ]; then
    # Set up DEBUG trap for command tracking
    track_command() {
        if [ "${SESSION_TRACKER_ENABLED}" != "true" ]; then
            return
        fi
        
        local cmd="${BASH_COMMAND}"
        local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        
        # Skip if it's the PROMPT_COMMAND itself
        if [[ "$cmd" != "$PROMPT_COMMAND" ]]; then
            echo "[${timestamp}] CMD: ${cmd}" >> "${SESSION_LOG_FILE}"
        fi
    }
    
    trap 'track_command' DEBUG
    
    # PROMPT_COMMAND for additional tracking
    session_prompt_command() {
        if [ "${SESSION_TRACKER_ENABLED}" != "true" ]; then
            return
        fi
        
        # Track directory changes
        if [ "${SESSION_LAST_PWD}" != "${PWD}" ]; then
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] PWD: ${PWD}" >> "${SESSION_LOG_FILE}"
            export SESSION_LAST_PWD="${PWD}"
        fi
        
        # Track git branch changes
        if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
            local current_branch=$(git branch --show-current 2>/dev/null)
            if [ "${SESSION_LAST_BRANCH}" != "${current_branch}" ]; then
                echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] BRANCH: ${current_branch}" >> "${SESSION_LOG_FILE}"
                export SESSION_LAST_BRANCH="${current_branch}"
            fi
        fi
    }
    
    # Append to existing PROMPT_COMMAND
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }session_prompt_command"
fi

# Function to toggle session tracking
toggle_session_tracking() {
    if [ "${SESSION_TRACKER_ENABLED}" = "true" ]; then
        export SESSION_TRACKER_ENABLED="false"
        echo "Session tracking disabled"
    else
        export SESSION_TRACKER_ENABLED="true"
        echo "Session tracking enabled"
        init_session_tracking
    fi
}

# Function to view session summary
session_summary() {
    if [ ! -f "${SESSION_LOG_FILE}" ]; then
        echo "No session data available"
        return
    fi
    
    echo "=== Session Summary ==="
    echo "Log file: ${SESSION_LOG_FILE}"
    echo ""
    echo "Commands executed today: $(grep "$(date +%Y-%m-%d)" "${SESSION_LOG_FILE}" | grep "CMD:" | wc -l)"
    echo "Directories visited: $(grep "PWD:" "${SESSION_LOG_FILE}" | sort -u | wc -l)"
    echo "Git branches used: $(grep "BRANCH:" "${SESSION_LOG_FILE}" | sort -u | wc -l)"
    echo ""
    echo "Recent commands:"
    tail -5 "${SESSION_LOG_FILE}" | grep "CMD:" | sed 's/.*CMD: /  /'
}

# Function to export session
export_session() {
    local export_dir="${1:-./session-export-$(date +%Y%m%d-%H%M%S)}"
    
    echo "Exporting session to ${export_dir}..."
    mkdir -p "${export_dir}"
    
    # Copy session files
    cp -r "${SESSION_TRACKER_DIR}"/* "${export_dir}/" 2>/dev/null
    
    # Generate summary report
    cat > "${export_dir}/session-report.md" << EOF
# Session Report

**Generated**: $(date)
**User**: $(whoami)
**System**: $(uname -a)

## Activity Summary

### Commands Executed
Total: $(grep "CMD:" "${SESSION_LOG_FILE}" 2>/dev/null | wc -l)

### Recent Commands
\`\`\`
$(tail -20 "${SESSION_LOG_FILE}" 2>/dev/null | grep "CMD:" | sed 's/.*CMD: //')
\`\`\`

### Directories Accessed
\`\`\`
$(grep "PWD:" "${SESSION_LOG_FILE}" 2>/dev/null | sed 's/.*PWD: //' | sort -u)
\`\`\`

### Git Branches
\`\`\`
$(grep "BRANCH:" "${SESSION_LOG_FILE}" 2>/dev/null | sed 's/.*BRANCH: //' | sort -u)
\`\`\`

## Session Files
$(ls -la "${export_dir}/" 2>/dev/null)
EOF
    
    echo "Session exported to ${export_dir}"
}

# Aliases for convenience
alias st-on='export SESSION_TRACKER_ENABLED=true && echo "Session tracking enabled"'
alias st-off='export SESSION_TRACKER_ENABLED=false && echo "Session tracking disabled"'
alias st-summary='session_summary'
alias st-export='export_session'
alias st-clear='> "${SESSION_LOG_FILE}" && echo "Session log cleared"'
alias st-tail='tail -f "${SESSION_LOG_FILE}"'

# Initialize on shell startup
init_session_tracking

# Export functions for use in shell
export -f init_session_tracking
export -f toggle_session_tracking
export -f session_summary
export -f export_session

echo "Session tracking initialized. Use 'st-summary' to view summary or 'st-off' to disable."
