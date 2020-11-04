# schools-data

Школы Беларусі

# Як абнавіць дадзеныя?

1. З дапамогай `osm2pgsql` трэба ўнесці дадзеныя OpenStreetMap у PostGIS

   Для гэтага глядзіце праект `osm-playground`.

1. Праз `psql` выканаць `select-all-schools.sql`.

   Гэта дасць новую версію `schools.csv`.

1. `node schools-csv-to-json.mjs` для абнаўлення файлаў у `data/`
