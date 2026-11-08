"""
A grille's mesh pattern changed (owner, 2026-11-06, `Prompts/Small design changes on famous new cars.md`: "mesh pattern
hex -> diamond"): the model's small repeating grille picture is redrawn with another hole shape, in the same size,
colours and spacing, so the grille looks the same from the normal camera. A normal picture is made to match, with the
strength and direction read off the model's own.

    python tools/details_tiles.py colour.png [normal.png] <pattern> out_prefix [--check]

pattern: "auto" (big cells -> diamond, small holes -> hex), "diamond" (each hole a diamond: a hex mesh becomes a diamond mesh), "hex" (each hole a hexagon, same area:
round perforations become hexagon ones), "slot" (each hole a rounded slot across), "square" (rounded squares).
Writes <out_prefix>_colour.png (and _normal.png); --check also <out_prefix>_check.png (old | new, small tiles 8 x 8 repeats).
"""

import sys

import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if a != "--check"]
CHECK = "--check" in sys.argv
col_path = args[0]
nrm_path = args[1] if len(args) == 4 else None
pattern, out = args[-2], args[-1]

src = Image.open(col_path)
mode = src.mode
C = np.asarray(src.convert("RGBA"), float)
H, W = C.shape[:2]
L = C[..., :3] @ np.array([0.299, 0.587, 0.114])
if np.percentile(L, 95) - np.percentile(L, 5) < 6:
    # (a plain picture: its pattern, if any, is in the normal picture only; nothing to redraw)
    print("TILES flat, nothing to do")
    sys.exit(2)
thr = (np.percentile(L, 5) + np.percentile(L, 95)) / 2
dark = L < thr
fd = dark.mean()
if pattern == "auto":
    # a mesh of big cells (a hex mesh) becomes diamonds, small holes in a plate (perforations) become hexagons
    pattern = "diamond" if fd > 0.33 else "hex"
    print("TILES auto ->", pattern)
hole = np.median(C[dark], 0)
frame = np.median(C[~dark], 0)


def regions(mask):
    """connected regions of a mask on a tile that wraps"""
    lab = -np.ones(mask.shape, int)
    out = []
    for y in range(H):
        for x in range(W):
            if mask[y, x] and lab[y, x] < 0:
                stack = [(y, x)]
                lab[y, x] = len(out)
                pts = []
                while stack:
                    a, b = stack.pop()
                    pts.append((a, b))
                    for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        c, d = (a + da) % H, (b + db) % W
                        if mask[c, d] and lab[c, d] < 0:
                            lab[c, d] = len(out)
                            stack.append((c, d))
                out.append(np.array(pts, float))
    return out


def centre(pts):
    """the middle of a region that may cross the tile's edges (circular means)"""
    ang_y = pts[:, 0] / H * 2 * np.pi
    ang_x = pts[:, 1] / W * 2 * np.pi
    cy = (np.arctan2(np.sin(ang_y).mean(), np.cos(ang_y).mean()) / (2 * np.pi) * H) % H
    cx = (np.arctan2(np.sin(ang_x).mean(), np.cos(ang_x).mean()) / (2 * np.pi) * W) % W
    return cx + 0.5, cy + 0.5


regs = [r for r in regions(dark) if len(r) >= 3]
if regs:
    # specks in the frame's shading are not holes
    med = np.median([len(r) for r in regs])
    regs = [r for r in regs if len(r) >= 0.35 * med]
cents = [centre(r) + (len(r),) for r in regs]
print("TILES", W, "x", H, "holes", len(cents), "dark share", round(fd, 3), "hole", hole.round(1), "frame", frame.round(1))

def lattice():
    """half-diagonals of the diamond cells: the offset to the first hole's nearest diagonal neighbour (a neighbour
    straight across or straight up doesn't count; the median of all holes' answers, so one odd hole can't spoil it)"""
    pts = np.array([c[:2] for c in cents])
    offs = []
    for c0 in pts[: min(len(pts), 40)]:
        best = None
        for c in pts:
            for ox in (-W, 0, W):
                for oy in (-H, 0, H):
                    d = c + (ox, oy) - c0
                    ax_, ay_ = abs(d[0]), abs(d[1])
                    if np.hypot(ax_, ay_) < 1 or ax_ < 0.3 * ay_ or ay_ < 0.3 * ax_:
                        continue
                    if best is None or np.hypot(*d) < np.hypot(*best):
                        best = d
        if best is not None:
            offs.append((abs(best[0]), abs(best[1])))
    if not offs:
        return W / np.sqrt(2 * len(cents)), H / np.sqrt(2 * len(cents))
    offs = np.array(offs)
    return float(np.median(offs[:, 0])), float(np.median(offs[:, 1]))


LATTICE = lattice() if cents else (W / 2, H / 2)
S = 4  # samples a pixel
ys, xs = np.mgrid[0:H * S, 0:W * S]
px = (xs + 0.5) / S
py = (ys + 0.5) / S
inside = np.zeros(px.shape, bool)
if pattern == "diamond" and cents:
    # snapped so the cells fit the tile exactly (no seam at the edges); a checkerboard lattice of diamonds, drawn in one go
    a = W / max(1, round(W / LATTICE[0]))
    b = H / max(1, round(H / LATTICE[1]))
    if round(W / a) % 2 or round(H / b) % 2:
        # the tile must hold whole pairs, or the checkerboard breaks at the edge
        a = W / (2 * max(1, round(W / (2 * a))))
        b = H / (2 * max(1, round(H / (2 * b))))
    LATTICE = (a, b)
    c0 = cents[0]
    u = (px - c0[0]) / a
    v = (py - c0[1]) / b
    fu, fv = np.floor(u), np.floor(v)
    best = np.full(u.shape, 9.0)
    for du in (0, 1):
        for dv in (0, 1):
            iu, iv = fu + du, fv + dv
            even = ((iu + iv) % 2) == 0
            d = np.abs(u - iu) + np.abs(v - iv)
            best = np.where(even & (d < best), d, best)
    k = np.sqrt(fd)  # (1 - frame share) so the dark share stays the same
    inside = best <= k
    print("TILES lattice", [round(float(x), 2) for x in LATTICE], "cells across", round(W / a), "down", round(H / b))
else:
    for cx, cy, area in cents:
        # only a window round each hole (big tiles hold hundreds)
        r_ = int(np.ceil(2.2 * np.sqrt(area))) + 2
        xi = (np.arange(int((cx - r_) * S), int((cx + r_) * S))) % (W * S)
        yi = (np.arange(int((cy - r_) * S), int((cy + r_) * S))) % (H * S)
        XX, YY = np.meshgrid(xi, yi)
        dx = ((XX + 0.5) / S - cx + W / 2) % W - W / 2
        dy = ((YY + 0.5) / S - cy + H / 2) % H - H / 2
        if pattern == "hex":
            r = np.sqrt(area / (1.5 * np.sqrt(3)))  # a flat-top hexagon of the same area
            q = np.abs(dx)
            t = np.abs(dy)
            hit = (t <= np.sqrt(3) / 2 * r) & (np.sqrt(3) * q + t <= np.sqrt(3) * r)
        elif pattern in ("slot", "square"):
            ar = 2.4 if pattern == "slot" else 1.0
            hh = np.sqrt(area / ar)
            hw = hh * ar
            rr = hh * (0.5 if pattern == "slot" else 0.28)
            qx = np.maximum(np.abs(dx) - (hw / 2 - rr), 0)
            qy = np.maximum(np.abs(dy) - (hh / 2 - rr), 0)
            hit = qx * qx + qy * qy <= rr * rr
        else:
            raise SystemExit("unknown pattern " + pattern)
        inside[YY[hit], XX[hit]] = True
cover = inside.reshape(H, S, W, S).mean((1, 3))  # hole share of each pixel, soft edge
newC = frame[None, None, :] * (1 - cover[..., None]) + hole[None, None, :] * cover[..., None]
newC = np.clip(newC, 0, 255)
img = Image.fromarray(newC.round().astype(np.uint8), "RGBA").convert(mode if mode in ("L", "RGB", "RGBA", "LA") else "RGBA")
img.save(out + "_colour.png")


def blur(a, n=1):
    for _ in range(n):
        a = (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5
    return a


def grads(h):
    return (np.roll(h, -1, 1) - np.roll(h, 1, 1)) / 2, (np.roll(h, -1, 0) - np.roll(h, 1, 0)) / 2


REP = 8 if max(W, H) <= 128 else 1
check = [np.tile(C[..., :3], (REP, REP, 1)), np.tile(newC[..., :3], (REP, REP, 1))]
if nrm_path:
    nimg = Image.open(nrm_path).convert("RGB")
    NSIZE = nimg.size
    if NSIZE != (W, H):
        # (a normal picture bigger than its colour picture: read at the colour's size, written back at its own)
        nimg = nimg.resize((W, H), Image.BILINEAR)
    Nm = np.asarray(nimg, float) / 255 * 2 - 1
    h_old = blur((~dark).astype(float), 1)
    gx, gy = grads(h_old)
    m = (np.abs(gx) + np.abs(gy)) > 0.05
    sx = (Nm[..., 0][m] @ -gx[m]) / max(gx[m] @ gx[m], 1e-6)
    sy = (Nm[..., 1][m] @ -gy[m]) / max(gy[m] @ gy[m], 1e-6)
    print("TILES normal strength", round(sx, 3), round(sy, 3))
    h_new = blur(1 - cover, 1)
    gx, gy = grads(h_new)
    n = np.dstack([-gx * sx * 1.6, -gy * sy * 1.6, np.ones_like(gx)])  # the old bevels are sharper than a blur
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    nout = Image.fromarray(((n * 0.5 + 0.5) * 255).round().astype(np.uint8), "RGB")
    if NSIZE != (W, H):
        nout = nout.resize(NSIZE, Image.BICUBIC)
    nout.save(out + "_normal.png")
    check += [np.tile((Nm * 0.5 + 0.5) * 255, (REP, REP, 1)), np.tile((n * 0.5 + 0.5) * 255, (REP, REP, 1))]
if CHECK:
    sheet = np.concatenate(check, 1)
    Image.fromarray(sheet.clip(0, 255).astype(np.uint8)).resize((sheet.shape[1] * 2, sheet.shape[0] * 2), Image.NEAREST).save(out + "_check.png")
print("TILES wrote", out + "_colour.png", "normal" if nrm_path else "")
