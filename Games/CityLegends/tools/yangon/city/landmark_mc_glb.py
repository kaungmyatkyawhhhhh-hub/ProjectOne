"""landmark_mc_glb.py <y0> [out.glb] [--plane a,b,c]: build/landmarks/myanmar_centre/mc_tris.json (landmark_mc_blend.dump()) -> one .glb with
the Myanmar Centre meshes for Studio, in YangonBuildingMeshes' format (place with M.place, cell id "mc"):
  F_mcs<k>_...  walls (shadows on)          one per Blender object of kind F
  R_mcs<k>_...  roofs and props              one per Blender object of kind R
  G_mcs<k>_...  night windows: the glow-flagged faces copied 0.08 studs out along their normal
Mesh names carry the true box (glb.code); positions are world studs: X = 32600 + x, Y = y0 + z, Z = -1350 - y (a proper
rotation of the Blender axes, so the winding stays counter-clockwise from outside). Default out: imports/sync/landmarks/.
--plane a,b,c: the pavements round the lot slope; the ground pieces (paving, props, plinth) follow
Y = a + b (X - 32600) + c (Z + 1350) instead of the flat y0 (shifted per vertex: at most ~0.6 studs of shear).
Also writes <out>.collide.txt: the collision boxes as YangonBuildingMeshes.collide data ("mc|x y z sx sy sz yaw|...").
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code, check_glb  # noqa: E402

ROOT = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "myanmar_centre")
OX, OZ = 32600.0, -1350.0
MAX_TRIS = 9000


GROUND = ("MC_paving", "MC_props", "MC_plinth", "MC_plinthR")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    plane = None
    for i, a in enumerate(sys.argv):
        if a == "--plane":
            plane = [float(v) for v in sys.argv[i + 1].split(",")]
            args = [x for x in args if x != sys.argv[i + 1]]
    y0 = float(args[0])
    sys.argv = [sys.argv[0]] + args
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks",
                                                             "myanmar_centre.glb")
    data = json.load(open(os.path.join(ROOT, "mc_tris.json")))
    groups = {"F": [], "R": [], "G": []}
    for name in sorted(data):
        ob = data[name]
        kind = ob["kind"]
        m = Mesh()
        g = Mesh()
        for corners, glow in ob["tris"]:
            P, U, C = [], [], []
            for x, y, z, u, v, r, gg, b in corners:
                X, Z = OX + x, OZ - y
                base = y0
                if plane and name in GROUND:
                    base = plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)
                P.append((X, base + z, Z))
                U.append((u, v))
                C.append((r * 255, gg * 255, b * 255))
            col = tuple(sum(c[k] for c in C) / 3 for k in range(3))
            m.tri(P[0], P[1], P[2], U[0], U[1], U[2], col)
            if glow:
                ax, ay, az = (P[1][k] - P[0][k] for k in range(3))
                bx, by, bz = (P[2][k] - P[0][k] for k in range(3))
                nx, ny, nz = ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
                ln = math.sqrt(nx * nx + ny * ny + nz * nz)
                if ln > 1e-9:
                    o = (nx / ln * 0.08, ny / ln * 0.08, nz / ln * 0.08)
                    Q = [(p[0] + o[0], p[1] + o[1], p[2] + o[2]) for p in P]
                    g.tri(Q[0], Q[1], Q[2], U[0], U[1], U[2], (255, 255, 255))
        groups[kind].append(m)
        if g.T:
            groups["G"].append(g)
    named = []
    k = 0
    for kind in ("F", "R", "G"):
        # merge small meshes per kind up to MAX_TRIS each
        cur = Mesh()
        for m in groups[kind] + [None]:
            if m is None or (cur.T and cur.tris + m.tris > MAX_TRIS):
                if cur.T:
                    k += 1
                    lo, hi = cur.box()
                    c = [(lo[i] + hi[i]) / 2 for i in range(3)]
                    s = [hi[i] - lo[i] for i in range(3)]
                    named.append((code(kind, "mcs%d" % k, c, s), cur))
                cur = Mesh()
            if m is not None:
                cur.extend(m)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    info = write_glb(out, named, generator="landmark_mc_glb.py")
    n, bad = check_glb(out, info)
    tris = sum(v["tris"] for v in info.values())
    print(out, "meshes", n, "tris", tris, "bad", bad)
    boxes = json.load(open(os.path.join(ROOT, "mc_collide.json")))
    parts = []
    for cx, cy, z0, sx, sy, sz, yaw in boxes:
        X, Z = OX + cx, OZ - cy
        base = y0
        if plane:
            base = max(y0, plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ))
        parts.append("%.2f %.2f %.2f %.2f %.2f %.2f %.4f" % (X, base + z0 + sz / 2, Z, sx, sz, sy, yaw))
    open(out + ".collide.txt", "w").write("mc|" + "|".join(parts) + chr(10))
    print("collide boxes", len(parts))
    for name, v in info.items():
        print(" ", name[:40], v["tris"])


if __name__ == "__main__":
    main()
