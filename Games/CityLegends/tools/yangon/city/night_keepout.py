"""night_keepout.py <cells.glb> <keepout.txt> <out.glb> (26 Nov 2026, P1-P3 re-run): drop the night panes whose triangle
middle stands in a KeepOut box (venue / house pads and the shells deleted there before), so a re-run district's night
cells don't light empty lots. keepout.txt = lines "name x y z sx sy sz rx rz lx lz" (Studio YgnKit.KeepOut export).
Each kept mesh is renamed with glb.code from its new box (YangonKitPlace.cells places by the name)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
from glb import Mesh, write_glb, check_glb, code  # noqa: E402
from gltf_io import read_glb, accessor  # noqa: E402

GROW = 2.0


def boxes(path):
    out = []
    for line in open(path):
        w = line.split()
        if len(w) < 11:
            continue
        x, z, sx, sz, rx, rz, lx, lz = (float(w[i]) for i in (1, 3, 4, 6, 7, 8, 9, 10))
        out.append((x, z, sx / 2 + GROW, sz / 2 + GROW, rx, rz, lx, lz))
    return out


def inside(B, px, pz):
    for x, z, hx, hz, rx, rz, lx, lz in B:
        dx, dz = px - x, pz - z
        if abs(dx) > hx + hz or abs(dz) > hx + hz:
            continue
        # local X along RightVector, local Z along -LookVector (|.| is enough)
        if abs(dx * rx + dz * rz) <= hx and abs(dx * lx + dz * lz) <= hz:
            return True
    return False


def parse(name):
    w = name.split("_")
    f = [(-int(v[1:]) if v.startswith("n") else int(v)) / 100 for v in w[-6:]]
    return w[0], "_".join(w[1:-6]), f[:3], f[3:]


def main(src, kpath, out):
    B = boxes(kpath)
    j, b = read_glb(src)
    named, dropped, kept = [], 0, 0
    for m in j["meshes"]:
        kind, mid, c, _ = parse(m["name"])
        p = m["primitives"][0]
        P = accessor(j, b, p["attributes"]["POSITION"])
        C = accessor(j, b, p["attributes"]["COLOR_0"]) if "COLOR_0" in p["attributes"] else None
        T = accessor(j, b, p["indices"])
        if kind != "NWH":
            raise SystemExit("not a night cell file: " + m["name"])
        W = [(c[0] - q[0], c[1] + q[1], c[2] - q[2]) for q in P]  # undo the x / z negation
        nm = Mesh()
        for t in range(0, len(T), 3):
            a, bb, cc = W[T[t]], W[T[t + 1]], W[T[t + 2]]
            if inside(B, (a[0] + bb[0] + cc[0]) / 3, (a[2] + bb[2] + cc[2]) / 3):
                dropped += 1
                continue
            col = C[T[t]][:3] if C else (204, 160, 104)
            if C and isinstance(col[0], float):
                col = tuple(v * 255 for v in col)
            nm.tri(a, bb, cc, (0, 0), (0, 0), (0, 0), col)
            kept += 1
        if nm.T:
            lo, hi = nm.box()
            named.append((code("NWH", mid, [(lo[k] + hi[k]) / 2 for k in range(3)], [hi[k] - lo[k] for k in range(3)]), nm))
    info = write_glb(out, named, generator="night_keepout.py")
    bad = check_glb(out, info)
    print("meshes %d -> %d, triangles kept %d dropped %d, bad %s, %.1f MB" % (len(j["meshes"]), len(named), kept, dropped,
                                                                               bad, os.path.getsize(out) / 1e6))


if __name__ == "__main__":
    main(*sys.argv[1:4])
