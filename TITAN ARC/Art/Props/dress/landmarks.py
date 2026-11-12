import sys, os, math, random
sys.path.insert(0, "/home/claude/props")
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
from lib import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
def star(r1, r2, th, loc, col, axis='y'):
    pts = []
    for k in range(10):
        r = r1 if k % 2 == 0 else r2; t = math.pi / 2 + k * math.pi / 5
        pts.append((math.cos(t) * r, math.sin(t) * r))
    v = [(a, -th / 2, b) for (a, b) in pts] + [(a, th / 2, b) for (a, b) in pts]
    f = [tuple(range(10)), tuple(range(19, 9, -1))] + [(k, (k + 1) % 10, (k + 1) % 10 + 10, k + 10) for k in range(10)]
    return poly(v, f, col, loc, bev=min(th * 0.3, 0.3))
# CLOCK TOWER (~16 x 16 x 46): brick tower, white trim, 4 clock faces, blue spire, gold star
def clocktower():
    box((16, 16, 2), (0, 0, 1), 'stone2', 0.3)
    box((13, 13, 26), (0, 0, 15), 'wall_brick', 0.4)
    for z in (6, 12, 18, 24): box((13.6, 13.6, 0.8), (0, 0, z), 'wall_brick2', 0.2)
    for x in (-6.5, 6.5):
        for y in (-6.5, 6.5): box((1.6, 1.6, 26), (x, y, 15), 'cream', 0.3)
    box((5, 0.8, 7), (0, -6.7, 5.5), 'cream', 0.3); box((3.6, 0.9, 6), (0, -6.8, 5.0), 'door', 0.2)
    box((14.5, 14.5, 9), (0, 0, 32.5), 'cream', 0.4)
    for a in range(4):
        rot = a * 90; dx, dy = [(0, -1), (1, 0), (0, 1), (-1, 0)][a]
        cx, cy = dx * 7.35, dy * 7.35
        o = cyl(3.6, 0.6, (cx, cy, 32.5), 'gold', seg=24, bev=0.15, rot=(90, 0, rot)); 
        cyl(3.1, 0.7, (cx + dx * 0.05, cy + dy * 0.05, 32.5), 'white', seg=24, bev=0.1, rot=(90, 0, rot))
        for h in range(12):
            t = h * math.pi / 6
            bx = cx + dx * 0.4 + (math.cos(t) * 2.6 if dy != 0 else 0)
            by = cy + dy * 0.4 + (math.cos(t) * 2.6 if dx != 0 else 0)
            box((0.35, 0.35, 0.35), (bx, by, 32.5 + math.sin(t) * 2.6), 'black', 0.05)
        box((0.35 if dy else 0.5, 0.5 if dy else 0.35, 2.2), (cx + dx * 0.5, cy + dy * 0.5, 33.4), 'black', 0.08)
        box((1.8 if dy else 0.5, 0.5 if dy else 1.8, 0.35), (cx + dx * 0.5 + (0.8 if dy else 0), cy + dy * 0.5 + (0.8 if dx else 0), 32.5), 'black', 0.08)
    box((15.5, 15.5, 1.2), (0, 0, 37.6), 'trim', 0.3)
    hip(14, 14, 7, (0, 0, 38.2), 'roof_blue', over=0.5, top=0.05)
    cyl(0.5, 3, (0, 0, 46.5), 'gold', seg=8, bev=0.1)
    o = star(2.0, 0.85, 0.8, (0, 0, 49.5), 'yellow')
    done("LM_ClockTower")
# FOUNTAIN SQUARE (~30 x 30): round plaza tiles, a two-tier fountain with water, 4 planters
def fountain():
    cyl(15, 0.4, (0, 0, 0.2), 'concrete', seg=32, bev=0.1)
    for i in range(16):
        a = i * math.pi / 8
        box((2.2, 5.5, 0.1), (math.cos(a) * 11, math.sin(a) * 11, 0.45), 'concrete2', 0.03, rot=(0, 0, math.degrees(a)))
    cyl(7, 1.4, (0, 0, 1.1), 'stone', seg=24, bev=0.25)
    cyl(6.3, 0.3, (0, 0, 1.75), 'sky', seg=24, bev=0.05)
    cyl(1.2, 4.0, (0, 0, 3.6), 'stone', seg=12, bev=0.2)
    cyl(3.6, 0.8, (0, 0, 5.6), 'stone', seg=16, bev=0.2, r2=2.6)
    cyl(3.2, 0.25, (0, 0, 6.0), 'sky', seg=16, bev=0.05)
    cyl(0.6, 2.0, (0, 0, 7.0), 'stone', seg=8, bev=0.1)
    blob(1.0, (0, 0, 8.4), 'glass2', sub=2, sq=(1, 1, 1.4))
    for i in range(6):                 # falling water ribbons
        a = i * math.pi / 3
        box((0.8, 0.25, 3.2), (math.cos(a) * 3.3, math.sin(a) * 3.3, 4.0), 'glass2', 0.1, rot=(0, 0, math.degrees(a) + 90))
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4; x, y = math.cos(a) * 12, math.sin(a) * 12
        box((3.2, 3.2, 1.2), (x, y, 0.8), 'wall_brick', 0.2); box((2.8, 2.8, 0.3), (x, y, 1.45), 'soil', 0.05)
        for k in range(3): blob(0.6, (x - 0.6 + k * 0.6, y + (k % 2) * 0.5 - 0.25, 1.9), ['petal_p', 'petal_y', 'petal_v'][k], sub=2, sq=(1, 1, 0.7), seed=k + i * 3)
    done("LM_Fountain")
# FERRIS WHEEL: the stand and the wheel are separate meshes (the wheel turns in game); 8 gondolas separate too
def ferris():
    for s in (-1, 1):
        for a in (-24, 24):
            box((1.4, 1.4, 32), (math.sin(math.radians(a)) * 13, s * 4, 15), 'white', 0.3, rot=(0, -a, 0))
        box((4, 2, 1.6), (0, s * 4, 30), 'red', 0.3)
    cyl(1.2, 9.5, (0, 0, 30), 'grey2', seg=12, bev=0.15, rot=(90, 0, 0))
    box((32, 12, 1.2), (0, 0, 0.6), 'concrete', 0.3)
    box((8, 6, 4), (0, -8, 2), 'red', 0.4); box((8.6, 6.6, 1), (0, -8, 4.4), 'yellow', 0.3)
    done("LM_FerrisStand")
    R = 22
    for s in (-1.8, 1.8):
        torus(R, 0.55, (0, s, 0), 'red', rot=(90, 0, 0), maj=48, mn=6)
        torus(R * 0.55, 0.35, (0, s, 0), 'yellow', rot=(90, 0, 0), maj=32, mn=6)
        for k in range(16):
            a = k * math.pi / 8
            box((0.4, 0.4, R), (math.cos(a) * R / 2, s, math.sin(a) * R / 2), 'white', 0.08, rot=(0, -math.degrees(a) + 90, 0))
    cyl(2.2, 4.4, (0, 0, 0), 'yellow', seg=12, bev=0.3, rot=(90, 0, 0))
    for k in range(8):
        a = k * math.pi / 4
        cyl(0.25, 4.2, (math.cos(a) * R, 0, math.sin(a) * R), 'grey2', seg=6, bev=0, rot=(90, 0, 0))
    for k in range(16):
        a = k * math.pi / 8 + math.pi / 16
        blob(0.45, (math.cos(a) * R, 2.3, math.sin(a) * R), 'light', sub=1)
        blob(0.45, (math.cos(a) * R, -2.3, math.sin(a) * R), 'light', sub=1)
    done("LM_FerrisWheel")
    for c in range(4):
        col = ['sky', 'pink', 'lime' if 'lime' in PAL else 'green', 'yellow'][c]
        box((3.2, 3.0, 2.6), (0, 0, -2.4), col, 0.6, seg=2)
        box((3.4, 3.2, 0.5), (0, 0, -0.9), 'white', 0.2)
        box((2.6, 3.1, 1.0), (0, 0, -2.0), 'glass2', 0.2)
        cyl(0.2, 1.2, (0, 0, -0.3), 'grey2', seg=6, bev=0)
        done("LM_Gondola_%d" % (c + 1))
# TOY TRAIN: engine + 2 carriages (separate), rails piece, station
def train():
    # engine (faces +x)
    box((9, 4.2, 1.2), (0, 0, 1.4), 'black', 0.3)
    cyl(1.9, 6, (1.2, 0, 3.6), 'red', seg=14, bev=0.3, rot=(0, 90, 0))
    box((3.6, 4.4, 4.6), (-2.6, 0, 4.4), 'red', 0.4); box((4.2, 5.0, 0.6), (-2.6, 0, 7.0), 'black', 0.2)
    box((3.7, 4.5, 1.6), (-2.6, 0, 5.4), 'glass2', 0.2)
    cyl(0.7, 2.6, (3.2, 0, 6.4), 'black', seg=10, bev=0.15, r2=1.0); cyl(1.0, 0.4, (3.2, 0, 7.8), 'gold', seg=10, bev=0.08)
    blob(0.8, (0.6, 0, 5.8), 'gold', sub=2, sq=(1, 1, 0.8))
    cyl(1.95, 0.3, (4.25, 0, 3.6), 'gold', seg=14, bev=0.08, rot=(0, 90, 0)); blob(0.5, (4.5, 0, 3.6), 'light', sub=1)
    box((1.4, 4.4, 0.8), (4.8, 0, 1.0), 'yellow', 0.2, rot=(0, -25, 0))
    for x in (-3, 0, 3):
        for y in (-2.2, 2.2): cyl(1.1, 0.5, (x, y, 1.2), 'yellow', seg=12, bev=0.1, rot=(90, 0, 0)); cyl(0.4, 0.55, (x, y, 1.2), 'black', seg=8, bev=0.05, rot=(90, 0, 0))
    done("LM_TrainEngine")
    for c, col in enumerate(('sky', 'green')):
        box((9, 4.0, 1.0), (0, 0, 1.4), 'black', 0.3)
        box((8.6, 4.4, 4.2), (0, 0, 4.0), col, 0.5); box((9.2, 5.0, 0.6), (0, 0, 6.3), 'white', 0.25)
        for x in (-2.6, 0, 2.6):
            for y in (-2.21, 2.21): box((1.8, 0.1, 1.6), (x, y, 4.4), 'glass', 0.05)
        for x in (-3, 3):
            for y in (-2.0, 2.0): cyl(1.0, 0.5, (x, y, 1.1), 'yellow', seg=12, bev=0.1, rot=(90, 0, 0))
        done("LM_TrainCar_%d" % (c + 1))
    # a 20-stud rail piece: ballast + sleepers + 2 rails
    box((20, 5.6, 0.5), (0, 0, 0.25), 'stone2', 0.15)
    for k in range(8): box((1.0, 5.0, 0.4), (-8.75 + k * 2.5, 0, 0.6), 'wood2', 0.08)
    for y in (-1.6, 1.6): box((20, 0.4, 0.5), (0, y, 0.95), 'chrome', 0.08)
    done("LM_Rail")
    # station: platform + roof + bench + clock
    box((40, 10, 1.6), (0, 0, 0.8), 'concrete', 0.3)
    for x in (-16, -8, 0, 8, 16): cyl(0.45, 7, (x, 2.5, 5.1), 'green2', seg=8, bev=0.08)
    box((42, 8, 0.8), (0, 1.5, 8.8), 'red', 0.3)
    for k in range(10): box((4.2, 8.2, 0.3), (-18.9 + k * 4.2, 1.5, 9.3), 'red2' if k % 2 else 'awn_white', 0.1)
    box((14, 5, 6), (0, 4.5, 4.6), 'cream', 0.4); box((3, 0.4, 4), (0, 1.9, 3.6), 'door', 0.1)
    for x in (-5, 5): box((2.6, 0.4, 2.2), (x, 1.9, 4.6), 'glass', 0.1)
    cyl(1.4, 0.5, (0, 1.6, 8.0), 'white', seg=16, bev=0.1, rot=(90, 0, 0))
    done("LM_Station")
def bird():
    blob(0.5, (0, 0, 0), 'white', sub=2, sq=(1.6, 0.8, 0.8))
    blob(0.35, (0.75, 0, 0.15), 'white', sub=1); box((0.35, 0.15, 0.12), (1.15, 0, 0.1), 'orange', 0.03)
    for s in (-1, 1): box((0.9, 1.8, 0.12), (0, s * 1.1, 0.15), 'grey', 0.05, rot=(s * 18, 0, 0))
    box((0.6, 0.6, 0.1), (-0.85, 0, 0.05), 'grey', 0.04)
    done("LM_Bird")
def balloon():
    for i, c in enumerate(('red', 'yellow', 'sky', 'pink')):
        blob(1.2, (0, 0, 0), c, sub=2, sq=(1, 1, 1.2)); cyl(0.2, 0.35, (0, 0, -1.45), c, seg=6, bev=0.04, r2=0.08)
        cyl(0.03, 4.0, (0, 0, -3.6), 'white', seg=4, bev=0)
        done("LM_Balloon_%d" % (i + 1))
clocktower(); fountain(); ferris(); train(); bird(); balloon()
for o in made: o.data.calc_loop_triangles(); print(o.name, len(o.data.loop_triangles), [round(d, 1) for d in o.dimensions])
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/out2/landmarks.blend")
for o in bpy.data.objects: o.select_set(o.type == 'MESH')
bpy.ops.export_scene.fbx(filepath="/home/claude/props/out2/StompLandmarks_v1.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
