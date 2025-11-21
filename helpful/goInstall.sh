#!/usr/bin/env bash
set -euo pipefail

# goInstall.sh
# This file defines a single function: package_install_go()
# and then (currently) invokes it immediately at the end of the file.
#
# IMPORTANT: because the function is called unconditionally at the bottom,
# sourcing this file (source ./goInstall.sh) will also run the installer.
# If you want to *only* import the function without executing it, remove or
# comment out the final line that calls package_install_go.
#
# Current behavior when the file is executed (or sourced):
#  - Installs the default Go version 1.25.1
#  - Uses /usr/local/src as a staging area and /usr/local as the install dir
#  - Removes any existing /usr/local/go
#  - Downloads the official go1.25.1.linux-amd64.tar.gz and extracts it
#  - Adds export PATH=$PATH:/usr/local/go/bin to the current user's ~/.bashrc
#  - Sources ~/.bashrc (best-effort) so interactive shells get the new PATH
#
# Notes on the function itself (callable directly if you remove the auto-run):
#  - Function name: package_install_go
#  - Parameters accepted by the function (when called directly):
#      $1: GO_VERSION (optional) — default is 1.25.1
#      $2: CONFIRM (optional) — set to "true" or "1" to prompt before running
#  - Exit status: returns 3 if neither wget nor curl are available
#  - The function uses sudo for operations under /usr/local and /usr/local/src
#
# Usage examples:
#  - Current file (will install default immediately):
#      ./goInstall.sh
#  - To call the function with a custom version (recommended: edit out auto-run):
#      # remove or comment the final package_install_go line
#      source ./goInstall.sh
#      package_install_go 1.26.0 true
#
# Security & safety:
#  - The script runs commands with sudo and writes to system locations; review
#    the code before running on a production machine.

package_install_go() {
    # Default Go version can be overridden by the first argument
    local GO_VERSION="${1:-1.25.1}"
    # If CONFIRM is true (string "true" or "1"), the user will be prompted
    local CONFIRM="${2:-false}"

    # TARBALL and URL are computed from the version
    local TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
    local URL="https://go.dev/dl/${TARBALL}"

    # STAGING is where we download the tarball; INSTALL_DIR is where Go is installed
    local STAGING="/usr/local/src"
    local INSTALL_DIR="/usr/local"

    # PATH_LINE is the exact line we will add to ~/.bashrc (if missing) so that
    # /usr/local/go/bin is available on the user's PATH in future shells.
    local PATH_LINE="export PATH=\$PATH:/usr/local/go/bin"

    # Optional confirmation prompt for interactive runs
    if [[ "$CONFIRM" == "true" || "$CONFIRM" == "1" ]]; then
        read -r -p "Would you like to install Go $GO_VERSION now? (Y/N) " resp
        case "$resp" in
            [Yy]*) ;;             # proceed on Y/y
            *) echo "Cancelled."; return 0 ;;  # cancel on anything else
        esac
    fi

    # Ensure staging directory exists and is writable
    echo "Preparing staging directory: $STAGING"
    sudo mkdir -p "$STAGING"
    # Try to change owner to the current user so downloads don't require sudo
    # chown may fail on some systems when run by non-root; ignore failures
    sudo chown --quiet "$(id -u):$(id -g)" "$STAGING" || true

    # Choose a downloader: prefer wget, fall back to curl. Fail if neither exist.
    if command -v wget >/dev/null 2>&1; then
        echo "Downloading $TARBALL with wget..."
        # -P sets destination directory
        wget -P "$STAGING" "$URL"
    elif command -v curl >/dev/null 2>&1; then
        echo "Downloading $TARBALL with curl..."
        # -L to follow redirects, -o to specify output path
        curl -L -o "$STAGING/$TARBALL" "$URL"
    else
        echo "Error: neither wget nor curl is installed." >&2
        return 3
    fi

    # Remove any previously-installed Go tree; this ensures the install is clean
    echo "Removing existing Go installation at $INSTALL_DIR/go (if any)..."
    sudo rm -rf "$INSTALL_DIR/go"

    # Extract the downloaded tarball into the installation directory
    echo "Extracting $TARBALL to $INSTALL_DIR..."
    # Using sudo because /usr/local is owned by root on many systems
    sudo tar -C "$INSTALL_DIR" -xzf "$STAGING/$TARBALL"

    # Remove the tarball to keep /usr/local/src tidy
    echo "Removing tarball $STAGING/$TARBALL"
    sudo rm -f "$STAGING/$TARBALL"

    # Ensure the PATH line exists in ~/.bashrc so future shells have Go on PATH
    echo "Ensuring Go bin is on PATH in ~/.bashrc"
    # Use an exact-line check (grep -qxF) to avoid adding duplicates
    if ! grep -qxF "$PATH_LINE" "$HOME/.bashrc" 2>/dev/null; then
        echo "$PATH_LINE" >> "$HOME/.bashrc"
        echo "Appended PATH entry to ~/.bashrc"
    else
        echo "PATH entry already present in ~/.bashrc"
    fi

    # Source ~/.bashrc so that if the user sourced this script interactively
    # they get immediate access to the new PATH. This will be a no-op for
    # non-interactive invocations and we ignore failures.
    echo "Reloading shell configuration (this only affects the current process if sourced)"
    source "$HOME/.bashrc" 2>/dev/null || true

    echo "Go $GO_VERSION installed successfully."
}

# NOTE: this file currently calls the function automatically when loaded.
# The following line performs that auto-run. Remove/comment it if you only
# want to import the function without executing it.
package_install_go