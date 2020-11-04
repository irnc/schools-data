SELECT array_to_string(array_agg(ST_x(bbox_points.geom)||','||ST_y(bbox_points.geom)), ',') AS bbox
FROM (
    SELECT osm_id, ST_Transform((dp).geom, 4326) AS geom
    FROM (
        SELECT osm_id, ST_DumpPoints(ST_Envelope(way)) AS dp
        FROM planet_osm_polygon
    ) AS bbox_polygon
    WHERE (dp).path[2] IN (1, 3)
) AS bbox_points WHERE osm_id=479924757;