"""Textures for the wheel kit v2 (2026-11-08, Prompts/A million times better wheels (new models).md).

Plain Python (PIL + numpy):  python tools/wheels/wheel_textures.py imports/wheels2/tex

Tyres (UV: U = half the way round, so everything shows twice; V = across the profile in fixed bands, the same on
every tyre mesh of tools/wheels/wheel_library_v2.py):
    0.00-0.05 bead (rim protector ridges)   0.05-0.30 outer sidewall (our lettering)   0.30-0.38 shoulder
    0.38-0.62 tread (normal map, lighter worn rubber)   0.62-0.70 shoulder   0.70-1.00 inner sidewall (plain)
Tread kinds: sport, cup, touring, offroad. Lettering: our own made-up tyre maker (never a real brand).
Discs (UV: the disc seen from the side, planar, the middle at 0.5, 0.5, the edge at radius 0.5): steel, drilled, slotted,
ceramic. The friction ring is from radius 0.4 to 1.0 of the disc (texture radius 0.2 to 0.5).
Plus the lip's machined rings (roughness) and plain one-value maps.
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else "imports/wheels2/tex"
os.makedirs(OUT, exist_ok=True)
FONTS = "C:/Windows/Fonts/"
rng = np.random.default_rng(7)


def save(name, arr, mode=None):
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    Image.fromarray(arr, mode).save(os.path.join(OUT, name + ".png"))


def normal_from_height(h, strength):
    """h: 0..1 height field (rows = V, cols = U), wraps in U. Returns an RGB normal map (OpenGL / Roblox: +Y up)."""
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5
    dy = np.zeros_like(h)
    dy[1:-1] = (h[2:] - h[:-2]) * 0.5
    nx, ny = -dx * strength, dy * strength
    nz = np.ones_like(h)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack([nx / ln, ny / ln, nz / ln], -1)
    return (rgb * 0.5 + 0.5) * 255


def blur(a, r):
    im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(r)), dtype=np.float32) / 255


def flat(name, value, size=8):
    save(name, np.full((size, size), value, np.float32))


# ------------------------------------------------------------------ tyres
TW, TH = 1024, 512  # U across half the tyre, V across the profile
V_TREAD = (0.38, 0.62)
V_SIDE = (0.05, 0.30)
V_BEAD = (0.0, 0.05)


def rows(a, b):
    return slice(int(a * TH), int(b * TH))


def tread_height(kind):
    """the tread's height field in its band: 1 = rubber top, 0 = groove floor"""
    a, b = int(V_TREAD[0] * TH), int(V_TREAD[1] * TH)
    h = np.ones((b - a, TW), np.float32)
    n = b - a
    yy, xx = np.mgrid[0:n, 0:TW].astype(np.float32)
    v = yy / n  # 0..1 across the tread (0 = outer side)

    def groove(at, width):
        h[np.abs(v - at) < width / 2] = 0.0

    if kind == "cup":
        pitch = TW / 18
        groove(0.36, 0.05)
        groove(0.66, 0.045)
        # a few long slanted cuts on the outer shoulder only
        u = (xx + v * 60) % pitch
        h[(u < 5) & (v < 0.22)] = 0.0
        h[(((xx - v * 40) % pitch) < 4) & (v > 0.86)] = 0.0
    elif kind == "sport":
        pitch = TW / 30
        for at, w in ((0.24, 0.05), (0.43, 0.055), (0.6, 0.055), (0.79, 0.045)):
            groove(at, w)
        # angled lateral grooves on the outer blocks, sipes on the inner ones (asymmetric)
        h[(((xx + v * 90) % pitch) < 4.5) & (v < 0.21)] = 0.0
        h[(((xx - v * 70) % (pitch * 2)) < 3) & (v > 0.27) & (v < 0.4)] = 0.0
        h[(((xx + v * 50) % pitch) < 2.2) & (v > 0.63) & (v < 0.76)] = 0.0
        h[(((xx - v * 80) % pitch) < 4.0) & (v > 0.82)] = 0.0
    elif kind == "touring":
        pitch = TW / 36
        for at, w in ((0.2, 0.045), (0.4, 0.05), (0.6, 0.05), (0.8, 0.045)):
            groove(at, w)
        h[(((xx + v * 60) % pitch) < 3.5) & ((v < 0.17) | (v > 0.83))] = 0.0
        for lo, hi in ((0.23, 0.37), (0.43, 0.57), (0.63, 0.77)):
            h[(((xx + v * 30) % (pitch / 2)) < 1.6) & (v > lo) & (v < hi)] = 0.0
    else:  # offroad: big blocks
        pitch = TW / 22
        cell = ((xx // pitch) % 2).astype(np.int32)
        bx = (xx % pitch) / pitch
        h[(v > 0.47) & (v < 0.53)] = 0.0
        h[(bx < 0.18)] = 0.0
        h[(cell == 0) & (np.abs(v - 0.28) < 0.05)] = 0.0
        h[(cell == 1) & (np.abs(v - 0.72) < 0.05)] = 0.0
        h[(cell == 1) & (v < 0.06)] = 0.0
        h[(cell == 0) & (v > 0.94)] = 0.0
    # soften the edges a touch (moulded, not cut)
    return blur(h, 0.9)


LETTERING = {
    # tread kind: (the maker, the line). Made up: "Velodrome" / "Corsa" etc are words, not tyre makers
    "cup": ("VELODROME", "CORSA R"),
    "sport": ("VELODROME", "STRADA SPORT"),
    "touring": ("VELODROME", "GRAN TURISMO"),
    "offroad": ("VELODROME", "TERRA A/T"),
}


def lettering_height(kind):
    """raised letters on the outer sidewall band (same black rubber, so they show by their edges)"""
    a, b = int(V_SIDE[0] * TH), int(V_SIDE[1] * TH)
    n = b - a
    im = Image.new("L", (TW, n), 0)
    d = ImageDraw.Draw(im)
    maker, line = LETTERING[kind]
    big = ImageFont.truetype(FONTS + "bahnschrift.ttf", int(n * 0.5))
    small = ImageFont.truetype(FONTS + "bahnschrift.ttf", int(n * 0.2))
    # V runs from the bead (row 0) out to the shoulder: letters read from outside with their tops towards the tread
    d.text((TW * 0.06, n * 0.24), maker, font=big, fill=255)
    d.text((TW * 0.63, n * 0.4), line, font=small, fill=255)
    d.text((TW * 0.63, n * 0.66), "RADIAL  TUBELESS  XL", font=ImageFont.truetype(FONTS + "bahnschrift.ttf", int(n * 0.12)), fill=200)
    # a thin moulded ring under the letters
    d.line([(0, int(n * 0.9)), (TW, int(n * 0.9))], fill=110, width=2)
    arr = np.asarray(im, np.float32) / 255
    # the texture's rows run bead -> shoulder; letters drawn upright put their tops at row 0 (the bead): turn them
    # round so their tops face the tread, as on a real tyre (which way round they read is set by the mesh's U)
    arr = arr[::-1, ::-1]
    return blur(arr, 0.7)


def tyre(kind):
    h = np.zeros((TH, TW), np.float32) + 0.5
    col = np.zeros((TH, TW), np.float32)
    rough = np.zeros((TH, TW), np.float32)
    # base rubber: sidewalls a deep satin black, the tread a little lighter and duller (worn where it meets the road)
    col[:] = 30
    rough[:] = 0.82
    t = rows(*V_TREAD)
    col[t] = 44
    rough[t] = 0.95
    for s0, s1 in ((0.30, 0.38), (0.62, 0.70)):
        r = rows(s0, s1)
        k = np.linspace(0, 1, r.stop - r.start)[:, None]
        k = k if s0 < 0.5 else 1 - k
        col[r] = 30 + 14 * k
        rough[r] = 0.82 + 0.13 * k
    # the tread pattern
    th = tread_height(kind)
    h[t] = 0.5 + 0.5 * th
    col[t] = col[t] * (0.55 + 0.45 * th)  # dark grooves
    # sidewall lettering
    lh = lettering_height(kind)
    s = rows(*V_SIDE)
    h[s] += 0.35 * lh
    col[s] += 10 * lh
    rough[s] -= 0.12 * lh
    # rim protector ridges near the bead
    b = rows(*V_BEAD)
    yy = np.arange(b.stop - b.start)[:, None]
    h[b] += 0.2 * (np.sin(yy * 1.9) > 0.6)
    # a faint rubber grain everywhere
    grain = rng.normal(0, 1, (TH, TW)).astype(np.float32)
    grain = blur((grain * 0.1 + 0.5).clip(0, 1), 0.6) - 0.5
    col += grain * 18
    h += grain * 0.06
    save("tyre_%s_col" % kind, np.stack([col, col, col * 1.02], -1))
    save("tyre_%s_nrm" % kind, normal_from_height(h, 3.0))
    save("tyre_%s_rgh" % kind, rough * 255)


for k in ("sport", "cup", "touring", "offroad"):
    tyre(k)

# ------------------------------------------------------------------ discs
DS = 512


def polar():
    yy, xx = np.mgrid[0:DS, 0:DS].astype(np.float32)
    x, y = (xx + 0.5) / DS - 0.5, (yy + 0.5) / DS - 0.5
    return np.sqrt(x * x + y * y) * 2, np.arctan2(y, x)  # r: 0..1 at the edge


def disc(kind):
    r, a = polar()
    ring = (r > 0.4) & (r <= 1.0)
    hat = r <= 0.4
    col = np.zeros((DS, DS, 3), np.float32)
    h = np.zeros((DS, DS), np.float32) + 0.5
    rough = np.full((DS, DS), 0.5, np.float32)
    metal = np.full((DS, DS), 0.9, np.float32)
    if kind == "ceramic":
        base = np.array([88, 88, 92], np.float32)
        mott = blur((rng.random((DS, DS)) > 0.5).astype(np.float32), 1.2)
        col[ring] = base + (mott[ring, None] - 0.5) * 30
        rough[ring] = 0.62
        metal[ring] = 0.15
        col[hat] = [150, 152, 158]  # anodised hat
        rough[hat] = 0.35
    else:
        base = np.array([150, 150, 154], np.float32)
        # fine machining rings
        rings = 0.5 + 0.5 * np.sin(r * 900)
        col[ring] = base + (rings[ring, None] - 0.5) * 18
        rough[ring] = 0.38 + rings[ring] * 0.12
        # heat tint near the outer edge: a faint blue-gold band
        k = np.clip((r - 0.9) / 0.09, 0, 1) * ring
        tint = np.stack([k * 12, k * 5, -k * 9], -1)
        col += tint
        col[hat] = [74, 74, 78]
        rough[hat] = 0.55
    # holes / slots on the friction ring (dark, sunk)
    if kind in ("drilled", "ceramic"):
        n = 30
        for row, rr in enumerate((0.55, 0.68, 0.81)):
            off = row * math.tau / n / 3
            for i in range(n):
                ang = off + i / n * math.tau
                cx, cy = 0.5 + rr / 2 * math.cos(ang), 0.5 + rr / 2 * math.sin(ang)
                yy, xx = np.ogrid[0:DS, 0:DS]
                d = np.sqrt(((xx + 0.5) / DS - cx) ** 2 + ((yy + 0.5) / DS - cy) ** 2) * DS
                m = d < 4.2
                col[m] = [16, 16, 18]
                h[m] = 0.0
                rough[m] = 0.9
    if kind == "slotted":
        n = 12
        for i in range(n):
            ang0 = i / n * math.tau
            for t in np.linspace(0, 1, 60):
                rr = 0.5 + 0.42 * t
                ang = ang0 + t * 0.55
                cx, cy = 0.5 + rr / 2 * math.cos(ang), 0.5 + rr / 2 * math.sin(ang)
                x0, y0 = int(cx * DS), int(cy * DS)
                col[y0 - 2 : y0 + 3, x0 - 2 : x0 + 3] = [22, 22, 24]
                h[y0 - 2 : y0 + 3, x0 - 2 : x0 + 3] = 0.1
    # outside the disc: plain dark (the outer edge and the vanes use these pixels too)
    out = r > 1.0
    col[out] = [60, 60, 64]
    h = blur(h, 0.8)
    save("disc_%s_col" % kind, col)
    save("disc_%s_nrm" % kind, normal_from_height(h, 4.0))
    save("disc_%s_rgh" % kind, rough * 255)
    save("disc_%s_mtl" % kind, metal * 255)
    # the glow mask for hot brakes: the friction ring only
    save("disc_%s_glow" % kind, (ring & (h > 0.3)).astype(np.float32) * 255)


for k in ("steel", "drilled", "slotted", "ceramic"):
    disc(k)

# ------------------------------------------------------------------ the lip's machined rings (roughness)
r, a = polar()
lip = 0.16 + 0.1 * (0.5 + 0.5 * np.sin(r * 1400)) + 0.04 * (0.5 + 0.5 * np.sin(r * 160))
save("lip_machined_rgh", lip * 255)

# ------------------------------------------------------------------ one-value maps
for v in (0.0, 0.15, 0.25, 0.35, 0.45, 0.55, 0.7, 0.85, 1.0):
    flat("v%03d" % int(v * 100), v * 255)
save("nrm_flat", np.full((8, 8, 3), (128, 128, 255), np.float32))
print("textures in", OUT)
