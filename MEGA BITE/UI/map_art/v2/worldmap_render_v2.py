"""MEGA BITE world map picture v2 (13 Nov 2026): the WHOLE world, r 0..2480 (v1 stopped at the old wall, r 1780, so the
Titan Sea was a plain gold ring). Drawn from the real terrain and the real props:
  h150.npy      heights of the inner sea, 24-stud grid over +-1800 (v1 export)
  ring_h/_m.npy heights + terrain material of r 1690..2530, 36-stud grid over +-2520 (decode_ring.py, exported 13 Nov)
  clusters_v2.json  what stands where: [kind, x, z, radius, pieces], from the live props in 150-stud cells
Output: 2040 x 2040 px = four 1024 px tiles that overlap by 8 px (so the map can be zoomed), + a preview."""
import numpy as np, json, math
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi
from scipy.spatial import cKDTree
rng = np.random.default_rng(7)
S = 2040; HALF = 2480.0; k = (S/2)/HALF
ys, xs = np.mgrid[0:S, 0:S].astype(np.float32)
wx = (xs + 0.5 - S/2)/k; wz = (ys + 0.5 - S/2)/k
r = np.hypot(wx, wz)
def hexc(s): return np.array([int(s[i:i+2], 16) for i in (0, 2, 4)], np.float32)/255
def sstep(v, a, b):
    t = np.clip((v-a)/(b-a), 0, 1); return t*t*(3-2*t)
def ramp(v, stops):
    out = np.zeros(v.shape + (3,), np.float32) + stops[0][1]
    for (a, ca), (b, cb) in zip(stops[:-1], stops[1:]):
        t = np.clip((v-a)/(b-a), 0, 1)[..., None]
        out = np.where((v >= a)[..., None], ca*(1-t) + cb*t, out)
    return out
# ---------------------------------------------------------------- heights
h150 = ndi.gaussian_filter(np.load("h150.npy"), 0.8)
h_in = ndi.map_coordinates(h150, [(wz + 1800)/24 - 0.5, (wx + 1800)/24 - 0.5], order=3, mode="nearest")
ring_h = ndi.gaussian_filter(np.load("ring_h.npy"), 0.6); ring_m = np.load("ring_m.npy")
gj, gi = (wz + 2520)/36 - 0.5, (wx + 2520)/36 - 0.5
h_out = ndi.map_coordinates(ring_h, [gj, gi], order=3, mode="nearest")
def matmask(code, blur):
    m = ndi.gaussian_filter((ring_m == code).astype(np.float32), blur)
    return np.clip(ndi.map_coordinates(m, [gj, gi], order=1, mode="nearest"), 0, 1)
w_out = sstep(r, 1700, 1760)
h = h_in*(1 - w_out) + h_out*w_out
# the Kraken's pit and the eel's burrow were dug after the v1 export
for (px, pz, pr, pd) in ((-790, 180, 150, -105), (738, 48, 30, -70)):
    d = np.hypot(wx - px, wz - pz); t = 1 - sstep(d, pr*0.55, pr)
    h = h*(1 - t) + np.minimum(h, pd)*t
depth = -h
gyv, gxv = np.gradient(h)
shade = np.clip((-gxv - gyv)*k*1.6, -1, 1)          # light from the north-west
# ---------------------------------------------------------------- the inner sea (as v1)
sea = ramp(depth, [(-12, hexc("8FF2E6")), (8, hexc("49C8E8")), (30, hexc("2E8BE0")), (55, hexc("215FC2")), (80, hexc("173F96")), (105, hexc("0F2A6E")), (130, hexc("0A1B4A"))])
rr = np.maximum(r, 1)
wN = np.maximum(0, -wz/rr)**2; wE = np.maximum(0, wx/rr)**2; wS = np.maximum(0, wz/rr)**2; wW = np.maximum(0, -wx/rr)**2
tint = (wN[..., None]*hexc("1FC07A") + wE[..., None]*hexc("F4C46A") + wS[..., None]*hexc("D6E0FF") + wW[..., None]*hexc("8A4CF0"))
amt = ((0.6*wN + 0.9*wE + 0.62*wS + 0.6*wW)*sstep(r, 300, 430))
amt = (amt*(0.62 + 0.38*np.clip(1 - (depth-30)/70, 0, 1)))[..., None]
col = sea*(1-amt) + tint*amt
reef = ramp(depth, [(-14, hexc("C8FFF2")), (-6, hexc("86F3E6")), (4, hexc("4FDCE0")), (20, hexc("31B6DE"))])
mreef = (1 - sstep(r, 286, 318))[..., None]
col = col*(1-mreef) + reef*mreef
col = col*(1 + 0.22*shade[..., None])
def contours(step, strength, mask):
    f = (h/step) % 1.0
    gm = np.hypot(gxv, gyv)/step + 1e-6
    dline = np.minimum(f, 1-f)/gm
    return np.clip(1.5 - dline, 0, 1)*strength*sstep(np.hypot(gxv, gyv)/k, 0.05, 0.14)*mask
col = col + contours(16.0, 0.16, sstep(r, 300, 330)*(1 - sstep(r, 1150, 1210)))[..., None]
# ---------------------------------------------------------------- the Red Trench (now r 1200..1800)
tr = ramp(depth, [(40, hexc("7E2247")), (90, hexc("5E1838")), (120, hexc("3E0F2A")), (135, hexc("2A0A20"))])
mt = (sstep(r, 1165, 1235)*(1 - sstep(r, 1790, 1840)))[..., None]
col = col*(1-mt) + tr*mt*(1 + 0.3*shade[..., None])
pts = rng.uniform(-1850, 1850, (5600, 2)); pr_ = np.hypot(pts[:, 0], pts[:, 1])
pts = pts[(pr_ > 1180) & (pr_ < 1830)]
tree = cKDTree(pts)
sel = (r.ravel() > 1215) & (r.ravel() < 1800)
dd, _ = tree.query(np.stack([wx.ravel()[sel], wz.ravel()[sel]], 1), k=2)
crack = np.zeros(S*S, np.float32); crack[sel] = np.clip(1 - (dd[:, 1] - dd[:, 0])/6.5, 0, 1); crack = crack.reshape(S, S)
floor = sstep(depth, 104, 120)*sstep(r, 1235, 1275)*(1 - sstep(r, 1740, 1790))
nz = ndi.zoom(rng.random((48, 48)).astype(np.float32), S/48, order=3)[:S, :S]
veins = crack*floor*sstep(nz, 0.38, 0.62)
glow = ndi.gaussian_filter(veins, 5)*1.1
col = col + glow[..., None]*hexc("FF5A1E")*0.75 + (veins**1.5)[..., None]*hexc("FFC24A")*0.95
# ---------------------------------------------------------------- the Titan Sea (r 1800..2480): gold sand, turquoise meadows
gold = ramp(depth, [(18, hexc("FFF1B8")), (34, hexc("FFE08C")), (52, hexc("F9C963")), (70, hexc("EBAE48")), (90, hexc("D08F36"))])
meadow = ramp(depth, [(28, hexc("7FF0DC")), (50, hexc("3FD3C6")), (74, hexc("23ABB4"))])
rock = ramp(depth, [(-100, hexc("F3E2C4")), (-20, hexc("D9BF98")), (30, hexc("B99A76")), (80, hexc("94775A"))])
m_grass = sstep(matmask(2, 0.7), 0.3, 0.62)[..., None]
m_rock = sstep(matmask(3, 0.55), 0.35, 0.65)[..., None]
ti = gold*(1 - m_grass) + meadow*m_grass
ti = ti*(1 - m_rock) + rock*m_rock
# sand ripples: thin light lines that follow the slope a little
rip = np.sin((wx*0.055 + wz*0.031 + ndi.zoom(rng.random((30, 30)).astype(np.float32), S/30, order=3)[:S, :S]*9))
ti = ti*(1 + 0.035*rip[..., None]*(1 - m_grass)*(1 - m_rock))
ti = ti*(1 + 0.26*shade[..., None])
ti = ti + contours(12.0, 0.2, np.ones_like(r))[..., None]*np.array([1, 0.98, 0.9], np.float32)
mti = sstep(r, 1795, 1850)[..., None]
col = col*(1 - mti) + ti*mti
# a warm lip where the trench climbs out into the Titan Sea
lip = (sstep(r, 1770, 1805)*(1 - sstep(r, 1805, 1850)))[..., None]
col = col*(1 - 0.55*lip) + hexc("A8572E")*0.55*lip
# ---------------------------------------------------------------- the outer wall
wall = sstep(r, 2436, 2470)[..., None]
wc = hexc("3A2A1E")*(1 + 0.3*shade[..., None])
col = col*(1 - wall) + wc*wall
out_m = sstep(r, 2482, 2500)[..., None]
col = col*(1 - out_m) + hexc("10224A")*out_m
col = np.clip(col, 0, 1)
img = Image.fromarray((col*255).astype(np.uint8)).convert("RGBA")
# ---------------------------------------------------------------- lines + glyphs, drawn at 2x and scaled down (smooth edges)
Q = 2; SQ = S*Q; kq = k*Q
ov = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0)); d = ImageDraw.Draw(ov)
def P(x, z): return (SQ/2 + x*kq, SQ/2 + z*kq)
def ring(R, colr, w, dash=None, dr=d):
    box = [SQ/2-R*kq, SQ/2-R*kq, SQ/2+R*kq, SQ/2+R*kq]
    if not dash: dr.ellipse(box, outline=colr, width=w); return
    n = 720
    for i in range(0, n, 2*dash): dr.arc(box, 360*i/n, 360*(i+dash)/n, fill=colr, width=w)
for R in (510, 720, 930): ring(R, (255, 255, 255, 110), 7, dash=6)
ring(300, (255, 255, 255, 220), 10)
gl = Image.new("RGBA", (SQ, SQ), (0, 0, 0, 0)); gd = ImageDraw.Draw(gl)
ring(1200, (255, 70, 90, 255), 30, dr=gd); ring(1800, (255, 214, 96, 255), 30, dr=gd)
gl = gl.filter(ImageFilter.GaussianBlur(16))
ring(1200, (255, 96, 116, 255), 11); ring(1800, (255, 232, 150, 255), 11)
ring(2476, (16, 10, 8, 255), 14)
INK = (10, 24, 60, 255); INKT = (92, 52, 20, 255)   # the Titan Sea is drawn with a warm brown line (navy looks dirty on gold)
def blob(cx, cy, rad, fill, n=9, jit=0.22, outline=INK, w=5, squash=1.0):
    a0 = rng.uniform(0, 6.28); pts_ = []
    for i in range(n):
        a = a0 + 6.2832*i/n; rr_ = rad*(1 + rng.uniform(-jit, jit))
        pts_.append((cx + math.cos(a)*rr_, cy + math.sin(a)*rr_*squash))
    d.polygon(pts_, fill=fill); d.line(pts_ + [pts_[0]], fill=outline, width=w, joint="curve")
def star(cx, cy, rad, fill, ink):
    a0 = rng.uniform(0, 6.28); pts_ = []
    for i in range(10):
        a = a0 + 6.2832*i/10; rr_ = rad if i % 2 == 0 else rad*0.45
        pts_.append((cx + math.cos(a)*rr_, cy + math.sin(a)*rr_))
    d.polygon(pts_, fill=fill); d.line(pts_ + [pts_[0]], fill=ink, width=4, joint="curve")
def leaf(cx, cy, rad, fill, ink):
    a = rng.uniform(-0.5, 0.5) - 1.5708
    tip = (cx + math.cos(a)*rad*1.5, cy + math.sin(a)*rad*1.5)
    l = (cx + math.cos(a+2.2)*rad*0.7, cy + math.sin(a+2.2)*rad*0.7); r_ = (cx + math.cos(a-2.2)*rad*0.7, cy + math.sin(a-2.2)*rad*0.7)
    d.polygon([tip, l, r_], fill=fill); d.line([tip, l, r_, tip], fill=ink, width=4, joint="curve")
def spire(px, py, hh, fill, lit, ink):
    ww = hh*0.42
    tri = [(px, py - hh), (px - ww, py + hh*0.35), (px + ww, py + hh*0.35)]
    d.polygon(tri, fill=fill); d.polygon([(px, py - hh), (px - ww, py + hh*0.35), (px - ww*0.1, py + hh*0.35)], fill=lit)
    d.line(tri + [tri[0]], fill=ink, width=5, joint="curve")
def column(px, py, hh, ink):
    ww = hh*0.3
    d.rectangle([px - ww, py - hh, px + ww, py + hh*0.4], fill=(244, 232, 206, 255), outline=ink, width=5)
    d.rectangle([px - ww*1.35, py - hh*1.08, px + ww*1.35, py - hh*0.82], fill=(255, 208, 92, 255), outline=ink, width=4)
    d.line([(px, py - hh*0.75), (px, py + hh*0.3)], fill=(206, 190, 160, 255), width=4)
def shroom(px, py, rad, ink):
    d.ellipse([px - rad*1.6, py - rad*1.6, px + rad*1.6, py + rad*1.6], fill=(120, 230, 255, 70))
    d.ellipse([px - rad, py - rad*0.8, px + rad, py + rad*0.8], fill=(72, 204, 255, 255), outline=ink, width=4)
    d.ellipse([px - rad*0.45, py - rad*0.5, px + rad*0.1, py - rad*0.1], fill=(214, 248, 255, 255))
BIO = {  # glyph colours by where the cluster is: N kelp hills, E sunken kingdom, S whale graveyard, W glow gardens, trench, titan
    "N": dict(rock=(108, 150, 124), lit=(160, 204, 170), garden=[(255, 214, 90), (160, 230, 96), (255, 150, 80), (255, 120, 150)], kelp=[(60, 200, 110), (36, 160, 96)]),
    "E": dict(rock=(226, 172, 112), lit=(255, 216, 160), garden=[(60, 214, 200), (255, 206, 80), (255, 170, 60), (120, 236, 214)], kelp=[(60, 180, 150), (40, 150, 130)]),
    "S": dict(rock=(206, 212, 226), lit=(246, 248, 255), garden=[(190, 130, 255), (255, 170, 220), (236, 236, 250), (150, 120, 240)], kelp=[(150, 190, 200), (130, 150, 210)]),
    "W": dict(rock=(104, 82, 190), lit=(160, 136, 250), garden=[(70, 240, 230), (190, 100, 255), (255, 90, 200), (90, 160, 255)], kelp=[(130, 90, 240), (70, 220, 220)]),
    "T": dict(rock=(96, 44, 70), lit=(150, 76, 100), garden=[(255, 96, 120), (255, 150, 90), (220, 80, 160), (255, 190, 110)], kelp=[(200, 70, 110), (150, 50, 100)]),
    "G": dict(rock=(196, 150, 104), lit=(240, 206, 160), garden=[(255, 110, 130), (60, 206, 196), (255, 150, 60), (250, 250, 240), (150, 110, 240)], kelp=[(46, 176, 150), (30, 140, 130)]),
}
def biome(x, z):
    rad = math.hypot(x, z)
    if rad > 1800: return "G"
    if rad > 1200: return "T"
    if abs(x) > abs(z): return "E" if x > 0 else "W"
    return "S" if z > 0 else "N"
def c4(c): return (c[0], c[1], c[2], 255)
clusters = json.load(open("clusters_v2.json"))
# keep the map readable: small flower beds are left out, the tall and solid things are always drawn
keep = []
for kind, x, z, rad, n in clusters:
    need = {"g": 6, "k": 4, "t": 3, "p": 2, "r": 2, "m": 2, "s": 1, "c": 1}[kind]
    if n >= need: keep.append((kind, x, z, rad, n))
print("clusters drawn", len(keep), "of", len(clusters))
for kind, x, z, rad, n in sorted(keep, key=lambda c: c[2]):
    b = biome(x, z); B = BIO[b]; ink = INKT if b == "G" else INK
    big = 1.25 if b == "G" else 1.0                 # the Titan Sea's props are giants
    cx, cy = P(x, z); R = rad*kq*big
    def spot(f=0.8):
        a = rng.uniform(0, 6.28); q = math.sqrt(rng.uniform(0, 1))*R*f
        return cx + math.cos(a)*q, cy + math.sin(a)*q
    if kind == "r":
        for i in range(min(3, max(1, n // 2))):
            px, py = spot(0.55); rr_ = max(R*rng.uniform(0.26, 0.42), 9)
            blob(px, py, rr_, c4(B["rock"]), n=7, jit=0.18, outline=ink)
            blob(px - rr_*0.2, py - rr_*0.25, rr_*0.45, c4(B["lit"]), n=6, jit=0.15, outline=c4(B["lit"]), w=1)
    elif kind == "s":
        for i in range(min(4, n + 1)):
            px, py = spot(0.6); spire(px, py, max(R*rng.uniform(0.42, 0.6), 20), c4(B["rock"]), c4(B["lit"]), ink)
    elif kind == "c":
        for i in range(min(4, n + 1)):
            px, py = spot(0.6); column(px, py, max(R*rng.uniform(0.34, 0.46), 18), ink)
    elif kind == "k":
        for i in range(min(9, n + 2)):
            px, py = spot(0.85); leaf(px, py, max(R*0.2, 12), c4(B["kelp"][i % 2]), (8, 60, 44, 255) if b != "G" else ink)
    elif kind == "p":
        for i in range(min(4, n)):
            px, py = spot(0.7); star(px, py, max(R*0.3, 13), (64, 214, 190, 255), ink)
    elif kind == "g":
        for i in range(min(6, n // 2)):
            px, py = spot(0.7); rr_ = max(R*rng.uniform(0.15, 0.24), 8)
            g = B["garden"]; blob(px, py, rr_, c4(g[int(rng.integers(0, len(g)))]), n=8, jit=0.1, w=4, outline=ink)
    elif kind == "t":
        for i in range(min(4, n)):
            px, py = spot(0.7); star(px, py, max(R*0.26, 11), (255, 150, 70, 255), ink)
    elif kind == "m":
        for i in range(min(4, n)):
            px, py = spot(0.7); shroom(px, py, max(R*0.2, 10), ink)
ov = Image.alpha_composite(gl, ov).resize((S, S), Image.LANCZOS)
img = Image.alpha_composite(img, ov).convert("RGB")
img.save("mb_worldmap_v2_full.png")
# four tiles: [0..1024) and [1016..2040) on each axis
for ty, y0 in enumerate((0, 1016)):
    for tx, x0 in enumerate((0, 1016)):
        img.crop((x0, y0, x0 + 1024, y0 + 1024)).save("mb_worldmap_v2_%d%d.png" % (ty, tx))
pv = Image.new("RGB", (1100, 1100), (233, 242, 255))
small = img.resize((1024, 1024), Image.LANCZOS)
mask = Image.new("L", (1024, 1024), 0); ImageDraw.Draw(mask).ellipse([0, 0, 1023, 1023], fill=255)
pv.paste(small, (38, 38), mask); pv.save("preview_v2.png")
# a zoomed look (what the open map shows at zoom 4, at the Titan's Gate and in the north-east of the Open Sea)
def zoomshot(x, z, name, span=1240):
    cx, cy = S/2 + x*k, S/2 + z*k; hw = span*k/2
    img.crop((int(cx - hw), int(cy - hw), int(cx + hw), int(cy + hw))).resize((640, 640), Image.LANCZOS).save(name)
zoomshot(1900, 340, "zoom_titan.png"); zoomshot(560, -520, "zoom_sea.png")
print("ok")
