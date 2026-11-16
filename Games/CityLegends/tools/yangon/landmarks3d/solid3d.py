"""solid3d.py (2026-11-16): small pure-Python solid modeller for the 1:1 Yangon landmarks (no Blender).

Model space: metres, x / y on the ground, z up, right-handed. Every closed solid is turned outward by its signed
volume; open faces take an outward normal hint. Smooth normals for organic shapes (figures), flat for the rest.

    m = Model()
    m.box("GLD", x0, x1, y0, y1, z0, z1, skip=("-z",))
    m.beam("STM", p0, p1, w, h)                      # a box along a segment
    m.slab(top, bot, edge, [4 corners], t)          # a sloped plate (roofs): top face, underside, edges
    m.prism(grp, poly2d, z0, z1, frame=None, top=True, bottom=False)   # concave ok (shapely CDT)
    m.ellipsoid(grp, c, (rx, ry, rz), axes=None)
    m.loft(grp, [(c, a, b), ...], seg, cap0="point", cap1="point")     # rings c + a cos t + b sin t
    m.tube(grp, [(p, r), ...], seg)
    export(m, pivot_studs, bearing_deg, out_glb, tag) -> (files, world tris with keys)

World: local x points along `bearing` (degrees clockwise from north), y to its left, z up; 1 m = geo.SPM studs.
X = PX + s*east, Z = PZ - s*north, Y = PY + s*z (Roblox: X east, Y up, Z south).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "city"))
from glb import Mesh, write_glb, code, check_glb  # noqa: E402
from landmark_glb3d import box_uv  # noqa: E402

from shapely.geometry import Polygon  # noqa: E402
from shapely import constrained_delaunay_triangles  # noqa: E402


def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def mul(a, k): return (a[0] * k, a[1] * k, a[2] * k)
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def length(a): return math.sqrt(dot(a, a))


def unit(a):
    L = length(a)
    return (a[0] / L, a[1] / L, a[2] / L) if L > 1e-12 else (0.0, 0.0, 1.0)


def tri_n(a, b, c):
    return cross(sub(b, a), sub(c, a))


def triangulate(poly):
    """2D polygon (list of (x, y)) -> triangles (each CCW), concave allowed."""
    P = Polygon(poly)
    if not P.is_valid:
        P = P.buffer(0)
    out = []
    for t in constrained_delaunay_triangles(P).geoms:
        c = list(t.exterior.coords)[:3]
        a, b, d = c
        if (b[0] - a[0]) * (d[1] - a[1]) - (b[1] - a[1]) * (d[0] - a[0]) < 0:
            b, d = d, b
        out.append((a, b, d))
    return out


class Model:
    def __init__(self):
        self.g = {}      # group -> [(a, b, c, normals | None, shape id)]
        self.sid = 0

    # ---------- low level
    def _put(self, grp, tris):
        self.sid += 1
        L = self.g.setdefault(grp, [])
        for t in tris:
            a, b, c, n = t
            if length(tri_n(a, b, c)) < 1e-10:
                continue
            L.append((a, b, c, n, self.sid))

    def tris(self):
        return sum(len(v) for v in self.g.values())

    def solid(self, grp, chunks):
        """chunks: [(tris [(a, b, c)], smooth)] forming one closed (or nearly closed) solid: made outward, normals."""
        vol = 0.0
        allp = [p for tris, _ in chunks for t in tris for p in t]
        if not allp:
            return
        o = mul((sum(p[0] for p in allp), sum(p[1] for p in allp), sum(p[2] for p in allp)), 1.0 / len(allp))
        for tris, _ in chunks:
            for a, b, c in tris:
                vol += dot(sub(a, o), cross(sub(b, o), sub(c, o)))
        out = []
        for tris, smooth in chunks:
            T = [(a, c, b) if vol < 0 else (a, b, c) for a, b, c in tris]
            if smooth:
                acc = {}
                key = lambda p: (round(p[0], 4), round(p[1], 4), round(p[2], 4))
                for a, b, c in T:
                    n = tri_n(a, b, c)
                    for p in (a, b, c):
                        k = key(p)
                        s = acc.get(k, (0.0, 0.0, 0.0))
                        acc[k] = add(s, n)
                out += [(a, b, c, tuple(unit(acc[key(p)]) for p in (a, b, c))) for a, b, c in T]
            else:
                out += [(a, b, c, None) for a, b, c in T]
        self._put(grp, out)

    def face(self, grp, pts, n):
        """Planar polygon (3D points, convex or not), shown on the side of normal hint n."""
        # true plane normal (Newell), turned to the hint
        nn = [0.0, 0.0, 0.0]
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            nn[0] += (a[1] - b[1]) * (a[2] + b[2])
            nn[1] += (a[2] - b[2]) * (a[0] + b[0])
            nn[2] += (a[0] - b[0]) * (a[1] + b[1])
        pn = unit(tuple(nn))
        n = pn if dot(pn, n) >= 0 else mul(pn, -1)
        e1 = unit(sub(pts[1], pts[0]))
        e2 = cross(n, e1)
        o = pts[0]
        poly = [(dot(sub(p, o), e1), dot(sub(p, o), e2)) for p in pts]
        out = []
        for a, b, c in triangulate(poly):
            P = [add(o, add(mul(e1, q[0]), mul(e2, q[1]))) for q in (a, b, c)]
            if dot(tri_n(*P), n) < 0:
                P = [P[0], P[2], P[1]]
            out.append((P[0], P[1], P[2], None))
        self._put(grp, out)

    def grid_top(self, grp, x0, x1, y0, y1, z, nx, ny):
        """A flat up-facing rectangle split into nx x ny quads (no huge triangles: they show seam sparkles)."""
        for i in range(nx):
            for j in range(ny):
                xa, xb = x0 + (x1 - x0) * i / nx, x0 + (x1 - x0) * (i + 1) / nx
                ya, yb = y0 + (y1 - y0) * j / ny, y0 + (y1 - y0) * (j + 1) / ny
                self.quad(grp, (xa, ya, z), (xb, ya, z), (xb, yb, z), (xa, yb, z), (0, 0, 1))

    def quad(self, grp, a, b, c, d, n):
        out = []
        for P in ((a, b, c), (a, c, d)):
            if dot(tri_n(*P), n) < 0:
                P = (P[0], P[2], P[1])
            out.append((P[0], P[1], P[2], None))
        self._put(grp, out)

    # ---------- boxes
    def obox(self, grp, c, u, v, w, hu, hv, hw, skip=()):
        """Box centred c with unit axes u, v, w (right-handed) and half sizes. skip: '+u','-u','+v','-v','+w','-w'."""
        def P(su, sv, sw):
            return add(c, add(mul(u, su * hu), add(mul(v, sv * hv), mul(w, sw * hw))))
        faces = {
            "+u": [P(1, -1, -1), P(1, 1, -1), P(1, 1, 1), P(1, -1, 1)],
            "-u": [P(-1, 1, -1), P(-1, -1, -1), P(-1, -1, 1), P(-1, 1, 1)],
            "+v": [P(1, 1, -1), P(-1, 1, -1), P(-1, 1, 1), P(1, 1, 1)],
            "-v": [P(-1, -1, -1), P(1, -1, -1), P(1, -1, 1), P(-1, -1, 1)],
            "+w": [P(-1, -1, 1), P(1, -1, 1), P(1, 1, 1), P(-1, 1, 1)],
            "-w": [P(-1, 1, -1), P(1, 1, -1), P(1, -1, -1), P(-1, -1, -1)],
        }
        nrm = {"+u": u, "-u": mul(u, -1), "+v": v, "-v": mul(v, -1), "+w": w, "-w": mul(w, -1)}
        out = []
        for k, q in faces.items():
            if k in skip:
                continue
            for T in ((q[0], q[1], q[2]), (q[0], q[2], q[3])):
                if dot(tri_n(*T), nrm[k]) < 0:
                    T = (T[0], T[2], T[1])
                out.append((T[0], T[1], T[2], None))
        self._put(grp, out)

    def box(self, grp, x0, x1, y0, y1, z0, z1, skip=()):
        m = {"+x": "+u", "-x": "-u", "+y": "+v", "-y": "-v", "+z": "+w", "-z": "-w"}
        self.obox(grp, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (1, 0, 0), (0, 1, 0), (0, 0, 1),
                  (x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2, [m[s] for s in skip])

    def beam(self, grp, p0, p1, w, h, up=(0, 0, 1), skip=()):
        d = sub(p1, p0)
        L = length(d)
        d = unit(d)
        if abs(dot(d, unit(up))) > 0.98:
            up = (1, 0, 0)
        u2 = unit(cross(up, d))
        w2 = cross(d, u2)
        self.obox(grp, mul(add(p0, p1), 0.5), d, u2, w2, L / 2, w / 2, h / 2, skip)

    # ---------- plates and prisms
    def slab(self, gtop, gbot, gedge, corners, t, edges=(True, True, True, True)):
        """corners: 4 points of the top surface CCW seen from above (outside). Underside t below along the normal."""
        n = unit(tri_n(corners[0], corners[1], corners[2]))
        if n[2] < 0:
            corners = corners[::-1]
            edges = tuple(edges[(2 - k) % 4] for k in range(4))
            n = mul(n, -1)
        bot = [sub(p, mul(n, t)) for p in corners]
        self.quad(gtop, *corners, n)
        self.quad(gbot, *bot, mul(n, -1))
        for i in range(4):
            if not edges[i]:
                continue
            a, b = corners[i], corners[(i + 1) % 4]
            a2, b2 = bot[i], bot[(i + 1) % 4]
            en = cross(sub(b, a), n)
            self.quad(gedge, a, a2, b2, b, en)

    def prism(self, grp, poly, z0, z1, frame=None, top=True, bottom=False, sides=True, gside=None, gbottom=None):
        """poly 2D (any winding) extruded from z0 to z1 in frame (origin, ex, ey, ez) (default model axes)."""
        o, ex, ey, ez = frame or ((0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1))
        P2 = Polygon(poly)
        if P2.exterior.is_ccw is False:
            poly = poly[::-1]

        def W(q, z):
            return add(o, add(mul(ex, q[0]), add(mul(ey, q[1]), mul(ez, z))))
        out = []
        cap = triangulate(poly)
        if top:
            for a, b, c in cap:
                out.append((W(a, z1), W(b, z1), W(c, z1)))
        if bottom:
            botT = [(W(a, z0), W(c, z0), W(b, z0)) for a, b, c in cap]
            if gbottom:
                self._put(gbottom, [(a, b, c, None) for a, b, c in botT])
            else:
                out += botT
        side = []
        if sides:
            n = len(poly)
            for i in range(n):
                a, b = poly[i], poly[(i + 1) % n]
                side += [(W(a, z0), W(b, z0), W(b, z1)), (W(a, z0), W(b, z1), W(a, z1))]
        if gside:
            self._put(gside, [(a, b, c, None) for a, b, c in side])
        else:
            out += side
        self._put(grp, [(a, b, c, None) for a, b, c in out])

    def shape(self, grp, geom, z0, z1, top=True, bottom=False, sides=True, gside=None):
        """A shapely (Multi)Polygon (holes allowed) extruded from z0 to z1 in model axes."""
        geoms = list(geom.geoms) if hasattr(geom, "geoms") else [geom]
        for P in geoms:
            if P.is_empty or P.area < 1e-6:
                continue
            caps = []
            for t in constrained_delaunay_triangles(P).geoms:
                c = list(t.exterior.coords)[:3]
                a, b, d = c
                if (b[0] - a[0]) * (d[1] - a[1]) - (b[1] - a[1]) * (d[0] - a[0]) < 0:
                    b, d = d, b
                caps.append((a, b, d))
            out = []
            if top:
                out += [((a[0], a[1], z1), (b[0], b[1], z1), (c[0], c[1], z1), None) for a, b, c in caps]
            if bottom:
                out += [((a[0], a[1], z0), (c[0], c[1], z0), (b[0], b[1], z0), None) for a, b, c in caps]
            self._put(grp, out)
            side = []
            if sides:
                rings = [list(P.exterior.coords)] + [list(r.coords) for r in P.interiors]
                for k, ring in enumerate(rings):
                    ring = ring[:-1]
                    ccw = Polygon(ring).exterior.is_ccw
                    # exterior CCW: outward = right of travel; holes: the other way
                    if (k == 0) != ccw:
                        ring = ring[::-1]
                    for i in range(len(ring)):
                        a, b = ring[i], ring[(i + 1) % len(ring)]
                        A0, B0, A1, B1 = (a[0], a[1], z0), (b[0], b[1], z0), (a[0], a[1], z1), (b[0], b[1], z1)
                        side += [(A0, B0, B1, None), (A0, B1, A1, None)]
            self._put(gside or grp, side)

    # ---------- organic
    def ring_grid(self, rings, seg, cap0="point", cap1="point", ex=2.0):
        """rings: list of (c, a, b). Returns side tris and cap tris. ex > 2: superellipse (rounded box) rings."""
        def f(v):
            return math.copysign(abs(v) ** (2.0 / ex), v)
        R = []
        for c, a, b in rings:
            R.append([add(c, add(mul(a, f(math.cos(2 * math.pi * i / seg))), mul(b, f(math.sin(2 * math.pi * i / seg)))))
                      for i in range(seg)])
        side = []
        for j in range(len(R) - 1):
            for i in range(seg):
                p, q = R[j][i], R[j][(i + 1) % seg]
                r, s = R[j + 1][(i + 1) % seg], R[j + 1][i]
                side += [(p, q, r), (p, r, s)]
        caps = []
        for cap, ring, c, first in ((cap0, R[0], rings[0][0], True), (cap1, R[-1], rings[-1][0], False)):
            if cap is None:
                continue
            for i in range(seg):
                if first:
                    caps.append((c, ring[(i + 1) % seg], ring[i]))
                else:
                    caps.append((c, ring[i], ring[(i + 1) % seg]))
        return side, caps

    def loft(self, grp, rings, seg=24, cap0="flat", cap1="flat", smooth_caps=False, ex=2.0):
        side, caps = self.ring_grid(rings, seg, cap0, cap1, ex)
        self.solid(grp, [(side, True), (caps, smooth_caps)])

    def ellipsoid(self, grp, c, r, nu=24, nv=14, axes=((1, 0, 0), (0, 1, 0), (0, 0, 1)), zcut=None):
        """Ellipsoid radii r along axes. zcut: keep only the part with local w >= zcut * r[2] (open below)."""
        u, v, w = axes
        rings = []
        a0 = -math.pi / 2 if zcut is None else math.asin(max(-1.0, min(1.0, zcut)))
        for j in range(nv + 1):
            ang = a0 + (math.pi / 2 - a0) * j / nv
            s = math.cos(ang)
            cc = add(c, mul(w, r[2] * math.sin(ang)))
            rings.append((cc, mul(u, r[0] * s), mul(v, r[1] * s)))
        side, caps = self.ring_grid(rings, nu, None, None)
        self.solid(grp, [(side, True)])

    def tube(self, grp, path, seg=16, cap0="flat", cap1="flat", up=(0, 0, 1), sq=1.0):
        """path: [(point, r)] or [(point, r, r2)]: rings perpendicular to the path (r along the side, r2 along 'up')."""
        rings = []
        n = len(path)
        for i, pr in enumerate(path):
            p, r = pr[0], pr[1]
            r2 = pr[2] if len(pr) > 2 else r * sq
            d = unit(sub(path[min(i + 1, n - 1)][0], path[max(i - 1, 0)][0]))
            uu = up if abs(dot(d, unit(up))) < 0.95 else (1, 0, 0)
            a = unit(cross(d, uu))
            b = cross(a, d)
            rings.append((p, mul(a, r), mul(b, r2)))
        self.loft(grp, rings, seg, cap0, cap1)


# ---------------------------------------------------------------- export
def to_world(p, pivot, bearing, s=3.0):
    b = math.radians(bearing)
    x, y, z = p
    east = x * math.sin(b) - y * math.cos(b)
    north = x * math.cos(b) + y * math.sin(b)
    return (pivot[0] + s * east, pivot[1] + s * z, pivot[2] - s * north)


def to_world_dir(n, bearing):
    b = math.radians(bearing)
    x, y, z = n
    east = x * math.sin(b) - y * math.cos(b)
    north = x * math.cos(b) + y * math.sin(b)
    return (east, z, -north)


MAX_TRIS = 9000


def export(model, pivot, bearing, out_glb, tag, s=3.0):
    named = []
    world = []
    k = 0
    for grp in sorted(model.g):
        T = model.g[grp]
        for st in range(0, len(T), MAX_TRIS):
            m = Mesh()
            for a, b, c, n, sid in T[st:st + MAX_TRIS]:
                P = [to_world(p, pivot, bearing, s) for p in (a, b, c)]
                N = [to_world_dir(q, bearing) for q in n] if n else None
                m.tri(P[0], P[1], P[2], *box_uv(P), (255, 255, 255), N)
                world.append(((P[0], P[1], P[2]), grp, sid))
            if not m.T:
                continue
            k += 1
            lo, hi = m.box()
            cc = [(lo[i] + hi[i]) / 2 for i in range(3)]
            sz = [hi[i] - lo[i] for i in range(3)]
            named.append((code(grp, "%ss%d" % (tag, k), cc, sz), m))
    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    info = write_glb(out_glb, named, generator="solid3d.py")
    n, bad = check_glb(out_glb, info)
    return dict(path=out_glb, meshes=len(named), tris=sum(v["tris"] for v in info.values()), bad=bad,
                names=[nm for nm, _ in named]), world


def collide_rows(boxes, pivot, bearing, s=3.0):
    """boxes in model metres: (cx, cy, z0, sx, sy, sz, yaw_local_deg) -> rows (X, Y, Z, SX, SY, SZ, yawRad) in studs,
    yaw for CFrame.Angles(0, yaw, 0) (Roblox: positive yaw turns +X towards -Z)."""
    rows = []
    for cx, cy, z0, sx, sy, sz, yl in boxes:
        X, Y, Z = to_world((cx, cy, z0 + sz / 2), pivot, bearing, s)
        # local x axis in world (east, north) -> heading
        ang = math.radians(bearing - yl)  # bearing of the box's local x (yaw_local turns it CCW = towards left)
        e, nn = math.sin(ang), math.cos(ang)
        # Roblox: CFrame.Angles(0, yaw, 0) maps +X to (cos yaw, 0, -sin yaw); want (e, 0, -nn)
        yaw = math.atan2(nn, e)
        rows.append((round(X, 2), round(Y, 2), round(Z, 2), round(sx * s, 2), round(sz * s, 2), round(sy * s, 2), round(yaw, 4)))
    return rows
