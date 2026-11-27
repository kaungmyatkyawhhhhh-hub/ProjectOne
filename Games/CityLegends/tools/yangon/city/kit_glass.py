"""kit_glass.py (2026-11-27, building fronts: real glass): splits the window glass (group KGL) out of the kit's KGR
meshes into its own KGG meshes, for the panels Studio already has (ReplicatedStorage.YgnKit.Templates).

    YANGON_SCALE=1to1 python kit_glass.py build/kit_glass/studio_kgr_pids.txt

Rebuilds every listed panel / prop from the union of build/city_1to1/buildings_*/kit_meta.json, checks the old KGR
mesh's triangle count = new KGR + KGG (same generator, glass only moved to class G), and writes
imports/sync/kit_glass/kit_glass_<n>.glb: KGR_<pid>_<box> (without glass) + KGG_<pid>_<box> (glass only, white vertex
colour) for the panels that have glass. Studio: tools/yangon/KitGlassApply.luau swaps the templates.
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
OUT = os.path.join(ROOT, "imports", "sync", "kit_glass")
FILE_MESHES = 90


def main():
    want = open(sys.argv[1]).read().split()
    meta = {}
    # the current runs first; older runs ("before_places") only for pieces nothing current uses any more
    files = sorted(glob.glob(os.path.join(ROOT, "build", "city_1to1", "buildings_*", "kit_meta.json")),
                   key=lambda f: ("before" in f, f))
    for f in files:
        if "OLD" in f:
            continue
        for pid, m in json.load(open(f)).items():
            meta.setdefault(pid, m)
    kit = Kit()
    named, bad, plain = [], [], 0
    for pid in want:
        m = meta.get(pid)
        if not m:
            bad.append((pid, "no meta"))
            continue
        key = tuple(m["key"])
        q = kit.prop(key[1]) if key[0] == "prop" else kit.panel(*key[:5], shop=key[5], stripe=key[6])
        assert q == pid, (pid, q)
        d = kit.data[q]
        old = m["parts"].get("M", {}).get("tris")
        if old != d["M"].tris + d["G"].tris:
            bad.append((pid, "tris %s != %d + %d" % (old, d["M"].tris, d["G"].tris)))
            continue
        if not d["G"].T:
            plain += 1
            continue
        for kind, mesh in (("KGR", d["M"]), ("KGG", d["G"])):
            if not mesh.T:   # a panel whose M was only glass: KitGlassApply deletes its KGR template
                continue
            lo, hi = mesh.box()
            cen = [(lo[i] + hi[i]) / 2 for i in range(3)]
            siz = [max(0.05, hi[i] - lo[i]) for i in range(3)]
            named.append((code(kind, pid, cen, siz), mesh))
    os.makedirs(OUT, exist_ok=True)
    for i in range(0, len(named), FILE_MESHES):
        path = os.path.join(OUT, "kit_glass_%d.glb" % (i // FILE_MESHES + 1))
        info = write_glb(path, named[i:i + FILE_MESHES], generator="kit_glass.py")
        n, b = check_glb(path, info)
        assert not b, b
        print(path, n)
    kgg = sum(1 for n, _ in named if n.startswith("KGG"))
    print("panels %d, with glass %d, without %d, meshes %d, bad %d" % (len(want), kgg, plain, len(named), len(bad)))
    for b in bad[:20]:
        print("BAD", b)
    json.dump(sorted(n for n, _ in named), open(os.path.join(OUT, "names.json"), "w"), indent=0)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
