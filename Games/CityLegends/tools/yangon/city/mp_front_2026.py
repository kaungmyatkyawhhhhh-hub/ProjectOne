"""Myanmar Plaza corner front, current design (2026-11-27, owner: "the myanmar plaza thing is on the road. also that
thing is from the 2019 myanmar plaza. the new myanmar plaza is different"; vault
`City Legends/2026-11-27 Myanmar Plaza front - current design, off the road.md`).

The old corner sign (mc3d.plinth: a 4 m maroon granite ring wall with the white HAGL MYANMAR CENTRE band, hedge and
lawn round it, a teal channel inside; MCDrone.fountain's round fountain and hedge ring) is the 2016-2025 design and,
at 1:1, its west end and lawn ran 6 studs onto Kabar Aye Pagoda Road (the game's roads are wider than the real ones).
Current satellite (Google Maps Airbus/Maxar, Esri World Imagery; 2026) shows a low open semicircle instead:
pale paving, five radial sectors (paved / lawn / paved / lawn / paved), a low curved inner wall, a teal pool wedge
in the middle facing the junction. No tall wall, no letters (no clear current street photo: kept plain).

  YANGON_SCALE=1to1 python mp_front_2026.py
    -> imports/sync/landmarks/mc1/mc1_front26.glb  new ground meshes (MAR paving, GRN white kerbs / wall, LAW, POL, WAT)
                                                   + patched HDG / LAW / LIT / MUW / PGR (the old plinth triangles out)
    -> imports/sync/landmarks/mc1/mc1_front26.json mesh info, which old meshes go whole, collision boxes
Everything new stays 1 stud inside the site outline (LAY["site"]) and 1 stud off every road / pavement box.
Studio: tools/yangon/MPFront2026.luau."""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from shapely.geometry import Polygon  # noqa: E402
from shapely.ops import unary_union  # noqa: E402
import geo as GEO  # noqa: E402

assert GEO.ONE_TO_ONE, "run with YANGON_SCALE=1to1"
import onetoone as X1  # noqa: E402
from geom3d import Geo, raster_boxes  # noqa: E402
from glb import Mesh, write_glb, code  # noqa: E402
from mc_portal_strip import read, D  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

ROOT = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "myanmar_centre")
LAY = json.load(open(os.path.join(ROOT, "layout_fit_1to1.json")))
S = X1.S
PLANE = LAY["ground"]["plane"]
OCX, OCY = LAY["plinth_c"][0] * S, LAY["plinth_c"][1] * S        # model studs (centre of the old ring)
_f = LAY["face"]
FA = math.atan2(_f[1], _f[0])                                       # facing the junction (model frame)
CW = (X1.OX1 + OCX, X1.OZ1 - OCY)                                   # world X, Z: 34717.5, 27127.5 (old ring)
# the new centre: 6.3 studs (2.1 m) east of the old ring's, the smallest move that keeps the beds, wall and pool
# whole inside the lot (the game's wider Kabar Aye Pagoda Road pavement covers the real west bed's spot)
SHIFT = (6.0, -2.0)
CX, CY = OCX + SHIFT[0], OCY + SHIFT[1]
FW = (math.cos(FA), -math.sin(FA))                                  # facing, world XZ

SITE = unary_union([Polygon([(x * S, y * S) for x, y in r]).buffer(0) for r in LAY["site"]])


def _road_boxes():
    """The game's road (R) and pavement (P) collision boxes round the corner (Studio Roads.Collide RCol, 27 Nov:
    world x y z sx sy sz rightX rightZ kind) -> model-frame footprints. The site outline runs along the kerb on
    Kabar Aye Pagoda Road, so the pavement boxes are taken out too."""
    out = []
    for ln in open(os.path.join(ROOT, "mp_front_roadboxes.txt")):
        x, _y, z, sx, _sy, sz, rx, rz, _k = ln.split()
        x, z, sx, sz, rx, rz = map(float, (x, z, sx, sz, rx, rz))
        ux, uz = (rx, rz), (-rz, rx)
        pts = [(x + ux[0] * a * sx / 2 + uz[0] * b * sz / 2, z + ux[1] * a * sx / 2 + uz[1] * b * sz / 2)
               for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        out.append(Polygon([(X - X1.OX1, -(Z - X1.OZ1)) for X, Z in pts]))
    return unary_union(out)


ROADS = _road_boxes()
LOT = SITE.buffer(-1.0).difference(ROADS.buffer(1.0))

# the design in true studs (3 a metre), from the satellite (outer ring ~12.5 m, sectors 6.6-10.4 m, inner wall
# ~5.5-5.9 m, pool wedge 1.5-5 m)
R_FILL = 49.5          # paving fills the old lawn / hedge zone out to the site edge
R_IN_WALL = (16.5, 17.7)
WALL_TOP = 2.7         # ~0.9 m
BEDS = ()   # (27 Nov, owner: "there is no grass on myanmar plaza area") the satellite's two lawn sectors are paved: was ((-54, -18), (18, 54))
BED_R = (19.8, 31.2)
POOL = (-22, 22, 4.5, 15.0)
Z_SLAB = 0.20          # the old plaza paving (PAV) is at 0.06: 0.14 apart
Z_FCT = 0.13           # the forecourt paving (owner: no grass on the Plaza area): 0.07 over PAV, 0.07 under the platform
# the Plaza's front only (Kabar Aye Pagoda Road and the corner, world x < 34900, z < 27460): the pavement plane fits
# there (further south and east the pavements are up to 3 studs off it)
FRONT = Polygon([(34560 - X1.OX1, -(27040 - X1.OZ1)), (34900 - X1.OX1, -(27040 - X1.OZ1)),
                 (34900 - X1.OX1, -(27460 - X1.OZ1)), (34560 - X1.OX1, -(27460 - X1.OZ1))])
Z_UNDER = -0.30        # the edge fill inside the site: 0.36 under the plaza paving, so it shows only in its gaps


def _edge_fill():
    """(27 Nov, round 2) The plaza paving (mc3d PAV) stops 2-5 studs short of the site edge along the roads, and the
    gap showed the terrain 3-4 studs below (green-brown Ground) all along Kabar Aye Pagoda Road; the forecourt in front
    of the mall's north-west corner had holes too. A paving sheet under the PAV level fills the site's whole front
    (FRONT box, buildings out); where PAV lies over it, it stays hidden."""
    full = SITE.buffer(16, join_style=2).buffer(-16, join_style=2)
    blds = unary_union([Polygon([(x * S, y * S) for x, y in LAY[k]]).buffer(0) for k in ("podium", "A", "B", "melia_osm")])
    return full.intersection(FRONT).difference(blds).difference(ROADS.buffer(0.3)).buffer(-0.01)


def _pav_footprint():
    """The placed plaza paving (mc1_2.glb PAV, up-facing triangles) as a model-frame shape."""
    name, c, P, N, U, C, T = read(os.path.join(D, "mc1_2.glb"), "PAV_mc1gs98")
    tris = []
    for k in range(0, len(T), 3):
        if N[T[k]][1] < 0.9:
            continue
        pts = [(c[0] - P[i][0] - X1.OX1, -(c[2] - P[i][2] - X1.OZ1)) for i in T[k:k + 3]]
        q = Polygon(pts)
        if q.area > 1e-6:
            tris.append(q.buffer(0.002))
    return unary_union(tris)


def _pod_holes():
    """(27 Nov, round 2) In front of the mall's north-west chamfer the podium outline is not built (no floor, no
    paving): terrain showed through. Paving there, inside the podium outline but outside the shopfront line (POD 3.5
    in) and the plaza paving; laid at the mall floor level - 0.12 (or the pavement plane - 0.3 where that is lower),
    so it stays under the floor band and the paving wherever they exist."""
    pod = Polygon([(x * S, y * S) for x, y in LAY["podium"]]).buffer(0)
    # (the whole podium in the front box: where the mall's floor exists at y0 this sheet is 0.12 under it, hidden)
    return pod.intersection(FRONT).difference(_pav_footprint()).difference(ROADS.buffer(0.3)).buffer(-0.01)


def _floor_footprint():
    """Everything the mall model lays at ground-floor level (up-facing triangles within 1.5 of y0, any group), from
    mc1.glb: where the podium outline is really built."""
    import struct
    y0 = LAY["ground"]["y0"]
    path = os.path.join(D, "mc1.glb")
    b = open(path, "rb").read()
    js = json.loads(b[20:20 + struct.unpack("<I", b[12:16])[0]])
    tris = []
    for nd in js["nodes"]:
        if "mesh" not in nd:
            continue
        name, c, P, N, U, C, T = read(path, nd["name"])
        for k in range(0, len(T), 3):
            if N[T[k]][1] < 0.9:
                continue
            ys = [c[1] + P[i][1] for i in T[k:k + 3]]
            if abs(sum(ys) / 3 - y0) > 1.5:
                continue
            q = Polygon([(c[0] - P[i][0] - X1.OX1, -(c[2] - P[i][2] - X1.OZ1)) for i in T[k:k + 3]])
            if q.area > 1e-6:
                tris.append(q.buffer(0.002))
    return unary_union(tris)


def _cap_under(g, grp, shape, y0):
    """A cap whose height is min(Z_UNDER over the plane, y0 - 0.12 world) at each vertex (ground layer)."""
    import shapely
    geoms = [shape] if shape.geom_type == "Polygon" else list(getattr(shape, "geoms", []))
    for G in geoms:
        if G.geom_type != "Polygon" or G.area < 1e-3:
            continue
        for t in shapely.constrained_delaunay_triangles(G).geoms:
            c3 = list(t.exterior.coords)[:3]
            a = (c3[1][0] - c3[0][0]) * (c3[2][1] - c3[0][1]) - (c3[1][1] - c3[0][1]) * (c3[2][0] - c3[0][0])
            if abs(a) < 1e-9:
                continue
            if a < 0:
                c3 = [c3[0], c3[2], c3[1]]
            v = []
            for x, y in c3:
                X, Z = X1.OX1 + x, X1.OZ1 - y
                v.append((x, y, min(Z_UNDER, y0 - 0.12 - X1.plane_y(PLANE, X, Z))))
            g.tri(grp, v[0], v[1], v[2])


def _flat_boxes(shape, ztop, out):
    """Raster collision boxes for a paving cap on the sloped pavement plane: each run cut into pieces of at most 12
    studs, each set at the plane under its own middle (a 130-stud flat box was 0.7 off at its ends)."""
    for cx, cy, z0, sx, sy, sz, _ in raster_boxes(shape, -1.0, ztop, 2.0):
        k = max(1, int(math.ceil(sx / 12.0)))
        for i in range(k):
            px = cx - sx / 2 + sx * (i + 0.5) / k
            X, Z = X1.OX1 + px, X1.OZ1 - cy
            out.append([round(X, 2), round(X1.plane_y(PLANE, X, Z) + z0 + sz / 2, 2), round(Z, 2), round(sx / k, 2),
                        round(sz, 2), round(sy, 2), 0])


def _forecourt():
    """(27 Nov) The ground between the corner plot and the mall plot (the two site polygons leave a 25-stud strip of
    terrain grass in front of the mall) and the corner plot round the platform: grey plaza paving (PAV), as the
    satellite's paved forecourt. The two polygons are closed only near the corner (world x < 34860, z < 27260), then
    the road / pavement boxes (1 stud), the buildings and the platform come out."""
    from shapely.geometry import box as sbox
    near = sbox(34560 - X1.OX1, -(27260 - X1.OZ1), 34860 - X1.OX1, -(27040 - X1.OZ1))
    closed = SITE.buffer(30, join_style=2).buffer(-30, join_style=2).intersection(near)   # 30: the notch at the mall's NW corner (16 left it open)
    blds = unary_union([Polygon([(x * S, y * S) for x, y in LAY[k]]).buffer(0) for k in ("podium", "A", "B", "melia_osm")])
    main = max(SITE.geoms, key=lambda q: q.area) if SITE.geom_type != "Polygon" else Polygon()
    fct = closed.difference(main.buffer(-0.01))
    # (27 Nov, round 2) the verge: the site outline stops 1-6 studs short of the pavement, and that strip showed
    # terrain grass all along Kabar Aye Pagoda Road. Paved too, wherever the strip borders a pavement / road box.
    full = SITE.buffer(16, join_style=2).buffer(-16, join_style=2)
    verge = full.buffer(10, join_style=2).difference(full).intersection(ROADS.buffer(10)).intersection(FRONT)
    # (the verge strip outside the site is NOT paved: between the road boxes it reached onto the road mesh, which the
    # boxes don't fully cover; the gaps it was for are inside the site and are filled by _edge_fill / _pod_holes)
    del verge
    return fct.difference(blds).difference(ROADS.buffer(0.3)).buffer(-0.01)


class GG(Geo):
    """All triangles on the pavement plane (onetoone.export's ground layer)."""

    def __init__(self):
        super().__init__()
        self.gg = {}

    def tri(self, grp, a, b, c):
        self.gg.setdefault(grp, []).append((tuple(a), tuple(b), tuple(c)))


def sector(r0, r1, t0, t1, step=2.0):
    n = max(2, int(math.ceil((t1 - t0) / step)))
    angs = [math.radians(t0 + (t1 - t0) * k / n) + FA for k in range(n + 1)]
    out = [(CX + r1 * math.cos(a), CY + r1 * math.sin(a)) for a in angs]
    if r0 > 0:
        out += [(CX + r0 * math.cos(a), CY + r0 * math.sin(a)) for a in reversed(angs)]
    else:
        out.append((CX, CY))
    return Polygon(out).buffer(0)


def build():
    g = GG()
    beds = [sector(BED_R[0], BED_R[1], a, b).intersection(LOT) for a, b in BEDS]
    pool = sector(POOL[2], POOL[3], POOL[0], POOL[1]).intersection(LOT)
    wall = sector(R_IN_WALL[0], R_IN_WALL[1], -80, 80).intersection(LOT)
    slab = sector(0, R_FILL, -90, 90).intersection(LOT)
    top = slab.difference(unary_union(beds + [pool, wall]))
    fct = _forecourt().difference(slab.buffer(0.01))
    g.capshape("PAV", fct, Z_FCT)
    g.wallshape("PAV", fct, -1.0, Z_FCT)
    under = _edge_fill().difference(fct.buffer(0.01)).difference(slab.buffer(0.01))
    g.capshape("PAV", under, Z_UNDER)
    g.wallshape("PAV", under, -1.5, Z_UNDER)
    holes = _pod_holes().difference(under.buffer(0.01)).difference(fct.buffer(0.01)).difference(slab.buffer(0.01))
    _cap_under(g, "PAV", holes, LAY["ground"]["y0"])
    g.capshape("MAR", top, Z_SLAB)
    g.wallshape("MAR", slab, -1.0, Z_SLAB)
    for b in beds:
        inner = b.buffer(-0.5, join_style=2)
        g.capshape("GRN", b.difference(inner), 0.6)
        g.wallshape("GRN", b, Z_SLAB, 0.6)
        g.wallshape("GRN", inner, 0.5, 0.6, inward=True)
        g.capshape("LAW", inner, 0.5)
    inner = pool.buffer(-0.75, join_style=2)
    g.capshape("GRN", pool.difference(inner), 1.0)
    g.wallshape("GRN", pool, Z_SLAB, 1.0)
    g.wallshape("GRN", inner, 0.3, 1.0, inward=True)
    g.capshape("POL", inner, 0.3)
    g.capshape("WAT", inner, 0.75)
    g.capshape("GRN", wall, WALL_TOP)
    g.wallshape("GRN", wall, Z_SLAB, WALL_TOP)
    # collision: the inner wall in short straight pieces, the pool rim as a ring of boxes (world, ground based)
    coll = []
    for k in range(16):
        a0, a1 = -80 + 160 * k / 16, -80 + 160 * (k + 1) / 16
        rm = sum(R_IN_WALL) / 2
        p = [(CX + rm * math.cos(math.radians(a) + FA), CY + rm * math.sin(math.radians(a) + FA)) for a in (a0, a1)]
        m = ((p[0][0] + p[1][0]) / 2, (p[0][1] + p[1][1]) / 2)
        if not LOT.contains(Polygon([(m[0] + 0.1, m[1]), (m[0], m[1] + 0.1), (m[0] - 0.1, m[1])])):
            continue
        coll.append((m, math.dist(p[0], p[1]) + 0.2, R_IN_WALL[1] - R_IN_WALL[0], WALL_TOP, math.atan2(p[1][1] - p[0][1], p[1][0] - p[0][0])))
    boxes = []
    for (mx, my), L, w, h, yaw in coll:
        X, Z = X1.OX1 + mx, X1.OZ1 - my
        boxes.append([round(X, 2), round(X1.plane_y(PLANE, X, Z) + h / 2, 2), round(Z, 2), round(L, 2), round(h, 2), round(w, 2), round(yaw, 4)])  # CFrame.Angles(0, yaw, 0) lays X along (dx, -dy) world
    # the paving: walkable at its own top (the old lawn ring was walked on the terrain 0.7 below)
    _flat_boxes(slab, Z_SLAB, boxes)
    _flat_boxes(fct, Z_FCT, boxes)
    return g, boxes, {"holes": holes.area, "under": under.area, "fct": fct.area, "slab": slab.area, "beds": [b.area for b in beds], "pool": pool.area, "wall": wall.area}


def old_zone(t):
    """An old plinth triangle (world): the ring wall, its cap, band, hedge, lawns, channel, uplights, centre plinth."""
    gx = sum(p[0] for p in t) / 3
    gz = sum(p[2] for p in t) / 3
    dx, dz = gx - CW[0], gz - CW[1]
    r = math.hypot(dx, dz)
    d = dx * FW[0] + dz * FW[1]
    if 29.0 <= r <= 50.0 and d >= -2.5:
        return True
    return abs(dx) < 3.7 and abs(dz) < 3.7


def patch(path, prefix):
    name, c, P, N, U, C, T = read(path, prefix)
    m = Mesh()
    kept = gone = 0
    for k in range(0, len(T), 3):
        ids = T[k:k + 3]
        Wp = [(c[0] - P[i][0], c[1] + P[i][1], c[2] - P[i][2]) for i in ids]
        if old_zone(Wp):
            gone += 1
            continue
        kept += 1
        i0 = len(m.P)
        m.P += Wp
        m.N += [(-N[i][0], N[i][1], -N[i][2]) for i in ids]
        m.U += [U[i] for i in ids]
        m.C += [C[i][:3] for i in ids]
        m.T += [i0, i0 + 1, i0 + 2]
    grp = name.split("_")[0]
    print(name, "kept", kept, "dropped", gone)
    if not kept:
        return name, None, None, gone
    lo, hi = m.box()
    cc = [(lo[i] + hi[i]) / 2 for i in range(3)]
    ss = [hi[i] - lo[i] for i in range(3)]
    return name, code(grp, "mpp" + name.split("_")[1][3:], cc, ss), m, gone


def main():
    g, boxes, areas = build()
    out = os.path.join(D, "mc1_front26.glb")
    files = X1.export(g, LAY["ground"]["y0"], PLANE, out, "mpf")
    print(files, "flicker", g.flicker, areas)
    assert g.flicker[2] == 0
    # the patched old meshes go in a second file (same upload)
    f2 = os.path.join(D, "mc1_2.glb")
    patched, emptied = [], []
    for pre in ("HDG_mc1gs91", "LAW_mc1gs94", "LIT_mc1gs95", "MUW_mc1gs96", "PGR_mc1gs100"):
        old, new, m, gone = patch(f2, pre)
        if gone and m is None:
            emptied.append(old)
        elif gone:
            patched.append((old, new, m))
    pinfo = write_glb(os.path.join(D, "mc1_front26_patch.glb"), [(n, m) for _, n, m in patched])
    # self-check: nothing new outside the site, the old wall ring is out of every patched mesh
    for _, _, m in patched:
        for k in range(0, len(m.T), 3):
            assert not old_zone([m.P[i] for i in m.T[k:k + 3]])
    json.dump({"new": files, "patched": {o: n for o, n, _ in patched}, "patch_info": pinfo,
               "whole": ["PBD_mc1gs99", "POL_mc1gs101", "WAT_mc1gs104", "ORG_mcsggs5", "HGL_mcsggs4", "BLU_mcsggs1",
                         "GLD_mcsggs2", "GLD_mcsggs3"] + emptied,
               "coll": boxes, "centre": CW, "face": FW, "areas": areas},
              open(os.path.join(D, "mc1_front26.json"), "w"), indent=1)
    print("coll", len(boxes))


if __name__ == "__main__":
    main()
