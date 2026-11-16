"""YangonRoads.findMouths + buildMouth's edge walk, in Python (17 Nov 2026): which mouths the Studio builder would fail
("MOUTH FAILED ... an edge of X never meets Y") and which roads it would drop as lying wholly on a bigger one.

    YANGON_SCALE=1to1 python roads05_mouthsim.py <net dir> [roads.json] [bbox x0 z0 x1 z1]
-> <net>/mouthsim.json {failed: [...], dropped: [...], mouths: n} and prints the counts.

Same rules as the Luau (YangonRoads.luau ~line 565 / 755, Roads.luau edges with the inner-bend wait); flat only.
"""
import json, math, os, sys
from collections import defaultdict

N_RING = 96
CELL = 24


def load(path):
    return json.load(open(path, encoding='utf-8'))


class Net:
    def __init__(self, data):
        self.data = data
        self.roads = data['roads']
        self.by = {r['name']: i for i, r in enumerate(self.roads)}
        self.cut = [set() for _ in self.roads]
        for n, lst in data['cut'].items():
            if n in self.by:
                self.cut[self.by[n]] = set(lst)  # 0-based
        self.rings = []
        for g in data['roundabouts']:
            ro = g['r_out']
            self.rings.append(dict(cx=g['c'][0], cz=g['c'][2], R_OUT=ro, RING_V=ro / math.cos(math.pi / N_RING), R_CUT=ro - 14, name=g['name']))
        # ring cut (radius < R_CUT of the nearest ring)
        for ri, r in enumerate(self.roads):
            for i, q in enumerate(r['s']):
                R, rad = self.ring_of(q[0], q[2])
                if R and rad < R['R_CUT']:
                    self.cut[ri].add(i)
        self.grid = defaultdict(list)
        for ri, r in enumerate(self.roads):
            c = self.cut[ri]
            for i, q in enumerate(r['s']):
                if i not in c:
                    self.grid[(math.floor(q[0] / CELL), math.floor(q[2] / CELL))].append((ri, i))
        self.edges = {}

    def ring_of(self, x, z):
        best, bd, rad = None, 1e18, 0
        for R in self.rings:
            d = math.hypot(x - R['cx'], z - R['cz'])
            if d - R['R_OUT'] < bd:
                best, bd, rad = R, d - R['R_OUT'], d
        return best, rad

    def near(self, px, pz, reach):
        best = {}
        cx, cz = math.floor(px / CELL), math.floor(pz / CELL)
        for dx in range(-reach, reach + 1):
            for dz in range(-reach, reach + 1):
                for ri, i in self.grid.get((cx + dx, cz + dz), ()):
                    q = self.roads[ri]['s'][i]
                    d = math.hypot(q[0] - px, q[2] - pz)
                    b = best.get(ri)
                    if b is None or d < b[0]:
                        best[ri] = (d, i)
        return best

    def half_at(self, ri, i):
        q = self.roads[ri]['s'][i]
        return max(q[6], q[7])

    def poly_dist(self, ri, i, px, pz):
        s = self.roads[ri]['s']
        n = len(s)
        cut = self.cut[ri]
        lo, hi = max(0, i - 2), min(n - 2, i + 1)
        for j in range(lo, hi + 1):
            if j not in cut and j + 1 not in cut:
                a, b = s[j], s[j + 1]
                vx, vz = b[0] - a[0], b[2] - a[2]
                L2 = vx * vx + vz * vz
                if L2 > 1e-9:
                    t = ((px - a[0]) * vx + (pz - a[2]) * vz) / L2
                    if (j > 0 and (j - 1) in cut and t < 0) or (j + 2 <= n - 1 and (j + 2) in cut and t > 1):
                        return math.inf
        best, skipped = math.inf, False
        for j in range(lo, hi + 1):
            if j not in cut and j + 1 not in cut:
                a, b = s[j], s[j + 1]
                vx, vz = b[0] - a[0], b[2] - a[2]
                L2 = vx * vx + vz * vz
                t = min(1, max(0, ((px - a[0]) * vx + (pz - a[2]) * vz) / L2)) if L2 > 1e-12 else 0
                d = math.hypot(px - a[0] - t * vx, pz - a[2] - t * vz)
                if (t >= 1 - 1e-9 and j + 2 <= n - 1 and (j + 2) in cut) or (t <= 1e-9 and j - 1 >= 0 and (j - 1) in cut):
                    skipped = True
                    d = math.inf
                best = min(best, d)
        if best == math.inf and not skipped:
            q = s[i]
            best = math.hypot(px - q[0], pz - q[2])
        return best

    def edge(self, ri):
        e = self.edges.get(ri)
        if e:
            return e
        s = self.roads[ri]['s']
        L, R = [], []
        for i, q in enumerate(s):
            dl = math.hypot(q[3], q[4]) or 1
            rx, rz = -q[4] / dl, q[3] / dl
            l = (q[0] - rx * q[6], q[2] - rz * q[6])
            r = (q[0] + rx * q[7], q[2] + rz * q[7])
            if i > 0:
                dx, dz = q[0] - s[i - 1][0], q[2] - s[i - 1][2]
                dm = math.hypot(dx, dz)
                if (l[0] - L[-1][0]) * dx + (l[1] - L[-1][1]) * dz <= 0.05 * dm:
                    l = L[-1]
                if (r[0] - R[-1][0]) * dx + (r[1] - R[-1][1]) * dz <= 0.05 * dm:
                    r = R[-1]
            L.append(l)
            R.append(r)
        self.edges[ri] = (L, R)
        return L, R

    def find_mouths(self, box=None):
        mouths, dropped = [], []
        for ri, r in enumerate(self.roads):
            s = r['s']
            n = len(s)
            for i0, step in ((0, 1), (n - 1, -1)):
                if (i0 == 0 and r.get('startsOnEnd')) or (i0 == n - 1 and r.get('endsOnEnd')):
                    continue
                s0 = s[i0]
                if box and not (box[0] <= s0[0] < box[2] and box[1] <= s0[2] < box[3]):
                    continue
                m = None
                Rg, rad = self.ring_of(s0[0], s0[2])
                if Rg and rad < Rg['R_OUT']:
                    m = dict(road=r['name'], ri=ri, i0=i0, step=step, ring=Rg, on=Rg['name'])
                elif i0 not in self.cut[ri]:
                    bestRank = None
                    for oi, (d, bi) in self.near(s0[0], s0[2], 2).items():
                        big = self.roads[oi]
                        if big['rank'] < r['rank'] and self.poly_dist(oi, bi, s0[0], s0[2]) < self.half_at(oi, bi) and (bestRank is None or big['rank'] < bestRank):
                            bestRank = big['rank']
                            m = dict(road=r['name'], ri=ri, i0=i0, step=step, big=oi, bigI=bi, on=big['name'])
                if not m:
                    continue

                def outside(px, pz):
                    if 'ring' in m:
                        R = m['ring']
                        return math.hypot(px - R['cx'], pz - R['cz']) > R['RING_V'] + 0.5
                    b = self.near(px, pz, 3).get(m['big'])
                    if not b:
                        return True
                    return self.poly_dist(m['big'], b[1], px, pz) > self.half_at(m['big'], b[1]) + 0.5
                L, Rr = self.edge(ri)
                k = i0
                while True:
                    ok = k not in self.cut[ri]
                    if ok:
                        q = s[k]
                        dl = math.hypot(q[3], q[4]) or 1
                        rx, rz = -q[4] / dl, q[3] / dl
                        lx, lz = q[0] - rx * q[6], q[2] - rz * q[6]
                        qx, qz = q[0] + rx * q[7], q[2] + rz * q[7]
                        for t in range(9):
                            if not outside(lx + (qx - lx) * t / 8, lz + (qz - lz) * t / 8):
                                ok = False
                                break
                    if ok:
                        break
                    k += step
                    if k < 0 or k > n - 1:
                        k = None
                        break
                if k is None:
                    dropped.append(dict(road=r['name'], on=m['on'], x=round(s0[0], 1), z=round(s0[2], 1)))
                    continue
                m['k'] = k
                mouths.append(m)
        return mouths, dropped

    def border(self, m):
        if 'ring' in m:
            R = m['ring']
            return [(R['cx'] + R['RING_V'] * math.cos(2 * math.pi * j / N_RING), R['cz'] + R['RING_V'] * math.sin(2 * math.pi * j / N_RING)) for j in range(N_RING)], True
        bi = m['big']
        big = self.roads[bi]['s']
        sk, sb = self.roads[m['ri']]['s'][m['k']], big[m['bigI']]
        dl = math.hypot(sb[3], sb[4]) or 1
        rx, rz = -sb[4] / dl, sb[3] / dl
        side = 1 if (sk[0] - sb[0]) * rx + (sk[2] - sb[2]) * rz > 0 else 0
        m['side'] = 'R' if side else 'L'
        cutB = self.cut[bi]
        lo = hi = m['bigI']
        while lo > 0 and (lo - 1) not in cutB and m['bigI'] - lo < 60:
            lo -= 1
        while hi < len(big) - 1 and (hi + 1) not in cutB and hi - m['bigI'] < 60:
            hi += 1
        E = self.edge(bi)[side]
        return E[lo:hi + 1], False

    def walk(self, m):
        """None when both edges meet the border, else which edge fails"""
        B, closed = self.border(m)
        nB = len(B)
        segs = [(B[j], B[(j + 1) % nB]) for j in range(nB if closed else nB - 1)]
        s = self.roads[m['ri']]['s']
        for nm, E in zip('LR', self.edge(m['ri'])):
            i = m['k']
            hit = False
            while True:
                j = i - m['step']
                if j < 0 or j > len(s) - 1:
                    break
                if any(seg_x(E[i], E[j], a, b) for a, b in segs):
                    hit = True
                    break
                i = j
            if not hit:
                # YangonRoads.MOUTH_SNAP: the edge's end within 30 studs of the border closes onto it (a shallow merge)
                p = E[i]
                d = min(seg_dist(p, a, b) for a, b in segs) if segs else math.inf
                if d < SNAP:
                    m['snapped'] = round(d, 1)
                    continue
                return nm
        return None


SNAP = 50.0  # = YangonRoads.MOUTH_SNAP


def seg_dist(p, a, b):
    vx, vz = b[0] - a[0], b[1] - a[1]
    L = vx * vx + vz * vz
    t = min(1, max(0, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vz) / L)) if L > 1e-12 else 0
    return math.hypot(p[0] - a[0] - t * vx, p[1] - a[1] - t * vz)


def seg_x(p, q, a, b):
    rX, rZ = q[0] - p[0], q[1] - p[1]
    sX, sZ = b[0] - a[0], b[1] - a[1]
    den = rX * sZ - rZ * sX
    if abs(den) < 1e-9:
        return False
    t = ((a[0] - p[0]) * sZ - (a[1] - p[1]) * sX) / den
    u = ((a[0] - p[0]) * rZ - (a[1] - p[1]) * rX) / den
    return -1e-6 <= t <= 1 + 1e-6 and -1e-6 <= u <= 1 + 1e-6


def run(data, box=None):
    net = Net(data)
    mouths, dropped = net.find_mouths(box)
    failed = []
    for m in mouths:
        e = net.walk(m)
        if e:
            q = data['roads'][m['ri']]['s'][m['i0']]
            failed.append(dict(road=m['road'], on=m['on'], edge=e, end='start' if m['i0'] == 0 else 'end',
                               on_kind='ring' if 'ring' in m else data['roads'][m['big']]['kind'], x=round(q[0], 1), z=round(q[2], 1)))
    snapped = [dict(road=m['road'], on=m['on'], gap=m['snapped'], x=round(data['roads'][m['ri']]['s'][m['i0']][0], 1), z=round(data['roads'][m['ri']]['s'][m['i0']][2], 1)) for m in mouths if 'snapped' in m]
    return dict(mouths=len(mouths), failed=failed, dropped=dropped, snapped=snapped)


def main():
    D = sys.argv[1]
    path = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].lstrip('-').replace('.', '').isdigit() else os.path.join(D, 'roads.json')
    nums = [float(a) for a in sys.argv[2:] if a.lstrip('-').replace('.', '').isdigit()]
    box = nums[:4] if len(nums) >= 4 else None
    res = run(load(path), box)
    json.dump(res, open(os.path.join(D, 'mouthsim.json'), 'w'), indent=1)
    print(json.dumps(dict(mouths=res['mouths'], failed=len(res['failed']), snapped=len(res['snapped']), dropped=len(res['dropped']))))


if __name__ == '__main__':
    main()
