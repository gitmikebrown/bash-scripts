#!/bin/bash
# File: setup-database.sh
# Author: Michael Brown
# Version: 1.0.1
# Date: February 6, 2026
# Description: Menu-driven database setup script for Ubuntu/Debian and RHEL-based systems
#              Installs and configures PostgreSQL, MySQL, MongoDB, Redis, SQLite, and DB client tools

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
#   ./setup-database.sh # Starts the interactive menu
#   ./setup-database.sh --install-postgres # Install PostgreSQL (standard)
#   ./setup-database.sh --install-postgres-server # Install PostgreSQL server only
#   ./setup-database.sh --install-postgresql-client # Install PostgreSQL client CLI only
#   ./setup-database.sh --install-postgresql-client-gui # Install PostgreSQL client GUI
#   ./setup-database.sh --install-mysql # Install MySQL (standard)
#   ./setup-database.sh --install-mysql-server # Install MySQL server only
#   ./setup-database.sh --install-mysql-client # Install MySQL client CLI only
#   ./setup-database.sh --install-mysql-client-gui # Install MySQL client GUI
#   ./setup-database.sh --install-mongodb # Install MongoDB (standard)
#   ./setup-database.sh --install-mongodb-server # Install MongoDB server only
#   ./setup-database.sh --install-mongodb-client # Install MongoDB client CLI only
#   ./setup-database.sh --install-mongodb-client-gui # Install MongoDB client GUI
#   ./setup-database.sh --install-redis # Install Redis (standard)
#   ./setup-database.sh --install-redis-tools # Install Redis CLI tools only
#   ./setup-database.sh --install-sqlite # Install SQLite (standard)
#   ./setup-database.sh --install-sqlite3 # Install SQLite3 CLI only
#   ./setup-database.sh --help # Show help information

# COMMON SCENARIOS:
#
# 1. Interactive installation (menu-driven):
#    ./setup-database.sh
#    Then select options 1-18 from the menu
#
# 2. Install specific database:
#    ./setup-database.sh --install-postgres  # Standard install
#    ./setup-database.sh --install-mysql

# MENU OPTIONS EXPLAINED:
# When you run ./setup-database.sh, you'll see a menu with these options:
#   1. Install PostgreSQL (standard) - PostgreSQL database server and client
#   2. Install PostgreSQL Server - PostgreSQL database server only
#   3. Install PostgreSQL Client CLI - PostgreSQL client tools only
#   4. Install PostgreSQL Client GUI - PostgreSQL GUI client only
#   5. Install MySQL (standard)
#   6. Install MySQL Server - MySQL database server only
#   7. Install MySQL Client CLI - MySQL client tools only
#   8. Install MySQL Client GUI - MySQL GUI client only
#   9. Install MongoDB (standard)
#   10. Install MongoDB Server - MongoDB server only
#   11. Install MongoDB Client CLI - MongoDB client tools only
#   12. Install MongoDB Client GUI - MongoDB GUI client only
#   13. Install Redis (standard)
#   14. Install Redis Tools - Redis CLI tools only
#   15. Install SQLite (standard)
#   16. Install SQLite3 CLI - SQLite3 CLI only
#   17. Show Installed Versions - Display versions of installed databases
#   18. Help - Show usage information
#   0. Exit                      - Quit the script

################################################################################################
#### Configurable Variables
################################################################################################

# Define script version
SCRIPT_VERSION="1.0.1"

# Enable or disable logging (true/false)
LOGGING_ENABLED=false
LOGFILE="/var/log/database-setup-script.log"

# Quiet mode (suppress non-essential output)
QUIET_MODE=false

# Prompt colors
COLOR_YELLOW="\033[0;33m"
COLOR_RESET="\033[0m"

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
        printf "%b\n" "$1"
    fi
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

function pause(){
    promptInput "Press [Enter] to return to the menu..."
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

function installPostgresServer() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing PostgreSQL Server"
    terminalOutput "======================================"
    log "Starting PostgreSQL server installation"

    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib

        sudo systemctl start postgresql
        sudo systemctl enable postgresql

    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y postgresql-server postgresql-contrib
        sudo postgresql-setup --initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql

    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y postgresql-server postgresql-contrib
        sudo postgresql-setup --initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    else
        terminalOutput "Error: Unsupported package manager"
        log "PostgreSQL server installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "PostgreSQL server installation complete!"
    terminalOutput "Service status:"
    sudo systemctl status postgresql --no-pager | head -n 5
    log "PostgreSQL server installation complete"
    pause
}

function installPostgresClient() {
    terminalOutput "======================================"
    terminalOutput " Installing PostgreSQL Client"
    terminalOutput "======================================"
    log "Starting PostgreSQL client installation"

    ensurePackages postgresql-client

    terminalOutput "PostgreSQL client installation complete!"
    psql --version
    log "PostgreSQL client installation complete"
    pause
}

function installPostgresClientGui() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing PostgreSQL Client GUI"
    terminalOutput "======================================"
    log "Starting PostgreSQL client GUI installation"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages curl ca-certificates gnupg lsb-release

        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /etc/apt/keyrings/pgadmin.gpg
        echo "deb [signed-by=/etc/apt/keyrings/pgadmin.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" | sudo tee /etc/apt/sources.list.d/pgadmin4.list

        sudo apt update
        sudo apt install -y pgadmin4-desktop

    elif [ "$pkgManager" = "yum" ]; then
        ensurePackages curl
        sudo rpm -Uvh https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm
        sudo yum install -y pgadmin4-desktop

    elif [ "$pkgManager" = "dnf" ]; then
        ensurePackages curl
        sudo rpm -Uvh https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm
        sudo dnf install -y pgadmin4-desktop
    else
        terminalOutput "Error: Unsupported package manager"
        log "PostgreSQL client GUI installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "PostgreSQL client GUI installation complete!"
    if command -v pgadmin4 >/dev/null 2>&1; then
        pgadmin4 --version
    fi
    log "PostgreSQL client GUI installation complete"
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

function installMySQLServer() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MySQL Server"
    terminalOutput "======================================"
    log "Starting MySQL server installation"

    if [ "$pkgManager" = "apt" ]; then
        sudo apt update
        sudo apt install -y mysql-server

        sudo systemctl start mysql
        sudo systemctl enable mysql

    elif [ "$pkgManager" = "yum" ]; then
        sudo yum install -y mysql-server

        sudo systemctl start mysqld
        sudo systemctl enable mysqld

    elif [ "$pkgManager" = "dnf" ]; then
        sudo dnf install -y mysql-server

        sudo systemctl start mysqld
        sudo systemctl enable mysqld
    else
        terminalOutput "Error: Unsupported package manager"
        log "MySQL server installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "MySQL server installation complete!"
    log "MySQL server installation complete"
    pause
}

function installMySQLClientCli() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MySQL Client CLI"
    terminalOutput "======================================"
    log "Starting MySQL client CLI installation"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages mysql-client
    elif [ "$pkgManager" = "yum" ]; then
        ensurePackages mysql
    elif [ "$pkgManager" = "dnf" ]; then
        ensurePackages mysql
    else
        terminalOutput "Error: Unsupported package manager"
        log "MySQL client CLI installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "MySQL client CLI installation complete!"
    mysql --version
    log "MySQL client CLI installation complete"
    pause
}

function installMySQLClientGui() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MySQL Client GUI"
    terminalOutput "======================================"
    log "Starting MySQL client GUI installation"

    local PHPMYADMIN_URL="https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz"
    local TMP_ARCHIVE="/tmp/phpmyadmin.tar.gz"
    local TMP_DIR="/tmp/phpmyadmin"
    local TARGET_DIR="/var/www/html/phpmyadmin"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages apache2 php libapache2-mod-php php-mbstring php-zip php-gd php-json php-curl curl tar
        sudo systemctl enable --now apache2

    elif [ "$pkgManager" = "yum" ]; then
        ensurePackages httpd php php-mbstring php-zip php-gd php-json php-curl curl tar
        sudo systemctl enable --now httpd

    elif [ "$pkgManager" = "dnf" ]; then
        ensurePackages httpd php php-mbstring php-zip php-gd php-json php-curl curl tar
        sudo systemctl enable --now httpd
    else
        terminalOutput "Error: Unsupported package manager"
        log "MySQL client GUI installation failed - unsupported package manager"
        pause
        return 1
    fi

    sudo rm -rf "$TMP_DIR" "$TARGET_DIR"
    mkdir -p "$TMP_DIR"
    curl -fsSL "$PHPMYADMIN_URL" -o "$TMP_ARCHIVE"
    tar -xzf "$TMP_ARCHIVE" -C "$TMP_DIR"

    local EXTRACTED_DIR
    EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "phpMyAdmin-*" | head -n 1)
    if [ -z "$EXTRACTED_DIR" ]; then
        terminalOutput "Error: Failed to extract phpMyAdmin"
        log "MySQL client GUI installation failed - extraction error"
        pause
        return 1
    fi

    sudo mv "$EXTRACTED_DIR" "$TARGET_DIR"

    if id -u www-data >/dev/null 2>&1; then
        sudo chown -R www-data:www-data "$TARGET_DIR"
    elif id -u apache >/dev/null 2>&1; then
        sudo chown -R apache:apache "$TARGET_DIR"
    fi

    terminalOutput "MySQL client GUI installation complete!"
    terminalOutput "Note: phpMyAdmin is available at http://localhost/phpmyadmin"
    log "MySQL client GUI installation complete"
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

function installMongoDBServer() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MongoDB Server"
    terminalOutput "======================================"
    log "Starting MongoDB server installation"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages curl gnupg lsb-release
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

        sudo apt update
        sudo apt install -y mongodb-org-server

        sudo systemctl start mongod
        sudo systemctl enable mongod

    elif [ "$pkgManager" = "yum" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo yum install -y mongodb-org-server

        sudo systemctl start mongod
        sudo systemctl enable mongod

    elif [ "$pkgManager" = "dnf" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo dnf install -y mongodb-org-server

        sudo systemctl start mongod
        sudo systemctl enable mongod
    else
        terminalOutput "Error: Unsupported package manager"
        log "MongoDB server installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "MongoDB server installation complete!"
    log "MongoDB server installation complete"
    pause
}

function installMongoDBClientCli() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MongoDB Client CLI"
    terminalOutput "======================================"
    log "Starting MongoDB client CLI installation"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages curl gnupg lsb-release
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

        sudo apt update
        sudo apt install -y mongodb-mongosh

    elif [ "$pkgManager" = "yum" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo yum install -y mongodb-mongosh

    elif [ "$pkgManager" = "dnf" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo dnf install -y mongodb-mongosh
    else
        terminalOutput "Error: Unsupported package manager"
        log "MongoDB client CLI installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "MongoDB client CLI installation complete!"
    if command -v mongosh >/dev/null 2>&1; then
        mongosh --version
    fi
    log "MongoDB client CLI installation complete"
    pause
}

function installMongoDBClientGui() {
    local pkgManager
    pkgManager=$(detectPackageManager)

    terminalOutput "======================================"
    terminalOutput " Installing MongoDB Client GUI"
    terminalOutput "======================================"
    log "Starting MongoDB client GUI installation"

    if [ "$pkgManager" = "apt" ]; then
        ensurePackages curl gnupg lsb-release
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

        sudo apt update
        sudo apt install -y mongodb-compass

    elif [ "$pkgManager" = "yum" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo yum install -y mongodb-compass

    elif [ "$pkgManager" = "dnf" ]; then
        sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
        sudo dnf install -y mongodb-compass
    else
        terminalOutput "Error: Unsupported package manager"
        log "MongoDB client GUI installation failed - unsupported package manager"
        pause
        return 1
    fi

    terminalOutput "MongoDB client GUI installation complete!"
    log "MongoDB client GUI installation complete"
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

function installRedisTools() {
    terminalOutput "======================================"
    terminalOutput " Installing Redis Tools"
    terminalOutput "======================================"
    log "Starting Redis tools installation"

    ensurePackages redis-tools

    terminalOutput "Redis tools installation complete!"
    redis-cli --version
    log "Redis tools installation complete"
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
function installSqlite3() {
    terminalOutput "======================================"
    terminalOutput " Installing SQLite3"
    terminalOutput "======================================"
    log "Starting SQLite3 installation"

    ensurePackages sqlite3

    terminalOutput "SQLite3 installation complete!"
    sqlite3 --version
    log "SQLite3 installation complete"
    pause
}

function showVersions() {
    local GREEN="\033[0;32m"
    local RESET="\033[0m"

    terminalOutput "${GREEN}======================================${RESET}"
    terminalOutput "${GREEN} Installed Database Versions${RESET}"
    terminalOutput "${GREEN}======================================${RESET}"
    
    terminalOutput ""
    terminalOutput "--- PostgreSQL ---"
    if command -v psql >/dev/null 2>&1; then
        local pgVersion
        local pgStatus

        pgVersion=$(psql --version 2>/dev/null)
        terminalOutput "${GREEN}${pgVersion}${RESET}"
        terminalOutput "Service status:"
        pgStatus=$(sudo systemctl is-active postgresql 2>/dev/null || echo "Service not running or not found")
        terminalOutput "${GREEN}${pgStatus}${RESET}"
    else
        terminalOutput "PostgreSQL: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- MySQL ---"
    if command -v mysql >/dev/null 2>&1; then
        local mysqlVersion
        local mysqlStatus

        mysqlVersion=$(mysql --version 2>/dev/null)
        terminalOutput "${GREEN}${mysqlVersion}${RESET}"
        terminalOutput "Service status:"
        mysqlStatus=$(sudo systemctl is-active mysql 2>/dev/null || sudo systemctl is-active mysqld 2>/dev/null || echo "Service not running or not found")
        terminalOutput "${GREEN}${mysqlStatus}${RESET}"
    else
        terminalOutput "MySQL: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- MongoDB ---"
    if command -v mongod >/dev/null 2>&1; then
        local mongoVersion
        local mongoStatus

        mongoVersion=$(mongod --version 2>/dev/null | head -n 1)
        terminalOutput "${GREEN}${mongoVersion}${RESET}"
        terminalOutput "Service status:"
        mongoStatus=$(sudo systemctl is-active mongod 2>/dev/null || echo "Service not running or not found")
        terminalOutput "${GREEN}${mongoStatus}${RESET}"
    else
        terminalOutput "MongoDB: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- Redis ---"
    if command -v redis-server >/dev/null 2>&1; then
        local redisVersion
        local redisStatus

        redisVersion=$(redis-server --version 2>/dev/null)
        terminalOutput "${GREEN}${redisVersion}${RESET}"
        terminalOutput "Service status:"
        redisStatus=$(sudo systemctl is-active redis 2>/dev/null || sudo systemctl is-active redis-server 2>/dev/null || echo "Service not running or not found")
        terminalOutput "${GREEN}${redisStatus}${RESET}"
    else
        terminalOutput "Redis: Not installed"
    fi

    terminalOutput ""
    terminalOutput "--- Redis CLI Tools ---"
    if command -v redis-cli >/dev/null 2>&1; then
        local redisCliVersion

        redisCliVersion=$(redis-cli --version 2>/dev/null)
        terminalOutput "${GREEN}${redisCliVersion}${RESET}"
    else
        terminalOutput "Redis CLI Tools: Not installed"
    fi
    
    terminalOutput ""
    terminalOutput "--- SQLite ---"
    if command -v sqlite3 >/dev/null 2>&1; then
        local sqliteVersion

        sqliteVersion=$(sqlite3 --version 2>/dev/null)
        terminalOutput "${GREEN}${sqliteVersion}${RESET}"
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
    terminalOutput "  --install-postgres          Install PostgreSQL (standard)"
    terminalOutput "  --install-postgres-server   Install PostgreSQL server only"
    terminalOutput "  --install-postgresql-client Install PostgreSQL client CLI"
    terminalOutput "  --install-postgresql-client-gui Install PostgreSQL client GUI"
    terminalOutput "  --install-mysql             Install MySQL (standard)"
    terminalOutput "  --install-mysql-server      Install MySQL server only"
    terminalOutput "  --install-mysql-client      Install MySQL client CLI"
    terminalOutput "  --install-mysql-client-gui  Install MySQL client GUI"
    terminalOutput "  --install-mongodb           Install MongoDB (standard)"
    terminalOutput "  --install-mongodb-server    Install MongoDB server only"
    terminalOutput "  --install-mongodb-client    Install MongoDB client CLI"
    terminalOutput "  --install-mongodb-client-gui Install MongoDB client GUI"
    terminalOutput "  --install-redis             Install Redis (standard)"
    terminalOutput "  --install-redis-tools       Install Redis CLI tools"
    terminalOutput "  --install-sqlite            Install SQLite (standard)"
    terminalOutput "  --install-sqlite3           Install SQLite3 CLI"
    terminalOutput "  --help                      Show this help message"
    terminalOutput ""
    terminalOutput "Menu Options:"
    terminalOutput "  1) Install PostgreSQL (standard) - PostgreSQL database server and client"
    terminalOutput "  2) Install PostgreSQL Server - PostgreSQL database server only"
    terminalOutput "  3) Install PostgreSQL Client CLI - PostgreSQL client tools only"
    terminalOutput "  4) Install PostgreSQL Client GUI - PostgreSQL GUI client only"
    terminalOutput "  5) Install MySQL (standard) - MySQL database server and client"
    terminalOutput "  6) Install MySQL Server - MySQL database server only"
    terminalOutput "  7) Install MySQL Client CLI - MySQL client tools only"
    terminalOutput "  8) Install MySQL Client GUI - MySQL GUI client only"
    terminalOutput "  9) Install MongoDB (standard) - MongoDB NoSQL database"
    terminalOutput "  10) Install MongoDB Server - MongoDB server only"
    terminalOutput "  11) Install MongoDB Client CLI - MongoDB client tools only"
    terminalOutput "  12) Install MongoDB Client GUI - MongoDB GUI client only"
    terminalOutput "  13) Install Redis (standard) - Redis in-memory data store"
    terminalOutput "  14) Install Redis Tools - Redis CLI tools only"
    terminalOutput "  15) Install SQLite (standard) - SQLite lightweight database"
    terminalOutput "  16) Install SQLite3 CLI - SQLite3 CLI only"
    terminalOutput "  17) Show Installed Versions - Display versions and status"
    terminalOutput "  18) Help - Show this help message"
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
    terminalOutput "1) Install PostgreSQL (standard)"
    terminalOutput "2) Install PostgreSQL Server"
    terminalOutput "3) Install PostgreSQL Client CLI"
    terminalOutput "4) Install PostgreSQL Client GUI"
    terminalOutput "5) Install MySQL (standard)"
    terminalOutput "6) Install MySQL Server"
    terminalOutput "7) Install MySQL Client CLI"
    terminalOutput "8) Install MySQL Client GUI"
    terminalOutput "9) Install MongoDB (standard)"
    terminalOutput "10) Install MongoDB Server"
    terminalOutput "11) Install MongoDB Client CLI"
    terminalOutput "12) Install MongoDB Client GUI"
    terminalOutput "13) Install Redis (standard)"
    terminalOutput "14) Install Redis Tools"
    terminalOutput "15) Install SQLite (standard)"
    terminalOutput "16) Install SQLite3 CLI"
    terminalOutput "17) Show Installed Versions"
    terminalOutput "18) Help"
    terminalOutput "0) Exit"
    terminalOutput "======================================"
    promptInput "Choose an option [0-18]: " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -gt 18 ]; then
        terminalOutput "Invalid input. Please enter a number between 0 and 18."
        sleep 2
        return
    fi

    case $choice in
        1) installPostgreSQL ;;
        2) installPostgresServer ;;
        3) installPostgresClient ;;
        4) installPostgresClientGui ;;
        5) installMySQL ;;
        6) installMySQLServer ;;
        7) installMySQLClientCli ;;
        8) installMySQLClientGui ;;
        9) installMongoDB ;;
        10) installMongoDBServer ;;
        11) installMongoDBClientCli ;;
        12) installMongoDBClientGui ;;
        13) installRedis ;;
        14) installRedisTools ;;
        15) installSQLite ;;
        16) installSqlite3 ;;
        17) showVersions ;;
        18) showHelp ;;
        0) terminalOutput "Exiting..."; log "Script exited by user"; exit 0 ;;
    esac
}

################################################################################################
#### Start Script with Command Line Arguments or Menu
################################################################################################

# Check if script is run with root privileges
checkRoot

# Parse command line arguments
if [[ "$1" == "--install-postgres" ]]; then
    installPostgreSQL
    exit 0
elif [[ "$1" == "--install-postgres-server" ]]; then
    installPostgresServer
    exit 0
elif [[ "$1" == "--install-postgresql-client" ]]; then
    installPostgresClient
    exit 0
elif [[ "$1" == "--install-postgresql-client-gui" ]]; then
    installPostgresClientGui
    exit 0
elif [[ "$1" == "--install-mysql" ]]; then
    installMySQL
    exit 0
elif [[ "$1" == "--install-mysql-server" ]]; then
    installMySQLServer
    exit 0
elif [[ "$1" == "--install-mysql-client" ]]; then
    installMySQLClientCli
    exit 0
elif [[ "$1" == "--install-mysql-client-gui" ]]; then
    installMySQLClientGui
    exit 0
elif [[ "$1" == "--install-mongodb" ]]; then
    installMongoDB
    exit 0
elif [[ "$1" == "--install-mongodb-server" ]]; then
    installMongoDBServer
    exit 0
elif [[ "$1" == "--install-mongodb-client" ]]; then
    installMongoDBClientCli
    exit 0
elif [[ "$1" == "--install-mongodb-client-gui" ]]; then
    installMongoDBClientGui
    exit 0
elif [[ "$1" == "--install-redis" ]]; then
    installRedis
    exit 0
elif [[ "$1" == "--install-sqlite" ]]; then
    installSQLite
    exit 0
elif [[ "$1" == "--install-redis-tools" ]]; then
    installRedisTools
    exit 0
elif [[ "$1" == "--install-sqlite3" ]]; then
    installSqlite3
    exit 0
elif [[ "$1" == "--help" ]]; then
    showHelp
    exit 0
else
    # Start interactive menu
    while true; do showMenu; done
fi
