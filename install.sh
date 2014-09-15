#!/bin/bash

. /etc/profile

if [ ! -f /var/www/sites/default/settings.php ]; then
	# Start mysql
	/usr/bin/mysqld_safe &
	# Start apache 
	service apache2 start
	sleep 10s
	# Generate random passwords 
	DRUPAL_DB="drupal"
	MYSQL_PASSWORD='test'
	DRUPAL_PASSWORD='drupalAdmin'
	# This is so the passwords show up in logs. 
	echo mysql root password: $MYSQL_PASSWORD
	echo drupal password: $DRUPAL_PASSWORD
	echo $MYSQL_PASSWORD > /mysql-root-pw.txt
	echo $DRUPAL_PASSWORD > /drupal-db-pw.txt
	mysqladmin -u root password $MYSQL_PASSWORD 

	mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE drupal; GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"
	sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
	a2enmod rewrite vhost_alias
	cd /var/www/drupal-7.22
	drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPAL_PASSWORD}@localhost:3306/drupal"
	drush pm-download views advanced_help ctools imagemagick token libraries
	drush pm-enable views advanced_help ctools imagemagick token libraries

	#setup fedora database
	mysql -u root -ptest  -e "create database fedora3";
	mysql -u root -ptest  -e "GRANT ALL PRIVILEGES ON "fedora3".* TO 'fedoraAdmin'@'%' IDENTIFIED BY 'fedoraAdmin' WITH GRANT OPTION";
	mysql -u root -ptest  -e "flush privileges";

	# setup drupal database 
	mysql -u root -ptest  -e "create database drupal";
	mysql -u root -ptest  -e "GRANT ALL PRIVILEGES ON "drupal".* TO 'drupal'@'%' IDENTIFIED BY 'drupalAdmin' WITH GRANT OPTION";
	mysql -u root -ptest  -e "flush privileges";

	. /etc/profile
	java -jar /tmp/fcrepo-installer-3.7.0.jar

	$FEDORA_HOME/tomcat/bin/startup.sh
	sleep 3s
	$FEDORA_HOME/tomcat/bin/shutdown.sh
	sleep 3s

	rm -v /usr/local/fedora/data/fedora-xacml-policies/repository-policies/default/deny-purge-*
	mkdir /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora

	cd /tmp
	wget https://github.com/Islandora/islandora_drupal_filter/releases/download/v7.1.3/fcrepo-drupalauthfilter-3.7.0.jar
	cp -v fcrepo-drupalauthfilter-3.7.0.jar $FEDORA_HOME/tomcat/webapps/fedora/WEB-INF/lib
	cd /usr/local/fedora/server/config
	rm jaas.conf
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/jaas.conf
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/filter-drupal.xml
	rm $FEDORA_HOME/server/config/fedora-users.xml
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/fedora-users.xml

	cd $FEDORA_HOME/tomcat/webapps/fedoragsearch/FgsConfig/
	rm fgsconfig-basic-for-islandora.properties
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/fgsconfig-basic-for-islandora.properties
	ant -f fgsconfig-basic.xml

	echo "ciaoooooooo"

	$FEDORA_HOME/tomcat/bin/startup.sh

	sleep 10s

	# Copy islandora XACML policies
	cp -v /var/www/islandora/sites/all/modules/islandora/policies/* /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora
	rm $FEDORA_HOME/data/fedora-xacml-policies/repository-policies/default/deny-apim-if-not-localhost.xml
	
fi
#supervisord -n
