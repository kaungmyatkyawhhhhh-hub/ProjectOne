import sys, os, numpy as np, trimesh
from skimage import measure
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from geo import mk
import build as B
from clouds import cumulus, cloud_tex  # reuse the ball layout + texture
OUT, PREV = sys.argv[1], sys.argv[2]; os.makedirs(OUT, exist_ok=True); os.makedirs(PREV, exist_ok=True); B.OUT = OUT
def balls_of(seed, W, D, H, n):
    R = np.random.default_rng(seed); balls = []
    for i in range(n):
        x = R.uniform(-W/2, W/2); z = R.uniform(-D/2, D/2)
        edge = 1 - min(1, (abs(x)/(W/2))**2 + (abs(z)/(D/2))**2)
        r = 4.5 + 7.5*edge*R.uniform(0.6, 1.0)
        y = r*0.55 + edge*H*0.45*R.uniform(0.3, 1.0)
        balls.append((np.array([x, y, z]), r))
    return balls
def metacloud(balls, step):
    lo = np.min([c - r for c, r in balls], 0) - 2; hi = np.max([c + r for c, r in balls], 0) + 2
    lo[1] = -1.5
    xs = [np.arange(lo[i], hi[i], step) for i in range(3)]
    X, Y, Z = np.meshgrid(*xs, indexing="ij"); F = np.zeros(X.shape)
    for c, r in balls:
        d2 = (X-c[0])**2 + (Y-c[1])**2 + (Z-c[2])**2
        F += np.exp(-(d2/(r*r))*4.5)              # gaussian metaballs -> soft merged blobs
    F[:, xs[1] < 0, :] = 0                         # flat bottom at y=0
    v, f, n, _ = measure.marching_cubes(F, level=0.42, spacing=(step, step, step))
    v += lo
    m = trimesh.Trimesh(v, f[:, ::-1], process=True)
    parts = m.split(only_watertight=False)
    big = max(len(p.faces) for p in parts)
    m = trimesh.util.concatenate([p for p in parts if len(p.faces) > 0.08*big])
    trimesh.smoothing.filter_taubin(m, iterations=10)
    h = (m.vertices[:, 1] - m.vertices[:, 1].min())/(np.ptp(m.vertices[:, 1]) + 1e-9)
    out = mk(m.vertices, m.faces, np.stack([np.full(len(h), 0.5), h], 1))
    if np.dot(out.face_normals, [0, 1, 0]).mean() < -0.0: pass
    return out
tex = cloud_tex()
cfg = [(40, 24, 16, 30), (30, 20, 14, 24), (52, 28, 18, 40), (24, 18, 11, 20), (60, 14, 8, 30)]   # 5th = long flat ground cloud
for k, (W, D, H, n) in enumerate(cfg):
    balls = balls_of(k+3, W, D, H, n)
    if k == 4: balls = [(c*np.array([1, 0.45, 1]), r*0.8) for c, r in balls]
    step = 0.9
    m = metacloud(balls, step)
    while len(m.faces) > 18000:
        step *= 1.15; m = metacloud(balls, step)
    name = f"Cloud_{k+1}" if k < 4 else "Cloud_GroundRow"
    t, merged = B.export(name, {"Cloud": [m]}, {"Cloud": tex})
    B.render(name, merged, {"Cloud": tex}, os.path.join(PREV, name + ".png"), views=((12, -70), (35, -20)))
    print(name, t, "step", round(step, 2), "watertight", m.is_watertight)
