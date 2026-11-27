"""Straight lines on Kabar Aye Pagoda Road in front of Myanmar Plaza, into the placed line mesh (27 Nov 2026; see
paint_straight.py). Mesh-only patch of cell 22x17's white line mesh (RMeshL, from roads05_RBM/glb/roads05_2.glb):
the triangles of the moved paint items (roads05_RBM/paint.json.bak27 polygons) come out, the straightened polygons
(paint.json, items marked "straight") go in, laid on the cell's road surface mesh (R, roads05_3.glb) at the same
height over it as the old paint. Nothing else in the cell changes.
    python mp_lines_patch.py   -> imports/sync/landmarks/mc1/mp_lines_L22x17.glb (+ .json)
Studio: ApplyMesh onto Yangon1to1.Roads.Meshes.Cell_22x17.RMeshL (old MeshId kept in attribute OldMeshId_lines27)."""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from shapely.geometry import Polygon, Point  # noqa: E402
from shapely.strtree import STRtree  # noqa: E402
from shapely.ops import unary_union  # noqa: E402
from glb import Mesh, write_glb, code  # noqa: E402
from mc_portal_strip import read  # noqa: E402

B = os.path.join(HERE, "..", "..", "..", "build", "city_1to1", "roads05_RBM")
OUT = os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "mc1", "mp_lines_L22x17.glb")
STEP = 3.0


def tris(path, prefix):
    name, c, P, N, U, C, T = read(path, prefix)
    out = []
    for k in range(0, len(T), 3):
        out.append([(c[0] - P[i][0], c[1] + P[i][1], c[2] - P[i][2]) for i in T[k:k + 3]])
    return name, out, [(C[T[k]][:3], [U[i] for i in T[k:k + 3]]) for k in range(0, len(T), 3)]


def main():
    new = json.load(open(os.path.join(B, "paint.json")))["items"]
    old = json.load(open(os.path.join(B, "paint.json.bak27")))["items"]
    idx = [i for i, it in enumerate(new) if it.get("straight")]
    oldp = unary_union([Polygon(old[i]["p"]).buffer(0.15) for i in idx])
    newp = [Polygon(new[i]["p"]) for i in idx]
    name, L, Lc = tris(os.path.join(B, "glb", "roads05_2.glb"), "L_22x17s0")
    _, R, _ = tris(os.path.join(B, "glb", "roads05_3.glb"), "R_22x17s0")
    x0, z0, x1, z1 = oldp.union(unary_union(newp)).bounds
    R = [t for t in R if x0 - 5 < t[0][0] < x1 + 5 and z0 - 5 < t[0][2] < z1 + 5]
    Rp = [Polygon([(p[0], p[2]) for p in t]) for t in R]
    tree = STRtree(Rp)

    def ground(x, z):
        pt = Point(x, z)
        cand = [j for j in tree.query(pt) if Rp[j].buffer(1e-6).contains(pt)]
        if not cand:   # (the median nose: no road triangle under) the nearest road triangle's plane, within 4 studs
            j = int(tree.nearest(pt))
            cand = [j] if Rp[j].distance(pt) < 4.0 else []
        for j in cand:
            if True:
                (ax, ay, az), (bx, by, bz), (cx, cy, cz) = R[j]
                d = (bz - cz) * (ax - cx) + (cx - bx) * (az - cz)
                if abs(d) < 1e-9:
                    continue
                w1 = ((bz - cz) * (x - cx) + (cx - bx) * (z - cz)) / d
                w2 = ((cz - az) * (x - cx) + (ax - cx) * (z - cz)) / d
                return w1 * ay + w2 * by + (1 - w1 - w2) * cy
        return None
    keep, gone, lifts = [], 0, []
    for t, col in zip(L, Lc):
        g = (sum(p[0] for p in t) / 3, sum(p[2] for p in t) / 3)
        if oldp.contains(Point(g)):
            gone += 1
            for p in t:
                y = ground(p[0], p[2])
                if y is not None:
                    lifts.append(p[1] - y)
            continue
        keep.append((t, col))
    lift = sorted(lifts)[len(lifts) // 2]
    rgb = keep[0][1][0]
    m = Mesh()
    for t, (col, uv) in keep:   # the bake's UVs are world (x, z): keep them, the new strips get the same
        m.tri(t[0], t[1], t[2], uv[0], uv[1], uv[2], col)
    added = 0
    import shapely
    from shapely.geometry import box as sbox
    for poly in newp:
        # cut into a STEP grid so every piece follows the road (grade and crossfall), then triangulate each piece
        bx0, bz0, bx1, bz1 = poly.bounds
        gx = math.floor(bx0 / STEP) * STEP
        while gx < bx1:
            gz = math.floor(bz0 / STEP) * STEP
            while gz < bz1:
                piece = poly.intersection(sbox(gx, gz, gx + STEP, gz + STEP))
                for G in ([piece] if piece.geom_type == "Polygon" else list(getattr(piece, "geoms", []))):
                    if G.geom_type != "Polygon" or G.area < 1e-4:
                        continue
                    for t in shapely.constrained_delaunay_triangles(G).geoms:
                        c3 = list(t.exterior.coords)[:3]
                        tri = []
                        for x, z in c3:
                            y = ground(x, z)
                            assert y is not None, ("no road under", x, z)
                            tri.append((x, y + lift, z))
                        ux, uz = tri[1][0] - tri[0][0], tri[1][2] - tri[0][2]
                        vx, vz = tri[2][0] - tri[0][0], tri[2][2] - tri[0][2]
                        if abs(ux * vz - uz * vx) < 1e-9:
                            continue
                        if ux * vz - uz * vx > 0:   # up-facing (y of the cross product > 0)
                            tri = [tri[0], tri[2], tri[1]]
                        m.tri(tri[0], tri[1], tri[2], *[(p[0], p[2]) for p in tri], rgb)
                        added += 1
                gz += STEP
            gx += STEP
    lo, hi = m.box()
    cc = [(lo[i] + hi[i]) / 2 for i in range(3)]
    ss = [hi[i] - lo[i] for i in range(3)]
    nm = code("L", "22x17s0", cc, ss)
    info = write_glb(OUT, [(nm, m)])
    json.dump({"name": nm, "old": name, "dropped": gone, "added": added, "lift": lift, "info": info},
              open(OUT + ".json", "w"), indent=1)
    print(nm, "dropped", gone, "added", added, "lift %.3f" % lift, "kept", len(keep))


if __name__ == "__main__":
    main()
