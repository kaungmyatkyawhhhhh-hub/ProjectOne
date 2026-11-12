# MEGA BITE landmark: the Whale Graveyard skeleton (sheet: mb_sheet_lm_whale_skeleton.png). Hand-built from the sheet's
# measurements (side view 7.425 px/stud, top view 4.175 px/stud; tables below are read from the sheet's pixels).
# Model axes: X = length (snout tip at 0, tail +X), Y = width, Z = up (sand = 0). 200 studs long.
import sys; sys.path.insert(0, '/tmp/claude-0/lm')
import lmkit as K, math, random, bmesh, bpy
from mathutils import Vector, Matrix
OUT = '/tmp/claude-0/lm2/skel'
K.reset()
K.mat('Bone', (243, 226, 190)); K.mat('BoneDark', (92, 64, 60)); K.mat('AnemPurple', (160, 84, 230)); K.mat('AnemPink', (255, 104, 150))
K.mat('AnemTeal', (30, 200, 210)); K.mat('Crystal', (70, 235, 250)); K.mat('CoralOrange', (250, 146, 56)); K.mat('CoralPink', (250, 104, 112))
K.mat('CoralYellow', (250, 190, 44)); K.mat('Rock', (52, 84, 150)); K.mat('Kelp', (20, 165, 150))
rnd = random.Random(11)
def tab(t, x):
    if x <= t[0][0]: return t[0][1]
    for (a, va), (b, vb) in zip(t[:-1], t[1:]):
        if x <= b: u = (x - a) / (b - a); return va + (vb - va) * u
    return t[-1][1]
def ctab(t, x):   # Catmull-Rom through the table (smooth outlines from few points)
    xs = [p[0] for p in t]
    if x <= xs[0]: return t[0][1]
    if x >= xs[-1]: return t[-1][1]
    i = max(j for j in range(len(xs) - 1) if xs[j] <= x)
    p0 = t[max(i - 1, 0)][1]; p1 = t[i][1]; p2 = t[i + 1][1]; p3 = t[min(i + 2, len(t) - 1)][1]
    u = (x - xs[i]) / (xs[i + 1] - xs[i])
    return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3)
# ---------------------------------------------------------------- skull (upper): loft of superellipse rings along X
TOP = [(0, 14.9), (1.5, 17.2), (4, 19.4), (8, 22.2), (12, 24.8), (16, 26.9), (20, 28.8), (24, 30.6), (28, 32.2), (32, 33.5), (36, 34.7), (40, 36.0), (44, 37.2), (48, 37.4), (52, 36.8), (56, 34.7), (59, 31.2), (60.5, 27)]
BOT = [(0, 13.2), (1.5, 12.6), (4, 12.4), (8, 11.6), (12, 13.6), (16, 15.6), (20, 16.9), (24, 17.5), (28, 17.6), (32, 17.4), (36, 16.8), (40, 15.8), (44, 14.6), (48, 14.4), (52, 14.2), (56, 15.5), (59, 19.5), (60.5, 23)]
WID = [(0, 1.5), (1, 4.6), (2.5, 6.9), (4, 8.0), (8, 8.2), (12, 8.8), (16, 9.6), (20, 10.9), (24, 13.0), (28, 15.9), (32, 20.4), (36, 22.4), (40, 22.6), (44, 22.4), (48, 21.9), (52, 20.8), (56, 18.8), (59, 14.5), (60.5, 9)]
def sring(x, n=14, p=2.5):
    zt, zb, w = tab(TOP, x), tab(BOT, x), tab(WID, x)
    zc, h = (zt + zb) / 2, (zt - zb) / 2
    pts = []
    for i in range(n):
        th = 2 * math.pi * i / n
        c, s = math.cos(th), math.sin(th)
        pts.append(Vector((x, math.copysign(abs(c) ** (2 / p), c) * w, zc + math.copysign(abs(s) ** (2 / p), s) * h)))
    return pts
XS = [0, 1, 2.5, 4.5, 8, 13, 19, 25, 30, 34, 39, 44, 49, 54, 57.5, 59.5, 60.5]
K.loft([sring(x, 12) for x in XS], 'Skull', 'Bone')
def on_top(x, y, lift=0.25):   # a point on the skull's upper surface
    zt, zb, w = tab(TOP, x), tab(BOT, x), tab(WID, x)
    c = min(0.999, abs(y) / w); s = (1 - c ** 2.5) ** (1 / 2.5)
    return Vector((x, y, (zt + zb) / 2 + s * (zt - zb) / 2 + lift))
def patch(cx, cy, lx, ly, yaw, key='BoneDark', n=12):
    bm = bmesh.new(); vs = []
    for k in range(n):
        a = 2 * math.pi * k / n
        dx, dy = math.cos(a) * lx, math.sin(a) * ly
        x = cx + dx * math.cos(yaw) - dy * math.sin(yaw); y = cy + dx * math.sin(yaw) + dy * math.cos(yaw)
        vs.append(bm.verts.new(on_top(x, y)))
    lo = [bm.verts.new(v.co - Vector((0, 0, 0.5))) for v in vs]
    bm.faces.new(vs); bm.faces.new(list(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n; bm.faces.new((vs[i], lo[i], lo[j], vs[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    K.obj_from_bm(bm, 'Open', key)
for side in (-1, 1):
    w = tab(WID, 46.5)
    # the orbit: a dark hollow with a thick bone rim and a brow above it
    K.disc(Vector((46.5, side * (w - 2.6), 28.0)), Vector((0, side, 0.08)), 5.3, 2.6, 'Orbit', 'BoneDark', sides=12)
    K.tube([Vector((46.5 + math.cos(2 * math.pi * k / 12) * 6.3, side * (w + 0.35 - 0.7 * abs(math.sin(2 * math.pi * k / 12))), 28.0 + math.sin(2 * math.pi * k / 12) * 6.0)) for k in range(13)],
           [1.75] * 13, 'OrbitRim', 'Bone', sides=5, cap=True)
    K.tube([Vector((38.5, side * (tab(WID, 38.5) - 0.3), 30.2)), Vector((43.0, side * (w + 1.0), 34.3)), Vector((49.0, side * (w + 1.1), 35.6)), Vector((54.5, side * (tab(WID, 54.5) + 0.2), 32.6))],
           [1.5, 2.1, 2.2, 1.5], 'Brow', 'Bone', sides=5)
    # cheek bar under the orbit, back to the jaw joint
    K.tube([Vector((36.0, side * (tab(WID, 36) - 0.2), 20.5)), Vector((42.0, side * (w + 0.5), 19.6)), Vector((50.0, side * (w + 0.3), 20.6)), Vector((55.0, side * (tab(WID, 55) + 0.2), 23.5))],
           [1.6, 1.9, 1.9, 1.5], 'Cheek', 'Bone', sides=5)
    patch(38.5, side * 9.8, 7.4, 3.0, side * 0.12)          # the openings behind the rostrum (top view)
    # rostrum relief: a raised bar along each edge (the dark groove between it and the middle ridge is the long opening)
    K.tube([on_top(x, side * (tab(WID, x) - 1.5), 0.15) for x in (5, 10, 16, 22, 28, 33)], [1.25, 1.4, 1.5, 1.6, 1.7, 1.5], 'RostEdge', 'Bone', sides=5)
    patch(19.0, side * (tab(WID, 19) * 0.55), 11.5, 1.6, side * 0.13)
K.tube([on_top(x, 0, 0.35) for x in (3, 9, 16, 23, 30, 36)], [1.3, 1.7, 2.0, 2.3, 2.6, 2.2], 'RostRidge', 'Bone', sides=6, ry=[1.5] * 6, side_ref=Vector((0, 1, 0)))
# ---------------------------------------------------------------- lower jaw: two bowed rami joined at the chin (they show beside the rostrum from above)
JY = [(0.4, 1.0), (2, 4.6), (4, 7.2), (8, 10.2), (12, 12.8), (16, 15.2), (20, 16.5), (24, 17.6), (28, 18.6), (32, 19.5), (36, 20.4), (40, 20.6), (44.5, 20.2)]
JZ = [(0.4, 7.2), (2, 5.6), (4, 4.9), (8, 3.8), (12, 4.0), (16, 5.0), (20, 6.2), (24, 7.6), (28, 8.6), (32, 9.9), (36, 12.3), (40, 13.4), (44.5, 16.0)]
JX = [0.4, 2, 4.5, 9, 15, 21, 27, 33, 39, 44.5]
JP = [Vector((x, -tab(JY, x), tab(JZ, x))) for x in reversed(JX)] + [Vector((x, tab(JY, x), tab(JZ, x))) for x in JX]
K.tube(JP, [1.95 - 0.25 * abs(i - (len(JP) - 1) / 2) / ((len(JP) - 1) / 2) for i in range(len(JP))], 'Jaw', 'Bone', sides=7, ry=[1.62] * len(JP), side_ref=Vector((0, 0, 1)))
for side in (-1, 1): K.rock(Vector((45.0, side * 20.2, 16.6)), (3.0, 2.6, 3.2), 'Hinge', 'Bone', seed=4, sub=1, rough=0.04, flat_bottom=False)
K.rock(Vector((1.2, 0, 8.2)), (1.9, 2.6, 2.4), 'Chin', 'Bone', seed=2, sub=1, rough=0.04, flat_bottom=False)
# ---------------------------------------------------------------- spine with vertebra bumps + neural spines (shark-fin blades)
SPZ = [(59, 33.5), (64, 35.2), (70, 36.6), (80, 38.2), (90, 38.9), (100, 38.5), (110, 36.8), (116, 35.0), (124, 31.2), (130, 27.4), (136, 23.8), (142, 20.4), (148, 17.6), (156, 14.6), (164, 13.5), (172, 12.8), (180.5, 12.0)]
def spz(x): return ctab(SPZ, x)
def spr(x): return tab([(59, 3.3), (116, 3.0), (136, 2.3), (148, 1.7), (160, 1.45), (172, 1.2), (180.5, 1.1)], x)
SPX = [59 + i * 3.0375 for i in range(41)]
K.tube([Vector((x, 0, spz(x))) for x in SPX], [spr(x) * (1 + 0.24 * math.cos(2 * math.pi * (x - 59) / 6.075)) for x in SPX], 'Spine', 'Bone', sides=6,
       ry=[1.3] * len(SPX), side_ref=Vector((0, 1, 0)))
for i in range(10):
    x = 62.0375 + 6.075 * i; r = spr(x)
    for side in (-1, 1):
        K.tube([Vector((x, side * r * 0.8, spz(x))), Vector((x + 1.0, side * (r + 4.6), spz(x) - 1.4))], [r * 0.66, r * 0.3], 'Process', 'Bone', sides=4)
NS = [(64, 44.0, 8.5), (76.5, 49.8, 10.5), (90, 50.5, 10.5), (100.5, 48.6, 9.5), (112, 44.6, 8.5), (120.5, 40.0, 7.6), (128.5, 34.3, 6.6), (136.5, 28.6, 5.6), (144, 23.4, 4.6),
      (151, 19.6, 3.8), (158.5, 17.0, 3.1), (165.5, 15.8, 2.6), (171.5, 14.4, 2.2)]
for (x, ztip, ln) in NS:
    ln = ln * 1.12; ztip += 0.4
    f0, r0x = x - 0.7 * ln, x + 0.36 * ln
    zb0, zb1 = spz(f0) + spr(f0) * 0.3, spz(r0x) + spr(r0x) * 0.3
    th = 1.15 + ln * 0.11
    a = [Vector((f0, -th, zb0)), Vector((r0x, -th, zb1)), Vector((r0x, th, zb1)), Vector((f0, th, zb0))]
    zm = (max(zb0, zb1) + ztip) / 2
    b = [Vector((x - 0.42 * ln, -th * 0.85, zm)), Vector((x + 0.2 * ln, -th * 0.85, zm + 0.3)), Vector((x + 0.2 * ln, th * 0.85, zm + 0.3)), Vector((x - 0.42 * ln, th * 0.85, zm))]
    c = [Vector((x - 0.2 * ln, -th * 0.5, ztip - 0.5)), Vector((x + 0.16 * ln, -th * 0.5, ztip)), Vector((x + 0.16 * ln, th * 0.5, ztip)), Vector((x - 0.2 * ln, th * 0.5, ztip - 0.5))]
    K.loft([a, b, c], 'NSpine', 'Bone')
# ---------------------------------------------------------------- ribs: X as a function of height (side view), width from the top view
RIBS = [  # [(z, x) top to bottom] (side view, all-mask runs), half width (top view), X-width, bottom z
    ([(35.5, 63.5), (30, 68.5), (24, 70.8), (20, 69.8), (16, 69.2), (12, 69.0), (3, 69.0)], 24.5, 5.4, 2.0),
    ([(36.5, 70.5), (32, 74.5), (28, 77.5), (24, 79.2), (20, 79.6), (16, 79.5), (12, 79.6), (3, 79.5)], 28.0, 8.0, 2.0),
    ([(38.5, 88.5), (32, 92.0), (28, 94.0), (24, 95.5), (20, 96.7), (16, 97.3), (12, 97.7), (3, 97.5)], 28.5, 6.4, 2.0),
    ([(38, 100.5), (32, 103.5), (28, 105.4), (24, 107.4), (20, 108.6), (16, 109.3), (12, 109.4), (3, 108.7)], 28.0, 5.8, 1.5),
    ([(35, 112.5), (32, 114.3), (28, 116.6), (24, 118.6), (20, 120.0), (16, 120.7), (12, 121.0), (3, 119.0)], 26.0, 5.3, 1.5),
    ([(29, 123.0), (24, 126.5), (20, 128.7), (16, 130.0), (12, 130.5), (3, 130.6)], 22.0, 4.5, 2.0),
    ([(24, 133.5), (20, 136.9), (16, 138.5), (12, 139.3), (8, 138.2), (3.5, 137.2)], 16.5, 3.7, 3.0),
    ([(20, 142.5), (16, 146.0), (12, 145.9), (6.5, 146.1)], 11.5, 3.1, 6.0),
    ([(17.5, 148.5), (14, 150.6), (10, 151.5), (7.5, 151.0)], 9.0, 2.5, 7.5)]
PHI = math.radians(118)
for (zx, hw, wx, bz) in RIBS:
    zx = sorted(zx)                      # by z ascending for the table
    zt = zx[-1][0]
    for side in (-1, 1):
        pts = []; rad = []; NSEG = 6
        for k in range(NSEG + 1):
            t = k / NSEG; ph = PHI * t
            z = bz + (zt - bz) * (math.cos(ph) - math.cos(PHI)) / (1 - math.cos(PHI))
            y = side * (1.0 + (hw - 1.0) * math.sin(ph))
            pts.append(Vector((ctab(zx, z), y, z))); rad.append(0.5 * wx * (1.0 - 0.34 * t ** 2) * (1 + 0.75 * max(0.0, 1 - t / 0.24)))
        K.tube(pts, [r * 0.8 for r in rad], 'Rib', 'Bone', sides=7, ry=[1 / 0.8] * len(pts), side_ref=Vector((1, 0, 0)))
# ---------------------------------------------------------------- flippers: a short arm, then a paddle of four long finger bones on the sand
for side in (-1, 1):
    arm = [Vector((53.5, side * 19.0, 17.0)), Vector((53.0, side * 23.0, 9.5)), Vector((54.0, side * 26.0, 3.6))]
    K.tube(arm, [3.5, 2.9, 2.8], 'Arm', 'Bone', sides=7)
    K.rock(arm[0], (3.7, 3.0, 3.7), 'Shoulder', 'Bone', seed=3, sub=1, rough=0.05, flat_bottom=False)
    K.rock(arm[2], (3.1, 3.4, 2.5), 'Wrist', 'Bone', seed=5, sub=1, rough=0.05, flat_bottom=False)
    for f in range(4):
        u = f / 3
        base = Vector((51.5 + 2.6 * u, side * (23.0 + 9.4 * u), 2.6))
        tip = Vector((74.0 + 8.5 * u - 3.0 * abs(u - 0.6), side * (38.0 + 7.4 * u), 1.3))
        ts = (0, 0.34, 0.42, 0.74, 1.0); rr = (2.1, 1.65, 2.0, 1.6, 0.75)     # knuckles between the three bones
        K.tube([base.lerp(tip, t) + Vector((0, 0, 0.8 * math.sin(math.pi * t))) for t in ts], list(rr), 'Finger', 'Bone', sides=5, ry=[1.35] * len(ts), side_ref=Vector((0, 0, 1)))
# ---------------------------------------------------------------- tail fluke: two flat lobes (outline from the top view), rolled so one lobe rises
roll = Matrix.Rotation(math.radians(-16), 4, 'X')
joint = Vector((180.0, 0, 12.0))
OUTL = [(0, 0.3), (2.2, 6.5), (4.6, 12.6), (8.6, 17.4), (14.0, 20.2), (20.0, 21.8), (16.6, 17.2), (13.6, 11.0), (12.4, 4.6), (11.2, 0.3)]
for side in (-1, 1):
    bm = bmesh.new()
    top = [bm.verts.new(joint + roll @ Vector((x, side * y, 0.55 * (1 - x / 30)))) for x, y in OUTL]
    bot = [bm.verts.new(joint + roll @ Vector((x, side * y, -0.55 * (1 - x / 30)))) for x, y in OUTL]
    n = len(OUTL)
    ct = bm.verts.new(joint + roll @ Vector((8.5, side * 9.0, 1.9))); cb = bm.verts.new(joint + roll @ Vector((8.5, side * 9.0, -1.9)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((top[i], top[j], ct)); bm.faces.new((bot[j], bot[i], cb)); bm.faces.new((top[j], top[i], bot[i], bot[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    K.obj_from_bm(bm, 'Fluke', 'Bone')
# ---------------------------------------------------------------- decor
def anemone(c, key, r, n=7, up=Vector((0, 0, 1)), lush=False):
    up = up.normalized()
    q = Vector((0, 0, 1)).rotation_difference(up)
    K.lathe([(r * 0.68, -r * 0.1), (r * 0.8, r * 0.34), (r * 0.42, r * 0.78)], 'AnemBase', key, sides=7).matrix_world = Matrix.Translation(c) @ q.to_matrix().to_4x4()
    if lush or n >= 7: K.rock(c + up * r * 0.8, (r * 0.36, r * 0.36, r * 0.24), 'AnemCore', 'AnemPink', seed=1, sub=1, rough=0.0, flat_bottom=False)
    rings_ = ((11, 1.0, 1.0, 0.0), (6, 0.5, 0.86, 0.5)) if lush else ((7, 1.0, 1.0, 0.0), (3, 0.45, 0.82, 0.5))
    for (cnt, lean, ln, ph) in rings_:
        for j in range(cnt):
            a = 2 * math.pi * (j + ph) / cnt + rnd.uniform(-0.1, 0.1)
            d = q @ Vector((math.cos(a), math.sin(a), 0))
            base = c + d * r * 0.5 * lean + up * r * 0.6
            l = ln * rnd.uniform(0.88, 1.1); tr = r * (0.2 if lush else 0.22)
            p1 = base + d * r * 0.6 * lean * l + up * r * (0.34 + 0.5 * (1 - lean)) * l
            p2 = base + d * r * 1.12 * lean * l + up * r * (0.5 + 0.8 * (1 - lean)) * l
            K.tube([base, p1, p2], [tr, tr * 1.02, tr * 0.8], 'Tent', key, sides=4 if lush else 3)
def crystals(c, n=3, s=1.0):
    for j in range(n):
        K.crystal(c + Vector((rnd.uniform(-2.2, 2.2) * s, rnd.uniform(-2.2, 2.2) * s, 0.9)), Vector((rnd.uniform(-0.35, 0.35), rnd.uniform(-0.35, 0.35), 1)),
                  rnd.uniform(5.5, 9.5) * s, rnd.uniform(1.3, 2.0) * s, 'Cry', 'Crystal', sides=5, seed=j)
def tubes(c, key, n=3, s=1.0):
    for j in range(n):
        a = rnd.uniform(0, 6.28); lean = rnd.uniform(0.1, 0.5)
        p1 = c + Vector((math.cos(a) * 1.4 * s, math.sin(a) * 1.4 * s, 0))
        K.tube([p1, p1 + Vector((math.cos(a) * lean * 3 * s, math.sin(a) * lean * 3 * s, rnd.uniform(4, 7) * s))], [1.0 * s, 1.15 * s], 'Tube', key, sides=5)
def branch(c, key, s=1.0):
    for j in range(3):
        a = rnd.uniform(0, 6.28)
        p1 = c + Vector((0, 0, 2.5 * s)); p2 = p1 + Vector((math.cos(a) * 2.6 * s, math.sin(a) * 2.6 * s, 3.2 * s)); p3 = p2 + Vector((math.cos(a + 0.8) * 1.4 * s, math.sin(a + 0.8) * 1.4 * s, 2.8 * s))
        K.tube([c, p1, p2, p3], [1.0 * s, 0.9 * s, 0.75 * s, 0.5 * s], 'Branch', key, sides=3)
def kelp(c, h, n=3):
    for j in range(n):
        a = rnd.uniform(0, 6.28); hh = h * rnd.uniform(0.6, 1.0); sway = rnd.uniform(1.5, 3.5)
        b = c + Vector((math.cos(a) * 1.5, math.sin(a) * 1.5, 0))
        pts = [b + Vector((math.sin(t * 3.0 + a) * sway * t, math.cos(t * 2.3 + a) * sway * t, hh * t)) for t in (0, 0.33, 0.66, 1.0)]
        K.tube(pts, [1.5, 1.8, 1.5, 0.3], 'Kelp', 'Kelp', sides=4, ry=[0.3] * 4)
def rocks(c, n=2, s=1.0):
    for j in range(n):
        K.rock(c + Vector((rnd.uniform(-3, 3) * s, rnd.uniform(-3, 3) * s, 1.2)), (rnd.uniform(2.4, 4.2) * s, rnd.uniform(2.4, 4.0) * s, rnd.uniform(2.0, 3.0) * s), 'Rock', 'Rock', seed=j + int(c.x), sub=1, rough=0.2)
for side in (-1, 1): branch(Vector((46.8, side * (tab(WID, 46.5) + 0.2), 24.6)), 'CoralOrange', 0.42)   # a small coral inside each orbit, like the sheet
# every decoration below is placed where the sheet shows it (decor_scan.py: colour blobs matched between the top and side views)
def rib_pt(x, y):   # a point on the outside of the rib cage near (x, y): height of the arch there
    best = None
    for (zx, hw, wx, bz) in RIBS:
        zs = sorted(zx); zt = zs[-1][0]; xm = zs[len(zs) // 2][1]
        if best is None or abs(xm - x) < abs(best[0] - x): best = (xm, hw, zt, bz)
    xm, hw, zt, bz = best
    sy = min(0.999, abs(y) / hw); ph = math.asin(sy)
    return bz + (zt - bz) * (math.cos(ph) - math.cos(PHI)) / (1 - math.cos(PHI))
anemone(on_top(44.5, 7.4, -0.7), 'AnemPurple', 6.6, lush=True)
anemone(on_top(36.0, -12.0, -0.5), 'AnemTeal', 4.6, n=6, up=Vector((0, -0.4, 1)))
anemone(Vector((76.0, -10.1, 33.2)), 'AnemPurple', 6.4, up=Vector((0, -0.5, 1)), lush=True)
anemone(Vector((69.5, 19.0, rib_pt(69.5, 19.0) + 0.5)), 'AnemPurple', 4.6, up=Vector((0, 0.7, 0.8)))
anemone(Vector((83.4, 7.1, 37.2)), 'AnemPurple', 3.2, n=6, up=Vector((0, 0.3, 1)))
anemone(Vector((103.8, -26.0, 21.8)), 'AnemPurple', 5.4, up=Vector((0, -1, 0.45)), lush=True)
anemone(Vector((149.1, 8.6, 15.4)), 'AnemPurple', 3.2, n=6, up=Vector((0, 0.8, 0.7)))
anemone(Vector((111.5, -8.0, 34.6)), 'AnemTeal', 4.6, n=6, up=Vector((0, -0.5, 1)))
anemone(Vector((101.4, 26.0, rib_pt(104, 26.0))), 'AnemTeal', 4.0, n=6, up=Vector((0, 1, 0.4)))
anemone(Vector((68.7, -6.5, 35.6)), 'AnemTeal', 2.3, n=6)
branch(on_top(32.7, 9.5, -0.6), 'CoralPink', 0.8); branch(on_top(45.0, -18.2, -0.9), 'CoralOrange', 0.7)
branch(Vector((113.2, 12.5, 30.5)), 'CoralPink', 0.7); branch(Vector((134.6, 7.9, 24.0)), 'CoralPink', 0.55)
kelp(Vector((141.5, -1.5, 20.5)), 10, 3)
# on the sand: under the jaw, at the rib feet (near side = -Y, the side the sheet's side view shows)
rocks(Vector((18.5, -12.5, 0)), 2, 1.25); branch(Vector((19.2, -14.5, 1.5)), 'CoralPink', 1.35); tubes(Vector((24.2, -13.0, 1.0)), 'CoralOrange', 3, 0.95)
rocks(Vector((31.8, -15.5, 0)), 2, 1.45); rocks(Vector((25, 12.5, 0)), 2, 1.1); tubes(Vector((21, 13.5, 1.0)), 'CoralYellow', 3, 0.9)
crystals(Vector((41.5, -26.0, 0)), 3, 1.25); crystals(Vector((44.1, 23.5, 0)), 3, 1.1)
rocks(Vector((38.9, -25.7, 0)), 1, 0.9); rocks(Vector((48.6, -27.5, 0)), 1, 1.0); rocks(Vector((39.2, 22.4, 0)), 1, 0.8); rocks(Vector((48.5, 24.2, 0)), 1, 1.0)
kelp(Vector((45.5, -22.0, 0)), 17, 3); kelp(Vector((60.0, -18.5, 0)), 23, 3); kelp(Vector((47, 21, 0)), 14, 2)
rocks(Vector((51.3, -22.5, 0)), 1, 1.0); rocks(Vector((62.2, -25.9, 0)), 2, 1.2); rocks(Vector((62.0, 23.3, 0)), 1, 1.0); rocks(Vector((57.2, 17.6, 0)), 1, 0.7)
rocks(Vector((68.0, -15.4, 3.5)), 1, 0.8); rocks(Vector((66.9, 11.3, 0)), 1, 0.8)
tubes(Vector((76.0, -28.3, 1.2)), 'CoralOrange', 3, 1.0); branch(Vector((80.0, -27.0, 3.5)), 'CoralPink', 1.25); rocks(Vector((80.5, -30.2, 0)), 2, 1.15)
rocks(Vector((92.0, -30.1, 0)), 1, 1.15); crystals(Vector((98.0, -32.3, 0)), 3, 1.2); rocks(Vector((102.5, -30.9, 0)), 1, 1.1); kelp(Vector((102.0, -22.0, 0)), 15, 2)
rocks(Vector((87.3, 24.7, 0)), 2, 0.95); tubes(Vector((89.9, 28.6, 1.0)), 'CoralOrange', 3, 0.95)
rocks(Vector((115.0, -29.0, 2.5)), 1, 1.1); rocks(Vector((122.9, -29.7, 0)), 1, 1.15); rocks(Vector((124.2, -23.7, 0)), 1, 0.85); tubes(Vector((126.0, -26.9, 1.5)), 'CoralOrange', 3, 0.95); rocks(Vector((129.6, -27.7, 0)), 1, 0.7)
rocks(Vector((110.8, 11.0, 0)), 1, 0.8); tubes(Vector((134.5, 17.6, 1.2)), 'CoralOrange', 3, 0.85); rocks(Vector((135.3, -24.0, 1.5)), 1, 0.9)
rocks(Vector((140.5, -21.8, 0.5)), 2, 1.1); branch(Vector((142.5, -18.4, 3.0)), 'CoralPink', 1.05)
crystals(Vector((144.7, 12.7, 0)), 3, 0.7); crystals(Vector((150.0, -15.7, 2.0)), 3, 0.85); rocks(Vector((147.1, -9.5, 0)), 1, 0.7); rocks(Vector((152.8, -12.0, 1.0)), 1, 0.85)
K.finish(40)
obs = K.join_by_key()
print('TRIS', K.tris())
K.export_obj(OUT + '/model.obj')
bpy.ops.wm.save_as_mainfile(filepath=OUT + '/model.blend')
