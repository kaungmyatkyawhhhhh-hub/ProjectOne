# Galaxy Incremental - map images (2 Nov 2026, Claude Code). python make_map_images.py
#   sky_<face>.png   6 skybox faces (1024): deep violet space, a soft galaxy band, violet/blue nebula, stars (static)
#   board_upgrades.png / board_tree.png   the board screens (the approved v9/v12 windows, cropped)
import os, math
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
UI = os.path.join(HERE, "..", "UI")
OUT = os.path.join(HERE, "images")
os.makedirs(OUT, exist_ok=True)
N = 1024
rng = np.random.default_rng(3)

# ---- smooth 3D noise of a direction (value noise on a lattice, trilinear, a few octaves)
LAT = rng.random((64, 64, 64)).astype(np.float32)


def vnoise(p):
    p = p % 64
    i = np.floor(p).astype(int)
    f = p - i
    f = f * f * (3 - 2 * f)
    def g(dx, dy, dz):
        return LAT[(i[..., 0] + dx) % 64, (i[..., 1] + dy) % 64, (i[..., 2] + dz) % 64]
    x00 = g(0, 0, 0) * (1 - f[..., 0]) + g(1, 0, 0) * f[..., 0]
    x10 = g(0, 1, 0) * (1 - f[..., 0]) + g(1, 1, 0) * f[..., 0]
    x01 = g(0, 0, 1) * (1 - f[..., 0]) + g(1, 0, 1) * f[..., 0]
    x11 = g(0, 1, 1) * (1 - f[..., 0]) + g(1, 1, 1) * f[..., 0]
    y0 = x00 * (1 - f[..., 1]) + x10 * f[..., 1]
    y1 = x01 * (1 - f[..., 1]) + x11 * f[..., 1]
    return y0 * (1 - f[..., 2]) + y1 * f[..., 2]


def fbm(d, scale, octaves=5):
    total, amp, s = 0, 0.5, scale
    for _ in range(octaves):
        total = total + vnoise(d * s + 17.3) * amp
        amp *= 0.5
        s *= 2.03
    return total


# Roblox skybox faces, measured in Studio on 2 Nov with test images (seen from inside): Ft = -Z, Bk = +Z, Lf = +X, Rt = -X
# (Lf/Rt are NOT the -X/+X you'd guess), Up = +Y with the image top toward +X, Dn = -Y with the image top toward -X.
# Each face: F (the direction it faces), R (the image's right), U (the image's top); a pixel's direction = F + x*R + y*U
FACES = {
    "Ft": ((0, 0, -1), (1, 0, 0), (0, 1, 0)),
    "Bk": ((0, 0, 1), (-1, 0, 0), (0, 1, 0)),
    "Lf": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "Rt": ((-1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "Up": ((0, 1, 0), (0, 0, -1), (1, 0, 0)),
    "Dn": ((0, -1, 0), (0, 0, -1), (-1, 0, 0)),
}


def face_dirs(face):
    F, R, U = (np.array(v, np.float64) for v in FACES[face])
    u = (np.arange(N) + 0.5) / N * 2 - 1
    uu, vv = np.meshgrid(u, -u)
    d = F + uu[..., None] * R + vv[..., None] * U
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


# the stars: random directions, splatted per face
STARS = rng.normal(size=(9000, 3))
STARS /= np.linalg.norm(STARS, axis=1, keepdims=True)
SB = rng.random(9000) ** 3
SCOL = np.array([[1, 0.95, 0.9], [0.8, 0.85, 1], [1, 0.85, 0.7], [0.95, 0.8, 1]])[rng.integers(0, 4, 9000)]
band_axis = np.array([0.25, 0.9, -0.35]); band_axis /= np.linalg.norm(band_axis)

for face in ["Ft", "Bk", "Lf", "Rt", "Up", "Dn"]:
    d = face_dirs(face).astype(np.float32)
    base = np.zeros(d.shape, np.float32) + np.array([0.035, 0.018, 0.075], np.float32)
    band = np.exp(-(d @ band_axis) ** 2 / 0.06)[..., None]  # the galaxy band
    n1 = fbm(d, 2.2)[..., None]
    n2 = fbm(d + 5.1, 3.1)[..., None]
    neb_v = np.clip((n1 - 0.45) * 2.2, 0, 1) ** 1.6
    neb_b = np.clip((n2 - 0.5) * 2.4, 0, 1) ** 1.8
    col = base + band * np.array([0.16, 0.08, 0.26]) * (0.5 + n1) + neb_v * np.array([0.42, 0.12, 0.62]) + neb_b * np.array([0.1, 0.22, 0.55])
    img = np.clip(col, 0, 1)
    # stars on this face
    lay = np.zeros((N, N, 3), np.float32)
    F, R, U = (np.array(v, np.float64) for v in FACES[face])
    for s_, b, c in zip(STARS, SB, SCOL):
        f = s_ @ F
        if f <= 0: continue
        dd = s_ / f
        x, y = dd @ R, dd @ U
        if abs(x) > 1 or abs(y) > 1: continue
        px, py = int((x + 1) / 2 * N), int((1 - (y + 1) / 2) * N)
        if 0 <= px < N and 0 <= py < N:
            lay[py, px] += c * (0.35 + 1.6 * b)
    glow = np.asarray(Image.fromarray(np.clip(lay * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255
    img = np.clip(img + lay * 0.9 + glow * 1.4, 0, 1)
    Image.fromarray((img * 255).astype(np.uint8)).save(os.path.join(OUT, f"sky_{face}.png"))

# the board screens: the windows cropped from the approved UI
Image.open(os.path.join(UI, "galaxy_ui_v9_flat.png")).convert("RGB").crop((276, 112, 1004, 614)).resize((512, 353), Image.LANCZOS).save(os.path.join(OUT, "board_upgrades.png"))
Image.open(os.path.join(UI, "windows", "galaxy_window_tree.png")).convert("RGB").crop((296, 116, 1004, 594)).resize((512, 346), Image.LANCZOS).save(os.path.join(OUT, "board_tree.png"))
print("done", sorted(os.listdir(OUT)))
