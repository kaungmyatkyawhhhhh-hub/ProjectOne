"""yangon_sky.py: Yangon's midday sky box from the street survey's measured colours (2026-11-16): zenith about
150, 185, 220, a near-white haze band 5-10 degrees high at the horizon (215, 222, 225), soft white dry-season cumulus.
Writes the six faces (1024 px) to imports/sync/sky/ for upload; DayCycle uses them as RivieraSkies.YangonDay."""
import math, os, random
import numpy as np
from PIL import Image, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "imports", "sync", "sky")
N = 512
ZEN = np.array([150, 185, 220], float)
HOR = np.array([216, 223, 226], float)
GROUND = np.array([196, 198, 194], float)


def sky_col(el):
    """el: elevation in radians -> colour (a haze band near 0, pale blue overhead)."""
    if el < 0:
        return GROUND
    t = min(1.0, el / math.radians(55))
    t = t ** 0.65
    return HOR + (ZEN - HOR) * t


def face_dirs(face):
    u = (np.arange(N) + 0.5) / N * 2 - 1
    U, V = np.meshgrid(u, -u)
    one = np.ones_like(U)
    if face == "Ft": d = (U, V, -one)        # -Z
    elif face == "Bk": d = (-U, V, one)      # +Z
    elif face == "Rt": d = (one, V, U)       # +X
    elif face == "Lf": d = (-one, V, -U)     # -X
    elif face == "Up": d = (U, one, V)
    else: d = (U, -one, -V)
    x, y, z = d
    L = np.sqrt(x * x + y * y + z * z)
    return x / L, y / L, z / L


rng = np.random.default_rng(7)
# cloud field on a sphere: sum of soft blobs above the horizon
blobs = []
for _ in range(0):
    az = rng.uniform(0, 2 * math.pi)
    el = rng.uniform(math.radians(6), math.radians(40))
    r = rng.uniform(0.04, 0.12)
    for _ in range(rng.integers(3, 8)):
        a2, e2 = az + rng.normal(0, r * 0.9), max(math.radians(4), el + rng.normal(0, r * 0.35))
        blobs.append((math.cos(e2) * math.sin(a2), math.sin(e2), math.cos(e2) * math.cos(a2), r * rng.uniform(0.4, 0.9)))
B = np.array(blobs).reshape(-1, 4)  # (no painted clouds: the game draws its own 3D clouds)

os.makedirs(OUT, exist_ok=True)
for face in ("Ft", "Bk", "Lf", "Rt", "Up", "Dn"):
    x, y, z = face_dirs(face)
    el = np.arcsin(np.clip(y, -1, 1))
    t = np.clip(el / math.radians(55), 0, 1) ** 0.65
    img = HOR[None, None, :] + (ZEN - HOR)[None, None, :] * t[..., None]
    img = np.where((el < 0)[..., None], GROUND[None, None, :], img)
    cloud = np.zeros_like(x)
    for bx, by, bz, br in B:
        d = (x - bx) ** 2 + (y - by) ** 2 + (z - bz) ** 2
        cloud += np.exp(-d / (2 * br * br)) * 0.32
    cloud = np.clip(cloud, 0, 1) * (el > 0)
    shade = 1 - 0.12 * np.clip((by_ := y) * 0, 0, 1)
    cl = np.array([246, 246, 243], float)
    img = img * (1 - cloud[..., None] * 0.85) + cl[None, None, :] * cloud[..., None] * 0.85
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.5)).save(os.path.join(OUT, "ygn_sky_%s.png" % face))
    print(face, img[N // 2, N // 2].astype(int))
