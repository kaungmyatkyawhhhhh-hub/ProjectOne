"""Per-car dial looks (copies of the real clusters). Writes a preview PNG per dial and the Lua module."""
import re, json, math, sys
from PIL import Image, ImageDraw, ImageFont

SRC = "src/client/CarSkin.lua"
OUT_LUA = "src/client/DialLooks.lua"

# --- the dial table (geometry + scale) from CarSkin
def dials():
    s = open(SRC).read()
    body = s[s.index("CarSkin.DIAL_NEEDLES = {"):]
    body = body[:body.index("} :: { [string]: { DialSpec } }")]
    out = {}
    for m in re.finditer(r"^\t([a-z0-9_]+) = \{(.*?)^\t\},", body, re.S | re.M):
        out[m.group(1)] = [dict(kind=k, unit=u, length=float(l), scale=sc) for k, u, l, sc in re.findall(r'kind = "(\w+)", unit = "(\w+)",.*?length = ([\d.]+), scale = "([^"]*)"', m.group(2))]
    return out

W, BLK, GRY = (240, 242, 246), (14, 14, 16), (200, 202, 206)
RED = (225, 35, 28)
def L(**k): return k

# per car, per dial (same order as DIAL_NEEDLES; digits entries get None)
LOOKS = {
 "bentlee_bentayga": [
  L(r=134, face=(52, 54, 58), bezel=(178, 180, 186), bezelW=4, lines=[(66, (205, 205, 210), 2)], tick=W, tickR=130, major=(12, 3), minor=(6, 1.5), minors=4,
    num=W, numR=102, size=19, font="GothamMedium", step=1000, div=100, red=7000, redC=(235, 150, 40), needle=(238, 128, 36), needleW=5, hub=(30, 30, 32), hubR=13,
    circles=[(0, 68, 32, None, (205, 205, 210), 2)], texts=[("x100 r/min", 0, -36, 11, (200, 200, 205), "GothamMedium")]),
  L(r=134, face=(52, 54, 58), bezel=(178, 180, 186), bezelW=4, lines=[(66, (205, 205, 210), 2)], tick=W, tickR=130, major=(12, 3), minor=(6, 1.5), minors=1,
    num=W, numR=102, size=17, font="GothamMedium", step=20, needle=(238, 128, 36), needleW=5, hub=(30, 30, 32), hubR=13,
    circles=[(0, 68, 32, None, (205, 205, 210), 2)], texts=[("MPH", 0, -36, 12, (200, 200, 205), "GothamMedium")]),
 ],
 "bentz_gt63s": [
  L(r=110, face=(110, 18, 22), inner=(80, 12, 15), innerR=58, bezel=(206, 208, 212), bezelW=7, tick=W, tickR=106, major=(15, 4), minor=(7, 1.5), minors=4,
    num=W, numR=76, size=24, font="GothamBold", step=1000, div=1000, red=6200, redC=(255, 255, 255), needle=(245, 245, 245), needleW=9, hub=(12, 12, 12), hubR=24, hubRing=(70, 70, 74),
    texts=[("RPM", 0, 44, 14, W, "GothamBold"), ("x1000", 0, 58, 10, W, "GothamMedium")]),
  L(r=110, face=(110, 18, 22), inner=(80, 12, 15), innerR=58, bezel=(206, 208, 212), bezelW=7, tick=W, tickR=106, major=(15, 4), minor=(7, 1.5), minors=1,
    num=W, numR=78, size=17, font="GothamBold", step=20, needle=(245, 245, 245), needleW=9, hub=(12, 12, 12), hubR=24, hubRing=(70, 70, 74),
    texts=[("MPH", 0, 48, 14, W, "GothamBold")]),
 ],
 "bentz_sl65bs": [
  L(r=150, face=(58, 60, 64), inner=(22, 24, 28), innerR=74, bezel=(150, 152, 156), bezelW=4, tick=W, tickR=146, major=(14, 3), minor=(7, 1.5), minors=1,
    num=W, numR=114, size=19, font="GothamMedium", step=20, needle=RED, needleW=5, hub=(20, 20, 22), hubR=13,
    texts=[("MPH", 0, -40, 11, (190, 192, 198), "GothamMedium")]),
  L(r=150, face=(214, 216, 220), inner=(22, 24, 28), innerR=74, bezel=(150, 152, 156), bezelW=4, tick=(30, 30, 32), tickR=146, major=(14, 3), minor=(7, 1.5), minors=4,
    num=(28, 28, 30), numR=110, size=26, font="GothamMedium", step=1000, div=1000, red=6500, redC=RED, numRed=RED, bands=[(6500, 8000, 143, 9, RED)],
    needle=RED, needleW=5, hub=(20, 20, 22), hubR=13,
    texts=[("x1000/min", 0, -40, 10, (190, 192, 198), "GothamMedium")]),
 ],
 "toyoka_lc300": [
  L(r=118, face=(10, 10, 12), bezel=(215, 216, 220), bezelW=6, tick=W, tickR=112, major=(14, 4), minor=(7, 1.5), minors=4,
    num=W, numR=88, size=24, font="GothamBold", step=1000, div=1000, red=6000, redC=(230, 40, 30), needle=(232, 52, 36), needleW=5, hub=(18, 18, 20), hubR=14,
    texts=[("x1000 r/min", 0, 44, 10, W, "GothamMedium")]),
  L(r=118, face=(10, 10, 12), bezel=(215, 216, 220), bezelW=6, tick=W, tickR=112, major=(14, 4), minor=(7, 1.5), minors=1,
    num=W, numR=88, size=17, font="GothamBold", step=20, needle=(232, 52, 36), needleW=5, hub=(18, 18, 20), hubR=14,
    texts=[("km/h", 0, 44, 11, W, "GothamMedium")]),
  None,
 ],
 "bentz_cls63s": [
  L(r=128, face=(206, 208, 211), inner=(12, 12, 14), innerR=78, bezel=(26, 26, 28), bezelW=10, tick=(30, 30, 32), tickR=124, major=(13, 3), minor=(7, 1.5), minors=1,
    num=(26, 26, 28), numR=101, size=19, font="GothamMedium", step=20, needle=(242, 242, 244), needleW=5, hub=(14, 14, 16), hubR=15,
    texts=[("km/h", 0, 42, 11, (190, 192, 198), "GothamMedium")]),
  L(r=112, face=(206, 208, 211), inner=(12, 12, 14), innerR=62, bezel=(26, 26, 28), bezelW=10, tick=(30, 30, 32), tickR=108, major=(13, 3), minor=(7, 1.5), minors=4,
    num=(26, 26, 28), numR=86, size=22, font="GothamMedium", step=1000, div=1000, bands=[(7000, 8000, 104, 9, RED)],
    needle=(242, 242, 244), needleW=5, hub=(14, 14, 16), hubR=15, texts=[("x1000 r/min", 0, 36, 10, (190, 192, 198), "GothamMedium")]),
 ],
 "bentz_gle53": [
  L(r=118, face=(14, 14, 16), bezel=(192, 194, 198), bezelW=5, tick=W, tickR=113, major=(13, 3), minor=(7, 1.5), minors=1,
    num=W, numR=88, size=17, font="GothamMedium", step=20, needle=RED, needleW=5, hub=(26, 26, 28), hubR=13,
    texts=[("MPH", 0, -40, 11, (190, 192, 198), "GothamMedium")]),
  L(r=118, face=(14, 14, 16), bezel=(192, 194, 198), bezelW=5, tick=W, tickR=113, major=(13, 3), minor=(7, 1.5), minors=4,
    num=W, numR=88, size=22, font="GothamMedium", step=1000, div=1000, red=6500, redC=RED, bands=[(6500, 8000, 110, 8, RED)], needle=RED, needleW=5, hub=(26, 26, 28), hubR=13,
    texts=[("x1000/min", 0, -40, 10, (190, 192, 198), "GothamMedium")]),
 ],
 "bentz_sls": [
  L(r=122, face=(16, 16, 18), inner=(56, 57, 61), innerR=58, tick=W, tickR=118, major=(16, 5), minor=(8, 3), minors=2,
    num=W, numR=97, size=19, font="GothamBold", step=30, needle=RED, needleW=6, hub=(40, 40, 44), hubR=14,
    texts=[("km/h", 58, 26, 11, W, "GothamMedium")]),
  L(r=128, face=(16, 16, 18), inner=(56, 57, 61), innerR=60, tick=W, tickR=124, major=(17, 5), minor=(8, 3), minors=1,
    num=W, numR=102, size=30, font="GothamBold", step=1000, div=1000, red=7000, redC=RED, numRed=RED, bands=[(7000, 9000, 120, 10, RED)], needle=RED, needleW=6, hub=(40, 40, 44), hubR=14,
    texts=[("x1000 1/min", 56, 32, 10, W, "GothamMedium")]),
 ],
 "brabos_g63": [
  L(r=118, face=(16, 16, 18), bezel=(226, 32, 30), bezelW=9, tick=W, tickR=110, major=(13, 3), minor=(7, 1.5), minors=1,
    num=W, numR=88, size=19, font="GothamBold", step=30, needle=(236, 40, 32), needleW=6, hub=(30, 30, 32), hubR=14,
    texts=[("km/h", 0, -42, 12, W, "GothamMedium")]),
  L(r=118, face=(16, 16, 18), bezel=(226, 32, 30), bezelW=9, tick=W, tickR=110, major=(13, 3), minor=(7, 1.5), minors=4,
    num=W, numR=88, size=22, font="GothamBold", step=1000, div=1000, needle=(236, 40, 32), needleW=6, hub=(30, 30, 32), hubR=14,
    texts=[("x1000/min", 0, -42, 10, W, "GothamMedium")]),
 ],
 "lambrini_lp700": [
  L(r=125, face=(18, 34, 70), inner=(10, 22, 48), innerR=62, bezel=(96, 116, 156), bezelW=4, tick=W, tickR=120, major=(13, 3), minor=(7, 1.5), minors=4,
    num=W, numR=86, size=22, font="GothamBold", step=1000, div=1000, red=7000, redC=(245, 85, 45), numRed=(245, 85, 45), needle=(245, 75, 45), needleW=4, hub=(14, 24, 50), hubR=12,
    texts=[]),
  None,
 ],
 "mazdo_rx8": [
  L(r=126, face=(28, 28, 30), bezel=(205, 205, 209), bezelW=11, tick=W, tickR=114, major=(14, 4), minor=(7, 2), minors=1,
    num=W, numR=88, size=24, font="GothamBold", step=1000, div=1000, start=1000, red=9000, redC=(235, 55, 40),
    bands=[(5000, 9000, 62, 12, (205, 42, 30)), (9000, 10000, 120, 10, (235, 55, 40))], needle=(238, 48, 36), needleW=7, hub=(22, 22, 24), hubR=14),
  None,
 ],
 "nisun_gtr": [
  L(r=112, face=(12, 12, 14), bezel=(202, 204, 208), bezelW=12, tick=W, tickR=104, major=(13, 3), minor=(7, 1.5), minors=1,
    num=W, numR=82, size=16, font="GothamBold", step=20, needle=RED, needleW=5, hub=(26, 26, 28), hubR=14, texts=[("MPH", 0, 34, 11, W, "GothamMedium")]),
  L(r=115, face=(12, 12, 14), bezel=(202, 204, 208), bezelW=12, tick=W, tickR=107, major=(14, 4), minor=(7, 1.5), minors=4,
    num=W, numR=84, size=24, font="GothamBold", step=1000, div=1000, red=7000, redC=RED, needle=RED, needleW=5, hub=(26, 26, 28), hubR=14,
    texts=[("RPMx1000", 0, 40, 10, W, "GothamMedium")]),
 ],
 "nisun_r34": [
  L(r=120, face=(236, 236, 232), inner=(20, 20, 22), innerR=48, bezel=(40, 40, 42), bezelW=4, tick=(150, 80, 30), tickR=116, major=(14, 3), minor=(7, 1.5), minors=1,
    num=(200, 96, 32), numR=92, size=20, font="GothamBold", step=20, needle=(236, 70, 32), needleW=6, hub=(14, 14, 16), hubR=16,
    texts=[("km/h", 0, -24, 11, W, "GothamMedium")]),
  L(r=120, face=(236, 236, 232), inner=(20, 20, 22), innerR=48, bezel=(40, 40, 42), bezelW=4, tick=(150, 80, 30), tickR=116, major=(14, 3), minor=(7, 1.5), minors=4,
    num=(200, 96, 32), numR=92, size=22, font="GothamBold", step=1000, div=1000, red=9000, redC=(220, 40, 30), numRed=(220, 40, 30), needle=(236, 70, 32), needleW=6, hub=(14, 14, 16), hubR=16,
    texts=[("x1000r/min", 0, -24, 9, W, "GothamMedium")]),
 ],
 "porsha_boxster": [
  L(r=118, face=(14, 14, 16), bezel=(62, 62, 66), bezelW=3, tick=W, tickR=113, major=(13, 3), minor=(7, 1.5), minors=4,
    num=W, numR=88, size=22, font="GothamMedium", step=1000, div=1000, red=7500, redC=RED, needle=RED, needleW=5, hub=(26, 26, 28), hubR=13,
    texts=[("1/min x1000", 0, 40, 10, (190, 192, 198), "GothamMedium")]),
  L(r=118, face=(14, 14, 16), bezel=(62, 62, 66), bezelW=3, tick=W, tickR=113, major=(12, 3), minor=(6, 1.5), minors=1,
    num=W, numR=89, size=13, font="GothamMedium", step=20, needle=RED, needleW=5, hub=(26, 26, 28), hubR=13,
    texts=[("km/h", 0, 40, 11, (190, 192, 198), "GothamMedium")]),
 ],
 "bentz_g63": [
  L(r=122, face=(10, 10, 12), bezel=(206, 208, 212), bezelW=12, lines=[(60, (222, 222, 226), 2)], tick=W, tickR=114, major=(12, 3), minor=(6, 1.5), minors=1,
    num=W, numR=92, size=14, font="GothamMedium", step=10, needle=(230, 32, 26), needleW=5, hub=(26, 26, 28), hubR=13,
    circles=[(42, 56, 27, None, (222, 222, 226), 2)], texts=[("MPH", 0, -36, 10, W, "GothamMedium")]),
  L(r=122, face=(10, 10, 12), bezel=(206, 208, 212), bezelW=12, lines=[(60, (222, 222, 226), 2)], tick=W, tickR=114, major=(13, 3), minor=(6, 1.5), minors=4,
    num=W, numR=92, size=22, font="GothamMedium", step=1000, div=1000, bands=[(6500, 8000, 114, 7, RED)], needle=(230, 32, 26), needleW=5, hub=(26, 26, 28), hubR=13,
    circles=[(42, 56, 27, None, (222, 222, 226), 2)], texts=[("x1000/min", 62, 22, 9, W, "GothamMedium")]),
 ],
 "ferrara_599": [
  L(r=118, face=(244, 180, 22), bezel=(40, 40, 42), bezelW=6, tick=(22, 22, 22), tickR=113, major=(13, 3), minor=(6, 1.5), minors=4,
    num=(22, 22, 22), numR=86, size=30, font="GothamBold", step=1000, div=1000, red=9000, redC=(150, 25, 20), numRed=(150, 25, 20), needle=(230, 30, 26), needleW=5,
    hub=(202, 198, 190), hubR=22, texts=[("RPM", 0, 36, 12, (22, 22, 22), "GothamBold"), ("x1000", 0, 50, 10, (22, 22, 22), "GothamMedium")]),
  L(r=112, face=(12, 12, 14), bezel=(226, 226, 230), bezelW=5, tick=W, tickR=107, major=(12, 3), minor=(6, 1.5), minors=2,
    num=W, numR=80, size=15, font="GothamMedium", step=30, start=20, needle=(230, 30, 26), needleW=5, hub=(202, 198, 190), hubR=22,
    texts=[("km/h", 0, -34, 11, W, "GothamMedium")]),
 ],
 "astin_db9": [
  L(r=118, face=(40, 42, 46), inner=(22, 23, 26), innerR=70, bezel=(196, 198, 202), bezelW=4, tick=W, tickR=114, major=(12, 2.5), minor=(6, 1.2), minors=1,
    num=W, numR=58, size=11, font="TitilliumWeb", step=20, start=20, needle=(234, 236, 240), needleW=5, hub=(18, 18, 20), hubR=14,
    alt=dict(mul=1.609, step=30, start=30, numR=95, size=15, c=W), rects=[(62, 0, 64, 34, (18, 18, 20), None), (62, -17, 66, 2, (205, 207, 211), None), (62, 17, 66, 2, (205, 207, 211), None)],
    texts=[("MPH", 62, 52, 10, W, "TitilliumWeb")]),
  L(r=118, face=(40, 42, 46), inner=(22, 23, 26), innerR=70, bezel=(196, 198, 202), bezelW=4, tick=W, tickR=114, major=(13, 3), minor=(6, 1.2), minors=4,
    num=W, numR=94, size=19, font="TitilliumWeb", step=1000, div=1000, start=1000, needle=(234, 236, 240), needleW=5, hub=(18, 18, 20), hubR=14,
    rects=[(-62, 0, 64, 34, (18, 18, 20), None), (-62, -17, 66, 2, (205, 207, 211), None), (-62, 17, 66, 2, (205, 207, 211), None)],
    texts=[("rpm x1000", -60, 62, 10, W, "TitilliumWeb")]),
 ],
 "astin_vantage": [
  L(r=118, face=(132, 134, 138), inner=(80, 82, 86), innerR=74, lines=[(76, (44, 44, 48), 4)], bezel=(198, 200, 204), bezelW=12, tick=W, tickR=114, major=(12, 2.5), minor=(6, 1.2), minors=1,
    num=W, numR=58, size=11, font="TitilliumWeb", step=20, start=20, needle=(236, 236, 240), needleW=5, hub=(26, 26, 28), hubR=15,
    alt=dict(mul=1.609, step=30, start=30, numR=96, size=15, c=W), texts=[("MPH", 50, -30, 10, W, "TitilliumWeb")]),
  L(r=118, face=(132, 134, 138), inner=(80, 82, 86), innerR=74, lines=[(76, (44, 44, 48), 4)], bezel=(198, 200, 204), bezelW=12, tick=W, tickR=114, major=(13, 3), minor=(6, 1.2), minors=4,
    num=W, numR=95, size=19, font="TitilliumWeb", step=1000, div=1000, start=1000, needle=(236, 236, 240), needleW=5, hub=(26, 26, 28), hubR=15,
    rects=[(-58, 0, 60, 34, (52, 54, 58), None)], texts=[("rpm x1000", -60, 62, 10, W, "TitilliumWeb")]),
 ],
 "lambrini_countach": [
  L(r=118, face=(12, 12, 14), bezel=(26, 26, 28), bezelW=6, tick=W, tickR=113, major=(13, 3), minor=(6, 1.5), minors=1,
    num=W, numR=90, size=14, font="GothamBold", step=20, start=20, needle=(236, 140, 42), needleW=5, hub=(30, 30, 32), hubR=13,
    texts=[("000000", 0, 26, 12, W, "RobotoMono"), ("km/h", 46, 52, 10, W, "GothamMedium")]),
  L(r=115, face=(12, 12, 14), bezel=(26, 26, 28), bezelW=6, tick=W, tickR=110, major=(13, 3), minor=(6, 1.5), minors=1,
    num=W, numR=86, size=18, font="GothamBold", step=1000, div=100, bands=[(6500, 7500, 104, 10, (240, 200, 40)), (7500, 9000, 104, 10, (222, 42, 30))],
    needle=(236, 140, 42), needleW=5, hub=(30, 30, 32), hubR=13, texts=[("ELETTRONICO", 0, -30, 9, W, "GothamMedium")]),
 ],
}
# scales that need extending beyond what was measured
SCALE_FIX = {}

def parse(scale):
    return [tuple(map(float, p.split(":"))) for p in scale.split(",") if p]

def angle_of(pts, v):
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        if v <= b[0] or i == len(pts) - 2:
            return a[1] + (b[1] - a[1]) * (v - a[0]) / (b[0] - a[0])

def values(lk, pts):
    lo, top = pts[0][0], pts[-1][0]
    step = lk["step"]
    start = lk.get("start", math.ceil(lo / step) * step)
    v, out = start, []
    while v <= top + 1e-6:
        out.append(v); v += step
    return out

FONTS = {"bold": "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "reg": "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"}
def font(name, size):
    return ImageFont.truetype(FONTS["bold" if ("Bold" in name or "Black" in name) else "reg"], max(6, int(size)))

def render(lk, pts, kind, test, path, Z=3):
    R = lk["r"] + lk.get("bezelW", 0) + 4
    N = int(2 * R * Z)
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    C = N / 2
    def circle(r, fill=None, outline=None, w=0, cx=0, cy=0):
        x, y = C + cx * Z, C + cy * Z
        d.ellipse((x - r * Z, y - r * Z, x + r * Z, y + r * Z), fill=fill, outline=outline, width=int(w * Z))
    bw = lk.get("bezelW", 0)
    if bw: circle(lk["r"] + bw, fill=lk["bezel"])
    circle(lk["r"], fill=lk["face"])
    if lk.get("inner"): circle(lk["innerR"], fill=lk["inner"])
    for r, c, w in lk.get("lines", []): circle(r, outline=c, w=w)
    for cx, cy, r, fill, st, w in lk.get("circles", []): circle(r, fill=fill, outline=st, w=w, cx=cx, cy=cy)
    def bar(a, r0, r1, w, c):
        t = math.radians(a); dx, dy = math.sin(t), -math.cos(t); px, py = -dy, dx
        p = [(C + (dx * r + px * s * w / 2) * Z, C + (dy * r + py * s * w / 2) * Z) for r, s in ((r0, -1), (r1, -1), (r1, 1), (r0, 1))]
        d.polygon(p, fill=c)
    for v0, v1, r, w, c in lk.get("bands", []):
        a0, a1 = angle_of(pts, v0), angle_of(pts, v1)
        n = max(2, int(abs(a1 - a0) / 2))
        for i in range(n):
            a = a0 + (a1 - a0) * (i + 0.5) / n
            bar(a, r - w / 2, r + w / 2, abs(a1 - a0) / n * math.pi / 180 * r + 1, c)
    vals = values(lk, pts)
    step = lk["step"]; minors = lk.get("minors", 1)
    lk = dict(lk, size=fit_size(lk["size"], lk["numR"], [angle_of(pts, v) for v in vals], [str(int(round(v / lk.get("div", 1)))) for v in vals]))
    for i, v in enumerate(vals):
        for k in range(minors + 1):
            vv = v + step * k / (minors + 1)
            if vv > pts[-1][0] + 1e-6 or (k > 0 and i == len(vals) - 1 and vv > vals[-1]): continue
            major = k == 0
            ln, w = lk["major"] if major else lk["minor"]
            red = lk.get("red") is not None and vv >= lk["red"]
            bar(angle_of(pts, vv), lk["tickR"] - ln, lk["tickR"], w, lk.get("redC", RED) if red else lk["tick"])
        a = math.radians(angle_of(pts, v))
        txt = str(int(round(v / lk.get("div", 1))))
        red = lk.get("numRed") and lk.get("red") is not None and v >= lk["red"]
        f = font(lk["font"], lk["size"] * Z)
        x, y = C + lk["numR"] * math.sin(a) * Z, C - lk["numR"] * math.cos(a) * Z
        d.text((x, y), txt, fill=lk["numRed"] if red else lk["num"], font=f, anchor="mm")
    alt = lk.get("alt")
    if alt:
        av = [v for v in frange(alt.get("start", 0), pts[-1][0] * alt["mul"], alt["step"])]
        asize = fit_size(alt["size"], alt["numR"], [angle_of(pts, v / alt["mul"]) for v in av], [str(int(v)) for v in av])
        for v in av:
            a = math.radians(angle_of(pts, v / alt["mul"]))
            d.text((C + alt["numR"] * math.sin(a) * Z, C - alt["numR"] * math.cos(a) * Z), str(int(v)), fill=alt["c"], font=font(lk["font"], asize * Z), anchor="mm")
    for x, y, w, h, c, st in lk.get("rects", []):
        d.rectangle((C + (x - w / 2) * Z, C + (y - h / 2) * Z, C + (x + w / 2) * Z, C + (y + h / 2) * Z), fill=c)
    for t, x, y, s, c, fn in lk.get("texts", []):
        d.text((C + x * Z, C + y * Z), t, fill=c, font=font(fn, s * Z), anchor="mm")
    # needle at the test value, with its tail
    a = angle_of(pts, test)
    bar(a, -22, 100, lk.get("needleW", 6), lk["needle"])
    if lk.get("hubRing"): circle(lk["hubR"] + 3, fill=lk["hubRing"])
    circle(lk["hubR"], fill=lk["hub"])
    im.save(path)
    return R

def frange(a, b, st):
    out, v = [], a
    while v <= b + 1e-6:
        out.append(v); v += st
    return out

def fit_size(size, r, angs, txts):
    """numbers never touch: at most the gap between neighbours along the arc"""
    if len(angs) < 2: return size
    gap = min(abs(angs[i + 1] - angs[i]) for i in range(len(angs) - 1)) * math.pi / 180 * r
    chars = max(len(t) for t in txts)
    return min(size, gap * 0.92 / (0.62 * chars))

def lua_color(c): return "Color3.fromRGB(%d, %d, %d)" % tuple(c)
def lua(v):
    if isinstance(v, tuple) and len(v) == 3 and all(isinstance(x, int) for x in v): return lua_color(v)
    if isinstance(v, str): return '"%s"' % v
    if isinstance(v, (int, float)): return "%g" % v
    raise TypeError(v)

def lua_look(lk):
    parts = []
    for k in ("r", "face", "inner", "innerR", "bezel", "bezelW", "tick", "tickR", "minors", "num", "numR", "size", "font", "step", "div", "start", "red", "redC", "numRed", "needle", "needleW", "hub", "hubR", "hubRing"):
        if k in lk: parts.append("%s = %s" % (k, lua(lk[k])))
    for k in ("major", "minor"):
        parts.append("%s = { %s, %s }" % (k, lua(lk[k][0]), lua(lk[k][1])))
    if lk.get("lines"): parts.append("lines = { %s }" % ", ".join("{ r = %g, c = %s, w = %g }" % (r, lua_color(c), w) for r, c, w in lk["lines"]))
    if lk.get("circles"): parts.append("circles = { %s }" % ", ".join("{ x = %g, y = %g, r = %g, fill = %s, stroke = %s, w = %g }" % (x, y, r, lua_color(f) if f else "nil", lua_color(s) if s else "nil", w) for x, y, r, f, s, w in lk["circles"]))
    if lk.get("bands"): parts.append("bands = { %s }" % ", ".join("{ from = %g, to = %g, r = %g, w = %g, c = %s }" % (a, b, r, w, lua_color(c)) for a, b, r, w, c in lk["bands"]))
    if lk.get("alt"):
        a = lk["alt"]
        parts.append("alt = { mul = %g, step = %g, start = %g, numR = %g, size = %g, c = %s }" % (a["mul"], a["step"], a.get("start", 0), a["numR"], a["size"], lua_color(a["c"])))
    if lk.get("rects"): parts.append("rects = { %s }" % ", ".join("{ x = %g, y = %g, w = %g, h = %g, c = %s }" % (x, y, w, h, lua_color(c)) for x, y, w, h, c, st in lk["rects"]))
    if lk.get("texts"): parts.append("texts = { %s }" % ", ".join('{ t = "%s", x = %g, y = %g, size = %g, c = %s, font = "%s" }' % (t, x, y, s, lua_color(c), f) for t, x, y, s, c, f in lk["texts"]))
    return "{ " + ", ".join(parts) + " }"

if __name__ == "__main__":
    D = dials()
    __import__("os").makedirs("build/dials", exist_ok=True)
    lines = ["--[[", '\tDialLooks (client): how each car\'s own dials look, copied from its real cluster (owner, 2026-10-13:',
             '\t"I want the custom cluster to look exactly like the real car"). Same order as CarSkin.DIAL_NEEDLES;',
             '\tsizes in canvas pixels where 100 is the needle length. Made by tools (see the notes); CarSkin draws them.', ']]', '',
             'return {']
    for car in sorted(LOOKS):
        assert car in D, car
        assert len(LOOKS[car]) == len(D[car]), (car, len(LOOKS[car]), len(D[car]))
        lines.append("\t%s = {" % car)
        for i, (lk, dl) in enumerate(zip(LOOKS[car], D[car])):
            if lk is None:
                lines.append("\t\tfalse,"); continue
            sc = SCALE_FIX.get((car, i), dl["scale"])
            pts = parse(sc)
            top = pts[-1][0]
            render(lk, pts, dl["kind"], top * 0.45, "build/dials/%s_%d.png" % (car, i))
            lines.append("\t\t" + lua_look(lk) + ",")
        lines.append("\t},")
    lines.append("}")
    open(OUT_LUA, "w").write("\n".join(lines) + "\n")
    missing = [c for c in D if c not in LOOKS]
    print("written; cars without a look:", missing)
