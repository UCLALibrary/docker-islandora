Dockerized Islandora
========================

SCRIPT needs some cleaning and parameterizations

A [dockerized](http://docker.io) development instance [Islandora](http://islandora.ca), an open-source software framework designed to help institutions and organizations and their audiences collaboratively manage, and discover digital assets using a best-practices framework. Built on a base of [Drupal](http://drupal.org/), [Fedora Commons](http://www.fedora-commons.org/), and [Solr](http://lucene.apache.org/solr/), Islandora releases solution packs which empower users to work with data types (such as image, video, and pdf) and knowledge domains (such as Chemistry and the Digital Humanities). Solution packs also often provide integration with additional viewers, editors, and data processing applications.

Installation
------------

1. Install [Docker](http://www.docker.io/gettingstarted/)
1. Change the docker init script (/etc/init.d/docker) to add an appropriate size image (default is only 10G): `/usr/bin/docker -d --exec-driver=lxc --selinux-enabled --storage-opt dm.basesize=50G`
1. Clone this repository
1. Change into the source directory: `cd docker-islandora`
1. Build the container: `docker build -rm --tag=islandora .`
1. Run the docker container: `docker run -t -i -p 80:80 -p 8080:8080 islandora /bin/bash`
1. Run the installer/configuration script script: `./install.sh`
1. Browse to http://localhost
1. Install the isladora modules from the web interface
1. CTRL+P and CTRL+Q to exit the container shell
1. View the running containers via `docker ps -a`
1. To get a back the docker container: `docker attach [CONTAINER ID]`
1. To commit the changes made to a container: `docker commit [CONTAINER ID] [SOME IMAGE NAME]`
1. To stop a running container: `docker stop [CONTAINER ID]`
1. To stop all running containers: `docker ps -a | grep '<none>' | awk '{print $1}' | xargs docker rm`
1. To delete all the docker images: `docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi`

Islandora Configuration
------------

1. Choose Image Toolkit -> ImageMagick as image processing toolkit
1. Specify the `convert` path: `/usr/bin/convert`
1. Islandora -> Page Content Module -> djatoka URL: specify the correct url
1. Islandora -> Solr index -> solr URL: specify the correct url