"""sedona3d.py: the Sedona Hotel Yangon in real 3D geometry (owner, 2026-11-14: "... and also sedona").

    python sedona3d.py <y0> [--plane a,b,c]  -> imports/sync/landmarks/sd3d*.glb, build/landmarks/refs/sedona/sd3d_*.json

Sources (build/landmarks/refs/sedona/, gathered 2026-11-14): OpenStreetMap outlines (Garden Wing 374512164, Inya Wing
452876267, pools, tennis, the entrance loop), Esri z19 satellite, photos (kabaaye_garden_inya_2020.jpg, mp_5111.jpg),
facts: Garden Wing 1996, ~11-12 floors, white rendered walls with green-tinted ribbon windows and sill ledges, dark hip
roofs with deep eaves, a central pavilion two floors taller with a curved bow window and a Burmese tiered spire; Inya
Wing 2016, 29 storeys (~104 m), three interlocking cream slabs (staggered blue windows in portal-fin frames with a
pergola crown; a narrow tallest slab with a full-height dark glass strip; a finned grid slab, lower); a 3-storey
connector carrying the pool deck; two tennis courts; a one-way entrance loop round an oval garden; a white fence on
Kaba Aye Pagoda Road; the name as plain text on a blue sign board.
Model coords as mc3d (x = world X - 32600, y = -(world Z + 1350)); heights 12 + 9 a floor.
"""
import json
import math
import os
import sys

from shapely.geometry import Polygon, Point, LineString, MultiPoint, box as sbox
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geom3d import Geo, ccw, offset_poly, outward, ellipse  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

REF = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "refs", "sedona")
OSM = json.load(open(os.path.join(REF, "sedona_model.json")))
LOT = Polygon(json.load(open(os.path.join(REF, "lot_fine.json")))).buffer(0)
LET = json.load(open(os.path.join(HERE, "..", "..", "..", "build", "landmarks", "text3d.json")))
FLOOR = 9.0
SKIRT = -4.0
g = Geo()
COLL = []
LIGHTS = []


def unit(v):
    l = math.hypot(v[0], v[1])
    return (v[0] / l, v[1] / l)


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def coll_poly(poly, z0, h, thick=1.6):
    poly = ccw(poly)
    for i in range(len(poly)):
        p, q = poly[i], poly[(i + 1) % len(poly)]
        n = outward(poly, i)
        L = math.dist(p, q)
        if L < 0.4:
            continue
        cx, cy = (p[0] + q[0]) / 2 - n[0] * thick / 2, (p[1] + q[1]) / 2 - n[1] * thick / 2
        COLL.append((cx, cy, z0, L + thick * 0.3, thick, h, math.atan2(q[1] - p[1], q[0] - p[0])))


def fins(poly, z0, z1, step, depth, width, grp, recess=0.0, edges=None):
    poly = ccw(poly)
    for i in range(len(poly)):
        if edges is not None and i not in edges:
            continue
        p, q = poly[i], poly[(i + 1) % len(poly)]
        L = math.dist(p, q)
        if L < step * 0.6:
            continue
        e = unit((q[0] - p[0], q[1] - p[1]))
        n = outward(poly, i)
        k = max(1, int(round(L / step)))
        for j in range(1, k):
            c = lerp(p, q, j / k)
            g.box(grp, c[0] + n[0] * (-recess + depth / 2), c[1] + n[1] * (-recess + depth / 2), z0, width, depth, z1 - z0,
                  math.atan2(e[1], e[0]), faces=("-y", "+x", "-x"))


def mrr(shape):
    """The minimum rotated rectangle of a shape as 4 CCW points."""
    r = shape.minimum_rotated_rectangle
    return ccw(list(r.exterior.coords)[:-1])


def hip_roof(rect, z, pitch, overhang, roof_grp="TER", fascia_grp="EAV", peak=None):
    """A hip roof on a rectangle (4 CCW points) with eaves `overhang` out, slope rise/run = pitch."""
    R = offset_poly(rect, overhang)
    L01, L12 = math.dist(R[0], R[1]), math.dist(R[1], R[2])
    if L01 < L12:
        R = R[1:] + R[:1]
        L01, L12 = L12, L01
    a, b = L01 / 2, L12 / 2  # half length (along 0->1), half width
    c = ((R[0][0] + R[2][0]) / 2, (R[0][1] + R[2][1]) / 2)
    ex = unit((R[1][0] - R[0][0], R[1][1] - R[0][1]))
    h = b * pitch if peak is None else peak
    r0 = (c[0] - ex[0] * (a - b), c[1] - ex[1] * (a - b), z + h)
    r1 = (c[0] + ex[0] * (a - b), c[1] + ex[1] * (a - b), z + h)
    P = [(p[0], p[1], z) for p in R]
    # faces: side 0-1 (with ridge r1-r0), end 1-2 (apex r1), side 2-3 (r0-r1), end 3-0 (apex r0); CCW from outside
    g.quad(roof_grp, P[0], P[1], r1, r0)
    g.tri(roof_grp, P[1], P[2], r1)
    g.quad(roof_grp, P[2], P[3], r0, r1)
    g.tri(roof_grp, P[3], P[0], r0)
    g.ring(fascia_grp, R, z - 0.9, z)
    g.cap(fascia_grp, R, z - 0.9, down=True)
    return z + h, r0, r1


def ribbon_wing(poly, z0, nfl, ground=True):
    """Garden Wing facade: white walls with a recessed green-glass window band per floor, white piers, a sill ledge."""
    poly = ccw(poly)
    zs = z0
    if ground:
        inner = offset_poly(poly, -1.5)
        g.ring("DRK", poly, SKIRT, 0.0)
        g.ring("GLL", inner, 0.3, 11.0)
        fins(inner, 0.3, 11.0, 6.0, 0.5, 0.4, "MUL")
        g.ring("SED", inner, 11.0, 12.0)
        g.annulus("CEL", poly, inner, 12.0, down=True)
        g.band("SED", poly, 11.0, 12.0, 0.3)
        zs = 12.0
    top = zs + nfl * FLOOR
    skin = offset_poly(poly, -0.5)
    g.ring("SEW", skin, zs, top)
    fins(skin, zs, top, 5.5, 0.5, 1.6, "SED")
    for k in range(nfl):
        z = zs + k * FLOOR
        g.band("SED", poly, z, z + 3.4, 0.05)
        g.band("SED", poly, z + 3.2, z + 3.7, 0.7)
    g.band("SED", poly, top, top + 1.5, 0.05)
    coll_poly(poly, 0.0, top)
    return top + 1.5


def build():
    gw = Polygon(OSM["374512164"]["m"]).buffer(0)
    # the Garden Wing's three arms, the elbow (pavilion) and the low north block, cut from the one OSM outline
    S = gw.intersection(sbox(-200, 100, 200, 326))
    E = gw.intersection(sbox(36, 326, 200, 420))
    J = gw.intersection(sbox(-200, 326, 36, 392))
    N = gw.intersection(sbox(-200, 392, 10.5, 600))
    NB = gw.intersection(sbox(10.5, 392, 200, 600))
    tops = {}
    for name, part, nfl in (("S", S, 10), ("E", E, 10), ("N", N, 10), ("NB", NB, 3)):
        for G in ([part] if part.geom_type == "Polygon" else list(part.geoms)):
            if G.area < 30:
                continue
            pts = list(G.simplify(0.3).exterior.coords)[:-1]
            top = ribbon_wing(pts, 0.0, nfl)
            if name == "NB":
                g.annulus("SED", offset_poly(pts, 0.05), offset_poly(pts, -1.0), top)
                g.cap("ROF", offset_poly(pts, -1.0), top - 1.0)
                hip_roof(mrr(G.buffer(-6)), top - 1.0, 0.35, 0.0)
            else:
                g.cap("ROF", pts, top)
                hip_roof(mrr(G), top, 0.42, 2.6)
            tops[name] = top
    # the central pavilion: two floors taller, a curved glass bow window on its west face, a steep hip roof, a spire
    Jp = list(J.simplify(0.3).exterior.coords)[:-1]
    topJ = ribbon_wing(Jp, 0.0, 12)
    g.cap("ROF", Jp, topJ)
    rect = mrr(J)
    zr, r0, r1 = hip_roof(rect, topJ, 0.8, 3.2)
    cxj, cyj = J.centroid.x, J.centroid.y
    # the bow window: a half drum of glass on the west face, the two top floors
    wx = min(p[0] for p in Jp)
    bow_c = (wx, cyj)
    arc = [(bow_c[0] + 7.0 * math.cos(a), bow_c[1] + 7.0 * math.sin(a)) for a in [math.pi / 2 + k * math.pi / 8 for k in range(9)]]
    for i in range(8):
        g.wall("GLL", arc[i], arc[i + 1], topJ - 18.0, topJ - 1.0)
        g.tube("MUW", (arc[i][0], arc[i][1], topJ - 18.0), (arc[i][0], arc[i][1], topJ - 1.0), 0.3)
    g.cap("SED", arc + [arc[0]][:0], topJ - 1.0)
    g.cap("SED", arc, topJ - 18.0, down=True)
    # the Burmese tiered spire (pyatthat): two stacked tiers and a gold finial on the ridge's middle
    mid = ((r0[0] + r1[0]) / 2, (r0[1] + r1[1]) / 2)
    z = zr
    for side, h in ((10.0, 3.0), (6.5, 2.6)):
        sq = [(mid[0] + side / 2 * sx, mid[1] + side / 2 * sy) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        g.ring("SED", offset_poly(sq, -1.5), z - 1.0, z + 2.0)
        hip_roof(offset_poly(sq, -1.5), z + 2.0, 0.9, 1.5, peak=h)
        z += 2.0 + h * 0.6
    g.tube("GLD", (mid[0], mid[1], z), (mid[0], mid[1], z + 7.0), 0.5)
    g.tube("GLD", (mid[0], mid[1], z + 1.0), (mid[0], mid[1], z + 3.0), 1.2)

    # ---- the Inya Wing: three interlocking slabs along its long axis ----
    P0, P1, P2, P3 = [tuple(p) for p in OSM["452876267"]["m"][:4]]

    def slab(a, b, grow=0.0):
        s = [lerp(P0, P1, a), lerp(P0, P1, b), lerp(P3, P2, b), lerp(P3, P2, a)]
        return ccw(offset_poly(ccw(s), grow)) if grow else ccw(s)
    # SW: the finned grid slab (lower), the middle: the tallest narrow cream slab with a dark glass strip, NE: checker
    sw, md, ne = slab(0.0, 0.4, -0.8), slab(0.4, 0.6, 1.6), slab(0.6, 1.0, 0.0)
    for poly in (sw, md, ne):
        inner = offset_poly(poly, -1.5)
        g.ring("DRK", poly, SKIRT, 0.0)
        g.ring("GLL", inner, 0.3, 12.0)
        fins(inner, 0.3, 12.0, 6.0, 0.5, 0.4, "MUL")
        g.annulus("CEL", poly, inner, 12.0, down=True)
        coll_poly(poly, 0.0, 40.0)
    # finned grid slab, 25 floors
    top_sw = 12.0 + 24 * FLOOR
    sk = offset_poly(sw, -0.4)
    g.ring("SEW", sk, 12.0, top_sw)
    fins(sk, 12.0, top_sw, 2.4, 0.9, 0.5, "CRM")
    for k in range(24):
        g.band("CRM", sw, 12.0 + k * FLOOR, 12.0 + k * FLOOR + 0.8, 0.5)
    g.band("CRM", sw, top_sw, top_sw + 6.0, 0.5)
    g.annulus("CRM", offset_poly(sw, 0.5), offset_poly(sw, -1.0), top_sw + 6.0)
    g.cap("ROF", offset_poly(sw, -1.0), top_sw + 5.0)
    # middle slab, 29 floors + 1: cream, a full-height recessed dark glass strip on both long faces
    top_md = 12.0 + 29 * FLOOR
    g.ring("CRM", md, 12.0, top_md)
    for i in range(4):
        p, q = md[i], md[(i + 1) % 4]
        L = math.dist(p, q)
        n = outward(md, i)
        e = unit((q[0] - p[0], q[1] - p[1]))
        m = lerp(p, q, 0.5)
        yaw = math.atan2(e[1], e[0])
        if L > 30:
            g.box("GLA", m[0] + n[0] * 0.02, m[1] + n[1] * 0.02, 14.0, 7.0, 0.1, top_md - 18.0, yaw, faces=("-y",))
            g.box("CRM", m[0] - e[0] * 4.0 + n[0] * 0.4, m[1] - e[1] * 4.0 + n[1] * 0.4, 12.0, 1.0, 0.8, top_md - 12.0, yaw, faces=("-y", "+x", "-x"))
            g.box("CRM", m[0] + e[0] * 4.0 + n[0] * 0.4, m[1] + e[1] * 4.0 + n[1] * 0.4, 12.0, 1.0, 0.8, top_md - 12.0, yaw, faces=("-y", "+x", "-x"))
        else:
            for k in (-1, 1):
                c = lerp(p, q, 0.5 + k * 0.25)
                g.box("GLA", c[0] + n[0] * 0.02, c[1] + n[1] * 0.02, 14.0, 1.2, 0.1, top_md - 18.0, yaw, faces=("-y",))
    g.band("CRM", md, top_md, top_md + 8.0, 0.4)
    g.annulus("CRM", offset_poly(md, 0.4), offset_poly(md, -1.0), top_md + 8.0)
    g.cap("ROF", offset_poly(md, -1.0), top_md + 7.0)
    # checker slab, 28 floors: staggered blue windows in cream portal-fin frames; a pergola crown
    top_ne = 12.0 + 27 * FLOOR
    g.ring("CRM", ne, 12.0, top_ne)
    for i in range(4):
        p, q = ne[i], ne[(i + 1) % 4]
        L = math.dist(p, q)
        n = outward(ne, i)
        e = unit((q[0] - p[0], q[1] - p[1]))
        yaw = math.atan2(e[1], e[0])
        nb = max(1, int(L // 6.5))
        for f in range(27):
            z = 12.0 + f * FLOOR + 1.6
            for j in range(nb):
                t = (j + 0.5) / nb + (0.06 if (f + j) % 2 else -0.06)
                c = lerp(p, q, t)
                g.box("GLU", c[0] + n[0] * 0.03, c[1] + n[1] * 0.03, z, 3.2, 0.06, 5.6, yaw, faces=("-y",))
                g.box("CRM", c[0] + n[0] * 0.45, c[1] + n[1] * 0.45, z + 5.6, 4.4, 0.9, 0.7, yaw, faces=("-y", "bottom", "+x", "-x"))
                for s in (-1, 1):
                    fc = (c[0] + e[0] * s * 1.9 + n[0] * 0.45, c[1] + e[1] * s * 1.9 + n[1] * 0.45)
                    g.box("CRM", fc[0], fc[1], z, 0.5, 0.9, 5.6, yaw, faces=("-y", "+x", "-x"))
    g.band("CRM", ne, top_ne, top_ne + 2.0, 0.4)
    g.annulus("CRM", offset_poly(ne, 0.4), offset_poly(ne, -1.0), top_ne + 2.0)
    g.cap("ROF", offset_poly(ne, -1.0), top_ne + 1.0)
    # the pergola: posts round the roof edge, long beams and cross beams 12 above
    inner = offset_poly(ne, -1.5)
    zt = top_ne + 2.0
    for i in range(4):
        p, q = inner[i], inner[(i + 1) % 4]
        L = math.dist(p, q)
        k = max(1, int(L // 8))
        for j in range(k + 1):
            c = lerp(p, q, j / k)
            g.box("CRM", c[0], c[1], zt, 1.0, 1.0, 12.0, 0.0)
    e0 = unit((inner[1][0] - inner[0][0], inner[1][1] - inner[0][1]))
    yaw0 = math.atan2(e0[1], e0[0])
    for t in [k / 6 for k in range(7)]:
        a_, b_ = lerp(inner[0], inner[3], t), lerp(inner[1], inner[2], t)
        g.tube("CRM", (a_[0], a_[1], zt + 12.0), (b_[0], b_[1], zt + 12.0), 1.0)
    for t in [k / 4 for k in range(5)]:
        a_, b_ = lerp(inner[0], inner[1], t), lerp(inner[3], inner[2], t)
        g.tube("CRM", (a_[0], a_[1], zt + 12.6), (b_[0], b_[1], zt + 12.6), 0.8)
    # SEDONA in white letters on the crown frame: on the short end facing Industrial Road / Myanmar Plaza and on the
    # long north-west face over the pool (lit at night in the real one)
    for i in range(4):
        p, q = ne[i], ne[(i + 1) % 4]
        n = outward(ne, i)
        L = math.dist(p, q)
        if (L < 30 and n[1] < 0) or (L > 30 and n[0] < 0):
            m = lerp(p, q, 0.5)
            g.text("WLT", LET, "SEDONA", (m[0] + n[0] * 0.6, m[1] + n[1] * 0.6, zt + 3.0), (-n[1], n[0]), 6.0, 0.5, max_w=min(L - 4, 34))

    # ---- the connector podium with the pool deck on top (3 storeys) ----
    tower = Polygon([P0, P1, P2, P3]).buffer(1.8, join_style=2)
    hull = MultiPoint([(35.3, 325.7), (30.8, 284.8), (94.2, 236.0), (112, 222), (158, 272), (196, 300), (199, 322), (138, 329)]).convex_hull
    deck = hull.difference(gw.buffer(0.5, join_style=2)).difference(tower)
    deck = max([deck] if deck.geom_type == "Polygon" else list(deck.geoms), key=lambda G: G.area)
    dp = list(deck.simplify(0.4).exterior.coords)[:-1]
    zd = 12.0 + 2 * FLOOR
    g.ring("DRK", dp, SKIRT, 0.0)
    inner = offset_poly(dp, -1.5)
    g.ring("GLL", inner, 0.3, 11.0)
    g.annulus("CEL", dp, inner, 12.0, down=True)
    g.ring("SED", inner, 11.0, 12.0)
    g.ring("SEW", offset_poly(dp, -0.4), 12.0, zd)
    for k in range(2):
        g.band("SED", dp, 12.0 + k * FLOOR, 12.0 + k * FLOOR + 3.4, 0.05)
    g.band("SED", dp, zd, zd + 1.2, 0.3)
    coll_poly(dp, 0.0, zd + 1.2)
    pool = Polygon(OSM["244944721"]["m"]).buffer(0)
    jac = Polygon(OSM["445805081"]["m"]).buffer(0)
    deck_top = deck.buffer(-0.3)
    holes = [G for G in (pool, jac) if deck_top.contains(G.centroid)]
    g.capshape("PAV", deck_top.difference(unary_union(holes)) if holes else deck_top, zd + 1.2)
    for G in holes:
        pts = list(G.simplify(0.3).exterior.coords)[:-1]
        g.ring("POL", pts, zd - 1.5, zd + 1.2, inward=True)
        g.cap("POL", pts, zd - 1.5)
        g.cap("WAT", pts, zd + 0.7)
    rail = offset_poly(list(deck_top.exterior.coords)[:-1], -0.2)
    g.ring("RAL", rail, zd + 1.2, zd + 3.6)
    g.ring("RAL", rail, zd + 1.2, zd + 3.6, inward=True)
    # loungers along the pool
    pc = pool.centroid
    for k in range(8):
        a = 2 * math.pi * k / 8
        lp = (pc.x + 30 * math.cos(a), pc.y + 26 * math.sin(a))
        if deck_top.contains(Point(lp)) and not pool.buffer(2).contains(Point(lp)):
            g.box("WOD", lp[0], lp[1], zd + 1.2, 1.4, 3.6, 0.8, a)

    # ---- tennis courts: a red-brown surround, two green courts with white lines, a dark fence ----
    tn = Polygon(OSM["631392085"]["m"]).buffer(0)
    T = mrr(tn)
    g.cap("TEN", T, 0.08)
    e1 = unit((T[1][0] - T[0][0], T[1][1] - T[0][1]))
    e2 = unit((T[3][0] - T[0][0], T[3][1] - T[0][1]))
    L1, L2 = math.dist(T[0], T[1]), math.dist(T[0], T[3])
    for k in (0, 1):
        # two courts side by side across the short-ish axis
        a0, a1 = 0.06 + k * 0.49, 0.45 + k * 0.49
        c = [(T[0][0] + e1[0] * L1 * a0 + e2[0] * L2 * 0.08, T[0][1] + e1[1] * L1 * a0 + e2[1] * L2 * 0.08),
             (T[0][0] + e1[0] * L1 * a1 + e2[0] * L2 * 0.08, T[0][1] + e1[1] * L1 * a1 + e2[1] * L2 * 0.08),
             (T[0][0] + e1[0] * L1 * a1 + e2[0] * L2 * 0.92, T[0][1] + e1[1] * L1 * a1 + e2[1] * L2 * 0.92),
             (T[0][0] + e1[0] * L1 * a0 + e2[0] * L2 * 0.92, T[0][1] + e1[1] * L1 * a0 + e2[1] * L2 * 0.92)]
        g.cap("CRT", ccw(c), 0.12)
        cc = ccw(c)
        for i in range(4):
            p, q = cc[i], cc[(i + 1) % 4]
            e = unit((q[0] - p[0], q[1] - p[1]))
            m = lerp(p, q, 0.5)
            g.box("MUW", m[0], m[1], 0.13, math.dist(p, q), 0.25, 0.02, math.atan2(e[1], e[0]), faces=("top",))
        nm = (lerp(cc[0], cc[3], 0.5), lerp(cc[1], cc[2], 0.5))
        e = unit((nm[1][0] - nm[0][0], nm[1][1] - nm[0][1]))
        m = lerp(nm[0], nm[1], 0.5)
        g.box("DRK", m[0], m[1], 0.12, math.dist(*nm) + 2, 0.12, 1.6, math.atan2(e[1], e[0]))
    g.ring("FEN", T, 0.0, 5.0)
    g.ring("FEN", T, 0.0, 5.0, inward=True)
    coll_poly(T, 0.0, 5.0, thick=0.4)
    # the small building north of the courts
    sb = Polygon(OSM["452634562"]["m"]).buffer(0)
    sbp = list(sb.exterior.coords)[:-1]
    top = ribbon_wing(sbp, 0.0, 1)
    g.cap("ROF", sbp, top)
    hip_roof(mrr(sb), top, 0.45, 1.6)

    # ---- the entrance loop: a one-way drive round an oval garden, a porte-cochere canopy, the sign, the fence ----
    loop_pts = OSM["1206690868"]["m"] + OSM["1206690867"]["m"] + OSM["617314196"]["m"]
    lc = (sum(p[0] for p in loop_pts) / len(loop_pts), sum(p[1] for p in loop_pts) / len(loop_pts))
    # the game road is wider than the real one: slide the loop east until the oval sits 4 inside the site
    site0 = LOT.intersection(sbox(-120, 150, 213, 545)).buffer(-4.0)
    shift = 0.0
    while not site0.contains(Polygon(ellipse(lc[0] - 6 + shift, lc[1], 10.0, 18.0, 24))) and shift < 40:
        shift += 2.0
    lc = (lc[0] + shift, lc[1])
    oval = ellipse(lc[0] - 6, lc[1], 10.0, 18.0, 24)
    g.ring("PGR", oval, 0.0, 1.0)
    g.cap("LAW", oval, 1.0)
    g.ring("HDG", ellipse(lc[0] - 6, lc[1], 7.0, 14.0, 20), 1.0, 2.6)
    g.cap("HDG", ellipse(lc[0] - 6, lc[1], 7.0, 14.0, 20), 2.6)
    COLL.append((lc[0] - 6, lc[1], 0.0, 16.0, 30.0, 1.0, 0.0))
    from shapely import affinity as _aff
    drive = unary_union([_aff.translate(LineString(OSM[k]["m"]), shift, 0).buffer(4.0)
                         for k in ("1206690868", "1206690867", "617314196")])
    # canopy from the pavilion's west face over the inner leg
    cw = (wx, cyj)
    can = [(cw[0] - 16, cw[1] - 10), (cw[0], cw[1] - 10), (cw[0], cw[1] + 10), (cw[0] - 16, cw[1] + 10)]
    g.cap("TER", can, 15.0)
    g.cap("CEL", can, 13.5, down=True)
    g.ring("SED", can, 13.5, 15.0)
    for cx_, cy_ in ((cw[0] - 15, cw[1] - 9), (cw[0] - 15, cw[1] + 9)):
        g.column("SED", cx_, cy_, SKIRT, 13.5, 0.8)
        COLL.append((cx_, cy_, 0.0, 1.6, 1.6, 13.5, 0.0))
        LIGHTS.append({"p": (cx_ + 6, cy_, 12.8), "kind": "soffit"})
    # the name: a blue board on two posts on the front lawn, white 3D letters, facing the road (west)
    sb_c = (lc[0] - 18, lc[1] + 34)
    if LOT.buffer(-3).contains(Point(sb_c)):
        g.box("BLU", sb_c[0], sb_c[1], 3.0, 0.8, 22.0, 7.0, 0.0)
        for s in (-1, 1):
            g.box("DRK", sb_c[0], sb_c[1] + s * 8.0, SKIRT, 0.8, 0.8, 3.0 - SKIRT, 0.0)
        g.text("WLT", LET, "SEDONA", (sb_c[0] - 0.42, sb_c[1], 4.2), (0.0, -1.0), 3.6, 0.3, max_w=19.0)
        COLL.append((sb_c[0], sb_c[1], 0.0, 0.8, 22.0, 10.0, 0.0))
    # white fence along Kaba Aye Pagoda Road (the lot's west edge), pillars every 7 with two rails
    site = LOT.intersection(sbox(-120, 150, 213, 545))
    edge = list(site.buffer(-1.5).exterior.simplify(2.5).coords)
    fence = []
    for i in range(len(edge) - 1):
        p, q = edge[i], edge[i + 1]
        if max(p[0], q[0]) < -15 and 240 < (p[1] + q[1]) / 2 < 540:
            fence.append((p, q))
    for p, q in fence:
        L = math.dist(p, q)
        k = max(1, int(L // 7))
        for j in range(k + 1):
            c = lerp(p, q, j / k)
            g.box("MUW", c[0], c[1], 0.0, 0.9, 0.9, 3.4, 0.0)
        for zz in (1.2, 2.6):
            g.tube("MUW", (p[0], p[1], zz), (q[0], q[1], zz), 0.25)
        e = unit((q[0] - p[0], q[1] - p[1]))
        COLL.append(((p[0] + q[0]) / 2, (p[1] + q[1]) / 2, 0.0, L, 0.4, 3.4, math.atan2(e[1], e[0])))
    # the ground: drives, then lawn over the rest of the site (buildings cut out)
    bld = unary_union([gw, tower, deck, tn, sb]).buffer(0.3)
    drv = drive.intersection(site).difference(bld)
    g.capshape("DRV", drv, 0.05)
    lawn = site.difference(bld).difference(drive).difference(Polygon(oval).buffer(0.3))
    g.capshape("LAW", lawn, 0.04)
    return {"garden_tops": tops, "pavilion": topJ, "inya": (top_sw, top_md, top_ne)}


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    plane = None
    for i, a in enumerate(sys.argv):
        if a == "--plane":
            plane = [float(v) for v in sys.argv[i + 1].split(",")]
            args = [x for x in args if x != sys.argv[i + 1]]
    y0 = float(args[0]) if args else 29.0
    info = build()
    cnt = g.count()
    print(info, "tris", sum(cnt.values()))
    print(sorted(cnt.items(), key=lambda kv: -kv[1]))
    out = os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "sd3d.glb")
    for f in LG.export(g, y0, out, plane=plane, ground_groups=tuple(g.g.keys()), tag="sd"):
        print(f)
    open(os.path.join(REF, "sd3d_collide.txt"), "w").write(LG.collide_text(COLL, y0, plane, tag="sd") + chr(10))
    json.dump(LIGHTS, open(os.path.join(REF, "sd3d_lights.json"), "w"))
    json.dump({k: v for k, v in g.g.items()}, open(os.path.join(REF, "sd3d_tris.json"), "w"))
    print("collide", len(COLL))
