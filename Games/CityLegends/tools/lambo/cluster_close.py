"""Step 1 close-ups of a converted car: the cluster with the steering wheel hidden, the steering wheel
from the driver's eye, and what the cluster is made of (parts, materials, pictures and their sizes).
Aims from the steering centre in auto_car.py's report (render_car.py aims at the last wheel piece, which
is off when the wheel comes in several pieces).

    blender -b --python tools/lambo/cluster_close.py -- car.blend outprefix [up,back,lens]

Writes <outprefix>_cl.png, <outprefix>_sw.png, <outprefix>_cl.json. The car lies like auto_car.py makes
it: front along -Y, up +Z, metres. `up,back,lens` move the cluster aim from the wheel's centre.
"""

import json
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
blend, out = args[0], args[1]
up, back, lens = 0.10, 0.25, 42.0
if len(args) > 2:
    up, back, lens = [float(v) for v in args[2].split(",")]
report = json.load(open(blend + ".json"))
c = Vector(report["steering"]["centre"])
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene

w = bpy.data.worlds.new("w")
sc.world = w
w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.84, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 48
sc.cycles.use_denoising = True
sc.render.image_settings.file_format = "PNG"
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
sc.camera = co
lamp = bpy.data.lights.new("l", "POINT")
lamp.energy = 10
lo = bpy.data.objects.new("l", lamp)
sc.collection.objects.link(lo)


def aim(eye, look, lns):
    cam.lens = lns
    co.location = eye
    co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
    lo.location = eye + Vector((0, 0.04, 0.05))
    bpy.context.view_layer.update()


def shoot(path, W, H):
    sc.render.resolution_x, sc.render.resolution_y = W, H
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def is_wheel(o):
    t = o
    while t:
        if t.name.startswith("SteeringWheel"):
            return True
        t = t.parent
    return False


# the steering wheel, from the driver's eye
aim(c + Vector((0, 0.62, 0.10)), c, 35)
shoot(out + "_sw.png", 900, 750)

# the cluster, wheel hidden
for o in bpy.data.objects:
    if o.type == "MESH" and is_wheel(o):
        o.hide_render = True
        o.hide_viewport = True
bpy.context.view_layer.update()
target = c + Vector((0, -back, up))
eye = target + Vector((0, 0.46, 0.12))
aim(eye, target, lens)
shoot(out + "_cl.png", 1400, 800)

# what it's made of: a grid of rays through the picture
dg = bpy.context.evaluated_depsgraph_get()
sc.render.resolution_x, sc.render.resolution_y = 1400, 800
fr = cam.view_frame(scene=sc)
tr, br, bl, tl = fr[0], fr[1], fr[2], fr[3]
seen = {}
for i in range(36):
    for j in range(20):
        u, v = (i + 0.5) / 36, (j + 0.5) / 20
        p = bl.lerp(tl, 1 - v).lerp(br.lerp(tr, 1 - v), u)
        d = (co.matrix_world.to_3x3() @ p).normalized()
        origin = eye
        for _ in range(6):
            hit, loc, nrm, idx, obj, mat = sc.ray_cast(dg, origin, d)
            if not hit:
                break
            if obj.name.startswith("SeeThrough"):
                origin = loc + d * 0.002
                continue
            me = obj.evaluated_get(dg).to_mesh()
            poly = me.polygons[idx]
            m = obj.material_slots[poly.material_index].material if obj.material_slots else None
            imgs = []
            if m and m.use_nodes:
                for n in m.node_tree.nodes:
                    if n.type == "TEX_IMAGE" and n.image:
                        s = ""
                        for o2 in n.outputs:
                            for l in o2.links:
                                s = l.to_socket.name
                        imgs.append("%s %dx%d %s" % (n.image.name[:36], n.image.size[0], n.image.size[1], s[:10]))
            k = (obj.name[:40], m.name[:40] if m else "", " | ".join(imgs))
            seen[k] = seen.get(k, 0) + 1
            break
rows = sorted(seen.items(), key=lambda kv: -kv[1])[:10]
json.dump([{"n": n, "obj": k[0], "mat": k[1], "imgs": k[2]} for k, n in rows], open(out + "_cl.json", "w"), indent=0)
print("CLOSE", out)
