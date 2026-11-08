"""
Scissor doors cut from a converted car's own model (owner, 2026-11-08, `Prompts/Scissor doors on the SVJ and SVJ 63 (cut
properly).md`). The SVJs' models already have each door as its own loose pieces (outer skin, window, mirror, the door
card layers), so a door is those pieces taken out of the body parts; the body keeps its own door frame.

    blender -b --factory-startup --python tools/doors.py -- tools/doors/<car id>.json <outprefix> [view|build]

view: takes the doors out, renders the shots (closed, half open, open, door taken away), checks the swing against the body
      and lists the pieces; writes nothing else.
build: the same, then writes the FBX + report for tools/riviera/DoorsApply.luau (the changed body parts and the doors).

job: {
  "source": the car's .blend, "overlay": ["imports/details/<id>.fbx", ...] (parts replaced in Studio since: theirs are used)
  "box": [x0, y0, z0, x1, y1, z1]     the left door's pieces lie wholly inside it (the right door: mirrored in x)
  "xmin": 0.655                       ... and reach no further in than this (cabin pieces next to the door stay), except
  "glass": ["SeeThrough_A_GLASS"]     glass parts: every piece in the box goes (the window curves in at its top)
  "keep": [[part, cx, cy, cz], ...]   pieces that stay anyway (the middle of the piece's box, within 1.5 cm)
  "take": [[part, cx, cy, cz], ...]   pieces that go anyway
  "hinge": [x, y, z], "axis": [x, y, z], "open": 72     the left door's hinge (metres), its turning axis (the door's rear goes
                                       up for a positive angle) and how far it opens
  "shots": [{"name", "eye", "look", "lens", "angle"}]   renders (angle: the doors open by that much for the shot)
  "out": "imports/doors/<id>.fbx"
}
Metres, the car as auto_car.py lays it: front -Y, up +Z, left +X, ground 0.
"""

import json
import math
import os
import re
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
args = sys.argv[sys.argv.index("--") + 1 :]
job = json.load(open(args[0], encoding="utf-8"))
PREFIX = args[1]
MODE = args[2] if len(args) > 2 else "view"
os.makedirs(os.path.dirname(PREFIX), exist_ok=True)

src = job["source"]
if not os.path.isabs(src):
    src = os.path.join(ROOT, src)
bpy.ops.wm.open_mainfile(filepath=src)
sc = bpy.context.scene
WHEELS = ("FL", "FR", "RL", "RR")


def base(n):
    return re.sub(r"\.\d+$", "", n)


def in_wheel(o):
    p = o.parent
    while p is not None:
        if p.name in WHEELS or p.name == "Wheels":
            return True
        p = p.parent
    return False


CAR = [o for o in bpy.data.objects if o.type == "MESH"]
BODY = [o for o in CAR if not in_wheel(o)]


def box_of(o):
    M = o.matrix_world
    me = o.data
    used = sorted({v for pl in me.polygons for v in pl.vertices})
    if not used:
        return None
    p = np.array([tuple(M @ me.vertices[i].co) for i in used])
    return p.min(0).tolist(), p.max(0).tolist()


# --- overlay: meshes replaced in Studio since the .blend (details.py / retext.py) -------------------------------------
for path in job.get("overlay", []):
    if not os.path.isabs(path):
        path = os.path.join(ROOT, path)
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before_objs]
    rep = json.load(open(path + ".json"))
    for o in new:
        if o.type != "MESH":
            continue
        key = base(o.name)
        name = rep.get(key, {}).get("part", key)
        lst = [c for c in BODY if base(c.name) == name]
        if not lst:
            print("DOORS overlay: no part", name, "(left out)")
            continue
        tgt = lst[0]
        mats = list(tgt.data.materials)
        me = o.data.copy()
        me.transform(tgt.matrix_world.inverted() @ o.matrix_world)
        me.materials.clear()
        for m in mats:
            me.materials.append(m)
        tgt.data = me
        print("DOORS overlay", name, len(me.polygons), "faces")
    for o in new:
        bpy.data.objects.remove(o)

BEFORE = {o.name: box_of(o) for o in BODY}


# --- pieces ----------------------------------------------------------------------------------------------------------
def world_co(o):
    me = o.data
    n = len(me.vertices)
    co = np.empty(n * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    M = np.array(o.matrix_world)
    return (M[:3, :3] @ co.T).T + M[:3, 3]


def loose_pieces(o):
    """[vertex index arrays], world points"""
    me = o.data
    n = len(me.vertices)
    co = world_co(o)
    parent = np.arange(n)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    ev = np.empty(len(me.edges) * 2, int)
    me.edges.foreach_get("vertices", ev)
    for a, b in ev.reshape(-1, 2):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb
    roots = np.array([find(i) for i in range(n)])
    order = np.argsort(roots, kind="stable")
    cuts = np.flatnonzero(np.diff(roots[order])) + 1
    return np.split(order, cuts), co


def near(spec_list, part, c):
    for s in spec_list:
        if s[0] == part and np.linalg.norm(np.array(s[1:4]) - c) < 0.015:
            return True
    return False


def side_box(b, side):
    b = np.array(b, float)
    lo, hi = b[:3].copy(), b[3:6].copy()
    if side < 0:
        lo[0], hi[0] = -b[3], -b[0]
    return lo, hi


def door_faces(side):
    """{object: set of face indices} of the door on that side (+1 left, -1 right): whole loose pieces (box, xmin, glass,
    keep, take, keep_box) and single faces of pieces joined to the body ("cut_faces")"""
    lo, hi = side_box(job["box"], side)
    xmin = job.get("xmin", 0.0)
    glass = set(job.get("glass", []))
    mirror = lambda s: [s[0], s[1] * side, s[2], s[3]]
    keep = [mirror(s) for s in job.get("keep", [])]
    take = [mirror(s) for s in job.get("take", [])]
    keep_boxes = [(k[0], *side_box(k[1:7], side)) for k in job.get("keep_box", [])]
    cut_boxes = [(k[0], *side_box(k[1:7], side)) for k in job.get("cut_faces", [])]
    out = {}
    listing = []
    for o in BODY:
        comps, co = loose_pieces(o)
        name = base(o.name)
        go_verts = set()
        for comp in comps:
            p = co[comp]
            plo, phi = p.min(0), p.max(0)
            c = (plo + phi) / 2
            if not (np.all(plo >= lo - 1e-6) and np.all(phi <= hi + 1e-6)):
                if near(take, name, c):
                    go_verts.update(int(i) for i in comp)
                continue
            inward = plo[0] if side > 0 else -phi[0]
            go = name in glass or inward >= xmin
            for kn, klo, khi in keep_boxes:
                if kn == name and np.all(plo >= klo) and np.all(phi <= khi):
                    go = False
            if near(keep, name, c):
                go = False
            if near(take, name, c):
                go = True
            listing.append((go, name, len(comp), plo, phi, c))
            if go:
                go_verts.update(int(i) for i in comp)
        faces = set()
        M = o.matrix_world
        mine = [(clo, chi) for cn, clo, chi in cut_boxes if cn == name]
        for f in o.data.polygons:
            if f.vertices[0] in go_verts:
                faces.add(f.index)
            elif mine:
                fc = np.array(tuple(M @ f.center))
                for clo, chi in mine:
                    if np.all(fc >= clo) and np.all(fc <= chi):
                        faces.add(f.index)
                        break
        if faces:
            out[o] = faces
    return out, listing


def color_layer(me):
    ca = me.color_attributes.active_color
    if ca is None and len(me.color_attributes):
        ca = me.color_attributes[0]
    return ca


def split_off(o, faces, new_name):
    """those faces move to a new object (same materials, picture map, colours, normals)"""
    me = o.data
    me_d = me.copy()
    bm_d = bmesh.new()
    bm_d.from_mesh(me_d)
    bm_d.faces.ensure_lookup_table()
    bmesh.ops.delete(bm_d, geom=[f for f in bm_d.faces if f.index not in faces], context="FACES")
    bmesh.ops.delete(bm_d, geom=[v for v in bm_d.verts if not v.link_faces], context="VERTS")
    bm_d.to_mesh(me_d)
    bm_d.free()
    ob = bpy.data.objects.new(new_name, me_d)
    sc.collection.objects.link(ob)
    ob.matrix_world = o.matrix_world.copy()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()
    me.update()
    return ob


def repaint():
    """job "repaint": [[part, cx, cy, cz, z_min, to_part], ...] (the left side's piece by its box middle; mirrored for the
    right): that body piece's faces above z_min move into to_part (the door frame's uprights into the body paint, so
    Customs paints them like the body; the bottom run along the sill stays carbon)"""
    for spec in job.get("repaint", []):
        src_name, zmin, dst_name = spec[0], spec[4], spec[5]
        srcs = [o for o in BODY if base(o.name) == src_name]
        dsts = [o for o in BODY if base(o.name) == dst_name]
        if not srcs or not dsts:
            print("DOORS repaint: no part", src_name, dst_name)
            continue
        o, dst = srcs[0], dsts[0]
        for side in (1, -1):
            want = np.array([spec[1] * side, spec[2], spec[3]])
            comps, co = loose_pieces(o)
            piece = None
            for comp in comps:
                p = co[comp]
                if np.linalg.norm((p.min(0) + p.max(0)) / 2 - want) < 0.015:
                    piece = set(int(i) for i in comp)
            if piece is None:
                print("DOORS repaint: no piece", spec[:4], "side", side)
                continue
            M = o.matrix_world
            faces = {f.index for f in o.data.polygons if f.vertices[0] in piece and (M @ f.center).z >= zmin}
            if not faces:
                continue
            tmp = split_off(o, faces, "repaint_tmp")
            me = tmp.data
            me.transform(dst.matrix_world.inverted() @ tmp.matrix_world)
            tmp.matrix_world = dst.matrix_world.copy()
            me.materials.clear()
            for m in dst.data.materials:
                me.materials.append(m)
            for f in me.polygons:
                f.material_index = 0
            with bpy.context.temp_override(active_object=dst, object=dst, selected_objects=[dst, tmp], selected_editable_objects=[dst, tmp]):
                bpy.ops.object.join()
            print("DOORS repaint", len(faces), "faces of", src_name, "into", dst_name, "side", side)


DOORS = {}  # side -> [objects]
LISTING = {}
for side, tag in ((1, "L"), (-1, "R")):
    faces_by_obj, listing = door_faces(side)
    LISTING[tag] = listing
    objs = []
    for o, faces in faces_by_obj.items():
        objs.append(split_off(o, faces, "D%s__%s" % (tag, base(o.name))))
    DOORS[tag] = objs
    print("DOORS door", tag, {o.name: len(o.data.polygons) for o in objs})
repaint()


def back_faces(cands, layers, max_layer=0.02):
    """cands: [(world points, centre, normal)]. Which faces need a black back: not a face that already has a twin facing
    the other way (a sheet modelled both sides: a back there would sit just in front of the twin and paint it black), and
    not a face with another face close behind it that faces the other way (that face already shows from behind, and a
    back between them would flicker against it). layers = (bvh, normals) of the faces to look behind into."""
    from mathutils.kdtree import KDTree
    kd = KDTree(len(cands))
    for i, cd in enumerate(cands):
        kd.insert(cd[1], i)
    kd.balance()
    bvh, lnorms = layers
    keep, twins, hidden = [], 0, 0
    for pts, c, n in cands:
        if any(float(np.dot(n, cands[j][2])) < -0.9 for _, j, _ in kd.find_range(c, 0.0015)):
            twins += 1
            continue
        back = Vector(tuple(-n))
        # (the middle and a spot near each corner must all have that face behind them: a big floor face can have a small
        # piece just behind its middle and still be bare everywhere else)
        P = np.array(pts)
        spots = [c] + [c + (q - c) * 0.75 for q in P]
        covered = True
        for sp in spots:
            hit, hn, idx, dist = bvh.ray_cast(Vector(tuple(sp)) + back * 1e-4, back, max_layer)
            if hit is None or float(np.dot(lnorms[idx], -n)) <= 0.5:
                covered = False
                break
        if covered:
            hidden += 1
            continue
        keep.append(pts)
    return keep, twins, hidden


def cover_objects(name, faces_pts, rgb, gap, max_tris=15000):
    """cover_object in parts of at most max_tris triangles (Roblox meshes take about 20,000): name, name2, name3 ..."""
    out, chunk, tris = [], [], 0
    for pts in faces_pts:
        t = len(pts) - 2
        if chunk and tris + t > max_tris:
            out.append(chunk)
            chunk, tris = [], 0
        chunk.append(pts)
        tris += t
    if chunk:
        out.append(chunk)
    return [cover_object(name + ("" if i == 0 else str(i + 1)), ch, rgb, gap) for i, ch in enumerate(out)]


def layer_bvh(objs):
    verts, polys, norms = [], [], []
    for o in objs:
        M = o.matrix_world
        N3 = M.to_3x3()
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        for p in o.data.polygons:
            polys.append([off + i for i in p.vertices])
            norms.append(np.array(tuple((N3 @ p.normal).normalized())))
    return BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0), norms


def cover_object(name, faces_pts, rgb, gap):
    """a mesh of the faces turned round (each a hair behind the face it backs), plain black"""
    verts, faces = [], []
    for pts in faces_pts:
        idx = []
        for p in reversed(pts):
            verts.append(p)
            idx.append(len(verts) - 1)
        faces.append(idx)
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.validate()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.normal_update()
    for v in bm.verts:
        v.co += v.normal * gap
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    mat = bpy.data.materials.new("JambCover")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1)
    mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    me.materials.append(mat)
    return ob


def build_cover():
    """job "cover": {"box": [x0, y0, z0, x1, y1, z1], "skip": ["SeeThrough"], "color": [r, g, b], "doors": true}: Roblox
    draws only the front of a face, so where the door sat the body's jamb, sill and tub sides (single sheets, often facing
    in) let the ground show through once the door is up (owner, 2026-11-08: "cover it with a black thing"). Every body
    face in the box (the left side's; mirrored for the right) gets a copy facing the other way, in plain black: part
    Body_JambCover. From any side only one of the two shows, so nothing flickers. "doors": the doors' own faces get backs
    too (part Body_JambCover in each door: an open door's inner panel was see-through from below)."""
    spec = job.get("cover")
    if not spec:
        return []
    skip = spec.get("skip", ["SeeThrough"])
    out_max = spec.get("out_max", 0.7)  # (faces looking straight out of the car's side are its skin: their backs never show)
    rgb = spec.get("color", [0.02, 0.02, 0.02])
    gap = spec.get("gap", 0.001)
    body_objs = [o for o in BODY if len(o.data.polygons)]
    cands = []
    for side in (1, -1):
        lo, hi = side_box(spec["box"], side)
        for o in body_objs:
            name = base(o.name)
            if any(name.startswith(p) for p in skip):
                continue
            M = o.matrix_world
            N3 = M.to_3x3()
            co = world_co(o)
            for f in o.data.polygons:
                pts = co[list(f.vertices)]
                # (any face that reaches into the box: the underbody is a few big faces whose middles lie far inside)
                if np.all(pts.min(0) <= hi) and np.all(pts.max(0) >= lo):
                    n = np.array(tuple((N3 @ f.normal).normalized()))
                    if side * n[0] > out_max:
                        continue
                    cands.append(([tuple(p) for p in pts], np.array(tuple(M @ f.center)), n))
    keep, twins, hidden = back_faces(cands, layer_bvh(body_objs))
    print("DOORS cover: skipped", twins, "faces that have a back already,", hidden, "with a face just behind")
    obs = cover_objects("Body_JambCover", keep, rgb, gap) if keep else []
    for ob in obs:
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        print("DOORS cover", ob.name, len(ob.data.polygons), "faces,", tris, "triangles")
    if spec.get("doors"):
        for tag, objs in DOORS.items():
            solid = [o for o in objs if len(o.data.polygons) and not any(base(o.name).split("__", 1)[-1].startswith(p) for p in skip)]
            dc = []
            for o in solid:
                M = o.matrix_world
                N3 = M.to_3x3()
                co = world_co(o)
                for f in o.data.polygons:
                    dc.append(([tuple(p) for p in co[list(f.vertices)]], np.array(tuple(M @ f.center)), np.array(tuple((N3 @ f.normal).normalized()))))
            dkeep, dt, dh = back_faces(dc, layer_bvh(solid))
            for d in (cover_objects("D%s__Body_JambCover" % tag, dkeep, rgb, gap) if dkeep else []):
                objs.append(d)
                print("DOORS door cover", d.name, len(d.data.polygons), "faces (skipped", dt, "twins,", dh, "with a face just behind)")
    return obs


COVER = build_cover()

if job.get("list"):
    for tag in ("L",):
        for go, name, n, plo, phi, c in sorted(LISTING[tag], key=lambda r: (r[1], r[3][0])):
            print("DOORS piece %s %-28s v%5d x %.3f..%.3f y %.3f..%.3f z %.3f..%.3f c [%.3f, %.3f, %.3f]" % (
                "GO  " if go else "stay", name, n, plo[0], phi[0], plo[1], phi[1], plo[2], phi[2], c[0], c[1], c[2]))


# --- the hinge ---------------------------------------------------------------------------------------------------------
def hinge(tag):
    s = 1 if tag == "L" else -1
    h = Vector(job["hinge"])
    a = Vector(job["axis"]).normalized()
    if s < 0:
        h.x = -h.x
        a = Vector((a.x, -a.y, -a.z))  # (mirrored in x: an axis is a pseudo-vector, it flips the other two)
    return h, a


def door_matrix(tag, deg):
    h, a = hinge(tag)
    R = Quaternion(a, math.radians(deg)).to_matrix().to_4x4()
    return Matrix.Translation(h) @ R @ Matrix.Translation(-h)


BASE_MW = {o.name: o.matrix_world.copy() for objs in DOORS.values() for o in objs}


def show_pieces():
    """job "show": [[part, cx, cy, cz, [r, g, b]], ...] body pieces painted in a flat colour for the renders (to find them)"""
    for spec in job.get("show", []):
        mat = bpy.data.materials.new("show")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        rgb = spec[4] if len(spec) > 4 else [1, 0, 1]
        bsdf.inputs["Base Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = 0.6
        for o in BODY:
            if base(o.name) != spec[0]:
                continue
            comps, co = loose_pieces(o)
            for comp in comps:
                p = co[comp]
                c = (p.min(0) + p.max(0)) / 2
                if np.linalg.norm(c - np.array(spec[1:4])) < 0.015:
                    o.data.materials.append(mat)
                    mi = len(o.data.materials) - 1
                    vs = set(int(i) for i in comp)
                    for f in o.data.polygons:
                        if f.vertices[0] in vs:
                            f.material_index = mi
                    print("DOORS show", spec[:4])


def show_faces():
    """job "show_faces": [[part, x0, y0, z0, x1, y1, z1, [r, g, b]], ...] faces of a body part whose middles are in the
    box, in a flat colour for the renders"""
    for spec in job.get("show_faces", []):
        mat = bpy.data.materials.new("showf")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        rgb = spec[7] if len(spec) > 7 else [1, 0, 1]
        bsdf.inputs["Base Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = 0.6
        lo_, hi_ = np.array(spec[1:4]), np.array(spec[4:7])
        for o in BODY:
            if base(o.name) != spec[0]:
                continue
            o.data.materials.append(mat)
            mi = len(o.data.materials) - 1
            M = o.matrix_world
            n = 0
            flt = spec[8] if len(spec) > 8 else {}
            N3 = M.to_3x3()
            for f in o.data.polygons:
                c = np.array(tuple(M @ f.center))
                if np.all(c >= lo_) and np.all(c <= hi_):
                    nn = (N3 @ f.normal).normalized()
                    if "nz_max" in flt and abs(nn.z) > flt["nz_max"]:
                        continue
                    if "nz_min" in flt and abs(nn.z) < flt["nz_min"]:
                        continue
                    f.material_index = mi
                    n += 1
            print("DOORS show faces", spec[0], n)


if MODE == "view":
    show_pieces()
    show_faces()


def set_open(deg):
    for tag, objs in DOORS.items():
        M = door_matrix(tag, deg)
        for o in objs:
            o.matrix_world = M @ BASE_MW[o.name]
    bpy.context.view_layer.update()


# --- does the swing hit the body? --------------------------------------------------------------------------------------
def bvh_of(objs):
    verts, polys = [], []
    for o in objs:
        M = o.matrix_world
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        polys.extend([[off + i for i in p.vertices] for p in o.data.polygons])
    return BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0), verts, polys


def swing_check():
    body_objs = [o for o in BODY if len(o.data.polygons)]
    body_bvh, _, _ = bvh_of(body_objs)
    rows = []
    for deg in (0, 10, 20, 30, 40, 50, 60, job.get("open", 72)):
        set_open(deg)
        for tag, objs in DOORS.items():
            d_bvh, dv, dp = bvh_of(objs)
            hits = d_bvh.overlap(body_bvh)
            # (where: the door's faces that touch)
            pts = np.array([np.mean([dv[i] for i in dp[a]], 0) for a, _ in hits]) if hits else np.zeros((0, 3))
            where = ""
            if len(pts):
                lo_, hi_ = pts.min(0), pts.max(0)
                where = " at x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % (lo_[0], hi_[0], lo_[1], hi_[1], lo_[2], hi_[2])
            rows.append((deg, tag, len(hits), where))
    set_open(0)
    for deg, tag, n, where in rows:
        print("DOORS swing %3d deg %s: %d face pairs touch%s" % (deg, tag, n, where))
    return rows


# --- renders -------------------------------------------------------------------------------------------------------------
def cull_backfaces():
    """job "cull": the renders show only the front of each face, as Roblox draws them (a back face lets you see through)"""
    for mat in bpy.data.materials:
        if not mat.use_nodes or mat.get("culled"):
            continue
        nt = mat.node_tree
        out = next((n for n in nt.nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output), None)
        if out is None or not out.inputs["Surface"].is_linked:
            continue
        link = out.inputs["Surface"].links[0]
        src = link.from_socket
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        nt.links.remove(link)
        nt.links.new(geo.outputs["Backfacing"], mix.inputs[0])
        nt.links.new(src, mix.inputs[1])
        nt.links.new(tr.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
        mat["culled"] = True


def setup_render():
    if job.get("cull"):
        cull_backfaces()
    w = bpy.data.worlds.new("w")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.84, 0.9, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 2.5
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (0.8, 0.2, 0.9)
    sc.collection.objects.link(so)
    for p in job.get("lamps", []):
        ld = bpy.data.lights.new("lamp", "POINT")
        ld.energy = p[3] if len(p) > 3 else 60
        ld.shadow_soft_size = 0.3
        lo_ = bpy.data.objects.new("lamp", ld)
        lo_.location = p[:3]
        sc.collection.objects.link(lo_)
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, 0))
    if job.get("probe_ground"):
        # (view: a glowing magenta ground, so anywhere you can see the ground through the car shows)
        g = bpy.context.active_object
        gm = bpy.data.materials.new("probe_ground")
        gm.use_nodes = True
        gm.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1, 0, 1, 1)
        gm.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 2.0
        g.data.materials.append(gm)
        g.visible_diffuse = g.visible_glossy = g.visible_transmission = g.visible_volume_scatter = False
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = job.get("samples", 20)
    sc.cycles.use_denoising = True
    cam = bpy.data.cameras.new("c")
    co = bpy.data.objects.new("cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    sc.render.resolution_x, sc.render.resolution_y = 1280, 800
    sc.render.image_settings.file_format = "PNG"
    return cam, co


def render(tag, shots):
    cam, co = setup_render() if not sc.camera else (sc.camera.data, sc.camera)
    for shot in shots:
        cam.lens = shot.get("lens", 35)
        eye, look = Vector(shot["eye"]), Vector(shot["look"])
        co.location = eye
        co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
        hide = shot.get("hide_doors", False)
        for objs in DOORS.values():
            for o in objs:
                o.hide_render = hide
        set_open(shot.get("angle", 0))
        sc.render.filepath = "%s_%s_%s.png" % (PREFIX, shot["name"], tag)
        bpy.ops.render.render(write_still=True)
    set_open(0)
    for objs in DOORS.values():
        for o in objs:
            o.hide_render = False
    print("DOORS rendered", tag, len(shots))


def search():
    """job "search": {"x": [...], "y": [...], "z": [...], "yaw": [...], "down": [...], "angles": [...]}: hinge spots and
    axis tilts tried on the left door; prints the ones whose swing touches the body least"""
    S = job["search"]
    body_objs = [o for o in BODY if len(o.data.polygons)]
    body_bvh, _, _ = bvh_of(body_objs)
    verts, polys = [], []
    for o in DOORS["L"]:
        M = o.matrix_world
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        polys.extend([[off + i for i in p.vertices] for p in o.data.polygons])
    V = np.array(verts)
    rows = []
    for hx in S["x"]:
        for hy in S["y"]:
            for hz in S["z"]:
                for yaw in S["yaw"]:
                    for down in S["down"]:
                        b_, g_ = math.radians(yaw), math.radians(down)
                        a = Vector((math.cos(g_) * math.cos(b_), math.cos(g_) * math.sin(b_), -math.sin(g_)))
                        h = np.array([hx, hy, hz])
                        total, worst = 0, 0
                        for deg in S["angles"]:
                            R = np.array(Quaternion(a, math.radians(deg)).to_matrix())
                            W = (R @ (V - h).T).T + h
                            bvh = BVHTree.FromPolygons(W.tolist(), polys, all_triangles=False, epsilon=0.0)
                            n = len(bvh.overlap(body_bvh))
                            total += n
                            worst = max(worst, n)
                        # how far the door's rear end moves out at full open (a real one stays close to the body)
                        R = np.array(Quaternion(a, math.radians(S["angles"][-1])).to_matrix())
                        W = (R @ (V - h).T).T + h
                        out_ = W[:, 0].max() - V[:, 0].max()
                        rows.append((total, worst, out_, hx, hy, hz, yaw, down))
    rows.sort()
    for r in rows[:25]:
        print("DOORS search total %5d worst %4d out %.2f  hinge [%.3f, %.3f, %.3f] yaw %g down %g" % r)


def who_hits(deg):
    """which door pieces touch which body parts at that angle (the left door)"""
    set_open(deg)
    body_objs = [o for o in BODY if len(o.data.polygons)]
    fmap = []
    verts, polys = [], []
    for o in body_objs:
        M = o.matrix_world
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        for p in o.data.polygons:
            polys.append([off + i for i in p.vertices])
            fmap.append((o, p.index))
    body_bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    dv, dp, dmap = [], [], []
    for o in DOORS["L"]:
        M = o.matrix_world
        off = len(dv)
        dv.extend([tuple(M @ v.co) for v in o.data.vertices])
        for p in o.data.polygons:
            dp.append([off + i for i in p.vertices])
            dmap.append((o, p.index))
    d_bvh = BVHTree.FromPolygons(dv, dp, all_triangles=False, epsilon=0.0)
    pairs = d_bvh.overlap(body_bvh)
    groups = {}
    for a, b in pairs:
        do, _ = dmap[a]
        bo, bi = fmap[b]
        dc = np.mean([dv[i] for i in dp[a]], 0)
        bc = np.mean([verts[i] for i in polys[b]], 0)
        key = (base(do.name), base(bo.name))
        g = groups.setdefault(key, [])
        g.append((dc, bc))
    for (dn, bn), g in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        d = np.array([x[0] for x in g])
        b = np.array([x[1] for x in g])
        print("DOORS hits %3d deg: %-28s x %-28s %4d pairs; door at %s, body at %s" % (deg, dn, bn, len(g),
              np.round(d.mean(0), 3).tolist(), np.round(b.mean(0), 3).tolist()))
    set_open(0)


def show_hits():
    """job "show_hits": [angles]: the body faces the left door touches at those angles, in magenta for the renders"""
    angles = job.get("show_hits")
    if not angles:
        return
    body_objs = [o for o in BODY if len(o.data.polygons)]
    verts, polys, fmap = [], [], []
    for o in body_objs:
        M = o.matrix_world
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        for p in o.data.polygons:
            polys.append([off + i for i in p.vertices])
            fmap.append((o, p.index))
    body_bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    hit = {}
    for deg in angles:
        set_open(deg)
        d_bvh, _, _ = bvh_of(DOORS["L"])
        for a, b in d_bvh.overlap(body_bvh):
            o, fi = fmap[b]
            hit.setdefault(o, set()).add(fi)
    set_open(0)
    mat = bpy.data.materials.new("hit")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (1, 0, 1, 1)
    bsdf.inputs["Emission Color"].default_value = (1, 0, 1, 1)
    bsdf.inputs["Emission Strength"].default_value = 1.0
    for o, faces in hit.items():
        o.data.materials.append(mat)
        mi = len(o.data.materials) - 1
        for fi in faces:
            o.data.polygons[fi].material_index = mi
        print("DOORS hit faces", base(o.name), len(faces))


def holes():
    """mode "holes": with the doors up, rays from many spots round the left side into the opening; the ones that reach the
    ground under the car went through a hole Roblox would show (one-sided faces count only from their front, as in
    Roblox). Prints where those rays cross the jamb planes, grouped in 5 cm cells."""
    set_open(job.get("open", 72))
    objs = [o for o in BODY if len(o.data.polygons)] + COVER + DOORS["L"]
    verts, polys, norms = [], [], []
    for o in objs:
        M = o.matrix_world
        N3 = M.to_3x3()
        off = len(verts)
        verts.extend([tuple(M @ v.co) for v in o.data.vertices])
        for p in o.data.polygons:
            polys.append([off + i for i in p.vertices])
            norms.append(np.array(tuple((N3 @ p.normal).normalized())))
    bvh = BVHTree.FromPolygons(verts, polys, all_triangles=False, epsilon=0.0)
    owner = []
    for o in objs:
        owner.extend([base(o.name)] * len(o.data.polygons))
    for e, t in job.get("debug_rays", []):
        e, t = Vector(e), Vector(t)
        o_, d = e.copy(), (Vector(t) - e).normalized()
        for _ in range(20):
            hit, n, idx, dist = bvh.ray_cast(o_, d)
            if hit is None:
                print("DOORS ray", tuple(e), "->", tuple(t), ": escapes")
                break
            front = float(np.dot(norms[idx], np.array(tuple(d)))) < 0
            print("DOORS ray hit %-26s %s at (%.3f, %.3f, %.3f)" % (owner[idx], "FRONT" if front else "back ", *hit))
            if front:
                break
            o_ = hit + d * 1e-4
    glass = [o2.startswith("SeeThrough") or o2.startswith("DL__SeeThrough") or o2.startswith("DR__SeeThrough") for o2 in owner]
    eyes = [Vector((x, y, z)) for x in (1.8, 2.6, 3.4) for y in (-2.4, -1.6, -0.8, 0.0, 0.8, 1.6) for z in (0.5, 0.9, 1.4, 2.0)]
    targets = [Vector((x, y, z)) for x in (0.7, 0.85) for y in np.arange(-1.0, 0.45, 0.05) for z in np.arange(0.15, 0.95, 0.05)]
    # (2026-11-08, owner saw the front jamb by the wheel see-through on the SV: the front and rear ends of the opening too,
    # and any ray that went through a back face and then left the car counts, wherever it lands)
    targets += [Vector((x, y, z)) for x in (0.8, 0.9, 1.0) for y in np.arange(-1.3, -0.85, 0.05) for z in np.arange(0.15, 0.95, 0.05)]
    targets += [Vector((x, y, z)) for x in (0.8, 0.9, 1.0) for y in np.arange(0.2, 0.6, 0.05) for z in np.arange(0.15, 0.95, 0.05)]
    cells = {}
    for e in eyes:
        for t in targets:
            o = e.copy()
            d = (t - e).normalized()
            last = None
            first = None
            blocked = False
            for _ in range(60):
                hit, n, idx, dist = bvh.ray_cast(o, d)
                if hit is None:
                    break
                if not glass[idx] and float(np.dot(norms[idx], np.array(tuple(d)))) < 0:  # a front face: the ray stops
                    blocked = True
                    break
                if not glass[idx]:
                    last = (hit.copy(), owner[idx])
                    first = first or last
                o = hit + d * 1e-4
            else:
                blocked = True
            if blocked:
                continue
            if first is not None:
                # (went through the back of a face and out of the car: the sky or the ground shows there in Roblox)
                p = first[0]
                key = (round(p.x * 20) / 20, round(p.y * 20) / 20, round(p.z * 20) / 20, first[1])
                cells[key] = cells.get(key, 0) + 1
                continue
            if d.z >= 0:
                continue
            g = e + d * (-e.z / d.z)
            if 0.3 < g.x < 0.95 and -1.05 < g.y < 0.5:
                # (through the floor of the opening or the jamb: where it last went through a back face)
                p = last[0] if last else g
                key = (round(p.x * 20) / 20, round(p.y * 20) / 20, round(p.z * 20) / 20, last[1] if last else "-")
                cells[key] = cells.get(key, 0) + 1
    # (rays with no back face on the way ("-") went under the car to the ground: not a hole)
    real = {k: n for k, n in cells.items() if k[3] != "-"}
    for k, n in sorted(real.items(), key=lambda kv: -kv[1])[:60]:
        print("DOORS hole through (%.2f, %.2f, %.2f) %s: %d rays" % (k[0], k[1], k[2], k[3], n))
    print("DOORS holes:", len(real), "cells,", sum(real.values()), "rays (and", sum(cells.values()) - sum(real.values()), "under the car)")
    set_open(0)


def piece_at():
    """mode "piece": job "piece_at": [[part, x, y, z], ...]: the body part's loose piece nearest that spot (the middle of its
    box, as "repaint" and "show" want it, its size and how many points)"""
    for spec in job.get("piece_at", []):
        for o in BODY:
            if base(o.name) != spec[0] or not len(o.data.polygons):
                continue
            comps, co = loose_pieces(o)
            want = np.array(spec[1:4])
            best = min(comps, key=lambda comp: np.min(np.linalg.norm(co[comp] - want, axis=1)))
            p = co[best]
            mid = (p.min(0) + p.max(0)) / 2
            print("DOORS piece at %s: %s middle [%.4f, %.4f, %.4f] size [%.3f, %.3f, %.3f] points %d, nearest %.3f" % (
                spec[1:4], spec[0], *mid, *(p.max(0) - p.min(0)), len(best), np.min(np.linalg.norm(p - want, axis=1))))


if MODE == "piece":
    piece_at()
    sys.exit(0)
if MODE == "holes":
    holes()
    sys.exit(0)
if MODE == "search":
    search()
    sys.exit(0)
if MODE == "view":
    show_hits()
if MODE == "hits":
    for deg in job.get("hit_angles", [0, 30, 60]):
        who_hits(deg)
    sys.exit(0)

swing = swing_check()
if job.get("shots") and MODE in ("view", "build"):
    render("doors", job["shots"])
if MODE != "build":
    sys.exit(0)

# --- export --------------------------------------------------------------------------------------------------------------
report = {"doors": {}, "parts": {}}
obs = []
for o in BODY:
    if any(o in objs for objs in DOORS.values()):
        continue
    if BEFORE.get(o.name) and box_of(o) and box_of(o) != BEFORE[o.name] or (BEFORE.get(o.name) and len(o.data.polygons) < 1):
        pass
changed = set()
for tag, objs in DOORS.items():
    for d in objs:
        changed.add(d.name.split("__", 1)[1])
for o in BODY:
    if base(o.name) in changed:
        box = box_of(o)
        if box is None:
            # (the doors took the whole part, e.g. a part that is only the two mirrors: Studio drops it)
            report["parts"][base(o.name)] = {"before": BEFORE[o.name], "after": None, "faces": 0}
            continue
        report["parts"][base(o.name)] = {"before": BEFORE[o.name], "after": list(box), "faces": len(o.data.polygons)}
        obs.append(o)
for tag, objs in DOORS.items():
    h, a = hinge(tag)
    report["doors"][tag] = {"hinge": list(h), "axis": list(a), "open": job.get("open", 72), "parts": {}}
    for d in objs:
        lo, hi = box_of(d)
        report["doors"][tag]["parts"][d.name] = {"part": d.name.split("__", 1)[1], "after": [lo, hi], "faces": len(d.data.polygons)}
        obs.append(d)
if COVER:
    rgb = job["cover"].get("color", [0.02, 0.02, 0.02])
    report["covers"] = {}
    for cv in COVER:
        lo, hi = box_of(cv)
        report["covers"][cv.name] = {"after": [lo, hi], "faces": len(cv.data.polygons), "color": rgb}
        obs.append(cv)
report["swing"] = [list(r) for r in swing]
for o in obs:
    W = o.matrix_world.copy()
    o.parent = None
    o.data.transform(W)
    o.matrix_world = Matrix.Identity(4)
for o in list(bpy.data.objects):
    if o not in obs:
        bpy.data.objects.remove(o)
for o in obs:
    o.name = base(o.name) if not o.name.startswith("D") or "__" not in o.name else o.name
bpy.ops.object.select_all(action="DESELECT")
for o in obs:
    o.select_set(True)
bpy.context.view_layer.objects.active = obs[0]
out = os.path.join(ROOT, job["out"])
os.makedirs(os.path.dirname(out), exist_ok=True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, global_scale=1.0, apply_unit_scale=True,
                         bake_space_transform=False, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False,
                         path_mode="STRIP")
# (read back and written again, as details.py: Open Cloud refused some first exports)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=out, axis_forward="-Z", axis_up="Y")
for o in bpy.data.objects:
    o.select_set(o.type == "MESH")
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                         mesh_smooth_type="FACE", path_mode="STRIP")
json.dump(report, open(out + ".json", "w"), indent=0)
print("DOORS wrote", out, os.path.getsize(out) // 1024, "KB")
