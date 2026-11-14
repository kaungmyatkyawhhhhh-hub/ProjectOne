"""Whole-Yangon map (14 Nov 2026): NPC traffic lanes of a batch's main roads, for roads.py.

Format: src/shared/YangonLanes.lua's (RivieraLanes): lanes { road, way, lane, kind, closed, yangon = true, pts = {x,y,z,...} }
with points every ~STEP studs in the direction of travel, y = the surface + 0.15, and links { fromLane, fromK, toLane, toK }
in the GLOBAL numbering (RivieraTraffic.build appends module after module; each module's `first` must equal the count
before it + 1).

Which roads: every road with 2+ lanes a side, and the 1 + 1 trunk / primary / secondary / tertiary roads and the links.
Right-hand traffic. Lane 1 is the inner lane (by the centre line or the median), lane n the outer one.
  * offsets: a two-way road's lane k sits W (k - 0.5) right of the centre line (W = its lane width); a one-way
    carriageway's lane k sits inner + W (k - 0.5) from its inner edge (inner = the median's half on a divided road).
  * a lane stops before a junction, clear of every carriageway meeting there (the biggest one's reach + CLEAR); nodes
    joined by a road piece too short to hold a lane form one junction (one-way pieces inside it are respected).
  * links at a junction: straight on (within 35 degrees: lane k -> lane k, extra lanes merge into / split from the outer
    one), right turns from the outer lane into the outer lane, left turns from lane 1 into lane 1. A middle lane with
    no way on changes lanes (inner or outer) 40 studs before its end. A road that ends with no way on turns round (a
    two-way road: each lane into the same lane the other way; a divided road: onto the other carriageway); a one-way
    road that cannot turn round is dropped, and the drop is repeated until nothing dead remains (the dead-end check).
  * the batch 0.5 seam: lanes that end on a game road's map-edge end join its lanes in src/shared/YangonLanes*.lua.
Road names are made unique ("<name> B<tag>.<edge>") because RivieraTraffic.mergeRouteEnds keys on road + way.
"""
import math, os, re

import numpy as np

import geo
import roadnet as rn

STEP = 24.0
LIFT = 0.15
CLEAR = 6.0
CHARS = 189000
MAX_LINK = 180.0    # no junction link longer than this (studs, end to start)


def lane_offsets(e, way):
    """[(lane no, offset array right of e's direction)] for one direction of an edge"""
    lo, hi = rn.offsets(e)
    out = []
    if e.oneway:
        n = e.nf
        W = (hi - lo) / n
        for k in range(1, n + 1):
            out.append((k, lo + W * (k - 0.5)))
    elif way == 1:
        n = e.nf
        W = hi / n
        for k in range(1, n + 1):
            out.append((k, W * (k - 0.5)))
    else:
        n = e.nb
        W = -lo / n
        for k in range(1, n + 1):
            out.append((k, -W * (k - 0.5)))
    return out


def reach_at(e, end):
    lo, hi = rn.offsets(e)
    return max(abs(lo[end]), abs(hi[end]))


def build(net, tag, log=print):
    edges = [e for e in net.edges if e.traffic and len(e.P) >= 2]
    eset = {e.id for e in edges}
    # junctions: traffic degree per node
    inc = {}
    for e in edges:
        inc.setdefault(e.a, []).append((e, 0))
        inc.setdefault(e.b, []).append((e, -1))
    # all-road degree (a traffic road crossing a street is not a junction for traffic)
    trim = {}
    for key, lst in inc.items():
        if len(lst) >= 3 or (len(lst) == 2 and _turn(lst) > 35):
            trim[key] = max(reach_at(e, end) for e, end in lst) + CLEAR
        else:
            trim[key] = 0.0
    # clusters: edges too short to hold a lane between two trimmed nodes
    parent = {k: k for k in inc}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    internal = set()
    for e in edges:
        L = rn.chain(e.P)[-1]
        ta, tb = trim.get(e.a, 0), trim.get(e.b, 0)
        if L - ta - tb < 16:
            internal.add(e.id)
            parent[find(e.a)] = find(e.b)
    clusters = {}
    for k in inc:
        clusters.setdefault(find(k), []).append(k)
    # lane records
    lanes, index = [], {}
    for e in edges:
        if e.id in internal:
            continue
        c = rn.chain(e.P)
        L = c[-1]
        ta = trim.get(e.a, 0.0) if len(clusters[find(e.a)]) > 1 or trim.get(e.a, 0) else 0.0
        tb = trim.get(e.b, 0.0) if len(clusters[find(e.b)]) > 1 or trim.get(e.b, 0) else 0.0
        if e.seam[0]:
            ta = 0.0
        if e.seam[1]:
            tb = 0.0
        d0, d1 = ta, L - tb
        if d1 - d0 < 16:
            continue
        n = max(2, int(round((d1 - d0) / STEP))) + 1
        ds = np.linspace(d0, d1, n)
        X = np.interp(ds, c, e.P[:, 0])
        Z = np.interp(ds, c, e.P[:, 1])
        Y = np.interp(ds, c, e.y) + LIFT
        Dx = np.interp(ds, c, e.D[:, 0])
        Dz = np.interp(ds, c, e.D[:, 1])
        Dl = np.hypot(Dx, Dz)
        Dx, Dz = Dx / Dl, Dz / Dl
        ways = (1,) if e.oneway else (1, -1)
        for way in ways:
            nl = e.nf if way == 1 else e.nb
            for k, off in lane_offsets(e, way):
                o = np.interp(ds, c, off)
                pts = np.stack([X + (-Dz) * o, Y, Z + Dx * o], axis=1)
                if way == -1:
                    pts = pts[::-1]
                index[(e.id, way, k)] = len(lanes)
                lanes.append(dict(edge=e, way=way, lane=k, n=nl, pts=pts,
                                  road='%s B%s.%d' % ((e.name or e.hw).replace('"', "'"), tag, e.id),
                                  kind='route' if nl >= 2 or (not e.oneway and max(e.nf, e.nb) >= 2) else 'street'))
    links = []

    def link(a, fk, b, tk, why):
        links.append([a, fk, b, tk, why])

    def npts(i):
        return len(lanes[i]['pts'])

    # lane groups arriving at / leaving each cluster
    arrive, leave = {}, {}
    for (eid, way, k), i in index.items():
        e = net.edges[eid]
        end_key = e.b if way == 1 else e.a
        start_key = e.a if way == 1 else e.b
        arrive.setdefault(find(end_key), {}).setdefault((eid, way), {})[k] = i
        leave.setdefault(find(start_key), {}).setdefault((eid, way), {})[k] = i
    # one-way pieces inside a cluster: which arriving node reaches which leaving node
    adj = {}
    for e in edges:
        if e.id in internal:
            adj.setdefault(e.a, set()).add(e.b)
            if not e.oneway:
                adj.setdefault(e.b, set()).add(e.a)

    def reach(a):
        seen = {a}
        st = [a]
        while st:
            x = st.pop()
            for y in adj.get(x, ()):
                if y not in seen:
                    seen.add(y)
                    st.append(y)
        return seen
    rcache = {}
    stats = dict(straight=0, right=0, left=0, uturn=0, change=0, turnround=0, seam=0, dropped=0)
    for cl in set(list(arrive) + list(leave)):
        ins = arrive.get(cl, {})
        outs = leave.get(cl, {})
        for (eid, way), lin in ins.items():
            e = net.edges[eid]
            end_key = e.b if way == 1 else e.a
            if end_key not in rcache:
                rcache[end_key] = reach(end_key)
            r = rcache[end_key]
            a_last = lanes[next(iter(lin.values()))]['pts']
            din = a_last[-1] - a_last[-2]
            din = np.array([din[0], din[2]])
            din /= max(np.linalg.norm(din), 1e-9)
            right_in = np.array([-din[1], din[0]])
            options = []
            for (fid, fway), lout in outs.items():
                f = net.edges[fid]
                start_key = f.a if fway == 1 else f.b
                if start_key not in r:
                    continue
                if fid == eid:
                    continue  # never straight back onto itself
                b_pts = lanes[next(iter(lout.values()))]['pts']
                dout = b_pts[1] - b_pts[0]
                dout = np.array([dout[0], dout[2]])
                dout /= max(np.linalg.norm(dout), 1e-9)
                ang = math.degrees(math.atan2(float(dout @ right_in), float(dout @ din)))
                gap = math.hypot(b_pts[0][0] - a_last[-1][0], b_pts[0][2] - a_last[-1][2])
                if gap > MAX_LINK:
                    continue  # (a turn across a whole cluster of junctions: too long a curve)
                options.append((ang, fid, fway, lout))
            n_in = max(lin)
            fed = {k: 0 for k in lin}
            untrimmed = trim.get(end_key, 0.0) == 0.0 and len(clusters[cl]) == 1
            for ang, fid, fway, lout in options:
                n_out = max(lout)
                if abs(ang) < 35:
                    for k, ia in lin.items():
                        kk = min(k, n_out)
                        link(ia, npts(ia), lout[kk], 2 if untrimmed else 1, 'straight')
                        fed[k] += 1
                        stats['straight'] += 1
                    for kk in range(n_in + 1, n_out + 1):
                        link(lin[n_in], npts(lin[n_in]), lout[kk], 1, 'straight, a lane more')
                elif 35 <= ang <= 160:
                    link(lin[n_in], npts(lin[n_in]), lout[n_out], 1, 'right turn')
                    fed[n_in] += 1
                    stats['right'] += 1
                elif -160 <= ang <= -35:
                    link(lin[1], npts(lin[1]), lout[1], 1, 'left turn')
                    fed[1] += 1
                    stats['left'] += 1
            # middle lanes (or any lane) with no way on: change lanes before the end
            if options:
                for k, ia in lin.items():
                    if fed[k]:
                        continue
                    tgt = None
                    for kk in sorted(lin, key=lambda q: abs(q - k)):
                        if kk != k and fed[kk]:
                            tgt = kk
                            break
                    if tgt is None:
                        continue
                    ib = lin[tgt]
                    fk = max(2, npts(ia) - 2)
                    tk = min(npts(ib) - 1, fk + 1)
                    if tk <= fk - 1 or npts(ib) < 4:
                        tk = max(1, min(npts(ib) - 1, fk))
                    link(ia, fk, ib, tk, 'lane change before the junction')
                    fed[k] += 1
                    stats['change'] += 1
            if not options or not any(fed.values()):
                # U-turn on a two-way road (into the same edge the other way), else onto a partner carriageway
                ok = False
                if not e.oneway:
                    back = index.get((eid, -way, 1))
                    if back is not None:
                        for k, ia in lin.items():
                            ib = index.get((eid, -way, min(k, e.nb if way == 1 else e.nf)))
                            link(ia, npts(ia), ib, 1, 'turns round')
                        ok = True
                else:
                    p_end = lanes[lin[1]]['pts'][-1]
                    best = None
                    for (fid, fway), lout in [(k_, v_) for cl2 in leave.values() for k_, v_ in cl2.items()]:
                        q0 = lanes[lout[1]]['pts'][0]
                        d = math.hypot(q0[0] - p_end[0], q0[2] - p_end[2])
                        if d > 140:
                            continue
                        dq = lanes[lout[1]]['pts'][1] - q0
                        dq = np.array([dq[0], dq[2]])
                        dq /= max(np.linalg.norm(dq), 1e-9)
                        if dq @ din > -0.7:
                            continue
                        if best is None or d < best[0]:
                            best = (d, lout)
                    if best:
                        lout = best[1]
                        for k, ia in lin.items():
                            link(ia, npts(ia), lout[min(k, max(lout))], 1, 'turns round onto the other carriageway')
                        ok = True
                if ok:
                    stats['turnround'] += 1
    # the batch 0.5 seam
    seam_links, seam_first = _seam(net, lanes, index, link)
    stats['seam'] = seam_links
    # (2026-11-14, batch 2) the seam with an earlier batch: a lane that ends on its border runs on into that batch's lane
    # there (and that batch's lanes ending there run on into ours), instead of turning round
    cont, nb = _seam_batches(net, lanes, link, tag)
    if cont:
        links[:] = [x for x in links if not (not isinstance(x[0], tuple) and x[0] in cont and x[4].startswith('turns round'))]
    stats['seam_batches'] = nb
    # dead-end check: drop lanes whose end leads nowhere, repeatedly
    lanes, links, dropped = _prune(lanes, links)
    stats['dropped'] = dropped
    return lanes, links, stats, seam_first


def _turn(lst):
    (e1, end1), (e2, end2) = lst
    d1 = e1.D[end1] * (1 if end1 == -1 else -1)   # arriving direction at the node
    d2 = e2.D[end2] * (1 if end2 == 0 else -1)     # leaving direction
    return math.degrees(math.acos(float(np.clip(d1 @ d2, -1, 1))))


def existing_modules():
    """lane counts of the modules in src/shared that come before the batch modules"""
    sh = os.path.join(geo.ROOT, 'src', 'shared')
    names = ['RivieraLanes.lua', 'RivieraLanesHighway.lua', 'YangonLanes.lua']
    k = 2
    while os.path.exists(os.path.join(sh, 'YangonLanes%d.lua' % k)):
        names.append('YangonLanes%d.lua' % k)
        k += 1
    out = []
    for nm in names:
        p = os.path.join(sh, nm)
        if os.path.exists(p):
            src = open(p, encoding='utf-8').read()
            m = re.search(r'first\s*=\s*(\d+)', src)
            out.append((nm, len(re.findall(r'\{ road = ', src)), int(m.group(1)) if m else 1, src))
    return out


def _yangon_lanes():
    """the batch 0.5 lanes (YangonLanes*.lua) with their global numbers"""
    res = []
    for nm, n, first, src in existing_modules():
        if not nm.startswith('YangonLanes'):
            continue
        k = 0
        for m in re.finditer(r'\{ road = "([^"]*)", way = (-?\d+), lane = (\d+), kind = "(\w+)", closed = (\w+)[^}]*?pts = \{ ([^}]*) \}', src):
            v = [float(x) for x in m.group(6).split(',')]
            pts = np.array(v).reshape(-1, 3)
            res.append(dict(g=first + k, road=m.group(1), way=int(m.group(2)), lane=int(m.group(3)), pts=pts))
            k += 1
    return res


def _seam(net, lanes, index, link):
    """join the lanes that reach a game road's map-edge end to that road's lanes (they start ~30 studs inside it)"""
    old = _yangon_lanes()
    if not old:
        return 0, None
    n = 0

    def match(p, d, cands_pts, ahead):
        """the old lane whose point (first if ahead else last) lies on this lane's line, 0..60 studs ahead / behind"""
        best = None
        dl = math.hypot(d[0], d[2])
        if dl < 1e-6:
            return None
        u = (d[0] / dl, d[2] / dl)
        for o in old:
            q = o['pts'][0] if ahead else o['pts'][-1]
            dq = (o['pts'][1] - o['pts'][0]) if ahead else (o['pts'][-1] - o['pts'][-2])
            if dq[0] * u[0] + dq[2] * u[1] <= 0:
                continue
            vx, vz = q[0] - p[0], q[2] - p[2]
            along = (vx * u[0] + vz * u[1]) * (1 if ahead else -1)
            lat = abs(vx * u[1] - vz * u[0])
            if -2 <= along <= 60 and lat < 4.5 and (best is None or lat < best[0]):
                best = (lat, o)
        return best
    for i, l in enumerate(lanes):
        e = l['edge']
        at_end = (l['way'] == 1 and e.seam[1]) or (l['way'] == -1 and e.seam[0])
        at_start = (l['way'] == 1 and e.seam[0]) or (l['way'] == -1 and e.seam[1])
        if at_end:
            best = match(l['pts'][-1], l['pts'][-1] - l['pts'][-2], None, True)
            if best:
                link(i, len(l['pts']), ('g', best[1]['g']), 1, 'onto batch 0.5: ' + best[1]['road'])
                n += 1
        if at_start:
            best = match(l['pts'][0], l['pts'][1] - l['pts'][0], None, False)
            if best:
                link(('g', best[1]['g']), len(best[1]['pts']), i, 1, 'from batch 0.5: ' + best[1]['road'])
                n += 1
    return n, None


def _batch_lanes(u):
    """batch u's lanes from build/city/YangonLanesB<u>_<k>.lua with their global numbers"""
    res = []
    k = 1
    while True:
        p = os.path.join(geo.BUILD, 'city', 'YangonLanesB%s_%d.lua' % (u, k))
        if not os.path.exists(p):
            break
        src = open(p, encoding='utf-8').read()
        first = int(re.search(r'first\s*=\s*(\d+)', src).group(1))
        j = 0
        for m in re.finditer(r'\{ road = "([^"]*)", way = (-?\d+), lane = (\d+), kind = "(\w+)", closed = (\w+)[^}]*?pts = \{ ([^}]*) \}', src):
            v = [float(x) for x in m.group(6).split(',')]
            res.append(dict(g=first + j, road=m.group(1), way=int(m.group(2)), lane=int(m.group(3)), pts=np.array(v).reshape(-1, 3)))
            j += 1
        k += 1
    return res


BATCH_ORDER = ('1', '2', '3')


def _seam_batches(net, lanes, link, tag):
    """(2026-11-14, batch 2) join the lanes that end / start on an earlier batch's border (a cut end) to that batch's lanes
    starting / ending there (the same spot within 4.5 studs across, 0..12 along, the same heading). Returns (the set of
    our lanes whose end now runs on, the number of links)."""
    if tag not in BATCH_ORDER:
        return set(), 0
    from shapely.geometry import Point
    cont, n = set(), 0
    for u in BATCH_ORDER[:BATCH_ORDER.index(tag)]:
        old = _batch_lanes(u)
        if not old:
            continue
        poly = geo.batch_poly(u)
        S0 = np.array([[o['pts'][0][0], o['pts'][0][2]] for o in old])
        S1 = np.array([[o['pts'][-1][0], o['pts'][-1][2]] for o in old])

        def best_of(p, d, ends, ahead):
            dl = math.hypot(d[0], d[2])
            if dl < 1e-6:
                return None
            ux, uz = d[0] / dl, d[2] / dl
            dd = np.hypot(ends[:, 0] - p[0], ends[:, 1] - p[2])
            best = None
            for j in np.nonzero(dd < 14.0)[0]:
                o = old[int(j)]
                q = o['pts'][0] if ahead else o['pts'][-1]
                dq = (o['pts'][1] - o['pts'][0]) if ahead else (o['pts'][-1] - o['pts'][-2])
                ql = math.hypot(dq[0], dq[2])
                if ql < 1e-6 or (dq[0] * ux + dq[2] * uz) / ql < 0.85:
                    continue
                vx, vz = q[0] - p[0], q[2] - p[2]
                along = (vx * ux + vz * uz) * (1 if ahead else -1)
                lat = abs(vx * uz - vz * ux)
                if -4 <= along <= 12 and lat < 4.5 and (best is None or lat < best[0]):
                    best = (lat, o)
            return best
        for i, l in enumerate(lanes):
            e = l['edge']
            cut = getattr(e, 'cut', None) or [False, False]
            end_i, start_i = (1, 0) if l['way'] == 1 else (0, 1)
            if cut[end_i]:
                p = l['pts'][-1]
                if poly.distance(Point(p[0], p[2])) < 6.0:
                    b = best_of(p, l['pts'][-1] - l['pts'][-2], S0, True)
                    if b:
                        link(i, len(l['pts']), ('g', b[1]['g']), 1, 'onto batch %s: %s' % (u, b[1]['road']))
                        cont.add(i)
                        n += 1
            if cut[start_i]:
                p = l['pts'][0]
                if poly.distance(Point(p[0], p[2])) < 6.0:
                    b = best_of(p, l['pts'][1] - l['pts'][0], S1, False)
                    if b:
                        link(('g', b[1]['g']), len(b[1]['pts']), i, 1, 'from batch %s: %s' % (u, b[1]['road']))
                        n += 1
    return cont, n


def _prune(lanes, links):
    """drop lanes whose end has no link (closed lanes excepted), until none is left; renumber"""
    alive = [True] * len(lanes)
    dropped = 0
    while True:
        out_end = [False] * len(lanes)
        for a, fk, b, tk, why in links:
            if isinstance(a, tuple) or not alive[a]:
                continue
            if isinstance(b, tuple) or alive[b]:
                if fk >= len(lanes[a]['pts']) - 3:
                    out_end[a] = True
        changed = False
        for i in range(len(lanes)):
            if alive[i] and not out_end[i]:
                alive[i] = False
                dropped += 1
                changed = True
        if not changed:
            break
    new = {}
    keep = []
    for i, l in enumerate(lanes):
        if alive[i]:
            new[i] = len(keep)
            keep.append(l)
    out = []
    for a, fk, b, tk, why in links:
        if not isinstance(a, tuple) and a not in new:
            continue
        if not isinstance(b, tuple) and b not in new:
            continue
        out.append([a if isinstance(a, tuple) else new[a], fk, b if isinstance(b, tuple) else new[b], tk, why])
    return keep, out, dropped


def first_index(tag):
    """the global number of this batch's first lane: after src/shared's modules and the earlier batches' modules"""
    total = sum(n for _, n, _, _ in existing_modules())
    for t in ('1', '2', '3'):
        if t == tag:
            break
        k = 1
        while True:
            p = os.path.join(geo.BUILD, 'city', 'YangonLanesB%s_%d.lua' % (t, k))
            if not os.path.exists(p):
                break
            total += len(re.findall(r'\{ road = ', open(p, encoding='utf-8').read()))
            k += 1
    return total + 1


def fmt(v):
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'


def write(lanes, links, tag, outdir):
    first = first_index(tag)
    for f in os.listdir(outdir):
        if re.match(r'YangonLanesB%s_\d+\.lua$' % tag, f):
            os.remove(os.path.join(outdir, f))
    lane_lines = []
    for l in lanes:
        pts = ','.join('%s,%s,%s' % (fmt(p[0]), fmt(p[1]), fmt(p[2])) for p in l['pts'])
        outer = ', outer = true' if l['n'] >= 2 and l['lane'] == l['n'] else ''   # (v5's flag: the spawn's lane)
        lane_lines.append('\t\t{ road = "%s", way = %d, lane = %d, kind = "%s", closed = false, yangon = true%s, pts = { %s } },' % (
            l['road'], l['way'], l['lane'], l['kind'], outer, pts))
    link_lines = {}
    for a, fk, b, tk, why in links:
        ga = a[1] if isinstance(a, tuple) else a + first
        gb = b[1] if isinstance(b, tuple) else b + first
        owner = a if not isinstance(a, tuple) else b
        link_lines.setdefault(owner, []).append('\t\t{ %d, %d, %d, %d },' % (ga, fk, gb, tk))
    mods = []
    cur, cur_links, start = [], [], 0
    size = 0
    for i, ln in enumerate(lane_lines):
        ll = link_lines.get(i, [])
        add = len(ln) + sum(len(x) + 1 for x in ll) + 1
        if cur and size + add > CHARS - 600:
            mods.append((start, cur, cur_links))
            cur, cur_links, size, start = [], [], 0, i
        cur.append(ln)
        cur_links += ll
        size += add
    if cur:
        mods.append((start, cur, cur_links))
    files = []
    for m, (start, ls, lk) in enumerate(mods):
        src = '\n'.join(['-- generated by tools/yangon/city/roads.py (batch %s roads, OSM ODbL): do not edit' % tag,
                         '-- Yangon batch %s traffic lanes, module %d of %d; numbered on from the modules before it (`first`),' % (tag, m + 1, len(mods)),
                         '-- links in the global numbering (RivieraTraffic.build appends the modules in order)',
                         'return {', '\tfirst = %d,' % (first + start), '\tlanes = {'] + ls + ['\t},', '\tlinks = {'] + lk + ['\t},', '}']) + '\n'
        assert len(src) < 190000, len(src)
        p = os.path.join(outdir, 'YangonLanesB%s_%d.lua' % (tag, m + 1))
        open(p, 'w', encoding='utf-8', newline='\n').write(src)
        files.append((p, len(src), len(ls), first + start))
    return files, first
