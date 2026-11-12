import numpy as np, json, math
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi
rng = np.random.default_rng(7)
S = 2048; HALF = 1780.0; k = (S/2)/HALF
h150 = np.load("h150.npy")
h150 = ndi.gaussian_filter(h150, 0.8)
ys, xs = np.mgrid[0:S, 0:S].astype(np.float32)
wx = (xs + 0.5 - S/2)/k; wz = (ys + 0.5 - S/2)/k
gx = (wx + 1800)/24 - 0.5; gz = (wz + 1800)/24 - 0.5
h = ndi.map_coordinates(h150, [gz, gx], order=3, mode="nearest")
r = np.hypot(wx, wz)
def hexc(s): return np.array([int(s[i:i+2],16) for i in (0,2,4)], np.float32)/255
def ramp(v, stops):
    out = np.zeros(v.shape + (3,), np.float32)
    for (a, ca), (b, cb) in zip(stops[:-1], stops[1:]):
        t = np.clip((v-a)/(b-a), 0, 1)[..., None]
        m = ((v >= a) & (v <= b))[..., None] if a < b else 0
        out = np.where((v >= a)[..., None], ca*(1-t) + cb*t, out)
    out = np.where((v < stops[0][0])[..., None], stops[0][1], out)
    return out
def sstep(v, a, b):
    t = np.clip((v-a)/(b-a), 0, 1); return t*t*(3-2*t)
# --- sea by depth
depth = -h   # studs below 0
sea = ramp(depth, [(-12, hexc("8FF2E6")), (8, hexc("49C8E8")), (30, hexc("2E8BE0")), (55, hexc("215FC2")), (80, hexc("173F96")), (105, hexc("0F2A6E")), (130, hexc("0A1B4A"))])
# biome tints by bearing
rr = np.maximum(r, 1)
wN = np.maximum(0, -wz/rr)**2; wE = np.maximum(0, wx/rr)**2; wS = np.maximum(0, wz/rr)**2; wW = np.maximum(0, -wx/rr)**2
tint = (wN[...,None]*hexc("1FC07A") + wE[...,None]*hexc("F4C46A") + wS[...,None]*hexc("D6E0FF") + wW[...,None]*hexc("8A4CF0"))
amt = ((0.6*wN + 0.9*wE + 0.62*wS + 0.6*wW)*sstep(r, 300, 430))[..., None]
# shallow parts take more tint (hills, terraces), deep channels stay blue
amt = amt*(0.62 + 0.38*np.clip(1 - (depth-30)/70, 0, 1))[..., None]
col = sea*(1-amt) + tint*amt
# reef lagoon
reef = ramp(depth, [(-14, hexc("C8FFF2")), (-6, hexc("86F3E6")), (4, hexc("4FDCE0")), (20, hexc("31B6DE"))])
mreef = (1 - sstep(r, 286, 318))[..., None]
col = col*(1-mreef) + reef*mreef
# hillshade (light from the north-west)
gyv, gxv = np.gradient(h)
slope = (-gxv - gyv)*k*0.9
shade = np.clip(slope, -1, 1)
col = col*(1 + 0.22*shade[..., None])
# contours every 16 studs
f = (h/16.0) % 1.0
gm = np.hypot(gxv, gyv)/16.0 + 1e-6
dline = np.minimum(f, 1-f)/gm     # distance to the line in px
cl = np.clip(1.6 - dline, 0, 1)*0.16*sstep(np.hypot(gxv, gyv)/k, 0.05, 0.14)*sstep(r, 300, 330)*(1 - sstep(r, 1150, 1210))
col = col + cl[..., None]*np.array([1, 1, 1], np.float32)
# --- the Red Trench
tr = ramp(depth, [(40, hexc("7E2247")), (90, hexc("5E1838")), (120, hexc("3E0F2A")), (135, hexc("2A0A20"))])
mt = sstep(r, 1165, 1235)[..., None]
col = col*(1-mt) + tr*mt*(1 + 0.3*shade[..., None])
# lava cracks: worley edges on the floor
pts = rng.uniform(-1780, 1780, (5200, 2))
pts = pts[(np.hypot(pts[:,0], pts[:,1]) > 1180) & (np.hypot(pts[:,0], pts[:,1]) < 1760)]
from scipy.spatial import cKDTree
tree = cKDTree(pts)
Q = np.stack([wx.ravel(), wz.ravel()], 1)
crack = np.zeros(S*S, np.float32)
sel = (r.ravel() > 1215) & (r.ravel() < 1745)
d, _ = tree.query(Q[sel], k=2)
e = (d[:,1] - d[:,0])
crack[sel] = np.clip(1 - e/5.0, 0, 1)
crack = crack.reshape(S, S)
floor = sstep(depth, 108, 122)*sstep(r, 1235, 1275)*(1 - sstep(r, 1690, 1735))
# only some cracks glow (noise mask), so it reads as veins not a net
nz = ndi.zoom(rng.random((40, 40)).astype(np.float32), S/40, order=3)[:S, :S]
veins = crack*floor*sstep(nz, 0.38, 0.62)
glow = ndi.gaussian_filter(veins, 7)*1.1
col = col + glow[..., None]*hexc("FF5A1E")*0.75 + (veins**1.5)[..., None]*hexc("FFC24A")*0.95
# --- the wall
wall = sstep(r, 1740, 1772)[..., None]
wc = hexc("1A1026")*(1 + 0.25*shade[..., None])
col = col*(1-wall) + wc*wall
col = np.clip(col, 0, 1)
img = Image.fromarray((col*255).astype(np.uint8)).convert("RGBA")
# --- lines + glyphs
ov = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(ov)
def P(x, z): return (S/2 + x*k, S/2 + z*k)
def ring(R, colr, w, dash=None):
    n = 720
    if not dash:
        d.ellipse([S/2-R*k, S/2-R*k, S/2+R*k, S/2+R*k], outline=colr, width=w); return
    for i in range(0, n, 2*dash):
        a0, a1 = 360*i/n, 360*(i+dash)/n
        d.arc([S/2-R*k, S/2-R*k, S/2+R*k, S/2+R*k], a0, a1, fill=colr, width=w)
for R in (510, 720, 930): ring(R, (255, 255, 255, 105), 5, dash=6)
ring(300, (255, 255, 255, 215), 7)
# trench edge with glow
gl = Image.new("RGBA", (S, S), (0, 0, 0, 0)); gd = ImageDraw.Draw(gl)
gd.ellipse([S/2-1200*k, S/2-1200*k, S/2+1200*k, S/2+1200*k], outline=(255, 70, 90, 255), width=22)
gl = gl.filter(ImageFilter.GaussianBlur(12))
img = Image.alpha_composite(img, Image.eval(gl, lambda v: v))
ring(1200, (255, 96, 116, 255), 8)
ring(1746, (10, 6, 18, 255), 10)
INK = (10, 24, 60, 255)
def blob(cx, cy, rad, fill, n=9, jit=0.22, outline=INK, w=4, squash=1.0, rot=None):
    a0 = rng.uniform(0, 6.28) if rot is None else rot
    pts_ = []
    for i in range(n):
        a = a0 + 6.2832*i/n
        rr_ = rad*(1 + rng.uniform(-jit, jit))
        pts_.append((cx + math.cos(a)*rr_, cy + math.sin(a)*rr_*squash))
    d.polygon(pts_, fill=fill, outline=outline)
    d.line(pts_ + [pts_[0]], fill=outline, width=w, joint="curve")
def star(cx, cy, rad, fill):
    pts_ = []
    a0 = rng.uniform(0, 6.28)
    for i in range(10):
        a = a0 + 6.2832*i/10; rr_ = rad if i % 2 == 0 else rad*0.45
        pts_.append((cx + math.cos(a)*rr_, cy + math.sin(a)*rr_))
    d.polygon(pts_, fill=fill); d.line(pts_ + [pts_[0]], fill=INK, width=3, joint="curve")
def leaf(cx, cy, rad, fill):
    a = rng.uniform(-0.5, 0.5) - 1.5708
    tip = (cx + math.cos(a)*rad*1.5, cy + math.sin(a)*rad*1.5)
    l = (cx + math.cos(a+2.2)*rad*0.7, cy + math.sin(a+2.2)*rad*0.7); r_ = (cx + math.cos(a-2.2)*rad*0.7, cy + math.sin(a-2.2)*rad*0.7)
    d.polygon([tip, l, r_], fill=fill); d.line([tip, l, r_, tip], fill=(8, 60, 44, 255), width=3, joint="curve")
clusters = json.load(open("clusters.json"))
GARDEN = [(255, 120, 170, 255), (255, 176, 66, 255), (255, 226, 92, 255), (120, 235, 190, 255), (190, 140, 255, 255)]
for kind, x, z, rad in sorted(clusters, key=lambda c: c[2]):
    cx, cy = P(x, z); R = rad*k
    def spot(f=0.8):
        a = rng.uniform(0, 6.28); q = math.sqrt(rng.uniform(0, 1))*R*f
        return cx + math.cos(a)*q, cy + math.sin(a)*q
    if kind == "rocks":
        for i in range(3):
            px, py = spot(0.55); rr_ = R*rng.uniform(0.28, 0.46)
            blob(px, py, rr_, (118, 146, 176, 255), n=7, jit=0.18)
            blob(px - rr_*0.2, py - rr_*0.25, rr_*0.45, (168, 196, 222, 255), n=6, jit=0.15, outline=(168, 196, 222, 255), w=1)
    elif kind == "mesa":
        for i in range(2):
            px, py = spot(0.4); rr_ = R*rng.uniform(0.42, 0.6)
            blob(px, py + rr_*0.16, rr_, (150, 104, 60, 255), n=8, jit=0.12)
            blob(px, py - rr_*0.06, rr_*0.86, (232, 186, 112, 255), n=8, jit=0.12, w=3)
    elif kind == "spires":
        for i in range(5):
            px, py = spot(0.7); hh = R*rng.uniform(0.3, 0.5); ww = hh*0.42
            tri = [(px, py - hh), (px - ww, py + hh*0.35), (px + ww, py + hh*0.35)]
            d.polygon(tri, fill=(118, 86, 214, 255))
            d.polygon([(px, py - hh), (px - ww, py + hh*0.35), (px - ww*0.1, py + hh*0.35)], fill=(170, 140, 255, 255))
            d.line(tri + [tri[0]], fill=INK, width=4, joint="curve")
    elif kind == "kelpForest":
        for i in range(9):
            px, py = spot(0.85); leaf(px, py, max(R*0.2, 9), (60, 200, 110, 255) if i % 2 else (36, 160, 96, 255))
    elif kind == "palms":
        for i in range(4):
            px, py = spot(0.7); star(px, py, max(R*0.3, 10), (64, 214, 190, 255))
    elif kind == "garden":
        for i in range(5):
            px, py = spot(0.7); rr_ = max(R*rng.uniform(0.16, 0.26), 6)
            blob(px, py, rr_, GARDEN[int(rng.integers(0, len(GARDEN)))], n=8, jit=0.1, w=3)
    elif kind == "starfield":
        for i in range(4):
            px, py = spot(0.7); star(px, py, max(R*0.28, 8), (255, 150, 70, 255))
img = Image.alpha_composite(img, ov)
out = img.convert("RGB").resize((1024, 1024), Image.LANCZOS)
out.save("worldmap_1024.png")
# preview in a disc on the window colour
pv = Image.new("RGB", (1100, 1100), (233, 242, 255))
mask = Image.new("L", (1024, 1024), 0); ImageDraw.Draw(mask).ellipse([0, 0, 1023, 1023], fill=255)
pv.paste(out, (38, 38), mask); pv.save("preview.png")
print("ok")
