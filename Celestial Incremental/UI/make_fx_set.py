# Galaxy Incremental - PLACEHOLDER particle textures (5 Nov, VFX layering pass #281): the owner's artist makes the final set;
# these keep the effects working until then (swap the ids in UIAssets.fx). White on transparent (the emitter's Color tints
# them), <= 512 px. Output: UI/roblox/fx_glowdot.png, fx_ring.png, fx_streak.png, fx_shard.png, fx_smoke4x4.png
import os, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "roblox")
os.makedirs(OUT, exist_ok=True)

def save(alpha, name):
    im = Image.new("RGBA", alpha.size, (255, 255, 255, 0))
    im.putalpha(alpha)
    im.save(os.path.join(OUT, name))

# glow dot: a soft round light with a bright core
S = 128
g = Image.new("L", (S, S), 0)
ImageDraw.Draw(g).ellipse((40, 40, 88, 88), fill=255)
halo = g.filter(ImageFilter.GaussianBlur(14))
core = Image.new("L", (S, S), 0)
ImageDraw.Draw(core).ellipse((54, 54, 74, 74), fill=255)
save(ImageChops.lighter(halo, core.filter(ImageFilter.GaussianBlur(3))), "fx_glowdot.png")

# ring: a thin bright ring with a soft glow either side (flashes, shockwaves)
S, K = 256, 4
r = Image.new("L", (S * K, S * K), 0)
d = ImageDraw.Draw(r)
d.ellipse((S * K * 0.08, S * K * 0.08, S * K * 0.92, S * K * 0.92), outline=255, width=int(S * K * 0.035))
r = r.resize((S, S), Image.LANCZOS)
save(ImageChops.lighter(r, r.filter(ImageFilter.GaussianBlur(8))), "fx_ring.png")

# streak: a long soft line, bright head on the right fading to the left (trails, fast sparks)
W, H = 512, 64
st = Image.new("L", (W, H), 0)
px = st.load()
for x in range(W):
    a = (x / W) ** 1.8
    for y in range(H):
        dy = abs(y - H / 2) / (H / 2)
        px[x, y] = int(255 * a * max(0, 1 - dy * dy * 1.6))
save(st.filter(ImageFilter.GaussianBlur(1.5)), "fx_streak.png")

# shard: a sharp crystal splinter (the Supernova's fast layer: "sharp shards = impact")
S, K = 128, 4
sh = Image.new("L", (S * K, S * K), 0)
pts = [(0.50, 0.02), (0.62, 0.40), (0.56, 0.98), (0.44, 0.60), (0.38, 0.30)]
ImageDraw.Draw(sh).polygon([(x * S * K, y * S * K) for x, y in pts], fill=255)
sh = sh.resize((S, S), Image.LANCZOS)
save(ImageChops.lighter(sh, sh.filter(ImageFilter.GaussianBlur(4)).point(lambda v: v // 2)), "fx_shard.png")

# smoke: a 4x4 flipbook (512 px, 128 per frame) of a soft puff growing and fading (embers' haze, the nebula's bloom)
F = 128
sm = Image.new("L", (F * 4, F * 4), 0)
random.seed(7)
blobs = [(random.uniform(-0.18, 0.18), random.uniform(-0.18, 0.18), random.uniform(0.18, 0.3)) for _ in range(9)]
for i in range(16):
    t = i / 15
    frame = Image.new("L", (F, F), 0)
    fd = ImageDraw.Draw(frame)
    for bx, by, br in blobs:
        rr = br * (0.55 + 0.6 * t) * F
        cx, cy = F / 2 + bx * F * (0.6 + t), F / 2 + by * F * (0.6 + t)
        fd.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=int(150 * (1 - t) ** 0.8 + 20))
    frame = frame.filter(ImageFilter.GaussianBlur(9 + 6 * t))
    sm.paste(frame, ((i % 4) * F, (i // 4) * F))
save(sm, "fx_smoke4x4.png")
print(sorted(f for f in os.listdir(OUT) if f.startswith("fx_")))
