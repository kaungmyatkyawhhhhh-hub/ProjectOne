"""What is the cluster made of? Blender: rays from the cluster camera; object, material, its images, UV.
blender -b --python pick.py -- car.blend outdir"""
import bpy, sys, os, json
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
blend, outdir = args[0], args[1]
name = os.path.splitext(os.path.basename(blend))[0]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
steer = None
for o in bpy.data.objects:
    if o.type == "MESH" and o.name.startswith("SteeringWheel"):
        steer = o
        break
# same point render_car.py uses
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
for v in steer.bound_box:
    p = steer.matrix_world @ Vector(v)
    lo = Vector(map(min, lo, p))
    hi = Vector(map(max, hi, p))
c = (lo + hi) / 2
eye = c + Vector((0, 0.32, 0.16))
look = c + Vector((0, -0.3, 0.05))
cam = bpy.data.cameras.new("c")
co = bpy.data.objects.new("cam", cam)
sc.collection.objects.link(co)
cam.lens = 30
co.location = eye
co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
bpy.context.view_layer.update()
sc.render.resolution_x, sc.render.resolution_y = 1200, 750
dg = bpy.context.evaluated_depsgraph_get()
fr = cam.view_frame(scene=sc)
tr, br, bl, tl = fr[0], fr[1], fr[2], fr[3]


def ray(u, v):
    top = tl.lerp(tr, u)
    bot = bl.lerp(br, u)
    p = bot.lerp(top, 1 - v)
    d = (co.matrix_world.to_3x3() @ p).normalized()
    origin = eye
    # step through see-through hits
    for _ in range(6):
        hit, loc, nrm, idx, obj, mat = sc.ray_cast(dg, origin, d)
        if not hit:
            return None
        if obj.name.startswith("SteeringWheel") or obj.name.startswith("SeeThrough"):
            origin = loc + d * 0.002
            continue
        ev = obj.evaluated_get(dg)
        me = ev.to_mesh()
        poly = me.polygons[idx]
        m = obj.material_slots[poly.material_index].material if obj.material_slots else None
        uv = None
        if me.uv_layers:
            li = poly.loop_indices[0]
            uv = tuple(round(x, 3) for x in me.uv_layers.active.data[li].uv)
        imgs = []
        if m and m.use_nodes:
            for n in m.node_tree.nodes:
                if n.type == "TEX_IMAGE" and n.image:
                    socket = ""
                    for out in n.outputs:
                        for l in out.links:
                            socket = l.to_socket.name
                    imgs.append((n.image.name[:40], n.image.size[0], n.image.size[1], socket))
        return {"obj": obj.name[:44], "mat": (m.name[:44] if m else None), "uv": uv, "imgs": imgs, "pos": [round(x, 3) for x in loc]}
    return None


res = {}
for key, (u, v) in {"mid": (0.5, 0.46), "left": (0.36, 0.5), "right": (0.64, 0.5), "up": (0.5, 0.38)}.items():
    res[key] = ray(u, v)
print("PICK", name, json.dumps(res))
seen = {}
for key, r in res.items():
    if r:
        for im in r["imgs"]:
            seen[im[0]] = 1
os.makedirs(outdir, exist_ok=True)
for im in bpy.data.images:
    if im.name[:40] in seen and im.size[0] > 0:
        try:
            im2 = im.copy()
            im2.filepath_raw = os.path.join(outdir, name + "_" + "".join(ch if ch.isalnum() else "_" for ch in im.name[:32]) + ".png")
            im2.file_format = "PNG"
            im2.save()
        except Exception as e:
            print("save failed", im.name, e)
