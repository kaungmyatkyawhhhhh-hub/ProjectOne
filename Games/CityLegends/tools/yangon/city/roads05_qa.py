"""QA of a roads05 network from its data (17 Nov 2026, owner: "theres so many more mistakes on the roads").

    YANGON_SCALE=1to1 python roads05_qa.py <tags joined by _> [roads.json] [paint.json]
-> build/city_1to1/roads05_<tags>/qa.json (issues per type with x, z) and prints the counts.

Types:
  dead_end      a road end that is not on another road / ring / deck and not on the map edge (a real dead end in OSM
                is listed too: look at the main-road ones first)
  paint_off     a paint polygon reaching more than 1 sq stud off the carriageways (lines past the asphalt)
  median_box    a median sample on another main road's carriageway (a median through a junction box)
  zebra_median  a zebra or stop line crossing a median
  deck_grade    a deck steeper than 8% anywhere, or a step over 1.5 studs between samples
  deck_foot     a deck end not on its road's height (more than 0.3 studs off)
  stack_paint   three or more paint polygons piled on one spot (arrows / lines piled at a junction)
"""
import json, os, sys

import numpy as np
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo


def quads(s, cut=(), lo=6, hi=7, inner=None):
    out = []
    cut = set(cut)
    for i in range(len(s) - 1):
        if i in cut or i + 1 in cut:
            continue
        a, b = s[i], s[i + 1]
        ra = np.array([-a[4], a[3]])
        rb = np.array([-b[4], b[3]])
        pa, pb = np.array([a[0], a[2]]), np.array([b[0], b[2]])
        if inner is None:
            q = [pa - ra * a[lo], pa + ra * a[hi], pb + rb * b[hi], pb - rb * b[lo]]
        else:
            q = [pa - ra * a[inner], pa + ra * a[inner], pb + rb * b[inner], pb - rb * b[inner]]
        P = Polygon(q)
        if P.is_valid and P.area > 0.01:
            out.append(P)
    return out


def main():
    tag = sys.argv[1]
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(D, 'roads.json'), encoding='utf-8'))
    paint = json.load(open(sys.argv[3] if len(sys.argv) > 3 else os.path.join(D, 'paint.json')))['items']
    cutd = {k: set(v) for k, v in data['cut'].items()}
    cw = {}
    for r in data['roads']:
        cw[r['name']] = unary_union(quads(r['s'], cutd.get(r['name'], ())))
    for d in data['decks']:
        cw[d['name']] = unary_union(quads(d['s']))
    rings = [Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 1, 64) for g in data['roundabouts']]
    names = list(cw)
    geoms = [cw[n] for n in names]
    tree = STRtree(geoms)
    allcw = unary_union(geoms + rings)
    issues = {k: [] for k in ('dead_end', 'paint_off', 'median_box', 'zebra_median', 'deck_grade', 'deck_foot', 'stack_paint')}
    # dead ends
    for r in data['roads']:
        s = r['s']
        for end, k in (('start', 0), ('end', -1)):
            if r.get('edgeStart' if k == 0 else 'edgeEnd'):
                continue
            p = Point(s[k][0], s[k][2])
            if any(g.distance(p) < 2 for g in rings):
                continue
            on = False
            for j in tree.query(p.buffer(3)):
                n = names[int(j)]
                if n != r['name'] and geoms[int(j)].distance(p) < 3:
                    on = True
                    break
            if not on:
                issues['dead_end'].append(dict(road=r['name'], kind=r['kind'], end=end, x=round(s[k][0], 1), z=round(s[k][2], 1)))
    # paint off the asphalt
    med = []
    for r in data['roads']:
        if any(q[8] > 0 for q in r['s']):
            med.extend(quads(r['s'], cutd.get(r['name'], ()), inner=8))
    medU = unary_union(med) if med else Polygon()
    pts = []
    polys = []
    for it in paint:
        P = Polygon(json.loads(it['p']) if isinstance(it['p'], str) else it['p'])
        if not P.is_valid:
            P = P.buffer(0)
        polys.append(P)
        off = P.difference(allcw.buffer(0.3)).area
        if off > 1.0:
            c = P.centroid
            issues['paint_off'].append(dict(what=it.get('w'), road=it.get('r'), off=round(off, 1), x=round(c.x, 1), z=round(c.y, 1)))
        if it.get('w') in ('zebra', 'stop') and P.intersection(medU).area > 0.5:
            c = P.centroid
            issues['zebra_median'].append(dict(what=it.get('w'), road=it.get('r'), x=round(c.x, 1), z=round(c.y, 1)))
        pts.append((P.centroid.x, P.centroid.y))
    # piles of paint
    pt = STRtree(polys)
    seen = set()
    for i, P in enumerate(polys):
        if i in seen or P.area < 0.5:
            continue
        hit = [int(j) for j in pt.query(P) if int(j) != i and polys[int(j)].intersection(P).area > 0.3]
        if len(hit) >= 2:
            seen.update(hit)
            c = P.centroid
            issues['stack_paint'].append(dict(n=len(hit) + 1, what=paint[i].get('w'), road=paint[i].get('r'), x=round(c.x, 1), z=round(c.y, 1)))
    # medians through junction boxes
    mains = {r['name']: cw[r['name']] for r in data['roads'] if r['kind'] == 'route'}
    for r in data['roads']:
        cut = cutd.get(r['name'], set())
        last = -99
        for i, q in enumerate(r['s']):
            if q[8] <= 0 or i in cut:
                continue
            p = Point(q[0], q[2])
            for n, g in mains.items():
                if n != r['name'] and g.distance(p) < 0.5:
                    if i - last > 6:
                        issues['median_box'].append(dict(road=r['name'], other=n, x=round(q[0], 1), z=round(q[2], 1)))
                    last = i
                    break
    # decks
    roadby = {r['name']: r for r in data['roads']}
    for d in data['decks']:
        s = np.array(d['s'])
        c = np.r_[0, np.cumsum(np.linalg.norm(np.diff(s[:, [0, 2]], axis=0), axis=1))]
        g = np.abs(np.diff(s[:, 1])) / np.maximum(np.diff(c), 1e-6)
        st = np.abs(np.diff(s[:, 1]))
        if g.max() > 0.08 or st.max() > 1.5:
            i = int(np.argmax(g))
            issues['deck_grade'].append(dict(deck=d['name'], grade=round(float(g.max()), 3), step=round(float(st.max()), 2), x=round(s[i, 0], 1), z=round(s[i, 2], 1)))
        r = roadby.get(d['of'])
        if r:
            for k, i in ((0, d['from']), (-1, d['to'])):
                dy = abs(s[k][1] - r['s'][i][1])
                if dy > 0.3:
                    issues['deck_foot'].append(dict(deck=d['name'], dy=round(float(dy), 2), x=round(s[k][0], 1), z=round(s[k][2], 1)))
    json.dump(issues, open(os.path.join(D, 'qa.json'), 'w'), indent=1)
    print(json.dumps({k: len(v) for k, v in issues.items()}))
    return issues


if __name__ == '__main__':
    main()
