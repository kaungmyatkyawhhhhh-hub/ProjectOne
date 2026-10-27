"""SPEED ARC - Hub kit (stylized low-poly, bevelled, vertex colours with baked soft shading).

Run headless:
    blender --background --factory-startup --python hub_kit.py -- <output folder>
Writes one .fbx per prop (+ a .blend with everything) into the output folder.
1 Blender unit = 1 Roblox stud. In Studio: Avatar/3D Importer -> keep "Scale unit: Stud",
"Import only as model", vertex colours on. Palette = SPEED ARC Config/Palette.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "hub")
os.makedirs(OUT, exist_ok=True)


def hex_rgb(h):
    h = h.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    # colour attributes are linear; convert so Roblox shows the palette colour
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb) + (1.0,)


P = {
    "black": hex_rgb("#0B0D12"), "carbon": hex_rgb("#171A22"), "graphite": hex_rgb("#2A2F3A"),
    "blue": hex_rgb("#1E7BFF"), "bright": hex_rgb("#4FC3FF"), "deep": hex_rgb("#0E3A8A"),
    "gold": hex_rgb("#FFC83D"), "deepgold": hex_rgb("#E09A12"), "white": hex_rgb("#F4F6FA"),
    "alu": hex_rgb("#C9D1DD"), "concrete": hex_rgb("#B8BFCB"), "wood": hex_rgb("#B9824F"),
    "leaf": hex_rgb("#4E9A47"), "leaf_l": hex_rgb("#6DBA55"), "leaf_d": hex_rgb("#3D7F3D"),
    "trunk": hex_rgb("#7A5236"), "cone": hex_rgb("#FF8A2B"), "track": hex_rgb("#1C57C8"),
    "skin1": hex_rgb("#F2CDA8"), "skin2": hex_rgb("#C68B62"), "skin3": hex_rgb("#8D5A3B"),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 64
    scene.cycles.device = "CPU"


def paint(obj, color):
    """Fill a colour attribute with one flat colour."""
    me = obj.data
    attr = me.color_attributes.get("Col") or me.color_attributes.new("Col", "BYTE_COLOR", "CORNER")
    for d in attr.data:
        d.color = color
    me.color_attributes.active_color = attr
    return obj


def bevel(obj, width=0.08, segments=2):
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.harden_normals = False
    return obj


def box(name, size, loc, color, bev=0.08, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bev:
        bevel(o, bev)
    return paint(o, color)


def cyl(name, r, h, loc, color, verts=10, bev=0.05, rot=(0, 0, 0), r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    if bev:
        bevel(o, bev)
    return paint(o, color)


def blob(name, r, loc, color, subdiv=1, squash=1.0, jitter=0.12, seed=0):
    """Low-poly faceted ball (tree crowns, heads)."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = (1, 1, squash)
    bpy.ops.object.transform_apply(scale=True)
    import random
    rnd = random.Random(seed)
    for v in o.data.vertices:
        v.co += v.co.normalized() * rnd.uniform(-jitter, jitter) * r
    for p in o.data.polygons:
        p.use_smooth = False
    return paint(o, color)


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        for m in o.modifiers:
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.modifier_apply(modifier=m.name)
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    # put the origin at the bottom centre so it sits on the ground in Studio
    bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
    minz = min(v.z for v in bb)
    cx = sum(v.x for v in bb) / 8
    cy = sum(v.y for v in bb) / 8
    bpy.context.scene.cursor.location = (cx, cy, minz)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    o.location = (0, 0, 0)
    return o


def bake_ao(obj, strength=0.55):
    """Bake ambient occlusion into a colour attribute and multiply it into "Col" (soft baked shading)."""
    me = obj.data
    base = [tuple(d.color) for d in me.color_attributes["Col"].data]
    ao = me.color_attributes.new("AO", "BYTE_COLOR", "CORNER")
    me.color_attributes.active_color = ao
    # a simple material so Cycles can bake
    mat = bpy.data.materials.new(obj.name + "_mat")
    mat.use_nodes = True
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    scene = bpy.context.scene
    scene.cycles.bake_type = "AO"
    scene.render.bake.target = "VERTEX_COLORS"
    scene.render.bake.margin = 0
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.bake(type="AO", target="VERTEX_COLORS")
    col = me.color_attributes["Col"]
    for i, d in enumerate(col.data):
        a = ao.data[i].color[0]
        k = 1 - strength + strength * a
        b = base[i]
        d.color = (b[0] * k, b[1] * k, b[2] * k, 1.0)
    me.color_attributes.remove(me.color_attributes["AO"])
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = 0
    obj.data.materials.clear()


def export(obj, name):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    path = os.path.join(OUT, name + ".fbx")
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", colors_type="SRGB", add_leaf_bones=False,
    )
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print(f"[kit] {name}.fbx  {tris} triangles")
    return tris


# ---------------------------------------------------------------------------
# props (sizes in studs; Z is up in Blender, Y up after export)
# ---------------------------------------------------------------------------
def tree_round(seed):
    parts = [cyl("trunk", 0.7, 6, (0, 0, 3), P["trunk"], verts=7, r2=0.5, bev=0)]
    cols = [P["leaf"], P["leaf_l"], P["leaf_d"]]
    parts.append(blob("crown", 4.2, (0, 0, 8.6), cols[seed % 3], subdiv=2, squash=0.9, seed=seed))
    parts.append(blob("crown2", 2.9, (2.1, 1.0, 10.6), cols[(seed + 1) % 3], subdiv=1, seed=seed + 1))
    parts.append(blob("crown3", 2.6, (-2.0, -1.5, 7.6), cols[(seed + 2) % 3], subdiv=1, seed=seed + 2))
    return join(parts, f"Tree_Round_{seed}")


def tree_pine(seed):
    parts = [cyl("trunk", 0.55, 3, (0, 0, 1.5), P["trunk"], verts=7, bev=0)]
    for i, (r, z) in enumerate([(3.6, 4.2), (2.8, 6.6), (1.9, 8.8)]):
        parts.append(cyl("tier", r, 3.2, (0, 0, z), P["leaf_d"] if i % 2 == 0 else P["leaf"], verts=8, r2=0.2, bev=0.06))
    return join(parts, f"Tree_Pine_{seed}")


def bleacher_section():
    parts = []
    rows, depth, width = 6, 3.0, 20.0
    for k in range(1, rows + 1):
        h = 1 + 1.3 * k
        y = -1.5 - depth * (k - 1)
        parts.append(box("step", (width, depth, h), (0, y, h / 2), P["graphite"] if k % 2 == 0 else P["carbon"], bev=0.06))
        parts.append(box("seat", (width - 0.6, 1.3, 0.5), (0, y + 0.6, h + 0.25), P["alu"], bev=0.12))
        parts.append(box("edge", (width - 0.6, 0.2, 0.15), (0, y + 1.25, h + 0.42), P["blue"], bev=0))
    for x in (-width / 2 + 0.3, width / 2 - 0.3):
        parts.append(box("post", (0.3, 0.3, 3.2), (x, 0.6, 1.6), P["alu"], bev=0.05))
    parts.append(box("rail", (width, 0.3, 0.3), (0, 0.6, 3.2), P["alu"], bev=0.08))
    return join(parts, "Bleacher_Section")


def crowd_fan(i):
    skin = [P["skin1"], P["skin2"], P["skin3"]][i % 3]
    shirt = [P["blue"], P["gold"], P["white"]][i % 3]
    parts = [
        box("body", (1.7, 1.1, 2.1), (0, 0, 1.05), shirt, bev=0.25),
        blob("head", 0.68, (0, 0, 2.75), skin, subdiv=2, jitter=0.03, seed=i),
    ]
    if i % 3 == 1:
        parts.append(box("arm", (0.45, 0.45, 1.6), (1.0, 0, 2.6), shirt, bev=0.15))
        parts.append(box("flag", (0.9, 0.08, 0.6), (1.5, 0, 3.4), P["blue"], bev=0))
    return join(parts, f"Crowd_Fan_{i}")


def start_arch():
    parts = []
    span = 30.0
    for x in (-span / 2, span / 2):
        parts.append(box("leg", (2.4, 2.4, 18), (x, 0, 9), P["black"], bev=0.2))
        parts.append(box("foot", (4, 4, 1), (x, 0, 0.5), P["graphite"], bev=0.15))
        for z in (6, 12):
            parts.append(box("trim", (2.6, 2.6, 0.5), (x, 0, z), P["bright"], bev=0.05))
        # truss braces
        for z in range(2, 17, 4):
            parts.append(box("brace", (0.25, 2.5, 0.25), (x, 0, z), P["graphite"], bev=0, rot=(math.radians(45), 0, 0)))
    parts.append(box("beam", (span + 2.4, 3, 4), (0, 0, 19.5), P["black"], bev=0.2))
    parts.append(box("beamgold", (span + 2.6, 3.2, 1), (0, 0, 21.7), P["gold"], bev=0.15))
    parts.append(box("screen", (span - 6, 3.25, 3.2), (0, 0, 19.5), P["carbon"], bev=0.05))
    return join(parts, "Start_Arch")


def treadmill():
    parts = [
        box("deck", (3.6, 7, 0.8), (0, 0, 0.4), P["graphite"], bev=0.15),
        box("belt", (2.8, 6.2, 0.1), (0, 0, 0.82), P["black"], bev=0),
        box("stripeL", (0.25, 6.2, 0.12), (-1.1, 0, 0.83), P["blue"], bev=0),
        box("stripeR", (0.25, 6.2, 0.12), (1.1, 0, 0.83), P["blue"], bev=0),
        box("console", (3.4, 0.6, 1.4), (0, -3.3, 4.6), P["carbon"], bev=0.15),
        box("screen", (2.2, 0.62, 0.7), (0, -3.32, 4.7), P["bright"], bev=0.05),
    ]
    for s in (-1, 1):
        parts.append(box("upright", (0.35, 0.35, 4.0), (s * 1.6, -3.2, 2.6), P["alu"], bev=0.08))
        parts.append(box("rail", (0.3, 3.2, 0.3), (s * 1.6, -1.8, 4.2), P["alu"], bev=0.1))
    return join(parts, "Treadmill")


def bench():
    parts = [
        box("seat", (6, 1.6, 0.4), (0, 0, 1.6), P["wood"], bev=0.1),
        box("back", (6, 0.3, 1.2), (0, 0.75, 2.6), P["wood"], bev=0.1, rot=(math.radians(-10), 0, 0)),
    ]
    for s in (-1, 1):
        parts.append(box("leg", (0.3, 1.6, 1.6), (s * 2.6, 0, 0.8), P["black"], bev=0.06))
    return join(parts, "Bench")


def cone():
    parts = [
        cyl("base", 0.9, 0.2, (0, 0, 0.1), P["black"], verts=8, bev=0.04),
        cyl("cone", 0.6, 1.6, (0, 0, 1.0), P["cone"], verts=10, r2=0.12, bev=0),
        cyl("band", 0.47, 0.3, (0, 0, 1.0), P["white"], verts=10, r2=0.38, bev=0),
    ]
    return join(parts, "Cone")


def lamp_post():
    parts = [
        cyl("pole", 0.3, 9, (0, 0, 4.5), P["black"], verts=8, bev=0.04),
        cyl("foot", 0.6, 0.5, (0, 0, 0.25), P["graphite"], verts=8, bev=0.05),
        box("arm", (0.3, 2, 0.3), (0, -0.8, 9), P["black"], bev=0.05),
        box("head", (1.2, 1.6, 0.5), (0, -1.6, 8.8), P["black"], bev=0.12),
        box("glow", (1.0, 1.4, 0.15), (0, -1.6, 8.5), hex_rgb("#FFE3A0"), bev=0),
    ]
    return join(parts, "Lamp_Post")


def starting_block():
    parts = [
        box("rail", (0.3, 2.2, 0.25), (0, 0, 0.12), P["alu"], bev=0.05),
        box("padL", (0.9, 0.5, 0.7), (-0.5, -0.4, 0.45), P["black"], bev=0.08, rot=(math.radians(-35), 0, 0)),
        box("padR", (0.9, 0.5, 0.7), (0.5, 0.5, 0.45), P["black"], bev=0.08, rot=(math.radians(-35), 0, 0)),
    ]
    return join(parts, "Starting_Block")


BUILD = [
    ("Tree_Round_A", lambda: tree_round(1)),
    ("Tree_Round_B", lambda: tree_round(2)),
    ("Tree_Pine", lambda: tree_pine(3)),
    ("Bleacher_Section", bleacher_section),
    ("Crowd_Fan_A", lambda: crowd_fan(0)),
    ("Crowd_Fan_B", lambda: crowd_fan(1)),
    ("Crowd_Fan_C", lambda: crowd_fan(2)),
    ("Start_Arch", start_arch),
    ("Treadmill", treadmill),
    ("Bench", bench),
    ("Cone", cone),
    ("Lamp_Post", lamp_post),
    ("Starting_Block", starting_block),
]

if __name__ == "__main__":
    report = []
    for name, fn in BUILD:
        reset()
        obj = fn()
        bake_ao(obj)
        tris = export(obj, name)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
        report.append(f"{name}: {tris} tris")
    print("[kit] done ->", OUT)
    print("\n".join(report))
