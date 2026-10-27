"""SPEED ARC - M2 kit: shoe pairs (worn on the feet) and the shop shells (Shoe Shop, Trail Booth,
Coach Corner board). Same modelling rule and helpers as hub_kit_v2.py.

blender --background --factory-startup --python hub_kit_v3.py -- <output folder> [names...]
Design space: Blender X = Roblox X, Blender Y = Roblox Z, Z up. Shoes: toe towards -Y (Roblox -Z = forward).
Shop shells: front (open side) towards +X, like the part builds in tools/build_hub.luau.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hub_kit_v2 as K  # noqa: E402  (helpers: box, cyl, tube, rounded_slab, cut, join, shade ...)
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = ARGS[0] if ARGS else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "hub", "v3")
ONLY = set(ARGS[1:])
os.makedirs(OUT, exist_ok=True)
P = K.P
H = K.hex_rgb


def center_bottom(o):
    """Origin at the bottom centre of the bounding box (what the game expects)."""
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


# ---------------------------------------------------------------------------
# shoes (Config/Shoes colours: sole, upper, accent). Size ~1.05 x 1.5 x 0.72 studs (one foot)
# ---------------------------------------------------------------------------
SHOES = {
    "WornSneakers": dict(c=("#D9DEE6", "#8A93A3", "#5E6878"), sole=0.18, style="worn"),
    "CanvasRunners": dict(c=("#F4F6FA", "#1E7BFF", "#F4F6FA"), sole=0.17, style="canvas"),
    "TrackTrainers": dict(c=("#F4F6FA", "#171A22", "#4FC3FF"), sole=0.22, style="trainer"),
    "LightRacers": dict(c=("#FFC83D", "#F4F6FA", "#1E7BFF"), sole=0.15, style="racer"),
    "ParkPacers": dict(c=("#F4F6FA", "#3FA34D", "#FFC83D"), sole=0.28, style="trainer"),
    "SpikeShoes": dict(c=("#0B0D12", "#0E3A8A", "#FFC83D"), sole=0.12, style="spike"),
}


def profile_x(name, pts_yz, width, color, x0=0.0):
    """A shape drawn as a side profile (Y forward, Z up) and pushed out across X."""
    import bmesh
    bm = bmesh.new()
    a = [bm.verts.new((x0 - width / 2, y, z)) for y, z in pts_yz]
    b = [bm.verts.new((x0 + width / 2, y, z)) for y, z in pts_yz]
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    n = len(a)
    for i in range(n):
        bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return K.paint(K.to_object(name, bm), color)


def shoe(name):
    d = SHOES[name]
    sole_c, upper_c, acc_c = (H(x) for x in d["c"])
    sh = d["sole"]
    parts = []
    # sole: rounded slab with toe spring, a darker tread underneath
    sole = K.rounded_slab("sole", 1.02, 1.55, sh, 0.42, 0.0, sole_c, seg=3)
    for v in sole.data.vertices:
        if v.co.y < -0.35:
            v.co.z += (-0.35 - v.co.y) * 0.25
    parts.append(sole)
    parts.append(K.rounded_slab("tread", 0.98, 1.5, 0.05, 0.4, -0.02, P["rubber"], seg=3))
    # upper: a real side profile, toe -> laces rising -> collar dip -> heel counter
    prof = [(-0.74, sh + 0.06), (-0.74, sh + 0.16), (-0.6, sh + 0.3), (-0.3, sh + 0.42), (0.05, sh + 0.53),
            (0.28, sh + 0.62), (0.45, sh + 0.55), (0.62, sh + 0.66), (0.76, sh + 0.6), (0.79, sh + 0.3), (0.76, sh + 0.06)]
    up = profile_x("upper", prof, 0.9, upper_c)
    for v in up.data.vertices:  # rounder toe: narrow the front
        if v.co.y < -0.25:
            v.co.x *= 1 - min(0.22, (-0.25 - v.co.y) * 0.5)
    K.cut(up, K.cutter_cyl(0.25, 0.6, (0, 0.44, sh + 0.72), verts=12)())  # the collar opening
    K.bevel(up, 0.12, 2, 30)
    K.weighted(up)
    parts.append(up)
    # toe cap and heel counter follow the profile, a side stripe on each side
    cap = profile_x("toecap", [(-0.77, sh + 0.04), (-0.77, sh + 0.17), (-0.63, sh + 0.3), (-0.45, sh + 0.33), (-0.45, sh + 0.04)], 0.86, sole_c if d["style"] == "canvas" else upper_c * 0.8)
    for v in cap.data.vertices:
        v.co.x *= 1 - min(0.2, max(0, (-0.3 - v.co.y)) * 0.5)
    K.bevel(cap, 0.06, 2, 30)
    K.weighted(cap)
    parts.append(cap)
    heel = profile_x("heel", [(0.55, sh + 0.04), (0.62, sh + 0.6), (0.77, sh + 0.62), (0.8, sh + 0.3), (0.77, sh + 0.04)], 0.94, acc_c)
    K.bevel(heel, 0.05, 2, 30)
    K.weighted(heel)
    parts.append(heel)
    for sx in (-1, 1):
        st = profile_x("stripe", [(-0.35, sh + 0.08), (0.1, sh + 0.42), (0.3, sh + 0.42), (-0.1, sh + 0.08)], 0.04, acc_c, x0=sx * 0.455)
        parts.append(st)
    # laces across the rising top
    for i in range(3):
        y = -0.38 + i * 0.17
        z = sh + 0.38 + i * 0.05
        parts.append(K.box("lace", (0.42, 0.06, 0.05), (0, y, z), P["white"], bev=0.015, seg=1, rot=(math.radians(-20), 0, 0)))
    parts.append(K.box("tab", (0.18, 0.07, 0.24), (0, 0.74, sh + 0.66), acc_c, bev=0.03, seg=1))
    if d["style"] == "spike":
        for (x, y) in ((-0.25, -0.5), (0.25, -0.5), (-0.28, -0.15), (0.28, -0.15), (0, -0.62)):
            parts.append(K.cyl("spike", 0.05, 0.1, (x, y, -0.05), P["alu"], verts=6, r2=0.01, bev=0))
    if d["style"] == "racer":
        parts.append(profile_x("wing", [(0.1, sh + 0.25), (0.45, sh + 0.55), (0.6, sh + 0.5), (0.35, sh + 0.22)], 0.04, P["gold"], x0=0.47))
    o = K.join(parts, "Shoe_" + name)
    size = center_bottom(o)
    K.shade(o, ao_dist=0.25, highlight=0.3, wear=0.12 if d["style"] == "worn" else 0.05, seed=len(name))
    return o, size


# ---------------------------------------------------------------------------
# shop shells
# ---------------------------------------------------------------------------
def shoe_shop_shell():
    parts = []
    # back wall with a recessed display panel and three shelves
    back = K.box("back", (1.0, 24, 12), (-7.5, 0, 6), P["carbon"], bev=0.12, seg=2,
                 cutters=[K.cutter_box((0.6, 21, 7), (-6.95, 0, 5.2))])
    parts.append(back)
    parts.append(K.box("panel", (0.3, 21, 7), (-7.05, 0, 5.2), P["deep"], bev=0.04, seg=1))
    for i in range(3):
        parts.append(K.box("shelf", (1.2, 20, 0.22), (-6.4, 0, 3 + i * 2.2), P["alu"], bev=0.06, seg=2))
    for s in (-1, 1):
        # side walls with an inset panel line and a blue band, chamfered front edge
        parts.append(K.box("side", (16, 1, 12), (0, s * 11.5, 6), P["carbon"], bev=0.12, seg=2,
                           cutters=[K.cutter_box((14, 0.4, 0.12), (0, s * 12.0, 3.0))]))
        parts.append(K.box("band", (16.1, 1.05, 0.5), (0, s * 11.5, 9.5), P["blue"], bev=0.05, seg=1))
        parts.append(K.box("pillar", (1.4, 1.4, 12.4), (7.6, s * 11.5, 6.2), P["black"], bev=0.18, seg=2))
        parts.append(K.box("pillarcap", (1.7, 1.7, 0.4), (7.6, s * 11.5, 0.2), P["graphite"], bev=0.08, seg=1))
    parts.append(K.box("roof", (17, 25, 1.0), (0, 0, 12.5), P["black"], bev=0.15, seg=2))
    parts.append(K.box("roofgold", (17.2, 25.2, 0.35), (0, 0, 12.05), P["gold"], bev=0.06, seg=1))
    # scalloped awning: 8 rounded stripes sloping out over the front
    for i in range(8):
        y = -10.5 + i * 3
        st = K.box("awning", (4.0, 2.9, 0.25), (10.0, y, 10.4), P["blue"] if i % 2 == 0 else P["white"], bev=0.08, seg=2, rot=(0, math.radians(18), 0))
        parts.append(st)
        parts.append(K.cyl("scallop", 0.72, 0.25, (11.85, y, 9.75), P["blue"] if i % 2 == 0 else P["white"], verts=10, rot=(0, math.radians(90 + 18), 0), bev=0.04, seg=1))
    o = K.join(parts, "ShoeShop_Shell")
    size = center_bottom(o)
    K.shade(o, ao_dist=1.6, cavity=0.45, seed=21)
    return o, size


def trail_booth_shell():
    parts = []
    parts.append(K.box("back", (0.8, 14, 9), (-4.6, 0, 4.5), P["black"], bev=0.12, seg=2,
                       cutters=[K.cutter_box((0.5, 10.4, 5.9), (-4.25, 0, 5.0))]))
    parts.append(K.box("counter", (2.2, 12, 3.4), (3.6, 0, 1.7 + 0.5), P["carbon"], bev=0.12, seg=2,
                       cutters=[K.cutter_box((0.3, 11, 0.12), (4.7, 0, 2.6)), K.cutter_box((0.3, 11, 0.12), (4.7, 0, 1.4))]))
    parts.append(K.box("countertop", (2.6, 12.4, 0.3), (3.6, 0, 4.05), P["gold"], bev=0.08, seg=2))
    for s in (-1, 1):
        parts.append(K.box("post", (0.8, 0.8, 10), (4.4, s * 6.6, 5), P["black"], bev=0.12, seg=2))
        parts.append(K.cyl("ball", 0.55, 0.5, (4.4, s * 6.6, 10.3), P["gold"], verts=10, bev=0.12, seg=2))
    # striped carnival canopy with a scalloped edge
    for i in range(7):
        y = -6 + i * 2
        c = P["gold"] if i % 2 == 0 else P["black"]
        parts.append(K.box("canopy", (10, 1.9, 0.3), (0, y, 10.8), c, bev=0.08, seg=1, rot=(0, math.radians(-12), 0)))
        parts.append(K.cyl("scallop", 0.5, 0.3, (4.95, y, 9.75), c, verts=10, rot=(0, math.radians(90 - 12), 0), bev=0.04, seg=1))
    o = K.join(parts, "TrailBooth_Shell")
    size = center_bottom(o)
    K.shade(o, ao_dist=1.2, seed=22)
    return o, size


def coach_board():
    parts = []
    # whiteboard on a wheeled aluminium stand, with a marker tray
    parts.append(K.box("frame", (0.35, 9.4, 5.4), (0, 0, 5.2), P["alu"], bev=0.1, seg=2,
                       cutters=[K.cutter_box((0.6, 8.9, 4.9), (0.25, 0, 5.2))]))
    parts.append(K.box("board", (0.12, 8.95, 4.95), (0.05, 0, 5.2), P["white"], bev=0))
    parts.append(K.box("tray", (0.5, 8.6, 0.12), (0.3, 0, 2.45), P["alu_d"], bev=0.03, seg=1))
    for i, c in enumerate(("blue", "gold", "black")):
        parts.append(K.tube("marker", [(0.35, -1 + i * 0.6, 2.56), (0.35, -0.55 + i * 0.6, 2.56)], 0.05, P[c], sides=6))
    for s in (-1, 1):
        parts.append(K.tube("leg", [(0, s * 4.3, 0.4), (0, s * 4.3, 7.6)], 0.14, P["alu"], sides=8))
        parts.append(K.tube("foot", [(-0.9, s * 4.3, 0.3), (0.9, s * 4.3, 0.3)], 0.12, P["alu_d"], sides=8))
        for fx in (-0.85, 0.85):
            parts.append(K.cyl("wheel", 0.18, 0.12, (fx, s * 4.3, 0.18), P["rubber"], verts=8, rot=(math.radians(90), 0, 0), bev=0))
    o = K.join(parts, "CoachBoard")
    size = center_bottom(o)
    K.shade(o, ao_dist=0.6, seed=23)
    return o, size


BUILD = [("Shoe_" + n, (lambda n=n: shoe(n))) for n in SHOES] + [
    ("ShoeShop_Shell", shoe_shop_shell),
    ("TrailBooth_Shell", trail_booth_shell),
    ("CoachBoard", coach_board),
]

if __name__ == "__main__":
    for name, fn in BUILD:
        if ONLY and name not in ONLY:
            continue
        K.reset()
        obj, size = fn()
        tris = export(obj, name)
        print(f"[size] {name} {size}")
