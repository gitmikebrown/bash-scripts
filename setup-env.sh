#!/bin/bash
# File: setup-env.sh
# Author: Michael Brown
# Version: 1.1.0
# Date: February 6, 2026
# Description: Menu-driven development environment setup script for Ubuntu/Debian systems
#              Installs and configures common dev tools including Python, Node.js, Git, curl, wget,
#              make/build tools, Docker, Docker Compose, zip/unzip, Golang, PHP, AWS/Azure/GCloud CLIs,
#              Terraform, OpenSSL, OpenSSH, Composer, Laravel deps, Vim, and Postman CLI

################################################################################################
#### HOW TO USE THIS SCRIPT - Examples and Quick Reference
################################################################################################

# BASIC USAGE:
# Make the script executable first:
#   chmod +x setup-env.sh
#
# Run in interactive menu mode (shows a numbered menu with options):
# Simply run the script without any parameters - this starts the interactive menu
#   ./setup-env.sh
#
# Run with command line options:
#   ./setup-env.sh                  # Starts the interactive menu
#   ./setup-env.sh --github-clone   # Clone a GitHub repo via HTTPS
#   ./setup-env.sh --install-python         # Install Python only
#   ./setup-env.sh --install-nodejs         # Install Node.js only
#   ./setup-env.sh --install-npm            # Install npm only
#   ./setup-env.sh --install-git            # Install Git only
#   ./setup-env.sh --install-curl           # Install curl only
#   ./setup-env.sh --install-wget           # Install wget only
#   ./setup-env.sh --install-make           # Install make/build tools only
#   ./setup-env.sh --install-docker         # Install Docker only
#   ./setup-env.sh --install-docker-compose # Install Docker Compose only
#   ./setup-env.sh --install-zip            # Install zip/unzip only
#   ./setup-env.sh --install-golang         # Install Golang only
#   ./setup-env.sh --install-php            # Install PHP only
#   ./setup-env.sh --install-aws            # Install AWS CLI only
#   ./setup-env.sh --install-azure          # Install Azure CLI only
#   ./setup-env.sh --install-gcloud         # Install Google Cloud SDK only
#   ./setup-env.sh --install-terraform      # Install Terraform only
#   ./setup-env.sh --install-openssl        # Install OpenSSL only
#   ./setup-env.sh --install-openssh        # Install OpenSSH server only
#   ./setup-env.sh --install-composer       # Install Composer only
#   ./setup-env.sh --install-laravel-deps   # Install Laravel dependencies
#   ./setup-env.sh --install-vim            # Install Vim only
#   ./setup-env.sh --install-postman        # Install Postman CLI only
#   ./setup-env.sh --system-update          # Run system update and cleanup
#   ./setup-env.sh --install-packages pkg1 pkg2 ... # Install a list of packages
#   ./setup-env.sh --help           # Show help information

# COMMON SCENARIOS:
#
# 1. Interactive installation (menu-driven):
#    ./setup-env.sh
#    Then select options 1-26 from the menu (you can enter multiple numbers separated by spaces)
#
# 2. Install specific tools:
#    ./setup-env.sh --install-python
#    ./setup-env.sh --install-docker

# 3. Install Laravel dependencies:
#    ./setup-env.sh --install-laravel-deps

# MENU OPTIONS EXPLAINED:
# When you run ./setup-env.sh, you'll see a menu with these options.
# You can select one option or multiple options by entering numbers separated by spaces (e.g., 3 5 9 11 19).
# Menu labels are dynamic and may show Install/Update with color based on status.
# Green = installed and up to date; Yellow = installed but update available.
#   1. Install Python             - Installs Python 3 and pip
#   2. Install Node.js            - Installs Node.js runtime
#   3. Install npm                - Installs npm package manager
#   4. Install Golang             - Installs Go programming language
#   5. Install PHP                - Installs PHP and common extensions
#   6. Install Composer           - Installs Composer
#   7. Install Laravel Deps       - Installs Laravel dependencies
#   8. Install make               - Installs build-essential (make, gcc, g++)
#   9. Install Docker             - Installs Docker Engine
#   10. Install Docker Compose    - Installs Docker Compose (standalone)
#   11. Install AWS CLI           - Installs AWS CLI
#   12. Install Azure CLI         - Installs Azure CLI
#   13. Install Google Cloud SDK  - Installs Google Cloud SDK
#   14. Install Terraform         - Installs Terraform
#   15. Install wget              - Installs wget for file downloads
#   16. Install zip/unzip         - Installs zip and unzip utilities
#   17. Install Git               - Installs Git version control
#   18. Install curl              - Installs curl for HTTP requests
#   19. Install OpenSSL           - Installs OpenSSL
#   20. Install Postman CLI       - Installs Postman CLI
#   21. Install Vim               - Installs Vim editor
#   22. Clone GitHub Repo (HTTPS) - Clone a GitHub repository
#   23. Set Git Identity          - Configure git user.name and user.email
#   24. Show Installed Versions   - Display versions of installed tools
#   25. CLI Options               - Show command line options
#   26. Help                      - Show usage information
#   0. Exit                       - Quit the script

################################################################################################
#### Configurable Variables
################################################################################################

# Define script version
SCRIPT_VERSION="1.1.0"

# Enable or disable logging (true/false)
LOGGING_ENABLED=false
LOGFILE="/var/log/dev-setup-script.log"

# Quiet mode (suppress non-essential output)
QUIET_MODE=false

# Non-interactive mode (skip pauses for CLI usage)
NON_INTERACTIVE=false

# Git global identity
GIT_USER_NAME="gitmikebrown"
GIT_USER_EMAIL="123339553+gitmikebrown@users.noreply.github.com"

# Cache for detected package manager
DETECTED_PKG_MANAGER=""

# Terminal colors
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_BLUE="\033[0;34m"
COLOR_PURPLE="\033[0;35m"
COLOR_YELLOW="\033[0;33m"
COLOR_GRAY="\033[0;90m"
COLOR_RESET="\033[0m"

################################################################################################
#### Detect Package Manager
################################################################################################

function detectPackageManager() {
    # Return cached value if already detected
    if [ -n "$DETECTED_PKG_MANAGER" ]; then
        echo "$DETECTED_PKG_MANAGER"
        return
    fi
    
    # Detect package manager and cache the result
    if command -v apt >/dev/null 2>&1; then
        DETECTED_PKG_MANAGER="apt"
    elif command -v yum >/dev/null 2>&1; then
        DETECTED_PKG_MANAGER="yum"
    elif command -v dnf >/dev/null 2>&1; then
        DETECTED_PKG_MANAGER="dnf"
    else
        DETECTED_PKG_MANAGER="unknown"
    fi
    
    echo "$DETECTED_PKG_MANAGER"
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

################################################################################################
#### Logging Function
################################################################################################

function log() {
    if [ "$LOGGING_ENABLED" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
    fi
}

################################################################################################
#### Quiet Mode Handling
################################################################################################

function terminalOutput() {
    if [ "$QUIET_MODE" = false ]; then
        local text="$1"

        if [[ "$text" =~ ^[=]{10,}$ ]]; then
            printf "%b\n" "${COLOR_GREEN}${text}${COLOR_RESET}"
        elif [[ "$text" =~ ^\ (WARNING|Warning|CAUTION|Caution|DANGER|Danger) ]]; then
            printf "%b\n" "${COLOR_RED}${text}${COLOR_RESET}"
        elif [[ "$text" =~ ^\ (Installing|Installed|Dev\ Environment\ Setup|Database\ Setup|Help) ]]; then
            printf "%b\n" "${COLOR_GREEN}${text}${COLOR_RESET}"
        else
            printf "%b\n" "$text"
        fi
    fi
}

################################################################################################
#### Utility Functions
################################################################################################

function isWSL(){
    if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
        return 0
    fi
    if grep -qiE "(microsoft|wsl)" /proc/sys/kernel/osrelease 2>/dev/null; then
        return 0
    fi
    if [ -n "${WSL_DISTRO_NAME-}" ] || [ -n "${WSL_INTEROP-}" ]; then
        return 0
    fi
    return 1
}

function warnWslDocker(){
    if isWSL; then
        terminalOutput "This looks like a WSL environment."
        terminalOutput "Docker Engine inside WSL is not recommended for most users."
        terminalOutput "Install Docker Desktop on Windows and enable this distro instead."
        terminalOutput "Docker Desktop: Settings > Resources > WSL Integration > Enable integration."
        terminalOutput "Then select this distro (or enable default WSL distro integration)."
        terminalOutput ""
    fi
}

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

function pause(){
    if [ "$NON_INTERACTIVE" = true ]; then
        return
    fi
    local prompt="${1:-Press [Enter] to return to the menu...}"
    promptInput "$prompt"
}

function confirm(){
    promptInput "$1 [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

function ensurePackages() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    if [ "$#" -eq 0 ]; then
        return 0
    fi

    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y "$@"
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y "$@"
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y "$@"
    else
        terminalOutput "Error: Unsupported package manager"
        log "Package installation failed - unsupported package manager"
        return 1
    fi
}

################################################################################################
#### Installation Functions
################################################################################################

function installPython() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Python"
    terminalOutput "======================================"
    log "Starting Python installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv python3-dev
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y python3 python3-pip python3-devel
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y python3 python3-pip python3-devel
    else
        terminalOutput "Error: Unsupported package manager"
        log "Python installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Python installation complete!"
    python3 --version
    pip3 --version
    log "Python installation complete"
    pause
}

function installNodeJS() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Node.js and npm"
    terminalOutput "======================================"
    log "Starting Node.js installation"

    ensurePackages curl
    
    if [ "$pkgManager" = "apt" ]; then
        # Install Node.js LTS via NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    elif [ "$pkgManager" = "yum" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo yum install -y nodejs
    elif [ "$pkgManager" = "dnf" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo dnf install -y nodejs
    else
        terminalOutput "Error: Unsupported package manager"
        log "Node.js installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Node.js installation complete!"
    node --version
    if ! command -v npm >/dev/null 2>&1; then
        ensurePackages npm
    fi
    npm --version
    log "Node.js installation complete"
    pause
}

function installNpm() {
    terminalOutput "======================================"
    terminalOutput " Installing npm"
    terminalOutput "======================================"
    log "Starting npm installation"

    ensurePackages npm

    terminalOutput "npm installation complete!"
    npm --version
    log "npm installation complete"
    pause
}

function installGit() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Git"
    terminalOutput "======================================"
    log "Starting Git installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y git
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y git
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y git
    else
        terminalOutput "Error: Unsupported package manager"
        log "Git installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Git installation complete!"
    git --version
    if ! setGitIdentity; then
        pause
        return
    fi
    log "Git installation complete"
    pause
}

function setGitIdentity() {
    local targetUser="$USER"
    local targetHome="$HOME"
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        targetUser="$SUDO_USER"
        targetHome=$(getent passwd "$targetUser" | cut -d: -f6)
        if [ -z "$targetHome" ]; then
            targetHome="$HOME"
        fi
    fi

    local gitConfigCmd=(git config --global)
    if [ "$targetUser" != "$USER" ]; then
        gitConfigCmd=(sudo -u "$targetUser" env HOME="$targetHome" git config --global)
    fi

    if [ "$NON_INTERACTIVE" = true ]; then
        "${gitConfigCmd[@]}" user.name "$GIT_USER_NAME"
        "${gitConfigCmd[@]}" user.email "$GIT_USER_EMAIL"
        return 0
    fi

    if ! confirm "Would you like to set your Git identity now?"; then
        terminalOutput "Skipped Git identity setup. You can set it later with:"
        terminalOutput "  git config --global user.name \"Your Name\""
        terminalOutput "  git config --global user.email \"you@example.com\""
        terminalOutput "To change the defaults, edit GIT_USER_NAME/GIT_USER_EMAIL near the top of this script."
        log "Git identity setup skipped"
        return 1
    fi

    local gitName="$GIT_USER_NAME"
    local gitEmail="$GIT_USER_EMAIL"

    terminalOutput ""
    terminalOutput "Git identity defaults:"
    terminalOutput "  Name:  $gitName"
    terminalOutput "  Email: $gitEmail"

    if confirm "Is this your info?"; then
        "${gitConfigCmd[@]}" user.name "$gitName"
        "${gitConfigCmd[@]}" user.email "$gitEmail"
        return 0
    fi

    terminalOutput "You can update it now or later with:"
    terminalOutput "  git config --global user.name \"Your Name\""
    terminalOutput "  git config --global user.email \"you@example.com\""
    terminalOutput "To change the defaults, edit GIT_USER_NAME/GIT_USER_EMAIL near the top of this script."

    promptInput "Enter your name (leave blank to skip): " gitNameInput
    promptInput "Enter your email (leave blank to skip): " gitEmailInput

    if [ -n "$gitNameInput" ]; then
        gitName="$gitNameInput"
    fi

    if [ -n "$gitEmailInput" ]; then
        gitEmail="$gitEmailInput"
    fi

    if [ -n "$gitNameInput" ] || [ -n "$gitEmailInput" ]; then
        if [ -n "$gitName" ]; then
            "${gitConfigCmd[@]}" user.name "$gitName"
        fi
        if [ -n "$gitEmail" ]; then
            "${gitConfigCmd[@]}" user.email "$gitEmail"
        fi
    fi
    return 0
}

function setGitIdentityMenu() {
    clear
    terminalOutput "======================================"
    terminalOutput " Set Git Identity"
    terminalOutput "======================================"

    if ! command -v git >/dev/null 2>&1; then
        terminalOutput "Git is not installed."
        if confirm "Install Git now?"; then
            installGit
        else
            terminalOutput "Canceled."
        fi
        return 0
    fi

    setGitIdentity
    pause
}

function cloneGitHubRepo() {
    terminalOutput "======================================"
    terminalOutput " GitHub HTTPS Clone"
    terminalOutput "======================================"
    terminalOutput "Tip: Type 'q' at any prompt to cancel."

    if ! command -v git >/dev/null 2>&1; then
        terminalOutput "Git is not installed."
        if confirm "Install Git now?"; then
            installGit
        else
            terminalOutput "Canceled."
            return 1
        fi
    fi

    local repoUrl=""
    local repoName=""
    local defaultDir=""
    local targetDir=""
    local confirmAction=""
    local action=""

    while true; do
        promptInput "Enter the HTTPS repo URL (e.g., https://github.com/owner/repo.git): " repoUrl

        if [ "$repoUrl" = "q" ] || [ "$repoUrl" = "Q" ]; then
            terminalOutput "Canceled."
            return 0
        fi

        if [ -z "$repoUrl" ]; then
            terminalOutput "Please enter a URL or 'q' to cancel."
            continue
        fi

        if [[ "$repoUrl" != https://* ]]; then
            terminalOutput "URL must start with https://"
            continue
        fi

        break
    done

    repoName=$(basename "$repoUrl")
    repoName=${repoName%.git}

    if [ -z "$repoName" ]; then
        terminalOutput "Could not determine repo name from URL."
        return 1
    fi

    defaultDir="$repoName"
    while true; do
        promptInput "Target folder [${defaultDir}]: " targetDir

        if [ "$targetDir" = "q" ] || [ "$targetDir" = "Q" ]; then
            terminalOutput "Canceled."
            return 0
        fi

        if [ -z "$targetDir" ]; then
            targetDir="$defaultDir"
        fi

        if [ -e "$targetDir" ]; then
            terminalOutput "Target path '$targetDir' already exists. Choose another folder or 'q' to cancel."
            targetDir=""
            continue
        fi

        break
    done

    terminalOutput "About to clone:"
    terminalOutput "  URL:  $repoUrl"
    terminalOutput "  Dest: $targetDir"

    while true; do
        promptInput "Continue? [y/N]: " confirmAction
        if ! [[ "$confirmAction" =~ ^[Yy]$ ]]; then
            terminalOutput "Canceled."
            return 0
        fi

        if git clone "$repoUrl" "$targetDir"; then
            terminalOutput "Clone complete."
            terminalOutput "Next steps:"
            terminalOutput "  cd \"$targetDir\""
            terminalOutput "  git status"
            terminalOutput ""
            terminalOutput "Tip: If prompted for credentials, use a GitHub token or sign in via VS Code."
            return 0
        fi

        terminalOutput "Clone failed. Choose an option:"
        terminalOutput "  1) Retry clone"
        terminalOutput "  2) Change URL"
        terminalOutput "  3) Change target folder"
        terminalOutput "  4) Cancel"

        promptInput "Select [1-4]: " action
        case "$action" in
            1) ;;
            2)
                repoUrl=""
                while true; do
                    promptInput "Enter the HTTPS repo URL (e.g., https://github.com/owner/repo.git): " repoUrl
                    if [ "$repoUrl" = "q" ] || [ "$repoUrl" = "Q" ]; then
                        terminalOutput "Canceled."
                        return 0
                    fi
                    if [ -z "$repoUrl" ]; then
                        terminalOutput "Please enter a URL or 'q' to cancel."
                        continue
                    fi
                    if [[ "$repoUrl" != https://* ]]; then
                        terminalOutput "URL must start with https://"
                        continue
                    fi
                    break
                done

                repoName=$(basename "$repoUrl")
                repoName=${repoName%.git}
                if [ -z "$repoName" ]; then
                    terminalOutput "Could not determine repo name from URL."
                    return 1
                fi
                defaultDir="$repoName"
                targetDir=""
                ;;
            3)
                targetDir=""
                while true; do
                    promptInput "Target folder [${defaultDir}]: " targetDir
                    if [ "$targetDir" = "q" ] || [ "$targetDir" = "Q" ]; then
                        terminalOutput "Canceled."
                        return 0
                    fi
                    if [ -z "$targetDir" ]; then
                        targetDir="$defaultDir"
                    fi
                    if [ -e "$targetDir" ]; then
                        terminalOutput "Target path '$targetDir' already exists. Choose another folder or 'q' to cancel."
                        targetDir=""
                        continue
                    fi
                    break
                done
                ;;
            4)
                terminalOutput "Canceled."
                return 0
                ;;
            *)
                terminalOutput "Invalid option."
                ;;
        esac
    done
}

function installCurl() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing curl"
    terminalOutput "======================================"
    log "Starting curl installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y curl
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y curl
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y curl
    else
        terminalOutput "Error: Unsupported package manager"
        log "curl installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "curl installation complete!"
    curl --version
    log "curl installation complete"
    pause
}

function installMake() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing make and build tools"
    terminalOutput "======================================"
    log "Starting build-essential installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y build-essential
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y make gcc gcc-c++
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y make gcc gcc-c++
    else
        terminalOutput "Error: Unsupported package manager"
        log "build-essential installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "make and build tools installation complete!"
    make --version
    gcc --version
    log "build-essential installation complete"
    pause
}

function runSystemUpdate() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Running System Update"
    terminalOutput "======================================"
    log "Starting system update"

    if [ "$pkgManager" = "apt" ]; then
        sudo apt -y -qq update
        sudo apt -y -qq upgrade
        sudo apt -y -qq dist-upgrade
        sudo apt -y -qq autoremove
        sudo apt -y -qq autoclean
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum -y update
        sudo yum -y autoremove || true
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf -y upgrade
        sudo dnf -y autoremove || true
    else
        terminalOutput "Error: Unsupported package manager"
        log "System update failed - unsupported package manager"
        return 1
    fi

    terminalOutput "System update complete!"
    log "System update complete"
}

function installDocker() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Docker"
    terminalOutput "======================================"
    log "Starting Docker installation"
    
    if [ "$pkgManager" = "apt" ]; then
        # Remove old versions
        sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null
        
        # Install prerequisites
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg lsb-release
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Add current user to docker group
        sudo usermod -aG docker $SUDO_USER 2>/dev/null || sudo usermod -aG docker $USER
        
    elif [ "$pkgManager" = "yum" ]; then
        # Remove old versions
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $SUDO_USER 2>/dev/null || sudo usermod -aG docker $USER
        
    elif [ "$pkgManager" = "dnf" ]; then
        # Remove old versions
        sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $SUDO_USER 2>/dev/null || sudo usermod -aG docker $USER
    else
        terminalOutput "Error: Unsupported package manager"
        log "Docker installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Docker installation complete!"
    terminalOutput "Note: You may need to log out and back in for Docker group changes to take effect."
    docker --version
    log "Docker installation complete"
    pause
}

function installZip() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing zip and unzip"
    terminalOutput "======================================"
    log "Starting zip/unzip installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y zip unzip
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y zip unzip
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y zip unzip
    else
        terminalOutput "Error: Unsupported package manager"
        log "zip/unzip installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "zip and unzip installation complete!"
    zip --version
    log "zip/unzip installation complete"
    pause
}

function installGolang() {
    terminalOutput "======================================"
    terminalOutput " Installing Golang"
    terminalOutput "======================================"
    log "Starting Golang installation"

    ensurePackages curl
    
    # Detect architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv6l) ARCH="armv6l" ;;
        *) 
            terminalOutput "Error: Unsupported architecture: $ARCH"
            log "Golang installation failed - unsupported architecture: $ARCH"
            pause
            return 1
            ;;
    esac
    
    # Get latest Go version from official API
    terminalOutput "Fetching latest Go version..."
    local GO_VERSION=$(curl -s https://go.dev/dl/?mode=json | grep -m 1 -E '"version"[[:space:]]*:[[:space:]]*"[^"]+"' | cut -d'"' -f4)
    
    if [ -z "$GO_VERSION" ]; then
        terminalOutput "Error: Failed to fetch latest Go version"
        log "Golang installation failed - could not fetch version"
        pause
        return 1
    fi
    
    terminalOutput "Latest Go version: $GO_VERSION"
    local GO_TARBALL="${GO_VERSION}.linux-${ARCH}.tar.gz"
    local GO_URL="https://go.dev/dl/${GO_TARBALL}"
    
    # Remove existing Go installation
    terminalOutput "Removing any existing Go installation..."
    sudo rm -rf /usr/local/go
    
    # Download and install Go
    terminalOutput "Downloading Go from ${GO_URL}..."
    cd /tmp
    curl -LO "$GO_URL"
    
    if [ ! -f "$GO_TARBALL" ]; then
        terminalOutput "Error: Failed to download Go"
        log "Golang installation failed - download failed"
        pause
        return 1
    fi
    
    terminalOutput "Installing Go to /usr/local/go..."
    sudo tar -C /usr/local -xzf "$GO_TARBALL"
    rm -f "$GO_TARBALL"
    
    # Add Go to PATH if not already present
    local TARGET_HOME="$HOME"
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        TARGET_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    fi

    if [ -z "$TARGET_HOME" ]; then
        TARGET_HOME="$HOME"
    fi

    local PROFILE_FILES=("/etc/profile" "$TARGET_HOME/.profile" "$TARGET_HOME/.bashrc")
    local GO_PATH_ENTRY='export PATH=$PATH:/usr/local/go/bin'
    
    for PROFILE in "${PROFILE_FILES[@]}"; do
        if [ -f "$PROFILE" ] && ! grep -q "/usr/local/go/bin" "$PROFILE"; then
            echo "" >> "$PROFILE"
            echo "# Go programming language" >> "$PROFILE"
            echo "$GO_PATH_ENTRY" >> "$PROFILE"
            terminalOutput "Added Go to PATH in $PROFILE"
        fi
    done
    
    # Export for current session
    export PATH=$PATH:/usr/local/go/bin
    
    terminalOutput "======================================"
    terminalOutput "Golang installation complete!"
    terminalOutput "======================================"
    /usr/local/go/bin/go version
    terminalOutput ""
    terminalOutput "Note: You may need to restart your terminal or run 'source ~/.profile' for PATH changes to take effect."
    log "Golang installation complete - $GO_VERSION"
    pause
}

function installPHP() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing PHP"
    terminalOutput "======================================"
    log "Starting PHP installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y php php-cli php-common php-mbstring php-xml php-curl php-zip php-mysql php-json
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y php php-cli php-common php-mbstring php-xml php-curl php-zip php-mysqlnd php-json
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y php php-cli php-common php-mbstring php-xml php-curl php-zip php-mysqlnd php-json
    else
        terminalOutput "Error: Unsupported package manager"
        log "PHP installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "PHP installation complete!"
    php --version
    log "PHP installation complete"
    pause
}

function installDockerCompose() {
    terminalOutput "======================================"
    terminalOutput " Installing Docker Compose (standalone)"
    terminalOutput "======================================"
    log "Starting Docker Compose installation"

    ensurePackages curl
    
    # Get latest Docker Compose version
    terminalOutput "Fetching latest Docker Compose version..."
    local COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$COMPOSE_VERSION" ]; then
        terminalOutput "Error: Failed to fetch latest Docker Compose version"
        log "Docker Compose installation failed - could not fetch version"
        pause
        return 1
    fi
    
    terminalOutput "Latest Docker Compose version: $COMPOSE_VERSION"
    
    # Detect architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        armv7l) ARCH="armv7" ;;
        *) 
            terminalOutput "Error: Unsupported architecture: $ARCH"
            log "Docker Compose installation failed - unsupported architecture"
            pause
            return 1
            ;;
    esac
    
    # Download and install
    local COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"
    terminalOutput "Downloading Docker Compose from GitHub..."
    sudo curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    terminalOutput "Docker Compose installation complete!"
    docker-compose --version
    log "Docker Compose installation complete - $COMPOSE_VERSION"
    pause
}

function installOpenSSHServer() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing OpenSSH Server"
    terminalOutput "======================================"
    log "Starting OpenSSH server installation"

    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y openssh-server
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y openssh-server
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y openssh-server
    else
        terminalOutput "Error: Unsupported package manager"
        log "OpenSSH installation failed - unsupported package manager"
        return 1
    fi

    # Configure SSH server
    sudo mkdir -p /var/run/sshd
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

    if command -v ufw >/dev/null 2>&1; then
        sudo ufw allow ssh
    fi

    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now ssh 2>/dev/null || sudo systemctl enable --now sshd
    else
        sudo service ssh start 2>/dev/null || sudo service sshd start
    fi

    terminalOutput "OpenSSH server installation complete!"
    log "OpenSSH server installation complete"
}

function installWget() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing wget"
    terminalOutput "======================================"
    log "Starting wget installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y wget
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y wget
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y wget
    else
        terminalOutput "Error: Unsupported package manager"
        log "wget installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "wget installation complete!"
    wget --version | head -n 1
    log "wget installation complete"
    pause
}

function installAWSCLI() {
    terminalOutput "======================================"
    terminalOutput " Installing AWS CLI"
    terminalOutput "======================================"
    log "Starting AWS CLI installation"

    ensurePackages curl unzip
    
    # Detect architecture
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        *) 
            terminalOutput "Error: Unsupported architecture: $ARCH"
            log "AWS CLI installation failed - unsupported architecture"
            pause
            return 1
            ;;
    esac
    
    terminalOutput "Downloading AWS CLI v2..."
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip"
    
    if [ ! -f "awscliv2.zip" ]; then
        terminalOutput "Error: Failed to download AWS CLI"
        log "AWS CLI installation failed - download failed"
        pause
        return 1
    fi
    
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    rm -rf aws awscliv2.zip
    
    terminalOutput "AWS CLI installation complete!"
    aws --version
    log "AWS CLI installation complete"
    pause
}

function installAzureCLI() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Azure CLI"
    terminalOutput "======================================"
    log "Starting Azure CLI installation"
    
    if [ "$pkgManager" = "apt" ]; then
        # Install prerequisites
        sudo apt update
        sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg
        
        # Download and install Microsoft signing key
        sudo mkdir -p /etc/apt/keyrings
        curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
        
        # Add repository
        AZ_DIST=$(lsb_release -cs)
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
        
        # Install Azure CLI
        sudo apt update
        sudo apt install -y azure-cli
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/azure-cli.repo <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        sudo yum install -y azure-cli
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/azure-cli.repo <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        sudo dnf install -y azure-cli
    else
        terminalOutput "Error: Unsupported package manager"
        log "Azure CLI installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Azure CLI installation complete!"
    az version
    log "Azure CLI installation complete"
    pause
}

function installGoogleCloudSDK() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Google Cloud SDK"
    terminalOutput "======================================"
    log "Starting Google Cloud SDK installation"

    ensurePackages curl gnupg
    
    if [ "$pkgManager" = "apt" ]; then
        # Add Cloud SDK repo
        sudo mkdir -p /usr/share/keyrings
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        
        # Import Google Cloud public key (overwrite if it exists)
        sudo rm -f /usr/share/keyrings/cloud.google.gpg
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
        
        # Install SDK
        sudo apt update
        sudo apt install -y google-cloud-sdk
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo tee /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        sudo yum install -y google-cloud-sdk
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo tee /etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        sudo dnf install -y google-cloud-sdk
    else
        terminalOutput "Error: Unsupported package manager"
        log "Google Cloud SDK installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Google Cloud SDK installation complete!"
    gcloud version
    log "Google Cloud SDK installation complete"
    pause
}

function installTerraform() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Terraform"
    terminalOutput "======================================"
    log "Starting Terraform installation"

    ensurePackages wget
    
    if [ "$pkgManager" = "apt" ]; then
        # Add HashiCorp GPG key
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        
        # Add HashiCorp repository
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        
        # Install Terraform
        sudo apt update
        sudo apt install -y terraform
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum install -y terraform
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        sudo dnf install -y terraform
    else
        terminalOutput "Error: Unsupported package manager"
        log "Terraform installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Terraform installation complete!"
    terraform --version
    log "Terraform installation complete"
    pause
}

function installOpenSSL() {
    terminalOutput "======================================"
    terminalOutput " Installing OpenSSL"
    terminalOutput "======================================"
    log "Starting OpenSSL installation"

    ensurePackages openssl

    terminalOutput "OpenSSL installation complete!"
    openssl version
    log "OpenSSL installation complete"
    pause
}

function installComposer() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing Composer"
    terminalOutput "======================================"
    log "Starting Composer installation"

    ensurePackages curl php-cli

    if [ "$pkgManager" = "apt" ]; then
        sudo apt install -y composer
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y composer
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y composer
    else
        terminalOutput "Error: Unsupported package manager"
        log "Composer installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "Composer installation complete!"
    COMPOSER_ALLOW_SUPERUSER=1 composer --version
    log "Composer installation complete"
    pause
}

function installLaravelDeps() {
    terminalOutput "======================================"
    terminalOutput " Installing Laravel Dependencies"
    terminalOutput "======================================"
    log "Starting Laravel dependencies installation"

    installPHP
    installNodeJS
    installComposer
    installZip
    ensurePackages php-xml php-mbstring php-curl php-zip php-intl php-bcmath php-gd

    terminalOutput "Laravel dependencies installation complete!"
    log "Laravel dependencies installation complete"
    pause
}

function installVim() {
    terminalOutput "======================================"
    terminalOutput " Installing Vim"
    terminalOutput "======================================"
    log "Starting Vim installation"

    ensurePackages vim

    terminalOutput "Vim installation complete!"
    vim --version | head -n 1
    log "Vim installation complete"
    pause
}

function installPostman() {
    terminalOutput "======================================"
    terminalOutput " Installing Postman CLI"
    terminalOutput "======================================"
    log "Starting Postman CLI installation"

    if ! command -v npm >/dev/null 2>&1; then
        installNodeJS
    fi

    sudo npm install -g postman-cli

    # Ensure the postman command uses WSL Node.js (avoid Windows-side binary)
    local NODE_PATH
    NODE_PATH=$(command -v node)
    if [ -z "$NODE_PATH" ]; then
        terminalOutput "Error: Node.js not found after installation."
        log "Postman CLI installation failed - node not found"
        pause
        return 1
    fi

    local POSTMAN_WRAPPER="/usr/local/bin/postman"
    local POSTMAN_JS="/usr/local/lib/node_modules/postman-cli/bin/postman.js"

    if [ -f "$POSTMAN_WRAPPER" ] && ! grep -q "postman-cli/bin/postman.js" "$POSTMAN_WRAPPER" 2>/dev/null; then
        sudo rm -f "$POSTMAN_WRAPPER"
    fi

    sudo tee "$POSTMAN_WRAPPER" >/dev/null <<EOF
#!/usr/bin/env bash
exec "$NODE_PATH" "$POSTMAN_JS" "\$@"
EOF
    sudo chmod +x "$POSTMAN_WRAPPER"

    # Clear shell command cache so the new wrapper is picked up
    hash -r 2>/dev/null || true

    terminalOutput "Postman CLI installation complete!"
    postman --version
    log "Postman CLI installation complete"
    pause
}

function installPackagesFromList() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    if [ "$#" -eq 0 ]; then
        terminalOutput "Error: No packages provided."
        log "Package list installation failed - no packages provided"
        return 1
    fi

    terminalOutput "======================================"
    terminalOutput " Installing Package List"
    terminalOutput "======================================"
    log "Starting package list installation: $*"

    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y "$@"
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y "$@"
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y "$@"
    else
        terminalOutput "Error: Unsupported package manager"
        log "Package list installation failed - unsupported package manager"
        return 1
    fi

    terminalOutput "Package list installation complete!"
    log "Package list installation complete"
}

function printGroupHeader(){
    local title="$1"
    terminalOutput "${COLOR_BLUE}----- ${title} -----${COLOR_RESET}"
}

function printStatusLine(){
    local label="$1"
    local value="$2"
    local installed="$3"
    local tabs="${4:-2}"
    local displayLabel="${COLOR_PURPLE}${label}${COLOR_RESET}"
    local displayValue="$value"
    if [ "$installed" = "1" ]; then
        displayValue="${COLOR_YELLOW}${value}${COLOR_RESET}"
    else
        displayValue="${COLOR_GRAY}${value}${COLOR_RESET}"
    fi
    if [ "$tabs" -eq 0 ]; then
        printf "%b %b\n" "$displayLabel" "$displayValue"
    elif [ "$tabs" -eq 1 ]; then
        printf "%b\t%b\n" "$displayLabel" "$displayValue"
    else
        printf "%b\t\t%b\n" "$displayLabel" "$displayValue"
    fi
}

function normalizeVersion(){
    local version="$1"
    version=${version#v}
    version=${version#go}
    version=${version##*:}
    version=${version%%-*}
    echo "$version"
}

function isVersionNewer(){
    local current="$1"
    local latest="$2"
    if [ -z "$current" ] || [ -z "$latest" ]; then
        return 1
    fi

    if [ "$current" = "$latest" ]; then
        return 1
    fi

    local sorted
    sorted=$(printf "%s\n%s\n" "$current" "$latest" | sort -V | tail -n 1)
    [ "$sorted" = "$latest" ]
}

function getVersionStatus(){
    local current="$1"
    local latest="$2"
    if [ -z "$current" ]; then
        echo "not-installed"
        return
    fi

    if [ -z "$latest" ]; then
        echo "installed"
        return
    fi

    if isVersionNewer "$current" "$latest"; then
        echo "update-available"
    else
        echo "up-to-date"
    fi
}

function formatMenuLabel(){
    local base="$1"
    local status="$2"
    local color=""
    local text=""
    case "$status" in
        up-to-date)
            color="$COLOR_GREEN"
            text="${base} (Up to date)"
            ;;
        update-available)
            color="$COLOR_YELLOW"
            text="Update ${base}"
            ;;
        installed)
            color="$COLOR_GREEN"
            text="${base} (Installed)"
            ;;
        *)
            text="Install ${base}"
            ;;
    esac
    printf "%b%s%b" "$color" "$text" "$COLOR_RESET"
}

function getAptCandidateVersion(){
    local pkg="$1"
    apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}'
}

function getPackageInstalledVersion(){
    local pkg="$1"
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" = "apt" ]; then
        dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null
    elif [ "$pkgManager" = "yum" ] || [ "$pkgManager" = "dnf" ]; then
        rpm -q --qf '%{VERSION}-%{RELEASE}' "$pkg" 2>/dev/null
    fi
}

function getRpmUpdateVersion(){
    local pkg="$1"
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" != "yum" ] && [ "$pkgManager" != "dnf" ]; then
        return
    fi

    $pkgManager -q check-update "$pkg" 2>/dev/null | awk -v p="$pkg" '$1 ~ ("^"p"(\\.|$)") {print $2; exit}'
}

function getPackageLatestVersion(){
    local pkg="$1"
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" = "apt" ]; then
        getAptCandidateVersion "$pkg"
    elif [ "$pkgManager" = "yum" ] || [ "$pkgManager" = "dnf" ]; then
        getRpmUpdateVersion "$pkg"
    fi
}

function getGoLatestVersion(){
    if ! command -v curl >/dev/null 2>&1; then
        return
    fi
    curl -s https://go.dev/dl/?mode=json | grep -m 1 -E '"version"[[:space:]]*:[[:space:]]*"go[^"]+"' | cut -d'"' -f4 | sed 's/^go//'
}

function getNodeLtsVersion(){
    if ! command -v curl >/dev/null 2>&1; then
        return
    fi

    curl -s https://nodejs.org/dist/index.json | \
        awk '/"version":/ {v=$0} /"lts":/ {if ($0 !~ /"lts": (null|false)/) {print v; exit}}' | \
        sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"v([^\"]+)".*/\1/'
}

function getDockerComposeLatestVersion(){
    if ! command -v curl >/dev/null 2>&1; then
        return
    fi
    curl -s https://api.github.com/repos/docker/compose/releases/latest | \
        grep -m 1 '"tag_name"' | sed -E 's/.*"v?([^\"]+)".*/\1/'
}

function getNpmLatestVersion(){
    local pkg="$1"
    if ! command -v npm >/dev/null 2>&1; then
        return
    fi
    npm view "$pkg" version 2>/dev/null | head -n 1
}

function isLaravelDepsInstalled(){
    command -v php >/dev/null 2>&1 && \
    command -v composer >/dev/null 2>&1 && \
    command -v node >/dev/null 2>&1 && \
    command -v zip >/dev/null 2>&1 && \
    command -v unzip >/dev/null 2>&1
}

function normalizeVersion(){
    local version="$1"
    version=${version#v}
    version=${version#go}
    version=${version##*:}
    version=${version%%-*}
    echo "$version"
}

function isVersionNewer(){
    local current="$1"
    local latest="$2"
    if [ -z "$current" ] || [ -z "$latest" ]; then
        return 1
    fi

    if [ "$current" = "$latest" ]; then
        return 1
    fi

    local sorted
    sorted=$(printf "%s\n%s\n" "$current" "$latest" | sort -V | tail -n 1)
    [ "$sorted" = "$latest" ]
}

function formatUpdateNote(){
    local current="$1"
    local latest="$2"
    if isVersionNewer "$current" "$latest"; then
        printf " (latest %s)" "$latest"
    fi
}

function getAptCandidateVersion(){
    local pkg="$1"
    apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}'
}

function getRpmUpdateVersion(){
    local pkg="$1"
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" != "yum" ] && [ "$pkgManager" != "dnf" ]; then
        return
    fi

    $pkgManager -q check-update "$pkg" 2>/dev/null | awk -v p="$pkg" '$1 ~ ("^"p"(\\.|$)") {print $2; exit}'
}

function getPackageLatestVersion(){
    local pkg="$1"
    local pkgManager
    pkgManager=$(detectPackageManager)
    if [ "$pkgManager" = "apt" ]; then
        getAptCandidateVersion "$pkg"
    elif [ "$pkgManager" = "yum" ] || [ "$pkgManager" = "dnf" ]; then
        getRpmUpdateVersion "$pkg"
    fi
}

function getGoLatestVersion(){
    if ! command -v curl >/dev/null 2>&1; then
        return
    fi
    curl -s https://go.dev/dl/?mode=json | grep -m 1 -E '"version"[[:space:]]*:[[:space:]]*"go[^"]+"' | cut -d'"' -f4 | sed 's/^go//'
}

function getNodeLtsVersion(){
    if ! command -v curl >/dev/null 2>&1; then
        return
    fi

    curl -s https://nodejs.org/dist/index.json | \
        awk '/"version":/ {v=$0} /"lts":/ {if ($0 !~ /"lts": (null|false)/) {print v; exit}}' | \
        sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"v([^\"]+)".*/\1/'
}

function showVersions() {
    clear
    terminalOutput "======================================"
    terminalOutput " Installed Tool Versions"
    terminalOutput "======================================"
    terminalOutput ""
    printGroupHeader "Language Packages"
    if command -v python3 >/dev/null 2>&1; then
        local pythonCurrent
        local pythonLatest
        local pythonNote
        pythonCurrent=$(python3 --version | awk '{print $2}')
        pythonLatest=$(getPackageLatestVersion "python3")
        pythonNote=$(formatUpdateNote "$(normalizeVersion "$pythonCurrent")" "$(normalizeVersion "$pythonLatest")")
        printStatusLine "Python->" "$(python3 --version)${pythonNote}" 1 1
    else
        printStatusLine "Python->" "Python: Not installed" 0
    fi
    if command -v pip3 >/dev/null 2>&1; then
        local pipCurrent
        local pipLatest
        local pipNote
        pipCurrent=$(pip3 --version | awk '{print $2}')
        pipLatest=$(getPackageLatestVersion "python3-pip")
        pipNote=$(formatUpdateNote "$(normalizeVersion "$pipCurrent")" "$(normalizeVersion "$pipLatest")")
        printStatusLine "Python->" "$(pip3 --version)${pipNote}" 1 1
    else
        printStatusLine "Python->" "pip3: Not installed" 0 1
    fi
    if command -v node >/dev/null 2>&1; then
        local nodeCurrent
        local nodeLatest
        local nodeNote
        nodeCurrent=$(getPackageInstalledVersion "nodejs")
        if [ -z "$nodeCurrent" ]; then
            nodeCurrent=$(node --version | sed 's/^v//')
        fi
        nodeLatest=$(getPackageLatestVersion "nodejs")
        nodeNote=$(formatUpdateNote "$(normalizeVersion "$nodeCurrent")" "$(normalizeVersion "$nodeLatest")")
        printStatusLine "Node.js->" "$(node --version)${nodeNote}" 1
    else
        printStatusLine "Node.js->" "Node.js: Not installed" 0 1
    fi
    if command -v npm >/dev/null 2>&1; then
        local npmCurrent
        local npmLatest
        local npmNote
        npmCurrent=$(getPackageInstalledVersion "npm")
        if [ -z "$npmCurrent" ]; then
            npmCurrent=$(npm --version)
        fi
        npmLatest=$(getPackageLatestVersion "npm")
        npmNote=$(formatUpdateNote "$(normalizeVersion "$npmCurrent")" "$(normalizeVersion "$npmLatest")")
        printStatusLine "npm->" "$(npm --version)${npmNote}" 1 1
    else
        printStatusLine "npm->" "npm: Not installed" 0 1
    fi
    if command -v go >/dev/null 2>&1; then
        local goCurrent
        local goLatest
        local goNote
        goCurrent=$(go version | awk '{print $3}' | sed 's/^go//')
        goLatest=$(getGoLatestVersion)
        goNote=$(formatUpdateNote "$(normalizeVersion "$goCurrent")" "$(normalizeVersion "$goLatest")")
        printStatusLine "Golang->" "$(go version)${goNote}" 1
    else
        printStatusLine "Golang->" "Golang: Not installed" 0 1
    fi
    if command -v php >/dev/null 2>&1; then
        local phpCurrent
        local phpLatest
        local phpNote
        phpCurrent=$(php --version | head -n 1 | awk '{print $2}')
        phpLatest=$(getPackageLatestVersion "php")
        phpNote=$(formatUpdateNote "$(normalizeVersion "$phpCurrent")" "$(normalizeVersion "$phpLatest")")
        printStatusLine "PHP->" "$(php --version | head -n 1)${phpNote}" 1
    else
        printStatusLine "PHP->" "PHP: Not installed" 0
    fi

    terminalOutput ""
    printGroupHeader "Build Tools"
    if command -v make >/dev/null 2>&1; then
        printStatusLine "Makefile->" "$(make --version | head -n 1)" 1
    else
        printStatusLine "Makefile->" "make: Not installed" 0 1
    fi
    if command -v gcc >/dev/null 2>&1; then
        printStatusLine "GCC->" "$(gcc --version | head -n 1)" 1
    else
        printStatusLine "GCC->" "gcc: Not installed" 0
    fi

    terminalOutput ""
    printGroupHeader "Containers"
    if command -v docker >/dev/null 2>&1; then
        printStatusLine "Docker->" "$(docker --version)" 1
    else
        printStatusLine "Docker->" "Docker: Not installed" 0 1
    fi
    if docker compose version >/dev/null 2>&1; then
        printStatusLine "Docker Compose->" "$(docker compose version)" 1
    elif command -v docker-compose >/dev/null 2>&1; then
        printStatusLine "Docker Compose->" "$(docker-compose --version)" 1
    else
        printStatusLine "Docker Compose->" "Docker Compose: Not installed" 0 0
    fi

    terminalOutput ""
    printGroupHeader "Cloud"
    if command -v aws >/dev/null 2>&1; then
        printStatusLine "AWS->" "$(aws --version 2>&1)" 1
    else
        printStatusLine "AWS->" "AWS CLI: Not installed" 0
    fi
    if command -v az >/dev/null 2>&1; then
        printStatusLine "Azure->" "$(az version --output tsv | head -n 1)" 1
    else
        printStatusLine "Azure->" "Azure CLI: Not installed" 0
    fi
    if command -v gcloud >/dev/null 2>&1; then
        printStatusLine "Google SDK->" "$(gcloud version | head -n 1)" 1
    else
        printStatusLine "Google SDK->" "Google Cloud SDK: Not installed" 0 1
    fi
    if command -v terraform >/dev/null 2>&1; then
        printStatusLine "Terraform->" "$(terraform --version | head -n 1)" 1
    else
        printStatusLine "Terraform->" "Terraform: Not installed" 0 1
    fi

    terminalOutput ""
    printGroupHeader "File Management"
    if command -v wget >/dev/null 2>&1; then
        printStatusLine "wget->" "$(wget --version | head -n 1)" 1
    else
        printStatusLine "wget->" "wget: Not installed" 0
    fi
    if command -v zip >/dev/null 2>&1; then
        printStatusLine "zip->" "$(zip --version | head -n 1)" 1
    else
        printStatusLine "zip->" "zip: Not installed" 0
    fi
    if command -v git >/dev/null 2>&1; then
        printStatusLine "Git->" "$(git --version)" 1
    else
        printStatusLine "Git->" "Git: Not installed" 0
    fi
    if command -v curl >/dev/null 2>&1; then
        printStatusLine "curl->" "$(curl --version | head -n 1)" 1
    else
        printStatusLine "curl->" "curl: Not installed" 0
    fi

    terminalOutput ""
    printGroupHeader "Key Management"
    if command -v openssl >/dev/null 2>&1; then
        printStatusLine "OpenSSL->" "$(openssl version)" 1 1
    else
        printStatusLine "OpenSSL->" "OpenSSL: Not installed" 0
    fi

    terminalOutput ""
    printGroupHeader "API Management"
    if command -v postman >/dev/null 2>&1; then
        printStatusLine "Postman CLI->" "$(postman --version)" 1
    else
        printStatusLine "Postman CLI->" "Postman CLI: Not installed" 0 1
    fi
    
    terminalOutput "======================================"
    pause
}

################################################################################################
#### Help Menu
################################################################################################

function showHelp(){
    local mode="$1"
    clear
    terminalOutput "Development Environment Setup Script - Version $SCRIPT_VERSION"
    terminalOutput ""
    terminalOutput "Menu Options (enter one or more numbers separated by spaces, e.g., 3 5 9 11 19):"
    terminalOutput "  1)  Install Python             - Python 3, pip, and development tools"
    terminalOutput "  2)  Install Node.js            - Node.js LTS runtime"
    terminalOutput "  3)  Install npm                - Node package manager"
    terminalOutput "  4)  Install Golang             - Go programming language"
    terminalOutput "  5)  Install PHP                - PHP and common extensions"
    terminalOutput "  6)  Install Composer           - Install Composer"
    terminalOutput "  7)  Install Laravel Deps       - Install Laravel dependencies"
    terminalOutput "  8)  Install make               - Build tools (make, gcc, g++)"
    terminalOutput "  9)  Install Docker             - Docker Engine"
    terminalOutput "  10) Install Docker Compose     - Docker Compose (standalone)"
    terminalOutput "  11) Install AWS CLI            - Amazon Web Services CLI"
    terminalOutput "  12) Install Azure CLI          - Microsoft Azure CLI"
    terminalOutput "  13) Install Google Cloud SDK   - Google Cloud Platform tools"
    terminalOutput "  14) Install Terraform          - Infrastructure as Code tool"
    terminalOutput "  15) Install wget               - File download utility"
    terminalOutput "  16) Install zip/unzip          - Archive utilities"
    terminalOutput "  17) Install Git                - Git version control system"
    terminalOutput "  18) Install curl               - Command-line tool for HTTP requests"
    terminalOutput "  19) Install OpenSSL            - Install OpenSSL"
    terminalOutput "  20) Install Postman CLI        - Install Postman CLI"
    terminalOutput "  21) Install Vim                - Install Vim"
    terminalOutput "  22) Clone GitHub Repo (HTTPS)  - Clone a GitHub repository"
    terminalOutput "  23) Set Git Identity           - Configure git user.name and user.email"
    terminalOutput "  24) Show Installed Versions    - Display versions of installed tools"
    terminalOutput "  25) CLI Options                - Show command line options"
    terminalOutput "  26) Help                       - Show menu options"
    terminalOutput "  0)  Exit                       - Quit the script"
    if [ "$mode" = "exit" ]; then
        pause "Press [Enter] to exit..."
        exit 0
    fi
    pause
}

function showCliOptions(){
    local mode="$1"
    clear
    terminalOutput "Development Environment Setup Script - Version $SCRIPT_VERSION"
    terminalOutput ""
    terminalOutput "Usage: ./setup-env.sh [OPTION]"
    terminalOutput ""
    terminalOutput "  --install-python            Install Python"
    terminalOutput "  --install-nodejs            Install Node.js"
    terminalOutput "  --install-npm               Install npm"
    terminalOutput "  --install-git               Install Git"
    terminalOutput "  --install-curl              Install curl"
    terminalOutput "  --install-wget              Install wget"
    terminalOutput "  --install-make              Install make/build tools"
    terminalOutput "  --install-docker            Install Docker"
    terminalOutput "  --install-docker-compose    Install Docker Compose"
    terminalOutput "  --install-zip               Install zip/unzip"
    terminalOutput "  --install-golang            Install Golang"
    terminalOutput "  --install-php               Install PHP"
    terminalOutput "  --install-aws               Install AWS CLI"
    terminalOutput "  --install-azure             Install Azure CLI"
    terminalOutput "  --install-gcloud            Install Google Cloud SDK"
    terminalOutput "  --install-terraform         Install Terraform"
    terminalOutput "  --install-openssl           Install OpenSSL"
    terminalOutput "  --install-openssh           Install OpenSSH server"
    terminalOutput "  --install-composer          Install Composer"
    terminalOutput "  --install-laravel-deps      Install Laravel dependencies"
    terminalOutput "  --install-vim               Install Vim"
    terminalOutput "  --install-postman           Install Postman CLI"
    terminalOutput "  --github-clone              Clone a GitHub repo via HTTPS"
    terminalOutput "  --system-update             Run system update and cleanup"
    terminalOutput "  --install-packages          Install a list of packages (space-separated)"
    terminalOutput "  --help                      Show this help message"

    if [ "$mode" = "exit" ]; then
        pause "Press [Enter] to exit..."
        exit 0
    fi
    pause
}

################################################################################################
#### Menu Interface
################################################################################################

function showMenu(){
    clear
    local GREEN="\033[0;32m"
    local YELLOW="\033[0;33m"
    local RESET="\033[0m"

    local pythonCurrent pythonLatest pythonStatus pythonLabel
    pythonCurrent=""
    if command -v python3 >/dev/null 2>&1; then
        pythonCurrent=$(python3 --version | awk '{print $2}')
    fi
    pythonLatest=$(getPackageLatestVersion "python3")
    pythonStatus=$(getVersionStatus "$(normalizeVersion "$pythonCurrent")" "$(normalizeVersion "$pythonLatest")")
    pythonLabel=$(formatMenuLabel "Python" "$pythonStatus")

    local nodeCurrent nodeLatest nodeStatus nodeLabel
    nodeCurrent=$(getPackageInstalledVersion "nodejs")
    if [ -z "$nodeCurrent" ] && command -v node >/dev/null 2>&1; then
        nodeCurrent=$(node --version | sed 's/^v//')
    fi
    nodeLatest=$(getPackageLatestVersion "nodejs")
    nodeStatus=$(getVersionStatus "$(normalizeVersion "$nodeCurrent")" "$(normalizeVersion "$nodeLatest")")
    nodeLabel=$(formatMenuLabel "Node.js" "$nodeStatus")

    local npmCurrent npmLatest npmStatus npmLabel
    npmCurrent=$(getPackageInstalledVersion "npm")
    if [ -z "$npmCurrent" ] && command -v npm >/dev/null 2>&1; then
        npmCurrent=$(npm --version)
    fi
    npmLatest=$(getPackageLatestVersion "npm")
    npmStatus=$(getVersionStatus "$(normalizeVersion "$npmCurrent")" "$(normalizeVersion "$npmLatest")")
    npmLabel=$(formatMenuLabel "npm" "$npmStatus")

    local goCurrent goLatest goStatus goLabel
    goCurrent=""
    if command -v go >/dev/null 2>&1; then
        goCurrent=$(go version | awk '{print $3}' | sed 's/^go//')
    fi
    goLatest=$(getGoLatestVersion)
    goStatus=$(getVersionStatus "$(normalizeVersion "$goCurrent")" "$(normalizeVersion "$goLatest")")
    goLabel=$(formatMenuLabel "Golang" "$goStatus")

    local phpCurrent phpLatest phpStatus phpLabel
    phpCurrent=""
    if command -v php >/dev/null 2>&1; then
        phpCurrent=$(php --version | head -n 1 | awk '{print $2}')
    fi
    phpLatest=$(getPackageLatestVersion "php")
    phpStatus=$(getVersionStatus "$(normalizeVersion "$phpCurrent")" "$(normalizeVersion "$phpLatest")")
    phpLabel=$(formatMenuLabel "PHP" "$phpStatus")

    local composerCurrent composerLatest composerStatus composerLabel
    composerCurrent=""
    if command -v composer >/dev/null 2>&1; then
        composerCurrent=$(composer --version 2>/dev/null | awk '{print $3}')
    fi
    composerLatest=$(getPackageLatestVersion "composer")
    composerStatus=$(getVersionStatus "$(normalizeVersion "$composerCurrent")" "$(normalizeVersion "$composerLatest")")
    composerLabel=$(formatMenuLabel "Composer" "$composerStatus")

    local laravelStatus laravelLabel
    if isLaravelDepsInstalled; then
        laravelStatus="installed"
    else
        laravelStatus="not-installed"
    fi
    laravelLabel=$(formatMenuLabel "Laravel Dependencies" "$laravelStatus")

    local makeCurrent makeLatest makeStatus makeLabel
    makeCurrent=""
    if command -v make >/dev/null 2>&1; then
        makeCurrent=$(make --version | head -n 1 | awk '{print $3}')
    fi
    makeLatest=$(getPackageLatestVersion "make")
    makeStatus=$(getVersionStatus "$(normalizeVersion "$makeCurrent")" "$(normalizeVersion "$makeLatest")")
    makeLabel=$(formatMenuLabel "make" "$makeStatus")

    local dockerCurrent dockerLatest dockerStatus dockerLabel
    dockerCurrent=""
    if command -v docker >/dev/null 2>&1; then
        dockerCurrent=$(docker --version | awk '{print $3}' | tr -d ',')
    fi
    dockerLatest=$(getPackageLatestVersion "docker-ce")
    if [ -z "$dockerLatest" ]; then
        dockerLatest=$(getPackageLatestVersion "docker.io")
    fi
    dockerStatus=$(getVersionStatus "$(normalizeVersion "$dockerCurrent")" "$(normalizeVersion "$dockerLatest")")
    dockerLabel=$(formatMenuLabel "Docker" "$dockerStatus")

    local composeCurrent composeLatest composeStatus composeLabel
    composeCurrent=""
    if command -v docker-compose >/dev/null 2>&1; then
        composeCurrent=$(docker-compose --version | awk '{print $3}' | tr -d ',')
    elif docker compose version >/dev/null 2>&1; then
        composeCurrent=$(docker compose version 2>/dev/null | awk '{print $4}' | sed 's/^v//')
    fi
    composeLatest=$(getDockerComposeLatestVersion)
    composeStatus=$(getVersionStatus "$(normalizeVersion "$composeCurrent")" "$(normalizeVersion "$composeLatest")")
    composeLabel=$(formatMenuLabel "Docker Compose" "$composeStatus")

    local awsCurrent awsLatest awsStatus awsLabel
    awsCurrent=""
    if command -v aws >/dev/null 2>&1; then
        awsCurrent=$(aws --version 2>/dev/null | awk -F'[ /]' '{print $2}')
    fi
    awsLatest=$(getPackageLatestVersion "awscli")
    awsStatus=$(getVersionStatus "$(normalizeVersion "$awsCurrent")" "$(normalizeVersion "$awsLatest")")
    awsLabel=$(formatMenuLabel "AWS CLI" "$awsStatus")

    local azureCurrent azureLatest azureStatus azureLabel
    azureCurrent=""
    if command -v az >/dev/null 2>&1; then
        azureCurrent=$(az version --output tsv 2>/dev/null | head -n 1 | awk '{print $2}')
    fi
    azureLatest=$(getPackageLatestVersion "azure-cli")
    azureStatus=$(getVersionStatus "$(normalizeVersion "$azureCurrent")" "$(normalizeVersion "$azureLatest")")
    azureLabel=$(formatMenuLabel "Azure CLI" "$azureStatus")

    local gcloudCurrent gcloudLatest gcloudStatus gcloudLabel
    gcloudCurrent=""
    if command -v gcloud >/dev/null 2>&1; then
        gcloudCurrent=$(gcloud version 2>/dev/null | head -n 1 | awk '{print $4}')
    fi
    gcloudLatest=$(getPackageLatestVersion "google-cloud-sdk")
    gcloudStatus=$(getVersionStatus "$(normalizeVersion "$gcloudCurrent")" "$(normalizeVersion "$gcloudLatest")")
    gcloudLabel=$(formatMenuLabel "Google Cloud SDK" "$gcloudStatus")

    local terraformCurrent terraformLatest terraformStatus terraformLabel
    terraformCurrent=""
    if command -v terraform >/dev/null 2>&1; then
        terraformCurrent=$(terraform --version | head -n 1 | awk '{print $2}')
    fi
    terraformLatest=$(getPackageLatestVersion "terraform")
    terraformStatus=$(getVersionStatus "$(normalizeVersion "$terraformCurrent")" "$(normalizeVersion "$terraformLatest")")
    terraformLabel=$(formatMenuLabel "Terraform" "$terraformStatus")

    local wgetCurrent wgetLatest wgetStatus wgetLabel
    wgetCurrent=""
    if command -v wget >/dev/null 2>&1; then
        wgetCurrent=$(wget --version | head -n 1 | awk '{print $3}')
    fi
    wgetLatest=$(getPackageLatestVersion "wget")
    wgetStatus=$(getVersionStatus "$(normalizeVersion "$wgetCurrent")" "$(normalizeVersion "$wgetLatest")")
    wgetLabel=$(formatMenuLabel "wget" "$wgetStatus")

    local zipCurrent zipLatest zipStatus zipLabel
    zipCurrent=""
    if command -v zip >/dev/null 2>&1; then
        zipCurrent=$(zip --version | head -n 1 | awk '{print $2}')
    fi
    zipLatest=$(getPackageLatestVersion "zip")
    zipStatus=$(getVersionStatus "$(normalizeVersion "$zipCurrent")" "$(normalizeVersion "$zipLatest")")
    zipLabel=$(formatMenuLabel "zip/unzip" "$zipStatus")

    local gitCurrent gitLatest gitStatus gitLabel
    gitCurrent=""
    if command -v git >/dev/null 2>&1; then
        gitCurrent=$(git --version | awk '{print $3}')
    fi
    gitLatest=$(getPackageLatestVersion "git")
    gitStatus=$(getVersionStatus "$(normalizeVersion "$gitCurrent")" "$(normalizeVersion "$gitLatest")")
    gitLabel=$(formatMenuLabel "Git" "$gitStatus")

    local curlCurrent curlLatest curlStatus curlLabel
    curlCurrent=""
    if command -v curl >/dev/null 2>&1; then
        curlCurrent=$(curl --version | head -n 1 | awk '{print $2}')
    fi
    curlLatest=$(getPackageLatestVersion "curl")
    curlStatus=$(getVersionStatus "$(normalizeVersion "$curlCurrent")" "$(normalizeVersion "$curlLatest")")
    curlLabel=$(formatMenuLabel "curl" "$curlStatus")

    local opensslCurrent opensslLatest opensslStatus opensslLabel
    opensslCurrent=""
    if command -v openssl >/dev/null 2>&1; then
        opensslCurrent=$(openssl version | awk '{print $2}')
    fi
    opensslLatest=$(getPackageLatestVersion "openssl")
    opensslStatus=$(getVersionStatus "$(normalizeVersion "$opensslCurrent")" "$(normalizeVersion "$opensslLatest")")
    opensslLabel=$(formatMenuLabel "OpenSSL" "$opensslStatus")

    local postmanCurrent postmanLatest postmanStatus postmanLabel
    postmanCurrent=""
    if command -v postman >/dev/null 2>&1; then
        postmanCurrent=$(postman --version 2>/dev/null | awk -F'/' '{print $2}')
    fi
    postmanLatest=$(getNpmLatestVersion "postman-cli")
    postmanStatus=$(getVersionStatus "$(normalizeVersion "$postmanCurrent")" "$(normalizeVersion "$postmanLatest")")
    postmanLabel=$(formatMenuLabel "Postman CLI" "$postmanStatus")

    local vimCurrent vimLatest vimStatus vimLabel
    vimCurrent=$(getPackageInstalledVersion "vim")
    if [ -z "$vimCurrent" ] && command -v vim >/dev/null 2>&1; then
        vimCurrent=$(vim --version | head -n 1 | awk '{print $5}')
    fi
    vimLatest=$(getPackageLatestVersion "vim")
    vimStatus=$(getVersionStatus "$(normalizeVersion "$vimCurrent")" "$(normalizeVersion "$vimLatest")")
    vimLabel=$(formatMenuLabel "Vim" "$vimStatus")

    terminalOutput "${GREEN}======================================${RESET}"
    terminalOutput "${GREEN} Dev Environment Setup - v$SCRIPT_VERSION${RESET}"
    terminalOutput "${GREEN}======================================${RESET}"
    terminalOutput "1)  ${pythonLabel}"
    terminalOutput "2)  ${nodeLabel}"
    terminalOutput "3)  ${npmLabel}"
    terminalOutput "4)  ${goLabel}"
    terminalOutput "5)  ${phpLabel}"
    terminalOutput "6)  ${composerLabel}"
    terminalOutput "7)  ${laravelLabel}"
    terminalOutput "8)  ${makeLabel}"
    terminalOutput "9)  ${dockerLabel}"
    terminalOutput "10) ${composeLabel}"
    terminalOutput "11) ${awsLabel}"
    terminalOutput "12) ${azureLabel}"
    terminalOutput "13) ${gcloudLabel}"
    terminalOutput "14) ${terraformLabel}"
    terminalOutput "15) ${wgetLabel}"
    terminalOutput "16) ${zipLabel}"
    terminalOutput "17) ${gitLabel}"
    terminalOutput "18) ${curlLabel}"
    terminalOutput "19) ${opensslLabel}"
    terminalOutput "20) ${postmanLabel}"
    terminalOutput "21) ${vimLabel}"
    terminalOutput "22) Clone GitHub Repo (HTTPS)"
    terminalOutput "23) Set Git Identity"
    terminalOutput "24) Show Installed Versions"
    terminalOutput "25) CLI Options"
    terminalOutput "26) Help"
    terminalOutput "0)  Exit"
    terminalOutput "======================================"
    terminalOutput "Tip: Enter one or more numbers separated by spaces (e.g., 3 5 9 11 19)."
    printf "%b" "${YELLOW}Choose option(s) [0-26] (space-separated): ${RESET}"
    read -r -a choices

    if [ "${#choices[@]}" -eq 0 ]; then
        terminalOutput "Invalid input. Please enter one or more numbers between 0 and 26."
        sleep 2
        return
    fi

    for choice in "${choices[@]}"; do
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -gt 26 ]; then
            terminalOutput "Invalid input. Please enter numbers between 0 and 26."
            sleep 2
            return
        fi
    done

    for choice in "${choices[@]}"; do
        case $choice in
            1) installPython ;;
            2) installNodeJS ;;
            3) installNpm ;;
            4) installGolang ;;
            5) installPHP ;;
            6) installComposer ;;
            7) installLaravelDeps ;;
            8) installMake ;;
            9)
                warnWslDocker
                if [ "$dockerStatus" = "update-available" ]; then
                    if confirm "Update Docker now?"; then
                        installDocker
                    else
                        terminalOutput "Canceled."
                    fi
                elif [ "$dockerStatus" = "up-to-date" ] || [ "$dockerStatus" = "installed" ]; then
                    if confirm "Docker is already installed. Reinstall anyway?"; then
                        installDocker
                    else
                        terminalOutput "Canceled."
                    fi
                else
                    if confirm "Install Docker now?"; then
                        installDocker
                    else
                        terminalOutput "Canceled."
                    fi
                fi
                ;;
            10)
                warnWslDocker
                if [ "$composeStatus" = "update-available" ]; then
                    if confirm "Update Docker Compose now?"; then
                        installDockerCompose
                    else
                        terminalOutput "Canceled."
                    fi
                elif [ "$composeStatus" = "up-to-date" ] || [ "$composeStatus" = "installed" ]; then
                    if confirm "Docker Compose is already installed. Reinstall anyway?"; then
                        installDockerCompose
                    else
                        terminalOutput "Canceled."
                    fi
                else
                    if confirm "Install Docker Compose now?"; then
                        installDockerCompose
                    else
                        terminalOutput "Canceled."
                    fi
                fi
                ;;
            11) installAWSCLI ;;
            12) installAzureCLI ;;
            13) installGoogleCloudSDK ;;
            14) installTerraform ;;
            15) installWget ;;
            16) installZip ;;
            17) installGit ;;
            18) installCurl ;;
            19) installOpenSSL ;;
            20) installPostman ;;
            21) installVim ;;
            22) cloneGitHubRepo ;;
            23) setGitIdentityMenu ;;
            24) showVersions ;;
            25) showCliOptions ;;
            26) showHelp ;;
            0) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
        esac
    done
}

################################################################################################
#### Start Script with Command Line Arguments or Menu
################################################################################################

# Check if script is run with root privileges
checkRoot

# Enable non-interactive mode for CLI usage
if [ "$#" -gt 0 ]; then
    NON_INTERACTIVE=true
fi

# Parse command line arguments
if [[ "$1" == "--install-python" ]]; then
    installPython
    exit 0
elif [[ "$1" == "--install-nodejs" ]]; then
    installNodeJS
    exit 0
elif [[ "$1" == "--install-npm" ]]; then
    installNpm
    exit 0
elif [[ "$1" == "--install-git" ]]; then
    installGit
    exit 0
elif [[ "$1" == "--install-curl" ]]; then
    installCurl
    exit 0
elif [[ "$1" == "--install-make" ]]; then
    installMake
    exit 0
elif [[ "$1" == "--install-wget" ]]; then
    installWget
    exit 0
elif [[ "$1" == "--install-docker" ]]; then
    installDocker
    exit 0
elif [[ "$1" == "--install-docker-compose" ]]; then
    installDockerCompose
    exit 0
elif [[ "$1" == "--install-zip" ]]; then
    installZip
    exit 0
elif [[ "$1" == "--install-golang" ]]; then
    installGolang
    exit 0
elif [[ "$1" == "--install-php" ]]; then
    installPHP
    exit 0
elif [[ "$1" == "--install-aws" ]]; then
    installAWSCLI
    exit 0
elif [[ "$1" == "--install-azure" ]]; then
    installAzureCLI
    exit 0
elif [[ "$1" == "--install-gcloud" ]]; then
    installGoogleCloudSDK
    exit 0
elif [[ "$1" == "--install-terraform" ]]; then
    installTerraform
    exit 0
elif [[ "$1" == "--install-openssl" ]]; then
    installOpenSSL
    exit 0
elif [[ "$1" == "--install-openssh" ]]; then
    installOpenSSHServer
    exit 0
elif [[ "$1" == "--install-composer" ]]; then
    installComposer
    exit 0
elif [[ "$1" == "--install-laravel-deps" ]]; then
    installLaravelDeps
    exit 0
elif [[ "$1" == "--install-vim" ]]; then
    installVim
    exit 0
elif [[ "$1" == "--install-postman" ]]; then
    installPostman
    exit 0
elif [[ "$1" == "--github-clone" ]]; then
    cloneGitHubRepo
    exit 0
elif [[ "$1" == "--system-update" ]]; then
    runSystemUpdate
    exit 0
elif [[ "$1" == "--install-packages" ]]; then
    shift
    installPackagesFromList "$@"
    exit 0
elif [[ "$1" == "--help" ]]; then
    showCliOptions "exit"
else
    # Start interactive menu
    while true; do showMenu; done
fi
