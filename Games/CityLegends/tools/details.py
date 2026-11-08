"""
Very small design changes on a converted car (owner, 2026-11-06, `Prompts/Small design changes on famous new cars.md`):
vent slats, fins, exhaust tips, cut lines, light graphics. Same look from the normal camera, different up close.

    blender -b --factory-startup --python tools/details.py -- tools/details/<car id>.json <outprefix> [view|build]

view: renders the job's shots (and marks what the ops pick in magenta), lists pieces, probes pixels; writes nothing.
build: renders the shots before and after the ops and writes the FBX + report for tools/riviera/RetextApply.luau.

job: {
  "source": the car's .blend (or a pack .fbx with "root": the car's group in it)
  "overlay": ["imports/retext/<car id>.fbx"]   parts replaced in Studio since that .blend: their meshes are used instead
  "ops": [...], "out": "imports/details/<car id>.fbx", "export": [...] (default: every part an op touched)
  "shots": [{"name": "tail", "eye": [x, y, z], "look": [x, y, z], "lens": 50}]   1280 x 800 ("light": [x, y, z], "power": W
                                 adds a lamp for that shot)
  "auto": true                   adds the standard shots from the car's box (far_rear, far_front, tail, lamp, exhaust, side, front,
                                 nose; "auto_names" picks some); "info": true lists the parts with their pictures; "dump_tiles": true saves
                                 the small repeating pictures (<prefix>_tile_<part>_colour / _normal.png)
  "list": [{"part": "Body_Grille" or "*", "box": [x0, y0, z0, x1, y1, z1]}]       pieces wholly in the box ("count" rows,
                                                                                   "min" / "max" their longest side)
  "probe": [{"shot": "tail", "px": [[x, y], ...]}]                                 what each pixel shows
  "tiles": {"Body_Grille": {"colour": png, "normal": png, "pattern": "diamond"}}    new grille pictures for the after shots
                                                                                   (tools/details_tiles.py; uploaded on their own)
}
Metres, the car as auto_car.py lays it: front -Y, up +Z, ground 0. "mirror": true on an op does it on the other side too
(x -> -x). A piece = a loose part of a mesh (connected faces); an op takes the pieces lying wholly inside its boxes.
ops:
  shape    {"part", "boxes", "to": "soft" | "round" | "hex" | "oct" | "oval" | "rsq", "axis": "y", "k": 1, "rot": deg, "aspect": 1.3,
            "soft": 0.35}  each piece gets the cross-section "to" round its own middle (its outer edge is fitted, the inner
            walls follow); "soft" rounds a polygon's corners; to "soft" only rounds the piece's own corners in ("window" bins of 4 degrees);
            "group": 0.02 shapes pieces whose middles are that close as one (a tip and its inner wall)
  clip     {"part", "boxes", "p": [x, y, z], "n": [x, y, z]}  the points of the pieces beyond the plane go onto it (a straight cut);
            "frac": 0.85 in place of "p" cuts each piece at that share of its length along n ("group": 0.03 measures
            pieces whose middles are that close as one)
  respace  {"part", "boxes", "axis": [x, y, z], "count": n}  slats: first and last stay, n pieces evenly between them
  fin      {"part", "o", "u", "v", "t": 0.006, "bevel": 0.002, "from": [x, y, z]}  a thin plate with chamfered edges: corner
            o, along u, up v, t thick; its picture spot and shade come from the part's surface nearest "from"
  scale    {"part", "boxes", "s": [sx, sy, sz]}  each piece round its own middle
  move     {"part", "boxes", "d": [dx, dy, dz]}
  drop     {"part", "boxes"}
Pieces an op reshapes get fresh normals (sharp past 40 degrees); moved or copied ones keep theirs.
"""

import json
import math
import os
import re
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
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
if src.endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=src)
else:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=src)
sc = bpy.context.scene


def base(n):
    return re.sub(r"\.\d+$", "", n)


def meshes():
    if job.get("root"):
        r = bpy.data.objects[job["root"]]
        return [o for o in r.children_recursive if o.type == "MESH"]
    return [o for o in bpy.data.objects if o.type == "MESH"]


CAR = meshes()
OFF = Vector((0, 0, 0))
if job.get("root"):
    lo = np.min([np.min([tuple(o.matrix_world @ Vector(c)) for c in o.bound_box], 0) for o in CAR], 0)
    hi = np.max([np.max([tuple(o.matrix_world @ Vector(c)) for c in o.bound_box], 0) for o in CAR], 0)
    OFF = Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))
    OFF = Vector(job.get("offset", tuple(OFF)))


def part(name):
    key, faces = (name.split("#") + [None])[:2]
    lst = [o for o in CAR if base(o.name) == key]
    if faces:
        lst = [o for o in lst if len(o.data.polygons) == int(faces)]
    if not lst:
        print("DETAILS no part " + name + " in " + str(sorted({base(o.name) for o in CAR})))
        raise SystemExit(1)
    return lst[0]


def box_of(o):
    M = o.matrix_world
    me = o.data
    used = sorted({v for pl in me.polygons for v in pl.vertices})
    if not used:
        return None
    p = np.array([tuple(M @ me.vertices[i].co) for i in used]) - np.array(tuple(OFF))
    return p.min(0).tolist(), p.max(0).tolist()


# --- overlay: meshes replaced since the .blend (retext) ---------------------------------------------------------------
for path in job.get("overlay", []):
    if not os.path.isabs(path):
        path = os.path.join(ROOT, path)
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before_objs]
    for o in new:
        if o.type != "MESH":
            continue
        rep = json.load(open(path + ".json"))
        key = base(o.name)
        name = rep.get(key, {}).get("part", key)
        lst = [c for c in CAR if base(c.name) == name]
        if not lst:
            print("DETAILS overlay: new part", name, "(kept as its own)")
            o.name = name
            if "paint" in name.lower():
                # (for the renders: a fill sheet shows in the paint's look; in Studio it copies the paint part's look)
                paints = [c for c in CAR if "paint" in c.name.lower() and c.data.materials]
                if paints:
                    big = max(paints, key=lambda c: len(c.data.polygons))
                    o.data.materials.clear()
                    o.data.materials.append(big.data.materials[0])
            CAR.append(o)
            continue
        tgt = lst[0]
        bef = rep.get(key, {}).get("before")
        if len(lst) > 1 and bef:
            # (parts of one name: the one whose box matches the job's "before" box)
            want = np.array(bef[1]) - np.array(bef[0])
            def gap(c):
                b = box_of(c)
                return np.abs((np.array(b[1]) - np.array(b[0])) - want).sum() if b else 1e9
            tgt = min(lst, key=gap)
        mats = list(tgt.data.materials)
        me = o.data.copy()
        me.transform(tgt.matrix_world.inverted() @ o.matrix_world)
        me.materials.clear()
        for m in mats:
            me.materials.append(m)
        tgt.data = me
        print("DETAILS overlay", name, len(me.polygons), "faces")
    for o in new:
        if o not in CAR:
            bpy.data.objects.remove(o)


# --- pieces ----------------------------------------------------------------------------------------------------------
def boxes_of(op, key="boxes"):
    out = [np.array(b, float) + np.array(tuple(OFF) * 2) for b in op.get(key, [])]
    if op.get("mirror"):
        for b in list(out):
            ox = OFF.x * 2
            out.append(np.array([ox - b[3], b[1], b[2], ox - b[0], b[4], b[5]]))
    return out


def pieces_in(o, boxes, op=None):
    """lists of vertex indices: the loose pieces of o lying wholly inside one of the boxes ("min" / "max": only pieces
    whose longest side is at least / at most that)"""
    op = op or {}
    me = o.data
    M = o.matrix_world
    n = len(me.vertices)
    co = np.empty(n * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    co = (np.array(M)[:3, :3] @ co.T).T + np.array(M)[:3, 3]
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
    out = []
    order = np.argsort(roots, kind="stable")
    r_sorted = roots[order]
    cuts = np.flatnonzero(np.diff(r_sorted)) + 1
    for comp in np.split(order, cuts):
        p = co[comp]
        lo, hi = p.min(0), p.max(0)
        side = (hi - lo).max()
        if side < op.get("min", 0) or side > op.get("max", 1e9):
            continue
        for b in boxes:
            if np.all(lo >= b[:3]) and np.all(hi <= b[3:]):
                out.append(comp)
                break
    return out, co


def color_layer(me):
    ca = me.color_attributes.active_color
    if ca is None and len(me.color_attributes):
        ca = me.color_attributes[0]
    return ca


def take(o, comps, remove=True):
    """the faces of those pieces: [(material, [(co, uv, normal, colour), ...]), ...]; removed from o"""
    me = o.data
    me.update()
    M = o.matrix_world
    N = M.to_3x3().inverted().transposed()
    uvl = me.uv_layers.active
    ca = color_layer(me)
    normals = me.corner_normals
    kill = set()
    for c in comps:
        kill.update(int(i) for i in c)
    faces = []
    for f in me.polygons:
        if f.vertices[0] in kill:
            loops = []
            for li in f.loop_indices:
                vi = me.loops[li].vertex_index
                uv = tuple(uvl.data[li].uv) if uvl else (0.0, 0.0)
                nn = N @ Vector(normals[li].vector)
                nn.normalize()
                col = None
                if ca is not None:
                    col = tuple(ca.data[li if ca.domain == "CORNER" else vi].color)
                loops.append([tuple(M @ me.vertices[vi].co), uv, tuple(nn), col])
            faces.append((f.material_index, loops))
    if remove and kill:
        bm = bmesh.new()
        bm.from_mesh(me)
        bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[bm.verts[i] for i in kill], context="VERTS")
        bm.to_mesh(me)
        bm.free()
    return faces


def put(o, faces, fresh=False):
    """faces back into part o (joined), keeping its material slots, picture map and colour names"""
    if not faces:
        return
    me0 = o.data
    idx, verts, polys, uvs, nor, cols, mats = {}, [], [], [], [], [], []
    for mat, f in faces:
        ids = []
        for corner in f:
            k = tuple(round(c, 6) for c in corner[0])
            if k not in idx:
                idx[k] = len(verts)
                verts.append(corner[0])
            ids.append(idx[k])
            uvs.append(corner[1])
            nor.append(corner[2])
            cols.append(corner[3])
        if len(set(ids)) < 3:
            for _ in f:
                uvs.pop()
                nor.pop()
                cols.pop()
            continue
        polys.append(ids)
        mats.append(mat)
    Mi = o.matrix_world.inverted()
    me = bpy.data.meshes.new(o.name + "_add")
    me.from_pydata([tuple(Mi @ Vector(v)) for v in verts], [], polys)
    uvname = me0.uv_layers.active.name if me0.uv_layers.active else "UVMap"
    layer = me.uv_layers.new(name=uvname)
    for i, uv in enumerate(uvs[: len(layer.data)]):
        layer.data[i].uv = uv
    ca0 = color_layer(me0)
    if ca0 is not None and cols and cols[0] is not None:
        ca = me.color_attributes.new(ca0.name, ca0.data_type, "CORNER")
        for i, c_ in enumerate(cols[: len(ca.data)]):
            ca.data[i].color = c_
    for m in me0.materials:
        me.materials.append(m)
    me.polygons.foreach_set("material_index", mats)
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    me.update()
    if fresh:
        me.set_sharp_from_angle(angle=math.radians(40))
    else:
        Ni = o.matrix_world.to_3x3().transposed()  # world normals back to local (rotation part)
        me.normals_split_custom_set([tuple((Ni @ Vector(n)).normalized()) for n in nor[: len(me.loops)]])
    ob = bpy.data.objects.new(o.name + "_add", me)
    sc.collection.objects.link(ob)
    ob.matrix_world = o.matrix_world.copy()  # (its points are in o's space: a pack's parts sit under a scaled, turned group)
    with bpy.context.temp_override(active_object=o, object=o, selected_objects=[o, ob], selected_editable_objects=[o, ob]):
        bpy.ops.object.join()


def pieces(faces):
    """faces split back into pieces by shared points"""
    parent = {}

    def find(a):
        while parent.setdefault(a, a) != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    keys = []
    for _, f in faces:
        ks = [tuple(round(c, 6) for c in corner[0]) for corner in f]
        keys.append(ks)
        for k in ks[1:]:
            ra, rb = find(ks[0]), find(k)
            if ra != rb:
                parent[ra] = rb
    groups = {}
    for fi, ks in enumerate(keys):
        groups.setdefault(find(ks[0]), []).append(fi)
    return [[faces[i] for i in g] for g in groups.values()]


def corners(faces):
    return [c for _, f in faces for c in f]


def mid_of(faces):
    p = np.array([c[0] for c in corners(faces)])
    return (p.min(0) + p.max(0)) / 2


# --- shapes ----------------------------------------------------------------------------------------------------------
def shape_r(name, th, op):
    rot = math.radians(op.get("rot", 0))
    t = th - rot
    if name == "round":
        return np.ones_like(t)
    if name in ("hex", "oct", "tri", "pent"):
        n = {"tri": 3, "pent": 5, "hex": 6, "oct": 8}[name]
        seg = 2 * math.pi / n
        a = np.mod(t, seg) - seg / 2
        poly = math.cos(math.pi / n) / np.cos(a)
        s = op.get("soft", 0.35)
        return poly * (1 - s) + s
    if name == "oval":
        ax = op.get("aspect", 1.3)
        return 1 / np.sqrt((np.cos(t) / ax) ** 2 + np.sin(t) ** 2)
    if name == "rsq":
        e = op.get("power", 4)
        ax = op.get("aspect", 1.0)
        return (np.abs(np.cos(t) / ax) ** e + np.abs(np.sin(t)) ** e) ** (-1 / e)
    raise SystemExit("DETAILS unknown shape " + name)


AX = {"x": (1, 2), "y": (0, 2), "z": (0, 1)}


def op_shape(op, faces):
    out = []
    a_, b_ = AX[op.get("axis", "y")]
    k = op.get("k", 1.0)
    groups = pieces(faces)
    if op.get("group"):
        # pieces sharing a middle (a tip and its inner wall) are shaped as one
        merged = []
        for pc in groups:
            m = mid_of(pc)[[a_, b_]]
            for g in merged:
                if np.linalg.norm(g[0] - m) < op["group"]:
                    g[1].extend(pc)
                    break
            else:
                merged.append([m, list(pc)])
        groups = [g[1] for g in merged]
        print("DETAILS shape groups", len(groups))
    for pc in groups:
        cs = corners(pc)
        p = np.array([c[0] for c in cs])
        cen = (p.min(0) + p.max(0)) / 2
        if op.get("centre"):
            cen = np.array(op["centre"], float)
        d = p[:, [a_, b_]] - cen[[a_, b_]]
        r = np.hypot(d[:, 0], d[:, 1])
        th = np.arctan2(d[:, 1], d[:, 0])
        B = 90
        bins = ((th + math.pi) / (2 * math.pi) * B).astype(int) % B
        rmax = np.zeros(B)
        for bi, rr in zip(bins, r):
            rmax[bi] = max(rmax[bi], rr)
        have = rmax > 0
        if have.sum() < 6:
            out += pc
            continue
        xs = np.flatnonzero(have)
        rmax = np.interp(np.arange(B), np.concatenate([xs - B, xs, xs + B]), np.tile(rmax[have], 3))
        rmax = (np.roll(rmax, 1) + rmax * 2 + np.roll(rmax, -1)) / 4
        thb = (np.arange(B) + 0.5) / B * 2 * math.pi - math.pi
        if op["to"] == "soft":
            w = op.get("window", 9)
            pad = np.concatenate([rmax[-w:], rmax, rmax[:w]])
            sm = np.convolve(pad, np.ones(2 * w + 1) / (2 * w + 1), "same")[w:-w]
            tgt = np.minimum(rmax, sm)
        else:
            tgt = shape_r(op["to"], thb, op)
            tgt *= rmax.mean() / tgt.mean() * op.get("size", 1.0)
        s = tgt / rmax
        sv = np.interp(th, thb, s, period=2 * math.pi)
        f = 1 + k * (sv - 1)
        newp = p.copy()
        newp[:, a_] = cen[a_] + d[:, 0] * f
        newp[:, b_] = cen[b_] + d[:, 1] * f
        for c, q in zip(cs, newp):
            c[0] = tuple(q)
        out += pc
    return out


def op_clip(op, faces, pt, nn):
    nn = np.array(nn, float)
    nn /= np.linalg.norm(nn)
    groups = pieces(faces) if "frac" in op else [faces]
    if "frac" in op and op.get("group"):
        # pieces lying together (a lamp's layers) get one cut, measured over all of them
        merged = []
        for pc in groups:
            m = mid_of(pc)
            for g in merged:
                if np.linalg.norm(g[0] - m) < op["group"]:
                    g[1].extend(pc)
                    break
            else:
                merged.append([m, list(pc)])
        groups = [g[1] for g in merged]
        print("DETAILS clip groups", len(groups))
    for pc in groups:
        if "frac" in op:
            t = np.array([c[0] for c in corners(pc)]) @ nn
            p0 = nn * (t.min() + op["frac"] * (t.max() - t.min()))
        else:
            p0 = np.array(pt, float)
        for c in corners(pc):
            q = np.array(c[0])
            d = (q - p0) @ nn
            if d > 0:
                c[0] = tuple(q - d * nn)
    return faces


def op_respace(op, faces):
    ax = np.array(op["axis"], float)
    ax /= np.linalg.norm(ax)
    pcs = pieces(faces)
    pcs.sort(key=lambda pc: float(mid_of(pc) @ ax))
    t = [float(mid_of(pc) @ ax) for pc in pcs]
    n = op["count"]
    if len(pcs) < 2:
        return faces
    first, last = pcs[0], pcs[-1]
    inner = pcs[1:-1]
    template = inner[len(inner) // 2] if inner else first
    import copy

    out = list(first) + list(last)
    for i in range(1, n - 1):
        ti = t[0] + (t[-1] - t[0]) * i / (n - 1)
        src_pc = inner[i - 1] if (len(inner) == n - 2) else template
        pc = copy.deepcopy(src_pc)
        shift = (ti - float(mid_of(pc) @ ax)) * ax
        for c in corners(pc):
            c[0] = tuple(np.array(c[0]) + shift)
        out += pc
    print("DETAILS respace", len(pcs), "->", n)
    return out


def op_scale(op, faces):
    s = np.array(op["s"], float)
    out = []
    for pc in pieces(faces):
        m = mid_of(pc)
        for c in corners(pc):
            c[0] = tuple(m + (np.array(c[0]) - m) * s)
        out += pc
    return out


def op_move(op, faces):
    d = np.array(op["d"], float)
    for c in corners(faces):
        c[0] = tuple(np.array(c[0]) + d)
    return faces


def surface_sample(o, point):
    """picture spot and colour of o's surface nearest a point"""
    me = o.data
    M = o.matrix_world
    me.calc_loop_triangles()
    verts = [M @ v.co for v in me.vertices]
    tris = [tuple(t.vertices) for t in me.loop_triangles]
    bvh = BVHTree.FromPolygons(verts, tris, all_triangles=True)
    loc, nrm, ti, dist = bvh.find_nearest(Vector(point))
    t = me.loop_triangles[ti]
    uvl = me.uv_layers.active
    ca = color_layer(me)
    li = t.loops[0]
    uv = tuple(uvl.data[li].uv) if uvl else (0.5, 0.5)
    col = None
    if ca is not None:
        col = tuple(ca.data[li if ca.domain == "CORNER" else t.vertices[0]].color)
    print("DETAILS sample", base(o.name), "at", [round(x, 3) for x in loc], "dist", round(dist, 4), "uv", [round(x, 3) for x in uv], "mat", t.material_index)
    return uv, col, t.material_index


def op_fin(op, o, mirror=False):
    o_ = Vector(op["o"]) + OFF
    u, v = Vector(op["u"]), Vector(op["v"])
    fr = Vector(op.get("from", tuple(o_ + u / 2 + v / 2)))
    if mirror:
        o_ = Vector((2 * OFF.x - o_.x, o_.y, o_.z))
        u, v = Vector((-u.x, u.y, u.z)), Vector((-v.x, v.y, v.z))
        fr = Vector((2 * OFF.x - fr.x, fr.y, fr.z))
    w = u.cross(v).normalized() * op.get("t", 0.006)
    uv, col, mat = surface_sample(o, fr)
    bm = bmesh.new()
    c0 = o_ - w / 2
    P = [c0, c0 + u, c0 + u + v, c0 + v]
    vs = [bm.verts.new(p) for p in P] + [bm.verts.new(p + w) for p in P]
    for q in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in q])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if op.get("bevel", 0.002) > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=op.get("bevel", 0.002), segments=1, affect="EDGES", profile=0.5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    faces = []
    for f in bm.faces:
        n = tuple(f.normal)
        faces.append((mat, [[tuple(l.vert.co), uv, n, col] for l in f.loops]))
    bm.free()
    return faces


# --- render ----------------------------------------------------------------------------------------------------------
def setup_render():
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
    bpy.ops.mesh.primitive_plane_add(size=60, location=(OFF.x, OFF.y, OFF.z))
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


CAM = None


def place(shot):
    cam, co = CAM
    cam.lens = shot.get("lens", 50)
    eye = Vector(shot["eye"]) + OFF
    look = Vector(shot["look"]) + OFF
    co.location = eye
    co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()


LIGHTS = {}


def render(tag):
    for shot in job.get("shots", []):
        place(shot)
        for lo_ in LIGHTS.values():
            lo_.hide_render = True
        if shot.get("light"):
            # a lamp for a look into a dark spot (under the bumper)
            if shot["name"] not in LIGHTS:
                ld = bpy.data.lights.new("l_" + shot["name"], "POINT")
                ld.energy = shot.get("power", 40)
                ld.shadow_soft_size = 0.3
                lo_ = bpy.data.objects.new("l_" + shot["name"], ld)
                lo_.location = Vector(shot["light"]) + OFF
                sc.collection.objects.link(lo_)
                LIGHTS[shot["name"]] = lo_
            LIGHTS[shot["name"]].hide_render = False
        sc.render.filepath = "%s_%s_%s.png" % (PREFIX, shot["name"], tag)
        bpy.ops.render.render(write_still=True)
    print("DETAILS rendered", tag, len(job.get("shots", [])))


def probe():
    cam, co = CAM
    dg = bpy.context.evaluated_depsgraph_get()
    shots = {s["name"]: s for s in job.get("shots", [])}
    for pr in job.get("probe", []):
        place(shots[pr["shot"]])
        dg = bpy.context.evaluated_depsgraph_get()
        fr = cam.view_frame(scene=sc)
        tr, br, bl, tl = fr[0], fr[1], fr[2], fr[3]
        for x, y in pr["px"]:
            u, v = x / 1280, y / 800
            p = bl.lerp(tl, 1 - v).lerp(br.lerp(tr, 1 - v), u)
            d = (co.matrix_world.to_3x3() @ p).normalized()
            hit, loc, nrm, idx, obj, mat = sc.ray_cast(dg, co.location, d)
            if hit:
                L = loc - OFF
                print("DETAILS probe", pr["shot"], (x, y), base(obj.name), [round(c, 3) for c in L], "n", [round(c, 2) for c in nrm])
            else:
                print("DETAILS probe", pr["shot"], (x, y), "nothing")


def listing():
    for it in job.get("list", []):
        b = np.array(it["box"], float) + np.array(tuple(OFF) * 2)
        if it["part"] != "*" and not any(base(o.name) == it["part"].split("#")[0] for o in CAR):
            print("DETAILS list: no part", it["part"])
            continue
        names = [o for o in CAR] if it["part"] == "*" else [part(it["part"])]
        rows = []
        for o in names:
            comps, co = pieces_in(o, [b], it)
            for c in comps:
                p = co[c] - np.array(tuple(OFF))
                lo, hi = p.min(0), p.max(0)
                rows.append(((hi - lo).max(), base(o.name), (lo + hi) / 2, hi - lo, len(c)))
        rows.sort(key=lambda r: -r[0])
        print("DETAILS list", it["part"], it["box"], len(rows), "pieces")
        for r in rows[: int(it.get("count", 40))]:
            print("   ", r[1], "mid", [round(x, 3) for x in r[2]], "size", [round(x, 3) for x in r[3]], "verts", r[4])


MARK = None


def mark_mat():
    global MARK
    if MARK is None:
        MARK = bpy.data.materials.new("mark")
        MARK.use_nodes = True
        b = MARK.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (1, 0, 1, 1)
        b.inputs["Emission Color"].default_value = (1, 0, 1, 1)
        b.inputs["Emission Strength"].default_value = 2.0
    return MARK


def show_mark(faces, name="mark"):
    if not faces:
        return
    verts, polys = [], []
    for _, f in faces:
        ids = []
        for c in f:
            ids.append(len(verts))
            verts.append(Vector(c[0]) + Vector(c[2]) * 0.0015)
        polys.append(ids)
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], polys)
    me.materials.append(mark_mat())
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)


# --- run -------------------------------------------------------------------------------------------------------------
touched = []
before = {}


def touch(o):
    if o.name not in before:
        before[o.name] = box_of(o)
        touched.append(o)


def parts_named(name):
    """every object of that name (some cars have many parts of one name); "Name#faces" picks one"""
    if "#" in name:
        return [part(name)]
    lst = [o for o in CAR if base(o.name) == name]
    if not lst:
        part(name)  # (prints the names there are and stops)
    return lst


def run_ops(view):
    for op in job.get("ops", []):
        kind = op["op"]
        if kind == "fin":
            o = part(op["part"])
            fs = op_fin(op, o)
            if op.get("mirror"):
                fs += op_fin(op, o, mirror=True)
            if view:
                show_mark(fs)
            else:
                touch(o)
                put(o, fs, fresh=True)
            continue
        found = 0
        for o in parts_named(op["part"]):
            comps, _ = pieces_in(o, boxes_of(op), op)
            if not comps:
                continue
            found += len(comps)
            print("DETAILS", kind, base(o.name), len(comps), "pieces")
            if view:
                show_mark(take(o, comps, remove=False))
                continue
            touch(o)
            faces = take(o, comps)
            fresh = kind in ("shape", "clip", "scale")
            if kind == "drop":
                continue
            if kind == "shape":
                faces = op_shape(op, faces)
            elif kind == "clip":
                pt, nn = list(op.get("p", (0, 0, 0))), list(op["n"])
                pt = [pt[0] + OFF.x, pt[1] + OFF.y, pt[2] + OFF.z]
                if op.get("mirror"):
                    left = [f for f in faces if np.mean([c[0][0] for c in f[1]]) - OFF.x < 0]
                    right = [f for f in faces if np.mean([c[0][0] for c in f[1]]) - OFF.x >= 0]
                    side_l = (pt[0] - OFF.x) < 0
                    a, b = (left, right) if side_l else (right, left)
                    op_clip(op, a, pt, nn)
                    op_clip(op, b, [2 * OFF.x - pt[0], pt[1], pt[2]], [-nn[0], nn[1], nn[2]])
                else:
                    op_clip(op, faces, pt, nn)
            elif kind == "respace":
                faces = op_respace(op, faces)
            elif kind == "scale":
                faces = op_scale(op, faces)
            elif kind == "move":
                faces = op_move(op, faces)
            put(o, faces, fresh=fresh)
        if not found:
            print("DETAILS warning: no pieces for", json.dumps(op)[:200])


_lo = np.min([b[0] for b in (box_of(o) for o in CAR) if b], 0)
_hi = np.max([b[1] for b in (box_of(o) for o in CAR) if b], 0)
print("DETAILS car box", [round(x, 3) for x in _lo], [round(x, 3) for x in _hi])
if job.get("auto"):
    # standard looks from the car's box (front -Y): far shots like the game's camera, then close-ups
    hx, ly, hy, hz = float(_hi[0]), float(_lo[1]), float(_hi[1]), float(_hi[2])
    my = (ly + hy) / 2
    std = [
        {"name": "far_rear", "eye": [2.6, hy + 5.8, 2.3], "look": [0, my + 0.8, 0.5], "lens": 40},
        {"name": "far_front", "eye": [-3.2, ly - 4.1, 1.6], "look": [0, my - 0.4, 0.5], "lens": 40},
        {"name": "tail", "eye": [0.45 * hx, hy + 2.0, 0.85 * hz], "look": [0, hy - 0.1, 0.55 * hz], "lens": 40},
        {"name": "lamp", "eye": [0.7 * hx, hy + 1.25, 0.8 * hz], "look": [0.55 * hx, hy - 0.1, 0.66 * hz], "lens": 55},
        {"name": "exhaust", "eye": [0.15, hy + 1.0, 0.42 * hz], "look": [0, hy - 0.1, 0.28 * hz], "lens": 40},
        {"name": "side", "eye": [hx + 1.6, my + 0.2, 0.6 * hz], "look": [hx - 0.1, my + 0.3, 0.5 * hz], "lens": 30},
        {"name": "front", "eye": [0.6 * hx, ly - 1.5, 0.5 * hz], "look": [0.35 * hx, ly + 0.15, 0.35 * hz], "lens": 40},
        {"name": "nose", "eye": [-0.3, ly - 2.2, 0.9 * hz], "look": [0, ly + 0.3, 0.45 * hz], "lens": 40},
    ]
    have = {s_["name"] for s_ in job.get("shots", [])}
    job["shots"] = job.get("shots", []) + [s_ for s_ in std if s_["name"] not in have and s_["name"] in job.get("auto_names", [s_["name"] for s_ in std])]
if job.get("info"):
    for o in sorted(CAR, key=lambda o: o.name):
        ims = []
        for slot in o.material_slots:
            if slot.material and slot.material.use_nodes:
                ims += ["%s %dx%d" % (n.image.name[:20], n.image.size[0], n.image.size[1]) for n in slot.material.node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
        b = box_of(o)
        size = (np.array(b[1]) - np.array(b[0])).round(2).tolist() if b else None
        print("DETAILS part", base(o.name), len(o.data.polygons), size, ims)
if job.get("dump_tiles"):
    # small repeating pictures (grilles, meshes) saved as <prefix>_tile_<part>_colour/normal.png for details_tiles.py
    lim = job.get("tile_max", 128)
    for o in CAR:
        for slot in o.material_slots:
            m = slot.material
            if not (m and m.use_nodes):
                continue
            for lk in m.node_tree.links:
                n = lk.from_node
                if n.type != "TEX_IMAGE" or not n.image or max(n.image.size) > lim or min(n.image.size) < 8:
                    continue
                key = "normal" if lk.to_node.type == "NORMAL_MAP" else "colour" if lk.to_socket.name == "Base Color" else None
                if not key:
                    continue
                path = "%s_tile_%s_%s.png" % (PREFIX, base(o.name), key)
                try:
                    im = n.image.copy()
                    im.filepath_raw = path
                    im.file_format = "PNG"
                    im.save()
                except RuntimeError as e:
                    print("DETAILS tile skipped", base(o.name), key, str(e)[:80])
                    continue
                print("DETAILS tile", base(o.name), key, n.image.size[:], path)
CAM = setup_render()
listing()
if MODE == "view":
    run_ops(view=True)
    probe()
    render("view")
    sys.exit(0)

def swap_tiles():
    """the new grille pictures (tools/details_tiles.py) on their parts, for the after shots only"""
    for name, t in job.get("tiles", {}).items():
        o = part(name)
        for slot in o.material_slots:
            m = slot.material
            if not (m and m.use_nodes):
                continue
            for lk in m.node_tree.links:
                n = lk.from_node
                if n.type != "TEX_IMAGE":
                    continue
                key = "normal" if lk.to_node.type == "NORMAL_MAP" else "colour" if lk.to_socket.name == "Base Color" else None
                path = t.get(key) if key else None
                if path:
                    if not os.path.isabs(path):
                        path = os.path.join(os.path.dirname(os.path.abspath(args[0])), path)
                    im = bpy.data.images.load(path)
                    im.colorspace_settings.name = "Non-Color" if key == "normal" else "sRGB"
                    n.image = im
        print("DETAILS tiles", name)


render("before")
run_ops(view=False)
swap_tiles()
render("after")

export = [part(n) for n in job["export"]] if "export" in job else touched
if not export:
    # (pictures only: nothing to upload as a model)
    print("DETAILS no mesh changes, pictures only")
    sys.exit(0)
report = {}
obs = []
keys = {}
for o in export:
    name = base(o.name)
    lo, hi = box_of(o)
    b = before.get(o.name)
    # (parts of one name get a name each in the file: name__<faces before>; "part" keeps the real one for DetailsApply)
    same = [x for x in export if base(x.name) == name]
    key = name if len(same) == 1 else "%s__%d" % (name, len(o.data.polygons))
    report[key] = {"before": b, "after": [lo, hi], "faces": len(o.data.polygons), "part": name}
    keys[o] = key
    obs.append(o)
report["__like"] = {}
for o in obs:
    W = o.matrix_world.copy()
    o.parent = None
    o.data.transform(W)
    o.matrix_world = Matrix.Identity(4)
for o in list(bpy.data.objects):
    if o not in obs:
        bpy.data.objects.remove(o)
for o in obs:
    o.name = keys[o]
bpy.ops.object.select_all(action="DESELECT")
for o in obs:
    o.select_set(True)
bpy.context.view_layer.objects.active = obs[0]
out = os.path.join(ROOT, job["out"])
os.makedirs(os.path.dirname(out), exist_ok=True)
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, global_scale=1.0, apply_unit_scale=True,
                         bake_space_transform=False, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False,
                         path_mode="STRIP")  # (no picture paths: a broken one made Open Cloud refuse the STO file; looks come from the parts in Studio)
# (read back and written again: Open Cloud refused some first exports, the STO's, with "Failed to parse the uploaded
# file"; the same parts read back and written again by Blender go through)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=out, axis_forward="-Z", axis_up="Y")
for o in bpy.data.objects:
    o.select_set(o.type == "MESH")
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"MESH"}, axis_forward="-Z", axis_up="Y",
                         mesh_smooth_type="FACE", path_mode="STRIP")
json.dump(report, open(out + ".json", "w"), indent=0)
print("DETAILS wrote", out, os.path.getsize(out) // 1024, "KB", {k: v.get("faces") for k, v in report.items() if k != "__like"})
