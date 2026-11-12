import sys, os, math, random
sys.path.insert(0, "/home/claude/props")
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
from lib import *
from lib import _finish, _place
from mathutils import Vector
rnd = random.Random(3)
made = []
def done(n): made.append(join(n))
# ---------- trees (round blob tree like the concept, a pine, a blossom tree) ----------
def tree_round(n, leaf=('leaf', 'leaf2', 'leaf3')):
    cyl(0.55, 5.0, (0, 0, 2.5), 'bark', seg=8, bev=0.1, r2=0.4)
    for a, l, h in ((40, 2.2, 3.6), (200, 2.0, 4.0), (300, 1.6, 3.2)):
        box((0.35, 0.35, l), (math.cos(math.radians(a)) * 0.6, math.sin(math.radians(a)) * 0.6, h), 'bark', 0.05, rot=(0, 35, a))
    pts = [(0, 0, 7.2, 2.6), (1.7, 0.6, 6.0, 1.9), (-1.6, -0.4, 6.2, 2.0), (0.3, -1.6, 6.1, 1.8), (-0.4, 1.6, 6.4, 1.8), (0.4, 0.2, 8.6, 1.7)]
    for i, (x, y, z, r) in enumerate(pts): blob(r, (x, y, z), leaf[i % len(leaf)], sub=2, sq=(1, 1, 0.92), seed=n * 10 + i)
    cyl(1.3, 0.25, (0, 0, 0.12), 'soil', seg=10, bev=0.05)
    done("Tree_Round_%d" % n)
def tree_pine():
    cyl(0.45, 2.0, (0, 0, 1.0), 'bark', seg=8, bev=0.08)
    for i, (r, z) in enumerate(((2.6, 2.6), (2.1, 4.3), (1.6, 5.9), (1.0, 7.3))):
        cyl(r, 2.2, (0, 0, z), 'leaf2' if i % 2 == 0 else 'green2', seg=8, bev=0.12, r2=0.15)
    done("Tree_Pine")
def tree_blossom():
    cyl(0.5, 4.2, (0, 0, 2.1), 'bark', seg=8, bev=0.1, r2=0.35)
    for i, (x, y, z, r) in enumerate([(0, 0, 6.0, 2.3), (1.5, 0.5, 5.2, 1.7), (-1.4, -0.3, 5.3, 1.7), (0.2, -1.4, 5.4, 1.6), (-0.2, 1.4, 5.6, 1.6)]):
        blob(r, (x, y, z), 'pink' if i % 2 == 0 else 'petal_p', sub=2, sq=(1, 1, 0.9), seed=70 + i)
    done("Tree_Blossom")
# ---------- street furniture ----------
def lamp():
    cyl(0.55, 0.5, (0, 0, 0.25), 'green2', seg=8, bev=0.1)
    cyl(0.2, 6.0, (0, 0, 3.2), 'green2', seg=8, bev=0.05)
    cyl(0.32, 0.4, (0, 0, 6.3), 'green', seg=8, bev=0.06)
    cyl(0.55, 1.2, (0, 0, 7.1), 'light', seg=8, bev=0.08, r2=0.45)
    cyl(0.75, 0.3, (0, 0, 7.8), 'green2', seg=8, bev=0.08)
    cyl(0.5, 0.6, (0, 0, 8.2), 'green', seg=8, bev=0.1, r2=0.1)
    blob(0.18, (0, 0, 8.6), 'green2', sub=1)
    done("Lamp")
def bench():
    for x in (-1.6, 1.6):
        box((0.25, 1.4, 0.9), (x, 0, 0.45), 'grey2', 0.05); box((0.25, 0.2, 1.4), (x, 0.6, 1.2), 'grey2', 0.04)
    for i in range(3): box((4.0, 0.42, 0.18), (0, -0.4 + i * 0.45, 1.0), 'wood', 0.05)
    for i in range(2): box((4.0, 0.18, 0.42), (0, 0.72, 1.45 + i * 0.5), 'wood', 0.05)
    done("Bench")
def hedge():
    box((6.0, 1.6, 1.8), (0, 0, 0.9), 'leaf2', 0.4, seg=2)
    for i in range(5): blob(0.75, (-2.4 + i * 1.2, 0, 1.75), 'leaf' if i % 2 else 'leaf3', sub=1, sq=(1, 0.9, 0.7), seed=i)
    done("Hedge")
def fence():
    for i in range(5): box((0.35, 0.25, 1.6), (-2.6 + i * 1.3, 0, 0.8), 'white', 0.05); box((0.35, 0.26, 0.3), (-2.6 + i * 1.3, 0, 1.68), 'white', 0.1, rot=(0, 45, 0))
    for z in (0.5, 1.2): box((6.0, 0.15, 0.22), (0, 0.12, z), 'white', 0.04)
    done("Fence")
def hydrant():
    cyl(0.4, 1.1, (0, 0, 0.55), 'red', seg=10, bev=0.08); blob(0.42, (0, 0, 1.15), 'red', sub=1, sq=(1, 1, 0.7))
    cyl(0.18, 0.6, (0, 0, 0.75), 'chrome', seg=6, bev=0.03, rot=(90, 0, 0)); cyl(0.55, 0.15, (0, 0, 0.08), 'red2', seg=10, bev=0.03)
    done("Hydrant")
def tlight():
    cyl(0.2, 7.5, (0, 0, 3.75), 'grey2', seg=8, bev=0.04)
    box((5.0, 0.3, 0.3), (2.4, 0, 7.3), 'grey2', 0.05)
    box((0.9, 0.9, 2.6), (4.6, 0, 6.2), 'black', 0.15)
    for i, c in enumerate(('red', 'yellow', 'green')): cyl(0.3, 0.2, (4.6, -0.5, 6.95 - i * 0.75), c, seg=12, bev=0.05, rot=(90, 0, 0))
    done("TrafficLight")
# ---------- landscape ----------
def hill(n):
    blob(30, (0, 0, -6), 'leaf' if n == 1 else 'leaf3', sub=3, sq=(1.4, 1.0, 0.45), seed=200 + n)
    done("Hill_%d" % n)
def cloud(n):
    r = random.Random(300 + n)
    for i in range(5): blob(r.uniform(4, 7), (i * 5 - 10 + r.uniform(-1, 1), r.uniform(-2, 2), r.uniform(0, 2.5)), 'white', sub=2, sq=(1.2, 1, 0.75), seed=n * 10 + i)
    done("Cloud_%d" % n)
for n in (1, 2): tree_round(n)
tree_pine(); tree_blossom(); lamp(); bench(); hedge(); fence(); hydrant(); tlight(); hill(1); hill(2); cloud(1); cloud(2)
for o in made:
    o.data.calc_loop_triangles(); print(o.name, len(o.data.loop_triangles), [round(d, 1) for d in o.dimensions])
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/out2/dress.blend")
for o in bpy.data.objects: o.select_set(o.type == 'MESH')
bpy.ops.export_scene.fbx(filepath="/home/claude/props/out2/StompDress_v1.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
