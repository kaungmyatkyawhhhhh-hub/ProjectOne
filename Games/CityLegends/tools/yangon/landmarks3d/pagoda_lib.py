"""pagoda_lib.py (2026-11-16): shared pure-Python pieces for the 1:1 pagoda landmarks (Sule, Botataung).

Model units are METRES (x east, y north, z up, z = 0 at the site's ground); export() turns them into world studs at
geo.SPM (3 studs a metre at YANGON_SCALE=1to1). Every face is wound counter-clockwise seen from the side that shows.

    g = PGeo()                                    # geom3d.Geo plus per-corner normals and lathes
    g.lathe(grp, prof, n, rot)                    # prof = [(a, z)], a = half width ACROSS FLATS (vertex radius a / cos(pi/n))
    g.fan(grp, z, r_in, r_out, h, n)              # the wire "fan" crown of a Burmese stupa (open double-sided frustum)
    export_site(geo, templates, X0, Y0, Z0, out_glb, tag)   # world meshes + template meshes -> .glb (names carry the centre)

Templates (instanced): built in their own local metres; exported once, named "<GRP>_T<name><k>_<centre>_<size>", the
centre in LOCAL studs (Roblox axes: x east, y up, z south). The placer clones them per instance:
CFrame.new(P) * CFrame.Angles(0, yaw, 0) * CFrame.new(centre) * part.CFrame.Rotation.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CITY = os.path.join(os.path.dirname(HERE), "city")
sys.path.insert(0, CITY)
os.environ.setdefault("YANGON_SCALE", "1to1")
import geo  # noqa: E402
from geom3d import Geo, ccw  # noqa: E402
from glb import Mesh, write_glb, code, check_glb  # noqa: E402

SPM = geo.SPM
MAX_TRIS = 9000
WHITE = (255, 255, 255)   # vertex colour: white, so a MaterialVariant is not tinted (P1 trap: medians came out green)

# group -> (Material, Color, Transparency, Reflectance, DoubleSided, CastShadow, MaterialVariant)
# Kaba Aye look pass v2 settled values: gold = Metal + YgnGoldLeaf (226, 222, 245); white SmoothPlastic (255, 255, 250);
# cream SmoothPlastic (236, 219, 148).
LOOK = {
    "GLD": ("Metal", (255, 187, 84), 0, 0, False, True, ""),   # v2: plain Metal, measured photo gold (look_calib)
    "GWF": ("Metal", (255, 187, 84), 0.45, 0, True, False, ""),   # wire fan crowns (see-through)
    "GWR": ("Metal", (255, 187, 84), 0, 0, True, True, ""),       # thin gold plates (vanes, crests)
    "GLT": ("Foil", (230, 160, 50), 0, 0.1, False, True, ""),     # gilded trim / frames
    "GLC": ("Metal", (255, 206, 130), 0, 0, False, False, "YgnGoldPlate"),   # embossed gold panel tiles (corridor)
    "SG5": ("SmoothPlastic", (246, 244, 236), 0, 0, False, True, ""),
    "SG6": ("SmoothPlastic", (226, 112, 34), 0, 0, False, True, ""),
    "AW1": ("SmoothPlastic", (44, 92, 168), 0, 0, True, True, ""),           # canvas awnings
    "AW2": ("SmoothPlastic", (40, 120, 84), 0, 0, True, True, ""),
    "AW3": ("SmoothPlastic", (190, 52, 44), 0, 0, True, True, ""),
    "SHT": ("Metal", (168, 168, 166), 0, 0, False, True, "YgnCorrugatedZinc"),  # roller shutters
    "WD1": ("Wood", (176, 92, 40), 0, 0.05, False, False, ""),       # herringbone parquet, two tones
    "WD2": ("Wood", (146, 72, 30), 0, 0.05, False, False, ""),
    "WHT": ("SmoothPlastic", (255, 255, 250), 0, 0, False, True, ""),
    "CRM": ("SmoothPlastic", (236, 219, 148), 0, 0, False, True, ""),         # yellow-cream tiles (shrines, fence, ring)
    "MAR": ("SmoothPlastic", (236, 234, 228), 0, 0.03, False, False, ""),     # white tiled / marble paving
    "PAV": ("SmoothPlastic", (178, 176, 170), 0, 0, False, False, ""),        # street pavement
    "DRK": ("SmoothPlastic", (52, 44, 38), 0, 0, False, False, ""),           # shop interiors seen through the fronts
    "SG1": ("SmoothPlastic", (186, 40, 36), 0, 0, False, True, ""),           # shop sign boards (plain, no made-up text)
    "SG2": ("SmoothPlastic", (34, 76, 156), 0, 0, False, True, ""),
    "SG3": ("SmoothPlastic", (236, 186, 36), 0, 0, False, True, ""),
    "SG4": ("SmoothPlastic", (34, 124, 74), 0, 0, False, True, ""),
    "BLU": ("SmoothPlastic", (44, 116, 196), 0, 0, False, True, ""),          # Sule ring blue band (photo 1)
    "GLW": ("Glass", (120, 132, 134), 0, 0.2, False, True, ""),               # windows (opaque, no interior)
    "ROF": ("SmoothPlastic", (196, 196, 190), 0, 0, False, False, ""),        # flat roofs
    "TEL": ("SmoothPlastic", (156, 206, 176), 0, 0, False, False, ""),        # mint shrine interiors (photo 10)
    "GRN": ("SmoothPlastic", (58, 112, 84), 0, 0, False, True, ""),           # pyatthat green roof slopes (photo 6)
    "RRF": ("SmoothPlastic", (96, 42, 32), 0, 0, False, True, ""),            # red-brown roofs (pond walkway)
    "RWD": ("SmoothPlastic", (112, 40, 36), 0, 0, False, True, ""),           # maroon walkway cladding / posts
    "YRL": ("SmoothPlastic", (238, 204, 40), 0.25, 0, True, False, ""),       # yellow railing panels (pond walkway)
    "WAT": ("Glass", (62, 96, 58), 0.1, 0.1, False, False, ""),               # green pond water
    "WOD": ("WoodPlanks", (150, 78, 38), 0, 0.05, False, False, ""),          # parquet (Botataung corridor)
    "STL": ("Metal", (150, 150, 152), 0, 0, False, True, ""),
    "CON": ("SmoothPlastic", (168, 166, 158), 0, 0, False, True, ""),         # concrete (jetty, embankment)
    "RED": ("SmoothPlastic", (180, 36, 36), 0, 0, False, True, ""),           # red step edges, red bases
    "GLS": ("Glass", (196, 214, 222), 0.6, 0.1, True, False, ""),             # see-through glass (relic window)
    "FNC": ("DiamondPlate", (214, 176, 70), 0.35, 0, True, False, ""),        # gold grille panels (stupa fence)
    "MOS": ("Foil", (150, 160, 140), 0, 0.2, False, False, ""),               # glass mosaic (relic chamber)
    "ZNC": ("Metal", (70, 120, 140), 0, 0, False, True, "YgnCorrugatedZinc"),  # jetty shed roof
}


class PGeo(Geo):
    """geom3d.Geo with optional per-corner normals (smooth lathes)."""

    def __init__(self):
        super().__init__()
        self.nrm = {}

    def tri(self, grp, a, b, c, normals=None):
        self.g.setdefault(grp, []).append((tuple(a), tuple(b), tuple(c)))
        self.nrm.setdefault(grp, []).append(normals)

    def quad(self, grp, a, b, c, d, normals=None):
        if normals:
            self.tri(grp, a, b, c, (normals[0], normals[1], normals[2]))
            self.tri(grp, a, c, d, (normals[0], normals[2], normals[3]))
        else:
            self.tri(grp, a, b, c)
            self.tri(grp, a, c, d)

    def lathe(self, grp, prof, n, rot=0.0, cx=0.0, cy=0.0, smooth=None, cap_top=True):
        """Surface of revolution through an n-gon section. prof: [(a, z)] bottom to top, a = across-flats half width.
        smooth (default n >= 16): normals across the faces (round). A last point with a > 0 gets a top cap."""
        if smooth is None:
            smooth = n >= 16
        k = 1.0 / math.cos(math.pi / n)
        ang = [rot + 2 * math.pi * i / n for i in range(n)]
        cs = [(math.cos(t), math.sin(t)) for t in ang]
        for j in range(len(prof) - 1):
            (a0, z0), (a1, z1) = prof[j], prof[j + 1]
            r0, r1 = a0 * k, a1 * k
            if abs(r0 - r1) < 1e-9 and abs(z0 - z1) < 1e-9:
                continue
            dr, dz = r1 - r0, z1 - z0
            for i in range(n):
                (c0, s0), (c1, s1) = cs[i], cs[(i + 1) % n]
                A = (cx + r0 * c0, cy + r0 * s0, z0)
                B = (cx + r0 * c1, cy + r0 * s1, z0)
                C = (cx + r1 * c1, cy + r1 * s1, z1)
                D = (cx + r1 * c0, cy + r1 * s0, z1)
                nm = None
                if smooth:
                    def N(c, s):
                        v = (c * dz, s * dz, -dr)
                        L = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2) or 1.0
                        return (v[0] / L, v[1] / L, v[2] / L)
                    nm = (N(c0, s0), N(c1, s1), N(c1, s1), N(c0, s0))
                if r1 < 1e-6:
                    self.tri(grp, A, B, C if r1 > 0 else (cx, cy, z1), nm[:3] if nm else None)
                elif r0 < 1e-6:
                    self.tri(grp, A, C, D, (nm[0], nm[2], nm[3]) if nm else None)
                else:
                    self.quad(grp, A, B, C, D, nm)
        a_end, z_end = prof[-1]
        if cap_top and a_end > 1e-6:
            r = a_end * k
            for i in range(n):
                (c0, s0), (c1, s1) = cs[i], cs[(i + 1) % n]
                self.tri(grp, (cx, cy, z_end), (cx + r * c0, cy + r * s0, z_end), (cx + r * c1, cy + r * s1, z_end))

    def fan(self, grp, z, r_in, r_out, h, n=32):
        """The stupa's wire fan crown: an open frustum flaring out and up (double-sided, see-through group)."""
        for i in range(n):
            t0, t1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            A = (r_in * math.cos(t0), r_in * math.sin(t0), z)
            B = (r_in * math.cos(t1), r_in * math.sin(t1), z)
            C = (r_out * math.cos(t1), r_out * math.sin(t1), z + h)
            D = (r_out * math.cos(t0), r_out * math.sin(t0), z + h)
            self.quad(grp, A, B, C, D)

    def prism(self, grp, poly, z0, z1, top=True, bottom=False, top_grp=None):
        self.ring(grp, poly, z0, z1)
        if top:
            self.cap(top_grp or grp, poly, z1)
        if bottom:
            self.cap(grp, poly, z0, down=True)

    def plate(self, grp, p, q, z0, z1, out, sides=True):
        """A thin plate standing `out` proud of the wall line p -> q (wall outside on the right): front + edges."""
        e = (q[0] - p[0], q[1] - p[1])
        L = math.hypot(*e)
        nx, ny = e[1] / L, -e[0] / L
        P = (p[0] + nx * out, p[1] + ny * out)
        Q = (q[0] + nx * out, q[1] + ny * out)
        self.wall(grp, P, Q, z0, z1)
        if sides:
            self.wall(grp, p, P, z0, z1)
            self.wall(grp, Q, q, z0, z1)
            self.quad(grp, (P[0], P[1], z1), (Q[0], Q[1], z1), (q[0], q[1], z1), (p[0], p[1], z1))
            self.quad(grp, (p[0], p[1], z0), (q[0], q[1], z0), (Q[0], Q[1], z0), (P[0], P[1], z0))

    def count(self):
        return sum(len(v) for v in self.g.values())


def catmull(pts, per=4):
    """Catmull-Rom through (a, z) control points (ends kept), `per` samples per span."""
    out = []
    P = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per):
            t = k / per
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[d]) + (-p0[d] + p2[d]) * t + (2 * p0[d] - 5 * p1[d] + 4 * p2[d] - p3[d]) * t2
                                    + (-p0[d] + 3 * p1[d] - 3 * p2[d] + p3[d]) * t3) for d in range(2)))
    out.append(tuple(pts[-1]))
    return out


def box_uv(P):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = P
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    nx, ny, nz = abs(uy * vz - uz * vy), abs(uz * vx - ux * vz), abs(ux * vy - uy * vx)
    if ny >= nx and ny >= nz:
        return [(p[0], p[2]) for p in P]
    if nx >= nz:
        return [(p[2], -p[1]) for p in P]
    return [(p[0], -p[1]) for p in P]


def _meshes(geo_, to_world, tag):
    named = []
    k = 0
    for grp in sorted(geo_.g):
        if grp not in LOOK:
            raise KeyError("unknown group " + grp)
        tris, nrms = geo_.g[grp], geo_.nrm.get(grp, [None] * len(geo_.g[grp]))
        for start in range(0, len(tris), MAX_TRIS):
            m = Mesh()
            for (a, b, c), nm in zip(tris[start:start + MAX_TRIS], nrms[start:start + MAX_TRIS]):
                P = [to_world(p) for p in (a, b, c)]
                N = [(n[0], n[2], -n[1]) for n in nm] if nm else None
                m.tri(P[0], P[1], P[2], *box_uv(P), WHITE, N)
            if not m.T:
                continue
            k += 1
            lo, hi = m.box()
            c = [(lo[i] + hi[i]) / 2 for i in range(3)]
            s = [hi[i] - lo[i] for i in range(3)]
            named.append((code(grp, "%s%d" % (tag, k), c, s), m))
    return named


def world_fn(X0, Y0, Z0):
    return lambda p: (X0 + p[0] * SPM, Y0 + p[2] * SPM, Z0 - p[1] * SPM)


def local_fn():
    return lambda p: (p[0] * SPM, p[2] * SPM, -p[1] * SPM)


def export_site(geo_, templates, X0, Y0, Z0, out_glb, tag):
    """geo_ in site metres (origin at the site centre, z = 0 at ground) + {name: PGeo} templates -> packs of <= 90 meshes.
    Returns (files, mesh rows)."""
    named = _meshes(geo_, world_fn(X0, Y0, Z0), tag + "s")
    for tname, tg in templates.items():
        named += _meshes(tg, local_fn(), "T" + tname)
    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    files = []
    for i in range(0, len(named), 90):
        path = out_glb if i == 0 else out_glb.replace(".glb", "_%d.glb" % (i // 90 + 1))
        info = write_glb(path, named[i:i + 90], generator="pagoda_lib.py")
        n, bad = check_glb(path, info)
        files.append((path, n, sum(v["tris"] for v in info.values()), bad))
    return files, named


SKIP_FLICKER = ("WD1", "WD2")   # herringbone planks: tiled exactly by construction (area-sum check), O(n^2) here


def flicker(geo_, templates_placed=()):
    """Flicker / overlap test on the model triangles (metres -> studs) with tools/yangon/city/flicker_check.py.
    templates_placed: [(PGeo, x, y, z, yaw)] instances added in site metres. Returns (bad pairs, details)."""
    from flicker_check import check
    items = []
    for grp, tris in geo_.g.items():
        if grp in SKIP_FLICKER:
            continue
        for i, t in enumerate(tris):
            items.append((tuple(tuple(c * SPM for c in p) for p in t), "%s:%d" % (grp, i)))
    for k, (tg, x, y, z, yaw) in enumerate(templates_placed):
        co, si = math.cos(yaw), math.sin(yaw)
        for grp, tris in tg.g.items():
            for i, t in enumerate(tris):
                items.append((tuple(((x + p[0] * co - p[1] * si) * SPM, (y + p[0] * si + p[1] * co) * SPM, (z + p[2]) * SPM)
                                    for p in t), "%s:%d#%d" % (grp, i, k)))
    bad, tris = check(items)
    return bad, tris


def dump_scene(path, geo_, templates, places):
    """Site metres + placed template instances -> {grp: {rgb, mat, tr, ds, variant, tris}} for preview_pagoda_blend.py."""
    import json
    out = {}
    def add(grp, t):
        m, rgb, tr, rf, ds, sh, var = LOOK[grp]
        d = out.setdefault(grp, {"rgb": rgb, "mat": m, "tr": tr, "ds": ds, "variant": var, "tris": []})
        d["tris"].append([[round(c, 3) for c in p] for p in t])
    for grp, tris in geo_.g.items():
        for t in tris:
            add(grp, t)
    for (name, x, y, z, yaw) in places:
        co, si = math.cos(yaw), math.sin(yaw)
        for grp, tris in templates[name].g.items():
            for t in tris:
                add(grp, [(x + p[0] * co - p[1] * si, y + p[0] * si + p[1] * co, z + p[2]) for p in t])
    json.dump(out, open(path, "w"))
