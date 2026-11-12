# CARGO SHIP (Industrial harbour landmark) from sheet se_lm_ship (ChatGPT, 13 Nov). 1 sheet px = 0.37 studs. Bow = +x. z=0 = waterline.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
S = 0.37
L = 548 * S; B = 154 * S; H = 67 * S
NX = 22
def wx(t):                       # half beam along the hull, t in [0,1] stern->bow
    if t < 0.06: return B / 2 * (0.86 + 0.14 * t / 0.06)
    if t < 0.7: return B / 2
    u = (t - 0.7) / 0.3
    return B / 2 * max(0.0, 1 - u ** 1.7)
def deck(t): return H + (9 * ((t - 0.72) / 0.28) ** 2 if t > 0.72 else 0) + (1.5 if t < 0.05 else 0)
def keel(t): return 0 if t < 0.88 else (t - 0.88) / 0.12 * H * 0.35
def f(zr): return 0.62 + 0.38 * min(1, zr) ** 0.5
def band(z0r, z1r, col, rows=3):
    v = []; fc = []; ts = [i / NX for i in range(NX + 1)]
    for i, t in enumerate(ts):
        x = -L / 2 + t * L; k0 = keel(t); d = deck(t)
        for j in range(rows + 1):
            zr = z0r + (z1r - z0r) * j / rows
            z = k0 + (d - k0) * zr
            w = wx(t) * f(zr) + (0.12 if t >= 0.999 else 0)
            v.append((x, -w, z)); v.append((x, w, z))
    R = (rows + 1) * 2
    for i in range(NX):
        for j in range(rows):
            a = i * R + j * 2; b = (i + 1) * R + j * 2
            fc.append((a, b, b + 2, a + 2))                 # port side (-y)
            fc.append((a + 1, a + 3, b + 3, b + 1))         # starboard
    return poly(v, fc, col, bev=0)
band(0, 0.32, 'red2'); band(0.32, 0.9, 'blue2'); band(0.9, 1.0, 'white', rows=1)
# deck cap + stern transom + bottom
ts = [i / NX for i in range(NX + 1)]
top = [(-L / 2 + t * L, -wx(t) * f(1), deck(t)) for t in ts] + [(-L / 2 + t * L, wx(t) * f(1), deck(t)) for t in reversed(ts)]
poly(top, [tuple(range(len(top)))], 'white', bev=0)
o = PARTS[-1]
bot = [(-L / 2 + t * L, -wx(t) * f(0), keel(t)) for t in ts] + [(-L / 2 + t * L, wx(t) * f(0), keel(t)) for t in reversed(ts)]
poly(bot, [tuple(range(len(bot)))[::-1]], 'red2', bev=0)
tr = []
for j in range(7):
    zr = j / 6; z = keel(0) + (deck(0) - keel(0)) * zr; tr.append((-L / 2, -wx(0) * f(zr), z))
for j in reversed(range(7)):
    zr = j / 6; z = keel(0) + (deck(0) - keel(0)) * zr; tr.append((-L / 2, wx(0) * f(zr), z))
poly(tr, [tuple(range(len(tr)))], 'blue2', bev=0)
# deck rails (white) along both sides and around the bow
for sgn in (-1, 1):
    for i in range(NX):
        t0, t1 = ts[i], ts[i + 1]
        a = Vector((-L / 2 + t0 * L, sgn * (wx(t0) * f(1) - 0.6), deck(t0) + 1.6)); b = Vector((-L / 2 + t1 * L, sgn * (wx(t1) * f(1) - 0.6), deck(t1) + 1.6))
        c = (a + b) / 2; Ln = (b - a).length
        if Ln < 0.1: continue
        r = box((0.5, 0.5, Ln), (0, 0, 0), 'white', 0)
        r.matrix_world = Matrix.Translation(c) @ (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
        if i % 2 == 0: box((0.5, 0.5, 1.6), (a.x, a.y, a.z - 0.8), 'white', 0)
done("LM2_Ship_Hull")
# SUPERSTRUCTURE: bridge tower at the stern, funnel, mast
X0 = -L / 2
def SX(px): return X0 + (px - 634) * S
bx0, bx1 = SX(701), SX(788); bz0 = deck(0.1); bz1 = bz0 + (628 - 501) * S
box((bx1 - bx0, B * 0.8, bz1 - bz0 - 6), ((bx0 + bx1) / 2, 0, bz0 + (bz1 - bz0 - 6) / 2), 'white', 0.6)
box((bx1 - bx0 + 2, B * 0.96, 6), ((bx0 + bx1) / 2, 0, bz1 - 3), 'white', 0.6)      # bridge deck with wings
box((bx1 - bx0 - 4, B * 0.62, 3), ((bx0 + bx1) / 2, 0, bz1 + 1.5), 'grey', 0.4)
for sgn in (-1, 1):
    for k in range(6): box((0.8, B * 0.12, 2.6), (bx1 + 0.5, sgn * (B * 0.06 + k * B * 0.075) * 0 + (-B * 0.42 + k * B * 0.168), bz1 - 3), 'glass', 0.2) if sgn > 0 else None
    for row in range(3):
        for k in range(4): box((2.6, 0.8, 2.2), (bx0 + 3 + k * (bx1 - bx0 - 6) / 3, sgn * B * 0.4 + sgn * 0.3, bz0 + 4 + row * 5.5), 'glass', 0.2)
for k in range(3): box((0.8, 2.6, 2.2), (bx1 + 0.3, -B * 0.25 + k * B * 0.25, bz0 + 9.5), 'glass', 0.2)
box((0.9, B * 0.88, 3.2), (bx1 + 1.2, 0, bz1 - 3), 'glass', 0.3)
for k in range(1, 6): box((1.0, 0.6, 3.4), (bx1 + 1.3, -B * 0.44 + k * B * 0.88 / 6, bz1 - 3), 'white', 0)
cyl(0.7, 14, ((bx0 + bx1) / 2 + 3, 0, bz1 + 8), 'white', seg=8, bev=0.1)
box((0.6, 7, 0.6), ((bx0 + bx1) / 2 + 3, 0, bz1 + 11), 'white', 0)
fx = SX(690); fz0 = bz0 + 6
cyl(5.5, bz1 - fz0 + 4, (fx, 0, fz0 + (bz1 - fz0 + 4) / 2), 'red', seg=14, bev=0.5)
cyl(5.7, 2.6, (fx, 0, bz1 - 1), 'white', seg=14, bev=0.2)
cyl(5.6, 2.4, (fx, 0, bz1 + 4 + 1.2 - 2.4), 'black', seg=14, bev=0.3)
done("LM2_Ship_Bridge")
# CONTAINERS: 6 bays x 3 rows, 2-3 tiers
cols = ['blue', 'red', 'orange', 'green', 'roof_teal', 'blue', 'orange', 'red', 'green']
cl, cw, chh = 16.5, (B * 0.84) / 3, 7.6
x0 = SX(781) + 1
import random
rnd = random.Random(4)
for bay in range(6):
    tiers = 3 if bay in (1, 2, 3, 4) else 2
    for row in range(3):
        for tier in range(tiers):
            c = cols[(bay * 3 + row * 2 + tier) % len(cols)]
            x = x0 + bay * (cl + 1.2) + cl / 2; y = -B * 0.42 + cw * (row + 0.5); z = deck(0.5) + 0.2 + tier * chh + chh / 2
            box((cl, cw - 0.5, chh - 0.3), (x, y, z), c, 0.35)
            box((cl - 2, cw - 0.1, 0.5), (x, y, z), c + '2' if c + '2' in PAL else 'grey2', 0)
done("LM2_Ship_Cargo")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/ship.blend")
