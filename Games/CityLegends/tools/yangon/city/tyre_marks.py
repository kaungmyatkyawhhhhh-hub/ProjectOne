"""Tyre marks for the People's Park car meet (2026-11-28): rubber left by drift donuts and slides, dark on transparent.
Writes imports/sync/car_meet/donut.png (a donut: the two rear tyres' rings, 1024 px = 26 studs) and arc.png (a
slide: two tracks along a quarter circle). Uploaded as Images (group 33151111); ids in tools/yangon/PeoplesPark.luau
MARKS. Run: python tools/yangon/city/tyre_marks.py"""
import math, os, random
from PIL import Image, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "imports", "sync", "car_meet")
os.makedirs(OUT, exist_ok=True)
N = 1024
rng = random.Random(2811)


def track(px, cx, cy, r, w, a0, a1, alpha, wob):
    """one tyre's rubber along a circle arc (radius r px, width w px); streaky across and faded along"""
    steps = int(abs(a1 - a0) * r * 1.2) + 1
    streak = [rng.uniform(0.55, 1.0) for _ in range(int(w) + 2)]
    for i in range(steps):
        a = a0 + (a1 - a0) * i / steps
        t = i / steps
        fade = alpha * (0.55 + 0.45 * math.sin(t * math.pi)) * rng.uniform(0.85, 1.0)
        rr = r + wob * math.sin(a * 3.0 + 1.3)
        for k in range(int(w)):
            d = rr - w / 2 + k
            x, y = int(cx + math.cos(a) * d), int(cy + math.sin(a) * d)
            if 0 <= x < N and 0 <= y < N:
                v = int(255 * fade * streak[k] * (1 - abs(k - w / 2) / (w / 2) * 0.35))
                if v > px[x, y][3]:
                    px[x, y] = (18, 18, 20, v)


def save(img, name):
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    p = os.path.abspath(os.path.join(OUT, name))
    img.save(p)
    print(p)
    return img


# donut: a car spinning on its front, the rear tyres trace two rings ~5.6 studs apart (1 stud = 1024/26 px)
S = N / 26
img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
px = img.load()
c = N / 2
for loops in range(3):  # several overlapping laps, each a little off
    ox, oy = rng.uniform(-12, 12), rng.uniform(-12, 12)
    for r in (7.2 * S, 12.8 * S):
        track(px, c + ox, c + oy, r + rng.uniform(-6, 6), 1.0 * S, 0, 2 * math.pi, 0.5, 5)
d = save(img, "donut.png")
assert d.getpixel((0, 0))[3] == 0 and d.getpixel((N // 2, N // 2))[3] == 0

# arc: a slide through a quarter circle, the two rear tracks 5.6 studs apart (texture = 26 x 26 studs)
img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
px = img.load()
for r in (17 * S, 22.6 * S):
    track(px, 0, N, r, 1.0 * S, -math.pi / 2 + 0.05, -0.05, 0.6, 3)
a = save(img, "arc.png")
assert a.getpixel((N - 1, 0))[3] == 0
