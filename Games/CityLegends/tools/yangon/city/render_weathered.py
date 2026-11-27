"""render_weathered.py (2026-11-27, coordinator review of "buildings less blocky"): the stained render read cold
blue-grey and grimy, and its 9-stud tile repeated on big blank walls. Two new wall MaterialVariants, made from the
painted render (Poly Haven painted_plaster_wall, build/materials/render_painted) on a much larger tile:

  YgnRenderWeathered      front walls of the kit panels: 36 studs a tile, warm sun-faded, soft light blotches at two
                          scales, a few faint streaks; mean ~ the painted render's, so each wall keeps its own colour.
                          The strong grime stays where the panels' own vertex stains put it (under slabs, the roof
                          edge, AC units: kit_panels WALL_K).
  YgnRenderWeatheredSide  plain side / party walls (no slabs to hang streaks from): 48 studs a tile, more and longer
                          warm-grey rain streaks and mildew patches (Yankin side walls), still lighter than the old
                          stained render.

Real refs: build/landmarks/refs/kit/walkup_apartment/ (Yankin 5-storey, 30th / 47th St, balcony_grilles_grime) and
City Legends/2026-11-16 Critique - Yangon kit vs real photos.md (seen = paint x 0.8, stains warm grey-brown).

    python render_weathered.py   -> imports/sync/render_weathered/<variant>_{color,normal,rough}.png
                                     + build/render_weathered/preview.png
"""
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
SRC = os.path.join(ROOT, "build", "materials", "render_painted", "roblox", "render_painted_")
OUT = os.path.join(ROOT, "imports", "sync", "render_weathered")
PREV = os.path.join(ROOT, "build", "render_weathered")
N = 1024
SRC_TILE_M = 2.0   # the painted render's tile (spec.py)

SETS = {
    # name: tile (m), blotch darkening (large, small), streaks (count, darkness, length m), target mean
    "YgnRenderWeathered": dict(tile_m=12.0, blot=(0.10, 0.05), streaks=(16, 0.17, (1.5, 4.5)), mean=219.0),
    "YgnRenderWeatheredSide": dict(tile_m=16.0, blot=(0.14, 0.07), streaks=(30, 0.30, (2.0, 7.0)), mean=206.0),
}
WARM = np.array([1.045, 1.0, 0.925])        # sun-faded warm white
DIRT = np.array([1.0, 0.955, 0.90])         # stains are warm grey-brown, never blue


def tiled(path, k, mode):
    im = Image.open(path).convert(mode)
    a = np.asarray(im)
    big = np.tile(a, (k, k, 1) if a.ndim == 3 else (k, k))
    return np.asarray(Image.fromarray(big).resize((N, N), Image.LANCZOS)).astype(np.float32)


def pnoise(cells, rng):
    """tile-periodic smooth noise 0..1 (bicubic over a wrapped grid)."""
    g = rng.random((cells, cells))
    big = np.tile(g, (3, 3))
    up = np.asarray(Image.fromarray((big * 255).astype(np.uint8)).resize((N * 3, N * 3), Image.BICUBIC)).astype(np.float32) / 255
    return up[N:2 * N, N:2 * N]


def blur(a, r):
    if r <= 0:
        return a
    k = np.fft.fftfreq(N)
    g = np.exp(-(2 * np.pi * r) ** 2 * (k[:, None] ** 2 + k[None, :] ** 2) / 2)
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def streaks(count, dark, len_m, tile_m, rng):
    ppm = N / tile_m
    m = np.zeros((N, N), np.float32)
    yy = np.arange(N)
    for _ in range(count):
        x = rng.uniform(0, N)
        w = rng.uniform(0.25, 1.2) * ppm
        y0 = rng.uniform(0, N)
        L = rng.uniform(*len_m) * ppm
        a = rng.uniform(0.35, 1.0)
        d = (yy - y0) % N
        prof = np.clip(1 - d / L, 0, 1) ** 1.5 * np.clip(d / (0.05 * L + 1), 0, 1) * a
        xs = np.arange(int(x - 1.5 * w), int(x + 1.5 * w) + 1)
        g = np.exp(-((xs - x) / max(w / 2, 1)) ** 2)
        m[:, xs % N] = np.maximum(m[:, xs % N], prof[:, None] * g[None, :])
    return np.clip(blur(m, 5.0), 0, 1) * dark


def make(name, p, seed):
    rng = np.random.default_rng(seed)
    k = int(round(p["tile_m"] / SRC_TILE_M))
    col = tiled(SRC + "color.jpg", k, "RGB")
    nrm = tiled(SRC + "normal.png", k, "RGB")
    rough = tiled(SRC + "roughness.png", k, "L")
    grey = col.mean(-1)
    grey = grey / grey.mean()                       # the painted grain, mean 1
    base = (0.55 + 0.45 * grey)[..., None] * WARM   # grain softened: the fine tile repeat must not show at 36 studs
    big, small = p["blot"]
    dark = big * np.clip((pnoise(3, rng) - 0.35) / 0.65, 0, 1) + small * np.clip((pnoise(11, rng) - 0.4) / 0.6, 0, 1)
    dark += 0.5 * small * pnoise(29, rng)
    dark += streaks(p["streaks"][0], p["streaks"][1], p["streaks"][2], p["tile_m"], rng)
    dark = np.clip(dark, 0, 0.6)[..., None]
    rgb = base * (1 - dark) * (1 - dark * (1 - DIRT))   # darker AND warmer where dirty
    rgb = rgb / rgb.mean() * p["mean"]
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    rough = np.clip(rough + 30 * dark[..., 0], 0, 255).astype(np.uint8)   # grime is matte
    return rgb, nrm.astype(np.uint8), rough


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    tiles = []
    for i, (name, p) in enumerate(SETS.items()):
        c, n, r = make(name, p, 4100 + i)
        Image.fromarray(c, "RGB").save(os.path.join(OUT, name + "_color.png"))
        Image.fromarray(n, "RGB").save(os.path.join(OUT, name + "_normal.png"))
        Image.fromarray(r, "L").save(os.path.join(OUT, name + "_rough.png"))
        print(name, "mean", c.reshape(-1, 3).mean(0).round(1), "tile studs", p["tile_m"] * 3)
        # preview: 2 x 2 tiles at a 230,226,214 wall (the shell / kit KW6 colour) so the repeat can be judged
        wall = np.array([222, 212, 194]) / 255.0
        t = np.tile(c, (2, 2, 1)).astype(np.float32) * wall
        tiles.append(Image.fromarray(np.clip(t, 0, 255).astype(np.uint8)).resize((768, 768)))
    sheet = Image.new("RGB", (768 * len(tiles), 768))
    for i, im in enumerate(tiles):
        sheet.paste(im, (768 * i, 0))
    sheet.save(os.path.join(PREV, "preview.png"))


if __name__ == "__main__":
    main()
