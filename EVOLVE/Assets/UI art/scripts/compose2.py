# v2: sizes chosen in PHONE POINTS x2 (this 1334x750 mock = a 667x375 pt phone). Min text 14 pt = 28 px.
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
exec(open("compose.py").read().split("scr = Image.open")[0])  # reuse nine(), text(), font(), icons
P = lambda k: Image.open(f"piece_{k}.png"); C = lambda k: Image.open(f"card_{k}.png"); I = lambda n: Image.open(f"item_{n}.png")
def world():
    w = Image.new("RGBA", (1334, 750)); d = ImageDraw.Draw(w)
    for y in range(750):
        if y < 420: k = y / 420; c = tuple(int(a + (b - a) * k) for a, b in zip((127, 200, 242), (205, 235, 247)))
        else: k = (y - 420) / 330; c = tuple(int(a + (b - a) * k) for a, b in zip((125, 170, 74), (78, 122, 44)))
        d.line([(0, y), (1334, y)], fill=c + (255,))
    d.ellipse((600, 330, 1500, 590), fill=(110, 156, 64, 255)); return w
def fit(img, w, h):
    im = img.copy(); im.thumbnail((w, h), Image.LANCZOS); return im
def robux(scr, x, y, s):  # stand-in for Roblox's own Robux glyph (the game uses the real one)
    d = ImageDraw.Draw(scr); import math
    pts = [(x + s/2 + s/2*math.cos(math.radians(a)), y + s/2 + s/2*math.sin(math.radians(a))) for a in range(-90, 270, 60)]
    d.polygon(pts, outline=INK, width=8); d.polygon(pts, outline=(255,255,255), width=4)
    q = s * 0.3; d.rectangle((x+s/2-q/2, y+s/2-q/2, x+s/2+q/2, y+s/2+q/2), outline=(255,255,255), width=4)
def hud(scr):
    scr.alpha_composite(nine(P(1), (175, 70, 60, 70), 300, 80, 0.38), (20, 14))
    text(scr, (102, 55), "1.02M", 36, (140, 245, 192), "lm")
    text(scr, (296, 55), "x2", 26, (255, 210, 122), "rm")
    for i, (label, ic, k) in enumerate([("Shop", "bag", 2), ("Diet", "food", 3), ("Index", "book", 3)]):
        x, y = 20 + i * 102, 106
        scr.alpha_composite(nine(P(k), (60, 60, 60, 65), 96, 96, 0.36), (x, y)); put_icon(scr, ic, (x + 20, y + 10, 56, 50))
        text(scr, (x + 48, y + 76), label, 22, anchor="mm")
    sx = (1334 - 600) // 2
    scr.alpha_composite(nine(P(0), (90, 80, 90, 70), 600, 172, 0.6), (sx, 10))
    text(scr, (667, 52), "Cosmic Being  ·  Gen 8", 34, (255, 244, 224), "mm")
    for j, (pct, col, label) in enumerate([(0.35, (245, 170, 50, 255), "Adult  ·  16s left"), (1.0, (110, 205, 60, 255), "Fully evolved!")]):
        x, y, w = sx + 46, 80 + j * 44, 508
        scr.alpha_composite(nine(P(8), (50, 45, 50, 45), w, 40, 0.38), (x, y))
        fw = int((w - 26) * pct); f = Image.new("RGBA", (max(fw, 20), 22)); dd = ImageDraw.Draw(f)
        dd.rounded_rectangle((0, 0, f.width - 1, 21), 11, fill=col); dd.rounded_rectangle((4, 3, f.width - 5, 8), 3, fill=(255, 255, 255, 110))
        scr.alpha_composite(f, (x + 13, y + 9)); text(scr, (x + w // 2, y + 20), label, 22, anchor="mm")
def card(scr, x, y, frame, item, name, price, state="buy", info=""):
    w, h = 220, 372
    fr = nine(C(frame), (90, 90, 90, 90), w, h, 0.42)
    if state == "owned": fr = ImageEnhance.Brightness(fr).enhance(0.6)
    scr.alpha_composite(fr, (x, y))
    it = fit(I(item), 150, 132)
    if state == "owned": it = ImageEnhance.Color(ImageEnhance.Brightness(it).enhance(0.65)).enhance(0.4)
    scr.alpha_composite(it, (x + (w - it.width) // 2, y + 26 + (132 - it.height) // 2))
    text(scr, (x + w // 2, y + 190), name, 30, (255, 244, 224), "mm")
    text(scr, (x + w // 2, y + 230), info, 24, (225, 205, 175), "mm", outline=False)
    if state == "owned":
        text(scr, (x + w // 2, y + 306), "Owned", 30, (170, 160, 150), "mm"); return
    bx, by, bw, bh = x + 20, y + 272, w - 40, 66
    scr.alpha_composite(nine(P(2), (60, 60, 60, 65), bw, bh, 0.3), (bx, by))
    if price.startswith("R"):
        robux(scr, bx + 34, by + 15, 34); text(scr, (bx + bw // 2 + 22, by + 34), price[2:], 32, anchor="mm")
    else:
        text(scr, (bx + bw // 2, by + 34), price, 30, anchor="mm")
def tab(scr, x, y, label, on):
    t = nine(C(3), (130, 70, 130, 70), 230, 64, 0.38)
    if not on: t = ImageEnhance.Brightness(t).enhance(0.55)
    scr.alpha_composite(t, (x, y)); text(scr, (x + 115, y + 33), label, 28, (255, 231, 168) if on else (190, 175, 155), "mm")

# --- screen 1: HUD only
s1 = world(); hud(s1); s1.convert("RGB").save("v2_hud.png")
# --- screen 2: Shop open (dim behind, window over the HUD)
s2 = world(); hud(s2)
s2.alpha_composite(Image.new("RGBA", s2.size, (10, 6, 3, 150)))
wx, wy, ww, wh = 107, 40, 1120, 690
s2.alpha_composite(nine(P(6), (70, 115, 70, 75), ww, wh, 1.15), (wx, wy))
text(s2, (wx + 52, wy + 64), "Shop", 50, (255, 231, 168), "lm")
cl = fit(P(4), 84, 84); s2.alpha_composite(cl, (wx + ww - 108, wy + 22))
tab(s2, wx + 58, wy + 150, "Upgrades", False); tab(s2, wx + 304, wy + 150, "Robux", True)
cards = [(1, "crown", "VIP", "R$299", "buy", "+25% DNA"), (0, "dna2", "2x DNA", "R$149", "owned", "Forever"), (0, "stopwatch", "Fast Gens", "R$199", "buy", "Faster lives"),
         (2, "skip", "Skip 5 Gens", "R$25", "buy", "5 lives now")]
for i, (fr, it, nm, pr, stt, inf) in enumerate(cards):
    card(s2, wx + 58 + i * 236, wy + 238, fr, it, nm, pr, stt, inf)
# 5th card cut off at the edge = "scroll for more"
peek = Image.new("RGBA", (1334, 750)); card(peek, wx + 58 + 4 * 236, wy + 238, 2, "jar", "DNA Pack", "R$19", "buy", "10 min DNA")
peek = peek.crop((0, 0, wx + ww - 46, 750)); s2.alpha_composite(peek)
s2.convert("RGB").save("v2_shop.png")
# stacked for review
out = Image.new("RGB", (1334, 1520), (24, 18, 12)); out.paste(s1.convert("RGB"), (0, 0)); out.paste(s2.convert("RGB"), (0, 770)); out.save("v2_compare.png")
print("ok")
