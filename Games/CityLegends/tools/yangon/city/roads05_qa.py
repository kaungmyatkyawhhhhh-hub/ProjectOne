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
Friday-level junction checks (17 Nov, owner: kerbs lying diagonally across a junction, a median through a junction):
  mouth_short   a road end on another road that stops more than 1 stud short of its carriageway (gap)
  mouth_over    a road end that runs past the far edge of the road it ends on
  mouth_edge    a road end on a bigger road where one carriageway edge never reaches the bigger road's edge
                (YangonRoads.buildMouth fails: "an edge of X never meets Y", kerbs left across the junction)
  kerb_cross    a road's kerb + pavement strip (carriageway edge .. + walk) over another road's / ring's carriageway,
                away from the road's own ends (a mouth is trimmed by the builder; a crossing is not)
  median_cross  a median over any other road's / ring's carriageway (streets too)
  zero_width    a sample with carriageway width under 2 studs
  overlap       two roads whose carriageways overlap far more than a crossing would (a doubled road)
  rank_dup      two roads with one rank
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


def strip(s, cut, side, walk):
    """the kerb + pavement band on one side: carriageway edge .. edge + walk (side -1 left, +1 right)"""
    out = []
    for i in range(len(s) - 1):
        if i in cut or i + 1 in cut:
            continue
        a, b = s[i], s[i + 1]
        ra, rb = np.array([-a[4], a[3]]), np.array([-b[4], b[3]])
        pa, pb = np.array([a[0], a[2]]), np.array([b[0], b[2]])
        ha, hb = (a[6], b[6]) if side < 0 else (a[7], b[7])
        q = [pa + side * ra * ha, pa + side * ra * (ha + walk), pb + side * rb * (hb + walk), pb + side * rb * hb]
        P = Polygon(q)
        if P.is_valid and P.area > 0.01:
            out.append((i, P))
    return out


def junction_checks(data, cutd, cw, names, geoms, tree, rings, issues):
    import collections
    rk = collections.defaultdict(list)
    for r in data['roads']:
        rk[r['rank']].append(r['name'])
    for k, v in rk.items():
        if len(v) > 1:
            issues['rank_dup'].append(dict(rank=k, roads=v))
    ringU = unary_union(rings) if rings else Polygon()
    endpts = {r['name']: [np.array([r['s'][k][0], r['s'][k][2]]) for k in (0, -1)] for r in data['roads']}
    for d in data['decks']:
        endpts[d['name']] = [np.array([d['s'][k][0], d['s'][k][2]]) for k in (0, -1)]
    byname = {r['name']: r for r in data['roads']}
    rank = {r['name']: r['rank'] for r in data['roads']}
    name_i = set(names)
    lines = {r['name']: LineString([(q[0], q[2]) for q in r['s']]) for r in data['roads'] if len(r['s']) > 1}
    for n_, cs_ in cutd.items():  # a road cut where it crosses a bigger one: both sides of the cut are mouths
        if n_ in byname:
            ss = byname[n_]['s']
            endpts.setdefault(n_, []).extend(np.array([ss[i][0], ss[i][2]]) for i in cs_ if 0 <= i < len(ss) and ((i - 1) not in cs_ or (i + 1) not in cs_))
    for r in data['roads']:
        s = r['s']
        cut = cutd.get(r['name'], set())
        n = r['name']
        # zero width
        for i, q in enumerate(s):
            if i not in cut and q[6] + q[7] < 2:
                issues['zero_width'].append(dict(road=n, x=round(q[0], 1), z=round(q[2], 1)))
                break
        # mouths: the end against the road it lands on
        ends = []
        for k in (0, -1):
            p = Point(s[k][0], s[k][2])
            if ringU.distance(p) < 2:
                continue
            for j in tree.query(p.buffer(20)):
                o = names[int(j)]
                if o == n:
                    continue
                g = geoms[int(j)]
                d = g.distance(p)
                if d > 12:
                    continue
                ends.append((k, o))
                e2e = min(np.linalg.norm(e - np.array([s[k][0], s[k][2]])) for e in endpts.get(o, [])[:2]) < 40
                if d > 1.0 and not e2e and r['kind'] != 'side':
                    issues['mouth_short'].append(dict(road=n, on=o, gap=round(d, 1), x=round(s[k][0], 1), z=round(s[k][2], 1)))
                else:
                    # running on past the far edge: the end sample's forward step stays inside, the point beyond is out
                    q = s[k]
                    fwd = np.array([q[3], q[4]]) * (1 if k == -1 else -1)
                    back = Point(q[0] - fwd[0] * 4, q[2] - fwd[1] * 4)
                    if g.contains(p) and not g.buffer(0.5).contains(back) and g.distance(back) > 2 and                             LineString([(back.x, back.y), (q[0], q[2])]).intersection(g).length < 1:
                        issues['mouth_over'].append(dict(road=n, on=o, x=round(q[0], 1), z=round(q[2], 1)))
                break
        if len(s) < 2:
            continue
        LA = LineString([(q[0], q[2]) for q in s])
        # mouth edges (YangonRoads.buildMouth): from the end, BOTH carriageway edges must reach the bigger road's edge,
        # or the mouth fails and the kerbs / pavement are left lying across the junction
        for k, o in ends:
            if o not in rank or rank[o] >= rank[n] or r['kind'] == 'side':
                continue
            if min(np.linalg.norm(e - np.array([s[k][0], s[k][2]])) for e in endpts.get(o, [])[:2]) < 40:
                continue  # end to end, not a mouth
            G = geoms[names.index(o)] if o in name_i else None
            if G is None:
                continue
            seg = s[:13] if k == 0 else s[-13:]
            for side in (-1, 1):
                E = []
                for q in seg:
                    h = q[6] if side < 0 else q[7]
                    E.append((q[0] - q[4] * h * side, q[2] + q[3] * h * side))
                if not LineString(E).intersects(G.boundary) and not all(G.contains(Point(e)) for e in E[-2:] if k == -1):
                    issues['mouth_edge'].append(dict(road=n, on=o, side=side, x=round(s[k][0], 1), z=round(s[k][2], 1)))
                    break
        # kerb / pavement strip over a carriageway where neither road ends on the other nor crosses it
        walk = max(r.get('walkL') or 0, r.get('walkR') or 0, 1.5)
        for side, wk in ((-1, r.get('walkL') or walk), (1, r.get('walkR') or walk)):
            last = -99
            for i, P in strip(s, cut, side, wk + 1.5):
                c = np.array([s[i][0], s[i][2]])
                reach = max(s[i][6], s[i][7]) + wk + 40
                hit = None
                for j in tree.query(P):
                    o = names[int(j)]
                    if o == n or geoms[int(j)].intersection(P).area <= 1.0:
                        continue
                    if any(np.linalg.norm(e - c) < reach for e in endpts.get(o, ()) + endpts.get(n, [])[:2]):
                        continue  # one of the two ends on the other here: a mouth
                    if o in byname and LA.distance(lines[o]) < 1 and Point(c).distance(LA.intersection(lines[o])) < reach:
                        continue  # a crossing: the builder cuts the smaller road and opens both kerbs
                    hit = o
                    break
                if hit:
                    if i - last > 6:
                        issues['kerb_cross'].append(dict(road=n, other=hit, x=round(s[i][0], 1), z=round(s[i][2], 1)))
                    last = i
        if any(q[8] > 0 for q in s):
            last = -99
            for i in range(len(s) - 1):
                if i in cut or s[i][8] <= 0:
                    continue
                p = Point(s[i][0], s[i][2])
                hit = None
                for j in tree.query(p.buffer(s[i][8])):
                    o = names[int(j)]
                    if o != n and geoms[int(j)].distance(p) < 0.5:
                        hit = o
                        break
                if hit is None and ringU.distance(p) < 0.5:
                    hit = 'ring'
                if hit:
                    if i - last > 6:
                        issues['median_cross'].append(dict(road=n, other=hit, x=round(s[i][0], 1), z=round(s[i][2], 1)))
                    last = i
    # doubled roads: overlap far beyond a crossing box
    seen = set()
    wid = {r['name']: max(q[6] + q[7] for q in r['s']) for r in data['roads']}
    for a, ga in zip(names, geoms):
        if a not in wid:
            continue  # decks lie over their roads
        for j in tree.query(ga):
            b = names[int(j)]
            if b == a or (b, a) in seen or b not in wid:
                continue
            seen.add((a, b))
            inter = ga.intersection(geoms[int(j)]).area
            if inter > 2.5 * wid[a] * wid[b] + 500:
                c = ga.intersection(geoms[int(j)]).centroid
                issues['overlap'].append(dict(a=a, b=b, area=round(inter), x=round(c.x, 1), z=round(c.y, 1)))


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
    allg = geoms + rings
    alltree = STRtree(allg)
    issues = {k: [] for k in ('dead_end', 'paint_off', 'median_box', 'zebra_median', 'deck_grade', 'deck_foot', 'stack_paint',
                              'mouth_short', 'mouth_over', 'mouth_edge', 'kerb_cross', 'median_cross', 'zero_width', 'overlap', 'rank_dup')}
    junction_checks(data, cutd, cw, names, geoms, tree, rings, issues)
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
        loc = [allg[int(j)] for j in alltree.query(P)]
        off = P.difference(unary_union(loc).buffer(0.3)).area if loc else P.area
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
