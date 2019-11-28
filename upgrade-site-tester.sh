#!/bin/bash

# Notes: A script to test a variety of sites on a shared cPanel server before, during and after a software upgrade.
#
# Author: Ashley Cawley // ash@ashleycawley.co.uk // @ashleycawley

# Variables
SAVEIFS=$IFS	# Backing up the delimiter used by arrays to differentiate between different data in the array (prior to changing it)
IFS=$'\n'	# Changing the delimiter used by arrays from a space to a new line, this allows a list of users (on new lines) to be stored in to an array
NUMBER_OF_SITES="20"
RANDOM_SITES=$(cat /etc/localdomains | shuf -n $NUMBER_OF_SITES) # Variable needs to be below $NUMBER_OF_SITES

# Functions

# Main Script
cat /dev/null > /tmp/online-sites.log # Clears temporary log from any prior runs

# Menu asking the user if this is the first run or post upgrade testing
MENU_OPTION=$(whiptail --title "Upgrade Site Tester" --menu "Choose an option" 25 78 16 \
"First Run" "Gathers a list of working sites." \
"Post-Upgrade Check" "Runs tests on the previously gathered list of sites that were working." 3>&1 1>&2 2>&3)

case $MENU_OPTION in
    "First Run") FIRST_RUN="YES" ;;
    "Post-Upgrade Check") FIRST_RUN="NO"
    esac

if [ $FIRST_RUN = "YES" ]
then
    for SITE in $RANDOM_SITES
    do
        # Tests site
        RESULT=$(curl -Is https://$SITE | grep 'HTTP/1.1 200 OK')

        echo "$SITE"
        echo "$RESULT"
        echo
        echo

        [[ $RESULT =~ "200 OK" ]] && echo "$SITE" >> /tmp/online-sites.log



        #  case $RESULT in
        #      "HTTP/1.1 200 OK") echo "200 OK :-)" ;;
        #      *) echo "Not OK ;----("
        #  esac

    done
fi

IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

# Exit
exit 0
