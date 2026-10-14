import numpy as np, os, sys
from PIL import Image, ImageDraw, ImageFilter
S = 256; OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
y, x = (np.mgrid[0:S, 0:S] + 0.5) / S * 2 - 1
r = np.sqrt(x*x + y*y); ang = np.arctan2(y, x)
rng = np.random.default_rng(3)

def save(name, a, rgb=(1, 1, 1)):
    a = np.clip(a, 0, 1)
    rgb = np.asarray(rgb, float)
    if rgb.ndim == 1: rgb = np.ones((S, S, 3))*rgb
    img = np.dstack([np.clip(rgb, 0, 1), a]); Image.fromarray((img*255).astype(np.uint8), "RGBA").save(f"{OUT}/{name}.png")

def blur(a, k): return np.asarray(Image.fromarray((np.clip(a, 0, 1)*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(k)), float)/255
def noise(scale, seed):
    g = np.random.default_rng(seed).random((scale+1, scale+1))
    return np.asarray(Image.fromarray((g*255).astype(np.uint8)).resize((S, S), Image.BICUBIC), float)/255

# 1 soft glow
save("glow", np.exp(-(r/0.45)**2))
# 2 spark: 4-point star
save("spark", np.clip(np.exp(-(np.abs(x)/0.04))*np.exp(-(np.abs(y)/0.7)) + np.exp(-(np.abs(y)/0.04))*np.exp(-(np.abs(x)/0.7)) + np.exp(-(r/0.12)**2), 0, 1))
# 3 star5
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
pts = []
for i in range(10):
    a0 = -np.pi/2 + i*np.pi/5; rad = 115 if i % 2 == 0 else 46
    pts.append((128+rad*np.cos(a0), 132+rad*np.sin(a0)))
d.polygon(pts, fill=255)
a = np.asarray(img, float)/255
save("star", np.clip(blur(a, 1) + blur(a, 10)*0.6, 0, 1))
# 4 flame (teardrop, hot core)
fy = (y+0.15); w = 0.45*(1-np.clip((-fy+0.85)/1.7, 0, 1))**0.5
n = noise(6, 4)
shape = np.clip(1 - np.abs(x)/(np.maximum(0.62*np.sqrt(np.clip((fy+1)/1.8, 0, 1))*(1-np.clip(-fy, 0, 1)*0.9), 1e-3)), 0, 1)
shape = blur(shape*(0.75+0.5*n), 3)
core = blur(np.clip(shape*1.6-0.8, 0, 1), 4)
save("flame", shape, np.dstack([np.ones((S, S)), 0.55+0.45*core, 0.2+0.8*core]))
save("flame_white", shape)
# 5 smoke (soft noisy puff)
sm = np.exp(-(r/0.6)**2)*(0.55+0.6*noise(5, 8))
save("smoke", blur(np.clip(sm-0.15, 0, 1), 6))
# 6 feather
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
pts = []
for t in np.linspace(0, 1, 60):
    wv = 34*np.sin(np.pi*t**0.8)
    pts.append((128 + wv, 230 - 210*t))
pts += [(128 - (p[0]-128), p[1]) for p in pts[::-1]]
d.polygon(pts, fill=230)
a = np.asarray(img, float)/255
barb = 0.75 + 0.25*np.sin((y*60 + np.abs(x)*40))
a = a*barb; a[(np.abs(x) < 0.015) & (y > -0.85)] = 1
save("feather", blur(a, 1))
# 7 ember
save("ember", np.clip(np.exp(-(r/0.12)**2)*1.2 + np.exp(-(r/0.4)**2)*0.35, 0, 1), np.dstack([np.ones((S, S)), 0.6+0.4*np.exp(-(r/0.15)**2), 0.25+0.75*np.exp(-(r/0.1)**2)]))
# 8 snowflake
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
for i in range(6):
    a0 = i*np.pi/3; ex, ey = 128+110*np.cos(a0), 128+110*np.sin(a0)
    d.line((128, 128, ex, ey), fill=255, width=9)
    for f in (0.45, 0.7):
        bx, by = 128+110*f*np.cos(a0), 128+110*f*np.sin(a0)
        for s in (-1, 1):
            d.line((bx, by, bx+38*np.cos(a0+s*0.8), by+38*np.sin(a0+s*0.8)), fill=255, width=7)
d.ellipse((108, 108, 148, 148), fill=255)
save("snowflake", np.clip(blur(np.asarray(img, float)/255, 1.5)*1.1 + np.exp(-(r/0.3)**2)*0.3, 0, 1))
# 9 ice shard
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
d.polygon([(128, 8), (170, 120), (145, 248), (110, 248), (86, 120)], fill=200)
d.polygon([(128, 8), (170, 120), (128, 150)], fill=255)
save("ice_shard", blur(np.asarray(img, float)/255, 1.2), np.dstack([0.8+0.2*np.ones((S, S)), 0.95*np.ones((S, S)), np.ones((S, S))]))
# 10 coin (gold, colored)
c = np.clip((0.82 - r)/0.03, 0, 1); rim = np.clip((r-0.62)/0.04, 0, 1)*c
face = 0.75 + 0.25*np.clip(-(x+y)*0.7, -1, 1)
rgb = np.dstack([np.ones((S, S))*1.0*face, 0.78*face, 0.18*face])
rgb = rgb*(1-rim[..., None]*0.35)
sym = (np.abs(x) < 0.08) & (np.abs(y) < 0.35) | (np.abs(y) < 0.08) & (np.abs(x) < 0.25)
rgb[sym] = [1, 0.93, 0.55]
save("coin", c, rgb)
# 11 bubble
save("bubble", np.clip(np.exp(-((r-0.78)/0.06)**2) + np.exp(-(((x+0.3)**2+(y+0.35)**2)/0.015))*0.9 + 0.06*(r < 0.8), 0, 1))
# 12 ring (shockwave)
save("ring", np.exp(-((r-0.8)/0.07)**2) + 0.25*np.exp(-((r-0.7)/0.15)**2))
# 13 petal (sakura)
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
d.ellipse((60, 40, 196, 230), fill=255); d.polygon([(128, 78), (100, 30), (156, 30)], fill=0)
a = np.asarray(img, float)/255
save("petal", blur(a, 2), np.dstack([np.ones((S, S)), 0.72+0.2*(y+1)/2, 0.82+0.15*(y+1)/2]))
# 14 claw slash (3 curved streaks)
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
for off in (-50, 0, 50):
    pts = [(60+off+t*120 + 18*np.sin(t*np.pi), 30+t*200) for t in np.linspace(0, 1, 30)]
    for i in range(len(pts)-1):
        wv = int(2 + 12*np.sin(np.pi*i/len(pts)))
        d.line((pts[i], pts[i+1]), fill=255, width=wv)
save("claw_slash", np.clip(blur(np.asarray(img, float)/255, 2)*1.2, 0, 1))
# 15 lightning
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
def bolt(x0, y0, x1, y1, w, depth):
    pts = [(x0, y0)]
    for t in np.linspace(0, 1, 10)[1:-1]:
        pts.append((x0+(x1-x0)*t + rng.normal(0, 18), y0+(y1-y0)*t))
    pts.append((x1, y1)); d.line(pts, fill=255, width=w)
    if depth: 
        i = rng.integers(2, 7); bolt(pts[i][0], pts[i][1], pts[i][0]+rng.normal(0, 60), pts[i][1]+70, max(2, w-3), depth-1)
bolt(128, 5, 128, 250, 7, 2)
a = np.asarray(img, float)/255
save("lightning", np.clip(a + blur(a, 6)*1.5, 0, 1))
# 16 rune circle
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
d.ellipse((8, 8, 248, 248), outline=255, width=6); d.ellipse((36, 36, 220, 220), outline=255, width=3)
for i in range(12):
    a0 = i*np.pi/6; cx, cy = 128+106*np.cos(a0), 128+106*np.sin(a0)
    d.regular_polygon((cx, cy, 9), 3 + i % 3, rotation=i*20, outline=255)
for i in range(6):
    a0 = i*np.pi/3; d.line((128+92*np.cos(a0), 128+92*np.sin(a0), 128+92*np.cos(a0+2*np.pi/3), 128+92*np.sin(a0+2*np.pi/3)), fill=255, width=3)
a = np.asarray(img, float)/255
save("rune_circle", np.clip(a + blur(a, 4)*0.8, 0, 1))
# 17 light rays
rays = np.clip(np.cos(ang*12)*0.5+0.5, 0, 1)**6 * np.exp(-r*1.4) + np.exp(-(r/0.25)**2)*0.6
save("rays", np.clip(rays*(r < 1), 0, 1))
# 18 chinese cloud swirl
img = Image.new("L", (S, S), 0); d = ImageDraw.Draw(img)
for cx, cy, rr in [(90, 140, 50), (150, 120, 60), (200, 150, 38), (60, 165, 32)]:
    d.ellipse((cx-rr, cy-rr, cx+rr, cy+rr), fill=255)
for cx, cy, rr in [(150, 120, 38), (90, 140, 28)]:
    d.arc((cx-rr, cy-rr, cx+rr, cy+rr), 180, 450, fill=120, width=6)
save("cloud", blur(np.asarray(img, float)/255, 2))
# 19 trail texture (for Trails/Beams): bright core, soft edges, wispy
u = (x+1)/2; vv = np.abs(y)
tr = np.exp(-(vv/0.35)**2)*(0.7 + 0.3*noise(8, 12)) + np.exp(-(vv/0.08)**2)*0.6
save("trail", np.clip(tr, 0, 1))
# 20 energy beam (swirly)
bm = np.exp(-(vv/0.5)**2)*(0.5+0.5*np.sin((x*6 + y*3)*np.pi)**2)
save("energy", np.clip(bm*1.2, 0, 1))
# 21 dust
save("dust", blur(np.clip(np.exp(-(r/0.55)**2)*(0.4+0.8*noise(10, 15)) - 0.2, 0, 1), 3))
# 22 orb (planet-like small sphere with shading)
sh = np.clip(1 - r, 0, 1)**0.3 * (r < 0.8)
light = np.clip(0.6 - (x+0.3)*0.5 - (y+0.3)*0.5, 0.2, 1)
save("orb", np.clip(sh*1.3, 0, 1)*(r < 0.8) + np.exp(-((r-0.8)/0.08)**2)*0.6, np.dstack([light]*3))
print("sprites:", len(os.listdir(OUT)))
