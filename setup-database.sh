#!/bin/bash
# File: setup-database.sh
# Author: Michael Brown
# Version: 1.0.0
# Date: November 20, 2025
# Description: Menu-driven database setup script for Ubuntu/Debian and RHEL-based systems
#              Installs and configures PostgreSQL, MySQL, MongoDB, Redis, and SQLite

################################################################################################
#### HOW TO USE THIS SCRIPT - Examples and Quick Reference
################################################################################################

# BASIC USAGE:
# Make the script executable first:
#   chmod +x setup-database.sh
#
# Run in interactive menu mode (shows a numbered menu with options):
# Simply run the script without any parameters - this starts the interactive menu
#   ./setup-database.sh
#
# Run with command line options:
#   ./setup-database.sh                    # Starts the interactive menu
#   ./setup-database.sh --install-all      # Install all databases
#   ./setup-database.sh --install-postgres # Install PostgreSQL only
#   ./setup-database.sh --install-mysql    # Install MySQL only
#   ./setup-database.sh --help             # Show help information

# COMMON SCENARIOS:
#
# 1. First time setup - install everything:
#    ./setup-database.sh --install-all
#
# 2. Interactive installation (menu-driven):
#    ./setup-database.sh
#    Then select options 1-7 from the menu
#
# 3. Install specific database:
#    ./setup-database.sh --install-postgres
#    ./setup-database.sh --install-mysql

# MENU OPTIONS EXPLAINED:
# When you run ./setup-database.sh, you'll see a menu with these options:
#   1. Install PostgreSQL        - PostgreSQL database server and client
#   2. Install MySQL             - MySQL database server and client
#   3. Install MongoDB           - MongoDB NoSQL database
#   4. Install Redis             - Redis in-memory data store
#   5. Install SQLite            - SQLite lightweight database
#   6. Install All Databases     - Installs all database systems
#   7. Show Installed Versions   - Display versions of installed databases
#   8. Help                      - Show usage information
#   0. Exit                      - Quit the script

################################################################################################
#### Configurable Variables
################################################################################################

# Define script version
SCRIPT_VERSION="1.0.0"

# Enable or disable logging (true/false)
LOGGING_ENABLED=false
LOGFILE="/var/log/database-setup-script.log"

# Quiet mode (suppress non-essential output)
QUIET_MODE=false

# Cache for detected package manager
DETECTED_PKG_MANAGER=""

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
        echo "$1"
    fi
}

################################################################################################
#### Utility Functions
################################################################################################

function pause(){
    read -p "Press [Enter] to return to the menu..."
}

function confirm(){
    read -p "$1 [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

################################################################################################
#### Database Installation Functions
################################################################################################

function installPostgreSQL() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing PostgreSQL"
    terminalOutput "======================================"
    log "Starting PostgreSQL installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib postgresql-client
        
        # Start and enable PostgreSQL service
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y postgresql-server postgresql-contrib
        
        # Initialize database
        sudo postgresql-setup --initdb
        
        # Start and enable PostgreSQL service
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y postgresql-server postgresql-contrib
        
        # Initialize database
        sudo postgresql-setup --initdb
        
        # Start and enable PostgreSQL service
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        terminalOutput "Error: Unsupported package manager"
        log "PostgreSQL installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "PostgreSQL installation complete!"
    terminalOutput "Service status:"
    sudo systemctl status postgresql --no-pager | head -n 5
    psql --version
    terminalOutput ""
    terminalOutput "Note: Default user is 'postgres'. Use 'sudo -u postgres psql' to connect."
    log "PostgreSQL installation complete"
    pause
}

function installMySQL() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing MySQL"
    terminalOutput "======================================"
    log "Starting MySQL installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y mysql-server mysql-client
        
        # Start and enable MySQL service
        sudo systemctl start mysql
        sudo systemctl enable mysql
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y mysql-server mysql
        
        # Start and enable MySQL service
        sudo systemctl start mysqld
        sudo systemctl enable mysqld
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y mysql-server mysql
        
        # Start and enable MySQL service
        sudo systemctl start mysqld
        sudo systemctl enable mysqld
    else
        terminalOutput "Error: Unsupported package manager"
        log "MySQL installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "MySQL installation complete!"
    terminalOutput "Service status:"
    if [ "$pkgManager" = "apt" ]; then
        sudo systemctl status mysql --no-pager | head -n 5
    else
        sudo systemctl status mysqld --no-pager | head -n 5
    fi
    mysql --version
    terminalOutput ""
    terminalOutput "Note: Run 'sudo mysql_secure_installation' to secure your MySQL installation."
    log "MySQL installation complete"
    pause
}

function installMongoDB() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing MongoDB"
    terminalOutput "======================================"
    log "Starting MongoDB installation"
    
    if [ "$pkgManager" = "apt" ]; then
        # Import MongoDB public GPG key
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        
        # Add MongoDB repository
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        
        # Install MongoDB
        sudo apt update
        sudo apt install -y mongodb-org
        
        # Start and enable MongoDB service
        sudo systemctl start mongod
        sudo systemctl enable mongod
        
    elif [ "$pkgManager" = "yum" ]; then
        # Add MongoDB repository
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        
        # Install MongoDB
        sudo yum install -y mongodb-org
        
        # Start and enable MongoDB service
        sudo systemctl start mongod
        sudo systemctl enable mongod
        
    elif [ "$pkgManager" = "dnf" ]; then
        # Add MongoDB repository
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        
        # Install MongoDB
        sudo dnf install -y mongodb-org
        
        # Start and enable MongoDB service
        sudo systemctl start mongod
        sudo systemctl enable mongod
    else
        terminalOutput "Error: Unsupported package manager"
        log "MongoDB installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "MongoDB installation complete!"
    terminalOutput "Service status:"
    sudo systemctl status mongod --no-pager | head -n 5
    mongod --version | head -n 1
    terminalOutput ""
    terminalOutput "Note: MongoDB is running on default port 27017. Use 'mongosh' to connect."
    log "MongoDB installation complete"
    pause
}

function installRedis() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing Redis"
    terminalOutput "======================================"
    log "Starting Redis installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y redis-server
        
        # Start and enable Redis service
        sudo systemctl start redis-server
        sudo systemctl enable redis-server
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y redis
        
        # Start and enable Redis service
        sudo systemctl start redis
        sudo systemctl enable redis
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y redis
        
        # Start and enable Redis service
        sudo systemctl start redis
        sudo systemctl enable redis
    else
        terminalOutput "Error: Unsupported package manager"
        log "Redis installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "Redis installation complete!"
    terminalOutput "Service status:"
    if [ "$pkgManager" = "apt" ]; then
        sudo systemctl status redis-server --no-pager | head -n 5
    else
        sudo systemctl status redis --no-pager | head -n 5
    fi
    redis-server --version
    terminalOutput ""
    terminalOutput "Note: Redis is running on default port 6379. Use 'redis-cli' to connect."
    log "Redis installation complete"
    pause
}

function installSQLite() {
    local pkgManager
    pkgManager=$(detectPackageManager)
    
    terminalOutput "======================================"
    terminalOutput " Installing SQLite"
    terminalOutput "======================================"
    log "Starting SQLite installation"
    
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y sqlite3 libsqlite3-dev
        
    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y sqlite sqlite-devel
        
    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y sqlite sqlite-devel
    else
        terminalOutput "Error: Unsupported package manager"
        log "SQLite installation failed - unsupported package manager"
        pause
        return 1
    fi
    
    terminalOutput "SQLite installation complete!"
    sqlite3 --version
    terminalOutput ""
    terminalOutput "Note: SQLite is a file-based database. Use 'sqlite3 <database-file>' to create/open a database."
    log "SQLite installation complete"
    pause
}

function installAll() {
    terminalOutput "======================================"
    terminalOutput " Installing All Databases"
    terminalOutput "======================================"
    log "Starting installation of all databases"
    
    if confirm "This will install PostgreSQL, MySQL, MongoDB, Redis, and SQLite. Continue?"; then
        installPostgreSQL
        installMySQL
        installMongoDB
        installRedis
        installSQLite
        
        terminalOutput "======================================"
        terminalOutput " All Databases Installed!"
        terminalOutput "======================================"
        log "All databases installation complete"
    else
        terminalOutput "Installation canceled."
        log "Installation canceled by user"
    fi
    pause
}

function showVersions() {
    terminalOutput "======================================"
    terminalOutput " Installed Database Versions"
    terminalOutput "======================================"
    
    terminalOutput ""
    terminalOutput "--- PostgreSQL ---"
    if command -v psql >/dev/null 2>&1; then
        psql --version
        terminalOutput "Service status:"
        sudo systemctl is-active postgresql 2>/dev/null || echo "Service not running or not found"
    else
        terminalOutput "PostgreSQL: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- MySQL ---"
    if command -v mysql >/dev/null 2>&1; then
        mysql --version
        terminalOutput "Service status:"
        sudo systemctl is-active mysql 2>/dev/null || sudo systemctl is-active mysqld 2>/dev/null || echo "Service not running or not found"
    else
        terminalOutput "MySQL: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- MongoDB ---"
    if command -v mongod >/dev/null 2>&1; then
        mongod --version | head -n 1
        terminalOutput "Service status:"
        sudo systemctl is-active mongod 2>/dev/null || echo "Service not running or not found"
    else
        terminalOutput "MongoDB: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Redis ---"
    if command -v redis-server >/dev/null 2>&1; then
        redis-server --version
        terminalOutput "Service status:"
        sudo systemctl is-active redis 2>/dev/null || sudo systemctl is-active redis-server 2>/dev/null || echo "Service not running or not found"
    else
        terminalOutput "Redis: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- SQLite ---"
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 --version
    else
        terminalOutput "SQLite: Not installed"
    fi
    
    terminalOutput "======================================"
    pause
}

################################################################################################
#### Help Menu
################################################################################################

function showHelp(){
    terminalOutput "Database Setup Script - Version $SCRIPT_VERSION"
    terminalOutput ""
    terminalOutput "Usage: ./setup-database.sh [OPTION]"
    terminalOutput ""
    terminalOutput "Options:"
    terminalOutput "  --install-all        Install all databases"
    terminalOutput "  --install-postgres   Install PostgreSQL"
    terminalOutput "  --install-mysql      Install MySQL"
    terminalOutput "  --install-mongodb    Install MongoDB"
    terminalOutput "  --install-redis      Install Redis"
    terminalOutput "  --install-sqlite     Install SQLite"
    terminalOutput "  --help               Show this help message"
    terminalOutput ""
    terminalOutput "Menu Options:"
    terminalOutput "  1) Install PostgreSQL        - PostgreSQL database server and client"
    terminalOutput "  2) Install MySQL             - MySQL database server and client"
    terminalOutput "  3) Install MongoDB           - MongoDB NoSQL database"
    terminalOutput "  4) Install Redis             - Redis in-memory data store"
    terminalOutput "  5) Install SQLite            - SQLite lightweight database"
    terminalOutput "  6) Install All Databases     - Install all database systems"
    terminalOutput "  7) Show Installed Versions   - Display versions and status"
    terminalOutput "  8) Help                      - Show this help message"
    terminalOutput "  0) Exit                      - Quit the script"
    pause
}

################################################################################################
#### Menu Interface
################################################################################################

function showMenu(){
    clear
    terminalOutput "======================================"
    terminalOutput " Database Setup - v$SCRIPT_VERSION"
    terminalOutput "======================================"
    terminalOutput "1) Install PostgreSQL"
    terminalOutput "2) Install MySQL"
    terminalOutput "3) Install MongoDB"
    terminalOutput "4) Install Redis"
    terminalOutput "5) Install SQLite"
    terminalOutput "6) Install All Databases"
    terminalOutput "7) Show Installed Versions"
    terminalOutput "8) Help"
    terminalOutput "0) Exit"
    terminalOutput "======================================"
    read -p "Choose an option [0-8]: " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -gt 8 ]; then
        terminalOutput "Invalid input. Please enter a number between 0 and 8."
        sleep 2
        return
    fi

    case $choice in
        1) installPostgreSQL ;;
        2) installMySQL ;;
        3) installMongoDB ;;
        4) installRedis ;;
        5) installSQLite ;;
        6) installAll ;;
        7) showVersions ;;
        8) showHelp ;;
        0) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
    esac
}

################################################################################################
#### Start Script with Command Line Arguments or Menu
################################################################################################

# Check if script is run with root privileges
checkRoot

# Parse command line arguments
if [[ "$1" == "--install-all" ]]; then
    installAll
    exit 0
elif [[ "$1" == "--install-postgres" ]]; then
    installPostgreSQL
    exit 0
elif [[ "$1" == "--install-mysql" ]]; then
    installMySQL
    exit 0
elif [[ "$1" == "--install-mongodb" ]]; then
    installMongoDB
    exit 0
elif [[ "$1" == "--install-redis" ]]; then
    installRedis
    exit 0
elif [[ "$1" == "--install-sqlite" ]]; then
    installSQLite
    exit 0
elif [[ "$1" == "--help" ]]; then
    showHelp
    exit 0
else
    # Start interactive menu
    while true; do showMenu; done
fi
