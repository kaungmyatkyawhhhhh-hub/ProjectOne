"""toyoka_supra_mk4_lampcut.py -- in.blend out.blend : straight edges for the 1994 Supra's tail lamp shells (2026-11-14).

tools/lamps/lampfx_glb.py picks whole triangles, and this model's tail lamp cover is coarse (one smoked clear cover per side
over four rounds, long triangles): the three slices of it (Rev / Tail / TurnR) came out with teeth that reached over the
next round. This cuts the cover's triangles themselves by two upright planes, after lampfx_glb.py and before pack_cars.py:
from the car's middle out, |x| < 0.312 m = Rev (over the clear reverse round), 0.312 - 0.505 = Tail (over the two red
rounds), > 0.505 = TurnR (over the amber round). The cover is the biggest SeeThrough_Window piece at the tail on each side,
the same faces lampfx_glb.py takes from the .glb. The headlamp's shells (HeadCore, HeadGlass) and TurnF are left as
lampfx_glb.py made them (a whole cover / whole lenses: no slice).

    blender -b --python tools/logo_paint/toyoka_supra_mk4_lampcut.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAT = bpy.data.materials["LampFx"]
REV_X = 0.312   # the clear reverse round | the two red rounds
TURN_X = 0.505  # the two red rounds | the amber round


def pieces(obj):
    """the loose pieces of a part (points welded by place first): [(lo, hi, [world triangles])]"""
    me = obj.data
    M = np.array(obj.matrix_world)
    assert np.linalg.det(M[:3, :3]) > 0
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
    key = np.unique(np.round(co, 4), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(key.max()) + 1))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    polys = [list(p.vertices) for p in me.polygons]
    for vs in polys:
        r = find(key[vs[0]])
        for v in vs[1:]:
            par[find(key[v])] = r
    groups = {}
    for vs in polys:
        g = groups.setdefault(find(key[vs[0]]), [])
        for k in range(1, len(vs) - 1):
            g.append((co[vs[0]], co[vs[k]], co[vs[k + 1]]))
    out = []
    for tris in groups.values():
        P = np.array(tris).reshape(-1, 3)
        out.append((P.min(0), P.max(0), tris))
    return out


def shell(tris, off):
    """a bmesh of the triangles, every point moved off metres along its smoothed normal (as lampfx_glb.py does)"""
    V = np.array(tris).reshape(-1, 3)
    T = np.arange(len(V)).reshape(-1, 3)
    uq, inv = np.unique(np.round(V, 4), axis=0, return_inverse=True)
    inv = inv.reshape(-1)
    N = np.zeros((len(uq), 3))
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for i in range(3):
        np.add.at(N, inv[T[:, i]], fn)
    L = np.linalg.norm(N, axis=1, keepdims=True)
    L[L < 1e-12] = 1
    N = N / L
    # (a lamp's glass faces out of the car: away from the car's middle line or along the car's length)
    c = uq.mean(0)
    out_dir = np.array([np.sign(c[0]) * 0.6, np.sign(c[1]) * 0.8, 0.0])
    if (N @ out_dir).mean() < 0:
        N = -N
    P = uq + N * off
    bm = bmesh.new()
    vs = [bm.verts.new(tuple(p)) for p in P]
    for tr in inv.reshape(-1, 3):
        if len({int(i) for i in tr}) == 3:
            try:
                bm.faces.new([vs[int(i)] for i in tr])
            except ValueError:
                pass
    return bm


def keep(bm, co, no):
    """a copy of the bmesh, only what lies on the side of the plane its normal points to"""
    b = bm.copy()
    bmesh.ops.bisect_plane(b, geom=b.verts[:] + b.edges[:] + b.faces[:], dist=1e-6, plane_co=Vector(co), plane_no=Vector(no), clear_inner=True, clear_outer=False)
    return b


def put(name, bms, keep_old=None):
    old = bpy.data.objects.get(name)
    kept = []
    if old is not None:
        if keep_old:  # the old shell's faces that stay
            for p in old.data.polygons:
                pts = [old.matrix_world @ old.data.vertices[i].co for i in p.vertices]
                if keep_old(sum(pts, Vector()) / len(pts)):
                    kept.append(pts)
        gone = old.data
        bpy.data.objects.remove(old, do_unlink=True)
        bpy.data.meshes.remove(gone)
    out = bmesh.new()
    for b in bms:
        vmap = {}
        for f in b.faces:
            for v in f.verts:
                if v not in vmap:
                    vmap[v] = out.verts.new(v.co)
            out.faces.new([vmap[v] for v in f.verts])
    for pts in kept:
        out.faces.new([out.verts.new(p) for p in pts])
    bmesh.ops.triangulate(out, faces=out.faces[:])
    me = bpy.data.meshes.new(name)
    out.to_mesh(me)
    n = len(out.faces)
    out.free()
    me.uv_layers.new(name="UVMap")
    me.materials.append(MAT)
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    P = np.array([list(v.co) for v in me.vertices])
    print("LAMPCUT", name, n, "tris (kept from the lamp job:", len(kept), ") mid", np.round((P.min(0) + P.max(0)) / 2, 3).tolist(), "size", np.round(P.max(0) - P.min(0), 3).tolist())


win = pieces(bpy.data.objects["SeeThrough_Window"])
for side, sx in (("L", 1.0), ("R", -1.0)):
    ex = (sx, 0.0, 0.0)
    nx = (-sx, 0.0, 0.0)
    back = [p for p in win if p[0][1] > 1.9 and (p[0][0] + p[1][0]) * sx > 0 and p[1][2] < 1.0 and p[0][2] > 0.7 and max(abs(p[0][0]), abs(p[1][0])) < 0.7]
    cover = max(back, key=lambda p: len(p[2]))
    print("LAMPCUT tail cover", side, len(cover[2]), "tris box", np.round(cover[0], 3).tolist(), np.round(cover[1], 3).tolist())
    c = shell(cover[2], 0.006)
    put("LampFx_Rev" + side, [keep(c, (REV_X * sx, 0, 0), nx)])
    put("LampFx_Tail" + side, [keep(keep(c, (REV_X * sx, 0, 0), ex), (TURN_X * sx, 0, 0), nx)])
    put("LampFx_TurnR" + side, [keep(c, (TURN_X * sx, 0, 0), ex)])
for o in list(bpy.data.objects):
    if o.type == "MESH" and len(o.data.polygons) == 0:
        print("LAMPCUT empty part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("LAMPCUT saved", a[1])
