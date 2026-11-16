"""bota3d.py (2026-11-16): Botataung Pagoda and its riverside site at true 1:1 (3 studs a metre), pure Python ->
imports/sync/landmarks/botataung.glb + build/landmarks/botataung/place.json.

Run from Games/CityLegends:  python tools/yangon/landmarks3d/bota3d.py

Real sizes (vault "City Legends/2026-11-16 Sule and Botataung 1 to 1.md"):
  * 40.1 m high (Wikipedia: 131 ft 8 in); hollow stupa on a 96 ft (29.3 m) base; OSM stupa way/180605242 is an
    octagon 29 x 28 m with its corners at the cardinal points -> 27.6 m across the flats (29.9 across the corners);
  * shape from the Commons photos (2013 "pagoda", 2014 0310, 2016 Konsek 01-03): seven broad octagonal terraces,
    a smooth round bell with one raised band, four rings, inverted bowl, lotus, banana bud, hti, two wire fans;
  * inside: the walkable zigzag corridor round the relic chamber (interior photos: Room_Inside_Paya, Eingang,
    Treasures): gilded walls and ceiling, parquet floor, a glass window onto the gold relic chamber;
  * site (OSM): compound way/314136068 (paving), pond way/314136067 (south of the stupa) with the maroon walkway on
    stilts, yellow railings, red roofs and a fountain ring (photo "pond"); north gate pavilion (2016 Konsek 01-03);
    stupa fence (yellow tiled wall, pillars, gold grilles) with corner zedis and white kiosks (2013 photo);
    Botahtaung jetty: pier way/395058306 (two arms and an end deck) and the river embankment.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pagoda_lib import PGeo, catmull, export_site, flicker, dump_scene, geo, SPM  # noqa: E402
from sule3d import pyatthat_tpl, zedi_tpl, buddha_tpl  # noqa: E402
from geom3d import ccw, raster_boxes  # noqa: E402
from shapely.geometry import Polygon, LineString, Point, box as sbox  # noqa: E402
from shapely import affinity  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT_GLB = os.path.join(ROOT, "imports", "sync", "landmarks", "botataung.glb")
OUT_DIR = os.path.join(ROOT, "build", "landmarks", "botataung")
LON_C, LAT_C = 96.171984, 16.76846
A0 = 13.8              # base half width across flats
P = 0.3                # compound paving over the ground
BASE_TOP = 3.9         # top of the hollow base storey
FLOOR = 0.9            # corridor floor
CEIL = 3.4             # corridor ceiling
CW = 1.7               # corridor width
WATER = -3.0           # river level under the ground (GLO-30 ground ~6.2 m)
POND_W = P - 1.4       # pond water level
TOP = 40.1
K8 = 1.0 / math.cos(math.pi / 8)
ENTRY = math.radians(-22.5)     # corridor door: the flat facing ESE
SPOKE = math.radians(157.5)     # window onto the relic chamber: the flat facing WNW
CH_A = 3.2                      # relic chamber half width across flats


def octagon(a, rot=0.0):
    r = a * K8
    return [(r * math.cos(rot + 2 * math.pi * i / 8), r * math.sin(rot + 2 * math.pi * i / 8)) for i in range(8)]


def osm_site():
    d = json.load(open(os.path.join(OUT_DIR, "osm_site.json")))
    g = json.load(open(os.path.join(ROOT, "build", "landmarks", "refs", "catalogue", "botataung", "footprint_osm.geojson"),
                       encoding="utf-8"))
    L = lambda p: ((p[0] - LON_C) * geo.KX, (p[1] - LAT_C) * geo.KY)
    comp = Polygon([L(p) for p in g["features"][1]["geometry"]["coordinates"][0][:-1]])
    pond = Polygon([L(p) for p in d["314136067"]["p"][:-1]])
    pier = Polygon([L(p) for p in d["395058306"]["p"][:-1]]).buffer(0)
    return comp, pond, pier


# ---------------------------------------------------------------- the stupa
def notched(a, n=0.45):
    """Octagon (corners at the cardinals, half width across flats a) with every corner stepped in (re-entrant
    corners of Botataung's terraces, 2013 / 2014 photos)."""
    V = octagon(a)
    out = []
    for i in range(8):
        p0, v, p1 = V[i - 1], V[i], V[(i + 1) % 8]
        d1 = ((v[0] - p0[0]), (v[1] - p0[1]))
        l1 = math.hypot(*d1)
        d1 = (d1[0] / l1, d1[1] / l1)
        d2 = ((p1[0] - v[0]), (p1[1] - v[1]))
        l2 = math.hypot(*d2)
        d2 = (d2[0] / l2, d2[1] / l2)
        A = (v[0] - d1[0] * n, v[1] - d1[1] * n)
        B = (A[0] + d2[0] * n, A[1] + d2[1] * n)
        C = (v[0] + d2[0] * n, v[1] + d2[1] * n)
        out += [A, B, C]
    return out


def stupa(g):
    """v2 look pass (2013 'pagoda' photo, widths relative to the base): 7 lower terraces (to 11.6 m) with stepped-in
    corners, a taller bell (11.6 -> 22.6 m, 15.6 m across at the lip), slimmer rings / bud / hti."""
    # ledge from the base storey to the first terrace
    tiers = []
    a = A0
    z = BASE_TOP
    for i in range(7):
        a1 = a - 0.84
        tiers.append((a, a1, z, z + 1.1))
        a = a1
        z += 1.1
    zt_ter = z
    prev = Polygon(octagon(A0))
    for (a_out, a_in, z0, z1) in tiers:
        P = Polygon(notched(a_in))
        g.capshape("GLD", prev.difference(P), z0)           # the tread (ledge) at z0
        g.ring("GLD", ccw(notched(a_in)), z0, z1)            # the riser up to the next tread
        prev = P
    # top of the last terrace: annulus out to the bell's lip
    bell_r = 7.75
    rv = bell_r / math.cos(math.pi / 32)
    g.capshape("GLD", prev.difference(Polygon([(rv * math.cos(2 * math.pi * k / 32), rv * math.sin(2 * math.pi * k / 32))
                                                 for k in range(32)])), zt_ter)
    zb = zt_ter
    lip = [(bell_r, zb), (bell_r, zb + 0.4), (bell_r - 0.2, zb + 0.55)]
    b0 = bell_r - 0.2
    lower = catmull([(b0, zb + 0.55), (b0 - 0.05, zb + 1.4), (b0 - 0.35, zb + 2.9)], per=3)
    zband = zb + 2.9
    bandp = [(b0 - 0.25, zband + 0.05), (b0 - 0.25, zband + 0.35), (b0 - 0.42, zband + 0.4)]
    upper = catmull([(b0 - 0.42, zband + 0.4), (b0 - 1.1, zband + 2.6), (b0 - 2.2, zband + 4.7), (b0 - 3.4, zband + 6.4),
                     (b0 - 4.1, zband + 7.2)], per=3)
    zt = upper[-1][1]
    rsh = upper[-1][0]
    rp = lip + lower[1:] + bandp + upper
    zz = zt
    r = rsh
    for i in range(4):
        rp += [(r, zz + 0.5), (r - 0.2, zz + 0.5)]
        zz += 0.5
        r -= 0.2
    rp += catmull([(r - 0.1, zz), (r + 0.15, zz + 0.6), (r - 0.1, zz + 1.1)], per=3)
    zz += 1.1
    rl = r - 0.1
    rp += [(rl - 0.35, zz + 0.9), (rl - 0.25, zz + 0.9), (rl - 0.6, zz + 1.6)]
    zz += 1.6
    zfan2 = zz
    rb = rl - 0.6
    bud = catmull([(rb, zz), (rb - 0.08, zz + 1.2), (rb - 0.3, zz + 2.6), (rb - 0.6, zz + 3.8), (rb - 0.85, zz + 4.6),
                   (rb - 0.95, zz + 4.9)], per=3)
    rp += bud[1:]
    zz = bud[-1][1]
    rp += [(0.0, zz)]
    g.lathe("GLD", rp, 32, smooth=True)
    g.fan("GWF", zt, rsh + 0.1, rsh + 1.6, 1.5)
    g.fan("GWF", zfan2, rb + 0.1, rb + 1.0, 0.9)
    zh = zz
    hp = [(0.3, zh)]
    r = 1.0
    n_t = 7
    th = (TOP - 1.9 - zh) / n_t
    for i in range(n_t):
        hp += [(r * 0.6, zh), (r, zh + 0.05), (r * 0.72, zh + th)]
        zh += th
        r = max(0.22, r * 0.83)
    hp += [(0.08, zh), (0.08, zh + 1.3), (0.0, zh + 1.3)]
    g.lathe("GLT", hp, 16, smooth=True)
    zm = zh + 1.3
    g.quad("GWR", (0.08, 0, zm - 0.95), (0.85, 0, zm - 0.8), (0.85, 0, zm - 0.4), (0.08, 0, zm - 0.25))
    orb = catmull([(0.0, zm), (0.22, zm + 0.12), (0.27, zm + 0.3), (0.16, TOP - 0.06), (0.0, TOP)], per=3)
    g.lathe("GLT", orb, 12, smooth=True, cap_top=False)
    return zt


HB_W, HB_L = 0.15, 0.6


def herringbone(g, W, z):
    """Parquet in a herringbone (photo Room_Inside_Paya): planks 0.6 x 0.15 m on the lattice (w, w), (L, -L), two wood
    tones, clipped to the walkable floor W (no plank overlaps another: checked area sum)."""
    from shapely.geometry import box as _b
    from shapely.prepared import prep
    x0, y0, x1, y1 = W.bounds
    pw = prep(W)
    w, L = HB_W, HB_L
    rmin = int(math.floor((x0 - y1) / (2 * L))) - 2
    rmax = int(math.ceil((x1 - y0) / (2 * L))) + 2
    for r in range(rmin, rmax + 1):
        smin = int(math.floor((y0 + r * L - L) / w)) - 2
        smax = int(math.ceil((y1 + r * L + L) / w)) + 2
        for s in range(smin, smax + 1):
            bx, by = s * w + r * L, s * w - r * L
            if bx > x1 + 1 or bx < x0 - 1:
                continue
            for grp, pl in (("WD1", _b(bx, by, bx + L, by + w)), ("WD2", _b(bx, by + w, bx + w, by + w + L))):
                if not pw.intersects(pl):
                    continue
                if pw.contains(pl):
                    g.cap(grp, list(pl.exterior.coords)[:-1], z)
                else:
                    g.capshape(grp, pl.intersection(W), z)


def panel_wall(g, A, B, mosaic=False):
    """A carved gold wall A -> B (walkable side on the right): embossed panel tiles (GLC) in raised gold frames (GLT:
    dado rail, top frieze, stiles every ~0.9 m), red skirting (photos Room_Inside_Paya, Eingang). mosaic: the mirror
    mosaic sections (MOS) with the same frames."""
    wall = "MOS" if mosaic else "GLC"
    L = math.dist(A, B)
    ex, ey = (B[0] - A[0]) / L, (B[1] - A[1]) / L
    P = lambda s: (A[0] + ex * s, A[1] + ey * s)
    g.wall(wall, A, B, FLOOR, CEIL)
    # rails stop their own depth short of each end, so two rails never overlap in a corner
    if L > 0.2:
        g.plate("RED", P(0.03), P(L - 0.03), FLOOR, FLOOR + 0.15, 0.03)
        g.plate("GLT", P(0.05), P(L - 0.05), FLOOR + 1.05, FLOOR + 1.15, 0.05)
        g.plate("GLT", P(0.05), P(L - 0.05), CEIL - 0.25, CEIL - 0.02, 0.05)
    n = int(L / 0.9)
    if n >= 1 and L > 0.5:
        for k in range(1, n + 1):
            s = L * k / (n + 1)
            if s < 0.12 or s > L - 0.12:
                continue
            for (z0, z1) in ((FLOOR + 0.15, FLOOR + 1.05), (FLOOR + 1.15, CEIL - 0.25)):
                g.plate("GLT", P(s - 0.04), P(s + 0.04), z0, z1, 0.04)


def relic_case(g, coll, A, B):
    """Glass relic case against a corridor wall (photos Treasures 2013, 10424722066): maroon base 0.8 m, glass box
    to 1.9 m, gold top plate, a small gold relic stupa inside. 0.03 m off the wall, no back faces."""
    L = math.dist(A, B)
    ex, ey = (B[0] - A[0]) / L, (B[1] - A[1]) / L
    nx, ny = ey, -ex                 # right of A -> B = the walkable side
    m = ((A[0] + B[0]) / 2, (A[1] + B[1]) / 2)
    d = 0.5
    c = (m[0] + nx * (0.03 + d / 2), m[1] + ny * (0.03 + d / 2))
    yaw = math.atan2(ey, ex)
    # local -y = right of the edge = walkable side
    g.box("RWD", c[0], c[1], FLOOR, 1.0, d, 0.8, yaw=yaw, faces=("+x", "-x", "-y"))
    g.box("GLT", c[0], c[1], FLOOR + 0.8, 1.0, d, 0.04, yaw=yaw, faces=("+x", "-x", "-y", "top"))
    g.box("GLS", c[0], c[1], FLOOR + 0.84, 1.0, d, 1.0, yaw=yaw, faces=("+x", "-x", "-y"))
    g.box("GLT", c[0], c[1], FLOOR + 1.84, 1.0, d, 0.06, yaw=yaw, faces=("+x", "-x", "-y", "top", "bottom"))
    rel = catmull([(0.13, FLOOR + 0.84), (0.11, FLOOR + 1.0), (0.06, FLOOR + 1.2), (0.02, FLOOR + 1.4)], per=2)
    g.lathe("GLT", rel + [(0.0, FLOOR + 1.45)], 10, cx=c[0], cy=c[1])
    coll.append((c[0], c[1], FLOOR, 1.0, d, 1.9, yaw))


def corridor(g, coll, lights):
    """The hollow base: zigzag corridor (right-angle turns) round the relic chamber, door on the ESE flat, a short
    spoke to the chamber window on the WNW flat."""
    # centre path: octagon at flats 9.0 (corners at the cardinals like the base) with an inward jog on each side
    rc = 9.0 * K8
    V = [(rc * math.cos(2 * math.pi * i / 8), rc * math.sin(2 * math.pi * i / 8)) for i in range(8)]
    path = []
    for i in range(8):
        p, q = V[i], V[(i + 1) % 8]
        e = (q[0] - p[0], q[1] - p[1])
        L = math.hypot(*e)
        ex, ey = e[0] / L, e[1] / L
        nx, ny = ey, -ex           # outward for a CCW octagon
        a1 = (p[0] + ex * L * 0.3, p[1] + ey * L * 0.3)
        b1 = (p[0] + ex * L * 0.7, p[1] + ey * L * 0.7)
        path += [p, a1, (a1[0] - nx * 2.0, a1[1] - ny * 2.0), (b1[0] - nx * 2.0, b1[1] - ny * 2.0), b1]
    ringP = Polygon(path).buffer(CW / 2, join_style=2).difference(Polygon(path).buffer(-CW / 2, join_style=2))
    ux, uy = math.cos(ENTRY), math.sin(ENTRY)
    door = affinity.rotate(sbox(6.0, -CW / 2, A0, CW / 2), math.degrees(ENTRY), origin=(0, 0))
    spoke = affinity.rotate(sbox(CH_A, -0.7, 8.0, 0.7), math.degrees(SPOKE), origin=(0, 0))
    W = ringP.union(door).union(spoke).buffer(0)
    W = W.simplify(0.001)
    outer_oct = Polygon(octagon(A0))
    ch_oct = Polygon(octagon(CH_A))
    # walls, edge by edge
    rings = [list(W.exterior.coords)[:-1]] + [list(h.coords)[:-1] for h in W.interiors]
    spoke_zone = spoke.buffer(0.05)
    ncase = 0
    for k, rr in enumerate(rings):
        rr = ccw(rr)
        hole = k > 0
        n = len(rr)
        for i in range(n):
            p, q = rr[i], rr[(i + 1) % n]
            mid = Point((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            if outer_oct.exterior.distance(mid) < 0.02:
                continue                                    # the door opening
            if ch_oct.exterior.distance(mid) < 0.02:
                g.wall("GLS", p, q, FLOOR, CEIL)             # glass onto the relic chamber (double-sided)
                coll.append(_seg_box(p, q, FLOOR, CEIL, 0.1, 0.0))
                continue
            # exterior ring: the walkable side is on the left (inward); holes: on the right
            A, B = (q, p) if not hole else (p, q)
            mos = spoke_zone.contains(mid) and math.hypot(mid.x, mid.y) < 8.2
            panel_wall(g, A, B, mosaic=mos)
            if not mos and math.dist(p, q) > 2.6 and math.hypot(mid.x, mid.y) > 9.0:
                ncase += 1
                if ncase % 3 == 1:
                    relic_case(g, coll, A, B)
            # base strip (red skirting, photo Room_Inside_Paya): 0.15 high, 0.03 proud
            coll.append(_seg_box(p, q, FLOOR, CEIL, 0.4, 0.2 if not hole else -0.2))
    herringbone(g, W, FLOOR)
    g.capshape("GLC", W, CEIL, down=True)
    # relic chamber: mosaic walls (inward), gold ceiling, floor, the gold relic stupa on a red plinth
    co = ccw(octagon(CH_A))
    for i in range(8):
        p, q = co[i], co[(i + 1) % 8]
        mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
        ang = math.atan2(mid[1], mid[0])
        if abs(((ang - SPOKE + math.pi) % (2 * math.pi)) - math.pi) < 0.1:
            # the window side: wall either side of the 1.4 m glass
            e = (q[0] - p[0], q[1] - p[1])
            L = math.hypot(*e)
            f0, f1 = 0.5 - 0.7 / L, 0.5 + 0.7 / L
            A = (p[0] + e[0] * f0, p[1] + e[1] * f0)
            B = (p[0] + e[0] * f1, p[1] + e[1] * f1)
            g.wall("MOS", A, p, FLOOR, CEIL)
            g.wall("MOS", q, B, FLOOR, CEIL)
        else:
            g.wall("MOS", q, p, FLOOR, CEIL)
    herringbone(g, Polygon(co), FLOOR)
    g.cap("GLD", co, CEIL, down=True)
    g.ring("RED", octagon(1.1), FLOOR, FLOOR + 0.5)
    g.cap("RED", octagon(1.1), FLOOR + 0.5)
    rel = [(0.85, FLOOR + 0.5), (0.85, FLOOR + 0.75), (0.7, FLOOR + 0.75)] + \
        catmull([(0.68, FLOOR + 0.75), (0.6, FLOOR + 1.3), (0.35, FLOOR + 1.8), (0.15, FLOOR + 2.1)], per=2)[0:] + \
        [(0.04, FLOOR + 2.45), (0.0, FLOOR + 2.45)]
    g.lathe("GLD", rel, 12, smooth=True)
    # outer face of the base storey with the door, steps, gold frame
    oo = ccw(octagon(A0))
    for i in range(8):
        p, q = oo[i], oo[(i + 1) % 8]
        mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
        ang = math.atan2(mid[1], mid[0])
        if abs(((ang - ENTRY + math.pi) % (2 * math.pi)) - math.pi) < 0.1:
            e = (q[0] - p[0], q[1] - p[1])
            L = math.hypot(*e)
            f0, f1 = 0.5 - (CW / 2) / L, 0.5 + (CW / 2) / L
            A = (p[0] + e[0] * f0, p[1] + e[1] * f0)
            B = (p[0] + e[0] * f1, p[1] + e[1] * f1)
            g.wall("GLD", p, A, P, BASE_TOP)
            g.wall("GLD", B, q, P, BASE_TOP)
            g.wall("GLD", A, B, P, FLOOR)
            g.wall("GLD", A, B, CEIL, BASE_TOP)
            coll.append(_seg_box(p, A, P, BASE_TOP, 0.8, -0.4))
            coll.append(_seg_box(B, q, P, BASE_TOP, 0.8, -0.4))
            coll.append(_seg_box(A, B, CEIL, BASE_TOP, 0.8, -0.4))
            # frame (carved gold surround, photo "Eingang"): jambs + lintel 0.06 proud
            ex, ey = e[0] / L, e[1] / L
            Aw = (A[0] - ex * 0.45, A[1] - ey * 0.45)
            Bw = (B[0] + ex * 0.45, B[1] + ey * 0.45)
            g.plate("GLD", Aw, A, FLOOR, CEIL, 0.06)
            g.plate("GLD", B, Bw, FLOOR, CEIL, 0.06)
            g.plate("GLD", Aw, Bw, CEIL, CEIL + 0.45, 0.06)
            # 3 steps up to the door (red edges, tiled treads)
            nx, ny = ey, -ex
            Sa = (A[0] - ex * 0.5, A[1] - ey * 0.5)
            Sb = (B[0] + ex * 0.5, B[1] + ey * 0.5)
            for k in range(3):
                d0 = 1.05 - 0.35 * k           # distance out from the face
                z0, z1 = P + 0.2 * k, P + 0.2 * (k + 1)
                a0 = (Sa[0] + nx * d0, Sa[1] + ny * d0)
                b0 = (Sb[0] + nx * d0, Sb[1] + ny * d0)
                a1 = (Sa[0] + nx * (d0 - 0.35), Sa[1] + ny * (d0 - 0.35))
                b1 = (Sb[0] + nx * (d0 - 0.35), Sb[1] + ny * (d0 - 0.35))
                g.wall("RED", a0, b0, z0, z1)                               # riser
                g.quad("MAR", (*a0, z1), (*b0, z1), (*b1, z1), (*a1, z1))   # tread (to the next riser)
                g.wall("MAR", Sa_side(Sa, nx, ny, d0), Sa_side(Sa, nx, ny, 0), z0, z1) if False else None
            # step ends: one wall each side from the face out to 1.05, stepped
            for k in range(3):
                d0 = 1.05 - 0.35 * k
                z0, z1 = P + 0.2 * k, P + 0.2 * (k + 1)
                g.wall("MAR", (Sa[0] + nx * d0, Sa[1] + ny * d0), Sa, z0, z1)
                g.wall("MAR", Sb, (Sb[0] + nx * d0, Sb[1] + ny * d0), z0, z1)
            coll.append(("W", (A[0] + B[0]) / 2 + nx * 0.55, (A[1] + B[1]) / 2 + ny * 0.55, P, 1.1, CW + 1.0,
                         FLOOR - P, math.atan2(ny, nx)))
        else:
            g.wall("GLD", p, q, P, BASE_TOP)
            coll.append(_seg_box(p, q, P, BASE_TOP, 0.8, -0.4))
    # corridor floor and the solid above as collision
    coll.append(("C", 0.0, 0.0, P, 2 * A0, 2 * A0, FLOOR - P, 0.0))
    for (z0, z1, a) in [(CEIL, BASE_TOP, A0 - 0.2), (BASE_TOP, 7.8, A0 - 1.5), (7.8, 11.6, A0 - 4.4),
                        (11.6, 16.0, 7.3), (16.0, 19.5, 6.0), (19.5, 22.6, 4.0), (22.6, 33.0, 1.8)]:
        coll.append(("C", 0.0, 0.0, z0, 2 * a, 2 * a, z1 - z0, 0.0))
    # lights along the corridor (warm, the gilding glows), one in the chamber
    for i in range(8):
        t = 2 * math.pi * (i + 0.5) / 8
        lights.append((7.5 * math.cos(t), 7.5 * math.sin(t), CEIL - 0.3, 5.0, 0.8))
    lights.append((0.0, 0.0, CEIL - 0.4, 4.0, 1.0))
    return W


def Sa_side(*a):
    return None


def _seg_box(p, q, z0, z1, th, off):
    """Collision box along p -> q, thickness th, moved `off` along the edge's right normal (+ = outward)."""
    e = (q[0] - p[0], q[1] - p[1])
    L = math.hypot(*e)
    nx, ny = e[1] / L, -e[0] / L
    cx, cy = (p[0] + q[0]) / 2 + nx * off, (p[1] + q[1]) / 2 + ny * off
    return (cx, cy, z0, L, th, z1 - z0, math.atan2(e[1], e[0]))


# ---------------------------------------------------------------- the stupa fence
def fence(g, coll, places):
    """Square fence 41 m (2013 photo): yellow tiled wall 1.3 m, pillars 0.5 m to 3.4 m every ~5 m, gold grilles,
    4 m gates in the middle of each side; zedis inside the corners; white kiosks outside."""
    h = 20.5
    corners = [(h, -h), (h, h), (-h, h), (-h, -h)]   # E side first (CCW)
    for s in range(4):
        p, q = corners[s], corners[(s + 1) % 4]
        e = (q[0] - p[0], q[1] - p[1])
        L = math.hypot(*e)
        ex, ey = e[0] / L, e[1] / L
        nx, ny = ey, -ex
        # pillar positions along the side; the gate leaves 4 m open in the middle
        posts = [0.0]
        half = [0.0, L / 2 - 2.0]
        n = 4
        posts = [half[1] * k / n for k in range(n + 1)] + [L / 2 + 2.0 + (L / 2 - 2.0) * k / n for k in range(n + 1)]
        for k, t in enumerate(posts):
            if k == len(posts) - 1:
                continue                                    # the corner post belongs to the next side
            c = (p[0] + ex * t, p[1] + ey * t)
            g.box("CRM", c[0], c[1], P, 0.5, 0.5, 3.1, yaw=math.atan2(ey, ex), faces=("+x", "-x", "+y", "-y"))
            g.box("GLD", c[0], c[1], P + 3.1, 0.62, 0.62, 0.25, yaw=math.atan2(ey, ex))
            coll.append((c[0], c[1], P, 0.5, 0.5, 3.35, math.atan2(ey, ex)))
        for k in range(len(posts) - 1):
            t0, t1 = posts[k] + 0.25, posts[k + 1] - 0.25
            if posts[k + 1] - posts[k] > 3.9 and abs((posts[k] + posts[k + 1]) / 2 - L / 2) < 0.1:
                continue                                    # the gate
            a = (p[0] + ex * t0, p[1] + ey * t0)
            b = (p[0] + ex * t1, p[1] + ey * t1)
            w = 0.15
            ao, bo = (a[0] + nx * w, a[1] + ny * w), (b[0] + nx * w, b[1] + ny * w)
            ai, bi = (a[0] - nx * w, a[1] - ny * w), (b[0] - nx * w, b[1] - ny * w)
            g.wall("CRM", ao, bo, P, P + 1.3)
            g.wall("CRM", bi, ai, P, P + 1.3)
            g.quad("CRM", (*ao, P + 1.3), (*bo, P + 1.3), (*bi, P + 1.3), (*ai, P + 1.3))
            g.wall("FNC", a, b, P + 1.3, P + 3.0)
            coll.append(_seg_box(a, b, P, P + 3.0, 0.3, 0.0))
    for (x, y) in corners:
        places.append(("zedibig", x * 0.88, y * 0.88, P, math.atan2(y, x)))
    for (x, y, yaw) in [(h + 2.6, -9.0, -math.pi / 2), (9.0, h + 2.6, 0.0), (-h - 2.6, 9.0, math.pi / 2), (-9.0, -h - 2.6, math.pi)]:
        places.append(("kiosk", x, y, P, yaw))
        coll.append((x, y, P, 2.6, 2.6, 3.0, yaw))


def kiosk_tpl():
    """White shrine kiosk (2013 photo): 2.6 m white tiled box, dark grille door (closed), gold eave, zedi on top;
    local +y is the front."""
    g = PGeo()
    s = 1.3
    o = [(-s, -s), (s, -s), (s, s), (-s, s)]
    g.ring("WHT", o, 0.0, 3.0)
    g.plate("DRK", (0.5, s), (-0.5, s), 0.15, 2.2, 0.03)
    g.band("GLD", o, 2.55, 3.0, 0.25, top=False)
    g.cap("GLD", [(-s - 0.25, -s - 0.25), (s + 0.25, -s - 0.25), (s + 0.25, s + 0.25), (-s - 0.25, s + 0.25)], 3.0)
    prof = [(0.9, 3.0), (0.9, 3.3), (0.75, 3.3)] + catmull([(0.72, 3.3), (0.62, 4.0), (0.35, 4.6), (0.2, 5.0)], per=2) + \
        [(0.03, 6.0), (0.0, 6.0)]
    g.lathe("GLD", prof, 8)
    return g


# ---------------------------------------------------------------- pond, walkway, fountain
def pond(g, pondP, coll, places):
    po = ccw([tuple(c) for c in list(pondP.exterior.coords)[:-1]])
    n = len(po)
    g.ring("CON", po, POND_W, P, inward=True)
    g.cap("WAT", po, POND_W)
    # walkway on stilts along the north (stupa) side and the west side (photo "pond": maroon slatted side, yellow
    # rails, cream and maroon posts, red roofs with a gold crest, a gold pyatthat at the corner)
    mids = [((po[i][0] + po[(i + 1) % n][0]) / 2, (po[i][1] + po[(i + 1) % n][1]) / 2) for i in range(n)]
    i_n = max(range(n), key=lambda i: mids[i][1])
    i_w = min(range(n), key=lambda i: mids[i][0])
    D = 3.4
    shared = po[(i_w + 1) % n] if math.dist(po[(i_w + 1) % n], po[i_n]) < 0.01 else po[i_w]
    strips = []
    for idx, i in enumerate((i_n, i_w)):
        p, q = po[i], po[(i + 1) % n]
        e = (q[0] - p[0], q[1] - p[1])
        L = math.hypot(*e)
        ex, ey = e[0] / L, e[1] / L
        nx, ny = -ey, ex          # into the pond (left of a CCW edge)
        a0, a1 = 0.0, L
        if idx == 1:              # the west strip stops at the north strip's inner edge
            if math.dist(p, shared) < 0.01:
                a0 = D + 0.15
            else:
                a1 = L - D - 0.15
        A2 = (p[0] + ex * a0, p[1] + ey * a0)
        B2 = (p[0] + ex * a1, p[1] + ey * a1)
        A2i, B2i = (A2[0] + nx * D, A2[1] + ny * D), (B2[0] + nx * D, B2[1] + ny * D)
        deck = [A2, B2, B2i, A2i]
        g.capshape("MAR", Polygon(deck).intersection(pondP), P)
        g.wall("RWD", B2i, A2i, POND_W + 0.25, P)          # slatted side facing the pond
        coll.append(_deck_box(deck, P))
        Ln = a1 - a0
        nst = max(2, int(Ln / 3.0))
        for k in range(nst + 1):
            t = a0 + 0.3 + (Ln - 0.6) * k / nst
            c = (p[0] + ex * t + nx * (D - 0.4), p[1] + ey * t + ny * (D - 0.4))
            g.column("CRM", c[0], c[1], POND_W, POND_W + 0.25, 0.18, 8)
            for off, grp in ((0.25, "CRM"), (D - 0.25, "RWD")):
                c = (p[0] + ex * t + nx * off, p[1] + ey * t + ny * off)
                g.box(grp, c[0], c[1], P, 0.25, 0.25, 3.0, yaw=math.atan2(ey, ex), faces=("+x", "-x", "+y", "-y"))
        g.wall("YRL", (B2i[0] - nx * 0.4, B2i[1] - ny * 0.4), (A2i[0] - nx * 0.4, A2i[1] - ny * 0.4), P, P + 1.0)
        coll.append(_seg_box(B2i, A2i, P, P + 1.0, 0.2, 0.4))
        # roof: gable along the strip, eaves 0.4 out each side, ridge at P + 4.2
        e0, e1 = -0.4, D + 0.4
        ra0 = a0 - 0.3 if a0 == 0.0 else a0 + 0.45
        ra1 = a1 + 0.3 if a1 == L else a1 - 0.45
        Ae, Be = (p[0] + ex * ra0, p[1] + ey * ra0), (p[0] + ex * ra1, p[1] + ey * ra1)

        def Q(base, off, z, nx=nx, ny=ny):
            return (base[0] + nx * off, base[1] + ny * off, z)
        zr, ze = P + 4.2, P + 3.0
        g.quad("RRF", Q(Ae, e0, ze), Q(Be, e0, ze), Q(Be, D / 2, zr), Q(Ae, D / 2, zr))
        g.quad("RRF", Q(Be, e1, ze), Q(Ae, e1, ze), Q(Ae, D / 2, zr), Q(Be, D / 2, zr))
        g.quad("WHT", Q(Ae, e0, ze), Q(Ae, e1, ze), Q(Be, e1, ze), Q(Be, e0, ze))
        g.poly3("RRF", [Q(Ae, e1, ze), Q(Ae, e0, ze), Q(Ae, D / 2, zr)])
        g.poly3("RRF", [Q(Be, e0, ze), Q(Be, e1, ze), Q(Be, D / 2, zr)])
        strips.append((p, ex, ey, nx, ny, Ae, Be, zr))
    cxs = shared[0] + (strips[0][3] + strips[1][3]) * D / 2
    cys = shared[1] + (strips[0][4] + strips[1][4]) * D / 2
    for (p, ex, ey, nx, ny, Ae, Be, zr) in strips:
        L = math.dist(Ae, Be)
        nt = max(1, int(L / 1.2))
        for k in range(nt):
            ta, tb = k / nt, (k + 1) / nt
            pa = (Ae[0] + (Be[0] - Ae[0]) * ta, Ae[1] + (Be[1] - Ae[1]) * ta)
            pb = (Ae[0] + (Be[0] - Ae[0]) * tb, Ae[1] + (Be[1] - Ae[1]) * tb)
            pm = ((pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2)
            cm = (pm[0] + nx * D / 2, pm[1] + ny * D / 2)
            if math.dist(cm, (cxs, cys)) < 3.4:
                continue                                    # under the pavilion
            g.tri("GWR", (pa[0] + nx * D / 2, pa[1] + ny * D / 2, zr + 0.02),
                  (pb[0] + nx * D / 2, pb[1] + ny * D / 2, zr + 0.02), (cm[0], cm[1], zr + 0.75))
    places.append(("pyatthats", cxs, cys, P + 4.2, math.atan2(strips[0][2], strips[0][1])))
    # fountain ring (steel) in the middle of the open water
    c = pondP.centroid
    n = 24
    for k in range(n):
        t0, t1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
        g.tube("STL", (c.x + 2.6 * math.cos(t0), c.y + 2.6 * math.sin(t0), POND_W + 0.6),
               (c.x + 2.6 * math.cos(t1), c.y + 2.6 * math.sin(t1), POND_W + 0.6), 0.08)
    for k in range(4):
        t = 2 * math.pi * k / 4 + math.pi / 4
        g.tube("STL", (c.x + 2.6 * math.cos(t), c.y + 2.6 * math.sin(t), POND_W),
               (c.x + 2.6 * math.cos(t), c.y + 2.6 * math.sin(t), POND_W + 0.56), 0.08)
    return pondP


def _deck_box(deck, z1):
    xs, ys = [p[0] for p in deck], [p[1] for p in deck]
    a, b = deck[0], deck[1]
    yaw = math.atan2(b[1] - a[1], b[0] - a[0])
    L = math.dist(deck[0], deck[1])
    D = math.dist(deck[1], deck[2])
    return (sum(xs) / 4, sum(ys) / 4, z1 - 0.4, L, D, 0.4, yaw)


# ---------------------------------------------------------------- north gate pavilion (2016 Konsek 01-03)
def gate_pavilion(g, coll, cx, yfront):
    """White hall 15 x 8 m, gold stepped gable crest to 11 m, central round-arched doorway 4 x 5 m (walk-through),
    side arches (closed, dark), 3 steps; front faces north."""
    w, d, H = 15.0, 8.0, 6.5
    x0, x1 = cx - w / 2, cx + w / 2
    yf, yb = yfront, yfront - d
    dw, dh = 2.0, 5.0
    # side and back walls (white), front wall with the door
    g.wall("WHT", (x1, yb), (x1, yf), P, H)
    g.wall("WHT", (x0, yf), (x0, yb), P, H)
    g.wall("WHT", (cx + dw, yb), (x1, yb), P, H)       # back faces south (toward the stupa)
    g.wall("WHT", (x0, yb), (cx - dw, yb), P, H)
    g.wall("WHT", (cx - dw, yb), (cx + dw, yb), P + dh, H)
    g.wall("WHT", (x1, yf), (cx + dw, yf), P, H)
    g.wall("WHT", (cx - dw, yf), (x0, yf), P, H)
    g.wall("WHT", (cx + dw, yf), (cx - dw, yf), P + dh, H)
    # passage through (walls, ceiling, floor)
    g.wall("WHT", (cx + dw, yf), (cx + dw, yb), P, P + dh)
    g.wall("WHT", (cx - dw, yb), (cx - dw, yf), P, P + dh)
    g.quad("GLD", (cx - dw, yf, P + dh), (cx + dw, yf, P + dh), (cx + dw, yb, P + dh), (cx - dw, yb, P + dh))
    g.quad("MAR", (cx - dw, yb, P), (cx + dw, yb, P), (cx + dw, yf, P), (cx - dw, yf, P)) if False else None
    # side arches (dark recesses on the front, 2 each side), red dado
    for sx in (-1, 1):
        ax = cx + sx * 5.0
        g.plate("DRK", (ax + 0.9 * sx * -1 * -1 if False else ax + 0.9, yf), (ax - 0.9, yf), P + 0.8, P + 3.8, 0.02)
    g.plate("RED", (x1, yf), (cx + dw + 0.6, yf), P, P + 0.6, 0.02)
    g.plate("RED", (cx - dw - 0.6, yf), (x0, yf), P, P + 0.6, 0.02)
    # gold door frame
    g.plate("GLD", (cx + dw + 0.6, yf), (cx + dw, yf), P, P + dh, 0.08)
    g.plate("GLD", (cx - dw, yf), (cx - dw - 0.6, yf), P, P + dh, 0.08)
    g.plate("GLD", (cx + dw + 0.6, yf), (cx - dw - 0.6, yf), P + dh, P + dh + 0.8, 0.08)
    # gold cornice
    g.band("GLD", [(x0, yb), (x1, yb), (x1, yf), (x0, yf)], H - 0.4, H, 0.2)
    # roof: gold gable roof, ridge along y at 10.0, gable front with a gold stepped crest to 11.2
    zr = H + 3.5
    g.quad("GLD", (x1 + 0.4, yb - 0.4, H), (x1 + 0.4, yf + 0.4, H), (cx, yf + 0.4, zr), (cx, yb - 0.4, zr))
    g.quad("GLD", (x0 - 0.4, yf + 0.4, H), (x0 - 0.4, yb - 0.4, H), (cx, yb - 0.4, zr), (cx, yf + 0.4, zr))
    g.quad("WHT", (x0 - 0.4, yb - 0.4, H), (x1 + 0.4, yb - 0.4, H), (x1 + 0.4, yf + 0.4, H), (x0 - 0.4, yf + 0.4, H)) if False else None
    g.cap("WHT", [(x0 - 0.4, yb - 0.4), (x1 + 0.4, yb - 0.4), (x1 + 0.4, yf + 0.4), (x0 - 0.4, yf + 0.4)], H, down=True)
    # gable ends: white tympanum with a gold edge, front and back
    for (yy, front) in ((yf + 0.4, True), (yb - 0.4, False)):
        pts = [(x0 - 0.4, yy, H), (x1 + 0.4, yy, H), (cx, yy, zr)]
        g.poly3("WHT", pts[::-1] if front else pts)
    # crest: stepped gold fingers along both gable edges of the front (thin double-sided plates)
    yc = yf + 0.45
    nf = 9
    for sgn in (-1, 1):
        for k in range(nf):
            f0, f1 = k / nf, (k + 1) / nf
            xa = cx + sgn * (w / 2 + 0.4) * (1 - f0)
            xb = cx + sgn * (w / 2 + 0.4) * (1 - f1)
            za = H + 3.5 * f0
            zb = H + 3.5 * f1
            g.quad("GWR", (xa, yc, za), (xb, yc, zb), (xb, yc, zb + 0.9), (xa, yc, za + 0.9))
    g.lathe("GLD", [(0.35, zr + 0.6), (0.3, zr + 1.2), (0.12, zr + 2.0), (0.0, zr + 2.4)], 8, cx=cx, cy=yc + 0.0) if False else None
    # steps (3) in front of the door, red edges
    for k in range(3):
        d0 = 1.2 - 0.4 * k
        z0, z1 = 0.0 + P / 3 * k, P / 3 * (k + 1)
        g.wall("RED", (cx - dw - 0.5, yf + d0), (cx + dw + 0.5, yf + d0), z0, z1) if False else \
            g.wall("RED", (cx + dw + 0.5, yf + d0), (cx - dw - 0.5, yf + d0), z0, z1)
        g.quad("MAR", (cx - dw - 0.5, yf + d0, z1), (cx + dw + 0.5, yf + d0, z1), (cx + dw + 0.5, yf + d0 - 0.4, z1),
               (cx - dw - 0.5, yf + d0 - 0.4, z1)) if False else \
            g.quad("MAR", (cx + dw + 0.5, yf + d0, z1), (cx - dw - 0.5, yf + d0, z1), (cx - dw - 0.5, yf + d0 - 0.4, z1),
                   (cx + dw + 0.5, yf + d0 - 0.4, z1))
    # collision: two side blocks + lintel + roof block
    coll.append(((x0 + cx - dw) / 2, (yf + yb) / 2, P, (cx - dw) - x0, d, H - P, 0.0))
    coll.append(((x1 + cx + dw) / 2, (yf + yb) / 2, P, x1 - (cx + dw), d, H - P, 0.0))
    coll.append((cx, (yf + yb) / 2, P + dh, 2 * dw, d, H - P - dh, 0.0))


# ---------------------------------------------------------------- jetty and embankment
def jetty(g, pierP, coll):
    zt = 0.45
    po = ccw([tuple(c) for c in list(pierP.exterior.coords)[:-1]])
    g.cap("CON", po, zt)
    g.ring("CON", po, WATER, zt)
    for b in raster_boxes(pierP, zt - 0.5, zt, cell=1.0):
        coll.append(b)
    # piles under the deck every ~4 m along the arms / end deck (square 0.4)
    minx, miny, maxx, maxy = pierP.bounds
    x = minx + 1.0
    while x < maxx:
        y = miny + 1.0
        while y < maxy:
            if pierP.buffer(-0.5).contains(Point(x, y)) and y < -190:
                g.box("CON", x, y, WATER - 0.5, 0.4, 0.4, 0.5 + 0.0 + (0.0), faces=()) if False else None
            y += 4.0
        x += 4.0
    # shed on the end deck: posts + a zinc roof (ferry waiting area)
    xs = [-4.0, 8.0, 20.0, 32.0, 44.0, 56.0, 64.0]
    for x in xs:
        for y in (-259.0, -267.4):
            g.box("STL", x, y, zt, 0.2, 0.2, 3.2, faces=("+x", "-x", "+y", "-y"))
    g.quad("ZNC", (-5.0, -268.0, zt + 3.2), (65.0, -268.0, zt + 3.2), (65.0, -263.2, zt + 3.9), (-5.0, -263.2, zt + 3.9))
    g.quad("ZNC", (65.0, -258.4, zt + 3.2), (-5.0, -258.4, zt + 3.2), (-5.0, -263.2, zt + 3.9), (65.0, -263.2, zt + 3.9))
    g.quad("WHT", (-5.0, -268.0, zt + 3.2), (-5.0, -258.4, zt + 3.2), (65.0, -258.4, zt + 3.2), (65.0, -268.0, zt + 3.2))
    g.poly3("ZNC", [(-5.0, -258.4, zt + 3.2), (-5.0, -268.0, zt + 3.2), (-5.0, -263.2, zt + 3.9)])
    g.poly3("ZNC", [(65.0, -268.0, zt + 3.2), (65.0, -258.4, zt + 3.2), (65.0, -263.2, zt + 3.9)])
    # rails along the arms (steel tube on posts)
    # embankment: concrete wall along the bank, ground -> river (faces the river)
    bank = [(-80.0, -185.3), (-63.9, -184.6), (8.6, -186.4), (48.9, -188.2), (81.5, -191.7), (97.0, -193.1)]
    BL = LineString(bank).difference(pierP.buffer(0.02))
    for seg in getattr(BL, "geoms", [BL]):
        cs = list(seg.coords)
        for i in range(len(cs) - 1):
            g.wall("CON", cs[i], cs[i + 1], WATER, 0.0)
    return bank


def build():
    g = PGeo()
    coll, places, lights = [], [], []
    comp, pondP, pierP = osm_site()
    # compound paving + kerb
    pondP = pondP.simplify(0.6)
    GY = 67.0                                     # gate pavilion front (the compound's north edge is at y 67.2-67.7)
    steps = sbox(-2.5, GY, 2.5, GY + 1.5)
    pave = comp.difference(pondP).difference(steps)
    g.capshape("MAR", pave, P)
    g.ring("MAR", ccw([tuple(c) for c in list(pave.exterior.coords)[:-1]]), 0.0, P)
    for b in raster_boxes(comp.difference(Polygon(octagon(A0 + 0.5))).difference(pondP), P - 0.6, P, cell=4.0):
        coll.append(b)
    stupa(g)
    corridor(g, coll, lights)
    fence(g, coll, places)
    pond(g, pondP, coll, places)
    gate_pavilion(g, coll, 0.0, GY)
    bank = jetty(g, pierP, coll)
    tpl = {"zedibig": zedi_tpl(7.0, 1.4), "kiosk": kiosk_tpl()}
    pt, _ = pyatthat_tpl(base=4.2, tiers=5)
    tpl["pyatthats"] = pt
    return g, tpl, places, coll, lights, comp, bank


def main():
    g, tpl, places, coll, lights, comp, bank = build()
    X0, Z0 = geo.world(LON_C, LAT_C)
    import ground
    G = ground.Ground()
    Y0 = G.y(X0, Z0)
    ys = [G.y(X0 + dx * SPM, Z0 - dy * SPM) for dx in (-50, 0, 40) for dy in (-140, -60, 0, 60)]
    print("ground studs centre %.2f, min %.2f max %.2f" % (Y0, min(ys), max(ys)))
    files, named = export_site(g, tpl, X0, Y0, Z0, OUT_GLB, "bota")
    tri_site = g.count()
    tri_tpl = {k: v.count() for k, v in tpl.items()}
    tri_inst = sum(tri_tpl[p[0]] for p in places)
    print("site tris", tri_site, "templates", tri_tpl, "instanced total", tri_inst, "=> scene", tri_site + tri_inst)
    for f in files:
        print(f)
    bad, items = flicker(g, [(tpl[p[0]], p[1], p[2], p[3], p[4]) for p in places])
    print("flicker pairs:", len(bad))
    for b in bad[:30]:
        i, j = b[0], b[1]
        print("  ", items[i][1], items[j][1], "gap %.3f area %.3f" % (b[2], b[3]),
              [round(c / SPM, 2) for c in items[i][0][0]], [round(c / SPM, 2) for c in items[j][0][0]])
    os.makedirs(OUT_DIR, exist_ok=True)
    dump_scene(os.path.join(OUT_DIR, "scene.json"), g, tpl, places)
    W = lambda x, y, z: [round(X0 + x * SPM, 3), round(Y0 + z * SPM, 3), round(Z0 - y * SPM, 3)]
    data = {"X0": X0, "Y0": Y0, "Z0": Z0, "spm": SPM,
            "places": [[p[0]] + W(p[1], p[2], p[3]) + [round(p[4], 5)] for p in places],
            "coll": [], "lights": [],
            "tris": {"site": tri_site, "templates": tri_tpl, "scene": tri_site + tri_inst}}
    for c in coll:
        kind = "B"
        if c[0] in ("W", "C"):
            kind, c = c[0], c[1:]
        x, y, z0, sx, sy, sz, yaw = c
        if kind == "C":
            data["coll"].append(["C"] + W(x, y, z0 + sz / 2) + [round(sz * SPM, 3), round(sx * SPM, 3), round(sx * SPM, 3), 0.0])
            continue
        data["coll"].append([kind] + W(x, y, z0 + sz / 2) + [round(sx * SPM, 3), round(sz * SPM, 3), round(sy * SPM, 3),
                                                              round(yaw, 5)])
    for (x, y, z, rng, br) in lights:
        data["lights"].append(W(x, y, z) + [rng * SPM, br])
    # temporary ground plate (compound + street side to the bank) and the river water
    data["plate"] = {"name": "BotataungPlate_TEMP", "cx": X0 + (-12.0) * SPM, "cz": Z0 - (-56.0) * SPM,
                     "sx": 160 * SPM, "sz": 262 * SPM, "top": Y0}   # x -92..68, y -186..76
    data["river"] = {"name": "BotataungRiver_TEMP", "cx": X0 + 40 * SPM, "cz": Z0 - (-262.0) * SPM,
                     "sx": 420 * SPM, "sz": 150 * SPM, "top": Y0 + WATER * SPM}   # y -337..-187
    json.dump(data, open(os.path.join(OUT_DIR, "place.json"), "w"), indent=0)
    print("places", len(places), "coll", len(coll), "lights", len(lights))


if __name__ == "__main__":
    main()
