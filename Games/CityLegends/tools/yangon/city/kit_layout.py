"""kit_layout.py (2026-11-16, compact building data): the 1:1 kit buildings' detail as outline + archetype + seed.

buildings_1to1.py no longer writes every panel / pier / party wall / roof slab / prop / compound-wall piece as a record:
a tile string (kit_pack Meta FORMAT=2) starts with "!" and holds
  H  a building: arch(1) floors(1) wall(1) flags(1) base y(3) n(2) first point X(3) Z(3), n-1 deltas dX(2) dZ(2),
     then ceil(n/2) edge chars (3 bits an edge: 1 party, 2 street front, 4 shop front)
     flags: 1 pitched roof (no slab, no props), 2 crown (slab, no props)
  W  a chain of compound-wall runs: start X(3) Z(3), runs(1), per run dX(2) dZ(2) info(1) heights:
     info = colour(2 bits) + 4 reversed (the run goes from its end back to its start) + 8 absolute heights;
     heights = first piece y(3), then per further piece 1 char (0.1-stud steps from the previous, -32..31) or 3 chars
  P / Q / B  old kit_pack records (gates) as they are
and the client (src/shared/YangonKitData.lua KD.expand) lays out the same old records with the SAME code as expand()
below. Determinism: only + - * / sqrt and floor decide anything (identical doubles in Python and Luau); atan2 only
makes output angles; randomness = mix() (a 32-bit integer hash) of the building's seed (its first point). Outline points
are 0.1-stud integers relative to the tile origin (+1024 studs), deltas accumulate as integers.

    enc_building(...), enc_walls(...)  -> record strings (the generator)
    expand(s, i, j, panel_pid, prop_pid, info=None) -> old-style records [("P", pid, x, y, z, yaw, sx, code), ...]
    python kit_layout.py expect <tag> <out_dir> [n_tiles]   expected old strings of sample tiles (for the Studio check)
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from kit_panels import ARCH, FH, S, K_SET, stable_id  # noqa: E402
from kit_pack import B64, enc, dec  # noqa: E402

ARCHS = ["walkup", "township", "house", "villa", "condo", "civic", "shed", "market", "colonial"]
WALLS = ["KW0", "KW1", "KW2", "KW3", "KW4", "KW5", "KW6", "KW7", "KWG", "KWB", "KWC", "KWD2"]
WCOLS = ["KWC", "KW6", "KW1", "KWG"]
STRETCH = 0.15
BAYW = 3.5 * S        # compound-wall bay
WH = 2.1 * S          # compound-wall height (collision top over the highest piece)
WT = 0.22 * S         # compound-wall thickness (collision)
CELLM = 1.0 * S       # flat-roof raster
QO = 10240            # point origin: tile origin - 1024 studs, in 0.1 studs
DMAX = 2000           # max |delta| (0.1 studs): edges / runs longer than 200 studs are split
M32 = 0xFFFFFFFF


def M(v):
    return v * S


# ------------------------------------------------------------------------------------------- portable randomness
def mix(x):
    x ^= x >> 16
    x = (x * 0x7feb352d) & M32
    x ^= x >> 15
    x = (x * 0x846ca68b) & M32
    x ^= x >> 16
    return x


def rnd(seed, k):
    return mix(seed ^ mix(k + 1)) / 4294967296.0


def meta_lines():
    """the layout constants for the client (repr: the exact doubles)"""
    arch = " ".join("%s:%r,%r,%r,%r" % (a, ARCH[a]["bay"], ARCH[a]["gf"], ARCH[a]["par"], ARCH[a].get("fh", FH))
                    for a in ARCH)
    return "FORMAT=2\nARCH=%s\nWALLS=%s\nWCOLS=%s\nLAYOUT=%r %r %r\n" % (arch, " ".join(WALLS), " ".join(WCOLS), S, FH, STRETCH)


# ------------------------------------------------------------------------------------------------- geometry
def fit_wall(L, bay):
    best = None
    n0 = math.floor(L / bay)
    for n in range(max(1, n0 - 1), n0 + 3):
        s = L / (n * bay)
        if abs(s - 1) <= STRETCH:
            c = abs(s - 1)
            if best is None or c < best[0]:
                best = (c, n, s, 0.0)
        s = min(max((L - 0.5 * bay) / (n * bay), 1 - STRETCH), 1 + STRETCH)
        pw = L - n * bay * s
        ps = pw / (0.5 * bay)
        if 0.3 <= ps <= 1.6:
            c = abs(s - 1) + 0.3 * abs(ps - 1) + 0.05
            if best is None or c < best[0]:
                best = (c, n, s, ps)
    return best[1:] if best else None


def decompose(n):
    out = []
    for k in sorted(K_SET, reverse=True):
        while n >= k:
            out.append(k)
            n -= k
    return out


def wall_box(p, q, y0, y1, code, k):
    """a plain wall sheet (0.02 studs) with its outer face on p -> q"""
    dx, dz = q[0] - p[0], q[1] - p[1]
    L = math.sqrt(dx * dx + dz * dz)
    ux, uz = dx / L, dz / L
    nx, nz = uz, -ux
    cx, cz = (p[0] + q[0]) / 2 - nx * 0.01, (p[1] + q[1]) / 2 - nz * 0.01
    y1 -= 0.06 * k
    return ("B", cx, (y0 + y1) / 2, cz, L, y1 - y0, 0.02, math.atan2(-uz, ux), code)


def parity(i, n):
    return 2 if (n % 2 == 1 and i == n - 1) else i % 2


def inner(ring, px, pz, d):
    """inside the outline (even-odd) and at least d from every edge"""
    c = False
    n = len(ring)
    j = n - 1
    d2 = d * d
    for i in range(n):
        xi, zi = ring[i]
        xj, zj = ring[j]
        if (zi > pz) != (zj > pz) and px < (xj - xi) * (pz - zi) / (zj - zi) + xi:
            c = not c
        ex, ez = xj - xi, zj - zi
        ll = ex * ex + ez * ez
        t = ((px - xi) * ex + (pz - zi) * ez) / ll if ll > 0 else 0.0
        t = min(max(t, 0.0), 1.0)
        qx, qz = px - (xi + t * ex), pz - (zi + t * ez)
        if qx * qx + qz * qz < d2:
            return False
        j = i
    return c


def area(ring):
    a = 0.0
    n = len(ring)
    for i in range(n):
        x0, z0 = ring[i]
        x1, z1 = ring[(i + 1) % n]
        a += x0 * z1 - x1 * z0
    return abs(a) / 2


def frame(ring):
    """the min-area rectangle: (cx, cz, e1x, e1z, hl, hw), e1 along its long side (None if degenerate)"""
    pts = sorted(set(ring))
    if len(pts) < 3:
        return None

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    hull = lo[:-1] + up[:-1]
    if len(hull) < 3:
        return None
    best = None
    for k in range(len(hull)):
        a, b = hull[k], hull[(k + 1) % len(hull)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ll = math.sqrt(dx * dx + dz * dz)
        if ll < 1e-9:
            continue
        ux, uz = dx / ll, dz / ll
        u0 = u1 = hull[0][0] * ux + hull[0][1] * uz
        v0 = v1 = -hull[0][0] * uz + hull[0][1] * ux
        for p in hull:
            u = p[0] * ux + p[1] * uz
            v = -p[0] * uz + p[1] * ux
            u0, u1, v0, v1 = min(u0, u), max(u1, u), min(v0, v), max(v1, v)
        ar = (u1 - u0) * (v1 - v0)
        if best is None or ar < best[0]:
            best = (ar, ux, uz, u0, u1, v0, v1)
    _, ux, uz, u0, u1, v0, v1 = best
    um, vm = (u0 + u1) / 2, (v0 + v1) / 2
    cx, cz = ux * um - uz * vm, uz * um + ux * vm
    if u1 - u0 >= v1 - v0:
        return (cx, cz, ux, uz, (u1 - u0) / 2, (v1 - v0) / 2)
    return (cx, cz, -uz, ux, (v1 - v0) / 2, (u1 - u0) / 2)


def roof_slabs(ring, fr, inset=0.75):
    """a flat roof as Part rectangles inside the outline: its rectangle 0.75 in when that fits, else a 1 m raster of
    that inset rectangle (cells whose corners are all 0.6 inside the outline: no slab face in a wall's plane), rows
    cut into runs, equal runs of next rows merged"""
    cx, cz, e1x, e1z, hl, hw = fr
    e2x, e2z = -e1z, e1x
    yw = math.atan2(-e1z, e1x)
    hl, hw = hl - inset, hw - inset
    if hl < 0.25 or hw < 0.25:
        return []

    def ok(uu, v, hu, hv):
        return all(inner(ring, cx + e1x * (uu + a * hu) + e2x * (v + b * hv), cz + e1z * (uu + a * hu) + e2z * (v + b * hv), 0.6)
                   for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)))
    if ok(0.0, 0.0, hl, hw):
        return [(cx, cz, 2 * hl, 2 * hw, yw)]
    nu, nv = max(1, math.ceil(2 * hl / CELLM)), max(1, math.ceil(2 * hw / CELLM))
    du, dv = 2 * hl / nu, 2 * hw / nv
    res = []
    open_ = []   # [run (i0, i1), first row], in the order of the row before
    for j in range(nv + 1):
        runs = []
        if j < nv:
            v = -hw + (j + 0.5) * dv
            start = None
            for i in range(nu + 1):
                inside = i < nu and ok(-hl + (i + 0.5) * du, v, du / 2, dv / 2)
                if inside and start is None:
                    start = i
                elif not inside and start is not None:
                    runs.append((start, i))
                    start = None
        nxt = []
        for rr in runs:
            j0 = j
            for o in open_:
                if o[0] == rr:
                    j0 = o[1]
                    o[1] = -1
                    break
            nxt.append([rr, j0])
        for (i0, i1), j0 in open_:
            if j0 >= 0:
                uu = -hl + (i0 + i1) / 2 * du
                v = -hw + (j0 + j) / 2 * dv
                res.append((cx + e1x * uu + e2x * v, cz + e1z * uu + e2z * v, (i1 - i0) * du, (j - j0) * dv, yw))
        open_ = nxt
    return res


def wall_layout(a, b):
    """a compound-wall run a -> b: (L, ux, uz, stretch, piece bays [8, 4, 2, 1 ...])"""
    dx, dz = b[0] - a[0], b[1] - a[1]
    L = math.sqrt(dx * dx + dz * dz)
    n = max(1, math.floor(L / BAYW + 0.5))
    ks = [8] * (n // 8) + [4] * ((n % 8) // 4) + [2] * ((n % 4) // 2) + [1] * (n % 2)
    return L, dx / L, dz / L, L / (n * BAYW), ks


def split_long(pts, closed):
    """insert points so no edge is over 200 studs (the delta range)"""
    out = []
    n = len(pts)
    for k in range(n if closed else n - 1):
        a, b = pts[k], pts[(k + 1) % n]
        m = max(1, math.ceil(max(abs(b[0] - a[0]), abs(b[1] - a[1])) / 195.0))
        for t in range(m):
            out.append((a[0] + (b[0] - a[0]) * t / m, a[1] + (b[1] - a[1]) * t / m))
    if not closed:
        out.append(pts[-1])
    return out


# ----------------------------------------------------------------------------------------------- encoding
def _q(v, o):
    q = math.floor((v - o) * 10 + 0.5) + QO
    assert 0 <= q < 262144, (v, o)
    return q


def _d(d):
    assert -DMAX <= d <= DMAX, d
    return enc(d + 2048, 2)


def enc_building(tile, arch, floors, wall, flags, base, ring, edges, tile_size=256.0):
    """ring: counter-clockwise (x, z) points (no edge over 200 studs: split_long); edges: bits per edge"""
    x0, z0 = tile[0] * tile_size, tile[1] * tile_size
    Q = [(_q(x, x0), _q(z, z0)) for x, z in ring]
    assert floors < 64 and len(Q) < 4096
    s = ["H", B64[ARCHS.index(arch)], B64[floors], B64[WALLS.index(wall)], B64[flags],
         enc(math.floor((base + 200) * 200 + 0.5), 3), enc(len(Q), 2), enc(Q[0][0], 3), enc(Q[0][1], 3)]
    for k in range(1, len(Q)):
        s.append(_d(Q[k][0] - Q[k - 1][0]) + _d(Q[k][1] - Q[k - 1][1]))
    for k in range(0, len(Q), 2):
        s.append(B64[edges[k] | ((edges[k + 1] << 3) if k + 1 < len(Q) else 0)])
    return "".join(s)


def _deq(X, o):
    return o + (X - QO) / 10


def enc_walls(runs, ground, tile_size=256.0):
    """runs: [(a, b, colour code)] in order; ground(x, z) -> y. Chains runs that meet end to start (or end to end:
    reversed). Returns {tile: [chain strings]}"""
    out = {}
    chain = None   # [tile, start (X, Z) ints, last (X, Z), [segment strings]]

    def flush():
        if chain and chain[3]:
            out.setdefault(chain[0], []).append("W" + enc(chain[1][0], 3) + enc(chain[1][1], 3) + B64[len(chain[3])] +
                                                "".join(chain[3]))
    for a, b, col in runs:
        qa = qb = None
        x0, z0 = (chain[0][0] * tile_size, chain[0][1] * tile_size) if chain else (0.0, 0.0)
        if chain is not None and len(chain[3]) < 63 and all(abs(c - o) < 1000 for c, o in
                                                             ((a[0], x0), (a[1], z0), (b[0], x0), (b[1], z0))):
            qa, qb = (_q(a[0], x0), _q(a[1], z0)), (_q(b[0], x0), _q(b[1], z0))
        if qa is not None and qa == chain[2] and qa != qb:
            rev, nxt = False, qb
        elif qb is not None and qb == chain[2] and qa != qb:
            rev, nxt = True, qa
        else:
            flush()
            t = (math.floor(a[0] / tile_size), math.floor(a[1] / tile_size))
            x0, z0 = t[0] * tile_size, t[1] * tile_size
            qa, qb = (_q(a[0], x0), _q(a[1], z0)), (_q(b[0], x0), _q(b[1], z0))
            if qa == qb:
                chain = None
                continue
            chain = [t, qa, qa, []]
            rev, nxt = False, qb
        x0, z0 = chain[0][0] * tile_size, chain[0][1] * tile_size
        p, q = chain[2], nxt
        pa, pb = (q, p) if rev else (p, q)
        A = (_deq(pa[0], x0), _deq(pa[1], z0))
        B = (_deq(pb[0], x0), _deq(pb[1], z0))
        L, ux, uz, sw, ks = wall_layout(A, B)
        ys, u = [], 0.0
        for kk in ks:
            ln = kk * BAYW * sw
            ys.append(min(ground(A[0] + ux * (u + ln * t), A[1] + uz * (u + ln * t)) for t in (0, 0.25, 0.5, 0.75, 1.0)))
            u += ln
        hq = [math.floor((ys[0] + 200) * 200 + 0.5)]
        rel = True
        for y in ys[1:]:
            d = math.floor(((y + 200) * 200 - hq[-1]) / 20)   # never above the real ground
            if not -32 <= d <= 31:
                rel = False
                break
            hq.append(hq[-1] + 20 * d)
        if not rel:
            hq = [math.floor((y + 200) * 200 + 0.5) for y in ys]
        info = WCOLS.index(col) | (4 if rev else 0) | (0 if rel else 8)
        seg = _d(q[0] - p[0]) + _d(q[1] - p[1]) + B64[info] + enc(hq[0], 3)
        for k in range(1, len(hq)):
            seg += B64[(hq[k] - hq[k - 1]) // 20 + 32] if rel else enc(hq[k], 3)
        chain[3].append(seg)
        chain[2] = nxt
    flush()
    return out


# ------------------------------------------------------------------------------------------------- expansion
PLEN = {"P": 21, "Q": 27, "B": 25}


def expand(s, i, j, panel_pid, prop_pid, pids=None, codes=None, info=None, tile_size=256.0):
    """a compact tile string ("!" ...) -> old-style records. panel_pid(key) / prop_pid(name) give piece ids; pids /
    codes (index -> id) are needed only for the old P / Q / B records inside; info (a list) gets a dict a building"""
    x0, z0 = i * tile_size, j * tile_size
    out = []
    p = 1 if s[:1] == "!" else 0
    n = len(s)
    while p < n:
        t = s[p]
        if t == "H":
            arch = ARCHS[B64.index(s[p + 1])]
            floors = B64.index(s[p + 2])
            wall = WALLS[B64.index(s[p + 3])]
            flags = B64.index(s[p + 4])
            base = dec(s[p + 5:p + 8]) / 200 - 200
            N = dec(s[p + 8:p + 10])
            X, Z = dec(s[p + 10:p + 13]), dec(s[p + 13:p + 16])
            seed = mix(X ^ mix(Z + 7919))
            ring = [(_deq(X, x0), _deq(Z, z0))]
            p += 16
            for _ in range(N - 1):
                X += dec(s[p:p + 2]) - 2048
                Z += dec(s[p + 2:p + 4]) - 2048
                ring.append((_deq(X, x0), _deq(Z, z0)))
                p += 4
            edges = []
            for k in range(0, N, 2):
                v = B64.index(s[p])
                edges.append(v & 7)
                edges.append(v >> 3)
                p += 1
            d = building(arch, floors, wall, flags, base, ring, edges, seed, panel_pid, prop_pid, out)
            if info is not None:
                info.append(d)
        elif t == "W":
            X, Z = dec(s[p + 1:p + 4]), dec(s[p + 4:p + 7])
            nseg = B64.index(s[p + 7])
            p += 8
            for _ in range(nseg):
                X2, Z2 = X + dec(s[p:p + 2]) - 2048, Z + dec(s[p + 2:p + 4]) - 2048
                inf = B64.index(s[p + 4])
                P0, P1 = (_deq(X, x0), _deq(Z, z0)), (_deq(X2, x0), _deq(Z2, z0))
                A, B = (P1, P0) if inf & 4 else (P0, P1)
                L, ux, uz, sw, ks = wall_layout(A, B)
                hq = [dec(s[p + 5:p + 8])]
                p += 8
                for _k in range(1, len(ks)):
                    if inf & 8:
                        hq.append(dec(s[p:p + 3]))
                        p += 3
                    else:
                        hq.append(hq[-1] + 20 * (B64.index(s[p]) - 32))
                        p += 1
                ys = [h / 200 - 200 for h in hq]
                col = WCOLS[inf & 3]
                yaw = math.atan2(-uz, ux)
                u = 0.0
                for kk, gy in zip(ks, ys):
                    out.append(("P", prop_pid("cwall%d" % kk), A[0] + ux * u, gy, A[1] + uz * u, yaw, sw, col))
                    u += kk * BAYW * sw
                y0, y1 = min(ys) - 0.9, max(ys) + WH
                out.append(("B", (A[0] + B[0]) / 2, (y0 + y1) / 2, (A[1] + B[1]) / 2, L, y1 - y0, WT, yaw, "WCOL"))
                X, Z = X2, Z2
        elif t in PLEN:
            r = s[p:p + PLEN[t]]
            if t == "B":
                out.append(("B", dec(r[1:5]) / 500 - 16384 + x0, dec(r[5:8]) / 200 - 200, dec(r[8:12]) / 500 - 16384 + z0,
                            dec(r[15:18]) / 200, dec(r[18:21]) / 200, dec(r[21:24]) / 200,
                            dec(r[12:15]) / 262144 * 2 * math.pi, codes[B64.index(r[24])]))
            else:
                rec = (t, pids[dec(r[1:3])], dec(r[3:7]) / 500 - 16384 + x0, dec(r[7:10]) / 200 - 200,
                       dec(r[10:14]) / 500 - 16384 + z0, dec(r[14:17]) / 262144 * 2 * math.pi, dec(r[17:20]) / 50000 + 0.1,
                       codes[B64.index(r[20])])
                if t == "Q":
                    rec += (dec(r[21:24]) / 5000 + 0.05, dec(r[24:27]) / 5000 + 0.05)
                out.append(rec)
            p += PLEN[t]
        else:
            raise ValueError("bad record %r at %d" % (t, p))
    return out


def building(arch, floors, wall, flags, base, ring, edges, seed, panel_pid, prop_pid, out):
    base_arch = "shed" if arch == "market" else arch
    A_ = ARCH[base_arch]
    bay = A_["bay"] * S
    Hs = (A_["gf"] + A_.get("fh", FH) * max(0, floors - 1)) * S
    par = A_["par"] * S
    top = base + Hs + (par if par > 0 else 0)
    N = len(ring)
    fronts = []

    def stack(role, kk, var, shop, stripe):
        if arch == "condo":
            vv, st = (0, False) if kk == 0 else (var, stripe)
            res = [(panel_pid(("condo", role, 2, kk, vv, False, st)), base)]
            y = base + (ARCH["condo"]["gf"] + FH) * S
            left = floors - 2
            for nf in (8, 4, 2, 1):
                while left >= nf:
                    res.append((panel_pid(("condo_band", role, nf, kk, vv, False, st)), y))
                    y += nf * FH * S
                    left -= nf
            res.append((panel_pid(("condo_top", role, 0, kk, vv, False, st)), y))
            return res
        if kk == 0:
            return [(panel_pid((arch, role, floors, 0, 0, False, False)), base)]
        return [(panel_pid((arch, role, floors, kk, var, shop, stripe)), base)]

    for ei in range(N):
        a, b = ring[ei], ring[(ei + 1) % N]
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.sqrt(dx * dx + dz * dz)
        if L < 0.3:
            continue
        nx, nz = dz / L, -dx / L
        party, front, shop = edges[ei] & 1, edges[ei] & 2, edges[ei] & 4
        fit = None if (party or L < 0.85 * bay) else fit_wall(L, bay)
        if fit is None:
            out.append(wall_box(a, b, base - 1.0, top, wall, parity(ei, N)))
            continue
        n, s, ps = fit
        role = "front" if front else "side"
        ax, az = nz, -nx
        yaw = math.atan2(nx, nz)
        if front:
            fronts.append((L, b, ax, az, yaw, s, n))
        u = 0.0
        var = (mix(seed ^ (ei + 1000)) & 1) if (front and arch in ("walkup", "township", "colonial")) else 0
        stripe_done = False
        for kk in decompose(n) + ([0] if ps > 0 else []):
            stripe = False
            if arch == "condo" and front and not stripe_done and kk == 1:
                stripe, stripe_done = True, True
            sx = ps if kk == 0 else s
            ox, oz = b[0] + ax * u, b[1] + az * u
            for pid, py in stack(role, kk, var, bool(shop), stripe):
                out.append(("P", pid, ox, py, oz, yaw, sx, wall))
            u += (0.5 * bay * ps) if kk == 0 else kk * bay * s
    res = dict(spots=None, props=False)
    # one drainpipe and one or two AC units a building, on its longest street face
    if fronts and arch in ("walkup", "township", "house", "villa") and floors >= 2:
        e = fronts[0]
        for f in fronts[1:]:
            if f[0] > e[0]:
                e = f
        L, b, ax, az, yaw, s, n = e
        gf = A_["gf"]
        if arch in ("walkup", "township"):
            u = L - M(0.07)
            y0, y1 = base + M(gf - 0.3), top - M(0.1)
            out.append(("Q", prop_pid("pipe"), b[0] + ax * u, y0, b[1] + az * u, yaw, 1.0, wall, (y1 - y0) / M(3.0), 1.0))
        n_ac = 2 if (arch == "walkup" and floors >= 4) else 1
        spots = [(bb, f) for bb in range(n) for f in range(1, floors) if (bb * bay + M(0.16)) * s + M(0.8) < L - M(0.15)]
        res["spots"] = len(spots)
        for k in range(len(spots) - 1, 0, -1):
            m = math.floor(rnd(seed, 50 + k) * (k + 1))
            spots[k], spots[m] = spots[m], spots[k]
        for bb, f in spots[:n_ac]:
            u = (bb * bay + M(0.16)) * s
            out.append(("P", prop_pid("ac"), b[0] + ax * u, base + M(gf + FH * (f - 1) + 0.17), b[1] + az * u, yaw, 1.0, wall))
    if flags & 1:
        return res
    top_y = base + Hs
    fr = frame(ring)
    if fr is None:
        return res
    slabs = roof_slabs(ring, fr)
    for (cx, cz, sx, sz, yw) in slabs:
        out.append(("B", cx, top_y + 0.15 - 0.4, cz, sx, 0.8, sz, yw, "KCO"))
    # roof props on flat roofs: tanks, a dish, a stair room (2.5 m inside the outline)
    if arch in ("walkup", "township", "civic", "condo", "colonial") and area(ring) > M(5) * M(5) and not flags & 2:
        res["props"] = True
        cx, cz, e1x, e1z = fr[0], fr[1], fr[2], fr[3]
        rp = None
        if inner(ring, cx, cz, M(2.5)):
            rp = (cx, cz)
        elif slabs:
            big = slabs[0]
            for q in slabs[1:]:
                if q[2] * q[3] > big[2] * big[3]:
                    big = q
            if inner(ring, big[0], big[1], M(2.5)):
                rp = (big[0], big[1])
        if rp:
            for name, o0, o1 in (("tanks", 0.0, 0.0), ("dish", M(4), M(1)), ("stair", -M(4), M(2))):
                if name == "dish" and (arch not in ("walkup", "condo") or rnd(seed, 300) < 0.4):
                    continue
                if name == "stair" and arch not in ("walkup", "condo", "civic"):
                    continue
                px = rp[0] + o0 * e1x - o1 * e1z
                pz = rp[1] + o0 * e1z + o1 * e1x
                if not inner(ring, px, pz, M(2.5)):
                    continue
                out.append(("P", prop_pid(name), px, top_y + 0.15, pz, -math.atan2(e1z, e1x), 1.0, wall))
    return res


def stable_panel(key):
    return stable_id("p", tuple(key))


def stable_prop(name):
    return stable_id("q", ("prop", name))


# ------------------------------------------------------------------------------------------------- CLI
def _folder(path):
    """a kit_pack rbxmx -> {name: value}"""
    import re
    from xml.sax.saxutils import unescape
    x = open(path, encoding="utf-8").read()
    return {m.group(1): unescape(m.group(2)) for m in
            re.finditer(r'<string name="Name">([^<]*)</string><string name="Value">([^<]*)</string>', x)}


def expect(tag, out_dir, n_tiles=40):
    """sample tiles of a compact Data_<tag>: their expanded old strings (Python), for YangonKitCheck in Studio"""
    import kit_pack
    root = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
    d = _folder(os.path.join(root, "imports", "sync", "ygn1to1_%s" % tag.lower(), "ygnkit_%s.rbxmx" % tag.lower()))
    meta = d["Meta"]
    pids = meta.split("PIDS=")[1].split("\n")[0].split()
    codes = meta.split("CODES=")[1].split("\n")[0].split()
    pidx, cidx = {p: k for k, p in enumerate(pids)}, {c: k for k, c in enumerate(codes)}
    tiles = sorted((k for k in d if k != "Meta"), key=lambda k: -d[k].count("H"))
    pick = tiles[:n_tiles // 2] + tiles[len(tiles) // 2:len(tiles) // 2 + n_tiles - n_tiles // 2]
    os.makedirs(out_dir, exist_ok=True)
    nb = 0
    for k in pick:
        i, j = map(int, k.split("_"))
        info = []
        recs = expand(d[k], i, j, stable_panel, stable_prop, pids, codes, info)
        nb += len(info)
        open(os.path.join(out_dir, "%s.txt" % k), "w", newline="\n").write(kit_pack.pack_tile(recs, i * 256.0, j * 256.0, pidx, cidx))
    print(tag, "tiles", len(pick), "buildings", nb)


if __name__ == "__main__":
    if sys.argv[1] == "expect":
        expect(sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 40)
