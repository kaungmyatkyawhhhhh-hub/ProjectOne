"""SPEED ARC - M5 Locker kit: kit pieces (tops + bottoms) and headwear, worn over the player's avatar.
Same modelling rule and helpers as hub_kit_v2.py (bevels, real cut-outs, natural variation, 3-tone
vertex shading). These meshes are painted in LIGHT GREY tones on purpose: the game tints each one with
MeshPart.Color (vertex colour x part colour), so one mesh serves every colourway in Config/Cosmetics.

blender --background --factory-startup --python locker_kit.py -- <output folder> [names...]
Design space: Blender X = Roblox X, Blender Y = Roblox Z (front = -Y), Z up. The game sets each
mesh's Size to fit the body part (CosmeticsService FIT table), so only the proportions matter here:
tops are built around an R15 UpperTorso (2 x 1.6 x 1), bottoms around the hips, headwear around a
1.2-stud head.
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
OUT = ARGS[0] if ARGS else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "locker")
ONLY = set(ARGS[1:])
os.makedirs(OUT, exist_ok=True)
H = K.hex_rgb
CLOTH = H("#E9ECF1")  # tinted in game
SEAM = H("#C9CED8")  # stitched bands / hems a touch darker
TRIM = H("#FFFFFF")  # zips, logo plates stay bright
LENS = H("#5A6070")


def export(o, name):
    K.select_only(o)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", mesh_smooth_type="OFF",
        colors_type="SRGB", add_leaf_bones=False,
    )
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
    tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
    me = o.data
    size = [round(max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices), 3) for i in range(3)]
    print(f"[kit] {name}.fbx  {tris} tris  size {size}")
    return tris


def shell(name, w, d, h, wall, z0, color, bev=0.08):
    """A hollow garment body: rounded box with the inside cut out (open top and bottom)."""
    outer = K.box(name, (w, d, h), (0, 0, z0 + h / 2), color, bev=bev, seg=2, cutters=[
        K.cutter_box((w - wall * 2, d - wall * 2, h + 1), (0, 0, z0 + h / 2)),
    ])
    return outer


# ---------------------------------------------------------------------------
# tops (UpperTorso 2 x 1.6 x 1; the game fits Size to the torso)
# ---------------------------------------------------------------------------
def singlet():
    w, d, h = 2.14, 1.22, 1.62
    body = K.box("singlet", (w, d, h), (0, 0, h / 2), CLOTH, bev=0.1, seg=3, cutters=[
        K.cutter_box((w - 0.12, d - 0.12, h + 1), (0, 0, h / 2)),
        # deep arm holes either side
        K.cutter_cyl(0.52, 0.5, (w / 2, 0, h - 0.2), rot=(0, math.radians(90), 0), verts=20),
        K.cutter_cyl(0.52, 0.5, (-w / 2, 0, h - 0.2), rot=(0, math.radians(90), 0), verts=20),
        # scooped neck, front deeper than back
        K.cutter_cyl(0.5, 0.6, (0, -d / 2, h + 0.12), rot=(math.radians(90), 0, 0), verts=20),
        K.cutter_cyl(0.42, 0.6, (0, d / 2, h + 0.2), rot=(math.radians(90), 0, 0), verts=20),
    ])
    parts = [body]
    # hem band + a race stripe across the chest
    parts.append(shell("hem", w + 0.03, d + 0.03, 0.14, 0.07, 0.0, SEAM, bev=0.04))
    parts.append(K.box("stripe", (w + 0.02, 0.04, 0.12), (0, -d / 2 - 0.0, 0.78), SEAM, bev=0.02, seg=1))
    o = K.join(parts, "Kit_Singlet")
    K.shade(o, ao_dist=0.25, seed=41)
    return o


def tee():
    w, d, h = 2.1, 1.24, 1.64
    body = K.box("tee", (w, d, h), (0, 0, h / 2), CLOTH, bev=0.1, seg=2, cutters=[
        K.cutter_box((w - 0.12, d - 0.12, h + 1), (0, 0, h / 2)),
        K.cutter_cyl(0.36, 0.7, (0, -d / 2, h + 0.06), rot=(math.radians(90), 0, 0), verts=16),
        K.cutter_cyl(0.32, 0.7, (0, d / 2, h + 0.12), rot=(math.radians(90), 0, 0), verts=16),
    ])
    parts = [body]
    # shoulder caps instead of sleeves (a rigid sleeve would stick out while the arms swing)
    for sx in (-1, 1):
        parts.append(K.box("cap", (0.5, d + 0.06, 0.2), (sx * (w / 2 - 0.2), 0, h - 0.06), SEAM, bev=0.08, seg=2))
    # crew collar ring
    parts.append(K.cyl("collar", 0.4, 0.08, (0, -0.02, h - 0.02), SEAM, verts=16, bev=0.02, cutters=[
        K.cutter_cyl(0.33, 0.3, (0, -0.02, h - 0.02), verts=16)]))
    parts.append(shell("hem", w + 0.03, d + 0.03, 0.12, 0.07, 0.0, SEAM, bev=0.04))
    # a small chest logo plate (bright)
    parts.append(K.box("logo", (0.34, 0.05, 0.2), (0.5, -d / 2 - 0.01, 1.05), TRIM, bev=0.02, seg=1))
    o = K.join(parts, "Kit_Tee")
    K.shade(o, ao_dist=0.25, seed=42)
    return o


def zip_top():
    w, d, h = 2.12, 1.28, 1.66
    body = K.box("zip", (w, d, h), (0, 0, h / 2), CLOTH, bev=0.1, seg=3, cutters=[
        K.cutter_box((w - 0.12, d - 0.12, h + 1), (0, 0, h / 2)),
    ])
    parts = [body]
    for sx in (-1, 1):
        parts.append(K.box("cap", (0.52, d + 0.06, 0.22), (sx * (w / 2 - 0.21), 0, h - 0.07), SEAM, bev=0.08, seg=2))
    # stand-up collar, a zip down the middle with a pull, two pocket seams, a ribbed hem
    parts.append(K.cyl("collar", 0.46, 0.26, (0, 0, h + 0.08), SEAM, verts=24, bev=0.03, r2=0.42, cutters=[
        K.cutter_cyl(0.38, 0.6, (0, 0, h + 0.08), verts=24)]))
    parts.append(K.box("zip", (0.07, 0.05, h + 0.2), (0, -d / 2 - 0.005, h / 2 + 0.08), TRIM, bev=0.015, seg=1))
    parts.append(K.box("pull", (0.1, 0.06, 0.18), (0.04, -d / 2 - 0.03, h - 0.15), TRIM, bev=0.02, seg=1))
    for s in (-1, 1):
        parts.append(K.box("pocket", (0.5, 0.04, 0.05), (s * 0.55, -d / 2 - 0.005, 0.45), SEAM, bev=0.01, seg=1, rot=(0, math.radians(s * 12), 0)))
    rib = shell("rib", w + 0.04, d + 0.04, 0.18, 0.08, 0.0, SEAM, bev=0.04)
    parts.append(rib)
    o = K.join(parts, "Kit_ZipTop")
    K.shade(o, ao_dist=0.25, seed=43)
    return o


# ---------------------------------------------------------------------------
# bottoms (round the hips, hanging over the top of the legs)
# ---------------------------------------------------------------------------
def shorts(name, h, split=False, seed=50):
    w, d = 2.22, 1.3
    cutters = [
        K.cutter_box((w - 0.12, d - 0.12, h + 1), (0, 0, h / 2)),
        # the gap between the legs (an upside-down V)
        K.cutter_prism([(-0.16, -0.1), (0.16, -0.1), (0.04, h * 0.42), (-0.04, h * 0.42)], d + 1, axis="y"),
    ]
    if split:
        for s in (-1, 1):
            cutters.append(K.cutter_prism([(s * w / 2 - 0.2, -0.1), (s * w / 2 + 0.2, -0.1), (s * w / 2, 0.34)], d + 1, axis="y"))
    body = K.box(name, (w, d, h), (0, 0, h / 2), CLOTH, bev=0.09, seg=3, cutters=cutters)
    parts = [body]
    # waistband with a drawstring, side stripe
    parts.append(shell("waist", w + 0.04, d + 0.04, 0.2, 0.08, h - 0.2, SEAM, bev=0.05))
    for s in (-1, 1):
        parts.append(K.tube("string", [(s * 0.06, -d / 2 - 0.03, h - 0.12), (s * 0.12, -d / 2 - 0.04, h - 0.42)], 0.025, TRIM, sides=6))
        parts.append(K.box("side", (0.04, 0.22, h - 0.36), (s * (w / 2 + 0.005), 0, (h - 0.2) / 2 + 0.04), TRIM, bev=0.015, seg=1))
    o = K.join(parts, name)
    K.shade(o, ao_dist=0.25, seed=seed)
    return o


def tights():
    w, d, h = 2.2, 1.28, 1.44
    body = K.box("tights", (w, d, h), (0, 0, h / 2), CLOTH, bev=0.09, seg=3, cutters=[
        K.cutter_box((w - 0.12, d - 0.12, h + 1), (0, 0, h / 2)),
        K.cutter_prism([(-0.1, -0.1), (0.1, -0.1), (0.03, h * 0.62), (-0.03, h * 0.62)], d + 1, axis="y"),
    ])
    parts = [body, shell("waist", w + 0.04, d + 0.04, 0.16, 0.08, h - 0.16, SEAM, bev=0.04)]
    # two long side seams + reflective strips at the knee line
    for s in (-1, 1):
        parts.append(K.box("seam", (0.035, 0.08, h - 0.2), (s * (w / 2 + 0.004), 0, (h - 0.16) / 2), SEAM, bev=0.01, seg=1))
        parts.append(K.box("reflect", (0.5, 0.04, 0.07), (s * 0.55, -d / 2 - 0.005, 0.18), TRIM, bev=0.01, seg=1))
    o = K.join(parts, "Kit_Tights")
    K.shade(o, ao_dist=0.25, seed=53)
    return o


# ---------------------------------------------------------------------------
# headwear (around a 1.2-stud head; front = -Y)
# ---------------------------------------------------------------------------
def headband():
    parts = [K.cyl("band", 0.65, 0.29, (0, 0, 0), CLOTH, verts=20, bev=0.05, cutters=[
        K.cutter_cyl(0.6, 0.6, (0, 0, 0), verts=20)])]
    # stitched edges + a little front plate
    for z in (-0.12, 0.12):
        parts.append(K.cyl("edge", 0.66, 0.04, (0, 0, z), SEAM, verts=20, bev=0.01, cutters=[
            K.cutter_cyl(0.61, 0.2, (0, 0, 0), verts=20)]))
    parts.append(K.box("plate", (0.26, 0.04, 0.14), (0, -0.665, 0), TRIM, bev=0.015, seg=1))
    o = K.join(parts, "Head_Headband")
    K.shade(o, ao_dist=0.2, seed=60)
    return o


def cap():
    rnd = random.Random(61)
    crown = K.blob("crown", (0, 0.06, 0), 0.66, CLOTH, CLOTH, seed=61, subdiv=3, rough=0.015, flatten=0.02, scale=(1, 1.04, 0.82))
    parts = [crown]
    # curved brim out the front, a button on top, panel seams
    brim = K.rounded_slab("brim", 1.0, 0.62, 0.06, 0.26, -0.02, SEAM, seg=5, center=(0, -0.72))
    for v in brim.data.vertices:
        v.co.z -= (v.co.x ** 2) * 0.18 + max(0.0, (-v.co.y - 0.6)) * 0.12
    parts.append(brim)
    parts.append(K.cyl("button", 0.07, 0.05, (0, 0.06, 0.55), TRIM, verts=10, bev=0.015))
    for i in range(3):
        a = math.radians(-60 + i * 60 + rnd.uniform(-3, 3))
        parts.append(K.tube("seam", [(math.sin(a) * 0.1, 0.06 - math.cos(a) * 0.1, 0.53), (math.sin(a) * 0.62, 0.06 - math.cos(a) * 0.62, 0.05)], 0.012, SEAM, sides=5))
    o = K.join(parts, "Head_Cap")
    K.shade(o, ao_dist=0.2, seed=61)
    return o


def visor():
    parts = [K.cyl("band", 0.65, 0.22, (0, 0, 0), CLOTH, verts=28, bev=0.04, cutters=[
        K.cutter_cyl(0.6, 0.6, (0, 0, 0), verts=28),
        K.cutter_box((1.6, 0.6, 0.6), (0, 0.62, 0))])]  # open at the back
    brim = K.rounded_slab("brim", 1.08, 0.66, 0.055, 0.28, -0.1, SEAM, seg=5, center=(0, -0.74))
    for v in brim.data.vertices:
        v.co.z -= (v.co.x ** 2) * 0.16
    parts.append(brim)
    parts.append(K.box("strap", (0.9, 0.05, 0.08), (0, 0.6, -0.02), TRIM, bev=0.015, seg=1))
    o = K.join(parts, "Head_Visor")
    K.shade(o, ao_dist=0.2, seed=62)
    return o


def shades():
    parts = []
    # one wrap-around lens (curved), a nose bridge and arms back to the ears
    lens = K.box("lens", (1.12, 0.1, 0.26), (0, -0.62, 0), LENS, bev=0.05, seg=3)
    for v in lens.data.vertices:
        v.co.y += (v.co.x ** 2) * 0.3
    parts.append(lens)
    parts.append(K.box("rim", (1.16, 0.12, 0.05), (0, -0.62 + 0.0, 0.13), TRIM, bev=0.02, seg=1))
    for s in (-1, 1):
        parts.append(K.box("arm", (0.05, 0.62, 0.06), (s * 0.6, -0.26, 0.08), TRIM, bev=0.02, seg=1))
    parts.append(K.box("bridge", (0.16, 0.08, 0.06), (0, -0.66, -0.06), TRIM, bev=0.02, seg=1))
    o = K.join(parts, "Head_Shades")
    K.shade(o, ao_dist=0.15, seed=63)
    return o


def bucket_hat():
    parts = [K.cyl("crown", 0.58, 0.5, (0, 0, 0.2), CLOTH, verts=28, bev=0.08, r2=0.5)]
    brim = K.cyl("brim", 0.88, 0.14, (0, 0, -0.07), SEAM, verts=32, bev=0.03, r2=0.62, cutters=[
        K.cutter_cyl(0.55, 0.5, (0, 0, -0.07), verts=28)])
    parts.append(brim)
    parts.append(K.cyl("band", 0.6, 0.1, (0, 0, 0.02), TRIM, verts=28, bev=0.02))
    o = K.join(parts, "Head_BucketHat")
    K.shade(o, ao_dist=0.2, seed=64)
    return o


def beanie():
    dome = K.blob("dome", (0, 0, 0), 0.64, CLOTH, CLOTH, seed=65, subdiv=3, rough=0.03, flatten=0.05, scale=(1, 1, 0.95), freq=5.0)
    parts = [dome]
    parts.append(K.cyl("cuff", 0.67, 0.26, (0, 0, 0.06), SEAM, verts=28, bev=0.05, cutters=[
        K.cutter_cyl(0.6, 0.6, (0, 0, 0.06), verts=28)]))
    pom = K.blob("pom", (0, 0, 0.7), 0.17, TRIM, TRIM, seed=66, subdiv=2, rough=0.25, flatten=0.9, freq=4.0)
    parts.append(pom)
    o = K.join(parts, "Head_Beanie")
    K.shade(o, ao_dist=0.2, seed=65)
    return o


BUILD = [
    ("Kit_Singlet", singlet), ("Kit_Tee", tee), ("Kit_ZipTop", zip_top),
    ("Kit_Shorts", lambda: shorts("Kit_Shorts", 1.2, seed=50)),
    ("Kit_SplitShorts", lambda: shorts("Kit_SplitShorts", 0.96, split=True, seed=51)),
    ("Kit_Tights", tights),
    ("Head_Headband", headband), ("Head_Cap", cap), ("Head_Visor", visor),
    ("Head_Shades", shades), ("Head_BucketHat", bucket_hat), ("Head_Beanie", beanie),
]

if __name__ == "__main__":
    total = 0
    for name, fn in BUILD:
        if ONLY and name not in ONLY:
            continue
        K.reset()
        obj = fn()
        total += export(obj, name)
    print(f"[kit] total {total} tris")
