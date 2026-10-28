"""SPEED ARC store icons (M5): 512x512 PNGs for the 8 game passes and 5 developer products.
Cartoon badges in the palette, no people, no text other than short labels. Drawn at 1024 and scaled
down for smooth edges. Output: Downloads/speed_arc_models/icons/ (the owner approves, then uploads to
the GROUP).   python tools/make_icons.py [out folder]
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "icons")
os.makedirs(OUT, exist_ok=True)
S = 1024
FONT = "C:/Windows/Fonts/ariblk.ttf"

BLACK, CARBON, GRAPHITE = (11, 13, 18), (23, 26, 34), (42, 47, 58)
BLUE, BRIGHT, DEEP = (30, 123, 255), (79, 195, 255), (14, 58, 138)
GOLD, DEEPGOLD, WHITE = (255, 200, 61), (224, 154, 18), (244, 246, 250)
GREEN, PURPLE, ORANGE, RED = (63, 163, 77), (155, 107, 255), (255, 122, 31), (255, 74, 74)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def badge(top, bottom, ring=GOLD):
    """Rounded-square background: vertical gradient, speed streaks, a coloured ring, soft inner shade."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    grad = Image.new("RGBA", (S, S))
    gd = ImageDraw.Draw(grad)
    for y in range(S):
        gd.line([(0, y), (S, y)], fill=lerp(top, bottom, y / S) + (255,))
    # speed streaks
    st = ImageDraw.Draw(grad)
    for i in range(7):
        y = 140 + i * 120
        st.polygon([(-50, y), (S + 50, y - 180), (S + 50, y - 150), (-50, y + 30)], fill=lerp(top, WHITE, 0.12) + (255,))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([24, 24, S - 24, S - 24], radius=190, fill=255)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([24, 24, S - 24, S - 24], radius=190, outline=ring + (255,), width=34)
    d.rounded_rectangle([62, 62, S - 62, S - 62], radius=156, outline=lerp(ring, WHITE, 0.5) + (120,), width=6)
    return img


def outline_text(d, xy, text, size, fill, stroke=BLACK, sw=18, anchor="mm"):
    f = ImageFont.truetype(FONT, size)
    d.text(xy, text, font=f, fill=fill, stroke_width=sw, stroke_fill=stroke, anchor=anchor)


def coin(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=DEEPGOLD, outline=BLACK, width=max(6, r // 9))
    d.ellipse([cx - r * 0.78, cy - r * 0.78, cx + r * 0.78, cy + r * 0.78], fill=GOLD)
    w = r * 0.12
    for k in (-1, 1):  # the speed slashes on the coin face
        x = cx + k * r * 0.18
        d.polygon([(x - w + r * 0.12, cy - r * 0.45), (x + w + r * 0.12, cy - r * 0.45), (x + w - r * 0.12, cy + r * 0.45), (x - w - r * 0.12, cy + r * 0.45)], fill=DEEPGOLD)


def bolt(d, cx, cy, s, fill=GOLD):
    pts = [(0, -1), (0.45, -1), (0.1, -0.1), (0.5, -0.1), (-0.25, 1), (0, 0.15), (-0.4, 0.15)]
    d.polygon([(cx + x * s, cy + y * s) for x, y in pts], fill=fill, outline=BLACK, width=14)


def shoe(d, cx, cy, s, body=BLUE, sole=WHITE, stripe=GOLD):
    """A cartoon running shoe side view (toe right)."""
    def P(pts):
        return [(cx + x * s, cy + y * s) for x, y in pts]
    d.polygon(P([(-1, 0.35), (1.05, 0.35), (1.1, 0.55), (-1.0, 0.55)]), fill=sole, outline=BLACK, width=14)
    d.polygon(P([(-0.95, 0.35), (-0.95, -0.4), (-0.55, -0.55), (-0.15, -0.3), (0.5, -0.05), (1.0, 0.1), (1.05, 0.35)]), fill=body, outline=BLACK, width=14)
    d.line(P([(-0.4, 0.1), (0.6, -0.12)]), fill=stripe, width=int(s * 0.12))
    for i in range(3):
        x = -0.35 + i * 0.22
        d.line(P([(x, -0.38 + i * 0.07), (x + 0.12, -0.2 + i * 0.07)]), fill=WHITE, width=int(s * 0.05))


def stopwatch(d, cx, cy, r, face=WHITE):
    d.rectangle([cx - r * 0.18, cy - r * 1.35, cx + r * 0.18, cy - r * 1.05], fill=GRAPHITE, outline=BLACK, width=12)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GRAPHITE, outline=BLACK, width=16)
    d.ellipse([cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82], fill=face)
    for i in range(12):
        a = i / 12 * math.pi * 2
        d.line([(cx + math.cos(a) * r * 0.66, cy + math.sin(a) * r * 0.66), (cx + math.cos(a) * r * 0.76, cy + math.sin(a) * r * 0.76)], fill=BLACK, width=10)
    d.line([(cx, cy), (cx + r * 0.42, cy - r * 0.42)], fill=RED, width=20)
    d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=BLACK)


def save(img, name):
    img = img.resize((512, 512), Image.LANCZOS)
    img.save(os.path.join(OUT, name + ".png"))
    print("[icon]", name)


def auto_train():
    img = badge(BLUE, DEEP)
    d = ImageDraw.Draw(img)
    # a treadmill: belt with rollers, side rails and a handle post
    d.rounded_rectangle([170, 600, 860, 700], radius=50, fill=GRAPHITE, outline=BLACK, width=16)
    for i in range(7):
        x = 230 + i * 92
        d.line([(x, 615), (x - 30, 685)], fill=BRIGHT, width=12)
    for x in (215, 815):
        d.ellipse([x - 45, 605, x + 45, 695], fill=WHITE, outline=BLACK, width=12)
    d.polygon([(760, 600), (810, 600), (700, 300), (650, 300)], fill=WHITE, outline=BLACK, width=14)
    d.rounded_rectangle([560, 270, 760, 330], radius=25, fill=WHITE, outline=BLACK, width=14)
    bolt(d, 400, 400, 230)
    outline_text(d, (512, 840), "AUTO", 150, GOLD)
    save(img, "Pass_AutoTrain")


def speed2x():
    img = badge(DEEP, BLACK, ring=GOLD)
    d = ImageDraw.Draw(img)
    for i in range(3):
        d.line([(150, 420 + i * 70), (300, 420 + i * 70)], fill=BRIGHT, width=24)
    shoe(d, 540, 430, 290, body=GOLD, sole=WHITE, stripe=BLUE)
    outline_text(d, (512, 790), "2x", 280, GOLD)
    save(img, "Pass_2xSpeed")


def coins2x():
    img = badge(GREEN, (20, 70, 40))
    d = ImageDraw.Draw(img)
    coin(d, 400, 420, 210)
    coin(d, 630, 470, 210)
    outline_text(d, (512, 800), "2x", 280, GOLD)
    save(img, "Pass_2xCoins")


def vip():
    img = badge(CARBON, BLACK, ring=GOLD)
    d = ImageDraw.Draw(img)
    pts = [(230, 640), (230, 330), (370, 470), (512, 250), (654, 470), (794, 330), (794, 640)]
    d.polygon(pts, fill=GOLD, outline=BLACK, width=20)
    d.rectangle([230, 600, 794, 690], fill=DEEPGOLD, outline=BLACK, width=18)
    for x, c in ((370, BRIGHT), (512, RED), (654, BRIGHT)):
        d.ellipse([x - 40, 605, x + 40, 685], fill=c, outline=BLACK, width=10)
    for x, y in ((230, 330), (512, 250), (794, 330)):
        d.ellipse([x - 38, y - 38, x + 38, y + 38], fill=WHITE, outline=BLACK, width=12)
    outline_text(d, (512, 830), "VIP", 200, GOLD)
    save(img, "Pass_VIP")


def coach_slot():
    img = badge(PURPLE, (60, 30, 120))
    d = ImageDraw.Draw(img)
    # a coach's whistle on a cord
    d.arc([300, 160, 720, 560], 200, 340, fill=WHITE, width=18)
    d.rounded_rectangle([330, 380, 620, 560], radius=80, fill=ALU if False else (201, 209, 221), outline=BLACK, width=18)
    d.rectangle([600, 400, 760, 480], fill=(201, 209, 221), outline=BLACK, width=18)
    d.ellipse([400, 430, 480, 510], fill=GRAPHITE)
    outline_text(d, (512, 800), "+1", 260, GOLD)
    save(img, "Pass_ExtraCoachSlot")


def coach_slot2():
    img = badge(ORANGE, (140, 55, 10))
    d = ImageDraw.Draw(img)
    stopwatch(d, 512, 440, 220)
    outline_text(d, (512, 800), "+1", 260, GOLD)
    save(img, "Pass_ExtraCoachSlot2")


def trail_pack():
    img = badge(BLACK, CARBON, ring=BRIGHT)
    d = ImageDraw.Draw(img)
    cols = [BRIGHT, RED, PURPLE, GREEN]
    for i, c in enumerate(cols):
        y = 260 + i * 130
        for k in range(10):  # a tapered streak
            t = k / 10
            w = 70 * (1 - t) + 10
            x0 = 180 + t * 600
            d.ellipse([x0, y - w / 2, x0 + 110, y + w / 2], fill=lerp(c, WHITE, t * 0.5))
        d.ellipse([760, y - 45, 850, y + 45], fill=WHITE, outline=BLACK, width=10)
    outline_text(d, (512, 860), "TRAILS", 140, WHITE)
    save(img, "Pass_TrailPack")


def faster_rolls():
    img = badge(GRAPHITE, BLACK, ring=(201, 209, 221))
    d = ImageDraw.Draw(img)
    for i, (dx, rot_c) in enumerate(((-160, PURPLE), (0, GOLD), (160, BRIGHT))):
        x = 512 + dx
        d.rounded_rectangle([x - 110, 260 + abs(dx) * 0.25, x + 110, 580 + abs(dx) * 0.25], radius=30, fill=rot_c, outline=BLACK, width=16)
        d.ellipse([x - 50, 340 + abs(dx) * 0.25, x + 50, 440 + abs(dx) * 0.25], fill=WHITE, outline=BLACK, width=10)
    for i in range(3):
        d.line([(120, 330 + i * 90), (220, 330 + i * 90)], fill=WHITE, width=20)
    outline_text(d, (512, 800), "x3", 260, GOLD)
    save(img, "Pass_FasterRolls")


def coins(name, count, label):
    img = badge(DEEPGOLD, (120, 70, 10))
    d = ImageDraw.Draw(img)
    if count == 3:
        spots = [(400, 520, 150), (620, 540, 150), (512, 400, 150)]
    elif count == 6:
        spots = [(340, 560, 130), (512, 580, 130), (684, 560, 130), (420, 440, 130), (604, 440, 130), (512, 320, 130)]
    else:  # a chest overflowing with coins
        d.rounded_rectangle([230, 430, 794, 700], radius=40, fill=(156, 106, 60), outline=BLACK, width=18)
        d.rectangle([230, 520, 794, 560], fill=GOLD, outline=BLACK, width=10)
        d.rounded_rectangle([462, 500, 562, 600], radius=16, fill=GOLD, outline=BLACK, width=12)
        spots = [(330, 400, 100), (470, 360, 110), (620, 380, 105), (720, 420, 90), (400, 300, 90), (560, 270, 95)]
    for x, y, r in spots:
        coin(d, x, y, r)
    outline_text(d, (512, 840), label, 150, WHITE)
    save(img, name)


def speed15():
    img = badge(BLUE, DEEP)
    d = ImageDraw.Draw(img)
    stopwatch(d, 470, 430, 210)
    outline_text(d, (720, 600), "2x", 220, GOLD)
    outline_text(d, (512, 850), "15 MIN", 130, WHITE)
    save(img, "Product_2xSpeed15")


def starter():
    img = badge(GOLD, DEEPGOLD, ring=BLUE)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([250, 380, 774, 720], radius=40, fill=BLUE, outline=BLACK, width=18)
    d.rounded_rectangle([220, 300, 804, 420], radius=30, fill=BRIGHT, outline=BLACK, width=18)
    d.rectangle([470, 300, 554, 720], fill=GOLD, outline=BLACK, width=12)
    d.ellipse([360, 190, 500, 320], outline=GOLD, width=40)
    d.ellipse([524, 190, 664, 320], outline=GOLD, width=40)
    shoe(d, 700, 620, 120, body=GOLD, sole=WHITE, stripe=BLUE)
    outline_text(d, (512, 860), "STARTER", 130, WHITE)
    save(img, "Product_StarterPack")


if __name__ == "__main__":
    auto_train()
    speed2x()
    coins2x()
    vip()
    coach_slot()
    coach_slot2()
    trail_pack()
    faster_rolls()
    coins("Product_CoinsSmall", 3, "SMALL")
    coins("Product_CoinsMedium", 6, "MEDIUM")
    coins("Product_CoinsLarge", 0, "LARGE")
    speed15()
    starter()
