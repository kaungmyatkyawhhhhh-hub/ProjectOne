# MEGA BITE landmark: the Crystal Arch (sheet: mb_sheet_lm_crystal_arch.png). Hand-built from the sheet's measurements
# (side view 6.467 px/stud with the arch 150 studs wide). Axes: X along the arch (centre 0), Y depth (front = -Y), Z up.
import sys; sys.path.insert(0, '/tmp/claude-0/lm')
import lmkit as K, math, random, bmesh, bpy
from mathutils import Vector, Matrix, noise
OUT = '/tmp/claude-0/lm2/arch'
K.reset()
K.mat('Rock', (60, 72, 138)); K.mat('RockDark', (42, 50, 102)); K.mat('CryCyan', (48, 226, 236)); K.mat('CryPurple', (156, 112, 238)); K.mat('CryPink', (246, 132, 204))
K.mat('Mush', (252, 204, 62)); K.mat('Stem', (252, 234, 176)); K.mat('Spot', (255, 244, 190)); K.mat('CoralY', (250, 182, 44)); K.mat('Shelf', (238, 108, 112))
K.mat('CoralP', (246, 100, 116)); K.mat('Star', (252, 208, 54)); K.mat('Flower', (44, 214, 230))
rnd = random.Random(5)
# ---- the rock arch: rings in radial planes around the middle of the opening
def r_out(ph):
    c, s = abs(math.cos(ph)), abs(math.sin(ph)); a = 75.5 if math.cos(ph) < 0 else 73.0; p = 1.58 if math.cos(ph) < 0 else 1.66
    return 1 / ((c / a) ** p + (s / 57.0) ** p) ** (1 / p)
def r_in(ph):
    c, s = abs(math.cos(ph)), abs(math.sin(ph)); a = 28.5 if math.cos(ph) < 0 else 27.0
    return 1 / ((c / a) ** 3.0 + (s / 43.0) ** 3.0) ** (1 / 3.0)
def foot(ph): return max(0.0, min(1.0, (abs(math.cos(ph)) - 0.3) / 0.55)) ** 1.4
def depth(ph): return 11.3 + 13.2 * foot(ph)
def ycen(ph): return 11.7 * (1 - foot(ph))
NR, NS = 21, 8
X0 = 1.5
rings = []
for i in range(NR):
    ph = math.pi * i / (NR - 1)
    ro, ri = r_out(ph), r_in(ph); rc, rt = (ro + ri) / 2, (ro - ri) / 2
    rad = Vector((math.cos(ph), 0, math.sin(ph)))
    pts = []
    for k in range(NS):
        a = 2 * math.pi * k / NS + 0.31 + 0.39 * (i % 2)
        p = rad * (rc + math.cos(a) * rt) + Vector((X0, ycen(ph) + math.sin(a) * depth(ph) * (1.0 - 0.12 * abs(math.cos(a))), 0))
        n = noise.noise(p * 0.07 + Vector((3.1, 1.7, 9.2))) + 0.6 * rnd.uniform(-1, 1)
        p += (rad * math.cos(a) + Vector((0, math.sin(a), 0))) * n * 3.4 + Vector((rad.z, 0, -rad.x)) * rnd.uniform(-2.2, 2.2)
        if i in (0, NR - 1): p.z = 0.0
        pts.append(p)
    rings.append(pts)
arch = K.loft(rings, 'Arch', 'Rock')
# rock chunks around the feet (the bases are lumpy in the sheet)
for (x, y, s) in [(-62, -14, 9), (-50, -18, 7.5), (-44, 12, 8), (-68, 8, 7), (-29.0, 5, 10.5), (-29.5, 16, 9), (-57, 17, 9.5), (-66, -2, 8), (60, -15, 9), (48, -18, 7), (44, 13, 8), (68, 6, 7), (32.5, 5, 10.5), (33, 16, 9), (57, 17, 9.5), (66, -2, 8)]:
    K.rock(Vector((x, y, s * 0.3)), (s, s * 0.9, s * 0.75), 'Chunk', 'RockDark', seed=int(x * 3 + y), sub=2, rough=0.22)
def top_pt(x, y=None):          # a point on the upper surface of the arch at horizontal position x
    xr = x - X0
    ph = math.acos(max(-1, min(1, xr / 73.0))) if abs(xr) < 73 else (0 if xr > 0 else math.pi)
    for _ in range(12):            # solve r_out(ph) * cos(ph) = x - X0
        ph -= (r_out(ph) * math.cos(ph) - xr) / (-r_out(ph) * math.sin(ph) - 1e-6) * 0.6
        ph = max(0.02, min(math.pi - 0.02, ph))
    return Vector((x, ycen(ph) if y is None else y, r_out(ph) * math.sin(ph))), ph
def crystal(base, d, ln, r, key, seed=0):
    K.crystal(base, Vector(d), ln, r, 'Cry', key, sides=6, tip=0.34, seed=seed)
# ---- crystals on the crown
for (x, ln, r, key, lean, yy) in [(3, 21.0, 5.6, 'CryCyan', 0.02, 0), (-7.5, 14.0, 4.0, 'CryPurple', -0.3, 2), (12.5, 13.5, 3.8, 'CryPurple', 0.28, 1), (20.5, 11.5, 3.6, 'CryPink', 0.6, -2),
                              (-15.0, 9.5, 3.0, 'CryPink', -0.55, -3), (5, 9.0, 2.6, 'CryPurple', 0.1, -7), (0, 13.0, 3.4, 'CryPurple', -0.05, 11), (2, 12.0, 3.4, 'CryCyan', 0.0, 19)]:
    p, ph = top_pt(x); crystal(p + Vector((0, yy, -2.0)), (lean, yy * 0.05, 1), ln, r, key, seed=int(x))
# ---- crystals at the feet (front side)
crystal(Vector((-60.5, -13, 4)), (-0.05, -0.12, 1), 27.5, 6.4, 'CryCyan', seed=1)
crystal(Vector((-66.5, -9, 5)), (-0.2, -0.1, 1), 15, 4.0, 'CryPurple', seed=2)
crystal(Vector((-51, -16, 3.5)), (0.25, -0.25, 1), 17, 4.2, 'CryPurple', seed=3)
crystal(Vector((-45.5, -18, 2.5)), (0.5, -0.4, 1), 11, 3.2, 'CryPink', seed=4)
crystal(Vector((55.5, -13, 4)), (0.04, -0.12, 1), 28.5, 6.6, 'CryPink', seed=1)
crystal(Vector((46.5, -14, 4)), (-0.3, -0.15, 1), 22, 4.6, 'CryPurple', seed=2)
crystal(Vector((65.5, -12, 3)), (0.35, -0.2, 1), 19, 4.6, 'CryCyan', seed=3)
crystal(Vector((60, -19, 2.2)), (0.1, -0.6, 1), 9, 2.8, 'CryPurple', seed=5)
# ---- glowing mushrooms
def mushroom(c, r, h):
    K.lathe([(r * 0.36, 0), (r * 0.28, h * 0.6), (r * 0.34, h * 0.66)], 'Stem', 'Stem', sides=7).location = c
    K.lathe([(r * 0.92, h * 0.6), (r * 1.0, h * 0.68), (r * 0.82, h * 0.86), (r * 0.42, h * 0.98), (0.05, h * 1.02)], 'Cap', 'Mush', sides=10).location = c
    for j in range(4):
        a = j * 1.57 - 1.2; rr = r * (0.5 + 0.16 * (j % 2))
        q = c + Vector((math.cos(a) * rr, math.sin(a) * rr, h * (0.9 - 0.045 * (j % 2))))
        K.rock(q, (r * 0.2, r * 0.2, r * 0.09), 'Spot', 'Spot', seed=j, sub=1, rough=0.0, flat_bottom=False)
for sx in (-1, 1):
    mushroom(Vector((sx * 57.5 + 1, -19.0, 0)), 5.8, 13.0); mushroom(Vector((sx * 49.5, -20.0, 0)), 3.6, 8.0); mushroom(Vector((sx * 64.5, -18.5, 0)), 2.6, 5.5)
# ---- yellow branch corals
def branch(c, key, s=1.0, n=4, up=Vector((0, 0, 1))):
    q = Vector((0, 0, 1)).rotation_difference(up.normalized())
    for j in range(n):
        a = 2 * math.pi * j / n + rnd.uniform(-0.3, 0.3)
        d = q @ Vector((math.cos(a), math.sin(a), 0)); u = q @ Vector((0, 0, 1))
        p1 = c + u * 2.2 * s; p2 = p1 + d * 2.4 * s + u * 2.6 * s; p3 = p2 + d * 0.6 * s + u * 2.8 * s
        K.tube([c, p1, p2, p3], [0.95 * s, 0.85 * s, 0.75 * s, 0.6 * s], 'Branch', key, sides=4)
for (x, s) in [(-28.8, 1.45), (36.9, 1.45)]:
    p, ph = top_pt(x); branch(p + Vector((0, -2, -1.0)), 'CoralY', s)
for sx in (-1, 1):
    branch(Vector((sx * 71.5, -12, 0)), 'CoralY', 1.0); branch(Vector((sx * 41, -15, 0)), 'CoralY', 0.9)
branch(Vector((-49.5, -18.5, 22.0)), 'CoralP', 1.25, up=Vector((-0.3, -0.7, 1)))
# ---- pink shelf fungi on the shoulders
def shelf(x, z, r):       # a flat pink shelf fungus sticking out of the front of the rock (positions read from the sheet)
    ph = math.atan2(z, x - X0)
    c = Vector((x, ycen(ph) - depth(ph) * 0.62, z))
    K.disc(c, Vector((0, -0.08, 1)), r, 1.7, 'Shelf', 'Shelf', sides=10, squash=0.8)
for (x, z, r) in [(-33.8, 47.6, 8.8), (-42.3, 43.6, 3.6), (40.7, 45.2, 8.5), (47.7, 40.8, 4.6)]:
    shelf(x, z, r)
# ---- yellow stars on the front face + small flowers at the feet
def star(c, r, n=Vector((0, -1, 0.15))):
    n = n.normalized(); q = Vector((0, 0, 1)).rotation_difference(n)
    bm = bmesh.new(); pts = []
    for i in range(10):
        a = 2 * math.pi * i / 10 + math.pi / 2; rr = r if i % 2 == 0 else r * 0.46
        pts.append(c + q @ Vector((math.cos(a) * rr, math.sin(a) * rr, 0)))
    f = [bm.verts.new(p + n * 0.5) for p in pts]; b = [bm.verts.new(p - n * 0.9) for p in pts]; ctr = bm.verts.new(c + n * 1.3)
    for i in range(10):
        j = (i + 1) % 10; bm.faces.new((f[i], f[j], ctr)); bm.faces.new((f[j], f[i], b[i], b[j]))
    bm.faces.new(b)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    K.obj_from_bm(bm, 'Star', 'Star')
for (x, z, r) in [(-35.5, 39.0, 4.3), (39.5, 35.0, 4.3)]:
    ph = math.atan2(z, x - X0); star(Vector((x, ycen(ph) - depth(ph) - 1.2, z)), r)
    for k, (dx, dz) in enumerate([(-1.5, -6.0), (1.2, -7.6), (3.2, -5.6)]):
        K.rock(Vector((x + dx, ycen(ph) - depth(ph) - 0.6, z + dz)), (0.75, 0.6, 0.75), 'Dot', 'Star', seed=k, sub=1, rough=0.0, flat_bottom=False)
def flower(c, r):
    for j in range(5):
        a = 2 * math.pi * j / 5
        K.rock(c + Vector((math.cos(a) * r * 0.62, math.sin(a) * r * 0.62, 0.2)), (r * 0.42, r * 0.42, r * 0.2), 'Petal', 'Flower', seed=j, sub=1, rough=0.0, flat_bottom=False)
    K.rock(c + Vector((0, 0, 0.5)), (r * 0.3, r * 0.3, r * 0.24), 'Eye', 'Mush', seed=9, sub=1, rough=0.0, flat_bottom=False)
for sx in (-1, 1):
    for (x, y, z) in [(38, -18, 4.2), (34.5, -20.5, 2.4), (42, -21.5, 2.0)]: flower(Vector((sx * x, y, z)), 2.3)
K.finish(38)
obs = K.join_by_key()
print('TRIS', K.tris())
K.export_obj(OUT + '/model.obj')
bpy.ops.wm.save_as_mainfile(filepath=OUT + '/model.blend')
