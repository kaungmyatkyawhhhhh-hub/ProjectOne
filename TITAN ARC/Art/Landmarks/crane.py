# HARBOUR CRANE (Industrial landmark) from sheet se_lm_crane (ChatGPT, 13 Nov). 1 sheet px = 0.43 studs. Boom points +x (over the water).
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
S = 0.43; GY = 775; CX = 822
def X(px): return (px - CX) * S
def Z(py): return (GY - py) * S
LX, LY = 30, 38
zb0, zb1 = Z(554), Z(528)
def beam(a, b, t, col='yellow', bev=0.4):
    a, b = Vector(a), Vector(b); c = (a + b) / 2; L = (b - a).length
    o = box((t, t, L), (0, 0, 0), col, bev)
    o.matrix_world = Matrix.Translation(c) @ (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
    return o
# LEGS + braces + feet
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * LX, sy * LY
        box((8, 8, zb0 - 14), (x, y, 14 + (zb0 - 14) / 2), 'yellow', 0.7)
        # foot: red/white striped block + 2 wheels
        for k in range(5):
            box((20 / 5, 14, 8), (x - 10 + 2 + k * 4, y, 9), 'red' if k % 2 == 0 else 'white', 0.3)
        box((21, 15, 2.2), (x, y, 14), 'red2', 0.5)
        for wx in (-5.5, 5.5): cyl(4.2, 5, (x + wx, y, 4.2), 'tyre', seg=12, bev=0.4, rot=(90, 0, 0))
# portal beams along y (front/back pairs) and along x at the bottom frame
for sx in (-1, 1):
    box((7, 2 * LY + 6.5, 6), (sx * LX, 0, zb0 - 3), 'yellow', 0.6)
    beam((sx * LX, -LY, 12), (sx * LX, LY, zb0 - 22), 3.2); beam((sx * LX, LY, 12), (sx * LX, -LY, zb0 - 22), 3.2)
    box((5, 2 * LY, 4), (sx * LX, 0, 12), 'yellow', 0.5)
for sy in (-1, 1):
    beam((-LX, sy * LY, 14), (LX, sy * LY, 54), 3.2); beam((LX, sy * LY, 14), (-LX, sy * LY, 54), 3.2)
    box((2 * LX, 4, 4), (0, sy * LY, 54), 'yellow', 0.5)
done("LM2_Crane_Legs")
# BOOM + apex + tie rods + counterweight + cabin
bx0, bx1 = X(692), X(1142)
box((bx1 - bx0, 2 * LY + 2, 3.5), (( bx0 + bx1) / 2 * 0 + (bx0 + 70) / 2, 0, zb1 - 1.75), 'yellow', 0.5) if False else None
for sy in (-1, 1):
    box((bx1 - bx0, 6, zb1 - zb0), ((bx0 + bx1) / 2, sy * 7, (zb0 + zb1) / 2), 'yellow', 0.6)
for k in range(12):
    x = bx0 + 4 + k * (bx1 - bx0 - 8) / 11
    box((2.2, 14, 2.2), (x, 0, zb0 + 1.5), 'yellow2', 0.2)
box((6, 18, zb1 - zb0 + 2), (bx1 - 1, 0, (zb0 + zb1) / 2), 'yellow', 0.6)
# cross beam across the top of the legs (the portal deck) under the boom
for sy in (-1, 1): box((2 * LX + 6.5, 6, 6), (0, sy * LY, zb0 - 3), 'yellow', 0.6)
# apex frame (pyramid of 4 struts) with a red cap
ax, az = X(832), Z(427)
for (px_, py_) in [(-LX, -LY), (-LX, LY), (LX, -LY), (LX, LY)]:
    beam((px_ * 0.55, py_ * 0.2, zb1), (ax, 0, az - 2), 3.4)
box((7, 7, 5), (ax, 0, az), 'red', 0.6)
for sy in (-1, 1):
    beam((ax, sy * 1.5, az - 1), (bx1 - 2, sy * 7, zb1 + 0.5), 1.6, 'yellow2', 0.2)
    beam((ax, sy * 1.5, az - 1), (bx0 + 10, sy * 7, zb1 + 0.5), 1.6, 'yellow2', 0.2)
# counterweight (grey ribbed block on the back end)
cw0, cw1 = X(692), X(745)
box((cw1 - cw0, 20, Z(494) - Z(534)), ((cw0 + cw1) / 2, 0, (Z(494) + Z(534)) / 2), 'grey', 0.8)
for k in range(3): box((0.6, 20.6, Z(494) - Z(534) - 2), (cw0 + (k + 1) * (cw1 - cw0) / 4, 0, (Z(494) + Z(534)) / 2), 'grey2', 0)
# cabin under the boom near the legs, window looking out along +x
c0, c1 = X(884), X(955)
box((c1 - c0, 14, Z(550) - Z(614)), ((c0 + c1) / 2, 0, (Z(550) + Z(614)) / 2), 'white', 0.8)
box((1.2, 11, (Z(550) - Z(614)) * 0.6), (c1 + 0.2, 0, (Z(550) + Z(614)) / 2 + 1.5), 'glass', 0.3)
for sy in (-1, 1): box((c1 - c0 - 6, 1.2, (Z(550) - Z(614)) * 0.5), ((c0 + c1) / 2 + 1, sy * 7.2, (Z(550) + Z(614)) / 2 + 2), 'glass', 0.3)
box((4, 4, zb0 - Z(550)), ((c0 + c1) / 2, 0, (zb0 + Z(550)) / 2), 'grey2', 0.3)
done("LM2_Crane_Boom")
# TROLLEY + cables + container
tx = (X(1002) + X(1109)) / 2
box((12, 18, 5), (tx, 0, zb0 - 2.5), 'red', 0.6)
for sx in (-1, 1):
    for sy in (-1, 1): cyl(0.4, zb0 - 5 - Z(621), (tx + sx * 3.5, sy * 4, (zb0 - 5 + Z(621)) / 2), 'black', seg=6, bev=0)
box((16, 14, 2), (tx, 0, Z(621) + 1), 'grey2', 0.4)
k0, k1 = X(1002), X(1109)
box((k1 - k0, 18, Z(621) - Z(681)), ((k0 + k1) / 2, 0, (Z(621) + Z(681)) / 2), 'blue', 0.5)
for k in range(11):
    x = k0 + 2 + k * (k1 - k0 - 4) / 10
    for sy in (-1, 1): box((1.0, 0.8, Z(621) - Z(681) - 2), (x, sy * 9.2, (Z(621) + Z(681)) / 2), 'blue2', 0)
for sx in (-1, 1): box((1.0, 18.4, Z(621) - Z(681)), (k1 if sx > 0 else k0, 0, (Z(621) + Z(681)) / 2), 'blue2', 0.2)
done("LM2_Crane_Box")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/crane.blend")
