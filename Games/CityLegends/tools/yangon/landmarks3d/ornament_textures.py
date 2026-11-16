"""ornament_textures.py (2026-11-16): the carved-relief maps for the ornament kit's panel field (group P), drawn in code.

A seamless 512 px tile of Burmese foliate carving: a diaper of scroll leaves round small rosettes, with leaf veins and a
bead border, as a HEIGHTFIELD; from it a normal map (OpenGL, +Y up, as Roblox wants), a colour map (white with dark
cavities: the part's Color tints it, so one set serves gold and cream), a roughness map (cavities rough, raised polish
smooth) and a metalness map. No photo is copied.

    python ornament_textures.py   -> build/landmarks/ornament/tex/carved_{height,normal,color,rough,metal}.png
Used by the MaterialVariants YgnCarvedGold (Metal) and YgnCarvedPlaster (SmoothPlastic), StudsPerTile 3 (1 m).
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

N = 512
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "build", "landmarks", "ornament", "tex")


def spiral_pts(cx, cy, r0, turns, start, hand, k=40):
    pts = []
    for i in range(k + 1):
        s = i / k
        a = start + hand * 2 * math.pi * turns * s
        r = r0 * (1 - 0.8 * s)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def draw_tile(d, ox, oy, S):
    """One motif cell of size S at (ox, oy) in a 2x2 cell tile: rosette centre, four scroll leaves, veins, beads."""
    cx, cy = ox + S / 2, oy + S / 2
    # rosette: 8 petals + boss
    for i in range(8):
        a = 2 * math.pi * i / 8
        px, py = cx + 0.16 * S * math.cos(a), cy + 0.16 * S * math.sin(a)
        d.ellipse([px - 0.07 * S, py - 0.07 * S, px + 0.07 * S, py + 0.07 * S], fill=170)
    d.ellipse([cx - 0.08 * S, cy - 0.08 * S, cx + 0.08 * S, cy + 0.08 * S], fill=235)
    # four scroll leaves turning round the rosette
    for q in range(4):
        a0 = q * math.pi / 2 + math.pi / 4
        sx, sy = cx + 0.33 * S * math.cos(a0), cy + 0.33 * S * math.sin(a0)
        pts = spiral_pts(sx, sy, 0.15 * S, 1.1, a0 + math.pi, 1 if q % 2 else -1)
        for j in range(len(pts) - 1):
            wd = int(max(2, 0.07 * S * (1 - j / len(pts))))
            d.line([pts[j], pts[j + 1]], fill=210, width=wd)
        # leaf from the rosette to the scroll, with a vein
        lx, ly = cx + 0.22 * S * math.cos(a0), cy + 0.22 * S * math.sin(a0)
        d.line([(cx, cy), (lx, ly)], fill=190, width=int(0.05 * S))
        d.line([(cx, cy), (lx, ly)], fill=120, width=max(1, int(0.008 * S)))
    # bead row along the cell's edges (shared with the neighbours, so the tile repeats)
    nb = 8
    for i in range(nb):
        t = (i + 0.5) / nb
        for bx, by in ((ox + t * S, oy), (ox, oy + t * S)):
            d.ellipse([bx - 0.025 * S, by - 0.025 * S, bx + 0.025 * S, by + 0.025 * S], fill=200)


def main():
    os.makedirs(OUT, exist_ok=True)
    big = Image.new("L", (3 * N, 3 * N), 70)
    d = ImageDraw.Draw(big)
    S = N / 2
    for gy in range(6):
        for gx in range(6):
            draw_tile(d, gx * S, gy * S, S)
    big = big.filter(ImageFilter.GaussianBlur(2.2))
    h = np.asarray(big, dtype=np.float32)[N:2 * N, N:2 * N] / 255.0
    Image.fromarray((h * 255).astype(np.uint8)).save(os.path.join(OUT, "carved_height.png"))
    strength = 6.0
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    nx, ny, nz = -dx, dy, np.ones_like(h)            # OpenGL convention: +Y up in the picture
    L = np.sqrt(nx * nx + ny * ny + nz * nz)
    nrm = np.stack([nx / L, ny / L, nz / L], -1)
    Image.fromarray(((nrm * 0.5 + 0.5) * 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "carved_normal.png"))
    # cavities: the blurred difference between the local mean and the height
    blur = np.asarray(Image.fromarray((h * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(9)),
                      dtype=np.float32) / 255.0
    cav = np.clip((blur - h) * 3.0 + 0.5 * (1 - h), 0, 1)
    col = np.clip(1.0 - 0.55 * cav, 0, 1)
    c8 = (col * 255).astype(np.uint8)
    Image.fromarray(np.stack([c8, c8, c8], -1), "RGB").save(os.path.join(OUT, "carved_color.png"))
    rough = np.clip(0.28 + 0.5 * cav, 0, 1)
    Image.fromarray((rough * 255).astype(np.uint8)).save(os.path.join(OUT, "carved_rough.png"))
    Image.fromarray(np.full((N, N), 255, np.uint8)).save(os.path.join(OUT, "carved_metal.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
