"""
Road meshes, step 2 (2026-11-06, owner: "make all the roads smooth like in the blender"): turns the
export into meshes, cut into map cells, each kind its own mesh per cell. Plain Python; the output
(a pickle) goes to tools/road_mesh/export_fbx.py, which runs in Blender.

  R   the road surface: the real triangles from the place (hand fixes included), joined up
  L   the white lines and zebra stripes; the long solid lines along a smooth curve
  KS  kerbs (KR red, KW white): a rounded profile along a smooth curve through the old pieces
  PP  pavements (PB, PH, PC: the patterned ones)
  S   concrete shoulders

  islands between roads: rebuilt from the outline of their triangles, rounded, with a kerb all round
  (owner, 2026-11-06, a picture of the island at the top of the West Switchbacks: "the curb is too wide
  and not good": the old islands' edges followed the road samples in steps)

The drives are cut out of the kerbs and pavements (they are built when the server starts). Nothing is laid
where a road already runs: a pavement's stub past a junction corner lay on the asphalt.

run:  python tools/road_mesh/build.py <folder from collect.py>
"""
import math
import os
import pickle
import sys

from shapely.geometry import Point, Polygon
from shapely.ops import unary_union

BASE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+,-./:;<=>?@[]^_{|}"
B = len(BASE)
M = (B * B - 1) // 2
IDX = {c: i for i, c in enumerate(BASE)}
Q = 50.0
CELL = 384
MAX_TRIS = 17000
EDGE_DEEP = 3.0  # the side of a pavement or shoulder goes this far down
TOL = 0.02  # lines are thinned this close to the curve

work = sys.argv[1]


def decode(s, i=0):
    """yields the numbers in s from position i; stops at a character that isn't one"""
    n = len(s)
    while i < n:
        c = s[i]
        if c == "~":
            j = s.index("~", i + 1)
            yield int(s[i + 1 : j])
            i = j + 1
        else:
            yield (IDX[c] * B + IDX[s[i + 1]]) - M
            i += 2


def read_road():
    s = open(os.path.join(work, "R.txt"), encoding="utf-8").read()
    v = list(decode(s))
    assert len(v) % 9 == 0, len(v)
    out = []
    px = py = pz = 0
    for k in range(0, len(v), 9):
        px += v[k]
        py += v[k + 1]
        pz += v[k + 2]
        a = (px / Q, py / Q, pz / Q)
        b = ((px + v[k + 3]) / Q, (py + v[k + 4]) / Q, (pz + v[k + 5]) / Q)
        c = ((px + v[k + 6]) / Q, (py + v[k + 7]) / Q, (pz + v[k + 8]) / Q)
        out.append((a, b, c))
    return out


def read_lines():
    s = open(os.path.join(work, "L.txt"), encoding="utf-8").read()
    v = list(decode(s))
    assert len(v) % 9 == 0, len(v)
    out = []
    px = py = pz = 0
    for k in range(0, len(v), 9):
        px += v[k]
        py += v[k + 1]
        pz += v[k + 2]
        c = (px / Q, py / Q, pz / Q)
        out.append((c, (v[k + 3] / Q, v[k + 4] / Q, v[k + 5] / Q), (v[k + 6] / Q, v[k + 7] / Q, v[k + 8] / Q)))
    return out


def read_chains():
    out = []
    for line in open(os.path.join(work, "C.txt"), encoding="utf-8").read().split("\n"):
        if not line:
            continue
        kind, road, side, variant, width, data = line.split("|", 5)
        pts, cols = [], []
        i, n = 0, len(data)
        px = py = pz = 0
        while i < n:
            vals = []
            while len(vals) < 3:
                if data[i] == "~":
                    j = data.index("~", i + 1)
                    vals.append(int(data[i + 1 : j]))
                    i = j + 1
                else:
                    vals.append((IDX[data[i]] * B + IDX[data[i + 1]]) - M)
                    i += 2
            px += vals[0]
            py += vals[1]
            pz += vals[2]
            pts.append((px / Q, py / Q, pz / Q))
            cols.append(int(data[i]))
            i += 1
        out.append(dict(kind=kind, road=road, side=int(side), variant=variant, width=float(width), pts=pts, cols=cols))
    return out


def read_drives():
    lines = open(os.path.join(work, "A.txt"), encoding="utf-8").read().strip().split("\n")
    out = []
    for ln in lines[1:]:
        x, z, lx, lz, w, t0, t1 = map(float, ln.split())
        out.append((x, z, lx, lz, w, t0 - 1.5, t1 + 1.5))
    return out


drives = read_drives()
DG = 64
drive_grid = {}
for d in drives:
    reach = int(max(d[4], d[6] - d[5]) / DG) + 2
    cx, cz = int(d[0] // DG), int(d[1] // DG)
    for gx in range(cx - reach, cx + reach + 1):
        for gz in range(cz - reach, cz + reach + 1):
            drive_grid.setdefault((gx, gz), []).append(d)


def near_drive(x, z, far=10.0):
    for d in drive_grid.get((int(x // DG), int(z // DG)), ()):
        if math.hypot(x - d[0], z - d[1]) < max(d[4], d[6] - d[5]) + far:
            return True
    return False


def in_drive(x, z):
    for d in drive_grid.get((int(x // DG), int(z // DG)), ()):
        dx, dz = x - d[0], z - d[1]
        t = dx * d[2] + dz * d[3]
        u = dx * -d[3] + dz * d[2]
        if d[5] <= t <= d[6] and abs(u) <= d[4] / 2:
            return True
    return False


def smooth_y(pts, width=2):
    n = len(pts)
    out = []
    for i in range(n):
        lo, hi = max(i - width, 0), min(i + width, n - 1)
        y = sum(pts[j][1] for j in range(lo, hi + 1)) / (hi - lo + 1)
        out.append((pts[i][0], y, pts[i][2]))
    return out


def relax(pts, rounds=3, k=0.5):
    """takes the zig-zag out of a line (a road's samples in steps); the ends stay"""
    n = len(pts)
    if n < 3:
        return pts
    for _ in range(rounds):
        out = [pts[0]]
        for i in range(1, n - 1):
            a, b, c = pts[i - 1], pts[i], pts[i + 1]
            out.append((b[0] + k * ((a[0] + c[0]) / 2 - b[0]), b[1], b[2] + k * ((a[2] + c[2]) / 2 - b[2])))
        out.append(pts[-1])
        pts = out
    return pts


def catmull(p0, p1, p2, p3, t):
    t2, t3 = t * t, t * t * t
    return tuple(
        0.5 * (2 * p1[k] + (p2[k] - p0[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (3 * p1[k] - p0[k] - 3 * p2[k] + p3[k]) * t3)
        for k in range(3)
    )


def flat_dir(a, b):
    dx, dz = b[0] - a[0], b[2] - a[2]
    L = math.hypot(dx, dz)
    return (dx / L, dz / L) if L > 1e-6 else None


def curve(pts, cols):
    """more points where the line turns: a Catmull-Rom through the old pieces' middles"""
    n = len(pts)
    out, oc = [pts[0]], [cols[0]]
    for i in range(n - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, n - 1)]
        d1, d2, d3 = flat_dir(p0, p1), flat_dir(p1, p2), flat_dir(p2, p3)
        turn = 0.0
        if d1 and d2:
            turn = max(turn, abs(math.atan2(d1[0] * d2[1] - d1[1] * d2[0], d1[0] * d2[0] + d1[1] * d2[1])))
        if d2 and d3:
            turn = max(turn, abs(math.atan2(d2[0] * d3[1] - d2[1] * d3[0], d2[0] * d3[0] + d2[1] * d3[1])))
        # (a sharp corner in the old line is a junction or a piece's end, not a curve)
        steps = 1 if turn > math.radians(40) else min(max(1, math.ceil(math.degrees(turn) / 1.2)), 6)
        for s in range(1, steps + 1):
            out.append(catmull(p0, p1, p2, p3, s / steps) if steps > 1 else p2)
            oc.append(cols[i])
    return out, oc


def perp(a, b, p):
    ax, ay, az = a
    dx, dy, dz = b[0] - ax, b[1] - ay, b[2] - az
    L2 = dx * dx + dy * dy + dz * dz
    if L2 < 1e-9:
        return math.dist(a, p)
    t = max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy + (p[2] - az) * dz) / L2))
    return math.dist((ax + dx * t, ay + dy * t, az + dz * t), p)


def thin(pts, cols, keep_all=False):
    n = len(pts)
    mark = [False] * n
    mark[0] = mark[-1] = True
    for i in range(1, n):
        if cols[i] != cols[i - 1]:
            mark[i] = mark[i - 1] = True
    idx = [i for i in range(n) if mark[i]]
    stack = list(zip(idx, idx[1:]))
    while stack:
        a, b = stack.pop()
        worst, wi = 0.0, None
        for i in range(a + 1, b):
            d = perp(pts[a], pts[b], pts[i])
            if d > worst:
                worst, wi = d, i
        if wi is not None and worst > TOL:
            mark[wi] = True
            stack.append((a, wi))
            stack.append((wi, b))
    return [pts[i] for i in range(n) if mark[i]], [cols[i] for i in range(n) if mark[i]]


def near_points(pts, cols):
    """short steps by a drive, so the cut in the kerb is clean"""
    out, oc = [pts[0]], [cols[0]]
    for i in range(1, len(pts)):
        a, b = pts[i - 1], pts[i]
        L = math.dist(a, b)
        mid = ((a[0] + b[0]) / 2, (a[2] + b[2]) / 2)
        steps = 1
        if near_drive(mid[0], mid[1], 12 + L):
            steps = max(1, int(L / 0.6))
        elif L > 30:
            steps = int(L / 30) + 1
        for s in range(1, steps + 1):
            t = s / steps
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t))
            oc.append(cols[i - 1])
    return out, oc


class Mesh:
    __slots__ = ("v", "uv", "f", "index")

    def __init__(self):
        self.v, self.uv, self.f, self.index = [], [], [], {}

    def vert(self, p, uv, strip=0):
        key = (round(p[0], 2), round(p[1], 2), round(p[2], 2), strip, round(uv[0], 2), round(uv[1], 2))
        i = self.index.get(key)
        if i is None:
            i = len(self.v)
            self.index[key] = i
            self.v.append(p)
            self.uv.append(uv)
        return i

    def tri(self, a, b, c, ua, ub, uc, strip=0):
        self.f.append((self.vert(a, ua, strip), self.vert(b, ub, strip), self.vert(c, uc, strip)))

    def quad(self, a, b, c, d, ua, ub, uc, ud, strip=0):
        self.tri(a, b, c, ua, ub, uc, strip)
        self.tri(a, c, d, ua, uc, ud, strip)


meshes = {}


def mesh_for(kind, x, z):
    key = (kind, int(x // CELL), int(z // CELL))
    m = meshes.get(key)
    if m is None:
        m = Mesh()
        meshes[key] = m
    return m


def up_tri(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    return (uz * vx - ux * vz) > 0  # the normal's height


def orient(q, uv, want):
    """a quad's corners, turned so it faces `want` (the mesh shows one side only: a right-handed normal)"""
    a, b, c = q[0], q[1], q[2]
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    n = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
    if n[0] * want[0] + n[1] * want[1] + n[2] * want[2] < 0:
        return [q[0], q[3], q[2], q[1]], [uv[0], uv[3], uv[2], uv[1]]
    return q, uv


U_ROAD = 32.0
ROAD = read_road()
RG = 12
road_grid = {}
for t in ROAD:
    xs = [q[0] for q in t]
    zs = [q[2] for q in t]
    for gx in range(int(min(xs) // RG), int(max(xs) // RG) + 1):
        for gz in range(int(min(zs) // RG), int(max(zs) // RG) + 1):
            road_grid.setdefault((gx, gz), []).append(t)


def road_at(x, y, z):
    """is (x, z) on a road about this high?"""
    for a, b, c in road_grid.get((int(x // RG), int(z // RG)), ()):
        d = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
        if abs(d) < 1e-9:
            continue
        l1 = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / d
        l2 = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / d
        l3 = 1 - l1 - l2
        if l1 >= -0.001 and l2 >= -0.001 and l3 >= -0.001 and abs(l1 * a[1] + l2 * b[1] + l3 * c[1] - y) < 2.5:
            return True
    return False


for a, b, c in ROAD:
    cx, cz = (a[0] + b[0] + c[0]) / 3, (a[2] + b[2] + c[2]) / 3
    if not up_tri(a, b, c):
        b, c = c, b
    m = mesh_for("R", cx, cz)
    m.tri(a, b, c, (a[0] / U_ROAD, a[2] / U_ROAD), (b[0] / U_ROAD, b[2] / U_ROAD), (c[0] / U_ROAD, c[2] / U_ROAD))

LINES = read_lines()
# the long solid lines: joined end to end, relaxed, redrawn along a curve
LG = 4
ends = {}
for i, (c, hl, hw) in enumerate(LINES):
    if math.hypot(*hw) >= 0.27:
        a = (c[0] - hl[0], c[1] - hl[1], c[2] - hl[2])
        ends.setdefault((int(a[0] // LG), int(a[2] // LG)), []).append(i)
nxt, has_prev = {}, set()
for i, (c, hl, hw) in enumerate(LINES):
    if math.hypot(*hw) < 0.27:
        continue
    b = (c[0] + hl[0], c[1] + hl[1], c[2] + hl[2])
    L = math.hypot(*hl) or 1.0
    best, bd = None, 1.4
    cx, cz = int(b[0] // LG), int(b[2] // LG)
    for gx in (cx - 1, cx, cx + 1):
        for gz in (cz - 1, cz, cz + 1):
            for j in ends.get((gx, gz), ()):
                if j == i or j in has_prev:
                    continue
                c2, hl2, hw2 = LINES[j]
                a2 = (c2[0] - hl2[0], c2[1] - hl2[1], c2[2] - hl2[2])
                d = math.dist(a2, b)
                L2 = math.hypot(*hl2) or 1.0
                dot = (hl[0] * hl2[0] + hl[2] * hl2[2]) / (L * L2)
                if d < bd and dot > 0.6:
                    best, bd = j, d
    if best is not None:
        nxt[i] = best
        has_prev.add(best)
in_chain = set()
line_chains = []
for i, (c, hl, hw) in enumerate(LINES):
    if math.hypot(*hw) >= 0.27 and i not in has_prev and i in nxt:
        ch = []
        at = i
        while at is not None and at not in in_chain:
            in_chain.add(at)
            ch.append(at)
            at = nxt.get(at)
        line_chains.append(ch)
for ch in line_chains:
    if len(ch) < 3:
        in_chain.difference_update(ch)
        continue
    pts = []
    c0, hl0, hw0 = LINES[ch[0]]
    pts.append((c0[0] - hl0[0], c0[1] - hl0[1], c0[2] - hl0[2]))
    for k in range(len(ch) - 1):
        c1, hl1, _ = LINES[ch[k]]
        c2, hl2, _ = LINES[ch[k + 1]]
        b = (c1[0] + hl1[0], c1[1] + hl1[1], c1[2] + hl1[2])
        a = (c2[0] - hl2[0], c2[1] - hl2[1], c2[2] - hl2[2])
        pts.append(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2))
    c9, hl9, _ = LINES[ch[-1]]
    pts.append((c9[0] + hl9[0], c9[1] + hl9[1], c9[2] + hl9[2]))
    half = math.hypot(*hw0)
    pts = relax(pts, 3)
    cols = [0] * len(pts)
    pts, cols = curve(pts, cols)
    pts, cols = thin(pts, cols)
    n = len(pts)
    rights = []
    for i in range(n):
        d = flat_dir(pts[max(i - 1, 0)], pts[min(i + 1, n - 1)]) or (1.0, 0.0)
        rights.append((-d[1], d[0]))
    for i in range(n - 1):
        a, b = pts[i], pts[i + 1]
        ra, rb = rights[i], rights[i + 1]
        q = [
            (a[0] - ra[0] * half, a[1], a[2] - ra[1] * half),
            (b[0] - rb[0] * half, b[1], b[2] - rb[1] * half),
            (b[0] + rb[0] * half, b[1], b[2] + rb[1] * half),
            (a[0] + ra[0] * half, a[1], a[2] + ra[1] * half),
        ]
        z0 = (0.0, 0.0)
        q, uv = orient(q, [z0, z0, z0, z0], (0, 1, 0))
        m = mesh_for("L", (a[0] + b[0]) / 2, (a[2] + b[2]) / 2)
        m.quad(q[0], q[1], q[2], q[3], z0, z0, z0, z0, strip=len(m.f))

for li, (c, hl, hw) in enumerate(LINES):
    if li in in_chain:
        continue
    p = [
        (c[0] - hl[0] - hw[0], c[1] - hl[1] - hw[1], c[2] - hl[2] - hw[2]),
        (c[0] + hl[0] - hw[0], c[1] + hl[1] - hw[1], c[2] + hl[2] - hw[2]),
        (c[0] + hl[0] + hw[0], c[1] + hl[1] + hw[1], c[2] + hl[2] + hw[2]),
        (c[0] - hl[0] + hw[0], c[1] - hl[1] + hw[1], c[2] - hl[2] + hw[2]),
    ]
    if not up_tri(p[0], p[1], p[2]):
        p.reverse()
    m = mesh_for("L", c[0], c[2])
    z = (0.0, 0.0)
    m.quad(p[0], p[1], p[2], p[3], z, z, z, z, strip=len(m.f))


VARIANT = {"": "PP", "RivPaveBasket": "PB", "RivPaveHerring": "PH", "RivCobble": "PC"}
U_PAVE = 16.0
stats = {"points_in": 0, "points_out": 0}
rank = {}
for ch in read_chains():
    if ch["kind"] == "P":
        rank[ch["road"]] = rank.get(ch["road"], 0) + len(ch["pts"])


for ch in read_chains():
    pts, cols = ch["pts"], ch["cols"]
    stats["points_in"] += len(pts)
    pts = smooth_y(pts)
    pts = relax(pts, 2)
    pts, cols = curve(pts, cols)
    pts, cols = thin(pts, cols)
    pts, cols = near_points(pts, cols)
    stats["points_out"] += len(pts)
    n = len(pts)
    # the right vector at each point (between its two neighbours)
    rights = []
    for i in range(n):
        d = flat_dir(pts[max(i - 1, 0)], pts[min(i + 1, n - 1)]) or (1.0, 0.0)
        rights.append((-d[1], d[0]))
    arc = 0.0
    kind = ch["kind"]
    # (where two roads' pavements cross, the longer road's stands a hair higher: no flicker)
    lift = 0.0
    if kind == "P":
        lift = 0.02 + 0.04 * min(rank.get(ch["road"], 0) / 1500.0, 1.0)
    side = ch["side"]
    half = ch["width"] / 2
    for i in range(n - 1):
        a, b = pts[i], pts[i + 1]
        L = math.dist(a, b)
        mx, mz = (a[0] + b[0]) / 2, (a[2] + b[2]) / 2
        ra, rb = rights[i], rights[i + 1]
        u0, u1 = arc / U_PAVE, (arc + L) / U_PAVE
        arc += L
        if in_drive(mx, mz):
            continue
        my = (a[1] + b[1]) / 2
        if kind == "K":
            # (the far side of a kerb on the road too: it runs across the asphalt)
            if road_at(mx - ra[0] * side * 1.0, my - 0.5, mz - ra[1] * side * 1.0) and road_at(mx + ra[0] * side * 1.5, my - 0.5, mz + ra[1] * side * 1.5):
                continue
        elif road_at(mx, my - 0.5, mz):
            continue

        def at(p, r, u, dy):
            return (p[0] + r[0] * u, p[1] + dy, p[2] + r[1] * u)

        if kind == "K":
            m = mesh_for({0: "KS", 1: "KR", 2: "KW"}[cols[i]], mx, mz)
            # profile: u toward the road
            prof = [(0.45, -0.68), (0.45, -0.1), (0.33, 0.0), (-0.45, 0.0), (-0.45, -0.2)]
            for k in range(len(prof) - 1):
                (u_a, y_a), (u_b, y_b) = prof[k], prof[k + 1]
                p1 = at(a, ra, u_a * side, y_a)
                p2 = at(b, rb, u_a * side, y_a)
                p3 = at(b, rb, u_b * side, y_b)
                p4 = at(a, ra, u_b * side, y_b)
                rx, rz = ra[0] * side, ra[1] * side
                want = ((rx, 0, rz), (rx, 1, rz), (0, 1, 0), (-rx, 0, -rz))[k]
                q, uv = orient([p1, p2, p3, p4], [(u0, 0.0), (u1, 0.0), (u1, 0.1), (u0, 0.1)], want)
                m.quad(q[0], q[1], q[2], q[3], uv[0], uv[1], uv[2], uv[3], strip=k + 1)
        else:
            mk = VARIANT[ch["variant"]] if kind == "P" else "S"
            m = mesh_for(mk, mx, mz)
            l1, l2 = at(a, ra, -half, lift), at(b, rb, -half, lift)
            r1, r2 = at(a, ra, half, lift), at(b, rb, half, lift)
            w = ch["width"] / U_PAVE
            q, uvs = orient([l1, l2, r2, r1], [(u0, 0.0), (u1, 0.0), (u1, w), (u0, w)], (0, 1, 0))
            m.quad(q[0], q[1], q[2], q[3], uvs[0], uvs[1], uvs[2], uvs[3], strip=1)
            # the two sides, down into the ground
            for s, p1, p2 in ((-1, l1, l2), (1, r1, r2)):
                d1 = (p1[0], p1[1] - EDGE_DEEP, p1[2])
                d2 = (p2[0], p2[1] - EDGE_DEEP, p2[2])
                want = (ra[0] * s, 0, ra[1] * s)
                face, uv = orient([p1, p2, d2, d1], [(u0, 0.0), (u1, 0.0), (u1, 0.2), (u0, 0.2)], want)
                m.quad(face[0], face[1], face[2], face[3], uv[0], uv[1], uv[2], uv[3], strip=1 + (s + 3))

# the islands: rounded outlines, a kerb all round
ISLAND_ROUND = 1.4
ISLAND_KERB = 0.9


def ear_clip(pts):
    """triangles of a simple polygon (x, z), counter-clockwise or not"""
    n = len(pts)
    area = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
    idx = list(range(n)) if area > 0 else list(range(n - 1, -1, -1))
    out = []

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    guard = 0
    while len(idx) > 3 and guard < 100000:
        guard += 1
        found = False
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = pts[i0], pts[i1], pts[i2]
            if cross(a, b, c) <= 1e-9:
                continue
            inside = False
            for j in idx:
                if j in (i0, i1, i2):
                    continue
                q = pts[j]
                if cross(a, b, q) >= 0 and cross(b, c, q) >= 0 and cross(c, a, q) >= 0:
                    inside = True
                    break
            if not inside:
                out.append((i0, i1, i2))
                idx.pop(k)
                found = True
                break
        if not found:
            break
    if len(idx) == 3:
        out.append(tuple(idx))
    return out


def read_islands():
    out = []
    for line in open(os.path.join(work, "I.txt"), encoding="utf-8").read().strip().split("\n"):
        name, mat, data = line.split("|", 2)
        v = list(map(float, data.split()))
        tris = []
        for k in range(0, len(v), 9):
            tris.append(((v[k], v[k + 1], v[k + 2]), (v[k + 3], v[k + 4], v[k + 5]), (v[k + 6], v[k + 7], v[k + 8])))
        out.append((name, mat, tris))
    return out


island_count = 0
for name, mat, tris in read_islands():
    polys = []
    for a, b, c in tris:
        pg = Polygon([(a[0], a[2]), (b[0], b[2]), (c[0], c[2])])
        if pg.is_valid and pg.area > 1e-4:
            polys.append(pg)
    if not polys:
        continue
    whole = unary_union(polys).buffer(0.05)
    shapes = list(whole.geoms) if whole.geom_type == "MultiPolygon" else [whole]

    def height(x, z):
        best, bd = None, 1e18
        for a, b, c in tris:
            d = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
            if abs(d) > 1e-9:
                l1 = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / d
                l2 = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / d
                l3 = 1 - l1 - l2
                if min(l1, l2, l3) >= -0.01:
                    return l1 * a[1] + l2 * b[1] + l3 * c[1]
            for q in (a, b, c):
                dd = (q[0] - x) ** 2 + (q[2] - z) ** 2
                if dd < bd:
                    best, bd = q[1], dd
        return best

    for shape in shapes:
        # closing fills the steps in the outline, opening rounds the corners and takes off thin tips
        r = ISLAND_ROUND
        tidy = shape.buffer(r).buffer(-2 * r).buffer(r)
        if tidy.is_empty:
            tidy = shape.buffer(0.5).buffer(-0.5)
        parts = list(tidy.geoms) if tidy.geom_type == "MultiPolygon" else [tidy]
        for part in parts:
            if part.area < 6:
                continue
            ring = list(part.simplify(0.05).exterior.coords)[:-1]
            n = len(ring)
            if n < 3:
                continue
            island_count += 1
            kind = "PP" if mat.startswith("Pavement") else "S"
            area = sum(ring[i][0] * ring[(i + 1) % n][1] - ring[(i + 1) % n][0] * ring[i][1] for i in range(n))
            turn = 1 if area > 0 else -1
            ys = [height(q[0], q[1]) for q in ring]
            # the top, a hair under the kerb
            cx = sum(q[0] for q in ring) / n
            cz = sum(q[1] for q in ring) / n
            m = mesh_for(kind, cx, cz)
            for i0, i1, i2 in ear_clip(ring):
                a = (ring[i0][0], ys[i0], ring[i0][1])
                b = (ring[i1][0], ys[i1], ring[i1][1])
                c = (ring[i2][0], ys[i2], ring[i2][1])
                if not up_tri(a, b, c):
                    b, c = c, b
                m.tri(a, b, c, (a[0] / U_PAVE, a[2] / U_PAVE), (b[0] / U_PAVE, b[2] / U_PAVE), (c[0] / U_PAVE, c[2] / U_PAVE), strip=1)
            # the kerb: its outer face on the outline, the road outside it
            k = mesh_for("KS", cx, cz)
            normals = []
            for i in range(n):
                p0, p1, p2 = ring[i - 1], ring[i], ring[(i + 1) % n]
                dx, dz = p2[0] - p0[0], p2[1] - p0[1]
                L = math.hypot(dx, dz) or 1.0
                # out of the shape (x, z): a counter-clockwise ring has its inside on the left
                normals.append((dz / L * turn, -dx / L * turn))
            arc = 0.0
            prof = [(0.0, -0.75), (0.0, 0.0), (0.1, 0.1), (ISLAND_KERB, 0.1), (ISLAND_KERB, 0.0)]
            for i in range(n):
                j = (i + 1) % n
                a = (ring[i][0], ys[i], ring[i][1])
                b = (ring[j][0], ys[j], ring[j][1])
                L = math.dist(a, b)
                u0, u1 = arc / U_PAVE, (arc + L) / U_PAVE
                arc += L
                na, nb = normals[i], normals[j]
                for s_i in range(len(prof) - 1):
                    (ia, ya), (ib, yb) = prof[s_i], prof[s_i + 1]
                    p1 = (a[0] - na[0] * ia, a[1] + ya, a[2] - na[1] * ia)
                    p2 = (b[0] - nb[0] * ia, b[1] + ya, b[2] - nb[1] * ia)
                    p3 = (b[0] - nb[0] * ib, b[1] + yb, b[2] - nb[1] * ib)
                    p4 = (a[0] - na[0] * ib, a[1] + yb, a[2] - na[1] * ib)
                    want = ((na[0], 0, na[1]), (na[0], 1, na[1]), (0, 1, 0), (-na[0], 0, -na[1]))[s_i]
                    q, uv = orient([p1, p2, p3, p4], [(u0, 0.0), (u1, 0.0), (u1, 0.1), (u0, 0.1)], want)
                    k.quad(q[0], q[1], q[2], q[3], uv[0], uv[1], uv[2], uv[3], strip=10 + s_i)
print("islands", island_count)

# big cells are cut in two until each is under MAX_TRIS
out = []


def emit(kind, cell, m):
    if not m.f:
        return
    if len(m.f) <= MAX_TRIS:
        out.append((kind, cell, m.v, m.uv, m.f))
        return
    # split by the longer side
    xs = [m.v[f[0]][0] for f in m.f]
    zs = [m.v[f[0]][2] for f in m.f]
    axis = 0 if max(xs) - min(xs) >= max(zs) - min(zs) else 2
    order = sorted(m.f, key=lambda f: m.v[f[0]][axis])
    half = len(order) // 2
    for part, tag in ((order[:half], "a"), (order[half:], "b")):
        nm = Mesh()
        remap = {}
        for f in part:
            nf = []
            for i in f:
                j = remap.get(i)
                if j is None:
                    j = len(nm.v)
                    remap[i] = j
                    nm.v.append(m.v[i])
                    nm.uv.append(m.uv[i])
                nf.append(j)
            nm.f.append(tuple(nf))
        emit(kind, cell + tag, nm)


for (kind, cx, cz), m in meshes.items():
    emit(kind, f"{cx}x{cz}", m)

tally = {}
for kind, cell, v, uv, f in out:
    t = tally.setdefault(kind, [0, 0])
    t[0] += 1
    t[1] += len(f)
print(stats)
print({k: tuple(v) for k, v in sorted(tally.items())}, "total tris", sum(v[1] for v in tally.values()), "meshes", len(out))
pickle.dump(out, open(os.path.join(work, "meshes.pkl"), "wb"), protocol=4)
