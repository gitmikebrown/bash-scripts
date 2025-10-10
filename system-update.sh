#!/bin/bash
# File: system-update.sh
# Author: Michael Brown
# Version: 1.3.0
# Date: Updated 10/5/2025
# Description: Menu-driven Ubuntu update/upgrade manager with logging, input validation, and help

################################################################################################
#### HOW TO USE THIS SCRIPT - Examples and Quick Reference
################################################################################################

# BASIC USAGE:
# Make the script executable first:
#   chmod +x system-update.sh
#
# Run in interactive menu mode (shows a numbered menu with options 1-5):
# Simply run the script without any parameters - this starts the interactive menu
#   ./system-update.sh
#
# Run with command line options:
#   ./system-update.sh                  # Starts the interactive menu
#   ./system-update.sh --update-only    # Run standard update in quiet mode
#   ./system-update.sh --full-upgrade   # Run full upgrade without menu
#   ./system-update.sh --ubuntuUpdateOS # Run OS upgrade without menu

# COMMON SCENARIOS:
#
# 1. First time running - interactive menu mode:
#    ./system-update.sh
#
# 2. Regular interactive updates (menu-driven):
#    ./system-update.sh
#    Then select options 1-5 from the menu
#
# 3. Quick system update in quiet mode:
#    ./system-update.sh --update-only
#
# 4. Run full upgrade without menu:
#    ./system-update.sh --full-upgrade

# MENU OPTIONS EXPLAINED:
# When you run ./system-update.sh, you'll see a menu with these options:
#   1. Update package lists         - Refreshes available package information
#   2. Upgrade packages            - Installs available package updates
#   3. Full system upgrade         - Complete system upgrade (dist-upgrade)
#   4. Clean package cache         - Removes old downloaded package files
#   5. Autoremove unused packages  - Removes packages no longer needed
#   6. Show system information     - Displays system stats and package info
#   0. Exit                        - Quit the script

# CROSS-PLATFORM NOTES:
# This script automatically detects your package manager:
#   - Ubuntu/Debian systems: Uses 'apt' commands
#   - RHEL/CentOS/Amazon Linux: Uses 'yum' commands
#   - Fedora/RHEL 8+: Uses 'dnf' commands
#
# The menu options adapt automatically to your system's package manager

# LOGGING:
# To enable logging, edit the LOGGING_ENABLED variable below to 'true'
# To change log file location, edit the LOGFILE variable below (default: /var/log/ubuntu-update-script.log)
# Log file location: /var/log/ubuntu-update-script.log
# View logs: sudo tail -f /var/log/ubuntu-update-script.log
#
# Example custom log locations:
#   LOGFILE="/home/user/logs/system-update.log"        # User home directory
#   LOGFILE="/tmp/system-update.log"                   # Temporary directory
#   LOGFILE="/var/log/custom-update-$(date +%Y%m%d).log"  # Date-stamped logs

# AUTOMATION EXAMPLES:
# For EC2 user data or automation scripts:
#   wget https://raw.githubusercontent.com/gitmikebrown/bash/main/system-update.sh
#   chmod +x system-update.sh
#   ./system-update.sh --update-only    # Run standard update automatically
#
# Or run specific functions programmatically by sourcing the script:
#   source system-update.sh
#   runUpdate                       # Call individual functions

################################################################################################
#### Configurable Variables
################################################################################################

# Define script version
# Only displayed in help and menu headers
SCRIPT_VERSION="1.3.0"

# Enable or disable logging (true/false)
LOGGING_ENABLED=false
LOGFILE="/var/log/ubuntu-update-script.log"

# Quiet mode (suppress non-essential output)
QUIET_MODE=false


################################################################################################
#### Detect Package Manager
################################################################################################

# Detect whether the system uses apt or yum
# Returns "apt", "yum", or "unknown"

#DO-NOT use the terminalOutput function in this function as 
# it is used in other functions that call terminalOutput
function detectPackageManager() {
    if command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    else
        echo "unknown"
    fi
}


################################################################################################
#### Ensure Script is Run as Root
################################################################################################

function checkRoot() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or use sudo."
        exit 1
    fi
}


#################################################################################################
#### Quiet Mode Handling
#################################################################################################
#TODO: run all output through this function to suppress if quiet mode is enabled.


function terminalOutput() {
    if [ "$QUIET_MODE" = false ]; then
        echo "$1"
    fi
}

################################################################################################
#### System Summary
################################################################################################

function showSystemSummary(){
#TODO: the function titled detectPackageManager is not incorporated into summary yet.  
# Currently supports apt only.

    terminalOutput "======================================"
    terminalOutput " Ubuntu System Summary"
    terminalOutput "======================================"

    # Current version
    current_version=$(lsb_release -rs)
    terminalOutput "Current Ubuntu Version: $current_version"

    # Upgradeable packages
    terminalOutput ""
    terminalOutput "Checking for upgradeable packages..."
    upgradable_count=$(apt-get -s upgrade | awk '/^Inst /' | wc -l)
    terminalOutput "Packages available for upgrade: $upgradable_count"

    if [ "$upgradable_count" -gt 0 ]; then
        terminalOutput "Sample upgradeable packages:"
        apt-get -s upgrade | awk '/^Inst / {print $2}' | head -5
    fi

    # Full-upgrade simulation
    terminalOutput ""
    terminalOutput "Checking full-upgrade impact..."
    full_upgrade_preview=$(apt-get -s dist-upgrade | awk '/^Inst /')
    if [ -z "$full_upgrade_preview" ]; then
        terminalOutput "No packages require full-upgrade."
    else
        terminalOutput "Packages affected by full-upgrade:"
        terminalOutput "$full_upgrade_preview" | head -5
    fi

    # Release upgrade availability
    terminalOutput ""
    terminalOutput "Checking for Ubuntu release upgrade..."
    next_version=$(do-release-upgrade -c | grep "New release" | awk -F': ' '{print $2}')
    if [ -z "$next_version" ]; then
        terminalOutput "You are running the latest supported release."
    else
        terminalOutput "New Ubuntu release available: $next_version"
    fi

    terminalOutput "======================================"
    pause
}

################################################################################################
#### Utility Functions
################################################################################################

function log(){
    if [ "$LOGGING_ENABLED" = true ]; then
        terminalOutput "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
    fi
}

function pause(){
    read -p "Press [Enter] to return to the menu..."
}

function confirm(){
    read -p "$1 [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

################################################################################################
#### Update
################################################################################################

#### apt - Standard Update

function runUpdate(){
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    log "Starting standard update and cleanup"
    terminalOutput "Running standard update and cleanup..."
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt upgrade -y
        sudo apt dist-upgrade -y
        sudo apt autoremove -y
        sudo apt autoclean -y
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum update -y
        sudo yum upgrade -y
        sudo yum autoremove -y
        sudo yum clean all
        sudo yum update -y
        sudo yum upgrade -y
        if command -v yum-autoremove >/dev/null 2>&1; then
            sudo yum autoremove
        fi
        sudo yum clean all
        return
    fi
    terminalOutput "Standard update complete."
    log "Standard update complete"
}


################################################################################################
#### Ubuntu - Update to latest version
################################################################################################

function ubuntuUpdateOS(){
    terminalOutput "Checking current Ubuntu version..."
    current_version=$(lsb_release -rs)
    terminalOutput "You are currently running Ubuntu $current_version."

    # Fetch available upgrade version (requires update-manager-core)
    next_version=$(do-release-upgrade -c | grep "New release" | awk -F': ' '{print $2}')

    if [ -z "$next_version" ]; then
        terminalOutput "You are already running the latest supported version."
        log "OS upgrade check: already at latest version ($current_version)"
    else
        terminalOutput "A new Ubuntu version is available: $next_version"
        if confirm "Would you like to upgrade to Ubuntu $next_version?"; then
            log "User confirmed upgrade from $current_version to $next_version"
            sudo do-release-upgrade
            log "OS upgrade initiated"
        else
            terminalOutput "OS upgrade canceled."
            log "OS upgrade canceled by user"
        fi
    fi
    pause
}

################################################################################################
#### Ubuntu - Full upgrade
################################################################################################

function ubuntuFullUpgrade(){
    log "Checking for packages requiring full upgrade"
    terminalOutput "Checking for packages requiring full upgrade..."

    # Simulate full-upgrade to preview changes
    pending=$(apt-get -s dist-upgrade | awk '/^Inst /')

    if [ -z "$pending" ]; then
        terminalOutput "No packages require a full upgrade. System is up to date."
        log "Full upgrade skipped — no packages pending"
    else
        terminalOutput "The following packages are eligible for full upgrade:"
        terminalOutput "$pending"
        terminalOutput ""
        if confirm "Would you like to proceed with the full upgrade?"; then
            log "User confirmed full upgrade"
            terminalOutput "Running full upgrade..."
            sudo apt-get -y dist-upgrade
            log "Full upgrade complete"
        else
            terminalOutput "Full upgrade canceled."
            log "Full upgrade canceled by user"
        fi
    fi
    pause
}

################################################################################################
#### Help Menu
################################################################################################

function showHelp(){
    terminalOutput "Ubuntu Update Manager - Version $SCRIPT_VERSION"
    terminalOutput ""
    terminalOutput "Menu Options:"
    terminalOutput "  1) Standard Update & Cleanup - Runs apt update/upgrade and cleanup commands"
    terminalOutput "  2) Upgrade to Latest Ubuntu Version - Uses do-release-upgrade for LTS upgrades"
    terminalOutput "  3) Full Upgrade - Runs apt full-upgrade"
    terminalOutput "  4) Help - Show this usage summary"
    terminalOutput "  5) Exit - Quit the script"
    pause
}

################################################################################################
#### Menu Interface
################################################################################################

function showMenu(){
    clear
    terminalOutput "======================================"
    terminalOutput " Ubuntu Update Manager - v$SCRIPT_VERSION"
    terminalOutput "======================================"
    terminalOutput "1) Standard Update & Cleanup"
    terminalOutput "2) Upgrade to Latest Ubuntu Version"
    terminalOutput "3) Full Upgrade"
    terminalOutput "4) Help"
    terminalOutput "5) Exit"
    terminalOutput "======================================"
    read -p "Choose an option [1-5]: " choice

    if ! [[ "$choice" =~ ^[1-5]$ ]]; then
        terminalOutput "Invalid input. Please enter a number between 1 and 5."
        sleep 2
        return
    fi

    case $choice in
        1) runUpdate ;;
        2) ubuntuUpdateOS ;;
        3) ubuntuFullUpgrade ;;
        4) showHelp ;;
        5) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
    esac
}

################################################################################################
#### Start Script with Persistent Loop
################################################################################################



if [[ "$1" == "--update-only" ]]; then
    QUIET_MODE=true
    runUpdate
    exit 0
elif [[ "$1" == "--full-upgrade" ]]; then
    ubuntuFullUpgrade
    exit 0
elif [[ "$1" == "--ubuntuUpdateOS" ]]; then
    ubuntuUpdateOS
    exit 0
else
    showSystemSummary
    while true; do showMenu; done
fi

