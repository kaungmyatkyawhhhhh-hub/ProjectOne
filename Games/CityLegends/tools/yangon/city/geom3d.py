"""geom3d.py: pure-Python 3D geometry for real-geometry landmarks (no picture atlas: every face belongs to a MATERIAL
GROUP; in Studio each group becomes MeshParts with that group's Roblox Material / Color / Transparency).

Model coords: x east, y north, z up (studs); landmark_glb3d.py turns them into world studs.
Every face is wound counter-clockwise seen from the side that shows (Roblox draws only that side, unless the group is
marked double-sided).

    g = Geo()
    g.wall(grp, p, q, z0, z1)            vertical quad, outside on the right walking p -> q
    g.ring(grp, poly, z0, z1)            the walls of a CCW polygon (inward=True: faces toward the inside)
    g.cap(grp, poly, z, down=False, holes=[...])   flat polygon (constrained Delaunay, concave and holes fine)
    g.band(grp, poly, z0, z1, out)       a strip standing out by `out` from the polygon's walls (front, top, bottom)
    g.box(grp, cx, cy, z0, sx, sy, sz, yaw)        sx along the yaw direction
    g.tube(grp, a, b, w)                 square tube a -> b
    g.column(grp, cx, cy, z0, z1, r, n=8)
    g.text(grp, letters, text, origin, right, h, depth)            3D letters on a plane facing -front
    g.text_arc(grp, letters, text, centre, r, a_mid, z0, h, depth, width)   letters bent round an arc, facing out
"""
import math

import shapely
from shapely.geometry import Polygon, Point


def ccw(poly):
    a = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % len(poly)]
        a += x0 * y1 - x1 * y0
    return list(poly) if a > 0 else list(reversed(poly))


def offset_poly(poly, d):
    """Polygon pushed out by d (in for d < 0); miter capped at sharp corners; keeps the point count (for annuli)."""
    poly = ccw(poly)
    out = []
    n = len(poly)
    for i in range(n):
        p0, p1, p2 = poly[i - 1], poly[i], poly[(i + 1) % n]
        e0 = _unit((p1[0] - p0[0], p1[1] - p0[1]))
        e1 = _unit((p2[0] - p1[0], p2[1] - p1[1]))
        n0 = (e0[1], -e0[0])
        n1 = (e1[1], -e1[0])
        nm = _unit((n0[0] + n1[0], n0[1] + n1[1]), n0)
        k = d / max(nm[0] * n0[0] + nm[1] * n0[1], 0.35)
        out.append((p1[0] + nm[0] * k, p1[1] + nm[1] * k))
    return out


def _unit(v, fallback=(1.0, 0.0)):
    l = math.hypot(v[0], v[1])
    return (v[0] / l, v[1] / l) if l > 1e-9 else fallback


def outward(poly, i):
    p, q = poly[i], poly[(i + 1) % len(poly)]
    e = _unit((q[0] - p[0], q[1] - p[1]))
    return (e[1], -e[0])


def ellipse(cx, cy, rx, ry, n=32, a0=0.0):
    return [(cx + rx * math.cos(a0 + 2 * math.pi * k / n), cy + ry * math.sin(a0 + 2 * math.pi * k / n)) for k in range(n)]


class Geo:
    def __init__(self):
        self.g = {}

    # ---- primitives ----
    def tri(self, grp, a, b, c):
        self.g.setdefault(grp, []).append((tuple(a), tuple(b), tuple(c)))

    def quad(self, grp, a, b, c, d):
        self.tri(grp, a, b, c)
        self.tri(grp, a, c, d)

    def poly3(self, grp, pts):
        for k in range(1, len(pts) - 1):
            self.tri(grp, pts[0], pts[k], pts[k + 1])

    def wall(self, grp, p, q, z0, z1, inward=False):
        a, b, c, d = (p[0], p[1], z0), (q[0], q[1], z0), (q[0], q[1], z1), (p[0], p[1], z1)
        if inward:
            self.quad(grp, b, a, d, c)
        else:
            self.quad(grp, a, b, c, d)

    def ring(self, grp, poly, z0, z1, inward=False, edges=None, skip=None):
        """skip(p, q) -> list of (t0, t1) spans along the edge to leave open (doors)."""
        poly = ccw(poly)
        for i in range(len(poly)):
            if edges is not None and i not in edges:
                continue
            p, q = poly[i], poly[(i + 1) % len(poly)]
            spans = skip(p, q) if skip else []
            for a, b in _keep_spans(spans):
                pa = (p[0] + (q[0] - p[0]) * a, p[1] + (q[1] - p[1]) * a)
                pb = (p[0] + (q[0] - p[0]) * b, p[1] + (q[1] - p[1]) * b)
                self.wall(grp, pa, pb, z0, z1, inward)

    def cap(self, grp, poly, z, down=False, holes=()):
        P = Polygon(ccw(poly), [ccw(h)[::-1] for h in holes]).buffer(0)
        geoms = [P] if P.geom_type == "Polygon" else list(getattr(P, "geoms", []))
        for G in geoms:
            if G.is_empty or G.area < 1e-4:
                continue
            for t in shapely.constrained_delaunay_triangles(G).geoms:
                c = list(t.exterior.coords)[:3]
                a = (c[1][0] - c[0][0]) * (c[2][1] - c[0][1]) - (c[1][1] - c[0][1]) * (c[2][0] - c[0][0])
                if abs(a) < 1e-9:
                    continue
                if (a > 0) == down:
                    c = [c[0], c[2], c[1]]
                self.tri(grp, (c[0][0], c[0][1], z), (c[1][0], c[1][1], z), (c[2][0], c[2][1], z))

    def capshape(self, grp, shape, z, down=False):
        """Cap any shapely (Multi)Polygon."""
        geoms = [shape] if shape.geom_type == "Polygon" else list(getattr(shape, "geoms", []))
        for G in geoms:
            if G.geom_type != "Polygon" or G.area < 1e-3:
                continue
            for t in shapely.constrained_delaunay_triangles(G).geoms:
                c = list(t.exterior.coords)[:3]
                a = (c[1][0] - c[0][0]) * (c[2][1] - c[0][1]) - (c[1][1] - c[0][1]) * (c[2][0] - c[0][0])
                if abs(a) < 1e-9:
                    continue
                if (a > 0) == down:
                    c = [c[0], c[2], c[1]]
                self.tri(grp, (c[0][0], c[0][1], z), (c[1][0], c[1][1], z), (c[2][0], c[2][1], z))

    def wallshape(self, grp, shape, z0, z1, inward=False):
        """Walls round every ring of a shapely (Multi)Polygon (holes face into the hole)."""
        geoms = [shape] if shape.geom_type == "Polygon" else list(getattr(shape, "geoms", []))
        for G in geoms:
            if G.geom_type != "Polygon":
                continue
            ext = list(G.exterior.coords)[:-1]
            self.ring(grp, ext, z0, z1, inward)
            for h in G.interiors:
                hh = ccw(list(h.coords)[:-1])
                self.ring(grp, hh, z0, z1, not inward)

    def annulus(self, grp, outer, inner, z, down=False):
        outer, inner = ccw(outer), ccw(inner)
        for i in range(len(outer)):
            a, b = outer[i], outer[(i + 1) % len(outer)]
            c, d = inner[(i + 1) % len(inner)], inner[i]
            pts = [(a[0], a[1], z), (b[0], b[1], z), (c[0], c[1], z), (d[0], d[1], z)]
            if down:
                pts = pts[::-1]
            self.quad(grp, *pts)

    def band(self, grp, poly, z0, z1, out, top=True, bottom=True, edges=None):
        """A strip proud of the wall line by `out`: its front face on the offset polygon, top and bottom faces."""
        poly = ccw(poly)
        op = offset_poly(poly, out)
        for i in range(len(poly)):
            if edges is not None and i not in edges:
                continue
            j = (i + 1) % len(poly)
            self.wall(grp, op[i], op[j], z0, z1)
            if top:
                self.quad(grp, (op[i][0], op[i][1], z1), (op[j][0], op[j][1], z1), (poly[j][0], poly[j][1], z1),
                          (poly[i][0], poly[i][1], z1))
            if bottom:
                self.quad(grp, (poly[i][0], poly[i][1], z0), (poly[j][0], poly[j][1], z0), (op[j][0], op[j][1], z0),
                          (op[i][0], op[i][1], z0))

    def box(self, grp, cx, cy, z0, sx, sy, sz, yaw=0.0, faces=("+x", "-x", "+y", "-y", "top", "bottom")):
        co, si = math.cos(yaw), math.sin(yaw)

        def P(dx, dy, z):
            return (cx + dx * co - dy * si, cy + dx * si + dy * co, z)
        hx, hy, z1 = sx / 2, sy / 2, z0 + sz
        A, B, C, D = P(-hx, -hy, 0), P(hx, -hy, 0), P(hx, hy, 0), P(-hx, hy, 0)
        z = lambda p, h: (p[0], p[1], h)
        if "-y" in faces:
            self.quad(grp, z(A, z0), z(B, z0), z(B, z1), z(A, z1))
        if "+x" in faces:
            self.quad(grp, z(B, z0), z(C, z0), z(C, z1), z(B, z1))
        if "+y" in faces:
            self.quad(grp, z(C, z0), z(D, z0), z(D, z1), z(C, z1))
        if "-x" in faces:
            self.quad(grp, z(D, z0), z(A, z0), z(A, z1), z(D, z1))
        if "top" in faces:
            self.quad(grp, z(A, z1), z(B, z1), z(C, z1), z(D, z1))
        if "bottom" in faces:
            self.quad(grp, z(A, z0), z(D, z0), z(C, z0), z(B, z0))

    def tube(self, grp, a, b, w):
        ax = _v3unit((b[0] - a[0], b[1] - a[1], b[2] - a[2]))
        up = (0.0, 0.0, 1.0) if abs(ax[2]) < 0.95 else (1.0, 0.0, 0.0)
        s1 = _v3unit(_cross(ax, up))
        s2 = _v3unit(_cross(s1, ax))
        r = w / 2
        ring = [_add(_mul(s1, r), _mul(s2, r)), _add(_mul(s1, -r), _mul(s2, r)), _add(_mul(s1, -r), _mul(s2, -r)),
                _add(_mul(s1, r), _mul(s2, -r))]
        for i in range(4):
            p0, p1 = ring[i], ring[(i + 1) % 4]
            self.quad(grp, _add(a, p0), _add(a, p1), _add(b, p1), _add(b, p0))

    def column(self, grp, cx, cy, z0, z1, r, n=8):
        pts = [(cx + r * math.cos(2 * math.pi * k / n), cy + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
        self.ring(grp, pts, z0, z1)

    # ---- 3D letters (text3d_blend.py unit meshes: x along, z up, y depth with the front at y = 0) ----
    def text(self, grp, letters, text, origin, right, h, depth, align="center", max_w=None):
        """Letters standing on a plane: origin = (x, y, z) of the baseline's middle (align center) on the front face;
        right = unit (x, y) along the text as the viewer reads it; the letters face toward the viewer (right rotated
        clockwise: front = (right.y, -right.x))."""
        L = letters[text]
        s = h
        if max_w and L["w"] * s > max_w:
            s = max_w / L["w"]
        rx, ry = right
        fx, fy = ry, -rx  # the front direction (toward the viewer)
        x0 = {"center": -L["w"] * s / 2, "left": 0.0, "right": -L["w"] * s}[align]
        for t in L["tris"]:
            pts = []
            for (u, v, w) in t:
                along = x0 + u * s
                back = v * depth
                pts.append((origin[0] + rx * along - fx * back, origin[1] + ry * along - fy * back, origin[2] + w * s))
            self.tri(grp, *pts)
        return L["w"] * s

    def text_arc(self, grp, letters, text, centre, r, a_mid, z0, h, depth, width=None):
        """Letters bent round a circle (centre, radius r), reading left -> right from outside, middle at angle a_mid,
        baseline at z0, front face on radius r, depth into the circle."""
        L = letters[text]
        s = h
        if width:
            s = width / L["w"]
        total = L["w"] * s
        for t in L["tris"]:
            pts = []
            for (u, v, w) in t:
                along = u * s - total / 2
                ang = a_mid + along / r  # increasing angle = the outside viewer's right
                rr = r - v * depth
                pts.append((centre[0] + rr * math.cos(ang), centre[1] + rr * math.sin(ang), z0 + w * s))
            self.tri(grp, *pts)
        return total, s

    def count(self):
        return {k: len(v) for k, v in self.g.items()}


def _keep_spans(skip):
    """[0, 1] minus the skip spans -> the spans to build."""
    spans = [(0.0, 1.0)]
    for a, b in sorted(skip or []):
        new = []
        for s0, s1 in spans:
            if b <= s0 or a >= s1:
                new.append((s0, s1))
                continue
            if a > s0:
                new.append((s0, a))
            if b < s1:
                new.append((b, s1))
        spans = new
    return [(a, b) for a, b in spans if b - a > 1e-4]


def _v3unit(v):
    l = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)
    return (v[0] / l, v[1] / l, v[2] / l) if l > 1e-9 else (1.0, 0.0, 0.0)


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _mul(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def raster_boxes(shape, z0, z1, cell=4.0):
    """Collision for a flat slab of any shape: axis boxes inside the shape (row runs, then runs with the same span in
    consecutive rows merged) -> [(cx, cy, z0, sx, sy, sz, 0)]."""
    if shape.is_empty:
        return []
    from shapely.prepared import prep as _prep
    pp = _prep(shape)
    x0, y0, x1, y1 = shape.bounds
    rows = []
    y = math.floor(y0 / cell) * cell
    while y < y1:
        runs = []
        x = math.floor(x0 / cell) * cell
        run = None
        while x <= x1 + cell:
            inside = pp.contains(Point(x + cell / 2, y + cell / 2))
            if inside and run is None:
                run = x
            if (not inside or x > x1) and run is not None:
                runs.append((run, x))
                run = None
            x += cell
        rows.append((y, runs))
        y += cell
    out = []
    open_ = {}  # (xa, xb) -> start y
    prev_y = None
    for y, runs in rows + [(None, [])]:
        cur = set(runs)
        for span in list(open_):
            if span not in cur:
                ys = open_.pop(span)
                ye = prev_y + cell
                out.append(((span[0] + span[1]) / 2, (ys + ye) / 2, z0, span[1] - span[0], ye - ys, z1 - z0, 0.0))
        for span in cur:
            if span not in open_:
                open_[span] = y
        prev_y = y
    return out
