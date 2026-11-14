"""landmark_mc_blend.py: the Myanmar Centre landmark (Myanmar Plaza mall, office towers A / B, Melia Yangon, The Lake Suites,
the corner plinth) modelled in Blender for City Legends' Yangon map (2026-11-14 building pilot).

Run inside Blender (headless works: blender -b --factory-startup --python-expr "exec(open(r'<this>').read()); build()"):
    build(opts)  -> the MC collection (one object per piece; custom prop "kind" F = walls, R = roofs / props)
    views(names, size) -> renders comparison views into build/landmarks/myanmar_centre/views/ (back faces culled, as Roblox)
    dump()       -> build/landmarks/myanmar_centre/mc_tris.json (every triangle: model coords, glTF uv, colour, glow flag)
                    and mc_collide.json (collision boxes, model coords) for landmark_mc_glb.py

Units: 1 Blender unit = 1 stud. Model coords: x = world X - 32600, y = -(world Z + 1350) (north up), z = height above the
model's ground (world Y set in Studio). Plan scale 1.6 studs a metre, heights 12 + 9 a floor (the Yangon map's rule).
Layout: layout_fit.json from landmark_mc_fit.py (real outlines from OSM / lean-corrected satellite roofs, then fitted into
the game's lot between the car-scale roads). Storeys: Wikipedia's list of tallest buildings in Yangon (Myanmar Plaza I / II:
27 floors; Lake Suites: 32 floors); the Melia from its lean band (~80 m). Detail from the 2026-11-14 critique panel (five
lenses against Wikimedia Commons photos of the corner, the west entrance and the towers).
"""
import json
import math
import os

import bpy
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

ROOT = r"D:\ObsidianOne\Claude+Obsidian\Games\CityLegends\build\landmarks\myanmar_centre"
_FIT = os.path.join(ROOT, "layout_fit.json")
LAY = json.load(open(_FIT if os.path.exists(_FIT) else os.path.join(ROOT, "layout.json")))
ATL = json.load(open(os.path.join(ROOT, "mc_atlas.json")))
AW = 1024.0
FULL = {k for k, r in ATL.items() if r[0] == 0 and r[2] == 1024}
GLOW = {"officeA", "officeB", "melia", "resid", "podium", "shop", "screen", "bill0", "bill1", "bill2", "soffit", "lamp",
        "txt_centre", "txt_plaza", "txt_melia", "txt_suites"}
FLOOR = 9.0
SKIRT = -4.0  # every ground-level wall starts this far below the model's ground (hides terrain mismatch)
INSET_PX = 3.0  # UV inset for non-tiling regions (no bleed from a neighbour at small mip levels)
GOLD = 0.6180339887


def ccw(poly):
    a = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % len(poly)]
        a += x0 * y1 - x1 * y0
    return list(poly) if a > 0 else list(reversed(poly))


def uvr(name, fu, fv):
    """Blender UV of a point in a region: fu across (0..1; runs on in full-width rows), fv up (0 = region bottom)."""
    x0, y0, x1, y1 = ATL[name]
    if name in FULL:
        px = x0 + (x1 - x0) * fu
        py = y1 - 0.5 - (y1 - y0 - 1.0) * fv
    else:
        px = x0 + INSET_PX + (x1 - x0 - 2 * INSET_PX) * fu
        py = y1 - INSET_PX - (y1 - y0 - 2 * INSET_PX) * fv
    return (px / AW, 1.0 - py / AW)


def flat(name):
    return uvr(name, 0.5, 0.5)


class Mesh:
    def __init__(self, name, kind="F"):
        self.name, self.kind = name, kind
        self.v, self.f, self.uv, self.col, self.glow = [], [], [], [], []

    def poly(self, pts, uvs, col=(1, 1, 1), glow=False):
        i0 = len(self.v)
        self.v.extend([tuple(p) for p in pts])
        self.f.append(tuple(range(i0, i0 + len(pts))))
        self.uv.append([tuple(u) for u in uvs])
        self.col.append(tuple(min(1.0, c) for c in col))
        self.glow.append(bool(glow))

    def quad(self, a, b, c, d, region, u0, u1, v0=0.0, v1=1.0, col=(1, 1, 1), glow=None):
        g = (region in GLOW) if glow is None else glow
        self.poly([a, b, c, d], [uvr(region, u0, v0), uvr(region, u1, v0), uvr(region, u1, v1), uvr(region, u0, v1)],
                  col, g)

    def flatpoly(self, pts, region="white", col=(1, 1, 1), glow=False):
        self.poly(pts, [flat(region)] * len(pts), col, glow)


MESHES = {}
COLL = []  # collision boxes: (cx, cy, z0, sx, sy, sz, yaw) in model coords, yaw about +z from +x


def mesh(name, kind="F"):
    if name not in MESHES:
        MESHES[name] = Mesh(name, kind)
    return MESHES[name]


def V2(p):
    return Vector((p[0], p[1]))


def outward(poly, i):
    """Outward unit normal of edge i of a CCW polygon (outside is on the right walking p -> q)."""
    p, q = V2(poly[i]), V2(poly[(i + 1) % len(poly)])
    e = (q - p).normalized()
    return Vector((e.y, -e.x))


def wall(m, p, q, za, zb, region, ustuds=76.8, col=(1, 1, 1), glow=None, u_off=0.0, v0=0.0, v1=1.0):
    """One wall strip p -> q (outside on the right walking p -> q) from za to zb."""
    p, q = Vector((p[0], p[1], 0)), Vector((q[0], q[1], 0))
    L = (q - p).length
    if L < 1e-3:
        return
    if region in FULL:
        m.quad((p.x, p.y, za), (q.x, q.y, za), (q.x, q.y, zb), (p.x, p.y, zb), region, u_off, u_off + L / ustuds, v0, v1,
               col, glow)
        return
    nseg = max(1, int(math.ceil(L / ustuds - 1e-6)))
    for k in range(nseg):
        a, b = p.lerp(q, k / nseg), p.lerp(q, (k + 1) / nseg)
        m.quad((a.x, a.y, za), (b.x, b.y, za), (b.x, b.y, zb), (a.x, a.y, zb), region, 0.0, 1.0, v0, v1, col, glow)


def ring(m, poly, za, zb, region, ustuds=76.8, col=(1, 1, 1), glow=None, u_base=0.0, edges=None):
    poly = ccw(poly)
    s = 0.0
    for i in range(len(poly)):
        p, q = poly[i], poly[(i + 1) % len(poly)]
        if edges is None or i in edges:
            wall(m, p, q, za, zb, region, ustuds, col, glow, u_off=u_base + s / ustuds)
        s += math.dist(p, q)


def storeys(m, poly, z0, heights, region, ustuds=76.8, col=(1, 1, 1), glow=None, k0=0, edges=None):
    """Storey rings; each storey's row starts at a different U (golden-ratio steps) so lit windows never line up."""
    z = z0
    for k, h in enumerate(heights):
        ring(m, poly, z, z + h, region, ustuds, col, glow, u_base=((k0 + k) * GOLD) % 1.0, edges=edges)
        z += h
    return z


def cap(m, poly, z, region, col=(1, 1, 1), down=False, glow=False, fit=None, holes=None, flatuv=False):
    poly = ccw(poly)
    loops = [poly] + [list(reversed(ccw(h))) for h in (holes or [])]
    flatpts = [p for lp in loops for p in lp]
    xs, ys = [p[0] for p in flatpts], [p[1] for p in flatpts]
    bx0, bx1, by0, by1 = fit or (min(xs), max(xs), min(ys), max(ys))
    tris = tessellate_polygon([[Vector((x, y, z)) for x, y in lp] for lp in loops])
    for t in tris:
        pts = [flatpts[i] for i in t]
        # make each triangle face up (CCW from above), then flip for a downward face
        a = (pts[1][0] - pts[0][0]) * (pts[2][1] - pts[0][1]) - (pts[1][1] - pts[0][1]) * (pts[2][0] - pts[0][0])
        if a < 0:
            pts = [pts[0], pts[2], pts[1]]
        if down:
            pts = [pts[0], pts[2], pts[1]]
        if flatuv:
            uvs = [flat(region)] * 3
        else:
            uvs = [uvr(region, (x - bx0) / max(bx1 - bx0, 1e-3), (y - by0) / max(by1 - by0, 1e-3)) for x, y in pts]
        m.poly([(x, y, z) for x, y in pts], uvs, col, glow)


def annulus(m, outer, inner, z, region="white", col=(1, 1, 1), down=False):
    """A flat band between two matching CCW loops (same point count), facing up (or down)."""
    outer, inner = ccw(outer), ccw(inner)
    for i in range(len(outer)):
        a, b = outer[i], outer[(i + 1) % len(outer)]
        c, d = inner[(i + 1) % len(inner)], inner[i]
        pts = [(a[0], a[1], z), (b[0], b[1], z), (c[0], c[1], z), (d[0], d[1], z)]
        if down:
            pts = list(reversed(pts))
        m.flatpoly(pts, region, col)


def box(m, c, size, yaw=0.0, region="white", col=(1, 1, 1), top=None, bottom=False, flatuv=True, glow=False):
    """A box turned by yaw about z: c = bottom centre (x, y, z0), size = (along, across, height)."""
    sx, sy, sz = size
    co, si = math.cos(yaw), math.sin(yaw)

    def P(dx, dy):
        return (c[0] + dx * co - dy * si, c[1] + dx * si + dy * co)
    poly = [P(-sx / 2, -sy / 2), P(sx / 2, -sy / 2), P(sx / 2, sy / 2), P(-sx / 2, sy / 2)]
    if flatuv:
        for i in range(4):
            p, q = poly[i], poly[(i + 1) % 4]
            m.flatpoly([(p[0], p[1], c[2]), (q[0], q[1], c[2]), (q[0], q[1], c[2] + sz), (p[0], p[1], c[2] + sz)],
                       region, col, glow)
        cap(m, poly, c[2] + sz, top or region, col, flatuv=(top is None))
        if bottom:
            cap(m, poly, c[2], top or region, col, down=True, flatuv=(top is None))
    else:
        ring(m, poly, c[2], c[2] + sz, region, ustuds=max(sx, sy, 1.0), col=col, glow=glow)
        cap(m, poly, c[2] + sz, top or region, col)
        if bottom:
            cap(m, poly, c[2], top or region, col, down=True)
    return poly


def panel(m, c, w, h, yaw, region, z0, col=(1, 1, 1), depth=0.0, glow=None, both=False):
    """A flat picture panel facing direction yaw (radians from +x): bottom centre c, 'depth' in front of c."""
    nx, ny = math.cos(yaw), math.sin(yaw)
    tx, ty = -ny, nx
    cx, cy = c[0] + nx * depth, c[1] + ny * depth
    a = (cx - tx * w / 2, cy - ty * w / 2)  # the viewer's left
    b = (cx + tx * w / 2, cy + ty * w / 2)  # the viewer's right
    m.quad((a[0], a[1], z0), (b[0], b[1], z0), (b[0], b[1], z0 + h), (a[0], a[1], z0 + h), region, 0, 1, 0, 1, col, glow)
    if both:
        m.quad((b[0], b[1], z0), (a[0], a[1], z0), (a[0], a[1], z0 + h), (b[0], b[1], z0 + h), region, 0, 1, 0, 1, col,
               glow)


def strut(m, a, b, w, col):
    """A square tube from a to b (both 3D Vectors), seen from any side."""
    ax = (b - a).normalized()
    up = Vector((0, 0, 1))
    s1 = ax.cross(up)
    if s1.length < 1e-3:
        s1 = Vector((1, 0, 0))
    s1.normalize()
    s2 = s1.cross(ax).normalized()
    r = w / 2
    pts = [s1 * r + s2 * r, -s1 * r + s2 * r, -s1 * r - s2 * r, s1 * r - s2 * r]
    for i in range(4):
        p0, p1 = pts[i], pts[(i + 1) % 4]
        m.flatpoly([tuple(a + p1), tuple(a + p0), tuple(b + p0), tuple(b + p1)], "white", col)


def offset_poly(poly, d):
    """Polygon pushed out by d (in for d < 0); miter, capped at sharp corners."""
    poly = ccw(poly)
    out = []
    n = len(poly)
    for i in range(n):
        p0, p1, p2 = V2(poly[i - 1]), V2(poly[i]), V2(poly[(i + 1) % n])
        e0, e1 = (p1 - p0).normalized(), (p2 - p1).normalized()
        n0, n1 = Vector((e0.y, -e0.x)), Vector((e1.y, -e1.x))
        nm = n0 + n1
        if nm.length < 1e-6:
            nm = n0
        nm.normalize()
        k = d / max(nm.dot(n0), 0.35)
        out.append((p1.x + nm.x * k, p1.y + nm.y * k))
    return out


def collide_wall(p, q, z0, h, thick=2.0, inward=None):
    """A collision box along p -> q (thick, set inward by thick/2 if an inward normal is given)."""
    p, q = V2(p), V2(q)
    e = q - p
    L = e.length
    if L < 0.5:
        return
    c = (p + q) / 2
    if inward is not None:
        c = c + inward * (thick / 2)
    COLL.append((c.x, c.y, z0, L + thick * 0.5, thick, h, math.atan2(e.y, e.x)))


def collide_poly(poly, z0, h, thick=2.0):
    poly = ccw(poly)
    for i in range(len(poly)):
        n = outward(poly, i)
        collide_wall(poly[i], poly[(i + 1) % len(poly)], z0, h, thick, inward=-n)


def canopy(m, R, p, q, depth, z, thick, fascia_col=(0.92, 0.92, 0.9), columns=0, col_h=None, extend=0.0):
    """A flat canopy along wall edge p -> q (outward = right): top, a glowing soffit, a fascia, columns at the edge."""
    p, q = V2(p), V2(q)
    e = (q - p).normalized()
    n = Vector((e.y, -e.x))
    a, b = p - e * extend, q + e * extend
    outer = [tuple(a), tuple(b), tuple(b + n * depth), tuple(a + n * depth)]
    # outer is CW seen from above (a -> b runs left to right looking at the wall): fix with ccw
    cap(R, [tuple(a + n * 0.05), tuple(b + n * 0.05), tuple(b + n * depth), tuple(a + n * depth)], z + thick, "white",
        col=(0.8, 0.8, 0.78), flatuv=True)
    cap(R, [tuple(a + n * 0.05), tuple(b + n * 0.05), tuple(b + n * depth), tuple(a + n * depth)], z, "soffit",
        down=True, glow=True)
    fo = [tuple(a + n * depth), tuple(b + n * depth)]
    # fascia on the front and both ends
    wall(m, (b + n * depth), (a + n * depth), z, z + thick, "white", ustuds=1e6, col=fascia_col, glow=False) \
        if False else m.flatpoly([(a.x + n.x * depth, a.y + n.y * depth, z), (b.x + n.x * depth, b.y + n.y * depth, z),
                                  (b.x + n.x * depth, b.y + n.y * depth, z + thick),
                                  (a.x + n.x * depth, a.y + n.y * depth, z + thick)][::-1] if n.dot(e.orthogonal()) > 0
                                 else [(a.x + n.x * depth, a.y + n.y * depth, z), (b.x + n.x * depth, b.y + n.y * depth, z),
                                       (b.x + n.x * depth, b.y + n.y * depth, z + thick),
                                       (a.x + n.x * depth, a.y + n.y * depth, z + thick)], "white", fascia_col)
    for end, sgn in ((a, -1), (b, 1)):
        o = end + n * depth
        pts = [(end.x, end.y, z), (o.x, o.y, z), (o.x, o.y, z + thick), (end.x, end.y, z + thick)]
        if sgn > 0:
            pts = [pts[1], pts[0], pts[3], pts[2]]
        m.flatpoly(pts, "white", fascia_col)
    if columns:
        for k in range(columns):
            t = (k + 0.5) / columns
            c = a.lerp(b, t) + n * (depth - 1.2)
            box(m, (c.x, c.y, SKIRT), (1.4, 1.4, (col_h or z) - SKIRT), math.atan2(e.y, e.x), col=(0.24, 0.24, 0.26))
            COLL.append((c.x, c.y, 0.0, 1.4, 1.4, col_h or z, math.atan2(e.y, e.x)))


# ------------------------------------------------------------------------------------------------------------------------
def edge_facing(poly, direction, min_len=8.0, tol=0.85):
    """The longest edge of a CCW poly whose outward normal points along direction (dot > tol)."""
    best = None
    for i in range(len(poly)):
        p, q = V2(poly[i]), V2(poly[(i + 1) % len(poly)])
        L = (q - p).length
        if L < min_len:
            continue
        nn = outward(poly, i)
        if nn.dot(direction) > tol and (best is None or L > best[2]):
            best = (p, q, L, nn, i)
    return best


def build_podium():
    pod = ccw([tuple(p) for p in LAY["podium"]])
    F = mesh("pod")
    R = mesh("podR", "R")
    inner = offset_poly(pod, -2.0)
    # skirt, ground-floor shops set 2 back under the first floor, four mall storeys of beige granite + glass
    ring(F, pod, SKIRT, 0.0, "concrete", ustuds=40.0, col=(0.5, 0.48, 0.46), glow=False)
    ring(F, inner, 0.0, 14.0, "shop", ustuds=64.0)
    annulus(R, pod, inner, 14.0, "soffit", down=True)
    z = storeys(F, pod, 14.0, [12.0, 12.0, 12.0, 12.0], "podium", ustuds=76.8)
    ring(F, pod, z, z + 4.0, "crown", ustuds=76.8, glow=False)
    top = z + 4.0
    roof_in = offset_poly(pod, -1.2)
    annulus(R, pod, roof_in, top, "white", col=(0.8, 0.78, 0.74))
    ring(R, list(reversed(roof_in)), top - 1.0, top, "white", ustuds=1e6, col=(0.72, 0.7, 0.66), glow=False)
    cap(R, roof_in, top - 1.0, "concrete")
    collide_poly(pod, 0.0, top)
    return pod, top


def build_front(pod, top):
    """The corner front (p3): a dark screen wall with the LED screen between two portrait billboards near the top, a
    solid tilted roof canopy on white V struts with a glass balustrade, ad boards on the roof at both ends, an entrance
    canopy on columns; the west entrance canopy with MYANMAR PLAZA standing on its edge."""
    F = mesh("front")
    R = mesh("frontR", "R")
    face = Vector(LAY["face"]).normalized()
    fb = edge_facing(pod, face, min_len=10.0, tol=0.9)
    p, q, L, n, _ = fb
    mid = (p + q) / 2
    t = (q - p).normalized()  # left -> right seen from the plinth? p -> q with outward on the right = viewer's left->right
    yaw = math.atan2(n.y, n.x)
    bw = min(72.0, L - 4.0)
    bd = 6.0
    # the screen wall
    c = mid + n * (bd / 2)
    box(F, (c.x, c.y, 26.0), (bd, bw, 38.0), yaw, region="darkglass", col=(1, 1, 1), top="concrete")
    fc = mid + n * (bd + 0.08)
    led_w = min(36.0, bw - 30.0)
    panel(F, (fc.x, fc.y), led_w, 20.0, yaw, "screen", 36.0)
    for k, reg in ((-1, "bill0"), (1, "bill2")):
        pc = fc + t * (k * (led_w / 2 + 7.5))
        panel(F, (pc.x, pc.y), 12.0, 22.0, yaw, reg, 35.0)
    # silver frames round the three panels and a light line at the top of the wall
    fr = fc + n * 0.04
    for x0, w, z0, h in ((-(led_w / 2 + 14.0), led_w + 28.0, 34.4, 0.6), (-(led_w / 2 + 14.0), led_w + 28.0, 57.0, 0.6)):
        pc = fr + t * (x0 + w / 2)
        panel(F, (pc.x, pc.y), w, h, yaw, "white", z0, col=(0.78, 0.78, 0.78), glow=False)
    panel(F, (fr.x, fr.y), bw, 1.0, yaw, "lamp", 62.6, glow=True)
    # entrance canopy on three columns at the ground floor, and the bollards come from the fit
    canopy(F, R, p, q, 9.0, 13.0, 1.6, columns=3, extend=-6.0)
    # the roof canopy: a solid plate, tilted up toward the street, white fascia, glowing ribbed soffit
    back_c = mid - n * 4.0
    front_c = mid + n * 10.0
    hw_back, hw_front = 20.0, 29.0
    zb_back, zb_front = top + 9.0, top + 12.5
    th = 1.6
    pts_b = [front_c - t * hw_front, front_c + t * hw_front, back_c + t * hw_back, back_c - t * hw_back]
    # CCW from above: viewer looking from the street (n side) sees -t on the left
    quad = [(v.x, v.y) for v in pts_b]
    zs = [zb_front, zb_front, zb_back, zb_back]
    poly3 = [(quad[i][0], quad[i][1], zs[i]) for i in range(4)]
    # underside (soffit) and top
    def oriented(pts, up):
        a = (pts[1][0] - pts[0][0]) * (pts[2][1] - pts[0][1]) - (pts[1][1] - pts[0][1]) * (pts[2][0] - pts[0][0])
        if (a > 0) != up:
            pts = list(reversed(pts))
        return pts
    R.poly(oriented(poly3, False), [uvr("soffit", 0, 0), uvr("soffit", 1, 0), uvr("soffit", 1, 1), uvr("soffit", 0, 1)],
           (1, 1, 1), True)
    top3 = [(x, y, z + th) for x, y, z in poly3]
    R.flatpoly(oriented(top3, True), "white", (0.3, 0.3, 0.31))
    # fascia: four sloping sides, dark grey with a white top lip on the street side
    for i in range(4):
        a, b = poly3[i], poly3[(i + 1) % 4]
        sq = [(a[0], a[1], a[2]), (b[0], b[1], b[2]), (b[0], b[1], b[2] + th), (a[0], a[1], a[2] + th)]
        # outward check: the centre of the plate is (front_c + back_c) / 2
        cc = (front_c + back_c) / 2
        e = Vector((b[0] - a[0], b[1] - a[1]))
        nn = Vector((e.y, -e.x))
        if nn.dot(Vector(((a[0] + b[0]) / 2 - cc.x, (a[1] + b[1]) / 2 - cc.y))) < 0:
            sq = [sq[1], sq[0], sq[3], sq[2]]
        R.flatpoly(sq, "white", (0.92, 0.92, 0.9) if i == 0 else (0.34, 0.35, 0.37))
    # V struts: pairs from the roof edge (behind the screen wall top) up to the plate's underside near the front
    for k in (-2, -1, 0, 1, 2):
        base = mid + t * (k * 11.0) - n * 1.0
        for s in (-1, 1):
            a = Vector((base.x, base.y, top))
            tip = mid + t * (k * 11.0 + s * 2.5) + n * 7.0
            frac = (tip - back_c).dot(n) / max((front_c - back_c).dot(n), 1e-3)
            zt = zb_back + (zb_front - zb_back) * frac
            strut(R, a, Vector((tip.x, tip.y, zt)), 0.7, (0.93, 0.93, 0.92))
    # glass balustrade along the roof edge under the canopy
    bal = mid - n * 0.6
    panel(F, (bal.x, bal.y), bw - 6.0, 3.2, yaw, "darkglass", top, col=(1, 1, 1), glow=False)
    # ad boards on the roof at both ends of the front (the red one on the right seen from the plinth)
    for side, reg, w, h, bcol in ((1, "bill1", 17.0, 11.0, (0.55, 0.1, 0.1)), (-1, "screen", 18.0, 9.0, (0.86, 0.86, 0.86))):
        bc = mid + t * side * (L / 2 - w / 2 - 2.0) - n * 2.0
        box(F, (bc.x, bc.y, top), (1.4, w + 1.0, h + 1.0), yaw, col=bcol, bottom=True)
        pc = bc + n * 0.78
        panel(F, (pc.x, pc.y), w, h, yaw, reg, top + 0.5)
        if side < 0:
            for k in range(4):
                a = bc + t * (-w / 2 + (k + 0.5) * w / 4)
                strut(R, Vector((a.x, a.y, top + h + 1.0)), Vector((a.x + n.x * 3, a.y + n.y * 3, top + h + 2.2)), 0.35,
                      (0.2, 0.2, 0.22))
    # the west entrance on Kabar Aye Pagoda Road: a heavy canopy with MYANMAR PLAZA standing on its front edge
    wb = edge_facing(pod, Vector((-1, 0)), min_len=12.0, tol=0.8)
    if wb:
        wp, wq, wl, wn, _ = wb
        wm = (wp + wq) / 2
        we = (wq - wp).normalized()
        half = min(26.0, wl / 2 - 1.0)
        canopy(F, R, wm - we * half, wm + we * half, 11.0, 13.0, 2.0, fascia_col=(0.55, 0.53, 0.5), columns=2)
        tp = wm + wn * 10.9
        panel(F, (tp.x, tp.y), min(46.0, 2 * half - 4.0), 5.5, math.atan2(wn.y, wn.x), "txt_plaza", 15.0)
    return mid, n, t


def build_tower(name, poly, z0, n_office, region, crown_rows=2, roof="roof", notch=None, slots=False, ground=False,
                bulge=None, end_region=None, end_col=(1, 1, 1)):
    """A slab tower. notch: recess the SW half of both short ends by notch studs (tower A); slots: a 2 x 2 slot down the
    middle of each short end (tower B); bulge: (edge index, sagitta) bows that long face outward (tower B's north face);
    ground: start at the street with a shop storey; end_region: a different picture on the short ends (the Melia)."""
    F = mesh(name)
    R = mesh(name + "R", "R")
    P = [V2(p) for p in poly]
    # long and short edges of the 4-point outline
    L = [(P[(i + 1) % 4] - P[i]).length for i in range(4)]
    if bulge:
        bi, sag = bulge
        a, b = P[bi], P[(bi + 1) % 4]
        cen = sum(P, Vector((0, 0))) / 4
        mid = (a + b) / 2
        out = Vector(((b - a).y, -(b - a).x)).normalized()
        if out.dot(mid - cen) < 0:
            out = -out
        pts = []
        for k in range(1, 8):
            u = k / 8
            h = sag * (1 - (2 * u - 1) ** 2)
            pts.append(a.lerp(b, u) + out * h)
        P = P[:bi + 1] + pts + P[bi + 1:]
    poly = ccw([(v.x, v.y) for v in P])
    if notch or slots:
        Pc = [V2(p) for p in poly]
        n = len(Pc)
        lens = [(Pc[(i + 1) % n] - Pc[i]).length for i in range(n)]
        cen = sum(Pc, Vector((0, 0))) / n
        newp = []
        for i in range(n):
            a, b = Pc[i], Pc[(i + 1) % n]
            newp.append(a)
            if lens[i] < 0.7 * max(lens) and lens[i] > 10:
                e = (b - a).normalized()
                inn = -Vector((e.y, -e.x))  # inward
                m = (a + b) / 2
                if slots:
                    newp += [m - e * 1.0, m - e * 1.0 + inn * 2.0, m + e * 1.0 + inn * 2.0, m + e * 1.0]
                if notch:
                    # recess the half nearer the long face whose corner is further south-west (smaller x + y)
                    if (a.x + a.y) < (b.x + b.y):
                        # a is the SW corner: move it in along the long axis, step back out at the middle
                        newp[-1] = a + inn * notch
                        newp += [m + inn * notch, m]
                    else:
                        newp += [m, m + inn * notch]
                        # b is the SW corner: moved in when it is appended next round
                        b_in = b + inn * notch
                        Pc[(i + 1) % n] = b_in
        poly = ccw([(v.x, v.y) for v in newp])
    zstart = z0
    if ground:
        ring(F, poly, SKIRT, 0.0, "concrete", ustuds=40.0, col=(0.5, 0.48, 0.46), glow=False)
        zstart = storeys(F, poly, 0.0, [14.0], "shop", ustuds=64.0)
        collide_poly(poly, 0.0, 30.0)
    if end_region:
        # long edges banded, short edges plain with a dark glass slot down the middle
        n = len(poly)
        lens = [math.dist(poly[i], poly[(i + 1) % n]) for i in range(n)]
        longs = {i for i in range(n) if lens[i] >= 0.7 * max(lens)}
        z = storeys(F, poly, zstart, [FLOOR] * n_office, region, edges=longs)
        shorts = set(range(n)) - longs
        ring(F, poly, zstart, z, end_region, ustuds=1e6, col=end_col, glow=False, edges=shorts)
        for i in shorts:
            a, b = V2(poly[i]), V2(poly[(i + 1) % n])
            m = (a + b) / 2
            nn = outward(poly, i)
            pc = m + nn * 0.1
            panel(F, (pc.x, pc.y), 2.6, z - zstart - 6.0, math.atan2(nn.y, nn.x), "darkglass", zstart + 3.0, glow=False)
    else:
        z = storeys(F, poly, zstart, [FLOOR] * n_office, region)
    z = storeys(F, poly, z, [8.0] * crown_rows, "crown", glow=False)
    top = z
    deck = offset_poly(poly, -1.6)
    annulus(R, poly, deck, top, "white", col=(0.84, 0.8, 0.74))
    ring(R, list(reversed(deck)), top - 2.0, top, "white", ustuds=1e6, col=(0.78, 0.75, 0.7), glow=False)
    cap(R, deck, top - 2.0, roof)
    # a plant room on the roof
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    e0 = V2(poly[1]) - V2(poly[0])
    box(R, (cx, cy, top - 2.0), (14.0, 8.0, 7.0), math.atan2(e0.y, e0.x), col=(0.8, 0.78, 0.74))
    return top, poly


def build_dome(top):
    R = mesh("domeR", "R")
    F = mesh("dome")
    cx, cy = LAY["dome_c"]
    rx, ry, hz = 23.0, 26.0, 9.0
    seg, rings = 24, 5
    z0 = top - 1.0

    def E(rr_x, rr_y, k):
        a = 2 * math.pi * k / seg
        return (cx + rr_x * math.cos(a), cy + rr_y * math.sin(a))
    outer = [E(rx + 4.5, ry + 4.5, k) for k in range(seg)]
    innr = [E(rx + 0.5, ry + 0.5, k) for k in range(seg)]
    ring(F, outer, z0, z0 + 2.5, "hedge", ustuds=20.0, glow=False)
    annulus(R, outer, innr, z0 + 2.5, "hedge", col=(1, 1, 1))
    ring(F, list(reversed(innr)), z0, z0 + 2.5, "white", ustuds=1e6, col=(0.8, 0.8, 0.78), glow=False)
    zb = z0 + 1.5
    for j in range(rings):
        t0, t1 = j / rings, (j + 1) / rings
        a0, a1 = t0 * math.pi / 2, t1 * math.pi / 2
        for k in range(seg):
            b0, b1 = 2 * math.pi * k / seg, 2 * math.pi * (k + 1) / seg

            def P(a, b):
                return (cx + rx * math.cos(a) * math.cos(b), cy + ry * math.cos(a) * math.sin(b), zb + hz * math.sin(a))
            pts = [P(a0, b0), P(a0, b1), P(a1, b1), P(a1, b0)]
            uvs = [uvr("dome", k / seg, t0), uvr("dome", (k + 1) / seg, t0), uvr("dome", (k + 1) / seg, t1),
                   uvr("dome", k / seg, t1)]
            if j == rings - 1:
                R.poly(pts[:3], uvs[:3], (1, 1, 1), False)
            else:
                R.poly(pts, uvs, (1, 1, 1), False)


def build_plinth():
    """The corner plinth (p3, p5, p8): a long shallow arc wall, polished maroon granite below (60 %) with the four building
    names and warm uplights, a cream band with MYANMAR CENTRE in orange over the left 85 % (the right end is bare granite),
    a coping, a low rounded hedge on a lawn strip in front, a flat lawn behind; the wall ends are closed."""
    F = mesh("plinth")
    R = mesh("plinthR", "R")
    cx, cy = LAY["plinth_c"]
    r = float(LAY["fit"]["plinth_r"])
    span = math.radians(float(LAY["fit"].get("plinth_span", 104)))
    face = math.atan2(LAY["face"][1], LAY["face"][0])
    a0 = face - span / 2
    nb = 40
    zg, zt = 7.2, 11.6
    band_k = int(round(nb * 0.85))

    def P(b, rr):
        return (cx + rr * math.cos(b), cy + rr * math.sin(b))
    arc_len = r * span
    for k in range(nb):
        t0, t1 = k / nb, (k + 1) / nb
        b0, b1 = a0 + span * t0, a0 + span * t1
        p, q = P(b0, r), P(b1, r)  # increasing angle = the viewer's right: p left, q right
        top_g = zg if k < band_k else zt
        # granite: the 'names' strip at 4.2-5.6 over the band part, plain granite elsewhere
        if k < band_k:
            u0, u1 = k / band_k, (k + 1) / band_k
            F.poly([(p[0], p[1], SKIRT), (q[0], q[1], SKIRT), (q[0], q[1], 4.2), (p[0], p[1], 4.2)],
                   [uvr("granite", 0.1, 0), uvr("granite", 0.9, 0), uvr("granite", 0.9, 0.6), uvr("granite", 0.1, 0.6)],
                   (1, 1, 1), False)
            F.poly([(p[0], p[1], 4.2), (q[0], q[1], 4.2), (q[0], q[1], 5.6), (p[0], p[1], 5.6)],
                   [uvr("names", u0, 0), uvr("names", u1, 0), uvr("names", u1, 1), uvr("names", u0, 1)], (1, 1, 1), False)
            F.poly([(p[0], p[1], 5.6), (q[0], q[1], 5.6), (q[0], q[1], zg), (p[0], p[1], zg)],
                   [uvr("granite", 0.1, 0.6), uvr("granite", 0.9, 0.6), uvr("granite", 0.9, 1), uvr("granite", 0.1, 1)],
                   (1, 1, 1), False)
            F.poly([(p[0], p[1], zg), (q[0], q[1], zg), (q[0], q[1], zt), (p[0], p[1], zt)],
                   [uvr("txt_centre", u0, 0), uvr("txt_centre", u1, 0), uvr("txt_centre", u1, 1),
                    uvr("txt_centre", u0, 1)], (1, 1, 1), True)
        else:
            F.poly([(p[0], p[1], SKIRT), (q[0], q[1], SKIRT), (q[0], q[1], zt), (p[0], p[1], zt)],
                   [uvr("granite", 0.1, 0), uvr("granite", 0.9, 0), uvr("granite", 0.9, 1), uvr("granite", 0.1, 1)],
                   (1, 1, 1), False)
        # coping (0.5 proud), its underside lip, and the plain back of the wall
        po, qo = P(b0, r + 0.5), P(b1, r + 0.5)
        pi_, qi_ = P(b0, r - 1.1), P(b1, r - 1.1)
        R.flatpoly([(po[0], po[1], zt + 0.6), (qo[0], qo[1], zt + 0.6), (qi_[0], qi_[1], zt + 0.6), (pi_[0], pi_[1], zt + 0.6)],
                   "white", (0.8, 0.76, 0.68))
        F.flatpoly([(po[0], po[1], zt), (qo[0], qo[1], zt), (qo[0], qo[1], zt + 0.6), (po[0], po[1], zt + 0.6)],
                   "white", (0.82, 0.78, 0.7))
        R.flatpoly([(p[0], p[1], zt), (q[0], q[1], zt), (qo[0], qo[1], zt), (po[0], po[1], zt)][::-1], "white",
                   (0.45, 0.42, 0.38))
        pb, qb = P(b0, r - 0.8), P(b1, r - 0.8)
        F.poly([(qb[0], qb[1], SKIRT), (pb[0], pb[1], SKIRT), (pb[0], pb[1], zt), (qb[0], qb[1], zt)],
               [uvr("granite", 0.1, 0), uvr("granite", 0.9, 0), uvr("granite", 0.9, 1), uvr("granite", 0.1, 1)],
               (0.8, 0.8, 0.8), False)
        R.flatpoly([(pb[0], pb[1], zt), (p[0], p[1], zt), (q[0], q[1], zt), (qb[0], qb[1], zt)][::-1], "white",
                   (0.6, 0.56, 0.5)) if False else None
        # hedge: r + 1.2 .. r + 3.2, vertical to 1.4 then rounded to a 1.0 wide crown at 1.9; u by arc length
        hi, ho = r + 1.2, r + 3.2
        s0, s1 = (r + 3.2) * span * t0 / 14.0, (r + 3.2) * span * t1 / 14.0
        A, B = P(b0, ho), P(b1, ho)
        F.poly([(A[0], A[1], 0.0), (B[0], B[1], 0.0), (B[0], B[1], 1.4), (A[0], A[1], 1.4)],
               [uvr("hedge", 0.05, 0), uvr("hedge", 0.95, 0), uvr("hedge", 0.95, 0.7), uvr("hedge", 0.05, 0.7)],
               (1, 1, 1), False)
        Am, Bm = P(b0, ho - 0.6), P(b1, ho - 0.6)
        F.poly([(A[0], A[1], 1.4), (B[0], B[1], 1.4), (Bm[0], Bm[1], 1.9), (Am[0], Am[1], 1.9)],
               [uvr("hedge", 0.05, 0.7), uvr("hedge", 0.95, 0.7), uvr("hedge", 0.95, 1), uvr("hedge", 0.05, 1)],
               (1, 1, 1), False)
        Ai, Bi = P(b0, hi + 0.6), P(b1, hi + 0.6)
        R.flatpoly([(Am[0], Am[1], 1.9), (Bm[0], Bm[1], 1.9), (Bi[0], Bi[1], 1.9), (Ai[0], Ai[1], 1.9)], "hedge",
                   (0.95, 1.0, 0.85))
        Ai2, Bi2 = P(b0, hi), P(b1, hi)
        F.poly([(Bi2[0], Bi2[1], 0.0), (Ai2[0], Ai2[1], 0.0), (Ai[0], Ai[1], 1.9), (Bi[0], Bi[1], 1.9)],
               [uvr("hedge", 0.05, 0), uvr("hedge", 0.95, 0), uvr("hedge", 0.95, 1), uvr("hedge", 0.05, 1)],
               (0.85, 0.9, 0.8), False)
        # lawn: between the wall and the hedge, and the strip in front of the hedge (to r + 6)
        for ra, rb in ((r, hi), (ho, r + 6.0)):
            a1, b1_ = P(b0, rb), P(b1, rb)
            a2, b2 = P(b0, ra), P(b1, ra)
            R.poly([(a1[0], a1[1], 0.14), (b1_[0], b1_[1], 0.14), (b2[0], b2[1], 0.14), (a2[0], a2[1], 0.14)],
                   [uvr("hedge", 0.4, 0.2)] * 4, (0.75, 0.95, 0.55), False)
        COLL.append(((p[0] + q[0]) / 2 - math.cos((b0 + b1) / 2) * 0.4, (p[1] + q[1]) / 2 - math.sin((b0 + b1) / 2) * 0.4,
                     0.0, math.dist(p, q) + 0.3, 1.0, zt + 0.6, math.atan2(q[1] - p[1], q[0] - p[0])))
    # uplights at the foot of the granite (9 warm spots)
    for k in range(9):
        b = a0 + span * (0.06 + 0.88 * k / 8)
        pp = P(b, r + 0.06)
        panel(F, pp, 0.7, 0.45, b, "lamp", 0.4, glow=True)
    # wall ends (granite) and hedge ends
    for b, sgn in ((a0, -1), (a0 + span, 1)):
        o, i_ = P(b, r + 0.5), P(b, r - 1.1)
        pts = [(i_[0], i_[1], SKIRT), (o[0], o[1], SKIRT), (o[0], o[1], zt + 0.6), (i_[0], i_[1], zt + 0.6)]
        if sgn > 0:
            pts = [pts[1], pts[0], pts[3], pts[2]]
        F.poly(pts, [uvr("granite", 0.2, 0), uvr("granite", 0.4, 0), uvr("granite", 0.4, 1), uvr("granite", 0.2, 1)],
               (1, 1, 1), False)
        o, i_ = P(b, r + 3.2), P(b, r + 1.2)
        pts = [(i_[0], i_[1], 0.0), (o[0], o[1], 0.0), (o[0], o[1], 1.6), (i_[0], i_[1], 1.6)]
        if sgn > 0:
            pts = [pts[1], pts[0], pts[3], pts[2]]
        F.poly(pts, [uvr("hedge", 0.2, 0), uvr("hedge", 0.5, 0), uvr("hedge", 0.5, 1), uvr("hedge", 0.2, 1)],
               (0.9, 0.95, 0.85), False)
    # the flat lawn garden behind the wall (inside the arc, closed by its chord)
    garden = [P(a0 + span * k / 24, r - 1.1) for k in range(25)]
    cap(R, garden, 0.14, "hedge", col=(0.72, 0.92, 0.52), flatuv=True)


def build_melia():
    base = ccw([tuple(p) for p in LAY["melia_osm"][:-1]])
    F = mesh("meliaPod")
    R = mesh("meliaPodR", "R")
    inner = offset_poly(base, -2.0)
    ring(F, base, SKIRT, 0.0, "concrete", ustuds=40.0, col=(0.5, 0.48, 0.46), glow=False)
    ring(F, inner, 0.0, 14.0, "shop", ustuds=64.0)
    annulus(R, base, inner, 14.0, "soffit", down=True)
    z = storeys(F, base, 14.0, [12.0, 12.0], "podium", ustuds=76.8, k0=3)
    ring(F, base, z, z + 3.0, "crown", glow=False)
    ptop = z + 3.0
    cap(R, base, ptop, "concrete")
    collide_poly(base, 0.0, ptop)
    top, C = build_tower("melia", LAY["C"], ptop, 19, "melia", crown_rows=2, roof="concrete", end_region="white",
                         end_col=(0.95, 0.94, 0.91))
    # the name on both long faces' crowns (east toward the mall's back road, west toward Kabar Aye Pagoda Road)
    n = len(C)
    for want in (1, -1):
        best = None
        for i in range(n):
            nn = outward(C, i)
            Ln = math.dist(C[i], C[(i + 1) % n])
            if Ln > 40 and (best is None or nn.x * want > best[2].x * want):
                best = (V2(C[i]), V2(C[(i + 1) % n]), nn)
        p, q, nn = best
        mc = (p + q) / 2 + nn * 0.3
        panel(mesh("melia"), (mc.x, mc.y), 34.0, 6.5, math.atan2(nn.y, nn.x), "txt_melia", top - 14.0)
    # D: the terraced west wing, stepping down to the west, gardens and a pool on each terrace
    D = [tuple(p) for p in LAY["D"]]
    FD = mesh("meliaD")
    RD = mesh("meliaDR", "R")

    def split(poly, a, b):
        p0, p1, p2, p3 = [V2(p) for p in poly]
        s0, s1, t0_, t1_ = p0.lerp(p1, a), p0.lerp(p1, b), p3.lerp(p2, a), p3.lerp(p2, b)
        return [(s0.x, s0.y), (s1.x, s1.y), (t1_.x, t1_.y), (t0_.x, t0_.y)]
    for k, (a, b, nfl) in enumerate([(0.0, 0.34, 3), (0.34, 0.67, 6), (0.67, 1.0, 9)]):
        piece = split(D, a, b)
        z2 = storeys(FD, piece, ptop, [FLOOR] * nfl, "melia", ustuds=76.8, k0=k * 3)
        ring(FD, piece, z2, z2 + 2.5, "crown", glow=False)
        cap(RD, piece, z2 + 2.5, "garden")


def build_suites():
    E = ccw([tuple(p) for p in LAY["E"]])
    F = mesh("suites")
    R = mesh("suitesR", "R")
    base = offset_poly(E, 6.0)
    ring(F, base, SKIRT, 0.0, "concrete", ustuds=40.0, col=(0.5, 0.48, 0.46), glow=False)
    z = storeys(F, base, 0.0, [14.0], "shop", ustuds=64.0)
    z = storeys(F, base, z, [12.0], "podium", k0=1)
    cap(R, base, z, "garden")
    collide_poly(base, 0.0, z)
    z = storeys(F, E, z, [FLOOR] * 29, "resid", ustuds=76.8)
    c1 = offset_poly(E, -3.0)
    annulus(R, E, c1, z, "white", col=(0.86, 0.84, 0.8))
    z1 = storeys(F, c1, z, [8.0, 8.0], "crown", glow=False)
    c2 = offset_poly(E, -9.0)
    annulus(R, c1, c2, z1, "white", col=(0.9, 0.88, 0.84))
    z2 = storeys(F, c2, z1, [7.0], "crown", glow=False)
    cap(R, c2, z2, "concrete")
    best = None
    for i in range(4):
        nn = outward(c1, i)
        if best is None or nn.y > best[2].y:
            best = (V2(c1[i]), V2(c1[(i + 1) % 4]), nn)
    p, q, nn = best
    mc = (p + q) / 2 + nn * 0.3
    panel(F, (mc.x, mc.y), 30.0, 5.0, math.atan2(nn.y, nn.x), "txt_suites", z + 2.0)


def build_whiteroof():
    W = ccw([tuple(p) for p in LAY["whiteroof"]])
    F = mesh("wroof")
    R = mesh("wroofR", "R")
    ring(F, W, SKIRT, 0.0, "concrete", ustuds=40.0, col=(0.5, 0.48, 0.46), glow=False)
    z = storeys(F, W, 0.0, [14.0], "shop", ustuds=64.0)
    z = storeys(F, W, z, [13.0, 13.0, 13.0, 13.0], "podium", k0=2)
    ring(F, W, z, z + 3.0, "crown", glow=False)
    cap(R, W, z + 3.0, "white", col=(0.95, 0.95, 0.93), flatuv=True)


def build_ground():
    """Pavers on the plaza round the buildings (tiles from the fit: each cell maps the paver picture once)."""
    R = mesh("paving", "R")
    for t in LAY.get("paving", []):
        x0, x1, y0, y1 = t["cell"]
        cap(R, [tuple(p) for p in t["outer"]], 0.06, "paver", fit=(x0, x1, y0, y1),
            holes=[[tuple(p) for p in h] for h in t.get("holes", [])])


def build_props():
    """Lamp posts with a pair of red banners, white bollards (positions from the fit)."""
    R = mesh("props", "R")
    pc = Vector(LAY["plinth_c"])
    fv = Vector(LAY["face"]).normalized()
    for x, y, yaw in LAY.get("lamps", []):
        # keep the corner view clear: no lamp in front of the plinth (within 65 degrees of its facing)
        dv = Vector((x, y)) - pc
        if dv.length > 1e-3 and dv.normalized().dot(fv) > math.cos(math.radians(65)):
            continue
        box(R, (x, y, SKIRT), (0.7, 0.7, 16.0 - SKIRT), yaw, col=(0.22, 0.23, 0.25))
        COLL.append((x, y, 0.0, 0.8, 0.8, 16.0, yaw))
        # the disc head: an octagon, lamp glow underneath
        oct_ = [(x + 2.0 * math.cos(k * math.pi / 4), y + 2.0 * math.sin(k * math.pi / 4)) for k in range(8)]
        ring(R, oct_, 16.0, 16.8, "white", ustuds=1e6, col=(0.25, 0.26, 0.28), glow=False)
        cap(R, oct_, 16.8, "white", col=(0.25, 0.26, 0.28), flatuv=True)
        cap(R, oct_, 16.0, "lamp", down=True, glow=True, flatuv=True)
        # two banners either side of the post, square to the road
        side = Vector((math.cos(yaw), math.sin(yaw)))
        for s in (-1, 1):
            c = Vector((x, y)) + side * s * 1.25
            strut(R, Vector((x, y, 14.2)), Vector((c.x + side.x * s * 0.9, c.y + side.y * s * 0.9, 14.2)), 0.18,
                  (0.3, 0.3, 0.32))
            panel(R, (c.x + side.x * s * 0.9 - side.x * s * 0.9, c.y), 1.0, 0.0, 0.0, "banner", 0.0) if False else None
            bc = c + side * s * 0.9
            fyaw = math.atan2(side.y, side.x) + math.pi / 2
            panel(R, (bc.x, bc.y), 1.7, 5.0, fyaw, "banner", 9.0, glow=False, both=True)
    for x, y in LAY.get("bollards", []):
        box(R, (x, y, 0.0), (0.5, 0.5, 2.4), 0.0, col=(0.94, 0.94, 0.92))
        COLL.append((x, y, 0.0, 0.5, 0.5, 2.4, 0.0))


def build(opts=None):
    opts = opts or {}
    MESHES.clear()
    COLL.clear()
    pod, top = build_podium()
    build_front(pod, top)
    build_dome(top)
    build_whiteroof()
    tA, _ = build_tower("towerA", LAY["A"], 0.0, 26, "officeA", crown_rows=3, ground=True, notch=5.0)
    # tower B: its north face (edge 0 -> 1 of the layout outline, the larger y) bows out 6 studs; slots in both ends
    tB, _ = build_tower("towerB", LAY["B"], top - 1.0, 20, "officeB", crown_rows=3, slots=True, bulge=(0, 6.0))
    build_melia()
    build_suites()
    build_plinth()
    build_ground()
    build_props()
    to_blender()
    return {k: (len(m.f), m.kind) for k, m in MESHES.items()}, tA, tB, len(COLL)


# ------------------------------------------------------------------------------------------------------------------------
def material():
    mat = bpy.data.materials.get("MC_Atlas") or bpy.data.materials.new("MC_Atlas")
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    img = bpy.data.images.get("mc_atlas.png")
    if img is None:
        img = bpy.data.images.load(os.path.join(ROOT, "mc_atlas.png"))
    else:
        img.reload()
    tex.image = img
    tex.interpolation = "Linear"
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "Col"
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    nt.links.new(tex.outputs["Color"], mix.inputs[1])
    nt.links.new(col.outputs["Color"], mix.inputs[2])
    nt.links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.6
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    mat.use_backface_culling = True  # Roblox draws only the front of a face
    return mat


def to_blender():
    coll = bpy.data.collections.get("MC")
    if coll is None:
        coll = bpy.data.collections.new("MC")
        bpy.context.scene.collection.children.link(coll)
    for o in list(coll.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    mat = material()
    for name, m in MESHES.items():
        if not m.f:
            continue
        me = bpy.data.meshes.new("MC_" + name)
        me.from_pydata(m.v, [], m.f)
        me.update()
        # make every layer first, then look them up again: adding a layer moves the others' memory, and writing
        # through an old reference crashed Blender 3.6 (EXCEPTION_ACCESS_VIOLATION, 2026-11-14)
        me.uv_layers.new(name="UV")
        me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="CORNER")
        me.attributes.new(name="glow", type="INT", domain="FACE")
        uvl = me.uv_layers["UV"]
        cl = me.color_attributes["Col"]
        gl = me.attributes["glow"]
        for fi, poly in enumerate(me.polygons):
            for k, l in enumerate(poly.loop_indices):
                uvl.data[l].uv = m.uv[fi][k]
                c = m.col[fi]
                cl.data[l].color = (c[0], c[1], c[2], 1.0)
            gl.data[fi].value = 1 if m.glow[fi] else 0
        me.materials.append(mat)
        ob = bpy.data.objects.new("MC_" + name, me)
        ob["kind"] = m.kind
        coll.objects.link(ob)


# ------------------------------------------------------------------------------------------------------------------------
def scene_setup():
    sc = bpy.context.scene
    if "Cube" in bpy.data.objects:
        bpy.data.objects.remove(bpy.data.objects["Cube"], do_unlink=True)
    try:
        sc.render.engine = "BLENDER_EEVEE"
    except TypeError:
        pass
    sc.render.resolution_x, sc.render.resolution_y = 1280, 960
    w = sc.world or bpy.data.worlds.new("World")
    sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.55, 0.7, 0.9, 1)
    bg.inputs[1].default_value = 0.9
    sun = bpy.data.objects.get("MC_Sun")
    if sun is None:
        ld = bpy.data.lights.new("MC_Sun", "SUN")
        sun = bpy.data.objects.new("MC_Sun", ld)
        sc.collection.objects.link(sun)
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(140))
    if "Light" in bpy.data.objects:
        bpy.data.objects["Light"].hide_render = True
    g = bpy.data.objects.get("MC_Ground")
    if g is None:
        bpy.ops.mesh.primitive_plane_add(size=1400, location=(0, 0, -0.05))
        g = bpy.context.active_object
        g.name = "MC_Ground"
        gm = bpy.data.materials.new("MC_GroundMat")
        gm.use_nodes = True
        b = next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Base Color"].default_value = (0.2, 0.2, 0.21, 1)
        g.data.materials.append(gm)
    sc.camera = bpy.data.objects.get("Camera")
    return sc.camera


def _p3():
    ax, ay = LAY.get("apex", LAY["plinth_c"])
    f = Vector(LAY["face"]).normalized()
    cam = Vector((ax, ay)) + f * 44.0
    return ((cam.x, cam.y, 5.5), (ax - f.x * 120.0, ay - f.y * 120.0, 82.0), 20.0)


VIEWS = {
    "p3_corner": None,
    "p2_southeast": ((330.0, -170.0, 6.0), (40.0, 40.0, 110.0), 30.0),
    "p13_west": ((-330.0, 60.0, 6.0), (0.0, 20.0, 110.0), 24.0),
    "air_nw": ((-420.0, 520.0, 380.0), (10.0, -40.0, 60.0), 35.0),
    "air_top": ((0.0, -40.0, 1100.0), (0.0, -39.0, 0.0), 30.0),
    "street_w": ((-140.0, 40.0, 5.5), (-60.0, 40.0, 30.0), 24.0),
}


def views(names=None, size=None):
    cam = scene_setup()
    sc = bpy.context.scene
    if size:
        sc.render.resolution_x, sc.render.resolution_y = size
    out = os.path.join(ROOT, "views")
    os.makedirs(out, exist_ok=True)
    done = []
    for name, v in VIEWS.items():
        if names and name not in names:
            continue
        pos, look, lens = v if v else _p3()
        cam.location = pos
        d = Vector(look) - Vector(pos)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        cam.data.clip_end = 5000
        sc.render.filepath = os.path.join(out, name + ".png")
        bpy.ops.render.render(write_still=True)
        done.append(sc.render.filepath)
    return done


def dump(path=None):
    """Every triangle of the MC collection: model coords, glTF uv (v down), colour, glow, kind; and the collision boxes."""
    path = path or os.path.join(ROOT, "mc_tris.json")
    out = {}
    for ob in bpy.data.collections["MC"].objects:
        me = ob.data
        me.calc_loop_triangles()
        uvl = me.uv_layers["UV"].data
        cl = me.color_attributes["Col"].data
        gl = me.attributes["glow"].data
        tris = []
        for t in me.loop_triangles:
            corners = []
            for li, vi in zip(t.loops, t.vertices):
                p = ob.matrix_world @ me.vertices[vi].co
                u, v = uvl[li].uv
                c = cl[li].color
                corners.append([round(p.x, 3), round(p.y, 3), round(p.z, 3), round(u, 5), round(1.0 - v, 5),
                                round(c[0], 3), round(c[1], 3), round(c[2], 3)])
            tris.append([corners, gl[t.polygon_index].value])
        out[ob.name] = {"kind": ob.get("kind", "F"), "tris": tris}
    json.dump(out, open(path, "w"))
    json.dump([[round(v, 3) for v in b] for b in COLL], open(os.path.join(ROOT, "mc_collide.json"), "w"))
    return {k: len(v["tris"]) for k, v in out.items()}, len(COLL)
