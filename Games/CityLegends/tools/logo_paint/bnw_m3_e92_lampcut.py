"""bnw_m3_e92_lampcut.py -- in.blend out.blend : straight edges for the E92 GTS's lamp shells (2026-11-13).

tools/lamps/lampfx_glb.py picks whole triangles, and this model's lamp glass is coarse (the headlamp cover is 100
triangles, the wing lamp's 163, the boot lid's 102): the roles that are slices of a lens came out with teeth (the
2026-11-09 pack). This cuts the triangles themselves, after lampfx_glb.py and before pack_cars.py:

  * LampFx_HeadGlass / LampFx_TurnF: the headlamp's cover cut by an upright plane 0.69 m from the car's middle. Inside it
    is HeadGlass (over the two rings), outside it TurnF (over the amber corner). TurnF keeps what the lamp job gave it
    (the amber corner piece in the lamp, the gill's strip and its cover);
  * LampFx_Tail / LampFx_TurnR: the wing lamp's cover cut level at 0.818 m (just under the lowest light bar). Over it
    is Tail, under it TurnR (the bottom band over the model's indicator strip);
  * LampFx_Tail / LampFx_Rev: the boot-lid lamp's cover with the reverse lamp's window cut out of it as a rectangle
    (0.410 to 0.515 m from the middle, 0.885 to 0.925 m up): the rectangle is Rev, the rest Tail. Tail also keeps the
    light bars the lamp job gave it.

HeadCore is left as lampfx_glb.py made it. The shells are cut from the finished car's own glass parts
(SeeThrough_Lens_Clear), the same faces lampfx_glb.py takes from the .glb.

    blender -b --python tools/logo_paint/bnw_m3_e92_lampcut.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAT = bpy.data.materials["LampFx"]
HEAD_X = 0.69
BAND_Z = 0.818
REV = (0.410, 0.515, 0.885, 0.925)  # x0, x1 (from the middle), z0, z1


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


clear = pieces(bpy.data.objects["SeeThrough_Lens_Clear"])
Z = (0.0, 0.0, 1.0)
for side, sx in (("L", 1.0), ("R", -1.0)):
    ex = (sx, 0.0, 0.0)
    nx = (-sx, 0.0, 0.0)
    # the headlamp's cover: the biggest clear piece at the nose on this side
    cover = max((p for p in clear if p[1][1] < -1.5 and (p[0][0] + p[1][0]) * sx > 0), key=lambda p: len(p[2]))[2]
    whole = shell(cover, 0.006)
    put("LampFx_HeadGlass" + side, [keep(whole, (HEAD_X * sx, 0, 0), nx)])
    put("LampFx_TurnF" + side, [keep(whole, (HEAD_X * sx, 0, 0), ex)], keep_old=lambda c: True)
    # the tail: each lamp has a clear cover over its red lens, and the red lens has an opening over the indicator's
    # window, so the slices are cut from the clear cover (whole). The wing's reaches further out than 0.7 m, the boot
    # lid's does not (the number-plate lamps' small covers are smaller pieces)
    back = [p for p in clear if p[0][1] > 1.9 and (p[0][0] + p[1][0]) * sx > 0 and p[1][2] < 1.0]
    wing = max((p for p in back if max(abs(p[0][0]), abs(p[1][0])) > 0.7), key=lambda p: len(p[2]))[2]
    lid = max((p for p in back if max(abs(p[0][0]), abs(p[1][0])) < 0.6), key=lambda p: len(p[2]))[2]
    w = shell(wing, 0.007)
    l = shell(lid, 0.007)
    x0, x1, z0, z1 = REV
    mid = keep(keep(l, (x0 * sx, 0, 0), ex), (x1 * sx, 0, 0), nx)
    tail = [keep(w, (0, 0, BAND_Z), Z), keep(l, (x0 * sx, 0, 0), nx), keep(l, (x1 * sx, 0, 0), ex), keep(mid, (0, 0, z1), Z), keep(mid, (0, 0, z0), (0, 0, -1.0))]
    put("LampFx_Tail" + side, tail, keep_old=lambda c: True)
    # (TurnR and Rev are the lens's own slices only: the housing pieces the lamp job picked behind them reach past the
    #  straight edges, and a lit shell under a dark one shows through it)
    put("LampFx_TurnR" + side, [keep(w, (0, 0, BAND_Z), (0, 0, -1.0))])
    put("LampFx_Rev" + side, [keep(keep(mid, (0, 0, z0), Z), (0, 0, z1), (0, 0, -1.0))])
for o in list(bpy.data.objects):
    if o.type == "MESH" and len(o.data.polygons) == 0:
        print("LAMPCUT empty part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("LAMPCUT saved", a[1])
