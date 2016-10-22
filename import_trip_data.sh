#!/bin/bash

bike_schema='("tripduration","starttime","stoptime","start station id","start station name","start station latitude","start station longitude","end station id","end station name","end station latitude","end station longitude","bikeid","usertype","birth year","gender")'

for filename in data/*.csv; do

  schema=$bike_schema

  echo "`date`: beginning load for ${filename}"
  sed $'s/\r$//' "$filename" | sed '/^$/d' | psql nyc_bike_data -c "COPY bike_tripdata_staging ${schema} FROM stdin CSV HEADER DELIMITER ',';"
  echo "`date`: finished raw load for ${filename}"
  psql nyc_bike_data -f populate_bike_trips.sql
  echo "`date`: loaded trips for ${filename}"
done;
