"""SPEED ARC - M6 look pass: hero props for City Park and the Big Stadium, replacing their part builds.
Same modelling rule and helpers as hub_kit_v2.py (bevels, real cut-outs, natural variation, 3-tone
vertex shading). Sizes match the part builds in tools/build_park.luau / build_stadium.luau, and the
builders use these meshes when they are in ServerStorage.Meshes (bottom-centre pivot).

blender --background --factory-startup --python areas_kit.py -- <output folder> [names...]
Blender X = Roblox X, Blender Y = Roblox Z, Z up.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hub_kit_v2 as K  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = ARGS[0] if ARGS else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "areas")
ONLY = set(ARGS[1:])
os.makedirs(OUT, exist_ok=True)
P = K.P
H = K.hex_rgb
STONE = H("#E6E8EE")
STONE_D = H("#BFC4CE")
WATER = H("#4FC3FF")


def center_bottom(o):
    me = o.data
    mn = [min(v.co[i] for v in me.vertices) for i in range(3)]
    mx = [max(v.co[i] for v in me.vertices) for i in range(3)]
    cx, cy = (mn[0] + mx[0]) / 2, (mn[1] + mx[1]) / 2
    for v in me.vertices:
        v.co = Vector((v.co.x - cx, v.co.y - cy, v.co.z - mn[2]))
    me.update()
    return [round(mx[i] - mn[i], 3) for i in range(3)]


def export(o, name):
    K.select_only(o)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", mesh_smooth_type="OFF",
        colors_type="SRGB", add_leaf_bones=False,
    )
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
    tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
    print(f"[kit] {name}.fbx  {tris} tris")
    return tris


def fountain():
    """Tiered stone fountain: a carved basin with a lip, a fluted column, an upper bowl, a gold finial."""
    rnd = random.Random(71)
    parts = []
    basin = K.cyl("basin", 8.5, 1.6, (0, 0, 0.8), STONE, verts=32, bev=0.2, seg=3, cutters=[
        K.cutter_cyl(7.8, 1.6, (0, 0, 1.5), verts=32)])
    parts.append(basin)
    parts.append(K.cyl("lip", 8.75, 0.3, (0, 0, 1.62), STONE_D, verts=32, bev=0.08, cutters=[K.cutter_cyl(7.9, 1, (0, 0, 1.6), verts=32)]))
    parts.append(K.cyl("water", 7.8, 0.1, (0, 0, 1.3), WATER, verts=32, bev=0))
    # carved panels round the basin (shallow insets)
    for i in range(12):
        a = i / 12 * math.pi * 2
        parts.append(K.box("panel", (2.6, 0.12, 0.7), (math.cos(a) * 8.55, math.sin(a) * 8.55, 0.8), STONE_D, bev=0.04, seg=1, rot=(0, 0, a + math.pi / 2)))
    # fluted column: a core + 8 thin ribs
    parts.append(K.cyl("column", 1.4, 6, (0, 0, 4.4), STONE, verts=16, bev=0.1))
    for i in range(8):
        a = i / 8 * math.pi * 2
        parts.append(K.cyl("rib", 0.18, 5.6, (math.cos(a) * 1.42, math.sin(a) * 1.42, 4.4), STONE_D, verts=6, bev=0.04))
    parts.append(K.cyl("bowl", 4.2, 0.9, (0, 0, 7.6), STONE, verts=28, bev=0.15, r2=3.4, cutters=[K.cutter_cyl(3.8, 1, (0, 0, 8.1), verts=28)]))
    parts.append(K.cyl("bowlwater", 3.8, 0.08, (0, 0, 7.95), WATER, verts=28, bev=0))
    parts.append(K.cyl("goldband", 4.3, 0.22, (0, 0, 8.02), P["gold"], verts=28, bev=0.05, cutters=[K.cutter_cyl(3.85, 1, (0, 0, 8), verts=28)]))
    parts.append(K.cyl("top", 0.7, 2.4, (0, 0, 9.2), STONE, verts=12, bev=0.08))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=8, radius=0.8, location=(0, 0, 10.9))
    ball = K.active()
    ball.data.shade_smooth()
    parts.append(K.paint(ball, P["gold"]))
    # a few water-worn chips on the basin rim (natural variation)
    for _ in range(5):
        a = rnd.uniform(0, math.pi * 2)
        parts.append(K.box("chip", (0.5, 0.3, 0.2), (math.cos(a) * 8.5, math.sin(a) * 8.5, 1.72), STONE_D, bev=0.08, seg=1, rot=(0, 0, a)))
    o = K.join(parts, "Park_Fountain")
    size = center_bottom(o)
    K.shade(o, ao_dist=0.8, seed=71)
    return o, size


def food_cart():
    parts = []
    parts.append(K.box("body", (6, 3.4, 3), (0, 0, 2.5), H("#FF8FB1"), bev=0.2, seg=3, cutters=[
        K.cutter_box((5.2, 1, 1.4), (0, -1.9, 2.8))]))  # the serving hatch
    parts.append(K.box("hatchback", (5.1, 0.1, 1.3), (0, -1.25, 2.8), H("#F4F6FA"), bev=0.02, seg=1))
    parts.append(K.box("counter", (6.4, 3.8, 0.3), (0, 0, 4.15), H("#F4F6FA"), bev=0.08, seg=2))
    parts.append(K.box("skirt", (6.1, 3.5, 0.5), (0, 0, 1.15), H("#E9739A"), bev=0.08, seg=2))
    for s in (-1, 1):
        for y in (-1.8, 1.8):
            parts.append(K.cyl("wheel", 0.85, 0.35, (s * 2, y, 0.85), P["rubber"], verts=12, bev=0.06, rot=(math.radians(90), 0, 0)))
            parts.append(K.cyl("hub", 0.3, 0.4, (s * 2, y, 0.85), P["alu"], verts=8, bev=0.03, rot=(math.radians(90), 0, 0)))
    parts.append(K.tube("handle", [(3.1, -1, 3.2), (3.8, -1, 3.4), (3.8, 1, 3.4), (3.1, 1, 3.2)], 0.08, P["alu"], sides=8))
    parts.append(K.cyl("pole", 0.15, 5, (0, 0, 6.6), P["alu"], verts=8, bev=0.03))
    # a striped umbrella: 8 panels alternating colours
    for i in range(8):
        a0 = i / 8 * math.pi * 2
        col = P["gold"] if i % 2 == 0 else P["white"]
        pts = [(0, 0, 9.6), (math.cos(a0) * 4, math.sin(a0) * 4, 8.5), (math.cos(a0 + math.pi / 4) * 4, math.sin(a0 + math.pi / 4) * 4, 8.5)]
        import bmesh
        bm = bmesh.new()
        vs = [bm.verts.new(p) for p in pts]
        vs2 = [bm.verts.new((p[0], p[1], p[2] - 0.08)) for p in pts]
        bm.faces.new(vs)
        bm.faces.new(list(reversed(vs2)))
        for k in range(3):
            bm.faces.new((vs[k], vs[(k + 1) % 3], vs2[(k + 1) % 3], vs2[k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        parts.append(K.paint(K.to_object("panel", bm), col))
    o = K.join(parts, "Park_FoodCart")
    size = center_bottom(o)
    K.shade(o, ao_dist=0.5, seed=72)
    return o, size


def gazebo():
    parts = []
    parts.append(K.cyl("floor", 9, 0.8, (0, 0, 0.4), STONE, verts=6, bev=0.12, seg=2))
    parts.append(K.cyl("step", 9.8, 0.35, (0, 0, 0.18), STONE_D, verts=6, bev=0.08))
    for i in range(6):
        a = i / 6 * math.pi * 2 + math.pi / 6
        x, y = math.cos(a) * 7.6, math.sin(a) * 7.6
        parts.append(K.cyl("post", 0.35, 7.6, (x, y, 4.6), P["white"], verts=10, bev=0.06))
        parts.append(K.box("base", (0.9, 0.9, 0.5), (x, y, 1.05), STONE_D, bev=0.08, seg=1))
        # a railing between posts (not at the front opening)
        if i != 4:
            b = i + 1
            a2 = b / 6 * math.pi * 2 + math.pi / 6
            x2, y2 = math.cos(a2) * 7.6, math.sin(a2) * 7.6
            parts.append(K.tube("rail", [(x, y, 2.4), (x2, y2, 2.4)], 0.09, P["white"], sides=6))
    parts.append(K.cyl("eave", 9.6, 0.6, (0, 0, 8.7), P["deep"], verts=6, bev=0.1))
    parts.append(K.cyl("roof", 9.4, 2.4, (0, 0, 10.2), P["blue"], verts=6, bev=0.12, r2=1.2))
    parts.append(K.cyl("cap", 1.3, 0.5, (0, 0, 11.6), P["deep"], verts=6, bev=0.06))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.6, location=(0, 0, 12.3))
    fin = K.active()
    fin.data.shade_smooth()
    parts.append(K.paint(fin, P["gold"]))
    o = K.join(parts, "Park_Gazebo")
    size = center_bottom(o)
    K.shade(o, ao_dist=0.7, seed=73)
    return o, size


def flood_tower():
    """A lattice floodlight mast: tapered legs + cross braces, a service platform, the lamp head
    (lamps face -Y, tilted down; the game turns it to face the track)."""
    parts = []
    h = 44
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(K.tube("leg", [(sx * 1.6, sy * 1.6, 0), (sx * 0.7, sy * 0.7, h)], 0.16, P["steel"], sides=6))
    for k in range(9):
        z = 2 + k * 4.8
        w = 1.6 - (1.6 - 0.7) * (z / h)
        for (ax, ay, bx, by) in ((-1, -1, 1, -1), (1, -1, 1, 1), (1, 1, -1, 1), (-1, 1, -1, -1)):
            parts.append(K.tube("brace", [(ax * w, ay * w, z), (bx * w, by * w, z + 4.8)], 0.07, P["graphite"], sides=5))
    parts.append(K.box("deck", (4, 4, 0.3), (0, 0, h), P["graphite"], bev=0.06, seg=1))
    for s in (-1, 1):
        parts.append(K.box("rail", (4, 0.1, 0.8), (0, s * 2, h + 0.5), P["alu_d"], bev=0.02, seg=1))
    head = K.box("head", (10, 2, 5), (0, -1.6, h + 3.2), P["black"], bev=0.15, seg=2, rot=(math.radians(-20), 0, 0))
    parts.append(head)
    for i in range(4):
        for j in range(2):
            parts.append(K.cyl("lamp", 0.85, 0.3, (-3.6 + i * 2.4, -2.75 + j * 0.0, h + 2 + j * 2.4), H("#FFF4D6"), verts=12, bev=0.04,
                               rot=(math.radians(90 - 20), 0, 0)))
    o = K.join(parts, "Stadium_FloodTower")
    size = center_bottom(o)
    K.shade(o, ao_dist=0.8, seed=74)
    return o, size


BUILD = [("Park_Fountain", fountain), ("Park_FoodCart", food_cart), ("Park_Gazebo", gazebo), ("Stadium_FloodTower", flood_tower)]

if __name__ == "__main__":
    for name, fn in BUILD:
        if ONLY and name not in ONLY:
            continue
        K.reset()
        obj, size = fn()
        export(obj, name)
        print(f"[size] {name} {size}")
