"""Shwedagon Pagoda at true 1:1 (3 studs = 1 m) for City Legends' Yangon (2026-11-16).

Pure Python (tools/yangon/city/geom3d.py triangles + glb.py writer), no Blender.
Blueprint: vault 'City Legends/2026-11-16 Research - Shwedagon 1 to 1 blueprint.md' (+ build/landmarks/refs/shwedagon/).

Frame: everything is modelled in METRES in the stupa frame of the blueprint: origin = stupa axis on the platform floor
(58 m ASL), +E = bearing 73, +N = bearing 343, +U up. In Studio the complex is one CFrame: the axis at world
(geo.world(96.14959, 16.79834), Y 174) turned +17 deg about Y (CFrame.Angles(0, rad 17, 0) turns local x toward north).
Local studs: x = 3E, y = 3U, z = -3N.

Repeated things are PIECES exported once and instanced in Studio (64 plinth stupas, 62 niche shrines, 12 planetary
posts, OSM stupas, trees, chinthe...). One mesh per (piece, material group, <= 9000 tris).

    YANGON_SCALE=1to1 python shwedagon3d.py            -> imports/sync/landmarks/shwedagon/shw_*.glb + build/landmarks/shwedagon/place.json
    YANGON_SCALE=1to1 python shwedagon3d.py check      -> also the flicker / overlap test on every placed triangle
"""
import json, math, os, sys

os.environ.setdefault("YANGON_SCALE", "1to1")
HERE = os.path.dirname(os.path.abspath(__file__))
CITY = os.path.join(HERE, "..", "city")
sys.path.insert(0, CITY)
import numpy as np
from shapely.geometry import Polygon, Point, box as sbox
from shapely.ops import unary_union
from shapely import affinity

import geo
from geom3d import Geo, ccw
from glb import Mesh, write_glb
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ornament_kit as OK  # noqa: E402  (2026-11-16 carved ornament kit)

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))          # Games/CityLegends
REFS = os.path.join(ROOT, "build", "landmarks", "refs", "shwedagon")
OUT_GLB = os.path.join(ROOT, "imports", "sync", "landmarks", "shwedagon")
OUT_BUILD = os.path.join(ROOT, "build", "landmarks", "shwedagon")
PLAN = json.load(open(os.path.join(REFS, "platform_plan.json")))

S = 3.0                      # studs per metre
Y0_M = 58.0                  # platform level ASL
YAW = math.radians(17.0)
AXIS_LL = (96.14959, 16.79834)
MAX_TRIS = 9000
TAU = 2 * math.pi

# material groups -> (Roblox material, MaterialVariant or "", colour)
GROUPS = {
    "GOLDL": ("Metal", "YgnGoldLeaf", (226, 222, 245)),
    "GOLDP": ("Metal", "YgnGoldPlate", (226, 222, 245)),
    "WHITE": ("SmoothPlastic", "", (255, 255, 250)),
    # (Studio check 16 Nov: Marble + YgnMarbleWhite rendered mid grey, darker than the beige inlay: SmoothPlastic reads
    # as the photos' white marble with the low-contrast grey-beige bands)
    "MARBLE": ("SmoothPlastic", "", (204, 202, 198)),
    "INLAY": ("SmoothPlastic", "", (150, 138, 130)),
    "RED": ("SmoothPlastic", "", (150, 32, 28)),
    "ROOF": ("SmoothPlastic", "", (96, 42, 32)),
    "GREEN": ("SmoothPlastic", "", (40, 110, 80)),
    "DARK": ("SmoothPlastic", "", (45, 32, 26)),
    "CEIL": ("SmoothPlastic", "", (110, 72, 46)),
    "WALL": ("Plaster", "YgnRenderStained", (215, 210, 198)),
    "BRONZE": ("Metal", "", (70, 52, 36)),
    "HILL": ("Grass", "YgnGrassLawn", (80, 100, 55)),
    "LEAF": ("Grass", "", (62, 92, 44)),
    "BARK": ("Wood", "YgnBark", (110, 95, 80)),
}


# ------------------------------------------------------------------ helpers (metres, E N U)
def rot(x, y, a):
    c, s = math.cos(a), math.sin(a)
    return (x * c - y * s, x * s + y * c)


class G(Geo):
    """geom3d.Geo + lathe, transforms, plane caps."""

    def lathe(self, prof, n, a0=0.0, cx=0.0, cy=0.0, cap_top=True, grp=None, sx=1.0, sy=1.0):
        """prof: [(r, z, grp?)...] bottom -> top along the OUTSIDE; grp of a point = the band up to the next point."""
        P = [(p[0], p[1], (p[2] if len(p) > 2 else grp)) for p in prof]
        clean = [P[0]]
        for p in P[1:]:
            if abs(p[0] - clean[-1][0]) > 1e-6 or abs(p[1] - clean[-1][1]) > 1e-6:
                clean.append(p)
        P = clean
        ang = [a0 + TAU * i / n for i in range(n)]
        cs = [(math.cos(a), math.sin(a)) for a in ang]

        def V(r, z, i):
            c, s = cs[i % n]
            return (cx + r * c * sx, cy + r * s * sy, z)
        for j in range(len(P) - 1):
            (r0, z0, g0), (r1, z1, _) = P[j], P[j + 1]
            for i in range(n):
                a, b = V(r0, z0, i), V(r0, z0, i + 1)
                c, d = V(r1, z1, i + 1), V(r1, z1, i)
                if r0 < 1e-6:
                    self.tri(g0, a, c, d)
                elif r1 < 1e-6:
                    self.tri(g0, a, b, c)
                else:
                    self.quad(g0, a, b, c, d)
        r, z, g = P[-1]
        if cap_top and r > 1e-6:
            for i in range(n):
                self.tri(g, (cx, cy, z), V(r, z, i), V(r, z, i + 1))

    def slope(self, grp, A, za, B, zb):
        """band between two CCW polygons with the same point count (A at za below, B at zb above), facing out."""
        n = len(A)
        for i in range(n):
            j = (i + 1) % n
            self.quad(grp, (A[i][0], A[i][1], za), (A[j][0], A[j][1], za), (B[j][0], B[j][1], zb), (B[i][0], B[i][1], zb))

    def vpoly(self, grp, pts2, origin, right, up, holes=()):
        """flat polygon in a vertical/any plane: 2D (u, v) -> origin + u*right + v*up; shows on the right x up side."""
        import shapely
        Pp = Polygon(ccw(pts2), [ccw(h)[::-1] for h in holes]).buffer(0)
        geoms = [Pp] if Pp.geom_type == "Polygon" else list(Pp.geoms)
        for Gm in geoms:
            for t in shapely.constrained_delaunay_triangles(Gm).geoms:
                c = list(t.exterior.coords)[:3]
                a = (c[1][0] - c[0][0]) * (c[2][1] - c[0][1]) - (c[1][1] - c[0][1]) * (c[2][0] - c[0][0])
                if abs(a) < 1e-9:
                    continue
                if a < 0:
                    c = [c[0], c[2], c[1]]
                self.tri(grp, *[tuple(origin[k] + u * right[k] + v * up[k] for k in range(3)) for u, v in c])

    def boxm(self, grp, cx, cy, z0, sx, sy, sz, yaw=0.0, bottom=False, top=True, grp_top=None):
        hx, hy = sx / 2, sy / 2
        pts = [rot(-hx, -hy, yaw), rot(hx, -hy, yaw), rot(hx, hy, yaw), rot(-hx, hy, yaw)]
        pts = [(cx + p[0], cy + p[1]) for p in pts]
        self.ring(grp, pts, z0, z0 + sz)
        if top:
            self.cap(grp_top or grp, pts, z0 + sz)
        if bottom:
            self.cap(grp, pts, z0, down=True)

    def prism(self, grp, poly, z0, z1, top=True, bottom=False, grp_top=None):
        self.ring(grp, poly, z0, z1)
        if top:
            self.cap(grp_top or grp, poly, z1)
        if bottom:
            self.cap(grp, poly, z0, down=True)

    def merge(self, other, dx=0.0, dy=0.0, dz=0.0, yaw=0.0, s=1.0):
        for grp, tris in other.g.items():
            for t in tris:
                out = []
                for (x, y, z) in t:
                    x, y = rot(x * s, y * s, yaw)
                    out.append((x + dx, y + dy, z * s + dz))
                self.tri(grp, *out)

    def ntris(self):
        return sum(len(v) for v in self.g.values())


def rect(cx, cy, hx, hy, yaw=0.0):
    pts = [rot(-hx, -hy, yaw), rot(hx, -hy, yaw), rot(hx, hy, yaw), rot(-hx, hy, yaw)]
    return [(cx + p[0], cy + p[1]) for p in pts]


def octagon(a, phase=math.pi / 8):
    R = a / math.cos(math.pi / 8)
    return [(R * math.cos(phase + k * math.pi / 4), R * math.sin(phase + k * math.pi / 4)) for k in range(8)]


def circle(r, n=64, a0=0.0):
    return [(r * math.cos(a0 + TAU * i / n), r * math.sin(a0 + TAU * i / n)) for i in range(n)]


def mirror4(quad):
    """quadrant polyline (N axis -> E axis, clockwise) -> full CCW polygon, symmetric about both axes."""
    q1 = list(quad)                                           # x>=0,y>=0 from (0,h) to (h,0)
    q4 = [(x, -y) for x, y in reversed(quad)][1:]             # (h,0) -> (0,-h)
    q3 = [(-x, -y) for x, y in quad][1:]                      # (0,-h) -> (-h,0)
    q2 = [(-x, y) for x, y in reversed(quad)][1:-1]           # (-h,0) -> (0,h) (open)
    return ccw(q1 + q4 + q3 + q2)


# ------------------------------------------------------------------ the DEM (raw Copernicus GLO-30, trees opened out)
_DEM = None


def frame_to_world(E, N):
    X0, Z0 = geo.world(*AXIS_LL)
    xt, yt = rot(E, N, YAW)
    return X0 + xt * S, Z0 - yt * S


def dem(E, N):
    global _DEM
    if _DEM is None:
        import terrain_study as ts
        from scipy.ndimage import grey_opening, gaussian_filter
        lon, lat, Z = ts.load_glo()
        Z = np.where((Z < -100) | (Z > 1000), np.nan, Z)
        Z = np.nan_to_num(Z, nan=np.nanmedian(Z))
        Zo = gaussian_filter(grey_opening(Z, size=(3, 3)), 0.8)
        _DEM = (np.asarray(lon), np.asarray(lat), Zo)
    lon, lat, Z = _DEM
    X, Zw = frame_to_world(E, N)
    lo, la = geo.lonlat(X, Zw)
    fi = (lo - lon[0]) / (lon[1] - lon[0])
    fj = (la - lat[0]) / (lat[1] - lat[0])
    i0, j0 = int(math.floor(fi)), int(math.floor(fj))
    ti, tj = fi - i0, fj - j0
    z00, z10, z01, z11 = Z[j0, i0], Z[j0, i0 + 1], Z[j0 + 1, i0], Z[j0 + 1, i0 + 1]
    return float((z00 * (1 - ti) + z10 * ti) * (1 - tj) + (z01 * (1 - ti) + z11 * ti) * tj)


# ------------------------------------------------------------------ the main stupa
PLINTH_H = 6.13
TERR = [(41.0, 6.13), (37.6, 10.42), (34.2, 14.71)]          # (outer half-width, base z), each 4.29 tall
TERR_TOP = 19.0
DAIS = [(30.0, 19.0), (27.7, 21.62), (25.4, 24.24)]          # octagon apothem, base z; top at 26.87 apothem 23
DAIS_TOP = (23.0, 26.87)


def plinth_poly(face=51.4, bay=56.0, bay_w=5.5, ch0=25.0, steps=12):
    d = (face - ch0) / steps
    q = [(0.0, bay), (bay_w, bay), (bay_w, face), (ch0, face)]
    for i in range(steps):
        q.append((ch0 + d * i, face - d * (i + 1)))
        q.append((ch0 + d * (i + 1), face - d * (i + 1)))
    q += [(face, bay_w), (bay, bay_w), (bay, 0.0)]
    # drop the duplicate corner (ch0, face) -> (ch0, face - d) is a vertical step: fine
    return mirror4(q)


def redent(h, steps=6, sfrac=0.55):
    s = sfrac * h
    d = (h - s) / steps
    q = [(0.0, h), (s, h)]
    for i in range(steps):
        q.append((s + d * i, h - d * (i + 1)))
        q.append((s + d * (i + 1), h - d * (i + 1)))
    q.append((h, 0.0))
    return mirror4(q)


def main_profile(k=1.0):
    """the round part, (r, z, group); k scales (Naungdawgyi)."""
    L = "GOLDL"
    P = "GOLDP"
    prof = [(21.2, 26.87, L), (21.2, 28.3, L), (19.7, 28.3, L), (19.7, 29.8, L), (18.2, 29.8, L), (18.2, 31.3, L),
            (16.7, 31.3, L), (16.7, 32.8, L), (15.5, 32.8, L), (15.5, 34.24, L),
            (15.25, 34.6, L), (15.1, 35.0, L), (14.8, 36.0, L), (14.5, 37.0, L), (14.1, 38.2, L), (13.6, 39.5, L),
            (13.1, 40.6, L), (12.6, 41.6, L),
            (12.75, 41.6, L), (12.75, 42.3, L), (12.25, 42.3, P),                     # girdle band (yin-zi)
            (11.7, 43.5, P), (11.0, 45.0, P), (10.3, 46.0, P), (9.7, 46.7, P),
            (9.85, 46.7, P), (9.85, 47.2, P), (9.6, 47.9, P), (9.4, 48.24, P),         # inverted alms bowl
            (9.0, 48.24, P), (9.0, 49.6, P), (8.3, 50.1, P), (8.3, 51.5, P), (7.6, 52.0, P), (7.6, 53.4, P),
            (6.8, 53.9, P), (6.8, 55.3, P), (6.0, 55.8, P), (6.0, 57.2, P), (5.3, 57.7, P), (5.3, 59.1, P),
            (4.7, 59.6, P), (4.7, 61.44, P),                                            # 7 baung-yit rings
            (4.9, 61.44, P), (4.9, 61.7, P), (4.7, 62.8, P), (4.55, 63.7, P), (4.4, 64.5, P),   # inverted lotus core
            (4.2, 64.5, P), (4.35, 64.85, P), (4.35, 65.65, P), (4.2, 66.0, P),         # bead band
            (4.0, 66.0, P), (4.0, 68.0, P), (4.05, 70.23, P),                          # upturned lotus core
            (3.4, 70.23, P), (3.55, 71.3, P), (3.6, 72.6, P), (3.5, 73.8, P), (3.3, 75.0, P), (3.0, 76.5, P),
            (2.65, 78.0, P), (2.3, 79.3, P), (2.0, 80.5, P), (1.7, 81.4, P), (1.45, 82.2, P), (1.2, 83.1, P),
            (1.0, 84.0, P), (0.85, 85.0, P), (0.7, 86.06, P)]                           # banana bud
    return [(r * k, z * k, g) for r, z, g in prof]


HTI_H = [0.99, 0.90, 0.81, 0.72, 0.64, 0.55, 0.46]
HTI_D = [4.72, 4.11, 3.50, 2.90, 2.29, 1.68, 1.07]


def hti_profile(z0=86.06, r_in=0.7, k=1.0):
    P = "GOLDP"
    prof = [(r_in, z0, P)]
    z = z0
    rims = []
    for h, d in zip(HTI_H, HTI_D):
        R = d / 2
        prof += [(R * 0.55, z, P), (R, z + 0.08, P), (R, z + 0.24, P), (R * 0.95, z + 0.3, P), (R * 0.7, z + h * 0.7, P),
                 (R * 0.48, z + h, P)]
        rims.append((R, z))
        z += h
    zt = z                                                           # ~91.13
    prof += [(0.3, zt, P), (0.51, zt + 0.5, P), (0.47, zt + 1.4, P), (0.34, zt + 2.4, P), (0.255, zt + 3.0, P),
             (0.3, zt + 3.4, P), (0.12, zt + 3.66, P)]
    zs = zt + 3.66                                                    # ~94.8
    prof += [(0.08, zs, P), (0.08, 95.45, P), (0.2, 95.5, P), (0.2, 95.75, P), (0.07, 95.8, P), (0.06, 98.8, P),
             (0.11, 98.86, P), (0.135, 99.0, P), (0.12, 99.18, P), (0.05, 99.32, P), (0.0, 99.36, P)]
    return [(r * k, zz * k if zz != z0 else z0 * k, g) for r, zz, g in prof], [(R * k, zr * k) for R, zr in rims]


def petals(g, n, r_fn, z_base, z_tip, width, down, grp, a0=0.0, back=True):
    """lotus petals round the axis; down=True: tips hang down (inverted lotus)."""
    for i in range(n):
        a = a0 + TAU * (i + 0.5) / n
        c, s = math.cos(a), math.sin(a)
        t = (-s, c)

        def P(r, z, u):
            return (r * c + u * t[0], r * s + u * t[1], z)
        zb, ztp = z_base, z_tip
        zm = zb + (ztp - zb) * 0.45
        rb, rm, rt = r_fn(zb) + 0.05, r_fn(zm) + 0.22, r_fn(zb) + (0.45 if down else 0.35)
        w = width / 2
        pts = [P(rb, zb, -w * 0.8), P(rm, zm, -w), P(rt, ztp, 0.0), P(rm, zm, w), P(rb, zb, w * 0.8)]
        ridge = P(rm + 0.08, zm, 0.0)
        # fan round the ridge point, outward
        for k in range(4):
            a1, b1 = pts[k], pts[k + 1]
            tri = (ridge, b1, a1) if down else (ridge, a1, b1)
            # orient: normal must point away from axis
            nx = _normal(*tri)
            if nx[0] * c + nx[1] * s < 0:
                tri = (tri[0], tri[2], tri[1])
            g.tri(grp, *tri)
        g.tri(grp, *_orient_out((ridge, pts[4], pts[0]), c, s))
        if back:
            off = 0.05
            bk = [(p[0] - c * off, p[1] - s * off, p[2]) for p in pts]
            rr = (ridge[0] - c * (off + 0.1), ridge[1] - s * (off + 0.1), ridge[2])
            for k in range(4):
                tri = _orient_out((rr, bk[k], bk[k + 1]), -c, -s)
                g.tri(grp, *tri)


def _normal(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    return (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])


def _orient_out(tri, c, s):
    n = _normal(*tri)
    if n[0] * c + n[1] * s < 0:
        return (tri[0], tri[2], tri[1])
    return tri


def r_of(prof, z):
    for (r0, z0, _), (r1, z1, _) in zip(prof, prof[1:]):
        if z0 <= z <= z1 and z1 > z0:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return prof[-1][0]


def stupa_round(g, k=1.0, seg=64, details=True):
    prof = main_profile(k)
    g.lathe(prof[:], seg, cap_top=False)
    hp, rims = hti_profile(86.06 * k, 0.7 * k, k)
    g.lathe(hp, max(24, seg // 2))
    # bell fringe under each hti tier: zig-zag skirt (outside + inside face)
    n = 40
    for R, z in rims:
        ro, ri = R + 0.03 * k, R + 0.005 * k
        drop = 0.32 * k
        for i in range(n):
            a0, a1 = TAU * i / n, TAU * (i + 1) / n
            am = (a0 + a1) / 2
            for r, inward in ((ro, False), (ri, True)):
                A = (r * math.cos(a0), r * math.sin(a0), z)
                B = (r * math.cos(a1), r * math.sin(a1), z)
                M = (r * math.cos(am), r * math.sin(am), z - drop)
                tri = (A, M, B)
                g.tri("GOLDP", *(_orient_out(tri, -math.cos(am), -math.sin(am)) if inward else _orient_out(tri, math.cos(am), math.sin(am))))
    if details:
        rfn = lambda z: r_of(prof, z)
        petals(g, 28, rfn, 63.9 * k, 61.0 * k, 1.15 * k, True, "GOLDP")
        petals(g, 28, rfn, 66.2 * k, 70.7 * k, 1.0 * k, False, "GOLDP", a0=TAU / 56)
        # festoons (pan-zwe) on the bell: 16 hanging garlands between the shoulder ornaments + the ornaments
        for i in range(16):
            a0 = TAU * i / 16
            a1 = TAU * (i + 1) / 16
            pts = []
            for t in [j / 10 for j in range(11)]:
                a = a0 + (a1 - a0) * t
                z = (46.1 - 2.6 * math.sin(math.pi * t)) * k
                r = rfn(z) + 0.1 * k
                pts.append((a, z, r))
            for (aa, za, ra), (ab, zb, rb) in zip(pts, pts[1:]):
                w = 0.22 * k
                A = (ra * math.cos(aa), ra * math.sin(aa), za - w)
                B = (rb * math.cos(ab), rb * math.sin(ab), zb - w)
                C = (rb * math.cos(ab), rb * math.sin(ab), zb + w)
                D = (ra * math.cos(aa), ra * math.sin(aa), za + w)
                am = (aa + ab) / 2
                t1 = _orient_out((A, B, C), math.cos(am), math.sin(am))
                t2 = _orient_out((A, C, D), math.cos(am), math.sin(am))
                g.tri("GOLDP", *t1)
                g.tri("GOLDP", *t2)
            # shoulder flower ornament: a small diamond plaque at the garland ends
            a = a0
            z = 46.15 * k
            r = rfn(z) + 0.14 * k
            c, s = math.cos(a), math.sin(a)
            tt = (-s, c)
            hw, hh = 0.55 * k, 0.75 * k
            Pp = lambda u, v, dr=0.0: ((r + dr) * c + u * tt[0], (r + dr) * s + u * tt[1], z + v)
            ctr = Pp(0, 0, 0.12 * k)
            rim = [Pp(0, -hh), Pp(hw, 0), Pp(0, hh), Pp(-hw, 0)]
            for j in range(4):
                g.tri("GOLDP", *_orient_out((ctr, rim[j], rim[(j + 1) % 4]), c, s))
    return prof


def build_main_stupa():
    g = G()
    P0 = plinth_poly()
    g.ring("GOLDL", P0, 0.0, PLINTH_H - 0.5)
    # plinth cornice band (0.25 proud) 5.63 -> 6.13
    P0o = plinth_poly(face=51.65, bay=56.25, bay_w=5.5, ch0=25.0)
    g.cap("GOLDL", P0o, PLINTH_H - 0.5, down=True, holes=[P0])
    g.ring("GOLDL", P0o, PLINTH_H - 0.5, PLINTH_H)
    T1 = redent(TERR[0][0])
    g.cap("MARBLE", P0o, PLINTH_H, holes=[T1])
    # terraces
    for k, (h, z0) in enumerate(TERR):
        z1 = z0 + 4.29
        A = redent(h)
        Ab = redent(h + 0.3)
        B = redent(h - 1.2)
        # three moulding bands per terrace (photos: fine horizontal lines on every step)
        Am = redent(h + 0.15)
        g.ring("GOLDL", A, z0, z0 + 0.8)
        for zb0, zb1, zn in ((z0 + 0.8, z0 + 1.05, z0 + 1.65), (z0 + 1.65, z0 + 1.9, z0 + 2.5)):
            g.cap("GOLDL", Am, zb0, down=True, holes=[A])
            g.ring("GOLDL", Am, zb0, zb1)
            g.cap("GOLDL", Am, zb1, holes=[A])
            g.ring("GOLDL", A, zb1, zn)
        g.cap("GOLDL", Ab, z0 + 2.5, down=True, holes=[A])
        g.ring("GOLDL", Ab, z0 + 2.5, z0 + 2.95)
        g.cap("GOLDL", Ab, z0 + 2.95, holes=[A])
        g.slope("GOLDL", A, z0 + 2.95, B, z1)
        nxt = redent(TERR[k + 1][0]) if k < 2 else octagon(DAIS[0][0])
        g.cap("GOLDL", B, z1, holes=[nxt])
    # octagonal dais
    for k, (a, z0) in enumerate(DAIS):
        z1 = z0 + 2.623
        A, Ab = octagon(a), octagon(a + 0.25)
        B = octagon(a - 0.9)
        g.ring("GOLDL", A, z0, z0 + 1.3)
        g.cap("GOLDL", Ab, z0 + 1.3, down=True, holes=[A])
        g.ring("GOLDL", Ab, z0 + 1.3, z0 + 1.65)
        g.cap("GOLDL", Ab, z0 + 1.65, holes=[A])
        g.slope("GOLDL", A, z0 + 1.65, B, z1)
        if k < 2:
            g.cap("GOLDL", B, z1, holes=[octagon(DAIS[k + 1][0])])
        else:
            g.cap("GOLDL", B, z1, holes=[circle(21.2, 64)])
    stupa_round(g)
    return g


# ------------------------------------------------------------------ small pieces
def small_stupa(h=4.4, base=3.5, seg=8):
    """plinth-top stupa (4.4 m): square 2-step base + lathe bell, rings, bud, spike."""
    g = G()
    k = h / 4.4
    b = base / 2
    g.boxm("GOLDL", 0, 0, 0, base, base, 0.5 * k)
    g.boxm("GOLDL", 0, 0, 0.5 * k, base * 0.8, base * 0.8, 0.45 * k, top=False)
    g.cap("GOLDL", rect(0, 0, b * 0.8, b * 0.8), 0.95 * k, holes=[circle(b * 0.62, seg)])
    prof = [(b * 0.62, 0.95), (b * 0.62, 1.15), (b * 0.52, 1.25), (b * 0.42, 2.1),
            (b * 0.27, 2.45), (b * 0.2, 2.75), (b * 0.2, 2.95), (b * 0.12, 3.4), (0.03, 4.4)]
    g.lathe([(r, z * k, "GOLDL") for r, z in prof], seg)
    return g


def cardinal_stupa():
    """the 4 bigger plinth stupas: 8.4 m, base up to ~11 m (blueprint 1c) -> base 7 m square in 3 steps."""
    g = G()
    g.boxm("GOLDL", 0, 0, 0, 7.0, 7.0, 0.9)
    g.boxm("GOLDL", 0, 0, 0.9, 5.8, 5.8, 0.8, top=False)
    g.cap("GOLDL", rect(0, 0, 2.9, 2.9), 1.7, holes=[octagon(2.3)])
    g.prism("GOLDL", octagon(2.3), 1.7, 2.5, top=False)
    g.cap("GOLDL", octagon(2.3), 2.5, holes=[circle(2.0, 20)])
    prof = [(2.0, 2.5), (2.0, 2.75), (1.8, 2.75), (1.75, 3.1), (1.6, 3.8), (1.25, 4.5), (1.0, 4.75), (1.0, 4.95),
            (0.8, 5.05), (0.8, 5.3), (0.62, 5.4), (0.55, 6.2), (0.35, 7.0), (0.18, 7.7), (0.12, 7.75), (0.05, 8.4)]
    g.lathe([(r, z, "GOLDL") for r, z in prof], 20)
    return g


def platform_stupa(white=False):
    """unit stupa for OSM 'man_made=stupa' footprints and Naungdawgyi's ring: base 1 x 1 (scaled to the footprint),
    height 2.3 x base (photos: the gilded and white shrine stupas round the platform)."""
    g = G()
    body = "WHITE" if white else "GOLDL"
    top = "GOLDL"
    g.boxm(body, 0, 0, 0, 1.0, 1.0, 0.12)
    g.boxm(body, 0, 0, 0.12, 0.86, 0.86, 0.1, top=False)
    g.cap(body, rect(0, 0, 0.43, 0.43), 0.22, holes=[octagon(0.36)])
    g.prism(body, octagon(0.36), 0.22, 0.42, top=False)
    g.cap(body, octagon(0.36), 0.42, holes=[circle(0.31, 16)])
    prof = [(0.31, 0.42, body), (0.31, 0.47, body), (0.28, 0.47, body), (0.27, 0.6, body), (0.24, 0.8, body),
            (0.18, 0.98, top), (0.15, 1.04, top), (0.15, 1.1, top), (0.12, 1.14, top), (0.1, 1.4, top),
            (0.065, 1.7, top), (0.035, 1.95, top), (0.008, 2.3, top)]
    g.lathe(prof, 10)
    return g


def buddha(h=1.0, grp="GOLDL", seg=10):
    """seated Buddha stand-in, height h (lotus base + lathe body, elliptical)."""
    g = G()
    k = h / 1.0
    g.lathe([(0.42 * k, 0.0, grp), (0.45 * k, 0.08 * k, grp), (0.38 * k, 0.16 * k, grp)], seg, sy=0.75, cap_top=False)
    prof = [(0.38, 0.16), (0.40, 0.22), (0.36, 0.30), (0.26, 0.36), (0.21, 0.58), (0.23, 0.64),
            (0.16, 0.69), (0.07, 0.72), (0.11, 0.78), (0.12, 0.87), (0.06, 0.96), (0.0, 1.0)]
    g.lathe([(r * k, z * k, grp) for r, z in prof], seg, sy=0.8)
    return g


def niche_shrine():
    """62 gilded niche shrines round the plinth foot: 3 x 3 m, 6.1 m tall, pointed-arch niche (front = +N side)."""
    g = G()
    W, D = 3.0, 3.0
    hx, hy = W / 2, D / 2
    # body: back + sides
    TB = 2.9
    g.wall("GOLDL", (hx, -hy), (-hx, -hy), 0.0, TB)
    g.wall("GOLDL", (hx, hy), (hx, -hy), 0.0, TB)
    g.wall("GOLDL", (-hx, -hy), (-hx, hy), 0.0, TB)
    # front with a pointed arch opening (u along -x -> +x seen from the front: front faces +y)
    arch = [(-0.75, 0.25)]
    for i in range(9):
        t = i / 8
        arch.append((-0.75 + 0.75 * t, 2.1 + 0.85 * math.sin(math.pi / 2 * t) ** 0.8))
    arch = [(-0.75, 0.25), (-0.75, 1.75), (-0.5, 2.15), (-0.22, 2.4), (0.0, 2.52), (0.22, 2.4), (0.5, 2.15), (0.75, 1.75), (0.75, 0.25)]
    front = [(-hx, 0.0), (hx, 0.0), (hx, TB), (-hx, TB)]
    # plane: origin (0, hy, 0), right = +x... a face seen from +y has right = -x
    g.vpoly("GOLDL", [(-u, v) for u, v in front], (0, hy, 0), (-1, 0, 0), (0, 0, 1), holes=[[(-u, v) for u, v in arch]])
    # niche recess 0.9 deep: inner walls (facing in) + back panel (dark)
    dep = 0.9
    for (u0, v0), (u1, v1) in zip(arch, arch[1:]):
        a = (u0, hy, v0)
        b = (u1, hy, v1)
        c = (u1, hy - dep, v1)
        d = (u0, hy - dep, v0)
        tri1, tri2 = (a, b, c), (a, c, d)
        nrm = _normal(*tri1)
        # inner surface faces toward the opening's middle (u 0, v ~1.5)
        mx, mz = -(u0 + u1) / 2, 1.5 - (v0 + v1) / 2
        if nrm[0] * mx + nrm[2] * mz < 0:
            tri1, tri2 = (a, c, b), (a, d, c)
        g.tri("GOLDL", *tri1)
        g.tri("GOLDL", *tri2)
    g.vpoly("DARK", [(-u, v) for u, v in arch], (0, hy - dep, 0), (-1, 0, 0), (0, 0, 1))
    # niche floor (sill) faces up
    g.quad("GOLDL", (-0.75, hy - dep, 0.25), (0.75, hy - dep, 0.25), (0.75, hy, 0.25), (-0.75, hy, 0.25))
    # cornice + roof tiers + spire
    g.cap("GOLDL", rect(0, 0, hx + 0.15, hy + 0.15), TB, down=True, holes=[rect(0, 0, hx, hy)])
    g.ring("GOLDL", rect(0, 0, hx + 0.15, hy + 0.15), TB, TB + 0.25)
    g.slope("GOLDL", rect(0, 0, hx + 0.15, hy + 0.15), TB + 0.25, rect(0, 0, 0.95, 0.95), TB + 0.6)
    g.ring("GOLDL", rect(0, 0, 0.95, 0.95), TB + 0.6, TB + 0.75)
    g.slope("GOLDL", rect(0, 0, 0.95, 0.95), TB + 0.75, rect(0, 0, 0.55, 0.55), TB + 0.95)
    g.cap("GOLDL", rect(0, 0, 0.55, 0.55), TB + 0.95, holes=[circle(0.42, 8)])
    z = TB + 0.95
    g.lathe([(0.42, z, "GOLDL"), (0.42, z + 0.25, "GOLDL"), (0.34, z + 0.55, "GOLDL"), (0.2, z + 0.85, "GOLDL"),
             (0.2, z + 1.0, "GOLDL"), (0.12, z + 1.3, "GOLDL"), (0.05, z + 2.3, "GOLDL"), (0.0, 6.8, "GOLDL")], 6)
    # flame-shaped hood over the arch (front gable), with a back face
    # 2026-11-16: the ornament kit's carved flame (bevelled, flame tongues, 0.12 m thick) in place of two flat plates
    OK.into_geo(OK.flame_blade(2.3, 1.75, 0.12, lod="lo"), g, {"G": "GOLDL"}, (0.0, hy + 0.21, TB), (1.0, 0.0, 0.0),
                (0.0, 1.0, 0.0))
    # small seated image in the niche
    g.merge(buddha(1.1, seg=5), 0.0, hy - dep * 0.55, 0.25)
    return g


def finial(g, x, y, z, h, grp="GOLDL", w=0.18):
    a = (x - w, y - w, z)
    b = (x + w, y - w, z)
    c = (x + w, y + w, z)
    d = (x - w, y + w, z)
    t = (x, y, z + h)
    g.tri(grp, a, b, t)
    g.tri(grp, b, c, t)
    g.tri(grp, c, d, t)
    g.tri(grp, d, a, t)


def pyatthat(g, cx, cy, z0, hx, hy, n, height, yaw=0.0, roof="GOLDL", neck="GREEN", gables=True):
    """Burmese tiered roof (odd tiers): tier k = a hipped frustum + a short neck; flame finials at the corners;
    a gable fin on each face; a spire (lathe) to height."""
    tier_h = height * 0.62 / n
    shrink = 0.80
    ax, ay = hx, hy
    z = z0

    def R(px, py):
        x, y = rot(px, py, yaw)
        return (cx + x, cy + y)
    for k in range(n):
        out = [R(*p) for p in rect(0, 0, ax, ay)]
        top = [R(*p) for p in rect(0, 0, ax * 0.55, ay * 0.55)]
        zr = z + tier_h * 0.72
        g.slope(roof, out, z, top, zr)
        if k == 0:
            pass
        g.ring(neck, top, zr, z + tier_h)
        nxt = (ax * shrink, ay * shrink) if k < n - 1 else (ax * 0.55, ay * 0.55)
        if k < n - 1:
            g.cap(roof, [R(*p) for p in rect(0, 0, *nxt)], z + tier_h, down=True, holes=[top])
        else:
            g.cap(roof, top, z + tier_h)
        for sx_, sy_ in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
            px, py = R(sx_ * ax, sy_ * ay)
            if k == 0:
                # 2026-11-16: the ornament kit's carved flame finial (square knob + thick flame) on the lowest tier,
                # turned to face out along the corner's diagonal
                d_ = math.hypot(px - cx, py - cy) or 1.0
                dx_, dy_ = (px - cx) / d_, (py - cy) / d_
                OK.into_geo(OK.flame_finial(tier_h * 1.1, lod="micro"), g, {"G": roof}, (px, py, z), (-dy_, dx_, 0.0),
                            (dx_, dy_, 0.0))
            elif k < 3:
                finial(g, px, py, z, tier_h * 0.9, roof, 0.06 + 0.02 * ax)
        if gables:
            # one fin per face, standing on the eave line, centred
            for face in range(4):
                if face % 2 == 0:
                    L, off = ax, ay
                else:
                    L, off = ay, ax
                fa = face * math.pi / 2
                w = L * 0.45
                hgt = tier_h * 1.05
                base_off = off * 0.86
                pts2 = [(-w, 0.0), (w, 0.0), (0.0, hgt)]
                # local: outward direction = rotate (0, 1) by fa - pi/2...
                ox, oy = rot(0.0, 1.0, fa - math.pi / 2 + math.pi / 2) if False else rot(1.0, 0.0, fa)
                tx, ty = -oy, ox
                zb = z + (tier_h * 0.72) * (1 - base_off / off) / 0.45 * 0.45 if False else z + tier_h * 0.72 * 0.3
                if k == 0:
                    # 2026-11-16: a carved flame from the ornament kit (thick slab with flame tongues) for the fin
                    org = (base_off * ox, base_off * oy)
                    wx, wy = R(*org)
                    rx, ry = rot(tx, ty, yaw)
                    OK.into_geo(OK.flame_blade(2 * w, hgt, 0.08, lod="micro"), g, {"G": roof}, (wx, wy, zb),
                                (rx, ry, 0.0), (-ry, rx, 0.0))
                    continue
                for dd, sgn in ((0.0, 1), (-0.05, -1)):
                    org = (base_off + dd) * ox, (base_off + dd) * oy
                    P3 = []
                    for u, v in pts2:
                        lx, ly = org[0] + u * tx * sgn, org[1] + u * ty * sgn
                        wx, wy = R(lx, ly)
                        P3.append((wx, wy, zb + v))
                    nrm = _normal(*P3)
                    dx, dy = rot(ox * sgn, oy * sgn, yaw)
                    if nrm[0] * dx + nrm[1] * dy < 0:
                        P3 = [P3[0], P3[2], P3[1]]
                    g.tri(roof, *P3)
        ax, ay = nxt
        z += tier_h
    # spire
    r0 = min(ax, ay) * 0.75
    hs = height - (z - z0)
    prof = [(r0, z), (r0 * 0.95, z + hs * 0.12), (r0 * 0.5, z + hs * 0.34),
            (r0 * 0.42, z + hs * 0.42), (r0 * 0.12, z + hs * 0.8), (0.0, z + hs)]
    g.lathe([(r, zz, "GOLDL") for r, zz in prof], 8, cx=cx, cy=cy)


HALL_FPS = []


def hall(g, cx, cy, yaw, L, W, wall_h=5.0, tiers=0, spire_h=0.0, roof="ROOF", walls="WHITE", open_front=True,
         plinth=0.5, statue=0.0, neck="GREEN", tier_roof="GOLDL", col_step=4.4):
    """open tazaung: plinth, red columns, back + side walls, gilded fascia, hipped roof, optional pyatthat.
    Local +y (after yaw) = the front (open)."""
    def R(px, py):
        x, y = rot(px, py, yaw)
        return (cx + x, cy + y)
    hx, hy = L / 2, W / 2
    pl = [R(*p) for p in rect(0, 0, hx, hy)]
    HALL_FPS.append(Polygon([R(*p) for p in rect(0, 0, hx + 0.3, hy + 0.3)]))
    g.ring(walls, pl, 0.0, plinth)
    g.cap("MARBLE", pl, plinth)
    # back wall + side walls (inset 0.5), faces in and out
    ix, iy = hx - 0.5, hy - 0.5
    z0, z1 = plinth, plinth + wall_h
    back = [R(-ix, -iy), R(ix, -iy)]
    for (p, q) in ((R(ix, -iy), R(-ix, -iy)),):                 # outside of the back wall faces -y
        g.wall(walls, p, q, z0, z1)
    g.wall(walls, R(-ix, -iy + 0.4), R(ix, -iy + 0.4), z0, z1)   # inside face (+y)
    if not open_front:
        g.wall(walls, R(-ix, iy), R(ix, iy), z0, z1)
    side_len = iy * (1.0 if not open_front else 0.55)
    for sx_ in (-1, 1):
        a, b = R(sx_ * ix, -iy), R(sx_ * ix, -iy + 2 * side_len)
        if sx_ > 0:
            g.wall(walls, a, b, z0, z1)
            g.wall(walls, R(ix - 0.4, -iy + 2 * side_len), R(ix - 0.4, -iy + 0.4), z0, z1)
        else:
            g.wall(walls, b, a, z0, z1)
            g.wall(walls, R(-ix + 0.4, -iy + 0.4), R(-ix + 0.4, -iy + 2 * side_len), z0, z1)
        # wall end
        g.wall(walls, R(sx_ * ix, -iy + 2 * side_len) if sx_ < 0 else R(ix - 0.4, -iy + 2 * side_len),
               R(-ix + 0.4, -iy + 2 * side_len) if sx_ < 0 else R(ix, -iy + 2 * side_len), z0, z1)
    # columns along the front and the open sides
    nx = max(2, int(round(L / col_step)))
    for i in range(nx + 1):
        px = -ix + 2 * ix * i / nx
        x, y = R(px, iy - 0.1)
        g.column("RED", x, y, z0, z1 - 0.5, 0.28, 6)
        g.column("GOLDL", x, y, z1 - 0.5, z1, 0.36, 6)
    # fascia (gilded) + ceiling
    fo = [R(*p) for p in rect(0, 0, hx + 0.3, hy + 0.3)]
    g.cap("CEIL", fo, z1, down=True)
    g.ring("GOLDL", fo, z1, z1 + 0.9)
    # hipped roof
    zr = z1 + 0.9
    top = [R(*p) for p in rect(0, 0, max(hx * 0.45, hx - hy * 0.7), hy * 0.3)]
    rh = min(hx, hy) * 0.55
    g.slope(roof, fo, zr, top, zr + rh)
    g.cap(roof, top, zr + rh)
    if tiers:
        th = min(hx, hy) * 0.5
        pyatthat(g, cx, cy, zr + rh, th, th, tiers, spire_h, yaw, roof=tier_roof, neck=neck)
    if statue:
        g.merge(buddha(statue), *R(0.0, -iy + 0.4 + statue * 0.45), z0, yaw=yaw)


def bell_piece(h, d, wall_h=6.0):
    """open bell pavilion: 4 x 2 columns, heavy beam, the bronze bell hanging low, 3-tier gilded roof."""
    g = G()
    L, W = 10.0, 8.4
    g.ring("WHITE", rect(0, 0, L / 2, W / 2), 0.0, 0.45)
    g.cap("MARBLE", rect(0, 0, L / 2, W / 2), 0.45)
    for i in range(4):
        for j in (-1, 1):
            x = -3.9 + 2.6 * i
            g.column("RED", x, j * 3.5, 0.45, wall_h - 0.4, 0.3, 8)
            g.column("GOLDL", x, j * 3.5, wall_h - 0.4, wall_h + 0.1, 0.4, 8)
    zt = wall_h + 0.1
    g.cap("CEIL", rect(0, 0, L / 2 + 0.3, W / 2 + 0.3), zt, down=True)
    g.ring("GOLDL", rect(0, 0, L / 2 + 0.3, W / 2 + 0.3), zt, zt + 0.8)
    g.slope("ROOF", rect(0, 0, L / 2 + 0.3, W / 2 + 0.3), zt + 0.8, rect(0, 0, 2.2, 1.2), zt + 3.0)
    g.cap("ROOF", rect(0, 0, 2.2, 1.2), zt + 3.0)
    pyatthat(g, 0, 0, zt + 3.0, 1.9, 1.9, 3, 7.0)
    # beam (gilded, under the ceiling) and hanger
    g.boxm("GOLDL", 0, 0, zt - 0.9, 8.0, 0.7, 0.8, bottom=True)
    zb = zt - 0.9 - 0.6 - h
    g.boxm("GOLDL", 0, 0, zb + h, 0.5, 0.5, 0.6)
    r = d / 2
    prof = [(r, zb), (r * 0.98, zb + 0.08), (r * 0.9, zb + h * 0.2), (r * 0.8, zb + h * 0.55), (r * 0.72, zb + h * 0.85),
            (r * 0.55, zb + h * 0.97), (0.0, zb + h)]
    g.lathe([(rr, zz, "BRONZE") for rr, zz in prof], 24, cap_top=False)
    # inside of the bell (seen from below): inner wall + crown, facing in
    pin = [(r - 0.3, zb + 0.08), (r * 0.82 - 0.3, zb + h * 0.55), (r * 0.5 - 0.3, zb + h * 0.92), (0.0, zb + h * 0.92)]
    gi = G()
    gi.lathe([(rr, zz, "BRONZE") for rr, zz in pin], 24, cap_top=False)
    for t in gi.g["BRONZE"]:
        g.tri("BRONZE", t[0], t[2], t[1])
    g.lathe([(r, zb, "BRONZE"), (r - 0.3, zb + 0.08, "BRONZE")], 24, cap_top=False)  # the rim underside joins
    return g


def post_piece():
    """planetary post (photos post_*.jpg): basin + seated Buddha, red-gold post with a sign board, guardian figure,
    small tiered spire, a low rail. Front (+y) faces away from the stupa. Base 3.4 x 2.8 m."""
    g = G()
    g.boxm("WHITE", 0, 0, 0, 3.4, 2.8, 0.35, grp_top="MARBLE")
    z = 0.35
    # basin
    g.lathe([(0.55, z, "GOLDL"), (0.6, z + 0.15, "GOLDL"), (0.45, z + 0.45, "GOLDL"), (0.5, z + 0.75, "GOLDL"),
             (0.62, z + 0.95, "GOLDL"), (0.55, z + 1.0, "GOLDL"), (0.0, z + 1.0, "GOLDL")], 12, cy=0.6)
    # pedestal + Buddha behind the basin
    g.boxm("GOLDL", 0, -0.4, z, 1.2, 0.7, 1.1)
    g.merge(buddha(0.95, seg=8), 0, -0.4, z + 1.1)
    # post with sign
    g.column("RED", 1.2, -0.45, z, z + 3.3, 0.09, 8)
    g.boxm("RED", 1.2, -0.4, z + 2.6, 0.9, 0.08, 0.6, bottom=True)
    g.boxm("GOLDL", 1.2, -0.4, z + 3.2, 0.95, 0.12, 0.08, bottom=True)
    # guardian deva (standing figure)
    g.boxm("GOLDL", -1.3, -0.4, z, 0.55, 0.55, 0.3)
    g.lathe([(0.2, z + 0.3, "GOLDL"), (0.24, z + 0.9, "GOLDL"), (0.19, z + 1.3, "GOLDL"), (0.22, z + 1.45, "GOLDL"),
             (0.09, z + 1.55, "GOLDL"), (0.12, z + 1.65, "GOLDL"), (0.1, z + 1.78, "GOLDL"), (0.0, z + 1.95, "GOLDL")],
            10, cx=-1.3, cy=-0.4, sy=0.7)
    # small spire behind
    g.boxm("GOLDL", 0, -1.05, z, 1.4, 0.6, 1.6, top=False)
    g.cap("GOLDL", rect(0, -1.05, 0.7, 0.3), z + 1.6)
    pyatthat(g, 0, -1.05, z + 1.6, 0.55, 0.26, 3, 2.4, gables=False)
    # low rail at the front edge
    for x in (-1.5, -0.5, 0.5, 1.5):
        g.boxm("GOLDL", x, 1.3, z, 0.12, 0.12, 0.6)
    g.boxm("GOLDL", 0, 1.3, z + 0.6, 3.1, 0.1, 0.08, bottom=True)
    return g


def animal(kind):
    """the day animals at the posts (stand-ins at 0.6-1.2 m; white body, gilded trim for the felines)."""
    g = G()
    if kind == "naga":
        # coiled body + raised hood
        for i, (r, z) in enumerate([(0.45, 0.0), (0.38, 0.22), (0.3, 0.42)]):
            g.lathe([(r + 0.11, z, "GOLDL"), (r + 0.13, z + 0.1, "GOLDL"), (r + 0.11, z + 0.2, "GOLDL"),
                     (r - 0.1, z + 0.2, "GOLDL")], 14, cap_top=False)
        g.lathe([(0.12, 0.42, "GOLDL"), (0.1, 0.9, "GOLDL"), (0.2, 1.05, "GOLDL"), (0.08, 1.2, "GOLDL"), (0.0, 1.22, "GOLDL")],
                8, cy=0.25, sx=1.4, sy=0.6)
        return g
    if kind == "garuda":
        g.boxm("GOLDL", 0, 0, 0, 0.5, 0.4, 0.25)
        g.lathe([(0.18, 0.25, "GOLDL"), (0.22, 0.6, "GOLDL"), (0.16, 0.9, "GOLDL"), (0.08, 0.98, "GOLDL"),
                 (0.11, 1.08, "GOLDL"), (0.0, 1.2, "GOLDL")], 10, sy=0.8)
        for sx_ in (-1, 1):
            a = (sx_ * 0.18, 0.0, 0.85)
            b = (sx_ * 0.75, -0.05, 1.15)
            c = (sx_ * 0.6, -0.05, 0.5)
            g.tri("GOLDL", *(a, b, c) if sx_ < 0 else (a, c, b))
            g.tri("GOLDL", *(a, c, b) if sx_ < 0 else (a, b, c))
        return g
    spec = {  # body length, height at the back, colour, head size, tusks / trunk
        "tiger": (0.9, 0.55, "GOLDL", 0.28, 0), "lion": (0.9, 0.6, "WHITE", 0.32, 0),
        "elephant_tusks": (1.1, 0.95, "WHITE", 0.4, 2), "elephant": (1.1, 0.95, "WHITE", 0.4, 1),
        "rat": (0.45, 0.22, "WHITE", 0.13, 0), "guinea_pig": (0.5, 0.26, "WHITE", 0.16, 0)}[kind]
    Lb, Hb, col, hs, el = spec
    leg = Hb * 0.45
    for x in (-Lb * 0.32, Lb * 0.32):
        for y in (-Hb * 0.18, Hb * 0.18):
            g.boxm(col, x, y, 0, Hb * 0.14, Hb * 0.14, leg)
    n0 = len(g.g.get(col, []))
    g.lathe([(0.0, -Lb / 2, col), (Hb * 0.26, -Lb * 0.42, col), (Hb * 0.3, 0.0, col), (Hb * 0.26, Lb * 0.42, col),
             (0.0, Lb / 2, col)], 10)
    # the lathe above runs along z: turn it to lie along x at the body height
    t = g.g[col][n0:]
    del g.g[col][n0:]
    for tri in t:
        g.tri(col, *[(p[2], p[1], p[0] + leg + Hb * 0.25) for p in tri][::-1])
    hx = Lb / 2 + hs * 0.4
    hz = leg + Hb * 0.5
    g.boxm(col, hx, 0, hz, hs, hs * 0.9, hs)
    if el:
        g.boxm(col, hx + hs * 0.55, 0, hz - hs * 1.2, hs * 0.25, hs * 0.25, hs * 1.4)        # trunk
        if el == 2:
            for y in (-hs * 0.3, hs * 0.3):
                g.boxm("WHITE", hx + hs * 0.6, y, hz - hs * 0.2, hs * 0.5, 0.06, 0.06, bottom=True)
        for y in (-1, 1):                                                               # ears
            g.boxm(col, hx - hs * 0.2, y * hs * 0.6, hz + hs * 0.1, hs * 0.08, hs * 0.5, hs * 0.8)
    return g


def chinthe():
    """seated guardian lion (white body, gilded trim): 9 m with the pedestal (southern pair), local front = +y."""
    g = G()
    g.boxm("WHITE", 0, 0, 0, 5.0, 7.0, 1.6, grp_top="GOLDL")
    z = 1.6
    # haunches (back) and chest (front)
    g.lathe([(1.7, z, "WHITE"), (1.9, z + 1.0, "WHITE"), (1.7, z + 2.0, "WHITE"), (1.2, z + 2.5, "WHITE"), (0.0, z + 2.6, "WHITE")],
            12, cy=-1.6, sx=1.0, sy=1.1)
    g.lathe([(1.4, z, "WHITE"), (1.5, z + 1.5, "WHITE"), (1.55, z + 3.2, "WHITE"), (1.35, z + 4.0, "GOLDL"),
             (1.5, z + 4.3, "GOLDL"), (1.1, z + 4.6, "WHITE")], 12, cy=0.6, sx=1.0, sy=0.9, cap_top=False)
    # front legs
    for x in (-0.8, 0.8):
        g.boxm("WHITE", x, 1.6, z, 0.6, 0.7, 3.0)
        g.boxm("GOLDL", x, 1.75, z, 0.75, 0.9, 0.35)
    # head: big face, gilded crown and mane
    hz = z + 4.6
    g.boxm("WHITE", 0, 0.9, hz, 2.0, 1.8, 1.6, grp_top="GOLDL")
    g.boxm("DARK", 0, 1.85, hz + 0.25, 1.3, 0.12, 0.55, bottom=True)                       # open mouth
    g.boxm("RED", 0, 1.85, hz + 0.08, 1.1, 0.1, 0.15, bottom=True)
    g.boxm("GOLDL", 0, 0.7, hz + 1.6, 1.6, 1.2, 0.5)
    g.lathe([(0.5, hz + 2.1, "GOLDL"), (0.25, hz + 2.6, "GOLDL"), (0.0, hz + 2.9, "GOLDL")], 8, cy=0.7)
    for x in (-1.0, 1.0):
        g.boxm("GOLDL", x * 1.1, 0.5, hz + 0.1, 0.25, 1.4, 1.6)                              # mane sides
    return g


def hill_tree():
    """slope tree (instanced on the hill): trunk + two lumps, ~100 triangles."""
    g = G()
    g.lathe([(0.35, -0.5, "BARK"), (0.25, 4.0, "BARK"), (0.0, 5.0, "BARK")], 5)
    for bx, by, bz, R_, Rz in ((0.0, 0.0, 7.2, 3.6, 2.6), (1.4, 0.8, 8.6, 2.4, 1.9)):
        prof = [(math.sin(math.pi * t / 4) * R_, bz - Rz * math.cos(math.pi * t / 4), "LEAF") for t in range(5)]
        g.lathe(prof, 7, cx=bx, cy=by, a0=bx)
    return g


def bodhi(height=18.0, crown=18.0, planter=True):
    g = G()
    if planter:
        r = 3.2
        g.lathe([(r, 0.0, "WHITE"), (r, 0.7, "WHITE"), (r + 0.15, 0.7, "GOLDL"), (r + 0.15, 0.95, "GOLDL"),
                 (r - 0.2, 0.95, "GOLDL")], 16, cap_top=False)
        g.cap("HILL", circle(r - 0.2, 16), 0.95, holes=[circle(0.9, 8, TAU / 16)])
        for i in range(12):
            a = TAU * i / 12
            g.column("GOLDL", (r - 0.05) * math.cos(a), (r - 0.05) * math.sin(a), 0.95, 1.9, 0.05, 3)
        g.lathe([(r - 0.05 + 0.07, 1.9, "GOLDL"), (r - 0.05 + 0.07, 1.98, "GOLDL"), (r - 0.12, 1.98, "GOLDL"),
                 (r - 0.12, 1.9, "GOLDL")], 32, cap_top=False)
        zt = 0.95
    else:
        zt = 0.0
    th = height * 0.42
    g.lathe([(0.9 if planter else 0.5, zt, "BARK"), (0.6, zt + th * 0.5, "BARK"), (0.45, zt + th, "BARK"), (0.0, zt + th + 0.5, "BARK")],
            8, a0=TAU / 16)
    # crown: lumpy ellipsoids
    blobs = [(0, 0, 0.72, 0.5, 0.32), (0.28, 0.1, 0.62, 0.3, 0.22), (-0.25, 0.15, 0.6, 0.32, 0.22),
             (0.05, -0.28, 0.6, 0.3, 0.22), (0.0, 0.05, 0.86, 0.3, 0.2)]
    for bx, by, bz, rr, rz in blobs:
        cx_, cy_, cz_ = bx * crown, by * crown, bz * height
        R_, Rz = rr * crown, rz * height
        prof = [(math.sin(math.pi * t / 5) * R_, cz_ - Rz * math.cos(math.pi * t / 5), "LEAF") for t in range(6)]
        g.lathe(prof[::5 // 4 or 1] if False else [prof[0], prof[1], prof[3], prof[5]], 7, cx=cx_, cy=cy_, a0=bx * 3)
    return g


# ------------------------------------------------------------------ platform, hill, stairs
OUTLINE = [tuple(p) for p in PLAN["platform_outline"][:-1]]
STAIRS = {  # top on the platform edge, foot (blueprint 2b), overall width, roof sections, gate spire tiers, top spire
    "S": dict(top=(-0.3, -102.5), foot=(-5.9, -303.5), W=19.2, sections=10, gate_tiers=9, top_tiers=5, chinthe=9.0),
    "E": dict(top=(110.8, -8.3), foot=(312.9, -26.7), W=27.1 * 0.62, sections=5, gate_tiers=7, top_tiers=5, chinthe=5.5),
    "N": dict(top=(18.4, 175.3), foot=(31.4, 278.7), W=18.3, sections=6, gate_tiers=7, top_tiers=5, chinthe=5.5),
    "W": dict(top=(-100.3, 3.8), foot=(-287.1, 11.8), W=12.2, sections=5, gate_tiers=7, top_tiers=5, chinthe=5.5),
}
SHOP_D = 3.2


def platform_shape():
    return Polygon(OUTLINE).buffer(0)


def build_platform(g):
    plat = platform_shape()
    plinth = Polygon(plinth_poly())
    floor = plat.difference(plinth)
    for k, st in STAIRS.items():
        T, u, v, L = stair_frame(st)
        hw = st["W"] / 2
        corr = Polygon([(T[0] + u[0] * s0 + v[0] * t0, T[1] + u[1] * s0 + v[1] * t0)
                        for s0, t0 in ((0.0, -hw), (L, -hw), (L, hw), (0.0, hw))])
        floor = floor.difference(corr)
    # inlay: two octagon bands + 16 radial strips (low contrast grey-beige, photos: star / octagon bands)
    bands = []
    for a, w in ((60.0, 1.2), (76.0, 1.6)):
        bands.append(Polygon(octagon(a + w / 2)).difference(Polygon(octagon(a - w / 2))))
    for i in range(16):
        ang = TAU * i / 16 + TAU / 32
        strip = sbox(57.0, -0.5, 120.0, 0.5)
        bands.append(affinity.rotate(strip, ang, origin=(0, 0), use_radians=True))
    inlay = unary_union(bands).intersection(floor)
    # keep the inlay off the hall / stupa footprints (they stand on the white marble)
    white = floor.difference(inlay)
    g.capshape("MARBLE", white.buffer(0), 0.0)
    g.capshape("INLAY", inlay.buffer(0), 0.0)
    # retaining wall + parapet; gaps at the stair tops
    pts = ccw(OUTLINE)
    gaps = []
    for k, st in STAIRS.items():
        gaps.append((st["top"], st["W"] / 2 + 0.3))
    n = len(pts)
    for i in range(n):
        p, q = pts[i], pts[(i + 1) % n]
        L = math.dist(p, q)
        ex, ey = (q[0] - p[0]) / L, (q[1] - p[1]) / L
        nx, ny = ey, -ex                       # outward
        spans = [(0.0, L)]
        for (gx, gy), hw in gaps:
            t = (gx - p[0]) * ex + (gy - p[1]) * ey
            d = abs((gx - p[0]) * nx + (gy - p[1]) * ny)
            if d < 3.0 and -hw < t < L + hw:
                new = []
                for a, b in spans:
                    if t + hw <= a or t - hw >= b:
                        new.append((a, b))
                    else:
                        if t - hw > a:
                            new.append((a, t - hw))
                        if t + hw < b:
                            new.append((t + hw, b))
                spans = new
        # the retaining wall runs the whole edge (below the floor); the parapet only on the spans
        zb = min(dem(p[0] + nx * 6, p[1] + ny * 6), dem(q[0] + nx * 6, q[1] + ny * 6), dem((p[0] + q[0]) / 2 + nx * 6, (p[1] + q[1]) / 2 + ny * 6)) - Y0_M - 3.0
        g.wall("WALL", p, q, zb, 0.0)
        for a, b in spans:
            A = (p[0] + ex * a, p[1] + ey * a)
            B = (p[0] + ex * b, p[1] + ey * b)
            Ai = (A[0] - nx * 0.35, A[1] - ny * 0.35)
            Bi = (B[0] - nx * 0.35, B[1] - ny * 0.35)
            g.wall("WALL", A, B, 0.0, 0.9)
            g.wall("WALL", Bi, Ai, 0.0, 0.9)
            g.quad("WALL", (A[0], A[1], 0.9), (B[0], B[1], 0.9), (Bi[0], Bi[1], 0.9), (Ai[0], Ai[1], 0.9))
            g.wall("WALL", Ai, A, 0.0, 0.9)
            g.wall("WALL", B, Bi, 0.0, 0.9)
    return plat


def stair_frame(st):
    T, F = st["top"], st["foot"]
    L = math.dist(T, F)
    u = ((F[0] - T[0]) / L, (F[1] - T[1]) / L)
    v = (-u[1], u[0])
    return T, u, v, L


def stair_profile(st, rise=0.15):
    """floor along the corridor: ground (opened DEM) made monotone and at most 0.6 rise per metre, stepped by `rise`.
    returns steps [(s0, s1, level_m_asl)], the foot level."""
    T, u, v, L = stair_frame(st)
    ds = 1.0
    n = int(L / ds)
    f = []
    cur = Y0_M
    for i in range(n + 1):
        s = i * ds
        h = dem(T[0] + u[0] * s, T[1] + u[1] * s)
        h = min(h, Y0_M)
        cur = min(cur, max(h, cur - 0.6 * ds))
        f.append(cur)
    # stairs start after 2 m of platform-level landing
    steps = []
    lvl = Y0_M
    s0 = 0.0
    for i in range(n + 1):
        s = i * ds
        while f[i] <= lvl - rise and s > 2.0:
            # several steps in one metre: split it
            steps.append((s0, s, lvl))
            s0 = s
            lvl -= rise
            # next step at least 0.3 m deep
            s += 0.3
        if s > s0 + 1e-6 and i == n:
            steps.append((s0, L, lvl))
    # merge: equalize steps that came out in the same metre (tread >= 0.3)
    out = []
    for a, b, l in steps:
        if out and b - a < 0.3:
            pa, pb, pl = out[-1]
            out[-1] = (pa, pb, pl)
            out.append((pb, max(b, pb + 0.3), l))
        else:
            out.append((a, b, l))
    # renormalize positions monotone
    fixed = []
    pos = 0.0
    for a, b, l in out:
        a = max(a, pos)
        b = max(b, a + 0.3)
        fixed.append((a, b, l))
        pos = b
    if fixed[-1][1] < L:
        a, b, l = fixed[-1]
        fixed[-1] = (a, L, l)
    # squeeze into L if it overran
    if fixed[-1][1] > L + 1e-6:
        k = L / fixed[-1][1]
        fixed = [(a * k, b * k, l) for a, b, l in fixed]
    return fixed, fixed[-1][2]


def build_stair(name, st):
    g = G()
    T, u, v, L = stair_frame(st)
    steps, foot = stair_profile(st)
    W = st["W"]
    hw = W / 2
    ws = hw - SHOP_D                                            # half walk width

    def P(s, t, z):                                             # corridor coords -> frame E N, z = m above platform
        return (T[0] + u[0] * s + v[0] * t, T[1] + u[1] * s + v[1] * t, z - Y0_M)

    def floor_at(s):
        for a, b, l in steps:
            if a - 1e-9 <= s <= b + 1e-9:
                return l
        return steps[-1][2]
    # sections: equal lengths; eave = floor at the section's top end + 6.7 (W official 6.7 m high)
    nsec = st["sections"]
    secs = []
    for j in range(nsec):
        a, b = L * j / nsec, L * (j + 1) / nsec
        secs.append((a, b, floor_at(a) + 6.7))
    # breakpoints
    bps = set([0.0, L])
    for a, b, l in steps:
        bps.add(round(a, 4))
        bps.add(round(b, 4))
    for a, b, e in secs:
        bps.add(round(a, 4))
        bps.add(round(b, 4))
    bay = 3.6
    k = 0
    while k * bay < L:
        bps.add(round(k * bay, 4))
        bps.add(round(min(L, k * bay + 2.6), 4))
        k += 1
    B = sorted(x for x in bps if 0.0 <= x <= L)

    def eave_at(s):
        for a, b, e in secs:
            if a - 1e-9 <= s < b - 1e-9:
                return e
        return secs[-1][2]
    for s0, s1 in zip(B, B[1:]):
        if s1 - s0 < 1e-4:
            continue
        sm = (s0 + s1) / 2
        f = floor_at(sm)
        e = eave_at(sm)
        # tread
        g.quad("MARBLE", P(s0, -ws, f), P(s0, ws, f), P(s1, ws, f), P(s1, -ws, f)) if False else None
        a, b, c, d = P(s0, ws, f), P(s0, -ws, f), P(s1, -ws, f), P(s1, ws, f)
        tri = (a, b, c)
        if _normal(*tri)[2] < 0:
            g.quad("MARBLE", a, d, c, b)
        else:
            g.quad("MARBLE", a, b, c, d)
        # shop fronts (inner walls at +-ws, facing the walk): open bay = dark recess panel up to 2.6 m
        in_bay = (sm % bay) < 2.6 and 4.0 < sm < L - 4.0
        for side in (-1, 1):
            p0, p1 = P(s0, side * ws, 0), P(s1, side * ws, 0)
            # facing inward: for side +1 (left of u) the inside is -v
            A_, B_ = ((p0, p1) if side > 0 else (p1, p0))
            zz = [f - Y0_M, f - Y0_M + 2.6, e - Y0_M]
            g.wall("DARK" if in_bay else "WHITE", A_[:2], B_[:2], zz[0], zz[1])
            g.wall("WHITE", A_[:2], B_[:2], zz[1], zz[2])
    # outer walls (white, gilded eave band) and the ceiling: per section and shop bay, not per step
    B2 = sorted(set([round(x, 4) for x in [0.0, L] + [a for a, b, e in secs] + [k_ * bay for k_ in range(int(L / bay) + 1)]
                     if 0.0 <= x <= L]))
    for s0, s1 in zip(B2, B2[1:]):
        if s1 - s0 < 1e-4:
            continue
        sm = (s0 + s1) / 2
        e = eave_at(sm)
        fmin = floor_at(s1 - 1e-6)
        for side in (-1, 1):
            q0, q1 = P(s0, side * hw, 0), P(s1, side * hw, 0)
            zb = min(fmin - 1.0, dem(*q0[:2]) - 1.0, dem(*q1[:2]) - 1.0)
            C_, D_ = ((q1, q0) if side > 0 else (q0, q1))
            g.wall("WHITE", C_[:2], D_[:2], zb - Y0_M, e - Y0_M - 0.7)
            g.wall("GOLDL", C_[:2], D_[:2], e - Y0_M - 0.7, e - Y0_M)
        a, b, c, d = P(s0, -hw, e), P(s1, -hw, e), P(s1, hw, e), P(s0, hw, e)
        if _normal(a, b, c)[2] > 0:
            g.quad("CEIL", a, d, c, b)
        else:
            g.quad("CEIL", a, b, c, d)
    # risers (face down the stairs = +u) at every step start
    prev = Y0_M
    for a, b, l in steps:
        if prev - l > 1e-6:
            A_, B_ = P(a, ws, 0), P(a, -ws, 0)
            nrm = _normal((A_[0], A_[1], l - Y0_M), (B_[0], B_[1], l - Y0_M), (B_[0], B_[1], prev - Y0_M))
            if nrm[0] * u[0] + nrm[1] * u[1] > 0:
                g.wall("MARBLE", A_[:2], B_[:2], l - Y0_M, prev - Y0_M)
            else:
                g.wall("MARBLE", B_[:2], A_[:2], l - Y0_M, prev - Y0_M)
            # the shop zone floors step too: closed by the shop-front walls, nothing to draw
        prev = l
    # columns (red, gilded capitals) along both sides of the walk
    s = 1.8
    while s < L - 1.0:
        f = floor_at(s)
        e = eave_at(s)
        for side in (-1, 1):
            x, y, _ = P(s, side * (ws - 0.7), 0)
            g.column("RED", x, y, f - Y0_M, e - Y0_M - 0.6, 0.25, 6)
            g.column("GOLDL", x, y, e - Y0_M - 0.6, e - Y0_M, 0.33, 6)
        s += 4.0
    # roofs: per section a gable roof along the corridor; end walls where the eave steps down
    for j, (a, b, e) in enumerate(secs):
        ov = 1.0
        a0, b0 = (a - (ov if j == 0 else 0.0)), b + ov * (1 if j == nsec - 1 else 0)
        rh = 3.2
        L1, R1 = P(a0, -(hw + ov), e), P(a0, hw + ov, e)
        L2, R2 = P(b0, -(hw + ov), e), P(b0, hw + ov, e)
        M1, M2 = P(a0, 0, e + rh), P(b0, 0, e + rh)
        for tri4 in ((L1, L2, M2, M1), (R2, R1, M1, M2)):
            n_ = _normal(tri4[0], tri4[1], tri4[2])
            if n_[2] < 0:
                tri4 = tri4[::-1]
            g.quad("ROOF", *tri4)
        # eave soffits (outside the walls)
        for side in (-1, 1):
            o1, o2 = P(a0, side * (hw + ov), e), P(b0, side * (hw + ov), e)
            i1, i2 = P(a0, side * hw, e), P(b0, side * hw, e)
            quad4 = (o1, o2, i2, i1)
            if _normal(*quad4[:3])[2] > 0:
                quad4 = quad4[::-1]
            g.quad("CEIL", *quad4)
        # gilded gable at the downhill end (faces +u), and at the top end of the first section (faces -u)
        for (sx, face) in ((b0, 1),) + (((a0, -1),) if j == 0 else ()):
            A_, B_, C_ = P(sx, -(hw + ov), e), P(sx, hw + ov, e), P(sx, 0, e + rh)
            tri = (A_, B_, C_)
            n_ = _normal(*tri)
            if (n_[0] * u[0] + n_[1] * u[1]) * face < 0:
                tri = (A_, C_, B_)
            g.tri("GOLDL", *tri)
            # gable soffit under the overhang at the ends
        # step-down wall to the next section (faces down the stairs)
        if j < nsec - 1:
            e2 = secs[j + 1][2]
            A_, B_ = P(b, hw, 0), P(b, -hw, 0)
            n_ = _normal((A_[0], A_[1], e2 - Y0_M), (B_[0], B_[1], e2 - Y0_M), (B_[0], B_[1], e - Y0_M))
            if n_[0] * u[0] + n_[1] * u[1] > 0:
                g.wall("WHITE", A_[:2], B_[:2], e2 - Y0_M, e - Y0_M)
            else:
                g.wall("WHITE", B_[:2], A_[:2], e2 - Y0_M, e - Y0_M)
        # tiered spires: top section, gate section, and every third in between (3 tiers)
        tiers = st["top_tiers"] if j == 0 else (st["gate_tiers"] if j == nsec - 1 else (3 if j % 3 == 1 else 0))
        if tiers:
            sm = (a + b) / 2 if j not in (0, nsec - 1) else (a + 6.0 if j == 0 else b - 6.0)
            x, y, _ = P(sm, 0, 0)
            base = e + rh - 0.6
            hh = {3: 7.0, 5: 12.0, 7: 17.0, 9: 22.0}[tiers]
            half = min(hw * 0.55, 5.5)
            yaw = math.atan2(u[1], u[0])
            # a square plinth box on the ridge so the spire sits on something
            g.boxm("GOLDL", x, y, base - Y0_M, half * 1.5, half * 1.5, 0.9, yaw=yaw, top=False)
            pyatthat(g, x, y, base - Y0_M + 0.9, half, half, tiers, hh, yaw=yaw)
    # gate end: open; a gilded portal frame at the foot
    x, y, _ = P(L, 0, 0)
    return g, steps, foot, secs


def build_hill(stair_geo):
    """temporary hill mass (no 1:1 terrain here yet): opened GLO-30 grid, platform cut out, stair corridors carved."""
    E0, E1, N0, N1 = -330.0, 340.0, -340.0, 300.0
    step = 10.0
    plat = platform_shape().buffer(-0.3)
    corr = []
    for name, st in STAIRS.items():
        T, u, v, L = stair_frame(st)
        hw = st["W"] / 2 + 2.0
        corr.append((T, u, v, L, hw, stair_geo[name]))
    nx = int((E1 - E0) / step) + 1
    ny = int((N1 - N0) / step) + 1
    H = np.zeros((ny, nx))
    for j in range(ny):
        for i in range(nx):
            E, N = E0 + i * step, N0 + j * step
            h = min(dem(E, N), Y0_M - 0.6)
            for T, u, v, L, hw, (steps, foot) in corr:
                s = (E - T[0]) * u[0] + (N - T[1]) * u[1]
                t = (E - T[0]) * v[0] + (N - T[1]) * v[1]
                if -2 <= s <= L + 6 and abs(t) <= hw + 6:
                    fl = foot if s >= L else next((l for a, b, l in steps if a <= max(s, 0) <= b), foot)
                    lim = fl - 0.6 + max(0.0, abs(t) - hw) * 0.9
                    h = min(h, lim)
            H[j, i] = h
    g = G()
    for j in range(ny - 1):
        for i in range(nx - 1):
            E, N = E0 + i * step, N0 + j * step
            c = Point(E + step / 2, N + step / 2)
            if plat.contains(sbox(E, N, E + step, N + step)):
                continue
            a = (E, N, H[j, i] - Y0_M)
            b = (E + step, N, H[j, i + 1] - Y0_M)
            cc = (E + step, N + step, H[j + 1, i + 1] - Y0_M)
            d = (E, N + step, H[j + 1, i] - Y0_M)
            g.quad("HILL", a, b, cc, d)
    return g, (E0, N0, step, H)


# ------------------------------------------------------------------ assembly
def plinth_path(offset, n_slots):
    """evenly spaced slots along a smooth octagonal path (the plinth outline at `offset` half-width)."""
    a = offset
    c = offset * 0.49                    # chamfer start (plinth chamfer from 25 at 51.4)
    q = [(0.0, a), (c, a), (a, c), (a, 0.0)]
    poly = mirror4(q)
    # start at the N axis, go clockwise (E): reverse CCW order
    poly = list(reversed(poly))
    i0 = min(range(len(poly)), key=lambda k: math.dist(poly[k], (0.0, a)))
    poly = poly[i0:] + poly[:i0]
    segs = []
    tot = 0.0
    for k in range(len(poly)):
        p, q2 = poly[k], poly[(k + 1) % len(poly)]
        l = math.dist(p, q2)
        segs.append((p, q2, tot, l))
        tot += l
    out = []
    for i in range(n_slots):
        s = tot * i / n_slots
        for p, q2, s0, l in segs:
            if s0 <= s < s0 + l + 1e-9:
                t = (s - s0) / l
                x, y = p[0] + (q2[0] - p[0]) * t, p[1] + (q2[1] - p[1]) * t
                # outward normal of a clockwise path = left of the walking direction
                dx, dy = (q2[0] - p[0]) / l, (q2[1] - p[1]) / l
                nrm = (-dy, dx)
                if nrm[0] * x + nrm[1] * y < 0:
                    nrm = (dy, -dx)
                out.append((x, y, math.atan2(nrm[1], nrm[0])))
                break
    return out


def split_rects(poly, cx, cy, yaw, max_n=4):
    """cover a concave footprint with up to max_n rectangles (largest first), in the frame turned by yaw."""
    P_ = affinity.rotate(affinity.translate(poly, -cx, -cy), -yaw, origin=(0, 0), use_radians=True)
    x0, y0, x1, y1 = P_.bounds
    nx, ny = int(math.ceil(x1 - x0)), int(math.ceil(y1 - y0))
    inner = P_.buffer(-0.3)
    M = np.zeros((ny, nx), dtype=bool)
    for j in range(ny):
        for i in range(nx):
            M[j, i] = inner.contains(Point(x0 + i + 0.5, y0 + j + 0.5))
    total = M.sum()
    out = []
    while len(out) < max_n and M.sum() > 0.12 * total:
        best = (0, None)
        H = np.zeros(nx, dtype=int)
        for j in range(ny):
            H = np.where(M[j], H + 1, 0)
            st = []
            for i in range(nx + 1):
                hcur = H[i] if i < nx else 0
                start = i
                while st and st[-1][1] >= hcur:
                    si, sh = st.pop()
                    area = sh * (i - si)
                    if area > best[0]:
                        best = (area, (si, j - sh + 1, i - si, sh))
                    start = si
                st.append((start, hcur))
        if best[0] < 16:
            break
        i0, j0, w, h = best[1]
        M[j0:j0 + h, i0:i0 + w] = False
        lx, ly = x0 + i0 + w / 2, y0 + j0 + h / 2
        gx, gy = rot(lx, ly, yaw)
        out.append((cx + gx, cy + gy, float(w), float(h)))
    return out


def min_rect(pts):
    P_ = Polygon(pts).minimum_rotated_rectangle
    c = list(P_.exterior.coords)[:4]
    e1 = (c[1][0] - c[0][0], c[1][1] - c[0][1])
    e2 = (c[2][0] - c[1][0], c[2][1] - c[1][1])
    l1, l2 = math.hypot(*e1), math.hypot(*e2)
    cx = sum(p[0] for p in c) / 4
    cy = sum(p[1] for p in c) / 4
    if l1 >= l2:
        yaw = math.atan2(e1[1], e1[0])
        return cx, cy, l1, l2, yaw
    return cx, cy, l2, l1, math.atan2(e2[1], e2[0])


def build_all():
    pieces = {}
    inst = []            # (piece, E, N, U, yaw, scale)
    coll = []            # ("box", E, N, U_centre, sE, sN, sU, yaw) | ("cyl", E, N, U0, U1, r)

    def add(name, g):
        pieces[name] = g

    def put(name, E, N, U=0.0, yaw=0.0, s=1.0):
        inst.append((name, E, N, U, yaw, s))

    # main stupa
    add("Stupa", build_main_stupa())
    put("Stupa", 0, 0)
    # plinth top: 64 + 4
    add("PlinthStupa", small_stupa())
    add("CardinalStupa", cardinal_stupa())
    slots = plinth_path(46.6, 68)
    for k, (x, y, a) in enumerate(slots):
        if k % 17 == 0:
            continue
        put("PlinthStupa", x, y, PLINTH_H, a - math.pi / 2)
    for (x, y) in ((0, 49.0), (49.6, 0), (0, -49.0), (-49.6, 0)):
        put("CardinalStupa", x, y, PLINTH_H, math.atan2(y, x) - math.pi / 2)
    # 62 niche shrines round the foot (front faces out), leaving the 4 bays / adoration halls
    add("NicheShrine", niche_shrine())
    cand = plinth_path(54.4, 640)
    cnr = 54.4 * 0.49
    corners = [(sx * cnr, sy * 54.4) for sx in (-1, 1) for sy in (-1, 1)] + [(sx * 54.4, sy * cnr) for sx in (-1, 1) for sy in (-1, 1)]
    keep = [c for c in cand if min(abs(c[0]), abs(c[1])) > 12.0 and min(math.dist(c[:2], q) for q in corners) > 2.4]
    # take 62 evenly from the free slots (keep holds ~470: no slot is taken twice)
    pick = [keep[int(i * len(keep) / 62 + len(keep) / 124)] for i in range(62)]
    for x, y, a in pick:
        put("NicheShrine", x, y, 0.0, a - math.pi / 2)
    # planetary posts + animals
    add("Post", post_piece())
    animals = {"Sunday": "garuda", "Monday": "tiger", "Tuesday": "lion", "Wednesday": "elephant_tusks",
               "Thursday": "rat", "Friday": "guinea_pig", "Saturday": "naga", "Rahu": "elephant"}
    for kind in set(animals.values()):
        add("Animal_" + kind, animal(kind))
    for p in PLAN["posts"]:
        x, y = p["at"]
        a = math.atan2(y, x) - math.pi / 2
        put("Post", x, y, 0.0, a)
        day = p["name"].split(" ")[0]
        ax, ay = rot(0.0, 0.75, a)
        bx, by = rot(-0.95, 0.0, a)
        put("Animal_" + animals[day], x + ax + bx, y + ay + by, 0.35, a + math.pi / 2)
    # adoration halls (4): 20 x 18 m against the plinth bays, open toward the stairs, 7-tier gilded pyatthat
    halls = G()
    for nm, (cx, cy) in (("S", (1.1, -64.5)), ("E", (63.6, -0.8)), ("N", (1.8, 62.4)), ("W", (-63.8, 1.5))):
        yaw = math.atan2(cy, cx) - math.pi / 2
        # the hall's back sits on the plinth bay face (56 m): depth from the bay out
        hall(halls, cx, cy, yaw, 18.0, 15.0, wall_h=7.5, tiers=7, spire_h=24.0, roof="GOLDL", walls="GOLDL",
             statue=4.2, neck="GREEN")
        coll.append(("box", cx, cy, 0.25, 18.0, 15.0, 0.5, yaw))
    add("PStupa", platform_stupa(False))
    add("PStupaWhite", platform_stupa(True))
    # Naungdawgyi (46 m): the main stupa's round part and terraces scaled (46 / 99.36), its own ring of stupas
    k = 46.0 / 99.36
    ng = G()
    for kk, (hh, z0) in enumerate(TERR):
        A = redent(hh * k)
        B = redent(hh * k - 0.6)
        ng.ring("GOLDL", A, z0 * k, z0 * k + 1.2)
        ng.slope("GOLDL", A, z0 * k + 1.2, B, (z0 + 4.29) * k)
        nxt = redent(TERR[kk + 1][0] * k) if kk < 2 else octagon(DAIS[0][0] * k)
        ng.cap("GOLDL", B, (z0 + 4.29) * k, holes=[nxt])
    ng.ring("GOLDL", redent(51.4 * k), 0.0, 6.13 * k)
    ng.cap("MARBLE", redent(51.4 * k), 6.13 * k, holes=[redent(TERR[0][0] * k)])
    for kk, (a, z0) in enumerate(DAIS):
        A, B = octagon(a * k), octagon((a - 0.9) * k)
        ng.ring("GOLDL", A, z0 * k, (z0 + 1.6) * k)
        ng.slope("GOLDL", A, (z0 + 1.6) * k, B, (z0 + 2.623) * k)
        ng.cap("GOLDL", B, (z0 + 2.623) * k, holes=[octagon(DAIS[kk + 1][0] * k) if kk < 2 else circle(21.2 * k, 48)])
    stupa_round(ng, k, seg=32, details=False)
    add("Naungdawgyi", ng)
    put("Naungdawgyi", 62.7, 127.6, 0.0, math.radians(2.0))
    for x, y, a in plinth_path(21.6, 32):
        if abs(x) < 3 or abs(y) < 3:
            continue
        put("PlinthStupa", 62.7 + x, 127.6 + y, 6.13 * k, a - math.pi / 2, 1.45 * 0.5)
    coll.append(("box", 62.7, 127.6, 3.0 * k, 47.6 * k * 2, 47.6 * k * 2, 6.13 * k, 0.0))
    coll.append(("cyl", 62.7, 127.6, 6.13 * k, 26.87 * k, 19.0 * k))
    coll.append(("cyl", 62.7, 127.6, 26.87 * k, 46.0, 12.0 * k))
    # great bells
    add("BellSingu", bell_piece(2.34, 2.06))
    add("BellTharrawaddy", bell_piece(2.59, 2.34))
    for nm, (cx, cy), oid in (("BellSingu", (-65.9, 95.3), 444334683), ("BellTharrawaddy", (81.3, 80.2), 444334667)):
        b = next(bb for bb in PLAN["buildings"] if bb["osm"] == oid)
        _, _, _, _, yaw = min_rect(b["pts"])
        put(nm, cx, cy, 0.0, yaw)
        coll.append(("box", cx, cy, 0.225, 10.0, 8.4, 0.45, yaw))
    # trees: the 4 corner Bodhi trees big, the rest smaller
    add("Bodhi", bodhi())
    corner = [(96, -97), (-100.3, -96.1), (-87, 78), (91, 109)]
    seen_t = []
    for t in PLAN["trees"]:
        x, y = t
        if any(math.dist((x, y), q) < 9.0 for q in seen_t):
            continue
        seen_t.append((x, y))
        big = min(math.dist((x, y), c) for c in corner) < 6
        s = 1.0 if big else 0.62
        x2, y2 = x, y
        P_ = platform_shape()
        if not P_.buffer(-4.0).contains(Point(x2, y2)):
            # pull inside the platform edge
            pt = P_.buffer(-4.0).exterior.interpolate(P_.buffer(-4.0).exterior.project(Point(x2, y2)))
            x2, y2 = pt.x, pt.y
        put("Bodhi", x2, y2, 0.0, (x * 7 + y) % TAU, s)
        coll.append(("cyl", x2, y2, 0.0, 2.0 * s, 3.2 * s))
    # OSM halls and stupas: fixed things first (posts, adoration halls, bells, trees, Naungdawgyi, the shrine ring,
    # the stair tops), then OSM stupas, then OSM halls (small first); a footprint that would overlap shrinks, or is left out
    fixed = list(HALL_FPS)
    fixed.append(Point(0, 0).buffer(57.5, 32))
    fixed.append(affinity.translate(Polygon(redent(51.4 * 46.0 / 99.36)), 62.7, 127.6).buffer(1.0))
    for p in PLAN["posts"]:
        x, y = p["at"]
        fixed.append(Polygon(rect(x, y, 1.8, 1.5, math.atan2(y, x) - math.pi / 2)))
    for pn, E, N, U, yaw_, s_ in inst:
        if pn == "Bodhi":
            fixed.append(Point(E, N).buffer(3.5 * s_, 12))
        if pn.startswith("Bell"):
            fixed.append(Polygon(rect(E, N, 5.3, 4.5, yaw_)))
    for k_, st in STAIRS.items():
        T, u, v, L = stair_frame(st)
        hw = st["W"] / 2 + 0.5
        fixed.append(Polygon([(T[0] + u[0] * s0 + v[0] * t0, T[1] + u[1] * s0 + v[1] * t0)
                              for s0, t0 in ((-14.0, -hw), (1.0, -hw), (1.0, hw), (-14.0, hw))]))
    plat_in = platform_shape().buffer(-0.6)
    names_skip = {444334660, 444334659, 444334658, 444334650, 117389465, 444334683, 444334667}
    blds = [b for b in PLAN["buildings"] if b["osm"] not in names_skip]
    blds.sort(key=lambda b: (b["tags"].get("man_made") != "stupa", b["area"]))
    skipped = []

    def fit(poly_fn, scale0):
        sc = scale0
        for _ in range(10):
            P_ = poly_fn(sc)
            if plat_in.contains(P_) and not any(P_.intersection(f).area > 0.05 for f in fixed):
                return sc, P_
            sc *= 0.9
        return None, None
    jobs = []
    for b in blds:
        osm_poly = Polygon(b["pts"]).buffer(0)
        cx, cy, Lx, Ly, yaw = min_rect(b["pts"])
        fill = osm_poly.area / max(Lx * Ly, 1e-6)
        if fill < 0.85 and b["tags"].get("man_made") != "stupa":
            # an L / U / courtyard shape: split into the biggest rectangles (1 m raster in the rectangle's frame)
            for k_, (rcx, rcy, rLx, rLy) in enumerate(split_rects(osm_poly, cx, cy, yaw)):
                bb = dict(b)
                bb["_rect"] = (rcx, rcy, rLx, rLy, yaw)
                bb["_main"] = k_ == 0
                jobs.append(bb)
        else:
            bb = dict(b)
            bb["_rect"] = (cx, cy, Lx, Ly, yaw)
            bb["_main"] = True
            jobs.append(bb)
    for b in jobs:
        oid = b["osm"]
        cx, cy, Lx, Ly, yaw = b["_rect"]
        k0 = 1.0
        if b["tags"].get("man_made") == "stupa":
            w0 = min(Lx, Ly)
            sc, P_ = fit(lambda sc: Polygon(rect(cx, cy, w0 * sc / 2, w0 * sc / 2, yaw)), k0)
            if sc is None:
                skipped.append(oid)
                continue
            w = w0 * sc
            fixed.append(P_)
            white = (oid % 5 == 0) or (cx < -20 and cy < -40)      # white shrines mixed in, more on the SW side
            put("PStupaWhite" if white else "PStupa", cx, cy, 0.0, yaw, w)
            coll.append(("box", cx, cy, w * 0.3, w * 0.86, w * 0.86, w * 0.6, yaw))
            continue
        sc, P_ = fit(lambda sc: Polygon(rect(cx, cy, (Lx * sc - 0.4) / 2 + 0.3, (Ly * sc - 0.4) / 2 + 0.3, yaw)), k0)
        if sc is None:
            skipped.append(oid)
            continue
        Lx, Ly = Lx * sc, Ly * sc
        fixed.append(P_)
        area = Lx * Ly
        wall_h = 4.5 if area < 200 else (5.5 if area < 700 else 6.5)
        h = oid % 7
        if area > 900:
            tiers, spire = 5, 14.0
        elif area > 300:
            tiers, spire = (7 if h < 3 else 5), (18.0 if h < 3 else 13.0)
        elif area > 100:
            tiers, spire = (5 if h < 4 else 3), (11.0 if h < 4 else 7.0)
        else:
            tiers, spire = 3, 6.0
        if not b["_main"]:
            tiers, spire = (3, 6.0) if area > 60 else (0, 0.0)
        style_white = h == 5
        # the open front faces away from the stupa
        fy = yaw + (math.pi / 2)
        to_out = math.atan2(cy, cx)
        if math.cos(fy - to_out) < 0:
            fy += math.pi
        hall(halls, cx, cy, fy - math.pi / 2, Lx - 0.4, Ly - 0.4, wall_h=wall_h, tiers=tiers, spire_h=spire,
             roof="ROOF" if not style_white else "GOLDL", walls="WHITE" if style_white or h % 2 == 0 else "RED",
             statue=min(3.5, Ly * 0.25) if b["names"] else 0.0, tier_roof="GOLDL")
        coll.append(("box", cx, cy, (wall_h + 0.5) / 2, Lx - 0.4, Ly - 0.4, wall_h + 0.5, yaw))
    print("OSM footprints left out (no room):", skipped)
    add("Halls", halls)
    # platform + walls
    plat = G()
    build_platform(plat)
    add("Platform", plat)
    # stairways
    sinfo = {}
    for nm, st in STAIRS.items():
        g, steps, foot, secs = build_stair(nm, st)
        add("Stair" + nm, g)
        sinfo[nm] = (steps, foot)
        T, u, v, L = stair_frame(st)
        # chinthe pair at the foot, facing out
        add("Chinthe", chinthe())
        F = st["foot"]
        hw = st["W"] / 2
        sc = st["chinthe"] / 9.0
        a_out = math.atan2(u[1], u[0])
        for side in (-1, 1):
            x = F[0] + u[0] * (4.0 * sc) + v[0] * side * (hw + 3.2 * sc)
            y = F[1] + u[1] * (4.0 * sc) + v[1] * side * (hw + 3.2 * sc)
            gz = dem(x, y) - Y0_M
            put("Chinthe", x, y, min(gz, foot - Y0_M), a_out - math.pi / 2, sc)
            coll.append(("box", x, y, min(gz, foot - Y0_M) + 4.5 * sc, 5.0 * sc, 7.0 * sc, 9.0 * sc, a_out))
        # ramps: through the step nosings, ~8 m segments
        knots = [0.0]
        while knots[-1] < L - 1e-6:
            knots.append(min(L, knots[-1] + 8.0))

        def nose(s):
            for a, b, l in steps:
                if a <= s <= b:
                    return l
            return foot
        ws = hw - SHOP_D
        for s0, s1 in zip(knots, knots[1:]):
            z0, z1 = nose(s0), nose(s1)
            length = math.hypot(s1 - s0, z1 - z0)
            pitch = math.atan2(z1 - z0, s1 - s0)
            cx_ = T[0] + u[0] * (s0 + s1) / 2
            cy_ = T[1] + u[1] * (s0 + s1) / 2
            coll.append(("ramp", cx_, cy_, (z0 + z1) / 2 - Y0_M, length + 0.4, 2 * ws, pitch, a_out))
            for side in (-1, 1):
                coll.append(("ramp", cx_ + v[0] * side * (ws + 0.2), cy_ + v[1] * side * (ws + 0.2), (z0 + z1) / 2 - Y0_M + 2.0,
                             length + 0.4, 0.4, pitch, a_out, 4.0))
    # hill (TEMP)
    hill, hgrid = build_hill(sinfo)
    add("Hill_TEMP", hill)
    # hill trees (instanced, no planter) on the slopes outside the corridors
    add("HillTree", hill_tree())
    E0, N0, step, H = hgrid
    plat_b = platform_shape().buffer(6.0)
    rs = 12345
    count = 0
    for j in range(2, H.shape[0] - 2, 3):
        for i in range(2, H.shape[1] - 2, 3):
            rs = (rs * 1103515245 + 12345) % 2147483648
            jx = (rs % 1000) / 1000.0 * step * 2 - step
            rs = (rs * 1103515245 + 12345) % 2147483648
            jy = (rs % 1000) / 1000.0 * step * 2 - step
            E, N = E0 + i * step + jx, N0 + j * step + jy
            if plat_b.contains(Point(E, N)):
                continue
            ok = True
            for nm, st in STAIRS.items():
                T, u, v, L = stair_frame(st)
                s = (E - T[0]) * u[0] + (N - T[1]) * u[1]
                t = (E - T[0]) * v[0] + (N - T[1]) * v[1]
                if -10 <= s <= L + 25 and abs(t) <= st["W"] / 2 + 9:
                    ok = False
            r = math.hypot(E, N)
            if not ok or r > 320:
                continue
            if (i + j) % 2 == 1 and r > 170:
                continue
            hz = H[j, i] - Y0_M
            slope = abs(H[j, i + 1] - H[j, i - 1]) + abs(H[j + 1, i] - H[j - 1, i])
            if slope < 1.5 and r > 240:
                continue                                       # flat ground far out: streets, leave clear
            put("HillTree", E, N, hz - 0.3, (E * 3 + N) % TAU, 0.8 + (rs % 500) / 1000.0)
            count += 1
    # elevator towers + covered bridges (S, E, N)
    el = G()
    for (tx, ty), (px, py) in (((81.8, -185.6), (81.0, -104.0)), ((172.7, -48.4), (110.6, -45.0)), ((-30.6, 241.6), (-34.0, 172.8))):
        gz = dem(tx, ty) - Y0_M
        el.boxm("WHITE", tx, ty, gz - 1.0, 9.0, 9.0, -gz + 5.0)
        el.boxm("ROOF", tx, ty, 4.0, 10.0, 10.0, 0.5, bottom=True)
        d = math.dist((tx, ty), (px, py))
        yaw = math.atan2(py - ty, px - tx)
        mx, my = (tx + px) / 2, (ty + py) / 2
        L2 = d - 9.0
        ox, oy = rot(4.5 + L2 / 2, 0.0, yaw)
        bx, by = tx + ox, ty + oy
        el.boxm("WHITE", bx, by, -0.8, L2 - 0.05, 4.0, 0.8, yaw, bottom=True)
        el.boxm("WHITE", bx, by, 0.0, L2 - 0.05, 0.25, 1.0, yaw) if False else None
        for side in (-1, 1):
            sx_, sy_ = rot(0.0, side * 1.9, yaw)
            el.boxm("WHITE", bx + sx_, by + sy_, 0.0, L2 - 0.05, 0.2, 1.0, yaw)
            for kk in range(int(L2 / 4)):
                cx2, cy2 = rot(-L2 / 2 + 2 + kk * 4, side * 1.9, yaw)
                el.column("RED", bx + cx2, by + cy2, 1.0, 3.2, 0.12, 6)
        el.boxm("ROOF", bx, by, 3.2, L2 - 0.05, 5.0, 0.35, yaw, bottom=True)
        coll.append(("box", bx, by, -0.4, L2, 4.0, 0.8, yaw))
    add("Elevators", el)
    # collision: platform strips (frame-aligned), plinth, terraces, stupa
    plat_s = platform_shape()
    for N_ in range(-106, 178, 8):
        strip = plat_s.intersection(sbox(-120, N_, 120, N_ + 8))
        if strip.is_empty:
            continue
        x0, y0, x1, y1 = strip.bounds
        coll.append(("box", (x0 + x1) / 2, (y0 + y1) / 2, -1.5, x1 - x0, y1 - y0, 3.0, 0.0))
    coll.append(("box", 0, 0, PLINTH_H / 2, 102.8, 50.0, PLINTH_H, 0.0))
    coll.append(("box", 0, 0, PLINTH_H / 2, 50.0, 102.8, PLINTH_H, 0.0))
    for sx_ in (-1, 1):
        for sy_ in (-1, 1):
            coll.append(("box", sx_ * 36.0, sy_ * 36.0, PLINTH_H / 2, 34.0, 12.0, PLINTH_H, math.atan2(sy_, sx_) + math.pi / 2))
    for hh, z0 in TERR:
        coll.append(("box", 0, 0, z0 + 2.145, 2 * hh * 0.92, 2 * hh * 0.92, 4.29, 0.0))
    coll.append(("cyl", 0, 0, 19.0, 26.87, 27.0))
    coll.append(("cyl", 0, 0, 26.87, 34.24, 20.0))
    coll.append(("cyl", 0, 0, 34.24, 42.0, 14.0))
    coll.append(("cyl", 0, 0, 42.0, 48.24, 10.5))
    coll.append(("cyl", 0, 0, 48.24, 61.44, 7.0))
    coll.append(("cyl", 0, 0, 61.44, 86.06, 3.8))
    for p in PLAN["posts"]:
        x, y = p["at"]
        coll.append(("box", x, y, 0.9, 3.4, 2.8, 1.8, math.atan2(y, x) - math.pi / 2))
    for x, y, a in pick:
        coll.append(("box", x, y, 2.0, 3.0, 3.0, 4.0, a - math.pi / 2))
    return pieces, inst, coll, sinfo, count


def rot_size(a, b):
    return a, b


# ------------------------------------------------------------------ export
def to_studs(p):
    return (p[0] * S, p[2] * S, -p[1] * S)


def export(pieces, inst, coll, sinfo):
    os.makedirs(OUT_GLB, exist_ok=True)
    os.makedirs(OUT_BUILD, exist_ok=True)
    meshes = []        # (name, piece, grp, Mesh)
    for pname in sorted(pieces):
        g = pieces[pname]
        for grp in sorted(g.g):
            tris = g.g[grp]
            for k0 in range(0, len(tris), MAX_TRIS):
                m = Mesh()
                for a, b, c in tris[k0:k0 + MAX_TRIS]:
                    P = [to_studs(a), to_studs(b), to_studs(c)]
                    # box UVs (1 UV = 1 stud) in the piece frame
                    from landmark_glb3d import box_uv
                    m.tri(P[0], P[1], P[2], *box_uv(P), (255, 255, 255))
                if m.T:
                    meshes.append(("SHW_%s_%s_%d" % (pname, grp, k0 // MAX_TRIS + 1), pname, grp, m))
    # split into files of <= 60 meshes
    files = []
    info_all = {}
    for i in range(0, len(meshes), 60):
        path = os.path.join(OUT_GLB, "shw_%d.glb" % (i // 60 + 1))
        info = write_glb(path, [(n, m) for n, _, _, m in meshes[i:i + 60]], generator="shwedagon3d.py")
        info_all.update(info)
        files.append(path)
    mesh_rows = []
    for n, pname, grp, m in meshes:
        inf = info_all[n]
        mesh_rows.append(dict(name=n, piece=pname, grp=grp, c=[round(x, 3) for x in inf["centre"]],
                              s=[round(x, 3) for x in inf["size"]], tris=inf["tris"]))
    place = dict(axis_world=list(geo.world(*AXIS_LL)), y0=Y0_M * S, yaw_deg=17.0, groups=GROUPS, meshes=mesh_rows,
                 inst=[[p, round(E, 3), round(N, 3), round(U, 3), round(yaw, 5), round(s, 4)] for p, E, N, U, yaw, s in inst],
                 coll=[[round(x, 4) if isinstance(x, float) else x for x in c] for c in coll],
                 stairs={k: dict(steps=len(v[0]), foot_m=round(v[1], 2)) for k, v in sinfo.items()},
                 files=[os.path.relpath(f, ROOT) for f in files])
    json.dump(place, open(os.path.join(OUT_BUILD, "place.json"), "w"), indent=0)
    write_data(place)
    return meshes, place


def write_data(place):
    """build/landmarks/shwedagon/ShwData.luau: the placement as one string for ShwedagonPlace.luau."""
    L = ["H|%.3f %.3f %.3f %.3f" % (place["axis_world"][0], place["axis_world"][1], place["y0"], place["yaw_deg"])]
    for k, (mat, var, rgb) in sorted(GROUPS.items()):
        L.append("G|%s|%s|%s|%d %d %d" % (k, mat, var or "-", *rgb))
    for m in place["meshes"]:
        L.append("M|%s|%s|%s|%.3f %.3f %.3f|%.3f %.3f %.3f" % (m["name"], m["piece"], m["grp"], *m["c"], *m["s"]))
    for p_, E, N, U, yaw, sc in place["inst"]:
        L.append("I|%s|%.3f %.3f %.3f %.5f %.4f" % (p_, E, N, U, yaw, sc))
    for c in place["coll"]:
        L.append("C|%s|%s" % (c[0], " ".join("%.4f" % v for v in c[1:])))
    txt = chr(10).join(L)
    out = os.path.join(OUT_BUILD, "ShwData.luau")
    open(out, "w", encoding="utf-8", newline=chr(10)).write("-- generated by shwedagon3d.py" + chr(10) + "return [==[" + chr(10) + txt + chr(10) + "]==]" + chr(10))
    print("data", out, len(txt), "chars")


def stats(pieces, inst, meshes):
    per = {}
    for p, *_ in inst:
        per[p] = per.get(p, 0) + 1
    tot = 0
    rows = []
    for pname, g in sorted(pieces.items()):
        n = per.get(pname, 1 if pname in ("Halls", "Platform", "Hill_TEMP", "Elevators") or pname.startswith("Stair") else 0)
        t = g.ntris()
        tot += t * n
        rows.append((pname, t, n, t * n))
    return rows, tot


def footprint_check(pieces, inst):
    """plan overlaps between things standing on the platform (no part inside another)."""
    from shapely.geometry import MultiPoint
    hulls = {}
    out = []
    for p, E, N, U, yaw, s in inst:
        if abs(U) > 0.5 or p in ("Stupa", "HillTree", "Naungdawgyi") or p.startswith("Animal"):
            continue
        if p not in hulls:
            pts = [(x, y) for grp, tris in pieces[p].g.items() if grp not in ("LEAF", "BARK") for t in tris for (x, y, z) in t if z <= 0.6]
            hulls[p] = MultiPoint(pts).convex_hull
        h = affinity.scale(hulls[p], s, s, origin=(0, 0))
        h = affinity.rotate(h, yaw, origin=(0, 0), use_radians=True)
        out.append((p, affinity.translate(h, E, N)))
    out += [("Hall", h) for h in HALL_FPS]
    out.append(("Naungdawgyi", Polygon(redent(51.4 * 46.0 / 99.36)).buffer(0) if False else affinity.translate(Polygon(redent(51.4 * 46.0 / 99.36)), 62.7, 127.6)))
    bad = []
    for i in range(len(out)):
        for j in range(i + 1, len(out)):
            a = out[i][1].intersection(out[j][1]).area
            if a > 0.2:
                bad.append((out[i][0], out[j][0], round(a, 2), [round(c, 1) for c in out[i][1].centroid.coords[0]],
                            [round(c, 1) for c in out[j][1].centroid.coords[0]]))
    return bad


def world_tris(pieces, inst):
    """every placed triangle in studs in the complex frame (for the flicker test)."""
    from math import cos, sin
    out = []
    per_piece_inst = {}
    for idx, (p, E, N, U, yaw, s) in enumerate(inst):
        per_piece_inst.setdefault(p, []).append((idx, E, N, U, yaw, s))
    for single in ("Halls", "Platform", "Hill_TEMP", "Elevators", "StairS", "StairE", "StairN", "StairW"):
        if single in pieces:
            per_piece_inst.setdefault(single, [(single, 0, 0, 0, 0, 1)])
    for p, lst in per_piece_inst.items():
        g = pieces[p]
        for idx, E, N, U, yaw, s in lst:
            for grp, tris in g.g.items():
                for t in tris:
                    pts = []
                    for (x, y, z) in t:
                        x2, y2 = rot(x * s, y * s, yaw)
                        pts.append(to_studs((x2 + E, y2 + N, z * s + U)))
                    out.append((tuple(pts), (p, idx, grp)))
    return out


if __name__ == "__main__":
    pieces, inst, coll, sinfo, ntrees = build_all()
    meshes, place = export(pieces, inst, coll, sinfo)
    rows, tot = stats(pieces, inst, meshes)
    for r in rows:
        print("%-22s tris %6d x %3d = %7d" % r)
    print("TOTAL placed triangles", tot, "| unique meshes", len(meshes), "| instances", len(inst), "| collision", len(coll),
          "| hill trees", ntrees)
    print("stairs", place["stairs"])
    print("files", place["files"])
    fb = footprint_check(pieces, inst)
    print("footprint overlaps:", len(fb))
    for b in fb:
        print("  ", b)
    if "check" in sys.argv:
        from flicker_check import check
        items = world_tris(pieces, inst)
        print("checking", len(items), "triangles")
        bad, tris = check(items)
        print("flicker pairs:", len(bad))
        from collections import Counter
        C = Counter()
        for i, j, gp, ar in bad:
            C[(tris[i][1][0], tris[i][1][2], tris[j][1][0], tris[j][1][2])] += 1
        for k_, v_ in C.most_common(30):
            print(v_, k_)
        json.dump([[list(tris[i][0]), list(tris[j][0]), tris[i][1], tris[j][1], gp, ar] for i, j, gp, ar in bad[:400]],
                  open(os.path.join(OUT_BUILD, "flicker_pairs.json"), "w"), default=str)
