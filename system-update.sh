#!/bin/bash
# File: system-update.sh
# Author: Michael Brown
# Version: 1.3.0
# Date: Updated 10/5/2025
# Description: Menu-driven system update/upgrade manager with logging, input validation, and help

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
#   ./system-update.sh --ubuntuUpdateOS # Run OS upgrade without menu (Ubuntu only)

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
#   3. Full system upgrade         - Complete system upgrade (apt full upgrade, or yum/dnf upgrade)
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

# Prompt colors
COLOR_YELLOW="\033[0;33m"
COLOR_RESET="\033[0m"


################################################################################################
#### Detect Package Manager
################################################################################################

# Detect whether the system uses apt or yum
# Returns "apt", "yum", or "unknown"

#DO-NOT use the terminalOutput function in this function as 
# it is used in other functions that call terminalOutput
function detectPackageManager() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
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
    # Ensure script is run with sudo/root privileges
    checkRoot

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
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " System Summary"
    terminalOutput "======================================"

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        terminalOutput "System: ${PRETTY_NAME:-Unknown}"
    fi

    if [ "$pkgManager" = "apt" ]; then
        current_version=$(lsb_release -rs 2>/dev/null)
        if [ -n "$current_version" ]; then
            terminalOutput "Current Ubuntu Version: $current_version"
        fi

        terminalOutput ""
        terminalOutput "Checking for upgradeable packages..."
        upgradable_count=$(apt-get -s upgrade | awk '/^Inst /' | wc -l)
        terminalOutput "Packages available for upgrade: $upgradable_count"

        if [ "$upgradable_count" -gt 0 ]; then
            terminalOutput "Sample upgradeable packages:"
            apt-get -s upgrade | awk '/^Inst / {print $2}' | head -5
        fi

        terminalOutput ""
        terminalOutput "Checking full-upgrade impact..."
        full_upgrade_preview=$(apt-get -s dist-upgrade | awk '/^Inst /')
        if [ -z "$full_upgrade_preview" ]; then
            terminalOutput "No packages require full-upgrade."
        else
            terminalOutput "Packages affected by full-upgrade:"
            terminalOutput "$full_upgrade_preview" | head -5
        fi

        terminalOutput ""
        terminalOutput "Checking for Ubuntu release upgrade..."
        next_version=$(do-release-upgrade -c 2>/dev/null | grep "New release" | awk -F': ' '{print $2}')
        if [ -z "$next_version" ]; then
            terminalOutput "You are running the latest supported release."
        else
            terminalOutput "New Ubuntu release available: $next_version"
        fi
    elif [ "$pkgManager" = "yum" ] || [ "$pkgManager" = "dnf" ]; then
        terminalOutput ""
        terminalOutput "Checking for upgradeable packages..."
        update_output=$($pkgManager -q check-update 2>/dev/null || true)
        upgradable_count=$(echo "$update_output" | awk 'NF==3 {count++} END{print count+0}')
        terminalOutput "Packages available for upgrade: $upgradable_count"

        if [ "$upgradable_count" -gt 0 ]; then
            terminalOutput "Sample upgradeable packages:"
            echo "$update_output" | awk 'NF==3 {print $1}' | head -5
        fi

        terminalOutput ""
        terminalOutput "OS upgrades are managed by your distribution tools."
    else
        terminalOutput "Package manager not detected."
    fi

    terminalOutput "======================================"
    pause
}

################################################################################################
#### Utility Functions
################################################################################################

function promptInput(){
    local prompt="$1"
    local varName="$2"
    printf "%b" "${COLOR_YELLOW}${prompt}${COLOR_RESET}"
    if [ -n "$varName" ]; then
        read -r "$varName"
    else
        read -r
    fi
}

function log(){
    if [ "$LOGGING_ENABLED" = true ]; then
        terminalOutput "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
    fi
}

function pause(){
    promptInput "Press [Enter] to return to the menu..."
}

function confirm(){
    promptInput "$1 [y/N]: " response
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
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf -y upgrade
        sudo dnf -y autoremove || true
        sudo dnf clean all
        return
    fi
    terminalOutput "Standard update complete."
    log "Standard update complete"
}


################################################################################################
#### Ubuntu - Update to latest version
################################################################################################

function ubuntuUpdateOS(){
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" != "apt" ]; then
        terminalOutput "OS upgrades are only supported on Ubuntu/Debian in this script."
        pause
        return
    fi

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
    local pkgManager
    pkgManager=$(detectPackageManager)

    if [ "$pkgManager" = "apt" ]; then
        log "Checking for packages requiring full upgrade"
        terminalOutput "Checking for packages requiring full upgrade..."

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
        return
    fi

    if confirm "Would you like to proceed with the full upgrade?"; then
        log "User confirmed full upgrade"
        terminalOutput "Running full upgrade..."
        if [ "$pkgManager" = "yum" ]; then
            sudo yum upgrade -y
            if command -v yum-autoremove >/dev/null 2>&1; then
                sudo yum autoremove
            fi
            sudo yum clean all
        elif [ "$pkgManager" = "dnf" ]; then
            sudo dnf -y upgrade
            sudo dnf -y autoremove || true
            sudo dnf clean all
        else
            terminalOutput "Package manager not detected."
        fi
        log "Full upgrade complete"
    else
        terminalOutput "Full upgrade canceled."
        log "Full upgrade canceled by user"
    fi
    pause
}

################################################################################################
#### Help Menu
################################################################################################

function showHelp(){
    local pkgManager
    pkgManager=$(detectPackageManager)

    if [ "$pkgManager" = "apt" ]; then
        terminalOutput "Ubuntu Update Manager - Version $SCRIPT_VERSION"
    else
        terminalOutput "System Update Manager - Version $SCRIPT_VERSION"
    fi
    terminalOutput ""
    terminalOutput "Menu Options:"
    if [ "$pkgManager" = "apt" ]; then
        terminalOutput "  1) Standard Update & Cleanup - Runs update/upgrade and cleanup commands"
        terminalOutput "  2) Upgrade to Latest Ubuntu Version - Uses do-release-upgrade (Ubuntu only)"
        terminalOutput "  3) Full Upgrade - Runs full upgrade for your package manager"
        terminalOutput "  4) Show System Summary - Displays system stats and package info"
        terminalOutput "  5) Help - Show this usage summary"
        terminalOutput "  6) Exit - Quit the script"
    else
        terminalOutput "  1) Standard Update & Cleanup - Runs update/upgrade and cleanup commands"
        terminalOutput "  2) Full Upgrade - Runs full upgrade for your package manager"
        terminalOutput "  3) Show System Summary - Displays system stats and package info"
        terminalOutput "  4) Help - Show this usage summary"
        terminalOutput "  5) Exit - Quit the script"
    fi
    pause
}

################################################################################################
#### Menu Interface
################################################################################################

function showMenu(){
    clear
    local pkgManager
    pkgManager=$(detectPackageManager)
    terminalOutput "======================================"
    if [ "$pkgManager" = "apt" ]; then
        terminalOutput " Ubuntu Update Manager - v$SCRIPT_VERSION"
    else
        terminalOutput " System Update Manager - v$SCRIPT_VERSION"
    fi
    terminalOutput "======================================"
    terminalOutput "1) Standard Update & Cleanup"
    if [ "$pkgManager" = "apt" ]; then
        terminalOutput "2) Upgrade to Latest Ubuntu Version"
        terminalOutput "3) Full Upgrade"
        terminalOutput "4) Show System Summary"
        terminalOutput "5) Help"
        terminalOutput "6) Exit"
    else
        terminalOutput "2) Full Upgrade"
        terminalOutput "3) Show System Summary"
        terminalOutput "4) Help"
        terminalOutput "5) Exit"
    fi
    terminalOutput "======================================"
    if [ "$pkgManager" = "apt" ]; then
        promptInput "Choose an option [1-6]: " choice

        if ! [[ "$choice" =~ ^[1-6]$ ]]; then
            terminalOutput "Invalid input. Please enter a number between 1 and 6."
            sleep 2
            return
        fi

        case $choice in
            1) runUpdate ;;
            2) ubuntuUpdateOS ;;
            3) ubuntuFullUpgrade ;;
            4) showSystemSummary ;;
            5) showHelp ;;
            6) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
        esac
    else
        promptInput "Choose an option [1-5]: " choice

        if ! [[ "$choice" =~ ^[1-5]$ ]]; then
            terminalOutput "Invalid input. Please enter a number between 1 and 5."
            sleep 2
            return
        fi

        case $choice in
            1) runUpdate ;;
            2) ubuntuFullUpgrade ;;
            3) showSystemSummary ;;
            4) showHelp ;;
            5) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
        esac
    fi
}

################################################################################################
#### Start Script with Persistent Loop
################################################################################################


# Ensure script is run with sudo/root privileges
checkRoot

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
    while true; do showMenu; done
fi

