"""Pagoda generator, step 3 (2026-11-16): every ordinary pagoda / stupa -> one placed copy of the stupa kit (pagoda_kit.py).

Run with YANGON_SCALE=1to1:   python pagodas_plan.py
In:  build/pagodas/pagodas_osm.json (pagodas_extract.py), build/pagodas/pagoda_kit.json (pagoda_kit.py), GLO-30 ground.
Out: build/pagodas/pagodas.json            every pagoda: id, name, lon/lat, world x/z, W m, H m, shape, yaw, class, scheme,
                                           ground y (GLO-30), source of each number, placed-now flag
     build/pagodas/PagodaData_<n>.txt      the placed-now set as one string per page (for the Studio placer)

Rules (documented in the vault note City Legends/2026-11-16 Pagoda generator.md):
  * Skipped: the six landmarks other jobs build (Shwedagon + everything on its platform, Sule, Botataung, Chaukhtatgyi,
    Ngahtatgyi, Maha Wizaya) and Kaba Aye (World Peace), by name and by a radius round each.
  * Footprint: man_made=stupa / building=pagoda outlines are the stupa itself (W = short side of the smallest box round it,
    round ones 2 x sqrt(area / pi)). A place_of_worship outline over 900 m2 is the compound: the stupa is guessed at
    0.45 x the compound's short side (4-40 m) at its innermost point, unless a stupa outline lies inside it (then skipped).
    Points: 6 m (stupa) / 10 m (named pagoda), unless they fall inside an outline already used.
  * Shape: round when the outline has 10+ corners after a 0.4 m simplify and fills 74-84 % of its box; octagonal when it has
    7-9 corners or fills 80-90 % with 6+ corners; square otherwise.
  * Height: OSM height when tagged; else H = 1.9 x W (Yangon zedi run 1.6-2.2 x the base width).
  * Colour scheme: OSM colour tags first; 'Shwe' (gold) in the name -> gold; named -> gold; unnamed -> whitetop (white
    base and bell, gold lotus, bud and hti); PHOTO overrides below win.
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402
from shapely.geometry import Polygon, Point  # noqa: E402
from shapely.ops import transform  # noqa: E402
from shapely.ops import polylabel  # noqa: E402

assert geo.ONE_TO_ONE, 'run with YANGON_SCALE=1to1'
ROOT = geo.ROOT
D = os.path.join(ROOT, 'build', 'pagodas')
KIT = json.load(open(os.path.join(D, 'pagoda_kit.json')))
H_RATIO = KIT['h_ratio']

# the jobs running beside this one (16 Nov) and Kaba Aye: (name pattern, lon, lat, radius m)
EXCLUDE = [
    (r'shwe ?dagon|ရွှေတိဂုံ', 96.14966, 16.79846, 60.0),
    (r'\bsule\b|ဆူးလေ', 96.15852, 16.77443, 45.0),
    (r'botah?taung|ဗိုလ်တထောင်', 96.17205, 16.76946, 70.0),
    (r'chauk ?htat ?gyi|chaukhtatgyi', 96.15985, 16.80553, 90.0),
    (r'nga ?htat ?gyi|ngahtatgyi', 96.16256, 16.80834, 70.0),
    (r'maha ?wizaya|wizaya', 96.15063, 16.79443, 70.0),
    (r'kaba ?aye|kabar ?aye|world peace', 96.15447, 16.85681, 110.0),
]
P1 = geo.PILOT_LL['P1']
NEAR_DEG = (0.028, 0.027)  # ~3 km round P1
PLACE_BOX = (P1[0] - NEAR_DEG[0], P1[1] - NEAR_DEG[1], P1[2] + NEAR_DEG[0], P1[3] + NEAR_DEG[1])

# checked by eye on Esri World Imagery z19 (pagoda_esri.sheet -> build/pagodas/sheet_placed.jpg, 16 Nov) and photos:
# scheme, w (m), shift (east m, north m), skip (no stupa there). The placed-now set only; the rest is OSM-based until checked.
E = 'Esri z19'
PHOTO = {
    'n11806237755': dict(scheme='whitetop', src=E + ': white square'),
    'n13601098532': dict(scheme='whitegold', src=E + ': gold stupa on a white square terrace'),
    'n2583375434': dict(src=E + ': gold stupa, 10 m'),
    'n4328046089': dict(skip=E + ': point on a big red-roofed hall, no stupa seen'),
    'n4716828097': dict(skip=E + ': point on the road, no stupa seen'),
    'n5060321526': dict(skip=E + ': houses and yards, no stupa seen'),
    'n5158587121': dict(shift=(-7.0, 0.0), src=E + ': white and gold stupa 7 m west of the point'),
    'n6032270836': dict(skip=E + ': metal-roofed building and a crane, no stupa seen'),
    'n6202563445': dict(scheme='whitetop', src=E + ': small white zedi'),
    'n6210030951': dict(skip=E + ': blue metal roof, no stupa seen'),
    'n8318841850': dict(w=6.0, src=E + ': small gold top among roofs'),
    'w1554637597': dict(scheme='whitegold', src=E + ': small gold-topped stupa'),
    'w180543971': dict(src=E + ': gold stupa on a white platform, outline fits'),
    'w265735743': dict(scheme='mosaic', src=E + ' + photo (shwedagonpagodayangon.blogspot.com): grey-green mirror mosaic tower, gold top'),
    'w354454988': dict(shift=(0.0, -28.0), scheme='gold', src=E + ': gold and green dome 28 m south of the OSM footprint pick'),
    'w393490899': dict(w=14.0, scheme='whitegold', src=E + ': white 37 m terrace with 4 teal shrines, small gold middle'),
    'w397352635': dict(w=26.0, scheme='whitegold', src=E + ': gold stupa ~24 m on a 43 m white terrace'),
    'w405364332': dict(w=10.0, shift=(-25.0, 9.0), shape='sq', scheme='gold', src=E + ': gold stupa NW of the pink-roofed hall'),
    'w407771486': dict(src=E + ': gold stupa, outline fits'),
    'w425781831': dict(scheme='whitetop', src=E + ': small white zedi by the railway'),
    'w425804832': dict(skip=E + ': grey-roofed hall, no stupa seen'),
    'w444474741': dict(scheme='whitegold', src=E + ': white terrace, gold middle'),
    'w444474745': dict(scheme='whitegold', src=E + ': white terrace, gold top'),
    'w588550736': dict(scheme='white', src=E + ': white stupa, grey top'),
    'w923283762': dict(w=22.0, scheme='white', src=E + ': white stupa ~20 m with a pink-roofed hall'),
    # the rest of the city (data only for now; sheet_rest.jpg)
    'n10177587706': dict(scheme='whitegold', src=E + ': gold stupa on a white terrace'),
    'n2579920827': dict(scheme='whitetop', src=E + ': white zedi'),
    'n2579920829': dict(w=10.0, shift=(0.0, 12.5), src=E + ': gold stupa 12 m north of the point'),
    'n2875149013': dict(scheme='whitetop', src=E + ': white round stupa'),
    'n4483155292': dict(skip=E + ': no stupa seen clearly (road edge, roofs)'),
    'n4483163891': dict(skip=E + ': red-roofed building, no stupa seen'),
    'n4541168492': dict(skip=E + ': a hall (Bamboo Thread Buddha image), no stupa'),
    'n4938193139': dict(skip=E + ': blue roof; the real Shwe Phone Pwint is w289328798'),
    'n5273125898': dict(w=7.0, shift=(-7.0, -8.0), scheme='whitetop', src=E + ': small white zedi SW of the point'),
    'n5441557223': dict(skip='a Hindu temple by its name, not a stupa'),
    'n7123778010': dict(scheme='whitegold', src=E + ': gold and white stupa'),
    'w1266188921': dict(scheme='whitegold', src=E + ': white terrace, small gold middle'),
    'w346447607': dict(skip=E + ': red-roofed hall picked, no stupa seen in the compound'),
    'w379875332': dict(w=45.0, shape='oct', src=E + ': Swe Taw Myat (Buddha Tooth), a big hollow pagoda: stand-in until its own model'),
    'w385710305': dict(skip=E + ': hall picked; the stupa not found in the compound yet'),
    'w388247577': dict(w=24.0, shift=(24.0, 0.0), src=E + ': big gold stupa east of the green-roofed hall'),
    'w389512154': dict(skip=E + ': rows of small gold stupas round a hall: needs its own layout'),
    'w390143757': dict(skip=E + ': a grid of small white stupas round a hall: needs its own layout'),
    'w392995671': dict(scheme='white', src=E + ': pale octagonal stupa'),
    'w399545334': dict(w=19.0, shift=(17.5, -1.0), src=E + ': gold stupa SE of the red-roofed hall'),
    'w406044505': dict(w=30.0, scheme='whitegold', src=E + ': gold stupa ~30 m on a 43 m white terrace'),
    'w440018981': dict(skip=E + ': Kyauk Taw Gyi is a hall with tiered roofs, not a zedi'),
}


def local_m(lon0, lat0):
    kx = 111320 * math.cos(math.radians(lat0))
    ky = 110540
    return lambda x, y, z=None: ((x - lon0) * kx, (y - lat0) * ky)


def name_of(t):
    return t.get('name:en') or t.get('name') or t.get('name:my') or ''


def all_names(t):
    return ' '.join(v for k, v in t.items() if k.startswith('name') or k.startswith('alt_name') or k.startswith('old_name'))


def dist_m(lo0, la0, lo1, la1):
    return math.hypot((lo1 - lo0) * 111320 * math.cos(math.radians(la0)), (la1 - la0) * 110540)


# Shwedagon's platform (OSM way 117388457, landuse=religious): everything on it, Naungdawgyi included, is the Shwedagon job's
SHWEDAGON_PLATFORM = Polygon([(96.1482365, 16.7995677), (96.1486828, 16.7981043), (96.148691, 16.7980712), (96.1489887, 16.7971829),
                              (96.1498722, 16.7974498), (96.150868, 16.797727), (96.1506102, 16.7985588), (96.1501447, 16.8000765),
                              (96.1492774, 16.7999027)]).buffer(0.00014)


def excluded(o):
    if SHWEDAGON_PLATFORM.contains(Point(o['lon'], o['lat'])):
        return 'shwe dagon platform'
    nm = all_names(o['tags']).lower()
    for pat, lo, la, r in EXCLUDE:
        d = dist_m(lo, la, o['lon'], o['lat'])
        if d < r:
            return pat.split('|')[0]
        if re.search(pat, nm, re.I) and d < 1500:
            if 'kaba' in pat and 'original' in nm:
                continue  # the Original Kabar Aye Pagoda (Bahan) is a different pagoda
            return pat.split('|')[0]
    return None


def height_tag(t):
    h = t.get('height') or t.get('est_height')
    if h:
        try:
            return float(re.sub(r'[^0-9.]', '', str(h).split(';')[0]))
        except ValueError:
            return None
    return None


def scheme_of(o):
    t = o['tags']
    col = ' '.join(t.get(k, '') for k in ('colour', 'building:colour', 'roof:colour')).lower()
    if 'gold' in col or 'yellow' in col:
        return 'gold', 'osm colour'
    if 'white' in col:
        return 'whitetop', 'osm colour'
    nm = all_names(t)
    if re.search(r'shwe|ရွှ', nm, re.I):
        return 'gold', 'name (shwe = gold)'
    if name_of(t):
        return 'gold', 'guess: named pagoda'
    return 'whitetop', 'guess: unnamed zedi'


def shape_of(poly_m):
    s = poly_m.simplify(0.4)
    n = len(s.exterior.coords) - 1
    box = poly_m.minimum_rotated_rectangle
    fill = poly_m.area / max(box.area, 1e-6)
    if n >= 10 and 0.70 <= fill <= 0.86:
        return 'rd'
    if 7 <= n <= 9 or (n >= 6 and 0.80 <= fill <= 0.90):
        return 'oct'
    return 'sq'


def box_dims(poly_m):
    box = poly_m.minimum_rotated_rectangle
    c = list(box.exterior.coords)
    e1 = (c[1][0] - c[0][0], c[1][1] - c[0][1])
    e2 = (c[2][0] - c[1][0], c[2][1] - c[1][1])
    l1, l2 = math.hypot(*e1), math.hypot(*e2)
    a = math.degrees(math.atan2(e1[1], e1[0])) % 90.0  # sides' bearing, 0-90 (square symmetry)
    return min(l1, l2), max(l1, l2), a


_FP = None


def footprints():
    """real outlines (OSM + Microsoft, build/footprints/ygn_footprints.json) in an STRtree"""
    global _FP
    if _FP is None:
        from shapely.strtree import STRtree
        L = json.load(open(os.path.join(ROOT, 'build', 'footprints', 'ygn_footprints.json'), encoding='utf-8'))['buildings']
        polys, meta = [], []
        for b in L:
            if 9 <= b.get('area_m2', 0) <= 4000 and len(b['poly']) >= 3:
                try:
                    pg = Polygon(b['poly'])
                except Exception:
                    continue
                if pg.is_valid and not pg.is_empty:
                    polys.append(pg)
                    meta.append(b)
        _FP = (STRtree(polys), polys, meta)
    return _FP


def stupa_footprint(lon, lat, within=None, reach_m=12.0, skip_id=None):
    """the most stupa-like real outline: compact (fills 60 %+ of its box, sides within 1.35), 9-4000 m2, nearest the spot
    (inside the compound when one is given). Returns (lonlat polygon, metres polygon, source id) or None."""
    tree, polys, meta = footprints()
    area = within if within is not None else Point(lon, lat).buffer(reach_m / 110540.0)
    best, bs = None, 0.0
    for i in tree.query(area):
        pg = polys[int(i)]
        if skip_id and meta[int(i)]['id'] == skip_id:
            continue
        if within is not None and not within.contains(pg.representative_point()):
            continue
        if within is None and not area.intersects(pg):
            continue
        pm = transform(local_m(lon, lat), pg)
        w, l, _ = box_dims(pm)
        fill = pm.area / max(pm.minimum_rotated_rectangle.area, 1e-6)
        if fill < 0.6 or l > 1.35 * w:
            continue
        c = pm.centroid
        d = math.hypot(c.x, c.y)
        sc = (1.6 if 0.70 <= fill <= 0.90 else 1.0) * min(pm.area, 2500) / (1.0 + d / 25.0)
        if sc > bs:
            best, bs = (pg, pm, meta[int(i)]['id']), sc
    return best


def cls_of(w):
    for k, v in KIT['classes'].items():
        if w <= v['max_w_m']:
            return k
    return 'XL'


def main():
    raw = json.load(open(os.path.join(D, 'pagodas_osm.json'), encoding='utf-8'))
    out, skipped = [], []
    rings = []  # (poly lonlat, id) of outlines already used
    # outlines first (stupa outlines before compounds), then points
    order = sorted(raw, key=lambda o: (o['ring'] is None, o['pick'] != 'stupa'))
    for o in order:
        ex = excluded(o)
        if ex:
            skipped.append(dict(id=o['id'], name=name_of(o['tags']), why='landmark job: ' + ex))
            continue
        t = o['tags']
        src = {}
        if o['ring'] and len(o['ring']) >= 4:
            pl = Polygon(o['ring'])
            if not pl.is_valid:
                pl = pl.buffer(0)
            if pl.is_empty:
                continue
            f = local_m(o['lon'], o['lat'])
            pm = transform(f, pl)
            if o['pick'] == 'stupa' or pm.area <= 900:
                # a stupa outline inside one already used (a duplicate tag on the same thing): skip
                dup = [rid for r, rid in rings if r.intersection(pl).area > 0.5 * pl.area]
                if dup:
                    skipped.append(dict(id=o['id'], name=name_of(t), why='same outline as ' + dup[0]))
                    continue
                w, l, ang = box_dims(pm)
                shape = shape_of(pm)
                if shape == 'rd':
                    w = 2 * math.sqrt(pm.area / math.pi)
                c = pl.centroid
                lon, lat = c.x, c.y
                src['W'] = 'OSM outline'
                rings.append((pl, o['id']))
            else:
                inner = [rid for r, rid in rings if pl.contains(r.representative_point())]
                if inner:
                    skipped.append(dict(id=o['id'], name=name_of(t), why='compound; stupa ' + inner[0] + ' inside'))
                    rings.append((pl, o['id']))
                    continue
                w0, l0, ang = box_dims(pm)
                fp = stupa_footprint(o['lon'], o['lat'], within=pl, skip_id='o' + o['id'][1:])
                rings.append((pl, o['id']))
                fill = pm.area / max(pm.minimum_rotated_rectangle.area, 1e-6)
                if not fp and pm.area <= 2500 and fill >= 0.6 and l0 <= 1.35 * w0:
                    fp = (pl, pm, 'own outline (compact, nothing inside)')
                if fp:
                    fpl, fpm, fid = fp
                    w, l, ang = box_dims(fpm)
                    shape = shape_of(fpm)
                    if shape == 'rd':
                        w = 2 * math.sqrt(fpm.area / math.pi)
                    c = fpl.centroid
                    lon, lat = c.x, c.y
                    src['W'] = 'footprint %s in compound (%.0f m)' % (fid, w0)
                else:
                    w = max(4.0, min(40.0, 0.45 * w0))
                    p = polylabel(pl, 0.00001)
                    lon, lat = p.x, p.y
                    shape = 'sq'
                    src['W'] = 'guess: 0.45 x compound (%.0f m)' % w0
        else:
            pt = Point(o['lon'], o['lat'])
            hit = [rid for r, rid in rings if r.buffer(0.00008).contains(pt)]
            if hit:
                skipped.append(dict(id=o['id'], name=name_of(t), why='point inside outline ' + hit[0]))
                continue
            fp = stupa_footprint(o['lon'], o['lat'])
            if fp:
                fpl, fpm, fid = fp
                w, l, ang = box_dims(fpm)
                shape = shape_of(fpm)
                if shape == 'rd':
                    w = 2 * math.sqrt(fpm.area / math.pi)
                c = fpl.centroid
                lon, lat = c.x, c.y
                src['W'] = 'footprint %s at the point' % fid
            else:
                w = 6.0 if o['pick'] == 'stupa' else 10.0
                lon, lat, ang, shape = o['lon'], o['lat'], 0.0, 'sq'
                src['W'] = 'guess: point (%.0f m)' % w
        h = height_tag(t)
        if h:
            src['H'] = 'OSM height'
        else:
            h = H_RATIO * w
            src['H'] = 'ratio %.1f x W' % H_RATIO
        sch, src['scheme'] = scheme_of(o)
        if o['id'] in PHOTO:
            ph = PHOTO[o['id']]
            if 'skip' in ph:
                skipped.append(dict(id=o['id'], name=name_of(t), why='checked: ' + ph['skip']))
                continue
            if 'shift' in ph:
                lon += ph['shift'][0] / (111320 * math.cos(math.radians(lat)))
                lat += ph['shift'][1] / 110540.0
            if 'w' in ph and 'h' not in ph and src['H'].startswith('ratio'):
                h = H_RATIO * ph['w']
            w = ph.get('w', w)
            h = ph.get('h', h)
            sch = ph.get('scheme', sch)
            shape = ph.get('shape', shape)
            src['photo'] = ph.get('src', 'photo')
        x, z = geo.world(lon, lat)
        out.append(dict(id=o['id'], name=name_of(t), name_my=t.get('name:my') or (t.get('name') if t.get('name') != name_of(t) else ''),
                        pick=o['pick'], lon=round(lon, 6), lat=round(lat, 6), x=round(x, 2), z=round(z, 2),
                        w=round(w, 2), h=round(h, 2), shape=shape, yaw=round(ang, 1), cls=cls_of(w), scheme=sch, src=src,
                        tags={k: v for k, v in t.items() if k in ('man_made', 'building', 'amenity', 'religion', 'height', 'historic', 'tourism', 'wikidata', 'wikipedia')}))
    # near-duplicates (a point and an outline a few metres apart, two outlines for one stupa)
    keep = []
    for p in sorted(out, key=lambda p: (p['src']['W'] != 'OSM outline', -p['w'])):
        clash = [k for k in keep if dist_m(k['lon'], k['lat'], p['lon'], p['lat']) < 0.5 * (k['w'] + p['w']) * 0.8]
        if clash:
            skipped.append(dict(id=p['id'], name=p['name'], why='overlaps ' + clash[0]['id']))
            continue
        keep.append(p)
    out = keep
    import ground
    G = ground.Ground()
    for p in out:
        r = geo.m(p['w']) * 0.55
        ys = [G.y(p['x'] + dx * r, p['z'] + dz * r) for dx, dz in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1))]
        p['ground_y'] = round(float(min(ys)), 2)  # lowest: the base sits on the low side, the high side sinks in
        p['ground_span'] = round(float(max(ys) - min(ys)), 2)
        p['in_p1'] = P1[0] <= p['lon'] <= P1[2] and P1[1] <= p['lat'] <= P1[3]
        p['place_now'] = PLACE_BOX[0] <= p['lon'] <= PLACE_BOX[2] and PLACE_BOX[1] <= p['lat'] <= PLACE_BOX[3]
    out.sort(key=lambda p: p['id'])
    json.dump(dict(count=len(out), skipped=skipped, place_box=PLACE_BOX, pagodas=out),
              open(os.path.join(D, 'pagodas.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    # the placed-now set as compact rows for Studio: id|name|x|z|gy|wStuds|hStuds|shape|yaw|cls|scheme|inP1
    rows = []
    for p in out:
        if p['place_now']:
            nm = re.sub(r'[|;\n]', ' ', p['name'])[:40]
            rows.append('%s|%s|%.2f|%.2f|%.2f|%.2f|%.2f|%s|%.1f|%s|%s|%d' % (
                p['id'], nm, p['x'], p['z'], p['ground_y'], geo.m(p['w']), geo.m(p['h']), p['shape'], p['yaw'],
                p['cls'], p['scheme'], 1 if p['in_p1'] else 0))
    with open(os.path.join(D, 'PagodaData.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(rows))
    from collections import Counter
    print('found', len(raw), 'kept', len(out), 'skipped', len(skipped))
    print('class', Counter(p['cls'] for p in out))
    print('shape', Counter(p['shape'] for p in out), 'scheme', Counter(p['scheme'] for p in out))
    print('place now', sum(p['place_now'] for p in out), 'in P1', sum(p['in_p1'] for p in out))
    print('skip why', Counter(s['why'].split(' ')[0] + ' ' + s['why'].split(' ')[1] for s in skipped))


if __name__ == '__main__':
    main()
