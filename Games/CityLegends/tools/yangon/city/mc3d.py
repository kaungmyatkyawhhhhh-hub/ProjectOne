"""mc3d.py: Myanmar Centre in real 3D geometry (owner, 2026-11-14: "make myanmar plaza 3d, not with textures and decals,
make interior of myanmar plaza too"), from layout_fit.json (landmark_mc_fit.py) and the 3D letters (text3d_blend.py).

    python mc3d.py [y0] [--plane a,b,c]  -> imports/sync/landmarks/mc3d*.glb, build/landmarks/myanmar_centre/mc3d_*.json

Exterior: protruding spandrel bands, recessed glass, real mullion fins, solid crowns, the corner front (screen wall,
entrance canopy, the tilted roof canopy on V struts), the west entrance with standing 3D letters, the dome skylight, the
Melia (C and its terraced D wing), The Lake Suites (balconies), the plinth with bent 3D letters, paving, lamps.
Interior (walkable): five floors round the oval atrium under the skylight, marble floors with ceilings, glass
balustrades, bridges across the atrium on floors 1-3, four escalators zig-zagging up, shop units with glass fronts,
sign bands and partitions, the two entrances (Kabar Aye Pagoda Road and the corner plaza).
Outputs: the meshes (material groups, geom3d / landmark_glb3d), mc3d_collide.txt (YangonBuildingMeshes.collide data),
mc3d_boards.json (picture screens / ad boards, made as parts with SurfaceGui pictures in Studio), mc3d_lights.json.
"""
import json
import math
import os
import sys

from shapely.geometry import Polygon, Point, LineString, box as sbox
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geom3d import Geo, ccw, offset_poly, outward, ellipse, raster_boxes  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

ROOT = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "myanmar_centre")
LAY = json.load(open(os.path.join(ROOT, "layout_fit.json")))
LET = json.load(open(os.path.join(HERE, "..", "..", "..", "build", "landmarks", "text3d.json")))
FLOOR = 9.0
SKIRT = -4.0
POD_Z = [0.0, 14.0, 26.0, 38.0, 50.0]  # the mall floors; the roof at 62 + a 4-stud parapet
POD_H = [14.0, 12.0, 12.0, 12.0, 12.0]
POD_TOP = 66.0

g = Geo()
COLL = []
BOARDS = []
LIGHTS = []


def V(p):
    return (float(p[0]), float(p[1]))


def unit(v):
    l = math.hypot(v[0], v[1])
    return (v[0] / l, v[1] / l)


def edges_of(poly):
    for i in range(len(poly)):
        yield i, poly[i], poly[(i + 1) % len(poly)]


def coll_wall(p, q, z0, h, thick=1.6, inward=None):
    ex, ey = q[0] - p[0], q[1] - p[1]
    L = math.hypot(ex, ey)
    if L < 0.4:
        return
    cx, cy = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
    if inward:
        cx += inward[0] * thick / 2
        cy += inward[1] * thick / 2
    COLL.append((cx, cy, z0, L + thick * 0.3, thick, h, math.atan2(ey, ex)))


def coll_poly(poly, z0, h, thick=1.6, skip=None):
    poly = ccw(poly)
    for i, p, q in edges_of(poly):
        n = outward(poly, i)
        spans = skip(p, q) if skip else []
        from geom3d import _keep_spans
        for a, b in _keep_spans(spans):
            pa = (p[0] + (q[0] - p[0]) * a, p[1] + (q[1] - p[1]) * a)
            pb = (p[0] + (q[0] - p[0]) * b, p[1] + (q[1] - p[1]) * b)
            coll_wall(pa, pb, z0, h, thick, inward=(-n[0], -n[1]))


def mullions(poly, z0, z1, step, depth, width, grp, recess=0.0, edges=None):
    """Vertical fins along a polygon's walls, `recess` behind the wall line, standing out `depth` from there."""
    poly = ccw(poly)
    for i, p, q in edges_of(poly):
        if edges is not None and i not in edges:
            continue
        L = math.hypot(q[0] - p[0], q[1] - p[1])
        if L < step * 0.6:
            continue
        e = unit((q[0] - p[0], q[1] - p[1]))
        n = outward(poly, i)
        k = max(1, int(round(L / step)))
        for j in range(1, k):
            t = j / k
            cx = p[0] + (q[0] - p[0]) * t + n[0] * (-recess + depth / 2)
            cy = p[1] + (q[1] - p[1]) * t + n[1] * (-recess + depth / 2)
            g.box(grp, cx, cy, z0, width, depth, z1 - z0, math.atan2(e[1], e[0]), faces=("-y", "+x", "-x"))


# ---------------------------------------------------------------------------------------------------------------------
# outlines
POD = ccw([V(p) for p in LAY["podium"]])
FACE = unit(LAY["face"])
DOME = V(LAY["dome_c"])
ATR_RX, ATR_RY = 23.0, 26.0


def tower_A():
    P = [V(p) for p in LAY["A"]]
    P = ccw(P)
    lens = [math.dist(P[i], P[(i + 1) % 4]) for i in range(4)]
    out = []
    notch = 5.0
    Pm = list(P)
    for i in range(4):
        a, b = Pm[i], Pm[(i + 1) % 4]
        out.append(a)
        if lens[i] < 0.7 * max(lens):
            e = unit((b[0] - a[0], b[1] - a[1]))
            inn = (-e[1], e[0])
            m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            if a[0] + a[1] < b[0] + b[1]:
                out[-1] = (a[0] + inn[0] * notch, a[1] + inn[1] * notch)
                out += [(m[0] + inn[0] * notch, m[1] + inn[1] * notch), m]
            else:
                out += [m, (m[0] + inn[0] * notch, m[1] + inn[1] * notch)]
                Pm[(i + 1) % 4] = (b[0] + inn[0] * notch, b[1] + inn[1] * notch)
    return ccw(out)


def tower_B():
    P = [V(p) for p in LAY["B"]]
    a, b = P[0], P[1]
    cen = (sum(p[0] for p in P) / 4, sum(p[1] for p in P) / 4)
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    o = unit((b[1] - a[1], -(b[0] - a[0])))
    if (mid[0] - cen[0]) * o[0] + (mid[1] - cen[1]) * o[1] < 0:
        o = (-o[0], -o[1])
    arc = []
    for k in range(1, 8):
        u = k / 8
        h = 10.0 * (1 - (2 * u - 1) ** 2)
        arc.append((a[0] + (b[0] - a[0]) * u + o[0] * h, a[1] + (b[1] - a[1]) * u + o[1] * h))
    P = [P[0]] + arc + P[1:]
    P = ccw(P)
    # a 2 x 2 slot down the middle of each short end
    out = []
    n = len(P)
    lens = [math.dist(P[i], P[(i + 1) % n]) for i in range(n)]
    for i in range(n):
        a, b = P[i], P[(i + 1) % n]
        out.append(a)
        if 25 < lens[i] < 60:
            e = unit((b[0] - a[0], b[1] - a[1]))
            inn = (-e[1], e[0])
            m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            out += [(m[0] - e[0], m[1] - e[1]), (m[0] - e[0] + inn[0] * 2, m[1] - e[1] + inn[1] * 2),
                    (m[0] + e[0] + inn[0] * 2, m[1] + e[1] + inn[1] * 2), (m[0] + e[0], m[1] + e[1])]
    return ccw(out)


A = tower_A()
B = tower_B()


# ---------------------------------------------------------------------------------------------------------------------
def office_tower(poly, z0, nfl, spand, glass, mull_step, band_h=2.9, band_out=0.55, recess=0.35, crown_rows=3,
                 crown_grp="CRN", lip=None, ground=False):
    """Bands per floor in front of one continuous recessed glass skin with full-height mullion fins."""
    zs = z0
    if ground:
        # the street storey: a lobby of see-through glass set 1.5 back, dark mullions, a band on top
        inner = offset_poly(poly, -1.5)
        g.ring("DRK", poly, SKIRT, 0.0)
        g.ring("GLL", inner, 0.3, 12.5)
        mullions(inner, 0.3, 12.5, 6.0, 0.5, 0.4, "MUL")
        g.ring("DRK", inner, 0.0, 0.3)
        g.ring("DRK", inner, 12.5, 14.0)
        g.annulus("CEL", poly, inner, 14.0, down=True)
        g.cap("MAR", inner, 0.05)
        coll_poly(poly, 0.0, 30.0)
        zs = 14.0
    top_glass = zs + nfl * FLOOR
    skin = offset_poly(poly, -recess)
    g.ring(glass, skin, zs, top_glass)
    mullions(skin, zs, top_glass, mull_step, 0.45, 0.32, "MUL")
    for k in range(nfl):
        z = zs + k * FLOOR
        g.band(spand, poly, z, z + band_h, band_out)
    z = top_glass
    for r in range(crown_rows):
        g.band(crown_grp, poly, z, z + 7.0, band_out)
        g.ring("DRK", skin, z + 7.0, z + 8.0)
        z += 8.0
    top = z
    g.band(crown_grp, poly, top, top + 1.2, band_out + (lip or 0.0))
    top += 1.2
    deck = offset_poly(poly, -1.6)
    g.annulus(crown_grp, offset_poly(poly, band_out + (lip or 0.0)), deck, top)
    g.ring("CEL", deck, top - 2.0, top, inward=True)
    g.cap("ROF", deck, top - 2.0)
    # plant room and solar rows
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    e0 = unit((poly[1][0] - poly[0][0], poly[1][1] - poly[0][1]))
    yaw = math.atan2(e0[1], e0[0])
    g.box("CRN", cx, cy, top - 2.0, 14.0, 8.0, 7.0, yaw)
    for r in (-3, -2, 2, 3):
        ox, oy = -e0[1] * r * 3.2, e0[0] * r * 3.2
        g.box("SOL", cx + ox, cy + oy, top - 1.8, 30.0, 2.2, 0.5, yaw, faces=("top", "-y", "+y"))
    return top


# ---------------------------------------------------------------------------------------------------------------------
def entrance_spans():
    """The two entrances: the corner front's middle and the west front's middle (Kabar Aye Pagoda Road)."""
    out = []
    best_f, best_w = None, None
    for i, p, q in edges_of(POD):
        n = outward(POD, i)
        L = math.dist(p, q)
        if L > 10 and n[0] * FACE[0] + n[1] * FACE[1] > 0.9 and (best_f is None or L > best_f[2]):
            best_f = (p, q, L, n)
        if L > 12 and n[0] < -0.8 and (best_w is None or L > best_w[2]):
            best_w = (p, q, L, n)
    for b, w in ((best_f, 14.0), (best_w, 14.0)):
        if b:
            p, q, L, n = b
            m = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            out.append((m, n, w, unit((q[0] - p[0], q[1] - p[1])), L))
    return out


ENTR = entrance_spans()


def skip_entrances(p, q, margin=0.0):
    spans = []
    L = math.dist(p, q)
    if L < 1e-6:
        return spans
    e = unit((q[0] - p[0], q[1] - p[1]))
    for (m, n, w, _, _) in ENTR:
        # the entrance middle projected on this edge (only if close to the line)
        t = ((m[0] - p[0]) * e[0] + (m[1] - p[1]) * e[1])
        d = abs((m[0] - p[0]) * e[1] - (m[1] - p[1]) * e[0])
        if d < 4.5 and -w / 2 < t < L + w / 2:
            spans.append(((t - w / 2 - margin) / L, (t + w / 2 + margin) / L))
    return spans


def podium():
    inner = offset_poly(POD, -3.5)
    g.ring("DRK", POD, SKIRT, 0.0)
    # street storey: see-through shopfronts 3.5 back (open at the two entrances), white piers, a dark head
    g.ring("GLS", inner, 0.3, 11.5, skip=skip_entrances)
    g.ring("DRK", inner, 0.0, 0.3, skip=skip_entrances)
    g.ring("DRK", inner, 11.5, 14.0)
    mullions(inner, 0.3, 11.5, 8.0, 0.5, 0.35, "MUL")
    mullions(POD, 0.0, 14.0, 16.0, 1.2, 1.2, "GRN")
    g.annulus("CEL", POD, inner, 14.0, down=True)
    # four mall storeys: granite spandrels proud of a dark glass ribbon with white mullions
    skin = offset_poly(POD, -0.2)
    g.ring("GLP", skin, 14.0, 62.0)
    mullions(skin, 18.0, 62.0, 6.0, 0.6, 0.35, "MUW")
    for z in POD_Z[1:]:
        g.band("GRN", POD, z, z + 4.5, 0.8)
        g.ring("CEL", offset_poly(POD, -0.8), z, z + 4.5, inward=True)
    g.band("GRN", POD, 62.0, POD_TOP, 0.8, bottom=True)
    g.annulus("GRN", offset_poly(POD, 0.8), offset_poly(POD, -0.8), POD_TOP)
    g.ring("GRN", offset_poly(POD, -0.8), 62.0, POD_TOP, inward=True)
    atr = ellipse(DOME[0], DOME[1], ATR_RX, ATR_RY, 40)
    g.cap("ROF", offset_poly(POD, -0.8), 62.0, holes=[atr])
    g.cap("CEL", offset_poly(POD, -0.8), 61.9, down=True)
    # outer collision with openings at the entrances (the street storey) and full walls above
    coll_poly(POD, 0.0, 14.0, skip=lambda p, q: skip_entrances(p, q, -1.0))
    coll_poly(POD, 14.0, POD_TOP - 14.0)
    # ad boards on the long street faces (white frames, pictures as parts in Studio)
    regs = ["bill0", "bill1", "bill2"]
    k = 0
    for i, p, q in edges_of(POD):
        n = outward(POD, i)
        L = math.dist(p, q)
        if L < 40 or n[0] * FACE[0] + n[1] * FACE[1] > 0.9:
            continue
        cnt = 2 if L < 80 else 3
        for j in range(cnt):
            t = (j + 1) / (cnt + 1)
            c = (p[0] + (q[0] - p[0]) * t + n[0] * 0.9, p[1] + (q[1] - p[1]) * t + n[1] * 0.9)
            BOARDS.append({"c": c, "z0": 28.0, "w": 14.0, "h": 9.0, "n": n, "img": regs[k % 3], "frame": 0.6})
            k += 1


def dome():
    cx, cy = DOME
    rx, ry, hz = ATR_RX, ATR_RY, 9.0
    z0 = 62.0
    seg, rings = 24, 5
    outer = ellipse(cx, cy, rx + 4.5, ry + 4.5, seg)
    innr = ellipse(cx, cy, rx + 0.5, ry + 0.5, seg)
    g.ring("HDG", outer, z0, z0 + 2.5)
    g.annulus("HDG", outer, innr, z0 + 2.5)
    g.ring("MUW", innr, z0, z0 + 2.5, inward=True)
    zb = z0 + 2.5
    for j in range(rings):
        a0, a1 = j / rings * math.pi / 2, (j + 1) / rings * math.pi / 2
        for k in range(seg):
            b0, b1 = 2 * math.pi * k / seg, 2 * math.pi * (k + 1) / seg

            def P(a, b):
                return (cx + rx * math.cos(a) * math.cos(b), cy + ry * math.cos(a) * math.sin(b), zb + hz * math.sin(a))
            if j == rings - 1:
                g.tri("MEL", P(a0, b0), P(a0, b1), P(a1, b1))
            else:
                g.quad("MEL", P(a0, b0), P(a0, b1), P(a1, b1), P(a1, b0))
    for k in range(12):
        b = 2 * math.pi * k / 12
        prev = None
        for j in range(rings + 1):
            a = j / rings * math.pi / 2
            pt = (cx + rx * math.cos(a) * math.cos(b), cy + ry * math.cos(a) * math.sin(b), zb + hz * math.sin(a) + 0.15)
            if prev:
                g.tube("MUW", prev, pt, 0.35)
            prev = pt


# ---------------------------------------------------------------------------------------------------------------------
def corner_front():
    """The corner front (p3): a charcoal screen wall with the LED screen between two portrait billboards (pictures as
    parts in Studio), white frames; the entrance canopy on three columns; the tilted roof canopy on white V struts with a
    glass balustrade; ad boards on the roof at both ends."""
    m, n, w, t, L = ENTR[0]
    yaw = math.atan2(n[1], n[0])
    bw = min(72.0, L - 4.0)
    bd = 4.0
    c = (m[0] + n[0] * bd / 2, m[1] + n[1] * bd / 2)
    g.box("CHR", c[0], c[1], 28.0, bw, bd, 32.0, yaw + math.pi / 2)
    fc = (m[0] + n[0] * (bd + 0.05), m[1] + n[1] * (bd + 0.05))
    led_w = min(42.0, bw - 32.0)
    for xc, ww, img in ((0.0, led_w, "screen"), (-(led_w / 2 + 8.5), 14.0, "bill0"), (led_w / 2 + 8.5, 14.0, "bill2")):
        pc = (fc[0] + t[0] * xc, fc[1] + t[1] * xc)
        BOARDS.append({"c": pc, "z0": 33.0, "w": ww, "h": 24.0, "n": n, "img": img, "frame": 0.8})
    # a light line on top of the wall
    lc = (m[0] + n[0] * (bd + 0.06), m[1] + n[1] * (bd + 0.06))
    g.box("LIT", lc[0], lc[1], 59.0, bw, 0.12, 0.8, yaw + math.pi / 2, faces=("+y", "-y", "top"))
    # entrance canopy (ground floor) on three columns
    dep = 9.0
    pts = [(m[0] - t[0] * (w / 2 + 12), m[1] - t[1] * (w / 2 + 12)), (m[0] + t[0] * (w / 2 + 12), m[1] + t[1] * (w / 2 + 12))]
    a, b = pts
    slab = [a, b, (b[0] + n[0] * dep, b[1] + n[1] * dep), (a[0] + n[0] * dep, a[1] + n[1] * dep)]
    g.cap("MUW", slab, 14.6)
    g.cap("CEL", slab, 13.0, down=True)
    g.ring("MUW", slab, 13.0, 14.6)
    for k in range(3):
        u = (k + 0.5) / 3
        cc = (a[0] + (b[0] - a[0]) * u + n[0] * (dep - 1.2), a[1] + (b[1] - a[1]) * u + n[1] * (dep - 1.2))
        g.column("DRK", cc[0], cc[1], SKIRT, 13.0, 0.8)
        COLL.append((cc[0], cc[1], 0.0, 1.6, 1.6, 13.0, 0.0))
        LIGHTS.append({"p": (cc[0] - n[0] * 4, cc[1] - n[1] * 4, 12.2), "kind": "soffit"})
    # roof canopy: a plate tilted up toward the street (soffit glowing), white front fascia, V struts, balustrade
    top = POD_TOP
    back = (m[0] - n[0] * 4.0, m[1] - n[1] * 4.0)
    front = (m[0] + n[0] * 10.0, m[1] + n[1] * 10.0)
    hwb, hwf = 20.0, 29.0
    zb, zf, th = top + 9.0, top + 12.5, 1.6
    P = [(front[0] - t[0] * hwf, front[1] - t[1] * hwf, zf), (front[0] + t[0] * hwf, front[1] + t[1] * hwf, zf),
         (back[0] + t[0] * hwb, back[1] + t[1] * hwb, zb), (back[0] - t[0] * hwb, back[1] - t[1] * hwb, zb)]
    Pt = [(x, y, z + th) for x, y, z in P]

    def up(pts, want_up):
        a_ = (pts[1][0] - pts[0][0]) * (pts[2][1] - pts[0][1]) - (pts[1][1] - pts[0][1]) * (pts[2][0] - pts[0][0])
        return pts if (a_ > 0) == want_up else pts[::-1]
    g.poly3("CEL", up(P, False))
    g.poly3("CHR", up(Pt, True))
    cc = ((front[0] + back[0]) / 2, (front[1] + back[1]) / 2)
    for i in range(4):
        a_, b_ = P[i], P[(i + 1) % 4]
        q = [(a_[0], a_[1], a_[2]), (b_[0], b_[1], b_[2]), (b_[0], b_[1], b_[2] + th), (a_[0], a_[1], a_[2] + th)]
        e = (b_[0] - a_[0], b_[1] - a_[1])
        nn = (e[1], -e[0])
        if nn[0] * ((a_[0] + b_[0]) / 2 - cc[0]) + nn[1] * ((a_[1] + b_[1]) / 2 - cc[1]) < 0:
            q = [q[1], q[0], q[3], q[2]]
        g.poly3("MUW" if i == 0 else "CHR", q)
    for k in (-2, -1, 0, 1, 2):
        base = (m[0] + t[0] * k * 11.0 - n[0] * 1.0, m[1] + t[1] * k * 11.0 - n[1] * 1.0)
        for s in (-1, 1):
            tip = (m[0] + t[0] * (k * 11.0 + s * 2.5) + n[0] * 7.0, m[1] + t[1] * (k * 11.0 + s * 2.5) + n[1] * 7.0)
            frac = ((tip[0] - back[0]) * n[0] + (tip[1] - back[1]) * n[1]) / 14.0
            g.tube("MUW", (base[0], base[1], top), (tip[0], tip[1], zb + (zf - zb) * frac), 0.7)
    bal = (m[0] - n[0] * 0.6, m[1] - n[1] * 0.6)
    g.box("RAL", bal[0], bal[1], top, bw - 6.0, 0.2, 3.2, yaw + math.pi / 2, faces=("+y", "-y"))
    for side, img, ww, hh in ((1, "bill1", 17.0, 11.0), (-1, "screen", 18.0, 9.0)):
        bc = (m[0] + t[0] * side * (L / 2 - ww / 2 - 2.0) - n[0] * 2.0, m[1] + t[1] * side * (L / 2 - ww / 2 - 2.0) - n[1] * 2.0)
        g.box("STL", bc[0], bc[1], top, ww + 1.0, 1.0, hh + 1.0, yaw + math.pi / 2)
        BOARDS.append({"c": (bc[0] + n[0] * 0.55, bc[1] + n[1] * 0.55), "z0": top + 0.5, "w": ww, "h": hh, "n": n,
                       "img": img, "frame": 0.0})
        for kk in range(4):
            a_ = (bc[0] + t[0] * (-ww / 2 + (kk + 0.5) * ww / 4), bc[1] + t[1] * (-ww / 2 + (kk + 0.5) * ww / 4))
            g.tube("STL", (a_[0], a_[1], top + hh + 1.0), (a_[0] + n[0] * 3, a_[1] + n[1] * 3, top + hh + 2.2), 0.35)


def west_entrance():
    m, n, w, t, L = ENTR[1]
    half = min(26.0, L / 2 - 1.0)
    dep, z, th = 11.0, 13.0, 2.0
    a = (m[0] - t[0] * half, m[1] - t[1] * half)
    b = (m[0] + t[0] * half, m[1] + t[1] * half)
    slab = [a, b, (b[0] + n[0] * dep, b[1] + n[1] * dep), (a[0] + n[0] * dep, a[1] + n[1] * dep)]
    g.cap("DRK", slab, z + th)
    g.cap("CEL", slab, z, down=True)
    g.ring("DRK", slab, z, z + th)
    for k in range(2):
        u = (k + 0.5) / 2
        cc = (a[0] + (b[0] - a[0]) * u + n[0] * (dep - 1.2), a[1] + (b[1] - a[1]) * u + n[1] * (dep - 1.2))
        g.column("DRK", cc[0], cc[1], SKIRT, z, 0.8)
        COLL.append((cc[0], cc[1], 0.0, 1.6, 1.6, z, 0.0))
    for k in range(4):
        u = (k + 0.5) / 4
        LIGHTS.append({"p": (a[0] + (b[0] - a[0]) * u + n[0] * 5, a[1] + (b[1] - a[1]) * u + n[1] * 5, z - 0.6), "kind": "soffit"})
    # MYANMAR PLAZA: 3D letters standing on the canopy's front edge, facing the road
    right = (-t[0], -t[1]) if (t[1] * 1 - t[0] * 0) else t  # placeholder, fixed below
    # reading direction = the viewer's right when facing the building: rotate the outward normal by -90 degrees
    right = (n[1], -n[0])
    right = (-right[0], -right[1])
    org = (m[0] + n[0] * (dep - 0.8), m[1] + n[1] * (dep - 0.8), z + th)
    g.text("WLT", LET, "MYANMAR PLAZA", org, right, 4.2, 0.6, max_w=2 * half - 4)


# ---------------------------------------------------------------------------------------------------------------------
def plinth():
    cx, cy = V(LAY["plinth_c"])
    r = float(LAY["fit"]["plinth_r"])
    span = math.radians(float(LAY["fit"].get("plinth_span", 104)))
    face = math.atan2(FACE[1], FACE[0])
    a0 = face - span / 2
    zg, zt = 7.6, 12.4
    nb = 40
    band_k = int(round(nb * 0.88))

    def P(b, rr):
        return (cx + rr * math.cos(b), cy + rr * math.sin(b))
    for k in range(nb):
        b0, b1 = a0 + span * k / nb, a0 + span * (k + 1) / nb
        p, q = P(b0, r), P(b1, r)
        if k < band_k:
            g.wall("PGR", p, q, SKIRT, zg)
            g.wall("PBD", p, q, zg, zt)
        else:
            g.wall("PGR", p, q, SKIRT, zt)
        po, qo, pi_, qi_ = P(b0, r + 0.5), P(b1, r + 0.5), P(b0, r - 1.1), P(b1, r - 1.1)
        g.quad("MUW", (po[0], po[1], zt + 0.6), (qo[0], qo[1], zt + 0.6), (qi_[0], qi_[1], zt + 0.6), (pi_[0], pi_[1], zt + 0.6))
        g.wall("MUW", po, qo, zt, zt + 0.6)
        g.quad("MUW", (p[0], p[1], zt), (po[0], po[1], zt), (qo[0], qo[1], zt), (q[0], q[1], zt))
        g.wall("PGR", P(b1, r - 1.1), P(b0, r - 1.1), SKIRT, zt + 0.6)
        # hedge: r + 1.2 .. r + 3.2, rounded top
        A_, B_ = P(b0, r + 3.2), P(b1, r + 3.2)
        Am, Bm = P(b0, r + 2.6), P(b1, r + 2.6)
        Ai, Bi = P(b0, r + 1.8), P(b1, r + 1.8)
        Ai2, Bi2 = P(b0, r + 1.2), P(b1, r + 1.2)
        g.wall("HDG", A_, B_, 0.0, 1.4)
        g.quad("HDG", (A_[0], A_[1], 1.4), (B_[0], B_[1], 1.4), (Bm[0], Bm[1], 1.9), (Am[0], Am[1], 1.9))
        g.quad("HDG", (Am[0], Am[1], 1.9), (Bm[0], Bm[1], 1.9), (Bi[0], Bi[1], 1.9), (Ai[0], Ai[1], 1.9))
        g.quad("HDG", (Bi2[0], Bi2[1], 0.0), (Ai2[0], Ai2[1], 0.0), (Ai[0], Ai[1], 1.9), (Bi[0], Bi[1], 1.9))
        for ra, rb in ((r, r + 1.2), (r + 3.2, r + 6.0)):
            a1, b1_ = P(b0, rb), P(b1, rb)
            a2, b2 = P(b0, ra), P(b1, ra)
            g.quad("LAW", (a1[0], a1[1], 0.14), (b1_[0], b1_[1], 0.14), (b2[0], b2[1], 0.14), (a2[0], a2[1], 0.14))
        COLL.append(((p[0] + q[0]) / 2 - math.cos((b0 + b1) / 2) * 0.4, (p[1] + q[1]) / 2 - math.sin((b0 + b1) / 2) * 0.4,
                     0.0, math.dist(p, q) + 0.3, 1.0, zt + 0.6, math.atan2(q[1] - p[1], q[0] - p[0])))
    # wall ends
    for b, sgn in ((a0, -1), (a0 + span, 1)):
        o, i_ = P(b, r + 0.5), P(b, r - 1.1)
        if sgn < 0:
            g.wall("PGR", i_, o, SKIRT, zt + 0.6)
        else:
            g.wall("PGR", o, i_, SKIRT, zt + 0.6)
    # MYANMAR CENTRE in bent 3D orange letters on the band; the four names in small cream letters on the granite
    band_span = span * band_k / nb
    mid_a = a0 + band_span / 2
    g.text_arc("ORG", LET, "MYANMAR CENTRE", (cx, cy), r + 0.45, mid_a, zg + 0.45, 3.6, 0.45, width=r * band_span * 0.9)
    names = "THE LAKE SUITES  MYANMAR CENTRE TOWER  MYANMAR PLAZA  MELIA YANGON"
    g.text_arc("GLD", LET, names, (cx, cy), r + 0.15, mid_a, 4.4, 1.1, 0.15, width=r * band_span * 0.86)
    for k in range(9):
        b = a0 + span * (0.06 + 0.88 * k / 8)
        pp = P(b, r + 0.05)
        g.box("LIT", pp[0], pp[1], 0.3, 0.7, 0.2, 0.45, b + math.pi / 2, faces=("-y", "top"))
    # the raised garden bed behind the wall (inside the arc, closed by the chord)
    garden = [P(a0 + span * k / 24, r - 1.1) for k in range(25)]
    g.cap("LAW", garden, 1.2)
    g.wall("PGR", garden[-1], garden[0], SKIRT, 1.2)


def paving():
    tiles = [Polygon(t["outer"], t.get("holes") or []) for t in LAY["paving"]]
    shape = unary_union([t.buffer(0.01) for t in tiles]).buffer(-0.01)
    g.capshape("PAV", shape, 0.06)


def props():
    pc = V(LAY["plinth_c"])
    for x, y, yaw in LAY.get("lamps", []):
        dv = (x - pc[0], y - pc[1])
        l = math.hypot(*dv)
        if l > 1e-3 and (dv[0] * FACE[0] + dv[1] * FACE[1]) / l > math.cos(math.radians(65)):
            continue
        g.box("DRK", x, y, SKIRT, 0.7, 0.7, 16.0 - SKIRT, yaw)
        COLL.append((x, y, 0.0, 0.8, 0.8, 16.0, yaw))
        oct_ = [(x + 2.0 * math.cos(k * math.pi / 4), y + 2.0 * math.sin(k * math.pi / 4)) for k in range(8)]
        g.ring("DRK", oct_, 16.0, 16.8)
        g.cap("DRK", oct_, 16.8)
        g.cap("LIT", oct_, 16.0, down=True)
        LIGHTS.append({"p": (x, y, 15.6), "kind": "street"})
        sx, sy = math.cos(yaw), math.sin(yaw)
        for s in (-1, 1):
            g.tube("DRK", (x, y, 14.2), (x + sx * s * 2.4, y + sy * s * 2.4, 14.2), 0.18)
            bc = (x + sx * s * 2.0, y + sy * s * 2.0)
            g.box("RED", bc[0], bc[1], 9.0, 1.7, 0.12, 5.0, yaw + math.pi / 2 * 0 + (math.pi / 2), faces=("+y", "-y", "+x", "-x"))
    for x, y in LAY.get("bollards", []):
        g.box("MUW", x, y, 0.0, 0.5, 0.5, 2.4)
        COLL.append((x, y, 0.0, 0.5, 0.5, 2.4, 0.0))
    fc0 = V(LAY["front_c"])
    tv = (FACE[1], -FACE[0])
    for along in (-30.0, -19.0, 19.0, 30.0):
        c = (fc0[0] + tv[0] * along + FACE[0] * 11.5, fc0[1] + tv[1] * along + FACE[1] * 11.5)
        yaw = math.atan2(tv[1], tv[0])
        g.box("PGR", c[0], c[1], 0.0, 4.0, 2.0, 1.6, yaw, faces=("+x", "-x", "+y", "-y"))
        g.box("HDG", c[0], c[1], 1.6, 3.6, 1.6, 0.6, yaw)
        COLL.append((c[0], c[1], 0.0, 4.0, 2.0, 1.6, yaw))


# ---------------------------------------------------------------------------------------------------------------------
def melia():
    base = ccw([V(p) for p in LAY["melia_osm"][:-1]])
    inner = offset_poly(base, -2.5)
    g.ring("DRK", base, SKIRT, 0.0)
    g.ring("GLL", inner, 0.3, 12.0)
    mullions(inner, 0.3, 12.0, 7.0, 0.5, 0.35, "MUL")
    g.ring("MEL", inner, 12.0, 14.0)
    g.annulus("CEL", base, inner, 14.0, down=True)
    skin = offset_poly(base, -0.2)
    g.ring("GLP", skin, 14.0, 38.0)
    for z in (14.0, 26.0):
        g.band("MEL", base, z, z + 4.0, 0.6)
    g.band("MEL", base, 38.0, 41.0, 0.6)
    g.annulus("MEL", offset_poly(base, 0.6), base, 41.0)
    g.cap("ROF", base, 40.9)
    coll_poly(base, 0.0, 41.0)
    # tower C: banded long faces, solid white ends with a dark slot, the name on both long crowns
    C = ccw([V(p) for p in LAY["C"]])
    lens = [math.dist(C[i], C[(i + 1) % 4]) for i in range(4)]
    longs = [i for i in range(4) if lens[i] >= 0.7 * max(lens)]
    shorts = [i for i in range(4) if i not in longs]
    zs, nfl = 41.0, 19
    skin = offset_poly(C, -0.35)
    g.ring("GLA", skin, zs, zs + nfl * FLOOR, edges=longs)
    mullions(skin, zs, zs + nfl * FLOOR, 4.0, 0.45, 0.3, "MUW", edges=longs)
    for k in range(nfl):
        z = zs + k * FLOOR
        g.band("MEL", C, z, z + 3.4, 0.5, edges=longs)
    top = zs + nfl * FLOOR
    g.band("MEL", C, zs, top, 0.5, top=False, bottom=False, edges=shorts)
    for i in shorts:
        p, q = C[i], C[(i + 1) % 4]
        n = outward(C, i)
        m = ((p[0] + q[0]) / 2 + n[0] * 0.6, (p[1] + q[1]) / 2 + n[1] * 0.6)
        e = unit((q[0] - p[0], q[1] - p[1]))
        g.box("GLA", m[0], m[1], zs + 3.0, 2.6, 0.2, top - zs - 6.0, math.atan2(e[1], e[0]), faces=("-y",))
    z = top
    g.band("MEL", C, z, z + 16.0, 0.5)
    top = z + 16.0
    g.annulus("MEL", offset_poly(C, 0.5), offset_poly(C, -1.4), top)
    g.ring("CEL", offset_poly(C, -1.4), top - 2.0, top, inward=True)
    g.cap("ROF", offset_poly(C, -1.4), top - 2.0)
    for want in (1, -1):
        best = None
        for i in longs:
            n = outward(C, i)
            if best is None or n[0] * want > best[2][0] * want:
                best = (C[i], C[(i + 1) % 4], n)
        p, q, n = best
        mm = ((p[0] + q[0]) / 2 + n[0] * 0.55, (p[1] + q[1]) / 2 + n[1] * 0.55, top - 13.0)
        right = (-n[1], n[0])
        right = (-right[0], -right[1]) if False else (n[1] * -1 * -1, -n[0]) if False else (-n[1] * -1, n[0] * -1)
        g.text("RDL", LET, "MELIA YANGON", mm, (n[1], -n[0]) if False else (-n[1], n[0]) if False else (n[1] * 0 - n[1], n[0]), 5.0, 0.5, max_w=34)
    # D: the terraced west wing, gardens and a pool on the terraces
    D = [V(p) for p in LAY["D"]]

    def split(poly, a, b):
        p0, p1, p2, p3 = poly
        lerp = lambda u, v, t: (u[0] + (v[0] - u[0]) * t, u[1] + (v[1] - u[1]) * t)
        return [lerp(p0, p1, a), lerp(p0, p1, b), lerp(p3, p2, b), lerp(p3, p2, a)]
    for k, (a, b, nf) in enumerate([(0.0, 0.34, 3), (0.34, 0.67, 6), (0.67, 1.0, 9)]):
        piece = ccw(split(D, a, b))
        sk = offset_poly(piece, -0.3)
        g.ring("GLA", sk, 41.0, 41.0 + nf * FLOOR)
        mullions(sk, 41.0, 41.0 + nf * FLOOR, 4.5, 0.4, 0.3, "MUW")
        for f in range(nf):
            g.band("MEL", piece, 41.0 + f * FLOOR, 41.0 + f * FLOOR + 3.4, 0.5)
        z2 = 41.0 + nf * FLOOR
        g.band("MEL", piece, z2, z2 + 2.5, 0.5)
        g.annulus("MEL", offset_poly(piece, 0.5), offset_poly(piece, -0.8), z2 + 2.5)
        tp = offset_poly(piece, -0.8)
        g.ring("RAL", tp, z2 + 2.5, z2 + 4.5)
        g.cap("PAV", tp, z2 + 1.0)
        cxp = sum(p[0] for p in tp) / 4
        cyp = sum(p[1] for p in tp) / 4
        g.box("LAW", cxp - 6, cyp, z2 + 1.0, 10.0, 8.0, 0.5)
        if k == 1:
            g.box("MEL", cxp + 8, cyp, z2 + 1.0, 12.0, 7.0, 0.9)
            g.box("WAT", cxp + 8, cyp, z2 + 1.9, 11.0, 6.0, 0.05, faces=("top",))


def lake_suites():
    E = ccw([V(p) for p in LAY["E"]])
    base = offset_poly(E, 6.0)
    g.ring("DRK", base, SKIRT, 0.0)
    inner = offset_poly(base, -2.0)
    g.ring("GLL", inner, 0.3, 12.0)
    mullions(inner, 0.3, 12.0, 7.0, 0.5, 0.35, "MUL")
    g.ring("RES", inner, 12.0, 14.0)
    g.annulus("CEL", base, inner, 14.0, down=True)
    g.band("GRN", base, 14.0, 26.0, 0.4)
    g.annulus("LAW", offset_poly(base, 0.4), E, 26.0)
    coll_poly(base, 0.0, 26.0)
    zs, nfl = 26.0, 29
    skin = offset_poly(E, -0.8)
    g.ring("GLA", skin, zs, zs + nfl * FLOOR)
    mullions(skin, zs, zs + nfl * FLOOR, 5.0, 0.5, 0.5, "RES")
    for k in range(nfl):
        z = zs + k * FLOOR
        g.band("RES", E, z, z + 1.0, 1.4)       # balcony slab
        g.ring("RAL", offset_poly(E, 1.3), z + 1.0, z + 3.4)  # glass balustrade
    z = zs + nfl * FLOOR
    c1 = offset_poly(E, -3.0)
    c2 = offset_poly(E, -9.0)
    g.annulus("RES", offset_poly(E, 1.4), c1, z)
    g.band("CRN", c1, z, z + 16.0, 0.3)
    g.annulus("CRN", offset_poly(c1, 0.3), c2, z + 16.0)
    g.band("CRN", c2, z + 16.0, z + 23.0, 0.3)
    g.cap("ROF", offset_poly(c2, 0.3), z + 23.0)
    best = None
    for i in range(4):
        n = outward(c1, i)
        if best is None or n[1] > best[2][1]:
            best = (c1[i], c1[(i + 1) % 4], n)
    p, q, n = best
    mm = ((p[0] + q[0]) / 2 + n[0] * 0.35, (p[1] + q[1]) / 2 + n[1] * 0.35, z + 5.0)
    g.text("GLD", LET, "THE LAKE SUITES", mm, (-n[1] * -1 * -1, n[0]) if False else (n[1] * 0 - n[1], n[0]), 4.0, 0.4, max_w=28)


def whiteroof():
    W = ccw([V(p) for p in LAY["whiteroof"]])
    g.ring("DRK", W, SKIRT, 0.0)
    g.ring("GLL", offset_poly(W, -2.0), 0.3, 12.0)
    g.annulus("CEL", W, offset_poly(W, -2.0), 14.0, down=True)
    g.ring("GRN", W, 14.0, 66.0)
    for z in (14.0, 27.0, 40.0, 53.0):
        g.band("GRN", W, z + 9.0, z + 13.0, 0.6)
    g.band("MUW", W, 66.0, 69.0, 0.6)
    g.cap("MUW", offset_poly(W, 0.6), 69.0)


# ---------------------------------------------------------------------------------------------------------------------
# THE INTERIOR (v2, from the 2026-11-14 reference brief: Wikimedia Commons atrium photos 2018-04-06 and a 2021 shopfront)
SIGNS = []
SHOP_NAMES = [
    ["URBAN STYLE", "GOLDEN SHOES", "BEAUTY BAR", "DENIM CO", "LUXE BAGS", "WATCH HOUSE", "SPORT ZONE", "EYE CARE",
     "KIDS WORLD", "GIFT BOX", "TEA HOUSE", "PHONE PLUS"],
    ["FRESH MARKET", "BABY CLUB", "GENERATION", "PIZZA TIME", "BOOK NOOK", "HOME DECO", "TOY TOWN", "SHOE BOX",
     "FASHION HUB", "COFFEE BEAN", "CANDY LAND", "OPTIKA"],
    ["MOBILE CITY", "GADGET HUB", "TECH WORLD", "PHONE PLUS", "LAPTOP LAB", "AUDIO ZONE", "GAME SPOT", "CAMERA SHOP",
     "SMART HOME", "PRINT SHOP", "REPAIR PRO", "SIM CENTRE"],
    ["FOOD COURT", "NOODLE BAR", "BBQ HOUSE", "SUSHI GO", "TEA SHOP", "DIM SUM", "BURGER JOINT", "CURRY POT",
     "ICE CREAM", "JUICE BAR", "HOT POT", "BAKERY"],
]
OPEN_FLOORS = 4          # GF, 1F, 2F, 3F open onto the atrium; the 4th (rooftop level) is closed above it
GALLERY = 8.0            # gallery walkway between the void and the shop fronts


def interior():
    ib_poly = Polygon(offset_poly(POD, -0.8)).buffer(0)
    A_shape = Polygon(A).buffer(0.6, join_style=2)
    Bc = ccw([V(p) for p in LAY["B"]])
    bcx = sum(p[0] for p in Bc) / 4
    bcy = sum(p[1] for p in Bc) / 4
    e0 = unit((Bc[1][0] - Bc[0][0], Bc[1][1] - Bc[0][1]))
    core_poly = [(bcx + e0[0] * dx - e0[1] * dy, bcy + e0[1] * dx + e0[0] * dy) for dx, dy in ((-16, -6), (16, -6), (16, 6), (-16, 6))]
    core = Polygon(core_poly)
    IB = ib_poly.difference(A_shape).difference(core)
    if IB.geom_type != "Polygon":
        IB = max(IB.geoms, key=lambda G: G.area)
    cx, cy = DOME
    ATR = Polygon(ellipse(cx, cy, ATR_RX, ATR_RY, 40))
    # the tower B core through the mall and tower A's walls inside it (charcoal stone, as the columns)
    g.ring("CHR", ccw(core_poly), 0.0, 50.0)
    COLL.append((bcx, bcy, 0.0, 32.0, 12.0, 62.0, math.atan2(e0[1], e0[0])))
    g.ring("CHR", ccw(list(A_shape.exterior.coords)[:-1]), 0.0, 50.0)

    # the west lobby: double height (GF + 1F) behind the Kabar Aye Pagoda Road entrance
    m, n, w, t, L = ENTR[1]
    lob_c = (m[0] - n[0] * 9.0, m[1] - n[1] * 9.0)
    lobby = Polygon([(lob_c[0] + t[0] * sx * 9 + n[0] * sy * 8, lob_c[1] + t[1] * sx * 9 + n[1] * sy * 8)
                     for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]).intersection(IB)

    # floors: GF marble; slabs at 1F-3F with the void (1F also open over the lobby); the slab at the 4th level closed
    g.capshape("MAR", IB, 0.05)
    COLL.extend(raster_boxes(IB, -1.0, 0.05, 6.0))
    for k, z in enumerate(POD_Z):
        if k == 0:
            continue
        if k < OPEN_FLOORS:
            slab = IB.difference(ATR)
            if k == 1:
                slab = slab.difference(lobby)
        else:
            slab = IB
        g.capshape("MAR", slab, z)
        g.capshape("CEL", slab, z - 1.5, down=True)
        COLL.extend(raster_boxes(slab, z - 1.5, z, 4.0))
        if k >= OPEN_FLOORS:
            continue
        for G in ([slab] if slab.geom_type == "Polygon" else list(slab.geoms)):
            for h in G.interiors:
                hh = ccw(list(h.coords)[:-1])
                # a light-grey fascia 1.5 deep, a warm strip under it, frameless glass on top with steel posts and rail
                g.ring("MUW", hh, z - 1.5, z, inward=True)
                g.ring("LIT", hh, z - 1.7, z - 1.5, inward=True)
                g.ring("RAL", offset_poly(hh, 0.3), z, z + 1.9, inward=True)
                perim = 0.0
                for i in range(len(hh)):
                    p, q = hh[i], hh[(i + 1) % len(hh)]
                    g.tube("STL", (p[0], p[1], z + 2.05), (q[0], q[1], z + 2.05), 0.22)
                    seg = math.dist(p, q)
                    s = 0.0
                    while s < seg:
                        u = s / seg
                        pp = (p[0] + (q[0] - p[0]) * u, p[1] + (q[1] - p[1]) * u)
                        g.box("STL", pp[0], pp[1], z, 0.15, 0.15, 2.0, math.atan2(q[1] - p[1], q[0] - p[0]), faces=("+x", "-x", "+y", "-y"))
                        s += 2.6
                    coll_wall(p, q, z, 2.4, 0.3)
    # the void's ceiling under the closed 4th level: a beige-gold grid with big round lights, ringed by a wood cove
    zc = POD_Z[OPEN_FLOORS] - 1.5
    ring_pts = ccw(ellipse(cx, cy, ATR_RX, ATR_RY, 40))
    g.cap("GRD", ring_pts, zc - 0.05, down=True)
    for i in range(-3, 4):
        g.box("MUL", cx + i * 6.0, cy, zc - 0.35, 0.25, 2 * ATR_RY, 0.3, 0.0, faces=("bottom", "+x", "-x"))
    for j in range(-4, 5):
        g.box("MUL", cx, cy + j * 6.0, zc - 0.35, 2 * ATR_RX, 0.25, 0.3, 0.0, faces=("bottom", "+y", "-y"))
    for (dx, dy) in ((0, 0), (-10, -12), (10, -12), (-10, 12), (10, 12), (0, -20), (0, 20)):
        disc = [(cx + dx + 2.0 * math.cos(a * math.pi / 8), cy + dy + 2.0 * math.sin(a * math.pi / 8)) for a in range(16)]
        g.cap("LIT", disc, zc - 0.45, down=True)
        LIGHTS.append({"p": (cx + dx, cy + dy, zc - 1.5), "kind": "atrium"})
    g.ring("WOD", ring_pts, zc - 2.8, zc, inward=True)
    g.annulus("WOD", offset_poly(ring_pts, 0.01), offset_poly(ring_pts, -1.2), zc - 2.8, down=True) if False else None

    # escalators: a side-by-side up / down pair GF-1F, then single runs crossing the void, direction alternating
    def escalator(p_lo, p_hi, z0, z1, wdt=2.8):
        """A truss from p_lo at z0 to p_hi at z1 (plan points just outside the void, on the galleries)."""
        d = unit((p_hi[0] - p_lo[0], p_hi[1] - p_lo[1]))
        sdx, sdy = -d[1], d[0]
        run = math.dist(p_lo, p_hi)
        hw = wdt / 2
        L0, R0 = (p_lo[0] + sdx * hw, p_lo[1] + sdy * hw), (p_lo[0] - sdx * hw, p_lo[1] - sdy * hw)
        L1, R1 = (p_hi[0] + sdx * hw, p_hi[1] + sdy * hw), (p_hi[0] - sdx * hw, p_hi[1] - sdy * hw)
        top = [(R0[0], R0[1], z0 + 0.1), (L0[0], L0[1], z0 + 0.1), (L1[0], L1[1], z1 + 0.1), (R1[0], R1[1], z1 + 0.1)]
        # top faces up: order so the normal points up
        a_ = (top[1][0] - top[0][0]) * (top[2][1] - top[0][1]) - (top[1][1] - top[0][1]) * (top[2][0] - top[0][0])
        g.quad("STP", *(top if a_ > 0 else top[::-1]))
        dep = 2.2
        bot = [(x, y, zz - dep) for x, y, zz in top]
        g.quad("WOD", *(bot[::-1] if a_ > 0 else bot))
        for (pa, pb) in ((R0, R1), (L1, L0)):
            za, zb = (z0, z1) if pa in (R0, L0) else (z1, z0)
            side = [(pa[0], pa[1], za - dep), (pb[0], pb[1], zb - dep), (pb[0], pb[1], zb + 0.1), (pa[0], pa[1], za + 0.1)]
            g.quad("WOD", *side)
            g.quad("WOD", *side[::-1])
        for (pa, pb) in ((L0, L1), (R0, R1)):
            g.quad("RAL", (pa[0], pa[1], z0 + 0.1), (pb[0], pb[1], z1 + 0.1), (pb[0], pb[1], z1 + 2.3), (pa[0], pa[1], z0 + 2.3))
            g.tube("DRK", (pa[0], pa[1], z0 + 2.4), (pb[0], pb[1], z1 + 2.4), 0.28)
        g.box("STL", p_lo[0] - d[0] * 1.5, p_lo[1] - d[1] * 1.5, z0, wdt + 0.4, 3.0, 0.12, math.atan2(d[1], d[0]) + math.pi / 2)
        g.box("STL", p_hi[0] + d[0] * 1.5, p_hi[1] + d[1] * 1.5, z1, wdt + 0.4, 3.0, 0.12, math.atan2(d[1], d[0]) + math.pi / 2)
        nst = int(math.ceil(z1 - z0))
        yaw = math.atan2(d[1], d[0])
        for s in range(nst):
            u = (s + 0.5) / nst
            c = (p_lo[0] + d[0] * run * u, p_lo[1] + d[1] * run * u)
            zz = z0 + (z1 - z0) * (s + 1) / nst
            COLL.append((c[0], c[1], zz - 2.0, run / nst + 0.3, wdt, 2.0, yaw))
        for sgn in (1, -1):
            mid = ((p_lo[0] + p_hi[0]) / 2 + sdx * sgn * (hw + 0.2), (p_lo[1] + p_hi[1]) / 2 + sdy * sgn * (hw + 0.2))
            COLL.append((mid[0], mid[1], z0, run, 0.3, z1 - z0 + 3.0, yaw))

    def chord(phi, run, off=0.0, r_out=1.8):
        """Endpoints of a chord of the void (pushed r_out outside the ellipse at each end) centred at angle phi."""
        best = None
        for k in range(1, 400):
            dlt = k * 0.0025
            pa = (cx + (ATR_RX + r_out) * math.cos(phi - dlt), cy + (ATR_RY + r_out) * math.sin(phi - dlt))
            pb = (cx + (ATR_RX + r_out) * math.cos(phi + dlt), cy + (ATR_RY + r_out) * math.sin(phi + dlt))
            if math.dist(pa, pb) >= run:
                best = (pa, pb)
                break
        pa, pb = best
        nrm = unit(((pa[0] + pb[0]) / 2 - cx, (pa[1] + pb[1]) / 2 - cy))
        return ((pa[0] - nrm[0] * off, pa[1] - nrm[1] * off), (pb[0] - nrm[0] * off, pb[1] - nrm[1] * off))
    rise1, rise = POD_Z[1] - POD_Z[0], POD_Z[2] - POD_Z[1]
    run1, run2 = rise1 * 1.73, rise * 1.73
    # GF-1F pair at the void's south end (up and down, side by side)
    for off in (2.0, 5.4):
        pa, pb = chord(-math.pi / 2, run1, off=off)
        escalator(pa, pb, POD_Z[0], POD_Z[1])
    # 1F-2F at the north end (the other way), 2F-3F back at the south end
    pa, pb = chord(math.pi / 2, run2)
    escalator(pb, pa, POD_Z[1], POD_Z[2])
    pa, pb = chord(-math.pi / 2, run2, off=-0.5)
    escalator(pb, pa, POD_Z[2], POD_Z[3])

    # shops round the galleries on GF-3F: glass fronts (door in the middle), white fascia with a warm strip and a sign,
    # charcoal square columns, partitions to the outer wall, a caramel floor border, downlights in the gallery ceiling
    usable = IB.buffer(-1.0)
    n_units = 12
    entr_dirs = [math.atan2(m_[1] - cy, m_[0] - cx) for (m_, n_, w_, t_, L_) in ENTR]
    unit_ang = 2 * math.pi / n_units
    shops = []
    RX, RY = ATR_RX + GALLERY, ATR_RY + GALLERY
    for k in range(OPEN_FLOORS):
        z, h = POD_Z[k], POD_H[k]
        top_z = z + h - 1.5
        for u in range(n_units):
            a0_, a1_ = u * unit_ang, (u + 1) * unit_ang
            am = (a0_ + a1_) / 2
            corridor = k == 0 and any(abs(math.atan2(math.sin(am - ed), math.cos(am - ed))) < unit_ang * 0.6 for ed in entr_dirs)
            pts = [(cx + RX * math.cos(a0_ + (a1_ - a0_) * s / 4), cy + RY * math.sin(a0_ + (a1_ - a0_) * s / 4)) for s in range(5)]
            if not all(usable.contains(Point(p)) for p in pts):
                continue
            far = [(cx + 400 * math.cos(a0_), cy + 400 * math.sin(a0_)), (cx + 400 * math.cos(a1_), cy + 400 * math.sin(a1_))]
            area = Polygon(pts + [far[1], far[0]]).buffer(0).intersection(IB)
            if area.is_empty or area.area < 60:
                continue
            for s in range(4):
                p, q = pts[s], pts[s + 1]
                g.quad("CAR", (p[0], p[1], z + 0.07), (q[0], q[1], z + 0.07),
                       (cx + (RX - 0.8) * (q[0] - cx) / RX, cy + (RY - 0.8) * (q[1] - cy) / RY, z + 0.07),
                       (cx + (RX - 0.8) * (p[0] - cx) / RX, cy + (RY - 0.8) * (p[1] - cy) / RY, z + 0.07))
                pc = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
                pi_ = (cx + (RX - GALLERY / 2) * (pc[0] - cx) / RX, cy + (RY - GALLERY / 2) * (pc[1] - cy) / RY)
                disc = [(pi_[0] + 0.7 * math.cos(a * math.pi / 4), pi_[1] + 0.7 * math.sin(a * math.pi / 4)) for a in range(8)]
                g.cap("LIT", disc, z + h - 1.55, down=True)
            if corridor:
                continue  # the entrance corridors on the ground floor: open
            shops.append((k, u))
            for s in range(4):
                p, q = pts[s], pts[s + 1]
                segs = [(p, q)]
                if s == 1:
                    e = unit((q[0] - p[0], q[1] - p[1]))
                    segs = [(p, (q[0] - e[0] * 2.4, q[1] - e[1] * 2.4))]
                if s == 2:
                    e = unit((q[0] - p[0], q[1] - p[1]))
                    segs = [((p[0] + e[0] * 2.4, p[1] + e[1] * 2.4), q)]
                for (pa, pb) in segs:
                    g.wall("GLS", pa, pb, z + 0.1, top_z - 2.0, inward=True)
                    coll_wall(pa, pb, z, top_z - 2.0 - z, 0.4)
                g.wall("MUW", p, q, top_z - 2.0, top_z, inward=True)
                g.wall("LIT", p, q, top_z, top_z + 0.25, inward=True)
            for s in (0, 4):
                p = pts[s]
                g.box("CHR", p[0], p[1], z, 1.6, 1.6, h - 1.5, math.atan2(p[1] - cy, p[0] - cx))
                COLL.append((p[0], p[1], z, 1.6, 1.6, h - 1.5, math.atan2(p[1] - cy, p[0] - cx)))
            # the sign on the fascia (a SurfaceGui text in Studio), facing the gallery
            sp = pts[2]
            nrm = unit((cx - sp[0], cy - sp[1]))
            SIGNS.append({"c": (sp[0] + nrm[0] * 0.08, sp[1] + nrm[1] * 0.08), "z0": top_z - 1.7, "w": 9.0, "h": 1.4,
                          "n": nrm, "text": SHOP_NAMES[k][u % 12], "floor": k})
            for a_, pp in ((a0_, pts[0]), (a1_, pts[4])):
                ray = LineString([pp, (cx + 400 * math.cos(a_), cy + 400 * math.sin(a_))])
                hit = ray.intersection(IB)
                seg = None
                if hit.geom_type == "LineString" and not hit.is_empty:
                    seg = list(hit.coords)
                elif hasattr(hit, "geoms"):
                    parts = [G for G in hit.geoms if G.geom_type == "LineString"]
                    if parts:
                        seg = list(min(parts, key=lambda G: G.distance(Point(pp))).coords)
                if seg and len(seg) >= 2:
                    s0, s1 = seg[0], seg[-1]
                    g.wall("CEL", s0, s1, z + 0.05, top_z)
                    g.wall("CEL", s1, s0, z + 0.05, top_z)
                    coll_wall(s0, s1, z, top_z - z, 0.4)
            cpt = area.representative_point()
            grp = "SH1" if (u + k) % 2 == 0 else "SH2"
            g.box(grp, cpt.x, cpt.y, z + 0.05, 6.0, 1.5, 5.0, am + math.pi / 2)
            g.box(grp, cpt.x + 4 * math.cos(am), cpt.y + 4 * math.sin(am), z + 0.05, 7.0, 1.5, 6.0, am + math.pi / 2)
            g.box("LIT", cpt.x, cpt.y, top_z - 0.15, 6.0, 4.0, 0.1, am, faces=("bottom",))
            LIGHTS.append({"p": (cpt.x, cpt.y, top_z - 1.0), "kind": "shop"})
    # the west lobby: dark granite columns, a three-ring light over a round planter
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        p = (lob_c[0] + t[0] * sx * 7 + n[0] * sy * 6, lob_c[1] + t[1] * sx * 7 + n[1] * sy * 6)
        if IB.contains(Point(p)):
            g.box("DRK", p[0], p[1], 0.0, 1.6, 1.6, 26.0, math.atan2(t[1], t[0]))
            COLL.append((p[0], p[1], 0.0, 1.6, 1.6, 26.0, math.atan2(t[1], t[0])))
    for r, zz in ((3.2, 19.0), (2.4, 18.0), (1.6, 17.0)):
        pts = [(lob_c[0] + r * math.cos(a * math.pi / 8), lob_c[1] + r * math.sin(a * math.pi / 8), zz) for a in range(17)]
        for i in range(16):
            g.tube("LIT", pts[i], pts[i + 1], 0.25)
        g.tube("STL", (lob_c[0], lob_c[1], zz), (lob_c[0], lob_c[1], 25.0), 0.06)
    pl = [(lob_c[0] + 2.2 * math.cos(a * math.pi / 6), lob_c[1] + 2.2 * math.sin(a * math.pi / 6)) for a in range(12)]
    g.ring("PGR", pl, 0.0, 1.4)
    g.cap("HDG", pl, 1.4)
    COLL.append((lob_c[0], lob_c[1], 0.0, 4.4, 4.4, 1.4, 0.0))
    LIGHTS.append({"p": (lob_c[0], lob_c[1], 16.0), "kind": "lobby"})
    for k in range(OPEN_FLOORS):
        z = POD_Z[k]
        for j in range(6):
            a = 2 * math.pi * j / 6
            LIGHTS.append({"p": (cx + (ATR_RX + 4) * math.cos(a), cy + (ATR_RY + 4) * math.sin(a), z + POD_H[k] - 2.5),
                           "kind": "mall"})
    return len(shops)


# ---------------------------------------------------------------------------------------------------------------------
def build():
    paving()
    podium()
    dome()
    corner_front()
    west_entrance()
    whiteroof()
    tA = office_tower(A, 0.0, 26, "SPA", "GLA", 4.8, ground=True, crown_grp="CRN", lip=0.5)
    tB = office_tower(B, POD_TOP - 1.0, 20, "SPB", "GLB", 3.2, band_h=2.2, crown_grp="SPB", lip=1.0)
    melia()
    lake_suites()
    plinth()
    props()
    nshops = interior()
    return tA, tB, nshops


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    plane = None
    for i, a in enumerate(sys.argv):
        if a == "--plane":
            plane = [float(v) for v in sys.argv[i + 1].split(",")]
            args = [x for x in args if x != sys.argv[i + 1]]
    y0 = float(args[0]) if args else 28.8
    tA, tB, nshops = build()
    cnt = g.count()
    print("tower tops", tA, tB, "shops", nshops, "tris", sum(cnt.values()))
    print(sorted(cnt.items(), key=lambda kv: -kv[1]))
    out = os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "mc3d.glb")
    files = LG.export(g, y0, out, plane=plane, ground_groups=("PAV", "LAW", "HDG", "PGR", "PBD", "ORG", "GLD"), tag="mc")
    for f in files:
        print(f)
    open(os.path.join(ROOT, "mc3d_collide.txt"), "w").write(LG.collide_text(COLL, y0, plane) + chr(10))
    json.dump({"boards": BOARDS, "y0": y0, "plane": plane}, open(os.path.join(ROOT, "mc3d_boards.json"), "w"))
    json.dump(LIGHTS, open(os.path.join(ROOT, "mc3d_lights.json"), "w"))
    json.dump(SIGNS, open(os.path.join(ROOT, "mc3d_signs.json"), "w"))
    print("collide boxes", len(COLL), "boards", len(BOARDS), "lights", len(LIGHTS), "signs", len(SIGNS))
    # the model-coords triangles for the Blender preview
    json.dump({k: v for k, v in g.g.items()}, open(os.path.join(ROOT, "mc3d_tris.json"), "w"))
