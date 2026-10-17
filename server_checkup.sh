#!/bin/bash

set -u
 
#Root access is needed to read /etc/shadow
if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run with sudo: sudo $0"
   exit 1
fi

for tool in ss awk find apt; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool"; exit 1; }
done

ISSUES=0
 
echo "Server checkup - $(date)"
echo "============================"


#Check 1 : Listening ports (information only)
echo "1. Listening ports:"
PORTS=$(ss -tuln | tail -n +2)
if [ -z "$PORTS" ]; then
    echo "none"
else
    echo "$PORTS"
fi

#Check 2 : Users with an empty password
echo "2. Users with empty password:"
EMPTY_PASSWORD=$( awk -F: '($2 == "") {print $1}' /etc/shadow)
if [ -n "$EMPTY_PASSWORD" ]; then
   echo " WARNING: $EMPTY_PASSWORD"
    ISSUES=$((ISSUES + 1))
else
   echo " OK "
   
fi

#Check 3 : Extra users with root permission
echo "3. Extra users with root permission:"
EXTRA_ROOT=$(awk -F: '($3 == 0 && $1 !="root") {print $1}' /etc/passwd)
if [ -n "$EXTRA_ROOT" ]; then
   echo " WARNING: $EXTRA_ROOT"
    ISSUES=$((ISSUES + 1))
else 
   echo " OK "
fi

#Check 4 : files anyone can write to
echo "4. World-writable files (in /etc /home /var):"
WRITABLE=$(find /etc /home /var -xdev -type f -perm -0002 2>/dev/null)
if [ -n "$WRITABLE" ]; then
   echo " WARNING: found these (first 10):"
   echo "$WRITABLE" | head -n 10
    ISSUES=$((ISSUES + 1))
else
   echo " OK "
fi

#Check 5: pending updates (information only)
echo "5. Pending updates (not all are security fixes):"
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable from")
echo "$UPDATES packages"

echo "==================================="
echo "Issues found: $ISSUES"


