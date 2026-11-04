"""
The ground under and beside the north roads (tools/map_plan/north_roads.py, 2026-11-04). Same idea as
highway_terrain.py, for much deeper ground:
  * cuts: a short steep rock face beside the road, then an ordinary hillside (the owner didn't like the
    Summit Pass's big grey rock bowl), running on until it meets the natural ground, so there is no
    edge to fade out;
  * fills: earth banks; where the road stands high (north_roads' viaduct runs) the ground stays
    natural and the road goes on piers (tools/riviera/Viaducts.luau);
  * every road and house lot already there keeps its ground.

Only the columns that change are written (build/riviera_nr/, same format as riviera_hw; the index adds
"above": how far above a tile's highest column the writer has to clear).

usage (from Games/CityLegends): python tools/map_plan/north_terrain.py
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import north_roads as nr  # noqa: E402

ROOT = os.path.join(HERE, "..", "..")
RIV = os.path.join(ROOT, "build", "riviera")
OUT = os.path.join(ROOT, "build", "riviera_nr")

REACH = 360
ROCK_BAND = 34      # studs of bare rock beside a cut
STEEP = 1.7         # the rock face's rise per stud
HILL = 0.85         # the hillside above it (40 degrees)
FILL = 0.9
KEEP_ROUTE = 48     # cells this close to an existing road's centre line stay as they are
KEEP_PASS = 24
LOT_R = 104         # and this close to a house lot's middle
STREET_REACH = 90   # (streets: a short steep garden bank, or they'd dig under the house lots beside them)
STREET_RISE = 2.4
# a house lot's plate that stood in mid air right over a new road (lot_riv_high_1, 50 studs over the
# hillside, there since the lots were made): the ground comes up under it. (x, z, size x, size z, top)
LOT_HILLS = [(11423.3, -40.2, 150, 144, 190.5)]
HILL_SLOPE = 2.0


def cut_rise(out):
    return np.where(out < ROCK_BAND, out * STEEP, ROCK_BAND * STEEP + (out - ROCK_BAND) * HILL)


def main():
    meta, H, M = nr.ground_after_highway()
    C, X0, Z0 = meta["cell"], meta["x0"], meta["z0"]
    roads = json.load(open(os.path.join(RIV, "north.json")))["roads"]
    old = json.load(open(os.path.join(RIV, "roads.json")))["roads"]
    road_hw = json.load(open(os.path.join(RIV, "highway.json")))["roads"]
    lots = json.load(open(os.path.join(RIV, "lots.json")))
    shape = H.shape
    best = np.full(shape, 1e9, dtype=np.float32)
    road_y = np.zeros(shape, dtype=np.float32)
    core_w = np.full(shape, 44, dtype=np.float32)
    on_bridge = np.zeros(shape, dtype=bool)
    on_street = np.zeros(shape, dtype=bool)
    cut_min = np.full(shape, 1e9, dtype=np.float32)
    fill_max = np.full(shape, -1e9, dtype=np.float32)
    keep = np.zeros(shape, dtype=bool)

    def window(x, z, radius):
        r = int(radius / C) + 2
        ci, cj = int((x - X0) / C), int((z - Z0) / C)
        i0, i1 = max(ci - r, 0), min(ci + r + 1, shape[1])
        j0, j1 = max(cj - r, 0), min(cj + r + 1, shape[0])
        if i0 >= i1 or j0 >= j1:
            return None
        cx = X0 + C * (np.arange(i0, i1) + 0.5)
        cz = Z0 + C * (np.arange(j0, j1) + 0.5)
        dd = np.sqrt((cx[None, :] - x) ** 2 + (cz[:, None] - z) ** 2).astype(np.float32)
        return (slice(j0, j1), slice(i0, i1)), dd

    for r in roads:
        bridge = np.zeros(len(r["s"]), dtype=bool)
        for a, b in r.get("viaducts", []):
            bridge[a:b + 1] = True
        street = r["kind"] == "street"
        reach = STREET_REACH if street else REACH
        for k in range(len(r["s"])):
            s = r["s"][k]
            win = window(s[0], s[2], reach)
            if not win:
                continue
            sl, dd = win
            core = (s[6] + 4) if s[6] < 30 else 44
            out = np.maximum(dd - core, 0)
            bed = s[1] - 1.5
            if bridge[k]:
                # the bridge's underside has to stay clear; nothing else changes
                np.minimum(cut_min[sl], bed - 9 + out * STEEP, out=cut_min[sl])
            else:
                rise = out * STREET_RISE if street else cut_rise(out)
                np.minimum(cut_min[sl], np.where(dd < reach, bed + rise, 1e9), out=cut_min[sl])
                f = np.where(dd < reach, bed - out * FILL, -1e9)
                np.maximum(fill_max[sl], f, out=fill_max[sl])
            sub = best[sl]
            m = dd < sub
            sub[m] = dd[m]
            road_y[sl][m] = s[1]
            core_w[sl][m] = core
            on_bridge[sl][m] = bridge[k]
            on_street[sl][m] = street
    for r, rad in [(q, KEEP_ROUTE) for q in old] + [(q, KEEP_PASS if q["kind"] == "pass" else KEEP_ROUTE) for q in road_hw]:
        for s in r["s"]:
            win = window(s[0], s[2], rad + 4)
            if win:
                sl, dd = win
                keep[sl] |= dd < rad
    road_keep = keep.copy()
    for (x, z) in lots:
        win = window(x, z, LOT_R + 4)
        if win:
            sl, dd = win
            keep[sl] |= dd < LOT_R

    newH = H.copy()
    newM = M.copy()
    zone = best < REACH
    core = zone & (best <= core_w) & ~on_bridge
    bank = zone & ~core
    newH[core] = (road_y - 1.5)[core]
    lo = np.minimum(fill_max, cut_min)
    newH[bank] = np.clip(H[bank], lo[bank], cut_min[bank])
    newM[core] = "A"
    out_d = np.maximum(best - core_w, 0)
    cutm = bank & (H > newH + 0.3)
    fillm = bank & (H < newH - 0.3)
    newM[cutm & (out_d < ROCK_BAND) & ~on_street] = "R"
    newM[cutm & on_street] = "G"
    newM[fillm & (out_d < 24)] = "D"
    newM[fillm & (out_d >= 24)] = "G"
    newH[keep] = H[keep]
    newM[keep] = M[keep]
    cx = X0 + C * (np.arange(shape[1]) + 0.5)
    cz = Z0 + C * (np.arange(shape[0]) + 0.5)
    for (x, z, sx, sz, top) in LOT_HILLS:
        ox = np.maximum(np.abs(cx[None, :] - x) - sx / 2 - 3, 0)
        oz = np.maximum(np.abs(cz[:, None] - z) - sz / 2 - 3, 0)
        d = np.sqrt(ox ** 2 + oz ** 2)
        hill = (top - d * HILL_SLOPE).astype(np.float32)
        up = (hill > newH) & ~road_keep & (best > 46)
        newM[up] = "G"
        newH[up] = hill[up]
    # (a second run writes only what differs from the first, and puts back ground no longer changed)
    prev = os.path.join(RIV, "ground_after_north.npz")
    if os.path.exists(prev) and "--fresh" not in sys.argv:
        z = np.load(prev)
        H, M = z["H"], z["M"]
    changed = (np.abs(newH - H) > 0.12) | (newM != M)
    print("cells changed:", int(changed.sum()), " deepest cut %.0f, highest fill %.0f" % (float((H - newH).max()), float((newH - H).max())))

    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        os.remove(os.path.join(OUT, f))
    T = meta["tile"]
    tiles = {}
    js, iz = np.nonzero(changed)
    for j, i in zip(js.tolist(), iz.tolist()):
        tiles.setdefault((i // T, j // T), []).append([i, j, int(round(float(newH[j, i]) * 4)), str(newM[j, i])])
    names = []
    for (ti, tj), cols in sorted(tiles.items()):
        name = "cols_%d_%d.json" % (ti, tj)
        json.dump({"i": ti * T, "j": tj * T, "cols": cols}, open(os.path.join(OUT, name), "w"), separators=(",", ":"))
        names.append(name)
    above = float((H - newH).max()) + 40
    json.dump({"tiles": names, "cell": C, "x0": X0, "z0": Z0, "mats": meta["mats"], "above": above}, open(os.path.join(OUT, "index.json"), "w"), separators=(",", ":"))
    print(len(names), "tiles ->", OUT, " above", above)
    np.savez_compressed(os.path.join(RIV, "ground_after_north.npz"), H=newH, M=newM)


if __name__ == "__main__":
    main()
