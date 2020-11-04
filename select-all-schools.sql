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
    ST_Y(ST_Transform(ST_Centroid(school.way), 4326)) AS lat,
    bbox
FROM
    (
        SELECT
            school.osm_id,
            school.name,
            CASE
                WHEN school.osm_id < 0 THEN 'relation'
                ELSE 'way' END
            AS osm_type,
            school.way,
            bbox
        FROM planet_osm_polygon school
        INNER JOIN (
            SELECT osm_id, array_to_string(array_agg(ST_x(bbox_points.geom)||','||ST_y(bbox_points.geom)), ',') AS bbox
            FROM (
                SELECT osm_id, ST_Transform((dp).geom, 4326) AS geom
                FROM (
                    SELECT osm_id, ST_DumpPoints(ST_Envelope(way)) AS dp
                    FROM planet_osm_polygon
                ) AS bbox_polygon
                WHERE (dp).path[2] IN (1, 3)
            ) AS bbox_points
            GROUP BY osm_id
        ) AS bbox
        ON bbox.osm_id=school.osm_id
        WHERE
            school.amenity = 'school'

        UNION

        SELECT
            school.osm_id,
            school.name,
            'node' AS osm_type,
            school.way,
            '' AS bbox
        FROM
            planet_osm_point school
        WHERE
            school.amenity = 'school'
    ) AS school
-- Omit schools outside Belarus. Geofabric extract contains some objects
-- which are outside BY administrative boundary (because extract is cut
-- by raw bounding poligon, which doesn't follow country boundary).
INNER JOIN planet_osm_polygon belarus ON belarus.osm_id = -59065
INNER JOIN planet_osm_polygon place ON place.boundary = 'administrative'
WHERE
    
    ST_Contains(belarus.way, school.way)
    AND ST_Contains(place.way, school.way)
;

COPY schools TO '/var/lib/postgresql/data/schools.csv' WITH CSV DELIMITER ',' HEADER;
