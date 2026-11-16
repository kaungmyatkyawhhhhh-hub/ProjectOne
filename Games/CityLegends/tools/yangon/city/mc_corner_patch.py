"""Myanmar Plaza corner front (2026-11-17, owner drone photo: "only the myanmar plaza building is accurate ... the
canopies"; then "the canopies are suppose to be at middle. not on the left side"): the placed 1:1 meshes are patched,
no full mc3d.py re-export (its flicker pass ran out of memory). mc3d.py at 1:1 builds the same, so a rerun keeps it.
  * CHR: the tilted roof canopy's underside plate is dropped (STR, its top, edges and V struts, is deleted whole in
    Studio). The photo shows no plate on struts: a white louvred pergola sits on the roof behind the facade
    (built as Parts by tools/yangon/MCDrone.luau).
  * FAS / SOF: the ground-floor corner canopy was 71 studs long, on the corner front's east chamfer, and stuck out
    over the Kabar Aye Pagoda Road pavement. It is now 44 (22 each side of the door) and centred on the WHOLE corner
    front (mc3d.front_chain), its back following the facade's bend, like the photo's porch under the screen.
  * DRK: the old canopy's columns go, two new ones under the new canopy; the shopfront's dark sill strip is rebuilt
    on the front with the door gap at the new middle.
  * GLS: the shopfront glass on the corner front is rebuilt with the door gap at the new middle (mc3d.ENTR[0]).
Reads imports/sync/landmarks/mc1/mc1.glb, writes mc1_corner.glb (+ .json: mesh info, the new collision boxes in
YangonBuildingMeshes.collide's format, the old boxes' area, soffit lights). Studio: tools/yangon/MCDrone.luau
(M.canopy) swaps them."""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb  # noqa: E402
from mc_portal_strip import read, D  # noqa: E402
import mc3d as MC  # noqa: E402
import onetoone as X1  # noqa: E402
import landmark_glb3d as LG  # noqa: E402

assert MC.ONE, "run with YANGON_SCALE=1to1"
Y0 = MC.LAY["ground"]["y0"]

# the OLD corner canopy slab in world studs (from the first export's SOF mesh): outer edge a -> b, facade 16.8 in (n)
A_ = (34782.8, 27202.0)
B_ = (34839.3, 27158.6)
M_ = ((A_[0] + B_[0]) / 2, (A_[1] + B_[1]) / 2)
L_ = math.hypot(B_[0] - A_[0], B_[1] - A_[1])
T_ = ((B_[0] - A_[0]) / L_, (B_[1] - A_[1]) / L_)
N_ = (-T_[1], T_[0])
OLD_COLS = [(M_[0] + T_[0] * s + N_[0] * 2.2, M_[1] + T_[1] * s + N_[1] * 2.2) for s in (-L_ / 3, 0.0, L_ / 3)]


def W(p):
    """1:1 model point (x, y, z) -> world (building, on y0)."""
    return (X1.OX1 + p[0], Y0 + p[2], X1.OZ1 - p[1])


def old_canopy(x, y, z):
    dx, dz = x - M_[0], z - M_[1]
    s, d = dx * T_[0] + dz * T_[1], dx * N_[0] + dz * N_[1]
    return abs(s) <= L_ / 2 + 0.5 and -0.5 <= d <= 17.5 and 50 <= y <= 66


# the shopfront line (POD offset 3.5 in) along the corner front, world
CH, _ = MC.front_chain()
INNER = MC.offset_poly(MC.POD, -3.5)
FRONT_I = [i for i in range(len(MC.POD)) if MC.POD[i] in CH and MC.POD[(i + 1) % len(MC.POD)] in CH]
SEGS = [(W((INNER[i][0] * X1.S, INNER[i][1] * X1.S, 0))[::2], W((INNER[(i + 1) % len(INNER)][0] * X1.S, INNER[(i + 1) % len(INNER)][1] * X1.S, 0))[::2]) for i in FRONT_I]


def near_front(x, z, tol=0.08):
    for (ax, az), (bx, bz) in SEGS:
        ex, ez = bx - ax, bz - az
        L2 = ex * ex + ez * ez
        u = max(0.0, min(1.0, ((x - ax) * ex + (z - az) * ez) / L2))
        if math.hypot(x - ax - ex * u, z - az - ez * u) < tol:
            return True
    return False


def on_shopfront(g, lo, hi):
    return lo <= g[1] - Y0 <= hi and near_front(g[0], g[2])


def patch(path, prefix, drop=lambda tri, g: False, add=()):
    name, c, P, N, U, C, T = read(path, prefix)
    m = Mesh()
    kept = gone = 0
    for k in range(0, len(T), 3):
        ids = T[k:k + 3]
        Wp = [(c[0] - P[i][0], c[1] + P[i][1], c[2] - P[i][2]) for i in ids]
        g = [sum(w[q] for w in Wp) / 3 for q in range(3)]
        if drop(Wp, g):
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
    for a, b, cc in add:
        P3 = [W(a), W(b), W(cc)]
        m.tri(P3[0], P3[1], P3[2], *LG.box_uv(P3), LG.GROUPS[grp][1])
    print(name, "kept", kept, "dropped", gone, "added", len(add))
    return name, m


def main():
    # the new pieces from mc3d itself (canopy, its columns, the front's glass and sill with the door at the middle)
    MC.COLL.clear()
    del MC.LIGHTS[:]
    MC.corner_front()
    edges = set(FRONT_I)
    skip = MC.skip_entrances
    MC.g.ring("GLS", INNER, 0.3, 11.5, edges=edges, skip=skip)
    MC.g.ring("DRK", INNER, 0.0, 0.3, edges=edges, skip=skip)
    ncol = len(MC.COLL)
    for i, p, q in MC.edges_of(MC.POD):
        if i in edges:
            n = MC.outward(MC.POD, i)
            from geom3d import _keep_spans
            for a, b in _keep_spans(MC.skip_entrances(p, q, -1.0)):
                pa = (p[0] + (q[0] - p[0]) * a, p[1] + (q[1] - p[1]) * a)
                pb = (p[0] + (q[0] - p[0]) * b, p[1] + (q[1] - p[1]) * b)
                MC.coll_wall(pa, pb, 0.0, 14.0, 1.6, inward=(-n[0], -n[1]))
    new = MC.g.g
    f = os.path.join(D, "mc1.glb")
    out = [patch(f, "CHR_mc1s", drop=lambda t, g: g[1] > 110),
           patch(f, "FAS_mc1s", drop=lambda t, g: old_canopy(*g), add=new["FAS"]),
           patch(f, "SOF_mc1s", drop=lambda t, g: old_canopy(*g), add=new["SOF"]),
           patch(f, "DRK_mc1s12", add=new["DRK"],
                 drop=lambda t, g: (g[1] < 58 and any(math.hypot(g[0] - cx, g[2] - cz) < 2.5 for cx, cz in OLD_COLS))
                 or (all(on_shopfront(v, -0.05, 0.40) for v in t))),
           patch(f, "GLS_mc1s", add=new["GLS"], drop=lambda t, g: all(on_shopfront(v, 0.30, 13.60) for v in t))]
    mid = W((MC.ENTR[0][0][0] * X1.S, MC.ENTR[0][0][1] * X1.S, 0))
    # self-check: the new canopy's back edge is centred on the front's middle (the old one sat 37 studs east of it)
    sof = [W(p) for t in new["SOF"] for p in t]
    xs, zs = [p[0] for p in sof], [p[2] for p in sof]
    assert math.hypot((min(xs) + max(xs)) / 2 - mid[0], (min(zs) + max(zs)) / 2 - mid[2]) < 9, "canopy not centred"
    boxes = []
    for cx, cy, z0, sx, sy, sz, yaw in list(MC.COLL):
        X, Z = X1.OX1 + cx, X1.OZ1 - cy
        boxes.append([round(X, 2), round(Y0 + z0 + sz / 2, 2), round(Z, 2), round(sx, 2), round(sz, 2), round(sy, 2), round(yaw, 4)])
    lights = X1.lights_world(MC.LIGHTS, Y0)
    path = os.path.join(D, "mc1_corner.glb")
    info = write_glb(path, out)
    for k, v in info.items():
        print(k, [round(x, 2) for x in v["centre"]], [round(x, 2) for x in v["size"]], v["tris"])
    json.dump({"info": info, "old_cols": OLD_COLS, "mid": [mid[0], mid[2]], "cols": boxes[:ncol], "walls": boxes[ncol:],
               "front_outer": [list(W((p[0] * X1.S, p[1] * X1.S, 0))[::2]) for p in CH], "lights": lights, "y0": Y0},
              open(path + ".json", "w"))
    print("mid", [round(v, 2) for v in mid], "boxes", len(boxes), "lights", lights)


if __name__ == "__main__":
    main()
