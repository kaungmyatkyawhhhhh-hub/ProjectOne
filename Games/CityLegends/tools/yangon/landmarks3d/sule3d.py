"""sule3d.py (2026-11-16): Sule Pagoda at true 1:1 (3 studs a metre) in pure Python -> imports/sync/landmarks/sule.glb
+ build/landmarks/sule/place.json (template instances, collision boxes, lights, plate).

Run from Games/CityLegends:  python tools/yangon/landmarks3d/sule3d.py

Real sizes (vault "City Legends/2026-11-16 Sule and Botataung 1 to 1.md" has the table and sources):
  * height 44.1 m from the street (Wikipedia: 144 ft 9.5 in);
  * stupa octagon OSM way/477836654: vertex radius 18.6 m (34.4 m across flats), turned -8 deg (vertices near the
    cardinal points);
  * roundabout island = OSM grounds way/131745510 (94 x 85 m): its outline is the outer face of the ring of shops;
  * ring of shops 8 m deep, shops at street level, platform on top of them at 4.2 m (one storey; photos 1 and 8),
    ring roof 8.0 m; four stair halls at N / E / S / W under seven-tier pyatthat roofs (photo 6);
  * eight yellow-tiled shrine rooms (planetary posts) round the stupa foot with a seated Buddha inside (photos 8, 10;
    interiors: refs/interiors/sule_pagoda "shrine rooms 4 x 4 m, yellow walls ... white-and-gold Buddha").
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pagoda_lib import PGeo, catmull, export_site, flicker, LOOK, geo, SPM  # noqa: E402
from shapely.geometry import Polygon, box as sbox, Point  # noqa: E402
from shapely import affinity  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
REF = os.path.join(ROOT, "build", "landmarks", "refs", "catalogue", "sule", "footprint_osm.geojson")
OUT_GLB = os.path.join(ROOT, "imports", "sync", "landmarks", "sule.glb")
OUT_DIR = os.path.join(ROOT, "build", "landmarks", "sule")

LON_C, LAT_C = 96.158748, 16.774373        # stupa centroid (OSM way/477836654)
ROT = math.radians(-8.0)                    # octagon vertices at -8, 37, 82 ... deg
A0 = 17.2                                   # stupa base, half across flats (vertex radius 18.6 m)
PZ = 3.6                                    # platform over the street (one shop storey; photo 1)
RING_D = 8.0                                # ring of shops: depth
RING_TOP = 6.6
FAC = 5.8                                   # facade top (white roof skirt rises from here)
CEIL = 5.4                                  # stair passage ceiling
PAVE = 0.15                                 # island pavement over the street
GATE_W = 8.0                                # stair hall width
TOP = 44.1


def loc(lon, lat):
    return ((lon - LON_C) * geo.KX, (lat - LAT_C) * geo.KY)


def grounds():
    d = json.load(open(REF, encoding="utf-8"))
    f = [f for f in d["features"] if f["id"] == "way/131745510"][0]
    pts = [loc(*p) for p in f["geometry"]["coordinates"][0][:-1]]
    P = Polygon(pts).simplify(0.4)
    return P


# ---------------------------------------------------------------- the stupa
def stupa(g):
    """Measured on photo 1 (far camera, 37 px a metre: tip 44.1 m, bell 10-11 m across at 17 m, bud ~2 m, fan ~5 m)
    and photos 6 / 8 (bell base ~15 m across, the broad stepped octagon below it)."""
    a = A0
    prof = [(a, PZ)]
    z = PZ
    tiers = [(1.2, 1.4), (1.2, 1.4), (1.0, 1.2), (1.0, 1.1), (0.9, 1.0), (0.9, 0.9), (0.8, 0.8), (0.8, 0.7), (0.8, 0.6)]
    for h, inset in tiers:          # the broad stepped octagon (photo 8)
        z += h
        prof += [(a, z), (a - inset, z)]
        a -= inset
    # octagonal bell: moulding, steep lower flank with the cartouches, curving in to the shoulder (photos 1, 6)
    a1 = a - 0.4
    prof += [(a1, z), (a1, z + 0.6)]
    zb = z + 0.6
    # photo 1: 10.5 m across at 17 m, so the octagonal bell is a near-straight, slightly concave cone (not a dome)
    bell = catmull([(a1, zb), (a1 - 1.0, zb + 2.0), (a1 - 2.2, zb + 4.4), (a1 - 3.4, zb + 7.0), (a1 - 4.4, zb + 9.6),
                    (a1 - 5.0, zb + 11.6)], per=3)
    prof += bell[1:]
    zt = bell[-1][1]
    a_sh = bell[-1][0]
    prof += [(a_sh - 0.15, zt)]
    g.lathe("GLD", prof + [(0.0, zt)], 8, rot=ROT)
    # cartouches: gold plates on the 8 lower bell faces (photo 6: carved leaf panels)
    k = 1.0 / math.cos(math.pi / 8)
    za, zc = zb + 0.4, zb + 2.5
    def a_at(zz):
        for (p0, z0_), (p1, z1_) in zip(bell, bell[1:]):
            if z0_ <= zz <= z1_:
                return p0 + (p1 - p0) * (zz - z0_) / (z1_ - z0_)
        return bell[-1][0]
    ra, rc = a_at(za) * k, a_at(zc) * k
    for i in range(8):
        t0, t1 = ROT + 2 * math.pi * i / 8, ROT + 2 * math.pi * (i + 1) / 8
        tm = (t0 + t1) / 2
        nx, ny = math.cos(tm), math.sin(tm)
        def pt(r, zz, f):
            x0, y0 = r * math.cos(t0), r * math.sin(t0)
            x1, y1 = r * math.cos(t1), r * math.sin(t1)
            return (x0 + (x1 - x0) * f + nx * 0.07, y0 + (y1 - y0) * f + ny * 0.07, zz)
        A, B, C, D = pt(ra, za, 0.36), pt(ra, za, 0.64), pt(rc, zc, 0.64), pt(rc, zc, 0.36)
        g.quad("GLD", A, B, C, D)
        for (p, q) in ((A, B), (B, C), (C, D), (D, A)):
            p2 = (p[0] - nx * 0.07, p[1] - ny * 0.07, p[2])
            q2 = (q[0] - nx * 0.07, q[1] - ny * 0.07, q[2])
            g.quad("GLD", p2, q2, q, p)
    # round from the shoulder: four rings, inverted bowl, lotus petals, banana bud (photos 1, 6)
    z = zt
    r0 = a_sh - 0.25
    rp = [(r0, z)]
    for r in (r0, r0 - 0.2, r0 - 0.4, r0 - 0.55):
        rp += [(r, z), (r, z + 0.6), (r - 0.18, z + 0.6)]
        z += 0.6
    rb = r0 - 0.73
    rp += catmull([(rb, z), (rb + 0.3, z + 0.7), (rb + 0.05, z + 1.3)], per=3)[1:]
    z += 1.3
    rl = rb + 0.05
    rp += [(rl - 0.25, z + 1.1), (rl - 0.15, z + 1.1), (rl - 0.45, z + 1.9)]
    z += 1.9
    zfan = z
    bud = catmull([(rl - 0.45, z), (rl - 0.5, z + 0.8), (rl - 0.65, z + 1.8), (rl - 0.95, z + 2.7), (rl - 1.25, z + 3.3),
                   (rl - 1.4, z + 3.5)], per=3)
    rp += bud[1:]
    z = bud[-1][1]
    rp += [(0.0, z)]
    g.lathe("GLD", rp, 32, smooth=True)
    g.fan("GWF", zfan, rl - 0.4, 3.0, 1.2)
    # hti (photo 1: a tall stack of umbrella tiers, z ~34 -> 42), mast, vane, orb to 44.1
    zh = z
    hp = [(0.35, zh)]
    r = 1.3
    n_t = 9
    th = (TOP - 2.2 - zh) / n_t
    for i in range(n_t):
        hp += [(r * 0.6, zh), (r, zh + 0.06), (r * 0.72, zh + th)]
        zh += th
        r = max(0.22, r * 0.84)
    hp += [(0.1, zh), (0.1, zh + 1.5), (0.0, zh + 1.5)]
    g.lathe("GLD", hp, 16, smooth=True)
    g.fan("GWF", z + 0.15, 1.35, 1.85, 0.8, n=24)
    zm = zh + 1.5
    g.quad("GWR", (0.1, 0, zm - 0.95), (0.9, 0, zm - 0.8), (0.9, 0, zm - 0.4), (0.1, 0, zm - 0.25))
    orb = catmull([(0.0, zm), (0.25, zm + 0.12), (0.3, zm + 0.32), (0.18, TOP - 0.06), (0.0, TOP)], per=3)
    g.lathe("GLD", orb, 12, smooth=True, cap_top=False)
    return z


# ---------------------------------------------------------------- ring of shops, platform, stair halls
def gate_rects(outerP):
    rects = []
    for ang in (90, 0, -90, 180):          # N, E, S, W
        t = math.radians(ang)
        R = sbox(0, -GATE_W / 2, 60, GATE_W / 2)
        rects.append((ang, affinity.rotate(R, ang, origin=(0, 0))))
    return rects


def ring(g, outerP, coll):
    inner = outerP.buffer(-RING_D, join_style=2)
    ringP = outerP.difference(inner)
    rects = gate_rects(outerP)
    cut = ringP
    for ang, R in rects:
        cut = cut.difference(R)
    pieces = list(cut.geoms) if cut.geom_type == "MultiPolygon" else [cut]
    signs = ["SG1", "SG2", "SG3", "SG4", "SG2", "SG1", "SG4", "SG3"]
    nsign = 0
    for P in pieces:
        ext = list(P.exterior.coords)[:-1]
        from geom3d import ccw
        ext = ccw(ext)
        n = len(ext)
        for i in range(n):
            p, q = ext[i], ext[(i + 1) % n]
            mid = Point((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            if L < 1e-3:
                continue
            if outerP.exterior.distance(mid) < 0.05:
                # outer facade: bays of ~4 m
                nb = max(1, round(L / 4.0))
                for b in range(nb):
                    s0, s1 = b / nb, (b + 1) / nb
                    A = (p[0] + (q[0] - p[0]) * s0, p[1] + (q[1] - p[1]) * s0)
                    B = (p[0] + (q[0] - p[0]) * s1, p[1] + (q[1] - p[1]) * s1)
                    bay(g, A, B, signs[nsign % len(signs)])
                    nsign += 1
                # roof slope from the facade top (6.8) up and in 2 m to the flat roof (8.0)
                ex, ey = (q[0] - p[0]) / L, (q[1] - p[1]) / L
                nx, ny = ey, -ex           # outward
                g.quad("WHT", (p[0], p[1], FAC), (q[0], q[1], FAC), (q[0] - nx * 2, q[1] - ny * 2, RING_TOP),
                       (p[0] - nx * 2, p[1] - ny * 2, RING_TOP))
            elif inner.exterior.distance(mid) < 0.05:
                # platform side: cream wall over the platform, gold eave band
                g.wall("CRM", p, q, PZ, RING_TOP - 0.5)
                g.wall("GLD", p, q, RING_TOP - 0.5, RING_TOP)
            else:
                # cut face = the stair hall's side wall (faces into the passage)
                g.wall("CRM", p, q, 0.0, CEIL)
            # collision: the ring solid along this edge is covered by the raster below
        # slope ends: where a cut edge meets the facade the slope leaves a triangle open between 6.6 and the roof
    # flat roof: the ring minus the 2 m slope strip
    flat = cut.intersection(outerP.buffer(-2.0, join_style=2))
    g.capshape("ROF", flat, RING_TOP)
    # end triangles of the slope at each cut (cut face continues up under the slope as a wall to the roof line)
    for P in pieces:
        ext = list(P.exterior.coords)[:-1]
        from geom3d import ccw
        ext = ccw(ext)
        n = len(ext)
        for i in range(n):
            p, q = ext[i], ext[(i + 1) % n]
            mid = Point((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            if outerP.exterior.distance(mid) < 0.05 or inner.exterior.distance(mid) < 0.05:
                continue
            # p or q on the facade: wall from 6.6 to the roof surface (6.8 at the facade, 8.0 two metres in)
            L = math.hypot(q[0] - p[0], q[1] - p[1])
            def roof_z(pt):
                d = outerP.exterior.distance(Point(pt))
                return min(RING_TOP, FAC + (RING_TOP - FAC) / 2.0 * d)
            k = 12
            for j in range(k):
                a = (p[0] + (q[0] - p[0]) * j / k, p[1] + (q[1] - p[1]) * j / k)
                b = (p[0] + (q[0] - p[0]) * (j + 1) / k, p[1] + (q[1] - p[1]) * (j + 1) / k)
                za, zb = roof_z(a), roof_z(b)
                g.quad("CRM", (a[0], a[1], CEIL), (b[0], b[1], CEIL), (b[0], b[1], zb), (a[0], a[1], za))
    # collision: ring solid (shops are closed: no walk-in), street to roof
    from geom3d import raster_boxes
    for b in raster_boxes(cut, 0, RING_TOP, cell=2.0):
        coll.append(b)
    return inner, rects, pieces


def bay(g, A, B, sgrp):
    """One shop bay on the outer facade A -> B (outside on the right): open shopfront with a dark interior, piers,
    fascia with a plain sign board, blue band, upper window, white wall."""
    L = math.hypot(B[0] - A[0], B[1] - A[1])
    ex, ey = (B[0] - A[0]) / L, (B[1] - A[1]) / L
    nx, ny = ey, -ex
    P = lambda s, d=0.0: (A[0] + ex * s - nx * d, A[1] + ey * s - ny * d)
    if L < 2.4:
        # a short bay (next to a gate): plain wall, sign-less fascia, blue band
        g.wall("WHT", P(0), P(L), PAVE, PZ)
        g.wall("BLU", P(0), P(L), PZ, PZ + 0.25)
        g.wall("WHT", P(0), P(L), PZ + 0.25, FAC)
        return
    pw = 0.4
    s0, s1 = pw, L - pw
    # piers
    g.wall("WHT", P(0), P(s0), PAVE, 2.7)
    g.wall("WHT", P(s1), P(L), PAVE, 2.7)
    # shopfront recess 0.7 deep: floor, back (dark), reveals, soffit, riser
    dd = 0.7
    g.quad("MAR", (*P(s0, 0), PAVE + 0.15), (*P(s1, 0), PAVE + 0.15), (*P(s1, dd), PAVE + 0.15), (*P(s0, dd), PAVE + 0.15))
    g.wall("WHT", P(s0), P(s1), PAVE, PAVE + 0.15)
    g.wall("DRK", P(s0, dd), P(s1, dd), PAVE + 0.15, 2.7)
    g.wall("WHT", P(s0, dd), P(s0, 0), PAVE + 0.15, 2.7)
    g.wall("WHT", P(s1, 0), P(s1, dd), PAVE + 0.15, 2.7)
    g.quad("WHT", (*P(s0, 0), 2.7), (*P(s0, dd), 2.7), (*P(s1, dd), 2.7), (*P(s1, 0), 2.7))
    # fascia + sign board
    g.wall("WHT", P(0), P(L), 2.7, PZ)
    if L > 2.0:
        g.plate(sgrp, P(0.5), P(L - 0.5), 2.8, 3.45, 0.1)
    # blue band, upper wall with a window
    g.wall("BLU", P(0), P(L), PZ, PZ + 0.25)
    g.wall("WHT", P(0), P(L), PZ + 0.25, 4.2)
    g.wall("WHT", P(0), P(0.8), 4.2, 5.3)
    g.wall("WHT", P(L - 0.8), P(L), 4.2, 5.3)
    if L > 1.7:
        wd = 0.15
        g.wall("GLW", P(0.8, wd), P(L - 0.8, wd), 4.2, 5.3)
        g.wall("WHT", P(0.8, wd), P(0.8, 0), 4.2, 5.3)
        g.wall("WHT", P(L - 0.8, 0), P(L - 0.8, wd), 4.2, 5.3)
        g.quad("WHT", (*P(0.8, 0), 4.2), (*P(L - 0.8, 0), 4.2), (*P(L - 0.8, wd), 4.2), (*P(0.8, wd), 4.2))
        g.quad("WHT", (*P(0.8, 0), 5.3), (*P(0.8, wd), 5.3), (*P(L - 0.8, wd), 5.3), (*P(L - 0.8, 0), 5.3))
    else:
        g.wall("WHT", P(0.8), P(L - 0.8), 4.2, 5.3)
    g.wall("WHT", P(0), P(L), 5.3, FAC)


def stair_halls(g, outerP, inner, rects, coll, templates_at, stair_cut):
    """Each gate: steps from the pavement (0.15) up to the platform (4.2) through the ring, a ceiling at CEIL, a
    block over the passage up to 8.0 with a gold arch frame on the facade, and a pyatthat on top."""
    for ang, R in rects:
        t = math.radians(ang)
        ux, uy = math.cos(t), math.sin(t)          # out along the gate
        vx, vy = -uy, ux                            # across (left)
        h = GATE_W / 2

        def P(s, w):
            return (ux * s + vx * w, uy * s + vy * w)
        # where the passage meets the facade and the platform (min / max along the axis at its two sides)
        def hit(poly, w, far):
            from shapely.geometry import LineString
            ln = LineString([P(0, w), P(far, w)])
            I = ln.intersection(poly.exterior)
            ds = []
            for gg in getattr(I, "geoms", [I]):
                if not gg.is_empty and gg.geom_type == "Point":
                    ds.append(gg.x * ux + gg.y * uy)
            return ds
        so = [max(hit(outerP, w, 80)) for w in (-h, h)]
        si = [max(hit(inner, w, 80)) for w in (-h, h)]
        s_out, s_in = max(so), min(si)
        s_out_min = min(so)
        # steps: 23 risers of 0.176 from 0.15 to 4.2, outer step starts 0.6 outside the facade
        nst = 20
        rise = (PZ - PAVE) / nst
        s_start = s_out + 0.6
        run = (s_start - s_in) / nst
        for k in range(nst):
            sA = s_start - k * run
            sB = sA - run
            z0, z1 = PAVE + k * rise, PAVE + (k + 1) * rise
            g.quad("MAR", (*P(sA, -h), z0), (*P(sA, h), z0), (*P(sA, h), z1), (*P(sA, -h), z1))  # riser (faces out)
            g.quad("MAR", (*P(sA, -h), z1), (*P(sA, h), z1), (*P(sB, h), z1), (*P(sB, -h), z1))  # tread
        # step side faces outside the facade (the part of the flight in front of the ring)
        for w0, sgn in ((-h, -1), (h, 1)):
            sf = so[0] if w0 < 0 else so[1]
            w = w0 - sgn * 0.03          # 3 cm inside the jamb's face line (no coplanar faces)
            # stair stringer on each side outside the facade: a triangle-ish wall up to the steps' top line
            pts = []
            for k in range(nst + 1):
                sA = s_start - k * run
                if sA < sf:
                    break
                pts.append((sA, PAVE + k * rise))
            for k in range(len(pts) - 1):
                (sa, za), (sb, zb) = pts[k], pts[k + 1]
                A, B = P(sa, w), P(sb, w)
                if sgn < 0:
                    g.quad("MAR", (*A, PAVE), (*B, PAVE), (*B, zb), (*A, zb))
                else:
                    g.quad("MAR", (*B, PAVE), (*A, PAVE), (*A, zb), (*B, zb))
        # ceiling of the passage at CEIL (faces down)
        g.quad("WHT", (*P(s_in, -h), CEIL), (*P(s_in, h), CEIL), (*P(s_out, h), CEIL), (*P(s_out, -h), CEIL))
        # block over the passage: CEIL -> 8.0, facade face, platform face, sides (hidden in the ring where it is taller)
        g.quad("WHT", (*P(s_out, -h), CEIL), (*P(s_out, h), CEIL), (*P(s_out, h), RING_TOP), (*P(s_out, -h), RING_TOP))
        g.quad("GLD", (*P(s_in, h), CEIL), (*P(s_in, -h), CEIL), (*P(s_in, -h), RING_TOP), (*P(s_in, h), RING_TOP))
        g.quad("WHT", (*P(s_in, -h), CEIL), (*P(s_out, -h), CEIL), (*P(s_out, -h), RING_TOP), (*P(s_in, -h), RING_TOP))
        g.quad("WHT", (*P(s_out, h), CEIL), (*P(s_in, h), CEIL), (*P(s_in, h), RING_TOP), (*P(s_out, h), RING_TOP))
        g.quad("ROF", (*P(s_out, -h), RING_TOP), (*P(s_out, h), RING_TOP), (*P(s_in, h), RING_TOP), (*P(s_in, -h), RING_TOP))
        # under-facade filler between the facade line and s_out on each side (passage ceiling edge) is covered by the
        # gold arch frame: jambs 0.5 wide and a lintel band, 0.12 proud of s_out
        fo = s_out + 0.12
        g.quad("GLD", (*P(fo, -h - 0.5), 0.15), (*P(fo, -h), 0.15), (*P(fo, -h), CEIL), (*P(fo, -h - 0.5), CEIL))
        g.quad("GLD", (*P(fo, h), 0.15), (*P(fo, h + 0.5), 0.15), (*P(fo, h + 0.5), CEIL), (*P(fo, h), CEIL))
        g.quad("GLD", (*P(fo, -h - 0.5), CEIL), (*P(fo, h + 0.5), CEIL), (*P(fo, h + 0.5), CEIL + 0.9), (*P(fo, -h - 0.5), CEIL + 0.9))
        for (a, b, z0, z1) in ((-h - 0.5, -h, 0.15, CEIL), (h, h + 0.5, 0.15, CEIL), (-h - 0.5, h + 0.5, CEIL, CEIL + 0.9)):
            # frame edges back to the hall face
            g.quad("GLD", (*P(s_out, a), z0), (*P(fo, a), z0), (*P(fo, a), z1), (*P(s_out, a), z1))
            g.quad("GLD", (*P(fo, b), z0), (*P(s_out, b), z0), (*P(s_out, b), z1), (*P(fo, b), z1))
            g.quad("GLD", (*P(s_out, a), z1), (*P(fo, a), z1), (*P(fo, b), z1), (*P(s_out, b), z1))
        # the frame sits in front of the facade bays near the gate: its back gap to the curved facade is hidden
        # pyatthat over the passage
        stair_cut.append(Polygon([P(s_in, -h), P(s_start, -h), P(s_start, h), P(s_in, h)]))
        cs = (s_in + s_out) / 2
        cx, cy = P(cs, 0)
        templates_at.append(("pyatthat", cx, cy, RING_TOP, t))
        # collision: a ramp per gate (wedge rising inward), passage ceiling block
        L = s_start - s_in
        mx, my = P((s_start + s_in) / 2, 0)
        coll.append(("W", mx, my, PAVE, L, GATE_W, PZ - PAVE, t))
        bx, by = P(cs, 0)
        coll.append((bx, by, CEIL, s_out - s_in, GATE_W, RING_TOP - CEIL, t))


def platform(g, inner, rects, shrine_polys, coll):
    hole = Polygon([(A0 / math.cos(math.pi / 8) * math.cos(ROT + 2 * math.pi * i / 8),
                     A0 / math.cos(math.pi / 8) * math.sin(ROT + 2 * math.pi * i / 8)) for i in range(8)])
    P = inner.difference(hole)
    for sp in shrine_polys:
        P = P.difference(sp)
    g.capshape("MAR", P, PZ)
    from geom3d import raster_boxes
    for b in raster_boxes(inner, PZ - 1.0, PZ, cell=2.0):
        coll.append(b)


# ---------------------------------------------------------------- templates
def pyatthat_tpl(base=9.0, tiers=7, spire=True):
    """Seven-tier Burmese pyatthat (photo 6): an eave roof, then tiers of a short frieze and a sloped roof, each
    smaller; green slopes with gold friezes and edges, a gold spire and hti. Local metres, base centre at 0."""
    g = PGeo()
    s = base / 2
    z = 0.0
    # base eave: wide sloped roof over the hall
    def frustum(grp, s0, s1, z0, z1):
        pts0 = [(-s0, -s0), (s0, -s0), (s0, s0), (-s0, s0)]
        pts1 = [(-s1, -s1), (s1, -s1), (s1, s1), (-s1, s1)]
        for i in range(4):
            a, b = pts0[i], pts0[(i + 1) % 4]
            c, d = pts1[(i + 1) % 4], pts1[i]
            g.quad(grp, (*a, z0), (*b, z0), (*c, z1), (*d, z1))
    # eave underside (visible from below) + slope
    g.quad("GLD", (-s - 0.6, -s - 0.6, 0.0), (-s - 0.6, s + 0.6, 0.0), (s + 0.6, s + 0.6, 0.0), (s + 0.6, -s - 0.6, 0.0))
    frustum("GRN", s + 0.6, s * 0.72, 0.0, 1.2)
    z = 1.2
    w = s * 0.72
    for i in range(tiers):
        fh, rh = 0.55 * (0.93 ** i), 0.9 * (0.93 ** i)
        # frieze
        pts = [(-w, -w), (w, -w), (w, w), (-w, w)]
        g.ring("GLD", pts, z, z + fh)
        z += fh
        # roof slope overhanging 0.35
        g.quad("GLD", (-w - 0.35, -w - 0.35, z), (-w - 0.35, w + 0.35, z), (w + 0.35, w + 0.35, z), (w + 0.35, -w - 0.35, z))
        w2 = w * 0.78
        frustum("GRN", w + 0.35, w2, z, z + rh)
        # gold ridge plates (crest) at the 4 corners: thin double-sided fins
        for (dx, dy) in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
            g.quad("GWR", (dx * (w + 0.35), dy * (w + 0.35), z), (dx * w2, dy * w2, z + rh),
                   (dx * w2, dy * w2, z + rh + 0.45), (dx * (w + 0.35), dy * (w + 0.35), z + 0.5))
        z += rh
        w = w2
    # top cap of the last tier and the spire
    g.cap("GRN", [(-w, -w), (w, -w), (w, w), (-w, w)], z)
    if spire:
        sp = catmull([(0.5, z), (0.45, z + 0.8), (0.32, z + 1.8), (0.18, z + 2.6), (0.08, z + 3.4)], per=2)
        g.lathe("GLD", sp + [(0.05, z + 4.4), (0.0, z + 4.4)], 12)
    return g, z + 4.4


def zedi_tpl(h=5.5, a=1.3):
    """A small gold stupa (zedi) for shrine roofs: octagonal terraces, bell, rings, bud, mast."""
    g = PGeo()
    s = h / 5.5
    prof = [(a, 0.0), (a, 0.35 * s), (a * 0.85, 0.35 * s), (a * 0.85, 0.7 * s), (a * 0.7, 0.7 * s), (a * 0.7, 1.0 * s)]
    prof += catmull([(a * 0.68, 1.0 * s), (a * 0.6, 1.8 * s), (a * 0.4, 2.6 * s), (a * 0.25, 3.0 * s)], per=2)[0:]
    g.lathe("GLD", prof + [(0.0, 3.0 * s)], 8)
    bud = catmull([(a * 0.25, 3.0 * s), (a * 0.22, 3.6 * s), (a * 0.14, 4.3 * s), (a * 0.05, 4.9 * s)], per=2)
    g.lathe("GLD", bud + [(0.02, h), (0.0, h)], 12)
    return g


def buddha_tpl(scale=1.0):
    """Seated Buddha on a lotus base, a lathe stand-in (Kaba Aye's figure approach): gold base, white robe body,
    gold head (photo 10 / interiors: white-and-gold image)."""
    g = PGeo()
    k = scale
    g.lathe("GLD", [(0.55 * k, 0.0), (0.55 * k, 0.25 * k), (0.62 * k, 0.32 * k), (0.48 * k, 0.45 * k)], 8)
    body = catmull([(0.62 * k, 0.45 * k), (0.6 * k, 0.6 * k), (0.32 * k, 0.75 * k), (0.3 * k, 1.05 * k),
                    (0.33 * k, 1.25 * k), (0.12 * k, 1.38 * k)], per=3)
    g.lathe("WHT", body, 16, cap_top=False)
    head = catmull([(0.12 * k, 1.38 * k), (0.17 * k, 1.48 * k), (0.16 * k, 1.62 * k), (0.08 * k, 1.72 * k),
                    (0.0, 1.78 * k)], per=3)
    g.lathe("GLD", head, 16, cap_top=False)
    return g


def shrine_tpl():
    """Planetary-post shrine room (photos 8, 10): yellow-tiled cube 4 x 4 m on a 0.15 plinth, walls 0.35 thick,
    arched-top door 1.4 x 2.5 (rectangular here) facing local +y, mint interior, white ceiling, marble floor, a seated
    Buddha at the back, gold eave band and a gold zedi on the roof. Walkable (door open)."""
    g = PGeo()
    s, th, H = 2.0, 0.35, 4.2
    o = [(-s, -s), (s, -s), (s, s), (-s, s)]
    i_ = s - th
    dw = 0.7
    # plinth
    g.ring("CRM", o, 0.0, 0.15)
    # outer walls with the door gap on the +y face (edge index 2 runs (s,s)->(-s,s))
    g.ring("CRM", o, 0.15, H, edges=[0, 1, 3])
    g.wall("CRM", (s, s), (dw, s), 0.15, H)
    g.wall("CRM", (-dw, s), (-s, s), 0.15, H)
    g.wall("CRM", (dw, s), (-dw, s), 2.65, H)
    # door reveals and soffit
    g.wall("CRM", (dw, i_), (dw, s), 0.15, 2.65)
    g.wall("CRM", (-dw, s), (-dw, i_), 0.15, 2.65)
    g.quad("CRM", (dw, s, 2.65), (dw, i_, 2.65), (-dw, i_, 2.65), (-dw, s, 2.65))
    g.quad("CRM", (-dw, s, 0.15), (-dw, i_, 0.15), (dw, i_, 0.15), (dw, s, 0.15))   # threshold top
    # gold door frame 0.06 proud
    g.plate("GLD", (dw + 0.35, s), (dw, s), 0.15, 2.65, 0.06)
    g.plate("GLD", (-dw, s), (-dw - 0.35, s), 0.15, 2.65, 0.06)
    g.plate("GLD", (dw + 0.35, s), (-dw - 0.35, s), 2.65, 3.2, 0.06)
    # interior
    ii = [(-i_, -i_), (i_, -i_), (i_, i_), (-i_, i_)]
    g.ring("TEL", ii, 0.15, 3.7, inward=True, edges=[0, 1, 3])
    g.wall("TEL", (-i_, i_), (-dw, i_), 0.15, 3.7)
    g.wall("TEL", (dw, i_), (i_, i_), 0.15, 3.7)
    g.wall("TEL", (-dw, i_), (dw, i_), 2.65, 3.7)
    g.cap("MAR", ii, 0.15)
    g.cap("WHT", ii, 3.7, down=True)
    # roof: slab top, gold eave band 0.08 proud
    g.cap("CRM", o, H)
    g.band("GLD", o, H - 0.5, H - 0.1, 0.08)
    # Buddha pedestal at the back
    g.box("GLD", 0.0, -i_ + 0.55, 0.15, 1.4, 1.0, 0.6, faces=("+x", "-x", "+y", "top"))
    return g


# ---------------------------------------------------------------- build
def build():
    g = PGeo()
    coll = []
    places = []           # (template, x, y, z, yaw)
    outerP = grounds()
    zbud = stupa(g)
    inner, rects, pieces = ring(g, outerP, coll)
    stair_cut = []
    stair_halls(g, outerP, inner, rects, coll, places, stair_cut)
    # island pavement round the ring + kerb
    isl = outerP.buffer(3.5, join_style=1)
    g.capshape("PAV", isl.difference(outerP), PAVE)
    ext = list(isl.exterior.coords)[:-1]
    from geom3d import ccw
    g.ring("PAV", ccw(ext), 0.0, PAVE)
    # shrines on the 8 faces of the stupa foot (door facing out), zedis on their roofs, Buddhas inside
    shrine_polys = []
    k = 1.0 / math.cos(math.pi / 8)
    for i in range(8):
        tm = ROT + 2 * math.pi * (i + 0.5) / 8
        r = A0 + 0.3 + 2.0
        x, y = r * math.cos(tm), r * math.sin(tm)
        yaw = tm - math.pi / 2          # local +y (door) -> outward
        places.append(("shrine", x, y, PZ, yaw))
        places.append(("zedi", x, y, PZ + 4.2, yaw))
        bx, by = x + (-(2.0 - 0.35) + 0.55) * math.cos(tm), y + (-(2.0 - 0.35) + 0.55) * math.sin(tm)
        places.append(("buddha", bx, by, PZ + 0.75, yaw))
        sq = Polygon([(-2, -2), (2, -2), (2, 2), (-2, 2)])
        shrine_polys.append(affinity.translate(affinity.rotate(sq, math.degrees(yaw), origin=(0, 0)), x, y))
        # collision: 3 walls + roof (door side open)
        co, si = math.cos(yaw), math.sin(yaw)
        def L(dx, dy):
            return (x + dx * co - dy * si, y + dx * si + dy * co)
        for (dx, dy, sx, sy) in ((0, -1.825, 4.0, 0.35), (1.825, 0, 0.35, 4.0), (-1.825, 0, 0.35, 4.0),
                                 (1.35, 1.825, 1.3, 0.35), (-1.35, 1.825, 1.3, 0.35)):
            cx, cy = L(dx, dy)
            coll.append((cx, cy, PZ, sx, sy, 4.2, yaw))
        cx, cy = L(0, 0)
        coll.append((cx, cy, PZ + 3.7, 4.0, 4.0, 0.5 + 4.0, yaw))   # roof + zedi block
    # corner zedis between shrines (photo 8: gold zedis round the stupa foot) on the platform
    for i in range(8):
        t = ROT + 2 * math.pi * i / 8
        r = A0 * k + 2.2
        places.append(("zedibig", r * math.cos(t), r * math.sin(t), PZ, t))
    platform(g, inner, rects, shrine_polys + stair_cut, coll)
    # stupa collision: octagon tiers as two crossing boxes each, bell / bud as shrinking boxes
    for (z0, z1, a) in [(PZ, PZ + 2.4, A0 - 0.1), (PZ + 2.4, PZ + 4.4, A0 - 2.9), (PZ + 4.4, PZ + 6.2, A0 - 5.2),
                        (PZ + 6.2, PZ + 8.6, A0 - 7.1), (PZ + 8.6, PZ + 13.0, 6.9), (PZ + 13.0, PZ + 17.0, 5.6),
                        (PZ + 17.0, PZ + 21.0, 3.2), (PZ + 21.0, PZ + 30.0, 1.4)]:
        coll.append(("C", 0.0, 0.0, z0, 2 * a, 2 * a, z1 - z0, 0.0))
    tpl = {}
    tpl["pyatthat"], _ = pyatthat_tpl()
    tpl["shrine"] = shrine_tpl()
    tpl["zedi"] = zedi_tpl(3.6, 0.9)
    tpl["zedibig"] = zedi_tpl(7.5, 1.5)
    tpl["buddha"] = buddha_tpl(0.9)
    lights = []
    for i in range(8):
        tm = ROT + 2 * math.pi * (i + 0.5) / 8
        r = A0 + 2.3
        lights.append((r * math.cos(tm), r * math.sin(tm), PZ + 3.2, 14, 1.0))
    return g, tpl, places, coll, lights, outerP


def main():
    g, tpl, places, coll, lights, outerP = build()
    X0, Z0 = geo.world(LON_C, LAT_C)
    import ground
    G = ground.Ground()
    ys = [G.y(X0 + dx * SPM, Z0 - dy * SPM) for dx in (-45, 0, 45) for dy in (-45, 0, 45)]
    Y0 = G.y(X0, Z0)
    print("ground studs centre %.2f, min %.2f max %.2f" % (Y0, min(ys), max(ys)))
    files, named = export_site(g, tpl, X0, Y0, Z0, OUT_GLB, "sule")
    tri_site = g.count()
    tri_tpl = {k: v.count() for k, v in tpl.items()}
    tri_inst = sum(tri_tpl[p[0]] for p in places)
    print("site tris", tri_site, "templates", tri_tpl, "instanced total", tri_inst, "=> scene", tri_site + tri_inst)
    for f in files:
        print(f)
    # flicker / overlap on the whole scene (instances placed)
    bad, items = flicker(g, [(tpl[p[0]], p[1], p[2], p[3], p[4]) for p in places])
    print("flicker pairs:", len(bad))
    for b in bad[:30]:
        i, j = b[0], b[1]
        print("  ", items[i][1], items[j][1], "gap %.3f area %.3f" % (b[2], b[3]),
              [round(c / SPM, 2) for c in items[i][0][0]], [round(c / SPM, 2) for c in items[j][0][0]])
    os.makedirs(OUT_DIR, exist_ok=True)
    from pagoda_lib import dump_scene
    dump_scene(os.path.join(OUT_DIR, "scene.json"), g, tpl, places)
    data = {"X0": X0, "Y0": Y0, "Z0": Z0, "spm": SPM,
            "places": [[p[0], round(X0 + p[1] * SPM, 3), round(Y0 + p[3] * SPM, 3), round(Z0 - p[2] * SPM, 3),
                        round(p[4], 5)] for p in places],
            "coll": [], "lights": [], "plate": None,
            "tris": {"site": tri_site, "templates": tri_tpl, "scene": tri_site + tri_inst}}
    for c in coll:
        if c[0] in ("W", "C"):
            k_, x, y, z0, sx, sy, sz, yaw = c
            if k_ == "C":
                data["coll"].append(["C", round(X0 + x * SPM, 3), round(Y0 + (z0 + sz / 2) * SPM, 3), round(Z0 - y * SPM, 3),
                                     round(sz * SPM, 3), round(sx * SPM, 3), round(sx * SPM, 3), 0.0])
                continue
            data["coll"].append(["W", round(X0 + x * SPM, 3), round(Y0 + (z0 + sz / 2) * SPM, 3), round(Z0 - y * SPM, 3),
                                 round(sx * SPM, 3), round(sz * SPM, 3), round(sy * SPM, 3), round(yaw, 5)])
        else:
            x, y, z0, sx, sy, sz, yaw = c
            data["coll"].append(["B", round(X0 + x * SPM, 3), round(Y0 + (z0 + sz / 2) * SPM, 3), round(Z0 - y * SPM, 3),
                                 round(sx * SPM, 3), round(sz * SPM, 3), round(sy * SPM, 3), round(yaw, 5)])
    for (x, y, z, rng, br) in lights:
        data["lights"].append([round(X0 + x * SPM, 2), round(Y0 + z * SPM, 2), round(Z0 - y * SPM, 2), rng * SPM / 3, br])
    data["plate"] = {"name": "SulePlate_TEMP", "cx": X0, "cz": Z0, "sx": 180 * SPM, "sz": 180 * SPM, "top": Y0}
    json.dump(data, open(os.path.join(OUT_DIR, "place.json"), "w"), indent=0)
    print("places", len(places), "coll", len(coll))


if __name__ == "__main__":
    main()
