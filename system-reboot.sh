#!/bin/bash
# File: system-rebootV2.sh
# Author: Michael Brown
# Version: 2.0.0
# Date: 10/5/2025
# Description: Enhanced system restart utility with flexible scheduling, validation, and status checking
# Compatible with: Ubuntu, AWS Linux, CentOS, RHEL, and most Linux distributions

# Example usage:
# ./system-rebootV2.sh -m 20    # Restart in 20 minutes
# ./system-rebootV2.sh -h 1     # Restart in 1 hour
# ./system-rebootV2.sh -d 1     # Restart in 1 day
# ./system-rebootV2.sh -n       # Immediate restart
# ./system-rebootV2.sh -c       # Cancel any scheduled restart
# ./system-rebootV2.sh -s       # Show restart status
# ./system-rebootV2.sh -t       # Test mode (dry run)
# ./system-rebootV2.sh --help   # Show detailed help
# ./system-rebootV2.sh          # Interactive mode

################################################################################################
#### Functions
################################################################################################

function showUsage() {
    echo "====================================="
    echo " System Restart Manager v2.0.0"
    echo "====================================="
    echo "Usage: $0 [OPTIONS]"
    echo "Enhanced system restart utility with flexible scheduling and validation"
    echo ""
    echo "Options:"
    echo "  -m <minutes>    Schedule restart in specified minutes (1-1440)"
    echo "  -h <hours>      Schedule restart in specified hours (1-24)"
    echo "  -d <days>       Schedule restart in specified days (1-7)"
    echo "  -n              Restart immediately (no confirmation)"
    echo "  -c              Cancel any scheduled restart"
    echo "  -s              Show current restart status"
    echo "  --check         Quick status check with multiple methods"
    echo "  -t              Test mode (show what would happen, don't execute)"
    echo "  -v              Verbose output"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -m 20        # Restart in 20 minutes"
    echo "  $0 -h 1         # Restart in 1 hour"
    echo "  $0 -d 1         # Restart in 1 day"
    echo "  $0 -n           # Restart now"
    echo "  $0 -c           # Cancel restart"
    echo "  $0 -s           # Show status"
    echo "  $0 -t -m 30     # Test: show what 30-minute restart would do"
    echo ""
    echo "Time Limits:"
    echo "  Minutes: 1-1440 (24 hours max)"
    echo "  Hours:   1-24"
    echo "  Days:    1-7"
    echo "====================================="
}

function validateTimeInput() {
    local value=$1
    local unit=$2
    
    # Check if value is numeric
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Error: '$value' is not a valid number"
        return 1
    fi
    
    # Validate ranges based on unit
    case "$unit" in
        "minutes")
            if [ "$value" -lt 1 ] || [ "$value" -gt 1440 ]; then
                echo "Error: Minutes must be between 1 and 1440 (24 hours)"
                return 1
            fi
            ;;
        "hours")
            if [ "$value" -lt 1 ] || [ "$value" -gt 24 ]; then
                echo "Error: Hours must be between 1 and 24"
                return 1
            fi
            ;;
        "days")
            if [ "$value" -lt 1 ] || [ "$value" -gt 7 ]; then
                echo "Error: Days must be between 1 and 7"
                return 1
            fi
            ;;
        *)
            echo "Error: Invalid time unit '$unit'"
            return 1
            ;;
    esac
    
    return 0
}

function showRestartStatus() {
    echo "====================================="
    echo " System Restart Status"
    echo "====================================="
    
    # Check multiple ways for scheduled shutdown/restart
    local restart_scheduled=false
    local restart_info=""
    
    # Method 1: Check for shutdown command process
    if pgrep -f "shutdown.*-r" > /dev/null 2>&1; then
        restart_scheduled=true
        restart_info="Shutdown process detected"
    fi
    
    # Method 2: Check systemd shutdown target
    if systemctl list-jobs | grep -q "shutdown.target\|reboot.target"; then
        restart_scheduled=true
        restart_info="System shutdown/reboot job active"
    fi
    
    # Method 3: Check for shutdown schedule file
    if [ -f /run/systemd/shutdown/scheduled ]; then
        restart_scheduled=true
        restart_info="Systemd shutdown scheduled"
        # Try to read the schedule details
        if [ -r /run/systemd/shutdown/scheduled ]; then
            schedule_details=$(cat /run/systemd/shutdown/scheduled 2>/dev/null)
            if [ -n "$schedule_details" ]; then
                restart_info="$restart_info - $schedule_details"
            fi
        fi
    fi
    
    # Method 4: Check recent systemd journal logs
    recent_shutdown=$(journalctl --no-pager -n 10 --since "5 minutes ago" 2>/dev/null | grep -i "scheduled.*shutdown\|scheduled.*reboot" | tail -1)
    if [ -n "$recent_shutdown" ]; then
        restart_scheduled=true
        restart_info="Recent schedule: $recent_shutdown"
    fi
    
    # Display results
    if [ "$restart_scheduled" = true ]; then
        echo "Status: Restart is SCHEDULED"
        echo "Details: $restart_info"
        
        # Try to get more specific timing information
        shutdown_msg=$(wall 2>&1 | grep -i "reboot\|shutdown" | head -1)
        if [ -n "$shutdown_msg" ]; then
            echo "Message: $shutdown_msg"
        fi
    else
        echo "Status: No restart scheduled"
        echo "Note: If you just scheduled a restart, it may take a moment to appear in status"
    fi
    
    echo "Current time: $(date +'%a %Y-%m-%d %T %Z')"
    echo ""
    echo "To check if a restart was recently scheduled:"
    echo "  journalctl --no-pager -n 5 | grep -i shutdown"
    echo "====================================="
}

function testMode() {
    local minutes=$1
    
    echo "====================================="
    echo " TEST MODE - No actual restart"
    echo "====================================="
    echo "Would schedule restart in: $minutes minutes"
    echo "Current time: $(date +'%a %Y-%m-%d %T %Z')"
    
    # Calculate restart time
    restart_time=$(date -d "+$minutes minutes" +'%a %Y-%m-%d %T %Z' 2>/dev/null || echo "$minutes minutes from now")
    echo "Scheduled restart time: $restart_time"
    
    echo "Command that would be executed: sudo shutdown -r +$minutes"
    echo "====================================="
}

function systemReboot() {
    # Text colors
    local text_Red='\033[0;31m'
    local text_Green='\033[0;32m'
    local text_Yellow='\033[1;33m'
    local text_reset='\033[0m'
    
    # System time message
    local timeNowMessage="Current system time: $(date +'%a %Y-%m-%d %T %Z')"
    
    # Parse command line arguments
    local restartInMinutes=0
    local immediateRestart=false
    local cancelRestart=false
    local promptUser=true
    local testMode=false
    local verbose=false
    
    # If no arguments provided, prompt user
    if [ $# -eq 0 ]; then
        read -p "Do you want to reboot now? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            printf "\n${text_Red}"
            printf "${timeNowMessage}\n"
            sudo reboot now
            printf "${text_reset}"
        else
            echo "Restart cancelled."
        fi
        return 0
    fi
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--minutes)
                if [[ -z "$2" ]]; then
                    echo "Error: -m requires a numeric value (minutes)"
                    return 1
                fi
                if ! validateTimeInput "$2" "minutes"; then
                    return 1
                fi
                restartInMinutes=$2
                promptUser=false
                shift 2
                ;;
            -h|--hours)
                if [[ -z "$2" ]]; then
                    echo "Error: -h requires a numeric value (hours)"
                    return 1
                fi
                if ! validateTimeInput "$2" "hours"; then
                    return 1
                fi
                restartInMinutes=$(($2 * 60))
                promptUser=false
                shift 2
                ;;
            -d|--days)
                if [[ -z "$2" ]]; then
                    echo "Error: -d requires a numeric value (days)"
                    return 1
                fi
                if ! validateTimeInput "$2" "days"; then
                    return 1
                fi
                restartInMinutes=$(($2 * 24 * 60))
                promptUser=false
                shift 2
                ;;
            -n|--now)
                immediateRestart=true
                promptUser=false
                shift
                ;;
            -c|--cancel)
                cancelRestart=true
                promptUser=false
                shift
                ;;
            -s|--status)
                showRestartStatus
                return 0
                ;;
            --check)
                echo "Quick status check methods:"
                echo "1. Check for shutdown processes:"
                ps aux | grep -E "[s]hutdown|[r]eboot" 
                echo ""
                echo "2. Check systemd jobs:"
                systemctl list-jobs 2>/dev/null | grep -E "shutdown|reboot" || echo "No shutdown/reboot jobs"
                echo ""
                echo "3. Check recent logs:"
                journalctl --no-pager -n 5 --since "2 minutes ago" 2>/dev/null | grep -i -E "shutdown|reboot|restart" || echo "No recent shutdown logs"
                return 0
                ;;
            -t|--test)
                testMode=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --help)
                showUsage
                return 0
                ;;
            *)
                echo "Error: Unknown option '$1'"
                showUsage
                return 1
                ;;
        esac
    done
    
    # Execute the appropriate action
    if [ "$cancelRestart" = true ]; then
        printf "${text_Green}"
        echo "Cancelling any scheduled restart..."
        sudo shutdown -c
        printf "${text_reset}"
        return 0
    elif [ "$immediateRestart" = true ]; then
        printf "\n${text_Red}"
        printf "${timeNowMessage}\n"
        echo "Restarting system immediately..."
        sudo reboot now
        printf "${text_reset}"
        return 0
    elif [ "$restartInMinutes" -gt 0 ]; then
        # Handle test mode
        if [ "$testMode" = true ]; then
            testMode "$restartInMinutes"
            return 0
        fi
        
        # Schedule restart
        if [ "$verbose" = true ]; then
            echo "Executing: sudo shutdown -r +$restartInMinutes"
        fi
        
        output=$(sudo shutdown -r +$restartInMinutes 2>&1 | sed "s/, use 'shutdown -c' to cancel.//")
        
        printf "\n${text_Yellow}"
        printf "\t\tThe computer will restart in ${restartInMinutes} minutes.\n\n"
        printf "\t\t${timeNowMessage}\n"
        
        # Calculate and show restart time
        restart_time=$(date -d "+$restartInMinutes minutes" +'%a %Y-%m-%d %T %Z' 2>/dev/null || echo "$restartInMinutes minutes from now")
        printf "\t\tScheduled restart time: ${restart_time}\n"
        
        if [ "$verbose" = true ]; then
            printf "\t\t${output}\n"
        fi
        
        printf "\n\t\tUse '$0 -c' to cancel.\n"
        printf "\t\tUse '$0 -s' to check status.\n"
        printf "${text_reset}\n"
        return 0
    fi
}

################################################################################################
#### Main Execution
################################################################################################

# Call the main function with all arguments
systemReboot "$@"
