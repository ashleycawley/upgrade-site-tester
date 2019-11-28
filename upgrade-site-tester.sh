#!/bin/bash

# Notes: A script to test a variety of sites on a shared cPanel server before, during and after a software upgrade.
#
# Author: Ashley Cawley // ash@ashleycawley.co.uk // @ashleycawley

# Variables
SAVEIFS=$IFS	# Backing up the delimiter used by arrays to differentiate between different data in the array (prior to changing it)
IFS=$'\n'	# Changing the delimiter used by arrays from a space to a new line, this allows a list of users (on new lines) to be stored in to an array
NUMBER_OF_SITES="30"
RANDOM_SITES=$(cat /etc/localdomains | shuf -n $NUMBER_OF_SITES) # Variable needs to be below $NUMBER_OF_SITES
CURL_TIMEOUT="5" # Number of seconds
# Functions

# Main Script
#cat /dev/null > /tmp/online-sites.log # Clears temporary log from any prior runs


# Menu asking the user if this is the first run or post upgrade testing
MENU_OPTION=$(whiptail --title "Upgrade Site Tester" --menu "Choose an option" 20 60 5 \
"First Run" "Gathers a list of working sites." \
"Post Upgrade Test" "Runs tests on previously working sites." 3>&1 1>&2 2>&3)

case $MENU_OPTION in
    "First Run") FIRST_RUN="YES" ;;
    "Post-Upgrade Check") FIRST_RUN="NO"
    esac

if [ $FIRST_RUN = "YES" ]
then
    for SITE in $RANDOM_SITES
    do
        # Tests site
        RESULT=$(curl --max-time $CURL_TIMEOUT -Is https://$SITE | grep 'HTTP/1.1 200 OK')

        # Logs working websites into a temporary log file
        [[ $RESULT =~ "200 OK" ]] && echo "$SITE" >> /tmp/online-sites.log && echo "$SITE saved for later re-testing."

    done

    IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

    exit 0

else

    echo "POST UPGRADE MODE ENABLED..."

    for SITE in $(cat /tmp/online-sites.log)
    do
        echo "Testing... $SITE"

        # Tests site
        RESULT=$(curl --max-time $CURL_TIMEOUT -Is https://$SITE | grep 'HTTP/1.1 200 OK')

        [[ ! $RESULT =~ "200 OK" ]] && echo "The is a problem with $SITE" && echo "Result: `curl --max-time $CURL_TIMEOUT -Is https://$SITE | head -n 1`"

        sleep 2

    done

    cat /dev/null > /tmp/online-sites.log # Clears temporary log from any prior runs

fi



IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

# Exit
exit 0
