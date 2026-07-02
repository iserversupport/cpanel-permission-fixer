#!/bin/bash
# ====================================================================
# Tool: cPanel Account Permissions & Ownership Fixer
# Maintained by: https://iserversupport.com
# Description: Safely resets files to 644 and directories to 755
#              within a specified user's public_html directory.
# ====================================================================

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: This script must be run as root."
  exit 1
fi

# Get username from argument
CPUSER=$1

if [ -z "$CPUSER" ]; then
    echo "[-] Usage: $0 <cpanel_username>"
    exit 1
fi

# Validate if the cPanel user actually exists
if [ ! -f "/var/cpanel/users/$CPUSER" ]; then
    echo "[-] Error: cPanel user '$CPUSER' does not exist on this server."
    exit 1
fi

# Dynamically fetch the user's home directory path
HOMEDIR=$(grep -E "^HOMEDIR" /var/cpanel/users/$CPUSER | cut -d= -f2)
if [ -z "$HOMEDIR" ]; then
    HOMEDIR="/home/$CPUSER"
fi

echo "[+] Starting permission correction for user: $CPUSER ($HOMEDIR)"

# 1. Reset core home folder permissions (Standard is 711 or 750 depending on suPHP/ruid2)
chown $CPUSER:$CPUSER $HOMEDIR
chmod 711 $HOMEDIR

# 2. Fix the public_html directory and contents
if [ -d "$HOMEDIR/public_html" ]; then
    echo "[+] Processing public_html directories and files..."
    
    # Fix ownership to the user
    chown -R $CPUSER:$CPUSER $HOMEDIR/public_html
    
    # Set directories to 755
    find $HOMEDIR/public_html -type d -exec chmod 755 {} \;
    
    # Set files to 644
    find $HOMEDIR/public_html -type f -exec chmod 644 {} \;
    
    # Special exception for cgi-bin if it exists (needs execution permissions)
    if [ -d "$HOMEDIR/public_html/cgi-bin" ]; then
        chmod 755 $HOMEDIR/public_html/cgi-bin
    fi
    
    echo "[+] Done. Permissions successfully reset."
else
    echo "[-] Warning: public_html directory not found for $CPUSER."
fi
