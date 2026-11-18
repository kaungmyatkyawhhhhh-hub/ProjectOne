"""Yangon traffic vehicles the roster lacks (2026-11-19): Probox wagon, Hiace van, Carry kei truck, YBS bus.
Our own low-poly shapes from real sizes (no downloaded models, no badges). One .glb, one group per vehicle:
Traffic_<type>_<id> = Body (paint, recoloured per livery in TrafficBodies) + Detail (glass, trim, lamps; vertex
colours) + FL / FR / RL / RR wheels (pivot at the hub). Front is -Z (like split_cars.py; the importer turns it to +Z),
wheels' bottom at y 0, metres (TrafficBodies scales each car to its real length).

usage: python -I yangon_traffic_cars.py out.glb [--svg views.svg]
"""
import sys, json, struct, math

GLASS = (0.10, 0.12, 0.14)
TRIM = (0.07, 0.07, 0.08)
LAMP = (0.90, 0.90, 0.86)
TAIL = (0.70, 0.04, 0.05)
AMBER = (0.95, 0.55, 0.08)
TYRE = (0.06, 0.06, 0.06)
RIM = (0.62, 0.63, 0.65)
WHITE = (0.93, 0.93, 0.92)
PAINT = (1.0, 1.0, 1.0)


class Mesh:
    def __init__(self):
        self.P, self.N, self.C = [], [], []

    def tri(self, a, b, c, col):
        u = [b[i] - a[i] for i in range(3)]
        v = [c[i] - a[i] for i in range(3)]
        n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
        L = math.sqrt(sum(x * x for x in n))
        if L < 1e-12:
            return
        n = [x / L for x in n]
        for p in (a, b, c):
            self.P.append(tuple(p))
            self.N.append(tuple(n))
            self.C.append(col)

    def quad(self, a, b, c, d, col):
        self.tri(a, b, c, col)
        self.tri(a, c, d, col)

    def tris(self):
        return len(self.P) // 3


def area2(poly):
    return sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))


def ear_clip(poly):
    """triangles (index triples) of a simple polygon, counter-clockwise"""
    idx = list(range(len(poly)))
    if area2(poly) < 0:
        idx.reverse()
    out = []

    def inside(p, a, b, c):
        def s(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = s(p, a, b), s(p, b, c), s(p, c, a)
        return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        n = len(idx)
        for k in range(n):
            i0, i1, i2 = idx[(k - 1) % n], idx[k], idx[(k + 1) % n]
            a, b, c = poly[i0], poly[i1], poly[i2]
            if (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]) <= 1e-12:
                continue
            if any(inside(poly[j], a, b, c) for j in idx if j not in (i0, i1, i2)):
                continue
            out.append((i0, i1, i2))
            idx.pop(k)
            break
        else:
            break
    if len(idx) == 3:
        out.append(tuple(idx))
    return out


def clip_a(poly, a0, a1):
    """the part of a profile polygon (a, y) between a0 and a1 (Sutherland-Hodgman, two vertical lines)"""
    def cut(pts, keep, edge):
        out = []
        for i in range(len(pts)):
            p, q = pts[i], pts[(i + 1) % len(pts)]
            pin, qin = keep(p), keep(q)
            if pin:
                out.append(p)
            if pin != qin:
                t = (edge - p[0]) / (q[0] - p[0])
                out.append((edge, p[1] + t * (q[1] - p[1])))
        return out
    pts = cut(poly, lambda p: p[0] >= a0, a0)
    return cut(pts, lambda p: p[0] <= a1, a1) if pts else []


class Car:
    def __init__(self, length):
        self.L = length
        self.body, self.detail = Mesh(), Mesh()
        self.wheels = {}

    def pt(self, x, y, a):
        return (x, y, -(a - self.L / 2))  # front (a = L) is -Z

    def extrude(self, m, prof, hw, col):
        """profile (a, y) extruded across the car; hw(y) = half width at that height (tumblehome)"""
        if area2(prof) < 0:
            prof = prof[::-1]
        tris = ear_clip(prof)
        for s in (1, -1):
            for (i, j, k) in tris:
                P = [self.pt(s * hw(prof[q][1]), prof[q][1], prof[q][0]) for q in (i, j, k)]
                if s > 0:
                    m.tri(P[0], P[2], P[1], col)
                else:
                    m.tri(P[0], P[1], P[2], col)
        for q in range(len(prof)):
            p0, p1 = prof[q], prof[(q + 1) % len(prof)]
            m.quad(self.pt(hw(p0[1]), p0[1], p0[0]), self.pt(hw(p1[1]), p1[1], p1[0]),
                   self.pt(-hw(p1[1]), p1[1], p1[0]), self.pt(-hw(p0[1]), p0[1], p0[0]), col)

    def box(self, m, x0, x1, y0, y1, a0, a1, col):
        c = [self.pt(x, y, a) for a in (a0, a1) for y in (y0, y1) for x in (x0, x1)]
        # c index = ai*4 + yi*2 + xi
        F = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
        for f in F:
            m.quad(c[f[0]], c[f[1]], c[f[2]], c[f[3]], col)

    def pair(self, m, xin, xout, y0, y1, a0, a1, col):
        self.box(m, xin, xout, y0, y1, a0, a1, col)
        self.box(m, -xout, -xin, y0, y1, a0, a1, col)

    def wheel(self, name, a, side, r, w, x):
        m = Mesh()
        n = 14
        hub = self.pt(side * x, r, a)
        for k in range(n):
            t0, t1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
            p = lambda t, dx: (dx, r * math.cos(t), r * math.sin(t))
            o, i = side * w / 2, -side * w / 2
            # tread
            m.quad(p(t0, o), p(t1, o), p(t1, i), p(t0, i), TYRE) if side > 0 else m.quad(p(t0, o), p(t0, i), p(t1, i), p(t1, o), TYRE)
            # outer face: rim disc inside a tyre ring; inner face plain
            rr = r * 0.62
            q = lambda t, rad, dx: (dx, rad * math.cos(t), rad * math.sin(t))
            for (col, ra, rb, dx) in ((TYRE, rr, r, o), (RIM, 0, rr, o + side * 0.012)):
                if side > 0:
                    m.quad(q(t0, ra, dx), q(t0, rb, dx), q(t1, rb, dx), q(t1, ra, dx), col)
                else:
                    m.quad(q(t0, ra, dx), q(t1, ra, dx), q(t1, rb, dx), q(t0, rb, dx), col)
            if side > 0:
                m.tri((i, 0, 0), q(t1, r, i), q(t0, r, i), TYRE)
            else:
                m.tri((i, 0, 0), q(t0, r, i), q(t1, r, i), TYRE)
        self.wheels[name] = (m, hub)

    def four(self, af, ar, r, w, x):
        self.wheel("FL", af, -1, r, w, x)
        self.wheel("FR", af, 1, r, w, x)
        self.wheel("RL", ar, -1, r, w, x)
        self.wheel("RR", ar, 1, r, w, x)


def arches(bottom, ends, wheels_at, r):
    """the lower body's bottom edge (rear to front) with a round arch over each wheel"""
    pts = [(ends[0], bottom)]
    for a in sorted(wheels_at):
        R = r + 0.05
        for k in range(9):
            t = math.pi - math.pi * k / 8
            pts.append((a + R * math.cos(t), max(bottom, r + R * math.sin(t))))
    pts.append((ends[1], bottom))
    return pts


def probox():
    L, W, H = 4.24, 1.69, 1.52
    c = Car(L)
    r, af, ar = 0.29, L - 0.85, 0.84
    hw = lambda y: W / 2 - max(0.0, 0.40 - y) * 0.12
    low = arches(0.24, (0.06, L - 0.08), (ar, af), r)[::-1]  # front to rear along the bottom
    prof = [(0.0, 0.34), (0.0, 0.93), (3.22, 0.96), (3.70, 0.86), (L - 0.04, 0.80), (L, 0.62), (L, 0.36), (L - 0.06, 0.26)]
    prof = prof[:-1] + low[1:]
    c.extrude(c.body, prof, hw, PAINT)
    # greenhouse: a boxy wagon, near-vertical tailgate glass, a raked windscreen
    gh = [(0.03, 0.93), (3.22, 0.96), (2.42, H - 0.02), (0.12, H - 0.03)]
    ghw = lambda y: W / 2 - 0.05 - (y - 0.93) * 0.30
    c.extrude(c.detail, gh, ghw, GLASS)
    roof = [(0.1, H - 0.03), (2.44, H - 0.03), (2.40, H), (0.12, H)]
    c.extrude(c.body, roof, lambda y: ghw(H - 0.03) + 0.015, PAINT)
    for a0, a1 in ((0.03, 0.20), (1.30, 1.40), (2.30, 2.50), (2.92, 3.22)):  # D, C(B), A pillars
        part = clip_a(gh, a0, a1)
        if part:
            c.extrude(c.body, part, lambda y: ghw(y) + 0.02, PAINT)
    # lamps, grille, bumpers, mirrors, the taxi roof sign
    c.pair(c.detail, 0.40, 0.78, 0.58, 0.74, L - 0.02, L + 0.02, LAMP)
    c.box(c.detail, -0.38, 0.38, 0.46, 0.68, L - 0.02, L + 0.015, TRIM)
    c.box(c.detail, -W / 2 + 0.02, W / 2 - 0.02, 0.22, 0.42, L - 0.03, L + 0.06, TRIM)
    c.box(c.detail, -W / 2 + 0.02, W / 2 - 0.02, 0.24, 0.44, -0.06, 0.03, TRIM)
    c.pair(c.detail, 0.52, 0.80, 0.62, 0.88, -0.02, 0.02, TAIL)
    c.pair(c.detail, W / 2 - 0.03, W / 2 + 0.12, 0.98, 1.10, 3.05, 3.15, TRIM)
    c.box(c.detail, -0.24, 0.24, H, H + 0.12, 1.55, 1.75, AMBER)
    c.four(af, ar, r, 0.19, W / 2 - 0.12)
    return "A_probox", c


def hiace():
    L, W, H = 4.84, 1.69, 1.98
    c = Car(L)
    r, af, ar = 0.31, L - 0.87, 0.86
    hw = lambda y: W / 2 - max(0.0, 0.40 - y) * 0.12
    low = arches(0.24, (0.05, L - 0.10), (ar, af), r)[::-1]
    prof = [(0.0, 0.34), (0.0, 1.02), (4.30, 1.06), (L - 0.05, 0.95), (L, 0.70), (L, 0.36), (L - 0.08, 0.26)]
    prof = prof[:-1] + low[1:]
    c.extrude(c.body, prof, hw, PAINT)
    gh = [(0.02, 1.02), (4.30, 1.06), (3.90, H - 0.03), (0.04, H - 0.03)]
    ghw = lambda y: W / 2 - 0.03 - (y - 1.02) * 0.10
    c.extrude(c.detail, gh, ghw, GLASS)
    roof = [(0.04, H - 0.03), (3.92, H - 0.03), (3.88, H), (0.06, H)]
    c.extrude(c.body, roof, lambda y: ghw(H - 0.03) + 0.015, PAINT)
    # a van: mostly painted sides, a window band, pillars
    for a0, a1 in ((0.02, 0.16), (1.05, 1.95), (2.85, 3.00), (3.60, 3.80), (4.00, 4.30)):
        part = clip_a(gh, a0, a1)
        if part:
            c.extrude(c.body, part, lambda y: ghw(y) + 0.02, PAINT)
    c.pair(c.detail, 0.45, 0.80, 0.78, 0.94, L - 0.02, L + 0.02, LAMP)
    c.box(c.detail, -0.42, 0.42, 0.62, 0.86, L - 0.02, L + 0.015, TRIM)
    c.box(c.detail, -W / 2 + 0.02, W / 2 - 0.02, 0.22, 0.44, L - 0.04, L + 0.06, TRIM)
    c.box(c.detail, -W / 2 + 0.02, W / 2 - 0.02, 0.24, 0.44, -0.06, 0.03, TRIM)
    c.pair(c.detail, 0.60, 0.82, 0.55, 0.95, -0.02, 0.02, TAIL)
    c.pair(c.detail, W / 2 - 0.03, W / 2 + 0.14, 1.10, 1.26, 4.15, 4.25, TRIM)
    c.four(af, ar, r, 0.20, W / 2 - 0.12)
    return "C_hiace", c


def carry():
    L, W, H = 3.395, 1.475, 1.765
    c = Car(L)
    r, af, ar = 0.27, L - 0.62, 0.90
    hw = lambda y: W / 2 - max(0.0, 0.40 - y) * 0.10
    cab0 = 1.95
    low = arches(0.26, (cab0, L - 0.06), (af,), r)[::-1]
    prof = [(cab0, 0.34), (cab0, 1.05), (L - 0.06, 1.05), (L, 0.80), (L, 0.36), (L - 0.05, 0.28)]
    prof = prof[:-1] + low[1:]
    c.extrude(c.body, prof, hw, PAINT)
    gh = [(cab0, 1.05), (L - 0.06, 1.05), (L - 0.30, H - 0.03), (cab0 + 0.02, H - 0.03)]
    ghw = lambda y: W / 2 - 0.04 - (y - 1.05) * 0.12
    c.extrude(c.detail, gh, ghw, GLASS)
    c.extrude(c.body, [(cab0 + 0.02, H - 0.03), (L - 0.29, H - 0.03), (L - 0.31, H), (cab0 + 0.04, H)],
              lambda y: ghw(H - 0.03) + 0.015, PAINT)
    for a0, a1 in ((cab0, cab0 + 0.55), (L - 0.50, L - 0.06)):  # the cab's back wall and the door pillar
        part = clip_a(gh, a0, a1)
        if part:
            c.extrude(c.body, part, lambda y: ghw(y) + 0.02, PAINT)
    # the bed: chassis, floor, low drop sides (white), a headboard guard
    c.box(c.detail, -0.35, 0.35, 0.30, 0.55, 0.30, cab0, TRIM)
    c.box(c.detail, -W / 2, W / 2, 0.55, 0.66, 0.0, cab0 - 0.03, (0.55, 0.56, 0.58))
    c.pair(c.detail, W / 2 - 0.04, W / 2, 0.66, 0.98, 0.0, cab0 - 0.03, WHITE)
    c.box(c.detail, -W / 2, W / 2, 0.66, 0.98, 0.0, 0.04, WHITE)
    c.box(c.detail, -W / 2 + 0.05, W / 2 - 0.05, 0.98, 1.45, cab0 - 0.06, cab0 - 0.02, TRIM)
    c.pair(c.detail, 0.48, 0.70, 0.82, 0.96, L - 0.02, L + 0.02, LAMP)
    c.box(c.detail, -W / 2 + 0.02, W / 2 - 0.02, 0.26, 0.44, L - 0.03, L + 0.05, TRIM)
    c.pair(c.detail, 0.50, 0.70, 0.66, 0.80, -0.03, 0.0, TAIL)
    c.pair(c.detail, W / 2 - 0.03, W / 2 + 0.12, 1.15, 1.30, L - 0.25, L - 0.17, TRIM)
    # one wheel arch at the back cut from nothing: the bed sits above the rear wheels
    c.four(af, ar, r, 0.17, W / 2 - 0.12)
    return "H_carry", c


def ybs_bus():
    L, W, H = 11.0, 2.5, 3.2
    c = Car(L)
    r, af, ar = 0.50, L - 2.55, 2.65
    hw = lambda y: W / 2
    low = arches(0.32, (0.05, L - 0.05), (ar, af), r)[::-1]
    prof = [(0.0, 0.40), (0.0, 1.30), (L - 0.02, 1.30), (L, 1.10), (L, 0.45), (L - 0.05, 0.34)]
    prof = prof[:-1] + low[1:]
    c.extrude(c.body, prof, hw, PAINT)
    gh = [(0.0, 1.30), (L - 0.02, 1.30), (L - 0.10, 2.85), (0.0, 2.85)]
    ghw = lambda y: W / 2 - 0.02
    c.extrude(c.detail, gh, ghw, GLASS)
    # window pillars every 1.2 m, painted; the white roof band and the route box over the windscreen
    a = 0.0
    while a < L - 1.0:
        part = clip_a(gh, a, a + 0.12)
        if part:
            c.extrude(c.body, part, lambda y: ghw(y) + 0.02, PAINT)
        a += 1.2
    c.extrude(c.detail, [(0.0, 2.85), (L - 0.10, 2.85), (L - 0.10, H - 0.05), (0.05, H - 0.05)], hw, WHITE)
    c.box(c.detail, -W / 2 + 0.15, W / 2 - 0.15, H - 0.05, H + 0.05, 1.0, L - 1.5, (0.78, 0.79, 0.80))
    c.box(c.detail, -0.80, 0.80, 2.55, 2.80, L - 0.11, L - 0.07, WHITE)
    c.box(c.detail, -0.70, 0.70, 2.58, 2.77, L - 0.07, L - 0.05, (0.12, 0.05, 0.03))
    c.pair(c.detail, 0.85, 1.15, 0.65, 0.85, L - 0.02, L + 0.02, LAMP)
    c.box(c.detail, -W / 2, W / 2, 0.32, 0.58, L - 0.03, L + 0.07, TRIM)
    c.box(c.detail, -W / 2, W / 2, 0.34, 0.58, -0.07, 0.02, TRIM)
    c.pair(c.detail, 0.95, 1.20, 0.70, 1.20, -0.02, 0.02, TAIL)
    c.pair(c.detail, W / 2, W / 2 + 0.20, 2.10, 2.40, L - 0.25, L - 0.15, TRIM)
    c.four(af, ar, r, 0.28, W / 2 - 0.20)
    return "D_ybs", c


# ---------------------------------------------------------------- glb
def write(path, cars):
    buf = bytearray()
    views, accs, meshes, nodes, roots = [], [], [], [], []

    def view(data, target):
        while len(buf) % 4:
            buf.append(0)
        views.append({"buffer": 0, "byteOffset": len(buf), "byteLength": len(data), "target": target})
        buf.extend(data)
        return len(views) - 1

    def acc(vals, n, minmax=False):
        flat = [x for v in vals for x in v]
        a = {"bufferView": view(struct.pack("<%df" % len(flat), *flat), 34962), "componentType": 5126,
             "count": len(vals), "type": {3: "VEC3", 4: "VEC4"}[n]}
        if minmax:
            a["min"] = [min(v[i] for v in vals) for i in range(n)]
            a["max"] = [max(v[i] for v in vals) for i in range(n)]
        accs.append(a)
        return len(accs) - 1

    def mesh(name, m, origin):
        P = [(p[0] - origin[0], p[1] - origin[1], p[2] - origin[2]) for p in m.P]
        attrs = {"POSITION": acc(P, 3, True), "NORMAL": acc(m.N, 3), "COLOR_0": acc([c + (1.0,) for c in m.C], 4)}
        meshes.append({"name": name, "primitives": [{"attributes": attrs, "material": 0}]})
        return len(meshes) - 1

    for i, (name, c) in enumerate(cars):
        kids = []
        for part, m in (("Body", c.body), ("Detail", c.detail)):
            nodes.append({"name": part, "mesh": mesh(part, m, (0, 0, 0))})
            kids.append(len(nodes) - 1)
        for q, (m, hub) in c.wheels.items():
            nodes.append({"name": q, "mesh": mesh(q, m, (0, 0, 0)), "translation": list(hub)})
            kids.append(len(nodes) - 1)
        nodes.append({"name": "Traffic_" + name, "children": kids, "translation": [i * 14.0, 0, 0]})
        roots.append(len(nodes) - 1)
    out = {"asset": {"version": "2.0", "generator": "CityLegends yangon_traffic_cars.py"}, "scene": 0,
           "scenes": [{"nodes": roots}], "nodes": nodes, "meshes": meshes, "accessors": accs, "bufferViews": views,
           "buffers": [{"byteLength": 0}],
           "materials": [{"name": "VertexColour", "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0, "roughnessFactor": 0.6}}]}
    while len(buf) % 4:
        buf.append(0)
    out["buffers"][0]["byteLength"] = len(buf)
    js = json.dumps(out).encode()
    while len(js) % 4:
        js += b" "
    glb = (struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(buf)) + struct.pack("<I4s", len(js), b"JSON") + js
           + struct.pack("<I4s", len(buf), b"BIN\0") + bytes(buf))
    open(path, "wb").write(glb)


def svg(path, cars):
    """side and front views per vehicle, to check the shapes by eye"""
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="%d" style="background:#bbb">' % (len(cars) * 260)]
    for row, (name, c) in enumerate(cars):
        s = 1100 / max(c.L, 5) if c.L > 6 else 120
        y0 = row * 260 + 230
        out.append('<text x="10" y="%d" font-size="20">%s  %d tris</text>' % (row * 260 + 22, name,
                   c.body.tris() + c.detail.tris() + sum(m.tris() for m, _ in c.wheels.values())))
        parts = [(c.body, None), (c.detail, None)] + [(m, hub) for m, hub in c.wheels.values()]
        for m, hub in parts:
            for t in range(0, len(m.P), 3):
                P = m.P[t:t + 3]
                if m.N[t][0] < 0.3:  # side view: faces turned to +X
                    continue
                col = "rgb(%d,%d,%d)" % tuple(int(255 * min(1, x)) for x in (m.C[t] if m.C[t] != PAINT else (0.8, 0.3, 0.3)))
                d = " ".join("%.1f,%.1f" % (40 + (c.L / 2 - p[2]) * s, y0 - p[1] * s) for p in P)
                out.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="0.3"/>' % (d, col, col))
    out.append("</svg>")
    open(path, "w").write("\n".join(out))


if __name__ == "__main__":
    cars = [probox(), hiace(), carry(), ybs_bus()]
    write(sys.argv[1], cars)
    for n, c in cars:
        print(n, "tris", c.body.tris() + c.detail.tris() + sum(m.tris() for m, _ in c.wheels.values()))
    if "--svg" in sys.argv:
        svg(sys.argv[sys.argv.index("--svg") + 1], cars)
