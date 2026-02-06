#!/bin/bash
# File: setup-env.sh
# Author: Michael Brown
# Version: 1.0.2
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
#   ./setup-env.sh --install-all    # Install all development tools
#   ./setup-env.sh --github-clone   # Clone a GitHub repo via HTTPS
#   ./setup-env.sh --install-python         # Install Python only
#   ./setup-env.sh --install-nodejs         # Install Node.js only
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
# 1. First time setup - install everything:
#    ./setup-env.sh --install-all
#
# 2. Interactive installation (menu-driven):
#    ./setup-env.sh
#    Then select options 1-23 from the menu (you can enter multiple numbers separated by spaces)
#
# 3. Install specific tools:
#    ./setup-env.sh --install-python
#    ./setup-env.sh --install-docker

# 4. Install Laravel dependencies:
#    ./setup-env.sh --install-laravel-deps

# MENU OPTIONS EXPLAINED:
# When you run ./setup-env.sh, you'll see a menu with these options.
# You can select one option or multiple options by entering numbers separated by spaces (e.g., 3 5 9 11 19).
#   1. Install Python             - Installs Python 3 and pip
#   2. Install Node.js & npm      - Installs Node.js and npm package manager
#   3. Install Git                - Installs Git version control
#   4. Install curl               - Installs curl for HTTP requests
#   5. Install wget               - Installs wget for file downloads
#   6. Install make               - Installs build-essential (make, gcc, g++)
#   7. Install Docker             - Installs Docker Engine
#   8. Install Docker Compose     - Installs Docker Compose (standalone)
#   9. Install zip/unzip          - Installs zip and unzip utilities
#   10. Install Golang            - Installs Go programming language
#   11. Install PHP               - Installs PHP and common extensions
#   12. Install AWS CLI           - Installs AWS CLI
#   13. Install Azure CLI         - Installs Azure CLI
#   14. Install Google Cloud SDK  - Installs Google Cloud SDK
#   15. Install Terraform         - Installs Terraform
#   16. Install OpenSSL           - Installs OpenSSL
#   17. Install Composer          - Installs Composer
#   18. Install Laravel Deps      - Installs Laravel dependencies
#   19. Install Vim               - Installs Vim editor
#   20. Install Postman CLI        - Installs Postman CLI
#   21. Install All Tools          - Installs all development tools
#   22. Show Installed Versions    - Display versions of installed tools
#   23. Help                       - Show usage information
#   0. Exit                       - Quit the script

################################################################################################
#### Configurable Variables
################################################################################################

# Define script version
SCRIPT_VERSION="1.0.2"

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
            echo "$text"
        fi
    fi
}

################################################################################################
#### Utility Functions
################################################################################################

function pause(){
    if [ "$NON_INTERACTIVE" = true ]; then
        return
    fi
    read -p "Press [Enter] to return to the menu..."
}

function confirm(){
    read -p "$1 [y/N]: " response
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
    npm --version
    log "Node.js installation complete"
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
    if [ "$NON_INTERACTIVE" = true ]; then
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
    else
        if ! confirm "Would you like to set your Git identity now?"; then
            terminalOutput "Skipped Git identity setup. You can set it later with:"
            terminalOutput "  git config --global user.name \"Your Name\""
            terminalOutput "  git config --global user.email \"you@example.com\""
            terminalOutput "To change the defaults, edit GIT_USER_NAME/GIT_USER_EMAIL near the top of this script."
            log "Git identity setup skipped"
            pause
            return
        fi

        local gitName="$GIT_USER_NAME"
        local gitEmail="$GIT_USER_EMAIL"

        terminalOutput "Git identity defaults:"
        terminalOutput "  Name:  $gitName"
        terminalOutput "  Email: $gitEmail"

        if confirm "Is this your info?"; then
            git config --global user.name "$gitName"
            git config --global user.email "$gitEmail"
        else
            terminalOutput "You can update it now or later with:"
            terminalOutput "  git config --global user.name \"Your Name\""
            terminalOutput "  git config --global user.email \"you@example.com\""
            terminalOutput "To change the defaults, edit GIT_USER_NAME/GIT_USER_EMAIL near the top of this script."

            read -p "Enter your name (leave blank to skip): " gitNameInput
            read -p "Enter your email (leave blank to skip): " gitEmailInput

            if [ -n "$gitNameInput" ]; then
                gitName="$gitNameInput"
            fi

            if [ -n "$gitEmailInput" ]; then
                gitEmail="$gitEmailInput"
            fi

            if [ -n "$gitNameInput" ] || [ -n "$gitEmailInput" ]; then
                if [ -n "$gitName" ]; then
                    git config --global user.name "$gitName"
                fi
                if [ -n "$gitEmail" ]; then
                    git config --global user.email "$gitEmail"
                fi
            fi
        fi
    fi
    log "Git installation complete"
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
        read -p "Enter the HTTPS repo URL (e.g., https://github.com/owner/repo.git): " repoUrl

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
        read -p "Target folder [${defaultDir}]: " targetDir

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
        read -p "Continue? [y/N]: " confirmAction
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

        read -p "Select [1-4]: " action
        case "$action" in
            1) ;;
            2)
                repoUrl=""
                while true; do
                    read -p "Enter the HTTPS repo URL (e.g., https://github.com/owner/repo.git): " repoUrl
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
                    read -p "Target folder [${defaultDir}]: " targetDir
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

function installAll() {
    terminalOutput "======================================"
    terminalOutput " Installing All Development Tools"
    terminalOutput "======================================"
    log "Starting installation of all development tools"
    
    if confirm "This will install Python, Node.js, Git, curl, wget, make, Docker, Docker Compose, zip, Golang, PHP, AWS CLI, Azure CLI, Google Cloud SDK, Terraform, OpenSSL, Composer, Laravel dependencies, Vim, and Postman CLI. Continue?"; then
        installCurl
        installWget
        installGit
        installMake
        installZip
        installPython
        installNodeJS
        installGolang
        installPHP
        installDocker
        installDockerCompose
        installAWSCLI
        installAzureCLI
        installGoogleCloudSDK
        installTerraform
        installOpenSSL
        installComposer
        installLaravelDeps
        installVim
        installPostman
        
        terminalOutput "======================================"
        terminalOutput " All Development Tools Installed!"
        terminalOutput "======================================"
        log "All development tools installation complete"
    else
        terminalOutput "Installation canceled."
        log "Installation canceled by user"
    fi
    pause
}

function showVersions() {
    terminalOutput "======================================"
    terminalOutput " Installed Tool Versions"
    terminalOutput "======================================"
    
    terminalOutput ""
    terminalOutput "--- Python ---"
    if command -v python3 >/dev/null 2>&1; then
        python3 --version
        if command -v pip3 >/dev/null 2>&1; then
            pip3 --version
        else
            terminalOutput "pip3: Not installed"
        fi
    else
        terminalOutput "Python: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Node.js ---"
    if command -v node >/dev/null 2>&1; then
        node --version
        npm --version
    else
        terminalOutput "Node.js: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Git ---"
    if command -v git >/dev/null 2>&1; then
        git --version
    else
        terminalOutput "Git: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- curl ---"
    if command -v curl >/dev/null 2>&1; then
        curl --version | head -n 1
    else
        terminalOutput "curl: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- make ---"
    if command -v make >/dev/null 2>&1; then
        make --version | head -n 1
        gcc --version | head -n 1
    else
        terminalOutput "make: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Docker ---"
    if command -v docker >/dev/null 2>&1; then
        docker --version
        docker compose version
    else
        terminalOutput "Docker: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- zip ---"
    if command -v zip >/dev/null 2>&1; then
        zip --version | head -n 2
    else
        terminalOutput "zip: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Golang ---"
    if command -v go >/dev/null 2>&1; then
        go version
    else
        terminalOutput "Golang: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- PHP ---"
    if command -v php >/dev/null 2>&1; then
        php --version | head -n 1
    else
        terminalOutput "PHP: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- wget ---"
    if command -v wget >/dev/null 2>&1; then
        wget --version | head -n 1
    else
        terminalOutput "wget: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Docker Compose ---"
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose --version
    else
        terminalOutput "Docker Compose: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- AWS CLI ---"
    if command -v aws >/dev/null 2>&1; then
        aws --version
    else
        terminalOutput "AWS CLI: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Azure CLI ---"
    if command -v az >/dev/null 2>&1; then
        az version --output tsv | head -n 1
    else
        terminalOutput "Azure CLI: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Google Cloud SDK ---"
    if command -v gcloud >/dev/null 2>&1; then
        gcloud version | head -n 1
    else
        terminalOutput "Google Cloud SDK: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Terraform ---"
    if command -v terraform >/dev/null 2>&1; then
        terraform --version | head -n 1
    else
        terminalOutput "Terraform: Not installed"
    fi

    terminalOutput ""
    terminalOutput "--- OpenSSL ---"
    if command -v openssl >/dev/null 2>&1; then
        openssl version
    else
        terminalOutput "OpenSSL: Not installed"
    fi

    terminalOutput ""
    terminalOutput "--- Postman CLI ---"
    if command -v postman >/dev/null 2>&1; then
        postman --version
    else
        terminalOutput "Postman CLI: Not installed"
    fi
    
    terminalOutput "======================================"
    pause
}

################################################################################################
#### Help Menu
################################################################################################

function showHelp(){
    terminalOutput "Development Environment Setup Script - Version $SCRIPT_VERSION"
    terminalOutput ""
    terminalOutput "Usage: ./setup-env.sh [OPTION]"
    terminalOutput ""
    terminalOutput "  --github-clone         Clone a GitHub repo via HTTPS"
    terminalOutput "  --install-postman        Install Postman CLI"
    terminalOutput "  --system-update          Run system update and cleanup"
    terminalOutput "  --install-packages       Install a list of packages (space-separated)"
    terminalOutput "  --help                   Show this help message"
    terminalOutput ""
    terminalOutput "Menu Options (enter one or more numbers separated by spaces, e.g., 3 5 9 11 19):"
    terminalOutput "  1)  Install Python             - Python 3, pip, and development tools"
    terminalOutput "  2)  Install Node.js & npm      - Node.js LTS and npm package manager"
    terminalOutput "  3)  Install Git                - Git version control system"
    terminalOutput "  4)  Install curl               - Command-line tool for HTTP requests"
    terminalOutput "  5)  Install wget               - File download utility"
    terminalOutput "  6)  Install make               - Build tools (make, gcc, g++)"
    terminalOutput "  7)  Install Docker             - Docker Engine"
    terminalOutput "  8)  Install Docker Compose     - Docker Compose (standalone)"
    terminalOutput "  9)  Install zip/unzip          - Archive utilities"
    terminalOutput "  10) Install Golang             - Go programming language"
    terminalOutput "  11) Install PHP                - PHP and common extensions"
    terminalOutput "  12) Install AWS CLI            - Amazon Web Services CLI"
    terminalOutput "  13) Install Azure CLI          - Microsoft Azure CLI"
    terminalOutput "  14) Install Google Cloud SDK   - Google Cloud Platform tools"
    terminalOutput "  15) Install Terraform          - Infrastructure as Code tool"
    terminalOutput "  16) Install OpenSSL            - Install OpenSSL"
    terminalOutput "  17) Install Composer           - Install Composer"
    terminalOutput "  18) Install Laravel Deps       - Install Laravel dependencies"
    terminalOutput "  19) Install Vim                - Install Vim"
    terminalOutput "  20) Install Postman CLI        - Install Postman CLI"
    terminalOutput "  21) Install All Tools          - Install everything at once"
    terminalOutput "  22) Show Installed Versions    - Display versions of installed tools"
    terminalOutput "  23) Help                       - Show this help message"
    terminalOutput "  24) Clone GitHub Repo (HTTPS)  - Clone a GitHub repository"
    terminalOutput "  0)  Exit                       - Quit the script"
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

    terminalOutput "${GREEN}======================================${RESET}"
    terminalOutput "${GREEN} Dev Environment Setup - v$SCRIPT_VERSION${RESET}"
    terminalOutput "${GREEN}======================================${RESET}"
    terminalOutput "1)  Install Python"
    terminalOutput "2)  Install Node.js & npm"
    terminalOutput "3)  Install Git"
    terminalOutput "4)  Install curl"
    terminalOutput "5)  Install wget"
    terminalOutput "6)  Install make"
    terminalOutput "7)  Install Docker"
    terminalOutput "8)  Install Docker Compose"
    terminalOutput "9)  Install zip/unzip"
    terminalOutput "10) Install Golang"
    terminalOutput "11) Install PHP"
    terminalOutput "12) Install AWS CLI"
    terminalOutput "13) Install Azure CLI"
    terminalOutput "14) Install Google Cloud SDK"
    terminalOutput "15) Install Terraform"
    terminalOutput "16) Install OpenSSL"
    terminalOutput "17) Install Composer"
    terminalOutput "18) Install Laravel Dependencies"
    terminalOutput "19) Install Vim"
    terminalOutput "20) Install Postman CLI"
    terminalOutput "21) Install All Tools"
    terminalOutput "22) Show Installed Versions"
    terminalOutput "23) Help"
    terminalOutput "24) Clone GitHub Repo (HTTPS)"
    terminalOutput "0)  Exit"
    terminalOutput "======================================"
    terminalOutput "Tip: Enter one or more numbers separated by spaces (e.g., 3 5 9 11 19)."
    read -p "${YELLOW}Choose option(s) [0-24] (space-separated): ${RESET}" -a choices

    if [ "${#choices[@]}" -eq 0 ]; then
        terminalOutput "Invalid input. Please enter one or more numbers between 0 and 24."
        sleep 2
        return
    fi

    for choice in "${choices[@]}"; do
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -gt 24 ]; then
            terminalOutput "Invalid input. Please enter numbers between 0 and 24."
            sleep 2
            return
        fi
    done

    for choice in "${choices[@]}"; do
        case $choice in
            1) installPython ;;
            2) installNodeJS ;;
            3) installGit ;;
            4) installCurl ;;
            5) installWget ;;
            6) installMake ;;
            7) installDocker ;;
            8) installDockerCompose ;;
            9) installZip ;;
            10) installGolang ;;
            11) installPHP ;;
            12) installAWSCLI ;;
            13) installAzureCLI ;;
            14) installGoogleCloudSDK ;;
            15) installTerraform ;;
            16) installOpenSSL ;;
            17) installComposer ;;
            18) installLaravelDeps ;;
            19) installVim ;;
            20) installPostman ;;
            21) installAll ;;
            22) showVersions ;;
            23) showHelp ;;
            24) cloneGitHubRepo ;;
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
if [[ "$1" == "--install-all" ]]; then
    installAll
    exit 0
elif [[ "$1" == "--install-python" ]]; then
    installPython
    exit 0
elif [[ "$1" == "--install-nodejs" ]]; then
    installNodeJS
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
    showHelp
    exit 0
else
    # Start interactive menu
    while true; do showMenu; done
fi
