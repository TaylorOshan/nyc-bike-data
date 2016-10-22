CREATE OR REPLACE FUNCTION DateDiff (units VARCHAR(30), start_t TIMESTAMP, end_t TIMESTAMP) 
     RETURNS INT AS $$
   DECLARE
     diff_interval INTERVAL; 
     diff INT = 0;
     years_diff INT = 0;
   BEGIN
     IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN
       years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);
 
       IF units IN ('yy', 'yyyy', 'year') THEN
         -- SQL Server does not count full years passed (only difference between year parts)
         RETURN years_diff;
       ELSE
         -- If end month is less than start month it will subtracted
         RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t)); 
       END IF;
     END IF;
 
     -- Minus operator returns interval 'DDD days HH:MI:SS'  
     diff_interval = end_t - start_t;
 
     diff = diff + DATE_PART('day', diff_interval);
 
     IF units IN ('wk', 'ww', 'week') THEN
       diff = diff/7;
       RETURN diff;
     END IF;
 
     IF units IN ('dd', 'd', 'day') THEN
       RETURN diff;
     END IF;
 
     diff = diff * 24 + DATE_PART('hour', diff_interval); 
 
     IF units IN ('hh', 'hour') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('minute', diff_interval);
 
     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('second', diff_interval);
 
     RETURN diff;
   END;
   $$ LANGUAGE plpgsql;

CREATE TABLE tmp_points AS
SELECT
  id,
  ST_SetSRID(ST_MakePoint("start station longitude", "start station latitude"), 4326) as pickup,
  ST_SetSRID(ST_MakePoint("end station longitude", "end station latitude"), 4326) as dropoff
FROM bike_tripdata_staging;  

CREATE INDEX idx_tmp_points_pickup ON tmp_points USING gist (pickup);
CREATE INDEX idx_tmp_points_dropoff ON tmp_points USING gist (dropoff);

CREATE TABLE tmp_pickups AS
SELECT t.id, n.gid
FROM tmp_points t, nyct2010 n
WHERE ST_Within(t.pickup, n.geom);

CREATE TABLE tmp_dropoffs AS
SELECT t.id, n.gid
FROM tmp_points t, nyct2010 n
WHERE ST_Within(t.dropoff, n.geom);

INSERT INTO trips
(start_station_id, start_station_name, end_station_id, end_station_name, station_tuple, start_datetime, end_datetime, start_year, start_quarter, start_month, start_week, start_day, start_dow, start_doy, start_hour, end_year, end_quarter, end_month, end_week, end_day, end_dow, end_doy, end_hour, tripduration, start_longitude, start_latitude, end_longitude, end_latitude, bike_id, user_type, birth_year, gender, start_geom, end_geom, start_nyct2010_gid, end_nyct2010_gid, ct_tuple)
SELECT
  "start station id"::varchar,
  "start station name"::varchar,
  "end station id"::varchar,
  "end station name"::varchar,
  CASE
    WHEN "start station id" IS NOT NULL AND "end station id" IS NOT NULL
    THEN ("start station id", "end station id")
  END,
  starttime::timestamp,
  stoptime::timestamp,
  EXTRACT(YEAR FROM starttime::timestamp),
  EXTRACT(QUARTER FROM starttime::timestamp),
  EXTRACT(MONTH FROM starttime::timestamp),
  EXTRACT(WEEK FROM starttime::timestamp),
  EXTRACT(DAY FROM starttime::timestamp),
  EXTRACT(DOW FROM starttime::timestamp),
  EXTRACT(DOY FROM starttime::timestamp),
  EXTRACT(HOUR FROM starttime::timestamp),
  EXTRACT(YEAR FROM stoptime::timestamp),
  EXTRACT(QUARTER FROM stoptime::timestamp),
  EXTRACT(MONTH FROM stoptime::timestamp),
  EXTRACT(WEEK FROM stoptime::timestamp),
  EXTRACT(DAY FROM stoptime::timestamp),
  EXTRACT(DOW FROM stoptime::timestamp),
  EXTRACT(DOY FROM stoptime::timestamp),
  EXTRACT(HOUR FROM stoptime::timestamp),
  DATEDIFF('second', starttime::timestamp, stoptime::timestamp),
  CASE WHEN "start station longitude" != 0 THEN "start station longitude" END,
  CASE WHEN "start station latitude" != 0 THEN "start station latitude" END,
  CASE WHEN "end station longitude" != 0 THEN "end station longitude" END,
  CASE WHEN "end station latitude" != 0 THEN "end station latitude" END,
  bikeid::varchar,
  usertype::varchar,
  "birth year"::varchar,
  gender::varchar,
  CASE
    WHEN "start station longitude" != 0 AND "start station latitude" != 0
    THEN ST_SetSRID(ST_MakePoint("start station longitude", "start station latitude"), 4326)
  END,
  CASE
    WHEN "end station longitude" != 0 AND "end station latitude" != 0
    THEN ST_SetSRID(ST_MakePoint("end station longitude", "end station latitude"), 4326)
  END,
  tmp_pickups.gid,
  tmp_dropoffs.gid,
  CASE
    WHEN tmp_pickups.gid IS NOT NULL AND tmp_dropoffs.gid IS NOT NULL
    THEN (tmp_pickups.gid, tmp_dropoffs.gid)
  END
FROM
  bike_tripdata_staging
    LEFT JOIN tmp_pickups ON bike_tripdata_staging.id = tmp_pickups.id
    LEFT JOIN tmp_dropoffs ON bike_tripdata_staging.id = tmp_dropoffs.id;

TRUNCATE TABLE bike_tripdata_staging;
DROP TABLE tmp_points;
DROP TABLE tmp_pickups;
DROP TABLE tmp_dropoffs;
