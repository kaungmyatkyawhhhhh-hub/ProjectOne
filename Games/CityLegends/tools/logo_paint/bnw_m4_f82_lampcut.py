"""bnw_m4_f82_lampcut.py -- in.blend out.blend : straight edges for four of the F82's lamp shells (2026-11-12).

tools/lamps/lampfx_glb.py picks whole triangles, and this model's lamp glass is coarse (the headlamp cover is 170
triangles, the wing's red lens 382): a role that is a slice of a lens came out with teeth up to 4 cm long. This cuts
the triangles themselves, after lampfx_glb.py and before pack_cars.py:

  * LampFx_HeadGlass / LampFx_TurnF: the headlamp's cover cut along the lower edge of the eyebrow strip (the real
    car's indicator; the strip rises outwards, so the cut is a slanted plane through that edge, as seen from the
    front and a little above). Under it is HeadGlass, over it TurnF (the mirror's repeater stays in TurnF);
  * LampFx_TurnR: the wing lamp's red lens under 0.773 m (its bottom band, the real car's indicator);
  * LampFx_Rev: the boot-lid lamp's red lens under 0.773 m (its bottom band) and the clear cover of the model's
    reverse window, which sits in an opening of the red lens.

HeadCore and Tail are left as lampfx_glb.py made them. Last, the parts that finish_car.py's cuts left with no faces (the
four tyre valves) are taken out of the file. The shells are cut from the finished car's own glass parts
(SeeThrough_Lens_Clear / SeeThrough_Lens_Red), the same faces lampfx_glb.py takes from the .glb.

    blender -b --python tools/logo_paint/bnw_m4_f82_lampcut.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
MAT = bpy.data.materials["LampFx"]
# the eyebrow strip's lower edge on the left side (measured on the lamp housing): z = 0.5071 + 0.1588 x,
# y = -2.3061 + 0.5552 x; the cut runs 3 mm under it
EDGE_P = Vector((0.60, -2.3061 + 0.5552 * 0.60, 0.5071 + 0.1588 * 0.60 - 0.003))
EDGE_D = Vector((1.0, 0.5552, 0.1588)).normalized()
VIEW = Vector((0.2, -1.0, 0.2)).normalized()  # from the lamp towards a viewer in front, a little above and outside
BAND_Z = 0.773


def loose(obj, keep):
    """the loose pieces of a part whose middle passes keep(c): [(area, [world triangles])], biggest first"""
    M = obj.matrix_world
    assert M.determinant() > 0
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen, out = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        st, comp = [f], []
        seen.add(f.index)
        while st:
            g = st.pop()
            comp.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        st.append(h)
        pts = [M @ v.co for g in comp for v in g.verts]
        c = sum(pts, Vector()) / len(pts)
        if not keep(c):
            continue
        tris = []
        for g in comp:
            p = [M @ v.co for v in g.verts]
            for k in range(1, len(p) - 1):
                tris.append((p[0], p[k], p[k + 1]))
        out.append((sum(g.calc_area() for g in comp), tris))
    bm.free()
    return sorted(out, key=lambda r: -r[0])


def shell(tris, off):
    """a bmesh of the triangles, every point moved off metres along its smoothed normal (as lampfx_glb.py does)"""
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
    bm = bmesh.new()
    vs = [bm.verts.new(tuple(p)) for p in P]
    for tr in inv.reshape(-1, 3):
        if len({int(i) for i in tr}) == 3:
            try:
                bm.faces.new([vs[int(i)] for i in tr])
            except ValueError:
                pass
    return bm


def cut(bm, co, no, above):
    """a copy of the bmesh, only what lies above (or under) the plane"""
    b = bm.copy()
    bmesh.ops.bisect_plane(b, geom=b.verts[:] + b.edges[:] + b.faces[:], dist=1e-6, plane_co=co, plane_no=no, clear_inner=above, clear_outer=not above)
    return b


def put(name, bms, extra=()):
    old = bpy.data.objects.get(name)
    keep = []
    if old is not None:
        if extra:  # the old shell's faces that stay (the mirror's repeater in TurnF)
            for p in old.data.polygons:
                pts = [old.matrix_world @ old.data.vertices[i].co for i in p.vertices]
                if extra[0](sum(pts, Vector()) / len(pts)):
                    keep.append(pts)
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
    for pts in keep:
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
    print("LAMPCUT", name, n, "tris mid", np.round((P.min(0) + P.max(0)) / 2, 3).tolist(), "size", np.round(P.max(0) - P.min(0), 3).tolist())


clear = bpy.data.objects["SeeThrough_Lens_Clear"]
red = bpy.data.objects["SeeThrough_Lens_Red"]
for side, sx in (("L", 1.0), ("R", -1.0)):
    # the headlamp's cover: the biggest clear piece at the nose on this side
    cover = loose(clear, lambda c: c.x * sx > 0 and c.y < -1.5)[0][1]
    whole = shell(cover, 0.006)
    d = Vector((EDGE_D.x * sx, EDGE_D.y, EDGE_D.z))
    v = Vector((VIEW.x * sx, VIEW.y, VIEW.z))
    no = d.cross(v).normalized()
    if no.z < 0:
        no = -no
    co = Vector((EDGE_P.x * sx, EDGE_P.y, EDGE_P.z))
    put("LampFx_HeadGlass" + side, [cut(whole, co, no, False)])
    put("LampFx_TurnF" + side, [cut(whole, co, no, True)], extra=(lambda c: c.y > -1.5,))
    # the tail: the wing's lens is the biggest red piece on this side, the boot-lid's the next
    lens = loose(red, lambda c: c.x * sx > 0 and c.y > 1.5)
    up, down = Vector((0, 0, BAND_Z + 0.0)), Vector((0, 0, 1))
    put("LampFx_TurnR" + side, [cut(shell(lens[0][1], 0.009), up, down, False)])
    # (the red lens has an opening over the model's clear reverse window: the window's own clear cover fills it)
    win = max(loose(clear, lambda c: 0.38 <= c.x * sx <= 0.53 and 2.28 <= c.y <= 2.34 and 0.75 <= c.z <= 0.77), key=lambda r: r[0])[1]
    put("LampFx_Rev" + side, [cut(shell(lens[1][1], 0.009), up, down, False), shell(win, 0.009)])
# the four tyre-valve parts (FL/FR/RL/RR_static_Rim): finish_car.py cut all their faces (the kit wheels bring their own
# valve; the model's would float), which leaves empty meshes: out, so the pack carries no part without faces
for o in list(bpy.data.objects):
    if o.type == "MESH" and len(o.data.polygons) == 0:
        print("LAMPCUT empty part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("LAMPCUT saved", a[1])
