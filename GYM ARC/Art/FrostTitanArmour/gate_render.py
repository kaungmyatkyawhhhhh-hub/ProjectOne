# Gate renders: each armour piece alone, orthographic, at the sheet's pixel scale (100 px = 1 unit), white on black.
# Output: gate/<view>.png, compared with mask_<view>.png by gate_iou.py. Run in Blender after build_armour.py.
import bpy, os, math
from mathutils import Vector

HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\FrostTitanArmour"
OUT = os.path.join(HERE, "gate")
os.makedirs(OUT, exist_ok=True)
sc = bpy.context.scene
VIEWS = {  # name: (objects, view direction from the target towards the eye, up)
    "plate1": (["PauldronPlate1L", "PauldronPlate1LRim"], (0, -1, 0)),
    "plate2": (["PauldronPlate2L", "PauldronPlate2LRim"], (0, -1, 0)),
    "plate3": (["PauldronPlate3L", "PauldronPlate3LRim"], (0, -1, 0)),
    "crown_front": (["IceCrown", "IceCrownRim"], (0, -1, 0)),
    "crown_top": (["IceCrown", "IceCrownRim"], (0, 0, 1)),
    "bracer_front": (["BracerL", "BracerLBand"], (0, -1, 0)),
    "bracer_side": (["BracerL", "BracerLBand"], (1, 0, 0)),
}
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "SINGLE"
sc.display.shading.single_color = (1, 1, 1)
sc.display.shading.background_type = "VIEWPORT" if False else sc.display.shading.background_type
sc.world = sc.world or bpy.data.worlds.new("GateWorld")
sc.world.color = (0, 0, 0)
sc.render.film_transparent = False
sc.view_settings.view_transform = "Standard"
sc.render.image_settings.file_format = "PNG"
cam_data = bpy.data.cameras.get("GateCam") or bpy.data.cameras.new("GateCam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.get("GateCam") or bpy.data.objects.new("GateCam", cam_data)
if cam.name not in sc.collection.objects:
    sc.collection.objects.link(cam)
sc.camera = cam
meshes = [o for o in sc.objects if o.type == "MESH"]
# the first render after a rebuild misses the freshly linked camera: render the first view twice
for name, (objs, d) in [next(iter(VIEWS.items()))] + list(VIEWS.items()):
    for o in meshes:
        o.hide_render = o.name not in objs
    pts = [o.matrix_world @ Vector(c) for o in meshes if o.name in objs for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    c = (lo + hi) / 2
    size = hi - lo
    d = Vector(d).normalized()
    cam.location = c + d * 50
    up = Vector((0, 1, 0)) if abs(d.z) > 0.9 else Vector((0, 0, 1))
    back = d
    right = up.cross(back).normalized()
    true_up = back.cross(right)
    from mathutils import Matrix
    cam.matrix_world = Matrix((
        (right.x, true_up.x, back.x, cam.location.x),
        (right.y, true_up.y, back.y, cam.location.y),
        (right.z, true_up.z, back.z, cam.location.z),
        (0, 0, 0, 1)))
    bpy.context.view_layer.update()
    # frame 1.3x the larger extent, keeping 100 px per unit
    if abs(d.x) > 0.9:
        w, h = size.y, size.z
    elif abs(d.y) > 0.9:
        w, h = size.x, size.z
    else:
        w, h = size.x, size.y
    ext = max(w, h) * 1.3
    px = int(round(ext * 100))
    sc.render.resolution_x = sc.render.resolution_y = px
    sc.render.resolution_percentage = 100
    cam_data.ortho_scale = ext
    sc.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
for o in meshes:
    o.hide_render = False
print("gate renders:", sorted(os.listdir(OUT)))
