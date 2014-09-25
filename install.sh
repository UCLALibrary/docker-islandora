#!/bin/bash

. /etc/profile

if [ ! -f /var/www/sites/default/settings.php ]; then
	# Start mysql
	/usr/bin/mysqld_safe &
	# Start apache 
	service apache2 start
	sleep 5

	. /etc/profile

	# Generate random passwords 
	DRUPAL_DB="drupal"
	DRUPAL_USER="drupal"
	DRUPAL_PASSWORD='drupalAdmin'

	MYSQL_PASSWORD='test'
	
	# This is so the passwords show up in logs. 
	echo mysql root password: $MYSQL_PASSWORD
	echo drupal password: $DRUPAL_PASSWORD
	echo $MYSQL_PASSWORD > /mysql-root-pw.txt
	echo $DRUPAL_PASSWORD > /drupal-db-pw.txt
	mysqladmin -u root password $MYSQL_PASSWORD

	#setup fedora database
	mysql -u root -p$MYSQL_PASSWORD  -e "drop database fedora3";
	mysql -u root -p$MYSQL_PASSWORD  -e "create database fedora3";
	mysql -u root -p$MYSQL_PASSWORD  -e "GRANT ALL ON "fedora3".* TO 'fedoraAdmin'@'%' IDENTIFIED BY 'fedoraAdmin'";
	mysql -u root -p$MYSQL_PASSWORD  -e "GRANT ALL ON "fedora3".* TO 'fedoraAdmin'@'localhost' IDENTIFIED BY 'fedoraAdmin'";
	mysql -u root -p$MYSQL_PASSWORD  -e "flush privileges";

	# 
	# Installing Fedora
	#
	#java -jar /tmp/fcrepo-installer-3.7.0.jar
	java -jar /tmp/fcrepo-installer-3.7.0.jar /tmp/install.properties
	/usr/local/fedora/tomcat/bin/startup.sh 
	sleep 20
	/usr/local/fedora/tomcat/bin/shutdown.sh

	# 
	# Remove XACML policies
	#
	rm -v /usr/local/fedora/data/fedora-xacml-policies/repository-policies/default/deny-*
	# Copy islandora XACML policies
	mkdir /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora
	cp -v /var/www/html/drupal-7.22/sites/all/modules/islandora/policies/* /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora
	#rm $FEDORA_HOME/data/fedora-xacml-policies/repository-policies/default/deny-apim-if-not-localhost.xml
	#sed -i 's/value="enforce-policies"/value="permit-all-requests"/' /usr/local/fedora/server/config/fedora.fcfg
	/usr/local/fedora/server/bin/fedora-reload-policies.sh
	/usr/local/fedora/tomcat/bin/startup.sh 
	sleep 20
	/usr/local/fedora/tomcat/bin/shutdown.sh
	sleep 10

	# 
	# Install Drupal
	#
	service apache2 stop
	mysql -u root -p$MYSQL_PASSWORD  -e "drop database drupal";
	mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE drupal; GRANT ALL ON drupal.* TO '$DRUPAL_USER'@'localhost' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"
	mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL ON drupal.* TO 'drupal'@'%' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"
	sed -i 's/min_uid=100/min_uid=30/' /etc/suphp/suphp.conf
	sed -i 's/min_gid=100/min_gid=30/' /etc/suphp/suphp.conf
	sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/html\/drupal/' /etc/apache2/sites-available/000-default.conf
	sed -i '/DocumentRoot \/var\/www\/html\/drupal/a <Directory "/var/www/html/drupal"> \n Options Includes \n AllowOverride All \n </Directory>' /etc/apache2/sites-available/000-default.conf
	a2enmod rewrite vhost_alias
	cd /var/www/html/drupal-7.22
	ln -s  /var/www/html/drupal-7.22 /var/www/html/drupal
	chmod a+w sites/default/settings.php
	chmod a+w sites/default
	service apache2 start

	drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPAL_PASSWORD}@localhost:3306/drupal"
	drush pm-download -y views advanced_help ctools imagemagick token libraries
	drush pm-enable -y views advanced_help ctools imagemagick token libraries
	drush pm-enable -y objective_forms
	drush pm-enable -y php_lib
	service apache2 restart

	#
	# Configure Drupal Filter
	#
	cd /tmp
	wget https://github.com/Islandora/islandora_drupal_filter/releases/download/v7.1.3/fcrepo-drupalauthfilter-3.7.0.jar
	cp -v fcrepo-drupalauthfilter-3.7.0.jar $FEDORA_HOME/tomcat/webapps/fedora/WEB-INF/lib
	cd /usr/local/fedora/server/config
	mv jaas.conf jaas.conf.bk
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/jaas.conf
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/filter-drupal.xml
	#rm $FEDORA_HOME/server/config/fedora-users.xml
	#wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/fedora-users.xml

	/usr/local/fedora/tomcat/bin/startup.sh 
	sleep 20

	# Tuque library - disable peer certificate validation on tuque library
	sed -i 's/public $verifyPeer = TRUE;/public $verifyPeer = FALSE;/' /var/www/html/drupal/sites/all/libraries/tuque/HttpConnection.php

	#
	# Install islandora
	#
	cd /var/www/html/drupal-7.22
	drush pm-enable -y -u 1 islandora
	drush pm-enable -y -u 1 islandora_ocr
	drush pm-enable -y -u 1 islandora_importer
	drush pm-enable -y -u 1 islandora_solr_views
	drush pm-enable -y -u 1 islandora_solr_search
	drush pm-enable -y -u 1 islandora_paged_content
	drush pm-enable -y -u 1 islandora_xml_forms
	drush pm-enable -y -u 1 islandora_jwplayer
	drush pm-enable -y -u 1 islandora_fits
	drush pm-enable -y -u 1 islandora_bookmark
	drush pm-enable -y -u 1 islandora_solution_pack_book
	drush pm-enable -y -u 1 islandora_solution_pack_audio
	drush pm-enable -y -u 1 islandora_solution_pack_large_image
	drush pm-enable -y -u 1 islandora_solution_pack_image
	drush pm-enable -y -u 1 islandora_solution_pack_collection
	drush pm-enable -y -u 1 islandora_solution_pack_pdf
	drush pm-enable -y -u 1 islandora_solution_pack_video
	drush pm-enable -y -u 1 islandora_solution_pack_newspaper
	drush pm-enable -y -u 1 islandora_solution_pack_web_archive
	drush pm-enable -y -u 1 islandora_solution_pack_compound
	drush pm-enable -y -u 1 islandora_openseadragon
	drush pm-enable -y -u 1 islandora_marcxml
	drush pm-enable -y -u 1 islandora_internet_archive_bookreader
	drush pm-enable -y -u 1 islandora_oai
	drush pm-enable -y -u 1 islandora_batch
	drush pm-enable -y -u 1 islandora_bagit
	drush pm-enable -y -u 1 islandora_premis
	drush pm-enable -y -u 1 islandora_scholar
	drush pm-enable -y -u 1 islandora_solr_facet_pages
	drush pm-enable -y -u 1 islandora_xacml_editor
	drush pm-enable -y -u 1 islandora_xmlsitemap
	drush pm-enable -y -u 1 islandora_checksum
	drush pm-enable -y -u 1 islandora_book_batch
	drush pm-enable -y -u 1 islandora_solr_metadata
	drush pm-enable -y -u 1 islandora_image_annotation

	drush updatedb

	# Set Gsearch
	cd /tmp; unzip fedoragsearch-2.6.zip;
	cp -v fedoragsearch-2.6/fedoragsearch.war /usr/local/fedora/tomcat/webapps

	# Set Solr
	cd /tmp; tar -xzvf solr-4.2.0.tgz; 
	mkdir -p /usr/local/fedora/solr; 
	cp -Rv solr-4.2.0/example/solr/* /usr/local/fedora/solr; 
	cp -v solr-4.2.0/dist/solr-4.2.0.war /usr/local/fedora/tomcat/webapps/solr.war

	/usr/local/fedora/tomcat/bin/shutdown.sh
	sleep 10
	/usr/local/fedora/tomcat/bin/startup.sh
	sleep 20

	cd $FEDORA_HOME/tomcat/webapps/fedoragsearch/FgsConfig/
	rm fgsconfig-basic-for-islandora.properties
	wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/fgsconfig-basic-for-islandora.properties
	ant -f fgsconfig-basic.xml
	
	#cp /usr/local/fedora/tomcat/webapps/fedoragsearch/FgsConfig/configForIslandora/fgsconfigFinal/index/FgsIndexconf/schema-4.2.0-for-fgs-2.6.xml $FEDORA_HOME/solr/collection1/conf/schema.xml
	#cp /usr/local/fedora/tomcat/webapps/fedoragsearch/FgsConfig/configProductionSolr/fgsconfigFinal/index/FgsIndex/conf/schema-4.2.0-for-fgs-2.6.xml $FEDORA_HOME/solr/collection1/conf/schema.xml
	/usr/local/fedora/tomcat/bin/shutdown.sh
	sleep 10
	/usr/local/fedora/tomcat/bin/startup.sh
	sleep 10
	service apache2 restart
	
fi
#supervisord -n
