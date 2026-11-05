"""A sharp 2 x 2 twill carbon tile, 512 px, for the imported cars' carbon parts (overnight prompt, step 1). The games'
tile is 128 px; the new one keeps its number of weave repeats, so it lands on the same UVs at the same scale. Writes
colour, normal and roughness.

    python tools/lambo/carbon_tile.py old_tile.png outdir
"""

import sys

import numpy as np
from PIL import Image

old, out = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(old).convert("L")).astype(float)
a -= a.mean()
# the pattern's period along a row, from the autocorrelation
f = np.abs(np.fft.fft(a.mean(axis=0))) ** 2 + np.abs(np.fft.fft(a, axis=1)).mean(axis=0) ** 2
f[0] = 0
n = int(np.argmax(f[1:64])) + 1  # repeats of the pattern across the tile
print("repeats across the tile", n, "period px", 128 / n)
S = 512
U = 4  # a 2 x 2 twill repeats every 4 tows
cell = S / (n * U)
yy, xx = np.mgrid[0:S, 0:S] + 0.5
i = np.floor(xx / cell).astype(int)
j = np.floor(yy / cell).astype(int)
warp = ((i + j) % 4) < 2  # warp tow on top, else weft
fx = xx / cell - i - 0.5  # -0.5 .. 0.5 across the cell
fy = yy / cell - j - 0.5
across = np.where(warp, fx, fy)  # across the tow on top
along = np.where(warp, fy, fx)  # along it
# height: a rounded tow, dipping where it goes under its neighbours
h = (1 - (across * 2) ** 2 * 0.55) * (1 - (along * 2) ** 4 * 0.35)
# fine fibres along the tow
rng = np.random.default_rng(7)
fib = rng.normal(0, 1, (S, S))
fib_v = np.roll(fib, 0, 0)
from_x = np.apply_along_axis(lambda r: np.convolve(np.r_[r, r[:9]], np.ones(9) / 9, "valid")[: S], 1, fib)
from_y = np.apply_along_axis(lambda r: np.convolve(np.r_[r, r[:9]], np.ones(9) / 9, "valid")[: S], 0, fib)
fibres = np.where(warp, from_y, from_x)
h2 = h + fibres * 0.02
# colour: the weft reads lighter than the warp, each with a soft sheen along the tow
base = np.where(warp, 15.0, 27.0) + (h - 0.6) * 22 + fibres * 3.0
col = np.clip(np.dstack([base, base * 1.0, base * 1.06]), 0, 255).astype("uint8")
Image.fromarray(col).save(out + "/carbon_c.png")
# normal from the height (tiles)
dx = (np.roll(h2, -1, 1) - np.roll(h2, 1, 1)) * 2.2
dy = (np.roll(h2, -1, 0) - np.roll(h2, 1, 0)) * 2.2
nz = np.ones_like(dx)
ln = np.sqrt(dx * dx + dy * dy + nz * nz)
nor = np.dstack([(-dx / ln + 1) / 2, (dy / ln + 1) / 2, (nz / ln + 1) / 2]) * 255
Image.fromarray(nor.astype("uint8")).save(out + "/carbon_n.png")
# roughness: clear coat, a touch rougher in the valleys between tows
r = np.clip(0.26 + (1 - h) * 0.16 + fibres * 0.015, 0, 1) * 255
Image.fromarray(r.astype("uint8")).save(out + "/carbon_r.png")
print("cell px", cell)
