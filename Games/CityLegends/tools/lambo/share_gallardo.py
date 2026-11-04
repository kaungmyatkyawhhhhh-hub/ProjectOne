"""The Superleggera's cluster in the LP560-4 Spyder (owner, 2026-11-04: "for the lp560, use the SL's
clusters"), and the SL's own middle screen fixed.

The middle screen's ghost text: the model's emission picture (256 px) shows other numbers than its
colour picture ("+21.0" over "+20.0", "R N" over the gear strip). `sl_emission.png` is that emission
picture at 1024 with its middle screen redrawn from the colour picture.

    blender -b --python tools/lambo/share_gallardo.py -- sl.blend sl_emission.png sl_out.blend
    blender -b --python tools/lambo/share_gallardo.py -- spyder.blend sl_emission.png spyder_out.blend sl_out.blend

The Spyder keeps its own dial shapes; each of its dial faces takes the SL's picture of the same dial,
mapped through both cars' 3D dial planes: big dials, the two small side dials and the middle screen.
"""

import sys

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
car, emission, out = args[0], args[1], args[2]
donor = args[3] if len(args) > 3 else None
bpy.ops.wm.open_mainfile(filepath=car)


def fix_material(mat):
    img = bpy.data.images.load(emission)
    img.name = "SL_dash_emission"
    for n in mat.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image and n.image.size[0] == 256:
            n.image = img
            return True
    return False


def axes(n):
    n = n.normalized()
    s = Vector((1, 0, 0))
    s = (s - n * s.dot(n)).normalized()
    t = n.cross(s).normalized()
    return s, t


def fit(points):
    """least squares: uv = a + B (s, t); points: [(s, t, u, v)]"""
    import numpy as np

    A = np.array([[1, p[0], p[1]] for p in points])
    U = np.array([p[2] for p in points])
    V = np.array([p[3] for p in points])
    cu = np.linalg.lstsq(A, U, rcond=None)[0]
    cv = np.linalg.lstsq(A, V, rcond=None)[0]
    return cu, cv


def island(o, centre, reach):
    """loops of the faces within reach of a 3D point, as a list of (face index, centre)"""
    m = o.matrix_world
    return [p.index for p in o.data.polygons if (m @ p.center - centre).length < reach]


SL_DIALS = {
    "big_l": (Vector((0.444, -0.727, 0.79)), 0.075, (0.0, 0.79, 0.61)),
    "big_r": (Vector((0.278, -0.727, 0.79)), 0.075, (0.0, 0.79, 0.61)),
    "small_l": (Vector((0.507, -0.688, 0.751)), 0.03, (0.0, 0.86, 0.52)),
    "small_r": (Vector((0.214, -0.688, 0.751)), 0.03, (0.0, 0.86, 0.52)),
    "mid": (Vector((0.361, -0.726, 0.788)), 0.06, (0.0, 0.79, 0.61)),
}
# the Spyder's faces of each dial: by their place in its atlas (u0, u1, v0, v1), the same dial's name
SPY_DIALS = {
    "big_l": (Vector((0.452, -0.75, 0.75)), (0.41, 0.88, 0.0, 0.46), (0.0, 0.92, 0.4)),
    "big_r": (Vector((0.279, -0.75, 0.75)), (0.0, 0.43, 0.0, 0.46), (0.0, 0.92, 0.4)),
    "small_l": (Vector((0.515, -0.698, 0.718)), (0.0, 0.2, 0.43, 0.62), (0.0, 0.99, 0.16)),
    "small_r": (Vector((0.216, -0.698, 0.718)), (0.2, 0.39, 0.43, 0.62), (0.0, 0.99, 0.16)),
    "mid": (Vector((0.366, -0.748, 0.751)), (0.875, 1.0, 0.27, 0.45), (0.0, 0.91, 0.42)),
}

if donor is None:
    # the SL: a new emission picture, the dash as a solid part
    o = bpy.data.objects.get("SeeThrough_SLMI_Dashboard1") or bpy.data.objects["Body_SLMI_Dashboard1"]
    mat = o.material_slots[0].material
    print("GALLARDO emission swapped", fix_material(mat))
    mat.blend_method = "OPAQUE"
    o.name = "Body_SLMI_Dashboard1"
    bpy.ops.wm.save_as_mainfile(filepath=out)
    sys.exit(0)

with bpy.data.libraries.load(donor) as (src, dst):
    dst.objects = [n for n in src.objects if n.endswith("SLMI_Dashboard1")]
sl = dst.objects[0]
mat = sl.material_slots[0].material
uvl = sl.data.uv_layers.active.data
maps = {}
for key, (c, reach, n) in SL_DIALS.items():
    s, t = axes(Vector(n))
    pts = []
    xs = []
    m = sl.matrix_world
    for idx in island(sl, c, reach):
        p = sl.data.polygons[idx]
        # only this dial's own island (by its picture's place)
        uvs = [uvl[li].uv.copy() for li in p.loop_indices]
        pts.append((p, uvs))
    # the island's middle: the 3D box of the faces that share the dial's plane
    good = []
    for p, uvs in pts:
        if (m.to_3x3() @ p.normal).normalized().dot(Vector(n).normalized()) > 0.97:
            good.append((p, uvs))
    # keep the dial's own picture: the largest cluster of uv
    all_u = sorted(sum(([uv.x for uv in uvs] for _, uvs in good), []))
    all_v = sorted(sum(([uv.y for uv in uvs] for _, uvs in good), []))
    ranges = {"big_l": (0.0, 0.39, 0.0, 0.39), "big_r": (0.4, 0.78, 0.0, 0.39), "small_l": (0.58, 0.79, 0.53, 0.74), "small_r": (0.79, 1.0, 0.53, 0.74), "mid": (0.78, 1.0, 0.05, 0.35)}[key]
    fitpts = []
    px = []
    for p, uvs in good:
        if all(ranges[0] <= uv.x <= ranges[1] and ranges[2] <= uv.y <= ranges[3] for uv in uvs):
            for li, uv in zip(p.loop_indices, uvs):
                co = m @ sl.data.vertices[sl.data.loops[li].vertex_index].co
                px.append(co)
    lo = Vector((min(v.x for v in px), min(v.y for v in px), min(v.z for v in px)))
    hi = Vector((max(v.x for v in px), max(v.y for v in px), max(v.z for v in px)))
    mid = (lo + hi) / 2
    for p, uvs in good:
        if all(ranges[0] <= uv.x <= ranges[1] and ranges[2] <= uv.y <= ranges[3] for uv in uvs):
            for li, uv in zip(p.loop_indices, uvs):
                co = m @ sl.data.vertices[sl.data.loops[li].vertex_index].co
                d = co - mid
                fitpts.append((d.dot(s), d.dot(t), uv.x, uv.y))
    cu, cv = fit(fitpts)
    half_s = max(abs(q[0]) for q in fitpts)
    half_t = max(abs(q[1]) for q in fitpts)
    maps[key] = (cu, cv, half_s, half_t)
    print("GALLARDO SL", key, "mid", [round(x, 4) for x in mid], "half", round(half_s, 4), round(half_t, 4))

src_obj = bpy.data.objects["Body_MMAT_Details_INT1"]
bm = bmesh.new()
bm.from_mesh(src_obj.data)
uv = bm.loops.layers.uv.active
m = src_obj.matrix_world
new = bpy.data.meshes.new("Body_SpyderDash")
nb = bmesh.new()
nuv = nb.loops.layers.uv.new("UVMap")
drop = []
for key, (c, box, n) in SPY_DIALS.items():
    s, t = axes(Vector(n))
    faces = []
    for f in bm.faces:
        us = [l[uv].uv.x for l in f.loops]
        vs = [l[uv].uv.y for l in f.loops]
        if min(us) >= box[0] and max(us) <= box[1] and min(vs) >= box[2] and max(vs) <= box[3]:
            ctr = m @ f.calc_center_median()
            if (ctr - c).length < 0.075:
                faces.append(f)
    pts = [m @ v.co for f in faces for v in f.verts]
    lo = Vector((min(v.x for v in pts), min(v.y for v in pts), min(v.z for v in pts)))
    hi = Vector((max(v.x for v in pts), max(v.y for v in pts), max(v.z for v in pts)))
    mid = (lo + hi) / 2
    half_s = max(abs((v - mid).dot(s)) for v in pts)
    half_t = max(abs((v - mid).dot(t)) for v in pts)
    cu, cv, hs, ht = maps[key]
    k_s, k_t = hs / half_s, ht / half_t
    if key != "mid":
        k_s = k_t = max(k_s, k_t)  # a dial stays round (the SL's own face is cut off a little at its sides)
    print("GALLARDO Spyder", key, "faces", len(faces), "mid", [round(x, 4) for x in mid], "half", round(half_s, 4), round(half_t, 4), "scale", round(k_s, 3), round(k_t, 3))
    for f in faces:
        vs = [nb.verts.new(m @ v.co) for v in f.verts]
        nf = nb.faces.new(vs)
        for l, src_v in zip(nf.loops, f.verts):
            d = m @ src_v.co - mid
            a, b = d.dot(s) * k_s, d.dot(t) * k_t
            l[nuv].uv = (cu[0] + cu[1] * a + cu[2] * b, cv[0] + cv[1] * a + cv[2] * b)
        drop.append(f)
bmesh.ops.delete(bm, geom=list(set(drop)), context="FACES")
bm.to_mesh(src_obj.data)
bm.free()
# the pale rings round its dials go dark, like the SL's: their faces take the hood's dark spot
hood = bpy.data.objects["Body_MMAT_Details_MAT1"]
bm = bmesh.new()
bm.from_mesh(hood.data)
uv = bm.loops.layers.uv.active
mm = hood.matrix_world
ringed = 0
for f in bm.faces:
    us = [l[uv].uv.x for l in f.loops]
    vs = [l[uv].uv.y for l in f.loops]
    if min(us) >= 0.53 and max(us) <= 0.6 and min(vs) >= 0.33 and max(vs) <= 0.49:
        ctr = mm @ f.calc_center_median()
        if 0.15 < ctr.x < 0.58 and -0.86 < ctr.y < -0.6 and 0.66 < ctr.z < 0.86:
            for l in f.loops:
                l[uv].uv = (0.072, 0.679)
            ringed += 1
bm.to_mesh(hood.data)
bm.free()
print("GALLARDO ring faces darkened", ringed)
nb.to_mesh(new)
nb.free()
new.materials.append(mat)
ob = bpy.data.objects.new("Body_SpyderDash", new)
src_obj.users_collection[0].objects.link(ob)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("GALLARDO saved", out)
