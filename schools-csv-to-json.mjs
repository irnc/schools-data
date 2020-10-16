// https://www.npmjs.com/package/csv-parse
// https://csv.js.org/parse/api/sync/
import fs from 'fs';
import assert from 'assert';
import _ from 'lodash';
import parse from 'csv-parse/lib/sync.js';

const schools = parse(fs.readFileSync('./schools.csv'), {
    columns: true
});

const schoolsById = _.groupBy(schools, 'school_osm_id');
const schoolIds = Object.keys(schoolsById);

console.log(`schools = ${schoolIds.length}`);

const places = new Map;
const schoolsWithoutPlace = [];

schoolIds.forEach(id => {
    const school = schoolsById[id];
    try {
        const place = getPlace(school);
        places.set(place.osm_id, place);
    } catch (err) {
        // console.error(`Failed to get place for school ${id}: ${err}`, school);
        if (err.actual !== 0) {
            // console.error(`${id}: ${err.actual}`);
        }
        schoolsWithoutPlace.push({
            osm_id: school[0].school_osm_id,
            osm_type: school[0].school_osm_typ,
            name: school[0].school_name,
        })
    }
});

console.log(`schoolsWithoutPlace = ${schoolsWithoutPlace.length}`);
console.log(`places ${places.size}`)

write('places', Array.from(places.values()));

// Write schools grouped by place into places/[place-osm-id].json
places.forEach(place => {
    const schoolsInPlace = _(schools).filter({ place_osm_id: place.osm_id }).uniqBy('school_osm_id').value();
    
    write(`places/${place.osm_id}`, schoolsInPlace);
});

Object.values(schoolsById).forEach(group => {
    const { school_osm_id, lat, lon } = group[0];
    let place;

    try {
        place = getPlace(group);
    } catch (err) {
        place = 'warning-school-without-place';
    }

    // `school` here is an array of school data joined with administrative area.
    write(`schools/${school_osm_id}`, {
        place,
        geo: {
            lat,
            lon,
        },
        group,
    });
});

function write(file, data) {
    fs.writeFileSync(`./data/${file}.json`, JSON.stringify(data, null, 2));
}

function getPlace(group) {
    const [place, ...rest] = _.filter(group, 'place_place');
    assert.strictEqual(rest.length, 0);
    // console.log(group)
    return {
        name: place.place_name,
        osm_id: place.place_osm_id,
        // TODO remove districts from city and область для республиканского подчинения
        hierarchy: _(group)
            .filter(p => Number(p.place_admin_level) < Number(place.place_admin_level) && p.place_admin_level !== '2')
            .orderBy(p => Number(p.place_admin_level), 'desc').map('place_name').value(),
    };
}