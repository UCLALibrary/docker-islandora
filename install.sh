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
	#sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
	sed -i '/DocumentRoot \/var\/www\/html/a AllowOverride All' /etc/apache2/sites-available/000-default.conf
	a2enmod rewrite vhost_alias
	cd /var/www/drupal-7.22
	drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPAL_PASSWORD}@localhost:3306/drupal"
	drush pm-download -y views advanced_help ctools imagemagick token libraries
	drush pm-enable -y views advanced_help ctools imagemagick token libraries

	drush pm-enable -y objective_forms
	drush pm-enable -y php_lib

	drush pm-enable -y islandora
	drush pm-enable -y islandora_solution_pack_audio
	drush pm-enable -y islandora_ocr
	drush pm-enable -y islandora_importer
	drush pm-enable -y islandora_solution_pack_book
	drush pm-enable -y islandora_solr_views
	drush pm-enable -y islandora_solr_search
	drush pm-enable -y islandora_paged_content
	drush pm-enable -y islandora_xml_forms
	drush pm-enable -y islandora_jwplayer
	drush pm-enable -y islandora_fits
	drush pm-enable -y islandora_bookmark
	drush pm-enable -y islandora_solution_pack_large_image
	drush pm-enable -y islandora_openseadragon
	drush pm-enable -y islandora_solution_pack_pdf
	drush pm-enable -y islandora_solution_pack_video
	drush pm-enable -y islandora_marcxml
	drush pm-enable -y islandora_internet_archive_bookreader
	drush pm-enable -y islandora_oai
	drush pm-enable -y islandora_solution_pack_image
	drush pm-enable -y islandora
	drush pm-enable -y islandora_solution_pack_collection
	drush pm-enable -y islandora_batch
	drush pm-enable -y islandora_bagit
	drush pm-enable -y islandora_premis
	drush pm-enable -y islandora_scholar
	drush pm-enable -y islandora_solr_facet_pages
	drush pm-enable -y islandora_solution_pack_newspaper
	drush pm-enable -y islandora_xacml_editor
	drush pm-enable -y islandora_xmlsitemap
	drush pm-enable -y islandora_solution_pack_web_archive
	drush pm-enable -y islandora_checksum
	drush pm-enable -y islandora_book_batch
	drush pm-enable -y islandora_solr_metadata
	drush pm-enable -y islandora_image_annotation
	drush pm-enable -y islandora_solution_pack_compound

	#setup fedora database
	mysql -u root -ptest  -e "create database fedora3";
	mysql -u root -ptest  -e "GRANT ALL PRIVILEGES ON "fedora3".* TO 'fedoraAdmin'@'%' IDENTIFIED BY 'fedoraAdmin' WITH GRANT OPTION";
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

	$FEDORA_HOME/tomcat/bin/startup.sh

	sleep 10s

	# Copy islandora XACML policies
	cp -v /var/www/islandora/sites/all/modules/islandora/policies/* /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora
	rm $FEDORA_HOME/data/fedora-xacml-policies/repository-policies/default/deny-apim-if-not-localhost.xml
	
fi
#supervisord -n
