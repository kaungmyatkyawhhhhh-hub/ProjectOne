# TITAN STADIUM (Titan District landmark) from sheet se_lm_stadium (ChatGPT, 13 Nov). 1 sheet px = 0.55 studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
S = 0.55
L, W = 523 * S, 420 * S          # 288 x 231
HW = 138 * S                      # wall height ~76
N = 40
def ell(rx, ry, t):               # superellipse-ish (a little boxy like the sheet)
    c, s = math.cos(t), math.sin(t)
    e = 0.8
    return (rx * math.copysign(abs(c) ** e, c), ry * math.copysign(abs(s) ** e, s))
def ring(rx, ry, w, z0, z1, col, inset_top=0.0, n=N):
    """closed elliptical band: outer (rx,ry) inner (rx-w, ry-w); top inner edge can move in by inset_top"""
    v = []; f = []
    for i in range(n):
        t = 2 * math.pi * i / n
        ox, oy = ell(rx, ry, t); ix, iy = ell(rx - w, ry - w, t)
        tx, ty = ell(rx - inset_top, ry - inset_top, t); tix, tiy = ell(rx - w - inset_top, ry - w - inset_top, t)
        v += [(ox, oy, z0), (tx, ty, z1), (tix, tiy, z1), (ix, iy, z0)]
    for i in range(n):
        a, b = i * 4, ((i + 1) % n) * 4
        for k in range(4):
            f.append((a + k, b + k, b + (k + 1) % 4, a + (k + 1) % 4))
    return poly(v, f, col, bev=0)
# BOWL: seating tiers stepping down to the pitch (inside), pitch with lines
for k in range(5):
    rx, ry = L / 2 - 14 - k * 12, W / 2 - 14 - k * 12
    ring(rx, ry, 13, 0, HW * 0.78 - k * 9, 'violet' if k % 2 == 0 else 'white')
pr_x, pr_y = L / 2 - 14 - 5 * 12 + 1, W / 2 - 14 - 5 * 12 + 1
v = []; 
for i in range(N):
    x, y = ell(pr_x, pr_y, 2 * math.pi * i / N); v.append((x, y, 0.5))
poly(v, [tuple(range(N))], 'green', bev=0)
lw = 0.8; zl = 0.75; px_, py_ = pr_x * 0.82, pr_y * 0.78
for (sx, sy, a, b) in [(0, -py_, 2 * px_, lw), (0, py_, 2 * px_, lw), (-px_, 0, lw, 2 * py_), (px_, 0, lw, 2 * py_), (0, 0, lw, 2 * py_)]:
    box((a, b, 0.3), (sx, sy, zl), 'white', 0)
torus(py_ * 0.28, lw / 2, (0, 0, zl), 'white', rot=(0, 0, 0), maj=24, mn=3)
for sx in (-1, 1):
    for (a, b, cx) in [(lw, py_ * 0.9, px_ - 16), (16, lw, px_ - 8)]:
        for sy in ((0,) if a == lw else (-1, 1)):
            box((a, b, 0.3), (sx * cx, sy * py_ * 0.45, zl), 'white', 0)
done("LM2_Stadium_Bowl")
# OUTER WALL: violet band, white ribs, round lights; white roof ring leaning in
ring(L / 2, W / 2, 6, 0, HW * 0.82, 'violet')
for i in range(28):
    t = 2 * math.pi * (i + 0.5) / 28
    x, y = ell(L / 2 + 0.6, W / 2 + 0.6, t)
    box((3.0, 3.0, HW * 0.82), (x, y, HW * 0.41), 'white', 0.4, rot=(0, 0, math.degrees(math.atan2(y, x))))
    if i % 1 == 0:
        t2 = 2 * math.pi * i / 28; x2, y2 = ell(L / 2 + 0.7, W / 2 + 0.7, t2)
        cyl(3.0, 1.2, (x2, y2, HW * 0.66), 'light', seg=12, bev=0.2, rot=(90, 0, 90 + math.degrees(math.atan2(y2, x2))))
ring(L / 2 + 3, W / 2 + 3, 18, HW * 0.82, HW, 'white', inset_top=6)
ring(L / 2 + 4, W / 2 + 4, 4, -0.5, 3.5, 'grey')          # plinth
# entrance arches (gold) on both long sides
for sy in (-1, 1):
    y = sy * (W / 2 + 4)
    aw = 143 * S; ah = (325 - 220) * S
    box((aw * 0.62, 6, ah - aw * 0.31), (0, y, (ah - aw * 0.31) / 2), 'glass', 0.3)
    cyl(aw * 0.31, 6, (0, y, ah - aw * 0.31), 'glass', seg=20, bev=0.3, rot=(90, 0, 0))
    torus(aw * 0.4, aw * 0.12, (0, y + sy * 1.5, ah - aw * 0.4), 'gold', rot=(90, 0, 0), maj=28, mn=6)
    clip_below(PARTS[-1], ah - aw * 0.4)
    for sx in (-1, 1): box((aw * 0.18, 8, ah - aw * 0.4), (sx * aw * 0.4, y + sy * 1.5, (ah - aw * 0.4) / 2), 'gold', 1.0)
    box((aw * 0.05, 7, ah * 0.5), (0, y + sy * 0.6, ah * 0.25), 'white', 0)
    for k in range(3): box((aw * 0.9 - k * 6, 5 + (2 - k) * 3, 1.6), (0, y + sy * (5 + (2 - k) * 1.5), 0.8 + k * 1.6), 'white' if k % 2 == 0 else 'trim', 0.4)
done("LM2_Stadium_Wall")
# FLOODLIGHT TOWERS at the 4 diagonal corners
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * L * 0.43, sy * W * 0.42
        hT = (325 - 100) * S
        box((7, 7, 4), (x, y, 2), 'grey', 0.6)
        box((11, 11, 6), (x, y, 3), 'grey', 0.8)
        cyl(4.2, hT - 18, (x, y, (hT - 18) / 2 + 5), 'white', seg=10, bev=0.5, r2=3.0)
        m = mark()
        box((27, 5, 19), (0, 0, 0), 'white', 1.0)
        box((24, 5.4, 16), (0, 0, 0), 'grey', 0.4)
        for i in range(3):
            for j in range(2):
                cyl(3.3, 1.2, (-8 + i * 8, -2.8, -4 + j * 8), 'light', seg=12, bev=0.25, rot=(90, 0, 0))
        # aim the panel at the pitch (its front faces -y in local space)
        ang = math.atan2(-y, -x) - math.atan2(-1, 0) + math.pi
        for o in PARTS[m:]:
            o.data.transform(o.matrix_basis); o.matrix_basis = Matrix.Identity(4)
            o.data.transform(Matrix.Translation((x, y, hT - 4)) @ Matrix.Rotation(ang, 4, 'Z') @ Matrix.Rotation(math.radians(-15), 4, 'X'))
done("LM2_Stadium_Lights")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/stadium.blend")
