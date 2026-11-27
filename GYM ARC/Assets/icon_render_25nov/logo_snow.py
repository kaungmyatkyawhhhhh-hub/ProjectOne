# Christmas logo: snow caps on every top surface of the logo, drawn in code (logo is never drawn by ChatGPT).
# usage: python logo_snow.py <in_logo.png> <out.png> [depth_px=30]
import sys, numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter1d, binary_closing, gaussian_filter
src, out = sys.argv[1], sys.argv[2]; D = int(sys.argv[3]) if len(sys.argv) > 3 else 30
im0 = Image.open(src).convert('RGBA'); PAD = int(D*1.3)
im = Image.new('RGBA', (im0.width, im0.height+PAD), (0,0,0,0)); im.alpha_composite(im0, (0, PAD)); H, W = im.size[1], im.size[0]
from scipy.ndimage import binary_fill_holes, binary_dilation
a = binary_fill_holes(binary_closing(np.asarray(im)[..., 3] > 60, np.ones((25, 25))))  # solid silhouette so caps sit on the outer shape, not the thin ring
rng = np.random.default_rng(7)
depth = D*(0.75 + 0.5*gaussian_filter1d(rng.random(W), 9)*1.0)  # wavy snow thickness
drip = np.zeros(W)
for c in rng.choice(W, W//90, replace=False):  # a few icicle-ish drips
    xs = np.arange(W); drip += 0.9*D*np.exp(-((xs-c)/(6+rng.random()*6))**2)
bulge = 0.7*D*(0.7+0.6*gaussian_filter1d(rng.random(W), 12))
snow = np.zeros((H, W), bool)
for x in range(W):
    col = a[:, x]; ys = np.where(col[1:] & ~col[:-1])[0] + 1
    if col[0]: ys = np.r_[0, ys]
    for y0 in ys:
        if y0 > 6 and col[max(0, y0-12):y0].any(): continue  # skip tiny gaps
        top = int(max(0, y0 - bulge[x])); bot = int(y0 + depth[x] + drip[x])
        seg = col[y0:bot]; end = y0 + (np.argmin(seg) if (~seg).any() else len(seg))  # stay inside the letter below the surface
        snow[top:end, x] = True
snow = binary_closing(snow, np.ones((5, 9)))
m = gaussian_filter(snow.astype(float), 1.6); snow_a = np.clip((m-0.35)/0.3, 0, 1)
# shading: white top, icy light blue toward the bottom edge of each cap
inner = gaussian_filter(snow.astype(float), 5)
ys = np.arange(H)[:, None]; shade = np.clip(1.15 - inner, 0, 1)
white = np.array([250, 253, 255.]); ice = np.array([170, 205, 245.])
rgb = white*(1-shade[..., None]*0.75) + ice*(shade[..., None]*0.75)
base = np.asarray(im).astype(float)
ring = np.clip(gaussian_filter(snow_a, 2.2)*1.0 + 0, 0, 1); ring = np.clip((gaussian_filter((snow_a>0.5).astype(float),3)>0.02)*1.0 - snow_a, 0, 1)  # dark navy edge so white snow separates from the silver letters
navy = np.array([8,16,40.])
base[..., :3] = base[..., :3]*(1-ring[..., None]) + navy*ring[..., None]; base[..., 3] = np.maximum(base[..., 3], ring*255)
outa = np.maximum(base[..., 3]/255, snow_a)
outrgb = base[..., :3]*(1-snow_a[..., None]) + rgb*snow_a[..., None]
res = np.dstack([outrgb, outa*255]).clip(0, 255).astype(np.uint8)
Image.fromarray(res, 'RGBA').save(out); print(out, snow.mean())
