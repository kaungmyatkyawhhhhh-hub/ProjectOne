import numpy as np, sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
def font(sz): return ImageFont.truetype(FONT, sz)
BLACK = (20, 20, 24, 255)

def outlined(img, w=10):
    """add a thick black cartoon outline around an RGBA image's shape"""
    a = img.split()[3]
    grown = a.filter(ImageFilter.MaxFilter(w*2+1))
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base.paste(Image.new("RGBA", img.size, BLACK), mask=grown)
    base.alpha_composite(img); return base

# 1) cartoon cash bill (flies across the screen when a bed breaks)
W, H = 512, 256
img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
d.rounded_rectangle((20, 20, W-20, H-20), 26, fill=(110, 214, 92, 255))
d.rounded_rectangle((44, 44, W-44, H-44), 18, outline=(60, 160, 60, 255), width=8)
d.ellipse((W/2-62, H/2-62, W/2+62, H/2+62), fill=(150, 235, 120, 255), outline=(60, 160, 60, 255), width=8)
d.text((W/2, H/2), "$", font=font(96), fill=(50, 140, 50, 255), anchor="mm")
for cx in (86, W-86):
    d.ellipse((cx-24, H/2-24, cx+24, H/2+24), outline=(60, 160, 60, 255), width=7)
img = outlined(img, 9); img.save(f"{OUT}/cash_bill.png")

# 2) cash stack in a hexagon badge (+5 money popups)
S = 512; img = Image.new("RGBA", (S, S)); d = ImageDraw.Draw(img)
hexp = [(S/2 + 230*np.cos(np.pi/6 + k*np.pi/3), S/2 + 230*np.sin(np.pi/6 + k*np.pi/3)) for k in range(6)]
d.polygon(hexp, fill=(70, 190, 80, 255))
inner = [(S/2 + 200*np.cos(np.pi/6 + k*np.pi/3), S/2 + 200*np.sin(np.pi/6 + k*np.pi/3)) for k in range(6)]
d.polygon(inner, fill=(95, 215, 95, 255))
# isometric stack of bills (3 layers) with orange band
def slab(y, col, top):
    d.polygon([(130, y), (S/2, y-70), (S-130, y), (S/2, y+70)], fill=top)
    d.polygon([(130, y), (S/2, y+70), (S/2, y+110), (130, y+40)], fill=col)
    d.polygon([(S/2, y+70), (S-130, y), (S-130, y+40), (S/2, y+110)], fill=tuple(int(c*0.8) for c in col[:3])+(255,))
for i, y in enumerate((300, 255, 210)):
    slab(y, (60, 170, 70, 255), (140, 230, 120, 255))
d.polygon([(S/2-40, 280-70+45), (S/2+40, 280-70+5), (S/2+40, 280+40+5), (S/2-40, 280+40+45)], fill=(255, 150, 40, 255))
img = outlined(img, 12); img.save(f"{OUT}/cash_stack_hex.png")

# 3) flexed bicep icon (yellow, for +4 strength popups)
img = Image.new("RGBA", (S, S)); d = ImageDraw.Draw(img)
Y = (255, 205, 60, 255); Yd = (230, 160, 30, 255)
d.rounded_rectangle((120, 300, 400, 420), 60, fill=Y)            # forearm/upper arm base
d.ellipse((230, 200, 420, 380), fill=Y)                           # bicep bulge
d.rounded_rectangle((110, 120, 220, 360), 55, fill=Y)             # raised forearm
d.ellipse((90, 70, 240, 200), fill=Y)                             # fist
d.arc((250, 220, 400, 360), 200, 330, fill=Yd, width=14)          # muscle line
d.line((150, 150, 200, 150), fill=Yd, width=10); d.line((150, 175, 200, 175), fill=Yd, width=10)
img = outlined(img, 14); img.save(f"{OUT}/bicep.png")

# 4) multiplier cube faces X2 / X3 / X5 (put on all 6 faces of a cube part)
for txt, base, dark in (("X2", (70, 190, 70), (40, 120, 40)), ("X3", (60, 140, 240), (30, 80, 170)), ("X5", (170, 80, 240), (100, 40, 160))):
    img = Image.new("RGBA", (S, S), base + (255,)); d = ImageDraw.Draw(img)
    d.rectangle((0, 0, S-1, S-1), outline=dark + (255,), width=34)
    d.rectangle((34, 34, S-35, S-35), outline=tuple(min(255, c+60) for c in base) + (255,), width=10)
    f = font(230)
    for dx in range(-12, 13, 4):
        for dy in range(-12, 13, 4):
            d.text((S/2+dx, S/2+dy+8), txt, font=f, fill=dark + (255,), anchor="mm")
    d.text((S/2, S/2), txt, font=f, fill=(255, 255, 255, 255), anchor="mm")
    img.save(f"{OUT}/cube_{txt.lower()}.png")
# 5) X5 gets a gold sparkle variant rim
print(sorted(os.listdir(OUT)))
