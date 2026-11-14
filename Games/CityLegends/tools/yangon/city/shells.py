"""shells.py: building geometry from a plot record, UV-mapped onto the atlas rows of atlas.py (see atlas.json).

    from shells import Context, build_plot
    ctx = Context(plots, atlas_json)          # all plots (for party walls: a wall facing a neighbour within ~2 studs)
    F, R, G, boxes, info = build_plot(plot, ctx)  # F: walls (casts shadow), R: roofs and props, G: night windows, boxes

PLOT (input; the full schema is in d24_bmesh.py's header):
  {"id", "poly": [[x, z], ...] world studs (any winding, not closed), "y" ground height at the base, "floors", "style",
   "roof", "roof_colour", "wall_colour", "front": edge index facing the street or null, "shop": bool, "name"}

Geometry (game scale: ground floor 12 studs, upper floors 9, YangonBuildings.luau line 39):
  * the outline is cleaned (buffer(0), simplify 0.5, edges under 1.5 studs merged) and turned counter-clockwise seen from
    above; `front` is carried over to the cleaned edge nearest the original front edge's middle.
  * walls: one quad per edge per floor. Each edge gets a whole number of 12-stud bays (U stretched a little to fit), so
    windows never cut at corners; edges under 5 studs and party walls get the blank `party` row at true scale.
    Ground floor: `gshop` on the front edge when shop, else `gres` (house rows for houses, corrugated for sheds).
    Upper floors by style: walkup/mass -> walkup (condo past 8 floors), shophouse -> shopup on the front, tower/round ->
    condo, house/villa -> house, hall -> shopup, shed -> corrugated metal. Floors alternate the bay offset by 4 bays.
  * walk-ups (and mass blocks of 3-8 floors) get grilled balcony cages on the front edge (2.2 studs deep).
  * flat roofs: parapet (cornice row outside, plain inside, a cap), the roof in 16-stud strips (rooff tiles in U and V),
    a stair room and 1-3 water tanks for walkup / mass / tower / shophouse.
  * pitched roofs (gable / hip / shed) over the outline's min-area rectangle, 1.2-stud eaves, corrugated `roofc`, an
    underside, and wall infill from the wall top up to the roof (that makes the gable triangles). Outlines that are not
    rectangle-like (area < 0.8 of the rectangle) get a flat roof instead.
  * round outlines (style round, or 10+ points with circularity > 0.86): resampled to 16-32 sides, smooth normals.
  * shops: a tarp awning over the front's ground floor and, often, a sign board above it.
Faces wind counter-clockwise seen from outside (only one side renders): every face is made through face(), which
checks its winding against the normal it should have.
Night layer G: every wall quad of a row with windows again, 0.08 studs in front, white; in Studio it wears a
SurfaceAppearance (atlas_night.png: alpha = the lit-window mask, emissive) and is shown only at night. F and R use a
plain TextureID, because a SurfaceAppearance hides the vertex colours (pilot, 2026-11-14) and the colours are the point.
Collision: the min-area rectangle, or 2-3 boxes when that rectangle wastes over 25% (L shapes): [x, y, z, sx, sy, sz, yaw].
"""
import math
import random
import zlib

import shapely
from shapely.geometry import Polygon, box as sbox
from shapely.geometry.polygon import orient

from glb import Mesh

GF, FH = 12.0, 9.0
PARAPET = 2.4
BAY = 12.0
WHITE = (255, 255, 255)


# ------------------------------------------------------------------ small vector helpers (x, z) and (x, y, z)
def sub2(a, b):
    return (a[0] - b[0], a[1] - b[1])


def len2(v):
    return math.hypot(v[0], v[1])


def unit2(v):
    l = len2(v)
    return (v[0] / l, v[1] / l) if l > 1e-9 else (1.0, 0.0)


def out2(d):
    """outward normal of an edge direction d on a counter-clockwise-from-above outline (x, z)."""
    return (-d[1], d[0])


def cross3(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def sub3(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def dot3(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def P(p, y):
    return (p[0], y, p[1])


def tint(rgb, k):
    return tuple(c * k for c in rgb)


def lerp3(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def face(m, pts, uvs, rgb, want, normals=None):
    """a triangle or quad that shows towards `want` (a world direction)."""
    n = cross3(sub3(pts[1], pts[0]), sub3(pts[2], pts[0]))
    if dot3(n, want) < 0:
        pts = pts[::-1]
        uvs = uvs[::-1]
        normals = normals[::-1] if normals else None
    if len(pts) == 3:
        m.tri(pts[0], pts[1], pts[2], uvs[0], uvs[1], uvs[2], rgb, normals)
    else:
        m.quad(pts[0], pts[1], pts[2], pts[3], uvs[0], uvs[1], uvs[2], uvs[3], rgb, normals)


# ------------------------------------------------------------------ outline cleaning
def clean_outline(pts, front):
    poly = Polygon(pts).buffer(0)
    if poly.geom_type == "MultiPolygon":
        poly = max(poly.geoms, key=lambda g: g.area)
    if poly.is_empty or poly.area < 4:
        return None, None
    poly = Polygon(poly.exterior.coords)  # no holes (courtyards are rare and cost walls)
    s = poly.simplify(0.5, preserve_topology=True)
    if s.is_valid and s.area > 0.8 * poly.area:
        poly = s
    poly = orient(poly, sign=-1.0)  # clockwise in (x, z) = counter-clockwise seen from above (north is -z)
    ring = list(poly.exterior.coords)[:-1]
    # merge edges under 1.5 studs
    changed = True
    while changed and len(ring) > 3:
        changed = False
        for i in range(len(ring)):
            a, b = ring[i], ring[(i + 1) % len(ring)]
            if len2(sub2(b, a)) < 1.5:
                trial = ring[:i] + ring[i + 1:] if i + 1 < len(ring) else ring[1:]
                tp = Polygon(trial)
                if len(trial) >= 3 and tp.is_valid and tp.area > 0.9 * poly.area:
                    ring = trial
                    changed = True
                    break
    fi = None
    if front is not None and 0 <= front < len(pts):
        a, b = pts[front], pts[(front + 1) % len(pts)]
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        best = 1e9
        for i in range(len(ring)):
            c, d = ring[i], ring[(i + 1) % len(ring)]
            m2 = ((c[0] + d[0]) / 2, (c[1] + d[1]) / 2)
            dist = len2(sub2(m2, mid))
            if dist < best:
                best, fi = dist, i
    return ring, fi


def is_round(ring, style):
    poly = Polygon(ring)
    per = poly.length
    circ = 4 * math.pi * poly.area / (per * per)
    return style == "round" or (len(ring) >= 10 and circ > 0.86)


def resample_round(ring):
    poly = Polygon(ring)
    n = max(16, min(32, int(round(poly.length / 6))))
    line = poly.exterior
    pts = [line.interpolate(i / n, normalized=True) for i in range(n)]
    r = [(p.x, p.y) for p in pts]
    return list(orient(Polygon(r), sign=-1.0).exterior.coords)[:-1]


def inset(ring, d):
    out = []
    n = len(ring)
    for i in range(n):
        p0, p1, p2 = ring[i - 1], ring[i], ring[(i + 1) % n]
        n1 = out2(unit2(sub2(p1, p0)))
        n2 = out2(unit2(sub2(p2, p1)))
        bis = unit2((n1[0] + n2[0], n1[1] + n2[1]))
        c = max(0.35, bis[0] * n1[0] + bis[1] * n1[1])
        out.append((p1[0] - bis[0] * d / c, p1[1] - bis[1] * d / c))
    return out


# ------------------------------------------------------------------ context
class Context:
    def __init__(self, plots, atlas):
        self.rows = atlas["rows"]
        self.polys = []
        for p in plots:
            try:
                g = Polygon(p["poly"]).buffer(0)
            except Exception:
                g = Polygon()
            self.polys.append(g)
        self.index = {p["id"]: i for i, p in enumerate(plots)}
        self.tree = shapely.STRtree(self.polys)

    def row(self, name):
        r = self.rows[name]
        return r["v0"], r["v1"]

    def neighbour_near(self, own, x, z, dist=1.2):
        pt = shapely.Point(x, z)
        for j in self.tree.query(pt, predicate="dwithin", distance=dist):
            if j != own and not self.polys[j].is_empty:
                return True
        return False


ROWS_UP = {"walkup": "walkup", "mass": "walkup", "shophouse": "walkup", "tower": "condo", "round": "condo",
           "house": "house", "villa": "house", "hall": "shopup", "shed": "roofc"}


# ------------------------------------------------------------------ pieces
GLOW_ROWS = {"walkup", "shopup", "condo", "house", "cage", "gshop", "gres"}
GLOW_OUT = 0.08  # the night overlay stands this far in front of the wall (flicker rule: 0.05 at least)


def wall_quad(m, ctx, a, b, y0, y1, row, u0, u1, rgb, normals=None, vspan=None, G=None):
    """a wall quad; with G (the night layer) rows with windows also get a see-through copy GLOW_OUT in front."""
    v0, v1 = ctx.row(row)
    if vspan:  # part of the row: (top fraction, bottom fraction)
        v0, v1 = v0 + (v1 - v0) * vspan[0], v0 + (v1 - v0) * vspan[1]
    d = unit2(sub2(b, a))
    n = out2(d)
    face(m, [P(a, y0), P(b, y0), P(b, y1), P(a, y1)], [(u0, v1), (u1, v1), (u1, v0), (u0, v0)], rgb, (n[0], 0, n[1]), normals)
    if G is not None and row in GLOW_ROWS:
        if normals:
            na, nb = (normals[0][0], normals[0][2]), (normals[1][0], normals[1][2])
        else:
            na = nb = n
        ga = (a[0] + na[0] * GLOW_OUT, a[1] + na[1] * GLOW_OUT)
        gb = (b[0] + nb[0] * GLOW_OUT, b[1] + nb[1] * GLOW_OUT)
        face(G, [P(ga, y0), P(gb, y0), P(gb, y1), P(ga, y1)], [(u0, v1), (u1, v1), (u1, v0), (u0, v0)], WHITE, (n[0], 0, n[1]), normals)


def bays_u(L, bay0, rng):
    """U range for an edge: a whole number of bays, starting at bay `bay0` (rows repeat every 8 bays)."""
    nb = max(1, int(round(L / BAY)))
    return bay0 / 8.0, (bay0 + nb) / 8.0


def flat_roof(m, ctx, ring, y, rgb, rng):
    v0, v1 = ctx.row("rooff")
    poly = Polygon(ring)
    minx, minz, maxx, maxz = poly.bounds
    uo = rng.random()
    k0 = math.floor(minz / 16.0)
    k1 = math.floor(maxz / 16.0)
    for k in range(k0, k1 + 1):
        piece = poly.intersection(sbox(minx - 1, k * 16.0, maxx + 1, (k + 1) * 16.0))
        if piece.is_empty:
            continue
        geoms = piece.geoms if hasattr(piece, "geoms") else [piece]
        for g in geoms:
            if g.geom_type != "Polygon" or g.area < 0.01:
                continue
            for t in shapely.constrained_delaunay_triangles(g).geoms:
                c = list(t.exterior.coords)[:3]
                pts = [P(p, y) for p in c]
                uvs = [(uo + p[0] / 256.0, v0 + (v1 - v0) * min(1.0, max(0.0, (p[1] - k * 16.0) / 16.0))) for p in c]
                face(m, pts, uvs, rgb, (0, 1, 0))


def cylinder(m, ctx, cx, cz, y0, r, h, rgb, sides=8):
    rp = ctx.rows["props"]
    u0, u1 = rp["regions"]["tank"]
    v0, v1 = rp["v0"], rp["v1"]
    pts = [(cx + r * math.cos(2 * math.pi * i / sides), cz + r * math.sin(2 * math.pi * i / sides)) for i in range(sides)]
    for i in range(sides):
        a, b = pts[i], pts[(i + 1) % sides]
        mid = ((a[0] + b[0]) / 2 - cx, (a[1] + b[1]) / 2 - cz)
        ua, ub = u0 + (u1 - u0) * i / sides, u0 + (u1 - u0) * (i + 1) / sides
        face(m, [P(a, y0), P(b, y0), P(b, y0 + h), P(a, y0 + h)], [(ua, v1), (ub, v1), (ub, v0), (ua, v0)], rgb, (mid[0], 0, mid[1]))
    for i in range(1, sides - 1):
        face(m, [P(pts[0], y0 + h), P(pts[i], y0 + h), P(pts[i + 1], y0 + h)], [(u0, v0), (u0 + 0.01, v0), (u0, v0 + 0.002)],
             tint(rgb, 0.9), (0, 1, 0))


def boxmesh(m, ctx, c, e1, hx, hz, y0, h, row_side, rgb, top_row="rooff", rng=None):
    """an upright box (stair room): centre c (x, z), axis e1, half sizes hx (along e1), hz."""
    e2 = (-e1[1], e1[0])
    corners = [(c[0] + e1[0] * sx * hx + e2[0] * sz * hz, c[1] + e1[1] * sx * hx + e2[1] * sz * hz)
               for sx, sz in ((1, 1), (-1, 1), (-1, -1), (1, -1))]
    ring = list(orient(Polygon(corners), sign=-1.0).exterior.coords)[:-1]
    uo = rng.random() if rng else 0
    for i in range(4):
        a, b = ring[i], ring[(i + 1) % 4]
        L = len2(sub2(b, a))
        wall_quad(m, ctx, a, b, y0, y0 + h, row_side, uo, uo + L / 96.0, rgb, vspan=(0, min(1.0, h / FH)))
    flat_roof(m, ctx, ring, y0 + h, tint(rgb, 0.85), rng or random.Random(1))
    return ring


def rect_frame(poly):
    rect = poly.minimum_rotated_rectangle
    c4 = list(rect.exterior.coords)[:4]
    s1 = sub2(c4[1], c4[0])
    s2 = sub2(c4[2], c4[1])
    if len2(s1) >= len2(s2):
        e1, hl, hw = unit2(s1), len2(s1) / 2, len2(s2) / 2
    else:
        e1, hl, hw = unit2(s2), len2(s2) / 2, len2(s1) / 2
    cx = sum(p[0] for p in c4) / 4
    cz = sum(p[1] for p in c4) / 4
    return (cx, cz), e1, hl, hw, rect


# ------------------------------------------------------------------ the building
def build_plot(plot, ctx, seed=None):
    rng = random.Random(seed if seed is not None else zlib.crc32(str(plot["id"]).encode()))
    ring, front = clean_outline([tuple(p) for p in plot["poly"]], plot.get("front"))
    F, R, G = Mesh(), Mesh(), Mesh()
    info = {"id": plot["id"], "skipped": False}
    if ring is None:
        info["skipped"] = True
        return F, R, G, [], info
    style = plot.get("style", "mass")
    floors = max(1, int(plot.get("floors", 2)))
    y0 = float(plot.get("y", 0.0))
    wall = tuple(plot.get("wall_colour", (236, 232, 222)))
    roofc = tuple(plot.get("roof_colour", (150, 150, 150)))
    shop = bool(plot.get("shop", False))
    roof = plot.get("roof", "flat")
    own = ctx.index.get(plot["id"], -1)
    rnd = is_round(ring, style)
    if rnd:
        ring = resample_round(ring)
        front = None
        style = "round" if style in ("mass", "tower", "round") else style
    poly = Polygon(ring)
    H = GF + FH * (floors - 1)
    top = y0 + H
    n = len(ring)
    c0 = poly.centroid
    centre = (c0.x, c0.y)

    # pitched roof only over rectangle-like outlines
    cen, e1, hl, hw, rect = rect_frame(poly)
    rectish = poly.area >= 0.8 * rect.area
    if roof in ("gable", "hip", "shed") and (not rectish or rnd):
        roof = "flat"
    if style in ("shed",) and roof == "flat" and rectish:
        roof = "shed"

    edges = []
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        d = sub2(b, a)
        L = len2(d)
        nrm = out2(unit2(d))
        party = False
        if L >= 3 and own >= 0:
            hits = 0
            for f in (0.25, 0.5, 0.75):
                x = a[0] + d[0] * f + nrm[0] * 1.5
                z = a[1] + d[1] * f + nrm[1] * 1.5
                if ctx.neighbour_near(own, x, z, 1.0):
                    hits += 1
            party = hits >= 2
        edges.append((a, b, L, nrm, party))
    if front is None and shop:
        # the longest edge that is not a party wall
        cands = [i for i, e in enumerate(edges) if not e[4]]
        front = max(cands or range(n), key=lambda i: edges[i][2])
    info["front"] = front
    info["party"] = sum(1 for e in edges if e[4])

    bay0 = rng.randrange(8)
    up_row = ROWS_UP.get(style, "walkup")
    if style == "mass" and floors > 8:
        up_row = "condo"
    if style == "mass" and floors <= 2:
        up_row = rng.choice(["walkup", "house"])
    # ------------------------------------------------ walls
    smooth = None
    for i, (a, b, L, nrm, party) in enumerate(edges):
        if rnd:
            na = unit2(sub2(a, centre))
            nb = unit2(sub2(b, centre))
            smooth = [(na[0], 0, na[1]), (nb[0], 0, nb[1]), (nb[0], 0, nb[1]), (na[0], 0, na[1])]
        for f in range(floors):
            fy0 = y0 if f == 0 else y0 + GF + FH * (f - 1)
            fy1 = y0 + GF + FH * f
            col = wall
            if f == 0:
                if shop and i == front:
                    row = "gshop"
                    col = lerp3(wall, WHITE, 0.65)
                elif party:
                    row = "party"
                elif style == "shed":
                    row = "roofc"
                elif style in ("house", "villa"):
                    row = "gres"
                else:
                    row = "gres"
            else:
                if party:
                    row = "party"
                elif style == "shophouse":
                    row = "shopup" if i == front else "walkup"
                else:
                    row = up_row
            if rnd:
                per = poly.length
                nbays = max(8, int(round(per / BAY)))
                cum = sum(e[2] for e in edges[:i])
                u0 = bay0 / 8 + cum / per * nbays / 8
                u1 = bay0 / 8 + (cum + L) / per * nbays / 8
            elif row in ("party", "roofc") or L < 5:
                if L < 5 and row not in ("roofc",):
                    row = "party" if f > 0 or not (shop and i == front) else row
                uo = rng.random()
                u0, u1 = uo, uo + L / (64.0 if row == "roofc" else 96.0)
            else:
                shift = 4 * (f % 2) if row in ("walkup", "cage", "shopup", "house", "condo") else 0
                u0, u1 = bays_u(L, bay0 + shift + 3 * i, rng)
            wall_quad(F, ctx, a, b, fy0, fy1, row, u0, u1, col, smooth, G=G)
    info["wall_quads"] = n * floors

    # ------------------------------------------------ balcony cages (walk-ups)
    cage_on = (style == "walkup" or (style == "mass" and 3 <= floors <= 8 and rng.random() < 0.5)) and floors >= 2
    if cage_on:
        ci = front if front is not None else max(range(n), key=lambda i: (not edges[i][4], edges[i][2]))
        a, b, L, nrm, party = edges[ci]
        if not party and L >= 14:
            d = unit2(sub2(b, a))
            nb = max(1, int((L - 4) // BAY))
            span = nb * BAY
            s0 = (L - span) / 2
            ca = (a[0] + d[0] * s0, a[1] + d[1] * s0)
            cb = (a[0] + d[0] * (s0 + span), a[1] + d[1] * (s0 + span))
            dep = 2.2
            oa = (ca[0] + nrm[0] * dep, ca[1] + nrm[1] * dep)
            ob = (cb[0] + nrm[0] * dep, cb[1] + nrm[1] * dep)
            v0, v1 = ctx.row("rooff")
            for f in range(1, floors):
                fy0 = y0 + GF + FH * (f - 1)
                fy1 = fy0 + FH
                u0 = (bay0 + 4 * (f % 2)) / 8
                wall_quad(F, ctx, oa, ob, fy0, fy1, "cage", u0, u0 + nb / 8, wall, G=G)
                # sides
                wall_quad(F, ctx, ca, oa, fy0, fy1, "cage", 0.02, 0.02 + dep / 96, wall)
                wall_quad(F, ctx, ob, cb, fy0, fy1, "cage", 0.1, 0.1 + dep / 96, wall)
                # the slab underneath (seen from the street)
                face(F, [P(ca, fy0), P(cb, fy0), P(ob, fy0), P(oa, fy0)], [(0, v0), (span / 256, v0), (span / 256, v1), (0, v1)],
                     tint(wall, 0.7), (0, -1, 0))
            ft = y0 + GF + FH * (floors - 1)
            face(F, [P(ca, ft), P(cb, ft), P(ob, ft), P(oa, ft)], [(0, v0), (span / 256, v0), (span / 256, v1), (0, v1)],
                 tint(roofc, 0.9), (0, 1, 0))
            info["cages"] = floors - 1

    # ------------------------------------------------ shops: awning and sign board
    if shop and front is not None:
        a, b, L, nrm, party = edges[front]
        if L >= 6:
            d = unit2(sub2(b, a))
            rp = ctx.rows["props"]
            pv0, pv1 = rp["v0"], rp["v1"]
            tu0, tu1 = rp["regions"]["tarp"]
            ea = (a[0] + d[0] * 0.6, a[1] + d[1] * 0.6)
            eb = (b[0] - d[0] * 0.6, b[1] - d[1] * 0.6)
            out = 3.2
            oa = (ea[0] + nrm[0] * out, ea[1] + nrm[1] * out)
            ob = (eb[0] + nrm[0] * out, eb[1] + nrm[1] * out)
            yi, yo = y0 + GF - 1.2, y0 + GF - 2.4
            tarp = rng.choice([(60, 120, 200), (50, 100, 180), (70, 150, 110), (220, 120, 50), (200, 70, 60), (170, 170, 170),
                               (60, 120, 200)])
            uu = (tu1 - tu0) * min(1.0, L / 24)
            face(R, [P(ea, yi), P(eb, yi), P(ob, yo), P(oa, yo)], [(tu0, pv0), (tu0 + uu, pv0), (tu0 + uu, pv1), (tu0, pv1)], tarp,
                 (nrm[0] * 0.3, 1, nrm[1] * 0.3))
            face(R, [P(ea, yi - 0.15), P(eb, yi - 0.15), P(ob, yo - 0.15), P(oa, yo - 0.15)],
                 [(tu0, pv0), (tu0 + uu, pv0), (tu0 + uu, pv1), (tu0, pv1)], tint(tarp, 0.55), (-nrm[0] * 0.3, -1, -nrm[1] * 0.3))
            face(R, [P(oa, yo - 0.15), P(ob, yo - 0.15), P(ob, yo), P(oa, yo)], [(tu0, pv0), (tu0 + uu, pv0), (tu0 + uu, pv1), (tu0, pv1)],
                 tint(tarp, 0.8), (nrm[0], 0, nrm[1]))
            if floors >= 2 and rng.random() < 0.6:
                sw = min(L - 2, rng.uniform(9, 16))
                s0 = (L - sw) / 2 + rng.uniform(-1, 1) * max(0, (L - sw) / 2 - 1)
                sa = (a[0] + d[0] * s0 + nrm[0] * 0.15, a[1] + d[1] * s0 + nrm[1] * 0.15)
                sb = (a[0] + d[0] * (s0 + sw) + nrm[0] * 0.15, a[1] + d[1] * (s0 + sw) + nrm[1] * 0.15)
                key = rng.choice(["signA", "signB"])
                su0, su1 = rp["regions"][key]
                sy0 = y0 + GF + 0.4
                sh = min(3.4, sw * 0.3)
                face(F, [P(sa, sy0), P(sb, sy0), P(sb, sy0 + sh), P(sa, sy0 + sh)], [(su0, pv1), (su1, pv1), (su1, pv0), (su0, pv0)],
                     WHITE, (nrm[0], 0, nrm[1]))
                info["sign"] = 1

    # ------------------------------------------------ roof
    boxes_top = top + PARAPET
    if roof == "flat":
        inner = inset(ring, 0.7)
        cv0, cv1 = ctx.row("cornice")
        pv0, pv1 = ctx.row("party")
        uo = rng.random()
        cum = 0.0
        for i, (a, b, L, nrm, party) in enumerate(edges):
            u0, u1 = uo + cum / 96, uo + (cum + L) / 96
            cum += L
            if rnd:
                na = unit2(sub2(a, centre))
                nb = unit2(sub2(b, centre))
                smooth = [(na[0], 0, na[1]), (nb[0], 0, nb[1]), (nb[0], 0, nb[1]), (na[0], 0, na[1])]
            wall_quad(F, ctx, a, b, top, top + PARAPET, "cornice", u0, u1, wall, smooth if rnd else None)
            ia, ib = inner[i], inner[(i + 1) % n]
            # inside face (looks inwards) and the cap
            face(R, [P(ib, top + 0.3), P(ia, top + 0.3), P(ia, top + PARAPET), P(ib, top + PARAPET)],
                 [(u1, pv0 + (pv1 - pv0) * 0.3), (u0, pv0 + (pv1 - pv0) * 0.3), (u0, pv0), (u1, pv0)], tint(wall, 0.9), (-nrm[0], 0, -nrm[1]))
            face(R, [P(a, top + PARAPET), P(b, top + PARAPET), P(ib, top + PARAPET), P(ia, top + PARAPET)],
                 [(u0, cv0), (u1, cv0), (u1, cv0 + 0.001), (u0, cv0 + 0.001)], wall, (0, 1, 0))
        try:
            flat_roof(R, ctx, inner if Polygon(inner).is_valid else ring, top + 0.3, roofc, rng)
        except Exception:
            flat_roof(R, ctx, ring, top + 0.3, roofc, rng)
        # stair room and tanks
        if style in ("walkup", "mass", "tower", "shophouse", "hall") and not rnd and floors >= 2:
            core = poly.buffer(-4.5)
            tank_cols = [(46, 48, 52), (40, 90, 170), (230, 230, 226), (46, 48, 52), (60, 110, 190), (150, 150, 146)]
            spots = []
            if not core.is_empty and core.area > 30:
                rp_ = core.representative_point()
                sc = (rp_.x, rp_.y)
                hx = min(3.6, max(2.4, hl * 0.25))
                boxmesh(R, ctx, sc, e1, hx, 3.4, top + 0.3, 8.0, "party", tint(wall, 0.95), rng=rng)
                spots.append((sc[0], sc[1], 4.5))
                tc = rng.choice(tank_cols)
                cylinder(R, ctx, sc[0] + e1[0] * (hx - 2.0), sc[1] + e1[1] * (hx - 2.0), top + 8.3, rng.uniform(1.6, 2.0), rng.uniform(3.4, 4.4), tc)
                boxes_top = max(boxes_top, top + 8.3)
            free = poly.buffer(-3.0)
            ntank = min(3, int(poly.area / 900)) if not free.is_empty else 0
            for _ in range(ntank):
                minx, minz, maxx, maxz = free.bounds
                for _try in range(12):
                    x, z = rng.uniform(minx, maxx), rng.uniform(minz, maxz)
                    if free.contains(shapely.Point(x, z)) and all((x - s[0]) ** 2 + (z - s[1]) ** 2 > (s[2] + 3) ** 2 for s in spots):
                        r = rng.uniform(1.4, 2.0)
                        cylinder(R, ctx, x, z, top + 0.3, r, rng.uniform(3.0, 4.2), rng.choice(tank_cols))
                        spots.append((x, z, r))
                        break
    else:
        o = 1.2
        HL, HW = hl + o, hw + o
        e2 = (-e1[1], e1[0])
        if roof == "shed":
            rise = max(1.5, min(5.0, 0.5 * HW))
        else:
            rise = max(2.5, min(9.0, 0.55 * HW))
        ye = top - rise * o / HW if roof != "shed" else top - 0.2

        def at(s1, s2):
            return (cen[0] + e1[0] * s1 + e2[0] * s2, cen[1] + e1[1] * s1 + e2[1] * s2)

        def height(p):
            q = sub2(p, cen)
            d1 = abs(q[0] * e1[0] + q[1] * e1[1])
            s2 = q[0] * e2[0] + q[1] * e2[1]
            if roof == "shed":
                return ye + rise * (HW - s2) / (2 * HW)
            hgt = ye + rise * (HW - abs(s2)) / HW
            if roof == "hip":
                hgt = min(hgt, ye + rise * (HL - d1) / HW)
            return hgt

        rv0, rv1 = ctx.row("roofc")
        under = tint(roofc, 0.45)
        rr = rng.random()

        def rface(pts2, ys, axis, want):
            pts = [P(p, y) for p, y in zip(pts2, ys)]
            uvs = [(rr + ((p[0] - cen[0]) * axis[0] + (p[1] - cen[1]) * axis[1]) / 64.0,
                    rv0 + (rv1 - rv0) * (1 - (y - ye) / rise)) for p, y in zip(pts2, ys)]
            face(R, pts, uvs, roofc, want)
            face(R, pts, uvs, under, (-want[0], -want[1], -want[2]))

        E1, E2, E3, E4 = at(HL, HW), at(-HL, HW), at(-HL, -HW), at(HL, -HW)
        if roof == "shed":
            rface([E1, E2, E3, E4], [ye, ye, ye + rise, ye + rise], e1, (e2[0] * 0.3, 1, e2[1] * 0.3))
            ridge_y = ye + rise
        else:
            r_len = HL - HW if roof == "hip" else HL
            r_len = max(0.0, r_len)
            R1, R2 = at(r_len, 0), at(-r_len, 0)
            yr = ye + rise
            rface([E1, E2, R2, R1], [ye, ye, yr, yr], e1, (e2[0] * 0.5, 1, e2[1] * 0.5))
            rface([E3, E4, R1, R2], [ye, ye, yr, yr], e1, (-e2[0] * 0.5, 1, -e2[1] * 0.5))
            if roof == "hip" and HL - HW >= 0:
                rface([E4, E1, R1], [ye, ye, yr], e2, (e1[0] * 0.5, 1, e1[1] * 0.5))
                rface([E2, E3, R2], [ye, ye, yr], e2, (-e1[0] * 0.5, 1, -e1[1] * 0.5))
            elif roof == "hip":
                pass
            ridge_y = yr
        boxes_top = ridge_y
        # wall infill from the wall top up under the roof (gable triangles, shed sides)
        pv0, pv1 = ctx.row("party")
        uo = rng.random()
        for (a, b, L, nrm, party) in edges:
            pts = [a]
            if roof == "gable":
                qa, qb = sub2(a, cen), sub2(b, cen)
                sa = qa[0] * e2[0] + qa[1] * e2[1]
                sb = qb[0] * e2[0] + qb[1] * e2[1]
                if sa * sb < 0:
                    t = sa / (sa - sb)
                    pts.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
            pts.append(b)
            for p, q in zip(pts[:-1], pts[1:]):
                hp, hq = height(p) - 0.05, height(q) - 0.05
                if max(hp, hq) - top < 0.15:
                    continue
                hp, hq = max(hp, top), max(hq, top)
                Lpq = len2(sub2(q, p))
                ua = uo + len2(sub2(p, a)) / 96
                ub = ua + Lpq / 96
                vv = lambda y: pv0 + (pv1 - pv0) * min(1.0, max(0.0, (top + rise - y) / FH))
                pts3 = [P(p, top), P(q, top), P(q, hq), P(p, hp)]
                uvs = [(ua, vv(top)), (ub, vv(top)), (ub, vv(hq)), (ua, vv(hp))]
                if hp - top < 0.05:
                    pts3, uvs = [pts3[0], pts3[1], pts3[2]], [uvs[0], uvs[1], uvs[2]]
                elif hq - top < 0.05:
                    pts3, uvs = [pts3[0], pts3[1], pts3[3]], [uvs[0], uvs[1], uvs[3]]
                face(F, pts3, uvs, wall, (nrm[0], 0, nrm[1]))

    # ------------------------------------------------ collision boxes
    boxes = collision(poly, y0, boxes_top)
    info.update(style=style, floors=floors, H=H, roof=roof, round=rnd, F=F.tris, R=R.tris, G=G.tris, boxes=len(boxes), verts=len(ring))
    return F, R, G, boxes, info


def _rect_box(g):
    cen, e1, hl, hw, _ = rect_frame(g)
    return cen, e1, hl, hw


def collision(poly, y0, ytop):
    """1 box (min-area rectangle) or 2-3 boxes for L / T / U shapes: [x, y, z, sx, sy, sz, yaw]."""
    cen, e1, hl, hw, rect = rect_frame(poly)
    best = [(cen, e1, hl, hw)]
    best_cost = rect.area - poly.area
    if poly.area < 0.75 * rect.area:
        e2 = (-e1[1], e1[0])
        for axis, half in ((e1, hl), (e2, hw)):
            for cuts in ([0.5], [1 / 3.0], [2 / 3.0], [1 / 3.0, 2 / 3.0]):
                ks = [0.0] + cuts + [1.0]
                pieces = []
                cost = 0.0
                ok = True
                for k0, k1 in zip(ks[:-1], ks[1:]):
                    s0, s1 = -half + 2 * half * k0, -half + 2 * half * k1
                    other = hw if axis is e1 else hl
                    oth = (-axis[1], axis[0])
                    corners = []
                    for s, t in ((s0, -other - 1), (s1, -other - 1), (s1, other + 1), (s0, other + 1)):
                        corners.append((cen[0] + axis[0] * s + oth[0] * t, cen[1] + axis[1] * s + oth[1] * t))
                    g = poly.intersection(Polygon(corners))
                    if g.is_empty or g.area < 1:
                        continue
                    pc = _rect_box(g)
                    pieces.append(pc)
                    cost += 4 * pc[2] * pc[3] - g.area
                if ok and pieces and cost + 40 * (len(pieces) - 1) < best_cost:
                    best, best_cost = pieces, cost + 40 * (len(pieces) - 1)
    # (batch 1 check, 14 Nov 2026: a U-shaped plot's boxes covered the dead-end road inside the U, an invisible wall on a
    # road; 116 boxes were 16%+ over a carriageway.) Every box whose rectangle still overshoots its piece of the outline by
    # more than 12% is split again (recursively, longer axis, best of 1/3, 1/2, 2/3), up to 8 boxes a building.
    def overshoot(g):
        cen2, e12, hl2, hw2, rect2 = rect_frame(g)
        return rect2.area - g.area, (cen2, e12, hl2, hw2)

    def fit(g, depth):
        over, box = overshoot(g)
        if depth == 0 or over <= 0.12 * (g.area + over) or g.area < 40:
            return [box]
        cen2, e12, hl2, hw2 = box
        e22 = (-e12[1], e12[0])
        axis, half, other = (e12, hl2, hw2) if hl2 >= hw2 else (e22, hw2, hl2)
        oth = (-axis[1], axis[0])
        best_split, best_over = None, over
        for k in (1 / 3.0, 0.5, 2 / 3.0):
            parts = []
            for s0, s1 in ((-half - 1, -half + 2 * half * k), (-half + 2 * half * k, half + 1)):
                corners = [(cen2[0] + axis[0] * s + oth[0] * t, cen2[1] + axis[1] * s + oth[1] * t)
                           for s, t in ((s0, -other - 1), (s1, -other - 1), (s1, other + 1), (s0, other + 1))]
                q = g.intersection(Polygon(corners))
                if q.geom_type == 'MultiPolygon':
                    q = max(q.geoms, key=lambda x: x.area)
                if q.geom_type == 'Polygon' and q.area >= 1:
                    parts.append(q)
            if len(parts) == 2:
                o = sum(overshoot(q)[0] for q in parts)
                if o < best_over * 0.8:
                    best_split, best_over = parts, o
        if not best_split:
            return [box]
        return fit(best_split[0], depth - 1) + fit(best_split[1], depth - 1)

    refined = []
    for b in best:
        cen2, e12, hl2, hw2 = b
        rect2 = Polygon([(cen2[0] + e12[0] * s * hl2 - e12[1] * t * hw2, cen2[1] + e12[1] * s * hl2 + e12[0] * t * hw2)
                         for s, t in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
        piece = poly.intersection(rect2)
        if piece.geom_type == 'MultiPolygon':
            for q in piece.geoms:
                if q.area >= 1:
                    refined += fit(q, 3)
        elif piece.geom_type == 'Polygon' and piece.area >= 1:
            refined += fit(piece, 3)
        else:
            refined.append(b)
    if refined:
        best = refined[:8]
    out = []
    h = ytop - y0 + 1.0
    for (c, e, a, b) in best:
        yaw = math.atan2(-e[1], e[0])
        out.append([round(c[0], 2), round(y0 - 1.0 + h / 2, 2), round(c[1], 2), round(2 * a, 2), round(h, 2), round(2 * b, 2),
                    round(yaw, 4)])
    return out
