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

STEP = 8.0
MED = 3.0             # median half (kerbs included), master plan / v5
PAIR_MAX = 45.0       # two one-way ways this close (centre to centre) are one divided road
PAIR_MIN = 6.0
TAPER = 48.0          # studs over which a move fades at a node / where pairing stops

PUBLIC = {'trunk', 'primary', 'secondary', 'tertiary', 'unclassified', 'residential', 'living_street', 'trunk_link',
          'primary_link', 'secondary_link', 'tertiary_link', 'motorway', 'motorway_link', 'road'}
MAIN = {'motorway', 'trunk', 'primary', 'secondary', 'tertiary'}
LINKS = {'motorway_link', 'trunk_link', 'primary_link', 'secondary_link', 'tertiary_link'}
RANK = {'motorway': 0, 'trunk': 0, 'primary': 1, 'secondary': 2, 'tertiary': 3, 'motorway_link': 4, 'trunk_link': 4,
        'primary_link': 4, 'secondary_link': 4, 'tertiary_link': 5, 'unclassified': 6, 'residential': 6, 'road': 6,
        'living_street': 7, 'service': 8}
LANE_W = {1: 10.0, 2: 16.0, 3: 13.0}


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


def cross_section(t):
    """-> dict: oneway, nf, nb (lanes forward / backward; 0 for a one-way's back), Wf, Wb, look, walk, traffic"""
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
                if k != 'tagged':
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


def family_ids(edges, nodes, ext_max=450.0):
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


def push_beside(edges, fam, gap=3.0, reach=80.0):
    """a ground road running beside a flyover / its ramps (within 30 degrees) is moved sideways until its carriageway
    clears the deck (+ parapet + gap): in the game the lanes are wider than real ones, so OSM's at-grade lanes would
    sit under the ramps"""
    fl = [(edges[i], LineString(edges[i].P0)) for i in fam]
    if not fl:
        return 0
    tree = STRtree([L for _, L in fl])
    moved = 0
    for e in edges:
        if e.id in fam or e.tunnel:
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
def pair_edges(edges, fam=frozenset()):
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
        e.w = ws
        e.own = fs * ws[:, None]
        stats['paired_len'] += float((ws > 0.5).sum() * STEP)
    for e in edges:
        if getattr(e, 'push', None) is not None:
            e.own = e.own + e.push
    return stats


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
        c = e.w * (MED + hw_)
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
    fam = family_ids(edges, node_map(edges))
    for e in edges:
        e.push = None
    net.pushed = push_beside(edges, fam)
    net.stats_pair = pair_edges(edges, fam)
    blend_nodes(edges)
    ends = seam_ends(game)
    # each game map-edge end belongs to the batch its outward side lies in
    polys = {t: geo.batch_poly(t) for t in ('1', '2', '3')}
    for E in ends:
        q = Point(E['x'] + E['out'][0] * 150, E['z'] + E['out'][1] * 150)
        E['batch'] = min(polys, key=lambda t: polys[t].distance(q))
        E['batch_dist'] = round(polys[E['batch']].distance(q))
    mine = [E for E in ends if E['batch'] == tag and E['batch_dist'] < 300]
    net.seam_report = match_seams(edges, mine, poly)
    net.seam_ends = ends
    # seam edges may reach into the 0.5 box up to the game road's end, never over a game road
    road_only = unary_union([LineString([(q[0], q[2]) for q in r['s']]).buffer(max(max(q[6], q[7]) for q in r['s']) + 10.5, cap_style=2)
                             for r in game['roads']])
    net.seam_region = poly.difference(road_only)
    edges = clip_edges(edges, region, net.seam_region)
    net.edges = edges
    # nodes
    nodes = {}
    for e in edges:
        nodes.setdefault(e.a, []).append((e.id, 0))
        nodes.setdefault(e.b, []).append((e.id, -1))
    net.nodes = nodes
    return net


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    tag = sys.argv[1] if len(sys.argv) > 1 else '1'
    net = build(tag)
    L = sum(chain(e.P)[-1] for e in net.edges)
    print('edges', len(net.edges), 'nodes', len(net.nodes), 'km %.1f' % (L / 1.6 / 1000), net.stats_pair)
    for r in net.seam_report:
        print(r)
