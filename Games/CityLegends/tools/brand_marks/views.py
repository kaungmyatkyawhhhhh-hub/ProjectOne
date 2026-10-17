import bpy, sys, re, json
from mathutils import Vector
blend, car, outdir = sys.argv[-3], sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=blend)
MARK = re.compile(r"badge|logo|emblem|letter|decal_badg|sign\b", re.I)
mag = bpy.data.materials.new("mark"); mag.use_nodes = True
b = mag.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = (1, 0, 1, 1)
b.inputs["Emission Color"].default_value = (1, 0, 1, 1); b.inputs["Emission Strength"].default_value = 1.5
lo, hi = Vector((1e9,)*3), Vector((-1e9,)*3)
for o in bpy.data.objects:
    if o.type != "MESH": continue
    for v in o.bound_box:
        p = o.matrix_world @ Vector(v); lo = Vector(map(min, lo, p)); hi = Vector(map(max, hi, p))
    if o.name.startswith(("FL", "FR", "RL", "RR", "SteeringWheel")): continue
    if MARK.search(o.name) or any(m and MARK.search(m.name) for m in o.data.materials):
        o.data.materials.clear(); o.data.materials.append(mag)
    if o.name.startswith("SeeThrough"): o.hide_render = True
w = bpy.data.worlds.new("w"); bpy.context.scene.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[1].default_value = 3
sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.samples = 12; sc.cycles.use_denoising = False
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
views = {}
def shot(name, eye, look, lens, W, H):
    sc.render.resolution_x = W; sc.render.resolution_y = H
    cam.lens = lens
    co.location = Vector(eye); co.rotation_euler = (Vector(look) - Vector(eye)).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{outdir}/{car}_{name}.png"; bpy.ops.render.render(write_still=True)
    views[name] = {"eye": list(eye), "look": list(look), "lens": lens, "W": W, "H": H}
Hh = hi.z - lo.z; L = hi.y - lo.y; Wd = hi.x - lo.x
d = Wd * 1.25 * 36 / 2 / 36 * 2  # framing
shot("F", (0, lo.y - 4.0, lo.z + Hh * 0.5), (0, lo.y, lo.z + Hh * 0.45), 50 * 4.0 / (Wd * 1.15) * 0.72, 800, 560)
shot("R", (0, hi.y + 4.0, lo.z + Hh * 0.5), (0, hi.y, lo.z + Hh * 0.45), 50 * 4.0 / (Wd * 1.15) * 0.72, 800, 560)
cy = (lo.y + hi.y) / 2
shot("S", (hi.x + 6.0, cy, lo.z + Hh * 0.5), (0, cy, lo.z + Hh * 0.5), 36 * 6.0 / (L * 1.08), 1600, 620)
json.dump(views, open(f"{outdir}/{car}.views.json", "w"))
