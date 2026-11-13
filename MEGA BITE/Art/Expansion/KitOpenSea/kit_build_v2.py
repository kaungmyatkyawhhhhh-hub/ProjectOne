# MEGA BITE Open Sea kit (sheet: mb_sheet_kit_opensea.png, 8 props in one 3/4 view each). Hand-built, low-poly, one mesh
# per prop (all eight share one atlas). Each prop stands on z = 0 with its middle at x = 40 * index.
import sys; sys.path.insert(0, '/tmp/claude-0/lm')
import lmkit as K, math, random, bmesh, bpy, json
from mathutils import Vector, Matrix
OUT = '/tmp/claude-0/lm2/kit'
K.reset()
rnd = random.Random(21)
GROUP = {}; FLAT = []
PROP = None; OX = 0.0
def M(col, rgb, flat=False):
    key = PROP + '_' + col
    K.mat(key, rgb); GROUP[key] = PROP
    if flat: FLAT.append(key)
    return key
def P(x, y, z): return Vector((OX + x, y, z))
def rocks(spots, key, s=1.0):
    for i, (x, y, r) in enumerate(spots):
        K.rock(P(x, y, r * 0.32 * s), (r * s, r * 0.9 * s, r * 0.62 * s), 'Rock', key, seed=i * 7 + int(OX), sub=1, rough=0.22)
def blades(c, key, n=3, h=4.0):
    for j in range(n):
        a = rnd.uniform(0, 6.28); hh = h * rnd.uniform(0.7, 1.1); sw = rnd.uniform(0.6, 1.4)
        b = c + Vector((math.cos(a) * 0.5, math.sin(a) * 0.5, 0))
        pts = [b + Vector((math.cos(a) * sw * t * t, math.sin(a) * sw * t * t, hh * t)) for t in (0, 0.5, 1.0)]
        K.tube(pts, [0.55, 0.6, 0.12], 'Blade', key, sides=4, ry=[0.3] * 3)
def branch(c, key, s=1.0, n=3):
    for j in range(n):
        a = 2 * math.pi * j / n + rnd.uniform(-0.4, 0.4)
        p1 = c + Vector((0, 0, 1.0 * s)); p2 = p1 + Vector((math.cos(a) * 1.0 * s, math.sin(a) * 1.0 * s, 1.1 * s)); p3 = p2 + Vector((math.cos(a) * 0.3 * s, math.sin(a) * 0.3 * s, 1.2 * s))
        K.tube([c, p1, p2, p3], [0.42 * s, 0.38 * s, 0.33 * s, 0.26 * s], 'Branch', key, sides=4)
def star(c, r, key):
    bm = bmesh.new(); pts = []
    for i in range(10):
        a = 2 * math.pi * i / 10 + 0.3; rr = r if i % 2 == 0 else r * 0.48
        pts.append(c + Vector((math.cos(a) * rr, math.sin(a) * rr, 0)))
    f = [bm.verts.new(p + Vector((0, 0, 0.12))) for p in pts]; top = bm.verts.new(c + Vector((0, 0, r * 0.36)))
    for i in range(10): bm.faces.new((f[i], f[(i + 1) % 10], top))
    bm.faces.new(list(reversed(f))); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    K.obj_from_bm(bm, 'Star', key)
def face(o, outward=True):
    me = o.data; bm = bmesh.new(); bm.from_mesh(me); bm.normal_update()
    for f in bm.faces:
        c = f.calc_center_median(); r = Vector((c.x, c.y, 0))
        if r.length < 1e-4: continue
        d = f.normal.dot(r.normalized())
        if abs(d) < 0.08: d = -f.normal.z if not outward else f.normal.z      # flat rims: up
        if (d < 0) == outward: f.normal_flip()
    bm.to_mesh(me); bm.free(); return o
def start(name, idx):
    global PROP, OX
    PROP = name; OX = idx * 40.0
# ------------------------------------------------------------ 1 tube sponges (yellow)
start('TubeSponge', 0)
Y = M('Yellow', (250, 206, 30)); YD = M('Inside', (196, 136, 14)); RK = M('Rock', (58, 92, 150), True); TL = M('Teal', (30, 176, 170)); ST = M('Star', (250, 130, 60))
for (x, y, r, h, lean) in [(0.0, 0.4, 1.9, 11.5, (0.05, 0.0)), (-2.9, -0.3, 1.7, 8.8, (-0.16, 0.02)), (2.9, 0.0, 1.6, 7.2, (0.2, 0.0)), (-4.6, -1.5, 1.5, 5.4, (-0.3, -0.05)),
                           (0.4, -2.2, 1.6, 5.6, (0.03, -0.14)), (-1.6, -3.0, 1.35, 3.4, (-0.08, -0.2))]:
    q = Vector((0, 0, 1)).rotation_difference(Vector((lean[0], lean[1], 1)).normalized()).to_matrix().to_4x4()
    o = face(K.lathe([(r * 0.86, 0), (r * 0.92, h * 0.5), (r * 1.06, h * 0.93), (r * 1.0, h), (r * 0.72, h)], 'Tube', Y, sides=9, cap=False))
    o.matrix_world = Matrix.Translation(P(x, y, 0)) @ q
    o2 = face(K.lathe([(r * 0.72, h), (r * 0.6, h - r * 0.9), (0.05, h - r * 1.1)], 'Hole', YD, sides=9, cap=False), False)
    o2.matrix_world = Matrix.Translation(P(x, y, 0)) @ q
rocks([(-3.6, 2.2, 2.6), (3.6, -1.6, 3.0), (-5.6, -2.6, 2.0)], RK); blades(P(-6.0, 0.4, 0), TL, 3, 4.0); blades(P(4.6, 1.2, 0), TL, 3, 5.0); star(P(2.8, -3.6, 1.5), 1.5, ST)
# ------------------------------------------------------------ 2 giant clam with a pearl
start('GiantClam', 1)
PU = M('Purple', (150, 104, 226)); CR = M('Cream', (250, 232, 200)); PK = M('Mantle', (244, 132, 168)); PE = M('Pearl', (255, 178, 216))
CU = Vector((0.30, -0.954, 0)); CV = Vector((0.954, 0.30, 0)); HINGE = (-1.6, 5.2, 4.3)
def Rr(phi): return 10.6 * (0.62 + 0.38 * math.cos(phi))
def zin(t): return -3.3 * (4 * t * (1 - t)) ** 0.75 * (0.55 + 0.45 * t) if 0 < t < 1 else 0.0
def valve(open_deg, upper):
    bm = bmesh.new(); NS = 17; TS = (0.3, 0.56, 0.8, 1.0); th0 = math.radians(open_deg)
    def W(u, v, z):
        if upper:
            z = -z; u, z = u * math.cos(th0) - z * math.sin(th0), u * math.sin(th0) + z * math.cos(th0)
        return P(HINGE[0], HINGE[1], HINGE[2]) + CU * u + CV * v + Vector((0, 0, z))
    def pt(i, t, outer):
        phi = math.radians(-108 + 216 * i / (NS - 1)); sgn = 1 if i % 2 == 0 else -1
        r = Rr(phi) * t * (1 + 0.06 * sgn * t)
        z = zin(t) + 0.42 * sgn * t * t
        if outer:
            z -= 0.5 + 0.35 * math.sin(math.pi * t) + 0.5 * max(0, sgn) * math.sin(math.pi * min(1, t * 1.1))
            r *= 1.03
        return W(math.cos(phi) * r, math.sin(phi) * r, z)
    inn = [[bm.verts.new(pt(i, t, False)) for i in range(NS)] for t in TS]
    out = [[bm.verts.new(pt(i, t, True)) for i in range(NS)] for t in TS]
    ai = bm.verts.new(W(0.2, 0, 0)); ao = bm.verts.new(W(-0.9, 0, -0.9))
    def F(vs, m):
        f = bm.faces.new(vs); f.material_index = m
    for i in range(NS - 1):
        F((ai, inn[0][i], inn[0][i + 1]), 1); F((ao, out[0][i + 1], out[0][i]), 0)
        for k in range(len(TS) - 1):
            F((inn[k][i], inn[k + 1][i], inn[k + 1][i + 1], inn[k][i + 1]), 1); F((out[k][i + 1], out[k + 1][i + 1], out[k + 1][i], out[k][i]), 0)
        F((inn[-1][i], out[-1][i], out[-1][i + 1], inn[-1][i + 1]), 1)
    for i in (0, NS - 1):       # close the two back edges
        F((ai, ao, out[0][i], inn[0][i]), 0)
        for k in range(len(TS) - 1): F((inn[k][i], out[k][i], out[k + 1][i], inn[k + 1][i]), 0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = K.obj_from_bm(bm, 'Valve', PU); o.data.materials.append(bpy.data.materials[CR])
valve(0, False); valve(56, True)
def CW(u, v, z): return P(HINGE[0], HINGE[1], HINGE[2]) + CU * u + CV * v + Vector((0, 0, z))
o = K.rock(Vector((0, 0, 0)), (5.6, 2.4, 2.5), 'Hinge', PU, seed=5, sub=1, rough=0.1, flat_bottom=False); o.matrix_world = Matrix.Translation(CW(-0.5, 0, 0.5)) @ Matrix.Rotation(math.atan2(CV.y, CV.x), 4, 'Z')
# the pink mantle: a wavy cushion that fills the bowl, and the pearl on it
bm = bmesh.new(); NM = 14; ringm = []
ctr = bm.verts.new(CW(5.2, 0, -1.5))
for k, (f_, dz) in enumerate(((0.45, -1.35), (0.74, -1.5), (0.86, -2.2))):
    ringm.append([bm.verts.new(CW(5.2 + math.cos(2 * math.pi * i / NM) * 4.6 * f_ * (1 + (0.1 if i % 2 else -0.04) * (k > 0)) + 0.6 * f_, math.sin(2 * math.pi * i / NM) * 6.9 * f_ * (1 + (0.1 if i % 2 else -0.04) * (k > 0)), dz + (0.3 if (i % 2 and k == 1) else 0))) for i in range(NM)])
for i in range(NM):
    j = (i + 1) % NM; bm.faces.new((ctr, ringm[0][i], ringm[0][j]))
    for k in range(2): bm.faces.new((ringm[k][i], ringm[k + 1][i], ringm[k + 1][j], ringm[k][j]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
for f in bm.faces:
    if f.normal.z < 0: f.normal_flip()
K.obj_from_bm(bm, 'Mantle', PK)
K.rock(CW(5.6, 0, 0.35), (2.0, 2.0, 2.0), 'Pearl', PE, seed=1, sub=2, rough=0.0, flat_bottom=False)
rocks([(-6.6, 3.0, 2.2), (6.8, 2.6, 2.0)], M('Rock', (58, 92, 150), True)); blades(P(7.4, 3.6, 0), M('Teal', (30, 176, 170)), 2, 4.0)
# ------------------------------------------------------------ 3 anemone (teal, pink tips)
start('Anemone', 2)
TE = M('Teal', (28, 200, 196)); PT = M('Tip', (246, 120, 170)); RK = M('Rock', (58, 92, 150), True); ST = M('Star', (250, 208, 50)); CO = M('Coral', (246, 110, 120))
for ring_, (cnt, lean, ln) in enumerate(((9, 1.0, 1.0), (6, 0.6, 1.05), (3, 0.22, 1.0))):
    for j in range(cnt):
        a = 2 * math.pi * (j + 0.5 * ring_) / cnt + rnd.uniform(-0.12, 0.12)
        d = Vector((math.cos(a), math.sin(a), 0)); l = ln * rnd.uniform(0.9, 1.1); up = Vector((0, 0, 1))
        b = P(0, 0, 2.0) + d * 1.4 * lean
        c1 = b + d * 2.2 * lean * l + up * (6.0 + 2.0 * (1 - lean))             # control point: up first
        e = b + d * 8.6 * lean * l + up * (3.4 * lean + 9.4 * (1 - lean)) * l    # then out and over
        def bez(t): return b * (1 - t) ** 2 + c1 * 2 * t * (1 - t) + e * t * t
        K.tube([bez(t) for t in (0, 0.3, 0.58, 0.8)], [1.15, 1.1, 1.0, 0.92], 'Tent', TE, sides=4, cap=False)
        tp = bez(1.0); tn = (bez(1.0) - bez(0.9)).normalized()
        K.tube([bez(0.8), bez(0.92), tp + tn * 0.7], [0.92, 0.95, 0.42], 'Tip', PT, sides=4)
K.lathe([(3.4, 0), (3.6, 1.6), (2.6, 2.8)], 'Base', TE, sides=9).location = P(0, 0, 0.6)
rocks([(-4.2, -2.6, 2.6), (3.8, -3.0, 2.8), (0.2, -4.4, 2.2), (4.6, 1.6, 2.2), (-4.4, 2.2, 2.0)], RK); star(P(-1.6, -5.4, 1.2), 1.5, ST); branch(P(3.2, -5.0, 1.0), CO, 1.3)
# ------------------------------------------------------------ 4 whip coral (orange and red)
start('WhipCoral', 3)
OR = M('Orange', (250, 138, 30)); RD = M('Red', (232, 60, 44)); RK = M('Rock', (58, 92, 150), True); YE = M('Yellow', (250, 206, 40)); TL = M('Teal', (30, 176, 170))
for j, (x, lean, h, key) in enumerate([(-3.6, -0.34, 13.0, OR), (-2.4, -0.2, 15.5, RD), (-1.2, -0.1, 12.0, OR), (0.0, 0.0, 16.5, OR), (1.0, 0.12, 13.5, RD), (2.2, 0.16, 15.0, OR),
                                        (3.2, 0.3, 11.5, RD), (4.0, 0.42, 13.0, OR), (-0.6, -0.04, 9.0, RD)]):
    ph = rnd.uniform(0, 6.28); yy = rnd.uniform(-1.2, 1.2)
    pts = [P(x * 0.5 + lean * h * t * 0.9 + 0.5 * math.sin(t * 5.5 + ph) * t, yy + 0.6 * math.cos(t * 4.0 + ph) * t, h * t) for t in (0, 0.2, 0.4, 0.6, 0.8, 1.0)]
    K.tube(pts, [0.62, 0.6, 0.56, 0.5, 0.44, 0.3], 'Whip', key, sides=4)
rocks([(-3.0, -1.0, 2.8), (3.0, -1.2, 3.0), (0.0, 1.6, 2.4)], RK); branch(P(2.2, -3.0, 1.2), YE, 1.2); blades(P(-4.6, -1.6, 0), TL, 2, 4.0)
# ------------------------------------------------------------ 5 barrel sponges (purple)
start('BarrelSponge', 4)
PU = M('Purple', (146, 70, 214)); PD = M('Inside', (86, 34, 150)); RK = M('Rock', (58, 92, 150), True); CO = M('Coral', (246, 116, 110)); TL = M('Teal', (30, 176, 170))
for (x, y, r, h) in [(-0.6, 1.4, 4.2, 9.5), (3.6, -1.0, 3.6, 6.8), (-3.4, -2.2, 3.4, 5.6)]:
    face(K.lathe([(r * 0.7, 0), (r * 0.98, h * 0.3), (r * 1.0, h * 0.62), (r * 0.82, h * 0.92), (r * 0.66, h), (r * 0.52, h)], 'Barrel', PU, sides=10, cap=False)).location = P(x, y, 0)
    face(K.lathe([(r * 0.52, h), (r * 0.42, h * 0.72), (0.05, h * 0.66)], 'Hole', PD, sides=10, cap=False), False).location = P(x, y, 0)
    for k in range(5):      # the dark pores: little dark studs on the wall
        a = rnd.uniform(-2.4, -0.7); zz = h * rnd.uniform(0.3, 0.8); rr = r * (0.98 if zz < h * 0.62 else 0.9)
        K.rock(P(x + math.cos(a) * rr, y + math.sin(a) * rr, zz), (r * 0.13, r * 0.13, r * 0.13), 'Pore', PD, seed=k, sub=1, rough=0.0, flat_bottom=False)
rocks([(-5.6, 0.2, 2.6), (5.8, 0.6, 2.4), (0.6, -4.6, 2.6), (-2.2, 4.8, 2.2)], RK); branch(P(1.4, -5.2, 1.0), CO, 1.5); blades(P(-6.4, 1.6, 0), TL, 3, 5.5)
# ------------------------------------------------------------ 6 mossy rock stack with a hole
start('MossRock', 5)
RK = M('Rock', (78, 104, 150), True); RD = M('RockDark', (56, 78, 124), True); MO = M('Moss', (124, 214, 44)); CO = M('Coral', (246, 116, 110)); TL = M('Teal', (30, 176, 170))
BL = [(-4.6, 0, 2.2, 2.9, 2.6, 2.2, 0.1), (4.4, 0.2, 2.0, 2.7, 2.6, 2.0, -0.12), (-4.9, 0.1, 6.0, 2.5, 2.4, 1.9, -0.08), (4.6, 0, 5.6, 2.4, 2.3, 1.8, 0.1),
      (-4.0, 0, 9.4, 2.7, 2.3, 1.7, 0.14), (3.7, 0.1, 9.0, 2.8, 2.3, 1.7, -0.1), (-0.3, 0, 12.5, 5.8, 2.5, 1.8, 0.05), (1.0, 0.2, 15.6, 3.4, 2.2, 1.6, -0.16)]
for i, (x, y, z, sx, sy, sz, rot) in enumerate(BL):
    o = K.rock(Vector((0, 0, 0)), (sx, sy, sz), 'Block', RK if i % 3 else RD, seed=i + 3, sub=1, rough=0.16, flat_bottom=False)
    o.matrix_world = Matrix.Translation(P(x, y, z)) @ Matrix.Rotation(rot, 4, 'Y')
    if i in (2, 4, 6, 7, 3):     # moss caps with drips
        K.rock(P(x, y, z + sz * 0.78), (sx * 0.92, sy * 0.96, sz * 0.36), 'Moss', MO, seed=i, sub=1, rough=0.1, flat_bottom=False)
        for k in range(3):
            dx = sx * rnd.uniform(-0.75, 0.75); L = rnd.uniform(1.0, 2.2)
            K.tube([P(x + dx, y - sy * 0.86, z + sz * 0.7), P(x + dx, y - sy * 0.94, z + sz * 0.7 - L)], [0.5, 0.2], 'Drip', MO, sides=4)
rocks([(-5.4, -2.2, 2.4), (5.2, -2.0, 2.6), (0.4, -3.0, 2.2), (-1.0, 2.6, 2.4)], RD); branch(P(-2.2, -3.6, 1.0), CO, 1.3); blades(P(4.2, -3.2, 0), TL, 3, 5.0)
# ------------------------------------------------------------ 7 glowing mushroom corals (blue)
start('GlowShroom', 6)
BL_ = M('Blue', (40, 150, 232)); GL = M('Glow', (196, 255, 238)); SM = M('Stem', (120, 232, 226)); RK = M('Rock', (58, 92, 150), True); CO = M('Coral', (246, 116, 130)); TL = M('Teal', (30, 176, 170))
RB = M('Rib', (255, 252, 214))
def lobed(profile, key, n=10, wob=0.07, ph=0.0):
    rings = [[Vector((math.cos(2 * math.pi * i / n) * r * (1 + wob * w * math.cos(i * math.pi + ph)), math.sin(2 * math.pi * i / n) * r * (1 + wob * w * math.cos(i * math.pi + ph)), z)) for i in range(n)] for (r, z, w) in profile]
    return K.loft(rings, 'Lobed', key, False, False)
for (x, y, r, h) in [(0.4, 0.8, 5.8, 12.5), (-4.2, -1.2, 3.7, 7.4), (4.3, -1.4, 3.2, 8.2), (0.5, -3.6, 2.9, 4.8)]:
    zr = h - r * 0.62; zs = zr + r * 0.3
    face(K.lathe([(r * 0.3, 0), (r * 0.2, zr * 0.55), (r * 0.24, zr), (r * 0.34, zs)], 'Stem', SM, sides=7, cap=False)).location = P(x, y, 0)
    o = lobed([(r * 0.34, zs, 0), (r * 0.7, zr + r * 0.12, 0.5), (r * 0.97, zr, 1)], GL); o.location = P(x, y, 0)       # the glowing underside
    bm_ = bmesh.new(); bm_.from_mesh(o.data); bm_.normal_update()
    for f_ in bm_.faces:
        if f_.normal.z > 0: f_.normal_flip()
    bm_.to_mesh(o.data); bm_.free()
    face(lobed([(r * 0.97, zr, 1), (r * 1.02, zr + r * 0.1, 1)], GL)).location = P(x, y, 0)                                 # a glowing lip
    face(lobed([(r * 1.02, zr + r * 0.1, 1), (r * 0.93, zr + r * 0.32, 0.8), (r * 0.66, zr + r * 0.52, 0.4), (r * 0.3, zr + r * 0.61, 0), (0.05, zr + r * 0.63, 0)], BL_)).location = P(x, y, 0)
    for k in range(5):      # cream gills under the cap
        a_ = 2 * math.pi * (k + 0.5) / 5
        K.tube([P(x + math.cos(a_) * r * 0.36, y + math.sin(a_) * r * 0.36, zs - r * 0.05), P(x + math.cos(a_) * r * 0.68, y + math.sin(a_) * r * 0.68, zr + r * 0.1), P(x + math.cos(a_) * r * 0.93, y + math.sin(a_) * r * 0.93, zr - r * 0.02)],
               [r * 0.06, r * 0.085, r * 0.05], 'Rib', RB, sides=3)
rocks([(-3.4, 1.6, 2.8), (3.6, 1.4, 2.8), (0.0, -5.0, 2.4), (-5.0, -3.2, 2.0), (5.4, -3.4, 2.0)], RK); branch(P(-4.6, -4.4, 1.0), CO, 1.4); blades(P(5.6, -1.0, 0), TL, 3, 5.0)
# ------------------------------------------------------------ 8 broken column
start('RuinColumn', 7)
SN = M('Stone', (206, 200, 190)); SD = M('StoneDark', (150, 148, 150), True); GO = M('Gold', (232, 178, 60)); WV = M('Wave', (44, 150, 190)); CO = M('Coral', (246, 116, 120)); YE = M('Yellow', (250, 206, 40)); TL = M('Teal', (30, 176, 170))
tilt = Matrix.Rotation(math.radians(5), 4, 'Y')
def col_part(profile, key, sides=12, cap=False):
    o = face(K.lathe(profile, 'Col', key, sides=sides, cap=cap)); o.matrix_world = Matrix.Translation(P(0, 0, 0)) @ tilt; return o
def fluted(profile, key, n=16, depth=0.1):
    rings = [[Vector((math.cos(2 * math.pi * i / n) * r * (1 - (depth if i % 2 else 0)), math.sin(2 * math.pi * i / n) * r * (1 - (depth if i % 2 else 0)), z)) for i in range(n)] for (r, z) in profile]
    o = face(K.loft(rings, 'Flute', key, False, False)); o.matrix_world = Matrix.Translation(P(0, 0, 0)) @ tilt; return o
col_part([(3.7, 0.0), (3.7, 1.1), (3.3, 1.1), (3.3, 1.9), (3.0, 1.9)], SN)
fluted([(3.0, 1.9), (2.95, 4.4)], SN)
col_part([(2.95, 4.4), (3.2, 4.4), (3.2, 5.0), (3.0, 5.0)], GO); col_part([(3.0, 5.0), (3.0, 7.2)], WV); col_part([(3.0, 7.2), (3.2, 7.2), (3.2, 7.8), (2.9, 7.8)], GO)
wave = []
for k in range(17):       # the gold wave scroll on the blue band
    a_ = 2 * math.pi * k / 16
    wave.append(tilt @ Vector((math.cos(a_) * 3.08, math.sin(a_) * 3.08, 6.1 + 0.62 * (1 if k % 2 else -1))) + P(0, 0, 0))
K.tube(wave, [0.2] * 17, 'Scroll', GO, sides=3, cap=False)
fluted([(2.9, 7.8), (2.72, 13.4)], SN)
col_part([(2.72, 13.4), (3.0, 13.4), (3.0, 14.0), (2.8, 14.0)], GO)
# the broken top: a jagged slanted stump and a fallen-off chunk
bm = bmesh.new(); n = 12
lo = [bm.verts.new(Vector((math.cos(2 * math.pi * i / n) * 2.8, math.sin(2 * math.pi * i / n) * 2.8, 14.0))) for i in range(n)]
hi = [bm.verts.new(Vector((math.cos(2 * math.pi * i / n) * 2.7, math.sin(2 * math.pi * i / n) * 2.7, 15.6 + 2.0 * math.cos(2 * math.pi * i / n - 0.6) + (0.7 if i % 2 else -0.5)))) for i in range(n)]
top_ = bm.verts.new(Vector((0.4, 0, 15.2)))
for i in range(n):
    bm.faces.new((lo[i], lo[(i + 1) % n], hi[(i + 1) % n], hi[i])); bm.faces.new((hi[i], hi[(i + 1) % n], top_))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
o = K.obj_from_bm(bm, 'Stump', SN); o.matrix_world = Matrix.Translation(P(0, 0, 0)) @ tilt
o = K.rock(Vector((0, 0, 0)), (2.6, 2.1, 1.6), 'Loose', SN, seed=4, sub=1, rough=0.14, flat_bottom=False); o.matrix_world = Matrix.Translation(P(3.0, 0.2, 17.9)) @ Matrix.Rotation(0.55, 4, 'Y')
rocks([(-3.6, -1.8, 2.6), (3.8, -1.6, 2.8), (0.2, -3.6, 2.4), (-2.4, 2.6, 2.4), (4.6, 2.0, 2.0)], SD)
branch(P(-3.2, -0.6, 9.0), CO, 1.2); branch(P(2.6, -3.4, 1.6), CO, 1.2); blades(P(5.0, -0.4, 0), TL, 3, 6.0)
for (x, y, r, h) in [(4.4, -3.6, 1.0, 2.6), (5.6, -3.0, 0.8, 1.8)]:
    face(K.lathe([(r * 0.86, 0), (r * 1.06, h * 0.93), (r, h), (r * 0.7, h)], 'Tube', YE, sides=7, cap=False)).location = P(x, y, 0.8)
    face(K.lathe([(r * 0.7, h), (r * 0.5, h - r), (0.05, h - r * 1.1)], 'TubeIn', M('Inside', (196, 136, 14)), sides=7, cap=False), False).location = P(x, y, 0.8)
K.finish(42)
print('TRIS', K.tris())
FLAT += [k for k in GROUP if k.endswith("_Stone")]
json.dump({"group": GROUP, "flat": FLAT, "default": "Misc", "floor_z": -0.2, "gain": 1.0, "tone": {"lo": 0.42, "gamma": 0.85, "pct": 90, "tint": 0.5}}, open(OUT + '/bake.json', 'w'))
K.export_obj(OUT + '/model.obj')
bpy.ops.wm.save_as_mainfile(filepath=OUT + '/model.blend')
