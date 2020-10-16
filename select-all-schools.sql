-- This SQL should be run over country extract exported into PostGIS.
-- It produces schools.csv file.
DROP TABLE schools;

CREATE TEMPORARY TABLE schools AS
SELECT
    DISTINCT school.osm_id AS school_osm_id,
    school.osm_type AS school_osm_type,
    school.name AS school_name,
    place.osm_id AS place_osm_id,
    place.admin_level AS place_admin_level,
    place.place AS place_place,
    place.name AS place_name,
    ST_X(ST_Transform(ST_Centroid(school.way), 4326)) AS lon,
    ST_Y(ST_Transform(ST_Centroid(school.way), 4326)) AS lat
FROM
    (
        SELECT
            school.osm_id,
            school.name,
            CASE
                WHEN school.osm_id < 0 THEN 'relation'
                ELSE 'way' END
            AS osm_type,
            school.way
        FROM
            planet_osm_polygon school
        WHERE
            school.amenity = 'school'

        UNION

        SELECT
            school.osm_id,
            school.name,
            'node' AS osm_type,
            school.way
        FROM
            planet_osm_point school
        WHERE
            school.amenity = 'school'
    ) AS school,
    planet_osm_polygon belarus,
    planet_osm_polygon place
WHERE
    -- Omit schools outside Belarus. Geofabric extract contains some objects
    -- which are outside BY administrative boundary (because extract is cut
    -- by raw bounding poligon, which doesn't follow country boundary).
    belarus.osm_id = -59065
    AND ST_Contains(belarus.way, school.way)
    AND place.boundary = 'administrative'
    AND ST_Contains(place.way, school.way)
;

COPY schools TO '/var/lib/postgresql/data/schools.csv' WITH CSV DELIMITER ',' HEADER;
