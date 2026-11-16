"""kit_flicker_test.py (2026-11-16): the no-flicker check on the 1:1 kit and on a placed sample of P1.

    YANGON_SCALE=1to1 python kit_flicker_test.py [P1]

1. every kit panel / prop that buildings_1to1.py used (kit_meta.json keys): rebuilt, all its classes together, checked
   with flicker_check (same-facing triangles under 0.05 studs apart that overlap, with different looks)
2. a placed sample: every instance line of the busiest cells' first 2,500 lines (panels stretched and turned, wall
   pieces, roofs, Part boxes) in world studs, checked across instances (seams between panels, panels against plain
   wall Parts and roof slabs, wall pieces against each other)
Prints the counts and the worst pairs; exits 1 if anything flickers.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from kit_panels import Kit  # noqa: E402
from flicker_check import check  # noqa: E402

TAG = sys.argv[1] if len(sys.argv) > 1 else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT = os.path.join(ROOT, "build", "city_1to1", "buildings_%s" % TAG)


def mesh_tris(m, key):
    for k in range(0, len(m.T), 3):
        yield (m.P[m.T[k]], m.P[m.T[k + 1]], m.P[m.T[k + 2]]), (key, m.C[m.T[k]])


def build_kit():
    meta = json.load(open(os.path.join(OUT, "kit_meta.json")))
    kit = Kit()
    pid_of = {}
    for pid, m in meta.items():
        key = tuple(m["key"])
        if key[0] == "prop":
            q = kit.prop(key[1])
        else:
            arch, role, floors, k, var, shop, stripe = key
            q = kit.panel(arch, role, floors, k, var, shop=shop, stripe=stripe)
        pid_of[pid] = q
    return kit, pid_of


def main():
    kit, pid_of = build_kit()
    bad_total = 0
    worst = []
    cat = {}
    for pid, q in pid_of.items():
        d = kit.data[q]
        items = []
        for c in "WMCR":
            items += list(mesh_tris(d[c], c))
        bad, tris = check(items)
        if bad:
            bad_total += len(bad)
            for i, j, g, a in bad:
                cat[(tris[i][1], tris[j][1])] = cat.get((tris[i][1], tris[j][1]), 0) + 1
            for i, j, g, a in bad[:3]:
                worst.append((pid, d["key"], tris[i][1], tris[j][1], round(g, 3), round(a, 3), tris[i][0][0]))
    print("kit: %d pieces checked, %d flickering pairs" % (len(pid_of), bad_total))
    for k, v in sorted(cat.items(), key=lambda kv: -kv[1])[:15]:
        print("   pair", k, v)
    for w in worst[:25]:
        print("  ", w)
    # placed sample
    lines = []
    for f in sorted(os.listdir(OUT)):
        if f.startswith("Inst_"):
            lines += [l for l in open(os.path.join(OUT, f)).read().split("\n") if l and not l.startswith("#")]
    sample = lines[:2500]
    items = []
    for n, line in enumerate(sample):
        w = line.split()
        if w[0] == "B":
            x, y, z, sx, sy, sz, yaw = map(float, w[1:8])
            c, s_ = math.cos(yaw), math.sin(yaw)
            X = (c, 0, -s_)
            Z = (s_, 0, c)
            def P(u, v, t):
                return (x + X[0] * u + Z[0] * t, y + v, z + X[2] * u + Z[2] * t)
            hx, hy, hz = sx / 2, sy / 2, sz / 2
            V = [P(a * hx, b * hy, e * hz) for a in (-1, 1) for b in (-1, 1) for e in (-1, 1)]
            faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
            # a plain wall sheet shows only its outer face (-Z: the wall's outward side); its back is inside the building
            for f in (faces if w[8] == "KCO" else [faces[4]]):
                a, b, cc, d = (V[i] for i in f)
                items.append(((a, b, cc), (("B", n), w[8])))
                items.append(((a, cc, d), (("B", n), w[8])))
            continue
        pid = pid_of.get(w[0])
        if not pid:
            continue
        sx = float(w[1])
        x, y, z, yaw = float(w[2]), float(w[3]), float(w[4]), float(w[5])
        sy = float(w[7]) if len(w) > 7 else 1.0
        sz = float(w[8]) if len(w) > 8 else 1.0
        c, s_ = math.cos(yaw), math.sin(yaw)
        d = kit.data[pid]
        for cl in "WMCR":
            m = d[cl]
            for k in range(0, len(m.T), 3):
                tri = []
                for t in (m.T[k], m.T[k + 1], m.T[k + 2]):
                    px, py, pz = m.P[t]
                    px, py, pz = px * sx, py * sy, pz * sz
                    tri.append((x + c * px + s_ * pz, y + py, z - s_ * px + c * pz))
                items.append((tuple(tri), (n, cl, m.C[m.T[k]])))
    bad, tris = check(items)
    # pairs inside one instance were checked above; here only pairs across instances count
    cross = [(i, j, g, a) for i, j, g, a in bad if tris[i][1][0] != tris[j][1][0]]
    def line_of(k):
        n = tris[k][1][0]
        return sample[n[1] if isinstance(n, tuple) else n]
    print("placed sample: %d instance lines, %d triangles, %d flickering pairs across instances" % (len(sample), len(items), len(cross)))
    for i, j, g, a in cross[:25]:
        print("  ", line_of(i)[:64], "|", line_of(j)[:64], round(g, 3), round(a, 3), tris[i][1][1:], tris[j][1][1:],
              [tuple(round(v, 2) for v in q) for q in tris[i][0]], [tuple(round(v, 2) for v in q) for q in tris[j][0]])
    sys.exit(1 if (bad_total or cross) else 0)


if __name__ == "__main__":
    main()
