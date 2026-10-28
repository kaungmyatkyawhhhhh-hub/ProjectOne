"""Blender (5.x): GYM ARC thumbnail renders from the Studio exports. Transparent background (composited later on a
real in-game shot). args after --: export_dir out_dir mode   (mode: hero | before_after)"""
import math
import os
import sys

import bpy
from mathutils import Vector

D, OUT, MODE = sys.argv[sys.argv.index("--") + 1:][:3]
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def import_obj(path):
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=path, forward_axis="NEGATIVE_Z", up_axis="Y")
    return [o for o in bpy.data.objects if o not in before and o.type == "MESH"]


def image(path):
    return bpy.data.images.load(path, check_existing=True)


def principled(mat):
    mat.use_nodes = True
    for n in mat.node_tree.nodes:
        if n.type == "BSDF_PRINCIPLED":
            return n
    return None


def set_skin(objs, skin_png, gold):
    """the body's skin material, and the head / hands / feet onto the same skin texture"""
    skin = None
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if m and (m.name.startswith("GoldSkin") or m.name.startswith("Skin")):
                skin = m
    if skin is None:
        return
    bsdf = principled(skin)
    # (the game's SurfaceAppearance "Overlay": the map's colour over the part's colour, by the map's alpha)
    nt = skin.node_tree
    tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
    if tex and not gold:
        # (the natural skin map is near white: the game tints it with the skin colour = the part colour, Kd)
        base = tuple(bsdf.inputs["Base Color"].default_value[:3]) + (1,)
        mat_kd = skin.diffuse_color
        base = (mat_kd[0], mat_kd[1], mat_kd[2], 1)
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs[0].default_value = 1.0
        mix.inputs[6].default_value = base
        nt.links.new(tex.outputs["Color"], mix.inputs[7])
        nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        for link in list(nt.links):
            if link.to_socket == bsdf.inputs["Alpha"]:
                nt.links.remove(link)
        bsdf.inputs["Alpha"].default_value = 1.0
    if gold:
        bsdf.inputs["Metallic"].default_value = 0.55
        bsdf.inputs["Roughness"].default_value = 0.32
    else:
        bsdf.inputs["Roughness"].default_value = 0.5
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if m and any(m.name.startswith(k) for k in ("Head1", "Lefthand1", "Righthand1", "Leftfoot1", "Rightfoot1")):
                slot.material = skin


def tidy_materials(objs):
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if not m:
                continue
            b = principled(m)
            if not b:
                continue
            if "Fabric" in m.name:
                b.inputs["Roughness"].default_value = 0.85
            elif m.name.startswith("Acc"):
                b.inputs["Roughness"].default_value = 0.55
            # cut-out alpha (hair cards) renders cleanly
            try:
                m.surface_render_method = "DITHERED"
            except Exception:
                pass
            for o2 in o.modifiers:
                pass
    for o in objs:
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
    bpy.ops.object.shade_auto_smooth() if hasattr(bpy.ops.object, "shade_auto_smooth") else None


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def load(prefix, gold):
    objs = import_obj(os.path.join(D, prefix + ".obj")) + import_obj(os.path.join(D, "gymarc_headhair_" + prefix.split("_")[1] + ".obj"))
    tidy_materials(objs)
    set_skin(objs, os.path.join(D, prefix + "_skin.png"), gold)
    return objs


def move(objs, offset):
    for o in objs:
        o.location += offset
    bpy.context.view_layer.update()


def area(name, loc, target, power, color, size):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.color, data.size = power, color, size
    obj = bpy.data.objects.new(name, data)
    obj.location = loc
    obj.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(obj)
    return obj


def camera(loc, target, lens):
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = lens
    cam.location = loc
    cam.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.05, 0.06, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.35
scene.world = world
scene.render.engine = "BLENDER_EEVEE"
try:
    scene.eevee.use_raytracing = True
    scene.eevee.taa_render_samples = 96
    scene.eevee.use_shadows = True
except Exception:
    pass
scene.render.film_transparent = True
scene.render.resolution_x, scene.render.resolution_y = 1920, 1080
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Punchy"

WARM, GOLDC, BLUE = (1.0, 0.93, 0.84), (1.0, 0.72, 0.32), (0.45, 0.65, 1.0)

if MODE == "hero":
    objs = load("gymarc_hero", True)
    lo, hi = bounds(objs)
    c = (lo + hi) / 2
    h = hi.z - lo.z
    chest = Vector((c.x, c.y, lo.z + h * 0.62))
    mid = Vector((c.x, c.y, lo.z + h * 0.5))
    # a low hero angle from the front (the front faces -Y here), the whole body in frame, he stands right of centre
    # (vertical view at 42 mm: 27 degrees; the body fills ~88% of the height)
    dist = (h * 1.14 / 2) / math.tan(math.radians(13.5))
    cam = camera(mid + Vector((-h * 0.12, -dist, -h * 0.16)), mid + Vector((-h * 0.42, 0, h * 0.02)), 42)
    area("key", chest + Vector((-h * 1.0, -h * 1.3, h * 0.9)), chest, 2600, WARM, h * 0.9)
    area("fill", chest + Vector((h * 1.2, -h * 1.1, h * 0.1)), chest, 500, WARM, h * 1.2)
    area("rimL", chest + Vector((-h * 0.9, h * 0.9, h * 0.6)), chest, 3200, GOLDC, h * 0.5)
    area("rimR", chest + Vector((h * 0.9, h * 0.9, h * 0.4)), chest, 2600, BLUE, h * 0.5)
    area("top", chest + Vector((0, h * 0.1, h * 1.4)), chest, 900, WARM, h * 0.6)
    scene.render.filepath = os.path.join(OUT, "render_hero.png")
else:
    small = load("gymarc_small", False)
    big = load("gymarc_hero", True)
    lo_b, hi_b = bounds(big)
    lo_s, hi_s = bounds(small)
    hb = hi_b.z - lo_b.z
    # the small one to the left, both on the same floor
    # small's centre: left of the big one's left edge by a gap
    gap = hb * 0.12
    small_c = (lo_s.x + hi_s.x) / 2
    want = lo_b.x - gap - (hi_s.x - lo_s.x) / 2
    move(small, Vector((want - small_c, 0, lo_b.z - lo_s.z)))
    lo, hi = bounds(small + big)
    c = (lo + hi) / 2
    target = Vector((c.x, c.y, lo.z + hb * 0.5))
    dist = (hb * 1.18 / 2) / math.tan(math.radians(14.0))
    cam = camera(target + Vector((0, -dist, -hb * 0.08)), target + Vector((0, 0, hb * 0.02)), 40)
    area("key", target + Vector((-hb * 1.2, -hb * 1.6, hb * 1.0)), target, 3200, WARM, hb)
    area("fill", target + Vector((hb * 1.4, -hb * 1.3, hb * 0.2)), target, 700, WARM, hb * 1.2)
    area("rimL", target + Vector((-hb * 1.4, hb * 1.0, hb * 0.6)), target, 3200, BLUE, hb * 0.6)
    area("rimR", target + Vector((hb * 1.4, hb * 1.0, hb * 0.6)), target, 3600, GOLDC, hb * 0.6)
    scene.render.filepath = os.path.join(OUT, "render_before_after.png")

bpy.ops.render.render(write_still=True)
print("RENDERED", scene.render.filepath)
