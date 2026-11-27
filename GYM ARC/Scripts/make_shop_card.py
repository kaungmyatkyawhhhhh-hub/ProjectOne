"""Shop card from a magenta-keyed Studio shot: cut-out + thick dark outline + soft glow on a themed radial gradient.
Popular-game style (Pet Simulator shop, owner's recording 27 Nov): the item is a clean cut-out, never a world screenshot.
usage: python make_shop_card.py shot.jpg out.png "#E9FBFF" "#3FA9E6" [size] [x0,y0,x1,y1 crop of the shot]
"""
import sys, random
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

src, out, inner, outer = sys.argv[1:5]
S = int(sys.argv[5]) if len(sys.argv) > 5 else 512
box = tuple(int(v) for v in sys.argv[6].split(",")) if len(sys.argv) > 6 else None
hexc = lambda h: np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], float)

src_im = Image.open(src).convert("RGB")
im = np.asarray(src_im.crop(box) if box else src_im).astype(float)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
key = np.clip(((np.minimum(r, b) - g) - 60) / 80, 0, 1)  # 1 = magenta background
alpha = 1 - key
# despill: pull magenta fringe toward the pixel's own green level
im[..., 0] = np.where(key > 0.05, np.minimum(r, g + (r - g) * (1 - key)), r)
im[..., 2] = np.where(key > 0.05, np.minimum(b, g + (b - g) * (1 - key)), b)
# shrink the mask 2 px so the magenta fringe hides under the outline
a8 = Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(3))
a8 = a8.point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(0.7))
fig = Image.fromarray(im.astype(np.uint8)).convert("RGBA")
fig.putalpha(a8)
fig = fig.crop(a8.point(lambda v: 255 if v > 40 else 0).getbbox())

# fit the figure into the card (88% of height)
pad = int(S * 0.07)
scale = min((S - 2 * pad) / fig.width, (S * 0.88) / fig.height)
fig = fig.resize((max(1, int(fig.width * scale)), max(1, int(fig.height * scale))), Image.LANCZOS)
x0, y0 = (S - fig.width) // 2, S - fig.height - int(S * 0.05)

# background: soft radial gradient, no spiky rays (owner rule)
yy, xx = np.mgrid[0:S, 0:S]
d = np.clip(np.hypot(xx - S / 2, yy - S * 0.45) / (S * 0.72), 0, 1)[..., None] ** 1.3
bg = hexc(inner) * (1 - d) + hexc(outer) * d
card = Image.fromarray(bg.astype(np.uint8)).convert("RGBA")

# soft sparkles in the background
rnd = random.Random(7)
sp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
dr = ImageDraw.Draw(sp)
for _ in range(14):
    cx, cy, rr = rnd.uniform(0, S), rnd.uniform(0, S * 0.8), rnd.uniform(S * 0.006, S * 0.018)
    dr.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=(255, 255, 255, rnd.randint(110, 200)))
card.alpha_composite(sp.filter(ImageFilter.GaussianBlur(S * 0.003)))

layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
layer.paste(fig, (x0, y0), fig)
A = layer.getchannel("A")

# ground shadow
sh = Image.new("L", (S, S), 0)
ImageDraw.Draw(sh).ellipse((S * 0.25, S * 0.9, S * 0.75, S * 0.985), fill=90)
card.alpha_composite(Image.merge("RGBA", (*[Image.new("L", (S, S), 20)] * 3, sh.filter(ImageFilter.GaussianBlur(S * 0.02)))))

# white glow halo behind the figure
glow = A.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(S * 0.035)).point(lambda v: min(255, int(v * 1.4)))
card.alpha_composite(Image.merge("RGBA", (*[Image.new("L", (S, S), 255)] * 3, glow)))

# thick dark outline (the popular-game item look)
ow = max(3, int(S * 0.014)) * 2 + 1
outline = A.point(lambda v: 255 if v > 60 else 0).filter(ImageFilter.MaxFilter(ow)).filter(ImageFilter.GaussianBlur(0.8))
card.alpha_composite(Image.merge("RGBA", (Image.new("L", (S, S), 18), Image.new("L", (S, S), 18), Image.new("L", (S, S), 30), outline)))
card.alpha_composite(layer)
card.convert("RGB").save(out)
assert card.size == (S, S)
print("ok", out, fig.size)
