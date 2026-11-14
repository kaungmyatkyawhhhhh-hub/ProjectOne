"""toyoka_chaser_lampcut.py -- in.blend out.blend : straight edges for the Chaser JZX100's tail lamp shells (2026-11-14).

The model's red tail lens is one coarse piece a side (93 triangles over two round lamps and a band along the top), so the
slices tools/lamps/lampfx_glb.py picks by whole triangles came out jagged and overlapping. This cuts the lens itself (the
finished car's SeeThrough_Lens_Red, its biggest piece on each side), after lampfx_glb.py and before pack_cars.py:
  * Tail = the lens outside 0.598 m from the car's middle (over the outer round lamp);
  * Rev = the lens between 0.47 and 0.598 m, under 0.776 m (over the inner round lamp);
  * TurnR = the band over the inner lamp (0.47-0.598 m, over 0.776 m) and the lens's inner end (inside 0.47 m).
The front shells stay as lampfx_glb.py made them (the clear cover and the amber lens are their own pieces there).
Functions copied from bnw_m3_e92_lampcut.py.

    blender -b --python tools/logo_paint/toyoka_chaser_lampcut.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAT = bpy.data.materials["LampFx"]
OUT_X = 0.598
IN_X = 0.47
BAND_Z = 0.776


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


red = pieces(bpy.data.objects["SeeThrough_Lens_Red"])
Z = (0.0, 0.0, 1.0)
NZ = (0.0, 0.0, -1.0)
for side, sx in (("L", 1.0), ("R", -1.0)):
    ex = (sx, 0.0, 0.0)
    nx = (-sx, 0.0, 0.0)
    lens = max((p for p in red if p[0][1] > 2.0 and (p[0][0] + p[1][0]) * sx > 0), key=lambda p: len(p[2]))[2]
    whole = shell(lens, 0.004)
    inner = keep(whole, (OUT_X * sx, 0, 0), nx)
    mid = keep(inner, (IN_X * sx, 0, 0), ex)
    put("LampFx_Tail" + side, [keep(whole, (OUT_X * sx, 0, 0), ex)])
    put("LampFx_Rev" + side, [keep(mid, (0, 0, BAND_Z), NZ)])
    put("LampFx_TurnR" + side, [keep(mid, (0, 0, BAND_Z), Z), keep(inner, (IN_X * sx, 0, 0), nx)])
for o in list(bpy.data.objects):
    if o.type == "MESH" and len(o.data.polygons) == 0:
        print("LAMPCUT empty part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("LAMPCUT saved", a[1])
