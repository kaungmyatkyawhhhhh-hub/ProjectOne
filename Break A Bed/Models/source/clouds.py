import sys, os, numpy as np, trimesh
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from geo import mk
import build as B
from PIL import Image
OUT, PREV = sys.argv[1], sys.argv[2]; os.makedirs(OUT, exist_ok=True); os.makedirs(PREV, exist_ok=True)
B.OUT = OUT

def puff(c, r, sub=2):
    m = trimesh.creation.icosphere(subdivisions=sub, radius=r)
    v = m.vertices + c
    # uv: v = height inside the cloud (filled in later), u unused
    return v, m.faces

def cumulus(seed, W=40, D=24, H=16, n=34):
    R = np.random.default_rng(seed); vs, fs, off = [], [], 0
    balls = []
    # flat-ish bottom row + bigger puffs piled on top toward the middle
    for i in range(n):
        x = R.uniform(-W/2, W/2); z = R.uniform(-D/2, D/2)
        edge = 1 - min(1, (abs(x)/(W/2))**2 + (abs(z)/(D/2))**2)
        r = 3.5 + 6.5*edge*R.uniform(0.6, 1.0)
        y = r*0.55 + edge*H*0.45*R.uniform(0.3, 1.0)
        balls.append((np.array([x, y, z]), r))
    for c, r in balls:
        v, f = puff(c, r); vs.append(v); fs.append(f + off); off += len(v)
    V = np.vstack(vs); F = np.vstack(fs)
    V[:, 1] = np.maximum(V[:, 1], 0.4)          # flatten the bottom (sits on the ground)
    h = (V[:, 1] - V[:, 1].min())/(np.ptp(V[:, 1]) + 1e-9)
    uv = np.stack([np.zeros(len(V)) + 0.5, h], 1)
    return mk(V, F, uv)

def cloud_tex():
    S = 256; img = np.zeros((S, S, 3))
    v = np.linspace(1, 0, S)[:, None]            # row 0 = top (v=1)
    top = np.array([1, 1, 1.0]); bottom = np.array([0.78, 0.82, 0.9])
    col = bottom + (top-bottom)*np.clip(v*1.6, 0, 1)
    img[:] = col[:, None, :] if col.ndim == 2 else col
    return Image.fromarray((np.clip(img, 0, 1)*255).astype(np.uint8))

tex = cloud_tex()
for k, (W, D, H) in enumerate([(40, 24, 16), (30, 20, 14), (52, 28, 18), (24, 18, 11)]):
    m = cumulus(k+3, W, D, H, n=[30, 24, 40, 20][k])
    name = f"Cloud_{k+1}"
    t, merged = B.export(name, {"Cloud": [m]}, {"Cloud": tex})
    B.render(name, merged, {"Cloud": tex}, os.path.join(PREV, name + ".png"), views=((12, -70), (35, -20)))
    print(name, t)
