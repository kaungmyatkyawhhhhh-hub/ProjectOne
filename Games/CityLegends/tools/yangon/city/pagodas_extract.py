"""Pagoda generator, step 1 (2026-11-16): every pagoda / stupa / zedi in the Yangon OSM box, with ALL tags, straight from
the Geofabrik extract (build/osm_extract/myanmar-261112.osm.pbf; e0_extract.py drops the tags these need).
-> build/pagodas/pagodas_osm.json  [{id, kind (node/way/rel), tags, lon, lat, ring [[lon,lat],...] or None}]
Picked: man_made=stupa, building=pagoda/stupa/shrine(buddhist), historic with stupa words, amenity=place_of_worship with
religion=buddhist whose name says pagoda / zedi / paya / ceti (or Burmese ceti / hpaya), tourism=attraction with those words.
(OpenStreetMap contributors, ODbL.)"""
import json, os, re, sys
import osmium

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
PBF = os.path.join(ROOT, 'build', 'osm_extract', 'myanmar-261112.osm.pbf')
OUT = os.path.join(ROOT, 'build', 'pagodas', 'pagodas_osm.json')
BOX = (96.095, 16.75, 96.235, 16.89)
WORDS = re.compile(r'pagoda|zedi|zeti|stupa|paya|phaya|hpaya|ceti|cetiya|chedi|\u1005\u1031\u1010\u102e|\u1018\u102f\u101b\u102c\u1038', re.I)


def wanted(t):
    mm, b = t.get('man_made', ''), t.get('building', '')
    name = ' '.join(v for k, v in t.items() if k.startswith('name') or k.startswith('alt_name'))
    if mm == 'stupa' or b in ('pagoda', 'stupa'):
        return 'stupa'
    if t.get('historic') in ('stupa', 'pagoda') or t.get('tower:type') == 'stupa':
        return 'stupa'
    if t.get('amenity') == 'place_of_worship' and t.get('religion', 'buddhist') == 'buddhist' and WORDS.search(name):
        return 'pow'
    if b in ('shrine', 'temple', 'religious') and WORDS.search(name):
        return 'pow'
    if t.get('tourism') == 'attraction' and WORDS.search(name):
        return 'attr'
    return None


def inbox(lo, la):
    return BOX[0] <= lo <= BOX[2] and BOX[1] <= la <= BOX[3]


class H(osmium.SimpleHandler):
    def __init__(s):
        super().__init__()
        s.out = []

    def node(s, n):
        t = {k.k: k.v for k in n.tags}
        w = wanted(t) if t else None
        if w and n.location.valid() and inbox(n.location.lon, n.location.lat):
            s.out.append(dict(id='n%d' % n.id, pick=w, tags=t, lon=n.location.lon, lat=n.location.lat, ring=None))

    def area(s, a):
        t = {k.k: k.v for k in a.tags}
        w = wanted(t) if t else None
        if not w:
            return
        rings = []
        for outer in a.outer_rings():
            rings.append([(p.lon, p.lat) for p in outer if p.location.valid()])
        if not rings:
            return
        ring = max(rings, key=len)
        lo = sum(p[0] for p in ring) / len(ring)
        la = sum(p[1] for p in ring) / len(ring)
        if inbox(lo, la):
            oid = ('w%d' % a.orig_id()) if a.from_way() else ('r%d' % a.orig_id())
            s.out.append(dict(id=oid, pick=w, tags=t, lon=lo, lat=la, ring=ring))


def run():
    """pyosmium 4: only tagged candidates go to the area assembler (the plain handler over all of Myanmar took 30+ min)."""
    out = []
    keys = ('man_made', 'building', 'amenity', 'historic', 'tourism', 'tower:type')
    fp = (osmium.FileProcessor(PBF)
          .with_locations()
          .with_areas(osmium.filter.KeyFilter(*keys))
          .with_filter(osmium.filter.KeyFilter(*keys)))
    for o in fp:
        t = {k.k: k.v for k in o.tags}
        w = wanted(t)
        if not w:
            continue
        if o.is_node():
            if o.location.valid() and inbox(o.location.lon, o.location.lat):
                out.append(dict(id='n%d' % o.id, pick=w, tags=t, lon=o.location.lon, lat=o.location.lat, ring=None))
        elif o.is_area():
            rings = [[(p.lon, p.lat) for p in r if p.location.valid()] for r in o.outer_rings()]
            rings = [r for r in rings if len(r) >= 4]
            if not rings:
                continue
            ring = max(rings, key=len)
            lo = sum(p[0] for p in ring) / len(ring)
            la = sum(p[1] for p in ring) / len(ring)
            if inbox(lo, la):
                oid = ('w%d' % o.orig_id()) if o.from_way() else ('r%d' % o.orig_id())
                out.append(dict(id=oid, pick=w, tags=t, lon=lo, lat=la, ring=ring))
    return out


if __name__ == '__main__':
    out = run()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False)
    from collections import Counter
    print(len(out), Counter((o['pick'], o['id'][0]) for o in out))
