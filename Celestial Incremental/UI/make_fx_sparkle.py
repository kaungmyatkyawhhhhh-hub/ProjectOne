# Galaxy Incremental - our own world sparkle for ParticleEmitters (5 Nov, checklist #281: no stock Roblox textures).
# White on transparent (the emitter's Color tints it), 256 px (<=512 rule): a bright core, a soft round glow and
# 4 thin tapered rays (the UI sparkle's 4-point shape, soft-edged so it reads at particle size). Output: UI/roblox/fx_sparkle.png
import os, math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "roblox", "fx_sparkle.png")
S, K = 256, 4  # size, supersample
B = S * K
c = B / 2

# rays: 4-point star, long and thin (like the UI sparkle, sharper waist)
rays = Image.new("L", (B, B), 0)
r, w = B * 0.48, B * 0.035
ImageDraw.Draw(rays).polygon([(c, c - r), (c + w, c - w), (c + r, c), (c + w, c + w), (c, c + r), (c - w, c + w), (c - r, c), (c - w, c - w)], fill=255)
rays = rays.resize((S, S), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))

# core + glow
core = Image.new("L", (S, S), 0)
ImageDraw.Draw(core).ellipse((S / 2 - 14, S / 2 - 14, S / 2 + 14, S / 2 + 14), fill=255)
core = core.filter(ImageFilter.GaussianBlur(5))
glow = Image.new("L", (S, S), 0)
ImageDraw.Draw(glow).ellipse((S / 2 - 46, S / 2 - 46, S / 2 + 46, S / 2 + 46), fill=120)
glow = glow.filter(ImageFilter.GaussianBlur(26))

a = ImageChops.lighter(ImageChops.lighter(rays, core), glow)
im = Image.new("RGBA", (S, S), (255, 255, 255, 0))
im.putalpha(a)
im.save(OUT)
# a preview on the game's dark sky, tinted gold, for checking by eye
prev = Image.new("RGBA", (S, S), (14, 10, 30, 255))
gold = Image.new("RGBA", (S, S), (255, 220, 140, 0)); gold.putalpha(a)
Image.alpha_composite(prev, gold).save(OUT.replace(".png", "_preview.png"))
print(OUT)
