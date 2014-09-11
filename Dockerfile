FROM ubuntu:14.04
MAINTAINER Alexander Kocisky github.com/namka
# Get ALL of the dependencies...
RUN echo "\ndeb http://archive.ubuntu.com/ubuntu trusty main universe multiverse" > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu trusty-updates main universe multiverse' >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade
RUN dpkg --configure -a
RUN apt-get clean
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential vim python-setuptools software-properties-common python-software-properties libc6-dev libgnutls-dev gnutls-bin libxml2 libxslt1.1 libxml2-dev libxslt-dev xsltproc curl libcurl3 libcurl3-dev php5-curl php5-curl zlib1g-dev graphicsmagick libmagickwand-dev libapache2-mod-proxy-html libxml2 libxml2-dev php5-curl php-soap php5-xsl libxslt1-dev libxslt1.1 lame libimage-exiftool-perl ffmpeg2theora subversion libleptonica-dev isomd5sum libx264-dev x264 libx264-142 avinfo mkvtoolnix libfaac-dev libfaac0 libxml2-utils libopenjpeg2 libopenjpeg-dev libavcodec-extra-54 libavdevice-extra-53 libavfilter-extra-3 libavformat-extra-54 libavutil-extra-52 libpostproc-dev libswscale-extra-2 libdc1394-22 libdc1394-22-dev libgsm1 libgsm1-dev libopenjpeg-dev yasm libvpx-dev libvpx1 apache2 apache2-doc apache2-mpm-prefork apache2-utils ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby wget mysql-client mysql-server wget unzip libmysqlclient-dev libmagickcore-dev libmagickwand-dev ghostscript curl drush stow python-software-properties libkrb5-dev librtmp-dev libssl-dev libtasn1-6-dev libbz2-dev libdjvulibre-dev libexif-dev libfreetype6-dev libgraphviz-dev libjpeg-dev librsvg2-dev libtiff5-dev libwmf-dev libgnutls-dev libssl-doc libtasn1-6-dev libmp3lame-dev libopencore-amrnb0 libopencore-amrnb-dev libopencore-amrwb0 libopencore-amrwb-dev libschroedinger-dev libspeex-dev libtheora-dev libvorbis-dev libxvidcore-dev libxfixes-dev make automake g++

# removed: libdvdcss2 libdvdcss2 apache2.2-common coreutils debianutils libexpat1 vim-tiny libssl1.0.0

RUN add-apt-repository ppa:webupd8team/java
RUN apt-get -y update
RUN echo "oracle-java6-installer  shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections
RUN apt-get -y install oracle-java6-installer

RUN easy_install supervisor
ADD ./start.sh /start.sh
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf

# Setup FFMPEG 1.1.14
RUN cd /tmp
RUN wget http://www.ffmpeg.org/releases/ffmpeg-1.1.14.tar.gz
RUN tar xvfz ffmpeg-1.1.14.tar.gz
RUN cd ffmpeg-1.1.14/
RUN ./configure --enable-gpl --enable-version3 --enable-nonfree --enable-postproc --enable-x11grab --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libdc1394 --enable-libfaac --enable-libgsm --enable-libmp3lame --enable-libopenjpeg --enable-libschroedinger --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libxvid --prefix=/usr/local/stow/ffmpeg-1.1.14
RUN make
RUN make install

# Setup Tesseract 3.02.02 - /usr/local/stow/tesseract-ocr-3.02.02
RUN cd /tmp
RUN wget https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz
RUN tar xvfz tesseract-ocr-3.02.02.tar.gz
RUN cd tesseract-ocr
RUN ./autogen.sh
RUN ./configure --prefix=/usr/local/stow/tesseract-ocr
RUN make
RUN make install

# Setup our enviroment
RUN mkdir /usr/local/fedora
RUN mkdir /opt/djatoka
RUN service mysql start
RUN update-rc.d mysql defaults
RUN mysqladmin -u root password test
RUN service apache2 start
RUN update-rc.d apache2 defaults

#setup fedora database
RUN mysql -u root -ptest  -e "create database fedora";
RUN mysql -u root -ptest  -e "GRANT ALL PRIVILEGES ON "fedora".* TO 'fedoraAdmin'@'%' IDENTIFIED BY 'fedoraAdmin' WITH GRANT OPTION";
RUN mysql -u root -ptest  -e "flush privileges";

# setup drupal database | DONE ON THE START.SH FILE !
#RUN mysql -u root -ptest  -e "create database drupal";
#RUN mysql -u root -ptest  -e "GRANT ALL PRIVILEGES ON "drupal".* TO 'drupal'@'%' IDENTIFIED BY 'drupalAdmin' WITH GRANT OPTION";
#RUN mysql -u root -ptest  -e "flush privileges";

# Setup Harvard's FITS tool
ADD https://fits.googlecode.com/files/fits-0.6.2.zip /tmp/
RUN unzip /tmp/fits-0.6.2.zip -d /opt/
RUN ln -s /opt/fits-0.6.2/fits.sh /usr/bin/

# Setup Fedora GSearch
RUN cd /tmp
RUN wget http://downloads.sourceforge.net/project/fedora-commons/fedora/3.7.0/fcrepo-installer-3.7.0.jar
RUN wget https://raw.githubusercontent.com/namka/configurations/master/fedora-370/install.properties

RUN echo 'export FEDORA_HOME=/usr/local/fedora' >> /etc/profile && \
    echo 'export CATALINA_HOME=/usr/local/fedora/tomcat' >> /etc/profile && \
    echo 'export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:MaxPermSize=128m -Djavax.net.ssl.trustStore=/usr/local/fedora/server/truststore -Djavax.net.ssl.trustStorePassword=tomcat"' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-6-oracle' >> /etc/profile && \
    echo 'export ANT_HOME=/opt/ant' >> /etc/profile && \
    echo 'export KAKADU_LIBRARY_PATH=/opt/djatoka' >> /etc/profile && \
    echo 'export JRE_HOME=/usr/lib/jvm/java-6-oracle/jre'

RUN . /etc/profile

#RUN java -jar fcrepo-installer-3.7.0.jar install.properties
RUN java -jar fcrepo-installer-3.7.0.jar
RUN rm -v /usr/local/fedora/data/fedora-xacml-policies/repository-policies/default/deny-purge-*
RUN mkdir /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora

#RUN $FEDORA_HOME/tomcat/bin/startup.sh

# Setup Solr

# Setup DJATOKA
RUN cd /tmp
RUN wget http://downloads.sourceforge.net/project/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz
RUN tar -xzvf adore-djatoka-1.1.tar.gz
RUN cd adore-djatoka-1.1
RUN mv -v * /usr/local/djatoka
RUN cd /usr/local/djatoka/bin
RUN wget https://gist.github.com/ruebot/7eba022ac0f59a530c86/raw/2ed7e054477083202fd275b3288f7833df3b771f/env.sh
RUN cd /usr/local/djatoka/dist
RUN cp adore-djatoka.war djatoka.war
RUN cp djatoka.war $FEDORA_HOME/tomcat/webapps

# Setup Drupal
RUN cd /tmp
RUN wget http://ftp.drupal.org/files/projects/drupal-7.22.tar.gz
RUN tar -xzvf drupal-7.22.tar.gz
RUN cd drupal-7.22
RUN mv -v drupal-7.22 /var/www
RUN cd /var/www/drupal-7.22
# done by the installer
#ADD https://raw.githubusercontent.com/namka/configurations/master/drupal-7.22/settings.php sites/default/
mkdir sites/default/files


# done on the start.sh file
#RUN drush pm-download views advanced_help ctools imagemagick token libraries
#RUN drush pm-enable views advanced_help ctools imagemagick token libraries

# Fetch Islandora and solution packs
RUN mkdir /var/www/drupal-7.22/sites/all/libraries
RUN cd /var/www/drupal-7.22/sites/all/libraries
RUN git clone -b 1.3 https://github.com/Islandora/tuque.git
RUN git clone https://github.com/openlibrary/bookreader.git
RUN git clone https://github.com/openseadragon/openseadragon.git
RUN git clone https://github.com/jwplayer/jwplayer.git
RUN cd /var/www/sites/all/modules
# Don't forget to add the other libraries - IA bookreader, jwplayer, openseadragon
RUN git clone -b 1.3 git://github.com/Islandora/islandora.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_audio.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_ocr.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_importer.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_book.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solr_views.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solr_search.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solr_search/islandora_solr_config.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_pathauto.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_paged_content.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_xml_forms.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_jwplayer.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_fits.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_bookmark.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_large_image.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_openseadragon.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_pdf.git
RUN git clone -b 1.3 git://github.com/ruebot/islandora_solution_pack_web_archive.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_video.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_marcxml.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_internet_archive_bookreader.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_oai.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_image.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_solution_pack_collection.git
RUN git clone -b 1.3 git://github.com/Islandora/islandora_batch.git
RUN git clone -b 1.3 git://github.com/ruebot/islandora_checksum.git
RUN git clone -b 1.3 git://github.com/Islandora/objective_forms.git
RUN git clone -b 1.3 git://github.com/Islandora/php_lib.git

RUN chown -hR www-data:www-data /var/www/

# Copy islandora XACML policies
RUN cp -v /var/www/islandora/sites/all/modules/islandora/policies/* /usr/local/fedora/data/fedora-xacml-policies/repository-policies/islandora
RUN rm $FEDORA_HOME/data/fedora-xacml-policies/repository-policies/default/deny-apim-if-not-localhost.xml
#RUN $FEDORA_HOME/tomcat/bin/startup.sh

# Expose the application's ports:
# 80: Drupal 
# 8080: Fedora and Solr
EXPOSE 80 8080

CMD ["/bin/bash", "/usr/local/fedora/tomcat/bin/startup.sh"]
