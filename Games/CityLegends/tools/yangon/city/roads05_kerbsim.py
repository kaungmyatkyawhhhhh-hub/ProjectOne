"""What the builder really leaves at junctions (17 Nov 2026, roads05 fix 3: "make sure QA counts what the builder
really builds"). Python copies of YangonRoads.sideZone (where a road's kerb stops) and findMouths, over the data:

  kerb_cross   a kerb piece the builder KEEPS (sideZone false) that lies on another road's carriageway or the ring
               (more than 0.5 inside it): the loose / diagonal kerbs of the Studio tests
  mouth_short  a road end that is no join at all (no mouth, no continuation flag, no ring, no map edge, no deck foot)
               but stops within 12 studs of another carriageway: a gap the builder leaves open
  mouth_over   a road end (no mouth) whose last 40 studs cross another road's carriageway and stick out past it
  mouth_edge   = roads05_mouthsim's failed joins ("MOUTH FAILED")

Round corners (YangonRoads.inCorner / ownedBy) are not simulated: they only take more kerb away, except right past a
corner where the joining road keeps its own band (mineOnly), which this does not model.

    python roads05_kerbsim.py <net dir> [roads.json]   -> <net>/kerbsim.json + counts
"""
import json, math, os, sys

from shapely.geometry import Point, LineString
from shapely.ops import unary_union
from shapely.strtree import STRtree

import roads05_mouthsim as MS
from roads05_qa import quads

KERB_W = 0.9
STEP = 3.2


def poly_dist(net, oi, i, px, pz, a=None, n=None):
    """YangonRoads polyDist (with the half-plane option): (distance, foot x, foot z)"""
    s = net.roads[oi]['s']
    N = len(s)
    cut = net.cut[oi]
    lo, hi = max(0, i - 2), min(N - 2, i + 1)
    for j in range(lo, hi + 1):
        if j not in cut and j + 1 not in cut:
            A, B = s[j], s[j + 1]
            vx, vz = B[0] - A[0], B[2] - A[2]
            L2 = vx * vx + vz * vz
            if L2 > 1e-9:
                t = ((px - A[0]) * vx + (pz - A[2]) * vz) / L2
                if (j > 0 and (j - 1) in cut and t < 0) or (j + 2 <= N - 1 and (j + 2) in cut and t > 1):
                    return math.inf, None, None
    best, fx, fz, skipped = math.inf, None, None, False
    for j in range(lo, hi + 1):
        if j in cut or j + 1 in cut:
            continue
        x1, z1, x2, z2 = s[j][0], s[j][2], s[j + 1][0], s[j + 1][2]
        if a is not None:
            s1 = (x1 - a[0]) * n[0] + (z1 - a[1]) * n[1]
            s2 = (x2 - a[0]) * n[0] + (z2 - a[1]) * n[1]
            if s1 < 0 and s2 < 0:
                continue
            if s1 < 0:
                t = s1 / (s1 - s2)
                x1, z1 = x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
            elif s2 < 0:
                t = s2 / (s2 - s1)
                x2, z2 = x2 + (x1 - x2) * t, z2 + (z1 - z2) * t
        vx, vz = x2 - x1, z2 - z1
        L = vx * vx + vz * vz
        t = min(1, max(0, ((px - x1) * vx + (pz - z1) * vz) / L)) if L > 1e-12 else 0
        d = math.hypot(px - x1 - t * vx, pz - z1 - t * vz)
        if (t >= 1 - 1e-9 and j + 2 <= N - 1 and (j + 2) in cut) or (t <= 1e-9 and j - 1 >= 0 and (j - 1) in cut):
            skipped, d = True, math.inf
        if d < best:
            best, fx, fz = d, x1 + vx * t, z1 + vz * t
    if best == math.inf and a is None and not skipped:
        q = s[i]
        best, fx, fz = math.hypot(px - q[0], pz - q[2]), q[0], q[2]
    return best, fx, fz


def side_zone(net, me, px, pz, what='Kerb'):
    R, rad = net.ring_of(px, pz)
    if R and rad < R['RING_V'] + (KERB_W if what == 'Kerb' else 7.5):
        return True
    road = net.roads[me]
    near = net.near(px, pz, 3)
    mine = near.get(me)
    a = n = None
    for oi, (d, bi) in near.items():
        if oi == me or d > 72:
            continue
        o = net.roads[oi]
        oh = net.half_at(oi, bi)
        if road['kind'] == 'side' and o['kind'] == 'side':
            if poly_dist(net, oi, bi, px, pz)[0] < oh + 1:
                return True
            continue
        if o['rank'] < road['rank']:
            reach = KERB_W if what == 'Kerb' else max(o.get('walkL') or 7.5, o.get('walkR') or 7.5)
            if poly_dist(net, oi, bi, px, pz)[0] < oh + reach:
                return True
        else:
            if a is None and mine:
                _, fx, fz = poly_dist(net, me, mine[1], px, pz)
                if fx is not None:
                    L = math.hypot(px - fx, pz - fz)
                    if L > 1e-6:
                        a, n = (fx, fz), ((px - fx) / L, (pz - fz) / L)
            if poly_dist(net, oi, bi, px, pz, a, n)[0] < oh - 0.01:
                return True
    return False


def run(data):
    net = MS.Net(data)
    roads = data['roads']
    cw = [unary_union(quads(r['s'], net.cut[i])) for i, r in enumerate(roads)]
    tree = STRtree(cw)
    rings = [Point(R['cx'], R['cz']).buffer(R['RING_V'], 96) for R in net.rings]
    ringU = unary_union(rings) if rings else None
    out = dict(kerb_cross=[], mouth_short=[], mouth_over=[], mouth_edge=[], dropped=[])
    # kerbs
    for ri, r in enumerate(roads):
        s = r['s']
        cut = net.cut[ri]
        last = {-1: -99, 1: -99}
        for i in range(len(s) - 1):
            if i in cut or i + 1 in cut:
                continue
            A, B = s[i], s[i + 1]
            for side in (-1, 1):
                h = 6 if side < 0 else 7
                ra, rb = (-A[4], A[3]), (-B[4], B[3])
                pa = (A[0] + ra[0] * side * (A[h] + KERB_W / 2), A[2] + ra[1] * side * (A[h] + KERB_W / 2))
                pb = (B[0] + rb[0] * side * (B[h] + KERB_W / 2), B[2] + rb[1] * side * (B[h] + KERB_W / 2))
                seg = LineString([pa, pb])
                hits = [int(j) for j in tree.query(seg) if int(j) != ri]
                onring = ringU is not None and ringU.intersects(seg)
                if not hits and not onring:
                    continue
                L = seg.length
                m = max(1, int(L / STEP))
                for t in range(m + 1):
                    p = seg.interpolate(L * t / m)
                    on = None
                    for j in hits:
                        if cw[j].contains(p) and p.distance(cw[j].boundary) > 0.5:
                            on = roads[j]['name']
                            break
                    if on is None and onring:
                        for R, g in zip(net.rings, rings):
                            if g.contains(p) and p.distance(g.boundary) > 0.5:
                                on = R['name']
                                break
                    if on is None:
                        continue
                    if side_zone(net, ri, p.x, p.y, 'Kerb'):
                        continue
                    if i - last[side] > 6:
                        out['kerb_cross'].append(dict(road=r['name'], other=on, side=side, x=round(p.x, 1), z=round(p.y, 1)))
                    last[side] = i
                    break
    # joins
    mouths, dropped = net.find_mouths()
    out['dropped'] = dropped
    mouth_ends = set((m['ri'], m['i0']) for m in mouths)
    for m in mouths:
        e = net.walk(m)
        if e:
            q = roads[m['ri']]['s'][m['i0']]
            out['mouth_edge'].append(dict(road=m['road'], on=m['on'], edge=e, x=round(q[0], 1), z=round(q[2], 1)))
    deck_feet = []
    for d in data['decks']:
        for k in (0, -1):
            deck_feet.append((d['s'][k][0], d['s'][k][2]))
    ends = []
    for ri, r in enumerate(roads):
        s = r['s']
        if r.get('closed') or len(s) < 2:
            continue
        for k, i0, fl, ed in ((0, 0, 'startsOnEnd', 'edgeStart'), (-1, len(s) - 1, 'endsOnEnd', 'edgeEnd')):
            ends.append((ri, k, i0, fl, ed))
    endpts = [(roads[ri]['s'][k][0], roads[ri]['s'][k][2], ri) for ri, k, *_ in ends]
    from scipy.spatial import cKDTree
    ET = cKDTree([(x, z) for x, z, _ in endpts])
    for (ri, k, i0, fl, ed) in ends:
        r = roads[ri]
        if (ri, i0) in mouth_ends or r.get(fl) or r.get(ed) or i0 in net.cut[ri]:
            continue
        q = r['s'][k]
        p = Point(q[0], q[2])
        Rg, rad = net.ring_of(q[0], q[2])
        if Rg and rad < Rg['R_OUT'] + 2:
            continue
        if any(math.hypot(q[0] - x, q[2] - z) < 40 for x, z in deck_feet):
            continue
        # another road's end here (a node joined end to end, or a continuation's host)
        if any(endpts[j][2] != ri for j in ET.query_ball_point((q[0], q[2]), 4.0)):
            continue
        near = [int(j) for j in tree.query(p.buffer(12)) if int(j) != ri]
        if not near:
            continue
        dmin = min(cw[j].distance(p) for j in near)
        if 1.0 < dmin <= 12:
            out['mouth_short'].append(dict(road=r['name'], gap=round(dmin, 1), x=round(q[0], 1), z=round(q[2], 1)))
            continue
        # sticking out past a carriageway it crosses
        s = r['s']
        idx = range(min(len(s) - 1, 6), -1, -1) if k == 0 else range(max(0, len(s) - 7), len(s))
        tail = LineString([(s[i][0], s[i][2]) for i in idx])
        for j in near:
            if cw[j].distance(p) > 0.5 and tail.intersects(cw[j]) and roads[j]['rank'] < r['rank']:
                out['mouth_over'].append(dict(road=r['name'], on=roads[j]['name'], x=round(q[0], 1), z=round(q[2], 1)))
                break
    return out


def main():
    D = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(D, 'roads.json')
    res = run(json.load(open(path, encoding='utf-8')))
    json.dump(res, open(os.path.join(D, 'kerbsim.json'), 'w'), indent=1)
    print(json.dumps({k: len(v) for k, v in res.items()}))


if __name__ == '__main__':
    main()
