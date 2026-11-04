"""Tight look at the cluster with the steering wheel hidden, and the same with SeeThrough parts listed.
blender -b --python zoom.py -- car.blend out.png cx,cy,cz lens"""
import bpy, sys, json
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
blend, out = args[0], args[1]
cen = Vector([float(v) for v in args[2].split(",")])
lens = float(args[3])
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
for o in bpy.data.objects:
    if o.type == "MESH" and o.name.startswith("SteeringWheel"):
        o.hide_render = True
w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.84, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 48
sc.cycles.use_denoising = True
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co
sc.render.resolution_x, sc.render.resolution_y = 1400, 800
cam.lens = lens
eye = cen + Vector((0, 0.42, 0.12))
co.location = eye
co.rotation_euler = (cen - eye).normalized().to_track_quat("-Z", "Y").to_euler()
# a soft lamp at the eye so the dash shows
lamp = bpy.data.lights.new("l", "POINT")
lamp.energy = 14
lo = bpy.data.objects.new("l", lamp)
lo.location = eye + Vector((0, 0.05, 0.05))
sc.collection.objects.link(lo)
sc.render.filepath = out
sc.render.image_settings.file_format = "PNG"
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
# what's at the middle, and the SeeThrough parts near it
hit, loc, nrm, idx, obj, mat = sc.ray_cast(dg, eye, (cen - eye).normalized())
print("HIT", obj.name if obj else None, [round(x, 3) for x in loc] if hit else None)
for o in bpy.data.objects:
    if o.type == "MESH" and o.material_slots:
        lo2, hi2 = Vector((1e9,) * 3), Vector((-1e9,) * 3)
        for v in o.bound_box:
            p = o.matrix_world @ Vector(v)
            lo2 = Vector(map(min, lo2, p))
            hi2 = Vector(map(max, hi2, p))
        size = hi2 - lo2
        if size.length < 1.2 and (lo2.x - 0.05 < cen.x < hi2.x + 0.05) and (lo2.y - 0.1 < cen.y < hi2.y + 0.1) and (lo2.z - 0.1 < cen.z < hi2.z + 0.1):
            mats = []
            for s in o.material_slots:
                if s.material and s.material.use_nodes:
                    ims = [(n.image.name[:18], n.image.size[0]) for n in s.material.node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
                    mats.append((s.material.name[:30], ims))
            print("NEAR", o.name[:40], [round(x, 2) for x in size], mats)
bpy.ops.render.render(write_still=True)
