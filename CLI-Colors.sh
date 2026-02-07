#!/bin/bash
# File: 
# Author: Michael Brown
# Date: 
# Description: 

################################################################################################
####   Colors for text as variables 
################################################################################################
####
####    Link: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
####    Notes: Link above is where this came from
####
####    Example:
####        RED='\033[0;31m'
####        NC='\033[0m' # No Color
####        printf "I ${text_Red}love${text_reset} Stack Overflow\n"
####
################################################################################################


# Reset
text_reset='\033[0m'       # Text Reset

# Regular Colors
text_Black='\033[0;30m'        # Black
text_Red='\033[0;31m'          # Red
text_Green='\033[0;32m'        # Green
text_Yellow='\033[0;33m'       # Yellow
text_Blue='\033[0;34m'         # Blue
text_Purple='\033[0;35m'       # Purple
text_Cyan='\033[0;36m'         # Cyan
text_White='\033[0;37m'        # White

# Bold
text_BBlack='\033[1;30m'       # Black
text_BRed='\033[1;31m'         # Red
text_BGreen='\033[1;32m'       # Green
text_BYellow='\033[1;33m'      # Yellow
text_BBlue='\033[1;34m'        # Blue
text_BPurple='\033[1;35m'      # Purple
text_BCyan='\033[1;36m'        # Cyan
text_BWhite='\033[1;37m'       # White

# Underline
text_UBlack='\033[4;30m'       # Black
text_URed='\033[4;31m'         # Red
text_UGreen='\033[4;32m'       # Green
text_UYellow='\033[4;33m'      # Yellow
text_UBlue='\033[4;34m'        # Blue
text_UPurple='\033[4;35m'      # Purple
text_UCyan='\033[4;36m'        # Cyan
text_UWhite='\033[4;37m'       # White

# Background
text_On_Black='\033[40m'       # Black
text_On_Red='\033[41m'         # Red
text_On_Green='\033[42m'       # Green
text_On_Yellow='\033[43m'      # Yellow
text_On_Blue='\033[44m'        # Blue
text_On_Purple='\033[45m'      # Purple
text_On_Cyan='\033[46m'        # Cyan
text_On_White='\033[47m'       # White

# High Intensity
text_IBlack='\033[0;90m'       # Black
text_IRed='\033[0;91m'         # Red
text_IGreen='\033[0;92m'       # Green
text_IYellow='\033[0;93m'      # Yellow
text_IBlue='\033[0;94m'        # Blue
text_IPurple='\033[0;95m'      # Purple
text_ICyan='\033[0;96m'        # Cyan
text_IWhite='\033[0;97m'       # White

# Bold High Intensity
text_BIBlack='\033[1;90m'      # Black
text_BIRed='\033[1;91m'        # Red
text_BIGreen='\033[1;92m'      # Green
text_BIYellow='\033[1;93m'     # Yellow
text_BIBlue='\033[1;94m'       # Blue
text_BIPurple='\033[1;95m'     # Purple
text_BICyan='\033[1;96m'       # Cyan
text_BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
text_On_IBlack='\033[0;100m'   # Black
text_On_IRed='\033[0;101m'     # Red
text_On_IGreen='\033[0;102m'   # Green
text_On_IYellow='\033[0;103m'  # Yellow
text_On_IBlue='\033[0;104m'    # Blue
text_On_IPurple='\033[0;105m'  # Purple
text_On_ICyan='\033[0;106m'    # Cyan
text_On_IWhite='\033[0;107m'   # White