"""
Art for the Legends Rewards hall (the casino building, 2026-11-04, owner's photo of a blue stained-glass
dome over a gilded hall): painted here, nothing copied from the photo.

    python tools/casino_art.py build/casino

  dome.png      512 x 512: the round stained-glass ceiling (see-through corners)
  lunette.png   512 x 256: a gilded fan for the half-round panels over the walls
  garden.png, harbour.png   512 x 384: two painted landscapes for the gold frames
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

Q = 2


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def dome(path):
    S = 512 * Q
    C = S / 2
    R = S / 2 - 4 * Q
    rnd = random.Random(8)
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    deep, mid, light = (10, 34, 150), (24, 84, 214), (92, 176, 255)
    # panes: rings of cells, brighter near the middle like light through the glass
    rings = [(0.16, 12), (0.3, 16), (0.46, 24), (0.62, 32), (0.8, 40), (1.0, 48)]
    r0 = 0.0
    for r1, n in rings:
        for k in range(n):
            a0 = 360 * k / n
            a1 = 360 * (k + 1) / n
            t = 1 - r1
            c = lerp(deep, light, min(1, t * 0.9 + rnd.random() * 0.35))
            if rnd.random() < 0.18:
                c = lerp(c, mid, 0.7)
            pts = []
            for u in range(0, 13):
                a = math.radians(a0 + (a1 - a0) * u / 12)
                pts.append((C + math.cos(a) * r1 * R, C + math.sin(a) * r1 * R))
            for u in range(12, -1, -1):
                a = math.radians(a0 + (a1 - a0) * u / 12)
                pts.append((C + math.cos(a) * r0 * R, C + math.sin(a) * r0 * R))
            d.polygon(pts, fill=c + (255,))
        r0 = r1
    # the iron: rings, main ribs, a ring of ovals, a rosette
    iron = (14, 18, 34, 255)
    gold = (216, 176, 96, 255)
    for r, _ in rings:
        b = [C - r * R, C - r * R, C + r * R, C + r * R]
        d.ellipse(b, outline=iron, width=5 * Q)
    for k in range(16):
        a = math.radians(k * 22.5)
        d.line([C + math.cos(a) * 0.16 * R, C + math.sin(a) * 0.16 * R, C + math.cos(a) * R, C + math.sin(a) * R], fill=iron, width=7 * Q)
    for k in range(48):
        a = math.radians(k * 7.5)
        d.line([C + math.cos(a) * 0.8 * R, C + math.sin(a) * 0.8 * R, C + math.cos(a) * R, C + math.sin(a) * R], fill=iron, width=3 * Q)
    for k in range(16):
        a = math.radians(k * 22.5 + 11.25)
        x, y = C + math.cos(a) * 0.54 * R, C + math.sin(a) * 0.54 * R
        r = 0.05 * R
        d.ellipse([x - r, y - r, x + r, y + r], fill=lerp(mid, light, 0.5) + (255,), outline=gold, width=4 * Q)
    for k in range(8):
        a = math.radians(k * 45)
        x, y = C + math.cos(a) * 0.72 * R, C + math.sin(a) * 0.72 * R
        for j, (rr, w) in enumerate(((0.09, 5), (0.05, 4))):
            r = rr * R
            d.ellipse([x - r, y - r, x + r, y + r], outline=iron, width=w * Q)
    r = 0.15 * R
    d.ellipse([C - r, C - r, C + r, C + r], fill=(8, 12, 30, 255), outline=gold, width=7 * Q)
    for k in range(12):
        a = math.radians(k * 30)
        d.line([C, C, C + math.cos(a) * r * 0.9, C + math.sin(a) * r * 0.9], fill=gold, width=4 * Q)
    r = 0.045 * R
    d.ellipse([C - r, C - r, C + r, C + r], fill=gold)
    # the gold rim
    d.ellipse([C - R, C - R, C + R, C + R], outline=gold, width=10 * Q)
    im = im.resize((512, 512), Image.LANCZOS)
    im.save(path)


def lunette(path):
    W, H = 512 * Q, 256 * Q
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    C = (W / 2, H)
    R = H - 6 * Q
    d.pieslice([C[0] - R, C[1] - R, C[0] + R, C[1] + R], 180, 360, fill=(30, 64, 120, 255), outline=(216, 176, 96, 255), width=8 * Q)
    for k in range(0, 15):
        a = math.radians(180 + 12 * k)
        b = math.radians(180 + 12 * (k + 1))
        col = (232, 214, 170, 255) if k % 2 == 0 else (204, 172, 112, 255)
        r = R * 0.62
        d.polygon([C, (C[0] + math.cos(a) * r, C[1] + math.sin(a) * r), (C[0] + math.cos(b) * r, C[1] + math.sin(b) * r)], fill=col)
    d.arc([C[0] - R * 0.62, C[1] - R * 0.62, C[0] + R * 0.62, C[1] + R * 0.62], 180, 360, fill=(150, 112, 50, 255), width=5 * Q)
    for k in range(1, 9):
        a = math.radians(180 + 20 * k)
        x, y = C[0] + math.cos(a) * R * 0.8, C[1] + math.sin(a) * R * 0.8
        r = 0.07 * R
        d.ellipse([x - r, y - r, x + r, y + r], fill=(90, 160, 240, 255), outline=(216, 176, 96, 255), width=3 * Q)
    im.resize((512, 256), Image.LANCZOS).save(path)


def painting(path, seed, sky0, sky1, hill, water):
    W, H = 512, 384
    rnd = random.Random(seed)
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        d.line([0, y, W, y], fill=lerp(sky0, sky1, min(1, y / (H * 0.6))))
    for _ in range(60):
        x, y = rnd.randint(0, W), rnd.randint(0, int(H * 0.45))
        r = rnd.randint(14, 54)
        c = lerp((255, 244, 226), sky1, rnd.random() * 0.5)
        d.ellipse([x - r * 2, y - r / 2, x + r * 2, y + r / 2], fill=c)
    pts = [(0, H)]
    for x in range(0, W + 16, 16):
        pts.append((x, H * 0.52 + math.sin(x / 70 + seed) * 26 + math.sin(x / 29) * 9))
    pts.append((W, H))
    d.polygon(pts, fill=hill)
    d.rectangle([0, H * 0.72, W, H], fill=water)
    for _ in range(420):
        x, y = rnd.randint(0, W), rnd.randint(int(H * 0.5), H)
        c = lerp(hill, (70, 120, 70), rnd.random()) if y < H * 0.72 else lerp(water, (250, 236, 200), rnd.random() * 0.5)
        d.ellipse([x - 7, y - 3, x + 7, y + 3], fill=c)
    im.filter(ImageFilter.GaussianBlur(1.2)).save(path)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "build/casino"
    os.makedirs(out, exist_ok=True)
    dome(os.path.join(out, "dome.png"))
    lunette(os.path.join(out, "lunette.png"))
    painting(os.path.join(out, "garden.png"), 3, (150, 190, 226), (250, 226, 190), (96, 128, 88), (70, 120, 170))
    painting(os.path.join(out, "harbour.png"), 9, (236, 188, 150), (250, 236, 206), (150, 120, 96), (44, 92, 150))
    print("ok")


if __name__ == "__main__":
    main()
