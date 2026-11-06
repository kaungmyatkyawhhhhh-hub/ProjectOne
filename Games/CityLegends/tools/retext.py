"""
Real names in a model's shape (owner, 2026-11-06: "I dont want to cover, I want to remove those old text and replace with
fake names", "in the same exact place"). Many cars' letters are not stuck on: the paint has a hole the shape of the
letters and a black piece fills it. So the old letters' faces move to a new paint part (the hole closes, in the car's
colour, Customs paints it), and new letters are built from a font and laid on the surface where the old ones were, in
the same part, so they get the same colour.

    blender -b --factory-startup --python tools/retext.py -- tools/logo_paint/retext/<car id>.json

job: {
  "source": car .blend, or the pack .fbx with "root": the car's group in it
  "offset": [x, y, z] of the car in the file (a pack), default 0
  "ops": [
    {"op": "move", "part": "Body_Trim2", "to": "Body_Paint_Fill", "boxes": [[x0, y0, z0, x1, y1, z1], ...], "mirror": true},
        pieces all inside a box leave the part for a new part "to"
    {"op": "drop", "part": ..., "boxes": ..., "mirror": ...}      pieces are deleted (nothing under them needs closing)
    {"op": "text", "part": "Body_Trim2", "text": "ZV", "o": [x, y, z], "u": [..], "v": [..], "ray": [-1, 0, 0],
     "on": ["Body_Paint", "Body_Paint_Fill"], "uv": [0.04, 0.82], "lift": 0.017, "mirror": true, "font": path}
        o = the text's bottom left as you read it, u = along it to the bottom right, v = up to the top left. "mirror": the
        same on the other side, still reading left to right
  ],
    {"op": "skin", "to": new part, "like": part, "on": [...], "o", "u", "v", "ray", "mirror"}  a smooth sheet over a hole, or over
        letters cut through a part: height, normals and picture position are fitted to the surface round it, so it shows no
        edge. "v2": v at the far end (a sheet that widens). "ring": [s, t] how far round it to read the surface, in sheet
        lengths, "gap": [s, t] what to skip at its edge (-1: read inside too, for a stencil). "uv": one fixed spot instead.
    {"op": "fill", "part": ..., "boxes": [...], "max_span": 0.3, "mirror": true}  closes letter shaped holes in a part's own mesh: open loops in
        the box no longer than max_span. The best way: the same mesh, with picture position and corner colours from the hole's edge. These models
        carry baked shade as corner colours and Studio shows them: a plain sheet or a part comes out brighter than the door round it.
    {"op": "cut", "part": ..., "boxes": [island's box], "x": [x0, x1]}, {"op": "plate", ...}  a piece of a sheet goes, a plain one takes its place
  "export": ["Body_Trim2", "Body_Paint_Fill"],
  "names": {"Part#123": "A"}   parts of one name need names of their own in the file; the report's "part" keeps the real one
  "out": "imports/retext/<car id>.fbx"
}
Metres, the car's layout: front -Y, up +Z, ground 0. Roblox model space is (-x, z, y).
Writes the FBX and <out>.json (each part's box before and after, for tools/riviera/.. RetextApply.luau).
"""
import json
import os
import re
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FONT = "C:/Windows/Fonts/arialbi.ttf"

job = json.load(open(sys.argv[sys.argv.index("--") + 1], encoding="utf-8"))
src = job["source"]
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=src)
OFF = Vector(job.get("offset", (0, 0, 0)))


def base(n):
    return re.sub(r"\.\d+$", "", n)


pool = {}
if job.get("root"):
    r = bpy.data.objects[job["root"]]
    for o in r.children_recursive:
        if o.type == "MESH":
            pool.setdefault(base(o.name), []).append(o)
else:
    for o in bpy.data.objects:
        if o.type == "MESH":
            pool.setdefault(o.name, []).append(o)


found = {}


def part(name):
    # ("name#faces": parts of one name told apart by their face count before any change)
    if name in found:
        return found[name]
    if name in bpy.data.objects:
        found[name] = bpy.data.objects[name]
        return found[name]
    key, faces = name, None
    if "#" in name:
        key, faces = name.split("#")
    lst = pool[key]
    if faces:
        lst = [o for o in lst if len(o.data.polygons) == int(faces)]
    found[name] = lst[0]
    return lst[0]


def box_of(o):
    # (only points of faces: Studio's mesh has no loose points, and a box with them puts a new part off by mm)
    M = o.matrix_world
    me = o.data
    used = sorted({v for pl in me.polygons for v in pl.vertices})
    p = np.array([tuple(M @ me.vertices[i].co) for i in used]) - np.array(tuple(OFF))
    return p.min(0).tolist(), p.max(0).tolist()


before = {}
for n in job["export"]:
    if n.split("#")[0] in pool or n in bpy.data.objects:
        before[n] = box_of(part(n))
for k, n in job.get("like", {}).items():
    before[n] = box_of(part(n))


def boxes_of(op):
    out = [np.array(b, float) + np.array(tuple(OFF) * 2) for b in op["boxes"]]
    if op.get("mirror"):
        for b in list(out):
            ox = OFF.x * 2
            out.append(np.array([ox - b[3], b[1], b[2], ox - b[0], b[4], b[5]]))
    return out


def take(op):
    """the pieces of a part inside the boxes: removed from the part, returned as faces"""
    o = part(op["part"])
    me = o.data
    me.update()
    normals = [tuple(n.vector) for n in me.corner_normals]
    M = o.matrix_world
    N = M.to_3x3().inverted().transposed()
    uvl = me.uv_layers.active
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    co = np.array([tuple(M @ v.co) for v in bm.verts])
    seen = np.zeros(len(bm.verts), bool)
    kill = set()
    count = 0
    limit = op.get("max_faces", 100000)
    for v in bm.verts:
        if seen[v.index]:
            continue
        stack, comp = [v], []
        seen[v.index] = True
        while stack:
            x = stack.pop()
            comp.append(x.index)
            for e in x.link_edges:
                y = e.other_vert(x)
                if not seen[y.index]:
                    seen[y.index] = True
                    stack.append(y)
        p = co[comp]
        lo, hi = p.min(0), p.max(0)
        for b in boxes_of(op):
            if np.all(lo >= b[:3]) and np.all(hi <= b[3:]):
                kill.update(comp)
                count += 1
                break
    faces = []
    for f in me.polygons:
        if f.vertices[0] in kill:
            loops = []
            for li in f.loop_indices:
                vi = me.loops[li].vertex_index
                uv = uvl.data[li].uv if uvl else (0, 0)
                n = N @ Vector(normals[li])
                n.normalize()
                loops.append((tuple(co[vi]), (uv[0], uv[1]), tuple(n)))
            faces.append(loops)
    bmesh.ops.delete(bm, geom=[bm.verts[i] for i in kill], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    print("RETEXT took", op["part"], "islands", count, "faces", len(faces))
    return faces, o


def new_part(name, faces, like):
    idx, verts, polys, uvs, nor, cols = {}, [], [], [], [], []
    for f in faces:
        ids = []
        for corner in f:
            co, uv, n = corner[:3]
            k = tuple(round(c, 6) for c in co)
            if k not in idx:
                idx[k] = len(verts)
                verts.append(co)
            ids.append(idx[k])
            uvs.append(uv)
            nor.append(n)
            cols.append(corner[3] if len(corner) > 3 else None)
        polys.append(ids)
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], polys)
    layer = me.uv_layers.new(name="UVMap")
    for i, uv in enumerate(uvs):
        layer.data[i].uv = uv
    if cols and cols[0] is not None:
        ca = me.color_attributes.new("Color", "BYTE_COLOR", "CORNER")
        for i, c_ in enumerate(cols):
            ca.data[i].color = c_
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    me.update()
    me.normals_split_custom_set(nor)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if like.data.materials:
        me.materials.append(like.data.materials[0])
    pool[name] = [ob]
    return ob


SURF = {}


def surface(names):
    verts, tris, info = [], [], []
    if names == ["*"]:
        names = [o for lst in pool.values() for o in lst]
    for n in names:
        o = part(n) if isinstance(n, str) else n
        M = o.matrix_world
        base_i = len(verts)
        verts += [M @ v.co for v in o.data.vertices]
        o.data.calc_loop_triangles()
        for t in o.data.loop_triangles:
            tris.append((t.vertices[0] + base_i, t.vertices[1] + base_i, t.vertices[2] + base_i))
            info.append((o, tuple(t.loops), t.polygon_index))
    bvh = BVHTree.FromPolygons(verts, tris, all_triangles=True)
    SURF[id(bvh)] = (verts, tris, info)
    return bvh


def sample(bvh, hit, idx):
    """the smooth normal and the picture position at a hit"""
    verts, tris, info = SURF[id(bvh)]
    a, b, c = (verts[i] for i in tris[idx])
    v0, v1, v2 = b - a, c - a, hit - a
    d00, d01, d11, d20, d21 = v0.dot(v0), v0.dot(v1), v1.dot(v1), v2.dot(v0), v2.dot(v1)
    d = d00 * d11 - d01 * d01
    w1 = (d11 * d20 - d01 * d21) / d if d else 0
    w2 = (d00 * d21 - d01 * d20) / d if d else 0
    w = (1 - w1 - w2, w1, w2)
    o, loops = info[idx][:2]
    me = o.data
    N = o.matrix_world.to_3x3().inverted().transposed()
    uvl = me.uv_layers.active
    n = Vector((0, 0, 0))
    uv = [0.0, 0.0]
    ca = me.color_attributes[0] if me.color_attributes and me.color_attributes[0].domain == "CORNER" else None
    col = [0.0, 0.0, 0.0, 0.0]
    for wi, li in zip(w, loops):
        n += (N @ Vector(me.corner_normals[li].vector)) * wi
        if uvl:
            q = uvl.data[li].uv
            uv[0] += q[0] * wi
            uv[1] += q[1] * wi
        c_ = ca.data[li].color if ca else (1, 1, 1, 1)
        for i in range(4):
            col[i] += c_[i] * wi
    return n.normalized(), uv, col


def glyphs(text, font_path):
    cu = bpy.data.curves.new("t", "FONT")
    cu.body = text
    cu.font = bpy.data.fonts.load(font_path, check_existing=True)
    cu.resolution_u = 3
    ob = bpy.data.objects.new("t", cu)
    bpy.context.scene.collection.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    return me


def lay(op, o_, u_, v_, ray, bvh, target):
    o_, u_, v_, ray = Vector(o_), Vector(u_), Vector(v_), Vector(ray).normalized()
    src_me = glyphs(op["text"], op.get("font", FONT))
    bm = bmesh.new()
    bm.from_mesh(src_me)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    lu, lv = u_.length, v_.length
    for v in bm.verts:
        v.co = Vector(((v.co.x - x0) / (x1 - x0) * lu, (v.co.y - y0) / (y1 - y0) * lv, 0))
    # small enough to follow the curve of the body
    limit = op.get("edge", max(lu, lv) / 22)
    for _ in range(6):
        longs = [e for e in bm.edges if e.calc_length() > limit]
        if not longs:
            break
        bmesh.ops.subdivide_edges(bm, edges=longs, cuts=1, use_grid_fill=False)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
    lift = op.get("lift", 0.017)
    M = target.matrix_world
    Mi = M.inverted()
    tb = bmesh.new()
    tb.from_mesh(target.data)
    uvl = tb.loops.layers.uv.active or tb.loops.layers.uv.new("UVMap")
    missed = 0
    nv = {}
    for v in bm.verts:
        p = o_ + u_ * (v.co.x / lu) + v_ * (v.co.y / lv) + OFF
        hit, n, _, _ = bvh.ray_cast(p - ray * 0.3, ray, 0.7)
        if hit is None:
            missed += 1
            hit, n, _, _ = bvh.find_nearest(p)
        if n.dot(ray) > 0:
            n = -n
        nv[v.index] = tb.verts.new(Mi @ (hit + n * lift))
    for f in bm.faces:
        ids = [nv[v.index] for v in f.verts]
        a, b, c = [(M @ q.co) for q in ids[:3]]
        if (b - a).cross(c - a).dot(ray) > 0:
            ids.reverse()
        try:
            nf = tb.faces.new(ids)
        except ValueError:
            continue
        nf.smooth = False
        for lp in nf.loops:
            lp[uvl].uv = op.get("uv", (0.5, 0.5))
    tb.to_mesh(target.data)
    tb.free()
    bm.free()
    print("RETEXT text", op["text"], "faces", len(nv), "missed", missed)


def skin_faces(op, o_, u_, v_, ray, bvh, v2=None):
    """a smooth sheet: the surface round it, fitted (quadratics: height, normal, picture position), laid over it"""
    o_, u_, v_, ray = Vector(o_) + OFF, Vector(u_), Vector(v_), Vector(ray).normalized()
    w_ = (Vector(v2) if v2 else v_) - v_

    def plane(s, t):
        return o_ + u_ * s + (v_ + w_ * s) * t

    def basis(s, t):
        return (1, s, t, s * s, s * t, t * t)

    sm, tm = op.get("ring", (0.6, 1.2))
    gs, gt = op.get("gap", (0.03, 0.1))
    A, H, Ns, Us, Cs = [], [], [], [], []
    for i in range(90):
        for j in range(60):
            s, t = -sm + (1 + 2 * sm) * i / 89, -tm + (1 + 2 * tm) * j / 59
            if gs >= 0 and -gs < s < 1 + gs and -gt < t < 1 + gt:
                continue
            hit, n, idx, _ = bvh.ray_cast(plane(s, t) - ray * 0.3, ray, 0.7)
            if hit is None or n.dot(ray) > 0:
                continue
            nn, uv, col = sample(bvh, hit, idx)
            if nn.dot(ray) > 0:
                nn = -nn
            A.append(basis(s, t))
            H.append((hit - plane(s, t)).dot(ray))
            Ns.append(tuple(nn))
            Us.append(uv)
            Cs.append(col)
    A, H, Ns, Us, Cs = np.array(A), np.array(H), np.array(Ns), np.array(Us), np.array(Cs)
    keep = np.ones(len(H), bool)
    for _ in range(5):
        c = np.linalg.lstsq(A[keep], H[keep], rcond=None)[0]
        r = np.abs(A @ c - H)
        keep = r < max(0.003, np.median(r) * 3)
    kn = keep.copy()
    for _ in range(5):
        cn = np.linalg.lstsq(A[kn], Ns[kn], rcond=None)[0]
        r = np.abs(A @ cn - Ns).max(1)
        kn = keep & (r < max(0.02, np.median(r[keep]) * 3))
    cc = np.linalg.lstsq(A[kn], Cs[kn], rcond=None)[0]
    # a tiled picture jumps between islands: the biggest set that fits one flat mapping
    B = A[:, :3]
    idx = np.flatnonzero(keep)
    rng = np.random.default_rng(1)
    best = keep & False
    for _ in range(400):
        q = rng.choice(idx, 3, replace=False)
        if abs(np.linalg.det(B[q])) < 1e-6:
            continue
        m = np.linalg.solve(B[q], Us[q])
        ok = keep & (np.abs(B @ m - Us).max(1) < 0.02)
        if ok.sum() > best.sum():
            best = ok
    cu = np.linalg.lstsq(B[best], Us[best], rcond=None)[0]
    print("RETEXT skin fit", int(keep.sum()), "of", len(H), "err", round(float(np.abs(A[keep] @ c - H[keep]).max()), 5),
          "normal err", round(float(np.abs(A[kn] @ cn - Ns[kn]).max()), 3), "of", int(kn.sum()), "uv of", int(best.sum()))
    lift = op.get("lift", 0.0015)
    nu, nv = op.get("n", (30, 10))
    fixed = op.get("uv")

    def point(s, t):
        b_ = np.array(basis(s, t))
        n = Vector(tuple(b_ @ cn)).normalized()
        uv = tuple(fixed) if fixed else tuple(b_[:3] @ cu)
        return tuple(plane(s, t) + ray * float(b_ @ c) - ray * lift), uv, tuple(n), tuple(np.clip(b_ @ cc, 0, 1))

    faces = []
    for i in range(nu):
        for j in range(nv):
            f = []
            for a_, b_ in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)):
                f.append(point(a_ / nu, b_ / nv))
            P = [Vector(x[0]) for x in f]
            if (P[1] - P[0]).cross(P[2] - P[0]).dot(ray) > 0:
                f.reverse()
            faces.append(f)
    return faces


def op_fill(op):
    """letter shaped holes in a part close: its own mesh, its own normals, picture position from the hole's edge"""
    o = part(op["part"])
    M = o.matrix_world
    Mi3 = M.inverted().to_3x3()
    span = op.get("max_span", 0.3)
    # "like_at": {"from", "dir"}: every new face takes the look of the face this ray hits (a hole with a bevel round it: its edge is no guide)
    like_face = {}
    if "like_at" in op:
        bvh = surface([op["part"]])
        for side in (1, -1) if op.get("mirror") else (1,):
            f_, d_ = Vector(op["like_at"]["from"]), Vector(op["like_at"]["dir"])
            f_.x, d_.x = f_.x * side, d_.x * side
            hit, _, idx, _ = bvh.ray_cast(f_ + OFF, d_.normalized(), 0.7)
            like_face[side] = SURF[id(bvh)][2][idx][2]
    for bi, box in enumerate(boxes_of(op)):
        bm = bmesh.new()
        bm.from_mesh(o.data)
        mark = bm.faces.layers.int.new("fill_mark")
        uvl = bm.loops.layers.uv.active
        # (colours kept per corner: on these models they shade the paint, and Studio shows them)
        cols = list(bm.loops.layers.color.values()) + list(bm.loops.layers.float_color.values())

        def inside(v):
            c = np.array(tuple(M @ v.co))
            return np.all(c >= box[:3]) and np.all(c <= box[3:])

        open_ = [e for e in bm.edges if e.is_boundary and inside(e.verts[0]) and inside(e.verts[1])]
        # open edges into loops
        at = {}
        for e in open_:
            for v in e.verts:
                at.setdefault(v, []).append(e)
        seen, take_ = set(), []
        loops = 0
        for e in open_:
            if e in seen:
                continue
            stack, comp = [e], []
            seen.add(e)
            while stack:
                x = stack.pop()
                comp.append(x)
                for v in x.verts:
                    for y in at[v]:
                        if y not in seen:
                            seen.add(y)
                            stack.append(y)
            # (a stray open edge can hang off a hole: only what closes counts)
            comp = set(comp)
            while True:
                deg = {}
                for x in comp:
                    for v in x.verts:
                        deg[v] = deg.get(v, 0) + 1
                ends = {x for x in comp if deg[x.verts[0]] == 1 or deg[x.verts[1]] == 1}
                if not ends:
                    break
                comp -= ends
            if not comp:
                continue
            pts = np.array([tuple(M @ v.co) for x in comp for v in x.verts])
            size = pts.max(0) - pts.min(0)
            if size.max() <= span:
                take_ += list(comp)
                loops += 1
        if not take_:
            bm.free()
            print("RETEXT fill: no holes in", box)
            continue
        out = None
        if "axis" in op:
            # (which way is out, for a hole with a bevel round it: the faces beside it are no guide)
            ax = Vector(op["axis"])
            if bi > 0:
                ax.x = -ax.x
            out = (Mi3 @ ax).normalized()
        r = bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=take_, **({"normal": out} if out else {}))
        faces = [q for q in r["geom"] if isinstance(q, bmesh.types.BMFace)]
        bmesh.ops.recalc_face_normals(bm, faces=faces)
        ref = None
        for f in faces:
            f.smooth = True
            for e in f.edges:
                for g in e.link_faces:
                    if g not in faces:
                        ref = g.normal
        if out is not None:
            ref = out
        if ref is not None:
            for f in faces:
                if f.normal.dot(ref) < 0:
                    f.normal_flip()
        new = set(faces)
        one = None
        src = None
        if like_face:
            bm.faces.ensure_lookup_table()
            src = bm.faces[like_face[1 if bi == 0 else -1]].loops[0]
        for f in faces:
            for lp in f.loops:
                if src is not None:
                    if uvl:
                        lp[uvl].uv = src[uvl].uv
                    for c in cols:
                        lp[c] = src[c]
                    continue
                for q in lp.vert.link_loops:
                    if q.face not in new:
                        if uvl:
                            if op.get("flat_uv"):
                                # (a picture whose faces each sit on their own spot: one spot, no stretch across the sheet)
                                one = one or q[uvl].uv.copy()
                                lp[uvl].uv = one
                            else:
                                lp[uvl].uv = q[uvl].uv
                        for c in cols:
                            lp[c] = q[c]
                        break
        # the normals at the hole's edge: what the faces round it use
        o.data.update()
        vn = {}
        for pl in o.data.polygons:
            for li in pl.loop_indices:
                vn.setdefault(o.data.loops[li].vertex_index, tuple(o.data.corner_normals[li].vector))
        for f in faces:
            f[mark] = 1
        bm.to_mesh(o.data)
        bm.free()
        me = o.data
        me.update()
        marks = [a_.value for a_ in me.attributes["fill_mark"].data]
        nor = [tuple(n.vector) for n in me.corner_normals]
        for pl in me.polygons:
            if marks[pl.index]:
                for li in pl.loop_indices:
                    v = me.loops[li].vertex_index
                    if v in vn:
                        nor[li] = vn[v]
        me.attributes.remove(me.attributes["fill_mark"])
        if not op.get("auto_normals"):
            me.normals_split_custom_set(nor)
        print("RETEXT fill", op["part"], "holes", loops, "faces", len(faces))


def op_cut(op):
    """the part of one island between two x goes (a sheet with letters cut out of it)"""
    o = part(op["part"])
    M = o.matrix_world
    Mi = M.inverted()
    bm = bmesh.new()
    bm.from_mesh(o.data)
    box = boxes_of(op)[0]
    bm.verts.ensure_lookup_table()
    seen, geom = set(), None
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, comp = [v], []
        seen.add(v.index)
        while stack:
            x = stack.pop()
            comp.append(x)
            for e in x.link_edges:
                y = e.other_vert(x)
                if y.index not in seen:
                    seen.add(y.index)
                    stack.append(y)
        p = np.array([tuple(M @ q.co) for q in comp])
        if np.all(p.min(0) >= box[:3]) and np.all(p.max(0) <= box[3:]) and len(comp) >= op.get("min_verts", 30):
            geom = comp
            break
    faces = {f for v in geom for f in v.link_faces}
    edges = {e for v in geom for e in v.link_edges}
    g = list(geom) + list(edges) + list(faces)
    for x in op["x"]:
        r = bmesh.ops.bisect_plane(bm, geom=g, plane_co=Mi @ Vector((x + OFF.x, 0, 0)), plane_no=(Mi.to_3x3() @ Vector((1, 0, 0))).normalized())
        keep_ = {q for q in g if q.is_valid} | set(r["geom"])
        for q in r["geom"]:
            if isinstance(q, bmesh.types.BMEdge):
                keep_ |= set(q.link_faces)
        keep_ |= {e for f in keep_ if isinstance(f, bmesh.types.BMFace) for e in f.edges}
        keep_ |= {v for f in keep_ if isinstance(f, bmesh.types.BMFace) for v in f.verts}
        g = list(keep_)
    x0, x1 = min(op["x"]) + OFF.x, max(op["x"]) + OFF.x
    mine = {q for q in g if isinstance(q, bmesh.types.BMFace) and q.is_valid}
    kill = []
    sample = None
    for f in mine:
        c = M @ f.calc_center_median()
        if x0 < c.x < x1:
            kill.append(f)
        elif sample is None:
            sample = f
    uvl = bm.loops.layers.uv.active
    uv = tuple(sample.loops[0][uvl].uv) if sample is not None and uvl is not None else (0.5, 0.5)
    print("RETEXT cut", len(kill), "faces, uv", uv)
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    bm.to_mesh(o.data)
    bm.free()
    return uv


def op_plate(op, uv):
    """a thin strip, bowed like the sheet it replaces, in the same part"""
    o = part(op["part"])
    Mi = o.matrix_world.inverted()
    ou, uu, vv = Vector(op["o"]) + OFF, Vector(op["u"]), Vector(op["v"])
    n = 16
    bm = bmesh.new()
    bm.from_mesh(o.data)
    uvl = bm.loops.layers.uv.active or bm.loops.layers.uv.new("UVMap")
    rows = []
    for i in range(n + 1):
        s = i / n
        d = Vector(op["bow"]) * (1 - (2 * s - 1) ** 2)
        rows.append((bm.verts.new(Mi @ (ou + uu * s + d)), bm.verts.new(Mi @ (ou + uu * s + vv + d))))
    ray = Vector(op["ray"])
    for i in range(n):
        q = [rows[i][0], rows[i + 1][0], rows[i + 1][1], rows[i][1]]
        w = [o.matrix_world @ x.co for x in q]
        if (w[1] - w[0]).cross(w[2] - w[0]).dot(ray) > 0:
            q.reverse()
        f = bm.faces.new(q)
        f.smooth = False
        for lp in f.loops:
            lp[uvl].uv = uv
    bm.to_mesh(o.data)
    bm.free()


last_uv = (0.5, 0.5)
for op in job["ops"]:
    if op["op"] in ("move", "drop"):
        faces, o = take(op)
        if op["op"] == "move":
            new_part(op["to"], faces, part(op.get("like", op["part"])))
    elif op["op"] == "fill":
        op_fill(op)
    elif op["op"] == "cut":
        last_uv = op_cut(op)
    elif op["op"] == "plate":
        op_plate(op, last_uv)
    elif op["op"] == "skin":
        bvh = surface(op["on"])
        faces = skin_faces(op, op["o"], op["u"], op["v"], op["ray"], bvh, op.get("v2"))
        if op.get("mirror"):
            o, u, v, ray = Vector(op["o"]), Vector(op["u"]), Vector(op["v"]), Vector(op["ray"])
            w = Vector(op.get("v2", op["v"]))
            faces += skin_faces(op, (-o.x, o.y, o.z), (-u.x, u.y, u.z), (-v.x, v.y, v.z), (-ray.x, ray.y, ray.z), bvh, (-w.x, w.y, w.z))
        new_part(op["to"], faces, part(op["like"]))
    elif op["op"] == "text":
        bvh = surface(op["on"])
        target = part(op["part"])
        lay(op, op["o"], op["u"], op["v"], op["ray"], bvh, target)
        if op.get("mirror"):
            o, u, v, ray = Vector(op["o"]), Vector(op["u"]), Vector(op["v"]), Vector(op["ray"])
            e = o + u
            lay(op, (-e.x, e.y, e.z), (u.x, -u.y, -u.z), (-v.x, v.y, v.z), (-ray.x, ray.y, ray.z), bvh, target)

report = {}
obs = []
for n in job["export"]:
    o = part(n)
    name = base(o.name)
    lo, hi = box_of(o)
    key = job.get("names", {}).get(n, name)
    report[key] = {"before": before.get(n), "after": [lo, hi], "faces": len(o.data.polygons), "part": name}
    W = o.matrix_world.copy()
    o.parent = None
    o.data.transform(W)
    o.matrix_world = Matrix.Identity(4)
    obs.append((o, key))
report["__like"] = {k: before[v] for k, v in job.get("like", {}).items()}
keep = {o for o, _ in obs}
for o in list(bpy.data.objects):
    if o not in keep:
        bpy.data.objects.remove(o)
for o, name in obs:
    o.name = name
obs = [o for o, _ in obs]
bpy.ops.object.select_all(action="DESELECT")
for o in obs:
    o.select_set(True)
bpy.context.view_layer.objects.active = obs[0]
out = os.path.join(ROOT, job["out"])
os.makedirs(os.path.dirname(out), exist_ok=True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, global_scale=1.0, apply_unit_scale=True,
                         bake_space_transform=False, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False)
json.dump(report, open(out + ".json", "w"), indent=0)
print("RETEXT wrote", out, os.path.getsize(out) // 1024, "KB", {k: v.get("faces") for k, v in report.items() if k != "__like"})
