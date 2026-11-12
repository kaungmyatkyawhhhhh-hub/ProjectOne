# GIANT PLAYGROUND (Starter Park landmark) from sheet se_lm_playground (ChatGPT, 13 Nov). Units ~studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
made = []
def done(n): made.append(join(n))
# BASE: soft green rubber disc + blue mat at the slide's end
cyl(24, 2.0, (0, 0, 1.0), 'green', seg=40, bev=0.7)
cyl(23, 0.3, (0, 0, 2.05), 'leaf', seg=40, bev=0.1)
box((8, 7, 0.9), (0, -26.5, 1.0), 'sky', 0.35)
done("LM2_Play_Base")
G = 2.2  # ground (top of the disc)
# TOWER: 4 red posts 16 apart, two yellow decks, panels with holes, red pyramid roof, gold ball
H = 26; half = 7.6
for sx in (-1, 1):
    for sy in (-1, 1):
        box((2.4, 2.4, H), (sx * half, sy * half, G + H / 2), 'red', 0.4)
for zd in (9.5, 18.0):
    box((17.5, 17.5, 1.2), (0, 0, G + zd), 'yellow', 0.35)
    box((15, 15, 0.6), (0, 0, G + zd - 0.9), 'wood', 0.1)
def panel(cx, cy, z, rotz, w=12.6, h=4.2):
    m = mark()
    box((w, 0.9, h), (0, 0, 0), 'yellow', 0.35)
    for i in (-1, 0, 1): cyl(1.15, 1.0, (i * 3.6, 0, 0), 'yellow2', seg=12, bev=0.1, rot=(90, 0, 0))
    for o in PARTS[m:]:
        o.data.transform(o.matrix_basis); o.matrix_basis = Matrix.Identity(4)
        o.data.transform(Matrix.Translation((cx, cy, z)) @ Matrix.Rotation(math.radians(rotz), 4, 'Z'))
# lower deck: panels front/back/left (right is open toward the swings), upper deck: back/left/right (front open for the slide)
panel(0, -half, G + 9.5 + 2.7, 0); panel(0, half, G + 9.5 + 2.7, 0); panel(-half, 0, G + 9.5 + 2.7, 90)
panel(0, half, G + 18 + 2.7, 0); panel(-half, 0, G + 18 + 2.7, 90); panel(half, 0, G + 18 + 2.7, 90)
# roof: red pyramid with eaves, gold ball
hip(16, 16, 7.5, (0, 0, G + H), 'roof_red', over=1.4, top=0.02)
box((18.4, 18.4, 0.9), (0, 0, G + H - 0.2), 'red2', 0.3)
blob(2.0, (0, 0, G + H + 9.4), 'yellow', sub=2)
cyl(0.4, 1.4, (0, 0, G + H + 7.6), 'yellow2', seg=8, bev=0.1)
done("LM2_Play_Tower")
# SLIDE: wide yellow chute from the upper deck (front edge) down toward -y in one smooth bend
def chute(path, w=5.4, wall=1.6, th=0.5):
    # U section: outer bottom + inner bottom + walls; stations along path [(x,y,z)]
    sec_out = [(-w / 2 - th, wall), (-w / 2 - th, -th), (w / 2 + th, -th), (w / 2 + th, wall)]
    sec_in = [(w / 2, wall), (w / 2, 0), (-w / 2, 0), (-w / 2, wall)]
    sec = sec_out + sec_in            # closed loop of 8
    verts = []; faces = []
    n = len(sec)
    for i, (x, y, z) in enumerate(path):
        # direction for the station frame (slide runs mostly along -y): normal = up rotated by slope
        j = min(i + 1, len(path) - 1); k = max(i - 1, 0)
        d = Vector(path[j]) - Vector(path[k]); d.normalize()
        side = Vector((1, 0, 0)); up = side.cross(d) * -1
        if up.z < 0: up = -up
        for (sx, sz) in sec: verts.append(tuple(Vector((x, y, z)) + side * sx + up * sz))
    for i in range(len(path) - 1):
        a, b = i * n, (i + 1) * n
        for s in range(n):
            t = (s + 1) % n
            faces.append((a + s, a + t, b + t, b + s))
    faces.append(tuple(range(n))[::-1]); faces.append(tuple(range((len(path) - 1) * n, len(path) * n)))
    return poly(verts, faces, 'yellow', bev=0)
P = []
N = 18
for i in range(N + 1):
    t = i / N
    y = -half - 0.5 - 19 * t
    z = G + 18.6 - 16.4 * (0.5 - 0.5 * math.cos(math.pi * min(1, t * 1.08)))
    x = 0.0          # a gentle sideways bend
    P.append((x, y, z))
P.append((P[-1][0], P[-1][1] - 3.2, G + 2.6))
chute(P)
# rails along the top of the walls
for sgn in (-1, 1):
    pts = [(p[0] + sgn * 3.25, p[1], p[2] + 1.75) for p in P]
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1]); c = (a + b) / 2; L = (b - a).length
        o = cyl(0.42, L + 0.3, (0, 0, 0), 'yellow2', seg=6, bev=0)
        o.matrix_world = Matrix.Translation(c) @ (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
# two support legs under the slide
for t in (0.45,):
    p = P[int(N * t)]
    box((1.2, 1.2, p[2] - G), (p[0] - 2.2, p[1], G + (p[2] - G) / 2 - 0.4), 'red', 0.2)
    box((1.2, 1.2, p[2] - G), (p[0] + 2.2, p[1], G + (p[2] - G) / 2 - 0.4), 'red', 0.2)
done("LM2_Play_Slide")
# LADDER: sky-blue, leaning out on the left (-x) up to the lower deck
for sy in (-1, 1):
    o = box((1.0, 1.0, 13.5), (-half - 3.75, sy * 2.6, G + 6.2), 'sky', 0.3, rot=(0, 24, 0))
for k in range(5):
    z = G + 1.8 + k * 2.2; x = -half - 6.5 + (z - G) * math.tan(math.radians(24))
    box((0.9, 5.8, 0.8), (x, 0, z), 'sky', 0.25)
done("LM2_Play_Ladder")
# SWINGS: red A-frame legs, yellow top bar, white chains, blue seats, on the +x side, a little to the back
sx0 = half + 13; sy0 = 2
for ex in (-8.5, 8.5):
    for sgn in (-1, 1):
        box((1.3, 1.3, 15.5), (sx0 + ex * 0 + 0, sy0 + sgn * 3.0, 0), 'red', 0.3)
        o = PARTS[-1]
        o.data.transform(Matrix.Translation((0, 0, 0)))
        o.matrix_world = Matrix.Translation((sx0 + ex, sy0 + sgn * 2.6, G + 7.2)) @ Matrix.Rotation(math.radians(sgn * 16), 4, 'X')
box((19, 1.5, 1.5), (sx0, sy0, G + 14.6), 'yellow', 0.4)
for cx in (-3.6, 3.6):
    for sgn in (-1, 1): box((0.35, 0.35, 9.8), (sx0 + cx + sgn * 1.4, sy0, G + 9.2), 'white', 0)
    box((4.2, 2.0, 0.7), (sx0 + cx, sy0, G + 4.2), 'sky', 0.3)
done("LM2_Play_Swings")
tot = 0
for o in made:
    # apply object matrices into mesh (some parts were placed by matrix_world)
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions], [round(v, 1) for v in o.location])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/playground.blend")
