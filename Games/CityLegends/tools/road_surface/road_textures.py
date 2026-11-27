"""Road surface maps (27 Nov 2026, owner: "the road textures dont look realistic ... not every small road is asphalt,
the big roads & overhead roads are always asphalt"; vault `City Legends/2026-11-27 Roads - realistic surfaces by road type.md`).

Tileable 1024 px maps, all procedural (numpy + PIL), seeded = rebuildable:
  asphalt_*   big roads + flyover decks (MaterialVariant YgnRoadAsphalt, base Asphalt, StudsPerTile 40 (v3, owner 27 Nov: the grain must show at driving distance; finer tiles fade to plain grey)):
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
    v = 0.55 + 0.11 * np.clip(g, -2.5, 2.5) + 0.022 * (tone_l - 0.5) + 0.012 * (tone_s - 0.5)   # owner 27 Nov: fine even speckle, no blotches
    v = v * (1 - chips) + 0.80 * chips
    v = v / v.mean() * 0.59                                # mean about 150
    rgb = np.dstack([v * 0.99, v * 1.0, v * 1.015])        # very slightly cool, as dry tarmac
    peak = np.clip((g - 1.0) / 1.2, 0, 1)                  # stone tops: smoother, catch the sun
    rough = 0.93 - 0.40 * peak - 0.25 * chips - 0.03 * (tone_l - 0.5)
    save('asphalt_color.png', rgb, 'RGB')
    save("asphalt_normal.png", normal_map(0.12 * g + 0.25 * chips, 15.0), "RGB")
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
    rng = np.random.default_rng(1711)
    U = (np.arange(N) + 0.5) / PXU                   # studs along, per column
    V = (np.arange(N) + 0.5) / PXV                   # studs across, per row (0 = centre line)
    Vs = np.where(V > SPAN_V / 2, V - SPAN_V, V)     # signed: -16 .. 16
    uu, vv = np.meshgrid(U, Vs)
    slab = (uu // 16).astype(int)                    # 4 slabs along
    side = (vv > 0).astype(int)
    tones = 1 + rng.uniform(-0.07, 0.07, (4, 2))
    v = tones[slab, side] * (0.70 + 0.035 * agrain(rng, 0.03) + 0.02 * agrain(rng, 0.12))
    # broad stains (tile-sized, soft) and worn spots
    stain = np.clip((ablur(rng.random((N, N)), 2.0, 2.0) - 0.5) * 40 + 0.0, 0, 1)
    v *= 1 - 0.10 * np.clip(ablur(rng.standard_normal((N, N)), 2.5, 1.2) * 6, 0, 1)
    # tyre paths: one lane each way, wheels at about 4.5 and 8.5 studs from the centre, worn darker + smoother
    track = sum(np.exp(-((np.abs(vv) - c) / 0.9) ** 2) for c in (4.3, 8.7))
    track = track * (0.85 + 0.3 * ablur(rng.random((N, N)), 3.0, 0.4))
    v *= 1 - 0.14 * np.clip(track, 0, 1.2)
    # dust and grime toward the edges (most lanes are about 20 studs wide: edges at 9-11 from the centre)
    edge = np.clip((np.abs(vv) - 8.5) / 2.5, 0, 1) * (0.8 + 0.4 * ablur(rng.random((N, N)), 1.5, 0.6))
    # repaired slab: slab 2, side 0 darker and greyer, sharp edge
    rep = (slab == 2) & (side == 0) & (np.abs(vv) > 0.3)
    v = np.where(rep, v * 0.74, v)
    # spalled corner: slab 1, side 1, at the joint near the centre
    cu, cv = 16.0, 0.0
    du, dv = uu - cu, vv - cv
    spall = (du > 0) & (dv > 0) & (du / 3.2 + dv / 2.2 + 0.25 * np.sin(du * 3) < 1)
    rim = (du > 0) & (dv > 0) & ~spall & (du / 3.7 + dv / 2.6 + 0.25 * np.sin(du * 3) < 1)
    v = np.where(spall, v * 0.62, np.where(rim, v * 0.8, v))
    # hairline cracks: across slab 0 side 0 and slab 3 side 1, along slab 1 side 0
    crack = np.zeros((N, N))
    def walk(u0, v0, ang, length):
        u, w, a = u0, v0, ang
        for _ in range(int(length / 0.08)):
            a += rng.normal(0, 0.06)
            u, w = u + np.cos(a) * 0.08, w + np.sin(a) * 0.08
            c, r = int((u % SPAN_U) * PXU), int((w % SPAN_V) * PXV)
            crack[r, c] = 1
    walk(9.0, 0.5, np.pi / 2 + 0.2, 13)       # across a whole half, slab 0
    walk(57.0, -0.5, -np.pi / 2 - 0.1, 9)     # across, slab 3, other side
    walk(18.0, 5.5, 0.05, 10)                 # along, slab 1
    walk(40.0, -11.0, 0.3, 4)                 # short one near an edge
    crack = np.clip(ablur(crack, 0.03, 0.03) * 8, 0, 1)
    v *= 1 - 0.35 * crack
    # sawn joints: across at 0 / 16 / 32 / 48 studs, along the centre (V = 0, wraps): dark, slightly worn wide
    ju = np.minimum(uu % 16, 16 - uu % 16)
    jv = np.abs(vv)
    joint = np.clip(1 - (np.minimum(ju, jv) - 0.12) / 0.12, 0, 1)
    v *= 1 - 0.45 * joint
    v = v / v.mean() * 0.62
    rgb = np.dstack([v * 1.0, v * 0.995, v * 0.965])
    rgb = rgb * (1 - edge[..., None] * np.array([0.05, 0.07, 0.12]))   # brown-grey dirt
    h = 0.4 * agrain(rng, 0.03) * 0.15 - 1.5 * joint - 0.8 * crack - 0.6 * spall + 0.1 * rep
    rough = np.clip(0.84 - 0.10 * np.clip(track, 0, 1) + 0.05 * spall, 0, 1)
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
