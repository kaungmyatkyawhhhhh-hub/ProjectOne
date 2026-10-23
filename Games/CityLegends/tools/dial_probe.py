"""Which texture and texture pixel a render pixel of a converted car shows (for tools/dial_fit.py).

    python tools/dial_probe.py car.blend view.json '{"name": [x, y], ...}'

view.json: {"eye": [x, y, z], "look": [x, y, z], "lens": mm, "W": px, "H": px}, the camera of the render.
"""
import bpy, sys, json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform
blend, viewjson, pts = sys.argv[-3], sys.argv[-2], json.loads(sys.argv[-1])
bpy.ops.wm.open_mainfile(filepath=blend)
v = json.load(open(viewjson))
sc = bpy.context.scene
W, H = v["W"], v["H"]
sc.render.resolution_x = W; sc.render.resolution_y = H
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co)
cam.lens = v["lens"]
eye, look = Vector(v["eye"]), Vector(v["look"])
co.location = eye; co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
for o in bpy.data.objects:
    if o.name.startswith("SteeringWheel") or o.name.startswith("SeeThrough"):
        o.hide_set(True); o.hide_viewport = True
bpy.context.view_layer.update()
tr, br, bl, tl = cam.view_frame(scene=sc)
M = co.matrix_world
dg = bpy.context.evaluated_depsgraph_get()
for name, (px, py) in pts.items():
    p = tl + (tr - tl) * (px / W) + (bl - tl) * (py / H)
    d = (M.to_3x3() @ p).normalized()
    hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, M.translation, d)
    if not hit:
        print("PROBE", name, "miss"); continue
    me = obj.data; poly = me.polygons[idx]
    mat = me.materials[poly.material_index] if me.materials else None
    img = None
    if mat and mat.node_tree and "Principled BSDF" in mat.node_tree.nodes:
        b = mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"]
        if b.is_linked and b.links[0].from_node.type == "TEX_IMAGE":
            img = b.links[0].from_node.image
    Mi = obj.matrix_world.inverted()
    lp = Mi @ loc
    uvl = me.uv_layers.active.data
    # the triangle of the polygon that holds the point
    best = None
    for li in range(1, len(poly.loop_indices) - 1):
        ids = [poly.loop_indices[0], poly.loop_indices[li], poly.loop_indices[li + 1]]
        vs = [me.vertices[me.loops[i].vertex_index].co for i in ids]
        uvs = [Vector((*uvl[i].uv, 0)) for i in ids]
        uv = barycentric_transform(lp, vs[0], vs[1], vs[2], uvs[0], uvs[1], uvs[2])
        best = uv; break
    if img:
        print("PROBE", name, obj.name, img.name, tuple(img.size), "px %.1f %.1f" % (best.x * img.size[0], (1 - best.y) * img.size[1]), "p", [round(x, 4) for x in loc], "n", [round(x, 3) for x in nrm])
    else:
        print("PROBE", name, obj.name, "no image", mat.name if mat else None, "p", [round(x, 4) for x in loc])
