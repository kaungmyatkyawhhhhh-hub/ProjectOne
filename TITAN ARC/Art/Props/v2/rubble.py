import sys, os, math, random
sys.path.insert(0, "/home/claude/props")
from lib import *
from lib import _finish, _place
from mathutils import Vector
import bpy
rnd = random.Random(5)
def chunk(sz, loc, col, jitter=0.12, rot=None):
    o = box(sz, loc, col, min(sz) * 0.18, rot=rot or (rnd.uniform(-35, 35), rnd.uniform(-35, 35), rnd.uniform(0, 360)))
    for v in o.data.vertices: v.co += Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))) * jitter * min(sz)
    return o
HZ = [0.5, 4.2]
def heap(col, r=4.2, h=0.9):
    HZ[0], HZ[1] = h, r
    blob(r, (0, 0, 0.0), col, sub=2, sq=(1.0, 1.0, h / r), seed=rnd.randint(0, 999))
def scatter(n, cols, smin, smax, R, zr=(0.3, 1.3)):
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi); d = rnd.uniform(0, R)
        s = rnd.uniform(smin, smax)
        chunk((s, s * rnd.uniform(0.6, 1.2), s * rnd.uniform(0.4, 0.8)), (math.cos(a) * d, math.sin(a) * d, HZ[0] * math.sqrt(max(0, 1 - (d / HZ[1]) ** 2)) + s * 0.25 + rnd.uniform(0, 0.3)), rnd.choice(cols))
# all piles authored on a 10 x 10 footprint, ~2.5 tall
def surf(d, r, h): return h * math.sqrt(max(0.0, 1 - (d / r) ** 2))
def garden():
    heap('soil', 4.6, 0.7)
    for i in range(6):
        a = rnd.uniform(0, 6.28); d = rnd.uniform(1.5, 4.2)
        box((3.0, 0.7, 0.35), (math.cos(a) * d, math.sin(a) * d, surf(d, 4.6, 0.7) + 0.15), rnd.choice(['wood', 'wood2', 'wall_brick', 'stone']), 0.1, rot=(rnd.uniform(-15, 15), rnd.uniform(-15, 15), rnd.uniform(0, 360)))
    for i in range(10):
        a = rnd.uniform(0, 6.28); d = rnd.uniform(0, 3.8)
        blob(0.55, (math.cos(a) * d, math.sin(a) * d, surf(d, 4.6, 0.7) + 0.2), rnd.choice(['petal_p', 'petal_y', 'petal_w', 'petal_v', 'petal_s', 'petal_o']), sq=(1.2, 1.2, 0.45), seed=i)
    for i in range(6):
        a = rnd.uniform(0, 6.28); d = rnd.uniform(0, 3.5)
        blob(0.75, (math.cos(a) * d, math.sin(a) * d, surf(d, 4.6, 0.7) + 0.15), 'leaf', sq=(1.2, 1, .6), seed=i + 40)
    done("Rubble_Garden")
def plastic():
    heap('grey', 4.2, 0.5)
    scatter(14, ['blue', 'green', 'red', 'grey2', 'blue2', 'green2'], 0.9, 2.0, 4.0, (0.3, 1.0))
    cyl(1.6, 0.35, (1.5, -1.0, 0.5), 'green2', seg=16, bev=0.08, rot=(12, 8, 0))       # a lid
    cyl(0.35, 4.5, (-1.0, 1.5, 0.6), 'grey2', seg=8, bev=0.05, rot=(80, 0, 30))         # a bent post
    box((1.6, 0.4, 1.0), (-2.4, -1.6, 0.6), 'red', 0.08, rot=(20, 10, 40))              # the flag
    done("Rubble_Plastic")
def metal():
    heap('grey2', 4.4, 0.45)
    o = box((6.0, 3.6, 1.2), (0, 0.3, 0.9), 'red', 0.3, rot=(6, -8, 15))               # crumpled body slab (tinted per prop in game? no: red reads as 'a car')
    for v in o.data.vertices: v.co += Vector((rnd.uniform(-.3, .3), rnd.uniform(-.3, .3), rnd.uniform(-.35, .35)))
    torus(1.1, 0.4, (3.0, -2.2, 0.55), 'tyre', rot=(10, 0, 0), maj=16, mn=6); cyl(0.65, 0.5, (3.0, -2.2, 0.6), 'rim', seg=12, bev=0.05, rot=(10, 0, 0))
    torus(1.1, 0.4, (-3.4, 1.8, 1.0), 'tyre', rot=(70, 20, 0), maj=16, mn=6)
    scatter(10, ['glass', 'glass2', 'chrome', 'grey', 'black', 'orange'], 0.5, 1.3, 4.2, (0.3, 1.2))
    for i in range(5): cyl(0.15, 2.2, (rnd.uniform(-3, 3), rnd.uniform(-3, 3), 0.7), 'chrome', seg=6, bev=0, rot=(rnd.uniform(60, 90), 0, rnd.uniform(0, 180)))
    done("Rubble_Metal")
def brick():
    heap('cream2', 4.8, 1.2)
    scatter(26, ['wall_brick', 'wall_brick2', 'cream', 'trim', 'stone'], 0.9, 1.8, 4.4, (0.6, 1.8))
    for i in range(6):   # roof tile slabs
        a = rnd.uniform(0, 6.28); d = rnd.uniform(0.5, 3.5)
        box((2.8, 2.0, 0.3), (math.cos(a) * d, math.sin(a) * d, 1.6), rnd.choice(['roof_red', 'roof_blue', 'roof_teal']), 0.08, rot=(rnd.uniform(-35, 35), rnd.uniform(-35, 35), rnd.uniform(0, 360)))
    box((2.6, 0.4, 2.8), (-1.5, 2.0, 1.6), 'white', 0.08, rot=(60, 10, 25)); box((2.0, 0.45, 2.2), (-1.5, 2.0, 1.6), 'glass', 0.05, rot=(60, 10, 25))   # a window frame
    box((5.0, 0.6, 0.6), (1.5, -1.0, 1.9), 'wood2', 0.1, rot=(0, 18, 60))              # a beam
    box((1.6, 0.35, 3.0), (2.5, 2.5, 1.2), 'door', 0.08, rot=(70, 0, -30))              # a door
    done("Rubble_Brick")
def concrete():
    heap('concrete2', 4.8, 1.4)
    scatter(14, ['concrete', 'concrete2', 'grey'], 1.6, 3.0, 4.2, (0.8, 2.0))
    scatter(10, ['glass', 'white', 'yellow3'], 0.5, 1.0, 4.4, (0.4, 1.6))
    for i in range(8): cyl(0.1, rnd.uniform(2, 3.5), (rnd.uniform(-3, 3), rnd.uniform(-3, 3), 1.8), 'rim', seg=5, bev=0, rot=(rnd.uniform(-50, 50), rnd.uniform(-50, 50), 0))
    done("Rubble_Concrete")
made = []
def done(n):
    o = join(n); made.append(o)
garden(); plastic(); metal(); brick(); concrete()
for o in made:
    o.data.calc_loop_triangles(); print(o.name, len(o.data.loop_triangles), [round(d, 2) for d in o.dimensions])
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/out/rubble.blend")
