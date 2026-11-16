"""Myanmar Centre corner sign (2026-11-17, owner: "the MYANMAR CENTRE sign is different in the real life modern myanmar
plaza"): only the sign's letter / logo meshes, without a full mc3d.py re-export (its flicker pass runs out of memory).
mc3d.sign_letters() is the one source: a full rerun gives the same.
    YANGON_SCALE=1to1 python mc_sign_patch.py  -> imports/sync/landmarks/mc1/mc1_sign.glb (+ .json)
Meshes (ground groups, on the pavement plane like the rest of the plinth): ORG (MYANMAR CENTRE + the plaza's orange
plate), HGL (HAGL + the green marks, new), BLU (the tower's blue plate, new), GLD (names + address).
Studio: tools/yangon/MCSign.luau swaps them in."""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mc3d as M  # noqa: E402
import onetoone as X1  # noqa: E402

assert M.ONE, "run with YANGON_SCALE=1to1"


def main():
    cx, cy = M.V(M.LAY["plinth_c"])
    r = float(M.LAY["fit"]["plinth_r"])
    span = math.radians(float(M.LAY["fit"].get("plinth_span", 104)))
    a0 = math.atan2(M.FACE[1], M.FACE[0]) - span / 2
    nb = 40
    band_span = span * int(round(nb * 0.88)) / nb
    with M.g.ground():
        M.sign_letters((cx, cy), r, a0 + band_span / 2, 7.6, 12.4)   # plinth(): zg, zt
    gr = M.LAY["ground"]
    out = os.path.join(HERE, "..", "..", "..", "imports", "sync", "landmarks", "mc1", "mc1_sign.glb")
    files = X1.export(M.g, gr["y0"], gr["plane"], out, "mcsg")
    print(files, "flicker", getattr(M.g, "flicker", None))
    assert M.g.flicker[2] == 0
    json.dump({k: len(v) for k, v in M.g.gg.items()}, open(out + ".json", "w"))


if __name__ == "__main__":
    main()
