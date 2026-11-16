"""Real building footprints for the whole Yangon box (16 Nov 2026), to replace the invented infill of plots.py.

Audit (16 Nov): about 80% of the map's 116,000 buildings were invented infill, because OSM has only ~54,000 outlines in the
box. Decision: use real footprints from open data. Sources (downloaded and clipped to lon 96.095-96.235, lat 16.75-16.89,
see build/footprints/footprints_report.md):
  - OSM (build/osm_ygn/buildings.json, ODbL): first, it is what the game's roads and landmarks are built on.
  - Microsoft Global ML Building Footprints, release 2026-02-03, quadkey 132201222 (build/footprints/ms_buildings.geojson,
    ODbL): fills everything OSM lacks. No model confidence and no heights for Myanmar (all -1), so `conf` here is a
    shape score (see ms_conf).
  - Google Open Buildings v3: Myanmar is not in it (S2 cell 30d streamed: 8.5 M rows, 0 in the box); 2.5D Temporal
    (heights) does not cover Myanmar either. Overture 2026-10-21 = OSM + an older Microsoft cut (no new buildings).

Merge rule:
  1. every OSM building (same filters as plots.py), conf 1.0, floors from its tags or an estimate;
  2. every Microsoft building, moved by the median OSM - MS offset (measured on matched pairs, ~1 m), unless it duplicates
     OSM: dropped when OSM covers > 30% of it, trimmed (OSM cut out) when 5-30%; dropped in water, under 15 m2,
     or under the shape-score cut CONF_CUT;
  3. merged shophouse rows in Microsoft data are split into plots 4.5-6 m wide along their street frontage, ONLY where
     clearly merged (shophouse context + a near-rectangle + frontage >= 13.5 m + depth 8-30 m); the pieces carry
     `split` and `parent`. Big Microsoft blocks in shophouse context that are not clean rectangles are flagged
     `merged_suspect` and left whole.
  4. kind guess and floors estimate from land use, zone (downtown = the owner's batch 2 outline), size, frontage and
     the local building cover. Every estimate says so (`floors_src`: tag | est).

Output: build/footprints/ygn_footprints.json
  {"meta": {...counts, offset, attribution}, "buildings": [{"id", "src": "osm"|"ms", "poly": [[lon, lat], ...],
   "area_m2", "conf", "floors", "floors_src", "kind", "flags": [...], "parent"?}]}
Run from anywhere:  python footprints.py  [--preview]
"""
import hashlib, json, math, os, sys, time

import numpy as np
import shapely
from shapely.geometry import Polygon, Point, LineString, shape, box as sbox
from shapely.strtree import STRtree
from shapely import affinity

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402  (BATCH_LL, floors_from_tags; read only)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
BUILD = os.path.join(ROOT, 'build')
FP = os.path.join(BUILD, 'footprints')
OSM_B = os.path.join(BUILD, 'osm_ygn', 'buildings.json')
OSM_A = os.path.join(BUILD, 'osm_ygn', 'areas.json')
OSM_R = os.path.join(BUILD, 'osm_ygn', 'roads.json')
MS = os.path.join(FP, 'ms_buildings.geojson')
OUT = os.path.join(FP, 'ygn_footprints.json')

BOX = (96.095, 16.75, 96.235, 16.89)
LAT0 = 16.82
KX = 111320 * math.cos(math.radians(LAT0))
KY = 110574
LON0 = 96.165

CONF_CUT = 0.5          # Microsoft buildings under this shape score are left out
DUP_DROP = 0.30         # OSM covers more than this share of an MS building -> duplicate
DUP_TRIM = 0.05         # between TRIM and DROP -> OSM is cut out of it
MIN_M2 = 15.0
PLOT_W = (4.5, 6.0)     # shophouse plot width, m
MAIN_ROADS = {'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'motorway_link', 'trunk_link', 'primary_link',
              'secondary_link', 'tertiary_link'}
STREETS = MAIN_ROADS | {'residential', 'unclassified', 'living_street', 'service'}
SAMPLES = {  # the report's sample boxes (3 x 3 Esri z18 tiles each; build/footprints/samples/*.jpg)
    'downtown': (96.15372, 16.7743, 96.15784, 16.77825),
    'kamayut_hledan': (96.12762, 16.82163, 96.13174, 16.82557),
    'bahan': (96.15372, 16.80717, 96.15784, 16.81111),
    'inya_lake_east': (96.14822, 16.83609, 96.15234, 16.84003),
    'myanmar_plaza': (96.15509, 16.82426, 96.15921, 16.8282),
}


def to_m(lon, lat):
    return ((lon - LON0) * KX, (lat - LAT0) * KY)


def to_ll(x, y):
    return (LON0 + x / KX, LAT0 + y / KY)


def poly_m(coords):
    return Polygon([to_m(x, y) for x, y in coords])


def ll_coords(p):
    return [[round(a, 7), round(b, 7)] for a, b in (to_ll(x, y) for x, y in list(p.exterior.coords)[:-1])]


def rng(*k):
    h = hashlib.md5(('|'.join(map(str, k))).encode()).digest()
    return np.random.default_rng(int.from_bytes(h[:8], 'little'))


def pick(r, values, weights):
    w = np.array(weights, float)
    return values[int(r.choice(len(values), p=w / w.sum()))]


def single(g):
    if g is None or g.is_empty:
        return None
    if not g.is_valid:
        g = g.buffer(0)
    if g.geom_type == 'Polygon':
        return g
    if hasattr(g, 'geoms'):
        ps = [q for q in g.geoms if q.geom_type == 'Polygon']
        return max(ps, key=lambda q: q.area) if ps else None
    return None


def rect_dims(p):
    """(long side, short side, unit vector of the long side, fill = area / min rotated rect area)"""
    r = p.minimum_rotated_rectangle
    xs = list(r.exterior.coords)
    a = (xs[1][0] - xs[0][0], xs[1][1] - xs[0][1])
    b = (xs[2][0] - xs[1][0], xs[2][1] - xs[1][1])
    la, lb = math.hypot(*a), math.hypot(*b)
    if la >= lb:
        L, D, u = la, lb, (a[0] / max(la, 1e-9), a[1] / max(la, 1e-9))
    else:
        L, D, u = lb, la, (b[0] / max(lb, 1e-9), b[1] / max(lb, 1e-9))
    return L, D, u, p.area / max(r.area, 1e-9)


# ------------------------------------------------------------------ inputs
def load_osm():
    d = json.load(open(OSM_B, encoding='utf-8'))['buildings']
    out = []
    for b in d:
        t = b['t']
        if 'building:part' in t and 'building' not in t:
            continue
        if 'building' not in t or t.get('building') in ('no', 'construction', 'ruins', 'collapsed'):
            continue
        if len(b['p']) < 4:
            continue
        try:
            p = single(poly_m(b['p']))
        except Exception:
            continue
        if p is None or p.area < 4:
            continue
        lo, la = to_ll(p.centroid.x, p.centroid.y)
        if not (BOX[0] <= lo <= BOX[2] and BOX[1] <= la <= BOX[3]):
            continue
        out.append((p, b['id'], t))
    return out


def load_ms():
    d = json.load(open(MS, encoding='utf-8'))['features']
    out = []
    for f in d:
        g = f['geometry']
        ring = g['coordinates'][0] if g['type'] == 'Polygon' else g['coordinates'][0][0]
        p = single(poly_m(ring))
        if p is None:
            continue
        lo, la = to_ll(p.centroid.x, p.centroid.y)
        if not (BOX[0] <= lo <= BOX[2] and BOX[1] <= la <= BOX[3]):
            continue
        out.append(p)
    return out


def load_areas():
    """land use polygons (metres): [(use, poly)], water polygons"""
    d = json.load(open(OSM_A, encoding='utf-8'))['areas']
    uses, water = [], []
    for a in d:
        t = a['t']
        if len(a['p']) < 4:
            continue
        try:
            p = single(poly_m(a['p']))
        except Exception:
            continue
        if p is None:
            continue
        if t.get('natural') == 'water' or t.get('water') or t.get('landuse') in ('basin', 'reservoir'):
            water.append(p)
            continue
        use = t.get('landuse') or t.get('amenity') or t.get('leisure')
        if use:
            uses.append((use, p))
    uses.sort(key=lambda q: q[1].area)  # smallest first: the most specific wins
    return uses, water


def load_roads():
    d = json.load(open(OSM_R, encoding='utf-8'))['roads']
    main, streets = [], []
    for r in d:
        hw = r['t'].get('highway')
        if hw not in STREETS or len(r['p']) < 2:
            continue
        ls = LineString([to_m(x, y) for x, y in r['p']])
        streets.append(ls)
        if hw in MAIN_ROADS:
            main.append(ls)
    return main, streets


# ------------------------------------------------------------------ guesses
TAG_KIND = {
    'house': 'house', 'detached': 'house', 'bungalow': 'house', 'semidetached_house': 'house', 'terrace': 'shophouse',
    'apartments': 'walkup', 'residential': 'walkup', 'dormitory': 'walkup', 'hotel': 'mass', 'commercial': 'mass',
    'retail': 'mass', 'office': 'mass', 'industrial': 'hall', 'warehouse': 'hall', 'factory': 'hall', 'hangar': 'hall',
    'shed': 'shed', 'hut': 'shed', 'garage': 'shed', 'garages': 'shed', 'roof': 'shed', 'kiosk': 'shed', 'carport': 'shed',
    'school': 'school', 'university': 'school', 'college': 'school', 'kindergarten': 'school', 'hospital': 'hospital',
    'temple': 'religious', 'pagoda': 'religious', 'monastery': 'religious', 'church': 'religious', 'mosque': 'religious',
    'religious': 'religious', 'cathedral': 'religious', 'shrine': 'religious', 'public': 'civic', 'civic': 'civic',
    'government': 'civic', 'train_station': 'civic', 'transportation': 'civic',
}
USE_KIND = {
    'industrial': 'hall', 'garages': 'shed', 'religious': 'religious', 'place_of_worship': 'religious', 'monastery': 'religious',
    'school': 'school', 'university': 'school', 'college': 'school', 'education': 'school', 'kindergarten': 'school',
    'hospital': 'hospital', 'healthcare': 'hospital', 'clinic': 'hospital', 'military': 'civic',
}


def floors_for(kind, zone, area, r):
    """a floors guess (Yangon, Esri / street photos): downtown shophouses 4-6, township shophouses 3-5, Bahan / Golden
    Valley houses and villas 1-3, township walk-ups 4-8, halls 1-2"""
    if kind == 'shed':
        return 1
    if kind == 'hall':
        return pick(r, [1, 1, 2], [1, 1, 1])
    if kind == 'religious':
        return pick(r, [1, 2, 3], [3, 2, 1])
    if kind == 'shophouse':
        return pick(r, [4, 5, 6, 7], [3, 4, 3, 1]) if zone == 'downtown' else pick(r, [3, 4, 5], [3, 4, 2])
    if kind == 'house':
        return pick(r, [1, 2, 3], [2, 5, 2])
    if kind == 'villa':
        return pick(r, [2, 3], [3, 2])
    if kind == 'walkup':
        return pick(r, [5, 6, 7, 8], [2, 3, 3, 2]) if zone == 'downtown' else pick(r, [4, 5, 6, 7, 8], [3, 3, 3, 2, 1])
    if kind in ('school', 'hospital', 'civic'):
        return pick(r, [2, 3, 4], [3, 3, 2])
    if kind == 'mass':
        if area > 3000:
            return pick(r, [3, 4, 6, 8], [2, 2, 2, 1])
        return pick(r, [4, 6, 8, 10], [3, 3, 2, 1])
    return pick(r, [2, 3, 4], [2, 2, 1])


def main(preview=False):
    t0 = time.time()
    osm = load_osm()
    ms = load_ms()
    uses, water = load_areas()
    main_roads, streets = load_roads()
    print(f'inputs: osm {len(osm)}, ms {len(ms)}, land use {len(uses)}, water {len(water)}, '
          f'streets {len(streets)} ({len(main_roads)} main)  {time.time() - t0:.0f}s')
    downtown = Polygon([to_m(lo, la) for lo, la in geo.BATCH_LL['2']])
    use_tree = STRtree([p for _, p in uses])
    water_tree = STRtree(water) if water else None
    main_tree = STRtree(main_roads)
    street_tree = STRtree(streets)

    def use_at(pt):
        for i in sorted(use_tree.query(pt, predicate='within'), key=lambda i: uses[i][1].area):
            return uses[i][0]
        return None

    # ---------------------------------------------------------------- 1. offset MS -> OSM on matched pairs
    osm_polys = [p for p, _, _ in osm]
    osm_tree = STRtree(osm_polys)
    ms_arr = np.array(ms, dtype=object)
    pi, oi = osm_tree.query(ms_arr, predicate='intersects')
    inter = shapely.area(shapely.intersection(ms_arr[pi], np.array(osm_polys, dtype=object)[oi]))
    union = shapely.area(shapely.union(ms_arr[pi], np.array(osm_polys, dtype=object)[oi]))
    iou = inter / np.maximum(union, 1e-9)
    good = iou > 0.5
    dx = [osm_polys[o].centroid.x - ms[p].centroid.x for p, o in zip(pi[good], oi[good])]
    dy = [osm_polys[o].centroid.y - ms[p].centroid.y for p, o in zip(pi[good], oi[good])]
    off = (float(np.median(dx)), float(np.median(dy))) if dx else (0.0, 0.0)
    print(f'offset OSM - MS on {int(good.sum())} pairs (IoU > 0.5): dx {off[0]:.2f} m, dy {off[1]:.2f} m  '
          f'(IQR x {np.percentile(dx, 25):.2f}..{np.percentile(dx, 75):.2f}, y {np.percentile(dy, 25):.2f}..{np.percentile(dy, 75):.2f})')
    ms = [affinity.translate(p, off[0], off[1]) for p in ms]
    ms_arr = np.array(ms, dtype=object)

    # ---------------------------------------------------------------- 2. duplicates against OSM
    pi, oi = osm_tree.query(ms_arr, predicate='intersects')
    inter = shapely.area(shapely.intersection(ms_arr[pi], np.array(osm_polys, dtype=object)[oi]))
    cover = np.zeros(len(ms))
    np.add.at(cover, pi, inter)
    share = cover / np.maximum(shapely.area(ms_arr), 1e-9)
    touch = {}
    for p, o in zip(pi, oi):
        touch.setdefault(int(p), []).append(int(o))
    drop = {'dup_osm': 0, 'small': 0, 'water': 0, 'low_conf': 0, 'trim_gone': 0, 'construction_site': 0, 'parking': 0}
    n_trim = 0

    # local building cover (OSM + MS) for the house / walk-up guess: share of a 50 m disc that is built
    all_c = [p.centroid for p in osm_polys] + [p.centroid for p in ms]
    all_a = np.array([p.area for p in osm_polys] + [p.area for p in ms])
    c_tree = STRtree(all_c)

    def local_cover(pt):
        idx = c_tree.query(pt.buffer(50))
        return float(all_a[idx].sum()) / (math.pi * 50 * 50)

    out = []
    stats = {'osm': 0, 'ms': 0, 'ms_split_parents': 0, 'ms_split_plots': 0, 'merged_suspect': 0}

    # ---------------------------------------------------------------- 3. OSM buildings
    for p, bid, t in osm:
        c = p.centroid
        zone = 'downtown' if downtown.contains(c) else 'township'
        kind = TAG_KIND.get(t.get('building'))
        use = use_at(c)
        if kind is None:
            kind = USE_KIND.get(use) or size_kind(p, zone, use, c, main_tree, local_cover)
        fl = geo.floors_from_tags(t)
        src = 'tag'
        if fl is None:
            fl = floors_for(kind, zone, p.area, rng('osm', bid))
            src = 'est'
        out.append({'id': f'o{bid}', 'src': 'osm', 'poly': ll_coords(p), 'area_m2': round(p.area, 1), 'conf': 1.0,
                    'floors': int(fl), 'floors_src': src, 'kind': kind, 'flags': [],
                    'name': t.get('name:en') or t.get('name')})
        stats['osm'] += 1

    # ---------------------------------------------------------------- 4. Microsoft buildings
    for i, p in enumerate(ms):
        flags = []
        if share[i] > DUP_DROP:
            drop['dup_osm'] += 1
            continue
        if share[i] > DUP_TRIM:
            q = p
            for o in touch.get(i, []):
                q = q.difference(osm_polys[o].buffer(0.5))
            q = single(q)
            if q is None or q.area < max(MIN_M2, 0.4 * p.area):
                drop['trim_gone'] += 1
                continue
            p = q
            flags.append('trimmed_osm')
            n_trim += 1
        if p.area < MIN_M2:
            drop['small'] += 1
            continue
        c = p.centroid
        if water_tree is not None and len(water_tree.query(c, predicate='within')):
            drop['water'] += 1
            continue
        use = use_at(c)
        conf, why = ms_conf(p, use)
        if conf < CONF_CUT:
            k = 'parking' if 'parking' in why else ('construction_site' if 'construction_site' in why else 'low_conf')
            drop[k] += 1
            continue
        flags += why
        zone = 'downtown' if downtown.contains(c) else 'township'
        lo, la = to_ll(c.x, c.y)
        mid = f'm{round(lo * 1e6)}_{round(la * 1e6)}'
        kind = USE_KIND.get(use) or size_kind(p, zone, use, c, main_tree, local_cover)
        # ---- split clearly merged shophouse rows
        pieces = split_row(p, zone, use, kind, c, main_tree, street_tree)
        if pieces:
            stats['ms_split_parents'] += 1
            for k, q in enumerate(pieces):
                r = rng('ms', mid, k)
                out.append({'id': f'{mid}_{k}', 'src': 'ms', 'poly': ll_coords(q), 'area_m2': round(q.area, 1),
                            'conf': round(conf, 2), 'floors': floors_for('shophouse', zone, q.area, r), 'floors_src': 'est',
                            'kind': 'shophouse', 'flags': flags + ['split'], 'parent': mid})
                stats['ms_split_plots'] += 1
                stats['ms'] += 1
            continue
        if zone == 'downtown' or kind == 'shophouse':
            L, D, _, fill = rect_dims(p)
            if p.area > 500 and fill < 0.8 and use not in USE_KIND:
                flags.append('merged_suspect')
                stats['merged_suspect'] += 1
        out.append({'id': mid, 'src': 'ms', 'poly': ll_coords(p), 'area_m2': round(p.area, 1), 'conf': round(conf, 2),
                    'floors': floors_for(kind, zone, p.area, rng('ms', mid)), 'floors_src': 'est', 'kind': kind,
                    'flags': flags})
        stats['ms'] += 1
        if i % 40000 == 0:
            print(f'  ms {i}/{len(ms)}  {time.time() - t0:.0f}s')

    # ---------------------------------------------------------------- 5. numbers per area
    km2_box = (BOX[2] - BOX[0]) * KX * (BOX[3] - BOX[1]) * KY / 1e6
    cents = np.array([[b['poly'][0][0], b['poly'][0][1]] for b in out])  # (first corner is enough for counting)
    srcs = np.array([b['src'] for b in out])
    dens = {'whole_box': {'km2': round(km2_box, 1), 'osm': int((srcs == 'osm').sum()), 'ms': int((srcs == 'ms').sum()),
                          'total': len(out), 'per_km2': round(len(out) / km2_box)}}
    for name, (w, s, e, n) in SAMPLES.items():
        km2 = (e - w) * KX * (n - s) * KY / 1e6
        inb = (cents[:, 0] >= w) & (cents[:, 0] <= e) & (cents[:, 1] >= s) & (cents[:, 1] <= n)
        dens[name] = {'km2': round(km2, 3), 'osm': int((inb & (srcs == 'osm')).sum()), 'ms': int((inb & (srcs == 'ms')).sum()),
                      'total': int(inb.sum()), 'per_km2': round(int(inb.sum()) / km2)}
    kinds = {}
    for b in out:
        kinds[b['kind']] = kinds.get(b['kind'], 0) + 1
    meta = {
        'made_by': 'tools/yangon/city/footprints.py', 'date': time.strftime('%Y-%m-%d'), 'box': list(BOX),
        'sources': {
            'osm': 'OpenStreetMap contributors, ODbL 1.0 (myanmar-261112.osm.pbf via build/osm_ygn/buildings.json)',
            'ms': 'Microsoft Global ML Building Footprints, release 2026-02-03, quadkey 132201222, ODbL 1.0',
        },
        'ms_offset_applied_m': [round(off[0], 2), round(off[1], 2)],
        'rules': {'conf_cut': CONF_CUT, 'dup_drop_share': DUP_DROP, 'dup_trim_share': DUP_TRIM, 'min_m2': MIN_M2,
                  'plot_width_m': list(PLOT_W)},
        'counts': {**stats, 'total': len(out), 'ms_trimmed': n_trim, 'ms_dropped': drop, 'ms_in_box': len(ms)},
        'density': dens, 'kinds': dict(sorted(kinds.items(), key=lambda kv: -kv[1])),
        'floors_note': 'floors_src est = a guess by kind / zone / size (no height data exists for Myanmar in Google 2.5D, '
                       'Microsoft or Overture); tag = OSM building:levels or height / 3.2',
    }
    json.dump({'meta': meta, 'buildings': out}, open(OUT, 'w', encoding='utf-8'), separators=(',', ':'), ensure_ascii=False)
    print(json.dumps(meta, indent=1, ensure_ascii=False))
    print('wrote', OUT, f'{os.path.getsize(OUT) / 1e6:.1f} MB', f'{time.time() - t0:.0f}s')
    if preview:
        previews(out)


def ms_conf(p, use):
    """a shape score for a Microsoft building (the release has no model confidence for Myanmar): 0.85, less for tiny,
    ragged, huge or construction-site outlines"""
    conf, why = 0.85, []
    L, D, _, fill = rect_dims(p)
    if p.area < 25:
        conf -= 0.25
        why.append('tiny')
    if fill < 0.6:
        conf -= 0.2
        why.append('ragged')
    if p.area > 6000:
        conf -= 0.2
        why.append('huge')
    if D < 2.5:
        conf -= 0.3
        why.append('sliver')
    if use == 'construction':
        conf -= 0.4  # (OSM construction sites: ML picks up site huts, stacked material, parked cars; can be stale)
        why.append('construction_site')
    if use in ('parking', 'parking_space'):
        conf -= 0.5  # (rows of parked cars read as roofs)
        why.append('parking')
    return conf, why


def size_kind(p, zone, use, c, main_tree, local_cover):
    a = p.area
    if a < 40:
        return 'shed'
    if use in ('industrial',):
        return 'hall'
    near_main = len(main_tree.query(c.buffer(28), predicate='intersects')) > 0
    if zone == 'downtown':
        if a > 1500:
            return 'mass'
        return 'shophouse' if a < 700 else 'walkup'
    if use in ('commercial', 'retail') and a > 1200:
        return 'mass'
    if near_main and a < 900:
        return 'shophouse'
    if a > 2500:
        return 'mass'
    cov = local_cover(c)
    if a >= 220 and cov > 0.40:
        return 'walkup'
    if a >= 220:
        return 'villa'
    return 'house'


def split_row(p, zone, use, kind, c, main_tree, street_tree):
    """pieces 4.5-6 m wide along the street frontage, or None when the block is not clearly a merged shophouse row"""
    if use in USE_KIND or use in ('commercial',) and p.area > 3000:
        return None
    shop_ctx = zone == 'downtown' or kind == 'shophouse' or use in ('retail', 'commercial')
    if not shop_ctx:
        return None
    L, D, u, fill = rect_dims(p)
    if fill < 0.8 or p.area < 120 or p.area > 3500:
        return None
    # the frontage: the rectangle side that faces the nearest street
    idx = street_tree.query(c.buffer(40))
    if not len(idx):
        return None
    road = min((street_tree.geometries[i] for i in idx), key=lambda g: g.distance(c))
    q = road.interpolate(road.project(c))
    nx, ny = q.x - c.x, q.y - c.y
    nl = math.hypot(nx, ny) or 1.0
    nx, ny = nx / nl, ny / nl
    # frontage direction = rectangle axis most square to the road normal
    v = (-u[1], u[0])
    if abs(u[0] * nx + u[1] * ny) < abs(v[0] * nx + v[1] * ny):
        along, front, depth = u, L, D
    else:
        along, front, depth = v, D, L
    if front < 13.5 or not (8 <= depth <= 30):
        return None
    n = max(2, int(round(front / 5.25)))
    w = front / n
    if not (PLOT_W[0] <= w <= PLOT_W[1]):
        n = int(math.ceil(front / PLOT_W[1]))
        w = front / n
        if w < PLOT_W[0]:
            return None
    # cut strips across the frontage axis, clipped by the polygon itself
    cx, cy = c.x, c.y
    proj = [((x - cx) * along[0] + (y - cy) * along[1]) for x, y in p.exterior.coords]
    lo = min(proj)
    span = max(proj) - lo
    w = span / n
    perp = (-along[1], along[0])
    big = depth * 3 + 40
    out = []
    for k in range(n):
        a0, a1 = lo + k * w, lo + (k + 1) * w
        strip = Polygon([(cx + along[0] * a0 + perp[0] * big, cy + along[1] * a0 + perp[1] * big),
                         (cx + along[0] * a1 + perp[0] * big, cy + along[1] * a1 + perp[1] * big),
                         (cx + along[0] * a1 - perp[0] * big, cy + along[1] * a1 - perp[1] * big),
                         (cx + along[0] * a0 - perp[0] * big, cy + along[1] * a0 - perp[1] * big)])
        g = single(p.intersection(strip))
        if g is not None and g.area >= 12:
            out.append(g)
    return out if len(out) >= 2 else None


def previews(out):
    """the merged result over the cached Esri tiles of each sample (build/footprints/samples/merged_<name>.jpg):
    yellow OSM, cyan Microsoft, magenta split plots"""
    from PIL import Image, ImageDraw
    tiles = os.path.join(FP, 'raw', 'esri')

    def txy(lon, lat, z=18):
        nn = 2 ** z
        s = math.sin(math.radians(lat))
        return ((lon + 180) / 360 * nn, (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * nn)

    for name, (w, s, e, n) in SAMPLES.items():
        x0, y0 = txy(w, n)
        x0, y0 = int(round(x0)), int(round(y0))
        im = Image.new('RGB', (768, 768))
        ok = True
        for i in range(3):
            for j in range(3):
                pth = os.path.join(tiles, f'18_{y0 + j}_{x0 + i}.jpg')
                if not os.path.exists(pth):
                    ok = False
                    continue
                im.paste(Image.open(pth).convert('RGB'), (256 * i, 256 * j))
        if not ok:
            print('preview: tiles missing for', name)
            continue
        d = ImageDraw.Draw(im)
        for b in out:
            lo, la = b['poly'][0]
            if not (w - 0.001 <= lo <= e + 0.001 and s - 0.001 <= la <= n + 0.001):
                continue
            col = (255, 220, 0) if b['src'] == 'osm' else ((255, 60, 220) if 'split' in b['flags'] else (0, 230, 255))
            pts = []
            for lo, la in b['poly'] + [b['poly'][0]]:
                X, Y = txy(lo, la)
                pts.append(((X - x0) * 256, (Y - y0) * 256))
            d.line(pts, fill=col, width=2)
        im.save(os.path.join(FP, 'samples', f'merged_{name}.jpg'), quality=88)
        print('preview', name)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main(preview='--preview' in sys.argv)
