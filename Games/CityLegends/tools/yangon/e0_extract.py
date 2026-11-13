"""Whole-Yangon map, step E0 (14 Nov 2026, owner: "do all the steps, until the entire yangon map is finished entirely").

Cuts the Yangon area out of Geofabrik's Myanmar extract (OpenStreetMap, ODbL; build/osm_extract/myanmar-*.osm.pbf, 288 MB,
13 Nov 2026) into compact JSON files in build/osm_ygn/:
  roads.json      every highway way: id, tags (lanes, oneway, bridge, layer, width ...), points [lon, lat]
  buildings.json  every building (ways and multipolygons): id, tags (levels, height, roof colour/shape, name ...), outer ring
  areas.json      land use, leisure, natural, water, amenity grounds (closed shapes), by kind
  lines.json      waterways, railways, walls / fences, power lines and towers' lines
  points.json     power poles / towers, trees, bus stops, places of worship, shops (a few kinds)
The box covers all the owner's batches (0.5, 1 west, 2 downtown south, 3 east to Thaketa) with a margin.

Run from Games/CityLegends:  python tools/yangon/e0_extract.py  (needs `pip install osmium`; about 2 minutes)
"""
import glob, json, os, sys, time

import osmium

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = sorted(glob.glob(os.path.join(ROOT, 'build', 'osm_extract', 'myanmar-*.osm.pbf')))[-1]
OUT = os.path.join(ROOT, 'build', 'osm_ygn')
# lon 96.095 .. 96.235, lat 16.750 .. 16.890 (Hlaing River to Thaketa, the Yangon River waterfront to Lotte / the Pyay-Kabar Aye junction)
W, E, S, N = 96.095, 96.235, 16.750, 16.890

ROAD_TAGS = ('highway', 'name', 'name:en', 'lanes', 'lanes:forward', 'lanes:backward', 'oneway', 'bridge', 'tunnel', 'layer',
             'width', 'junction', 'surface', 'turn:lanes', 'turn:lanes:forward', 'turn:lanes:backward', 'divider', 'sidewalk',
             'maxspeed', 'ref', 'access', 'service')
BLD_TAGS = ('building', 'building:levels', 'height', 'min_height', 'roof:colour', 'building:colour', 'roof:shape', 'roof:levels',
            'roof:material', 'building:material', 'name', 'name:en', 'amenity', 'religion', 'shop', 'tourism', 'office',
            'building:part', 'addr:street', 'man_made')
AREA_KEYS = ('landuse', 'leisure', 'natural', 'water', 'waterway', 'amenity', 'man_made', 'place', 'aeroway', 'parking',
             'historic', 'tourism', 'sport', 'golf')
AREA_TAGS = AREA_KEYS + ('name', 'name:en', 'religion', 'surface', 'building')
LINE_TAGS = ('waterway', 'railway', 'barrier', 'power', 'name', 'name:en', 'width', 'bridge', 'layer', 'tunnel', 'service',
             'usage', 'voltage', 'material', 'height', 'natural')
POINT_KEYS = {'power': ('pole', 'tower'), 'natural': ('tree',), 'highway': ('bus_stop', 'traffic_signals', 'street_lamp'),
              'amenity': ('place_of_worship', 'fuel', 'restaurant', 'cafe', 'bank', 'marketplace'), 'shop': None,
              'man_made': ('water_tower',), 'barrier': ('gate',)}


def inbox(lon, lat):
    return W <= lon <= E and S <= lat <= N


def pick(tags, keys):
    return {k: tags[k] for k in keys if k in tags}


def ring(nodes):
    out = []
    for n in nodes:
        if not n.location.valid():
            return None
        out.append([round(n.lon, 7), round(n.lat, 7)])
    return out


class H(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.roads, self.buildings, self.areas, self.lines, self.points = [], [], [], [], []

    def node(self, n):
        if not n.tags or not n.location.valid() or not inbox(n.lon, n.lat):
            return
        t = n.tags
        for k, vals in POINT_KEYS.items():
            v = t.get(k)
            if v is not None and (vals is None or v in vals):
                self.points.append({'id': n.id, 'k': k, 'v': v, 'name': t.get('name:en') or t.get('name'),
                                    'p': [round(n.lon, 7), round(n.lat, 7)]})
                break

    def way(self, w):
        t = w.tags
        if not t:
            return
        nodes = w.nodes
        if len(nodes) < 2:
            return
        a = nodes[0].location
        b = nodes[len(nodes) // 2].location
        if not ((a.valid() and inbox(a.lon, a.lat)) or (b.valid() and inbox(b.lon, b.lat))):
            return
        if 'highway' in t:
            pts = ring(nodes)
            if pts:
                self.roads.append({'id': w.id, 't': pick(t, ROAD_TAGS), 'p': pts})
            return
        if any(k in t for k in ('waterway', 'railway', 'barrier', 'power')) and not w.is_closed() or \
                ('barrier' in t and t.get('barrier') in ('wall', 'fence', 'retaining_wall', 'hedge')):
            pts = ring(nodes)
            if pts:
                self.lines.append({'id': w.id, 't': pick(t, LINE_TAGS), 'p': pts})

    def area(self, a):
        t = a.tags
        is_b = 'building' in t or 'building:part' in t
        is_a = any(k in t for k in AREA_KEYS)
        if not (is_b or is_a):
            return
        try:
            outers = list(a.outer_rings())
        except Exception:
            return
        if not outers:
            return
        o = outers[0]
        first = o[0].location if len(o) else None
        if first is None or not first.valid() or not inbox(first.lon, first.lat):
            return
        pts = ring(o)
        if not pts:
            return
        holes = []
        for r in a.inner_rings(o):
            h = ring(r)
            if h:
                holes.append(h)
        rec = {'id': a.orig_id(), 'way': a.from_way(), 'p': pts}
        if holes:
            rec['h'] = holes
        if is_b:
            rec['t'] = pick(t, BLD_TAGS)
            self.buildings.append(rec)
        else:
            rec['t'] = pick(t, AREA_TAGS)
            # (extra outer rings: big parks and the lake can be several pieces)
            if len(outers) > 1:
                rec['more'] = [ring(x) for x in outers[1:] if ring(x)]
            self.areas.append(rec)


def main():
    t0 = time.time()
    os.makedirs(OUT, exist_ok=True)
    h = H()
    h.apply_file(SRC, locations=True, idx='flex_mem')
    for name, data in (('roads', h.roads), ('buildings', h.buildings), ('areas', h.areas), ('lines', h.lines), ('points', h.points)):
        path = os.path.join(OUT, name + '.json')
        with open(path, 'w', encoding='utf-8') as f:
            json.dump({'source': os.path.basename(SRC) + ' (OpenStreetMap contributors, ODbL)', 'box': [W, S, E, N], name: data}, f,
                      ensure_ascii=False, separators=(',', ':'))
        print(f'{name}: {len(data)} -> {path} ({os.path.getsize(path) / 1e6:.1f} MB)')
    print(f'done in {time.time() - t0:.0f} s')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
