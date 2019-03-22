#!/bin/bash

if [ ! -f /root/firststart ]; then
    php /home/renderer/updatemapnik.php /home/renderer/src/openstreetmap-carto/mapnik.xml
    /home/renderer/src/openstreetmap-carto/scripts/get-shapefiles.py
    service postgresql start
    sudo -u postgres createuser renderer
    sudo -u postgres createdb -E UTF8 -O renderer gis
    sudo -u postgres psql -d gis -c "CREATE EXTENSION postgis;"
    sudo -u postgres psql -d gis -c "CREATE EXTENSION hstore;"
    sudo -u postgres psql -d gis -c "ALTER TABLE geometry_columns OWNER TO renderer;"
    sudo -u postgres psql -d gis -c "ALTER TABLE spatial_ref_sys OWNER TO renderer;"

    # Download Luxembourg as sample if no data is provided
    if [ ! -f /data.osm.pbf ]; then
        echo "WARNING: No import file found, Downloading $OSMFILE"
        wget -nv $OSMFILE -O /data.osm.pbf
    fi

    # Import data
    sudo -u renderer osm2pgsql -d gis --create --slim -G --hstore --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua -C 2048 --number-processes ${THREADS:-4} -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style /data.osm.pbf
    touch /root/firststart
fi

    # Initialize PostgreSQL and Apache
    service postgresql start

    # Run
    echo "Ready to serve ..."
    su renderer -c "php /home/renderer/worker.php $MQTT_SERVER 1883 $MQTT_CHANNEL" &
    
    
    while true; do
        su renderer -c "/home/renderer/update.sh"
        sleep 1h
    done
    exit 0
