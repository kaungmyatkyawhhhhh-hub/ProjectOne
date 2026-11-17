import os
from PIL import Image, ImageDraw, ImageFont
P = lambda k: Image.open(f"piece_{k}.png")
def nine(img, ins, W, H, s):
    l, t, r, b = ins; w, h = img.size
    L, T, R, B = [max(1, round(v * s)) for v in ins]
    out = Image.new("RGBA", (W, H))
    xs = [(0, l, 0, L), (l, w - r, L, W - R), (w - r, w, W - R, W)]
    ys = [(0, t, 0, T), (t, h - b, T, H - B), (h - b, h, H - B, H)]
    for sy0, sy1, dy0, dy1 in ys:
        for sx0, sx1, dx0, dx1 in xs:
            if dx1 > dx0 and dy1 > dy0:
                out.alpha_composite(img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS), (dx0, dy0))
    return out
def font(size):
    f = ImageFont.truetype("Fredoka.ttf", size)
    try: f.set_variation_by_name("Bold")
    except Exception: pass
    return f
INK = (26, 15, 8)
def text(canvas, xy, s, size, fill=(255, 255, 255), anchor="la", outline=True):
    d = ImageDraw.Draw(canvas); f = font(size)
    if outline:
        sw = max(2, size // 7)
        d.text((xy[0], xy[1] + max(2, size // 10)), s, font=f, fill=INK, anchor=anchor, stroke_width=sw, stroke_fill=INK)
        d.text(xy, s, font=f, fill=fill, anchor=anchor, stroke_width=sw, stroke_fill=INK)
    else:
        d.text(xy, s, font=f, fill=fill, anchor=anchor)
icons = {}
for name in ["dna", "bag", "food", "book", "badge"]:
    if os.path.exists(f"icon_{name}.png"): icons[name] = Image.open(f"icon_{name}.png")
def put_icon(canvas, name, box):
    if name not in icons: return
    ic = icons[name].copy(); ic.thumbnail((box[2], box[3]), Image.LANCZOS)
    canvas.alpha_composite(ic, (box[0] + (box[2] - ic.width) // 2, box[1] + (box[3] - ic.height) // 2))

scr = Image.open("figma_version.png").convert("RGBA")
# reuse the same stand-in world as the Figma mock: paint over its UI with a clean copy of the sky/ground
bgsrc = scr.copy()
world = Image.new("RGBA", scr.size)
d = ImageDraw.Draw(world)
for y in range(750):  # sky gradient + ground, same colours as the Figma stand-in
    if y < 420:
        k = y / 750; c = tuple(int(a + (b - a) * k) for a, b in zip((127, 200, 242), (205, 235, 247)))
    else:
        k = (y - 420) / 330; c = tuple(int(a + (b - a) * k) for a, b in zip((125, 170, 74), (78, 122, 44)))
    d.line([(0, y), (1334, y)], fill=c + (255,))
d.ellipse((600, 330, 1500, 590), fill=(110, 156, 64, 255))

scr = world
for y in range(420, 750):  # ground over the hill bottom like the mock
    pass

# DNA pill
scr.alpha_composite(nine(P(1), (175, 70, 60, 70), 250, 66, 0.31), (18, 14))
text(scr, (84, 47), "1.02M", 26, (140, 245, 192), "lm")
text(scr, (226, 47), "x2", 18, (255, 210, 122), "rm")
# menu buttons
for i, (label, ic, k) in enumerate([("Shop", "bag", 2), ("Diet", "food", 3), ("Index", "book", 3)]):
    b = nine(P(k), (60, 60, 60, 65), 80, 76, 0.3); x, y = 18 + i * 86, 92
    scr.alpha_composite(b, (x, y)); put_icon(scr, ic, (x + 22, y + 12, 36, 34))
    text(scr, (x + 40, y + 58), label, 15, anchor="mm")
# status
sx = (1334 - 480) // 2
scr.alpha_composite(nine(P(0), (90, 80, 90, 70), 480, 140, 0.5), (sx, 12))
text(scr, (667, 44), "Cosmic Being  ·  Gen 8", 25, (255, 244, 224), "mm")
def bar(x, y, w, pct, top, label):
    scr.alpha_composite(nine(P(8), (50, 45, 50, 45), w, 30, 0.3), (x, y))
    fw = int((w - 20) * pct); fill = Image.new("RGBA", (max(fw, 14), 16))
    ImageDraw.Draw(fill).rounded_rectangle((0, 0, fill.width - 1, 15), 8, fill=top)
    ImageDraw.Draw(fill).rounded_rectangle((3, 2, fill.width - 4, 6), 3, fill=(255, 255, 255, 110))
    scr.alpha_composite(fill, (x + 10, y + 7)); text(scr, (x + w // 2, y + 15), label, 14, anchor="mm")
bar(sx + 40, 62, 400, 0.35, (245, 170, 50, 255), "Adult  ·  16s left")
bar(sx + 40, 96, 400, 1.0, (110, 205, 60, 255), "Fully evolved!  Try an Extinction Event")
# shop window
wx, wy = (1334 - 640) // 2, 196
scr.alpha_composite(nine(P(6), (70, 115, 70, 75), 640, 486, 0.95), (wx, wy))
text(scr, (wx + 40, wy + 52), "Shop", 32, (255, 231, 168), "lm")
cl = P(4).copy(); cl.thumbnail((58, 58), Image.LANCZOS); scr.alpha_composite(cl, (wx + 640 - 76, wy + 22))
rows = [("Bigger Brain  Lv 3", "+1 DNA every second", 2, "1.2K DNA"), ("Faster Aging  Lv 1", "Shorter lives, faster generations", 2, "640 DNA"),
        None, ("2x DNA", "Double DNA forever", 5, "Owned"), ("VIP", "+25% DNA and golden graves", 2, "R$ 299")]
ry = wy + 106
for r in rows:
    if r is None:
        text(scr, (wx + 46, ry + 14), "Robux Store", 19, (255, 210, 122), "lm"); ry += 34; continue
    scr.alpha_composite(nine(P(7), (60, 55, 60, 55), 560, 76, 0.42), (wx + 40, ry))
    text(scr, (wx + 64, ry + 27), r[0], 21, (255, 244, 224), "lm")
    text(scr, (wx + 64, ry + 52), r[1], 14, (205, 183, 154), "lm", outline=False)
    bt = r[2]
    if bt == 5:  # stone "owned": stone face, no padlock in the middle (crop its rim only)
        bimg = nine(P(3), (60, 60, 60, 65), 140, 52, 0.22).convert("LA").convert("RGBA")
    else:
        bimg = nine(P(bt), (60, 60, 60, 65), 140, 52, 0.22)
    scr.alpha_composite(bimg, (wx + 40 + 560 - 156, ry + 12))
    text(scr, (wx + 40 + 560 - 86, ry + 38), r[3], 17 if len(r[3]) > 6 else 19, anchor="mm")
    ry += 80
scr.convert("RGB").save("chatgpt_version.png")
print("ok", sorted(icons))
