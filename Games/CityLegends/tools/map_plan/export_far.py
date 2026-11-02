"""
Far city data for the Riviera (owner 2026-11-02: "on the summit make it so that u can see the city lights").

Roblox streams parts and terrain out past ~1500 studs, so from the summit the far half of the city was
gone. tools/riviera/FarCity.luau builds a light stand-in that every client always has (a Persistent
model) and that shows only far away. This writes the parts of it that come from the map data:

  * ground: a 128-stud triangle grid over the land (heights a little under the real terrain, so the
    stand-in never pokes through where both are loaded), with the main ground colour of each cell
  * roads: one flat strip per ~40 studs of road (tunnels left out)

Output: build/riviera/far.json
"""
import json
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "build", "riviera")

G = 32  # grid step in terrain cells (32 x 4 studs = 128 studs)
REACH = 8  # vertex height = lowest sample within +-8 cells (32 studs), then 2 studs lower
DROP = 2.0
ROAD_STEP = 40.0
HALF = 32


def main():
    meta = json.load(open(os.path.join(OUT, "meta.json")))
    nx, nz, cell = meta["nx"], meta["nz"], meta["cell"]
    x0, z0 = meta["x0"], meta["z0"]
    h = np.full((nz, nx), np.nan, dtype=np.float32)
    m = np.full((nz, nx), "W", dtype="<U1")
    for name in meta["tiles"]:
        t = json.load(open(os.path.join(OUT, name)))
        i, j, w, d = t["i"], t["j"], t["w"], t["d"]
        hv = np.array(t["h"], dtype=np.float32).reshape(d, w) / 4
        h[j : j + d, i : i + w] = hv
        mv = np.array(list(t["m"]), dtype="<U1").reshape(d, w)
        m[j : j + d, i : i + w] = mv
    h = np.nan_to_num(h, nan=-20.0)

    gx = nx // G + 1
    gz = nz // G + 1
    verts = np.zeros((gz, gx), dtype=np.float32)
    for vj in range(gz):
        for vi in range(gx):
            ci, cj = vi * G, vj * G
            win = h[max(0, cj - REACH) : cj + REACH + 1, max(0, ci - REACH) : ci + REACH + 1]
            verts[vj, vi] = float(win.min()) - DROP if win.size else -20.0

    mats = list(meta["mats"].keys())
    cells = []  # [vi, vj, matIndex]
    for vj in range(gz - 1):
        for vi in range(gx - 1):
            q = [verts[vj, vi], verts[vj, vi + 1], verts[vj + 1, vi], verts[vj + 1, vi + 1]]
            if max(q) < 0.5:
                continue  # sea
            block = m[vj * G : (vj + 1) * G, vi * G : (vi + 1) * G]
            land = block[block != "W"]
            if land.size == 0:
                continue
            vals, counts = np.unique(land, return_counts=True)
            cells.append([vi, vj, mats.index(str(vals[counts.argmax()]))])

    data = json.load(open(os.path.join(OUT, "roads.json")))
    roads = []
    for r in data["roads"]:
        pts = r["s"]
        seg = [pts[0]]
        acc = 0.0
        for k in range(1, len(pts)):
            a, b = pts[k - 1], pts[k]
            acc += ((b[0] - a[0]) ** 2 + (b[2] - a[2]) ** 2) ** 0.5
            if acc >= ROAD_STEP or k == len(pts) - 1:
                seg.append(b)
                acc = 0.0
        for k in range(1, len(seg)):
            a, b = seg[k - 1], seg[k]
            if a[5] == 1 or b[5] == 1:
                continue  # tunnel
            wl = a[6] if len(a) > 6 else HALF
            wr = a[7] if len(a) > 7 else HALF
            roads.append([round(a[0], 1), round(a[1], 2), round(a[2], 1), round(b[0], 1), round(b[1], 2), round(b[2], 1), round(wl + wr, 1)])

    out = {
        "x0": x0,
        "z0": z0,
        "step": G * cell,
        "gx": gx,
        "gz": gz,
        "mats": mats,
        "verts": [round(float(v), 1) for v in verts.flatten()],
        "cells": cells,
        "roads": roads,
    }
    json.dump(out, open(os.path.join(OUT, "far.json"), "w"), separators=(",", ":"))
    print(f"far.json: grid {gx}x{gz}, {len(cells)} land cells, {len(roads)} road strips")


if __name__ == "__main__":
    main()
