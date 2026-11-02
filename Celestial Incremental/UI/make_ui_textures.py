# Galaxy Incremental - the v12 UI's texture pieces as images for Roblox (2 Nov). White shapes are tinted in Roblox
# (ImageColor3 / UIGradient), so one image serves several colours. Output: UI/roblox/.
import os, math
from PIL import Image, ImageDraw, ImageFilter
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "roblox")
os.makedirs(OUT, exist_ok=True)

# button stripes (v12 .stripes: repeating-linear-gradient(115deg, white .13 0-7px, clear 7-18px)); white, the alpha is
# set in Roblox (ImageTransparency 0.87). Drawn at 1:1 px, 512x128, used at its own size inside a clipped button.
W, H = 512, 128
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
px = im.load()
d = (math.sin(math.radians(115)), -math.cos(math.radians(115)))  # CSS gradient direction (x right, y down)
for y in range(H):
    for x in range(W):
        s = (x * d[0] + y * d[1]) % 18.0
        if s < 7.0:
            px[x, y] = (255, 255, 255, 255)
im.save(os.path.join(OUT, "ui_stripes.png"))

# 9-slice soft glow (the window's breathing neon glow, v12 'breathe'): a blurred rounded rectangle ring, 128 px,
# slice centre 48..80
S = 128
g = Image.new("L", (S, S), 0)
ImageDraw.Draw(g).rounded_rectangle((28, 28, S - 28, S - 28), radius=10, fill=255)
g = g.filter(ImageFilter.GaussianBlur(11))
glow = Image.new("RGBA", (S, S), (255, 255, 255, 0))
glow.putalpha(g)
glow.save(os.path.join(OUT, "ui_glow9.png"))

# soft round glow behind each icon (v12 'iglow' drop-shadow glow, tinted per icon)
S = 128
g = Image.new("L", (S, S), 0)
ImageDraw.Draw(g).ellipse((30, 30, S - 30, S - 30), fill=255)
g = g.filter(ImageFilter.GaussianBlur(16))
im = Image.new("RGBA", (S, S), (255, 255, 255, 0)); im.putalpha(g)
im.save(os.path.join(OUT, "ui_softglow.png"))

# 4-point sparkle (v12 .sp clip-path polygon)
S = 64
im = Image.new("RGBA", (S * 4, S * 4), (0, 0, 0, 0))
pts = [(50, 0), (60, 40), (100, 50), (60, 60), (50, 100), (40, 60), (0, 50), (40, 40)]
ImageDraw.Draw(im).polygon([(x / 100 * S * 4, y / 100 * S * 4) for x, y in pts], fill=(255, 255, 255, 255))
im.resize((S, S), Image.LANCZOS).save(os.path.join(OUT, "ui_sparkle.png"))

# mote (v12 .mote: 5 px dot #fff6c0 + 4 px #ffd25a glow); drawn white-gold at 32 px
S = 32
g = Image.new("L", (S, S), 0)
ImageDraw.Draw(g).ellipse((9, 9, S - 9, S - 9), fill=255)
halo = g.filter(ImageFilter.GaussianBlur(4))
core = Image.new("L", (S, S), 0); ImageDraw.Draw(core).ellipse((12, 12, S - 12, S - 12), fill=255)
a = Image.eval(Image.merge("L", [halo]), lambda v: v)
im = Image.new("RGBA", (S, S), (255, 210, 90, 0))
im.putalpha(Image.composite(core, halo, core))
base = Image.new("RGBA", (S, S), (255, 210, 90, 0)); base.putalpha(halo)
top = Image.new("RGBA", (S, S), (255, 246, 192, 0)); top.putalpha(core)
Image.alpha_composite(base, top).save(os.path.join(OUT, "ui_mote.png"))

# the top counter's slanted plate (v12: clip-path polygon(0 0,95% 0,100% 50%,95% 100%,0 100%)), white, 2x of 230x40
W, H = 460, 80
im = Image.new("RGBA", (W * 4, H * 4), (0, 0, 0, 0))
ImageDraw.Draw(im).polygon([(0, 0), (0.95 * W * 4, 0), (W * 4, H * 2), (0.95 * W * 4, H * 4), (0, H * 4)], fill=(255, 255, 255, 255))
im.resize((W, H), Image.LANCZOS).save(os.path.join(OUT, "ui_plate.png"))

# header texture (already made for v6/v12): copy
Image.open(os.path.join(os.path.dirname(OUT), "tex_header_orange.png")).convert("RGB").save(os.path.join(OUT, "ui_header_orange.png"))
print(sorted(os.listdir(OUT)))

# tutorial arrow (points down): gold fill, near-black outline, a lighter top band (the kit's look), 128 px
S = 512
im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dr = ImageDraw.Draw(im)
outer = [(176, 20), (336, 20), (336, 250), (450, 250), (256, 480), (62, 250), (176, 250)]
inner = [(200, 44), (312, 44), (312, 274), (396, 274), (256, 440), (116, 274), (200, 274)]
dr.polygon(outer, fill=(8, 6, 12, 255))
dr.polygon(inner, fill=(255, 196, 64, 255))
band = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(band).polygon(inner, fill=(255, 241, 192, 255))
mask = Image.new("L", (S, S), 0); ImageDraw.Draw(mask).rectangle((0, 0, 228, S), fill=255)
im.paste(band, (0, 0), Image.composite(band.split()[3], Image.new("L", (S, S), 0), mask))
im.resize((128, 128), Image.LANCZOS).save(os.path.join(OUT, "ui_arrow.png"))
print("arrow ok")
