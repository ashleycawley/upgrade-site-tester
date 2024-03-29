#!/bin/bash

# Notes: A script to test a variety of sites on a shared cPanel server before, during and after a software upgrade.
#
# Author: Ashley Cawley // ash@ashleycawley.co.uk // @ashleycawley

# Variables
SAVEIFS=$IFS	# Backing up the delimiter used by arrays to differentiate between different data in the array (prior to changing it)
IFS=$'\n'	# Changing the delimiter used by arrays from a space to a new line, this allows a list of users (on new lines) to be stored in to an array
CURL_TIMEOUT="2" # Number of seconds

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Functions

# Main Script

# Menu asking the user if this is the first run or post upgrade testing
MENU_OPTION=$(whiptail --title "Upgrade Site Tester" --menu "Choose an option" 20 60 5 \
"First Run" "Gathers a list of working sites." \
"Post Upgrade Test" "Runs tests on previously working sites." 3>&1 1>&2 2>&3)

case $MENU_OPTION in
    "First Run") FIRST_RUN="YES" ;;
    "Post-Upgrade Check") FIRST_RUN="NO"
    esac

if [ "$FIRST_RUN" = "YES" ]
then

    NUMBER_OF_SITES=$(whiptail --inputbox "Number of Sites" 8 78 30 --title "Number of Sites" 3>&1 1>&2 2>&3)

    # Picks a however many sites the user specified at random from the server
    RANDOM_SITES=$(cat /etc/localdomains | shuf -n $NUMBER_OF_SITES) # Variable needs to be below $NUMBER_OF_SITES

    for SITE in $RANDOM_SITES
    do
        # Tests sites
        RESULT=$(curl --max-time $CURL_TIMEOUT -Is https://$SITE | grep 'HTTP/1.1 200 OK')

        # Logs working websites into a temporary log file
        [[ $RESULT =~ "200 OK" ]] && echo "$SITE" >> /tmp/online-sites.log && echo "$SITE saved for later re-testing."

    done

    # Chances are that not all of the X number of sites the user choose will be OK - 200 to start with so this while loop
    # checks to see if the log of working sites matches the number the user specified, if it doesn't then it continues
    # adding additional sites to the list until it does match that number
    while [ `cat /tmp/online-sites.log | wc -l` -ne $NUMBER_OF_SITES ]
    do
        ADDITIONAL_SITES=$(cat /etc/localdomains | shuf -n 1) # Variable needs to be below $NUMBER_OF_SITES

        for SITE in $ADDITIONAL_SITES
        do
            # Tests sites
            RESULT=$(curl --max-time $CURL_TIMEOUT -Is https://$SITE | grep 'HTTP/1.1 200 OK')

            # Logs working websites into a temporary log file
            [[ $RESULT =~ "200 OK" ]] && echo "$SITE" >> /tmp/online-sites.log && echo "$SITE saved for later re-testing."

            # Removes duplicates from the list of sites
            sort -u /tmp/online-sites.log > /tmp/online-sites.log-dedup
            cat /tmp/online-sites.log-dedup > /tmp/online-sites.log
            rm -f /tmp/online-sites.log-dedup

        done
    done

    IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

    exit 0

else

    echo && echo "Post Upgrade Testing..."

    for SITE in $(cat /tmp/online-sites.log)``
    do
        #echo "OK - $SITE" | tee -a /tmp/online-sites.log-results

        # Tests site
        RESULT=$(curl --max-time $CURL_TIMEOUT -Is https://$SITE | grep 'HTTP/1.1 200 OK')

        [[ $RESULT =~ "200 OK" ]] && echo -e "OK - $SITE" | tee -a /tmp/online-sites.log-results

        [[ ! $RESULT =~ "200 OK" ]] && echo -e "${YELLOW}ERROR${NC} - ${YELLOW}$SITE${NC} did not return a 200 and requires further investigation." | tee -a /tmp/online-sites.log-results

        sleep 1

    done

    # Compiles a Summary review for the Engineer
    NUMBER_OF_SITES_TESTED=$(cat /tmp/online-sites.log | wc -l)
    NUMBER_OF_OK_SITES=$(grep -i OK /tmp/online-sites.log-results | wc -l)
    NUMBER_OF_FAILED_SITES=$(grep -i ERROR /tmp/online-sites.log-results | wc -l)
    echo && echo -e "Testing Summary: ${YELLOW}$NUMBER_OF_SITES_TESTED${NC} websites tested and the following was discovered..."
    echo -e "${GREEN}OK${NC} - $NUMBER_OF_OK_SITES"
    echo -e "${YELLOW}Failed ${NC}- $NUMBER_OF_FAILED_SITES"
    echo
    rm -f /tmp/online-sites.log-results # Deletes temporary stats file


    cat /dev/null > /tmp/online-sites.log # Clears temporary log from any prior runs

fi



IFS=$SAVEIFS # Resets $IFS this changes the delimiter that arrays use from new lines (\n) back to just spaces (which is what it normally is)

# Exit
exit 0
