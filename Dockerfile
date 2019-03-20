FROM ubuntu:18.04

# Based on
# https://switch2osm.org/manually-building-a-tile-server-18-04-lts/

# Install dependencies
RUN apt-get update
RUN apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg

# Set up environment and renderer user
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN adduser --disabled-password --gecos "" renderer
USER renderer

# Install latest osm2pgsql
RUN mkdir /home/renderer/src
WORKDIR /home/renderer/src
RUN git clone https://github.com/openstreetmap/osm2pgsql.git
WORKDIR /home/renderer/src/osm2pgsql
USER root
RUN apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev
USER renderer
RUN mkdir build
WORKDIR /home/renderer/src/osm2pgsql/build
RUN cmake ..
RUN make
USER root
RUN make install
USER renderer

# Install and test Mapnik
USER root
RUN apt-get -y install autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik
USER renderer
RUN python -c 'import mapnik'

# install MQTT Worker
USER root
RUN apt-get -y install php-cli php-gd php-curl
USER renderer
COPY worker.php /home/renderer/worker.php
COPY phpMQTT.php /home/renderer/phpMQTT.php


# Configure stylesheet
WORKDIR /home/renderer/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git
WORKDIR /home/renderer/src/openstreetmap-carto
USER root
RUN apt-get install -y npm nodejs
RUN npm install -g carto
USER renderer
RUN carto -v
RUN carto project.mml > mapnik.xml


WORKDIR /home/renderer/src
RUN git clone https://github.com/Zverik/Nik4.git
RUN chmod u+x /home/renderer/src/Nik4

ENV OSMFILE http://download.geofabrik.de/europe/germany/niedersachsen-latest.osm.pbf
ENV MQTT_SERVER 172.18.5.3
ENV MQTT_CHANNEL /osm/maprequest
ENV MQTT_USER node
ENV MQTT_PASSWD node

# Start running
USER root

COPY run.sh /
RUN chmod u+x /run.sh
ENTRYPOINT ["/run.sh"]
CMD []
EXPOSE 80/tcp
