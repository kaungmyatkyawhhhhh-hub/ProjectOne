"""ornament_kit.py (2026-11-16): ONE reusable Burmese carved-gold ornament kit for the Yangon landmarks.

Pure Python (no shapely, no bpy), so the pure-Python landmark scripts (sule3d, bota3d, shwedagon3d, bahan_buddhas3d)
and the headless-Blender ones (kaba_aye_blender, maha_wizaya_blender) both import it.

Reference: imports/refs/exploded/ornament/ornament_exploded_v1_lowres.png (ChatGPT sheet made from the real photos
ref1-ref4 in the same folder: Shwedagon pyatthat crests and finials, Kaba Aye porch gable, Botataung gate gable).
Layers from the sheet: crest = back board (stepped flame skyline) + scroll leaf row + flame fingers + bead moulding +
scalloped band with green glass drops, corner flame = an upswept horn; finial = ribbed base knob + a pair of curled
leaves + the flame blade (lobed, layered) + a raised beaded spine.

Every piece is real relief: stacked slabs, each with a bevelled (chamfered) front edge, standing 0.03-0.2 m proud, so
the gold reads by its own shadows. Each piece <= ~600 triangles (asserted), no two faces of different looks closer than
0.05 studs (slab fronts step >= 0.02 m = 0.06 studs), no bottoms where a piece stands on something.

Local frame of a piece (metres): x right, z up, y = OUT of the face (the front shows at +y).
  wall pieces (crest, gable, hood, panel, merlon front layers): back plane y = 0, bottom centre at the origin.
  free-standing pieces (finial, corner flame, merlon): mid plane y = 0 (relief on both faces).
Groups (looks; each landmark maps them to its own groups / materials):
  G  carved gold (flames, leaves, frames)            R  red lacquer field (gable / backboard)
  J  green glass inlay                               W  white / cream edge (arch hood rims)
  P  carved panel field (gets the YgnCarved* normal-mapped MaterialVariant)

    import ornament_kit as ok
    p = ok.flame_finial(1.2)                    # -> Piece; p.g = {grp: [(a, b, c), ...]}, p.count()
    for grp, a, b, c in p.placed(origin, right, out, up, s=1.0): ...   # world tris, winding kept
    ok.into_mb(p, {"G": mb_gold}, origin, right, out, up)              # kaba_aye_blender MB
    ok.into_geo(p, geo, {"G": "GLD"}, origin, right, out, up)          # geom3d / PGeo / Shwedagon G
"""
import math

MAX_TRIS = 600


# ---------------------------------------------------------------------------------------------- small 2D helpers
def _area(poly):
    a = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % len(poly)]
        a += x0 * y1 - x1 * y0
    return a / 2


def ccw(poly):
    poly = _dedupe(poly)
    return poly if _area(poly) > 0 else poly[::-1]


def _dedupe(poly, eps=1e-6):
    out = []
    for p in poly:
        if not out or abs(p[0] - out[-1][0]) > eps or abs(p[1] - out[-1][1]) > eps:
            out.append((float(p[0]), float(p[1])))
    if len(out) > 1 and abs(out[0][0] - out[-1][0]) < eps and abs(out[0][1] - out[-1][1]) < eps:
        out.pop()
    return out


def _seg_x(p, q, r, s):
    def o(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
    d1, d2, d3, d4 = o(r, s, p), o(r, s, q), o(p, q, r), o(p, q, s)
    return (d1 > 0) != (d2 > 0) and (d3 > 0) != (d4 > 0) and abs(d1) > 1e-12 and abs(d2) > 1e-12


def simple(poly):
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            if _seg_x(p, q, poly[j], poly[(j + 1) % n]):
                return False
    return True


def inset(poly, d):
    """CCW polygon moved IN by d (miter, capped), same point count."""
    n = len(poly)
    out = []
    for i in range(n):
        p0, p1, p2 = poly[i - 1], poly[i], poly[(i + 1) % n]
        e0 = (p1[0] - p0[0], p1[1] - p0[1])
        e1 = (p2[0] - p1[0], p2[1] - p1[1])
        l0, l1 = math.hypot(*e0) or 1e-9, math.hypot(*e1) or 1e-9
        n0 = (-e0[1] / l0, e0[0] / l0)          # inward (left) normal of a CCW edge
        n1 = (-e1[1] / l1, e1[0] / l1)
        m = (n0[0] + n1[0], n0[1] + n1[1])
        lm = math.hypot(*m)
        if lm < 1e-6:
            m = n0
        else:
            m = (m[0] / lm, m[1] / lm)
        k = d / max(m[0] * n0[0] + m[1] * n0[1], 0.45)
        k = min(k, 0.45 * min(l0, l1) / max(0.2, abs(m[0] * n0[0] + m[1] * n0[1])) + d)  # don't run past short edges
        out.append((p1[0] + m[0] * k, p1[1] + m[1] * k))
    return out


def safe_inset(poly, d):
    """inset() that halves d until the result is still a simple CCW polygon (0 = no bevel)."""
    for _ in range(5):
        q = inset(poly, d)
        if _area(q) > 0 and simple(q):
            return q, d
        d *= 0.5
    return list(poly), 0.0


def earclip(poly):
    """CCW simple polygon -> index triangles (CCW)."""
    idx = list(range(len(poly)))
    tris = []

    def inside(p, a, b, c):
        def s(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = s(p, a, b), s(p, b, c), s(p, c, a)
        return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        best = None
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = poly[i0], poly[i1], poly[i2]
            cr = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if cr <= 1e-12:
                continue
            if any(inside(poly[j], a, b, c) for j in idx if j not in (i0, i1, i2)):
                continue
            # prefer fat ears (fewer slivers)
            q = cr / (max(math.dist(a, b), math.dist(b, c), math.dist(c, a)) ** 2)
            if best is None or q > best[0]:
                best = (q, k)
        if best is None:          # degenerate: clip any convex corner
            k = 0
        else:
            k = best[1]
        tris.append((idx[k - 1], idx[k], idx[(k + 1) % len(idx)]))
        idx.pop(k)
    if len(idx) == 3:
        tris.append(tuple(idx))
    return tris


def spline(ctrl, per=4):
    """Catmull-Rom through 2D control points (ends kept)."""
    P = [ctrl[0]] + list(ctrl) + [ctrl[-1]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per):
            t = k / per
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[d]) + (-p0[d] + p2[d]) * t + (2 * p0[d] - 5 * p1[d] + 4 * p2[d] - p3[d]) * t2
                                    + (-p0[d] + 3 * p1[d] - 3 * p2[d] + p3[d]) * t3) for d in range(2)))
    out.append(tuple(ctrl[-1]))
    return out


def mirror_x(poly):
    return [(-x, z) for x, z in poly][::-1]


def move(poly, dx=0.0, dz=0.0, s=1.0, sx=None):
    sx = s if sx is None else sx
    return [(x * sx + dx, z * s + dz) for x, z in poly]


def rotate(poly, ang, cx=0.0, cz=0.0):
    c, s = math.cos(ang), math.sin(ang)
    return [(cx + (x - cx) * c - (z - cz) * s, cz + (x - cx) * s + (z - cz) * c) for x, z in poly]


# ---------------------------------------------------------------------------------------------- outlines (x, z)
def flame_outline(w, h, lobes=2, lean=0.0, n_lobe=4, barb=0.5, base=0.32, asym=0.0):
    """Kanote flame: a leaf-shaped blade rising to a long sharp tip, each side cut into `lobes` flame tongues whose
    points flick up and out (sheet: FLAME FINGERS / MAIN FLAME BLADE). w = widest width, h = height, lean = tip offset
    as a share of h, barb = how far a tongue's point stands out, base = bottom width share. n_lobe >= 3 adds a belly
    point to every tongue (rounder), asym shifts the left tongues by that share of a lobe."""
    def env(s):
        s = min(max(s, 0.0), 1.0)
        e = math.sin(math.pi * s ** 0.8) ** 0.65
        return max(e, base * (1.0 - s / 0.2)) if s < 0.2 else e
    span = 0.74                       # tongues on the lower 74 %; then the neck to the tip

    def side(sg, ph):
        pts = [(sg * 0.5 * w * base, 0.0)]
        for k in range(lobes):
            s0 = (k + ph) / lobes * span
            s1 = (k + 1 + ph) / lobes * span
            if s1 > span + 1e-9:
                s1 = span
            if s1 - s0 < 0.05:
                continue
            ds = s1 - s0
            if n_lobe >= 3:
                sb = s0 + 0.3 * ds
                pts.append((sg * 0.5 * w * env(sb), h * sb))
            st = s0 + 0.78 * ds                          # tongue point: flicks up and a little out
            pts.append((sg * 0.5 * w * env(st) * (1.0 + 0.3 * barb), h * (st + 0.3 * ds)))
            sn = s1 - 0.02 * ds                          # notch back in, under the point
            pts.append((sg * 0.5 * w * env(sn) * (1.0 - 0.55 * barb), h * sn))
        for s, k in ((0.82, 0.62), (0.91, 0.42)):
            pts.append((sg * 0.5 * w * env(s) * k, h * s))
        return pts
    R = side(1, 0.0)
    L = side(-1, asym)
    R = [(x + lean * h * (z / h) ** 3 if z < 0.85 * h else x, z) for x, z in R]
    L = [(x + lean * h * (z / h) ** 3 if z < 0.85 * h else x, z) for x, z in L]
    poly = ccw(_dedupe(R + [(lean * h, h)] + L[::-1]))
    return poly if simple(poly) else ccw(_dedupe([(0.5 * w * base, 0), (0.5 * w, 0.35 * h), (lean * h, h), (-0.5 * w, 0.35 * h), (-0.5 * w * base, 0)]))


def curl_outline(length, w0, turn=1.25, start=(0.0, 0.0), heading=90.0, hand=1, n=10, w1=None, bulb=0.0):
    """A leaf that curls: a fat ribbon along a path whose curvature grows (an acanthus scroll), width w0 at the root
    narrowing to w1 (default 0.45 w0), the curled end rounded. hand = +1 curls left (anticlockwise), -1 right."""
    if w1 is None:
        w1 = 0.45 * w0
    for _ in range(6):
        pts = [start]
        ang = math.radians(heading)
        ds = length / n
        x, z = start
        heads = [ang]
        for i in range(n):
            s = (i + 0.5) / n
            ang += hand * turn * math.pi * 2 * s / n
            x += math.cos(ang) * ds
            z += math.sin(ang) * ds
            pts.append((x, z))
            heads.append(ang)
        L, R = [], []
        for i, (p, a) in enumerate(zip(pts, heads)):
            s = i / n
            wd = 0.5 * (w0 * (1 - s) + w1 * s)
            nx, nz = -math.sin(a), math.cos(a)
            L.append((p[0] + nx * wd, p[1] + nz * wd))
            R.append((p[0] - nx * wd, p[1] - nz * wd))
        a = heads[-1]
        r = 0.5 * w1
        cap = [(pts[-1][0] + r * math.cos(a + t), pts[-1][1] + r * math.sin(a + t)) for t in (-math.pi / 3, 0.0, math.pi / 3)]
        poly = _dedupe(R + cap + L[::-1])
        if simple(poly):
            return ccw(poly)
        turn *= 0.8
    return ccw(poly)


def scroll(size, x=0.0, z=0.0, ang=0.0, mirror=False, n=7, fat=0.42):
    """The canonical acanthus scroll leaf: rises from its root at (0, 0) and curls over to the right into a rounded
    volute (sheet: SCROLL LEAF ROW / LOWER LEAF CURL), then turned by `ang` degrees (anticlockwise), mirrored (curls
    left) and moved to (x, z)."""
    p = curl_outline(size, fat * size, turn=1.1, heading=100, hand=-1, n=n)
    if mirror:
        p = [(-a, b) for a, b in p]
    p = rotate(p, math.radians(ang))
    return ccw([(a + x, b + z) for a, b in p])


def ogee(hw, zb, zt, n=7, tip=0.25):
    """Ogee arch (S sides to a point): base +-hw at zb, top at zt (+ tip)."""
    right = []
    for i in range(n + 1):
        u = i / n
        f = u - 0.16 * math.sin(2 * math.pi * u)
        right.append((hw * (1 - u), zb + (zt - zb) * f))
    right[-1] = (0.0, zt + tip)
    left = [(-x, z) for x, z in reversed(right[:-1])]
    return ccw(right + left)


def star(r_out, r_in, k, cx=0.0, cz=0.0, a0=0.0):
    return ccw([(cx + (r_out if i % 2 == 0 else r_in) * math.cos(a0 + math.pi * i / k),
                 cz + (r_out if i % 2 == 0 else r_in) * math.sin(a0 + math.pi * i / k)) for i in range(2 * k)])


def circle(r, n, cx=0.0, cz=0.0, a0=0.0):
    return [(cx + r * math.cos(a0 + 2 * math.pi * i / n), cz + r * math.sin(a0 + 2 * math.pi * i / n)) for i in range(n)]


# ---------------------------------------------------------------------------------------------- the piece
def _sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def _cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def _dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


class Piece:
    def __init__(self, name):
        self.name = name
        self.g = {}

    def tri(self, grp, a, b, c, want=None):
        n = _cross(_sub(b, a), _sub(c, a))
        if _dot(n, n) < 1e-16:
            return
        if want is not None and _dot(n, want) < 0:
            b, c = c, b
        self.g.setdefault(grp, []).append((tuple(a), tuple(b), tuple(c)))

    def quad(self, grp, a, b, c, d, want=None):
        self.tri(grp, a, b, c, want)
        self.tri(grp, a, c, d, want)

    def count(self):
        return sum(len(v) for v in self.g.values())

    def add(self, other, dx=0.0, dy=0.0, dz=0.0):
        for grp, ts in other.g.items():
            for t in ts:
                self.g.setdefault(grp, []).append(tuple((p[0] + dx, p[1] + dy, p[2] + dz) for p in t))

    def check(self, limit=MAX_TRIS):
        assert self.count() <= limit, "%s: %d triangles > %d" % (self.name, self.count(), limit)
        return self

    def placed(self, origin, right=(1, 0, 0), out=(0, 1, 0), up=(0, 0, 1), s=1.0, sx=None, sy=None, sz=None):
        """World triangles (grp, a, b, c). A mirrored basis flips the winding back so fronts still show."""
        sx = s if sx is None else sx
        sy = s if sy is None else sy
        sz = s if sz is None else sz
        flip = _dot(_cross(right, out), up) * sx * sy * sz < 0

        def T(p):
            return tuple(origin[i] + right[i] * p[0] * sx + out[i] * p[1] * sy + up[i] * p[2] * sz for i in range(3))
        for grp, ts in self.g.items():
            for a, b, c in ts:
                A, B, C = T(a), T(b), T(c)
                yield (grp, A, C, B) if flip else (grp, A, B, C)


def slab(P, grp, poly, y0, t, bevel, back=False, double=False, band=True):
    """A raised relief layer: outline `poly` (x, z) extruded along +y from y0 by t, its front edge chamfered by `bevel`
    (the front face is the outline moved in by bevel). double: both faces chamfered (free-standing, centred on y0+t/2).
    band=False: one sloped side (pure chamfer) instead of a straight side + chamfer (cheaper)."""
    poly = ccw(poly)
    inner, b = safe_inset(poly, bevel)
    if double:
        rings = [(inner, y0), (poly, y0 + b * 0.8), (poly, y0 + t - b * 0.8), (inner, y0 + t)]
        if not band:
            rings = [(inner, y0), (poly, y0 + t / 2), (inner, y0 + t)]
    else:
        rings = [(poly, y0), (poly, y0 + t - b * 0.8), (inner, y0 + t)] if band and t - b * 0.8 > 0.004 else [(poly, y0), (inner, y0 + t)]
    n = len(poly)
    for (ra, ya), (rb, yb) in zip(rings[:-1], rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            ex, ez = poly[j][0] - poly[i][0], poly[j][1] - poly[i][1]
            want = (ez, 0.0, -ex)              # outward of a CCW outline in the x-z plane
            a, bq = (ra[i][0], ya, ra[i][1]), (ra[j][0], ya, ra[j][1])
            c, d = (rb[j][0], yb, rb[j][1]), (rb[i][0], yb, rb[i][1])
            P.quad(grp, a, bq, c, d, want)
    front, yf = rings[-1]
    for i0, i1, i2 in earclip(front):
        P.tri(grp, (front[i0][0], yf, front[i0][1]), (front[i1][0], yf, front[i1][1]), (front[i2][0], yf, front[i2][1]),
              (0, 1, 0))
    if back or double:
        bk, yb_ = rings[0]
        for i0, i1, i2 in earclip(bk):
            P.tri(grp, (bk[i0][0], yb_, bk[i0][1]), (bk[i1][0], yb_, bk[i1][1]), (bk[i2][0], yb_, bk[i2][1]), (0, -1, 0))


def lathe(P, grp, prof, n, cap=True, y=0.0):
    """Round knob about the z axis (centre x = 0, y = y): prof [(r, z)] bottom -> top."""
    for (r0, z0), (r1, z1) in zip(prof[:-1], prof[1:]):
        for i in range(n):
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            A = (r0 * math.cos(a0), y + r0 * math.sin(a0), z0)
            B = (r0 * math.cos(a1), y + r0 * math.sin(a1), z0)
            C = (r1 * math.cos(a1), y + r1 * math.sin(a1), z1)
            D = (r1 * math.cos(a0), y + r1 * math.sin(a0), z1)
            am = (a0 + a1) / 2
            want = (math.cos(am) * (z1 - z0), math.sin(am) * (z1 - z0), r0 - r1)
            P.quad(grp, A, B, C, D, want)
    if cap and prof[-1][0] > 1e-6:
        r, z = prof[-1]
        for i in range(1, n - 1):
            P.tri(grp, (r, y, z), (r * math.cos(2 * math.pi * i / n), y + r * math.sin(2 * math.pi * i / n), z),
                  (r * math.cos(2 * math.pi * (i + 1) / n), y + r * math.sin(2 * math.pi * (i + 1) / n), z), (0, 0, 1))


def rod(P, grp, x0, x1, yc, zc, r, k=4, want_back=False):
    """Half-round bead moulding along x (front half only, no ends: pieces chain)."""
    for i in range(k):
        a0 = -math.pi / 2 + math.pi * i / k
        a1 = -math.pi / 2 + math.pi * (i + 1) / k
        p0 = (yc + r * math.cos(a0), zc + r * math.sin(a0))
        p1 = (yc + r * math.cos(a1), zc + r * math.sin(a1))
        am = (a0 + a1) / 2
        P.quad(grp, (x0, p0[0], p0[1]), (x1, p0[0], p0[1]), (x1, p1[0], p1[1]), (x0, p1[0], p1[1]),
               (0, math.cos(am), math.sin(am)))


# ---------------------------------------------------------------------------------------------- the kit pieces
def flame_finial(h=1.2, lod="hi"):
    """Kanote flame finial (free-standing; mid plane y = 0): ribbed base knob, a pair of curled leaves, the lobed flame
    blade and a raised beaded spine on both faces. Sheet right half; Shwedagon spires photo."""
    P = Piece("flame_finial")
    hi = lod == "hi"
    lathe(P, "G", [(0.07 * h, 0.0), (0.10 * h, 0.03 * h), (0.11 * h, 0.07 * h), (0.075 * h, 0.11 * h), (0.045 * h, 0.13 * h)],
          8 if hi else 6)
    t = 0.07 * h
    blade = move(flame_outline(0.36 * h, 0.8 * h, lobes=3 if hi else 2, n_lobe=3 if hi else 2, barb=0.55), dz=0.12 * h)
    slab(P, "G", blade, -t / 2, t, 0.018 * h, double=True, band=False)
    sp = []
    for k in range(13):
        s = k / 12
        wd = 0.035 * h * (1 - 0.5 * s) * (0.75 + 0.25 * math.cos(s * 6 * math.pi))
        sp.append((wd, 0.2 * h + 0.58 * h * s))
    spine = ccw([(-x, z) for x, z in sp[::-1]] + sp[1:-1] if False else [(x, z) for x, z in sp] + [(-x, z) for x, z in sp[::-1]])
    spine = ccw(_dedupe(spine))
    for side in (1, -1):
        Q = Piece("s")
        slab(Q, "G", spine, t / 2 - 0.002, 0.03 * h, 0.01 * h, band=False)
        for a, b, c in Q.g["G"]:
            P.tri("G", (a[0], side * a[1], a[2]), (b[0], side * b[1], b[2]), (c[0], side * c[1], c[2]),
                  _cross(_sub((b[0], side * b[1], b[2]), (a[0], side * a[1], a[2])),
                         _sub((c[0], side * c[1], c[2]), (a[0], side * a[1], a[2]))) if side > 0 else
                  tuple(-v for v in _cross(_sub((b[0], side * b[1], b[2]), (a[0], side * a[1], a[2])),
                                           _sub((c[0], side * c[1], c[2]), (a[0], side * a[1], a[2])))))
    if hi:
        for hand in (1, -1):
            cu = scroll(0.26 * h, hand * 0.05 * h, 0.1 * h, ang=-hand * 35, mirror=hand < 0, n=6)
            slab(P, "G", cu, -0.025 * h, 0.05 * h, 0.012 * h, double=True, band=False)
    return P.check()


def crest_corner(h=1.0, lod="hi"):
    """Corner flame (the tall upswept horn at a tier corner; free-standing, mid plane y = 0), leaning to +x."""
    P = Piece("crest_corner")
    horn = curl_outline(1.15 * h, 0.42 * h, turn=-0.32, start=(0.0, 0.0), heading=78, hand=1, n=9 if lod == "hi" else 6,
                        w1=0.02 * h)
    # barbs: little flame tongues along the outer edge
    t = 0.08 * h
    slab(P, "G", horn, -t / 2, t, 0.02 * h, double=True, band=lod == "hi")
    if lod == "hi":
        for k, (zz, sz) in enumerate(((0.18, 0.3), (0.45, 0.24))):
            cu = scroll(sz * h, 0.06 * h, zz * h, ang=-30 - 20 * k, n=6)
            for side in (1, -1):
                Q = Piece("c")
                slab(Q, "G", cu, t / 2 - 0.002, 0.035 * h, 0.01 * h, band=False)
                for a, b, c in Q.g["G"]:
                    A, B, C = (a[0], side * a[1], a[2]), (b[0], side * b[1], b[2]), (c[0], side * c[1], c[2])
                    if side < 0:
                        B, C = C, B
                    P.tri("G", A, B, C)
    return P.check()


def crest_segment(L=1.5, h=0.6, n=3, lod="hi", glass=True):
    """One run of a pyatthat tier crest (wall piece, back y = 0, x in [-L/2, L/2], chains end to end): back board with
    a stepped flame skyline, bead moulding, a scalloped band with green glass drops, curled scroll leaves and n flame
    fingers (the middle one tallest). Sheet left half; Shwedagon pyatthat photo."""
    P = Piece("crest_segment")
    hi = lod == "hi"
    tb = 0.035
    # back board: base band + one pointed tooth behind each finger
    top = []
    for i in range(n):
        x0 = -L / 2 + L * i / n
        x1 = x0 + L / n
        mid = n // 2
        th = (0.78 if i == mid else 0.62) * h
        top += [(x0, 0.3 * h), (x0 + 0.2 * (x1 - x0), 0.36 * h), ((x0 + x1) / 2, th), (x1 - 0.2 * (x1 - x0), 0.36 * h)]
    board = ccw([(-L / 2, 0.0), (L / 2, 0.0), (L / 2, 0.3 * h)] + top[::-1][:-1] + [(-L / 2, 0.3 * h)] if False else
                [(-L / 2, 0.0), (L / 2, 0.0), (L / 2, 0.3 * h)] + [p for p in top[::-1] if p[0] < L / 2 - 1e-9])
    slab(P, "G", board, 0.0, tb, 0.008, back=True, band=False)
    if lod == "xlo":       # far / small tiers: back board + flame fingers only (~55 triangles a finger)
        for i in range(n):
            x = -L / 2 + L * (i + 0.5) / n
            fh = (0.86 if i == n // 2 else 0.74) * h
            fl = move(flame_outline(0.5 * L / n, fh, lobes=1, n_lobe=2, barb=0.5), dx=x, dz=0.2 * h)
            slab(P, "G", fl, tb + 0.005, 0.05, 0.012, back=True, band=False)
        return P.check()
    rod(P, "G", -L / 2, L / 2, tb, 0.045 * h, 0.04 * h, k=3 if hi else 2)
    # scalloped band (gold) with green glass drops
    ns = 2 * n
    band_ = [(-L / 2, 0.11 * h), (L / 2, 0.11 * h), (L / 2, 0.2 * h)]
    band_ = [(L / 2, 0.2 * h), (-L / 2, 0.2 * h)]
    for i in range(ns + 1):
        x = -L / 2 + L * i / ns
        band_.append((x, 0.12 * h))
        if i < ns:
            band_.append((x + L / ns / 2, 0.09 * h))
    slab(P, "G", ccw(band_), tb, 0.022, 0.006, band=False)
    if glass:
        for i in range(n):
            x = -L / 2 + L * (i + 0.5) / n
            drop = [(x, 0.105 * h), (x + 0.03 * h, 0.13 * h), (x + 0.02 * h, 0.17 * h), (x, 0.185 * h), (x - 0.02 * h, 0.17 * h),
                    (x - 0.03 * h, 0.13 * h)]
            slab(P, "J", drop, tb + 0.022, 0.02, 0.005, band=False)
    # curled scroll leaves at the fingers' feet
    for i in range(n):
        x = -L / 2 + L * (i + 0.5) / n
        hand = 1 if i % 2 == 0 else -1
        cu = scroll(0.34 * h, x - hand * 0.18 * L / n, 0.2 * h, ang=hand * 15, mirror=hand > 0, n=7 if hi else 5)
        slab(P, "G", cu, tb, 0.05, 0.012, band=False)
    # flame fingers
    for i in range(n):
        x = -L / 2 + L * (i + 0.5) / n
        fh = (0.86 if i == n // 2 else 0.74) * h
        fl = move(flame_outline(0.5 * L / n, fh, lobes=2, n_lobe=2 if hi else 1, barb=0.45, asym=0.4), dx=x, dz=0.2 * h)
        slab(P, "G", fl, tb + 0.005, 0.06, 0.014, back=True, band=False)
    return P.check()


def merlon_leaf(h=1.45, w=0.6, lod="hi"):
    """Merlon leaf (free-standing parapet leaf, mid plane y = 0): a lobed leaf slab, a raised inner leaf and spine on the
    front, curls at the foot (hi). Kaba Aye terrace merlons (photo 2), sheet's flame blade layering."""
    P = Piece("merlon_leaf")
    hi = lod == "hi"
    t = 0.09
    outer = flame_outline(w, h, lobes=2 if hi else 1, n_lobe=3 if hi else 2, barb=0.35, base=0.85)
    slab(P, "G", outer, -t / 2, t, 0.016, double=True, band=False)
    inner = move(flame_outline(w * 0.62, h * 0.66, lobes=1, n_lobe=3 if hi else 2, barb=0.3, base=0.6), dz=0.2 * h)
    slab(P, "G", inner, t / 2 - 0.002, 0.05, 0.012, band=False)
    spine = ccw([(0.0, 0.3 * h), (0.035 * w, 0.45 * h), (0.025 * w * 1.6, 0.62 * h), (0.0, 0.8 * h), (-0.04 * w, 0.62 * h),
                 (-0.035 * w, 0.45 * h)])
    slab(P, "G", spine, t / 2 + 0.046, 0.04, 0.01, band=False)
    if hi:
        for hand in (1, -1):
            cu = scroll(0.22 * h, hand * 0.1 * w, 0.03 * h, ang=-hand * 45, mirror=hand < 0, n=5)
            slab(P, "G", cu, t / 2 - 0.002, 0.035, 0.01, band=False)
    return P.check()


def gable_frame(w=6.9, h=4.5, nf=2, lod="hi"):
    """Carved gable (porch pediment) with sun disc (wall piece, back y = 0, base centre at the origin, base width w,
    apex at h): red backboard, a gold ogee frame band, flame fingers stepping up its edge, a big apex flame, a raised
    gold sun disc with rays and boss in the red field, scrolls curling out at the eave ends. Kaba Aye porch (photo 2),
    Botataung gate (Konsek 01)."""
    P = Piece("gable_frame")
    hw = w / 2
    zt = h * 0.8
    board = ogee(hw * 0.97, 0.0, zt * 1.02, n=6, tip=0.05 * h)
    slab(P, "R", board, 0.0, 0.08, 0.02, back=True, band=False)
    outer = ogee(hw * 0.93, 0.0, zt, n=6, tip=0.12 * h)
    inner = ogee(hw * 0.78, 0.0, zt * 0.86, n=6, tip=0.06 * h)
    # frame band = outer arch minus inner arch, open at the eave line (one simple polygon)
    o = [p for p in outer]
    i_ = [p for p in inner]
    # split both at the base: outer CCW starts at (+hw, 0)
    o_r = [p for p in outer if p[0] >= 0][::-1]
    ob = ccw(outer)
    k0 = min(range(len(ob)), key=lambda k: (ob[k][1], -ob[k][0]))       # (+hw, 0)
    ob = ob[k0:] + ob[:k0]
    ib = ccw(inner)
    k1 = min(range(len(ib)), key=lambda k: (ib[k][1], -ib[k][0]))
    ib = ib[k1:] + ib[:k1]
    # outer: (+hw,0) up over the top to (-hw,0); inner back from (-hw',0) to (+hw',0)
    o_path = [p for p in ob if not (abs(p[1]) < 1e-9 and p[0] < 0)] + [p for p in ob if abs(p[1]) < 1e-9 and p[0] < 0]
    band_poly = ccw(o_path + ib[::-1][:-1] + [ib[0]])
    slab(P, "G", band_poly, 0.08, 0.1, 0.025, band=False)
    # sun disc: star of rays + boss
    zc = zt * 0.5
    sw = min(w, 1.6 * h)                       # the disc fits the field of a wide, low gable too
    slab(P, "G", star(0.17 * sw, 0.13 * sw, 12, 0.0, zc), 0.08, 0.07, 0.015, band=False)
    slab(P, "G", circle(0.08 * sw, 10, 0.0, zc), 0.15, 0.05, 0.015, band=False)
    # flame fingers up the frame's edge, leaning out, plus the apex flame
    for s in (1, -1):
        for k in range(nf):
            u = (k + 0.6) / (nf + 0.4)
            idx = int(round(u * 6))
            px, pz = o_r[min(idx, len(o_r) - 1)] if o_r else (hw * (1 - u), zt * u)
            px = abs(px) * s
            fl = flame_outline(0.13 * w, 0.2 * h, lobes=1, n_lobe=2, barb=0.5, lean=0.25 * s)
            fl = rotate(move(fl, dx=px, dz=pz - 0.02 * h), -s * 0.35, px, pz)
            slab(P, "G", fl, 0.08, 0.08, 0.016, back=True, band=False)
        cu = scroll(0.36 * h, s * hw * 0.9, 0.0, ang=-s * 25, mirror=s < 0, n=6)
        slab(P, "G", cu, 0.02, 0.16, 0.02, back=True, band=False)
    ap = move(flame_outline(0.16 * w, 0.32 * h, lobes=2, n_lobe=2, barb=0.5), dz=zt + 0.05 * h)
    slab(P, "G", ap, 0.1, 0.12, 0.02, back=True, band=False)      # front 0.22: clear of the band's 0.18
    return P.check()


def arch_hood(a=1.08, rise=1.15, band=0.31, n=14, lod="hi", flame=True, scrolls=True):
    """Carved arch hood (wall piece, back y = 0): a band over a round-topped arch (half width a, rise `rise` from the
    springing at z = 0) with a scalloped inner edge, a raised outer rim, a flame at the crown and leaf curls at the
    springings. Kaba Aye bay arches (photo 2), Shwedagon niche shrines."""
    P = Piece("arch_hood")
    inner, outer, rim_o = [], [], []
    for i in range(n + 1):
        t = math.pi * i / n
        sc = 0.06 * band * 2 if i % 2 else 0.0
        inner.append(((a + sc) * math.cos(t), (rise + sc) * math.sin(t)))
        outer.append(((a + band * 0.75) * math.cos(t), (rise + band * 0.75) * math.sin(t)))
        rim_o.append(((a + band) * math.cos(t), (rise + band) * math.sin(t)))
    slab(P, "B", ccw(outer + inner[::-1]), 0.0, 0.1, 0.02, band=False)
    slab(P, "W", ccw(rim_o + outer[::-1]), 0.0, 0.14, 0.02, band=False)
    if flame:
        fl = move(flame_outline(0.42 * band * 2.2, 0.9 * band * 2.2, lobes=2, n_lobe=2, barb=0.5), dz=rise + band * 0.85)
        slab(P, "G", fl, 0.0, 0.16, 0.025, back=True, band=False)
    for s in ((1, -1) if scrolls else ()):
        cu = scroll(band * 1.7, s * (a + band * 0.55), -0.05 * band, ang=-s * 40, mirror=s < 0, n=6)
        slab(P, "G", cu, 0.0, 0.12, 0.02, back=True, band=False)
    return P.check()


def panel_tile(w=0.9, h=0.9, lod="hi"):
    """Carved panel tile (wall piece, back y = 0, bottom centre at the origin): a recessed field (group P: the
    normal-mapped carved variant), a bevelled frame, a raised eight-petal rosette with a boss and four corner curls."""
    P = Piece("panel_tile")
    f = 0.09 * min(w, h)
    hw = w / 2
    # field
    slab(P, "P", [(-hw + f, f), (hw - f, f), (hw - f, h - f), (-hw + f, h - f)], 0.0, 0.03, 0.0, band=False)
    # frame: four bevelled bars (mitred)
    O = [(-hw, 0.0), (hw, 0.0), (hw, h), (-hw, h)]
    I = [(-hw + f, f), (hw - f, f), (hw - f, h - f), (-hw + f, h - f)]
    for k in range(4):
        bar = [O[k], O[(k + 1) % 4], I[(k + 1) % 4], I[k]]
        slab(P, "G", bar, 0.0, 0.06, 0.012, band=False)
    zc = h / 2
    r = 0.3 * min(w, h)
    pet = []
    for i in range(32):
        t = 2 * math.pi * i / 32
        rr = r * (0.62 + 0.38 * abs(math.cos(4 * t)) ** 0.6)
        pet.append((rr * math.cos(t), zc + rr * math.sin(t)))
    slab(P, "G", pet, 0.03, 0.05, 0.012, band=False)
    slab(P, "G", circle(0.32 * r, 8, 0.0, zc), 0.08, 0.035, 0.01, band=False)
    for sx in (1, -1):
        for sz in (1, -1):
            cx, cz = sx * (hw - f - 0.12 * w), zc + sz * (h / 2 - f - 0.12 * h)
            cu = scroll(0.2 * min(w, h), cx, cz, ang=(0 if sz < 0 else 180) + (-sx * 20 if sz < 0 else sx * 20),
                        mirror=(sx < 0) == (sz < 0), n=5)
            slab(P, "G", cu, 0.03, 0.035, 0.01, band=False)
    return P.check()


PIECES = {
    "flame_finial": flame_finial,
    "crest_segment": crest_segment,
    "crest_corner": crest_corner,
    "merlon_leaf": merlon_leaf,
    "gable_frame": gable_frame,
    "arch_hood": arch_hood,
    "panel_tile": panel_tile,
}


# ---------------------------------------------------------------------------------------------- adapters
def into_mb(piece, mbs, origin, right=(1, 0, 0), out=(0, 1, 0), up=(0, 0, 1), s=1.0, **kw):
    """kaba_aye_blender / maha_wizaya_blender MB: mbs = {kit group: MB}. Triangles keep their winding (want = normal)."""
    for grp, a, b, c in piece.placed(origin, right, out, up, s, **kw):
        mb = mbs.get(grp)
        if mb is None:
            continue
        n = _cross(_sub(b, a), _sub(c, a))
        mb.P([a, b, c], n)


def into_geo(piece, geo, groups, origin, right=(1, 0, 0), out=(0, 1, 0), up=(0, 0, 1), s=1.0, **kw):
    """geom3d.Geo / pagoda_lib.PGeo / shwedagon3d G (anything with tri(grp, a, b, c)): groups = {kit group: group}."""
    for grp, a, b, c in piece.placed(origin, right, out, up, s, **kw):
        g = groups.get(grp)
        if g is not None:
            geo.tri(g, a, b, c)


def basis_facing(bearing_rad):
    """Kit frame for a wall facing compass bearing (x east, y north, z up): returns (right, out, up)."""
    out = (math.sin(bearing_rad), math.cos(bearing_rad), 0.0)
    right = (math.cos(bearing_rad), -math.sin(bearing_rad), 0.0)
    return right, out, (0.0, 0.0, 1.0)


LOOKS = {"G": (226, 178, 84), "R": (150, 30, 28), "J": (40, 140, 90), "W": (245, 242, 232), "B": (170, 40, 34),
         "P": (210, 165, 80)}


def dump_sheet(path, lod="hi"):
    """All pieces side by side (x east, y north = toward the camera at -y... front +y), as preview_pagoda_blend scene."""
    import json
    out = {}
    x = 0.0
    for name, fn in PIECES.items():
        p = fn(lod=lod)
        xs = [q[0] for ts in p.g.values() for t in ts for q in t]
        w = max(xs) - min(xs)
        dx = x - min(xs)
        for grp, a, b, c in p.placed((dx, 0, 0)):
            d = out.setdefault(grp, {"rgb": LOOKS.get(grp, (200, 200, 200)), "mat": "Metal" if grp in "GP" else "SmoothPlastic",
                                     "tr": 0, "ds": False, "tris": []})
            d["tris"].append([a, b, c])
        x += w + 1.0
    json.dump(out, open(path, "w"))
    return x


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 2 and sys.argv[1] == "dump":
        print("width", dump_sheet(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "hi"))
        sys.exit()
    for name, fn in PIECES.items():
        p = fn()
        lo = fn(lod="lo")
        print("%-14s hi %4d tris   lo %4d tris   groups %s" % (name, p.count(), lo.count(), sorted(p.g)))
