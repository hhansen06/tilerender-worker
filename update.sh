echo "Updating OSM Database ..."

cd ~/src/openstreetmap-carto
WORKOSM_DIR=/home/renderer/osmosis_workdir

if [[ ! -e $WORKOSM_DIR ]]; then
    mkdir $WORKOSM_DIR
fi


if [ ! -f  $WORKOSM_DIR/state.txt ]; then
        wget "https://replicate-sequences.osm.mazdermind.de/?"`date -u +"%Y-%m-%d"`"T00:00:00Z" -O $WORKOSM_DIR/state.txt
        osmosis --read-replication-interval-init workingDirectory=$WORKOSM_DIR
        sed -i 's!baseUrl=http://planet.openstreetmap.org/!baseUrl=https://planet.openstreetmap.org/!' $WORKOSM_DIR/configuration.txt
fi

if [ ! -f  $WORKOSM_DIR/shape.poly ]; then
        wget https://download.geofabrik.de/europe/germany/niedersachsen.poly -O $WORKOSM_DIR/shape.poly
fi
echo "Downloading changeset ..."
osmosis --read-replication-interval workingDirectory="${WORKOSM_DIR}" --simplify-change --write-xml-change $WORKOSM_DIR/pipline.osc
echo "Trimming to Niedersachsen ..."
/usr/bin/python /home/renderer/src/regional/trim_osc.py -d gis -p "${WORKOSM_DIR}/shape.poly" $WORKOSM_DIR/pipline.osc $WORKOSM_DIR/pipline.osc
echo "Importing changes to pgsql..."
osm2pgsql --append -s -C 300 -G --hstore --style /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua -d gis $WORKOSM_DIR/pipline.osc
echo "Cleaing up ..."
rm $WORKOSM_DIR/pipline.osc
