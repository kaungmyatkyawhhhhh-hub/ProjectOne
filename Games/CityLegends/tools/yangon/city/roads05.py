"""1:1 districts' roads the batch 0.5 way (16 Nov 2026, owner: "the old road system was better ... batch 0.5 roads",
"friday roads were good but it wasnt accurate ... roundabouts are not roundabouts", "fix ALL THE ROADS to the good ones").

Turns the real OSM network of one or more 1:1 districts (geo.PILOT_LL tags) into road data for the PROVEN part builder
(tools/riviera/Roads.luau + RoadLines.luau driven by tools/yangon/YangonRoads.luau), in the ygn_roads_v5.json format,
with the simplicity of batch 0.5:
  * ONE centre line per road. A dual carriageway (two one-way OSM ways of one name and class, partner on the left,
    PAIR_MIN..PAIR_MAX apart) becomes one road on their midline with the real total width and the median inside the
    record (s[8] built median half, Roads.luau / YangonRoads.buildMedians). Never two roads + islands.
  * slip roads (*_link) are kept as one-way roads (owner 17 Nov: OSM is the truth); no PAVED_WAYS, no traffic islands.
  * a pair is merged only where its outer edges stay within MERGE_TOL of both OSM lines; flares stay two roads.
  * junctions only by rank: the LOWER rank is the bigger road, no ties; a road that ends inside another's carriageway is
    always the smaller one (Kahn order over the "ends on" relation, then class / lanes / length).
  * every real roundabout (junction=roundabout / circular) is a roundabout record (centre, ring radius from a circle fit,
    lanes from the tags, island), never a junction; its arms end in the ring.
  * a flyover (a raised OSM bridge in the district's road profile) is one deck (data.decks) continuing its road over a cut
    run, with the ground lanes beside it as Friday's `side` roads that start and end on the road's cut ends.
  * widths 1:1 (roadnet.cross_section_1to1: real lane counts, lanes 12 studs where they fit, never under 10), pavements
    2.5 m on main roads, 1.33 m on streets.
  * heights from the district's own road profile (roads_<tag>_profile.json, the proven 1:1 height design the terrain beds
    were cut for), the smaller road pinned to the bigger one where it meets it.

    YANGON_SCALE=1to1 python roads05.py P1 [P2 ...]
-> build/city_1to1/roads05_<tags>/roads.json (+ Roads3_<k>.luau modules for YangonData, stats.json). The tags are built as
ONE network (so the seams between districts match); Studio builds it cell by cell (YangonRoads05.luau).
Data: OpenStreetMap contributors (ODbL).
"""
import collections, heapq, json, math, os, sys

import numpy as np
from scipy.spatial import cKDTree
from shapely.geometry import LineString, Point, Polygon, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

sys.stdout.reconfigure(encoding='utf-8')
import geo
import roadnet as RN

assert geo.ONE_TO_ONE, 'run with YANGON_SCALE=1to1'

STEP = 8.0            # studs between samples
PAIR_MIN = geo.m(3.0)
PAIR_MAX = geo.m(26.0)  # Pyay Road along Inya Lake: 23.8 m between its OSM lines
TAIL = geo.m(45.0)    # a one-way remnant shorter than this at the end of a paired run is folded into the midline
JOIN = geo.m(12.0)    # ends of one road (same name) this close are one road
MERGE_TOL = geo.m(2.0)  # a merged dual carriageway reproduces both OSM lines' outer edges within this (owner 17 Nov)
MED_MIN = 1.5         # a 1 m barrier between kerbs (kerbs included: half 1.5 studs)
OPEN_R = 24.0         # a median opens where another main road's carriageway comes this near
MED_CUT = geo.m(1.0)  # a median half under this (a full median under 2 m) is no median, except a run's 1 m barrier
MIN_MEDIAN = geo.m(25.0)
RING_LANE_W = 12.0
EASE_W = 120.0         # width changes eased over this
PIN_EASE = 60.0       # a pinned junction height is eased out over this
WALK = dict(main=7.5, street=4.0, narrow=3.0)
DECK_LANE_W = 12.0
SIDE_INNER_WALK = 1.0  # a side lane's walk on the deck side
CHUNK = 185000
RANK_CLASS = dict(RN.RANK)


def out_dir(tags):
    return os.path.join(geo.BUILD, 'city_1to1', 'roads05_' + '_'.join(tags))


# ------------------------------------------------------------------------------------------------ helpers
def chain(P):
    return np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]


def resample(P, step):
    c = chain(P)
    L = c[-1]
    n = max(1, int(math.ceil(L / step)))
    t = np.linspace(0, L, n + 1)
    return np.stack([np.interp(t, c, P[:, 0]), np.interp(t, c, P[:, 1])], axis=1), t, c


def dirs(P):
    d = np.zeros_like(P)
    if len(P) < 2:
        d[:, 0] = 1
        return d
    d[1:-1] = P[2:] - P[:-2]
    d[0] = P[1] - P[0]
    d[-1] = P[-1] - P[-2]
    L = np.linalg.norm(d, axis=1)
    L[L < 1e-9] = 1
    return d / L[:, None]


def rights(D):
    return np.stack([-D[:, 1], D[:, 0]], axis=1)


def smooth_line(P, win):
    """moving average of a polyline resampled at 2 studs, ends fixed"""
    if len(P) < 3:
        return P
    Q, _, _ = resample(P, 2.0)
    k = int(win // 2)
    if len(Q) < 2 * k + 3 or k < 1:
        return Q
    S = Q.copy()
    for c in (0, 1):
        pad = np.r_[np.full(k, Q[0, c]) * 0 + 2 * Q[0, c] - Q[k:0:-1, c], Q[:, c], 2 * Q[-1, c] - Q[-2:-k - 2:-1, c]]
        S[:, c] = np.convolve(pad, np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
    S[0], S[-1] = Q[0], Q[-1]
    return S


def norm(s):
    s = (s or '').lower()
    for w in ('(bridge)', 'bridge', 'flyover'):
        s = s.replace(w, ' ')
    return RN.norm_name(s)


def key_of(p):
    return RN._node_key(p)


# ------------------------------------------------------------------------------------------------ 1. ways
def region_of(tags):
    return unary_union([geo.batch_poly(t) for t in tags])


TRACK_PAVED = {'asphalt', 'concrete', 'paved', 'paving_stones', 'sett', 'concrete:plates', 'concrete:lanes'}
DRIVE_LINK_MIN = 180.0   # (J14) a driveway is kept when it is over ~60 m and links two kept roads (load())


def keep_way(r, paved):
    """(J14, owner: "every way a car can drive") residential / unclassified / living_street / public classes, every
    service way but parking aisles and drive-throughs (driveways: load() keeps the long ones linking two roads), tracks
    only where paved. Private / access=no compound and campus roads count (a paved car road; owner draws them as
    missing); motor_vehicle=no does not.
    shortcut: a track's paving is read from its surface tag, not the satellite; untagged tracks stay out."""
    t = r['t']
    hw = t.get('highway')
    if r['id'] in paved or t.get('area') == 'yes' or len(r['p']) < 2:
        return False
    if t.get('motor_vehicle') == 'no':
        return False
    if hw in RN.LINKS:  # owner 17 Nov: OSM's slip roads are real (University Ave x Kabar Aye): one-way roads of their own
        return True
    if hw == 'service':
        return t.get('service') not in ('driveway', 'parking_aisle', 'drive-through')
    if hw == 'track':
        return t.get('surface') in TRACK_PAVED
    return hw in RN.PUBLIC


def drive_link(r, nodes):
    """a long driveway whose both ends sit on kept roads' nodes"""
    t = r['t']
    if t.get('highway') != 'service' or t.get('service') != 'driveway' or t.get('access') == 'no' or len(r['p']) < 2:
        return False
    if key_of(r['p'][0]) not in nodes or key_of(r['p'][-1]) not in nodes:
        return False
    return LineString(geo.proj(r['p'])).length >= DRIVE_LINK_MIN


class Edge:
    pass


def load(tags):
    region = region_of(tags)
    lon0, lat0 = geo.lonlat(region.bounds[0] - 50, region.bounds[3] + 50)
    lon1, lat1 = geo.lonlat(region.bounds[2] + 50, region.bounds[1] - 50)
    paved = set()
    for t in tags:
        paved |= set(RN.PAVED_WAYS.get(t, ()))
    ways = []
    for r in geo.load('roads'):
        if not keep_way(r, paved):
            continue
        xs = [q[0] for q in r['p']]
        ys = [q[1] for q in r['p']]
        if max(xs) < lon0 or min(xs) > lon1 or max(ys) < lat0 or min(ys) > lat1:
            continue
        ways.append(r)
    nodes = {key_of(q) for r in ways for q in r['p']}
    ways += [r for r in geo.load('roads') if r['id'] not in paved and drive_link(r, nodes)]
    count = collections.Counter()
    for r in ways:
        for i, q in enumerate(r['p']):
            count[key_of(q)] += 2 if i in (0, len(r['p']) - 1) else 1
    edges = []
    nedge = 0
    for r in ways:
        t = r['t']
        p = r['p']
        cs = RN.cross_section_1to1(t)
        if cs['oneway'] == -1:
            p = p[::-1]
            cs['oneway'] = 1
        cuts = [0] + [i for i in range(1, len(p) - 1) if count[key_of(p[i])] >= 2] + [len(p) - 1]
        for a, b in zip(cuts, cuts[1:]):
            seg = p[a:b + 1]
            W = np.array(geo.proj(seg))
            ls = LineString(W)
            if ls.length < 0.3:
                continue
            ka, kb = key_of(seg[0]), key_of(seg[-1])
            if region.contains(ls):
                pieces = [(W, ka, kb)]
            else:
                g = ls.intersection(region)
                if g.is_empty:
                    continue
                parts = [g] if g.geom_type == 'LineString' else [x for x in getattr(g, 'geoms', []) if x.geom_type == 'LineString']
                pieces = []
                for x in parts:
                    Q = np.array(x.coords)
                    if len(Q) < 2 or x.length < 1.0:
                        continue
                    k0 = ka if np.linalg.norm(Q[0] - W[0]) < 0.05 else ('edge', nedge, 0)
                    k1 = kb if np.linalg.norm(Q[-1] - W[-1]) < 0.05 else ('edge', nedge, 1)
                    nedge += 1
                    pieces.append((Q, k0, k1))
            for Q, k0, k1 in pieces:
                e = Edge()
                e.wid, e.t, e.hw = r['id'], t, t.get('highway')
                e.name = t.get('name:en') or t.get('name') or ''
                e.nn = norm(e.name)
                e.cs = cs
                e.oneway = cs['oneway']
                e.bridge = t.get('bridge') not in (None, 'no')
                e.ring = t.get('junction') in ('roundabout', 'circular')
                e.P = Q
                e.a, e.b = k0, k1
                edges.append(e)
    for i, e in enumerate(edges):
        e.id = i
    return region, edges


# ------------------------------------------------------------------------------------------------ 2. roundabouts
def circle_fit(P):
    x, y = P[:, 0], P[:, 1]
    A = np.c_[2 * x, 2 * y, np.ones(len(x))]
    b = x * x + y * y
    (cx, cy, c), *_ = np.linalg.lstsq(A, b, rcond=None)
    return np.array([cx, cy]), math.sqrt(max(c + cx * cx + cy * cy, 1.0))


def roundabouts(edges, region):
    ring = [e for e in edges if e.ring]
    parent = {}

    def find(k):
        while parent.setdefault(k, k) != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k
    for e in ring:
        parent[find(e.a)] = find(e.b)
    groups = collections.defaultdict(list)
    for e in ring:
        groups[find(e.a)].append(e)
    out = []
    for g in groups.values():
        P = np.vstack([e.P for e in g])
        c, rc = circle_fit(P)
        if not region.contains(Point(c)) or rc > 200:
            continue
        lanes = 0
        for e in g:
            n = RN._num(e.t, 'lanes')
            if n:
                lanes = max(lanes, int(round(n)))
        big = any(e.hw in ('trunk', 'primary', 'motorway', 'secondary') for e in g)
        if not lanes:
            lanes = 2 if big else 1
        lanes = min(lanes, 3)
        half = lanes * RING_LANE_W / 2
        r_in = max(6.0, rc - half)
        r_out = r_in + lanes * RING_LANE_W
        keys = set()
        for e in g:
            keys |= {e.a, e.b}
        out.append(dict(c=c, rc=rc, r_in=r_in, r_out=r_out, lanes=lanes, laneW=RING_LANE_W, keys=keys, edges=[e.id for e in g],
                        big=big, cls=min(RANK_CLASS.get(e.hw, 6) for e in g)))
    return out


# ------------------------------------------------------------------------------------------------ 3. dual carriageways
class Piece:
    """a run of road with per-sample cross-section: P (N x 2), wl, wr (carriageway edges left / right of the line),
    med (lane geometry's median half), nl, nr (lanes left / right), W (lane width), plus the source edge per sample"""


def piece_from(P, nl, nr, Wl, Wr, med, name, hw, src, oneway, ends, bridge=False, tags=None):
    p = Piece()
    p.P = np.asarray(P, float)
    n = len(p.P)
    f = lambda v: np.broadcast_to(np.asarray(v, float), (n,)).copy()
    p.nl, p.nr = f(nl), f(nr)
    p.Wl, p.Wr = f(Wl), f(Wr)
    p.med = f(med)
    p.name, p.nn, p.hw = name, norm(name), hw
    p.src = list(src) if isinstance(src, (list, tuple)) else [src] * n
    p.oneway = oneway
    p.ends = list(ends)
    p.bridge = bridge
    p.tags = tags or {}
    return p


def strokes_oneway(edges, ring_keys):
    """directed chains of one-way main edges of one (name, class)"""
    cand = [e for e in edges if e.oneway and not e.ring and e.hw in RN.MAIN]
    by_start = collections.defaultdict(list)
    by_end = collections.defaultdict(list)
    for e in cand:
        by_start[(e.a, e.nn, e.hw)].append(e)
        by_end[(e.b, e.nn, e.hw)].append(e)
    nxt, prv = {}, {}
    for e in cand:
        if e.b in ring_keys:
            continue
        def straight(f, g):
            d1 = f.P[-1] - f.P[max(0, len(f.P) - 2)]
            d2 = g.P[min(1, len(g.P) - 1)] - g.P[0]
            n1, n2 = np.linalg.norm(d1), np.linalg.norm(d2)
            return n1 > 1e-9 and n2 > 1e-9 and float(d1 @ d2) / (n1 * n2) > 0.5
        outs = [f for f in by_start[(e.b, e.nn, e.hw)] if f is not e and straight(e, f)]
        ins = [f for f in by_end[(e.b, e.nn, e.hw)] if f is e or straight(f, outs[0] if outs else e)]
        if len(outs) == 1 and len(ins) == 1:
            nxt[e.id] = outs[0]
            prv[outs[0].id] = e
    seen = set()
    strokes = []
    for e in cand:
        if e.id in seen or e.id in prv:
            continue
        run = [e]
        seen.add(e.id)
        while run[-1].id in nxt and nxt[run[-1].id].id not in seen:
            f = nxt[run[-1].id]
            run.append(f)
            seen.add(f.id)
        strokes.append(run)
    for e in cand:          # closed chains
        if e.id not in seen:
            run = [e]
            seen.add(e.id)
            while run[-1].id in nxt and nxt[run[-1].id].id not in seen:
                f = nxt[run[-1].id]
                run.append(f)
                seen.add(f.id)
            strokes.append(run)
    out = []
    for i, run in enumerate(strokes):
        P = [run[0].P[0]]
        src = [run[0].id]
        for e in run:
            Q, _, _ = resample(e.P, 4.0)
            P.extend(Q[1:])
            src.extend([e.id] * (len(Q) - 1))
        S = dict(id=i, edges=run, P=np.array(P), src=src, nn=run[0].nn, hw=run[0].hw, name=run[0].name,
                 a=run[0].a, b=run[-1].b)
        S['c'] = chain(S['P'])
        S['D'] = dirs(S['P'])
        S['line'] = LineString(S['P'])
        out.append(S)
    return out


def pair(strokes, edges, bridge_lines):
    """paired runs: for each stroke S, against strokes T with a higher id (each pair once)"""
    btree = STRtree(bridge_lines) if bridge_lines else None
    runs = []
    for S in strokes:
        P, D = S['P'], S['D']
        n = len(P)
        best = [None] * n
        for T in strokes:
            if T['id'] <= S['id'] or T['nn'] != S['nn'] or T['hw'] != S['hw'] or not S['nn']:
                continue
            if S['line'].distance(T['line']) > PAIR_MAX:
                continue
            L = T['line']
            sb = any(edges[e].bridge for e in set(S['src']))
            tb = any(edges[e].bridge for e in set(T['src']))
            for i in range(n):
                pt = Point(P[i])
                d = L.distance(pt)
                if d > PAIR_MAX or d < PAIR_MIN:
                    continue
                s = L.project(pt)
                q = np.array(L.interpolate(s).coords[0])
                q2 = np.array(L.interpolate(min(L.length, s + 2)).coords[0])
                q1 = np.array(L.interpolate(max(0, s - 2)).coords[0])
                fd = q2 - q1
                fl = np.linalg.norm(fd)
                if fl < 1e-6:
                    continue
                fd /= fl
                if fd @ D[i] > -0.8:
                    continue
                v = q - P[i]
                right = np.array([-D[i][1], D[i][0]])
                if v @ right > 0:
                    continue
                if abs(v @ D[i]) > 0.5 * d:
                    continue
                if btree is not None and not (sb and tb):
                    mid = Point(P[i] + v / 2)
                    hit = False
                    for k in btree.query(mid.buffer(d)):
                        if bridge_lines[int(k)].distance(mid) < 0.45 * d:
                            hit = True
                            break
                    if hit:
                        continue
                if best[i] is None or d < best[i][0]:
                    best[i] = (d, v, T['id'], s)
        # a merged pair keeps both OSM lines' outer edges within ~2 m only where the gap follows its neighbours'
        # (the built median is eased): a flare at a junction stays two one-way roads (owner 17 Nov)
        gaps = np.array([b[0] if b else np.nan for b in best])
        for i, b in enumerate(best):
            if b:
                w = gaps[max(0, i - 6):i + 7]
                w = w[~np.isnan(w)]
                if len(w) >= 3 and abs(b[0] - np.median(w)) > 2 * MERGE_TOL:
                    best[i] = None
        # runs per partner
        by_t = collections.defaultdict(list)
        for i, b in enumerate(best):
            if b:
                by_t[b[2]].append(i)
        for tid, idx in by_t.items():
            idx = np.array(sorted(idx))
            ok = np.zeros(n, bool)
            ok[idx] = True
            for k in range(len(idx) - 1):        # fill short gaps
                if 1 < idx[k + 1] - idx[k] <= 8:
                    ok[idx[k]:idx[k + 1] + 1] = True
            i = 0
            while i < n:
                if not ok[i]:
                    i += 1
                    continue
                j = i
                while j + 1 < n and ok[j + 1]:
                    j += 1
                if S['c'][j] - S['c'][i] >= geo.m(20):
                    good = [k for k in range(i, j + 1) if best[k] and best[k][2] == tid]
                    runs.append(dict(S=S['id'], T=tid, i=i, j=j, good=good, best=best))
                i = j + 1
    return runs


def build_pieces(edges, rings):
    """-> pieces (paired midlines, one-way remnants, two-way edges), the strokes and runs (for the flyover)"""
    ring_keys = set()
    ring_edges = set()
    for R in rings:
        ring_keys |= R['keys']
        ring_edges |= set(R['edges'])
    bridge_lines = [LineString(e.P) for e in edges if e.bridge and e.hw in RN.MAIN]
    strokes = strokes_oneway(edges, ring_keys)
    SB = {S['id']: S for S in strokes}
    runs = pair(strokes, edges, bridge_lines)
    used_S = collections.defaultdict(list)    # stroke id -> [(c0, c1)] chainage taken by a run
    pieces = []
    for r in runs:
        S, T = SB[r['S']], SB[r['T']]
        i, j = r['i'], r['j']
        good = r['good']
        best = r['best']
        gi = np.array(good)
        V = np.array([best[k][1] for k in good])
        G = np.array([best[k][0] for k in good])
        TS = np.array([best[k][3] for k in good])
        ks = np.arange(i, j + 1)
        Vx = np.interp(ks, gi, V[:, 0])
        Vz = np.interp(ks, gi, V[:, 1])
        Gg = np.interp(ks, gi, G)
        Ts = np.interp(ks, gi, TS)
        k = 3
        if len(ks) > 2 * k + 1:
            Vx = np.convolve(np.pad(Vx, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
            Vz = np.convolve(np.pad(Vz, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
            Gg = np.convolve(np.pad(Gg, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
        M = S['P'][i:j + 1] + np.stack([Vx, Vz], 1) / 2
        # cross-section: S is the right-hand carriageway (it runs the road's way), T the left
        srcS = [S['src'][x] for x in ks]
        nr, Wr = [], []
        nl, Wl = [], []
        srcT = []
        TL = T['line']
        Tc = T['c']
        for x, ts in zip(ks, Ts):
            es = edges[S['src'][x]]
            nr.append(es.cs['nf'])
            Wr.append(es.cs['Wf'])
            ti = int(np.clip(np.searchsorted(Tc, ts), 0, len(T['src']) - 1))
            et = edges[T['src'][ti]]
            srcT.append(et.id)
            nl.append(et.cs['nf'])
            Wl.append(et.cs['Wf'])
        nr, nl, Wr, Wl = map(np.array, (nr, nl, Wr, Wl))
        # (J15, owner: Shwedagon Pagoda Road "one constant width"; OSM tags its southbound carriageway lanes=4, the
        # whole road's count, the northbound one lanes=2: a 22.5 / 43.5 one-sided road and bridge) a carriageway
        # tagged with twice its partner's lanes or more carries the partner's count
        lo = np.minimum(nr, nl)
        odd = (lo > 0) & (np.maximum(nr, nl) >= 2 * lo)
        nr, nl = np.where(odd, lo, nr), np.where(odd, lo, nl)
        med = np.maximum(MED_MIN, Gg / 2 - np.maximum(nr * Wr, nl * Wl) / 2)
        p = piece_from(M, nl, nr, Wl, Wr, med, S['name'], S['hw'], srcS, 0, [None, None],
                       bridge=any(edges[e].bridge for e in srcS))
        p.srcT = srcT
        p.pairS, p.pairT = S['id'], T['id']
        p.cS = (S['c'][i], S['c'][j])
        p.cT = (float(min(Ts)), float(max(Ts)))
        pieces.append(p)
        used_S[S['id']].append(p.cS)
        used_S[T['id']].append(p.cT)
    # remnants of every stroke (what no run took), as one-way pieces
    rem = []
    for S in strokes:
        taken = sorted(used_S.get(S['id'], []))
        free = []
        c0 = 0.0
        for a, b in taken:
            if a - c0 > 0.5:
                free.append((c0, a))
            c0 = max(c0, b)
        if S['c'][-1] - c0 > 0.5:
            free.append((c0, S['c'][-1]))
        for a, b in free:
            m = (S['c'] >= a - 1e-6) & (S['c'] <= b + 1e-6)
            idx = np.where(m)[0]
            if len(idx) < 2:
                continue
            P = S['P'][idx]
            e0 = edges[S['src'][idx[0]]]
            rem.append(dict(S=S['id'], a=a, b=b, P=P, src=[S['src'][x] for x in idx], atStart=a < 0.5,
                            atEnd=b > S['c'][-1] - 0.5, L=b - a, e=e0))
    # fold short remnants into the midlines next to them
    keep = []
    mid_by_stroke = collections.defaultdict(list)
    for p in pieces:
        mid_by_stroke[p.pairS].append(p)
        mid_by_stroke[p.pairT].append(p)
    folded = set()
    for ri, R in enumerate(rem):
        if R['L'] > TAIL:
            continue
        # a remnant touching a run of its stroke (at a run's end) and reaching the stroke's own end or another run
        for p in mid_by_stroke[R['S']]:
            cs = p.cS if p.pairS == R['S'] else p.cT
            if abs(R['b'] - cs[0]) < 6 or abs(R['a'] - cs[1]) < 6:
                # folding moves the tail onto the midline: only where that keeps its edge within MERGE_TOL
                end = 0 if abs(R['b'] - cs[0]) < 6 else -1
                if float(np.asarray(p.med)[end]) <= MERGE_TOL:
                    folded.add(ri)
                break
    # extend each midline end to the middle of its folded tails' far ends
    for p in pieces:
        S, T = SB[p.pairS], SB[p.pairT]
        for end in (0, 1):
            # S at the start end: the remnant before cS[0]; T at the start end: the remnant after cT[1]
            if end == 0:
                rs = [R for k, R in enumerate(rem) if k in folded and R['S'] == S['id'] and abs(R['b'] - p.cS[0]) < 6]
                rt = [R for k, R in enumerate(rem) if k in folded and R['S'] == T['id'] and abs(R['a'] - p.cT[1]) < 6]
                fs = rs[0]['P'][0] if rs else None
                ft = rt[0]['P'][-1] if rt else None
            else:
                rs = [R for k, R in enumerate(rem) if k in folded and R['S'] == S['id'] and abs(R['a'] - p.cS[1]) < 6]
                rt = [R for k, R in enumerate(rem) if k in folded and R['S'] == T['id'] and abs(R['b'] - p.cT[0]) < 6]
                fs = rs[0]['P'][-1] if rs else None
                ft = rt[0]['P'][0] if rt else None
            if fs is None and ft is None:
                continue
            q = (fs + ft) / 2 if (fs is not None and ft is not None) else (fs if fs is not None else ft)
            if fs is not None and ft is not None and np.linalg.norm(fs - ft) > PAIR_MAX * 1.6:
                # (two tails far apart: only into a roundabout, where the midpoint lies in the ring)
                if not any(np.linalg.norm(q - R['c']) < R['r_out'] for R in rings):
                    for R in rs + rt:
                        R['unfold'] = True
                    continue
            k0 = 0 if end == 0 else -1
            # straight on along the run's own end direction (a midpoint off to one side bent the road's end)
            pe, de = piece_end(p, end)
            q = pe + de * max(0.0, float((q - pe) @ de))
            if np.linalg.norm(q - p.P[k0]) < 1:
                continue
            ext = np.linspace(q, p.P[k0], max(2, int(np.linalg.norm(q - p.P[k0]) / 4) + 1))
            if end == 0:
                p.P = np.vstack([ext[:-1], p.P])
                padn = len(ext) - 1
                for a in ('nl', 'nr', 'Wl', 'Wr', 'med'):
                    v = getattr(p, a)
                    setattr(p, a, np.r_[np.full(padn, v[0]), v])
                p.src = [p.src[0]] * padn + p.src
                p.srcT = [p.srcT[0]] * padn + p.srcT
            else:
                ext = ext[::-1]
                p.P = np.vstack([p.P, ext[1:]])
                padn = len(ext) - 1
                for a in ('nl', 'nr', 'Wl', 'Wr', 'med'):
                    v = getattr(p, a)
                    setattr(p, a, np.r_[v, np.full(padn, v[-1])])
                p.src = p.src + [p.src[-1]] * padn
                p.srcT = p.srcT + [p.srcT[-1]] * padn
    for k, R in enumerate(rem):
        if k in folded and not R.get('unfold'):
            continue
        e = R['e']
        cs = e.cs
        n = cs['nf']
        pc = piece_from(R['P'], 0, n, 0, cs['Wf'], 0, e.name, e.hw, R['src'], 1, [None, None], bridge=e.bridge)
        pc.wl_fix = n * cs['Wf'] / 2
        pieces.append(pc)
    # every other edge (two-way, one-way streets): as is
    in_stroke = set()
    for S in strokes:
        for e in S['edges']:
            in_stroke.add(e.id)
    for e in edges:
        if e.id in in_stroke or e.ring:
            continue
        cs = e.cs
        if e.oneway:
            pc = piece_from(e.P, 0, cs['nf'], 0, cs['Wf'], 0, e.name, e.hw, e.id, 1, [e.a, e.b], bridge=e.bridge, tags=e.t)
            pc.wl_fix = cs['nf'] * cs['Wf'] / 2
        else:
            pc = piece_from(e.P, cs['nb'], cs['nf'], cs['Wb'], cs['Wf'], 0, e.name, e.hw, e.id, 0, [e.a, e.b], bridge=e.bridge, tags=e.t)
        pieces.append(pc)
    stats = dict(strokes=len(strokes), runs=len(runs), remnants=len(rem), folded=len(folded),
                 paired_km=round(sum(chain(p.P)[-1] for p in pieces if hasattr(p, 'pairS')) / geo.SPM / 1000, 2))
    return pieces, strokes, runs, stats


# ------------------------------------------------------------------------------------------------ 4. roads from pieces
def piece_end(p, end, base=30.0):
    P = p.P
    if end == 0:
        q = P[0]
        k = min(len(P) - 1, 1)
        for k in range(1, len(P)):
            if np.linalg.norm(P[k] - q) > base:
                break
        d = q - P[k]
    else:
        q = P[-1]
        for k in range(len(P) - 2, -1, -1):
            if np.linalg.norm(P[k] - q) > base:
                break
        d = q - P[k]
    L = np.linalg.norm(d)
    return q, d / max(L, 1e-9)


def reverse_piece(p):
    p.P = p.P[::-1].copy()
    p.nl, p.nr = p.nr[::-1].copy(), p.nl[::-1].copy()
    p.Wl, p.Wr = p.Wr[::-1].copy(), p.Wl[::-1].copy()
    p.med = p.med[::-1].copy()
    p.src = p.src[::-1]
    p.ends = p.ends[::-1]
    if hasattr(p, 'srcT'):
        p.srcT = p.srcT[::-1]
    p.rev = not getattr(p, 'rev', False)


def cls_family(hw):
    return 'main' if hw in RN.MAIN else 'street'


def join_roads(pieces, ring_keys, region):
    """pieces of one road joined end to end (same name, or unnamed of one class), straightest first"""
    ends = []
    for pi, p in enumerate(pieces):
        for end in (0, 1):
            q, d = piece_end(p, end)
            ends.append((pi, end, q, d))
    pts = np.array([e[2] for e in ends])
    tree = cKDTree(pts)
    cands = []
    for a, b in tree.query_pairs(JOIN):
        pa, ea, qa, da = ends[a]
        pb, eb, qb, db = ends[b]
        if pa == pb:
            continue
        A, B = pieces[pa], pieces[pb]
        named = A.nn and A.nn == B.nn
        if not named:
            if A.nn or B.nn or cls_family(A.hw) != cls_family(B.hw):
                continue
            if np.linalg.norm(qa - qb) > 1.0:
                continue
        if any(k in ring_keys for k in (A.ends[ea], B.ends[eb]) if k is not None):
            continue
        cos = float(da @ db)          # both point outward: a straight join has cos = -1
        lim = -math.cos(math.radians(50 if named else 30))
        if cos > lim:
            continue
        gap = float(np.linalg.norm(qa - qb))
        # the gap must not run sideways (two parallel carriageway ends side by side)
        if gap > 2:
            g = (qb - qa) / gap
            if abs(float(g @ da)) < 0.7:
                continue
        cands.append((cos + gap / 400.0 + (0.3 if A.hw != B.hw else 0.0), a, b))
    cands.sort()
    link = {}
    for _, a, b in cands:
        if a in link or b in link:
            continue
        link[a] = b
        link[b] = a
    # walk chains: end index = pi * 2 + end
    eidx = {(e[0], e[1]): i for i, e in enumerate(ends)}
    seen = set()
    roads = []

    def walk(pi, end_in):
        """start at piece pi entered at end_in; returns [(piece, reversed?)]"""
        out = []
        cur, ein = pi, end_in
        while True:
            if cur in seen:
                break
            seen.add(cur)
            out.append((cur, ein == 1))
            eout = 1 - ein
            k = eidx[(cur, eout)]
            if k not in link:
                break
            nk = link[k]
            npi, nend = ends[nk][0], ends[nk][1]
            cur, ein = npi, nend
        return out
    for pi in range(len(pieces)):
        if pi in seen:
            continue
        # find a chain end: go back along links
        cur, end = pi, 0
        guard = 0
        while True:
            k = eidx[(cur, end)]
            if k not in link or guard > len(pieces):
                break
            nk = link[k]
            npi, nend = ends[nk][0], ends[nk][1]
            if npi == pi:
                break
            cur, end = npi, 1 - nend
            guard += 1
        roads.append(walk(cur, end))
    out = []
    for chainp in roads:
        parts = []
        for pi, rev in chainp:
            p = pieces[pi]
            if rev:
                reverse_piece(p)
            parts.append(p)
        out.append(parts)
    return out


def merge_parts(parts):
    """one polyline with per-sample attributes; joins blended across gaps"""
    P, attrs = [], collections.defaultdict(list)
    names = ('nl', 'nr', 'Wl', 'Wr', 'med')
    src = []
    for k, p in enumerate(parts):
        Q = p.P
        if k > 0 and np.linalg.norm(Q[0] - P[-1]) < 0.5:
            Q = Q[1:]
            sl = slice(1, None)
        else:
            sl = slice(0, None)
        P.extend(Q)
        for a in names:
            v = getattr(p, a)[sl]
            if p.oneway and a in ('Wl', 'Wr'):
                pass
            attrs[a].extend(v)
        oneway = np.full(len(Q), p.oneway)
        attrs['oneway'].extend(oneway)
        src.extend(p.src[sl])
    return np.array(P), {a: np.array(v, float) for a, v in attrs.items()}, src


# ------------------------------------------------------------------------------------------------ 5. heights
class Heights:
    def __init__(self, tags):
        self.by_key = collections.defaultdict(list)
        self.all = []
        self.raised_pts = []
        for t in tags:
            path = os.path.join(geo.BUILD, 'city_1to1', 'roads_%s_profile.json' % t)
            for e in json.load(open(path)):
                kk = (norm(e['name']), e['hw'])
                for q in e['pts']:
                    self.by_key[kk].append((q[0], q[2], q[1], q[3], e['raised']))
                    if not e['raised']:
                        self.all.append((q[0], q[2], q[1], q[3]))
                    else:
                        self.raised_pts.append((q[0], q[2], q[1], q[3]))
        self.trees = {}
        for kk, v in self.by_key.items():
            A = np.array(v)
            self.trees[kk] = (cKDTree(A[:, :2]), A)
        A = np.array(self.all)
        self.tall = (cKDTree(A[:, :2]), A)
        R = np.array(self.raised_pts) if self.raised_pts else np.zeros((0, 4))
        self.traised = (cKDTree(R[:, :2]), R) if len(R) else None

    def at(self, xz, keys, allow_raised=False):
        best = None
        for kk in keys:
            if kk not in self.trees:
                continue
            tr, A = self.trees[kk]
            d, i = tr.query(xz, k=8, distance_upper_bound=50)
            ok = np.isfinite(d)
            if not allow_raised:
                ok &= np.array([(not A[j, 4]) if np.isfinite(dd) else False for dd, j in zip(d, np.minimum(i, len(A) - 1))])
            if ok.any():
                w = 1.0 / (d[ok] + 1.0) ** 2
                y = float((A[i[ok], 2] * w).sum() / w.sum())
                g = float((A[i[ok], 3] * w).sum() / w.sum())
                if best is None or d[ok].min() < best[0]:
                    best = (d[ok].min(), y, g)
        if best is not None:
            return best[1], best[2], best[0]
        tr, A = self.tall
        d, i = tr.query(xz, k=4, distance_upper_bound=150)
        ok = np.isfinite(d)
        if ok.any():
            w = 1.0 / (d[ok] + 1.0) ** 2
            return float((A[i[ok], 2] * w).sum() / w.sum()), float((A[i[ok], 3] * w).sum() / w.sum()), 999.0
        d, i = tr.query(xz, k=1)
        return float(A[i, 2]), float(A[i, 3]), 9999.0


# ------------------------------------------------------------------------------------------------ main build
SEC_MIN = 300.0


def run_median(v, c, L):
    """median over +-L/2 studs of chainage (ends: the window shrinks); keeps steps, drops short bumps"""
    v = np.asarray(v, float)
    if len(v) < 3 or c[-1] < L / 2:
        return v.copy()
    out = v.copy()
    lo = np.searchsorted(c, c - L / 2)
    hi = np.searchsorted(c, c + L / 2, side='right')
    for i in range(len(v)):
        out[i] = np.median(v[lo[i]:hi[i]])
    return out


def med_runs(mb, c):
    """median halves per sample -> constant-width runs with blunt noses (see finish)"""
    mb = np.asarray(mb, float).copy()
    n = len(mb)

    def runs(on):
        k, n = 0, len(on)
        while k < n:
            if not on[k]:
                k += 1
                continue
            j = k
            while j + 1 < n and on[j + 1]:
                j += 1
            yield k, j
            k = j + 1
    out = np.zeros(n)
    for k, j in runs(mb > 0):
        w = float(np.median(mb[k:j + 1]))
        keep = mb[k:j + 1] >= max(0.75 * w, min(w, MED_CUT))
        for a, b in runs(keep):
            a, b = a + k, b + k
            if c[b] - c[a] < MIN_MEDIAN:
                continue
            ww = float(mb[a:b + 1].min())  # never wider than the lanes' gap (s[11])
            out[a:b + 1] = ww
            out[a] = out[b] = ww * 0.7      # a blunt nose: the builder closes it over one sample step
    return out


def widen_rate(v, c, k=0.12):
    """an edge never steps in faster than k studs a stud (it widens instead: no notches)"""
    v = np.asarray(v, float).copy()
    for i in range(1, len(v)):
        v[i] = max(v[i], v[i - 1] - k * (c[i] - c[i - 1]))
    for i in range(len(v) - 2, -1, -1):
        v[i] = max(v[i], v[i + 1] - k * (c[i + 1] - c[i]))
    return v


BRIDGE_NEAR = 40.0   # a raised profile point is a deck only within this of an OSM bridge way
SMOOTH_W = 16.0      # profile heights are smoothed along a road over +- this (two profile point spacings)


def smooth_chain(v, c, W=SMOOTH_W):
    """triangle-weighted mean over +- W studs of chainage (ends: the window shrinks): takes out the inverse-distance
    stair (flat at each profile point, steep between) and keeps the grade"""
    v = np.asarray(v, float)
    c = np.asarray(c, float)
    out = v.copy()
    lo = np.searchsorted(c, c - W)
    hi = np.searchsorted(c, c + W, side='right')
    for i in range(len(v)):
        w = np.maximum(0.0, 1.0 - np.abs(c[lo[i]:hi[i]] - c[i]) / W)
        out[i] = float((v[lo[i]:hi[i]] * w).sum() / w.sum())
    return out


def ease_steps(v, c, L=EASE_W):
    """a piecewise-constant array eased linearly over L studs at each change (centred)"""
    v = np.asarray(v, float)
    if len(v) < 3:
        return v.copy()
    out = v.copy()
    ch = np.where(np.abs(np.diff(v)) > 1e-6)[0]
    for k in ch:
        cm = (c[k] + c[k + 1]) / 2
        a, b = v[k], v[k + 1]
        lo = np.searchsorted(c, cm - L / 2)
        hi = np.searchsorted(c, cm + L / 2)
        for i in range(lo, min(hi, len(v))):
            u = np.clip((c[i] - (cm - L / 2)) / L, 0, 1)
            out[i] = a + (b - a) * (u * u * (3 - 2 * u))
    return out


def build(tags):
    region, edges = load(tags)
    rings = roundabouts(edges, region)
    ring_keys = set()
    for R in rings:
        ring_keys |= R['keys']
    pieces, strokes, runs, pstats = build_pieces(edges, rings)
    groups = join_roads(pieces, ring_keys, region)
    H = Heights(tags)
    roads = []
    for parts in groups:
        P, A, src = merge_parts(parts)
        if len(P) < 2 or chain(P)[-1] < 6:
            continue
        hw = min((edges[s].hw for s in src), key=lambda h: RANK_CLASS.get(h, 6))
        name = next((p.name for p in parts if p.name), '')
        # smooth the line a little (OSM vertices are corners), resample
        Ps = smooth_line(P, 9 if hw in RN.MAIN else 7)
        Q, t, c0 = resample(Ps, STEP)
        # attributes by nearest original sample (chainage on the smoothed line ~ the original's)
        cP = chain(P)
        cS = chain(Ps)
        scale = cP[-1] / max(cS[-1], 1e-9)
        idx = np.clip(np.searchsorted(cP, t * scale), 0, len(P) - 1)
        att = {a: A[a][idx] for a in A}
        srcs = [src[i] for i in idx]
        c = chain(Q)
        # cross-section per sample
        nl, nr, Wl, Wr, med = att['nl'], att['nr'], att['Wl'], att['Wr'], att['med']
        one = att['oneway'] > 0.5
        # (17 Nov, owner's "streets stop into grass": a one-way piece joined against its stroke carries its lanes in
        # nl, and nr * Wr gave it NO width: half of 57 downtown streets were never built) a one-way's lanes either side
        n1 = np.where(nr > 0, nr, nl)
        W1 = np.where(nr > 0, Wr, Wl)
        wl = np.where(one, (n1 * W1) / 2, med + nl * Wl)
        wr = np.where(one, (n1 * W1) / 2, med + nr * Wr)
        lm = np.where(one, 0.0, med)
        lanes = np.maximum(np.where(one, n1, np.maximum(nl, nr)), 1)
        lw = np.where(one, W1, np.maximum(Wl, Wr))
        # no section shorter than SEC_MIN (OSM's lane tags change at every way: a notch each time): a running median
        wl, wr, lm, lw = (run_median(x, c, SEC_MIN) for x in (wl, wr, lm, lw))
        lanes = np.round(run_median(lanes.astype(float), c, SEC_MIN)).astype(int)
        wl, wr, lm, lw = (ease_steps(x, c) for x in (wl, wr, lm, lw))
        wl, wr = widen_rate(wl, c), widen_rate(wr, c)
        main = hw in RN.MAIN
        look = 'main' if main else ('narrow' if any(edges[s].cs['look'] == 'narrow' for s in srcs) and not main else 'street')
        walk = WALK[look]
        r = dict(name=name or '', hw=hw, main=main, P=Q, c=c, wl=wl, wr=wr, lm=lm, lanes=lanes, lw=lw,
                 oneway=bool(one.all() and (nr > 0).all()), src=srcs, walk=walk,  # (a one-way run against its stroke: two-way data)
                 keys=[(norm(edges[s].name), edges[s].hw) for s in sorted(set(srcs))],
                 bridge=any(edges[s].bridge for s in srcs),
                 L=float(c[-1]))
        roads.append(r)
    # names: unique, readable
    cnt = collections.Counter()
    for r in roads:
        base = r['name'] or ('Lane' if not r['main'] else 'Road')
        cnt[base] += 1
        r['label'] = base if cnt[base] == 1 else '%s #%d' % (base, cnt[base])
    stats = dict(pieces=len(pieces), roads_raw=len(roads), **pstats)
    return dict(region=region, edges=edges, rings=rings, roads=roads, H=H, stats=stats, tags=tags)


# ------------------------------------------------------------------------------------------------ 6. ranks, heights, decks
def scc(n, succ):
    """strongly connected components (iterative Tarjan): node -> component id"""
    index = [None] * n
    low = [0] * n
    on = [False] * n
    st = []
    comp = [None] * n
    nxt = [0]
    cid = [0]
    for v0 in range(n):
        if index[v0] is not None:
            continue
        work = [(v0, iter(succ.get(v0, ())))]
        index[v0] = low[v0] = nxt[0]
        nxt[0] += 1
        st.append(v0)
        on[v0] = True
        while work:
            v, it = work[-1]
            adv = False
            for w in it:
                if index[w] is None:
                    index[w] = low[w] = nxt[0]
                    nxt[0] += 1
                    st.append(w)
                    on[w] = True
                    work.append((w, iter(succ.get(w, ()))))
                    adv = True
                    break
                elif on[w]:
                    low[v] = min(low[v], index[w])
            if adv:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[v])
            if low[v] == index[v]:
                while True:
                    w = st.pop()
                    on[w] = False
                    comp[w] = cid[0]
                    if w == v:
                        break
                cid[0] += 1
    return comp


def road_half(r, i):
    return max(r['wl'][i], r['wr'][i])


def inside0(px, pz, o, margin=0.0):
    """is (px, pz) on road o's carriageway (not a cut sample)? -> nearest sample index or None"""
    P = o['P']
    q = np.array([px, pz])
    d = np.linalg.norm(P - q, axis=1)
    i = int(np.argmin(d))
    if d[i] > 120:
        return None
    if o['cut'][i]:
        return None
    best = None
    for k in (i - 1, i):
        if k < 0 or k + 1 >= len(P):
            continue
        a, b = P[k], P[k + 1]
        ab = b - a
        L2 = float(ab @ ab)
        u = 0.0 if L2 < 1e-9 else float(np.clip((q - a) @ ab / L2, 0, 1))
        dd = float(np.linalg.norm(q - (a + ab * u)))
        if best is None or dd < best[0]:
            best = (dd, k if u < 0.5 else k + 1)
    if best is None:
        best = (float(d[i]), i)
    if best[0] < road_half(o, best[1]) + margin:
        return best[1]
    return None


DECK_SPAN_MIN = 75.0   # (J14) 25 m: a shorter raised run is a culvert / drain bridge, built as ground road
_UNDER = None


def _under():
    """railways and rivers / canals / lakes a deck may cross (streams, drains, ditches are not: culverts)"""
    global _UNDER
    if _UNDER is None:
        g = []
        for l in geo.load('lines'):
            t = l['t']
            if t.get('railway') in ('rail', 'tram', 'disused', 'light_rail', 'subway') or t.get('waterway') in ('river', 'canal'):
                if len(l['p']) >= 2:
                    g.append(LineString(geo.proj(l['p'])))
        for a in geo.load('areas'):
            t = a['t']
            if t.get('natural') == 'water' or t.get('water') in ('river', 'reservoir', 'lake') or t.get('waterway') == 'riverbank':
                try:
                    P = Polygon(geo.proj(a['p']))
                    if P.is_valid and P.area > 0:
                        g.append(P)
                except Exception:
                    pass
        _UNDER = (STRtree(g), g) if g else None
    return _UNDER


DECK_REACH = 150.0      # the raised run is only where the profile is 6+ over the ground: the structure reaches past it


def deck_crosses(r, i0, i1, roads):
    """(J14, owner: "not a bridge in real life" / "never drop a deck that runs over a ground road") a deck only where
    the raised run is >= DECK_SPAN_MIN and the structure (the run + DECK_REACH each way, 30 studs wide) meets another
    road, a railway, a river / canal or a lake -> 'road' (a flyover over a ground road), 'rail / water' (a simple
    bridge), or None (a culvert hump: built as ground road)"""
    if r['c'][i1] - r['c'][i0] < DECK_SPAN_MIN:
        return None
    run = LineString(r['P'][i0:i1 + 1])
    for o in roads:
        if o is not r and norm(o['name']) != norm(r['name']) and run.crosses(LineString(o['P'])):
            return 'road'
    k = [i for i in range(len(r['P'])) if r['c'][i0] - DECK_REACH <= r['c'][i] <= r['c'][i1] + DECK_REACH]
    zone = LineString(r['P'][k[0]:k[-1] + 1]).buffer(30)
    u = _under()
    if u:
        for j in u[0].query(zone):
            if zone.intersects(u[1][int(j)]):
                return 'rail / water'
    for o in roads:
        if o is not r and norm(o['name']) != norm(r['name']) and zone.intersects(LineString(o['P'])):
            return 'road'
    return None


DECK_GAP = 400.0     # ground this long between two raised runs of one road = two decks
DECK_FLAT = 24.0    # a deck starts level off its ramp foot (owner's bug 2: the ramp rose out of the junction box)
DECK_GRADE = 0.05


def deck_profile(raw, cc, y0, y1):
    """a flyover's heights (owner's bugs 2-5, 17 Nov: the raised profile stepped and dipped): level start at each
    foot, one straight grade up to one level top (the profile's 90th percentile), vertical curves, ends on the feet"""
    L = float(cc[-1])
    top = max(float(np.percentile(raw, 90)), y0, y1)
    run = max(L / 2 - DECK_FLAT, 1.0)
    grade = max(DECK_GRADE, (top - min(y0, y1)) / run)
    y = np.minimum(top, np.minimum(y0 + grade * np.maximum(0, cc - DECK_FLAT), y1 + grade * np.maximum(0, L - cc - DECK_FLAT)))
    k = 3
    if len(y) > 2 * k + 1:
        y = np.convolve(np.pad(y, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
    y[0], y[-1] = y0, y1
    return y


def finish(net):
    roads, rings, H = net['roads'], net['rings'], net['H']
    region = net['region']
    # flyovers: roads with samples near raised profile points of their own key
    decks = []
    for r in roads:
        r['cut'] = np.zeros(len(r['P']), bool)
    # (24 Nov, Arzani Street: the old P7 profile's "raised" run made a 1.2 km flyover deck where OSM has no bridge)
    # a raised profile point counts only where an OSM bridge way lies near; elsewhere the road is ground
    blines = [LineString(e.P) for e in net['edges'] if getattr(e, 'bridge', False) and len(e.P) > 1]
    btree = STRtree(blines) if blines else None

    def on_bridge(xz):
        if btree is None:
            return False
        pt = Point(float(xz[0]), float(xz[1]))
        return any(blines[int(k)].distance(pt) < BRIDGE_NEAR for k in btree.query(pt.buffer(BRIDGE_NEAR)))
    # heights (deck heights for raised samples kept separately)
    for r in roads:
        n = len(r['P'])
        y = np.zeros(n)
        g = np.zeros(n)
        yr = np.full(n, np.nan)
        for i in range(n):
            y[i], g[i], _ = H.at(r['P'][i], r['keys'], allow_raised=False)
            if r['main'] and H.traised is not None:
                tr, R = H.traised
                d, j = tr.query(r['P'][i], k=1, distance_upper_bound=40)
                if np.isfinite(d) and on_bridge(r['P'][i]):
                    yy, gg, dd = H.at(r['P'][i], r['keys'], allow_raised=True)
                    yr[i] = yy
        # (24 Nov, Ziwaka / Shwe Gone Dine / Merchant: the profile points are ~15 studs apart and H.at's inverse-distance
        # weights go flat at each point, so every other 8-stud sample changed grade by up to 8%) smoothed along the road
        r['y'], r['g'], r['yr'] = smooth_chain(y, r['c']), g, yr
    # decks: a main road whose raised-near samples climb > 6 studs over the ground
    for r in roads:
        ok = np.isfinite(r['yr']) & (r['yr'] - r['g'] > 6.0)
        if ok.sum() < 6:
            continue
        idx = np.where(ok)[0]
        # one deck per raised run (17 Nov: Lay Daungkan's two real bridges 12 km apart made ONE 12 km deck over every
        # ground junction between them; the slip roads there ended on nothing): split where the ground lasts DECK_GAP
        runs = [[idx[0], idx[0]]]
        for i in idx[1:]:
            if r['c'][i] - r['c'][runs[-1][1]] > DECK_GAP:
                runs.append([i, i])
            else:
                runs[-1][1] = i
        for i0, i1 in runs:
            if i1 - i0 >= 5:
                why = deck_crosses(r, int(i0), int(i1), roads)
                if why:
                    decks.append(dict(road=r, i0=int(i0), i1=int(i1), over=why))
                else:
                    a, b = r['P'][int(i0)], r['P'][int(i1)]
                    net.setdefault('decks_dropped', []).append(dict(road=r['name'], x=round(float((a[0] + b[0]) / 2), 1),
                                                                    z=round(float((a[1] + b[1]) / 2), 1),
                                                                    span=round(float(r['c'][int(i1)] - r['c'][int(i0)]), 1)))
                    r['yr'][int(i0):int(i1) + 1] = np.nan   # a ground road at full width
    net['decks'] = decks
    # side lanes of a deck: other roads of the deck's name running beside it
    for dk in decks:
        r = dk['road']
        line = LineString(r['P'][dk['i0']:dk['i1'] + 1])
        dk['sides'] = []
        for o in roads:
            if o is r or not o['oneway']:
                continue
            if norm(o['name']) != norm(r['name']):
                continue
            ol = LineString(o['P'])
            if ol.length < 100 or line.distance(ol) > geo.m(20):
                continue
            # most of it beside the deck
            near = sum(1 for p in o['P'] if line.distance(Point(p)) < geo.m(22))
            if near > 0.6 * len(o['P']):
                dk['sides'].append(o)
        # the deck runs to the side lanes' ends (the ramp feet): project their ends onto the road
        RL = LineString(r['P'])
        cs = []
        for o in dk['sides']:
            for q in (o['P'][0], o['P'][-1]):
                cs.append(RL.project(Point(q)))
        if cs:
            a = np.searchsorted(r['c'], min(cs)) - 1
            b = np.searchsorted(r['c'], max(cs)) + 1
        else:
            # no ground lanes: the feet are where the road leaves the ground
            yy = np.where(np.isfinite(r['yr']), r['yr'], r['y'])
            a, b = dk['i0'], dk['i1']
            while a > 0 and yy[a] - r['g'][a] > 0.6:
                a -= 1
            while b < len(yy) - 1 and yy[b] - r['g'][b] > 0.6:
                b += 1
        dk['from'], dk['to'] = int(max(0, a)), int(min(len(r['P']) - 1, b))
        for i in range(dk['from'] + 1, dk['to']):
            r['cut'][i] = True
        # deck heights: raised profile where near, else the ramp heights of its own key
        ys = []
        for i in range(dk['from'], dk['to'] + 1):
            yy, gg, _ = H.at(r['P'][i], r['keys'], allow_raised=True)
            ys.append(yy)
        dk['y'] = deck_profile(np.array(ys), r['c'][dk['from']:dk['to'] + 1] - r['c'][dk['from']],
                               r['y'][dk['from']], r['y'][dk['to']])
    # roundabouts: an arm's samples well inside the ring are cut (Friday's R_CUT = R_OUT - 14)
    for R in rings:
        for r in roads:
            d = np.linalg.norm(r['P'] - R['c'], axis=1)
            rc = d < R['r_out'] - 14
            r['ringcut'] = r.get('ringcut', np.zeros(len(r['P']), bool)) | rc
            r['cut'] |= rc
    # rings: heights at their centre from the arms' ends
    for R in rings:
        ys = []
        for r in roads:
            for k in (0, -1):
                if np.linalg.norm(r['P'][k] - R['c']) < R['r_out']:
                    ys.append(r['y'][k])
        R['y'] = float(np.median(ys)) if ys else float(H.at(R['c'], [], False)[0])
        R['arms'] = []
    # junction fillers: a short road lying (almost) wholly on other roads' carriageways goes
    lines = [LineString(r['P']) for r in roads]
    tree = STRtree(lines)
    drop = set()
    for xi, r in enumerate(roads):
        if any(r is dk['road'] for dk in decks):
            continue
        cand = [int(j) for j in tree.query(lines[xi].buffer(60)) if int(j) != xi and int(j) not in drop]
        on = 0
        for k in range(len(r['P'])):
            px, pz = r['P'][k]
            for j in cand:
                o = roads[j]
                if o['L'] <= r['L'] and o['main'] == r['main']:
                    continue
                if inside0(px, pz, o) is not None:
                    on += 1
                    break
        if on >= 0.8 * len(r['P']):
            drop.add(xi)
    net['dropped_fillers'] = len(drop)
    roads[:] = [r for i, r in enumerate(roads) if i not in drop]
    net['roads'] = roads
    # ranks
    lines = [LineString(r['P']) for r in roads]
    tree = STRtree(lines)

    def inside(px, pz, o, margin=0.0):
        """is (px, pz) on road o's carriageway (not a cut sample)? -> sample index or None"""
        P = o['P']
        d = np.linalg.norm(P - np.array([px, pz]), axis=1)
        i = int(np.argmin(d))
        if o['cut'][i]:
            return None
        # distance to the polyline near i
        best = None
        for k in (i - 1, i):
            if k < 0 or k + 1 >= len(P):
                continue
            a, b = P[k], P[k + 1]
            ab = b - a
            L2 = float(ab @ ab)
            u = 0.0 if L2 < 1e-9 else float(np.clip((np.array([px, pz]) - a) @ ab / L2, 0, 1))
            q = a + ab * u
            dd = float(np.linalg.norm(np.array([px, pz]) - q))
            if best is None or dd < best[0]:
                best = (dd, k if u < 0.5 else k + 1)
        if best is None:
            best = (float(d[i]), i)
        if best[0] < road_half(o, best[1]) + margin:
            return best[1]
        return None
    inside = inside0
    net['inside'] = inside
    ends_on = collections.defaultdict(set)    # X -> {Y}: X ends inside Y
    for xi, r in enumerate(roads):
        for k in (0, -1):
            px, pz = r['P'][k]
            for j in tree.query(Point(px, pz).buffer(60)):
                j = int(j)
                if j == xi:
                    continue
                o = roads[j]
                # not when o merely ends here too (two roads meeting end to end)
                if inside(px, pz, o) is not None:
                    ii = inside(px, pz, o)
                    if ii in (0, len(o['P']) - 1) and min(np.linalg.norm(o['P'][0] - r['P'][k]), np.linalg.norm(o['P'][-1] - r['P'][k])) < 2:
                        continue
                    ends_on[xi].add(j)
    key = []
    for r in roads:
        cls = RANK_CLASS.get(r['hw'], 6)
        key.append((cls, -float(r['lanes'].max()), -r['L'], r['label']))
    n = len(roads)
    # mutual "ends on" relations (two pieces of a junction ending in each other) are left to the key: drop the edges
    # inside each strongly connected group
    comp = scc(n, {y: set(x for x in range(n) if y in ends_on.get(x, ())) for y in range(n)})
    indeg = [0] * n
    succ = collections.defaultdict(set)
    for x, ys in ends_on.items():
        for y in ys:
            if comp[x] == comp[y]:
                continue
            if x not in succ[y]:
                succ[y].add(x)
                indeg[x] += 1
    heap = [(key[i], i) for i in range(n) if indeg[i] == 0]
    heapq.heapify(heap)
    order = []
    done = [False] * n
    broken = 0
    while len(order) < n:
        if not heap:
            rest = [i for i in range(n) if not done[i]]
            i = min(rest, key=lambda i: key[i])
            indeg[i] = 0
            heapq.heappush(heap, (key[i], i))
            broken += 1
        _, i = heapq.heappop(heap)
        if done[i]:
            continue
        done[i] = True
        order.append(i)
        for x in succ[i]:
            indeg[x] -= 1
            if indeg[x] == 0 and not done[x]:
                heapq.heappush(heap, (key[x], x))
    for rk, i in enumerate(order):
        roads[i]['rank'] = rk
    net['rank_cycles'] = broken
    bad = sum(1 for x, ys in ends_on.items() for y in ys if roads[y]['rank'] > roads[x]['rank'])
    net['ends_on_smaller'] = bad
    net['ends_on'] = ends_on
    # junction heights: smaller roads pinned to the bigger ones they touch (biggest first)
    for i in order:
        r = roads[i]
        P = r['P']
        pin = np.full(len(P), np.nan)
        cand = [int(j) for j in tree.query(lines[i].buffer(80)) if int(j) != i and roads[int(j)]['rank'] < r['rank']]
        for k in range(len(P)):
            for j in cand:
                o = roads[j]
                ii = inside(P[k][0], P[k][1], o, margin=2.0)
                if ii is not None:
                    pin[k] = o['y'][ii]
                    break
        ok = np.isfinite(pin)
        if not ok.any():
            continue
        y = r['y'].copy()
        delta = np.zeros(len(P))
        delta[ok] = pin[ok] - y[ok]
        # ease the nearest pin's delta out over PIN_EASE
        c = r['c']
        pinned = np.where(ok)[0]
        for k in range(len(P)):
            if ok[k]:
                continue
            j = pinned[np.argmin(np.abs(c[pinned] - c[k]))]
            dist = abs(c[j] - c[k])
            if dist < PIN_EASE:
                u = dist / PIN_EASE
                delta[k] = delta[j] * (1 - u * u * (3 - 2 * u))
        r['y'] = y + delta
    # roundabout arms flat onto the ring's height is done by YangonRoads (eased arms); medians
    route_cw = []
    for r in roads:
        route_cw.append(r['main'])
    for i, r in enumerate(roads):
        n = len(r['P'])
        mb = np.where(r['lm'] > 1.2, r['lm'], 0.0)
        mb = np.where(r['cut'], 0.0, mb)
        c = r['c']
        if mb.any():
            cand = [int(j) for j in tree.query(lines[i].buffer(120)) if int(j) != i and roads[int(j)]['main']]
            for k in range(n):
                if mb[k] == 0:
                    continue
                px, pz = r['P'][k]
                for j in cand:
                    if inside(px, pz, roads[j], margin=OPEN_R) is not None:
                        mb[k] = 0
                        break
                if mb[k]:
                    for R in rings:
                        if np.linalg.norm(r['P'][k] - R['c']) < R['r_out'] + 30:
                            mb[k] = 0
                            break
                # beside a cut (a deck's gore)
                if mb[k]:
                    lo, hi = max(0, k - 3), min(n, k + 4)
                    if r['cut'][lo:hi].any():
                        mb[k] = 0
            # median runs (owner's bug 1, 17 Nov: a long kerbed sliver where OSM's carriageways converge):
            # a run keeps ONE width (its median), ends where the real gap falls under 3/4 of it or under
            # MED_CUT (no easing into a median), runs shorter than MIN_MEDIAN go, and each end is a blunt nose
            mb = med_runs(mb, c)
        r['mb'] = mb
    # decks: the road widens at the gores to the deck + side lanes
    for dk in decks:
        r = dk['road']
        dh = 2 * DECK_LANE_W                 # 2 + 2 on the deck
        if not dk['sides']:
            # (J14, owner: Shwedagon Pagoda Rd over the railway at Phaya Lan) a bridge with no ground lanes beside it
            # carries its road's own full width, lanes and median: no gore widening, no narrowing
            dk['own'] = True
            # each side capped at its lanes x lane width + median (a fork's / an absorb's widening is not the bridge)
            cap = r['lanes'] * r['lw'] + r['mb'] + r['lm']
            r['dwl'], r['dwr'] = np.minimum(r['wl'], cap), np.minimum(r['wr'], cap)
            dh = float(max(r['dwl'][dk['from']:dk['to'] + 1].max(), r['dwr'][dk['from']:dk['to'] + 1].max()))
            dk['half'] = dh
            dk['from_half'] = dk['to_half'] = dh
            continue
        dk['half'] = dh
        side_w = 0.0
        for o in dk['sides']:
            side_w = max(side_w, float((o['wl'] + o['wr']).max()))
        # (J29, double_junction: the side lanes' deck-side walk + kerb (SIDE_INNER_WALK) lay on the deck's foot: kerbs
        # buried under the deck slab, pavement in it) the gore leaves room for that walk, as `need` below does mid-deck
        gore = dh + side_w + SIDE_INNER_WALK
        for end in ('from', 'to'):
            i = dk[end]
            for k in range(len(r['P'])):
                dist = abs(r['c'][k] - r['c'][i])
                if r['cut'][k] or dist > 150:
                    continue
                u = 1 - dist / 150
                u = u * u * (3 - 2 * u)
                for side in ('wl', 'wr'):
                    r[side][k] = max(r[side][k], r[side][k] + (gore - r[side][k]) * u)
            dk[end + '_half'] = gore
        # the side lanes clear of the deck (OSM draws the ground lanes under its edge): pushed out sideways
        DL = LineString(r['P'][dk['from']:dk['to'] + 1])
        for o in dk['sides']:
            mv = np.zeros_like(o['P'])
            for k in range(len(o['P'])):
                pt = Point(o['P'][k])
                t = DL.project(pt)
                f = np.array(DL.interpolate(t).coords[0])
                v = o['P'][k] - f
                dd = float(np.linalg.norm(v))
                need = dh + float(o['wl'][k] + o['wr'][k]) / 2 + 1.0
                if 0 < t < DL.length and dd < need and dd > 1e-6:
                    mv[k] = v / dd * (need - dd)
            kk = 6
            if len(mv) > 2 * kk + 1:
                for cc in (0, 1):
                    mv[:, cc] = np.convolve(np.pad(mv[:, cc], kk, mode='edge'), np.ones(2 * kk + 1) / (2 * kk + 1), mode='valid')
            o['P'] = o['P'] + mv
        # the side lanes start / end square on the cut ends
        for o in dk['sides']:
            D = dirs(r['P'])
            Rt = rights(D)
            for end in (0, -1):
                q = o['P'][end]
                i = dk['from'] if np.linalg.norm(q - r['P'][dk['from']]) < np.linalg.norm(q - r['P'][dk['to']]) else dk['to']
                side = 1 if (q - r['P'][i]) @ Rt[i] > 0 else -1
                half = float((o['wl'][end] + o['wr'][end]) / 2)
                target = r['P'][i] + Rt[i] * side * (gore - half)
                mv = target - q
                c = o['c']
                L = min(120.0, c[-1] / 2)
                for k in range(len(o['P'])):
                    dist = c[k] - c[0] if end == 0 else c[-1] - c[k]
                    if dist < L:
                        u = dist / L
                        o['P'][k] = o['P'][k] + mv * (1 - u * u * (3 - 2 * u))
                o['y'][end] = r['y'][i]
                o['y'] = o['y']
                o.setdefault('onEnd', {})['start' if end == 0 else 'end'] = (r, i)
                o['sideOf'] = r
                o['sideSign'] = side
    return net


# ------------------------------------------------------------------------------------------------ 7. write
def turn_runs(net):
    """OSM turn:lanes -> per road [{i, dir, lanes: [kinds], offs: [studs right of the travel direction]}], the arrows
    about 24 studs before the tagged way's end (where it reaches its junction)"""
    roads = [r for r in net['roads'] if r['main']]
    out = {}
    for e in net['edges']:
        t = e.t
        jobs = []
        if e.oneway and t.get('turn:lanes'):
            jobs.append((t['turn:lanes'], e.P))
        if not e.oneway:
            if t.get('turn:lanes:forward'):
                jobs.append((t['turn:lanes:forward'], e.P))
            if t.get('turn:lanes:backward'):
                jobs.append((t['turn:lanes:backward'], e.P[::-1]))
        for tag, Pt in jobs:
            if len(Pt) < 2:
                continue
            end = Pt[-1]
            dend = Pt[-1] - Pt[-2]
            dend = dend / max(np.linalg.norm(dend), 1e-9)
            best = None
            for r in roads:
                d = np.linalg.norm(r['P'] - end, axis=1)
                i = int(np.argmin(d))
                if d[i] < 40 and (best is None or d[i] < best[0]) and not r['cut'][i]:
                    best = (d[i], r, i)
            if best is None:
                continue
            _, r, i = best
            D = dirs(r['P'])
            sg = 1 if float(D[i] @ dend) > 0 else -1
            i = int(np.clip(i - sg * 3, 0, len(r['P']) - 1))
            lanes = [x for x in tag.split('|')]
            n = len(lanes)
            if sg > 0:
                half = float(r['wr'][i])
                lm = float(r['lm'][i])
            else:
                half = float(r['wl'][i])
                lm = float(r['lm'][i])
            if r['oneway']:
                W = float(r['wl'][i] + r['wr'][i]) / n
                offs = [-float(r['wl'][i]) + W * (k + 0.5) for k in range(n)]
            else:
                W = (half - lm) / n
                offs = [lm + W * (k + 0.5) for k in range(n)]
            out.setdefault(id(r), []).append(dict(i=i, dir=sg, lanes=lanes, offs=[round(o, 2) for o in offs]))
    return out



def write(net):
    roads, rings, decks = net['roads'], net['rings'], net['decks']
    region = net['region']
    bnd = region.boundary
    out_roads = []
    cut = {}
    names = set()
    # side lanes: ranks just under their road
    nth = collections.Counter()  # several side lanes on one side of a road (Kabar Aye Pagoda Road #4-#6): unique ranks
    for r in roads:
        if r.get('sideOf') is not None:
            key = (id(r['sideOf']), r['sideSign'] > 0)
            r['rank'] = round(r['sideOf']['rank'] + 0.1 + 0.1 * (r['sideSign'] > 0) + 0.01 * nth[key], 4)
            nth[key] += 1
    turns = turn_runs(net)
    for r in sorted(roads, key=lambda r: r['rank']):
        P = r['P']
        D = dirs(P)
        y = r['y']
        s = []
        for i in range(len(P)):
            s.append([round(float(P[i][0]), 2), round(float(y[i]), 2), round(float(P[i][1]), 2),
                      round(float(D[i][0]), 4), round(float(D[i][1]), 4), 0,
                      round(float(r['wl'][i]), 2), round(float(r['wr'][i]), 2), round(float(r['mb'][i]), 2),
                      int(r['lanes'][i]), round(float(r['lw'][i]), 2), round(float(r['lm'][i]), 2)])
        side = r.get('sideOf') is not None
        kind = 'side' if side else ('route' if r['main'] else 'street')
        half = float(min(np.min(r['wl'][~r['cut']]) if (~r['cut']).any() else r['wl'].min(),
                         np.min(r['wr'][~r['cut']]) if (~r['cut']).any() else r['wr'].min()))
        name = r['label']
        assert name not in names
        names.add(name)
        rec = dict(name=name, kind=kind, closed=False, rank=r['rank'], half=round(half, 2), s=s,
                   hw=r['hw'], walkL=r['walk'], walkR=r['walk'], lanes=int(r['lanes'].max()),
                   median=round(float(r['lm'].max()), 2), laneW=round(float(np.median(r['lw'])), 2), oneway=r['oneway'])
        if side:
            rec['walkL' if r['sideSign'] > 0 else 'walkR'] = SIDE_INNER_WALK
            if 'start' in r.get('onEnd', {}):
                rec['startsOnEnd'] = r['onEnd']['start'][0]['label']
            if 'end' in r.get('onEnd', {}):
                rec['endsOnEnd'] = r['onEnd']['end'][0]['label']
        if bnd.distance(Point(P[0])) < 1.0:
            rec['edgeStart'] = True
        if bnd.distance(Point(P[-1])) < 1.0:
            rec['edgeEnd'] = True
        # (the data's cut lists only the decks' runs: YangonRoads cuts the roundabouts' insides itself, R_OUT - 14)
        dcut = r['cut'] & ~r.get('ringcut', np.zeros(len(P), bool))
        if dcut.any():
            cut[name] = [int(i) for i in np.where(dcut)[0]]
        if turns.get(id(r)):
            rec['turn'] = turns[id(r)]
        out_roads.append(rec)
    out_decks = []
    for k, dk in enumerate(decks):
        r = dk['road']
        D = dirs(r['P'])
        s = []
        for q, i in enumerate(range(dk['from'], dk['to'] + 1)):
            if dk.get('own'):
                s.append([round(float(r['P'][i][0]), 2), round(float(dk['y'][q]), 2), round(float(r['P'][i][1]), 2),
                          round(float(D[i][0]), 4), round(float(D[i][1]), 4), 0, round(float(r['dwl'][i]), 2),
                          round(float(r['dwr'][i]), 2), round(float(r['mb'][i]), 2), int(r['lanes'][i]),
                          round(float(r['lw'][i]), 2), round(float(r['lm'][i]), 2)])
                continue
            s.append([round(float(r['P'][i][0]), 2), round(float(dk['y'][q]), 2), round(float(r['P'][i][1]), 2),
                      round(float(D[i][0]), 4), round(float(D[i][1]), 4), 0, dk['half'], dk['half'], 0, 2, DECK_LANE_W, 0])
        nm = '%s Flyover' % (r['name'] or 'Road')
        base, kk = nm, 1
        while any(d['name'] == nm for d in out_decks):  # (the same " #k" YangonRoads.load gives a repeated name)
            kk += 1
            nm = '%s #%d' % (base, kk)
        prev = [d for d in out_decks if d['of'] == r['label'] and d['from'] <= dk['to'] and dk['from'] <= d['to']]
        if prev:
            print('WARNING decks overlap on', r['label'], prev[0]['from'], prev[0]['to'], dk['from'], dk['to'])
        out_decks.append(dict(name=nm, of=r['label'], half=dk['half'],
                              sides=[o['label'] for o in dk['sides']], **{'from': dk['from'], 'to': dk['to']}, s=s))
    out_rings = []
    for k, R in enumerate(rings):
        arms = set()
        for r in roads:
            for q in (r['P'][0], r['P'][-1]):
                if np.linalg.norm(q - R['c']) < R['r_out']:
                    arms.add(r['label'])
        nm = 'Roundabout %d' % (k + 1)
        for a in sorted(arms):
            if 'Hanthawaddy' in a:
                nm = 'Hanthawaddy Roundabout'
        out_rings.append(dict(name=nm, c=[round(float(R['c'][0]), 2), round(R['y'], 2), round(float(R['c'][1]), 2)],
                              rc=round(R['rc'], 2), r_in=round(R['r_in'], 2), r_out=round(R['r_out'], 2),
                              lanes=R['lanes'], laneW=R['laneW'], arms=sorted(arms)))
    # driveway mouths (places_1to1.py driveways.json: fuel entries / exits): YangonRoads drops the kerb there
    drives = []
    for t in net['tags']:
        p = os.path.join(geo.BUILD, 'city_1to1', 'places_%s' % t, 'driveways.json')
        if os.path.exists(p):
            for d in json.load(open(p)):
                drives.append(dict(x=round(d['at'][0], 2), z=round(d['at'][1], 2), hw=round(geo.m(d['width_m']) / 2, 2),
                                   kind=d['kind']))
    data = dict(roads=out_roads, cut=cut, decks=out_decks, roundabouts=out_rings, driveways=drives, spm=geo.SPM,
                ox=geo.OX, oz=geo.OZ, tags=net['tags'],
                note='roads05.py (%s): the 1:1 districts %s in the batch 0.5 format (v5 sample fields; roundabouts list)'
                     % ('16 Nov 2026', '+'.join(net['tags'])))
    od = out_dir(net['tags'])
    os.makedirs(od, exist_ok=True)
    txt = json.dumps(data, separators=(',', ':'))
    open(os.path.join(od, 'roads.json'), 'w', encoding='utf-8').write(txt)
    # Studio modules (YangonData.Roads05_<k>)
    for f in os.listdir(od):
        if f.startswith('Roads05_') and f.endswith('.luau'):
            os.remove(os.path.join(od, f))
    k = 0
    for a in range(0, len(txt), CHUNK):
        k += 1
        part = txt[a:a + CHUNK]
        assert ']==]' not in part
        open(os.path.join(od, 'Roads05_%d.luau' % k), 'w', encoding='utf-8').write('return [==[' + part + ']==]')
    ranks = [r['rank'] for r in out_roads]
    st = dict(net['stats'])
    st.update(roads=len(out_roads), routes=sum(1 for r in out_roads if r['kind'] == 'route'),
              streets=sum(1 for r in out_roads if r['kind'] == 'street'), sides=sum(1 for r in out_roads if r['kind'] == 'side'),
              km=round(sum(chain(np.array([[q[0], q[2]] for q in r['s']]))[-1] for r in out_roads) / geo.SPM / 1000, 2),
              samples=sum(len(r['s']) for r in out_roads), decks=len(out_decks), roundabouts=len(out_rings),
              ranks_unique=len(set(ranks)) == len(ranks), rank_cycles_broken=net['rank_cycles'],
              ends_on_smaller=net['ends_on_smaller'], dropped_fillers=net.get('dropped_fillers'), json_chars=len(txt), modules=k,
              divided_roads=sum(1 for r in out_roads if r['median'] > 1.2), decks_dropped=net.get('decks_dropped', []))
    json.dump(st, open(os.path.join(od, 'stats.json'), 'w'), indent=1)
    return data, st


if __name__ == '__main__':
    tags = sys.argv[1:] or ['P1']
    net = build(tags)
    net = finish(net)
    data, st = write(net)
    print(json.dumps(st, indent=1))
