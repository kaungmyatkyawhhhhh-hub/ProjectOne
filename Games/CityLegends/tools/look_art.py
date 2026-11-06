"""Pictures for the Ghost Driver look (owner, 2026-11-06), all generated here, nothing copied:
asphalt tile (colour, normal, roughness), fog band, soft contact shadow, flat roughness maps.
Run from Games/CityLegends: python tools/look_art.py  -> build/look/*.png"""
import numpy as np
from PIL import Image
from pathlib import Path

OUT = Path("build/look")
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(1106)


def band_noise(n, lo, hi):
    """seamless noise: white noise filtered in frequency (it tiles because the FFT wraps)"""
    f = np.fft.fft2(rng.standard_normal((n, n)))
    kx = np.fft.fftfreq(n) * n
    r = np.sqrt(kx[:, None] ** 2 + kx[None, :] ** 2)
    mask = np.exp(-((r - (lo + hi) / 2) ** 2) / (2 * ((hi - lo) / 2 + 1e-6) ** 2))
    out = np.fft.ifft2(f * mask).real
    return (out - out.mean()) / out.std()


def save(arr, name):
    Image.fromarray(np.clip(arr * 255 + 0.5, 0, 255).astype(np.uint8)).save(OUT / name)


# asphalt: fine stones in dark binder, a little wear. The map stays bright: Roblox multiplies it with
# the part's own colour, so the road keeps the colour it has
N = 1024


def low_pass(n, cut):
    """seamless grain: white noise with the fine detail above `cut` removed (no ring of frequencies,
    so no worm or ripple pattern at a low angle)"""
    f = np.fft.fft2(rng.standard_normal((n, n)))
    kx = np.fft.fftfreq(n) * n
    r2 = kx[:, None] ** 2 + kx[None, :] ** 2
    out = np.fft.ifft2(f * np.exp(-r2 / (2 * cut * cut))).real
    return (out - out.mean()) / out.std()


stones = low_pass(N, 170)
fine = low_pass(N, 420)
patch = low_pass(N, 4)
height = 0.75 * stones + 0.25 * fine
height = (height - height.min()) / (height.max() - height.min())
pale = np.clip((stones - 1.7) / 1.0, 0, 1)  # pale stones catch the light
value = 0.9 + 0.17 * (height - height.mean()) + 0.12 * pale + 0.018 * patch
col = np.stack([value * 1.0, value * 0.995, value * 0.985], axis=2)
save(col, "asphalt_color.png")
dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.8
dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.8
nz = np.ones_like(dx)
l = np.sqrt(dx**2 + dy**2 + nz**2)
save(np.stack([(-dx / l + 1) / 2, (dy / l + 1) / 2, (nz / l + 1) / 2], axis=2), "asphalt_normal.png")
save(np.clip(0.84 - 0.1 * pale + 0.04 * (height - height.mean()) + 0.015 * patch, 0.5, 1), "asphalt_rough.png")


# the fog band: white, its strength in alpha; soft top and bottom, wisps across, ends fade to nothing
W, H = 1024, 256
a = band_noise(W, 2, 6) + 0.5 * band_noise(W, 6, 14)
a = np.array(Image.fromarray(((a - a.min()) / (a.max() - a.min()) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)) / 255.0
y = np.linspace(-1, 1, H)[:, None]
bell = np.exp(-(y**2) / (2 * 0.42**2)) * np.clip((1 - np.abs(y)) / 0.2, 0, 1)
x = np.linspace(0, 1, W)[None, :]
ends = np.clip(x / 0.2, 0, 1) * np.clip((1 - x) / 0.2, 0, 1)
ends = ends * ends * (3 - 2 * ends)
alpha = np.clip(bell * ends * (0.55 + 0.9 * a), 0, 1)
fog = np.dstack([np.ones((H, W)), np.ones((H, W)), np.ones((H, W)), alpha])
Image.fromarray((fog * 255).astype(np.uint8), "RGBA").save(OUT / "fog_band.png")


# a car's contact shadow: a soft dark rounded box, its edges fading out
S = 256
u, v = np.meshgrid(np.linspace(-1, 1, S), np.linspace(-1, 1, S))
dist = np.sqrt(np.clip(np.abs(u) - 0.55, 0, None) ** 2 + np.clip(np.abs(v) - 0.72, 0, None) ** 2)
t = np.clip(1 - dist / 0.3, 0, 1)
shadow = t * t * (3 - 2 * t) * 0.8
sh = np.dstack([np.zeros((S, S)), np.zeros((S, S)), np.zeros((S, S)), shadow])
Image.fromarray((sh * 255).astype(np.uint8), "RGBA").save(OUT / "contact_shadow.png")


# flat roughness maps for the paint variants
for name, val in (("rough_gloss", 0.2), ("rough_satin", 0.46)):
    save(np.full((16, 16), val), name + ".png")


# the Racing Hub's checks: one tile of black and white
c = np.ones((64, 64))
c[:32, :32] = 0.08
c[32:, 32:] = 0.08
save(np.dstack([c, c, c]), "checker.png")
