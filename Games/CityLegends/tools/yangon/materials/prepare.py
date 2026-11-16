"""prepare.py: turn each spec entry's CC0 maps (or procedural ones) into a Roblox MaterialVariant set in
build/materials/<slug>/roblox/:
  <slug>_color.jpg   (RGB, 1024; masks: <slug>_color.png RGBA, alpha = opacity)
  <slug>_normal.png  (OpenGL convention, +Y up: DirectX normals get their green flipped)
  <slug>_roughness.png, <slug>_metalness.png  (single channel)
  manifest.json      (variant, base, studsPerTile, files, colour targets)
Colour: "tint" scales each channel in linear light so the map's mean equals the colour target (the texture's own
variation is kept, highlights soft-compressed instead of clipped); "neutral" = desaturated, mean NEUTRAL_MEAN.
Outdoor targets go through tools/yangon/city/look_calib.albedo("SmoothPlastic", photo) (what a flat part needs to
render as the photo under Yangon's midday light), interior targets are the photo colour as it is.
Run: python -I prepare.py [slug ...]   (writes build/materials/manifest.json for all slugs)"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "build", "materials"))  # the maps live in build/ (gitignored)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.normpath(os.path.join(ROOT, "..", "..", "tools", "yangon", "city")))
from spec import S, NEUTRAL_MEAN  # noqa: E402
import look_calib  # noqa: E402

N = 1024
RNG = np.random.default_rng(20261116)


# ---------------------------------------------------------------- helpers
def lin(a):
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def srgb(a):
    a = np.clip(a, 0, 1)
    return np.where(a <= 0.0031308, a * 12.92, 1.055 * a ** (1 / 2.4) - 0.055)


def load(path, mode="RGB", size=N):
    im = Image.open(path).convert(mode)
    if im.size != (size, size):
        im = im.resize((size, size), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32) / 255.0
    return a


def find(slug, aid, role):
    d = os.path.join(ROOT, slug, "src", aid)
    keys = {"color": ["color.", "_Color."], "normal_gl": ["normal_gl.", "_NormalGL."], "normal_dx": ["_NormalDX."],
            "roughness": ["roughness.", "_Roughness."], "metalness": ["_Metalness."], "arm": ["arm."],
            "opacity": ["_Opacity."]}[role]
    for f in sorted(os.listdir(d)):
        if any(k in f for k in keys):
            return os.path.join(d, f)
    return None


def source(slug, aid):
    """-> dict color (linear RGB), normal (xyz -1..1, GL), rough, metal (or None), opacity (or None)."""
    m = {}
    m["color"] = lin(load(find(slug, aid, "color")))
    p = find(slug, aid, "normal_gl")
    if p:
        n = load(p)
    else:
        n = load(find(slug, aid, "normal_dx"))
        n[..., 1] = 1.0 - n[..., 1]  # DirectX -> OpenGL: flip green
    m["normal"] = n * 2 - 1
    m["rough"] = load(find(slug, aid, "roughness"), "L")
    p = find(slug, aid, "metalness")
    m["metal"] = load(p, "L") if p else None
    p = find(slug, aid, "arm")
    if p and m["metal"] is None:
        m["metal"] = load(p)[..., 2]  # Poly Haven ARM: B = metal
    p = find(slug, aid, "opacity")
    m["opacity"] = load(p, "L") if p else None
    return m


def fft_blur(a, sigma):
    """periodic gaussian blur (tileable), sigma in px; a is HxW."""
    h, w = a.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    g = np.exp(-2 * (math.pi ** 2) * (sigma ** 2) * (fx ** 2 + fy ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g)).astype(np.float32)


def noise(sigma, n=N, rng=RNG):
    """tileable smooth noise 0..1."""
    a = fft_blur(rng.standard_normal((n, n)).astype(np.float32), sigma)
    a -= a.min()
    return a / max(a.max(), 1e-6)


def normal_from_height(h, strength):
    """h: HxW height (0..1, px units scaled by strength) -> GL normal xyz."""
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.stack([-dx, dy, np.ones_like(h)], -1)  # +Y up: a rise toward the image top faces up
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def blend_normals(base, add):
    n = np.stack([base[..., 0] + add[..., 0], base[..., 1] + add[..., 1], base[..., 2] * add[..., 2]], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def flat_normal(n=N):
    z = np.zeros((n, n, 3), np.float32)
    z[..., 2] = 1
    return z


def target_albedo(e, t=None):
    t = t or e["target"]
    if e.get("light") == "in":
        return tuple(t), False
    a, clipped = look_calib.albedo("SmoothPlastic", t)
    return a, clipped


def tint(col, target_srgb):
    """linear RGB col -> linear RGB with mean = target (sRGB 0..255), variation kept, soft highlight compression."""
    out = np.empty_like(col)
    for c in range(3):
        x = col[..., c]
        m = max(float(x.mean()), 1e-4)
        T = float(lin(np.array(target_srgb[c] / 255.0)))
        r = x / m
        k = 1.0
        hi = float(np.percentile(r, 99.5))
        if T * hi > 0.98 and hi > 1:
            k = max(0.15, (0.98 / T - 1) / (hi - 1))
        out[..., c] = np.clip(T * (1 + (r - 1) * k), 0, 1)
    return out


def neutral(col, mean=NEUTRAL_MEAN):
    y = col[..., 0] * 0.2126 + col[..., 1] * 0.7152 + col[..., 2] * 0.0722
    g = np.repeat(y[..., None], 3, -1)
    return tint(g, (mean, mean, mean))


def tile2(a):
    """2x2 repeat then back to N (for tiles twice the source's size)."""
    big = np.concatenate([np.concatenate([a, a], 1)] * 2, 0)
    if big.ndim == 2:
        return np.asarray(Image.fromarray((np.clip(big, 0, 1) * 65535).astype(np.uint16)).resize((N, N), Image.LANCZOS),
                          np.float32) / 65535.0
    ch = [tile2(big[..., c][: big.shape[0] // 2, : big.shape[1] // 2]) for c in range(big.shape[-1])]
    return np.stack(ch, -1)


def disc(cx, cy, r, n=N):
    yy, xx = np.mgrid[0:n, 0:n]
    dx = (xx - cx + n / 2) % n - n / 2
    dy = (yy - cy + n / 2) % n - n / 2
    return np.sqrt(dx * dx + dy * dy) < r


def rect_mask(x0, y0, w, h, n=N):
    """wrap-around rectangle (px)."""
    m = np.zeros((n, n), bool)
    xs = np.arange(int(x0), int(x0 + w)) % n
    ys = np.arange(int(y0), int(y0 + h)) % n
    m[np.ix_(ys, xs)] = True
    return m


def line_mask(px_per_m, positions_m, width_m, axis, n=N):
    m = np.zeros((n, n), bool)
    w = max(1, int(round(width_m * px_per_m)))
    for p in positions_m:
        c = int(round(p * px_per_m))
        idx = np.arange(c - w // 2, c - w // 2 + w) % n
        if axis == "x":
            m[:, idx] = True
        else:
            m[idx, :] = True
    return m


# ---------------------------------------------------------------- procedural steps
def streaks(n, density, len_m, tile_m, dark, rng):
    """tileable vertical rain streaks: returns darkness 0..1 (multiply colour by 1 - dark*mask)."""
    ppm = n / tile_m
    m = np.zeros((n, n), np.float32)
    yy = np.arange(n)
    count = int(density * n / 6)
    for _ in range(count):
        x = rng.uniform(0, n)
        w = rng.uniform(0.02, 0.12) * ppm
        y0 = rng.uniform(0, n)
        L = rng.uniform(*len_m) * ppm
        a = rng.uniform(0.3, 1.0)
        d = (yy - y0) % n
        prof = np.clip(1 - d / L, 0, 1) ** 1.6 * np.clip(d / (0.06 * L + 1), 0, 1) * a  # soft start, long fade  # strong at the top (ledge), fading down
        xs = np.arange(int(x - 2 * w), int(x + 2 * w) + 1)
        g = np.exp(-((xs - x) / max(w / 2, 1)) ** 2)
        m[:, xs % n] = np.maximum(m[:, xs % n], prof[:, None] * g[None, :])
    wob = noise(6, n, rng)
    m = m * (0.6 + 0.8 * wob)
    m = fft_blur(m, 1.2)
    return np.clip(m, 0, 1) * dark


def p_rain(e, m, heavy):
    col = neutral(m["color"])
    s = streaks(N, 1.7 if heavy else 0.7, (0.4, 2.5) if heavy else (0.3, 1.2), e["tile_m"],
                0.62 if heavy else 0.22, RNG)
    if heavy:
        s = np.maximum(s, 0.25 * (noise(40) > 0.62) * noise(10))  # mildew blotches
    col = col * (1 - s[..., None])
    rough = np.clip(m["rough"] + 0.05 * s, 0, 1)
    return col, m["normal"], rough, None, None


def p_patches(e, srcs):
    base, patch = srcs
    tA, _ = target_albedo(e, (114, 112, 108))
    tP, _ = target_albedo(e, (88, 87, 84))
    col = tint(tile2(base["color"]), tA)
    nrm = tile2(base["normal"])
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    rough = tile2(base["rough"])
    pc = tint(patch["color"], tP)
    ppm = N / e["tile_m"]
    height = np.zeros((N, N), np.float32)
    for (x, y, w, h) in [(0.6, 0.8, 1.8, 4.6), (4.8, 3.9, 2.4, 2.2), (2.9, 6.1, 1.4, 3.0)]:
        mk = rect_mask(x * ppm, y * ppm, w * ppm, h * ppm)
        col[mk] = pc[mk]
        nrm[mk] = patch["normal"][mk]
        rough[mk] = patch["rough"][mk]
        height += mk.astype(np.float32)
    edge = fft_blur(height, 1.5)
    seam = (edge > 0.08) & (edge < 0.92)
    col[seam] *= 0.55  # bitumen joint round each patch
    nrm = blend_normals(nrm, normal_from_height(fft_blur(height, 2.0), 3.0))
    return col, nrm, rough, None, None


def p_oil(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    band = np.exp(-(((np.arange(N) - N / 2) / (0.45 * ppm)) ** 2))[None, :].repeat(N, 0)
    # drips along the lane centre: irregular (noise-shaped) blots in a 0.9 m band, plus a soft darker band
    blots = np.clip((noise(9) - 0.58) * 5, 0, 1) * np.clip((noise(35) - 0.35) * 3, 0, 1)
    oil = np.clip(blots * band * 1.4 + 0.3 * band * noise(30), 0, 1)
    oil = fft_blur(oil, 1.5)
    col = col * (1 - 0.45 * oil[..., None])
    rough = np.clip(m["rough"] * (1 - 0.35 * oil), 0.05, 1)
    return col, m["normal"], rough, None, None


def p_joints(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    j = line_mask(ppm, [0.0], 0.012, "x") | line_mask(ppm, [0.0], 0.012, "y")
    dirt = fft_blur(j.astype(np.float32), 10) * 3
    col = col * (1 - np.clip(0.25 * dirt, 0, 0.3))[..., None]
    col[j] *= 0.35
    crack = crack_mask(ppm, 3)
    col[crack] *= 0.6
    h = -(j.astype(np.float32) * 1.0 + crack * 0.5)
    nrm = blend_normals(m["normal"], normal_from_height(fft_blur(h, 1.0), 4.0))
    return col, nrm, m["rough"], None, None


def crack_mask(ppm, n_cracks, rng=RNG):
    img = Image.new("L", (N, N), 0)
    from PIL import ImageDraw
    d = ImageDraw.Draw(img)
    for _ in range(n_cracks):
        x, y = rng.uniform(0, N), rng.uniform(0, N)
        ang = rng.uniform(0, 2 * math.pi)
        pts = [(x, y)]
        for _ in range(int(rng.uniform(8, 20))):
            ang += rng.normal(0, 0.5)
            x += math.cos(ang) * 0.05 * ppm
            y += math.sin(ang) * 0.05 * ppm
            pts.append((x, y))
        d.line(pts, fill=255, width=2)
    return np.asarray(img) > 0


def p_broken(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    slab = rect_mask(N * 2 / 3 + 6, N / 3 + 6, N / 3 - 12, N / 3 - 12)
    dirt = noise(20)
    col[slab] *= (0.62 + 0.2 * dirt[slab])[:, None]
    cr = crack_mask(ppm, 5)
    col[cr] *= 0.45
    h = -(slab.astype(np.float32) * 0.6) - cr * 0.6
    nrm = blend_normals(m["normal"], normal_from_height(fft_blur(h, 1.5), 4.0))
    rough = m["rough"].copy()
    rough[slab] = np.clip(rough[slab] + 0.08, 0, 1)
    return col, nrm, rough, None, None


def p_kerb(e, m):
    col = neutral(m["color"])
    d = np.clip((noise(25) - 0.55) * 3, 0, 1) * 0.25 + np.clip((noise(4) - 0.7) * 4, 0, 1) * 0.15
    col *= (1 - d)[..., None]
    return col, m["normal"], np.clip(m["rough"] + 0.05, 0, 1), None, None


def p_drain(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    gaps = line_mask(ppm, [0.0, 0.5], 0.015, "x") | line_mask(ppm, [0.0], 0.015, "y")
    holes = np.zeros((N, N), bool)
    for x in (0.25, 0.75):
        for y in (0.12, 0.88):
            holes |= disc(x * ppm, y * ppm, 0.018 * ppm)
    lid2 = rect_mask(0.5 * ppm, 0, 0.5 * ppm, N)
    col[lid2] *= 0.93
    col = col * (1 - 0.2 * fft_blur(gaps.astype(np.float32), 8)[..., None] * 2)
    col[gaps] *= 0.2
    col[holes] *= 0.25
    h = -(gaps * 1.0 + holes * 0.8).astype(np.float32)
    nrm = blend_normals(m["normal"], normal_from_height(fft_blur(h, 1.2), 5.0))
    return col, nrm, m["rough"], None, None


def p_grille(e):
    ppm = N / e["tile_m"]
    bars = line_mask(ppm, [0.05, 0.15, 0.25], 0.012, "x")
    rail = line_mask(ppm, [0.15], 0.02, "y")
    a = (bars | rail).astype(np.float32)
    h = fft_blur(a, 3.0)
    col = np.full((N, N, 3), lin(np.array(NEUTRAL_MEAN / 255.0)), np.float32) * (0.85 + 0.15 * noise(8))[..., None]
    nrm = normal_from_height(h, 25.0)
    rough = np.full((N, N), 0.55, np.float32)
    metal = np.full((N, N), 0.2, np.float32)
    return col, nrm, rough, metal, a


def p_mask_opacity(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    return col, m["normal"], m["rough"], m["metal"], m["opacity"]


def p_razor(e):
    from PIL import ImageDraw
    big = 2 * N
    img = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(img)
    ppm = big / e["tile_m"]
    r = 0.3 * ppm
    cy = big / 2
    blades = []
    for k in range(int(e["tile_m"] / 0.12) + 2):
        cx = k * 0.12 * ppm
        for dxs in (-big, 0, big):
            d.ellipse([cx + dxs - 0.35 * r, cy - r, cx + dxs + 0.35 * r, cy + r], outline=255, width=7)
        for j in range(10):
            ang = j / 10 * 2 * math.pi + k
            bx, by = cx + 0.35 * r * math.cos(ang), cy + r * math.sin(ang)
            blades.append((bx, by))
    for bx, by in blades:
        L = 0.012 * ppm
        for dxs in (-big, 0, big):
            d.polygon([(bx + dxs - 2 * L, by), (bx + dxs, by - L * 0.6), (bx + dxs + 2 * L, by), (bx + dxs, by + L * 0.6)],
                      fill=255)
    a = np.asarray(img.resize((N, N), Image.LANCZOS), np.float32) / 255.0
    col = np.full((N, N, 3), 0.0, np.float32)
    t, _ = target_albedo({"light": "out"}, (170, 172, 170))
    col[:] = lin(np.array(t) / 255.0)
    col *= (0.85 + 0.3 * noise(5))[..., None]
    nrm = normal_from_height(fft_blur(a, 2.0), 12.0)
    return col, nrm, np.full((N, N), 0.35, np.float32), np.full((N, N), 0.9, np.float32), a


def p_blue_white(e):
    big = 2 * N
    ppm = big / e["tile_m"]
    tp = 0.2 * ppm  # tile size px
    yy, xx = np.mgrid[0:big, 0:big].astype(np.float32)
    u = (xx % tp) / tp
    v = (yy % tp) / tp
    blue = np.zeros((big, big), bool)
    # quarter circles at the four corners (they form full rings across 4 tiles)
    for cxu, cyv in ((0, 0), (1, 0), (0, 1), (1, 1)):
        rr = np.sqrt((u - cxu) ** 2 + (v - cyv) ** 2)
        blue |= (rr > 0.30) & (rr < 0.40)
        blue |= rr < 0.12
    # centre: four-petal star
    du, dv = np.abs(u - 0.5), np.abs(v - 0.5)
    blue |= (du + dv < 0.22) & ~((du + dv) < 0.14)
    blue |= (du < 0.035) & (dv < 0.035)
    border = (u < 0.03) | (u > 0.97) | (v < 0.03) | (v > 0.97)
    blue |= border & ~((u < 0.012) | (u > 0.988) | (v < 0.012) | (v > 0.988))
    grout = (u < 0.012) | (u > 0.988) | (v < 0.012) | (v > 0.988)
    B = lin(np.array([60, 90, 150]) / 255.0)
    W = lin(np.array([238, 236, 230]) / 255.0)
    G = lin(np.array([150, 146, 138]) / 255.0)
    col = np.where(blue[..., None], B, W).astype(np.float32)
    col[grout] = G
    col = np.asarray(Image.fromarray((srgb(col) * 255).astype(np.uint8)).resize((N, N), Image.LANCZOS), np.float32) / 255
    col = lin(col) * (0.94 + 0.08 * noise(30))[..., None]
    g = np.asarray(Image.fromarray(grout.astype(np.uint8) * 255).resize((N, N), Image.LANCZOS), np.float32) / 255
    nrm = normal_from_height(fft_blur(-g, 1.5), 6.0)
    rough = np.where(g > 0.5, 0.8, 0.32).astype(np.float32) + 0.05 * noise(12)
    return col, nrm, rough, None, None


def p_chequer(e, m):
    y = m["color"].mean(-1)
    ppm = N / e["tile_m"]
    per = 0.2 * ppm  # 0.2 m checks
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    best = None
    for ox in range(0, int(per), 2):
        for oy in range(0, int(per), 4):
            par = (((xx + ox) // per + (yy + oy) // per) % 2) * 2 - 1
            sc = float((par[::4, ::4] * y[::4, ::4]).mean())
            if best is None or abs(sc) > abs(best[0]):
                best = (sc, ox, oy)
    sc, ox, oy = best
    par = (((xx + ox) // per + (yy + oy) // per) % 2) * 2 - 1
    dark = (par * np.sign(sc)) < 0
    local = np.where(dark, y[dark].mean(), y[~dark].mean())
    var = y / np.maximum(local, 1e-4)
    W = float(lin(np.array(232 / 255)))
    K = float(lin(np.array(38 / 255)))
    v = np.where(dark, K, W) * np.clip(1 + (var - 1) * 0.5, 0.7, 1.2)
    col = np.repeat(v[..., None], 3, -1).astype(np.float32)
    col[..., 2] *= 0.985
    return col, m["normal"], np.clip(m["rough"] * 0.7, 0.15, 1), None, None


def p_bamboo(e):
    ppm = N / e["tile_m"]
    yy = np.arange(N)
    node = np.exp(-(((yy - N / 2) / (0.008 * ppm)) ** 2))
    ring = np.exp(-(((yy - N / 2 - 0.012 * ppm) / (0.004 * ppm)) ** 2))
    fib = np.random.default_rng(7).standard_normal(N).astype(np.float32)
    fib = np.convolve(np.concatenate([fib, fib[:9]]), np.ones(9) / 9, "valid")[:N]
    h = node[:, None] * 1.0 + 0.08 * fib[None, :] + 0.03 * noise(2)
    t, _ = target_albedo({"light": "out"}, (190, 165, 110))
    col = np.zeros((N, N, 3), np.float32) + lin(np.array(t) / 255.0)
    tone = 0.85 + 0.25 * noise(60) + 0.06 * fib[None, :]
    col *= tone[..., None]
    col *= (1 - 0.5 * ring)[:, None, None]
    green = noise(80)
    col[..., 0] *= 1 - 0.12 * green
    col[..., 2] *= 1 - 0.1 * green
    return col, normal_from_height(h, 8.0), np.full((N, N), 0.45, np.float32) + 0.1 * noise(20), None, None


def p_net(e):
    ppm = N / e["tile_m"]
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    p = 0.0125 * ppm  # 12.5 mm knit
    a = np.abs(((xx + yy) % (2 * p)) - p) < p * 0.28
    b = np.abs(((xx - yy) % (2 * p)) - p) < p * 0.28
    yarn = (a | b).astype(np.float32)
    t, _ = target_albedo({"light": "out"}, (48, 100, 60))
    col = np.zeros((N, N, 3), np.float32) + lin(np.array(t) / 255.0)
    col *= (0.35 + 0.65 * yarn)[..., None] * (0.9 + 0.2 * noise(40))[..., None]
    nrm = normal_from_height(fft_blur(yarn, 1.0), 4.0)
    return col, nrm, np.full((N, N), 0.7, np.float32), None, None


def p_tarp(e):
    ppm = N / e["tile_m"]
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    weave = (np.sin(xx / 2.2) * np.sin(yy / 2.2)) * 0.5 + 0.5
    folds = noise(45) * 0.7 + noise(12) * 0.3
    crease = np.exp(-((noise(60) - 0.5) / 0.015) ** 2) * 0.6
    h = folds * 1.0 + crease * 0.4 + weave * 0.02
    t, _ = target_albedo({"light": "out"}, (50, 110, 180))
    col = np.zeros((N, N, 3), np.float32) + lin(np.array(t) / 255.0)
    col *= (0.9 + 0.18 * folds - 0.25 * crease)[..., None] * (0.97 + 0.06 * weave)[..., None]
    return col, normal_from_height(h, 18.0), np.full((N, N), 0.55, np.float32) - 0.1 * crease, None, None


def p_vinyl(e):
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    sag = noise(90) * 0.8 + noise(25) * 0.2
    scrim = (np.sin(xx / 3.0) * np.sin(yy / 3.0)) * 0.5 + 0.5
    h = sag + 0.01 * scrim
    g = lin(np.array(NEUTRAL_MEAN / 255.0))
    col = np.zeros((N, N, 3), np.float32) + g
    col *= (0.96 + 0.06 * sag)[..., None]
    return col, normal_from_height(h, 14.0), np.full((N, N), 0.4, np.float32) + 0.05 * noise(10), None, None


def p_gold_leaf(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    sq = 0.1 * ppm
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    ix = ((xx + (yy // sq % 2) * sq * 0.37) // sq).astype(int)
    iy = (yy // sq).astype(int)
    tone = (np.sin(ix * 12.9898 + iy * 78.233) * 43758.5453) % 1.0
    col *= (0.95 + 0.1 * tone)[..., None]
    edge = (((xx + (yy // sq % 2) * sq * 0.37) % sq) < 2) | ((yy % sq) < 2)
    col[edge] *= 1.06
    lacq = (noise(8) > 0.93) & (noise(50) > 0.6)
    col[lacq] = lin(np.array([110, 28, 20]) / 255.0)
    metal = np.where(lacq, 0.0, 1.0).astype(np.float32)
    rough = np.clip(m["rough"] * 0.8 + 0.05 * tone, 0.12, 0.6)
    rough[lacq] = 0.5
    h = edge.astype(np.float32) * 0.3
    nrm = blend_normals(m["normal"], normal_from_height(fft_blur(h, 0.8), 2.0))
    return col, nrm, rough, metal, None


def p_gold_plate(e, m):
    t, _ = target_albedo(e)
    col = tint(m["color"], t)
    ppm = N / e["tile_m"]
    sq = 0.3 * ppm
    yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
    ix, iy = (xx // sq).astype(int), (yy // sq).astype(int)
    tone = (np.sin(ix * 12.9898 + iy * 78.233) * 43758.5453) % 1.0
    col *= (0.93 + 0.12 * tone)[..., None]
    fx, fy = (xx % sq) / sq, (yy % sq) / sq
    bevel = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy))
    seam = bevel < 0.012
    col[seam] *= 0.35
    h = np.clip(bevel / 0.04, 0, 1)
    nrm = blend_normals(m["normal"], normal_from_height(fft_blur(h, 1.0), 6.0))
    rough = np.clip(0.18 + 0.15 * tone + 0.1 * m["rough"], 0.1, 0.5)
    metal = np.where(seam, 0.6, 1.0).astype(np.float32)
    return col, nrm, rough.astype(np.float32), metal, None


def p_mosaic(e):
    ppm = N / e["tile_m"]
    rng = np.random.default_rng(11)
    col = np.zeros((N, N, 3), np.float32) + lin(np.array([200, 190, 170]) / 255.0) * 0.5
    nrm = flat_normal()
    rough = np.full((N, N), 0.8, np.float32)
    metal = np.zeros((N, N), np.float32)
    kinds = [((205, 210, 215), 1.0, 0.04, 0.68), ((60, 120, 80), 0.0, 0.08, 0.07), ((140, 45, 45), 0.0, 0.08, 0.05),
             ((215, 175, 90), 1.0, 0.12, 0.14), ((90, 140, 170), 0.0, 0.08, 0.06)]
    probs = np.array([k[3] for k in kinds])
    y = 0
    while y < N:
        hgt = int(rng.uniform(0.01, 0.02) * ppm)
        x = -rng.uniform(0, 0.01 * ppm)
        while x < N:
            w = int(rng.uniform(0.01, 0.02) * ppm)
            k = kinds[rng.choice(len(kinds), p=probs / probs.sum())]
            gap = max(2, int(0.0015 * ppm))
            x0, y0 = max(int(x) + gap, 0), y + gap
            x1, y1 = min(int(x) + w, N), min(y + hgt, N)
            if x1 > x0 and y1 > y0:
                c = lin(np.array(k[0]) / 255.0) * rng.uniform(0.85, 1.1)
                col[y0:y1, x0:x1] = c
                metal[y0:y1, x0:x1] = k[1]
                rough[y0:y1, x0:x1] = k[2]
                tilt = rng.normal(0, 0.08, 2)
                n = np.array([tilt[0], tilt[1], 1.0])
                nrm[y0:y1, x0:x1] = n / np.linalg.norm(n)
            x += w
        y += hgt
    return np.clip(col, 0, 1), nrm, rough, metal, None


PROCS_ONE = {"rain_streaks_heavy": lambda e, m: p_rain(e, m, True),
             "rain_streaks_light": lambda e, m: p_rain(e, m, False),
             "oil_stains": p_oil, "slab_joints_3m5": p_joints, "broken_slabs": p_broken, "kerb_dirt": p_kerb,
             "drain_slabs": p_drain, "mask_from_opacity": p_mask_opacity, "chequer_bw": p_chequer,
             "gold_leaf_squares": p_gold_leaf, "gold_plate_grid": p_gold_plate}
PROCS_NONE = {"grille_mask": p_grille, "razor_mask": p_razor, "blue_white_pattern": p_blue_white,
              "bamboo_culm": p_bamboo, "shade_net": p_net, "tarp": p_tarp, "vinyl": p_vinyl, "glass_mosaic": p_mosaic}


# ---------------------------------------------------------------- per entry
def build(e):
    slug = e["slug"]
    srcs = [source(slug, aid) for _, aid in e["src"]]
    proc = e.get("proc")
    alb = None
    if proc == "asphalt_patches":
        col, nrm, rough, metal, alpha = p_patches(e, srcs)
    elif proc in PROCS_NONE:
        col, nrm, rough, metal, alpha = PROCS_NONE[proc](e)
    elif proc in PROCS_ONE:
        col, nrm, rough, metal, alpha = PROCS_ONE[proc](e, srcs[0])
    else:
        m = srcs[0]
        if e["colour"] == "neutral":
            col = neutral(m["color"])
        else:
            alb, _ = target_albedo(e)
            col = tint(m["color"], alb)
        nrm, rough, metal, alpha = m["normal"], m["rough"], m["metal"], None
    if e["colour"] == "tint" and alb is None:
        alb, _ = target_albedo(e)
    if e.get("metal") is None:
        metal = metal if proc in PROCS_NONE or proc in ("gold_leaf_squares", "gold_plate_grid") else None
    elif isinstance(e.get("metal"), float) and metal is None:
        metal = np.full((N, N), e["metal"], np.float32)
    if metal is None:
        metal = np.zeros((N, N), np.float32)
    out = os.path.join(ROOT, slug, "roblox")
    os.makedirs(out, exist_ok=True)
    c8 = (srgb(col) * 255 + 0.5).astype(np.uint8)
    files = {}
    if alpha is not None:
        rgba = np.concatenate([c8, (np.clip(alpha, 0, 1) * 255 + 0.5).astype(np.uint8)[..., None]], -1)
        Image.fromarray(rgba, "RGBA").save(os.path.join(out, slug + "_color.png"), optimize=True)
        files["color"] = slug + "_color.png"
    else:
        Image.fromarray(c8, "RGB").save(os.path.join(out, slug + "_color.jpg"), quality=92, subsampling=0)
        files["color"] = slug + "_color.jpg"
    nrm = nrm / np.linalg.norm(nrm, axis=-1, keepdims=True)
    n8 = ((nrm * 0.5 + 0.5) * 255 + 0.5).clip(0, 255).astype(np.uint8)
    Image.fromarray(n8, "RGB").save(os.path.join(out, slug + "_normal.png"), optimize=True)
    files["normal"] = slug + "_normal.png"
    Image.fromarray((np.clip(rough, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(
        os.path.join(out, slug + "_roughness.png"), optimize=True)
    files["roughness"] = slug + "_roughness.png"
    Image.fromarray((np.clip(metal, 0, 1) * 255 + 0.5).astype(np.uint8), "L").save(
        os.path.join(out, slug + "_metalness.png"), optimize=True)
    files["metalness"] = slug + "_metalness.png"
    mean_lin = col.reshape(-1, 3).mean(0)
    mean_srgb = [int(round(float(v) * 255)) for v in srgb(mean_lin)]
    man = dict(variant=e["variant"], base=e["base"], studsPerTile=round(3 * e["tile_m"], 2), tile_m=e["tile_m"],
               files=files, colour=e["colour"], target_photo=e.get("target"), light=e.get("light"),
               colormap_target=list(alb) if alb else None, colormap_mean_srgb=mean_srgb,
               metal_mean=round(float(metal.mean()), 3), rough_mean=round(float(np.clip(rough, 0, 1).mean()), 3),
               mask=alpha is not None, procedural=proc, sources=[a for _, a in e["src"]], groups=e["groups"],
               note=e["note"], ids={"color": None, "normal": None, "roughness": None, "metalness": None})
    json.dump(man, open(os.path.join(out, "manifest.json"), "w"), indent=1)
    return man


def main(only):
    allm = {}
    mp = os.path.join(ROOT, "manifest.json")
    if os.path.exists(mp):
        allm = json.load(open(mp))
    for e in S:
        if only and e["slug"] not in only:
            continue
        man = build(e)
        allm[e["slug"]] = man
        print("%-22s %-20s spt %5.2f mean %s target %s" % (e["slug"], e["variant"], man["studsPerTile"],
                                                           man["colormap_mean_srgb"], man["colormap_target"]))
    json.dump({e["slug"]: allm[e["slug"]] for e in S if e["slug"] in allm}, open(mp, "w"), indent=1)


if __name__ == "__main__":
    main(set(sys.argv[1:]))
