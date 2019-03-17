FROM ubuntu:18.04

# Based on
# https://switch2osm.org/manually-building-a-tile-server-18-04-lts/

# Install dependencies
RUN apt-get update
RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev

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
RUN mkdir build
WORKDIR /home/renderer/src/osm2pgsql/build
RUN cmake ..
RUN make
USER root
RUN make install
USER renderer

# Install and test Mapnik
USER root
RUN apt-get -y install sudo fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted ttf-unifont npm nodejs autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik default-jre default-jdk gradle python-psycopg2 python-shapely python-lxml osmosis postgresql postgresql-contrib postgis postgresql-10-postgis-2.4
USER renderer
RUN python -c 'import mapnik'

# Configure stylesheet
WORKDIR /home/renderer/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git
WORKDIR /home/renderer/src/openstreetmap-carto
USER root
RUN npm install -g carto
USER renderer
RUN carto -v
RUN carto project.mml > mapnik.xml

# configure database updates
USER renderer
RUN mkdir -p /home/renderer/osmosis_workdir
USER root
COPY configuration.txt /home/renderer/osmosis_workdir/configuration.txt
COPY update.sh /home/renderer/update.sh
RUN chown renderer /home/renderer/update.sh
RUN chmod u+x /home/renderer/update.sh
WORKDIR /home/renderer/src
RUN git clone https://github.com/zverik/regional
RUN chmod u+x /home/renderer/src/regional/trim_osc.py

# Start running
USER root
COPY run.sh /
ENTRYPOINT ["/run.sh"]
CMD []
EXPOSE 80/tcp
