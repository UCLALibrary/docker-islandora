#!/bin/bash

. /etc/profile

# Start mysql
service mysql start
# Start apache 
service apache2 start

# Start Fedora server
$FEDORA_HOME/tomcat/bin/startup.sh
