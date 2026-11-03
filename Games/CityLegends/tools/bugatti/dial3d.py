"""3D dial centre / radius / normal on a converted car from texture circles (4 rim points each)."""
import bpy, sys, json, math
from mathutils import Vector
from mathutils.geometry import barycentric_transform, intersect_point_tri_2d
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
matsub, W, H = args[1], float(args[2]), float(args[3])
dials = json.loads(args[4])  # {kind: [px, py, r]}
tris = []
for o in bpy.data.objects:
    if o.type != "MESH": continue
    me = o.data; uv = me.uv_layers.active
    if not uv: continue
    mi = [i for i, m in enumerate(me.materials) if m and matsub.lower() in m.name.lower()]
    if not mi: continue
    me.calc_loop_triangles()
    for t in me.loop_triangles:
        if t.material_index not in mi: continue
        uvs = [uv.data[l].uv.copy() for l in t.loops]
        if abs((uvs[1] - uvs[0]).cross(uvs[2] - uvs[0])) < 1e-9: continue
        co = [o.matrix_world @ me.vertices[v].co for v in t.vertices]
        tris.append((uvs, co))
def to3d(px, py):
    p = Vector((px / W, 1 - py / H))
    hits = []
    for uvs, co in tris:
        if intersect_point_tri_2d(p, uvs[0], uvs[1], uvs[2]):
            hits.append(barycentric_transform(p.to_3d(), uvs[0].to_3d(), uvs[1].to_3d(), uvs[2].to_3d(), co[0], co[1], co[2]))
    # nearest the driver (largest y: front is -Y) = the visible face
    return max(hits, key=lambda q: q.y) if hits else None
out = {}
for k, (px, py, r) in dials.items():
    pts = [to3d(px + r * 0.9 * math.sin(a), py - r * 0.9 * math.cos(a)) for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2)]
    if any(p is None for p in pts):
        out[k] = None; continue
    c = sum(pts, Vector()) / 4
    rad = sum((p - c).length for p in pts) / 4 / 0.9
    n = (pts[1] - pts[3]).cross(pts[0] - pts[2]).normalized()
    if n.y < 0: n = -n
    out[k] = [[round(v, 5) for v in c], round(rad, 5), [round(v, 4) for v in n]]
print("DIAL3D", json.dumps(out))
