"""Road surface maps (27 Nov 2026, owner: "the road textures dont look realistic ... not every small road is asphalt,
the big roads & overhead roads are always asphalt"; vault `City Legends/2026-11-27 Roads - realistic surfaces by road type.md`).

Tileable 1024 px maps, all procedural (numpy + PIL), seeded = rebuildable:
  asphalt_*   big roads + flyover decks (MaterialVariant YgnRoadAsphalt, base Asphalt, StudsPerTile 24 = about 7.5 m):
              aggregate stones in dark binder (some pale quartz chips), tone blotches at two sizes (about 8 and 2 studs)
              so the 24-stud repeat doesn't read, no cracks (cracks / patches / tar seams are mesh regions, sparse);
              normal = stones raised; roughness = binder 0.9, stone tops 0.45-0.65 (sun sparkle).
  concrete_*  small streets (YgnRoadConcrete, base Concrete, StudsPerTile 32): pale worn cast concrete as in the
              owner's Yangon lane clips (0934, Hledan lane): stains, worn patches showing aggregate, a few hairlines.
Colour maps are neutral (mean about 150): each road kind's Part.Color sets the final shade (YangonRoadSurface.LOOK).

    python road_textures.py <outdir>     (-> imports/road_surface/*.png)
"""
import os, sys
import numpy as np
from PIL import Image

N = 1024
out = sys.argv[1] if len(sys.argv) > 1 else '.'
os.makedirs(out, exist_ok=True)


def tile_noise(rng, cells):
    g = rng.random((cells, cells))
    x = np.arange(N) * cells / N
    i0 = np.floor(x).astype(int) % cells
    i1 = (i0 + 1) % cells
    t = x - np.floor(x)
    t = t * t * (3 - 2 * t)
    a = g[i0][:, i0] * (1 - t)[None, :] + g[i0][:, i1] * t[None, :]
    b = g[i1][:, i0] * (1 - t)[None, :] + g[i1][:, i1] * t[None, :]
    return a * (1 - t)[:, None] + b * t[:, None]


def fbm(rng, octaves):
    f = sum(tile_noise(rng, c) * w for c, w in octaves)
    return (f - f.min()) / (f.max() - f.min())


def blur(a, sigma):
    """wrap-around gaussian blur (FFT: tileable)"""
    k = np.fft.fftfreq(N)
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (k[:, None] ** 2 + k[None, :] ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def stones(rng, count, sigma):
    """aggregate: random impulses blurred into round bumps; returns (height 0..1, per-stone tone 0..1)"""
    imp = np.zeros((N, N))
    tone = np.zeros((N, N))
    ys, xs = rng.integers(0, N, count), rng.integers(0, N, count)
    imp[ys, xs] = rng.uniform(0.6, 1.0, count)
    tone[ys, xs] = rng.random(count)
    h = blur(imp, sigma)
    t = blur(tone, sigma)
    w = np.maximum(h, 1e-6)
    return h / h.max(), np.clip(t / w, 0, 1)


def normal_map(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.dstack([-dx, dy, np.ones_like(h)])   # OpenGL (+Y up), as Roblox reads it
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def save(name, a, mode):
    if mode == 'L':
        Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), 'L').save(os.path.join(out, name))
    elif a.dtype == np.uint8:
        Image.fromarray(a, mode).save(os.path.join(out, name))
    else:
        Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), mode).save(os.path.join(out, name))


def grain(rng, sigma):
    g = blur(rng.standard_normal((N, N)), sigma)
    return (g - g.mean()) / g.std()


def asphalt():
    rng = np.random.default_rng(1127)
    g = 0.55 * grain(rng, 0.7) + 0.45 * grain(rng, 1.5)   # aggregate grain (stones about 1-2 cm = 1-3 px)
    chips = np.clip(blur((rng.random((N, N)) > 0.9965).astype(float), 0.6) * 9, 0, 1)   # pale quartz chips
    tone_l = fbm(rng, ((4, 0.6), (8, 0.4)))     # about 6-8 stud blotches (stops the 24-stud tile reading)
    tone_s = fbm(rng, ((16, 0.5), (32, 0.5)))   # about 1-2 stud blotches
    v = 0.55 + 0.068 * np.clip(g, -2.5, 2.5) + 0.07 * (tone_l - 0.5) + 0.035 * (tone_s - 0.5)
    v = v * (1 - chips) + 0.80 * chips
    v = v / v.mean() * 0.59                                # mean about 150
    rgb = np.dstack([v * 0.99, v * 1.0, v * 1.015])        # very slightly cool, as dry tarmac
    peak = np.clip((g - 1.0) / 1.2, 0, 1)                  # stone tops: smoother, catch the sun
    rough = 0.93 - 0.40 * peak - 0.25 * chips - 0.03 * (tone_l - 0.5)
    save('asphalt_color.png', rgb, 'RGB')
    save('asphalt_normal.png', normal_map(0.12 * g + 0.25 * chips, 9.0), 'RGB')
    save('asphalt_roughness.png', rough, 'L')
    return v


def concrete():
    rng = np.random.default_rng(2711)
    fine, _ = stones(rng, 120000, 0.7)          # sand / broom grain
    agg, aggt = stones(rng, 9000, 1.6)          # aggregate, shows where the top wore off
    tone_l = fbm(rng, ((3, 0.6), (6, 0.4)))     # about 6-10 stud stains / tone
    tone_s = fbm(rng, ((12, 0.5), (24, 0.5)))
    worn = fbm(rng, ((8, 0.5), (16, 0.3), (32, 0.2))) > 0.66   # worn patches: aggregate exposed, darker
    stain = np.clip((fbm(rng, ((5, 0.5), (10, 0.3), (20, 0.2))) - 0.66) / 0.25, 0, 1)   # oil / water stains
    v = 0.70 + 0.06 * (tone_l - 0.5) + 0.035 * (tone_s - 0.5) + 0.03 * grain(rng, 0.8)
    ma = np.clip((agg - 0.3) / 0.3, 0, 1) * worn
    v = v * (1 - ma) + (0.45 + 0.25 * aggt) * ma
    v = np.where(worn, v - 0.025, v)
    v = v * (1 - 0.16 * stain)
    # a few hairline cracks: random walks, thin and dark
    crack = np.zeros((N, N))
    for _ in range(5):
        y, x = rng.integers(0, N, 2).astype(float)
        a = rng.uniform(0, 2 * np.pi)
        for _ in range(rng.integers(120, 420)):
            a += rng.normal(0, 0.09)
            y, x = (y + np.sin(a) * 1.5) % N, (x + np.cos(a) * 1.5) % N
            crack[int(y), int(x)] = 1
    crack = np.clip(blur(crack, 0.7) * 6, 0, 1)
    v = v * (1 - 0.28 * crack)
    v = v / v.mean() * 0.62
    rgb = np.dstack([v * 1.0, v * 0.995, v * 0.965])   # warm pale grey (lane frames 180, 180, 175)
    h = 0.5 * fine + 0.6 * ma * agg - 0.8 * crack
    rough = 0.82 + 0.06 * (tone_s - 0.5) - 0.12 * stain
    save('concrete_color.png', rgb, 'RGB')
    save('concrete_normal.png', normal_map(h, 4.0), 'RGB')
    save('concrete_roughness.png', rough, 'L')
    return v


if __name__ == '__main__':
    a = asphalt()
    c = concrete()
    # self-check: tileable (edges meet) and sane means
    for nm in ('asphalt_color.png', 'concrete_color.png'):
        im = np.asarray(Image.open(os.path.join(out, nm)).convert('L'), float)
        seam = np.abs(im[:, 0] - im[:, -1]).mean()
        inner = np.abs(im[:, 500] - im[:, 501]).mean()
        assert seam < inner * 1.6, (nm, seam, inner)
        print(nm, 'mean %.1f std %.1f seam %.2f vs inner %.2f' % (im.mean(), im.std(), seam, inner))
