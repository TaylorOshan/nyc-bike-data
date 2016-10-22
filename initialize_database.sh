#!/bin/bash

#sudo -u postgres createdb -O toshan nyc_taxi_data

#psql nyc_taxi_data -c "CREATE TABLESPACE taxiDB LOCATION '/media/storage/taxis_tablespace';"
#psql -U nyc_taxi_data -c "ALTER DATABASE nyc_taxi_data SET TABLESPACE taxiDB;"

psql nyc_bike_data -f create_nyc_bike_schema.sql

shp2pgsql -s 2263:4326 nyct2010_15b/nyct2010.shp | psql -d nyc_bike_data
psql nyc_bike_data -c "CREATE INDEX index_nyct_on_geom ON nyct2010 USING gist (geom);"
psql nyc_bike_data -c "CREATE INDEX index_nyct_on_ntacode ON nyct2010 (ntacode);"
psql nyc_bike_data -c "VACUUM ANALYZE nyct2010;"


