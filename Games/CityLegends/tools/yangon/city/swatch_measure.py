"""swatch_measure.py: read the colour panels (tools/yangon/Swatches.luau) off two Studio screen captures.

    python swatch_measure.py <views.txt> <sun.jpg> <shade.jpg> <out.json> [label]
views.txt = the text Swatches.views() returned. Writes {"sun": {mat: [[r,g,b] x 10 greys]}, "shade": ...} with the
greys in ascending order (20..245), and prints a short summary (white and mid grey per side).
"""
import json
import sys

import numpy as np
from PIL import Image

GREYS = [20, 45, 70, 95, 120, 145, 170, 195, 220, 245]


def main():
    views, sun, shade, out = sys.argv[1:5]
    lines = [l for l in open(views).read().splitlines() if l.strip()]
    pos = {}
    for l in lines:
        if " cam" in l:
            continue
        for item in l.split(";"):
            n, fx, fy = item.split()
            pos[n] = (float(fx), float(fy))
    res = {}
    for side, f in (("sun", sun), ("shade", shade)):
        im = np.asarray(Image.open(f).convert("RGB")).astype(float)
        H, W, _ = im.shape
        res[side] = {}
        mats = sorted({n.split("_")[1] for n in pos if n.startswith(side + "_")})
        for m in mats:
            row = []
            for g in GREYS:
                fx, fy = pos["%s_%s_%d" % (side, m, g)]
                cx, cy = int(fx * W), int(fy * H)
                p = im[cy - 7:cy + 8, cx - 7:cx + 8].reshape(-1, 3)
                row.append([int(v) for v in np.median(p, axis=0)])
            res[side][m] = row
    json.dump(res, open(out, "w"))
    for side in ("sun", "shade"):
        sp = res[side]["SmoothPlastic"]
        print(side, "plastic 245", sp[-1], "145", sp[5], "20", sp[0], "| sandstone 245", res[side]["Sandstone"][-1])


if __name__ == "__main__":
    main()
