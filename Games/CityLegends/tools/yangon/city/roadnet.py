"""Whole-Yangon map (14 Nov 2026): the real road network of a batch (1 west, 2 downtown, 3 east) for roads.py.

From build/osm_ygn/roads.json (OpenStreetMap contributors, ODbL). Every public road: trunk .. residential, living_street,
the links, and service roads only when named or service=alley; never access=private/no.

Cross-sections (owner: "some are 4 lane and 6 lane and 2 lane but ingame theyre different"; master plan decision 2):
  lanes each way from the OSM tags (one-way: `lanes`, a one-way tagged 5+ is the road's total and is halved; two-way:
  lanes:forward / backward, else lanes / 2), capped at 3; untagged: trunk / primary / secondary 2, tertiary / links /
  streets 1.
  1 lane a side: half 10 (narrow lanes: living streets, width < 5.5 m, alleys: half 8; a one-way street: 8)
  2 lanes a side: 16 studs a lane;  3 lanes a side: 13 studs a lane
  divided: a dual carriageway is two one-way OSM ways. Where two one-way ways of the same road run 6..PAIR_MAX studs apart
  in opposite directions (the partner on the left, right-hand traffic), both are moved onto their midline and each
  carriageway runs from MED (the median's half, 3) to MED + n x lane width on its right; elsewhere they stay two one-way
  carriageways on their own lines. The move is smoothed along each way and shared at nodes, so every road ending on a
  moved way moves with it.
Topology: OSM ways split at every node shared by two ways (nodes matched by their exact coordinates).
Clipping: the batch outline (geo.batch_poly) minus batch 0.5 (BOX_05 and the v4/v5 game roads' corridors). A road that
continues a v4 game road's map-edge end (edgeStart / edgeEnd) is cut or extended to end EXACTLY on that end (position,
direction, height, the v5 cross-section).

    net = build(tag)   -> Net (edges, nodes, seams, region, ...)
"""
import json, math, os, re

import numpy as np
from shapely.geometry import LineString, Point, Polygon, MultiLineString, box as sbox
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo

STEP = 8.0 * geo.LK   # (geo.LK: 1.0 at the default scale; the 1:1 rebuild keeps these lengths in metres)
MED = 3.0             # median half (kerbs included), master plan / v5
PAIR_MAX = 45.0       # two one-way ways this close (centre to centre) are one divided road
PAIR_MIN = 6.0 * geo.LK
TAPER = 48.0 * geo.LK # studs over which a move fades at a node / where pairing stops
if geo.ONE_TO_ONE:
    PAIR_MAX = geo.m(26.0)   # Pyay Road along Inya Lake: its two OSM lines 23.8 m apart (the real planted median)
MED_MIN = 1.5         # (1:1) the narrowest median half: a 1 m barrier between kerbs

PUBLIC = {'trunk', 'primary', 'secondary', 'tertiary', 'unclassified', 'residential', 'living_street', 'trunk_link',
          'primary_link', 'secondary_link', 'tertiary_link', 'motorway', 'motorway_link', 'road'}
MAIN = {'motorway', 'trunk', 'primary', 'secondary', 'tertiary'}
LINKS = {'motorway_link', 'trunk_link', 'primary_link', 'secondary_link', 'tertiary_link'}
RANK = {'motorway': 0, 'trunk': 0, 'primary': 1, 'secondary': 2, 'tertiary': 3, 'motorway_link': 4, 'trunk_link': 4,
        'primary_link': 4, 'secondary_link': 4, 'tertiary_link': 5, 'unclassified': 6, 'residential': 6, 'road': 6,
        'living_street': 7, 'service': 8}
LANE_W = {1: 10.0, 2: 16.0, 3: 13.0}
# OSM way ids built whole past the batch outline (a bridge leaving over a river to land where no batch lies)
REACH_OUT = {'2': (1219935185,)}
# (2026-11-14, batch 2) a roundabout round a landmark: its centre line pushed out radially to at least rmin from the
# landmark's centre (the game's wider lanes ran the inner lane through Sule Pagoda's ring of shops, radius 66 + its gates:
# OSM's ring is 73-94 from the stupa, the carriageway 19.5 a side), and its lanes narrowed to lane_w (City Hall stands
# 103 studs from Sule at the roundabout's north-east: 3 lanes of 13 plus pavements could not fit between them); the roads
# meeting it move their end with it
ROUND_FIT = {'2': [dict(name='Sule Roundabout', centre=(33200.0, 8066.0), rmin=87.0, lane_w=10.0)]}


def round_fit(edges, tag):
    for R in ROUND_FIT.get(tag, ()):
        cx, cz = R['centre']
        rmin = R['rmin']
        ring = [e for e in edges if e.name == R['name']]
        keys = {e.a for e in ring} | {e.b for e in ring}

        def push(P):
            d = P - np.array([cx, cz])
            r = np.hypot(d[:, 0], d[:, 1])
            k = (r < rmin) & (r > 1e-6)
            P = P.copy()
            P[k] = np.array([cx, cz]) + d[k] * (rmin / r[k])[:, None]
            return P
        for e in ring:
            e.P0 = densify(push(e.P0))
            if R.get('lane_w'):
                e.Wf = R['lane_w']
                if not e.oneway:
                    e.Wb = R['lane_w']
        for e in edges:
            if e in ring:
                continue
            if e.a in keys:
                e.P0 = e.P0.copy()
                e.P0[0] = push(e.P0[:1])[0]
            if e.b in keys:
                e.P0 = e.P0.copy()
                e.P0[-1] = push(e.P0[-1:])[0]


def _num(t, k):
    v = t.get(k)
    if v is None:
        return None
    try:
        return float(str(v).split(';')[0].strip())
    except ValueError:
        return None


def width_m(t):
    try:
        return float(str(t.get('width', '')).lower().replace('m', '').strip())
    except ValueError:
        return None


def oneway_of(t):
    o = str(t.get('oneway', '')).lower()
    if o in ('yes', 'true', '1'):
        return 1
    if o == '-1':
        return -1
    if t.get('junction') in ('roundabout', 'circular') and o != 'no':
        return 1
    if t.get('highway') in ('motorway', 'motorway_link') and o != 'no':
        return 1
    return 0


# ---------------------------------------------------------------- 1:1 cross-sections (2026-11-16, rescale step 3)
# Owner's road rule "1:1 EXACT" (vault "Audit - Yangon roads 1 to 1", decisions 1, 2, 4): kerbs on their real lines; lanes
# 12 studs where they fit, otherwise the real carriageway width / the lane count, never under 10; real lane counts (up to
# 4 a side); each carriageway of a divided road on its own OSM line, the median its real width (pair_edges: e.med).
LANE_MIN, LANE_MAX = 10.0, 12.0
LANE_REAL_M = 3.5     # an unmeasured main road's lane (the audit's measured lanes are 3.0-3.8 m; the plan's 3.5 m)
LANE_CAP_1TO1 = 4     # audit item 4: one-way lanes=4 roads keep their 4th lane
# measured carriageways: (normalised name, bridge) -> (lanes a side, kerb to kerb of ONE carriageway in metres); trunk and
# primary ways here, secondary ways in REAL_XS_SECONDARY (Kabar Aye's secondary ways are the flyover's ground lanes)
REAL_XS = {
    ('kabarayepagoda', False): (3, 9.25),   # road_04 (16.8406): ~19.5 m kerb to kerb, 3+3 at ~3.1 m, ~1 m barrier
    ('kabarayepagoda', True): (2, 8.0),     # junc_06, the flyover by Myanmar Plaza: deck ~17 m, 2+2 (OSM says 4 a side)
    ('pyay', False): (3, 11.5),             # road_01 (Inya Lake): 2 x ~11.5 m, 3+3, 12-14 m planted median
}
REAL_XS_SECONDARY = {
    ('uwisara', False): (2, 7.5),           # road_22 (16.8084): ~20 m with a ~5 m tree median, 2+2
    ('kabarayepagoda', False): (1, 4.0),    # junc_06: the ground lanes beside the flyover, one narrow lane a side
}
WALK_1TO1 = dict(main=7.5, street=4.0, narrow=3.0)   # pavement 2.5 m on main roads (audit item 14); flush strips
# (2026-11-16, P1 road fixes) OSM ways built as paving instead of road, per pilot. P1: the Myanmar Centre junction's second
# slip (Kabar Aye Pagoda Road northbound -> the road east, 1513604988 + 730091070, both untagged primary_link) ran between
# the mall and its corner plaza and made the plaza an island; the real plaza joins the mall's corner (MC refit note), and
# the right turn there keeps its other slip (317877729, lanes=1).
PAVED_WAYS = {'P1': (1513604988, 730091070)}


def cross_section_1to1(t):
    hw = t.get('highway')
    one = oneway_of(t)
    total, fw, bw = _num(t, 'lanes'), _num(t, 'lanes:forward'), _num(t, 'lanes:backward')
    w = width_m(t)
    narrow = (hw == 'living_street' or hw == 'service' or (w is not None and w < 5.5)) and hw not in MAIN | LINKS
    dflt = 2 if hw in ('trunk', 'primary', 'motorway', 'secondary') else 1
    tagged = total is not None or fw is not None
    if one:
        n = total if total is not None else (fw if fw is not None else dflt)
        if n >= 5:
            n = n / 2
        nf, nb = n, 0
    else:
        if fw is not None or bw is not None:
            nf = fw if fw is not None else ((total - bw) if total is not None and bw is not None else dflt)
            nb = bw if bw is not None else ((total - fw) if total is not None and fw is not None else dflt)
        elif total is not None:
            nf = nb = max(1.0, total / 2)
        else:
            nf = nb = dflt
    cap = LANE_CAP_1TO1
    nf = int(max(1, min(cap, round(nf + 1e-6)))) if nf else 0
    nb = int(max(1, min(cap, round(nb + 1e-6)))) if (nb or not one) else 0
    if not one:
        nb = max(nb, 1)
    bridge = t.get('bridge') not in (None, 'no')
    table = REAL_XS if hw in ('trunk', 'primary') else (REAL_XS_SECONDARY if hw == 'secondary' else {})
    meas = table.get((norm_name(t.get('name:en') or t.get('name') or ''), bridge))
    if meas:
        nf = meas[0]
        if not one:
            nb = meas[0]
    ring = t.get('junction') in ('roundabout', 'circular')
    if ring and not tagged and hw in ('trunk', 'primary') and one:
        nf = 3                       # Hanthawaddy: one untagged piece of a 3-lane ring (audit item 6)
    main = hw in MAIN or hw in LINKS or max(nf, nb) >= 2
    look = 'main' if main else ('narrow' if narrow else 'street')

    def lw(n):
        if n == 0:
            return 0.0
        if meas:
            return float(min(LANE_MAX, max(LANE_MIN, geo.m(meas[1]) / n)))
        if ring:
            return LANE_MAX          # Hanthawaddy: a 3-lane ring ~14 m wide
        if main:
            return float(min(LANE_MAX, max(LANE_MIN, geo.m(LANE_REAL_M))))
        if narrow:
            # an alley / living street: one shared lane, its real width (a 4 m alley when untagged), at least 10 studs
            tot = max(LANE_MIN, geo.m(w if w else 4.0))
            return tot if one else tot / 2
        if one:
            return LANE_MAX          # a one-way street lane: 3.5-4 m
        return float(min(LANE_MAX, max(LANE_MIN, geo.m(w) / 2 if w else LANE_MIN)))
    traffic = max(nf, nb) >= 2 or hw in MAIN or hw in LINKS
    walk = WALK_1TO1[look]
    return dict(oneway=one, nf=nf, nb=nb, Wf=lw(nf), Wb=lw(nb), look=look, walk=walk, traffic=traffic, tagged=tagged,
                measured=bool(meas))


def cross_section(t):
    """-> dict: oneway, nf, nb (lanes forward / backward; 0 for a one-way's back), Wf, Wb, look, walk, traffic"""
    if geo.ONE_TO_ONE:
        return cross_section_1to1(t)
    hw = t.get('highway')
    one = oneway_of(t)
    total, fw, bw = _num(t, 'lanes'), _num(t, 'lanes:forward'), _num(t, 'lanes:backward')
    w = width_m(t)
    narrow = (hw == 'living_street' or hw == 'service' or (w is not None and w < 5.5)) and hw not in MAIN | LINKS
    if hw in ('trunk', 'primary', 'motorway'):
        dflt = 2
    elif hw == 'secondary':
        dflt = 2
    else:
        dflt = 1
    tagged = total is not None or fw is not None
    if one:
        n = total if total is not None else (fw if fw is not None else dflt)
        if n >= 5:
            n = n / 2
        nf, nb = n, 0
    else:
        if fw is not None or bw is not None:
            nf = fw if fw is not None else ((total - bw) if total is not None and bw is not None else dflt)
            nb = bw if bw is not None else ((total - fw) if total is not None and fw is not None else dflt)
        elif total is not None:
            nf = nb = max(1.0, total / 2)
        else:
            nf = nb = dflt
    nf = int(max(1, min(3, round(nf + 1e-6)))) if nf else 0
    nb = int(max(1, min(3, round(nb + 1e-6)))) if (nb or not one) else 0
    if not one:
        nb = max(nb, 1)
    main = hw in MAIN or hw in LINKS or max(nf, nb) >= 2
    look = 'main' if main else ('narrow' if narrow else 'street')

    def lw(n):
        if n == 0:
            return 0.0
        if n == 1:
            if one:
                return 16.0 if main else 16.0 if not narrow else 12.0
            return 10.0 if not narrow else 8.0
        return LANE_W[n]
    traffic = max(nf, nb) >= 2 or hw in MAIN or hw in LINKS
    walk = 6.0 if main else (4.0 if look == 'street' else 3.0)
    return dict(oneway=one, nf=nf, nb=nb, Wf=lw(nf), Wb=lw(nb), look=look, walk=walk, traffic=traffic, tagged=tagged)


def norm_name(s):
    if not s:
        return ''
    s = s.lower()
    s = re.sub(r'\b(north|south|east|west|a|b)\b', '', s)
    s = re.sub(r'\b(road|rd|street|st|lane|avenue)\b', '', s)
    return re.sub(r'[^a-z0-9]', '', s)


def densify(pts, step=STEP):
    ls = LineString(pts)
    L = ls.length
    n = max(1, int(math.ceil(L / step)))
    return np.array([ls.interpolate(L * i / n).coords[0] for i in range(n + 1)])


def dirs_of(P):
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


def chain(P):
    return np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]


class Edge:
    """an OSM way piece between two shared nodes: P (N x 2 world studs, every <= 8), D (unit directions), w (pair
    weight per sample: 1 = a divided road's carriageway on its midline), y / g (surface / ground studs)"""


class Net:
    pass


def _node_key(p):
    return (int(round(p[0] * 1e7)), int(round(p[1] * 1e7)))


def load_edges(area_ll):
    """OSM ways of the public network crossing area_ll (shapely, lon/lat), split at shared nodes"""
    ways = []
    for r in geo.load('roads'):
        t = r['t']
        hw = t.get('highway')
        if hw == 'service':
            if not (t.get('name') or t.get('name:en') or t.get('service') == 'alley'):
                continue
            if t.get('service') in ('driveway', 'parking_aisle', 'drive-through'):
                continue
        elif hw not in PUBLIC:
            continue
        if t.get('access') in ('private', 'no') or t.get('area') == 'yes' or t.get('motor_vehicle') == 'no':
            continue
        p = r['p']
        if len(p) < 2:
            continue
        xs = [q[0] for q in p]
        ys = [q[1] for q in p]
        bb = area_ll.bounds
        if max(xs) < bb[0] or min(xs) > bb[2] or max(ys) < bb[1] or min(ys) > bb[3]:
            continue
        if not LineString(p).intersects(area_ll):
            continue
        ways.append(r)
    count = {}
    for r in ways:
        for i, q in enumerate(r['p']):
            k = _node_key(q)
            count[k] = count.get(k, 0) + (2 if i in (0, len(r['p']) - 1) else 1)
    edges = []
    for r in ways:
        t = r['t']
        p = r['p']
        cs = cross_section(t)
        if cs['oneway'] == -1:
            p = p[::-1]
            cs['oneway'] = 1
        cuts = [0] + [i for i in range(1, len(p) - 1) if count[_node_key(p[i])] >= 2] + [len(p) - 1]
        for a, b in zip(cuts, cuts[1:]):
            seg = p[a:b + 1]
            if len(seg) < 2:
                continue
            e = Edge()
            e.wid = r['id']
            e.tags = t
            e.name = t.get('name:en') or t.get('name') or ''
            e.hw = t.get('highway')
            e.rank = RANK.get(e.hw, 6)
            for k, v in cs.items():
                if k not in ('tagged', 'measured'):
                    setattr(e, k, v)
            e.cs = cs
            e.bridge = t.get('bridge') not in (None, 'no')
            try:
                e.layer = int(float(t.get('layer', 1 if e.bridge else 0)))
            except ValueError:
                e.layer = 1 if e.bridge else 0
            if e.bridge and e.layer < 1:
                e.layer = 1
            e.tunnel = t.get('tunnel') not in (None, 'no')
            e.a = _node_key(seg[0])
            e.b = _node_key(seg[-1])
            W = geo.proj(seg)
            if LineString(W).length < 0.5:
                continue
            e.P0 = densify(W)
            e.seam = [None, None]
            e.cut = [False, False]
            e.dead = False
            edges.append(e)
    for i, e in enumerate(edges):
        e.id = i
    return edges


# ---------------------------------------------------------------- bridges and their ramps
def node_map(edges):
    nodes = {}
    for e in edges:
        nodes.setdefault(e.a, []).append((e.id, 0))
        nodes.setdefault(e.b, []).append((e.id, -1))
    return nodes


def family_ids(edges, nodes, ext_max=450.0 * geo.LK):
    """bridge / layer >= 1 edges, grown along the road they continue (through nodes where only that road meets) up to
    ext_max studs (their ramps): ids"""
    f0 = {e.id for e in edges if (e.bridge or e.layer >= 1) and not e.tunnel}
    fam = set(f0)
    stack = [(key, eid, 0.0) for eid in f0 for key in (edges[eid].a, edges[eid].b)]
    while stack:
        key, came, ext = stack.pop()
        inc = nodes.get(key, [])
        if len(inc) != 2:
            continue
        other = [x for x, _ in inc if x != came]
        if not other or other[0] in fam:
            continue
        f = other[0]
        ln = float(chain(edges[f].P0 if not hasattr(edges[f], 'P') else edges[f].P)[-1])
        if ext + ln > ext_max:
            continue
        fam.add(f)
        e2 = edges[f]
        stack.append((e2.b if e2.a == key else e2.a, f, ext + ln))
    return fam


def side_extent(e, side):
    """how far the carriageway reaches to the right (side 1) / left (side -1) of the OSM line (before moves)"""
    if e.oneway:
        return e.nf * e.Wf / 2
    return e.nf * e.Wf if side > 0 else e.nb * e.Wb


def push_beside(edges, fam, gap=3.0 * geo.LK, reach=80.0 * geo.LK):
    """a ground road running beside a flyover / its ramps (within 30 degrees) is moved sideways until its carriageway
    clears the deck (+ parapet + gap): in the game the lanes are wider than real ones, so OSM's at-grade lanes would
    sit under the ramps"""
    fl = [(edges[i], LineString(edges[i].P0)) for i in fam]
    if not fl:
        return 0
    tree = STRtree([L for _, L in fl])
    moved = 0
    if geo.ONE_TO_ONE:
        # (1:1) the lanes are real, so only real overlaps move: a 1-stud gap past the parapet, and the road's own carriageways
        # that run on from a ramp's foot (same name, sharing a node with the family) stay on their OSM lines
        gap = 1.0
        fnodes = {k for i in fam for k in (edges[i].a, edges[i].b)}
        fnames = {norm_name(edges[i].name) for i in fam if edges[i].name}
    for e in edges:
        if e.id in fam or e.tunnel:
            continue
        if geo.ONE_TO_ONE and e.name and norm_name(e.name) in fnames and e.hw in MAIN and (e.a in fnodes or e.b in fnodes):
            continue
        L0 = LineString(e.P0)
        near = [int(j) for j in tree.query(L0.buffer(reach))]
        if not near:
            continue
        D = dirs_of(e.P0)
        push = np.zeros_like(e.P0)
        hit = np.zeros(len(e.P0), bool)
        for i, p in enumerate(e.P0):
            pt = Point(p)
            for j in near:
                f, FL = fl[j]
                d = FL.distance(pt)
                if d > reach:
                    continue
                s_ = FL.project(pt)
                q = np.array(FL.interpolate(s_).coords[0])
                q2 = np.array(FL.interpolate(min(FL.length, s_ + 3)).coords[0])
                q1 = np.array(FL.interpolate(max(0.0, s_ - 3)).coords[0])
                fd = q2 - q1
                if np.linalg.norm(fd) < 1e-6:
                    continue
                fd /= np.linalg.norm(fd)
                if abs(fd @ D[i]) < 0.87:
                    continue
                v = p - q
                if d < 1.0:
                    continue  # right on top: nothing sensible to do (reported by the checks)
                n = v / d
                fright = np.array([-fd[1], fd[0]])
                fside = 1 if n @ fright > 0 else -1
                eright = np.array([-D[i][1], D[i][0]])
                eside = -1 if n @ eright > 0 else 1   # the side of e facing the flyover
                need = side_extent(f, fside) + 1.5 + gap + side_extent(e, eside)
                if need > d:
                    pv = n * (need - d)
                    if np.linalg.norm(pv) > np.linalg.norm(push[i]):
                        push[i] = pv
                        hit[i] = True
        if not hit.any():
            continue
        # smooth: hold the biggest push over +-6 samples, then average +-4
        k = 6
        mag = np.linalg.norm(push, axis=1)
        idx = np.arange(len(mag))
        out = push.copy()
        for i in idx:
            a, b = max(0, i - k), min(len(mag), i + k + 1)
            j = a + int(np.argmax(mag[a:b]))
            out[i] = push[j]
        for c in (0, 1):
            out[:, c] = np.convolve(np.pad(out[:, c], 4, mode='edge'), np.ones(9) / 9, mode='valid')
        e.push = out
        moved += 1
    return moved


# ---------------------------------------------------------------- dual carriageways
def pair_edges(edges, fam=frozenset(), unpair_near=None):
    """per one-way main edge: own move (N x 2) and pair weight w (N), before node blending. Never across a flyover or
    its ramps (fam): the ground carriageways either side of a flyover stay apart."""
    cand = [e for e in edges if e.oneway and e.hw in MAIN]
    lines = [LineString(e.P0) for e in cand]
    tree = STRtree(lines)
    flines = [LineString(edges[i].P0) for i in fam]
    ftree = STRtree(flines) if flines else None
    for e in edges:
        e.own = np.zeros_like(e.P0)
        e.w = np.zeros(len(e.P0))
    stats = dict(cand=len(cand), paired_len=0.0)
    for ci, e in enumerate(cand):
        D = dirs_of(e.P0)
        near = [int(j) for j in tree.query(lines[ci].buffer(PAIR_MAX)) if int(j) != ci]
        if not near:
            continue
        nm = norm_name(e.name)
        raw = np.zeros_like(e.P0)
        gap = np.zeros(len(e.P0))
        ok = np.zeros(len(e.P0), bool)
        for i, p in enumerate(e.P0):
            pt = Point(p)
            best = None
            for j in near:
                f = cand[j]
                fn = norm_name(f.name)
                if nm and fn and nm != fn:
                    continue
                if (not nm or not fn) and RANK[f.hw] != RANK[e.hw]:
                    continue
                L = lines[j]
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
                v = q - p
                right = np.array([-D[i][1], D[i][0]])
                if v @ right > 0:          # partner must lie on the left (right-hand traffic)
                    continue
                if abs(v @ D[i]) > 0.5 * d:
                    continue
                if ftree is not None and not (e.id in fam and f.id in fam):
                    mid = Point(p + v / 2)
                    if any(flines[int(k)].distance(mid) < 0.45 * d for k in ftree.query(mid.buffer(d))):
                        continue
                if best is None or d < best[0]:
                    best = (d, v)
            if best:
                raw[i] = best[1] / 2
                gap[i] = best[0]
                ok[i] = True
        if not ok.any():
            continue
        idx = np.where(ok)[0]
        # fill short gaps, interpolate the move across them
        w = ok.astype(float)
        for k in range(len(idx) - 1):
            a, b = idx[k], idx[k + 1]
            if 1 < b - a <= 7:
                w[a:b + 1] = 1
        full = np.zeros_like(raw)
        full[:, 0] = np.interp(np.arange(len(raw)), idx, raw[idx, 0])
        full[:, 1] = np.interp(np.arange(len(raw)), idx, raw[idx, 1])
        # smooth the weight (+-4 samples), and the move a little
        k = 4
        ws = np.convolve(np.pad(w, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), mode='valid')
        fs = full.copy()
        for c in (0, 1):
            fs[:, c] = np.convolve(np.pad(full[:, c], 3, mode='edge'), np.ones(7) / 7, mode='valid')
        if unpair_near is not None:
            ws = ws * unpair_near(e.P0)
        if geo.ONE_TO_ONE:
            # (1:1) each carriageway stays on its own OSM line: the median half is the real gap's half minus the
            # carriageway's half (offsets: centre = w (med + n W / 2) right of the midline = the OSM line for any w)
            gfull = np.interp(np.arange(len(gap)), idx, gap[idx])
            gfull = np.convolve(np.pad(gfull, 3, mode='edge'), np.ones(7) / 7, mode='valid')
            e.med = np.maximum(MED_MIN, gfull / 2 - e.nf * e.Wf / 2)
        e.w = ws
        e.own = fs * ws[:, None]
        stats['paired_len'] += float((ws > 0.5).sum() * STEP)
    for e in edges:
        if getattr(e, 'push', None) is not None:
            e.own = e.own + e.push
    return stats


UNPAIR_REACH = 120.0     # studs from batch 0.5's box edge over which a divided pair splits back onto its OSM lines
UNPAIR_KEEP = 300.0      # ... except within this of a v5 game road's map-edge end (those seams follow the game road)


def seam_unpair(game):
    """(2026-11-14) batch 0.5's mesh streets keep the OSM one-way lines of a divided road; a batch road merged onto the
    midline met them 12-27 studs off (U Wisara, Kabar Aye Pagoda, Insein). Returns f(P) -> pairing weight factor: 0 on the
    box's edge, 1 from UNPAIR_REACH out, 1 everywhere near a v5 game road's map-edge end."""
    x0, z0, x1, z1 = geo.BOX_05
    gends = np.array([[E['x'], E['z']] for E in seam_ends(game)]) if game else np.zeros((0, 2))

    def f(P):
        P = np.asarray(P)
        dx = np.maximum(np.maximum(x0 - P[:, 0], P[:, 0] - x1), 0)
        dz = np.maximum(np.maximum(z0 - P[:, 1], P[:, 1] - z1), 0)
        d = np.hypot(dx, dz)
        inside = (dx == 0) & (dz == 0)
        d = np.where(inside, 0.0, d)
        fac = np.clip(d / UNPAIR_REACH, 0, 1)
        if len(gends):
            dg = np.min(np.hypot(P[:, None, 0] - gends[None, :, 0], P[:, None, 1] - gends[None, :, 1]), axis=1)
            fac = np.where(dg < UNPAIR_KEEP, 1.0, fac)
        return fac
    return f


def blend_nodes(edges):
    """node moves = mean of the one-way main edges' end moves; every edge eased onto its nodes' moves"""
    acc = {}
    for e in edges:
        if not ((e.oneway and e.hw in MAIN) or getattr(e, 'push', None) is not None):
            continue
        for end, key in ((0, e.a), (-1, e.b)):
            a = acc.setdefault(key, [np.zeros(2), 0.0, 0])
            a[0] += e.own[end]
            a[1] += e.w[end]
            a[2] += 1
    node_move = {k: v[0] / v[2] for k, v in acc.items()}
    node_w = {k: v[1] / v[2] for k, v in acc.items()}
    for e in edges:
        s = chain(e.P0)
        L = s[-1]
        da = node_move.get(e.a, np.zeros(2))
        db = node_move.get(e.b, np.zeros(2))
        T = min(TAPER, L / 2) if L > 1e-6 else 1.0
        wa = np.clip(1 - s / max(T, 1e-6), 0, 1)
        wb = np.clip(1 - (L - s) / max(T, 1e-6), 0, 1)
        if L <= 2 * TAPER:
            wa = 1 - s / max(L, 1e-6)
            wb = s / max(L, 1e-6)
            base = e.own
        else:
            base = e.own
        mv = base + (da - base[0]) * wa[:, None] + (db - base[-1]) * wb[:, None]
        e.P = e.P0 + mv
        if e.oneway and e.hw in MAIN:
            wna, wnb = node_w.get(e.a, e.w[0]), node_w.get(e.b, e.w[-1])
            e.w = e.w + (wna - e.w[0]) * wa + (wnb - e.w[-1]) * wb
            e.w = np.clip(e.w, 0, 1)
        e.paired = e.oneway and e.hw in MAIN and bool((e.w > 0.5).any())


# ---------------------------------------------------------------- cross-section along an edge
def offsets(e):
    """per sample (inner, outer) carriageway offsets right of the edge line, the median side.
    two-way: (-left half, right half); one-way: (c - n W / 2, c + n W / 2) with c = w (MED + n W / 2)"""
    n = len(e.P)
    if e.oneway:
        hw_ = e.nf * e.Wf / 2
        med = getattr(e, 'med', None)
        if med is None or len(med) != n:
            med = MED
        c = e.w * (med + hw_)
        return c - hw_, c + hw_
    return np.full(n, -e.nb * e.Wb), np.full(n, e.nf * e.Wf)


def rights(e):
    return np.stack([-e.D[:, 1], e.D[:, 0]], axis=1)


def strip_poly(e, lo, hi):
    """polygon between offsets lo and hi (arrays or numbers) right of the edge line"""
    R = rights(e)
    lo = np.broadcast_to(lo, (len(e.P),))
    hi = np.broadcast_to(hi, (len(e.P),))
    A = e.P + R * lo[:, None]
    B = e.P + R * hi[:, None]
    ring = np.vstack([A, B[::-1]])
    pg = Polygon(ring)
    if not pg.is_valid:
        pg = pg.buffer(0)
    return pg


def carriageway(e, grow=0.0):
    lo, hi = offsets(e)
    return strip_poly(e, lo - grow, hi + grow)


# ---------------------------------------------------------------- batch 0.5 seam
def game_roads():
    v5 = os.path.join(geo.MAP, 'ygn_roads_v5.json')
    v4 = os.path.join(geo.MAP, 'ygn_roads_v4.json')
    path = v5 if os.path.exists(v5) else v4
    return json.load(open(path, encoding='utf-8')), os.path.basename(path)


def game_exclusion(game, grow=1.0):
    """batch 0.5's own ground: BOX_05 plus every game road's carriageway + pavement (with its decks)"""
    polys = [sbox(*geo.BOX_05)]
    for r in game['roads']:
        cs = set(game.get('cut', {}).get(r['name'], []))
        walk = max(r.get('walkL') or 10.0, r.get('walkR') or 10.0)
        run = []
        for k, s in enumerate(r['s'] + [None]):
            if s is None or k in cs:
                if len(run) > 1:
                    half = max(max(q[6], q[7]) for q in run)
                    polys.append(LineString([(q[0], q[2]) for q in run]).buffer(half + walk + grow, cap_style=2))
                run = []
                continue
            run.append(s)
    for d in game.get('decks', []):
        pts = [(q[0], q[2]) for q in d['s']]
        if len(pts) > 1:
            polys.append(LineString(pts).buffer(40, cap_style=2))
    return unary_union(polys)


def seam_ends(game):
    out = []
    for r in game['roads']:
        for flag, idx, sgn in (('edgeStart', 0, -1), ('edgeEnd', -1, 1)):
            if not r.get(flag):
                continue
            s = r['s'][idx]
            d = np.array([s[3], s[4]]) * sgn
            d /= np.linalg.norm(d)
            med = s[8] if len(s) > 8 else (r.get('median') or 0)
            lanes = s[9] if len(s) > 9 else (r.get('lanes') or (2 if r['kind'] == 'route' else 1))
            lw = s[10] if len(s) > 10 else (r.get('laneW') or (16.0 if r['kind'] == 'route' else 16.0))
            out.append(dict(road=r['name'], flag=flag, kind=r['kind'], x=s[0], y=s[1], z=s[2], out=d, half=max(s[6], s[7]),
                            median=med, lanes=int(lanes), laneW=float(lw), walk=r.get('walkL') or 10.0))
    return out


def match_seams(edges, ends, region_poly):
    """cut / extend the OSM edges that continue a game road's map-edge end so they end exactly on it"""
    lines = [LineString(e.P) for e in edges]
    tree = STRtree(lines)
    report = []
    for E in ends:
        pE = np.array([E['x'], E['z']])
        if not region_poly.buffer(400).contains(Point(pE)):
            continue
        cands = []
        for j in tree.query(Point(pE).buffer(70)):
            e = edges[int(j)]
            if e.look != 'main':
                continue
            L = lines[int(j)]
            d = L.distance(Point(pE))
            s = L.project(Point(pE))
            i = int(np.clip(np.searchsorted(chain(e.P), s), 1, len(e.P) - 1))
            de = e.P[i] - e.P[i - 1]
            de /= max(np.linalg.norm(de), 1e-9)
            dot = float(de @ E['out'])
            if abs(dot) < 0.85:
                continue
            # the lateral offset of this carriageway from the game road's centre line
            right = np.array([-de[1], de[0]])
            cands.append((d, e, s, dot, float((e.P[i] - pE) @ right)))
        if not cands:
            report.append(dict(road=E['road'], flag=E['flag'], status='no OSM road continues it', at=[round(E['x']), round(E['z'])]))
            continue
        cands.sort(key=lambda c: c[0])
        divided = E['median'] > 0
        pick = []
        if divided:
            fw = [c for c in cands if c[1].oneway and c[3] > 0]
            bw = [c for c in cands if c[1].oneway and c[3] < 0]
            if fw:
                pick.append(fw[0])
            if bw:
                pick.append(bw[0])
            if not pick:
                pick = [cands[0]]
        else:
            two = [c for c in cands if not c[1].oneway]
            if two:
                pick = [two[0]]
            else:
                fw = [c for c in cands if c[3] > 0]
                bw = [c for c in cands if c[3] < 0]
                pick = ([fw[0]] if fw else []) + ([bw[0]] if bw else [])
        for d, e, s, dot, lat in pick:
            # keep the part on the outward side of the end, end it exactly at the game road's centre (two-way / paired)
            c = chain(e.P)
            out_side_after = dot > 0   # the edge runs outward: keep s..end, the end at E is its START
            # trim
            if out_side_after:
                keep = c > s + 1e-6
                P = np.vstack([pE, e.P[keep]])
                W = np.r_[1.0 if divided else 0.0, e.w[keep]]
                end = 0
            else:
                keep = c < s - 1e-6
                P = np.vstack([e.P[keep], pE])
                W = np.r_[e.w[keep], 1.0 if divided else 0.0]
                end = -1
            if len(P) < 3:
                report.append(dict(road=E['road'], flag=E['flag'], status='OSM piece too short', at=[round(E['x']), round(E['z'])]))
                continue
            # ease the lateral difference over the last 160 studs; the end runs along the game road's direction
            cc = chain(P)
            u = cc / cc[-1] if end == -1 else 1 - cc / cc[-1]
            Lc = cc[-1]
            ramp = np.clip(1 - (cc[-1] - cc) / 160.0, 0, 1) if end == -1 else np.clip(1 - cc / 160.0, 0, 1)
            # the point on the old line nearest E is already E (we inserted it); pull the samples next to it onto the
            # game road's line through E
            outd = E['out']
            for k in range(len(P)):
                v = P[k] - pE
                along = v @ outd
                perp = v - along * outd
                P[k] = P[k] - perp * ramp[k] ** 1.5 * 0.999
            P = densify(P)
            Wn = np.interp(np.linspace(0, 1, len(P)), np.linspace(0, 1, len(W)), W)
            e.P = P
            e.P0 = P.copy()
            e.w = np.clip(Wn, 0, 1) if divided else np.zeros(len(P))
            if divided:
                e.w[:] = 1.0
                e.paired = True
            # the game road's cross-section
            n = E['lanes']
            if e.oneway:
                e.nf, e.Wf = n, E['laneW']
            else:
                e.nf = e.nb = n
                e.Wf = e.Wb = E['laneW']
                if n == 1:
                    e.Wf = e.Wb = E['half']
            if end == 0:
                e.a = ('seam', E['road'], E['flag'], e.wid)
            else:
                e.b = ('seam', E['road'], E['flag'], e.wid)
            e.seam[0 if end == 0 else 1] = dict(road=E['road'], flag=E['flag'], y=E['y'], x=E['x'], z=E['z'], out=outd.tolist(),
                                                half=E['half'], median=E['median'], lanes=n)
            report.append(dict(road=E['road'], flag=E['flag'], status='joined', osm=e.name, way=e.wid, oneway=bool(e.oneway),
                               moved=round(float(d), 1), lateral=round(lat, 1), at=[round(E['x']), round(E['z'])],
                               game_xs='%d+%d%s' % (n, n, ' divided' if divided else ''),
                               osm_xs='%d%s' % (e.cs['nf'], '' if e.cs['oneway'] else '+%d' % e.cs['nb'])))
    return report


# ---------------------------------------------------------------- clip to the batch
def clip_edges(edges, region, keep_seam_pieces):
    """cut every edge to the region (shapely, world studs); an edge piece that ends on the region's boundary gets a cut
    end (e.cut). Edges with a seam end are clipped only by the batch outline (they may reach into the 0.5 box)."""
    out = []
    nid = [0]
    for e in edges:
        reg = keep_seam_pieces if (e.seam[0] or e.seam[1]) else region
        ls = LineString(e.P)
        if reg.contains(ls):
            out.append(e)
            continue
        g = ls.intersection(reg)
        if g.is_empty:
            continue
        parts = [g] if g.geom_type == 'LineString' else [x for x in getattr(g, 'geoms', []) if x.geom_type == 'LineString']
        c = chain(e.P)
        for part in parts:
            if part.length < 4:
                continue
            s0 = ls.project(Point(part.coords[0]))
            s1 = ls.project(Point(part.coords[-1]))
            if s1 < s0:
                s0, s1 = s1, s0
            keep = (c > s0 + 0.5) & (c < s1 - 0.5)
            P = np.vstack([np.array(ls.interpolate(s0).coords[0]), e.P[keep], np.array(ls.interpolate(s1).coords[0])])
            Wv = np.r_[np.interp(s0, c, e.w), e.w[keep], np.interp(s1, c, e.w)]
            f = Edge()
            f.__dict__.update(e.__dict__)
            f.P = P
            f.w = Wv
            if getattr(e, 'med', None) is not None and len(e.med) == len(e.P):
                f.med = np.r_[np.interp(s0, c, e.med), e.med[keep], np.interp(s1, c, e.med)]
            f.seam = [e.seam[0] if s0 < 0.5 else None, e.seam[1] if s1 > c[-1] - 0.5 else None]
            f.cut = [s0 > 0.5, s1 < c[-1] - 0.5]
            if f.cut[0]:
                nid[0] += 1
                f.a = ('cut', e.id, nid[0])
            if f.cut[1]:
                nid[0] += 1
                f.b = ('cut', e.id, nid[0])
            out.append(f)
    for i, e in enumerate(out):
        e.id = i
        e.D = dirs_of(e.P)
        for end, sm in ((0, e.seam[0]), (-1, e.seam[1])):
            if sm:
                d = np.array(sm['out'])
                e.D[end] = d if end == 0 else -d   # (the edge leaves the game road at its start, arrives at its end)
    return out


def build(tag, margin=400.0):
    net = Net()
    net.tag = tag
    poly = geo.batch_poly(tag)
    net.outline = poly
    net.standalone = geo.standalone(tag)
    if net.standalone:
        return _build_standalone(net, poly, margin)
    game, gname = game_roads()
    net.game_name = gname
    excl = game_exclusion(game)
    net.exclusion = excl
    region = poly.difference(excl)
    net.region = region
    # OSM in lon/lat, the outline grown by margin
    big = poly.buffer(margin)
    area_ll = Polygon([geo.lonlat(x, z) for x, z in big.exterior.coords])
    edges = load_edges(area_ll)
    round_fit(edges, tag)
    fam = family_ids(edges, node_map(edges))
    for e in edges:
        e.push = None
    net.pushed = push_beside(edges, fam)
    net.stats_pair = pair_edges(edges, fam, unpair_near=seam_unpair(game))
    blend_nodes(edges)
    ends = seam_ends(game)
    # each game map-edge end belongs to the batch its outward side lies in
    polys = {t: geo.batch_poly(t) for t in ('1', '2', '3')}
    for E in ends:
        q = Point(E['x'] + E['out'][0] * 150, E['z'] + E['out'][1] * 150)
        E['batch'] = min(polys, key=lambda t: polys[t].distance(q))
        E['batch_dist'] = round(polys[E['batch']].distance(q))
    # (an end deep inside BOX_05 continues inside batch 0.5's own ground: streets.py's job, not a batch seam)
    x0, z0, x1, z1 = geo.BOX_05
    for E in ends:
        d = E['out']
        ts = []
        for c, lo, hi in ((0, x0, x1), (1, z0, z1)):
            v = (E['x'], E['z'])[c]
            if d[c] > 1e-6:
                ts.append((hi - v) / d[c])
            elif d[c] < -1e-6:
                ts.append((lo - v) / d[c])
        E['to_box_edge'] = round(max(0.0, min(ts))) if ts else 0
    net.inside_ends = [dict(road=E['road'], flag=E['flag'], to_box_edge=E['to_box_edge']) for E in ends
                       if E['batch'] == tag and E['to_box_edge'] > 300]
    mine = [E for E in ends if E['batch'] == tag and E['batch_dist'] < 300 and E['to_box_edge'] <= 300]
    net.seam_report = match_seams(edges, mine, poly)
    net.seam_ends = ends
    # seam edges may reach into the 0.5 box up to the game road's end, never over a game road
    road_only = unary_union([LineString([(q[0], q[2]) for q in r['s']]).buffer(max(max(q[6], q[7]) for q in r['s']) + 10.5, cap_style=2)
                             for r in game['roads']])
    net.seam_region = poly.difference(road_only)
    # (2026-11-14, batch 2) a river bridge that leaves the batch over open water (the Yangon-Dala Bridge left the outline in
    # mid-river and ended in the air) runs on whole to its far landing, where no other batch lies
    ext_ways = REACH_OUT.get(tag, ())
    if ext_ways:
        others = unary_union([geo.batch_poly(t) for t in ('1', '2', '3') if t != tag] + [sbox(*geo.BOX_05)])
        lines = [LineString(geo.proj(r['p'])) for r in geo.load('roads') if r['id'] in ext_ways]
        if lines:
            reach = unary_union(lines).buffer(4.0, cap_style=2).difference(others).difference(excl)
            whole = region.union(reach)
            # (the meshes' allowed area: the bridge's whole width and walls past the outline)
            net.reach_area = unary_union(lines).buffer(60.0, cap_style=2).difference(poly).difference(others).difference(excl)
            ext_e = [e for e in edges if e.wid in ext_ways]
            rest_e = [e for e in edges if e.wid not in ext_ways]
            rest = clip_edges(rest_e, region, net.seam_region)
            out = clip_edges(ext_e, whole, net.seam_region)
            edges = rest + out
            for i, e in enumerate(edges):
                e.id = i
            net.reach_out = sum(LineString(e.P).length for e in out)
        else:
            edges = clip_edges(edges, region, net.seam_region)
    else:
        edges = clip_edges(edges, region, net.seam_region)
    net.edges = edges
    # nodes
    nodes = {}
    for e in edges:
        nodes.setdefault(e.a, []).append((e.id, 0))
        nodes.setdefault(e.b, []).append((e.id, -1))
    net.nodes = nodes
    return net


def _build_standalone(net, poly, margin):
    """(2026-11-16, rescale step 3) a pilot district: the OSM network clipped to the district box and nothing else (no
    batch 0.5 box, no v4/v5 game roads, no seams: none of them exists in the 1:1 frame)"""
    net.game_name = None
    net.exclusion = Polygon()
    net.region = poly
    net.seam_region = poly
    net.seam_report, net.seam_ends, net.inside_ends = [], [], []
    big = poly.buffer(margin * geo.LK)
    area_ll = Polygon([geo.lonlat(x, z) for x, z in big.exterior.coords])
    edges = load_edges(area_ll)
    round_fit(edges, net.tag)
    fam = family_ids(edges, node_map(edges))
    for e in edges:
        e.push = None
    net.pushed = push_beside(edges, fam)
    net.stats_pair = pair_edges(edges, fam)
    blend_nodes(edges)
    edges = clip_edges(edges, poly, poly)
    # (2026-11-16, P1 road fixes) ways laid as paving, not road (PAVED_WAYS): they stay in the network (heights, terrain
    # beds) but carry no traffic, no carriageway and no paint; roadmesh paves their whole width (P), roads.py gives them
    # pavement collision
    for e in edges:
        e.paved = e.wid in PAVED_WAYS.get(net.tag, ())
        if e.paved:
            e.traffic = False
    net.pilot_seam_report = pilot_seams(net.tag, edges, poly) if net.tag in getattr(geo, 'PILOT_SEAMS', {}) else []
    net.edges = edges
    nodes = {}
    for e in edges:
        nodes.setdefault(e.a, []).append((e.id, 0))
        nodes.setdefault(e.b, []).append((e.id, -1))
    net.nodes = nodes
    return net


PILOT_SNAP = 40.0      # (1:1) studs: a cut end this close to an earlier pilot's cut end on the shared edge is its continuation
PILOT_EASE = 160.0     # studs over which the lateral snap is eased in


def pilot_seams(tag, edges, poly):
    """(2026-11-16, step 5) a later 1:1 pilot (geo.PILOT_SEAMS) meets the earlier districts it touches: every cut end on
    the shared edge is matched to the earlier district's road end there (roads_<u>_profile.json: its centre line and
    surface heights) and moved onto it: the same point, the same direction at the end (eased over PILOT_EASE), and a height
    pin (e.pin, heights.solve) at the earlier road's surface height. Ends with no partner are reported."""
    out_dir = os.path.join(geo.BUILD, 'city_1to1')
    report = []
    for u in geo.PILOT_SEAMS.get(tag, ()):
        prof_p = os.path.join(out_dir, 'roads_%s_profile.json' % u)
        if not os.path.exists(prof_p):
            report.append(dict(pilot=u, status='no roads_%s_profile.json' % u))
            continue
        shared = geo.batch_poly(u).boundary.intersection(poly.boundary)
        prof = json.load(open(prof_p))
        # the earlier district's network as roads.py built it (deterministic: terrain.py checks it against the profile),
        # for its cross-section at each end; the heights come from the profile (same edge order)
        net_u = build(u)
        assert len(net_u.edges) == len(prof), 'roads_%s_profile.json is not this network' % u
        ends = []
        for eu, pe in zip(net_u.edges, prof):
            pts = pe['pts']
            if len(pts) < 2 or len(pts) != len(eu.P):
                continue
            lo_u, hi_u = offsets(eu)
            for k, k2 in ((0, 1), (-1, -2)):
                q = np.array([pts[k][0], pts[k][2]])
                if shared.distance(Point(q)) > 0.5:
                    continue
                d = q - np.array([pts[k2][0], pts[k2][2]])     # pointing out of the earlier district
                d /= max(np.linalg.norm(d), 1e-9)
                med_u = getattr(eu, 'med', None)
                ends.append(dict(p=q, y=pts[k][1], out=d, name=pe['name'], walk=pe['walk'], oneway=bool(eu.oneway),
                                 lohi=(float(lo_u[k]), float(hi_u[k])), w=float(eu.w[k]),
                                 med=None if med_u is None or len(med_u) != len(eu.P) else float(med_u[k]), used=False))
        for e in edges:
            for end in (0, 1):
                if not e.cut[end]:
                    continue
                k = 0 if end == 0 else -1
                q = e.P[k]
                if shared.distance(Point(q)) > 1.0:
                    continue
                # the direction INTO this district at this end
                din = (e.P[1] - e.P[0]) if end == 0 else (e.P[-2] - e.P[-1])
                din = din / max(np.linalg.norm(din), 1e-9)
                best = None
                for E in ends:
                    if E['used']:
                        continue
                    dd = float(np.linalg.norm(E['p'] - q))
                    if dd > PILOT_SNAP or float(E['out'] @ din) < 0.7:
                        continue
                    if best is None or dd < best[0]:
                        best = (dd, E)
                if best is None:
                    report.append(dict(pilot=u, status='no road end in %s' % u, road=e.name, at=[round(float(q[0])), round(float(q[1]))]))
                    continue
                dd, E = best
                E['used'] = True
                pE = E['p']
                P = e.P.copy()
                c = chain(P)
                dist = c if end == 0 else c[-1] - c
                ramp = np.clip(1 - dist / PILOT_EASE, 0, 1)
                outd = E['out']
                for i in range(len(P)):
                    v = P[i] - pE
                    along = v @ outd
                    perp = v - along * outd
                    P[i] = P[i] - perp * ramp[i] ** 1.5
                P[k] = pE
                e.P = P
                e.P0 = P.copy()
                e.D = dirs_of(P)
                e.D[k] = outd if end == 0 else -outd
                # the earlier road's cross-section at the edge: pair weight and median eased in over PILOT_EASE
                if e.oneway and E['oneway']:
                    e.w = e.w * (1 - ramp) + E['w'] * ramp
                    if E['med'] is not None:
                        med = getattr(e, 'med', None)
                        if med is None or len(med) != len(P):
                            med = np.full(len(P), MED)
                        e.med = med * (1 - ramp) + E['med'] * ramp
                    elif getattr(e, 'med', None) is not None and len(e.med) == len(P):
                        e.med = e.med * (1 - ramp) + MED * ramp
                if not hasattr(e, 'pin') or e.pin is None:
                    e.pin = [None, None]
                e.pin[end] = float(E['y'])
                lo_, hi_ = offsets(e)
                # (both lines run the same way across the edge: compare the carriageway's span right of the line)
                xs_here = [round(float(lo_[k]), 2), round(float(hi_[k]), 2)]
                xs_there = [round(E['lohi'][0], 2), round(E['lohi'][1], 2)]
                report.append(dict(pilot=u, status='joined', road=e.name, moved=round(dd, 2), y=round(float(E['y']), 2),
                                   span_here=xs_here, span_there=xs_there, walk_here=e.walk, walk_there=E['walk'],
                                   at=[round(float(pE[0]), 1), round(float(pE[1]), 1)]))
        for E in ends:
            if not E['used']:
                report.append(dict(pilot=u, status='%s road end with no partner here' % u, road=E['name'],
                                   at=[round(float(E['p'][0])), round(float(E['p'][1]))]))
    return report


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    tag = sys.argv[1] if len(sys.argv) > 1 else '1'
    net = build(tag)
    L = sum(chain(e.P)[-1] for e in net.edges)
    print('edges', len(net.edges), 'nodes', len(net.nodes), 'km %.1f' % (L / geo.SPM / 1000), net.stats_pair)
    for r in net.seam_report:
        print(r)
    for r in getattr(net, 'pilot_seam_report', []):
        print(r)
