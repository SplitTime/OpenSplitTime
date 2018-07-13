let dist_temp, elev_temp;
const script_tag = document.getElementById('current_user');
if (script_tag) {
    let data = JSON.parse(script_tag.innerHTML);
    dist_temp = data.pref_distance_unit;
    elev_temp = data.pref_elevation_unit;
}

const unitTable = {
    kilometers: {
        labels: { short: 'km', singular: 'kilometer', plural: 'kilometers' },
        scale: 0.001
    },
    miles: {
        labels: { short: 'mi', singular: 'mile', plural: 'miles' },
        scale: 0.000621371
    },
    feet: {
        labels: { short: 'ft', singular: 'foot', plural: 'feet' },
        scale: 3.28084
    },
    meters: {
        labels: { short: 'm', singular: 'meter', plural: 'meters' },
        scale: 1.0
    }
};
var unitDistance = unitTable[dist_temp] || unitTable['kilometers'];
var unitElevation = unitTable[elev_temp] || unitTable['meters'];

export function preferredDistanceUnit(type) {
    return unitDistance.labels[type] || unitDistance.labels['plural'];
}

export function preferredElevationUnit(type) {
    return unitElevation.labels[type] || unitElevation.labels['plural'];
}

export function distanceToPreferred(value) {
    return unitDistance.scale * value;
}

export function elevationToPreferred(value) {
    return unitElevation.scale * value;
}
