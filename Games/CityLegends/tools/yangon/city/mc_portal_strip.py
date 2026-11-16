"""Myanmar Centre basement (2026-11-17): take the three ramps' dark end walls, barrier posts and barrier arms out of
the placed 1:1 meshes without a full mc3d.py re-export (that run's flicker pass needs more memory than the PC had).
Reads imports/sync/landmarks/mc1/mc1.glb + mc1_2.glb, writes imports/sync/landmarks/mc1/mc1_basement.glb with the
two changed meshes (the ground DRK mesh along the west strip and the ramps' RED mesh). mc3d.py at 1:1 no longer
builds these pieces either, so its next full run gives the same. Studio: tools/yangon/MCBasement.luau swaps them."""
import json, math, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb  # noqa: E402

D = os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "mc1")
PLANE = [40.40851827031085, -0.010750665929110522, -0.010526870203554915]


def plane_y(X, Z):
    return PLANE[0] + PLANE[1] * (X - 34875.0) + PLANE[2] * (Z - 27468.75)


# the dark end walls' collision boxes in Studio: centre x, z, yaw (deg), half sizes along / across
PORTALS = [(34669.5, 27611.3, -7.9, 0.75, 12.0), (34669.5, 27572.0, -6.9, 0.75, 12.0), (34740.7, 27686.5, -16.5, 0.75, 11.25)]


def in_portal(X, Z):
    for cx, cz, yaw, hx, hz in PORTALS:
        t = math.radians(yaw)
        dx, dz = X - cx, Z - cz
        lx = dx * math.cos(t) - dz * math.sin(t)
        lz = dx * math.sin(t) + dz * math.cos(t)
        if abs(lx) <= hx + 0.2 and abs(lz) <= hz + 0.2:
            return True
    return False


def near_ramp_end(X, Z):
    return any(math.hypot(X - cx, Z - cz) < 30 for cx, cz, *_ in PORTALS)


def read(path, prefix):
    b = open(path, "rb").read()
    jl = struct.unpack("<I", b[12:16])[0]
    js = json.loads(b[20:20 + jl])
    bn = b[20 + jl + 8:]
    nd = [n for n in js["nodes"] if n.get("name", "").startswith(prefix)][0]
    pr = js["meshes"][nd["mesh"]]["primitives"][0]

    def acc(i, fmt, w):
        a = js["accessors"][i]
        v = js["bufferViews"][a["bufferView"]]
        o = v.get("byteOffset", 0) + a.get("byteOffset", 0)
        sz = struct.calcsize("<" + fmt)
        return [struct.unpack_from("<" + fmt, bn, o + k * sz) for k in range(a["count"])]
    at = pr["attributes"]
    P, N = acc(at["POSITION"], "3f", 3), acc(at["NORMAL"], "3f", 3)
    U, C = acc(at["TEXCOORD_0"], "2f", 2), acc(at["COLOR_0"], "4B", 4)
    ia = js["accessors"][pr["indices"]]
    T = [t[0] for t in acc(pr["indices"], "H" if ia["componentType"] == 5123 else "I", 1)]
    # the name holds the box centre x 100 (the importer's half turn: x and z negated in the file)
    parts = nd["name"].split("_")
    c = [int(parts[2]) / 100, int(parts[3]) / 100, int(parts[4]) / 100]
    return nd["name"], c, P, N, U, C, T


def strip(path, prefix, drop):
    name, c, P, N, U, C, T = read(path, prefix)
    m = Mesh()
    kept = gone = 0
    for k in range(0, len(T), 3):
        ids = T[k:k + 3]
        W = [(c[0] - P[i][0], c[1] + P[i][1], c[2] - P[i][2]) for i in ids]
        g = [sum(w[q] for w in W) / 3 for q in range(3)]
        if drop(g):
            gone += 1
            continue
        kept += 1
        i0 = len(m.P)
        m.P += W
        m.N += [(-N[i][0], N[i][1], -N[i][2]) for i in ids]
        m.U += [U[i] for i in ids]
        m.C += [C[i][:3] for i in ids]
        m.T += [i0, i0 + 1, i0 + 2]
    print(name, "kept", kept, "dropped", gone)
    return name, m


def main():
    drk = strip(os.path.join(D, "mc1.glb"), "DRK_mc1gs",
                lambda g: in_portal(g[0], g[2]) or (near_ramp_end(g[0], g[2]) and g[1] < plane_y(g[0], g[2]) - 6))
    red = strip(os.path.join(D, "mc1_2.glb"), "RED_mc1gs", lambda g: g[1] < plane_y(g[0], g[2]) - 5.5)
    out = os.path.join(D, "mc1_basement.glb")
    info = write_glb(out, [drk, red])
    for k, v in info.items():
        print(k, [round(x, 2) for x in v["centre"]], [round(x, 2) for x in v["size"]], v["tris"])
    json.dump(info, open(out + ".json", "w"))


if __name__ == "__main__":
    main()
