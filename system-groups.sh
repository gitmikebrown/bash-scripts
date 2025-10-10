#!/bin/bash
# File: system-groups.sh
# Author: Michael Brown
# Date: October 5, 2025
# Version: 2.0.0
# Description: Cross-platform Linux groups management script with distribution detection
# Compatible with: Ubuntu, AWS Linux, CentOS, RHEL, Debian, and other major distributions

#to run script:
#bash system-groups.sh --help


################################################################################################
#### USAGE EXAMPLES - Quick Reference
################################################################################################

# BASIC USAGE:
# ./system-groups.sh                           # Launch interactive menu
# ./system-groups.sh --help                    # Show help and all options
# ./system-groups.sh --force                   # Enable silent mode (no prompts for automation)

# ADMIN MANAGEMENT:
# ./system-groups.sh --makeAdmin               # Make current user admin
# ./system-groups.sh --makeAdmin john          # Make 'john' an admin
# ./system-groups.sh --makeAdmin mike          # Make 'mike' an admin

# GROUP MANAGEMENT:
# ./system-groups.sh --addGroup developers     # Create 'developers' group
# ./system-groups.sh --addGroup docker         # Create 'docker' group
# ./system-groups.sh --addGroup webmasters     # Create 'webmasters' group
# ./system-groups.sh --deleteGroup oldgroup    # Delete 'oldgroup'

# USER-GROUP OPERATIONS:
# ./system-groups.sh --addUser mike docker     # Add 'mike' to 'docker' group
# ./system-groups.sh --addUser john developers # Add 'john' to 'developers' group
# ./system-groups.sh --removeUser mike docker  # Remove 'mike' from 'docker'
# ./system-groups.sh --addUser $USER www-data  # Add current user to web group
# NOTE: --addUser will prompt to create the group if it doesn't exist

# FILE OWNERSHIP:
# ./system-groups.sh --takeOwnership /var/www/html                    # Take ownership of web files
# ./system-groups.sh --takeOwnership /home/projects                   # Take ownership of projects
# ./system-groups.sh --takeOwnership /opt/myapp mike                  # Give 'mike' ownership of /opt/myapp
# ./system-groups.sh --takeOwnership "/var/www/html" $USER            # Take ownership for current user

# VIEWING INFORMATION:
# ./system-groups.sh --viewUser                # View current user's groups
# ./system-groups.sh --viewUser mike           # View 'mike's groups
# ./system-groups.sh --viewGroups              # View all system groups
# ./system-groups.sh --info                    # Show system information

# COMMON WORKFLOWS:

# New server setup (make admin, setup web development):
# ./system-groups.sh --makeAdmin --addGroup developers --addUser $USER developers --takeOwnership /var/www/html

# Docker development setup:
# ./system-groups.sh --addGroup docker --addUser $USER docker

# Web development setup:
# ./system-groups.sh --takeOwnership /var/www/html --addUser $USER www-data

# User onboarding (create user groups and add them):
# ./system-groups.sh --addGroup projectteam --addUser newuser projectteam --addUser newuser developers

# Quick admin + web setup:
# ./system-groups.sh --makeAdmin --takeOwnership /var/www/html

# Multiple operations in one command:
# ./system-groups.sh --addGroup dev --addGroup staging --addUser mike dev --addUser mike staging

# AUTOMATION EXAMPLES (--force mode for scripts/templates):
# ./system-groups.sh --force --addGroup developers --addUser mike developers
# ./system-groups.sh --force --makeAdmin mike --takeOwnership /var/www/html
# ./system-groups.sh --force --addGroup docker --addUser $USER docker --takeOwnership /opt/myapp

################################################################################################

################################################################################################
#### Distribution Detection and Configuration
################################################################################################

function detectDistribution() {
    local distro="unknown"
    
    # Check for specific distribution files
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                distro="ubuntu"
                ;;
            amzn)
                distro="amazon-linux"
                ;;
            centos|rhel)
                distro="redhat-family"
                ;;
            debian)
                distro="debian"
                ;;
            fedora)
                distro="fedora"
                ;;
            *)
                # Try to determine family
                if [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID_LIKE" == *"fedora"* ]]; then
                    distro="redhat-family"
                elif [[ "$ID_LIKE" == *"debian"* ]]; then
                    distro="debian"
                fi
                ;;
        esac
    elif [ -f /etc/redhat-release ]; then
        distro="redhat-family"
    elif [ -f /etc/debian_version ]; then
        distro="debian"
    fi
    
    echo "$distro"
}

function setDistributionGroups() {
    local distro=$(detectDistribution)
    
    case "$distro" in
        ubuntu|debian)
            ADMIN_GROUP="sudo"
            WEB_USER="www-data"
            ;;
        amazon-linux|redhat-family|fedora)
            ADMIN_GROUP="wheel"
            WEB_USER="apache"
            ;;
        *)
            echo "Warning: Unknown distribution. Using generic settings."
            ADMIN_GROUP="wheel"
            WEB_USER="apache"
            ;;
    esac
    
    echo "Detected distribution: $distro"
    echo "Admin group: $ADMIN_GROUP"
    echo "Web user: $WEB_USER"
}

################################################################################################
#### Utility Functions
################################################################################################

function showSystemInfo() {
    echo "========================================"
    echo " System Groups Management Tool v2.0.0"
    echo "========================================"
    echo "Current user: $USER"
    echo "Current system: $(uname -s) $(uname -r)"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "Distribution: $PRETTY_NAME"
    fi
    
    setDistributionGroups
    echo "========================================"
}

function viewAllGroups() {
    echo "All system groups and their members:"
    echo "======================================"
    cat /etc/group
}

function viewUserGroups() {
    local username=${1:-$USER}
    echo "Groups for user '$username':"
    echo "============================"
    groups "$username" 2>/dev/null || echo "User '$username' not found"
    echo ""
    echo "Detailed group membership:"
    cat /etc/group | grep "$username"
}

function viewWebUserGroups() {
    echo "Groups for web user '$WEB_USER':"
    echo "==============================="
    cat /etc/group | grep "$WEB_USER"
}

function createCustomGroups() {
    echo "Creating custom development groups..."
    
    local custom_groups=("frontEnd" "appDev" "dataBase" "webmasters")
    
    for group in "${custom_groups[@]}"; do
        if getent group "$group" >/dev/null 2>&1; then
            echo "Group '$group' already exists"
        else
            echo "Creating group: $group"
            sudo groupadd "$group"
        fi
    done
}

function addUserToCustomGroups() {
    local username=${1:-$USER}
    local custom_groups=("frontEnd" "appDev" "dataBase" "webmasters")
    
    echo "Adding user '$username' to custom development groups..."
    
    for group in "${custom_groups[@]}"; do
        if getent group "$group" >/dev/null 2>&1; then
            echo "Adding $username to $group"
            sudo usermod --append --groups "$group" "$username"
        else
            echo "Warning: Group '$group' does not exist. Create it first."
        fi
    done
}

function makeUserAdmin() {
    local username=${1:-$USER}
    
    echo "Making user '$username' an administrator..."
    
    # Add to admin group (sudo or wheel)
    if getent group "$ADMIN_GROUP" >/dev/null 2>&1; then
        echo "Adding $username to admin group: $ADMIN_GROUP"
        sudo usermod --append --groups "$ADMIN_GROUP" "$username"
        echo "SUCCESS: User '$username' now has admin privileges"
    else
        echo "ERROR: Admin group '$ADMIN_GROUP' not found on this system"
        return 1
    fi
    
    # Optionally add to web group for web development
    if getent group "$WEB_USER" >/dev/null 2>&1; then
        if [ "$FORCE_MODE" = true ]; then
            echo "Adding $username to web group: $WEB_USER (force mode)"
            sudo usermod --append --groups "$WEB_USER" "$username"
        else
            read -p "Also add $username to web group '$WEB_USER'? (y/n): " add_web
            if [[ "$add_web" =~ ^[Yy]$ ]]; then
                echo "Adding $username to web group: $WEB_USER"
                sudo usermod --append --groups "$WEB_USER" "$username"
            fi
        fi
    fi
}

function takeOwnership() {
    local path=${1:-""}
    local username=${2:-$USER}
    
    if [ -z "$path" ]; then
        echo "Usage: takeOwnership <path> [username]"
        echo "Example: takeOwnership /var/www/html"
        echo "Example: takeOwnership /home/projects mike"
        return 1
    fi
    
    if [ ! -e "$path" ]; then
        echo "ERROR: Path '$path' does not exist"
        return 1
    fi
    
    # Safety check: Prevent ownership changes to critical system directories
    local dangerous_paths=(
        "/bin" "/sbin" "/usr/bin" "/usr/sbin" "/usr/lib" "/usr/lib64"
        "/etc" "/boot" "/sys" "/proc" "/dev" "/run"
        "/root" "/lib" "/lib64" "/opt/aws" "/opt/amazon"
        "/" "/usr" "/var/lib/dpkg" "/var/lib/rpm"
    )
    
    # Convert path to absolute path for comparison
    local abs_path=$(realpath "$path" 2>/dev/null || echo "$path")
    
    for dangerous in "${dangerous_paths[@]}"; do
        if [[ "$abs_path" == "$dangerous" ]] || [[ "$abs_path" == "$dangerous"/* ]]; then
            echo "ERROR: Cannot change ownership of system directory '$path'"
            echo "This could break your system. Blocked for safety."
            echo "If you really need to do this, use chown directly with extreme caution."
            return 1
        fi
    done
    
    # Additional safety: Warn if trying to change ownership of anything in /usr or /etc
    if [[ "$abs_path" == /usr/* ]] || [[ "$abs_path" == /etc/* ]]; then
        echo "WARNING: You're trying to change ownership in a system directory ($path)"
        read -p "This could potentially break system functionality. Continue? (type 'YES' to confirm): " confirm
        if [[ "$confirm" != "YES" ]]; then
            echo "Operation cancelled for safety."
            return 1
        fi
    fi
    
    # Safety check: Don't allow taking ownership as root unless explicitly running as root
    if [[ "$username" == "root" ]] && [[ "$USER" != "root" ]]; then
        echo "ERROR: Cannot change ownership to root user unless you are root"
        return 1
    fi
    
    echo "Taking ownership of '$path' for user '$username'..."
    
    # Show what will be changed before doing it
    echo "Current ownership:"
    ls -la "$path" | head -5
    
    read -p "Change ownership of '$path' to '$username'? (y/n): " confirm_ownership
    if [[ ! "$confirm_ownership" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return 1
    fi
    
    # Change ownership
    sudo chown -R "$username:$username" "$path"
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Successfully changed ownership of '$path' to '$username'"
        
        # Show current permissions
        echo "Current permissions:"
        ls -la "$path"
        
        # Ask if they want to set permissions
        read -p "Set full read/write permissions for owner? (y/n): " set_perms
        if [[ "$set_perms" =~ ^[Yy]$ ]]; then
            sudo chmod -R 755 "$path"
            echo "SUCCESS: Set permissions to 755 (owner: read/write/execute, others: read/execute)"
        fi
    else
        echo "ERROR: Failed to change ownership"
        return 1
    fi
}

function addUserToGroup() {
    local username=${1:-""}
    local groupname=${2:-""}
    
    if [ -z "$username" ] || [ -z "$groupname" ]; then
        echo "Usage: addUserToGroup <username> <groupname>"
        echo "Example: addUserToGroup mike docker"
        return 1
    fi
    
    # Check if user exists
    if ! id "$username" >/dev/null 2>&1; then
        echo "ERROR: User '$username' does not exist"
        return 1
    fi
    
    # Check if group exists
    if ! getent group "$groupname" >/dev/null 2>&1; then
        if [ "$FORCE_MODE" = true ]; then
            echo "Creating group '$groupname' (force mode)..."
            sudo groupadd "$groupname"
            echo "SUCCESS: Created group '$groupname'"
        else
            echo "ERROR: Group '$groupname' does not exist"
            read -p "Create group '$groupname'? (y/n): " create_group
            if [[ "$create_group" =~ ^[Yy]$ ]]; then
                sudo groupadd "$groupname"
                echo "SUCCESS: Created group '$groupname'"
            else
                return 1
            fi
        fi
    fi
    
    echo "Adding user '$username' to group '$groupname'..."
    sudo usermod --append --groups "$groupname" "$username"
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Successfully added '$username' to group '$groupname'"
        echo "User '$username' is now in these groups:"
        groups "$username"
    else
        echo "ERROR: Failed to add user to group"
        return 1
    fi
}

function removeUserFromGroup() {
    local username=${1:-""}
    local groupname=${2:-""}
    
    if [ -z "$username" ] || [ -z "$groupname" ]; then
        echo "Usage: removeUserFromGroup <username> <groupname>"
        return 1
    fi
    
    echo "Removing user '$username' from group '$groupname'..."
    sudo gpasswd --delete "$username" "$groupname"
}

function deleteGroup() {
    local groupname=${1:-""}
    
    if [ -z "$groupname" ]; then
        echo "Usage: deleteGroup <groupname>"
        return 1
    fi
    
    if getent group "$groupname" >/dev/null 2>&1; then
        echo "Deleting group: $groupname"
        sudo groupdel "$groupname"
    else
        echo "Group '$groupname' does not exist"
    fi
}

function syncGroupFiles() {
    echo "Synchronizing group files..."
    sudo grpck
    echo "Group file synchronization complete"
}

function showUsage() {
    echo "========================================"
    echo " System Groups Management Tool v2.0.0"
    echo "========================================"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Command Line Options:"
    echo "  --makeAdmin [username]        Make user an admin (default: current user)"
    echo "  --takeOwnership <path> [user] Take ownership of files/folders"
    echo "  --addUser <user> <group>      Add user to group"
    echo "  --removeUser <user> <group>   Remove user from group"
    echo "  --addGroup <groupname>        Create new group"
    echo "  --deleteGroup <groupname>     Delete group"
    echo "  --viewUser [username]         View user's groups (default: current user)"
    echo "  --viewGroups                  View all groups"
    echo "  --info                        Show system info"
    echo "  --menu                        Launch interactive menu"
    echo "  --force                       Silent mode (no prompts for automation)"
    echo "  --help                        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --makeAdmin                # Make current user admin"
    echo "  $0 --makeAdmin john           # Make 'john' an admin"
    echo "  $0 --addGroup developers      # Create 'developers' group"
    echo "  $0 --addUser mike docker      # Add 'mike' to 'docker' group"
    echo "  $0 --takeOwnership /var/www/html"
    echo "  $0 --viewUser mike            # View mike's groups"
    echo "  $0 --menu                     # Launch interactive menu"
    echo ""
    echo "Automation Examples (--force mode):"
    echo "  $0 --force --addGroup dev --addUser mike dev"
    echo "  $0 --force --makeAdmin mike --takeOwnership /var/www/html"
    echo "========================================"
}

function parseArguments() {
    # Initialize force mode
    FORCE_MODE=false
    
    # If no arguments provided, show system info and launch menu
    if [ $# -eq 0 ]; then
        setDistributionGroups
        showSystemInfo
        launchInteractiveMenu
        return 0
    fi
    
    # Initialize distribution settings for command-line usage
    setDistributionGroups
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_MODE=true
                echo "Force mode enabled - no prompts for automation"
                shift 1
                ;;
            --makeAdmin)
                local username=${2:-$USER}
                echo "Making user '$username' an admin..."
                makeUserAdmin "$username"
                if [[ -n "$2" ]] && [[ ! "$2" =~ ^-- ]]; then
                    shift 2
                else
                    shift 1
                fi
                ;;
            --takeOwnership)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-- ]]; then
                    echo "ERROR: --takeOwnership requires a path"
                    echo "Usage: $0 --takeOwnership <path> [username]"
                    return 1
                fi
                local path="$2"
                local username=${3:-$USER}
                if [[ -n "$3" ]] && [[ ! "$3" =~ ^-- ]]; then
                    echo "Taking ownership of '$path' for user '$username'..."
                    takeOwnership "$path" "$username"
                    shift 3
                else
                    echo "Taking ownership of '$path' for user '$username'..."
                    takeOwnership "$path" "$username"
                    shift 2
                fi
                ;;
            --addUser)
                if [[ -z "$2" ]] || [[ -z "$3" ]] || [[ "$2" =~ ^-- ]] || [[ "$3" =~ ^-- ]]; then
                    echo "ERROR: --addUser requires username and groupname"
                    echo "Usage: $0 --addUser <username> <groupname>"
                    return 1
                fi
                echo "Adding user '$2' to group '$3'..."
                addUserToGroup "$2" "$3"
                shift 3
                ;;
            --removeUser)
                if [[ -z "$2" ]] || [[ -z "$3" ]] || [[ "$2" =~ ^-- ]] || [[ "$3" =~ ^-- ]]; then
                    echo "ERROR: --removeUser requires username and groupname"
                    echo "Usage: $0 --removeUser <username> <groupname>"
                    return 1
                fi
                echo "Removing user '$2' from group '$3'..."
                removeUserFromGroup "$2" "$3"
                shift 3
                ;;
            --addGroup)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-- ]]; then
                    echo "ERROR: --addGroup requires a group name"
                    echo "Usage: $0 --addGroup <groupname>"
                    return 1
                fi
                echo "Creating group '$2'..."
                sudo groupadd "$2" && echo "SUCCESS: Created group '$2'"
                shift 2
                ;;
            --deleteGroup)
                if [[ -z "$2" ]] || [[ "$2" =~ ^-- ]]; then
                    echo "ERROR: --deleteGroup requires a group name"
                    echo "Usage: $0 --deleteGroup <groupname>"
                    return 1
                fi
                echo "Deleting group '$2'..."
                deleteGroup "$2"
                shift 2
                ;;
            --viewUser)
                local username=${2:-$USER}
                echo "Viewing groups for user '$username'..."
                viewUserGroups "$username"
                if [[ -n "$2" ]] && [[ ! "$2" =~ ^-- ]]; then
                    shift 2
                else
                    shift 1
                fi
                ;;
            --viewGroups)
                clear
                echo "Viewing all system groups..."
                viewAllGroups
                shift 1
                ;;
            --info)
                clear
                showSystemInfo
                shift 1
                ;;
            --menu)
                clear
                showSystemInfo
                launchInteractiveMenu
                shift 1
                ;;
            --help)
                clear
                showUsage
                return 0
                ;;
            *)
                echo "ERROR: Unknown option '$1'"
                echo "Use '$0 --help' for usage information"
                return 1
                ;;
        esac
    done
}

function launchInteractiveMenu() {
    while true; do
        showMenu
        read -p "Choose an option [1-10]: " choice
        
        case $choice in
            1) read -p "Enter username (or press Enter for current user): " user; makeUserAdmin "${user:-$USER}" ;;
            2) read -p "Enter path to take ownership of: " path; read -p "Enter username (or press Enter for current user): " user; takeOwnership "$path" "${user:-$USER}" ;;
            3) read -p "Enter username: " user; read -p "Enter group name: " group; addUserToGroup "$user" "$group" ;;
            4) read -p "Enter username: " user; read -p "Enter group name: " group; removeUserFromGroup "$user" "$group" ;;
            5) read -p "Enter new group name: " group; sudo groupadd "$group" && echo "SUCCESS: Created group '$group'" ;;
            6) read -p "Enter group name to delete: " group; deleteGroup "$group" ;;
            7) read -p "Enter username (or press Enter for current user): " user; viewUserGroups "${user:-$USER}" ;;
            8) viewAllGroups ;;
            9) showSystemInfo ;;
            10) echo "Exiting..."; break ;;
            *) echo "Invalid option. Please choose 1-10." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

function showMenu() {
    echo ""
    echo "========================================"
    echo " System Administration Tool"
    echo "========================================"
    echo "1) Make user an admin"
    echo "2) Take ownership of files/folders"
    echo "3) Add user to group"
    echo "4) Remove user from group"
    echo "5) Create new group"
    echo "6) Delete group"
    echo "7) View user's groups"
    echo "8) View all groups"
    echo "9) Show system info"
    echo "10) Exit"
    echo "========================================"
}

################################################################################################
#### Main Execution
################################################################################################

# Parse command line arguments
parseArguments "$@"

################################################################################################
#### Quick Setup Examples (uncomment as needed)
################################################################################################

# Example 1: Make current user an admin
# makeUserAdmin

# Example 2: Make specific user an admin
# makeUserAdmin "brown"

# Example 3: Take ownership of web directory
# takeOwnership "/var/www/html"

# Example 4: Add user to docker group (common for development)
# addUserToGroup "$USER" "docker"

################################################################################################
#### Reference Links
################################################################################################

# Helpful links:
# https://www.redhat.com/sysadmin/linux-groups
# https://ubuntu.com/server/docs/how-to-use-apache2-modules
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html  
