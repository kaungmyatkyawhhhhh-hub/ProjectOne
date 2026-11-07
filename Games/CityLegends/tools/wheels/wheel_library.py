"""Our own rims (owner, 2026-11-06: "also make our own very similar wheels", Prompts/Small design changes on famous new cars.md).
Six designs of our own, by style family only: no real rim copied, no logos, blank centre caps. Each design is two meshes
in one unit box (radius 1, width 0.62, +X the outer face): Face (spokes, hub, bolts) and Lip (barrel and polished lip), so the
game sizes them to any car's rim with MeshPart.Size and colours them apart.

    blender -b --factory-startup --python tools/wheels/wheel_library.py -- out.fbx renders_dir
"""

import math
import os
import sys

import bmesh
import bpy

args = sys.argv[sys.argv.index("--") + 1 :]
out_fbx, out_dir = args[0], args[1]
os.makedirs(out_dir, exist_ok=True)
SEG = 96
W = 0.31  # half the width


def lathe(bm, profile, seg=SEG, a0=0.0):
    rings = []
    for x, r in profile:
        ring = []
        for i in range(seg):
            a = a0 + i / seg * math.tau
            ring.append(bm.verts.new((x, r * math.cos(a), r * math.sin(a))))
        rings.append(ring)
    for k in range(len(rings) - 1):
        a, b = rings[k], rings[k + 1]
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((a[i], a[j], b[j], b[i]))


def spoke(bm, ang, r0, r1, w0, w1, front, thick, steps=8, twist=0.0, side=0.0, side_to=None):
    """a tapered bar from the hub to the rim. front(t): X of its front face. side: moved sideways from the centre line"""
    side_to = side if side_to is None else side_to
    rings = []
    for k in range(steps + 1):
        t = k / steps
        r = r0 + (r1 - r0) * t
        w = w0 + (w1 - w0) * t
        a = ang + twist * t
        s = side + (side_to - side) * t
        dy, dz = math.cos(a), math.sin(a)
        py, pz = -dz, dy
        xf = front(t)
        sec = ((-w / 2, xf - thick), (w / 2, xf - thick), (w * 0.42, xf), (-w * 0.42, xf))
        ring = []
        for off, x in sec:
            q = s + off
            ring.append(bm.verts.new((x, dy * r + py * q, dz * r + pz * q)))
        rings.append(ring)
    for k in range(steps):
        a, b = rings[k], rings[k + 1]
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((a[i], a[j], b[j], b[i]))
    for ring, flip in ((rings[0], True), (rings[-1], False)):
        bm.faces.new(ring if not flip else list(reversed(ring)))


def hub(bm, front, r=0.27, bolts=5, nut=False):
    lathe(bm, [(front - 0.1, r), (front, r), (front + 0.012, r - 0.02), (front + 0.015, r * 0.5), (front + 0.03, r * 0.36), (front + 0.036, r * 0.3), (front + 0.036, 0.001)], seg=48)
    if nut:
        # one big centre nut, six flats
        lathe(bm, [(front + 0.03, 0.17), (front + 0.075, 0.17), (front + 0.085, 0.13), (front + 0.085, 0.001)], seg=6)
        return
    for i in range(bolts):
        a = i / bolts * math.tau + math.pi / bolts
        y, z = 0.185 * math.cos(a), 0.185 * math.sin(a)
        ring0, ring1 = [], []
        for k in range(10):
            b = k / 10 * math.tau
            ring0.append(bm.verts.new((front + 0.004, y + 0.026 * math.cos(b), z + 0.026 * math.sin(b))))
            ring1.append(bm.verts.new((front + 0.022, y + 0.026 * math.cos(b), z + 0.026 * math.sin(b))))
        for k in range(10):
            j = (k + 1) % 10
            bm.faces.new((ring0[k], ring0[j], ring1[j], ring1[k]))
        bm.faces.new(ring1)


def bounds(bm):
    """a hidden ring at the very back and edge: both meshes of a design fill the same box"""
    lathe(bm, [(-W, 0.985), (-W, 1.0), (-W + 0.004, 1.0)], seg=48)
    lathe(bm, [(W - 0.002, 0.9985), (W, 0.9985), (W, 1.0)], seg=48)


def ease(a, b):
    return lambda t: a + (b - a) * (t * t * (3 - 2 * t))


def furia(bm):
    """twin spokes, seven pairs, deep"""
    f = ease(0.12, 0.25)
    for i in range(7):
        a = i / 7 * math.tau
        spoke(bm, a, 0.26, 0.9, 0.12, 0.085, f, 0.08, side=0.05, side_to=0.13)
        spoke(bm, a, 0.26, 0.9, 0.12, 0.085, f, 0.08, side=-0.05, side_to=-0.13)
    hub(bm, 0.14, r=0.3)


def saetta(bm):
    """five Y spokes, the fork opens past the middle"""
    for i in range(5):
        a = i / 5 * math.tau
        spoke(bm, a, 0.26, 0.62, 0.3, 0.2, ease(0.17, 0.215), 0.09, steps=5)
        spoke(bm, a, 0.56, 0.9, 0.12, 0.13, ease(0.205, 0.255), 0.08, steps=5, side=0.045, side_to=0.25)
        spoke(bm, a, 0.56, 0.9, 0.12, 0.13, ease(0.205, 0.255), 0.08, steps=5, side=-0.045, side_to=-0.25)
    hub(bm, 0.18, r=0.3)


def corsa(bm):
    """ten straight forged spokes, a step cut along each"""
    f = ease(0.19, 0.255)
    for i in range(10):
        a = i / 10 * math.tau
        spoke(bm, a, 0.26, 0.9, 0.2, 0.135, f, 0.09)
        spoke(bm, a, 0.34, 0.86, 0.05, 0.035, ease(0.205, 0.268), 0.025)
    hub(bm, 0.2, r=0.3)


def centro(bm):
    """track wheel: six wide spokes, a small one between each, one centre nut"""
    f = ease(0.16, 0.255)
    for i in range(6):
        a = i / 6 * math.tau
        spoke(bm, a, 0.22, 0.9, 0.34, 0.22, f, 0.1)
        spoke(bm, a + math.pi / 6, 0.5, 0.9, 0.02, 0.13, ease(0.2, 0.255), 0.07, steps=4)
    hub(bm, 0.17, r=0.27, nut=True)


def turbine(bm):
    """aero: fourteen swept blades closing most of the wheel"""
    f = ease(0.2, 0.26)
    for i in range(14):
        a = i / 14 * math.tau
        spoke(bm, a, 0.25, 0.9, 0.13, 0.28, f, 0.06, steps=10, twist=0.62)
    hub(bm, 0.21, r=0.28)


def trio(bm):
    """six split spokes for the big cars"""
    f = ease(0.18, 0.255)
    for i in range(6):
        a = i / 6 * math.tau
        spoke(bm, a, 0.28, 0.9, 0.15, 0.13, f, 0.09, side=0.075, side_to=0.15)
        spoke(bm, a, 0.28, 0.9, 0.15, 0.13, f, 0.09, side=-0.075, side_to=-0.15)
    hub(bm, 0.19, r=0.31, bolts=6)


DESIGNS = {"Furia7": furia, "SaettaY5": saetta, "Corsa10": corsa, "Centro6": centro, "Turbine14": turbine, "Trio6": trio}
LIP = [(W, 1.0), (W, 0.972), (W - 0.02, 0.955)]
BARREL = [(W - 0.02, 0.955), (W - 0.05, 0.93), (0.02, 0.84), (-0.14, 0.82), (-0.24, 0.86), (-W, 0.93), (-W, 1.0)]


def mesh_of(name, fill, col):
    bm = bmesh.new()
    fill(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    m = o.modifiers.new("split", "EDGE_SPLIT")
    m.split_angle = math.radians(34)
    mat = bpy.data.materials.new(name + "_m")
    mat.use_nodes = True
    b = mat.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = col + (1,)
    b.inputs["Metallic"].default_value = 0.9
    b.inputs["Roughness"].default_value = 0.3
    me.materials.append(mat)
    return o


for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
objs = []
tris = {}
for k, (name, fn) in enumerate(DESIGNS.items()):
    def face(bm, fn=fn):
        fn(bm)
        bounds(bm)
        # the hidden spoke ring, in the barrel
        lathe(bm, [(0.25, 0.915), (0.25, 0.87), (0.18, 0.85)], seg=SEG)

    def lip(bm):
        lathe(bm, LIP, seg=SEG)
        lathe(bm, BARREL, seg=SEG)

    a = mesh_of("Rim_%s_Face" % name, face, (0.03, 0.03, 0.035))
    b = mesh_of("Rim_%s_Lip" % name, lip, (0.75, 0.75, 0.78))
    objs += [a, b]
    tris[name] = sum(len(p.vertices) - 2 for o in (a, b) for p in o.data.polygons)
print("TRIS", tris)


def tyre(bm):
    """one tyre for every car with no tyre of its own: radius 1, half width 0.21, the bead at 0.72. Three grooves"""
    side = [(0.17, 0.72), (0.195, 0.76), (0.208, 0.84), (0.205, 0.92), (0.185, 0.97), (0.165, 0.995)]
    tread = [(0.15, 1.0), (0.1, 1.0), (0.1, 0.985), (0.085, 0.985), (0.085, 1.0), (0.012, 1.0), (0.012, 0.985), (-0.012, 0.985), (-0.012, 1.0), (-0.085, 1.0), (-0.085, 0.985), (-0.1, 0.985), (-0.1, 1.0), (-0.15, 1.0)]
    lathe(bm, side + tread + [(-x, r) for x, r in reversed(side)], seg=64)


def disc(bm):
    """a brake disc with its hat: radius 1, half width 0.06"""
    lathe(bm, [(0.06, 0.001), (0.06, 0.36), (0.02, 0.4), (0.02, 0.98), (0.0, 1.0), (-0.02, 0.98), (-0.02, 0.4), (-0.06, 0.36), (-0.06, 0.001)], seg=48)


objs += [mesh_of("Rim_Tyre", tyre, (0.02, 0.02, 0.02)), mesh_of("Rim_Disc", disc, (0.45, 0.45, 0.47))]

# one render of each, on a tyre
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "CYCLES"
sc.render.resolution_x, sc.render.resolution_y = 520, 520
w = bpy.data.worlds.new("w")
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.82, 0.86, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.1
sc.world = w
cam = bpy.data.cameras.new("c")
cam.lens = 70
co = bpy.data.objects.new("c", cam)
sc.collection.objects.link(co)
sc.camera = co
co.location = (7.0, 2.4, 0.9)
d = -co.location.normalized() if hasattr(co.location, "normalized") else None
from mathutils import Vector

co.rotation_euler = (Vector((0, 0, 0)) - co.location).to_track_quat("-Z", "Y").to_euler()
sun = bpy.data.lights.new("s", "SUN")
sun.energy = 3
so = bpy.data.objects.new("s", sun)
sc.collection.objects.link(so)
so.rotation_euler = (0.8, 0.6, 0.2)
tb = bmesh.new()
lathe(tb, [(0.32, 1.0), (0.36, 1.08), (0.36, 1.34), (0.26, 1.42), (-0.26, 1.42), (-0.36, 1.34), (-0.36, 1.08), (-0.32, 1.0)], seg=64)
tm = bpy.data.meshes.new("tyre")
tb.to_mesh(tm)
tb.free()
to = bpy.data.objects.new("tyre", tm)
sc.collection.objects.link(to)
tmat = bpy.data.materials.new("t")
tmat.use_nodes = True
tmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.02, 0.02, 0.02, 1)
tmat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
tm.materials.append(tmat)
for name in DESIGNS:
    for o in objs:
        o.hide_render = not o.name.startswith("Rim_%s_" % name) and o.name != "Rim_Disc"
    sc.render.filepath = (out_dir + "/" + name + ".png").replace("\\", "/")
    bpy.ops.render.render(write_still=True)
print("RENDERS done")
for o in (co, so, to):
    bpy.data.objects.remove(o)
bpy.ops.object.select_all(action="DESELECT")
for o in objs:
    o.hide_render = False
    o.select_set(True)
bpy.ops.export_scene.fbx(filepath=out_fbx, use_selection=True, use_mesh_modifiers=True, axis_forward="-Z", axis_up="Y", global_scale=1.0, apply_scale_options="FBX_SCALE_NONE", mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
print("FBX", out_fbx)
