"""Paint QA of a roads05 network (J15, 18 Nov 2026; owner refs 'road markings messed up 1-5', 'double junction zebras
and stop lines', 'Sule Square road', 'junction box grass hole', 'broken median pieces'). Separate from roads05_qa.py
(geometry). Reads roads.json + paint.json, never the paint code's own bookkeeping (it shares only the box rule).

    YANGON_SCALE=1to1 python roads05_paint_qa.py <tags joined by _> [paint.json]
-> build/city_1to1/roads05_<tags>/qa_paint_J15.json (rows with x, z) and prints the counts.

  arrow_missing       a lane at a stop line with no turn arrow 5-40 studs behind it
  stopline_missing    a zebra arm with incoming traffic and no stop line
  stopline_wrong_side a stop line in a box, on / touching a zebra, on the box side of its zebra, reaching over the centre
                      into the outgoing lanes, or covering under 80% of the incoming lanes
  dash_jog            a lane dash whose next dash along the line sits 1.5-4 studs sideways (a jump, not a taper)
  dash_side_by_side   two lane dashes side by side under 4 studs apart
  paint_in_median     paint on a median, an island, or a median's nose cap (paint must stop short of it)
  double_box          a zebra / stop line inside the joined box of a double junction (two parallel roads < 40 apart
                      crossing one road)
  box_paint           any line / zebra / stop inside a junction box
  paint_snake         a line that wiggles (turns left-right-left by over 3 degrees) or kinks over 15 degrees
  edge_missing        a stretch of 24+ studs of kerb on a main road (outer or median) with no yellow line along it
  zebra_colour        a zebra not in the faded ochre paint (kind LZ = 230, 190, 110)
  zebra_torn          a zebra bar touched / cut by other paint, or not a whole rectangle
"""
import json, math, os, sys

import numpy as np
from scipy.spatial import cKDTree
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import unary_union
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo
from roads05_qa import quads
from roads05_paint import raw_boxes, double_pairs, merged_boxes, neff, runs, nose_caps

RULES = ('arrow_missing', 'stopline_missing', 'stopline_wrong_side', 'dash_jog', 'dash_side_by_side', 'paint_in_median',
         'double_box', 'box_paint', 'paint_snake', 'edge_missing', 'zebra_colour', 'zebra_torn')
LINES = ('lane', 'centre', 'median', 'edge', 'deck centre', 'deck lane', 'ring lane')
DASHES = ('lane', 'deck lane', 'ring lane')
JOG = 1.5      # a visible step (owner ref 5 was a whole lane line); under it is a taper on a curve


def xz(p):
    return dict(x=round(float(p[0]), 1), z=round(float(p[1]), 1))


def axis(P):
    """(middle, unit long axis, length, end a, end b) of a thin polygon's minimum rectangle"""
    c = list(P.minimum_rotated_rectangle.exterior.coords)[:4]
    c = [np.array(p) for p in c]
    e1, e2 = c[1] - c[0], c[2] - c[1]
    if np.linalg.norm(e1) >= np.linalg.norm(e2):
        L, u = np.linalg.norm(e1), e1 / max(np.linalg.norm(e1), 1e-9)
        a, b = (c[0] + c[3]) / 2, (c[1] + c[2]) / 2
    else:
        L, u = np.linalg.norm(e2), e2 / max(np.linalg.norm(e2), 1e-9)
        a, b = (c[0] + c[1]) / 2, (c[2] + c[3]) / 2
    return (a + b) / 2, u, L, a, b


def turns(P):
    """signed turning angles (degrees) along each long side of a line polygon (corners over 45 split the sides)"""
    if P.geom_type != "Polygon":
        return []
    co = list(P.simplify(0.05).exterior.coords)[:-1]
    n = len(co)
    if n < 5:
        return []
    t = []
    for i in range(n):
        a, b, c = np.array(co[i - 1]), np.array(co[i]), np.array(co[(i + 1) % n])
        u, v = b - a, c - b
        if np.linalg.norm(u) < 1.0 or np.linalg.norm(v) < 1.0:
            t.append(None)
            continue
        t.append(math.degrees(math.atan2(u[0] * v[1] - u[1] * v[0], u @ v)))
    sides, cur = [], []
    for k, x in enumerate(t):
        if x is None or abs(x) > 45:
            if cur:
                sides.append(cur)
            cur = []
        else:
            cur.append((x, co[k]))
    if cur:
        sides.append(cur)
    return sides


def main():
    av = [a for a in sys.argv[1:] if not a.startswith('--')]
    tag = av[0]
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(os.path.join(D, 'roads.json'), encoding='utf-8'))
    items = json.load(open(av[1] if len(av) > 1 else os.path.join(D, 'paint.json')))['items']
    iss = {k: [] for k in RULES}
    roads = data['roads']
    R = {r['name']: r for r in roads}
    cutd = {k: set(v) for k, v in data['cut'].items()}
    main_ = [r for r in roads if r['kind'] in ('route', 'side')]
    cw = {r['name']: unary_union(quads(r['s'], cutd.get(r['name'], ()))) for r in roads}
    tree = STRtree([cw[r['name']] for r in roads])
    raw = raw_boxes(roads, main_, cw, tree)
    rawU = unary_union([h for h, _, _ in raw]) if raw else Polygon()
    rings = unary_union([Point(g['c'][0], g['c'][2]).buffer(g['r_out'] + 1, 64) for g in data['roundabouts']])
    polys = []
    for it in items:
        P = Polygon(it['p'])
        polys.append(P if P.is_valid else P.buffer(0))
    W = [it['w'] for it in items]
    ptree = STRtree(polys)
    by = {}
    for i, w in enumerate(W):
        by.setdefault(w, []).append(i)
    S = {r['name']: np.array([(q[0], q[2]) for q in r['s']]) for r in roads}
    KD = {}

    def sample(name, p):
        if name not in KD:
            KD[name] = cKDTree(S[name])
        return int(KD[name].query(p)[1])

    lvl = [bool(it.get('deck')) for it in items]

    def near(g, d, kinds=None, deck=False):
        """paint items within d of g on one level (deck paint lies over ground paint in plan only)"""
        return [int(j) for j in ptree.query(g.buffer(d)) if (kinds is None or W[int(j)] in kinds) and lvl[int(j)] == deck
                and polys[int(j)].distance(g) <= d]

    # zebra groups (one per arm): bars within 2 studs of each other
    zeb = by.get('zebra', [])
    zg = unary_union([polys[i].buffer(1.0) for i in zeb]) if zeb else Polygon()
    zgroups = list(zg.geoms) if hasattr(zg, 'geoms') else ([zg] if not zg.is_empty else [])
    zgtree = STRtree(zgroups) if zgroups else None
    raw_tree = STRtree([h for h, _, _ in raw]) if raw else None

    def nearest_box(p):
        if raw_tree is None:
            return None
        j = raw_tree.nearest(Point(p))
        return raw[int(j)][0]

    # --- 2. stop lines
    for i in by.get('stop', []):
        P = polys[i]
        c, u, L, e0, e1 = axis(P)
        bx = nearest_box(c)
        if bx is None:
            continue
        nb = np.array(bx.exterior.interpolate(bx.exterior.project(Point(c))).coords[0])
        h = np.array([-u[1], u[0]])
        if h @ (nb - c) < 0:
            h = -h                     # heading into the box
        why = None
        if P.intersects(rawU.buffer(0.5)):
            why = 'in box'
        elif near(P, 0.5, ('zebra',)):
            why = 'on zebra'
        else:
            zs = near(P, 10.0, ('zebra',))
            if zs and min(polys[j].distance(bx) for j in zs) > P.distance(bx):
                why = 'box side of zebra'
        r = R.get(items[i].get('r'))
        if r is not None and why is None:
            q = r['s'][sample(r['name'], c)]
            rq = np.array([-q[4], q[3]])
            one = bool(r.get('oneway'))
            if not one:
                c0 = 0.0 if q[8] > 0.3 else (q[7] - q[6]) / 2
                mid = np.array([q[0], q[2]]) + rq * c0
                rg = np.array([-h[1], h[0]])          # the driver's right
                if min((e0 - mid) @ rg, (e1 - mid) @ rg) < -0.3:
                    why = 'over the centre'
                span = (q[7] if rq @ rg > 0 else q[6]) - (q[11] if q[8] > 0.3 else c0 * (1 if rq @ rg > 0 else -1) + q[11])
            else:
                span = q[6] + q[7]
            if why is None and L < 0.8 * span - 1.0:
                why = 'short'
        if why:
            iss['stopline_wrong_side'].append(dict(why=why, road=items[i].get('r'), **xz(c)))
        # --- 1. arrows on every incoming lane
        if r is None or why in ('in box', 'over the centre'):
            continue
        q = r['s'][sample(r['name'], c)]
        n = neff(q, bool(r.get('oneway')))
        for j in range(n):
            lc = e0 + (e1 - e0) * (j + 0.5) / n
            probe = LineString([lc - h * 5, lc - h * 40]).buffer(1.5)
            if not near(probe, 0.0, ('arrow',)):
                iss['arrow_missing'].append(dict(road=r['name'], lane=j, n=n, **xz(lc - h * 15)))
    # --- 2b. zebra arms with incoming traffic and no stop line
    stops = [polys[i] for i in by.get('stop', [])]
    stree = STRtree(stops) if stops else None
    for g in zgroups:
        c = np.array(g.centroid.coords[0])
        names = [items[i].get('r') for i in near(g, 0.0, ('zebra',))]
        r = R.get(names[0]) if names else None
        if r is None:
            continue
        bx = nearest_box(c)
        if bx is None:
            continue
        q = r['s'][sample(r['name'], c)]
        h = np.array(bx.centroid.coords[0]) - c
        if r.get('oneway'):
            if np.array([q[3], q[4]]) @ h < 0:
                continue                # traffic leaves the box here
        else:
            # a zebra half on the outgoing side of a median needs no stop line
            rq = np.array([-q[4], q[3]])
            c0 = 0.0 if q[8] > 0.3 else (q[7] - q[6]) / 2
            rg = np.array([-h[1], h[0]])
            if (c - np.array([q[0], q[2]]) - rq * c0) @ rg < -1.0 and q[8] > 0.3:
                continue
        if stree is None or not any(stops[int(j)].distance(g) < 8 for j in stree.query(g.buffer(8))):
            iss['stopline_missing'].append(dict(road=r['name'], **xz(c)))
    # --- 3. dashes
    di = [i for w in DASHES for i in by.get(w, [])]
    ax = {i: axis(polys[i]) for i in di}
    dtree = STRtree([polys[i] for i in di]) if di else None
    seen = set()
    for a_, i in enumerate(di):
        ca, ua, La, _, _ = ax[i]
        for j_ in dtree.query(polys[i].buffer(4)):
            j = di[int(j_)]
            if j <= i or (i, j) in seen or lvl[i] != lvl[j]:
                continue
            cb, ub, Lb, b0, b1 = ax[j]
            if abs(ua @ ub) < 0.85:
                continue
            lat = abs((cb - ca) @ np.array([-ua[1], ua[0]]))
            pa, pb = sorted(((b0 - ca) @ ua, (b1 - ca) @ ua))
            ov = min(La / 2, pb) - max(-La / 2, pa)
            if lat < 4.0 and ov > 1.0 and polys[i].distance(polys[j]) < 4.0:
                seen.add((i, j))
                iss['dash_side_by_side'].append(dict(what=W[i], road=items[i].get('r'), lat=round(float(lat), 2), **xz(ca)))
    ends = []
    for i in di:
        c, u, L, a, b = ax[i]
        ends.append((a, -u, i))
        ends.append((b, u, i))
    if ends:
        ek = cKDTree([e[0] for e in ends])
        for e, uo, i in ends:
            best = None
            for k in ek.query_ball_point(e, 26.0):
                f, uf, j = ends[k]
                if j == i or lvl[i] != lvl[j]:
                    continue
                v = f - e
                along = v @ uo
                if not (10.0 <= along <= 26.0) or abs(uo @ uf) < 0.9:
                    continue
                m = uo - uf
                m = m / max(np.linalg.norm(m), 1e-9)
                lat = abs(v[0] * m[1] - v[1] * m[0])
                if lat < 4.0 and (best is None or lat < best[0]):
                    best = (lat, j)
            if best and best[0] > JOG and best[1] > i:
                iss['dash_jog'].append(dict(what=W[i], road=items[i].get('r'), lat=round(float(best[0]), 2), **xz(e)))
    # --- 4. median / island / nose
    med = []
    for r in roads:
        if any(q[8] > 0 for q in r['s']):
            med.extend(quads(r['s'], cutd.get(r['name'], ()), inner=8))
    med.extend(nose_caps(data))
    for isl in data.get('islands', []):
        if len(isl) >= 3:
            med.append(Polygon([(p[0], p[2]) for p in isl]).buffer(0))
    mtree = STRtree(med)
    for i, P in enumerate(polys):
        if items[i].get('deck'):
            continue
        hit = [med[int(j)] for j in mtree.query(P)]
        if hit and P.intersection(unary_union(hit)).area > 0.05:
            iss['paint_in_median'].append(dict(what=W[i], road=items[i].get('r'), **xz(P.centroid.coords[0])))
    # --- 5. double junctions and boxes
    for a, b in double_pairs(raw, R):
        hull = unary_union([raw[a][0], raw[b][0]]).convex_hull.buffer(-0.5)
        for i in near(hull, 0.0, ('zebra', 'stop')):
            if polys[i].intersection(hull).area > 0.2:
                iss['double_box'].append(dict(what=W[i], road=items[i].get('r'), **xz(polys[i].centroid.coords[0])))
    inner = rawU.buffer(-0.5)
    for i in near(inner, 0.0, LINES + ('zebra', 'stop')):
        if not items[i].get('deck') and polys[i].intersection(inner).area > 0.2:
            iss['box_paint'].append(dict(what=W[i], road=items[i].get('r'), **xz(polys[i].centroid.coords[0])))
    # --- 6. snakes
    for w in LINES:
        for i in by.get(w, []):
            for sd in turns(polys[i]):
                side = [x for x, _ in sd]
                bad = [k for k in range(len(side)) if abs(side[k]) > 15] or [
                    k + 1 for k in range(len(side) - 2)
                    if side[k] * side[k + 1] < 0 and side[k + 1] * side[k + 2] < 0 and min(abs(side[k]), abs(side[k + 1]), abs(side[k + 2])) > 3]
                if bad:
                    iss['paint_snake'].append(dict(what=w, road=items[i].get('r'), **xz(sd[bad[0]][1])))
                    break
    # --- 7. yellow kerb lines on main roads
    yl = [polys[i] for i in by.get('edge', []) + by.get('median', [])]
    ytree = STRtree(yl) if yl else None
    zs_ = [polys[i] for w in ('zebra', 'stop', 'giveway') for i in by.get(w, [])]
    ztree = STRtree(zs_) if zs_ else None
    fills = unary_union([Polygon([(p[0], p[2]) for p in f]).buffer(0) for f in data.get('fills', []) if len(f) >= 3])
    skipU = unary_union([unary_union(merged_boxes(raw, R)[0]).buffer(4) if raw else Polygon(), rings, fills.buffer(2)])
    skip_t = STRtree(list(skipU.geoms) if hasattr(skipU, 'geoms') else [skipU])
    skip_g = list(skipU.geoms) if hasattr(skipU, 'geoms') else [skipU]

    def has(tr, gs, p, d):
        return tr is not None and any(gs[int(j)].distance(p) <= d for j in tr.query(p.buffer(d)))
    for r in main_:
        s = r['s']
        c = cutd.get(r['name'], set())
        one = bool(r.get('oneway'))
        kerbs = []
        for i in range(0, len(s)):
            if i in c:
                continue
            q = s[i]
            ks = [(-q[6], -1), (q[7], 1)]
            if q[8] > 0.3 and not one:
                ks += [(-q[8], 1), (q[8], -1)]     # median kerbs: line on the carriageway side
            kerbs.append((i, ks))
        for slot in range(4):
            miss = []
            for i, ks in kerbs:
                if slot >= len(ks):
                    miss.append(False)
                    continue
                q = s[i]
                off, sg = ks[slot]
                rq = np.array([-q[4], q[3]])
                base = np.array([q[0], q[2]])
                p = Point(base + rq * (off - sg * 0.9))
                outside = Point(base + rq * (off + sg * 2.0))
                if slot >= 2 and (i == 0 or i == len(s) - 1 or s[i - 1][8] <= 0.3 or s[i + 1][8] <= 0.3):
                    miss.append(False)          # median nose: the line stops short of it
                    continue
                if slot < 2 and any(o != r['name'] for o in (roads[int(j)]['name'] for j in tree.query(outside)
                                                             if cw[roads[int(j)]['name']].contains(outside))):
                    miss.append(False)          # no kerb: another road joins here
                    continue
                if has(skip_t, skip_g, p, 0.0) or has(ztree, zs_, p, 6.0) or rings.contains(outside):
                    miss.append(False)
                    continue
                miss.append(not has(ytree, yl, p, 0.6))
            for a, b in runs(miss):
                if b - a >= 2:
                    i0 = kerbs[a][0]
                    iss['edge_missing'].append(dict(road=r['name'], side=slot, n=b - a + 1, **xz((s[i0][0], s[i0][2]))))
    # --- 8 / 9. zebras
    for i in zeb:
        it = items[i]
        if it['k'] != 'LZ':
            iss['zebra_colour'].append(dict(road=it.get('r'), **xz(polys[i].centroid.coords[0])))
        P = polys[i]
        why = None
        if [j for j in near(P, 0.15, deck=lvl[i]) if j != i]:
            why = 'touched by paint'
        elif P.area / max(P.minimum_rotated_rectangle.area, 1e-9) < 0.97:
            why = 'not a rectangle'
        if why:
            iss['zebra_torn'].append(dict(why=why, road=it.get('r'), **xz(P.centroid.coords[0])))
    out = os.path.join(D, 'qa_paint_J15.json')
    json.dump(iss, open(out, 'w'), indent=1)
    print(json.dumps({k: len(v) for k, v in iss.items()}))
    from collections import Counter
    for k in ('stopline_wrong_side', 'zebra_torn'):
        print(k, dict(Counter(x['why'] for x in iss[k])))
    return iss


if __name__ == '__main__':
    main()
