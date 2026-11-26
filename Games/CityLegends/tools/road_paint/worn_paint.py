"""Worn road paint maps (27 Nov 2026, owner: "get close to that game reference" = the TorqX Racing study: worn,
chipped lines and textured zebras). Tileable 512 px: colour (white paint, chips where it wore off show a dark
grey, fine grit), roughness (paint 0.55, chips 0.85). Used by MaterialVariant CL_RoadPaintWorn (base SmoothPlastic)
on the road line meshes (Roads.Meshes RMeshL / LY / LZ). Run: python worn_paint.py <outdir>"""
import numpy as np, sys, os
from PIL import Image
N = 512
rng = np.random.default_rng(27)
out = sys.argv[1] if len(sys.argv) > 1 else '.'
os.makedirs(out, exist_ok=True)

def tile_noise(cells):
    """tileable value noise: random grid (wrapping) upsampled with smooth interpolation"""
    g = rng.random((cells, cells))
    x = np.arange(N) * cells / N
    i0 = np.floor(x).astype(int) % cells
    i1 = (i0 + 1) % cells
    t = x - np.floor(x)
    t = t * t * (3 - 2 * t)
    a = g[i0][:, i0] * (1 - t)[None, :] + g[i0][:, i1] * t[None, :]
    b = g[i1][:, i0] * (1 - t)[None, :] + g[i1][:, i1] * t[None, :]
    return a * (1 - t)[:, None] + b * t[:, None]

fbm = sum(tile_noise(c) * w for c, w in ((8, 0.3), (16, 0.3), (32, 0.25), (64, 0.15)))  # (fine: many small chips, not blobs)
fbm = (fbm - fbm.min()) / (fbm.max() - fbm.min())
grit = tile_noise(128) * 0.6 + rng.random((N, N)) * 0.4
chips = fbm > 0.70            # where the paint wore through
edge = (fbm > 0.65) & ~chips   # thin worn rim round each chip
col = 0.93 + 0.07 * grit       # paint, slightly uneven
col = np.where(edge, 0.78 + 0.1 * grit, col)
col = np.where(chips, 0.32 + 0.12 * grit, col)   # the asphalt showing through (x white = mid grey)
rough = np.where(chips, 0.85, np.where(edge, 0.7, 0.55)) + (grit - 0.5) * 0.06
c8 = (np.clip(col, 0, 1) * 255).astype(np.uint8)
Image.fromarray(np.stack([c8] * 3, -1)).save(f'{out}/cl_paint_worn_color.png')
Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8)).save(f'{out}/cl_paint_worn_rough.png')
print('chips %.1f%%  rim %.1f%%' % (chips.mean() * 100, edge.mean() * 100))
