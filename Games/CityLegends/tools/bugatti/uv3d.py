"""UV pixel -> 3D point on a converted car: blender -b --python uv3d.py -- car.blend <material substring> W H name:px,py ..."""
import bpy, sys, json
from mathutils import Vector
from mathutils.geometry import barycentric_transform, intersect_point_tri_2d
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
matsub, W, H = args[1], float(args[2]), float(args[3])
pts = {}
for a in args[4:]:
    n, xy = a.split(":"); px, py = map(float, xy.split(",")); pts[n] = Vector((px / W, 1 - py / H))
res = {}
for o in bpy.data.objects:
    if o.type != "MESH": continue
    me = o.data
    uv = me.uv_layers.active
    if not uv: continue
    mi = [i for i, m in enumerate(me.materials) if m and matsub.lower() in m.name.lower()]
    if not mi: continue
    me.calc_loop_triangles()
    for t in me.loop_triangles:
        if t.material_index not in mi: continue
        uvs = [uv.data[l].uv for l in t.loops]
        if abs((uvs[1] - uvs[0]).cross(uvs[2] - uvs[0])) < 1e-9: continue
        for n, p in pts.items():
            if intersect_point_tri_2d(p, uvs[0], uvs[1], uvs[2]):
                co = [o.matrix_world @ me.vertices[v].co for v in t.vertices]
                q = barycentric_transform(p.to_3d(), uvs[0].to_3d(), uvs[1].to_3d(), uvs[2].to_3d(), co[0], co[1], co[2])
                nrm = (o.matrix_world.to_3x3() @ t.normal).normalized()
                res.setdefault(n, []).append((o.name, [round(v, 4) for v in q], [round(v, 3) for v in nrm]))
print("UV3D", json.dumps(res))
