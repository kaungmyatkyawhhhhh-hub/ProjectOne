"""Myanmar Plaza corner front (2026-11-17, owner drone photo: "only the myanmar plaza building is accurate ... the
canopies"): the placed 1:1 meshes are patched, no full mc3d.py re-export (its flicker pass ran out of memory).
  * CHR: the tilted roof canopy's underside plate is dropped (STR, its top, edges and V struts, is deleted whole in
    Studio). The photo shows no plate on struts: a white louvred pergola sits on the roof behind the facade
    (built as Parts by tools/yangon/MCDrone.luau).
  * FAS / SOF: the ground-floor corner canopy was 71 studs long and stuck out past the corner front over the
    Kabar Aye Pagoda Road pavement; it is cut to 44 (22 each side of the door), like the photo's porch.
  * DRK: its two outer columns (outside the shorter canopy) are dropped; the middle one stays.
Reads imports/sync/landmarks/mc1/mc1.glb, writes mc1_corner.glb (+ .json). Studio: MCDrone.luau swaps them."""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb  # noqa: E402
from mc_portal_strip import read, D  # noqa: E402

# the corner canopy slab in world studs (from the SOF mesh): facade edge a -> b, the outer edge (facade at depth 16.8 along n, the outside is -n)
A_ = (34782.8, 27202.0)
B_ = (34839.3, 27158.6)
M_ = ((A_[0] + B_[0]) / 2, (A_[1] + B_[1]) / 2)
L_ = math.hypot(B_[0] - A_[0], B_[1] - A_[1])
T_ = ((B_[0] - A_[0]) / L_, (B_[1] - A_[1]) / L_)
N_ = (-T_[1], T_[0])  # square to the facade (the mesh edge is 0.25 deg off)
HALF = 22.0
COLS = [(M_[0] + T_[0] * s + N_[0] * 2.2, M_[1] + T_[1] * s + N_[1] * 2.2) for s in (-L_ / 3, L_ / 3)]


def st(x, z):
    dx, dz = x - M_[0], z - M_[1]
    return dx * T_[0] + dz * T_[1], dx * N_[0] + dz * N_[1]


def in_canopy(x, y, z):
    s, d = st(x, z)
    return abs(s) <= L_ / 2 + 0.5 and -0.5 <= d <= 17.5 and 50 <= y <= 66


def patch(path, prefix, drop=lambda g: False, move=None):
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
        if move:
            W = [move(w) for w in W]
            # a face squeezed to nothing (the old end faces past the cut) is dropped
            e1 = [W[1][q] - W[0][q] for q in range(3)]
            e2 = [W[2][q] - W[0][q] for q in range(3)]
            cr = (e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0])
            if math.sqrt(sum(v * v for v in cr)) < 1e-4:
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


def clamp(w):
    x, y, z = w
    if not in_canopy(x, y, z):
        return w
    s, d = st(x, z)
    if abs(s) <= HALF:
        return w
    s = math.copysign(HALF, s)
    return (M_[0] + T_[0] * s + N_[0] * d, y, M_[1] + T_[1] * s + N_[1] * d)


def main():
    f = os.path.join(D, "mc1.glb")
    out = [patch(f, "CHR_mc1s", drop=lambda g: g[1] > 110),
           patch(f, "FAS_mc1s", move=clamp),
           patch(f, "SOF_mc1s", move=clamp),
           patch(f, "DRK_mc1s", drop=lambda g: g[1] < 58 and any(math.hypot(g[0] - cx, g[2] - cz) < 2.5 for cx, cz in COLS))]
    # the cut canopy must not reach past HALF anywhere (self-check)
    for name, m in out[1:3]:
        for p in m.P:
            if in_canopy(*p):
                assert abs(st(p[0], p[2])[0]) <= HALF + 0.01, (name, p)
    path = os.path.join(D, "mc1_corner.glb")
    info = write_glb(path, out)
    for k, v in info.items():
        print(k, [round(x, 2) for x in v["centre"]], [round(x, 2) for x in v["size"]], v["tris"])
    json.dump({"info": info, "cols": COLS}, open(path + ".json", "w"))


if __name__ == "__main__":
    main()
