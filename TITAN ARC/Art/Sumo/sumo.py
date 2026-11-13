# SUMO RING ARENA from sheet se_sumo_sheet (ChatGPT, 13 Nov). Units = studs at fighter scale 1. Front = -y. z up.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
W = 60.0; HB = 6.0; INSET = 1.4          # platform: bottom width W, top width W-2*INSET (sloped sides), height HB
RR = 20.0                                 # rope circle radius (ring)
made = []
def done(n): made.append(join(n))
# PLATFORM: sloped clay block (frustum) + a thin lighter top
def frustum(wb, wt, h, z0, col):
    b, t = wb / 2, wt / 2
    v = [(-b, -b, z0), (b, -b, z0), (b, b, z0), (-b, b, z0), (-t, -t, z0 + h), (t, -t, z0 + h), (t, t, z0 + h), (-t, t, z0 + h)]
    f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return poly(v, f, col, (0, 0, 0), 0.35)
frustum(W, W - 2 * INSET, HB, 0, 'cream2')
# STEPS: 3 steps in the middle of each side, cut into the slope (they stick out a little like the sheet)
m = mark()
for k in range(3):            # k=0 lowest, outermost
    h = HB * (k + 1) / 3
    y = -W / 2 - 3.2 + k * 2.3
    box((16.0, 2.5, h), (0, y, h / 2), 'cream', 0.22)
    box((15.6, 2.7, 0.35), (0, y, h - 0.1), 'cream2', 0.1)   # darker nosing line on each tread
ring4(m)
done("Sumo_Base")
# FLOOR inside the ring: slightly lighter disc + two white starting lines
cyl(RR - 0.6, 0.25, (0, 0, HB + 0.1), 'cream', seg=48, bev=0.05)
for x in (-3.0, 3.0): box((0.9, 6.0, 0.18), (x, 0, HB + 0.3), 'white', 0.08)
done("Sumo_Floor")
# ROPE: braided straw rope lying flat in a perfect circle (a core + slanted knots)
torus(RR, 1.35, (0, 0, HB + 1.0), 'yellow2', rot=(0, 0, 0), maj=72, mn=8)
N = 40
for i in range(N):
    a = 2 * math.pi * i / N
    o = blob(1.0, (0, 0, 0), 'yellow', sub=2, sq=(2.0, 1.35, 1.35), seed=0)
    o.data.transform(Matrix.Rotation(math.radians(38), 4, 'Y'))
    o.data.transform(Matrix.Translation((RR * math.cos(a), RR * math.sin(a), HB + 1.25)) @ Matrix.Rotation(a + math.pi / 2, 4, 'Z'))
done("Sumo_Rope")
# POSTS: four chunky round posts at the corners (red front-left, blue front-right, black back-left, white back-right)
P = W / 2 - INSET - 5.0; PH = 16.0
cols = {(-1, -1): 'red', (1, -1): 'blue', (-1, 1): 'black', (1, 1): 'white'}
for (sx, sy), c in cols.items():
    x, y = sx * P, sy * P
    cyl(2.5, 1.0, (x, y, HB + 0.5), c, seg=16, bev=0.3)            # foot ring
    cyl(2.0, PH, (x, y, HB + PH / 2), c, seg=16, bev=0.3)
    cyl(2.45, 1.3, (x, y, HB + PH + 0.3), 'gold', seg=16, bev=0.3)  # gold collar
    blob(2.1, (x, y, HB + PH + 2.9), 'gold', sub=2)                 # gold ball cap
done("Sumo_Posts")
# BAND: purple fabric band with gold trim between the post tops, a gentle sag
BZ = HB + PH - 3.2; BH = 3.0
def band(a, b):
    a, b = Vector(a), Vector(b); n = 6
    for k in range(n):
        t0, t1 = k / n, (k + 1) / n
        p0, p1 = a.lerp(b, t0), a.lerp(b, t1)
        s0, s1 = 0.9 * math.sin(math.pi * t0), 0.9 * math.sin(math.pi * t1)
        p0.z -= s0; p1.z -= s1
        c = (p0 + p1) / 2; L = (p1 - p0).length + 0.12; d = (p1 - p0).normalized()
        R = d.to_track_quat('X', 'Z').to_matrix().to_4x4()
        for (h, dz, col, th) in ((BH, 0, 'violet', 0.45), (0.38, BH / 2 + 0.1, 'gold', 0.6), (0.38, -BH / 2 - 0.1, 'gold', 0.6)):
            o = box((L, th, h), (0, 0, 0), col, 0.1)
            o.data.transform(Matrix.Translation(c + Vector((0, 0, dz))) @ R)
cs = [(-P, -P), (P, -P), (P, P), (-P, P)]
for i in range(4):
    (x0, y0), (x1, y1) = cs[i], cs[(i + 1) % 4]
    d = Vector((x1 - x0, y1 - y0, 0)).normalized() * 2.1
    band((x0 + d.x, y0 + d.y, BZ), (x1 - d.x, y1 - d.y, BZ))
done("Sumo_Band")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); tot += len(o.data.loop_triangles); print("LM2", o.name, len(o.data.loop_triangles), [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/sumo/sumo.blend")
