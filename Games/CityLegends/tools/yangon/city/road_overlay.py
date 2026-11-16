"""Road plan overlay + OSM mismatch check per district (17 Nov 2026, owner: "in google maps, its entirely different";
the street plan picture is approved before building).

    YANGON_SCALE=1to1 python road_overlay.py <roads05 dir tag, e.g. P1_P2_P3> <district> [zoom=17]
-> "<vault>/City Legends/Road plan - <district> overlay.png" (Esri satellite, our carriageways coloured by kind:
   route orange, street yellow, side cyan, deck magenta, roundabouts orange; OSM drivable centrelines thin white;
   OSM roads we lack red; our samples off every OSM way purple) and build/city_1to1/roads05_<tag>/osm_check_<d>.json

Mismatch rules (all in the district box):
  missing   an OSM way that roads05 keeps (keep_way) with more than half its length over 3 m off our carriageways
  ours_off  one of our roads with more than half its samples further than its half width + 5 m from every OSM
            highway way (fictional)
  offset    our samples 5-8 m from the nearest kept OSM way (merged dual carriageways sit between their two lines)
  cut_end   one of our road ends with no road / ring / deck on it where the OSM way it follows runs on past it (> 15 m)
"""
import json, math, os, sys

import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial import cKDTree
from shapely.geometry import LineString, Point

import geo
import roads05 as R05
from footprints_compare import fetch, tile_xy  # (its module code prints a report on import)
from shapely.geometry import Polygon
from shapely.ops import unary_union

VAULT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', '..', 'City Legends'))
COL = dict(route=(255, 140, 0, 120), street=(255, 225, 40, 110), side=(0, 220, 255, 140), deck=(255, 0, 200, 150))


def dense(pts, step):
    out = []
    for a, b in zip(pts[:-1], pts[1:]):
        n = max(1, int(math.dist(a, b) / step))
        for k in range(n):
            out.append((a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n))
    out.append(tuple(pts[-1]))
    return out


def main():
    tag, dist = sys.argv[1], sys.argv[2]
    z = int(sys.argv[3]) if len(sys.argv) > 3 else 17
    lo0, la0, lo1, la1 = geo.PILOT_LL[dist]
    data = json.load(open(os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag, 'roads.json'), encoding='utf-8'))
    # satellite
    x0, y0 = tile_xy(lo0, la1, z)
    x1, y1 = tile_xy(lo1, la0, z)
    tx0, ty0, tx1, ty1 = int(x0), int(y0), int(x1) + 1, int(y1) + 1
    im = Image.new('RGB', (256 * (tx1 - tx0), 256 * (ty1 - ty0)))
    for i in range(tx0, tx1):
        for j in range(ty0, ty1):
            im.paste(fetch(z, i, j), (256 * (i - tx0), 256 * (j - ty0)))

    def px_ll(lon, lat):
        X, Y = tile_xy(lon, lat, z)
        return ((X - tx0) * 256, (Y - ty0) * 256)

    def px(x, zz):
        return px_ll(*geo.lonlat(x, zz))
    ov = Image.new('RGBA', im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    # ours
    our_pts = []
    our_by = []
    our_w = []
    cw = []
    for r in data['roads']:
        s = r['s']
        cut = set(data['cut'].get(r['name'], ()))
        col = COL.get(r['kind'], COL['street'])
        for i in range(len(s) - 1):
            if i in cut or i + 1 in cut:
                continue
            a, b = s[i], s[i + 1]
            q = [(a[0] + a[4] * a[6], a[2] - a[3] * a[6]), (a[0] - a[4] * a[7], a[2] + a[3] * a[7]),
                 (b[0] - b[4] * b[7], b[2] + b[3] * b[7]), (b[0] + b[4] * b[6], b[2] - b[3] * b[6])]
            d.polygon([px(*p) for p in q], fill=col)
            g = Polygon(q)
            if g.is_valid:
                cw.append(g)
        for q in s:
            our_pts.append((q[0], q[2]))
            our_by.append(r['name'])
            our_w.append(max(q[6], q[7]))
    for dk in data['decks']:
        s = dk['s']
        for a, b in zip(s[:-1], s[1:]):
            d.line([px(a[0], a[2]), px(b[0], b[2])], fill=COL['deck'], width=max(2, int(dk['half'] * 2 / geo.SPM / 1.19)))
    for g in data['roundabouts']:
        c = px(g['c'][0], g['c'][2])
        rr = g['r_out'] / geo.SPM / (156543.03 * math.cos(math.radians(16.8)) / 2 ** z)
        d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], outline=COL['route'], width=4)
    # OSM
    box = (lo0 - 0.002, la0 - 0.002, lo1 + 0.002, la1 + 0.002)
    kept, allw = [], []
    for w in geo.load('roads'):
        p = w['p']
        if max(q[0] for q in p) < box[0] or min(q[0] for q in p) > box[2] or max(q[1] for q in p) < box[1] or min(q[1] for q in p) > box[3]:
            continue
        P = [geo.world(q[0], q[1]) for q in p]
        allw.append(P)
        if R05.keep_way(w, set()):
            kept.append((w, P))
    for w, P in kept:
        d.line([px(*q) for q in P], fill=(255, 255, 255, 230), width=2)
    CW = unary_union(cw + [Point(g['c'][0], g['c'][2]).buffer(g['r_out']) for g in data['roundabouts']]
                     + [LineString([(q[0], q[2]) for q in dk['s']]).buffer(dk['half']) for dk in data['decks']])
    near8 = geo.m(8)
    res = dict(district=dist, missing=[], ours_off=[], offset_samples=0, cut_end=[])
    inbox = lambda x, zz: lo0 <= geo.lonlat(x, zz)[0] <= lo1 and la0 <= geo.lonlat(x, zz)[1] <= la1
    for w, P in kept:
        D = dense(P, geo.m(5))
        D = [q for q in D if inbox(*q)]
        if len(D) < 4:
            continue
        far = np.array([CW.distance(Point(q)) > geo.m(3) for q in D])
        if far.mean() > 0.5:
            name = w['t'].get('name:en') or w['t'].get('name') or ''
            res['missing'].append(dict(osm=w.get('id'), name=name, hw=w['t'].get('highway'), m=round(len(D) * 5),
                                       x=round(D[len(D) // 2][0], 1), z=round(D[len(D) // 2][1], 1)))
            for a, b in zip(D[:-1], D[1:]):
                d.line([px(*a), px(*b)], fill=(255, 30, 30, 255), width=5)
    osm_all = cKDTree(np.array([q for P in allw for q in dense(P, geo.m(5))]))
    kept_t = cKDTree(np.array([q for _, P in kept for q in dense(P, geo.m(5))]))
    names = np.array(our_by)
    O = np.array(our_pts)
    inb = np.array([inbox(*q) for q in our_pts])
    da, _ = osm_all.query(O)
    Wd = np.array(our_w)
    dk_, _ = kept_t.query(O)
    for nm in set(names[inb]):
        m_ = (names == nm) & inb
        if (da[m_] > Wd[m_] + geo.m(5)).mean() > 0.5:
            i = np.where(m_)[0][m_.sum() // 2]
            res['ours_off'].append(dict(road=nm, x=round(O[i, 0], 1), z=round(O[i, 1], 1)))
    off = inb & (dk_ > geo.m(5)) & (dk_ <= near8)
    res['offset_samples'] = int(off.sum())
    for q in O[inb & (da > Wd + geo.m(5))]:
        c = px(*q)
        d.ellipse([c[0] - 3, c[1] - 3, c[0] + 3, c[1] + 3], fill=(170, 0, 255, 255))
    # our dead ends where OSM runs on
    qa = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag, 'qa.json')
    if os.path.exists(qa):
        ends = [(w, P) for w, P in kept]
        lines = [LineString(P) for _, P in ends]
        for e in json.load(open(qa))['dead_end']:
            if not inbox(e['x'], e['z']):
                continue
            pt = Point(e['x'], e['z'])
            best = min(range(len(lines)), key=lambda k: lines[k].distance(pt)) if lines else None
            if best is None or lines[best].distance(pt) > near8:
                continue
            Lb = lines[best]
            t = Lb.project(pt)
            if t > geo.m(15) and Lb.length - t > geo.m(15):
                res['cut_end'].append(dict(road=e['road'], x=e['x'], z=e['z']))
                c = px(e['x'], e['z'])
                d.ellipse([c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9], outline=(255, 0, 0, 255), width=4)
    # crop to the district
    a = px_ll(lo0, la1)
    b = px_ll(lo1, la0)
    out = Image.alpha_composite(im.convert('RGBA'), ov).crop((int(a[0]), int(a[1]), int(b[0]), int(b[1]))).convert('RGB')
    os.makedirs(VAULT, exist_ok=True)
    pth = os.path.join(VAULT, 'Road plan - %s overlay.png' % dist)
    out.save(pth, optimize=True)
    json.dump(res, open(os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag, 'osm_check_%s.json' % dist), 'w'), indent=1, ensure_ascii=False)
    print(dist, pth, out.size, json.dumps({k: (len(v) if isinstance(v, list) else v) for k, v in res.items() if k != 'district'}))


if __name__ == '__main__':
    main()
