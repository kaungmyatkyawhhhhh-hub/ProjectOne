import numpy as np, sys
from PIL import Image, ImageFilter
OUT = sys.argv[1]
def blur(a, k): return np.asarray(Image.fromarray((np.clip(a,0,1)*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(k)), float)/255
def noise(w, h, sx, sy, seed):
    g = np.random.default_rng(seed).random((sy+1, sx+1))
    # tile horizontally: copy first column to last
    g[:, -1] = g[:, 0]
    return np.asarray(Image.fromarray((g*255).astype(np.uint8)).resize((w, h), Image.BICUBIC), float)/255
# 1) band: tileable (horizontal) wispy energy ribbon for Beams, 512x128
W, H = 512, 128
v = (np.arange(H)+0.5)/H*2-1; u = (np.arange(W)+0.5)/W
V, U = np.meshgrid(v, u, indexing="ij")
n1 = noise(W, H, 8, 4, 1); n2 = noise(W, H, 16, 6, 2)
core = np.exp(-(V/0.18)**2)
wisps = np.exp(-((V - 0.45*np.sin(2*np.pi*(U*2) + n1*3))/0.12)**2)*0.8 + np.exp(-((V + 0.4*np.sin(2*np.pi*(U*3+0.3) + n2*3))/0.1)**2)*0.6
streak = (0.6 + 0.4*np.sin(2*np.pi*(U*6 + n2*0.5)))
a = np.clip((core*0.9 + wisps)*streak*np.exp(-(V/0.85)**6), 0, 1)
lum = np.clip(0.75 + 0.25*core, 0, 1)
Image.fromarray((np.dstack([lum, lum, lum, blur(a, 1.2)])*255).astype(np.uint8), "RGBA").save(f"{OUT}/swirl_band.png")
# 2) swirl: spiral arms particle 256
S = 256; y, x = (np.mgrid[0:S, 0:S]+0.5)/S*2-1
r = np.sqrt(x*x+y*y); th = np.arctan2(y, x)
arms = np.zeros_like(r)
for k in range(3):
    ph = th + k*2*np.pi/3
    d = np.angle(np.exp(1j*(ph - r*5.5)))
    arms += np.exp(-(d/0.35)**2)*np.clip(1 - r, 0, 1)**0.7*(r > 0.08)
a = np.clip(arms*1.2 + np.exp(-(r/0.15)**2)*0.6, 0, 1)
Image.fromarray((np.dstack([np.ones((S,S)), np.ones((S,S)), np.ones((S,S)), blur(a, 1.5)])*255).astype(np.uint8), "RGBA").save(f"{OUT}/swirl.png")
print("ok")
