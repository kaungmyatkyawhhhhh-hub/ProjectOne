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
  deck_foot     a deck end not on its road's height (more than 0.3 studs off; a joint with another deck's end is not a foot)
  deck_clear    (J16) a deck under 4.5 m over a railway (OSM railway=rail) or 3 m over water, away from its feet
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
  dual_dead_end (J25, owner paint 'median road dead end') a divided road (a built median within 60 studs of the end) ending
                on nothing (a dead_end row) where OSM goes on: a kept OSM way within the road's width of the end reaches
                30+ studs past it. Ends outside or within EDGE_NEAR of the districts' outline are the map edge, not counted.
"""
import json, math, os, sys

import numpy as np
from scipy.spatial import cKDTree
from shapely.geometry import Polygon, Point, LineString
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo

OLD = '--old' in sys.argv          # the first (approximate) mouth_* / kerb_cross rules
PAINT_ONLY = '--paint-only' in sys.argv


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


AT_GRADE = 3.0  # (J16) a deck surface this close to a ground sample's height is at grade there (a deck foot)


def deck_segs(data):
    """(J16) every deck segment's carriageway quad, its mean height, deck, road, median: (STRtree, [(Polygon, y, deck
    name, road name, median half)])"""
    segs = []
    for d in data['decks']:
        s = d['s']
        for a, b in zip(s, s[1:]):
            ra, rb = np.array([-a[4], a[3]]), np.array([-b[4], b[3]])
            pa, pb = np.array([a[0], a[2]]), np.array([b[0], b[2]])
            P = Polygon([pa - ra * a[6], pa + ra * a[7], pb + rb * b[7], pb - rb * b[6]])
            if P.is_valid and P.area > 0.01:
                segs.append((P, (a[1] + b[1]) / 2, d['name'], d['of'], min(a[8], b[8])))
    return STRtree([x[0] for x in segs]), segs


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
    deck_names = {d['name'] for d in data['decks']}
    dtree, dsegs = deck_segs(data)
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
        # mouths: the end against the road it lands on (OLD approximation; roads05_kerbsim is the builder's own rule)
        ends = []
        for k in ((0, -1) if OLD else ()):
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
        for side, wk in (((-1, r.get('walkL') or walk), (1, r.get('walkR') or walk)) if OLD else ()):
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
                    if o in deck_names:
                        continue  # (J16) a deck: only where it is at grade (below); a median under a deck is fine
                    if o != n and geoms[int(j)].distance(p) < 0.5:
                        hit = o
                        break
                if hit is None:
                    for j in dtree.query(p.buffer(0.5)):
                        g, y, o, of, md = dsegs[int(j)]
                        if abs(y - s[i][1]) < AT_GRADE and g.distance(p) < 0.5 and not (of == n and md > 0):
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


def cont_pairs(data):
    """(J19) continuation joints: (road, host, joint sample, same direction?) for startsOnEnd / endsOnEnd within 3 studs"""
    byname = {r['name']: r for r in data['roads']}
    best = {}
    for r in data['roads']:
        for f, k in (('startsOnEnd', 0), ('endsOnEnd', -1)):
            h = byname.get(r.get(f)) if isinstance(r.get(f), str) else None
            if not h:
                continue
            q = r['s'][k]
            ke = min((0, -1), key=lambda j: (h['s'][j][0] - q[0]) ** 2 + (h['s'][j][2] - q[2]) ** 2)
            e = h['s'][ke]
            if math.hypot(e[0] - q[0], e[2] - q[2]) <= 3:
                same = ke != k  # start on the host's end (or end on its start) runs the same way
                # (a fork: several records on one host end: only the one running on most straight carries its pavement;
                # J20: a tie (Kun Chan Road #3 and Lane #3414 leave in one direction) goes to the wider record)
                al = (round(abs(q[3] * e[3] + q[4] * e[4]), 2), q[6] + q[7])
                if al > best.get((h['name'], ke), ((-1, 0),))[0]:
                    best[(h['name'], ke)] = (al, r, h, q, e, same)
    for v in best.values():
        yield v[1:]


def folds(s):
    """(J18, paint agent's roads05_paint.folds) samples where a road's centre line steps back: a chord against the
    sample's own direction, or two chords turning more than ~107 degrees"""
    out = []
    for i in range(1, len(s)):
        ax, az = s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2]
        L = math.hypot(ax, az)
        if L < 1e-6:
            continue
        if ax * s[i][3] + az * s[i][4] < -0.3 * L:
            out.append(i)
        elif i + 1 < len(s):
            bx, bz = s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]
            if ax * bx + az * bz < -0.3 * L * math.hypot(bx, bz):
                out.append(i)
    return out


def osm_mark(issues):
    """(J13) each mouth_short / mouth_over row against OSM: `osm` = "dead end" (the nearest OSM way end, within 3
    studs, is shared by no other way that roads05 builds: a real dead end, explained, not a fault; a join only to a
    driveway / private / footway way is a dead end on our map), "join" (OSM joins it: a fault) or
    "off" (no OSM way end there: a fault to look at). Counts in issues['real'] leave the dead ends out."""
    from scipy.spatial import cKDTree
    import roads05
    ways = [w for w in geo.load('roads') if roads05.keep_way(w, set())]  # the ways roads05 builds
    use = {}
    for w in ways:
        for p in w['p']:
            use.setdefault((round(p[0], 7), round(p[1], 7)), set()).add(w['id'])
    ends, joins = [], []
    for w in ways:
        for p in (w['p'][0], w['p'][-1]):
            ends.append(geo.world(p[0], p[1]))
            joins.append(len(use[(round(p[0], 7), round(p[1], 7))]) - 1)
    T = cKDTree(ends)
    real = {}
    for k in ('mouth_short', 'mouth_over'):
        for row in issues[k]:
            d, j = T.query((row['x'], row['z']))
            row['osm'] = 'off' if d > 3 else ('dead end' if joins[j] == 0 else 'join')
        real[k] = sum(1 for row in issues[k] if row['osm'] != 'dead end')
        real[k + '_osm_dead_end'] = len(issues[k]) - real[k]
    issues['real'] = [real]


EDGE_NEAR = 12.0   # (J25) a road end this close to the districts' outline is the map edge (fix trims ends a few studs)


def dual_dead_end(data, issues, tree=None, geoms=None, names=None, rings=()):
    """(J25) dead_end rows of divided roads where OSM goes on (see the header)"""
    import roads05
    reg = roads05.region_of(data['tags']) if data.get('tags') else None
    region = reg.boundary if reg is not None else None
    ways = [LineString([geo.world(*p) for p in w['p']]) for w in geo.load('roads') if roads05.keep_way(w, set())]
    wt = STRtree(ways)
    by = {r['name']: r for r in data['roads']}
    for x in issues['dead_end']:
        r = by[x['road']]
        s = r['s'] if x['end'] == 'end' else r['s'][::-1]
        e = s[-1]
        L, i = 0.0, len(s) - 1
        med = False
        while i > 0 and L < 60:
            med = med or s[i][8] > 0.3
            L += math.hypot(s[i][0] - s[i - 1][0], s[i][2] - s[i - 1][2])
            i -= 1
        if not med:
            continue
        p = Point(e[0], e[2])
        if region is not None and (region.distance(p) < EDGE_NEAR or not reg.contains(p)):
            continue
        # the end's whole cross-section (left kerb .. right kerb) on another road / deck / ring: a split or merge, not an end
        xs = LineString([(e[0] + e[4] * e[6], e[2] - e[3] * e[6]), (e[0] - e[4] * e[7], e[2] + e[3] * e[7])])
        if tree is not None and (any(names[int(j)] != r['name'] and geoms[int(j)].distance(xs) < 3 for j in tree.query(xs.buffer(3)))
                                 or any(g.distance(xs) < 3 for g in rings)):
            continue
        u = np.array([e[0] - s[i][0], e[2] - s[i][2]])
        u /= max(np.linalg.norm(u), 1e-9)
        w = e[6] + e[7]
        beyond = max([float((np.array(c) - (e[0], e[2])) @ u) for j in wt.query(p.buffer(w)) if ways[int(j)].distance(p) < w
                      for c in ways[int(j)].coords] or [0.0])
        if beyond >= 30:
            issues['dual_dead_end'].append(dict(road=r['name'], end=x['end'], osm_beyond=round(beyond), x=x['x'], z=x['z']))


def main():
    av = [a for a in sys.argv[1:] if not a.startswith('--')]
    tag = av[0]
    D = os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + tag)
    data = json.load(open(av[1] if len(av) > 1 else os.path.join(D, 'roads.json'), encoding='utf-8'))
    paint = json.load(open(av[2] if len(av) > 2 else os.path.join(D, 'paint.json')))['items']
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
                              'mouth_short', 'mouth_over', 'mouth_edge', 'kerb_cross', 'median_cross', 'zero_width', 'overlap', 'rank_dup', 'dropped', 'real', 'stub_in_grass', 'street_no_pave', 'carriageway_too_narrow', 'paint_off_centre', 'unmarked_strip', 'width_wobble', 'deck_wobble', 'seam_step', 'median_broken', 'signals', 'deck_clear', 'centre_fold', 'pave_width_jump', 'pave_step', 'dual_dead_end')}
    if not PAINT_ONLY:
        junction_checks(data, cutd, cw, names, geoms, tree, rings, issues)
        if not OLD:
            import roads05_kerbsim
            ks = roads05_kerbsim.run(data)
            for k in ('kerb_cross', 'mouth_short', 'mouth_over', 'mouth_edge'):
                issues[k] = ks[k]
            issues['dropped'] = ks['dropped']
            osm_mark(issues)
    # (J18) centre lines that fold back on themselves (paint leaves them bare)
    for r in (data['roads'] if not PAINT_ONLY else ()):
        for i in folds(r['s']):
            issues['centre_fold'].append(dict(road=r['name'], i=i, x=round(r['s'][i][0], 1), z=round(r['s'][i][2], 1)))
    # dead ends
    for r in (data['roads'] if not PAINT_ONLY else ()):
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
    # (J13, owner refs 18 Nov) stub_in_grass: a road under STUB studs long with an end on nothing (a dead end listed
    # above); street_no_pave: a street / route with no pavement on a side (walkL / walkR 0)
    STUB = 30.0
    de = {(x['road'], x['end']) for x in issues['dead_end']}
    for r in (data['roads'] if not PAINT_ONLY else ()):
        s = r['s']
        L = sum(np.hypot(s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]) for i in range(len(s) - 1))
        if L < STUB and ((r['name'], 'start') in de or (r['name'], 'end') in de):
            issues['stub_in_grass'].append(dict(road=r['name'], length=round(float(L), 1), x=round(s[0][0], 1), z=round(s[0][2], 1)))
        if r['kind'] in ('street', 'route') and not ((r.get('walkL') or 0) > 0 and (r.get('walkR') or 0) > 0):
            issues['street_no_pave'].append(dict(road=r['name'], walkL=r.get('walkL'), walkR=r.get('walkR'), x=round(s[0][0], 1), z=round(s[0][2], 1)))
    # (J14, owner ref `lane with no carriageway`) every road has at least one car lane of asphalt: 10.5 studs one-way,
    # 16.5 two-way (a divided road: each carriageway 10.5); the 40-stud taper at each end and cut samples are left out
    for r in (data['roads'] if not PAINT_ONLY else ()):
        s, cut = r['s'], cutd.get(r['name'], set())
        c = np.r_[0, np.cumsum([np.hypot(s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]) for i in range(len(s) - 1)])]
        # a chain can hold one-way and two-way pieces: a sample is one-way when its lanes fill its whole width; the
        # taper between two pieces (any width change within 5 samples) is left out
        ow = [abs(q[6] + q[7] - q[9] * q[10]) < 0.5 for q in s]
        for i, q in enumerate(s):
            if i in cut or c[i] < 40 or c[-1] - c[i] < 40:
                continue
            win = s[max(0, i - 5):i + 6]
            if len(set(ow[max(0, i - 5):i + 6])) > 1 or max(x[6] + x[7] for x in win) - min(x[6] + x[7] for x in win) > 0.05:
                continue
            if q[8] > 0:
                w, need = min(q[6], q[7]) - q[8], 10.5
            else:
                w, need = q[6] + q[7], 10.5 if (r.get('oneway') or ow[i]) else 16.5
            if w < need - 0.05:
                issues['carriageway_too_narrow'].append(dict(road=r['name'], w=round(w, 2), need=need, x=round(q[0], 1), z=round(q[2], 1)))
                break
    # (J14, owner refs `road width jumps`, `wavy road edges`) width_wobble: a kerb's offset stepping faster than 0.2 per
    # stud along the road (a block change, not a taper); cut samples left out
    for r in (data['roads'] if not PAINT_ONLY else ()):
        s, cut = r['s'], cutd.get(r['name'], set())
        for i in range(len(s) - 1):
            if i in cut or i + 1 in cut:
                continue
            ds = max(np.hypot(s[i + 1][0] - s[i][0], s[i + 1][2] - s[i][2]), 0.5)
            dw = max(abs(s[i + 1][6] - s[i][6]), abs(s[i + 1][7] - s[i][7]))
            if dw > 0.3 and dw / ds > 0.2:
                issues['width_wobble'].append(dict(road=r['name'], dw=round(dw, 2), ds=round(ds, 2), x=round(s[i][0], 1), z=round(s[i][2], 1)))
                break
    # (J15) seam_step: a continuation (startsOnEnd / endsOnEnd) whose joint sample differs from its host's end sample
    # by more than 0.1 in height or 0.5 in a kerb offset (a step / notch where two records meet)
    byname = {r['name']: r for r in data['roads']}
    for r in (data['roads'] if not PAINT_ONLY else ()):
        for f, k in (('startsOnEnd', 0), ('endsOnEnd', -1)):
            h = byname.get(r.get(f)) if isinstance(r.get(f), str) else None
            if not h:
                continue
            q = r['s'][k]
            e = min((h['s'][0], h['s'][-1]), key=lambda x: (x[0] - q[0]) ** 2 + (x[2] - q[2]) ** 2)
            if math.hypot(e[0] - q[0], e[2] - q[2]) > 3:
                continue
            dy = abs(e[1] - q[1])
            if dy > 0.1:
                issues['seam_step'].append(dict(road=r['name'], host=h['name'], dy=round(dy, 2), x=round(q[0], 1), z=round(q[2], 1)))
    # (J19, owner "pavements not smoothly connected", Kun Chan x Gyophyu) pave_width_jump: a continuation joint whose
    # pavement (walkL / walkR, constant along a record) changes by more than 0.5 on a side: a step with no taper;
    # pave_step: the joint's pavement (on the kerb-line height) more than 0.1 off its host's
    for r, h, q, e, same in (cont_pairs(data) if not PAINT_ONLY else ()):
        for a, b in (('walkL', 'walkL'), ('walkR', 'walkR')) if same else (('walkL', 'walkR'), ('walkR', 'walkL')):
            wa, wb = r.get(a) or 7.5, h.get(b) or 7.5
            if abs(wa - wb) > 0.5:
                issues['pave_width_jump'].append(dict(road=r['name'], host=h['name'], side=a, w=wa, host_w=wb, x=round(q[0], 1), z=round(q[2], 1)))
        if abs(e[1] - q[1]) > 0.1:
            issues['pave_step'].append(dict(road=r['name'], host=h['name'], dy=round(abs(e[1] - q[1]), 2), x=round(q[0], 1), z=round(q[2], 1)))
    # (J15) median_broken: a divided road's median gone for 1-3 samples between two median runs, away from any
    # cut / other road's carriageway (the medians step clears 6 studs before a junction: those gaps are real)
    for r in (data['roads'] if not PAINT_ONLY else ()):
        s, cut = r['s'], cutd.get(r['name'], set())
        on = [q[8] > 0.15 for q in s]
        i = 1
        while i < len(s) - 1:
            if on[i - 1] and not on[i]:
                j = i
                while j < len(s) and not on[j]:
                    j += 1
                if j < len(s) and j - i <= 3 and not any(x in cut for x in range(i - 1, j + 1)):
                    p = Point(s[i][0], s[i][2])
                    if not any(names[int(k)] != r['name'] and geoms[int(k)].distance(p) < 8 for k in tree.query(p.buffer(8))):
                        issues['median_broken'].append(dict(road=r['name'], gap=j - i, x=round(s[i][0], 1), z=round(s[i][2], 1)))
                i = j
            i += 1
    # (J15) signals: the signalled junctions in data.junctions (a count, not a fault)
    issues['signals'] = [dict(x=j['x'], z=j['z'], arms=len(j['arms'])) for j in data.get('junctions', [])]
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
    # (J14, owner shot: centre line far right, bare left half) paint_off_centre: a centre line more than 1 stud off its
    # undivided two-way road's carriageway middle; unmarked_strip: a lane strip (kerb or line to the next line) wider
    # than one lane + 1 with no line, on a marked road (a 1-lane-a-side road's halves, a one-way's lanes)
    rby = {r['name']: r for r in data['roads']}
    lines_by = {}
    for it, P in zip(paint, polys):
        if it.get('w') in ('centre', 'lane') and it.get('r') in rby:
            lines_by.setdefault(it['r'], []).append((it['w'], P.representative_point()))  # (a curved line's centroid is off it)
    for name, L in lines_by.items():
        r = rby[name]
        S = np.array([[q[0], q[2]] for q in r['s']])
        kd = cKDTree(S)
        bad_c = bad_u = None
        for w, c in L:
            i = int(kd.query([c.x, c.y])[1])
            q = r['s'][i]
            off = (c.x - q[0]) * -q[4] + (c.y - q[2]) * q[3]
            if w == 'centre' and q[8] <= 0.3 and abs(off - (q[7] - q[6]) / 2) > 1.0 and bad_c is None:
                bad_c = dict(road=name, off=round(off, 2), mid=round((q[7] - q[6]) / 2, 2), x=round(c.x, 1), z=round(c.y, 1))
        # strips: the paint rule's lanes (roads05_paint.neff) at every 4th sample; a strip over 1.5 lanes is unmarked
        from roads05_paint import neff
        for q in r['s'][::4]:
            if q[8] > 0.3 or q[9] < 1:
                continue
            one = bool(r.get('oneway'))
            span = (q[6] + q[7]) if one else ((q[6] + q[7]) / 2 - q[11])
            strip = span / neff(q, one)
            if strip > 18.0 and bad_u is None:
                bad_u = dict(road=name, strip=round(strip, 2), x=round(q[0], 1), z=round(q[2], 1))
        if bad_c:
            issues['paint_off_centre'].append(bad_c)
        if bad_u:
            issues['unmarked_strip'].append(bad_u)
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
    # (J14, owner: decks "zigzag") deck_wobble: a deck's lateral offset from the chord of its neighbours 4 samples each
    # way over 0.2 studs (on a curve the chord offset is smooth: a jump between neighbours' offsets over 0.2), or a
    # vertical second difference over 0.15
    for d in data['decks']:
        s = np.array(d['s'])
        bad = None
        for i in range(8, len(s) - 8):
            offs = []
            for j in (i - 1, i, i + 1):
                a, b, p = s[j - 4][[0, 2]], s[j + 4][[0, 2]], s[j][[0, 2]]
                t = b - a
                offs.append(((p - a)[0] * t[1] - (p - a)[1] * t[0]) / (np.linalg.norm(t) or 1))
            lat = abs(offs[1] - (offs[0] + offs[2]) / 2)
            ver = abs(s[i - 1][1] - 2 * s[i][1] + s[i + 1][1])
            if lat > 0.2 or ver > 0.15:
                bad = dict(deck=d['name'], lat=round(float(lat), 3), ver=round(float(ver), 3), x=round(s[i][0], 1), z=round(s[i][2], 1))
                break
        if bad:
            issues['deck_wobble'].append(bad)
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
                # (J16) a joint with another deck's end (one bridge in named pieces) is not a foot
                joint = any(o is not d and any(math.hypot(o['s'][kk][0] - s[k][0], o['s'][kk][2] - s[k][2]) < max(6.0, s[k][6] + s[k][7])
                                               and abs(o['s'][kk][1] - s[k][1]) < 0.3 for kk in (0, -1)) for o in data['decks'] if len(o['s']) > 1)
                if dy > 0.3 and not joint:
                    issues['deck_foot'].append(dict(deck=d['name'], dy=round(float(dy), 2), x=round(s[k][0], 1), z=round(s[k][2], 1)))
    # (J16) deck_clear: a deck under CLEAR_RAIL (4.5 m) over a railway or CLEAR_WATER (3 m) over water, away from its
    # feet (the abutments stand on the banks): heights against its road's own ground samples
    if not PAINT_ONLY:
        from roads05_fix import _rail_water, DECK_FLAT
        from shapely.geometry import LineString as _LS, Point as _Pt
        rwt, rw = _rail_water()
        for d in data['decks']:
            r = roadby.get(d['of'])
            if not r or len(d['s']) < 3:
                continue
            s = d['s']
            c = np.r_[0, np.cumsum([math.hypot(b[0] - a[0], b[2] - a[2]) for a, b in zip(s, s[1:])])]
            gnd = [r['s'][min(len(r['s']) - 1, d['from'] + j)][1] for j in range(len(s))]
            DL = _LS([(q[0], q[2]) for q in s])
            worst = None
            for k in rwt.query(DL):
                G, clr = rw[int(k)]
                if not DL.intersects(G):
                    continue
                if G.geom_type == 'Polygon':
                    from roads05_fix import water_cc
                    ccs = water_cc(G, s, c)  # (J20) the channel middle of each run over it (as deck_regrade)
                else:
                    X = DL.intersection(G)
                    ccs = [DL.project(P) for P in (list(X.geoms) if hasattr(X, 'geoms') else [X]) if P.geom_type == 'Point']
                for cc in ccs:
                    if DECK_FLAT + 10 <= cc <= c[-1] - DECK_FLAT - 10:
                        m = float(np.interp(cc, c, [q[1] for q in s])) - float(np.interp(cc, c, gnd)) - clr
                        if m < -0.05 and (worst is None or m < worst[0]):
                            worst = (m, cc, 'rail' if clr > 10 else 'water')
            if worst:
                P = DL.interpolate(worst[1])
                issues['deck_clear'].append(dict(deck=d['name'], over=worst[2], short_by=round(-worst[0], 1), x=round(P.x, 1), z=round(P.y, 1)))
    if not PAINT_ONLY:
        dual_dead_end(data, issues, tree, geoms, names, rings)
    json.dump(issues, open(os.path.join(D, 'qa_paint.json' if PAINT_ONLY else 'qa.json'), 'w'), indent=1)
    print(json.dumps({k: len(v) for k, v in issues.items() if k != 'real'}))
    if issues.get('real'):
        print('real faults (OSM dead ends left out):', json.dumps(issues['real'][0]))
    return issues


if __name__ == '__main__':
    main()
