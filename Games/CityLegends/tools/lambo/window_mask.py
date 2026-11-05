"""A flat cluster panel cut to the car's opening, so its corners don't stand out over the dash
(tools/lambo/frame_probe.py's depth map -> window_<name>.png, which cluster_live.py's masked() uses).
White where the model has a surface at the panel or in front of it; black where the panel would hang in
the air or over something far behind it.

    python tools/lambo/window_mask.py depth.json out.png u v w h px_w px_h [behind]

u, v: the panel's middle from the probe's point (m, u to the driver's right); w, h: its size (m);
px: the picture's size; behind: how far behind the probe's plane still counts (m, default 0.012).
"""

import json
import sys

import numpy as np
from PIL import Image, ImageFilter

depth, out = sys.argv[1], sys.argv[2]
u0, v0, w, h = [float(x) for x in sys.argv[3:7]]
pw, ph = int(sys.argv[7]), int(sys.argv[8])
behind = float(sys.argv[9]) if len(sys.argv) > 9 else 0.012
j = json.load(open(depth))
step, ug, vg = j["step"], j["u0"], j["v0"]
d = np.array([[(c[0] if c[0] is not None else -9.0) for c in row] for row in j["rows"]], float)
ok = d > -behind
xs = u0 - w / 2 + (np.arange(pw) + 0.5) / pw * w
ys = v0 + h / 2 - (np.arange(ph) + 0.5) / ph * h
ix = np.clip(((xs - ug) / step).round().astype(int), 0, d.shape[1] - 1)
iy = np.clip(((vg - ys) / step).round().astype(int), 0, d.shape[0] - 1)
m = ok[np.ix_(iy, ix)]
im = Image.fromarray((m * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.2))
im.save(out)
print("mask", out, "open", round(m.mean(), 3))
