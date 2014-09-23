FROM ubuntu:14.04
MAINTAINER Alexander Kocisky github.com/namka
# Get ALL of the dependencies...
RUN echo "\ndeb http://archive.ubuntu.com/ubuntu trusty main universe multiverse" > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu trusty-updates main universe multiverse' >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get -y upgrade
RUN dpkg --configure -a
RUN apt-get clean
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install gcc build-essential yasm vim python-setuptools software-properties-common python-software-properties libc6-dev libgnutls-dev gnutls-bin libxml2 libxslt1.1 libxml2-dev libxslt-dev xsltproc curl libcurl3 libcurl3-dev php5-curl php5-curl zlib1g-dev graphicsmagick libmagickwand-dev libapache2-mod-proxy-html libxml2 libxml2-dev php5-curl php-soap php5-xsl libxslt1-dev libxslt1.1 lame libimage-exiftool-perl ffmpeg2theora subversion libleptonica-dev isomd5sum libx264-dev x264 libx264-142 avinfo mkvtoolnix libfaac-dev libfaac0 libxml2-utils libopenjpeg2 libopenjpeg-dev libavcodec-extra-54 libavdevice-extra-53 libavfilter-extra-3 libavformat-extra-54 libavutil-extra-52 libpostproc-dev libswscale-extra-2 libdc1394-22 libdc1394-22-dev libgsm1 libgsm1-dev libopenjpeg-dev yasm libvpx-dev libvpx1 apache2 apache2-doc apache2-mpm-prefork apache2-utils ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby wget mysql-client mysql-server wget unzip libmysqlclient-dev libmagickcore-dev libmagickwand-dev ghostscript curl drush stow python-software-properties libkrb5-dev librtmp-dev libssl-dev libtasn1-6-dev libbz2-dev libdjvulibre-dev libexif-dev libfreetype6-dev libgraphviz-dev libjpeg-dev librsvg2-dev libtiff5-dev libwmf-dev libgnutls-dev libssl-doc libtasn1-6-dev libmp3lame-dev libopencore-amrnb0 libopencore-amrnb-dev libopencore-amrwb0 libopencore-amrwb-dev libschroedinger-dev libspeex-dev libtheora-dev libvorbis-dev libxvidcore-dev libxfixes-dev make automake g++ checkinstall git ant bibutils sendmail

# Setup Drupal
ADD http://ftp.drupal.org/files/projects/drupal-7.22.tar.gz /tmp/
RUN tar -xzvf /tmp/drupal-7.22.tar.gz -C /tmp
RUN mkdir -p /var/www/html
RUN mv -v /tmp/drupal-7.22 /var/www/html/
RUN cd /var/www/html/drupal-7.22; cp sites/default/default.settings.php sites/default/settings.php; mkdir -p sites/default/files;

RUN update-rc.d mysql defaults
RUN update-rc.d apache2 defaults

RUN add-apt-repository ppa:webupd8team/java
RUN apt-get -y update
RUN echo "oracle-java7-installer  shared/accepted-oracle-license-v1-1 boolean true" | debconf-set-selections
RUN apt-get -y install oracle-java7-installer

# Setup FFMPEG 1.1.14
ADD http://www.ffmpeg.org/releases/ffmpeg-1.1.14.tar.gz /tmp/
RUN tar xvfz /tmp/ffmpeg-1.1.14.tar.gz -C /tmp
RUN cd /tmp/ffmpeg-1.1.14; ./configure --enable-gpl --enable-version3 --enable-nonfree --enable-postproc --enable-x11grab --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libdc1394 --enable-libfaac --enable-libgsm --enable-libmp3lame --enable-libopenjpeg --enable-libschroedinger --enable-libspeex --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libxvid --prefix=/usr/local/stow/ffmpeg-1.1.14 && make && make install

# Setup Tesseract 3.02.02 - /usr/local/stow/tesseract-ocr-3.02.02
ADD https://tesseract-ocr.googlecode.com/files/tesseract-ocr-3.02.02.tar.gz /tmp/
RUN tar xvfz /tmp/tesseract-ocr-3.02.02.tar.gz -C /tmp
RUN cd /tmp/tesseract-ocr; ./autogen.sh; ./configure --prefix=/usr/local/stow/tesseract-ocr && make && make install 

# Setup Harvard's FITS tool
ADD https://fits.googlecode.com/files/fits-0.6.2.zip /tmp/
RUN unzip /tmp/fits-0.6.2.zip -d /opt/
RUN ln -s /opt/fits-0.6.2/fits.sh /usr/bin/

# Download Fedora
ADD http://downloads.sourceforge.net/project/fedora-commons/fedora/3.7.0/fcrepo-installer-3.7.0.jar /tmp/
ADD https://raw.githubusercontent.com/namka/configurations/master/fedora-370/install.properties /tmp/

# Setup GSearch
ADD http://iweb.dl.sourceforge.net/project/fedora-commons/services/3.6/fedoragsearch-2.6.zip /tmp/

# Setup Solr
ADD https://archive.apache.org/dist/lucene/solr/4.2.0/solr-4.2.0.tgz /tmp/

RUN echo 'export FEDORA_HOME=/usr/local/fedora' >> /etc/profile && \
    echo 'export CATALINA_HOME=/usr/local/fedora/tomcat' >> /etc/profile && \
    echo 'export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:MaxPermSize=128m -Djavax.net.ssl.trustStore=/usr/local/fedora/server/truststore -Djavax.net.ssl.trustStorePassword=tomcat"' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-7-oracle' >> /etc/profile && \
    echo 'export ANT_HOME=/opt/ant' >> /etc/profile && \
    echo 'export KAKADU_LIBRARY_PATH=/opt/djatoka' >> /etc/profile && \
    echo 'export JRE_HOME=/usr/lib/jvm/java-7-oracle/jre'

# Setup DJATOKA
ADD http://downloads.sourceforge.net/project/djatoka/djatoka/1.1/adore-djatoka-1.1.tar.gz /tmp/
RUN tar -xzvf /tmp/adore-djatoka-1.1.tar.gz -C /tmp
RUN mv -v /tmp/adore-djatoka-1.1 /opt/djatoka
ADD https://gist.github.com/ruebot/7eba022ac0f59a530c86/raw/2ed7e054477083202fd275b3288f7833df3b771f/env.sh /opt/djatoka/bin/
RUN mkdir -p $FEDORA_HOME/tomcat/webapps
RUN cp /opt/djatoka/dist/adore-djatoka.war $FEDORA_HOME/tomcat/webapps/djatoka.war

# Fetch Islandora and solution packs
RUN mkdir -p /var/www/html/drupal-7.22/sites/all/libraries/
RUN cd /var/www/html/drupal-7.22/sites/all/libraries/; git clone -b 1.3 https://github.com/Islandora/tuque.git; git clone https://github.com/openlibrary/bookreader.git; git clone https://github.com/openseadragon/openseadragon.git; git clone https://github.com/jwplayer/jwplayer.git;

RUN mkdir -p /var/www/html/drupal-7.22/sites/all/modules/;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_audio.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_ocr.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_importer.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_book.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.4 https://github.com/Islandora/islandora_solr_views.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solr_search.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_paged_content.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_xml_forms.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_jwplayer.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_fits.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_bookmark.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_large_image.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_openseadragon.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_pdf.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_video.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_marcxml.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_internet_archive_bookreader.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_oai.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_image.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_collection.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_batch.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/objective_forms.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/php_lib.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_bagit.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_premis.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_scholar.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solr_facet_pages.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_solution_pack_newspaper.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_xacml_editor.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/Islandora/islandora_xmlsitemap.git;

RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/ruebot/islandora_solution_pack_web_archive.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone -b 7.x-1.3 https://github.com/ruebot/islandora_checksum.git;

RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone https://github.com/adam-vessey/islandora_book_batch.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone https://github.com/adam-vessey/islandora_solr_metadata.git;

RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone https://github.com/ppound/islandora_image_annotation.git;
RUN cd /var/www/html/drupal-7.22/sites/all/modules/; git clone https://github.com/mitchmac/islandora_solution_pack_compound.git;
RUN chown -hR www-data:www-data /var/www/html/

RUN easy_install supervisor
ADD ./start.sh /start.sh
ADD ./install.sh /install.sh
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf
RUN chown root.root /start.sh
RUN chmod 750 /start.sh
RUN chown root.root /install.sh
RUN chmod 750 /install.sh

# Expose the application's ports:
# 80: Drupal 
# 8080: Fedora and Solr
EXPOSE 80 8080

#CMD ["/bin/bash", "/usr/local/fedora/tomcat/bin/startup.sh"]
