"""
The ground under and beside the Riviera Highway (tools/map_plan/highway.py): flattened 1.5 studs under
the road and its shoulders (asphalt), cut banks of pale rock where the road runs into the hill
(steep, like a mountain road's cutting), fill banks of earth where it runs over a dip; the rest of
the ground untouched. Cells within reach of the existing roads are left alone (their ground was
shaped with them).

Only the cells that change are written, per 64 x 64 terrain tile, so the Studio writer
(tools/riviera/HighwayTerrain.luau) rewrites those columns and keeps every other column of the tile
as it is in the place:
  build/riviera_hw/index.json       {"tiles": ["cols_<i>_<j>.json", ...], "cell": 4, "x0", "z0"}
  build/riviera_hw/cols_<i>_<j>.json  {"i", "j", "cols": [[ix, iz, h*4, mat], ...]} (cell indices in the grid)

usage (from Games/CityLegends): python tools/map_plan/highway_terrain.py
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import highway  # noqa: E402

ROOT = os.path.join(HERE, "..", "..")
RIV = os.path.join(ROOT, "build", "riviera")
OUT = os.path.join(ROOT, "build", "riviera_hw")

CORE = 32 + 10 + 2  # carriageway + shoulder + a little
REACH = 220  # banks end here at the latest
CUT_SLOPE = 2.0  # rise per stud out from the shoulder (a steep rock cutting)
FILL_SLOPE = 0.9  # fall per stud (an earth embankment)
BLEND = 50  # the last studs of the reach fade back to the natural ground (no cliff at the edge)
KEEP = 50  # cells this close to an existing road's centre line stay as they are


def main():
    meta = json.load(open(os.path.join(RIV, "meta.json")))
    _, H = highway.ground()
    M = np.full(H.shape, " ", dtype="<U1")
    for name in meta["tiles"]:
        t = json.load(open(os.path.join(RIV, name)))
        i, j, w, d = t["i"], t["j"], t["w"], t["d"]
        M[j:j + d, i:i + w] = np.array(list(t["m"])).reshape(d, w)
    C, X0, Z0 = meta["cell"], meta["x0"], meta["z0"]
    hw = json.load(open(os.path.join(RIV, "highway.json")))["roads"]
    old = json.load(open(os.path.join(RIV, "roads.json")))["roads"]

    best = np.full(H.shape, 1e9, dtype=np.float32)  # distance to the nearest highway centre line
    road_y = np.zeros(H.shape, dtype=np.float32)       # that road's height (for the flat bed)
    core_w = np.full(H.shape, CORE, dtype=np.float32)  # that road's flat half width
    # (2026-11-04, the pass's stacked legs) every road nearby limits the ground: no higher than the
    # lowest cut line of them all, no lower than the highest fill line; with only the nearest road's
    # lines, the ground jumped by a whole leg's height half way between two legs
    cut_min = np.full(H.shape, 1e9, dtype=np.float32)
    fill_max = np.full(H.shape, -1e9, dtype=np.float32)
    near_old = np.full(H.shape, 1e9, dtype=np.float32)

    def window(x, z, radius):
        r = int(radius / C) + 2
        ci, cj = int((x - X0) / C), int((z - Z0) / C)
        i0, i1 = max(ci - r, 0), min(ci + r + 1, H.shape[1])
        j0, j1 = max(cj - r, 0), min(cj + r + 1, H.shape[0])
        if i0 >= i1 or j0 >= j1:
            return None
        cx = X0 + C * (np.arange(i0, i1) + 0.5)
        cz = Z0 + C * (np.arange(j0, j1) + 0.5)
        dd = np.sqrt((cx[None, :] - x) ** 2 + (cz[:, None] - z) ** 2).astype(np.float32)
        return (slice(j0, j1), slice(i0, i1)), dd

    for r in hw:
        for s in r["s"]:
            win = window(s[0], s[2], REACH)
            if not win:
                continue
            sl, dd = win
            core = (s[6] + 4) if s[6] < 30 else CORE  # (the pass: walls at its edge, no shoulders)
            out = np.maximum(dd - core, 0)
            bed = s[1] - 1.5
            np.minimum(cut_min[sl], bed + out * CUT_SLOPE, out=cut_min[sl])
            np.maximum(fill_max[sl], bed - out * FILL_SLOPE, out=fill_max[sl])
            sub = best[sl]
            m = dd < sub
            sub[m] = dd[m]
            road_y[sl][m] = s[1]
            core_w[sl][m] = core
    for r in old:
        for s in r["s"]:
            win = window(s[0], s[2], KEEP + 8)
            if win:
                sl, dd = win
                np.minimum(near_old[sl], dd, out=near_old[sl])

    newH = H.copy()
    newM = M.copy()
    zone = best < REACH
    core = zone & (best <= core_w)
    flat = road_y - 1.5
    out_d = np.maximum(best - core_w, 0)
    newH[core] = flat[core]
    bank = zone & ~core
    lo = np.minimum(fill_max, cut_min)
    newH[bank] = np.clip(H[bank], lo[bank], cut_min[bank])
    fade = np.clip((best - (REACH - BLEND)) / BLEND, 0, 1)
    fade = fade * fade * (3 - 2 * fade)
    newH[bank] = newH[bank] * (1 - fade[bank]) + H[bank] * fade[bank]
    newM[core] = "A"
    cutm = bank & (H > newH + 0.3)
    fillm = bank & (H < newH - 0.3)
    newM[cutm] = "R"  # (grey rock cuttings: the pale limestone read as snow)
    newM[fillm & (out_d < 30)] = "D"
    newM[fillm & (out_d >= 30)] = "G"
    # existing roads' ground stays
    keep = near_old < KEEP
    newH[keep] = H[keep]
    newM[keep] = M[keep]
    changed = (np.abs(newH - H) > 0.12) | (newM != M)
    # --restore x0 z0 x1 z1: also write the natural ground back over that box (where nothing above
    # changes it and away from the old roads), undoing an earlier version's cuts and fills
    if "--restore" in sys.argv:
        k = sys.argv.index("--restore")
        bx0, bz0, bx1, bz1 = (float(v) for v in sys.argv[k + 1:k + 5])
        cx = X0 + C * (np.arange(H.shape[1]) + 0.5)
        cz = Z0 + C * (np.arange(H.shape[0]) + 0.5)
        box = ((cx[None, :] >= bx0) & (cx[None, :] <= bx1)) & ((cz[:, None] >= bz0) & (cz[:, None] <= bz1))
        extra = box & ~changed & ~keep
        print("restoring", int(extra.sum()), "cells to the natural ground")
        changed = changed | extra
    print("cells changed:", int(changed.sum()), " deepest cut %.0f, highest fill %.0f" % (float((H - newH).max()), float((newH - H).max())))

    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.startswith("cols_"):
            os.remove(os.path.join(OUT, f))
    T = meta["tile"]
    names = []
    js, iz = np.nonzero(changed)
    tiles = {}
    for j, i in zip(js.tolist(), iz.tolist()):
        tiles.setdefault((i // T, j // T), []).append([i, j, int(round(float(newH[j, i]) * 4)), str(newM[j, i])])
    for (ti, tj), cols in sorted(tiles.items()):
        name = "cols_%d_%d.json" % (ti, tj)
        json.dump({"i": ti * T, "j": tj * T, "cols": cols}, open(os.path.join(OUT, name), "w"), separators=(",", ":"))
        names.append(name)
    json.dump({"tiles": names, "cell": C, "x0": X0, "z0": Z0, "mats": meta["mats"]}, open(os.path.join(OUT, "index.json"), "w"), separators=(",", ":"))
    print(len(names), "tiles ->", OUT)
    # keep the master tiles in step, so a later full write keeps the highway's ground
    if "--master" in sys.argv:
        for name in meta["tiles"]:
            t = json.load(open(os.path.join(RIV, name)))
            i, j, w, d = t["i"], t["j"], t["w"], t["d"]
            sub = changed[j:j + d, i:i + w]
            if sub.any():
                t["h"] = [int(round(float(v) * 4)) for v in newH[j:j + d, i:i + w].flatten()]
                t["m"] = "".join(newM[j:j + d, i:i + w].flatten())
                json.dump(t, open(os.path.join(RIV, name), "w"), separators=(",", ":"))
        print("master tiles updated")


if __name__ == "__main__":
    main()
