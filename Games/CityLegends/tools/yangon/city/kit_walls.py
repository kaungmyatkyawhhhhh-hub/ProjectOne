"""kit_walls.py (2026-11-27, owner: "make the buildings look less blocky"): rebuilds the WALL meshes (class W, KWX_<pid>)
of the panels Studio already has, after the kit_panels.py wall changes (roof slab lip with end caps, heavier walk-up
floor slab edges), and writes them for upload. Same pattern as kit_glass.py.

    YANGON_SCALE=1to1 python kit_walls.py build/kit_walls/studio_kwx_pids.txt

Rebuilds every listed panel from the union of build/city_1to1/buildings_*/kit_meta.json and checks the generator's
random stream is unchanged: the panel's metal + glass triangles (M + G) must equal the old M count (only the wall
class may change). Writes imports/sync/kit_walls/kit_walls_<n>.glb (KWX_<pid>_<box>); Studio: KitGlassApply.apply
(it replaces KWX templates too).
"""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from kit_panels import Kit  # noqa: E402
from glb import write_glb, check_glb, code  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT = os.path.join(ROOT, "imports", "sync", "kit_walls")
FILE_MESHES = 90
CLEAN = {"house", "villa", "condo", "condo_band", "condo_top"}


def main():
    want = open(sys.argv[1]).read().split()
    meta = {}
    files = sorted(glob.glob(os.path.join(ROOT, "build", "city_1to1", "buildings_*", "kit_meta.json")),
                   key=lambda f: ("before" in f, f))
    for f in files:
        if "OLD" in f:
            continue
        for pid, m in json.load(open(f)).items():
            meta.setdefault(pid, m)
    kit = Kit()
    named, bad, same, oldw, neww = [], [], 0, 0, 0
    for pid in want:
        m = meta.get(pid)
        if not m:
            bad.append((pid, "no meta"))
            continue
        key = tuple(m["key"])
        q = kit.prop(key[1]) if key[0] == "prop" else kit.panel(*key[:5], shop=key[5], stripe=key[6])
        assert q == pid, (pid, q)
        d = kit.data[q]
        old_m = m["parts"].get("M", {}).get("tris", 0)
        if old_m != d["M"].tris + d["G"].tris:
            bad.append((pid, "M tris %s != %d + %d" % (old_m, d["M"].tris, d["G"].tris)))
            continue
        w = d["W"]
        if not w.T:
            bad.append((pid, "no wall"))
            continue
        ow = m["parts"].get("W", {}).get("tris", 0)
        oldw += ow
        neww += w.tris
        same += ow == w.tris
        lo, hi = w.box()
        cen = [(lo[i] + hi[i]) / 2 for i in range(3)]
        siz = [max(0.05, hi[i] - lo[i]) for i in range(3)]
        named.append((code("KWX", pid, cen, siz), w))
    os.makedirs(OUT, exist_ok=True)
    for f in glob.glob(os.path.join(OUT, "kit_walls_*.glb")):
        os.remove(f)
    for i in range(0, len(named), FILE_MESHES):
        path = os.path.join(OUT, "kit_walls_%d.glb" % (i // FILE_MESHES + 1))
        info = write_glb(path, named[i:i + FILE_MESHES], generator="kit_walls.py")
        n, b = check_glb(path, info)
        assert not b, b
        print(path, n)
    print("panels %d, walls written %d (unchanged %d), wall tris %d -> %d, bad %d"
          % (len(want), len(named), same, oldw, neww, len(bad)))
    for b in bad[:20]:
        print("BAD", b)
    json.dump(sorted(n for n, _ in named), open(os.path.join(OUT, "names.json"), "w"), indent=0)
    # (2026-11-27 review) newer / villa-type archetypes keep the clean painted render: their KWX templates get attribute
    # MV = "YgnRenderPainted" (KitGlassApply.clean); YangonKitData uses it over the code's variant
    clean = sorted(p for p in want if p in meta and meta[p]["key"][0] in CLEAN)
    open(os.path.join(HERE, "kit_walls_clean.txt"), "w").write(" ".join(clean))
    print("clean (painted) panels", len(clean))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
