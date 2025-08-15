#!/bin/bash

# Master Setup Script for Automated Session Tracking System
# This script installs and configures all components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.session-tracker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Automated Session Tracking System - Setup${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git jq tar gzip; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies and try again."
        exit 1
    fi
    
    print_status "All dependencies satisfied"
}

# Setup directories
setup_directories() {
    echo -e "\n${BLUE}Setting up directories...${NC}"
    
    mkdir -p "${INSTALL_DIR}"/{current,archive,reports,snapshots}
    mkdir -p "${HOME}/.config/session-tracker"
    
    print_status "Created directory structure at ${INSTALL_DIR}"
}

# Install session daemon
install_daemon() {
    echo -e "\n${BLUE}Installing session daemon...${NC}"
    
    if [ -f "${SCRIPT_DIR}/session-daemon.sh" ]; then
        chmod +x "${SCRIPT_DIR}/session-daemon.sh"
        print_status "Session daemon installed"
        
        # Create systemd service (if systemd is available)
        if command -v systemctl &> /dev/null && [ -d "${HOME}/.config/systemd/user" ]; then
            cat > "${HOME}/.config/systemd/user/session-tracker.service" << EOF
[Unit]
Description=Session Tracking Daemon
After=network.target

[Service]
Type=simple
ExecStart=${SCRIPT_DIR}/session-daemon.sh daemon
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
            systemctl --user daemon-reload
            print_status "Created systemd service"
        fi
    else
        print_error "Session daemon script not found"
    fi
}

# Setup Git hooks
setup_git_hooks() {
    echo -e "\n${BLUE}Setting up Git hooks...${NC}"
    
    local git_dir="$(git rev-parse --git-dir 2>/dev/null || echo "")"
    
    if [ -n "${git_dir}" ] && [ -d "${git_dir}/hooks" ]; then
        # Backup existing hooks
        for hook in pre-commit post-commit; do
            if [ -f "${git_dir}/hooks/${hook}" ] && [ ! -f "${git_dir}/hooks/${hook}.backup" ]; then
                mv "${git_dir}/hooks/${hook}" "${git_dir}/hooks/${hook}.backup"
                print_info "Backed up existing ${hook} hook"
            fi
        done
        
        # Copy our hooks
        if [ -f "${SCRIPT_DIR}/../.git/hooks/pre-commit" ]; then
            cp "${SCRIPT_DIR}/../.git/hooks/pre-commit" "${git_dir}/hooks/"
            chmod +x "${git_dir}/hooks/pre-commit"
            print_status "Installed pre-commit hook"
        fi
        
        # Create post-commit hook
        cat > "${git_dir}/hooks/post-commit" << 'EOF'
#!/bin/bash
# Post-commit hook for session tracking

SESSION_DIR=".session-tracking"
COMMIT_LOG="${SESSION_DIR}/commits.log"

mkdir -p "${SESSION_DIR}"

# Log commit details
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] COMMIT: $(git rev-parse HEAD) - $(git log -1 --pretty=%B | head -1)" >> "${COMMIT_LOG}"
EOF
        chmod +x "${git_dir}/hooks/post-commit"
        print_status "Installed post-commit hook"
    else
        print_info "Not in a git repository, skipping Git hooks"
    fi
}

# Setup shell integration
setup_shell_integration() {
    echo -e "\n${BLUE}Setting up shell integration...${NC}"
    
    local shell_rc=""
    
    # Detect shell and RC file
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="${HOME}/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="${HOME}/.bashrc"
    fi
    
    if [ -n "${shell_rc}" ] && [ -f "${shell_rc}" ]; then
        # Check if already installed
        if grep -q "session-tracker/shell-integration.sh" "${shell_rc}"; then
            print_info "Shell integration already installed"
        else
            # Add source line to RC file
            echo "" >> "${shell_rc}"
            echo "# Automated Session Tracking" >> "${shell_rc}"
            echo "[ -f \"${SCRIPT_DIR}/shell-integration.sh\" ] && source \"${SCRIPT_DIR}/shell-integration.sh\"" >> "${shell_rc}"
            print_status "Added shell integration to ${shell_rc}"
            print_info "Please restart your shell or run: source ${shell_rc}"
        fi
    else
        print_error "Could not detect shell RC file"
    fi
}

# Setup cron jobs
setup_cron() {
    echo -e "\n${BLUE}Setting up cron jobs...${NC}"
    
    if [ -f "${SCRIPT_DIR}/setup-cron.sh" ]; then
        chmod +x "${SCRIPT_DIR}/setup-cron.sh"
        "${SCRIPT_DIR}/setup-cron.sh" install
        print_status "Cron jobs installed"
    else
        print_error "Cron setup script not found"
    fi
}

# Create configuration file
create_config() {
    echo -e "\n${BLUE}Creating configuration...${NC}"
    
    cat > "${HOME}/.config/session-tracker/config.json" << EOF
{
    "version": "1.0.0",
    "install_dir": "${INSTALL_DIR}",
    "script_dir": "${SCRIPT_DIR}",
    "features": {
        "daemon": true,
        "git_hooks": true,
        "shell_integration": true,
        "cron_jobs": true,
        "auto_archive": true,
        "daily_reports": true,
        "analytics": true
    },
    "settings": {
        "session_timeout": 7200,
        "snapshot_interval": 3600,
        "max_log_size": 104857600,
        "archive_days": 30,
        "report_email": ""
    },
    "installed": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    print_status "Configuration saved to ~/.config/session-tracker/config.json"
}

# Start services
start_services() {
    echo -e "\n${BLUE}Starting services...${NC}"
    
    # Start daemon
    if [ -f "${SCRIPT_DIR}/session-daemon.sh" ]; then
        "${SCRIPT_DIR}/session-daemon.sh" start
        print_status "Session daemon started"
    fi
    
    # Start systemd service if available
    if command -v systemctl &> /dev/null && [ -f "${HOME}/.config/systemd/user/session-tracker.service" ]; then
        systemctl --user enable session-tracker.service
        systemctl --user start session-tracker.service
        print_status "Systemd service enabled and started"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}     Installation Complete! 🎉${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Installed Components:${NC}"
    echo "  ✓ Session tracking daemon"
    echo "  ✓ Git hooks (pre-commit, post-commit)"
    echo "  ✓ Shell integration (command tracking)"
    echo "  ✓ Cron jobs (hourly snapshots, daily reports)"
    echo "  ✓ Analytics system"
    echo ""
    echo -e "${GREEN}Available Commands:${NC}"
    echo "  st-summary    - View session summary"
    echo "  st-export     - Export session data"
    echo "  st-on/st-off  - Enable/disable tracking"
    echo "  st-tail       - Watch live session log"
    echo ""
    echo -e "${GREEN}File Locations:${NC}"
    echo "  Session data: ${INSTALL_DIR}"
    echo "  Configuration: ~/.config/session-tracker/config.json"
    echo "  Scripts: ${SCRIPT_DIR}"
    echo ""
    echo -e "${GREEN}Management:${NC}"
    echo "  Start daemon:    ${SCRIPT_DIR}/session-daemon.sh start"
    echo "  Stop daemon:     ${SCRIPT_DIR}/session-daemon.sh stop"
    echo "  Cron status:     ${SCRIPT_DIR}/setup-cron.sh status"
    echo ""
    echo -e "${YELLOW}NOTE: Restart your shell to activate command tracking${NC}"
    echo ""
}

# Uninstall function
uninstall() {
    echo -e "${RED}Uninstalling session tracking system...${NC}"
    
    # Stop services
    "${SCRIPT_DIR}/session-daemon.sh" stop 2>/dev/null || true
    systemctl --user stop session-tracker.service 2>/dev/null || true
    systemctl --user disable session-tracker.service 2>/dev/null || true
    
    # Remove cron jobs
    "${SCRIPT_DIR}/setup-cron.sh" uninstall 2>/dev/null || true
    
    # Remove shell integration
    if [ -f "${HOME}/.zshrc" ]; then
        sed -i.backup '/session-tracker\/shell-integration.sh/d' "${HOME}/.zshrc"
    fi
    if [ -f "${HOME}/.bashrc" ]; then
        sed -i.backup '/session-tracker\/shell-integration.sh/d' "${HOME}/.bashrc"
    fi
    
    # Remove Git hooks
    local git_dir="$(git rev-parse --git-dir 2>/dev/null || echo "")"
    if [ -n "${git_dir}" ]; then
        rm -f "${git_dir}/hooks/pre-commit" "${git_dir}/hooks/post-commit"
        # Restore backups if they exist
        [ -f "${git_dir}/hooks/pre-commit.backup" ] && mv "${git_dir}/hooks/pre-commit.backup" "${git_dir}/hooks/pre-commit"
        [ -f "${git_dir}/hooks/post-commit.backup" ] && mv "${git_dir}/hooks/post-commit.backup" "${git_dir}/hooks/post-commit"
    fi
    
    # Remove systemd service
    rm -f "${HOME}/.config/systemd/user/session-tracker.service"
    
    echo -e "${GREEN}Uninstall complete. Data preserved in ${INSTALL_DIR}${NC}"
    echo "To remove all data: rm -rf ${INSTALL_DIR}"
}

# Main installation flow
main() {
    case "${1:-install}" in
        install)
            check_dependencies
            setup_directories
            install_daemon
            setup_git_hooks
            setup_shell_integration
            setup_cron
            create_config
            start_services
            display_summary
            ;;
        uninstall)
            uninstall
            ;;
        status)
            echo "Session Tracking System Status:"
            echo ""
            "${SCRIPT_DIR}/session-daemon.sh" status
            echo ""
            "${SCRIPT_DIR}/setup-cron.sh" status
            echo ""
            if [ -f "${HOME}/.config/session-tracker/config.json" ]; then
                echo "Configuration:"
                jq . "${HOME}/.config/session-tracker/config.json"
            fi
            ;;
        *)
            echo "Usage: $0 {install|uninstall|status}"
            echo ""
            echo "  install   - Install complete session tracking system"
            echo "  uninstall - Remove session tracking (preserves data)"
            echo "  status    - Show system status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
