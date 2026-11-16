"""Pagoda generator, satellite check (2026-11-16): Esri World Imagery z19 (~0.29 m a pixel) round each pagoda.

The photo wins over the OSM guess: a gilded stupa shows from above as a bright gold disc. For each pagoda the tiles round
its spot are fetched (cached in build/pagodas/esri_tiles/), gold pixels found (hue 32-58 deg, saturation >= 0.28,
value >= 0.35), and the gold blob nearest the spot (largest connected set within the search radius) gives:
  gold_c   its middle (lon, lat): the stupa's real middle (the top leans ~0.29 m east per metre of height in this imagery,
           so the blob sits a little east of the base; not corrected for stupas under 30 m)
  gold_d   the diameter of a disc of the same area (m)
A blob counts only when it is compact (fills 55 %+ of its box, sides within 1.6) and bright (median value 0.55+).
Used by pagodas_plan.py: a gold blob -> scheme gold, middle moved onto it, W at least the blob's diameter when the old W
was a guess; no gold where the pagoda should be -> scheme whitetop (white-washed, gold top), unless OSM says gold.

    python pagoda_esri.py lon lat radius_m          (prints the blob; writes build/pagodas/esri_<lon>_<lat>.png)
"""
import math, os, subprocess, sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CACHE = os.path.join(ROOT, 'build', 'pagodas', 'esri_tiles')
Z = 19
URL = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/%d/%d/%d'


def _xy(lon, lat):
    n = 2 ** Z
    x = (lon + 180) / 360 * n
    y = (1 - math.log(math.tan(math.radians(lat)) + 1 / math.cos(math.radians(lat))) / math.pi) / 2 * n
    return x * 256, y * 256


def _ll(px, py):
    n = 2 ** Z * 256
    lon = px / n * 360 - 180
    lat = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * py / n))))
    return lon, lat


def _tile(tx, ty):
    os.makedirs(CACHE, exist_ok=True)
    fn = os.path.join(CACHE, '%d_%d.jpg' % (tx, ty))
    if not os.path.exists(fn) or os.path.getsize(fn) < 500:
        # curl (Python's own TLS store has an expired certificate on this PC)
        subprocess.run(['curl', '-s', '-A', 'Mozilla/5.0', '-o', fn, URL % (Z, ty, tx)], check=False)
    try:
        return Image.open(fn).convert('RGB')
    except Exception:
        return Image.new('RGB', (256, 256))


def crop(lon, lat, half_m):
    """RGB array round (lon, lat), its top-left pixel (world px) and metres per pixel"""
    cx, cy = _xy(lon, lat)
    mpp = 156543.03392 * math.cos(math.radians(lat)) / 2 ** Z
    hp = half_m / mpp
    x0, y0 = int(cx - hp), int(cy - hp)
    x1, y1 = int(cx + hp), int(cy + hp)
    tx0, ty0, tx1, ty1 = x0 // 256, y0 // 256, x1 // 256, y1 // 256
    W = Image.new('RGB', ((tx1 - tx0 + 1) * 256, (ty1 - ty0 + 1) * 256))
    for tx in range(tx0, tx1 + 1):
        for ty in range(ty0, ty1 + 1):
            W.paste(_tile(tx, ty), ((tx - tx0) * 256, (ty - ty0) * 256))
    ox, oy = x0 - tx0 * 256, y0 - ty0 * 256
    im = W.crop((ox, oy, ox + (x1 - x0), oy + (y1 - y0)))
    return np.asarray(im).astype(float) / 255.0, (x0, y0), mpp


def gold_mask(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    h = np.zeros_like(mx)
    d = np.maximum(mx - mn, 1e-6)
    rm = (mx == r)
    h = np.where(rm, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return (h >= 32) & (h <= 58) & (s >= 0.28) & (mx >= 0.35)


def find_gold(lon, lat, radius_m, min_d=2.5, save=None):
    a, (x0, y0), mpp = crop(lon, lat, radius_m + 15)
    m = gold_mask(a)
    m = ndimage.binary_opening(m, iterations=1)
    m = ndimage.binary_closing(m, iterations=3)
    lab, n = ndimage.label(m)
    best = None
    cy, cx = np.array(m.shape) / 2
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        area = len(xs) * mpp * mpp
        d = 2 * math.sqrt(area / math.pi)
        if d < min_d:
            continue
        # a stupa from above is a compact, bright disc or square; trees, dry grass and dirt are ragged or dull
        bw, bh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
        fill = len(xs) / float(bw * bh)
        if fill < 0.55 or max(bw, bh) > 1.6 * min(bw, bh):
            continue
        if np.median(a[ys, xs].max(-1)) < 0.55:
            continue
        mxp, myp = xs.mean(), ys.mean()
        dist = math.hypot(mxp - cx, myp - cy) * mpp
        if dist > radius_m:
            continue
        score = area / (1 + dist / 15.0)
        if best is None or score > best[0]:
            best = (score, mxp, myp, d, dist)
    if save:
        im = Image.fromarray((a * 255).astype(np.uint8))
        ov = np.asarray(im).copy()
        ov[m] = (ov[m] * 0.4 + np.array([255, 0, 255]) * 0.6).astype(np.uint8)
        Image.fromarray(ov).save(save)
    if not best:
        return None
    _, mxp, myp, d, dist = best
    glon, glat = _ll(x0 + mxp, y0 + myp)
    return dict(gold_c=(round(glon, 7), round(glat, 7)), gold_d=round(d, 2), off_m=round(dist, 1))


if __name__ == '__main__':
    lo, la, r = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
    print(find_gold(lo, la, r, save=os.path.join(ROOT, 'build', 'pagodas', 'esri_%s_%s.png' % (sys.argv[1], sys.argv[2]))))


def sheet(pagodas, out, cell=300, cols=6):
    """a contact sheet: each pagoda's Esri crop with the planned base drawn in red (square / octagon / circle, turned by yaw),
    labelled with its index. For checking the OSM-based plan by eye (the automatic gold finder above misses pale or shaded
    gold and catches dry trees, 16 Nov: it is not used to place anything)."""
    from PIL import ImageDraw
    rows = (len(pagodas) + cols - 1) // cols
    W = Image.new('RGB', (cols * cell, rows * cell), (40, 40, 40))
    for i, p in enumerate(pagodas):
        half = max(p['w'] * 1.6, 25.0)
        a, (x0, y0), mpp = crop(p['lon'], p['lat'], half)
        im = Image.fromarray((a * 255).astype(np.uint8))
        d = ImageDraw.Draw(im)
        cx, cy = im.size[0] / 2, im.size[1] / 2
        n = {'sq': 4, 'oct': 8}.get(p['shape'], 32)
        rr = p['w'] / 2 / mpp / math.cos(math.pi / n) if n < 32 else p['w'] / 2 / mpp
        ph = math.radians(p.get('yaw', 0)) + (math.pi / n if n < 32 else 0)
        pts = [(cx + rr * math.cos(ph + 2 * math.pi * k / n), cy - rr * math.sin(ph + 2 * math.pi * k / n)) for k in range(n)]
        d.polygon(pts, outline=(255, 0, 0))
        im = im.resize((cell, cell))
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 70, 14), fill=(0, 0, 0))
        d.text((2, 1), '%d %s' % (i, p['id']), fill=(255, 255, 0))
        W.paste(im, ((i % cols) * cell, (i // cols) * cell))
    W.save(out)
