import sys, os, math, random
sys.path.insert(0, "/home/claude/props")
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
from lib import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
# REFORGE SHRINE (fits a 26-stud footprint): round stone steps, 4 crystal pillars, an anvil in the middle with a violet crystal rooted in it
def reforge():
    cyl(13, 0.6, (0, 0, 0.3), 'stone2', seg=24, bev=0.15)
    cyl(11.5, 0.6, (0, 0, 0.9), 'stone', seg=24, bev=0.15)
    cyl(9.5, 0.5, (0, 0, 1.45), 'concrete', seg=24, bev=0.12)
    for i in range(12):                                   # violet inlay tiles
        a = i * math.pi / 6
        box((1.4, 2.6, 0.1), (math.cos(a) * 7.6, math.sin(a) * 7.6, 1.72), 'violet', 0.05, rot=(0, 0, math.degrees(a)))
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4; x, y = math.cos(a) * 8.6, math.sin(a) * 8.6
        cyl(1.1, 0.6, (x, y, 2.0), 'stone2', seg=8, bev=0.1)
        cyl(0.75, 5.0, (x, y, 4.6), 'concrete', seg=8, bev=0.1)
        cyl(1.0, 0.5, (x, y, 7.3), 'stone2', seg=8, bev=0.1)
        for k, (dx, dy, h, r) in enumerate(((0, 0, 2.2, 0.55), (0.45, 0.2, 1.4, 0.38), (-0.4, -0.25, 1.6, 0.4))):  # crystal cluster ROOTED on top
            cyl(r, h, (x + dx, y + dy, 7.6 + h / 2), 'violet' if k == 0 else 'lilac', seg=6, bev=0.04, r2=0.05, rot=(dx * 25, dy * 25, 0))
    # anvil on a pedestal
    box((3.6, 3.6, 2.6), (0, 0, 2.95), 'stone2', 0.25)
    box((4.4, 2.0, 0.7), (0, 0, 4.6), 'grey2', 0.12)
    box((3.0, 1.5, 0.9), (0, 0, 3.9), 'grey2', 0.12)
    box((5.6, 2.2, 1.0), (0, 0, 5.4), 'black', 0.18)
    cyl(1.05, 2.0, (2.9, 0, 5.4), 'black', seg=8, bev=0.1, r2=0.25, rot=(0, 90, 0))   # the horn
    for k, (dx, dy, h, r, rx, ry) in enumerate(((0, 0, 4.2, 0.9, 0, 0), (0.7, 0.4, 2.6, 0.55, 18, -12), (-0.7, -0.3, 2.9, 0.6, -15, 14), (0.2, -0.8, 2.2, 0.45, 20, 20))):
        cyl(r, h, (-1.2 + dx, dy, 5.9 + h / 2), 'violet' if k % 2 == 0 else 'lilac', seg=6, bev=0.05, r2=0.08, rot=(rx, ry, 0))
    box((0.5, 0.5, 3.4), (1.3, 0.9, 7.2), 'wood', 0.06, rot=(0, -28, 0)); box((1.6, 1.0, 0.9), (2.1, 0.9, 8.6), 'grey2', 0.12, rot=(0, -28, 0))  # hammer leaning
    done("Shrine_Reforge")
# AWAKEN ALTAR (96-stud plaza): tiered white + gold rings, 8 pillars with star finials, a central star on a pedestal
def awaken():
    cyl(48, 1.2, (0, 0, 0.6), 'cream2', seg=40, bev=0.3)
    cyl(46.5, 0.4, (0, 0, 1.3), 'gold', seg=40, bev=0.1)
    cyl(44, 1.0, (0, 0, 1.7), 'cream', seg=40, bev=0.25)
    cyl(30, 0.8, (0, 0, 2.6), 'trim', seg=36, bev=0.2)
    cyl(28.5, 0.25, (0, 0, 3.05), 'gold', seg=36, bev=0.06)
    for i in range(16):
        a = i * math.pi / 8
        box((4.0, 1.2, 0.12), (math.cos(a) * 37, math.sin(a) * 37, 2.25), 'yellow3', 0.05, rot=(0, 0, math.degrees(a)))
    for i in range(8):
        a = i * math.pi / 4; x, y = math.cos(a) * 44, math.sin(a) * 44
        box((6.5, 6.5, 2.0), (x, y, 3.2), 'trim', 0.3)
        cyl(2.4, 34, (x, y, 21), 'white', seg=10, bev=0.2)
        for k in range(10): box((0.6, 0.6, 33), (x + math.cos(k * 0.628) * 2.35, y + math.sin(k * 0.628) * 2.35, 21), 'cream', 0.1)   # fluting
        box((6.0, 6.0, 1.6), (x, y, 38.8), 'gold', 0.25)
        cyl(1.4, 2.0, (x, y, 40.6), 'gold', seg=8, bev=0.15)
        # a chunky 5-point star finial (extruded)
        pts = []
        for k in range(10):
            r = 3.2 if k % 2 == 0 else 1.4; t = math.pi / 2 + k * math.pi / 5
            pts.append((math.cos(t) * r, 0, math.sin(t) * r))
        verts = [(px_, -0.8, pz) for (px_, _, pz) in pts] + [(px_, 0.8, pz) for (px_, _, pz) in pts]
        faces = [tuple(range(10)), tuple(range(19, 9, -1))] + [(k, (k + 1) % 10, (k + 1) % 10 + 10, k + 10) for k in range(10)]
        o = poly(verts, faces, 'yellow', (x, y, 44.6), bev=0.25)
        o.rotation_euler = (0, 0, a + math.pi / 2); bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.transform_apply(location=False, rotation=True, scale=False); o.select_set(False)
    # central pedestal + big star
    cyl(6, 3.0, (0, 0, 4.5), 'trim', seg=16, bev=0.3); cyl(6.4, 0.5, (0, 0, 6.2), 'gold', seg=16, bev=0.1)
    cyl(3.5, 3.0, (0, 0, 7.9), 'white', seg=12, bev=0.2)
    pts = []
    for k in range(10):
        r = 5.5 if k % 2 == 0 else 2.3; t = math.pi / 2 + k * math.pi / 5
        pts.append((math.cos(t) * r, math.sin(t) * r))
    verts = [(a_, -1.2, b_) for (a_, b_) in pts] + [(a_, 1.2, b_) for (a_, b_) in pts]
    faces = [tuple(range(10)), tuple(range(19, 9, -1))] + [(k, (k + 1) % 10, (k + 1) % 10 + 10, k + 10) for k in range(10)]
    poly(verts, faces, 'yellow', (0, 0, 15.2), bev=0.4)
    cyl(0.9, 3.0, (0, 0, 10.6), 'gold', seg=8, bev=0.1)
    done("Shrine_Awaken")
reforge(); awaken()
for o in made: o.data.calc_loop_triangles(); print(o.name, len(o.data.loop_triangles), [round(d, 1) for d in o.dimensions])
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/out2/shrines.blend")
for o in bpy.data.objects: o.select_set(o.type == 'MESH')
bpy.ops.export_scene.fbx(filepath="/home/claude/props/out2/StompShrines_v1.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
