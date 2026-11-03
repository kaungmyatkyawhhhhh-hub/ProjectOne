"""Live-needle numbers for a converted car's own dials (CarSkin.OWN_NEEDLES / DIAL_NEEDLES), measured
on its .blend from the dial texture: each dial's centre and its number labels in texture pixels.

    blender -b --python tools/needle_specs.py -- car.blend spec.json

spec.json: {"material": "<name part>", "size": [W, H],
            "dials": {"rpm": {"unit": "redline", "centre": [px, py], "radius": rpx,
                              "labels": [[value, px, py], ...]}, ...}}
Prints one Lua line per dial: kind, unit, at (the dial's middle from the middle of the steering wheel,
metres along the car's right / up / back), face (the way the dial looks), its scale (reading ->
degrees clockwise from 12 o'clock as the driver sees it), the needle's modelled angle ("rest", from
the part "Needle_<kind>" if there is one) and its length (needle part, else 0.8 of the dial radius).
The car is laid out as auto_car.py makes it: front -Y, up +Z, metres (right = -X, back = +Y).
"""

import json
import math
import sys

import bpy
from mathutils import Vector
from mathutils.geometry import barycentric_transform, intersect_point_tri_2d

args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
spec = json.load(open(args[1]))
W, H = spec["size"]
matsub = spec["material"].lower()

tris = []
for o in bpy.data.objects:
    if o.type != "MESH" or o.name.startswith("Needle_"):
        continue
    me = o.data
    uv = me.uv_layers.active
    if not uv:
        continue
    mi = [i for i, m in enumerate(me.materials) if m and matsub in m.name.lower()]
    if not mi:
        continue
    me.calc_loop_triangles()
    for t in me.loop_triangles:
        if t.material_index not in mi:
            continue
        uvs = [uv.data[l].uv.copy() for l in t.loops]
        if abs((uvs[1] - uvs[0]).cross(uvs[2] - uvs[0])) < 1e-10:
            continue
        tris.append((uvs, [o.matrix_world @ me.vertices[v].co for v in t.vertices]))


def to3d(px, py):
    p = Vector((px / W, 1 - py / H))
    hits = []
    for uvs, co in tris:
        if intersect_point_tri_2d(p, uvs[0], uvs[1], uvs[2]):
            hits.append(barycentric_transform(p.to_3d(), uvs[0].to_3d(), uvs[1].to_3d(), uvs[2].to_3d(), co[0], co[1], co[2]))
    return max(hits, key=lambda q: q.y) if hits else None  # the face nearest the driver


def rub(v):  # Blender -> right / up / back
    return Vector((-v.x, v.z, v.y))


# the middle of the steering wheel: the box round all its pieces (as CarSkin reads it in Studio)
lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
for o in bpy.data.objects:
    if o.type == "MESH" and o.name.startswith("SteeringWheel"):
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
wheel = (lo + hi) / 2

# flat read-outs (a live speed or gear over the model's printed one): a texture rectangle -> its
# middle, the way it looks, its width (length) and height
for kind, b in spec.get("boxes", {}).items():
    x0, y0, x1, y1 = b["rect"]
    cs = [to3d(x0, y0), to3d(x1, y0), to3d(x0, y1), to3d(x1, y1)]
    if any(p is None for p in cs):
        print(f"-- box {kind}: not found on the model")
        continue
    mid = sum(cs, Vector()) / 4
    n = (cs[1] - cs[0]).cross(cs[2] - cs[0]).normalized()
    if n.y < 0:
        n = -n
    face = rub(n).normalized()
    at = rub(mid) - rub(wheel)
    w = ((cs[1] - cs[0]).length + (cs[3] - cs[2]).length) / 2
    h = ((cs[2] - cs[0]).length + (cs[3] - cs[1]).length) / 2
    print("LUA", f'{{ kind = "{kind}", unit = "{b.get("unit", "")}", at = Vector3.new({at.x:.4f}, {at.y:.4f}, {at.z:.4f}), '
          f'face = Vector3.new({face.x:.4f}, {face.y:.4f}, {face.z:.4f}), length = {w:.4f}, scale = "" }}, -- height {h:.4f}')

for kind, d in spec["dials"].items():
    cx, cy = d["centre"]
    r = d["radius"]
    rim = []
    for k in (0.9, 0.8, 0.7, 0.95):
        rim = [to3d(cx + r * k * math.sin(a), cy - r * k * math.cos(a)) for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2)]
        if all(p is not None for p in rim):
            break
    if any(p is None for p in rim):
        print(f"-- {kind}: not found on the model")
        continue
    c3 = to3d(cx, cy) or sum(rim, Vector()) / 4  # (the hub can be a hole in the face)
    if c3 is None:
        print(f"-- {kind}: not found on the model")
        continue
    n = (rim[1] - rim[3]).cross(rim[0] - rim[2]).normalized()
    if n.y < 0:
        n = -n
    face = rub(n).normalized()
    upP = (Vector((0, 1, 0)) - face * face.y).normalized()
    rightP = upP.cross(face)

    def ang(p3):
        dv = rub(p3) - rub(c3)
        return math.degrees(math.atan2(dv.dot(rightP), dv.dot(upP)))

    pts = []
    for val, px, py in d["labels"]:
        q = to3d(px, py)
        if q is not None:
            pts.append((val, ang(q)))
    # angles run clockwise with the value: unwrap so they only grow
    out = []
    for val, a in sorted(pts):
        if out:
            while a < out[-1][1] - 1:
                a += 360
        out.append((val, a))
    scale = ",".join(f"{v:g}:{a:.1f}" for v, a in out)
    rest, length = None, 0.8 * r / r * (sum((p - c3).length for p in rim) / 4)
    needle = bpy.data.objects.get(f"Needle_{kind}")
    if needle:
        far, fd = None, -1
        for v in needle.data.vertices:
            w = needle.matrix_world @ v.co
            dd = (rub(w) - rub(c3)).length
            if dd > fd:
                far, fd = w, dd
        rest, length = ang(far), fd
    at = rub(c3) - rub(wheel)
    print(
        "LUA",
        f'{{ kind = "{kind}", unit = "{d["unit"]}", at = Vector3.new({at.x:.4f}, {at.y:.4f}, {at.z:.4f}), '
        f"face = Vector3.new({face.x:.4f}, {face.y:.4f}, {face.z:.4f}), length = {length:.4f}, "
        f'scale = "{scale}"' + (f", rest = {rest:.1f}" if rest is not None else "") + " },",
    )
