"""Whole-Yangon map (14 Nov 2026): road heights, bridges and flyovers for roads.py.

Every edge sample is a vertex of one graph; an OSM node shared by roads is ONE vertex, so junctions share one height.
The surface height y (studs) is the smallest profile that
  * never goes under the ground (ground.Ground: SRTM smoothed like batch 0.5, its seam blended onto batch 0.5's ground),
  * meets every clearance (owner, 14 Nov: "the overhead bridges are too low"): a bridge / layer >= 1 sample whose deck lies
    over a road or railway of a lower layer gets its top at least CLEAR + DECK over it (17 studs from the girders' lowest
    point to the road / rail top under it); over a big water body (river, creek, canal, a lake of 3+ ha) the girders clear
    the water by WATER_CLEAR,
  * climbs or falls at most GRADE between any two neighbours (routes / main roads / links 6 %, streets 10 %).
That is a max-plus shortest path: y(v) = max(base(v), max over u of y(u) - grade x dist(u, v)) (Dijkstra from the highest).
The ramps come out of it on their own, along whatever road continues the bridge. Then the game roads' map-edge ends
(batch 0.5 seam) are pinned to their exact heights and eased back from there. Two passes: the second measures under the
heights of the first (a road under a deck may itself have been lifted).
"""
import heapq, math

import numpy as np
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union
from shapely.strtree import STRtree

import geo
import roadnet as rn

DECK = 3.0          # deck slab + girders under the road surface (the deck's lowest point is y - DECK)
CLEAR = 17.0        # studs from the deck's lowest point to the road / rail top beneath (owner's "too low"; 5.5-6 m at 3 studs a metre)
WATER_CLEAR = 10.0  # girders over the water level
MARGIN = 0.5        # extra on every clearance
RAIL_TOP = 1.0      # the rail top over the ground
RAISE = 1.5         # a sample this far over the ground is built raised (ramp walls or a viaduct)
GRADE_MAIN, GRADE_STREET = 0.06, 0.10


def grade_of(e):
    return GRADE_MAIN if (e.look == 'main' or e.traffic) else GRADE_STREET


def build_graph(net):
    vid = {}
    X = []
    owner = []
    for e in net.edges:
        ids = np.empty(len(e.P), dtype=np.int64)
        for i in range(len(e.P)):
            if i == 0 or i == len(e.P) - 1:
                key = ('n', e.a if i == 0 else e.b)
                if key not in vid:
                    vid[key] = len(X)
                    X.append(e.P[i])
                    owner.append(e.id)
                ids[i] = vid[key]
            else:
                ids[i] = len(X)
                X.append(e.P[i])
                owner.append(e.id)
        e._ids = ids
    X = np.array(X)
    adj = [[] for _ in range(len(X))]
    for e in net.edges:
        ids = e._ids
        g = grade_of(e)
        for i in range(len(ids) - 1):
            a, b = int(ids[i]), int(ids[i + 1])
            if a == b:
                continue
            d = float(np.linalg.norm(X[a] - X[b]))
            adj[a].append((b, d * g))
            adj[b].append((a, d * g))
    return X, adj


def maxprop(base, adj):
    y = base.copy()
    pq = [(-v, i) for i, v in enumerate(y)]
    heapq.heapify(pq)
    done = np.zeros(len(y), bool)
    while pq:
        nv, i = heapq.heappop(pq)
        v = -nv
        if done[i] or v < y[i] - 1e-9:
            continue
        done[i] = True
        for j, c in adj[i]:
            cand = v - c
            if cand > y[j] + 1e-9:
                y[j] = cand
                heapq.heappush(pq, (-cand, j))
    return y


def minprop_from(y, pins, adj, floor):
    """lower the profile so that it falls / climbs at most the grade from each pinned vertex (never under floor)"""
    pq = [(v, i) for i, v in pins.items()]
    for v, i in pq:
        y[i] = v
    heapq.heapify(pq)
    best = {i: v for i, v in pins.items()}
    while pq:
        v, i = heapq.heappop(pq)
        if v > best.get(i, 1e18) + 1e-9:
            continue
        for j, c in adj[i]:
            cand = v + c
            if cand < y[j] - 1e-9 and cand < best.get(j, 1e18):
                if cand < floor[j]:
                    continue
                best[j] = cand
                y[j] = cand
                heapq.heappush(pq, (cand, j))
    return y


def rails_beneath():
    out = []
    for l in geo.load('lines'):
        t = l['t']
        if t.get('railway') not in ('rail', 'light_rail', 'narrow_gauge'):
            continue
        if t.get('tunnel') not in (None, 'no') or t.get('bridge') not in (None, 'no'):
            continue
        pts = geo.proj(l['p'])
        if len(pts) > 1:
            out.append(dict(name=t.get('name:en') or t.get('name') or 'railway', line=LineString(pts),
                            poly=LineString(pts).buffer(7.0, cap_style=2)))
    return out


def _sub_maxprop(base, verts, adj_cost):
    """max-plus propagation over a vertex subset; adj_cost: {v: [(u, cost)]}"""
    y = {v: base[v] for v in verts}
    pq = [(-y[v], v) for v in verts]
    heapq.heapify(pq)
    done = set()
    while pq:
        nv, i = heapq.heappop(pq)
        v = -nv
        if i in done or v < y[i] - 1e-9:
            continue
        done.add(i)
        for j, c in adj_cost.get(i, ()):
            cand = v - c
            if cand > y[j] + 1e-9:
                y[j] = cand
                heapq.heappush(pq, (-cand, j))
    return y


def families(net, ext_max=700.0):
    """bridge / layer >= 1 edges, grown along the road they continue (through nodes where only that road meets) up to
    ext_max studs: the ramps. -> list of (edge ids, landing node keys)"""
    edges, nodes = net.edges, net.nodes
    f0 = {e.id for e in edges if (e.bridge or e.layer >= 1) and not e.tunnel}
    fam = set(f0)
    stack = []
    for eid in f0:
        e = edges[eid]
        for key in (e.a, e.b):
            stack.append((key, eid, 0.0))
    while stack:
        key, came, ext = stack.pop()
        inc = nodes.get(key, [])
        if len(inc) != 2:
            continue
        other = [x for x, _ in inc if x != came]
        if not other:
            continue
        f = other[0]
        if f in fam:
            continue
        ln = float(rn.chain(edges[f].P)[-1])
        if ext + ln > ext_max:
            continue
        fam.add(f)
        e2 = edges[f]
        nxt = e2.b if e2.a == key else e2.a
        stack.append((nxt, f, ext + ln))
    parent = {i: i for i in fam}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    by_node = {}
    for i in fam:
        e = edges[i]
        for key in (e.a, e.b):
            if key in by_node:
                parent[find(i)] = find(by_node[key])
            else:
                by_node[key] = i
    comps = {}
    for i in fam:
        comps.setdefault(find(i), []).append(i)
    out = []
    for ids in comps.values():
        s = set(ids)
        land = set()
        for i in ids:
            e = edges[i]
            for key in (e.a, e.b):
                if any(x not in s for x, _ in nodes.get(key, [])):
                    land.add(key)
        out.append((sorted(ids), land))
    return out


def _requirements(net, G, y, ctx):
    """(e.id, i) -> (top needed, (kind, what, height under)) for every raised-way sample over a road / rail / water"""
    edges = net.edges
    polys, ctree, rails, rtree, water, wtree, fam_of = ctx
    gr = net.ground_v
    req_info = {}
    for e in edges:
        if not ((e.bridge or e.layer >= 1) and not e.tunnel):
            continue
        lo, hi = rn.offsets(e)
        R = rn.rights(e)
        nbr = {e.a, e.b}
        for i in range(len(e.P)):
            seg = LineString([e.P[i] + R[i] * (lo[i] - 2), e.P[i] + R[i] * (hi[i] + 2)])
            need, what = -1e9, None
            for j in ctree.query(seg):
                f = edges[int(j)]
                if f.id == e.id or f.layer >= e.layer or f.a in nbr or f.b in nbr or f.tunnel:
                    continue
                if fam_of.get(f.id) is not None and fam_of.get(f.id) == fam_of.get(e.id):
                    continue
                if not polys[int(j)].intersects(seg):
                    continue
                s_ = LineString(f.P).project(Point(e.P[i]))
                c = rn.chain(f.P)
                k = int(np.clip(np.searchsorted(c, s_), 0, len(f.P) - 1))
                if abs(float(f.D[k] @ e.D[i])) > 0.9:
                    continue  # a road beside the deck, not under it (push_beside keeps it clear)
                fy = y[f._ids[k]]
                v = fy + CLEAR + DECK + MARGIN
                if v > need:
                    need, what = v, ('road', f.name or f.hw, fy)
            if rtree is not None:
                for j in rtree.query(seg):
                    r = rails[int(j)]
                    if not r['poly'].intersects(seg):
                        continue
                    ry = float(G.ys([e.P[i]])[0]) + RAIL_TOP
                    v = ry + CLEAR + DECK + MARGIN
                    if v > need:
                        need, what = v, ('rail', r['name'], ry)
            if wtree is not None:
                pt = Point(e.P[i])
                for j in wtree.query(pt):
                    w = water[int(j)]
                    if w['poly'].contains(pt):
                        v = w['level_m'] * 1.6 + WATER_CLEAR + DECK + MARGIN
                        if v > need:
                            need, what = v, ('water', w['name'] or w['kind'], w['level_m'] * 1.6)
            if what and need > gr[int(e._ids[i])] + 0.2:
                req_info[(e.id, i)] = (need, what)
    return req_info


def _trim_end(e, end, dist):
    """cut `dist` studs off one end of an edge (its arrays follow)"""
    c = rn.chain(e.P)
    L = c[-1]
    if dist >= L - 4:
        dist = max(0.0, L - 4)
    if end == 0:
        keep = c > dist
        P = np.vstack([np.interp(dist, c, e.P[:, 0]), np.interp(dist, c, e.P[:, 1])]).T
        e.P = np.vstack([P, e.P[keep]])
        e.w = np.r_[np.interp(dist, c, e.w), e.w[keep]]
    else:
        keep = c < L - dist
        P = np.vstack([np.interp(L - dist, c, e.P[:, 0]), np.interp(L - dist, c, e.P[:, 1])]).T
        e.P = np.vstack([e.P[keep], P])
        e.w = np.r_[e.w[keep], np.interp(L - dist, c, e.w)]
    e.D = rn.dirs_of(e.P)


def extend_short(net, G, log=print):
    """For a bridge whose ramps can't land within 12 % before the next junctions: carry its ramps on along the road it
    continues (8 %), and at every junction passed on the way the other roads either pass UNDER (where the deck is high
    enough there: they stay joined to each other under it) or end at the ramp's wall (trimmed back, a dead end).
    Returns the number of junctions changed. Run solve() again after."""
    edges, nodes = net.edges, net.nodes
    changed = 0
    y0 = net.y0
    for k, st in net.fam_status.items():
        if not st.startswith('too short'):
            continue
        ids, land = net.fams[k]
        s_ids = set(ids)
        # the requirement points of this family and their tops
        reqs = [(edges[eid].P[i], need) for (eid, i), (need, what) in net.req_info.items() if eid in s_ids]
        if not reqs:
            continue
        top = max(n for _, n in reqs)
        for key in list(land):
            # walk on from this landing along the best continuation
            cur_key = key
            came = [x for x, _ in nodes.get(key, []) if x in s_ids]
            if not came:
                continue
            prev = edges[came[0]]
            dist0 = min(np.linalg.norm(np.array(prev.P[0 if prev.a == key else -1]) - p) for p, _ in reqs)
            walked = 0.0
            for step in range(12):
                inc = [(x, end) for x, end in nodes.get(cur_key, []) if x != prev.id]
                if not inc:
                    break
                pe = prev
                pd = pe.D[0] * -1 if pe.a == cur_key else pe.D[-1]
                best = None
                for x, end in inc:
                    f = edges[x]
                    fd = f.D[0] if end == 0 else -f.D[-1]
                    sc = float(fd @ pd) + (0.3 if rn.norm_name(f.name) == rn.norm_name(pe.name) and f.name else 0)
                    if best is None or sc > best[0]:
                        best = (sc, x, end)
                if best is None or best[0] < 0.75:
                    break
                cont = edges[best[1]]
                d_here = dist0 + walked
                h_est = top - 0.08 * d_here - float(y0[vkey_of(net, cur_key)])
                if h_est <= 1.0:
                    break
                others = [(x, end) for x, end in inc if x != cont.id]
                if others:
                    if h_est >= CLEAR + DECK + MARGIN:
                        newk = ('under', cur_key)
                        for x, end in others:
                            f = edges[x]
                            if end == 0:
                                f.a = newk
                            else:
                                f.b = newk
                    else:
                        reach = max(rn.offsets(cont)[1].max(), -rn.offsets(cont)[0].min()) + 4.0
                        for x, end in others:
                            f = edges[x]
                            newk = ('wall', x, end)
                            _trim_end(f, end, reach + max(f.nf * f.Wf, f.nb * f.Wb) * 0.3)
                            if end == 0:
                                f.a = newk
                            else:
                                f.b = newk
                            f.wall = getattr(f, 'wall', [False, False])
                            f.wall[0 if end == 0 else 1] = True
                    changed += 1
                    nodes.clear()
                    nodes.update(rn.node_map(edges))
                walked += float(rn.chain(cont.P)[-1])
                prev = cont
                cur_key = cont.b if cont.a == cur_key else cont.a
                if walked > 700:
                    break
    if changed:
        log('  %d junctions on long ramps changed (roads passing under or ending at a ramp wall)' % changed)
    return changed


def vkey_of(net, key):
    for e in net.edges:
        if e.a == key:
            return int(e._ids[0])
        if e.b == key:
            return int(e._ids[-1])
    return 0


def solve(net, G, iters=2, log=print):
    X, adj = build_graph(net)
    gr = G.ys(X)
    net.X, net.adj, net.ground_v = X, adj, gr
    edges = net.edges
    rails = rails_beneath()
    rtree = STRtree([r['poly'] for r in rails]) if rails else None
    water = [w for w in G.water if w['big']]
    wtree = STRtree([w['poly'] for w in water]) if water else None
    polys = [rn.carriageway(e) for e in edges]
    ctree = STRtree(polys)
    fams = families(net)
    fam_of = {}
    for k, (ids, land) in enumerate(fams):
        for i in ids:
            fam_of[i] = k
    ctx = (polys, ctree, rails, rtree, water, wtree, fam_of)
    vkey = {}
    for e in edges:
        vkey[e.a] = int(e._ids[0])
        vkey[e.b] = int(e._ids[-1])
    y0 = maxprop(gr.copy(), adj)        # the ground-following profile (grades capped), no bridges
    net.y0 = y0
    y = y0.copy()
    fam_grade, fam_status = {}, {}
    adj2 = adj
    req_info = {}
    for it in range(iters):
        req_info = _requirements(net, G, y, ctx)
        reqs_by_fam = {}
        for (eid, i), (need, what) in req_info.items():
            reqs_by_fam.setdefault(fam_of.get(eid), []).append((int(edges[eid]._ids[i]), need))
        base = gr.copy()
        cost = {}
        fam_grade, fam_status = {}, {}
        for k, (ids, land) in enumerate(fams):
            rq = reqs_by_fam.get(k)
            if not rq:
                continue
            verts = set()
            links = []
            for i in ids:
                ii = edges[i]._ids
                verts.update(int(v) for v in ii)
                for a_, b_ in zip(ii[:-1], ii[1:]):
                    if a_ != b_:
                        links.append((int(a_), int(b_), float(np.linalg.norm(X[a_] - X[b_]))))
            lv = [vkey[key] for key in land if key in vkey]
            b0 = {v: y0[v] for v in verts}
            for vi, need in rq:
                b0[vi] = max(b0[vi], need)
            g_base = max(grade_of(edges[i]) for i in ids)
            g_ok = None
            for g in [g_base] + [x for x in (0.07, 0.08, 0.09, 0.10, 0.11, 0.12) if x > g_base + 1e-9]:
                ac = {}
                for a_, b_, d in links:
                    ac.setdefault(a_, []).append((b_, d * g))
                    ac.setdefault(b_, []).append((a_, d * g))
                ys = _sub_maxprop(b0, verts, ac)
                if all(ys[v] <= y0[v] + 0.3 for v in lv):
                    g_ok = g
                    break
            if g_ok is None:
                fam_status[k] = 'too short for its clearance at 12 %: the lift spills past its landings'
                g_ok = 0.12
            else:
                fam_status[k] = 'ok' if g_ok <= g_base + 1e-9 else 'ramps %.0f %%' % (g_ok * 100)
            fam_grade[k] = g_ok
            for a_, b_, d in links:
                cost[(a_, b_)] = d * g_ok
                cost[(b_, a_)] = d * g_ok
            for vi, need in rq:
                base[vi] = max(base[vi], need)
        adj2 = [[(j, cost.get((i, j), c)) for j, c in row] for i, row in enumerate(adj)]
        y = maxprop(base, adj2)
        log('  heights pass %d: %d samples under a clearance rule, %d bridge families raised' % (it + 1, len(req_info), len(fam_grade)))
    net.adj2 = adj2
    # the batch 0.5 seam: the game roads' end heights
    pins = {}
    for e in edges:
        for end, sm in ((0, e.seam[0]), (-1, e.seam[1])):
            if sm:
                pins[int(e._ids[end])] = sm['y']
    if pins:
        floor = np.full(len(y), -1e9)
        for (eid, i), (need, what) in req_info.items():
            floor[edges[eid]._ids[i]] = need
        y = minprop_from(y, pins, adj2, floor)
    net.y_v = y
    for e in edges:
        e.y = y[e._ids]
        e.g = gr[e._ids]
    net.req_info = req_info
    net.fams, net.fam_of, net.fam_grade, net.fam_status = fams, fam_of, fam_grade, fam_status
    spill = 0.0
    for e in edges:
        if fam_of.get(e.id) in fam_grade:
            continue
        spill += float(((e.y - e.g) > RAISE).sum()) * rn.STEP
    net.spill = spill
    log('  raised outside the bridge families: %.0f studs of road' % spill)
    return y


def structures(net):
    """bridges / flyovers: connected raised runs. -> list of dicts with name, length, max height, clearances"""
    edges = net.edges
    runs = []
    for e in edges:
        if net.fam_of.get(e.id) not in net.fam_grade:
            continue
        h = e.y - e.g
        r = h > RAISE
        if not r.any():
            continue
        i = 0
        n = len(r)
        while i < n:
            if not r[i]:
                i += 1
                continue
            j = i
            while j + 1 < n and r[j + 1]:
                j += 1
            runs.append((e.id, max(0, i - 1), min(n - 1, j + 1)))
            i = j + 1
    # group runs by shared nodes / closeness
    parent = list(range(len(runs)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    ends = {}
    for k, (eid, i0, i1) in enumerate(runs):
        e = edges[eid]
        for key in ((e.a if i0 == 0 else None), (e.b if i1 == len(e.P) - 1 else None)):
            if key is not None:
                if key in ends:
                    parent[find(k)] = find(ends[key])
                else:
                    ends[key] = k
    # paired carriageways: one structure
    lines = [LineString(edges[eid].P[i0:i1 + 1]) if i1 > i0 else Point(edges[eid].P[i0]) for eid, i0, i1 in runs]
    tree = STRtree(lines)
    for k, L in enumerate(lines):
        for j in tree.query(L.buffer(50)):
            j = int(j)
            if j != k and norm(edges[runs[j][0]].name) == norm(edges[runs[k][0]].name) and lines[j].distance(L) < 50:
                parent[find(k)] = find(j)
    groups = {}
    for k in range(len(runs)):
        groups.setdefault(find(k), []).append(k)
    out = []
    for g, ks in groups.items():
        names = {}
        L = 0.0
        hmax = 0.0
        clear = []
        bridge_len = 0.0
        for k in ks:
            eid, i0, i1 = runs[k]
            e = edges[eid]
            seg = e.P[i0:i1 + 1]
            ln = float(rn.chain(seg)[-1]) if len(seg) > 1 else 0.0
            L += ln
            if e.bridge or e.layer >= 1:
                bridge_len += ln
            names[e.name or e.hw] = names.get(e.name or e.hw, 0) + ln
            hmax = max(hmax, float((e.y[i0:i1 + 1] - e.g[i0:i1 + 1]).max()))
            for i in range(i0, i1 + 1):
                ri = net.req_info.get((eid, i))
                if ri:
                    need, (kind, what, under) = ri
                    clear.append((float(e.y[i] - DECK - under), kind, what))
        name = max(names, key=names.get)
        cl = min(clear) if clear else None
        out.append(dict(name=name, runs=ks, length=L, bridge_len=bridge_len, hmax=hmax,
                        clear_min=cl[0] if cl else None, over=cl[1] + ': ' + str(cl[2]) if cl else None,
                        overs=sorted({(c[1], c[2]) for c in clear})))
    out.sort(key=lambda d: -d['length'])
    net.runs = runs
    return out


def norm(s):
    return rn.norm_name(s)
