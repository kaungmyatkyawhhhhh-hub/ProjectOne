"""One family's cockpit shared across its cars (owner, 2026-11-03, the Bugattis: "the Veyron and the
Chiron do NOT share a cluster"; inside each family the best cluster and steering wheel go in every
car). Runs on a converted car (.blend from auto_car.py: front -Y, up +Z, metres) and saves it.

    blender -b --python tools/share_cockpit.py -- car.blend [options]

  --wheel donor.blend          the donor's steering wheel at this car's own wheel spot and tilt (the
                               donor's pieces take this car's "SteeringWheel_t<tilt>" names)
  --wheel-img NAME=file.png    on the donor wheel, image NAME (its base name, without Blender's .001)
                               swapped for file.png (e.g. its leather recoloured for this cabin)
  --screen "donor.blend|object|cx,cy,cz|nx,ny,nz|tx,ty,tz|mx,my,mz"
                               the donor's screen part moved from its centre / normal onto this
                               car's (3 mm towards the driver); this car's own faces within 16 mm
                               of it are removed (they poked through)
  --needles "donor.blend|object|json"
                               the donor's needle part (several loose needles) split up; each needle
                               goes onto this car's matching dial (json: {"dials": {kind: [donor
                               centre, donor radius, target centre, target radius, normal]}}), named
                               Needle_<kind>, with a NeedlePivot_<kind> marker at the dial's middle
  --split-needles "object|json" this car's own needle part split into Needle_<kind> + pivots (json as
                               above, donor = this car)
  --cut-hub "mat,R,Z[,cx,cy]"         on the steering wheel pieces of material `mat`, the faces within R m of
                               the column and over Z m towards the driver go (raised logo letters on
                               the hub, in the wheel's own frame: z = the column)
  --cut-box "mat|x0,y0,z0|x1,y1,z1"  faces of material `mat` with their middle inside the box go
                               (raised maker's letters on the body; may be given more than once)
  --cut-islands "mat|x0,y0,z0|x1,y1,z1"  loose pieces of material `mat` lying wholly inside the box go
                               (raised letters joined into a body panel of the same material)
  --cap-hub "mat,R,Z[,cx,cy[,Ry,u,v]]"         a flat disc R m round at Z m on the column added to the steering wheel
                               piece of material `mat` (covers the holes the logo letters sat in)
"""

import json
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

args = sys.argv[sys.argv.index("--") + 1:]
path = args[0]
bpy.ops.wm.open_mainfile(filepath=path)
sc = bpy.context.scene
report = {}


def opt(name):
    return args[args.index(name) + 1] if name in args else None


def vec(s):
    return Vector([float(v) for v in s.split(",")])


def steer_objs():
    return [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("SteeringWheel")]


# ---------------------------------------------------------------- steering wheel
if opt("--wheel"):
    own = steer_objs()
    main = max(own, key=lambda o: len(o.data.polygons))
    base = main.name.split(".")[0]
    frame_t = main.matrix_world.copy()
    with bpy.data.libraries.load(opt("--wheel")) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("SteeringWheel")]
    dmain = max(dst.objects, key=lambda o: len(o.data.polygons))
    frame_d = dmain.matrix_world.copy()
    for o in own:
        bpy.data.objects.remove(o, do_unlink=True)
    order = sorted(dst.objects, key=lambda o: -len(o.data.polygons))
    for i, o in enumerate(order):
        sc.collection.objects.link(o)
        o.matrix_world = frame_t @ frame_d.inverted() @ o.matrix_world
        o.name = base if i == 0 else f"{base}.{i:03d}"
    if opt("--wheel-img"):
        for spec in [args[k + 1] for k, a in enumerate(args) if a == "--wheel-img"]:
            name, file = spec.split("=")
            new = bpy.data.images.load(file)
            new.pack()
            for o in order:
                for m in o.data.materials:
                    if m and m.use_nodes:
                        for nd in m.node_tree.nodes:
                            if nd.type == "TEX_IMAGE" and nd.image and nd.image.name.split(".")[0] == name:
                                nd.image = new
    report["wheel"] = [o.name for o in order]

# ---------------------------------------------------------------- screen
if opt("--screen"):
    spec = opt("--screen").split("|")
    cd, nd_, ct, nt = (vec(x) for x in spec[2:6])
    with bpy.data.libraries.load(spec[0]) as (src, dst):
        dst.objects = [spec[1]]
    scr = dst.objects[0]
    sc.collection.objects.link(scr)
    rot = nd_.normalized().rotation_difference(nt.normalized()).to_matrix().to_4x4()
    scr.matrix_world = Matrix.Translation(ct + nt.normalized() * 0.003) @ rot @ Matrix.Translation(-cd) @ scr.matrix_world
    bm0 = bmesh.new()
    bm0.from_mesh(scr.data)
    bm0.transform(scr.matrix_world)
    tree = BVHTree.FromBMesh(bm0)
    n = nt.normalized()
    gone = 0
    for t in bpy.data.objects:
        if t.type != "MESH" or t == scr or t.name.startswith("SteeringWheel") or t.name.startswith("Wheels") or t.name[:2] in ("FL", "FR", "RL", "RR"):
            continue
        bm = bmesh.new()
        bm.from_mesh(t.data)
        mw = t.matrix_world
        kill = []
        for f in bm.faces:
            fc = mw @ f.calc_center_median()
            if (fc - ct).length > 0.25:
                continue
            for sgn in (1, -1):
                if tree.ray_cast(fc - n * 0.016 * sgn, n * sgn, 0.032)[0] is not None:
                    kill.append(f)
                    break
        if kill:
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(t.data)
            gone += len(kill)
        bm.free()
    report["screen"] = scr.name
    report["screen_faces_removed"] = gone


# ---------------------------------------------------------------- needles
def loose_parts(o):
    """o's loose pieces as lists of face indices."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    seen, parts = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, part = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            part.append(g.index)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        parts.append(part)
    bm.free()
    return parts


def sub_object(o, faces, name):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    keep = set(faces)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in o.data.materials:
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    ob.matrix_world = o.matrix_world.copy()
    sc.collection.objects.link(ob)
    return ob


def marker(name, at, normal):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.004)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    ob.matrix_world = Matrix.Translation(at) @ Vector((0, 0, 1)).rotation_difference(normal).to_matrix().to_4x4()
    sc.collection.objects.link(ob)
    return ob


def place_needles(src_obj, dials, remove_src):
    """src_obj's loose needles, each matched to the nearest donor dial centre, moved onto that
    dial's target spot (scaled by the radius ratio, turned to the target face)."""
    pieces = loose_parts(src_obj)
    groups = {}
    for faces in pieces:
        me = src_obj.data
        pts = [src_obj.matrix_world @ me.vertices[v].co for f in faces for v in me.polygons[f].vertices]
        c = sum(pts, Vector()) / len(pts)
        kind = min(dials, key=lambda k: (vec(dials[k][0]) - c).length)
        groups.setdefault(kind, []).extend(faces)
    made = []
    for kind, faces in groups.items():
        dc, dr, tc, tr, tn = dials[kind][:5]
        dc, tc, tn = vec(dc), vec(tc), vec(tn).normalized()
        ob = sub_object(src_obj, faces, f"Needle_{kind}")
        dn = vec(dials[kind][5]).normalized() if len(dials[kind]) > 5 else tn
        rot = dn.rotation_difference(tn).to_matrix().to_4x4()
        s = tr / dr
        ob.matrix_world = Matrix.Translation(tc + tn * 0.0015) @ rot @ Matrix.Scale(s, 4) @ Matrix.Translation(-dc) @ ob.matrix_world
        marker(f"NeedlePivot_{kind}", tc + tn * 0.0015, tn)
        made.append(kind)
    if remove_src:
        bpy.data.objects.remove(src_obj, do_unlink=True)
    return made


if opt("--needles"):
    blend, name, js = opt("--needles").split("|")
    with bpy.data.libraries.load(blend) as (src, dst):
        dst.objects = [name]
    o = dst.objects[0]
    sc.collection.objects.link(o)
    report["needles"] = place_needles(o, json.load(open(js))["dials"], True)

if opt("--split-needles"):
    name, js = opt("--split-needles").split("|")
    report["needles"] = place_needles(bpy.data.objects[name], json.load(open(js))["dials"], True)

if opt("--cut-hub"):
    mat, R, Z, cx, cy = (opt("--cut-hub") + ",0,0").split(",")[:5]
    R, Z, cx, cy = float(R), float(Z), float(cx), float(cy)
    cut = 0
    for o in steer_objs():
        if not any(m and mat in m.name for m in o.data.materials):
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        kill = []
        for f in bm.faces:
            c = f.calc_center_median()
            if math.hypot(c.x - cx, c.y - cy) < R and c.z > Z:
                kill.append(f)
        if kill:
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(o.data)
            cut += len(kill)
        bm.free()
    report["hub_faces_cut"] = cut

if opt("--cap-hub"):
    parts = opt("--cap-hub").split(",")
    parts += ["0", "0"][: max(0, 5 - len(parts))]
    mat, R, Z, cx, cy = parts[0], float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4])
    Ry = float(parts[5]) if len(parts) > 5 else R  # an oval cap: its half-height
    cap_uv = (float(parts[6]), float(parts[7])) if len(parts) > 7 else None  # one texel's colour
    for o in steer_objs():
        if o.data.materials and o.data.materials[0] and mat in o.data.materials[0].name:
            bm = bmesh.new()
            bm.from_mesh(o.data)
            res = bmesh.ops.create_circle(bm, cap_ends=True, segments=48, radius=R)
            for v in res["verts"]:
                v.co.x = v.co.x + cx
                v.co.y = v.co.y * (Ry / R) + cy
                v.co.z = Z
            if cap_uv:
                uvl = bm.loops.layers.uv.active
                for f in {f for v in res["verts"] for f in v.link_faces}:
                    for lp in f.loops:
                        lp[uvl].uv = cap_uv
            bm.normal_update()
            for f in {f for v in res["verts"] for f in v.link_faces}:
                if f.normal.z < 0:
                    f.normal_flip()
                f.material_index = 0
            bm.to_mesh(o.data)
            bm.free()
            report["hub_cap"] = o.name
            break

boxes = [args[k + 1] for k, a in enumerate(args) if a == "--cut-box"]
if boxes:
    gone = 0
    for spec in boxes:
        mat, a, b = spec.split("|")
        lo, hi = vec(a), vec(b)
        for o in bpy.data.objects:
            if o.type != "MESH" or not any(m and mat in m.name for m in o.data.materials):
                continue
            mw = o.matrix_world
            bm = bmesh.new()
            bm.from_mesh(o.data)
            kill = []
            for f in bm.faces:
                m = o.data.materials[f.material_index] if f.material_index < len(o.data.materials) else None
                c = mw @ f.calc_center_median()
                if m and mat in m.name and all(lo[i] <= c[i] <= hi[i] for i in range(3)):
                    kill.append(f)
            if kill:
                bmesh.ops.delete(bm, geom=kill, context="FACES")
                bm.to_mesh(o.data)
                gone += len(kill)
            bm.free()
    report["box_faces_cut"] = gone

islands = [args[k + 1] for k, a in enumerate(args) if a == "--cut-islands"]
if islands:
    gone = 0
    for spec in islands:
        mat, a, b = spec.split("|")
        lo, hi = vec(a), vec(b)
        for o in bpy.data.objects:
            if o.type != "MESH" or not any(m and mat in m.name for m in o.data.materials):
                continue
            mw = o.matrix_world
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bm.faces.ensure_lookup_table()
            seen, kill = set(), []
            for f in bm.faces:
                if f.index in seen:
                    continue
                stack, part = [f], []
                seen.add(f.index)
                while stack:
                    g = stack.pop()
                    part.append(g)
                    for e in g.edges:
                        for h in e.link_faces:
                            if h.index not in seen:
                                seen.add(h.index)
                                stack.append(h)
                inside = all(all(lo[i] <= (mw @ v.co)[i] <= hi[i] for i in range(3)) for g in part for v in g.verts)
                mats_ok = all(g.material_index < len(o.data.materials) and o.data.materials[g.material_index] and mat in o.data.materials[g.material_index].name for g in part)
                if inside and mats_ok:
                    kill.extend(part)
            if kill:
                bmesh.ops.delete(bm, geom=kill, context="FACES")
                bm.to_mesh(o.data)
                gone += len(kill)
            bm.free()
    report["island_faces_cut"] = gone

bpy.ops.wm.save_as_mainfile(filepath=path)
print("SHARE", json.dumps(report))
