# SCHOOL (Suburbs landmark) from sheet se_lm_school (ChatGPT, 13 Nov). 1 sheet px = 0.2 studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
made = []
def done(n): made.append(join(n))
S = 0.2
W, D = 371 * S, 172 * S            # 74.2 x 34.4
zb, z1, z2, zp = 2.0, 2.0 + 63 * S, 2.0 + 127 * S, 2.0 + 127 * S + 17 * S
fy = -D / 2
def win_row(z, xs, y, face=-1):
    for x in xs:
        box((40 * S, 0.8, 40 * S), (x, y + face * 0.25, z), 'white', 0.25)
        box((30 * S, 0.9, 30 * S), (x, y + face * 0.45, z), 'glass', 0.08)
        box((5 * S, 1.0, 22 * S), (x - 7 * S, y + face * 0.55, z + 1 * S), 'glass2', 0.03, rot=(0, 22, 0))
        box((44 * S, 1.4, 5 * S), (x, y + face * 0.6, z - 22 * S), 'white', 0.2)        # sill
def bricks(z0, z1_, w, d):
    for z in [z0 + k * 3.2 for k in range(1, int((z1_ - z0) / 3.2))]:
        box((w + 0.25, d + 0.25, 0.22), (0, 0, z), 'wall_brick2', 0)
XS = [(552 - 697) * S, (607 - 697) * S, (787 - 697) * S, (843 - 697) * S]   # window centres, building centre x=697
SX = [-D / 2 + 0.27 * D, -D / 2 + 0.73 * D]
# F1: cream plinth + ground floor walls + lower windows (front, back, sides)
box((W + 1.6, D + 1.6, zb), (0, 0, zb / 2), 'cream', 0.4)
box((W, D, z1 - zb), (0, 0, (zb + z1) / 2), 'wall_brick', 0.3)
bricks(zb, z1, W, D)
win_row(zb + 37 * S, XS, fy); win_row(zb + 37 * S, XS, -fy, face=1)
for sx in (-1, 1):
    m = mark()
    for y in SX:
        box((0.8, 40 * S, 40 * S), (sx * W / 2 + sx * 0.25, y, zb + 37 * S), 'white', 0.25)
        box((0.9, 30 * S, 30 * S), (sx * W / 2 + sx * 0.45, y, zb + 37 * S), 'glass', 0.08)
        box((1.4, 44 * S, 5 * S), (sx * W / 2 + sx * 0.6, y, zb + 15 * S), 'white', 0.2)
box((W + 0.8, D + 0.8, 1.0), (0, 0, z1), 'cream', 0.3)                                # floor band
done("LM2_School_F1")
# F2: upper floor + parapet + flat roof + roof slab
box((W, D, z2 - z1), (0, 0, (z1 + z2) / 2), 'wall_brick', 0.3)
bricks(z1, z2, W, D)
win_row(z1 + 33 * S, XS, fy); win_row(z1 + 33 * S, XS, -fy, face=1)
for sx in (-1, 1):
    for y in SX:
        box((0.8, 40 * S, 40 * S), (sx * W / 2 + sx * 0.25, y, z1 + 33 * S), 'white', 0.25)
        box((0.9, 30 * S, 30 * S), (sx * W / 2 + sx * 0.45, y, z1 + 33 * S), 'glass', 0.08)
        box((1.4, 44 * S, 5 * S), (sx * W / 2 + sx * 0.6, y, z1 + 11 * S), 'white', 0.2)
# parapet (cream frame) + grey roof inside + corner caps
pt = 2.2
for (sx, sy, w, d) in [(0, -1, W + 2, pt), (0, 1, W + 2, pt), (-1, 0, pt, D + 2), (1, 0, pt, D + 2)]:
    box((w, d, zp - z2 + 1), (sx * (W / 2), sy * (D / 2), (z2 + zp + 1) / 2), 'cream', 0.4)
box((W - 2, D - 2, 0.6), (0, 0, z2 + 0.6), 'grey', 0.1)
for sx in (-1, 1):
    for sy in (-1, 1): box((3.4, 3.4, 4.6), (sx * W / 2, sy * D / 2, zp + 0.2), 'cream2', 0.5)
for (x, y) in [(-W * 0.3, D * 0.18), (W * 0.32, -D * 0.1)]: box((3, 3, 1.6), (x, y, z2 + 1.6), 'grey2', 0.3)    # vents
done("LM2_School_F2")
# ENTRANCE: protruding cream block, columns, blue double doors, gable pediment, 3 steps, bushes
ex0, ew, ed = 0, 121 * S, 25 * S
ey = fy - ed / 2
box((ew, ed, 108 * S), (0, ey, zb + 54 * S), 'cream', 0.4)
for x in (-ew / 2 + 2, -ew / 2 + 5.2, ew / 2 - 5.2, ew / 2 - 2):
    cyl(1.2, 74 * S, (x, fy - ed - 0.8, zb + 37 * S + 1), 'white', seg=10, bev=0.2)
box((57 * S, 1.0, 55 * S), (0, fy - ed - 0.2, zb + 27.5 * S + 0.5), 'cream2', 0.2)
for sx in (-1, 1):
    box((26 * S, 1.0, 50 * S), (sx * 14 * S, fy - ed - 0.6, zb + 25 * S + 0.8), 'blue', 0.2)
    box((1.2, 1.2, 14 * S), (sx * 3.4 * S * 2, fy - ed - 1.2, zb + 30 * S), 'chrome', 0.15)
# pediment: triangular prism on top of the entrance
pw, ph = ew + 2, 40 * S
v = [(-pw / 2, 0, 0), (pw / 2, 0, 0), (0, 0, ph), (-pw / 2, ed + 1, 0), (pw / 2, ed + 1, 0), (0, ed + 1, ph)]
poly(v, [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)], 'cream', loc=(0, fy - ed - 0.5, zb + 108 * S), bev=0.3)
box((pw + 1, ed + 2, 1.2), (0, ey, zb + 108 * S), 'white', 0.3)
v2 = [(-pw / 2 + 3, 0, 0.6), (pw / 2 - 3, 0, 0.6), (0, 0, ph - 2)]
poly(v2 + [(a, -0.5, c) for (a, b, c) in v2], [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], 'cream2', loc=(0, fy - ed - 0.6, zb + 108 * S), bev=0.1)
for k in range(3):
    box((ew + 6 - k * 3, 3.2 + (2 - k) * 2.6, 1.0), (0, fy - ed - 1.6 - (2 - k) * 1.3 - 1.2, 0.5 + k * 1.0 + 0.0), 'cream' if k % 2 == 0 else 'cream2', 0.3)
for sx in (-1, 1):
    blob(4.2, (sx * (ew / 2 + 4), fy - 4, 4.2), 'leaf', sub=2, seed=sx + 3)
    blob(2.6, (sx * (ew / 2 + 6.2), fy - 5.2, 2.6), 'leaf2', sub=2, seed=sx + 7)
done("LM2_School_Entrance")
# CLOCK TOWER: cream block on the roof middle, a clock face per side, teal pyramid roof, gold ball
cw, ch = 77 * S, 50 * S
box((cw, cw, ch), (0, 0, zp + ch / 2), 'cream', 0.4)
box((cw + 1.6, cw + 1.6, 1.4), (0, 0, zp + ch), 'cream2', 0.3)
m = mark()
cyl(5.6, 0.8, (0, -cw / 2 - 0.3, zp + ch / 2), 'gold', seg=20, bev=0.2, rot=(90, 0, 0))
cyl(4.9, 0.9, (0, -cw / 2 - 0.45, zp + ch / 2), 'white', seg=20, bev=0.1, rot=(90, 0, 0))
box((0.6, 0.6, 3.6), (0, -cw / 2 - 1.0, zp + ch / 2 + 1.6), 'black', 0.1)
box((0.6, 0.6, 2.8), (1.0, -cw / 2 - 1.0, zp + ch / 2 - 1.0), 'black', 0.1, rot=(0, -40, 0))
ring4(m)
hip(cw, cw, 6.2, (0, 0, zp + ch + 0.7), 'roof_teal', over=1.0, top=0.03)
blob(1.9, (0, 0, zp + ch + 8.6), 'gold', sub=2)
done("LM2_School_Clock")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/school.blend")
