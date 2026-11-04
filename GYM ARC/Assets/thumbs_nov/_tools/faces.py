# Our own Roblox-style faces (1024x1024 = the head's front, width x height). RGBA colour + RGB glow (emission) maps.
import sys, math
from PIL import Image, ImageDraw, ImageFilter
OUT = sys.argv[1]
N = 1024
PURPLE = (176, 76, 255); TEAL = (40, 240, 215); INK = (24, 16, 14, 255)

def canvas(): return Image.new("RGBA", (N, N), (0, 0, 0, 0)), Image.new("RGB", (N, N), (0, 0, 0))
def thick_arc(d, box, a0, a1, w, col):
    d.arc(box, a0, a1, fill=col, width=w)
def eye_glow(img, glow, cx, cy, rx, ry, col, slant=0):
    d = ImageDraw.Draw(img); g = ImageDraw.Draw(glow)
    # dark socket ring, the bright iris, the white-hot middle
    d.ellipse((cx-rx-10, cy-ry-10, cx+rx+10, cy+ry+10), fill=INK)
    d.ellipse((cx-rx, cy-ry, cx+rx, cy+ry), fill=col + (255,))
    d.ellipse((cx-rx*0.28, cy-ry*0.3, cx+rx*0.28, cy+ry*0.3), fill=(255, 255, 255, 255))
    g.ellipse((cx-rx, cy-ry, cx+rx, cy+ry), fill=col)

def bacon_smirk():
    img, glow = canvas(); d = ImageDraw.Draw(img)
    ey = 440; ex = 150
    # glowing eyes: viewer's left purple, right teal (slightly narrowed = confident)
    eye_glow(img, glow, N/2 - ex, ey, 46, 64, PURPLE)
    eye_glow(img, glow, N/2 + ex, ey, 46, 64, TEAL)
    # brows: confident, the right one a bit raised
    d.line((N/2-ex-80, ey-120, N/2-ex+60, ey-95), fill=INK, width=30)
    d.line((N/2+ex-60, ey-112, N/2+ex+80, ey-140), fill=INK, width=30)
    # smirk: flat on the left, curling up on the right
    pts = []
    for i in range(41):
        t = i / 40
        x = N/2 - 130 + 270 * t
        y = 660 - (55 * (t ** 2.4))
        pts.append((x, y))
    d.line(pts, fill=INK, width=24, joint="curve")
    d.ellipse((pts[-1][0]-12, pts[-1][1]-12, pts[-1][0]+12, pts[-1][1]+12), fill=INK)
    d.ellipse((pts[0][0]-12, pts[0][1]-12, pts[0][0]+12, pts[0][1]+12), fill=INK)
    return img, glow

def giant_strain():
    img, glow = canvas(); d = ImageDraw.Draw(img)
    ey = 450; ex = 150
    # angry narrowed eyes (slanted lids)
    for s in (-1, 1):
        cx = N/2 + s*ex
        d.ellipse((cx-44, ey-46, cx+44, ey+50), fill=INK)
        d.polygon([(cx - 80*s, ey - 120), (cx + 70*s, ey - 40), (cx + 70*s, ey - 16), (cx - 80*s, ey - 86)], fill=(0,0,0,0))
    # lids cut: redraw skin-coloured wedge via transparent then the brows on top
    for s in (-1, 1):
        cx = N/2 + s*ex
        d.line((cx + 105*s, ey - 135, cx - 55*s, ey - 55), fill=INK, width=36)
    # gritted teeth
    mx, my, mw, mh = N/2, 680, 300, 110
    d.rounded_rectangle((mx-mw/2, my-mh/2, mx+mw/2, my+mh/2), radius=40, fill=(250, 248, 240, 255), outline=INK, width=16)
    d.line((mx-mw/2+14, my, mx+mw/2-14, my), fill=INK, width=8)
    for k in range(1, 6):
        x = mx - mw/2 + k * mw / 6
        d.line((x, my-mh/2+10, x, my+mh/2-10), fill=INK, width=7)
    # forehead / temple veins
    vein = (150, 70, 60, 210)
    d.line([(N/2+250, 230), (N/2+228, 280), (N/2+246, 330), (N/2+222, 380)], fill=vein, width=12, joint="curve")
    d.line([(N/2-60, 160), (N/2-40, 210), (N/2-62, 250)], fill=vein, width=11, joint="curve")
    # sweat drop
    d.ellipse((N/2-300, 300, N/2-262, 352), fill=(200, 235, 255, 230))
    return img, glow

def glow_eyes():
    img, glow = canvas(); d = ImageDraw.Draw(img); g = ImageDraw.Draw(glow)
    ey = 450; ex = 150
    for s, col in ((-1, PURPLE), (1, TEAL)):
        cx = N/2 + s*ex
        poly = [(cx - 70*s, ey - 40), (cx + 70*s, ey - 5), (cx + 55*s, ey + 35), (cx - 60*s, ey + 25)]
        d.polygon(poly, fill=col + (255,)); g.polygon(poly, fill=col)
        core = [(x*0.55 + cx*0.45, y*0.55 + ey*0.45) for x, y in poly]
        d.polygon(core, fill=(255,255,255,255)); g.polygon(core, fill=tuple(min(255, int(c*1.15)) for c in col))
    return img, glow

for name, fn in (("face_bacon_smirk", bacon_smirk), ("face_giant_strain", giant_strain), ("face_glow_eyes", glow_eyes)):
    img, glow = fn()
    img.save(f"{OUT}/{name}.png"); glow.save(f"{OUT}/{name}_glow.png")
    prev = Image.new("RGB", (N, N), (224, 168, 120)); prev.paste(img, (0, 0), img); prev.resize((256, 256)).save(f"{OUT}/{name}_preview.png")
print("ok")
