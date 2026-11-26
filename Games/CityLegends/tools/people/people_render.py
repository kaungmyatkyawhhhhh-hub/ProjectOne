"""people_render.py: check renders for people_mesh.py (called with `render`): a line-up of dressed people next to the
old 8-block figure, front 3/4 and a street-level close-up, written to imports/people/render_*.png."""
import math
import os
import random

import bpy

SKIN = [(226, 186, 148), (210, 166, 126), (192, 146, 106), (170, 124, 86), (146, 102, 68)]
LOOKS = [  # (top, low, hair, scale, atlas, arms swing, yaw deg)
    ((240, 240, 236), (44, 74, 56), "HairShort", 1.0, "atlas_a", 0.3, 10),
    ((232, 168, 180), (170, 40, 100), "HairBun", 0.95, "atlas_b", -0.25, -15),
    ((122, 36, 34), (122, 36, 34), None, 0.98, "atlas_a", 0.0, 25),
    ((40, 50, 80), (36, 46, 76), "HairShort", 1.02, "atlas_a", 0.2, -5),
    ((240, 222, 150), (30, 110, 120), "HairBun", 0.93, "atlas_b", 0.0, 0),
    ((244, 244, 240), (34, 110, 60), "HairShort", 0.72, "atlas_a", 0.3, 20),
]


def lin(c):
    return tuple(((v / 255) ** 2.2) for v in c) + (1.0,)


def mat(name, rgb, atlas=None, out=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.8
    if atlas:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.join(out, atlas + ".png"), check_existing=True)
        mix = nt.nodes.new("ShaderNodeMixRGB")
        mix.inputs[1].default_value = lin(rgb)
        nt.links.new(tex.outputs["Color"], mix.inputs[2])
        nt.links.new(tex.outputs["Alpha"], mix.inputs[0])
        nt.links.new(mix.outputs[0], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = lin(rgb)
    return m


def to_b(x, y, z):
    return (x, -z, y)


def place(src, name, m, at, yaw, s, local, pivot=None, swing=0.0):
    ob = bpy.data.objects.new(name, src.data)
    bpy.context.collection.objects.link(ob)
    ob.data = src.data.copy()
    ob.data.materials.clear()
    ob.data.materials.append(m)
    ob.scale = (s, s, s)
    # figure-space centre -> world: rotate about the figure's feet (Roblox yaw about +y = Blender z)
    from mathutils import Matrix, Vector
    R = Matrix.Rotation(math.radians(yaw), 4, "Z")
    c = Vector(to_b(*local)) * s
    rot = Matrix.Identity(4)
    if pivot is not None and swing:
        p = Vector(to_b(*pivot)) * s
        rot = Matrix.Translation(p) @ Matrix.Rotation(swing, 4, "X") @ Matrix.Translation(-p)
    ob.matrix_world = Matrix.Translation(Vector(at)) @ R @ rot @ Matrix.Translation(c) @ Matrix.Rotation(math.pi, 4, "Z") @ Matrix.Diagonal((s, s, s, 1))  # (the export is pre-turned)
    return ob


def render(info, out):
    P = info["parts"]
    src = {n: bpy.data.objects[n] for n in P}
    for o in src.values():
        o.hide_render = True
    J = info["joints"]
    random.seed(3)
    for i, (top, low, hair, s, atlas, sw, yaw) in enumerate(LOOKS):
        at = (i * 2.2 - 1.0, 0, 0)
        skin = SKIN[i % len(SKIN)]
        ms = mat("skin%d" % i, skin)
        mface = mat("face%d" % i, skin, atlas, out)
        mt, ml = mat("top%d" % i, top), mat("low%d" % i, low)
        mh = mat("hair%d" % i, (20, 18, 16))
        place(src["Torso"], "T%d" % i, mt, at, yaw, s, P["Torso"]["centre"])
        place(src["Head"], "H%d" % i, mface, at, yaw, s, P["Head"]["centre"])
        if hair:
            place(src[hair], "R%d" % i, mh, at, yaw, s, P[hair]["centre"])
        place(src["Longyi"], "L%d" % i, ml, at, yaw, s, P["Longyi"]["centre"])
        shL = (-J["shoulder"][0], J["shoulder"][1], 0)
        shR = (J["shoulder"][0], J["shoulder"][1], 0)
        place(src["ArmL"], "AL%d" % i, mt if (hair is None) else ms, at, yaw, s, P["ArmL"]["centre"], shL, -sw)
        place(src["ArmR"], "AR%d" % i, ms, at, yaw, s, P["ArmR"]["centre"], shR, sw)
        fc = P["Foot"]["centre"]
        for k, sx in enumerate((-1, 1)):
            st = 0.4 * sw * (1 if sx < 0 else -1)
            place(src["Foot"], "F%d%d" % (i, k), mface, at, yaw, s, (sx * 0.17, fc[1], fc[2] - 0.1 + st))
    # the old block figure, for size
    old = [((2, 2, 1), (0, 3, 0)), ((1.2, 1, 1), (0, 4.5, 0)), ((2, 1.75, 1.1), (0, 1.225, 0)), ((1, 2, 1), (-1.5, 3, 0)),
           ((1, 2, 1), (1.5, 3, 0)), ((0.8, 0.35, 1), (-0.5, 0.175, -0.1)), ((0.8, 0.35, 1), (0.5, 0.175, -0.1))]
    mo = mat("old", (200, 200, 200))
    for k, (sz, c) in enumerate(old):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(c[0] - 3.6, -c[2], c[1]))
        o = bpy.context.active_object
        o.scale = (sz[0], sz[2], sz[1])
        o.data.materials.append(mo)
    # ground, light, camera
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    bpy.context.active_object.data.materials.append(mat("ground", (150, 146, 138)))
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 3.5
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(50), 0, math.radians(30))
    bpy.context.collection.objects.link(so)
    w = bpy.context.scene.world or bpy.data.worlds.new("w")
    bpy.context.scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.62, 0.75, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 32
    sc.cycles.device = "CPU"
    sc.render.resolution_x, sc.render.resolution_y = 1400, 700
    cam = bpy.data.cameras.new("cam")
    cam.lens = 50
    co = bpy.data.objects.new("cam", cam)
    bpy.context.collection.objects.link(co)
    sc.camera = co
    from mathutils import Vector
    for name, pos, look in (("lineup", (2.0, 15.0, 3.4), (2.4, 0, 2.6)), ("close", (2.6, 4.2, 4.7), (2.2, 0, 4.5)), ("side", (12.0, 6.0, 3.0), (2.6, 0, 2.6))):
        co.location = pos
        d = Vector(look) - Vector(pos)
        co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(out, "render_%s.png" % name)
        bpy.ops.render.render(write_still=True)
        print("RENDER", sc.render.filepath)
