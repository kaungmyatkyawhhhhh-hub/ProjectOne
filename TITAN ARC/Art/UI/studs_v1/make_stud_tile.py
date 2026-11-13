# Stomp Evolution UI: one embossed stud on a transparent 64x64 tile (white/black alpha only, so it tints with any plate colour).
# Used with ScaleType.Tile so the studs keep their size on any card (the old plate art stretched them).
from PIL import Image
N, x0, x1, rad = 64, 18, 45, 6
img = Image.new("RGBA", (N, N), (0, 0, 0, 0)); px = img.load()
def inside(x, y, o=0):
    if not (x0 + o <= x <= x1 + o and y0(o) <= y <= x1 + o): return False
    cx = min(max(x, x0 + rad + o), x1 - rad + o); cy = min(max(y, x0 + rad + o), x1 - rad + o)
    return (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad
def y0(o): return x0 + o
for y in range(N):
    for x in range(N):
        if inside(x, y):
            tl = (x - x0 < 4) or (y - x0 < 4); br = (x1 - x < 4) or (x1 - y < 4)
            if tl and not br: px[x, y] = (255, 255, 255, 125)
            elif br and not tl: px[x, y] = (0, 0, 0, 62)
            elif tl and br: px[x, y] = (255, 255, 255, 40)
            else: px[x, y] = (255, 255, 255, 32)
        elif inside(x, y, 3): px[x, y] = (0, 0, 0, 36)
img.save("se_stud_tile_64.png")
print("ok")
