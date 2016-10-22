CREATE EXTENSION postgis;

CREATE TABLE bike_tripdata_staging (
  id serial primary key,
  tripduration numeric,
  starttime varchar,
  stoptime varchar,
  "start station id" varchar,
  "start station name" varchar,
  "start station latitude" numeric,
  "start station longitude" numeric,
  "end station id" varchar,
  "end station name" varchar,
  "end station latitude" numeric,
  "end station longitude" numeric,
  bikeid varchar,
  usertype varchar,
  "birth year" varchar,
  gender varchar
);


CREATE TABLE trips (
  id serial primary key,
  start_station_id varchar,
  start_station_name varchar,
  end_station_id varchar,
  end_station_name varchar,
  station_tuple varchar,
  start_datetime timestamp without time zone,
  end_datetime timestamp without time zone,
  start_year integer,
  start_quarter integer,
  start_month integer,
  start_week integer,
  start_day integer,
  start_dow integer,
  start_doy integer,
  start_hour integer,
  end_year integer,
  end_quarter integer,
  end_month integer,
  end_week integer,
  end_day integer,
  end_dow integer,
  end_doy integer,
  end_hour integer,
  tripduration numeric,
  start_longitude numeric,
  start_latitude numeric,
  end_longitude numeric,
  end_latitude numeric,
  bike_id varchar,
  user_type varchar,
  birth_year varchar,
  gender varchar,
  start_nyct2010_gid integer,
  end_nyct2010_gid integer,
  ct_tuple varchar
);

SELECT AddGeometryColumn('trips', 'start_geom', 4326, 'POINT', 2);
SELECT AddGeometryColumn('trips', 'end_geom', 4326, 'POINT', 2);
