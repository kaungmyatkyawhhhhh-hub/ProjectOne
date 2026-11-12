# CROWN TOWER (Crown Core landmark) from sheet se_lm_crowntower (ChatGPT, 13 Nov). Units: sheet studs (scaled in Studio).
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
made = []
def done(n): made.append(join(n))
def tier_box(w, z0, h, col='cream', quoin='cream2'):
    box((w, w, h), (0, 0, z0 + h / 2), col, 0.35)
    for sx in (-1, 1):
        for sy in (-1, 1):
            for k in range(int(h // 4)):
                box((1.6, 1.6, 1.8), (sx * w / 2, sy * w / 2, z0 + 1.2 + k * 4), quoin, 0)
def gold_slab(w, z0, h=4.5): box((w, w, h), (0, 0, z0 + h / 2), 'gold', 0.6)
def rails_around(w, z0, h=7):
    m = mark(); railing(w, z0, -w / 2 + 0.4, h=h, posts=int(w / 4)); ring4(m)
# T0 base: steps + turrets
box((92, 92, 4.4), (0, 0, 2.2), 'cream', 0.5)
box((84, 84, 4.4), (0, 0, 6.6), 'cream2', 0.5)
box((77, 77, 4.0), (0, 0, 10.8), 'cream', 0.5)
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * 30.5, sy * 30.5
        cyl(7.8, 3.4, (x, y, 14.5), 'cream2', seg=16, bev=0.4)
        cyl(6.5, 30, (x, y, 28), 'cream', seg=16, bev=0.4)
        cyl(7.3, 1.8, (x, y, 43.6), 'gold', seg=16, bev=0.4)
        cyl(8.2, 16, (x, y, 52.5), 'gold', seg=16, bev=0.3, r2=0.4)
        blob(1.3, (x, y, 61.2), 'gold', sub=2)
        # turret slit windows facing out
        m = mark(); box((2.2, 0.8, 6), (x + sx * 6.3 * 0.707, y + sy * 6.3 * 0.707, 32), 'blue', 0.2, rot=(0, 0, 45 if sx == sy else -45))
done("LM2_Crown_T0")
# T1 (12.8..51.8): body 46.7 wide, big arched window per face, railing at its foot
z1 = 12.8
tier_box(46.7, z1, 39)
m = mark(); arch_window(0, z1 + 9.5, 23, 26, -46.7 / 2); ring4(m)
rails_around(48.5, z1, h=7.5)
done("LM2_Crown_T1")
# T2: gold slab, railing, body 34 wide, window 18x19
z2 = z1 + 39
gold_slab(51, z2)
rails_around(48, z2 + 4.5, h=7.5)
tier_box(34, z2 + 4.5, 28.5)
m = mark(); arch_window(0, z2 + 6.5, 18, 19, -34 / 2); ring4(m)
done("LM2_Crown_T2")
# T3: gold slab, railing, body 23 wide, window 12.5 x 21.6
z3 = z2 + 4.5 + 28.5
gold_slab(38, z3)
rails_around(35.5, z3 + 4.5, h=7.5)
tier_box(23, z3 + 4.5, 26)
m = mark(); arch_window(0, z3 + 6.5, 12.5, 20, -23 / 2); ring4(m)
done("LM2_Crown_T3")
# T4 crown: gold slab, violet drum, crown band with 6 points + red balls, blue front gem, diamond
z4 = z3 + 4.5 + 26
gold_slab(27, z4)
cyl(11, 7, (0, 0, z4 + 4.5 + 3.5), 'violet', seg=24, bev=0.8)
zc = z4 + 4.5 + 7
cyl(16, 11.4, (0, 0, zc + 5.7), 'gold', seg=24, bev=0.8, r2=17.5)
cyl(13.5, 11.6, (0, 0, zc + 5.9), 'yellow2', seg=24, bev=0.3, r2=15)   # inner shade (reads as the crown's hollow)
for k in range(6):
    a = math.pi / 2 + k * math.pi / 3 + math.pi / 6
    x, y = math.cos(a) * 16.5, math.sin(a) * 16.5
    poly([(-5, -1.2, 0), (5, -1.2, 0), (0, -1.2, 9), (-5, 1.2, 0), (5, 1.2, 0), (0, 1.2, 9)],
         [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], 'gold', loc=(0, 0, 0), bev=0.5)
    o = PARTS[-1]; o.matrix_world = Matrix.Translation((x, y, zc + 10.5)) @ Matrix.Rotation(a - math.pi / 2, 4, 'Z')
    blob(3.4, (math.cos(a) * 16.5, math.sin(a) * 16.5, zc + 21.5), 'red', sub=2, seed=k)
# front gem (faces -y)
blob(3.6, (0, -17.8, zc + 6), 'blue', sub=1, sq=(1, 0.55, 1.25))
for x in (-10, 10): blob(1.7, (x, -17.4, zc + 6), 'red', sub=1, seed=11)
# diamond on top
cyl(7.5, 4, (0, 0, zc + 19 + 2), 'glass2', seg=8, bev=0.3, r2=5.5)
cyl(0.6, 8.5, (0, 0, zc + 19 - 4.25), 'glass', seg=8, bev=0.2, r2=7.5)
done("LM2_Crown_T4")
import json
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions], round(o.location.z, 1))
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/crowntower.blend")
