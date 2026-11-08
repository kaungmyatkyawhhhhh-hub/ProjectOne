"""The lamp shells (LampFx_<role><L/R>) for client/CarLamps, cut straight from the model's own lamp pieces in its
original .glb and laid into the finished car (2026-11-09, the first Precision Type 42). It replaces the Studio scan
(LampScan + lamp_pick + lamp_roles + lamp_mesh) for a car whose .glb names its lamp pieces: the shells go into the
car's pack, so one Open Cloud upload brings the car and its lamps.

    blender -b --python tools/lamps/lampfx_glb.py -- done.blend painted.glb out.blend tools/lamps/jobs/<car id>.json

The .glb is moved onto the finished car by its bounding box (auto_car.py only scales and lifts it: the scale and the
shift are printed, the same from the low and the high corner when it fits). Job file:
  {"<role>": [{"node": "headlight{S}_head_light", "off": 0.004,
               "uv": [u0, u1, v0, v1],      (only faces whose middle is in this part of the picture, in 0-1024 pixels)
               "absx": [lo, hi],            (only faces this far out from the middle, metres)
               "split": true,               (one node holds both sides: each side takes its own half)
               "box": [x0, y0, z0, x1, y1, z1],  (2026-11-09, the second Precision 4S: only faces whose middle is in this box,
                                             car metres, x as distance out from the middle, so one box serves
                                             both sides; for a node that holds the front and the rear lamps)
               "mat": "red_glass"}]}        (2026-11-09: in place of "node", every mesh of the .glb wearing a
                                             material with this in its name; for nodes whose names are cut
                                             to the same 63 characters)
{S} is L or R (Blender object names stop at 63 characters: give a piece of the node's name that fits). Roles:
HeadCore, HeadGlass, TurnF, TurnR, Rev, Tail. Each shell stands "off" metres proud of its piece along the normals.
After the insert, set each LampFx part to Neon, white, Transparency 0.9, no collisions or shadow (LampApply does
the same); then add the id to CarLamps.CARS.
"""
import json
import sys

import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
done, glb, out, job_path = a[0], a[1], a[2], a[3]
job = json.load(open(job_path))
bpy.ops.wm.open_mainfile(filepath=done)


def bbox(objs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


car = [o for o in bpy.data.objects if o.type == "MESH" and not o.name.startswith("LampFx_")]
dlo, dhi = bbox(car)
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=glb)
raw = [o for o in bpy.data.objects if o not in before]
rawm = [o for o in raw if o.type == "MESH" and not o.name.startswith("Icosphere") and len(o.data.polygons)]
rlo, rhi = bbox(rawm)
s3 = [(dhi[i] - dlo[i]) / (rhi[i] - rlo[i]) for i in range(3)]
s = (s3[0] + s3[1]) / 2
t = Vector([dlo[i] - s * rlo[i] for i in range(3)])
t2 = Vector([dhi[i] - s * rhi[i] for i in range(3)])
print("LAMPFX scale", [round(x, 3) for x in s3], "shift", [round(x, 4) for x in t], "from the high corner", [round(x, 4) for x in t2])


def node(word):
    m = [o for o in rawm if word in o.name]
    assert len(m) == 1, (word, [o.name for o in m])
    return m[0]


def nodes_for(pc):
    """the raw meshes for a piece: one node by a piece of its name, or all meshes wearing a material"""
    if "mat" in pc:
        m = [o for o in rawm if any(mt and pc["mat"] in mt.name for mt in o.data.materials)]
        assert m, ("no mesh wears", pc["mat"])
        return m
    return [node(pc["node"].replace("{S}", SIDE[0]))]


SIDE = ["L"]


def faces(o, keep=None):
    """triangles of a raw node in the car's frame (metres), [(p0, p1, p2)], optionally filtered by keep(c, u, v)"""
    me = o.data
    uv = me.uv_layers.active.data if me.uv_layers else None
    M = o.matrix_world
    tris = []
    for p in me.polygons:
        pts = [(M @ me.vertices[i].co) * s + t for i in p.vertices]
        if keep is not None:
            u = v = 0.0
            if uv:
                u = sum(uv[l].uv.x for l in p.loop_indices) / p.loop_total
                v = sum(uv[l].uv.y for l in p.loop_indices) / p.loop_total
            c = sum(pts, Vector()) / len(pts)
            if not keep(c, (u % 1.0) * 1024, (1 - (v % 1.0)) * 1024):
                continue
        for k in range(1, len(pts) - 1):
            tris.append((pts[0], pts[k], pts[k + 1]))
    return tris


mat = bpy.data.materials.new("LampFx")
mat.use_nodes = True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (1, 1, 1, 1)


def shell(name, tris, off):
    if not tris:
        print("LAMPFX empty", name)
        return
    V = np.array([[tuple(p) for p in tr] for tr in tris]).reshape(-1, 3)
    T = np.arange(len(V)).reshape(-1, 3)
    uq, inv = np.unique(np.round(V, 4), axis=0, return_inverse=True)
    inv = inv.reshape(-1)
    N = np.zeros((len(uq), 3))
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for i in range(3):
        np.add.at(N, inv[T[:, i]], fn)
    L = np.linalg.norm(N, axis=1, keepdims=True)
    L[L < 1e-12] = 1
    P = uq + (N / L) * off
    tri = inv.reshape(-1, 3)
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(x) for x in P], [], [tuple(int(i) for i in tr) for tr in tri])
    me.update()
    me.uv_layers.new(name="UVMap")
    me.materials.append(mat)
    for poly in me.polygons:
        poly.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    lo, hi = P.min(0), P.max(0)
    print("LAMPFX", name, len(tri), "tris", "mid", np.round((lo + hi) / 2, 3).tolist(), "size", np.round(hi - lo, 3).tolist())


for old in [o for o in bpy.data.objects if o.name.startswith("LampFx_")]:
    bpy.data.objects.remove(old, do_unlink=True)
for side, sx in (("L", 1), ("R", -1)):
    for role, pieces in job.items():
        tris, off = [], 0.004
        for pc in pieces:
            off = pc.get("off", off)
            uvr, absx, split, bx = pc.get("uv"), pc.get("absx"), pc.get("split"), pc.get("box")

            def keep(c, u, v, uvr=uvr, absx=absx, split=split, bx=bx):
                if uvr and not (uvr[0] <= u < uvr[1] and uvr[2] <= v < uvr[3]):
                    return False
                if absx and not (absx[0] <= abs(c.x) <= absx[1]):
                    return False
                if bx and not (bx[0] <= abs(c.x) <= bx[3] and bx[1] <= c.y <= bx[4] and bx[2] <= c.z <= bx[5]):
                    return False
                return not (split or bx) or c.x * sx > 0

            SIDE[0] = side
            for nd in nodes_for(pc):
                tris += faces(nd, keep if (uvr or absx or split or bx) else None)
        shell("LampFx_%s%s" % (role, side), tris, off)

for o in raw:
    bpy.data.objects.remove(o, do_unlink=True)
bpy.data.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)
bpy.ops.wm.save_as_mainfile(filepath=out)
print("LAMPFX saved", out)
