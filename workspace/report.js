const overpassResponse = require('./overpass-schools.json');

// 29803
// const total = schools.elements.length;

// 3120
const schools = overpassResponse.elements.filter(e => e.tags?.amenity === 'school');
const total = schools.length;
const report = {
    unnamedRelations: 0,
    unnamedWays: 0,
    unnamedNodes: 0,
}

const byId = new Map();
overpassResponse.elements.forEach(e => {
    // elements could contain multiple representations of a single element, e.g.
    // when relation and member way are both outputted by `out body` and then
    // they are recursed down and outputted by `out skel` for geometry.
    if (byId.has(e.id)) {
        // console.log('DEBUG MULTIPLE', e.id, byId.get(e.id), e);
        if (e.tags === undefined) {
            // assume that previous representation was from `out body`, i.e.
            // with tags.
            return;
        }
    }
    byId.set(e.id, e);
});

schools.forEach(s => {
    const { name } = s.tags;
    // console.log(name);

    if (name !== undefined) {
        return;
    }

    if (s.type === 'relation') {
        // TODO lookup name in outer members
        report.unnamedRelations++;
        s.members.filter(m => m.type === 'way' && m.role === 'outer').forEach(m => {
            // console.log(s.id, byId.get(m.ref).tags?.name);
        })
        return;
    }

    // if (s.type === 'way') {
    //     // TODO create report for fixing
    //     report.unnamedWays++;
    //     return;
    // }

    if (s.type === 'node') {
        // TODO create report for fixing
        report.unnamedNodes++;
        return;
    }

    if (name === undefined) { 
        console.log(s);
    }
});


console.log(`total ${total}`);
console.log(report)