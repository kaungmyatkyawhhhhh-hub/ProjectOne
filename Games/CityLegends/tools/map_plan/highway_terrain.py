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
CUT_SLOPE = 2.2  # rise per stud out from the shoulder (a steep rock cutting)
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

    best = np.full(H.shape, 1e9, dtype=np.float32)  # distance to the highway's centre line
    road_y = np.zeros(H.shape, dtype=np.float32)
    core_w = np.full(H.shape, CORE, dtype=np.float32)  # each cell's road's flat width (half)
    near_old = np.full(H.shape, 1e9, dtype=np.float32)

    def stamp(samples, radius, dist, yv=None, core=None):
        r = int(radius / C) + 2
        for s in samples:
            x, y, z = s[0], s[1], s[2]
            ci, cj = int((x - X0) / C), int((z - Z0) / C)
            i0, i1 = max(ci - r, 0), min(ci + r + 1, H.shape[1])
            j0, j1 = max(cj - r, 0), min(cj + r + 1, H.shape[0])
            if i0 >= i1 or j0 >= j1:
                continue
            cx = X0 + C * (np.arange(i0, i1) + 0.5)
            cz = Z0 + C * (np.arange(j0, j1) + 0.5)
            dd = np.sqrt((cx[None, :] - x) ** 2 + (cz[:, None] - z) ** 2).astype(np.float32)
            sub = dist[j0:j1, i0:i1]
            m = dd < sub
            sub[m] = dd[m]
            if yv is not None:
                yy = yv[j0:j1, i0:i1]
                yy[m] = y
            if core is not None:
                cc = core_w[j0:j1, i0:i1]
                # (the pass: its walls stand at the road's edge, no shoulders)
                cc[m] = (s[6] + 4) if s[6] < 30 else CORE

    for r in hw:
        stamp(r["s"], REACH, best, road_y, core=True)
    for r in old:
        stamp(r["s"][::1], KEEP + 8, near_old)

    newH = H.copy()
    newM = M.copy()
    zone = best < REACH
    core = zone & (best <= core_w)
    flat = road_y - 1.5
    out_d = np.maximum(best - core_w, 0)
    cut_top = flat + out_d * CUT_SLOPE
    fill_bot = flat - out_d * FILL_SLOPE
    # core: flat; banks: the ground clipped between the fill and cut lines
    newH[core] = flat[core]
    bank = zone & ~core
    newH[bank] = np.clip(H[bank], fill_bot[bank], cut_top[bank])
    fade = np.clip((best - (REACH - BLEND)) / BLEND, 0, 1)
    fade = fade * fade * (3 - 2 * fade)
    newH[bank] = newH[bank] * (1 - fade[bank]) + H[bank] * fade[bank]
    newM[core] = "A"
    cutm = bank & (H > newH + 0.3)
    fillm = bank & (H < newH - 0.3)
    newM[cutm] = "L"
    newM[fillm & (out_d < 30)] = "D"
    newM[fillm & (out_d >= 30)] = "G"
    # existing roads' ground stays
    keep = near_old < KEEP
    newH[keep] = H[keep]
    newM[keep] = M[keep]
    changed = (np.abs(newH - H) > 0.12) | (newM != M)
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
