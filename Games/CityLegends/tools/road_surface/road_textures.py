"""Road surface maps (27 Nov 2026, owner: "the road textures dont look realistic ... not every small road is asphalt,
the big roads & overhead roads are always asphalt"; vault `City Legends/2026-11-27 Roads - realistic surfaces by road type.md`).

Tileable 1024 px maps, all procedural (numpy + PIL), seeded = rebuildable:
  asphalt_*   big roads + flyover decks (MaterialVariant YgnRoadAsphalt, base Asphalt, StudsPerTile 16 (v4, owner 27 Nov: small sharp stones, not big blurry rubble)):
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
    """v4 (owner 27 Nov: "the asphalt road texture rubbles are too big ... they look blurry ... need to be sharp"):
    crisp, small aggregate - hard-edged stones 1-3 px (StudsPerTile 16: 64 px a stud, stones about 0.5-1.5 cm), each its
    own grey, in a dark binder with fine sand; domed normal per stone; stone tops glossier. No soft blur, no blotches."""
    from scipy.spatial import cKDTree
    rng = np.random.default_rng(1127)
    n = 60000
    pts = rng.random((n, 2)) * N
    rad = rng.uniform(0.9, 2.6, n) * (rng.random(n) < 0.85) + rng.uniform(2.6, 4.2, n) * 0   # mostly small stones
    rad = np.where(rad == 0, rng.uniform(2.6, 3.8, n), rad)
    tone = np.where(rng.random(n) < 0.03, rng.uniform(0.62, 0.74, n), rng.uniform(0.27, 0.46, n))   # a few pale chips
    off = np.array([(dx, dy) for dx in (-N, 0, N) for dy in (-N, 0, N)])
    tree = cKDTree(np.concatenate([pts + o for o in off]))
    yy, xx = np.mgrid[0:N, 0:N]
    q = np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1)
    d, i = tree.query(q)
    i = i % n
    d = d.reshape(N, N)
    i = i.reshape(N, N)
    r = rad[i]
    stone = d < r
    dome = np.where(stone, np.sqrt(np.maximum(r * r - d * d, 0)) / r, 0)
    sand = rng.random((N, N))
    binder = 0.19 + 0.05 * sand
    v = np.where(stone, tone[i] * (0.85 + 0.15 * dome), binder)
    v = v / v.mean() * 0.42
    rgb = np.dstack([v * 0.99, v * 1.0, v * 1.015])
    h = dome * 1.0 + 0.15 * sand
    rough = np.where(stone, 0.55 - 0.15 * dome, 0.95)
    save('asphalt_color.png', rgb, 'RGB')
    save('asphalt_normal.png', normal_map(h, 2.2), 'RGB')
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


# street-aligned concrete (owner 27 Nov: "i dont see concrete roads with details & texture"): the small streets' RC
# meshes carry road-local UVs (road_surface_split.street_uv): U = along / 2 (one tile = 64 studs = 4 slabs of 16), V = across
# (one tile = 32 studs, the centre line at V = 0). Image columns = along (16 px a stud), rows = across (32 px a stud).
SPAN_U, SPAN_V = 64.0, 32.0
PXU, PXV = N / SPAN_U, N / SPAN_V


def ablur(a, su, sv):
    """wrap-around gaussian blur with sigmas in studs along / across"""
    ku = np.fft.fftfreq(N)[None, :]
    kv = np.fft.fftfreq(N)[:, None]
    g = np.exp(-2 * np.pi ** 2 * ((su * PXU) ** 2 * ku ** 2 + (sv * PXV) ** 2 * kv ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * g))


def agrain(rng, sigma):
    g = ablur(rng.standard_normal((N, N)), sigma, sigma)
    return (g - g.mean()) / g.std()


def concrete_street():
    """small-street cast concrete, v4 (owner 27 Nov: "i dont think concrete comes in panels and symmetrical gradient
    line?"): ONE continuous surface - no slab joints, no centre joint, no per-panel tones, nothing mirrored across the
    street. Irregular soft blotches at several sizes, two tyre-polish paths that wander and fade (not symmetric), oil /
    dirt stains, a few random hairline cracks and two blobby cement repairs. Tile = 64 studs along x 32 across."""
    rng = np.random.default_rng(1811)
    U = (np.arange(N) + 0.5) / PXU
    V = (np.arange(N) + 0.5) / PXV
    Vs = np.where(V > SPAN_V / 2, V - SPAN_V, V)      # -16 .. 16 from the centre line
    uu, vv = np.meshgrid(U, Vs)

    def soft(su, sv):
        g = ablur(rng.standard_normal((N, N)), su, sv)
        return (g - g.mean()) / g.std()

    v = 0.70 + 0.030 * agrain(rng, 0.03) + 0.015 * agrain(rng, 0.10)
    v *= 1 + 0.045 * soft(6.0, 4.0) + 0.030 * soft(2.5, 1.8) + 0.015 * soft(0.9, 0.7)   # irregular tone, no panels
    # tyre polish: two paths that wander along the street and fade in and out, at different offsets (not mirrored)
    track = np.zeros((N, N))
    for c0, amp, k, ph in ((4.6, 1.3, 1, 0.7), (-6.3, 1.0, 2, 2.1)):
        centre = c0 + amp * np.sin(2 * np.pi * k * uu / SPAN_U + ph) + 0.5 * np.sin(2 * np.pi * (k + 2) * uu / SPAN_U + ph * 1.7)
        width = 1.1 + 0.35 * np.sin(2 * np.pi * 3 * uu / SPAN_U + ph)
        track += np.exp(-((vv - centre) / width) ** 2)
    fade = np.clip(0.55 + 0.6 * soft(9.0, 6.0), 0, 1)
    track = np.clip(track, 0, 1) * fade
    v *= 1 - 0.07 * track
    # stains: a few soft dark oil / water marks, brownish dirt blotches
    oil = np.clip((soft(1.8, 1.4) - 1.6) / 1.2, 0, 1)
    dirt = np.clip((soft(4.0, 3.0) - 1.0) / 1.5, 0, 1)
    v *= 1 - 0.16 * oil
    # two blobby cement repairs (irregular outlines, slightly greyer and smoother)
    rep = soft(1.6, 1.3) > 2.3   # a few irregular cement repairs (noise islands, not shapes)
    v = np.where(rep, v * 0.86 + 0.02, v)
    # a few random hairline cracks
    crack = np.zeros((N, N))
    for _ in range(5):
        u, w, a = rng.uniform(0, SPAN_U), rng.uniform(-14, 14), rng.uniform(0, 2 * np.pi)
        for _ in range(int(rng.uniform(4, 11) / 0.08)):
            a += rng.normal(0, 0.09)
            u, w = u + np.cos(a) * 0.08, w + np.sin(a) * 0.08
            crack[int((w % SPAN_V) * PXV) % N, int((u % SPAN_U) * PXU) % N] = 1
    crack = np.clip(ablur(crack, 0.03, 0.03) * 7, 0, 1)
    v *= 1 - 0.30 * crack
    v = v / v.mean() * 0.64
    rgb = np.dstack([v * 1.0, v * 0.995, v * 0.965])
    rgb = rgb * (1 - dirt[..., None] * np.array([0.04, 0.06, 0.10]))
    h = 0.06 * agrain(rng, 0.03) - 0.8 * crack + 0.05 * rep
    rough = np.clip(0.85 - 0.12 * track - 0.06 * rep - 0.1 * oil, 0, 1)
    save('concrete_color.png', rgb, 'RGB')
    save('concrete_normal.png', normal_map(h, 3.0), 'RGB')
    save('concrete_roughness.png', rough, 'L')
    return v

if __name__ == '__main__':
    a = asphalt()
    c = concrete_street()
    # self-check: tileable (edges meet) and sane means
    for nm in ('asphalt_color.png', 'concrete_color.png'):
        im = np.asarray(Image.open(os.path.join(out, nm)).convert('L'), float)
        seam = np.abs(im[:, 0] - im[:, -1]).mean()
        inner = np.abs(im[:, 500] - im[:, 501]).mean()
        assert seam < inner * 1.6, (nm, seam, inner)
        print(nm, 'mean %.1f std %.1f seam %.2f vs inner %.2f' % (im.mean(), im.std(), seam, inner))
