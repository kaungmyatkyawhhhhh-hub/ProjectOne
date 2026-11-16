"""dt_landmarks.py (2026-11-16, step 6): the downtown (P3) landmarks at 1:1, pure Python.

    python tools/yangon/landmarks3d/dt_landmarks.py city_hall      (from Games/CityLegends)

Each landmark = its real OSM outline (build/landmarks/refs/catalogue/<id>/footprint_osm.geojson) at 3 studs a metre,
real floor heights from the catalogue + photos, walls cut into facade panels by the kit's own primitives (kit.py /
kit_panels.py: arched windows recessed 0.35 m, bands with drips, parapets: already flicker-checked), roofs / towers /
tiered Burmese roofs here, gold finials from the ornament kit (ornament_kit.flame_finial).
Outputs: imports/sync/landmarks/<id>.glb (MeshParts named LOOK_<id>s<k>_<box>, world studs) and
build/landmarks/<id>/place.json (looks, collision boxes, base) -> DowntownPlace.luau in Studio.
No flicker: every scene goes through city/flicker_check.py (same-facing faces < 0.05 studs apart that overlap).
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
CITY = os.path.join(HERE, "..", "city")
sys.path.insert(0, CITY)
sys.path.insert(0, HERE)
os.environ.setdefault("YANGON_SCALE", "1to1")
import numpy as np  # noqa: E402
from shapely.geometry import Polygon  # noqa: E402

import geo  # noqa: E402
import kit as K  # noqa: E402
import kit_panels as KP  # noqa: E402
from glb import Mesh, write_glb, code, check_glb  # noqa: E402
from flicker_check import check  # noqa: E402
from shells import collision  # noqa: E402
import ornament_kit as OK  # noqa: E402

S = 3.0
REFS = os.path.join(ROOT, "build", "landmarks", "refs", "catalogue")
OUT_GLB = os.path.join(ROOT, "imports", "sync", "landmarks")
OUT = os.path.join(ROOT, "build", "landmarks")
MAX_TRIS = 9000

# look per group: Material, rgb, transparency, reflectance, variant, cast shadow, night
LOOKS = {
    "WAL": ("Plaster", (255, 255, 252), 0.0, 0.0, "YgnRenderPainted", True, None),   # white stucco
    "TRM": ("SmoothPlastic", (160, 214, 204), 0.0, 0.0, None, True, None),           # pale teal trim (City Hall)
    "WTR": ("SmoothPlastic", (252, 255, 250), 0.0, 0.0, None, True, None),           # white trim / cornices
    "GLW": ("Glass", (45, 47, 47), 0.0, 0.15, None, True, None),                     # dark window glass
    "GRL": ("Metal", (59, 62, 65), 0.0, 0.0, None, True, None),                      # frames, grilles
    "SHT": ("WoodPlanks", (209, 133, 76), 0.0, 0.0, None, True, None),               # teak shutters
    "STN": ("SmoothPlastic", (100, 96, 88), 0.55, 0.0, None, False, None),           # soft stains
    "STK": ("SmoothPlastic", (62, 60, 56), 0.45, 0.0, None, False, None),            # dark streaks
    "SLB": ("Concrete", (186, 180, 165), 0.0, 0.0, "YgnConcreteBare", False, None),  # flat roofs, slabs
    "ROW": ("SmoothPlastic", (250, 252, 250), 0.0, 0.0, None, True, None),           # white tiered roofs
    "GLD": ("Metal", (226, 222, 245), 0.0, 0.0, "YgnGoldLeaf", True, None),          # gold finials / crests
    "RED": ("SmoothPlastic", (150, 40, 34), 0.0, 0.0, None, True, None),             # red lacquer (ornament fields)
    "JAD": ("Glass", (60, 140, 90), 0.0, 0.2, None, True, None),                     # green glass inlay
    "NIT": ("Neon", (204, 160, 104), 1.0, 0.0, None, False, "night"),                # lit window panes
    "BRK": ("SmoothPlastic", (160, 62, 52), 0.0, 0.0, None, True, None),            # red brick / red-washed walls
    "CRM": ("SmoothPlastic", (232, 210, 150), 0.0, 0.0, None, True, None),           # cream stone bands
    "TER": ("SmoothPlastic", (186, 100, 78), 0.0, 0.0, None, True, None),            # terracotta tile roofs
    "DOM": ("SmoothPlastic", (176, 58, 48), 0.0, 0.0, None, True, None),             # red domes
    "CLK": ("SmoothPlastic", (245, 245, 238), 0.0, 0.0, None, True, None),           # clock faces
    "CRW": ("Plaster", (246, 234, 202), 0.0, 0.0, "YgnRenderPainted", True, None),   # cream-white walls (Strand)
    "TEK": ("WoodPlanks", (110, 70, 40), 0.0, 0.0, None, True, None),                # teak window frames, doors
    "YEL": ("Plaster", (236, 206, 128), 0.0, 0.0, "YgnRenderPainted", True, None),   # ochre-yellow walls
    "GRS": ("Grass", (104, 150, 66), 0.0, 0.0, None, False, None),                   # lawns
    "PAV": ("Pavement", (150, 146, 138), 0.0, 0.0, None, False, None),               # paving
    "MRB": ("SmoothPlastic", (236, 234, 228), 0.0, 0.05, None, False, None),         # marble steps, floors
    "GRT": ("Metal", (70, 130, 96), 0.0, 0.0, None, True, None),                     # green metal roof (Immanuel)
    "SLV": ("Metal", (210, 214, 220), 0.0, 0.1, None, True, None),                   # silver spires
    "BRN": ("CorrodedMetal", (110, 86, 76), 0.0, 0.0, None, True, None),             # brown metal roofs
    "GR1": ("SmoothPlastic", (72, 68, 62), 0.82, 0.0, None, False, None),           # grime (light, mid, heavy)
    "GR2": ("SmoothPlastic", (67, 63, 58), 0.72, 0.0, None, False, None),
    "GR3": ("SmoothPlastic", (60, 56, 52), 0.62, 0.0, None, False, None),
}
# kit.py / kit_panels groups -> our looks
KIT_MAP = {"KWX": "WAL", "KW0": "WTR", "KWG": "WTR", "KGL": "GLW", "KGR": "GRL", "KFR": "GRL", "KST": "STK", "KSU": "STN",
           "KCO": "SLB", "KSH": "SHT", "KSH2": "SHT", "KSH3": "SHT", "KSH4": "SHT", "KSI": "GLW",
           "NWH": "NIT", "NWA": "NIT", "NWY": "NIT", "NWC": "NIT",
           "KGM1": "GR1", "KGM2": "GR2", "KGM3": "GR3"}
OK_MAP = {"G": "GLD", "R": "RED", "J": "JAD", "W": "WTR", "P": "GLD"}


class Scene:
    """triangles by look, world studs (X east, Y up, Z south)"""

    def __init__(self):
        self.g = {}

    def tri(self, look, a, b, c):
        self.g.setdefault(look, []).append((a, b, c))

    def quad(self, look, a, b, c, d):
        self.tri(look, a, b, c)
        self.tri(look, a, c, d)

    def count(self):
        return sum(len(v) for v in self.g.values())


def outline(lid, pick=0):
    d = json.load(open(os.path.join(REFS, lid, "footprint_osm.geojson"), encoding="utf-8"))
    f = d["features"][pick]
    gm = f["geometry"]
    ring = gm["coordinates"][0] if gm["type"] == "Polygon" else gm["coordinates"][0][0]
    P = Polygon(geo.proj(ring)).buffer(0)
    return P.simplify(0.6)


def ground_of(poly):
    st = np.load(os.path.join(ROOT, "build", "city_1to1", "terrain_P3_state.npz"))
    H, org = st["H"], st["origin"]
    ys = []
    for x, z in list(poly.exterior.coords) + [poly.centroid.coords[0]]:
        i, j = int((x - org[0]) / 4), int((z - org[1]) / 4)
        ys.append(float(H[i, j]))
    return min(ys), max(ys)


# ------------------------------------------------------------------------------------------ facades from the kit
def kit_panel(fn, W, seed):
    """run a kit panel builder (metres, panel frame) and return its triangles {kit group: [tri (studs)]}"""
    K.reset(seed)
    K.LIT = 1.0
    h = fn(W)
    return dict(K.g.g), h


def place_panel(sc, tris, A, a_dir, out_dir, base):
    """panel frame (studs: x along, y INTO the building, z up) -> world: A + a*x - out*y, Y = base + z"""
    for grp, lst in tris.items():
        look = KIT_MAP.get(grp)
        if look is None:
            raise KeyError("kit group " + grp)
        for t in lst:
            P = [(A[0] + a_dir[0] * p[0] - out_dir[0] * p[1], base + p[2], A[1] + a_dir[1] * p[0] - out_dir[1] * p[1])
                 for p in t]
            sc.tri(look, *P)


def walls(sc, poly, base, fn_for_edge, seed=1, skip=None):
    """every outline edge (CCW in world X / -Z) gets the facade the builder returns (or a plain wall)"""
    ring = list(poly.exterior.coords)[:-1]
    # CCW in (east, north) = CW in (X, Z): poly in world (X, Z) with Z south; orient so the outside is on the right
    if Polygon(ring).exterior.is_ccw:     # CCW in (X, Z) means CW in (east, north)
        ring = ring[::-1]
    n = len(ring)
    for i in range(n):
        A, B = ring[i], ring[(i + 1) % n]
        L = math.hypot(B[0] - A[0], B[1] - A[1])
        if L < 1.0 or (skip and skip(i, A, B)):
            continue
        a = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
        # outward (X, Z) of a CW-in-(east,north) ring walked A -> B: to the left in (X, Z)
        out = (-a[1], a[0])
        tris, _ = kit_panel(lambda W: fn_for_edge(i, W / S), L, seed * 1000 + i)
        place_panel(sc, tris, A, a, out, base)
    return ring


def rect_window(x, z, w, h, holes, grille=False):
    """a glazed window recessed 0.35 m, a sill in FRONT of the wall only (kit_panels.window's sill reaches 0.06 m into
    the reveal: same-plane overlap once the sill and the wall have different looks)"""
    K.opening(holes, x, z, w, h, 0.0, "KWX", glass="KGL")
    K.front_quad("KFR", x + w / 2 - 0.03, x + w / 2 + 0.03, z, z + h, K.REVEAL - 0.03)
    K.box("KW0", x - 0.05, -0.14, z - 0.1, w + 0.1, 0.14, 0.1, faces=("-y", "top", "+x", "-x"))


# ------------------------------------------------------------------------------------------ roofs and towers
def flat_roof(sc, poly, z, look="SLB"):
    import shapely
    for t in shapely.constrained_delaunay_triangles(poly).geoms:
        c = list(t.exterior.coords)[:3]
        A, B, C = [(p[0], z, p[1]) for p in c]
        nrm = (B[1] - A[1]) * 0  # winding: want +Y normal
        cr = (B[0] - A[0]) * (C[2] - A[2]) - (B[2] - A[2]) * (C[0] - A[0])
        # (X, Z) cross < 0 = counter-clockwise seen from above (Y up, Z south)
        if cr > 0:
            B, C = C, B
        sc.tri(look, A, B, C)


def box_walls(sc, cx, cz, hx, hz, y0, y1, look, yaw=0.0):
    c, s = math.cos(yaw), math.sin(yaw)
    pts = [(cx + c * u - s * v, cz + s * u + c * v) for u, v in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz))]
    for i in range(4):
        p, q = pts[i], pts[(i + 1) % 4]
        quad_wall(sc, look, p, q, y0, y1)
    return pts


def cap4(sc, look, pts, y):
    """the top of a box_walls square (pts CCW in (X, Z)): faces up"""
    A, B, C, D = [(p[0], y, p[1]) for p in pts]
    sc.quad(look, D, C, B, A)


def quad_wall(sc, look, p, q, y0, y1):
    """a vertical quad p -> q (X, Z) seen from the side whose normal is (dz, -dx) rotated... (outside of a ring that is
    clockwise seen from above with Z south)"""
    a, b = (p[0], y0, p[1]), (q[0], y0, q[1])
    c_, d = (q[0], y1, q[1]), (p[0], y1, p[1])
    sc.quad(look, a, d, c_, b)


def tier_roof(sc, cx, cz, w, y0, rise, flare, look="ROW", yaw=0.0, eave_look="WTR"):
    """one tier of a Burmese roof: a hipped frustum from a w x w square (+ flare overhang) up to 0.42 w, a thin eave
    band under it"""
    c, s = math.cos(yaw), math.sin(yaw)

    def P(u, v, y):
        return (cx + c * u - s * v, y, cz + s * u + c * v)
    hb = w / 2 + flare
    ht = w * 0.21
    lo = [P(u, v, y0) for u, v in ((-hb, -hb), (hb, -hb), (hb, hb), (-hb, hb))]
    hi = [P(u, v, y0 + rise) for u, v in ((-ht, -ht), (ht, -ht), (ht, ht), (-ht, ht))]
    for i in range(4):
        j = (i + 1) % 4
        sc.quad(look, lo[i], hi[i], hi[j], lo[j])
    # eave band (0.5 studs) under the overhang, and its soffit
    lo2 = [P(u, v, y0 - 0.5) for u, v in ((-hb, -hb), (hb, -hb), (hb, hb), (-hb, hb))]
    for i in range(4):
        j = (i + 1) % 4
        sc.quad(eave_look, lo2[i], lo[i], lo[j], lo2[j])
    sc.quad(eave_look, lo2[0], lo2[1], lo2[2], lo2[3])
    sc.quad(look, hi[3], hi[2], hi[1], hi[0])        # the tier's top (what the drum stands on)
    return hi


def pyatthat(sc, cx, cz, w, y0, tiers, yaw=0.0, drum=None, look="ROW"):
    """tiered roof: `tiers` shrinking tiers with a short drum between them, a spire and a gold finial"""
    y = y0
    for k in range(tiers):
        rise = w * 0.22
        tier_roof(sc, cx, cz, w, y, rise, w * 0.12, look=look, yaw=yaw)
        y += rise
        w2 = w * 0.62
        dh = drum if drum else w2 * 0.35
        if k < tiers - 1:
            box_walls(sc, cx, cz, w2 * 0.21 + 0.0, w2 * 0.21, y, y + dh, "WAL", yaw)  # drum (inside the tier top)
            y += dh
        w = w2
    # spire + finial
    top = y
    for i in range(6):
        r = w * 0.2 * (1 - i / 6.0) + 0.3
        pts = box_walls(sc, cx, cz, r, r, top, top + w * 0.25, "GLD", yaw)
        top += w * 0.25
        cap4(sc, "GLD", pts, top)
    finial(sc, cx, top, cz, max(1.2, w * 0.12 / S))
    return top


def finial(sc, x, y, z, size_m):
    """ornament kit flame finial (metres), standing at (x, y, z) studs, facing +Z (south) and -Z"""
    p = OK.flame_finial(size_m)
    for grp, a, b, c in p.placed((x / S, -z / S, y / S), (1, 0, 0), (0, -1, 0), (0, 0, 1), 1.0):
        # ornament frame (east, north, up metres) -> world studs
        sc.tri(OK_MAP.get(grp, "GLD"), *[(q[0] * S, q[2] * S, -q[1] * S) for q in (a, b, c)])


def ring_walls(sc, ring, base, fn_for_edge, seed, inward=False):
    """facades on a ring given CW in (X, Z) seen from above (outward on the left); inward=True: the ring is a courtyard,
    the facades face into it"""
    pts = list(ring)
    if Polygon(pts).exterior.is_ccw != inward:
        pts = pts[::-1]
    n = len(pts)
    for i in range(n):
        A, B = pts[i], pts[(i + 1) % n]
        L = math.hypot(B[0] - A[0], B[1] - A[1])
        if L < 1.0:
            continue
        a = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
        out = (-a[1], a[0])
        tris, _ = kit_panel(lambda W: fn_for_edge(i, W / S), L, seed * 1000 + i)
        place_panel(sc, tris, A, a, out, base)


def hip_ring(sc, outer, ridge, inner, y0, rise, over, look="TER", eave="WTR"):
    """a pitched roof over a courtyard block: from the outer walls (eave `over` studs out) up to the ridge and down to
    the courtyard walls (eave `over` studs in); same vertex count on the three rings"""
    o2 = offset_ring(outer, over)
    i2 = offset_ring(inner, -over)
    n = len(outer)
    for k in range(n):
        j = (k + 1) % n
        A, B = (o2[k][0], y0, o2[k][1]), (o2[j][0], y0, o2[j][1])
        C, D = (ridge[j][0], y0 + rise, ridge[j][1]), (ridge[k][0], y0 + rise, ridge[k][1])
        up_quad(sc, look, A, B, C, D)
        E, F = (i2[k][0], y0, i2[k][1]), (i2[j][0], y0, i2[j][1])
        up_quad(sc, look, F, E, D, C)
        # eave fascias and soffits
        A0, B0 = (o2[k][0], y0 - 0.6, o2[k][1]), (o2[j][0], y0 - 0.6, o2[j][1])
        oa, ob = (outer[k][0], y0 - 0.6, outer[k][1]), (outer[j][0], y0 - 0.6, outer[j][1])
        side_quad(sc, eave, A0, B0, B, A)
        down_quad(sc, eave, A0, B0, ob, oa)
        E0, F0 = (i2[k][0], y0 - 0.6, i2[k][1]), (i2[j][0], y0 - 0.6, i2[j][1])
        ia, ib = (inner[k][0], y0 - 0.6, inner[k][1]), (inner[j][0], y0 - 0.6, inner[j][1])
        side_quad(sc, eave, F0, E0, E, F)
        down_quad(sc, eave, F0, E0, ia, ib)


def _nrm(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    return (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])


def up_quad(sc, look, a, b, c, d):
    """a quad whose shown side faces up (winding fixed from its normal)"""
    if _nrm(a, b, c)[1] < 0:
        a, b, c, d = d, c, b, a
    sc.quad(look, a, b, c, d)


def down_quad(sc, look, a, b, c, d):
    if _nrm(a, b, c)[1] > 0:
        a, b, c, d = d, c, b, a
    sc.quad(look, a, b, c, d)


def side_quad(sc, look, a, b, c, d, away=None):
    """a vertical quad facing away from the ring's middle (away = a point inside: the face shows to the other side)"""
    if away is None:
        sc.quad(look, a, b, c, d)
        return
    n = _nrm(a, b, c)
    mx, mz = (a[0] + c[0]) / 2, (a[2] + c[2]) / 2
    if n[0] * (mx - away[0]) + n[2] * (mz - away[1]) < 0:
        a, b, c, d = d, c, b, a
    sc.quad(look, a, b, c, d)


def offset_ring(ring, d):
    """ring (X, Z) pushed out by d studs (in for d < 0), same vertex count (geom3d.offset_poly works CCW in its own
    frame: x east, y north = -Z)"""
    from geom3d import offset_poly
    en = [(p[0], -p[1]) for p in ring]
    if Polygon(en).exterior.is_ccw is False:
        en = en[::-1]
        flip = True
    else:
        flip = False
    o = offset_poly(en, d)
    if flip:
        o = o[::-1]
    return [(p[0], -p[1]) for p in o]


def dome(sc, cx, cz, r, y0, h, look="DOM", n=20, rings=7):
    """a dome (ellipsoid cap) over a circle of radius r at y0, h tall"""
    prev = [(cx + r * math.cos(2 * math.pi * k / n), y0, cz + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    for i in range(1, rings + 1):
        t = i / rings
        rr = r * math.cos(t * math.pi / 2)
        yy = y0 + h * math.sin(t * math.pi / 2)
        cur = [(cx + rr * math.cos(2 * math.pi * k / n), yy, cz + rr * math.sin(2 * math.pi * k / n)) for k in range(n)]
        for k in range(n):
            j = (k + 1) % n
            a, b, c, d = prev[k], prev[j], cur[j], cur[k]
            nm = _nrm(a, b, c)
            mx, mz = (a[0] + b[0]) / 2 - cx, (a[2] + b[2]) / 2 - cz
            if nm[0] * mx + nm[2] * mz + nm[1] * 0.1 < 0:
                a, b, c, d = d, c, b, a
            if i == rings:
                sc.tri(look, a, b, c)
            else:
                sc.quad(look, a, b, c, d)
        prev = cur
    return y0 + h


# ------------------------------------------------------------------------------------------ export
def export(sc, lid):
    os.makedirs(OUT_GLB, exist_ok=True)
    named = []
    k = 0
    for look in sorted(sc.g):
        tris = sc.g[look]
        for st in range(0, len(tris), MAX_TRIS):
            m = Mesh()
            for a, b, c in tris[st:st + MAX_TRIS]:
                m.tri(a, b, c, (0, 0), (0, 0), (0, 0), LOOKS[look][1])
            k += 1
            lo, hi = m.box()
            named.append((code(look, "%ss%d" % (lid.replace("_", ""), k), [(lo[i] + hi[i]) / 2 for i in range(3)],
                               [hi[i] - lo[i] for i in range(3)]), m))
    path = os.path.join(OUT_GLB, lid + ".glb")
    info = write_glb(path, named, generator="dt_landmarks.py")
    n, bad = check_glb(path, info)
    return path, len(named), bad


def flicker(sc):
    items = []
    for look, tris in sc.g.items():
        if LOOKS[look][6] == "night":
            continue
        for t in tris:
            items.append((t, look))
    bad, tris = check(items)
    return bad, tris


def write_place(lid, poly, base, top, extra=None):
    boxes = collision(poly, base - 1.0, top)
    d = dict(id=lid, base=base, looks={k: list(v) for k, v in LOOKS.items()}, collide=boxes, **(extra or {}))
    os.makedirs(os.path.join(OUT, lid), exist_ok=True)
    json.dump(d, open(os.path.join(OUT, lid, "place.json"), "w"), indent=1)


# ------------------------------------------------------------------------------------------ City Hall
def city_hall():
    """Yangon City Hall (1926-36, U Tin): rel/5677100, 119 x 85 m. Photos (catalogue city_hall, all midday): bright
    white stucco, pale teal trim, ground floor arcade of round arches, a tall main floor of deep arched windows with
    teal surrounds, a low attic with square windows; corner pavilions a storey higher under 3-tier white roofs with gold
    finials; the centre of the front (south, facing Maha Bandula Park) rises to a tall 5-tier white-and-gold roof."""
    lid = "city_hall"
    poly = outline(lid)
    g0, g1 = ground_of(poly)
    base = g0
    GF, MF, AT = 5.0, 7.0, 3.6          # ground floor, main floor, attic (m)
    H = GF + MF + AT
    sc = Scene()
    KIT_MAP["KW0"] = "TRM"

    def facade(i, W):
        def fn(Wm):
            n = max(1, int(round(Wm / 4.2)))
            BAY = Wm / n
            holes = []
            for k in range(n):
                x = k * BAY
                KP.col_arch(x + BAY / 2 - 1.1, 0.3, 2.2, GF - 1.6, holes, "KWX", "KSH", None)
                KP.col_arch(x + BAY / 2 - 1.0, GF + 0.6, 2.0, MF - 2.2, holes, "KWX", "KSH", None)
                rect_window(x + BAY / 2 - 0.7, GF + MF + 0.8, 1.4, 1.5, holes)
            KP.band("KW0", Wm, GF - 0.3, 0.3, 0.3)
            KP.band("KW0", Wm, GF + MF - 0.3, 0.3, 0.35)
            for k in range(1, n):
                for z0, z1 in ((0.0, GF - 0.3), (GF, GF + MF - 0.3), (GF + MF, H - 0.45)):
                    K.box("KW0", k * BAY - 0.2, -0.18, z0, 0.4, 0.18, z1 - z0, faces=("-y", "+x", "-x"))
            KP.band("KW0", Wm, H - 0.45, 0.45, 0.5)
            K.facade("KWX", 0.0, Wm, 0.0, H, 0.0, holes)
            KP.stains_light(0.0, Wm, H - 0.45, 0.0, 3.0, 0.3, holes)
            KP.parapet(Wm, H, 1.2, "KWX")
            return H
        return fn(W)
    walls(sc, poly, base, facade, seed=11)
    yH = base + H * S
    flat_roof(sc, poly.buffer(-0.75 * S), yH + 0.15 * S - 0.4)
    # corner pavilions on the corners of the outline's rectangle, inset 2 m: a storey higher, 3-tier roofs
    mr = poly.minimum_rotated_rectangle
    cs = list(mr.exterior.coords)[:4]
    cxm, czm = mr.centroid.x, mr.centroid.y
    e = (cs[1][0] - cs[0][0], cs[1][1] - cs[0][1])
    yaw = math.atan2(e[1], e[0])
    tops = []
    for (x, z) in cs:
        dx, dz = cxm - x, czm - z
        L = math.hypot(dx, dz)
        tx, tz = x + dx / L * 9.0 * S, z + dz / L * 9.0 * S
        w = 9.0 * S
        box_walls(sc, tx, tz, w / 2, w / 2, yH - 1.0, yH + 5.0 * S + 0.1, "WAL", yaw)
        tier_roof(sc, tx, tz, w, yH + 5.0 * S + 0.6, w * 0.2, 1.2 * S, yaw=yaw)
        tops.append(pyatthat(sc, tx, tz, w * 0.62, yH + 5.0 * S + 0.6 + w * 0.2 + 0.4, 2, yaw=yaw))
    # the central tower on the south front (facing the park): the south-most point of the rectangle's long side
    # midpoints, pulled 12 m in
    mids = [((cs[i][0] + cs[(i + 1) % 4][0]) / 2, (cs[i][1] + cs[(i + 1) % 4][1]) / 2) for i in range(4)]
    sm = max(mids, key=lambda p: p[1])          # largest Z = south
    dx, dz = cxm - sm[0], czm - sm[1]
    L = math.hypot(dx, dz)
    tx, tz = sm[0] + dx / L * 12.0 * S, sm[1] + dz / L * 12.0 * S
    w = 18.0 * S
    box_walls(sc, tx, tz, w / 2, w / 2 * 0.8, yH - 1.0, yH + 8.0 * S + 0.1, "WAL", yaw)
    top = pyatthat(sc, tx, tz, w * 0.75, yH + 8.0 * S + 0.6, 5, yaw=yaw)
    tops.append(top)
    KIT_MAP["KW0"] = "WTR"
    dump_preview(lid, sc, base)
    bad, tr = flicker(sc)
    path, nm, badglb = export(sc, lid)
    write_place(lid, poly, base, yH + 1.2 * S)
    print("%s: %d tris, %d meshes, top %.1f studs (%.1f m over the ground), base %.2f, flicker pairs %d"
          % (lid, sc.count(), nm, max(tops), (max(tops) - base) / S, base, len(bad)))
    for i, j, gp, a in bad[:8]:
        print("  ", tr[i][1], tr[j][1], round(gp, 3), [round(v, 1) for v in tr[i][0][0]])
    return sc


def std_facade(levels, bay, cornice=0.45, parapet=1.2, pil=True, band_depth=0.3):
    """facade builder for walls(): levels = [(height m, kind)], kind 'arch' (glazed arched window), 'arcade' (tall open
    arch), 'rect' (glazed window), 'blank'"""
    H = sum(h for h, _ in levels)

    def fn(i, Wm):
        n = max(1, int(round(Wm / bay)))
        BAY = Wm / n
        holes = []
        z = 0.0
        for li, (h, kind) in enumerate(levels):
            for k in range(n):
                x = k * BAY
                if kind == "arch":
                    ww = min(2.0, BAY - 1.0)
                    KP.col_arch(x + BAY / 2 - ww / 2, z + 0.6, ww, max(1.0, h - 1.4 - ww / 2), holes, "KWX", "KSH", None)
                elif kind == "arcade":
                    ww = min(2.4, BAY - 0.9)
                    KP.col_arch(x + BAY / 2 - ww / 2, z, ww, max(1.0, h - 0.9 - ww / 2), holes, "KWX", "KSH", None)
                elif kind == "rect":
                    ww = min(1.5, BAY - 1.0)
                    rect_window(x + BAY / 2 - ww / 2, z + 0.9, ww, max(0.8, h - 1.9), holes)
            if li > 0:
                KP.band("KW0", Wm, z - band_depth, band_depth, band_depth)
            if pil and kind != "blank":
                for k in range(1, n):
                    top = h - (band_depth if li < len(levels) - 1 else cornice)
                    K.box("KW0", k * BAY - 0.2, -0.16, z, 0.4, 0.16, top, faces=("-y", "+x", "-x"))
            z += h
        KP.band("KW0", Wm, H - cornice, cornice, cornice + 0.05)
        K.facade("KWX", 0.0, Wm, 0.0, H, 0.0, holes)
        KP.stains_light(0.0, Wm, H - cornice, 0.0, 3.0, 0.3, holes)
        if parapet:
            KP.parapet(Wm, H, parapet, "KWX")
        return H
    return fn, H


def dump_preview(lid, sc, base):
    """scene dump for preview_pagoda_blend.py (site metres: x east, y north, z up, origin = the scene's middle at base)
    + 2 views (south-west and north-east 3/4 views)"""
    xs = [p[0] for v in sc.g.values() for t in v for p in t]
    zs = [p[2] for v in sc.g.values() for t in v for p in t]
    ys = [p[1] for v in sc.g.values() for t in v for p in t]
    cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    span = max(max(xs) - min(xs), max(zs) - min(zs)) / S
    hgt = (max(ys) - base) / S
    out = {}
    for look, tris in sc.g.items():
        L = LOOKS[look]
        if L[6] == "night":
            continue
        out[look] = dict(rgb=list(L[1]), mat=L[0], variant=L[4], tr=L[2], ds=False,
                         tris=[[[(p[0] - cx) / S, -(p[2] - cz) / S, (p[1] - base) / S] for p in t] for t in tris])
    d = os.path.join(OUT, lid, "preview")
    os.makedirs(d, exist_ok=True)
    json.dump(out, open(os.path.join(d, "scene.json"), "w"))
    r = span * 1.15 + hgt
    views = {"sw": [[-r * 0.7, -r * 0.7, r * 0.45], [0, 0, hgt * 0.3], 35],
             "ne": [[r * 0.7, r * 0.7, r * 0.45], [0, 0, hgt * 0.3], 35]}
    json.dump(views, open(os.path.join(d, "views.json"), "w"))
    return d


def report(lid, sc, base, top):
    dump_preview(lid, sc, base)
    bad, tr = flicker(sc)
    path, nm, badglb = export(sc, lid)
    print("%s: %d tris, %d meshes, top %.1f m over the ground, base %.2f, flicker pairs %d"
          % (lid, sc.count(), nm, (top - base) / S, base, len(bad)))
    for i, j, gp, a_ in bad[:8]:
        print("  ", tr[i][1], tr[j][1], round(gp, 3), [round(v, 1) for v in tr[i][0][0]])
    return len(bad)


def outward_of(poly, A, B):
    """the unit normal of edge A -> B (X, Z) pointing away from the polygon"""
    L = math.hypot(B[0] - A[0], B[1] - A[1])
    a = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
    n = (-a[1], a[0])
    mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    if poly.contains(Polygon([(mx + n[0] * 0.5, mz + n[1] * 0.5), (mx + n[0] * 0.6, mz + n[1] * 0.5),
                              (mx + n[0] * 0.6, mz + n[1] * 0.6)]).centroid):
        n = (-n[0], -n[1])
    return a, n, L


def gable(sc, A, B, y0, rise, out, look="CRW", depth=0.4 * S):
    """a triangular pediment on the wall plane A -> B (X, Z) at y0, `out` = outward unit, `depth` thick"""
    mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
    f = [(A[0] + out[0] * depth, y0, A[1] + out[1] * depth), (B[0] + out[0] * depth, y0, B[1] + out[1] * depth),
         (mx + out[0] * depth, y0 + rise, mz + out[1] * depth)]
    b = [(A[0], y0, A[1]), (B[0], y0, B[1]), (mx, y0 + rise, mz)]
    n = _nrm(*f)
    if n[0] * out[0] + n[2] * out[1] < 0:
        f = [f[1], f[0], f[2]]
    sc.tri(look, *f)
    n = _nrm(*b)
    if n[0] * out[0] + n[2] * out[1] > 0:
        b = [b[1], b[0], b[2]]
    sc.tri(look, *b)
    for p, q in ((0, 2), (2, 1)):
        side_quad(sc, "WTR", b[p], f[p], f[q], b[q], away=(mx - out[0] * 50, mz - out[1] * 50))


def steps(sc, front_a, front_b, out, base, n=5, rise=0.16, run=0.4, look="MRB", away=None):
    """marble steps in front of the edge front_a -> front_b (X, Z), climbing to base + n * rise at the edge"""
    for k in range(n):
        d0 = run * S * (n - k)
        q0 = (front_a[0] + out[0] * d0, front_a[1] + out[1] * d0)
        q1 = (front_b[0] + out[0] * d0, front_b[1] + out[1] * d0)
        y = base + rise * S * (k + 1)
        stp = [front_a, front_b, q1, q0]
        flat_roof(sc, Polygon(stp).buffer(-0.01), y, look)
        side_quad(sc, look, (q1[0], y - rise * S, q1[1]), (q0[0], y - rise * S, q0[1]), (q0[0], y, q0[1]), (q1[0], y, q1[1]),
                  away=away)


def strand_hotel():
    """The Strand Hotel (1901, Sarkies brothers): way/102682120 (60 x 36 m, 3 floors) + the ballroom wing
    way/185858884 (39 x 30 m, 2 floors). Photos (catalogue strand_hotel): cream-white rendered walls, teak-framed
    windows, cornice bands, a flat roof behind a parapet, the entrance on Strand Road (south) up white marble steps
    under a porch with a pediment. The lobby interior (photo 2) is not built yet."""
    lid = "strand_hotel"
    sc = Scene()
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "CRW", "WTR"
    tops = []
    base_all = None
    d = json.load(open(os.path.join(REFS, lid, "footprint_osm.geojson"), encoding="utf-8"))
    for pick, levels in ((0, [(5.0, "rect"), (4.2, "rect"), (4.2, "rect")]), (1, [(5.4, "arch"), (4.6, "rect")])):
        gm = d["features"][pick]["geometry"]
        poly = Polygon(geo.proj(gm["coordinates"][0])).buffer(0).simplify(0.6)
        g0, g1 = ground_of(poly)
        base = g0
        base_all = base if base_all is None else min(base_all, base)
        fn, H = std_facade(levels, 3.6)
        walls(sc, poly, base, fn, seed=31 + pick)
        yH = base + H * S
        flat_roof(sc, poly.buffer(-0.75 * S), yH + 0.15 * S - 0.4)
        tops.append(yH + 1.2 * S)
        if pick == 0:
            hotel, hbase, hH = poly, base, H
            ring = list(poly.exterior.coords)[:-1]
            best = None
            for i in range(len(ring)):
                A, B = ring[i], ring[(i + 1) % len(ring)]
                L = math.hypot(B[0] - A[0], B[1] - A[1])
                if L > 20 * S and (best is None or (A[1] + B[1]) > best[0]):
                    best = ((A[1] + B[1]), A, B)
            _, A, B = best
            a, out, L = outward_of(poly, A, B)
            mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
            pw, pd = 12.0 * S, 4.0 * S
            P0 = (mx - a[0] * pw / 2 + out[0] * 0.3 * S, mz - a[1] * pw / 2 + out[1] * 0.3 * S)
            P1 = (mx + a[0] * pw / 2 + out[0] * 0.3 * S, mz + a[1] * pw / 2 + out[1] * 0.3 * S)
            porch = [P0, P1, (P1[0] + out[0] * pd, P1[1] + out[1] * pd), (P0[0] + out[0] * pd, P0[1] + out[1] * pd)]
            pfn, pH = std_facade([(4.8, "arcade"), (4.2, "rect")], 4.0, parapet=0.0)
            ring_walls(sc, porch, base, lambda i, W: pfn(i, W), 39)
            yP = base + pH * S
            flat_roof(sc, Polygon(porch), yP + 0.02)
            gable(sc, porch[3], porch[2], yP, 2.6 * S, out)
            steps(sc, porch[3], porch[2], out, base, away=(mx, mz))
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    write_place(lid, hotel, hbase, hbase + hH * S)
    return report(lid, sc, base_all, max(tops))


def gable_roof(sc, rect, y0, rise, over, look, axis_long=True):
    """a gable roof over a rectangle (4 corners, X / Z), ridge along the long side, `over` eaves all round; returns
    (ridge ends, the two gable-end edges as (A, B, outward))"""
    c = rect
    l01 = math.dist(c[0], c[1])
    l12 = math.dist(c[1], c[2])
    if (l01 >= l12) != axis_long:
        c = c[1:] + c[:1]
    # c0-c1 and c2-c3 are the long sides; the gable ends are c1-c2 and c3-c0
    cx = sum(p[0] for p in c) / 4
    cz = sum(p[1] for p in c) / 4

    def push(p, d):
        dx, dz = p[0] - cx, p[1] - cz
        L = math.hypot(dx, dz)
        return (p[0] + dx / L * d, p[1] + dz / L * d)
    e = [push(p, over * 1.41) for p in c]
    m12 = ((e[1][0] + e[2][0]) / 2, (e[1][1] + e[2][1]) / 2)
    m30 = ((e[3][0] + e[0][0]) / 2, (e[3][1] + e[0][1]) / 2)
    R1, R0 = (m12[0], y0 + rise, m12[1]), (m30[0], y0 + rise, m30[1])
    E = [(p[0], y0, p[1]) for p in e]
    up_quad(sc, look, E[0], E[1], R1, R0)
    up_quad(sc, look, E[2], E[3], R0, R1)
    # soffits under the eaves (the outline's walls stop at y0)
    down_quad(sc, look, (e[0][0], y0 - 0.02, e[0][1]), (e[1][0], y0 - 0.02, e[1][1]), (e[2][0], y0 - 0.02, e[2][1]),
              (e[3][0], y0 - 0.02, e[3][1]))
    ends = []
    for (i, j) in ((1, 2), (3, 0)):
        A, B = c[i], c[j]
        mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
        dx, dz = mx - cx, mz - cz
        L = math.hypot(dx, dz)
        ends.append((A, B, (dx / L, dz / L)))
    return ends


def spire(sc, cx, cz, half, y0, h, look, yaw=0.0, pins=0, pin_look=None):
    """a square pointed spire (pyramid) with optional corner pinnacles"""
    c, s_ = math.cos(yaw), math.sin(yaw)
    pts = [(cx + c * u - s_ * v, cz + s_ * u + c * v) for u, v in ((-half, -half), (half, -half), (half, half), (-half, half))]
    apex = (cx, y0 + h, cz)
    for i in range(4):
        a, b = pts[i], pts[(i + 1) % 4]
        A, B = (a[0], y0, a[1]), (b[0], y0, b[1])
        n = _nrm(A, B, apex)
        if n[0] * ((a[0] + b[0]) / 2 - cx) + n[2] * ((a[1] + b[1]) / 2 - cz) < 0:
            A, B = B, A
        sc.tri(look, A, B, apex)
    if pins:
        for p in pts:
            q = (cx + (p[0] - cx) * 1.12, cz + (p[1] - cz) * 1.12)
            box_walls(sc, q[0], q[1], half * 0.12, half * 0.12, y0 - 0.5, y0 + h * 0.08, pin_look or look, yaw)
            spire(sc, q[0], q[1], half * 0.12, y0 + h * 0.08, h * 0.22, pin_look or look, yaw)
    return y0 + h


def church(lid, wall, trim, roof, spire_look, towers, levels, tower_w, tower_h, spire_h, front_near, gable_rise,
           clock=False, pins=False, pick=0):
    """a church: the outline's walls (gothic arched windows), a gable roof on its rectangle, towers at the front
    (`towers` = 1: the front corner nearest `front_near`'s side; 2: both front corners), each with a spire"""
    sc = Scene()
    poly = outline(lid, pick)
    g0, g1 = ground_of(poly)
    base = g0
    KIT_MAP["KWX"], KIT_MAP["KW0"] = wall, trim
    fn, H = std_facade(levels, 3.4, parapet=0.0)
    walls(sc, poly, base, fn, seed=hash(lid) % 97)
    yH = base + H * S
    rect = list(poly.minimum_rotated_rectangle.exterior.coords)[:4]
    # the rectangle shrunk 0.4 m so its gable walls stand just inside the outline's walls (no shared planes)
    rc = Polygon(rect).centroid
    rect_in = [(rc.x + (p[0] - rc.x) * 0.985, rc.y + (p[1] - rc.y) * 0.985) for p in rect]
    ends = gable_roof(sc, rect_in, yH + 0.3, gable_rise * S, 0.8 * S, roof)
    # front = the gable end nearest the street point
    ends.sort(key=lambda e: math.dist(((e[0][0] + e[1][0]) / 2, (e[0][1] + e[1][1]) / 2), front_near))
    for k, (A, B, out) in enumerate(ends):
        gable(sc, A, B, yH + 0.3, gable_rise * S - 0.6, out, look=wall, depth=0.3 * S)
    A, B, out = ends[0]
    a = ((B[0] - A[0]) / math.dist(A, B), (B[1] - A[1]) / math.dist(A, B))
    yaw = math.atan2(a[1], a[0])
    tw = tower_w * S
    spots = [A, B] if towers == 2 else [min((A, B), key=lambda p: math.dist(p, front_near))]
    top = yH
    for p in spots:
        # tower centre: the front corner pushed out 1 m in front of the gable wall and 1 m past the side
        side = (p[0] - (A[0] + B[0]) / 2, p[1] - (A[1] + B[1]) / 2)
        sl = math.hypot(*side)
        tx = p[0] + out[0] * (tw / 2 + 1.0 * S) * 0.5 + side[0] / sl * (tw / 2 - tw * 0.2)
        tz = p[1] + out[1] * (tw / 2 + 1.0 * S) * 0.5 + side[1] / sl * (tw / 2 - tw * 0.2)
        c, s_ = math.cos(yaw), math.sin(yaw)
        pts = [(tx + c * u - s_ * v, tz + s_ * u + c * v) for u, v in ((-tw / 2, -tw / 2), (tw / 2, -tw / 2), (tw / 2, tw / 2), (-tw / 2, tw / 2))]
        th = tower_h

        def tface(i, Wm, th=th):
            holes = []
            KP.col_arch(Wm / 2 - 0.8, th - 6.0, 1.6, 3.2, holes, "KWX", "KSH", None)
            KP.col_arch(Wm / 2 - 0.6, H * 0.45, 1.2, 2.4, holes, "KWX", "KSH", None)
            for zz in (H - 0.4, th - 7.0, th - 0.6):
                KP.band("KW0", Wm, zz, 0.4, 0.35)
            K.facade("KWX", 0.0, Wm, 0.0, th, 0.0, holes)
            return th
        ring_walls(sc, pts, base, lambda i, W: tface(i, W), hash(lid) % 89 + len(spots))
        yt = base + th * S
        cap4(sc, "SLB", pts, yt)
        top = max(top, spire(sc, tx, tz, tw * 0.42, yt, spire_h * S, spire_look, yaw, pins=4 if pins else 0, pin_look=spire_look))
        if clock:
            pass
    if clock:
        A, B, out = ends[0]
        mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
        cy = yH + gable_rise * S * 0.45
        r = 1.5 * S
        ax, az = (B[0] - A[0]) / math.dist(A, B), (B[1] - A[1]) / math.dist(A, B)
        ctr = (mx + out[0] * 0.45 * S, cy, mz + out[1] * 0.45 * S)
        rim = [(ctr[0] + ax * r * math.cos(t * math.pi / 8), cy + r * math.sin(t * math.pi / 8), ctr[2] + az * r * math.cos(t * math.pi / 8)) for t in range(16)]
        for k in range(16):
            a_, b_ = rim[k], rim[(k + 1) % 16]
            nm = _nrm(ctr, a_, b_)
            if nm[0] * out[0] + nm[2] * out[1] < 0:
                a_, b_ = b_, a_
            sc.tri("CLK", ctr, a_, b_)
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    write_place(lid, poly, base, yH)
    return report(lid, sc, base, top)


def immanuel_baptist():
    """Immanuel Baptist Church (1885; rebuilt 1952): way/182859345 (34 x 28 m), opposite City Hall, front to Maha
    Bandula Park (south-west). Photos (catalogue immanuel_baptist, 9 h): all white, four storeys of pointed windows on
    the front, two square towers with tall silver spires, a clock in the front gable, a green roof."""
    return church("immanuel_baptist", "WAL", "WTR", "GRT", "SLV", 2, [(5.0, "arch"), (4.0, "arch"), (4.0, "arch")],
                  6.0, 20.0, 14.0, (36223.0, 45617.0), 6.0, clock=True)


def holy_trinity():
    """Holy Trinity Cathedral (1886-94, Robert Chisholm): way/186939481 (53 x 32 m) on Bogyoke Aung San Road. Photos
    (catalogue holy_trinity): salmon-red brick, white trim, steep brown metal roofs, a brick tower at the front corner
    with a white spire and four white pinnacles (about 50 m to the cross)."""
    return church("holy_trinity", "BRK", "WTR", "BRN", "WAL", 1, [(5.5, "arch"), (5.5, "arch")],
                  8.0, 30.0, 18.0, (34500.0, 43000.0), 9.0, pins=True)


def hip_roof_rect(sc, rect, y0, rise, over, look, eave="WTR"):
    """a hipped roof over a rectangle (4 corners X / Z), `over` eaves, ridge along the long side"""
    c = list(rect)
    if math.dist(c[0], c[1]) < math.dist(c[1], c[2]):
        c = c[1:] + c[:1]
    cx = sum(p[0] for p in c) / 4
    cz = sum(p[1] for p in c) / 4

    def push(p, d):
        dx, dz = p[0] - cx, p[1] - cz
        L = math.hypot(dx, dz)
        return (p[0] + dx / L * d, p[1] + dz / L * d)
    e = [push(p, over * 1.41) for p in c]
    short = math.dist(e[1], e[2])
    ax = ((e[1][0] - e[0][0]) / math.dist(e[0], e[1]), (e[1][1] - e[0][1]) / math.dist(e[0], e[1]))
    r0 = (cx - ax[0] * (math.dist(e[0], e[1]) / 2 - short / 2), y0 + rise, cz - ax[1] * (math.dist(e[0], e[1]) / 2 - short / 2))
    r1 = (cx + ax[0] * (math.dist(e[0], e[1]) / 2 - short / 2), y0 + rise, cz + ax[1] * (math.dist(e[0], e[1]) / 2 - short / 2))
    E = [(p[0], y0, p[1]) for p in e]
    up_quad(sc, look, E[0], E[1], r1, r0)
    up_quad(sc, look, E[2], E[3], r0, r1)
    for A, B, R in ((E[1], E[2], r1), (E[3], E[0], r0)):
        n = _nrm(A, B, R)
        if n[1] < 0:
            A, B = B, A
        sc.tri(look, A, B, R)
    down_quad(sc, eave, (e[0][0], y0 - 0.02, e[0][1]), (e[1][0], y0 - 0.02, e[1][1]), (e[2][0], y0 - 0.02, e[2][1]),
              (e[3][0], y0 - 0.02, e[3][1]))


def central_station():
    """Yangon Central Railway Station (1954, Burmese style): way/102685394 (197 x 49 m). Photos (catalogue
    central_station): cream-white walls with rows of arched windows over two storeys, green hipped roofs, four towers
    along the front (Bogyoke Aung San Road side, south) under tall gold multi-tier pyatthat roofs. The station hall
    inside (photographed) is not built yet."""
    lid = "central_station"
    sc = Scene()
    poly = outline(lid)
    g0, g1 = ground_of(poly)
    base = g0
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "CRW", "WTR"
    fn, H = std_facade([(6.0, "arch"), (5.0, "arch")], 3.6, parapet=0.0)
    walls(sc, poly, base, fn, seed=51)
    yH = base + H * S
    rect = list(poly.minimum_rotated_rectangle.exterior.coords)[:4]
    rc = Polygon(rect).centroid
    hip_roof_rect(sc, [(rc.x + (p[0] - rc.x) * 0.99, rc.y + (p[1] - rc.y) * 0.99) for p in rect], yH + 0.3, 5.0 * S,
                  1.2 * S, "GRT")
    # the four towers: along the long side nearest the road (south = larger Z), at 1/8, 3/8, 5/8, 7/8 of its length
    c = rect
    if math.dist(c[0], c[1]) < math.dist(c[1], c[2]):
        c = c[1:] + c[:1]
    sides = [(c[0], c[1]), (c[2], c[3])]
    A, B = max(sides, key=lambda e: e[0][1] + e[1][1])
    L = math.dist(A, B)
    a = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
    inward = (rc.x - (A[0] + B[0]) / 2, rc.y - (A[1] + B[1]) / 2)
    il = math.hypot(*inward)
    inward = (inward[0] / il, inward[1] / il)
    yaw = math.atan2(a[1], a[0])
    tw = 8.0 * S
    top = yH
    for k, f in enumerate((0.16, 0.39, 0.61, 0.84)):
        tx = A[0] + a[0] * L * f + inward[0] * (tw / 2 + 1.0 * S)
        tz = A[1] + a[1] * L * f + inward[1] * (tw / 2 + 1.0 * S)
        hgt = 7.0 if k in (0, 3) else 5.0
        box_walls(sc, tx, tz, tw / 2, tw / 2, yH - 1.0, yH + hgt * S + 0.1, "CRW", yaw)
        top = max(top, pyatthat(sc, tx, tz, tw * 1.05, yH + hgt * S + 0.6, 5 if k in (0, 3) else 4, yaw=yaw, look="GLD"))
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    write_place(lid, poly, base, yH)
    return report(lid, sc, base, top)


def skirt_roof(sc, outer, inner, y0, rise, over, look="TER", top_look="TER", eave="WTR"):
    """a pitched skirt from the outer walls (eaves `over` out) up to the inner ring, flat on top (same vertex count)"""
    o2 = offset_ring(outer, over)
    n = len(outer)
    for k in range(n):
        j = (k + 1) % n
        A, B = (o2[k][0], y0, o2[k][1]), (o2[j][0], y0, o2[j][1])
        C, D = (inner[j][0], y0 + rise, inner[j][1]), (inner[k][0], y0 + rise, inner[k][1])
        up_quad(sc, look, A, B, C, D)
        A0, B0 = (o2[k][0], y0 - 0.6, o2[k][1]), (o2[j][0], y0 - 0.6, o2[j][1])
        oa, ob = (outer[k][0], y0 - 0.6, outer[k][1]), (outer[j][0], y0 - 0.6, outer[j][1])
        side_quad(sc, eave, A0, B0, B, A, away=None)
        down_quad(sc, eave, A0, B0, ob, oa)
    flat_roof(sc, Polygon(inner), y0 + rise, top_look)


def secretariat():
    """The Secretariat (Ministers' Building, 1889-1905): way/264732913 (wings round a 6.5 ha compound). Photos
    (catalogue secretariat): red brick with cream bands, two-three storeys of arched windows and verandah arcades,
    red pitched roofs, square corner towers with small domes (the central cupola fell in the 1930 earthquake)."""
    lid = "secretariat"
    sc = Scene()
    poly = outline(lid).simplify(3.0 * S)
    g0, g1 = ground_of(poly)
    base = g0
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "BRK", "CRM"
    fn, H = std_facade([(5.2, "arcade"), (5.0, "arch"), (4.4, "arch")], 3.6, parapet=0.0)
    outer = list(poly.exterior.coords)[:-1]
    ring_walls(sc, outer, base, lambda i, W: fn(i, W), 61)
    yH = base + H * S
    inner = offset_ring(outer, -7.0 * S)
    skirt_roof(sc, outer, inner, yH + 0.6, 3.5 * S, 0.9 * S)
    # corner towers on the four extreme corners
    top = yH
    picks = [max(outer, key=lambda p: p[0] + p[1]), max(outer, key=lambda p: p[0] - p[1]),
             max(outer, key=lambda p: -p[0] + p[1]), max(outer, key=lambda p: -p[0] - p[1])]
    cx_, cz_ = poly.centroid.x, poly.centroid.y
    for p in picks:
        dx, dz = cx_ - p[0], cz_ - p[1]
        L = math.hypot(dx, dz)
        tw = 7.0 * S
        tx, tz = p[0] + dx / L * tw * 0.45, p[1] + dz / L * tw * 0.45
        th = H + 7.0
        c, s_ = 1.0, 0.0
        pts = [(tx - tw / 2, tz - tw / 2), (tx + tw / 2, tz - tw / 2), (tx + tw / 2, tz + tw / 2), (tx - tw / 2, tz + tw / 2)]
        tfn, _ = std_facade([(H, "blank"), (4.0, "arch"), (3.0, "blank")], 3.5, parapet=0.8)
        ring_walls(sc, pts, base, lambda i, W: tfn(i, W), 62)
        yt = base + (H + 7.0) * S
        cap4(sc, "SLB", pts, yt + 0.15 * S - 0.4 + 0.05)
        top = max(top, dome(sc, tx, tz, tw * 0.38, yt + 0.8 * S + 0.3, 3.0 * S))
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    write_place(lid, poly, base, yH)
    return report(lid, sc, base, top)


def bogyoke_market():
    """Bogyoke Aung San Market (1926): area way/23395611 (187 x 187 m). Photos (catalogue bogyoke_market): long
    two-storey market halls with cream-white walls, arcaded shop fronts, terracotta-red tiled pitched roofs, lanes
    between the halls, a white clock tower with a white dome over the Bogyoke Aung San Road front (south). The halls'
    insides (photographed: jewellery and textile shops) are not built yet: the halls are closed blocks for now."""
    lid = "bogyoke_market"
    sc = Scene()
    area = outline(lid)
    g0, g1 = ground_of(area)
    base = g0
    rect = list(area.minimum_rotated_rectangle.exterior.coords)[:4]
    rc = Polygon(rect).centroid
    # long axis
    c = rect
    if math.dist(c[0], c[1]) < math.dist(c[1], c[2]):
        c = c[1:] + c[:1]
    L = math.dist(c[0], c[1])
    Wd = math.dist(c[1], c[2])
    ax = ((c[1][0] - c[0][0]) / L, (c[1][1] - c[0][1]) / L)
    ay = ((c[2][0] - c[1][0]) / Wd, (c[2][1] - c[1][1]) / Wd)
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "CRW", "WTR"
    fn, H = std_facade([(5.0, "arcade"), (4.4, "arch")], 3.6, parapet=0.0)
    inset, gap, nh = 4.0 * S, 10.0 * S, 4
    hw = (Wd - 2 * inset - (nh - 1) * gap) / nh
    top = base + H * S
    halls = []
    for k in range(nh):
        v0 = inset + k * (hw + gap)
        u0, u1 = inset, L - inset
        P = lambda u, v: (c[0][0] + ax[0] * u + ay[0] * v, c[0][1] + ax[1] * u + ay[1] * v)
        hall = [P(u0, v0), P(u1, v0), P(u1, v0 + hw), P(u0, v0 + hw)]
        halls.append(hall)
        ring_walls(sc, hall, base, lambda i, W: fn(i, W), 70 + k)
        yH = base + H * S
        hc = Polygon(hall).centroid
        ends = gable_roof(sc, [(hc.x + (p[0] - hc.x) * 0.995, hc.y + (p[1] - hc.y) * 0.995) for p in hall], yH + 0.3,
                          5.0 * S, 1.0 * S, "TER")
        for A, B, out in ends:
            gable(sc, A, B, yH + 0.3, 5.0 * S - 0.6, out, look="CRW", depth=0.3 * S)
    # the clock tower: on the south side's middle, in the middle lane
    s_mid = max([((c[0][0] + c[1][0]) / 2, (c[0][1] + c[1][1]) / 2, 0), ((c[2][0] + c[3][0]) / 2, (c[2][1] + c[3][1]) / 2, 1),
                 ((c[1][0] + c[2][0]) / 2, (c[1][1] + c[2][1]) / 2, 2), ((c[3][0] + c[0][0]) / 2, (c[3][1] + c[0][1]) / 2, 3)],
                key=lambda t: t[1])
    dx, dz = rc.x - s_mid[0], rc.y - s_mid[1]
    d = math.hypot(dx, dz)
    tw = 7.0 * S
    tx, tz = s_mid[0] + dx / d * (inset + tw / 2 + 1.0 * S), s_mid[1] + dz / d * (inset + tw / 2 + 1.0 * S)
    # keep it in a lane: snap across the halls to the nearest gap middle
    yaw = math.atan2(ax[1], ax[0])
    pts = [(tx + math.cos(yaw) * u - math.sin(yaw) * v, tz + math.sin(yaw) * u + math.cos(yaw) * v)
           for u, v in ((-tw / 2, -tw / 2), (tw / 2, -tw / 2), (tw / 2, tw / 2), (-tw / 2, tw / 2))]
    tower_poly = Polygon(pts)
    if any(tower_poly.intersects(Polygon(h).buffer(0.5 * S)) for h in halls):
        # move along the halls' cross axis to the middle gap
        mid_gap = inset + (nh // 2) * (hw + gap) - gap / 2
        base_pt = (c[0][0] + ay[0] * mid_gap, c[0][1] + ay[1] * mid_gap)
        # project the tower onto that line
        t = (tx - base_pt[0]) * ax[0] + (tz - base_pt[1]) * ax[1]
        tx, tz = base_pt[0] + ax[0] * t, base_pt[1] + ax[1] * t
        pts = [(tx + math.cos(yaw) * u - math.sin(yaw) * v, tz + math.sin(yaw) * u + math.cos(yaw) * v)
               for u, v in ((-tw / 2, -tw / 2), (tw / 2, -tw / 2), (tw / 2, tw / 2), (-tw / 2, tw / 2))]
    th = 20.0
    tfn, _ = std_facade([(H, "arcade"), (th - H - 4.0, "blank"), (4.0, "arch")], 3.4, parapet=0.9)
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    ring_walls(sc, pts, base, lambda i, W: tfn(i, W), 79)
    yt = base + th * S
    cap4(sc, "SLB", pts, yt + 0.05)
    top = max(top, dome(sc, tx, tz, tw * 0.4, yt + 0.9 * S + 0.3, 3.5 * S, look="WAL"))
    finial(sc, tx, top - 0.3, tz, 1.0)
    write_place(lid, Polygon(halls[0]).union(Polygon(halls[-1])).convex_hull, base, base + H * S,
                extra=dict(halls=halls))
    # collision: one box per hall + the tower (write_place made boxes for the hull: replace them)
    pj = os.path.join(OUT, lid, "place.json")
    d_ = json.load(open(pj))
    boxes = []
    for h in halls + [pts]:
        boxes += collision(Polygon(h), base - 1.0, base + H * S)
    d_["collide"] = boxes
    json.dump(d_, open(pj, "w"), indent=1)
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    return report(lid, sc, base, top)


def cylinder(sc, cx, cz, r, y0, y1, look, n=32, top=True, top_look=None):
    pts = [(cx + r * math.cos(2 * math.pi * k / n), cz + r * math.sin(2 * math.pi * k / n)) for k in range(n)]
    for k in range(n):
        a, b = pts[k], pts[(k + 1) % n]
        side_quad(sc, look, (a[0], y0, a[1]), (b[0], y0, b[1]), (b[0], y1, b[1]), (a[0], y1, a[1]), away=(cx, cz))
    if top:
        for k in range(n):
            a, b = pts[k], pts[(k + 1) % n]
            t = [(cx, y1, cz), (a[0], y1, a[1]), (b[0], y1, b[1])]
            if _nrm(*t)[1] < 0:
                t = [t[0], t[2], t[1]]
            sc.tri(top_look or look, *t)


def mahabandula_park():
    """Maha Bandula Park (park way/129485365) and the Independence Monument (1948): a white obelisk 46 m tall
    (landmarks.json) with five fins round its foot, on a white drum with gold bands (photos: drum about 10 m across and
    7 m tall, a gold band at its foot, middle and top), on a round stepped platform; a paved circle round it. The lawns
    are the terrain's grass; the chinthe statues at the platform (photos) are not built yet."""
    lid = "mahabandula_park"
    sc = Scene()
    cx, cz = geo.world(96.15933, 16.77312)
    st = np.load(os.path.join(ROOT, "build", "city_1to1", "terrain_P3_state.npz"))
    H_, org = st["H"], st["origin"]
    base = 20.4   # the terrain pad under the paved circle (terrain.PILOT_PADS["P3"]: top 20.4, radius 88 studs)
    # paved circle 28 m, 0.2 m over the ground (the terrain dips under its edge are hidden by a 1 m skirt)
    # (the smooth terrain's grass bulges ~2 studs over its set height: the paving stands 1.2 m over the ground)
    cylinder(sc, cx, cz, 28.0 * S, base - 1.0 * S, base + 0.3, "PAV", n=48)
    # 4 steps, 0.18 m each, radii 15 -> 12.5 m
    y = base + 0.3
    for k in range(4):
        r = (15.0 - 0.8 * k) * S
        cylinder(sc, cx, cz, r, y - 0.02, y + 0.18 * S, "MRB", n=48)
        y += 0.18 * S
    # drum: 5 m radius, 7 m tall, gold bands 0.6 m (0.15 m proud) at its foot, middle and top
    yd = y
    cylinder(sc, cx, cz, 5.0 * S, yd - 0.02, yd + 7.0 * S, "WAL", n=40, top=True, top_look="WAL")
    for zb in (0.0, 3.4, 6.4):
        cylinder(sc, cx, cz, 5.15 * S, yd + zb * S, yd + (zb + 0.6) * S, "GLD", n=40, top=zb < 6.0)
    # the obelisk: a square shaft tapering 3.6 m -> 1.4 m over 37 m, a pyramidion to 46 m over the street
    y0 = yd + 7.0 * S
    h_shaft = (46.0 - 7.0 - 0.8) * S - 2.6 * S
    lo, hi = 1.8 * S, 0.7 * S
    for i in range(4):
        a0 = math.pi / 4 + i * math.pi / 2
        a1 = a0 + math.pi / 2
        pa = (cx + lo * 1.414 * math.cos(a0), y0, cz + lo * 1.414 * math.sin(a0))
        pb = (cx + lo * 1.414 * math.cos(a1), y0, cz + lo * 1.414 * math.sin(a1))
        pc = (cx + hi * 1.414 * math.cos(a1), y0 + h_shaft, cz + hi * 1.414 * math.sin(a1))
        pd = (cx + hi * 1.414 * math.cos(a0), y0 + h_shaft, cz + hi * 1.414 * math.sin(a0))
        side_quad(sc, "WAL", pa, pb, pc, pd, away=(cx, cz))
        apex = (cx, y0 + h_shaft + 2.6 * S, cz)
        t = [pd, pc, apex]
        n = _nrm(*t)
        if n[0] * ((pd[0] + pc[0]) / 2 - cx) + n[2] * ((pd[2] + pc[2]) / 2 - cz) < 0:
            t = [pc, pd, apex]
        sc.tri("WAL", *t)
    # five fins round the foot: thin blades 0.5 m thick, 2.2 m out, 9 m tall, pointed
    for k in range(5):
        ang = 2 * math.pi * k / 5 + 0.3
        ux, uz = math.cos(ang), math.sin(ang)
        vx, vz = -uz, ux
        r0 = 1.4 * S
        r1 = 3.4 * S
        th = 0.25 * S
        for sgn in (1, -1):
            A = (cx + ux * r0 + vx * th * sgn, y0, cz + uz * r0 + vz * th * sgn)
            B = (cx + ux * r1 + vx * th * sgn, y0, cz + uz * r1 + vz * th * sgn)
            C = (cx + ux * r0 + vx * th * sgn, y0 + 9.0 * S, cz + uz * r0 + vz * th * sgn)
            t = [A, B, C]
            n = _nrm(*t)
            if (n[0] * vx + n[2] * vz) * sgn < 0:
                t = [A, C, B]
            sc.tri("WAL", *t)
        # the sloped outer edge
        Bp = (cx + ux * r1 + vx * th, y0, cz + uz * r1 + vz * th)
        Bm = (cx + ux * r1 - vx * th, y0, cz + uz * r1 - vz * th)
        Cp = (cx + ux * r0 + vx * th, y0 + 9.0 * S, cz + uz * r0 + vz * th)
        Cm = (cx + ux * r0 - vx * th, y0 + 9.0 * S, cz + uz * r0 - vz * th)
        q = [Bm, Bp, Cp, Cm]
        n = _nrm(q[0], q[1], q[2])
        if n[0] * ux + n[2] * uz < 0:
            q = q[::-1]
        sc.quad("WAL", *q)
    top = y0 + h_shaft + 2.6 * S
    pts = [(cx + 15.0 * S * math.cos(2 * math.pi * k / 24), cz + 15.0 * S * math.sin(2 * math.pi * k / 24)) for k in range(24)]
    write_place(lid, Polygon(pts), base, yd)
    pj = os.path.join(OUT, lid, "place.json")
    d_ = json.load(open(pj))
    d_["collide"] = collision(Polygon(pts), base - 1.0, yd) + [[cx, (yd + y0) / 2, cz, 7.0 * S, y0 - yd, 7.0 * S, 0.0],
                                                             [cx, (y0 + top) / 2, cz, 3.0 * S, top - y0, 3.0 * S, 0.0]]
    json.dump(d_, open(pj, "w"), indent=1)
    return report(lid, sc, base, top)


# ------------------------------------------------------------------------------------------ High Court
def high_court():
    """Former High Court (1905-11, James Ransome): rel/2409553 (113 x 102 m round a courtyard). Photos (catalogue
    high_court): red-washed brick with cream bands and capitals, three storeys of arcades (round arches on every floor,
    the ground and first floor tall, the top floor a lighter loggia), terracotta hipped roofs round the courtyard, a
    clock tower on the north-east corner (Pansodan) with clock faces, corner turrets and a red dome. The OSM outline has
    no courtyard: the wings are taken 18 m deep (photo: about 6 bays of 3 m)."""
    lid = "high_court"
    # (the OSM outline's projecting bays make the courtyard offset self-intersect: simplified to 8 corners, +9% area)
    poly = outline(lid).simplify(12.0 * S)
    g0, g1 = ground_of(poly)
    base = g0
    GF, F1, F2 = 5.2, 5.0, 4.6
    H = GF + F1 + F2
    sc = Scene()
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "BRK", "CRM"

    def facade(i, W):
        n = max(1, int(round(W / 3.6)))
        BAY = W / n
        holes = []
        for k in range(n):
            x = k * BAY
            KP.col_arch(x + BAY / 2 - 1.1, 0.0, 2.2, GF - 1.9, holes, "KWX", "KSH", None)
            KP.col_arch(x + BAY / 2 - 1.0, GF + 0.7, 2.0, F1 - 2.4, holes, "KWX", "KSH", None)
            KP.col_arch(x + BAY / 2 - 0.9, GF + F1 + 0.5, 1.8, F2 - 2.0, holes, "KWX", "KSH", None)
        KP.band("KW0", W, GF - 0.35, 0.35, 0.3)
        KP.band("KW0", W, GF + 0.45, 0.15, 0.12)
        KP.band("KW0", W, GF + F1 - 0.35, 0.35, 0.3)
        KP.band("KW0", W, GF + F1 + 0.3, 0.15, 0.12)
        KP.band("KW0", W, H - 0.5, 0.5, 0.45)
        K.facade("KWX", 0.0, W, 0.0, H, 0.0, holes)
        KP.stains_light(0.0, W, H - 0.5, 0.0, 3.0, 0.4, holes)
        return H

    outer = [p for p in poly.exterior.coords][:-1]
    ridge = offset_ring(outer, -9.0 * S)
    inner = offset_ring(outer, -18.0 * S)
    assert Polygon(inner).is_valid and Polygon(ridge).is_valid, "offsets self-intersect"
    ring_walls(sc, outer, base, lambda i, W: facade(i, W), 21)
    ring_walls(sc, inner, base, lambda i, W: facade(i, W), 22, inward=True)
    yH = base + H * S
    hip_ring(sc, outer, ridge, inner, yH + 0.6, 4.0 * S, 0.9 * S)
    # the clock tower: the outline corner furthest north-east, pushed 2 m out so its faces stand proud of the walls
    cx_, cz_ = poly.centroid.x, poly.centroid.y
    ne = max(outer, key=lambda p: (p[0] - cx_) - (p[1] - cz_))
    dx, dz = ne[0] - cx_, ne[1] - cz_
    L = math.hypot(dx, dz)
    w = 10.0 * S
    tx, tz = ne[0] - dx / L * (w * 0.5 - 2.0 * S), ne[1] - dz / L * (w * 0.5 - 2.0 * S)
    e = (outer[1][0] - outer[0][0], outer[1][1] - outer[0][1])
    yaw = math.atan2(e[1], e[0])
    ytop = yH + 16.0 * S
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "BRK", "CRM"
    c, s_ = math.cos(yaw), math.sin(yaw)
    pts = [(tx + c * u - s_ * v, tz + s_ * u + c * v) for u, v in ((-w / 2, -w / 2), (w / 2, -w / 2), (w / 2, w / 2), (-w / 2, w / 2))]

    def tower_face(i, Wm):
        holes = []
        TH = (ytop - base) / S
        KP.col_arch(Wm / 2 - 1.2, TH - 5.6, 2.4, 3.0, holes, "KWX", "KSH", None)
        for zz in (GF - 0.35, GF + F1 - 0.35, H - 0.5, TH - 6.4, TH - 0.6):
            KP.band("KW0", Wm, zz, 0.35, 0.3)
        K.facade("KWX", 0.0, Wm, 0.0, TH, 0.0, holes)
        return TH
    ring_walls(sc, pts, base, lambda i, W: tower_face(i, W), 23)
    # clock faces: a white disc 3.2 m across on each face, 0.3 m proud, under the belfry arch
    for i in range(4):
        A, B = pts[i], pts[(i + 1) % 4]
        mx, mz = (A[0] + B[0]) / 2, (A[1] + B[1]) / 2
        ax, az = (B[0] - A[0]) / w, (B[1] - A[1]) / w
        ox, oz = az, -ax
        if (mx - tx) * ox + (mz - tz) * oz < 0:
            ox, oz = -ox, -oz
        cy = base + (H + 5.0) * S
        r = 1.6 * S
        ctr = (mx + ox * 0.3 * S, cy, mz + oz * 0.3 * S)
        rim = [(ctr[0] + ax * r * math.cos(t * math.pi / 8), cy + r * math.sin(t * math.pi / 8), ctr[2] + az * r * math.cos(t * math.pi / 8))
               for t in range(16)]
        for k in range(16):
            a_, b_ = rim[k], rim[(k + 1) % 16]
            nm = _nrm(ctr, a_, b_)
            if nm[0] * ox + nm[2] * oz < 0:
                a_, b_ = b_, a_
            sc.tri("CLK", ctr, a_, b_)
    # roof of the tower: a flat slab, a drum and the red dome
    cap4(sc, "SLB", pts, ytop)
    box_walls(sc, tx, tz, w * 0.36, w * 0.36, ytop, ytop + 2.0 * S, "BRK", yaw)
    top = dome(sc, tx, tz, w * 0.42, ytop + 2.0 * S, 4.5 * S)
    finial(sc, tx, top - 0.3, tz, 1.4)
    KIT_MAP["KWX"], KIT_MAP["KW0"] = "WAL", "WTR"
    dump_preview(lid, sc, base)
    bad, tr = flicker(sc)
    path, nm, badglb = export(sc, lid)
    write_place(lid, Polygon(outer), base, yH, extra=dict(courtyard=inner))
    print("%s: %d tris, %d meshes, tower top %.1f m over the ground, base %.2f, flicker pairs %d"
          % (lid, sc.count(), nm, (top - base) / S, base, len(bad)))
    for i, j, gp, a_ in bad[:8]:
        print("  ", tr[i][1], tr[j][1], round(gp, 3), [round(v, 1) for v in tr[i][0][0]])
    return sc


if __name__ == "__main__":
    {"city_hall": city_hall, "high_court": high_court, "strand_hotel": strand_hotel,
     "immanuel_baptist": immanuel_baptist, "holy_trinity": holy_trinity,
     "central_station": central_station, "secretariat": secretariat, "bogyoke_market": bogyoke_market, "mahabandula_park": mahabandula_park}[sys.argv[1] if len(sys.argv) > 1 else "city_hall"]()
