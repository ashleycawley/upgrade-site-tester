# upgrade-site-tester
Designed to test a variety of sites on a shared cPanel server after a software upgrade

## Installation / Run
root permissions are required as the script needs access to /etc/localdomains file to grab a list of all websites on the server.
```
wget https://raw.githubusercontent.com/ashleycawley/upgrade-site-tester/master/upgrade-site-tester.sh
chmod +x upgrade-site-tester.sh
./upgrade-site-tester.sh
```
