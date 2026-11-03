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
  --screen-fit spec.json        (owner, 2026-11-03: "the clusters aren't aligned properly in the Chiron
                               Super Sport and Pur Sport") the donor's screen in two pieces: its dial
                               (cut out round the dial's inner ring) scaled and moved onto this car's
                               own dial ring, and the rest (the side screens) fitted to this car's
                               screen window; see screen_fit() for the spec
  --binnacle "donor.blend|donor_dials.json|target_dials.json"
                               (owner, same day: "the cluster doesn't look smooth in the Veyron Super
                               Sport and Grand Sport") the donor's whole instrument binnacle (dial
                               faces, chrome bezels, needles) moved onto this car's dials by the best
                               fit of the dial centres (rotation, one scale, move); this car's own
                               faceted dials are cut out first. Dials json: {kind: [[x,y,z], r, [nx,ny,nz]]}

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
    if isinstance(s, (list, tuple)):
        return Vector([float(v) for v in s])
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


# ---------------------------------------------------------------- screen fitted in two pieces
def world_of(frame, px, py):
    """a pixel of an ortho check render (rotated 180, as the driver sees it) -> a point on its plane"""
    c, cx, cy, mpp, res = vec(frame["c"]), vec(frame["camX"]), vec(frame["camY"]), frame["mpp"], frame["res"]
    return c + (px - res / 2) * mpp * (-cx) + (py - res / 2) * mpp * cy


def ray_hit(objs, p, n):
    """where a ray along -n through p meets objs (the face nearest the driver)"""
    dg = bpy.context.evaluated_depsgraph_get()
    best = None
    for o in objs:
        inv = o.matrix_world.inverted()
        start = inv @ (p + n * 0.2)
        d = (inv.to_3x3() @ (-n)).normalized()
        ok, loc, nrm, idx = o.ray_cast(start, d, distance=1.0)
        if ok:
            w = o.matrix_world @ loc
            if best is None or (w - p).dot(n) > (best - p).dot(n):
                best = w
    return best


def screen_fit(spec):
    """spec: {"donor": blend, "object": name,
              "donor_frame" / "target_frame": {"c", "camX", "camY", "mpp", "res"} (the check renders),
              "donor_ring" / "target_ring": [px, py, rpx] (the dial's inner ring in those renders),
              "donor_window" / "target_window": [x0, x1, y0, y1] (the screen window, wide renders,
              frames "donor_wide" / "target_wide"), "cut": 1.03 (the dial piece's radius in rings)}"""
    with bpy.data.libraries.load(spec["donor"]) as (src, dst):
        dst.objects = [spec["object"]]
    scr = dst.objects[0]
    sc.collection.objects.link(scr)
    targets = [o for o in bpy.data.objects if o.type == "MESH" and o != scr and not o.name.startswith(("SteeringWheel", "Needle_", "Wheels")) and o.name[:2] not in ("FL", "FR", "RL", "RR")]
    fd, ft = spec["donor_frame"], spec["target_frame"]
    nd_ = vec(fd["camX"]).cross(vec(fd["camY"])).normalized()
    nt = vec(ft["camX"]).cross(vec(ft["camY"])).normalized()
    # (the camera looks along -n: n points at the driver)
    if nd_.y < 0:
        nd_ = -nd_
    if nt.y < 0:
        nt = -nt
    rot = nd_.rotation_difference(nt).to_matrix().to_4x4()
    # the dial: ring centre to ring centre, ring size to ring size
    dx, dy, dr = spec["donor_ring"]
    tx, ty, tr = spec["target_ring"]
    dc = ray_hit([scr], world_of(fd, dx, dy), nd_)
    tc = ray_hit(targets, world_of(ft, tx, ty), nt)
    k_dial = (tr * ft["mpp"]) / (dr * fd["mpp"])
    R_d = dr * fd["mpp"]
    # split the screen at the ring: tangent cuts all round, then the faces inside are the dial
    bm = bmesh.new()
    bm.from_mesh(scr.data)
    bm.transform(scr.matrix_world)
    cut = spec.get("cut", 1.03) * R_d
    u = (vec(fd["camX"]) - nd_ * vec(fd["camX"]).dot(nd_)).normalized()
    v = nd_.cross(u)
    N = 40
    for k in range(N):
        a = 2 * math.pi * k / N
        dirv = u * math.cos(a) + v * math.sin(a)
        geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
        bmesh.ops.bisect_plane(bm, geom=geom, plane_co=dc + dirv * cut, plane_no=dirv)
    lim = cut / math.cos(math.pi / N) + 1e-5
    inside = []
    for f in bm.faces:
        q = f.calc_center_median() - dc
        q -= nd_ * q.dot(nd_)
        if all(q.dot(u * math.cos(2 * math.pi * k / N) + v * math.sin(2 * math.pi * k / N)) <= cut + 1e-6 for k in range(N)):
            inside.append(f)
    bm2 = bm.copy()
    keep_in = {f.index for f in inside}
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index in keep_in], context="FACES")
    bm2.faces.ensure_lookup_table()
    bmesh.ops.delete(bm2, geom=[f for f in bm2.faces if f.index not in keep_in], context="FACES")
    rest_me = bpy.data.meshes.new(scr.name + "_rest")
    bm.to_mesh(rest_me)
    dial_me = bpy.data.meshes.new(scr.name + "_dial")
    bm2.to_mesh(dial_me)
    bm.free()
    bm2.free()
    for me in (rest_me, dial_me):
        for m in scr.data.materials:
            me.materials.append(m)
    # the rest: window to window (the width ratio), anchored between the two side screens
    wx0, wx1, wy0, wy1 = spec["donor_window"]
    tx0, tx1, ty0, ty1 = spec["target_window"]
    fdw, ftw = spec["donor_wide"], spec["target_wide"]
    k_rest = ((tx1 - tx0) * ftw["mpp"]) / ((wx1 - wx0) * fdw["mpp"])
    tmp_rest = bpy.data.objects.new("tmp", rest_me)
    sc.collection.objects.link(tmp_rest)
    pts_d, pts_t = [], []
    for fx in (0.14, 0.86):
        for fy in (0.35, 0.65):
            pd = ray_hit([tmp_rest], world_of(fdw, wx0 + fx * (wx1 - wx0), wy0 + fy * (wy1 - wy0)), nd_)
            pt = ray_hit(targets, world_of(ftw, tx0 + fx * (tx1 - tx0), ty0 + fy * (ty1 - ty0)), nt)
            if pd is not None and pt is not None:
                pts_d.append(pd)
                pts_t.append(pt)
    bpy.data.objects.remove(tmp_rest, do_unlink=True)
    ad = sum(pts_d, Vector()) / len(pts_d)
    at = sum(pts_t, Vector()) / len(pts_t)
    M_rest = Matrix.Translation(at + nt * 0.003) @ rot @ Matrix.Scale(k_rest, 4) @ Matrix.Translation(-ad)
    M_dial = Matrix.Translation(tc + nt * 0.0045) @ rot @ Matrix.Scale(k_dial, 4) @ Matrix.Translation(-dc)
    made = []
    for me, M, name in ((rest_me, M_rest, scr.name), (dial_me, M_dial, scr.name.replace("Dashboard1", "Dashboard1Dial"))):
        me.transform(M)
        ob = bpy.data.objects.new(name + "_fit", me)
        sc.collection.objects.link(ob)
        made.append(ob)
    bpy.data.objects.remove(scr, do_unlink=True)
    made[0].name = spec["object"]
    made[1].name = spec["object"].replace("Dashboard1", "Dashboard1Dial")
    # this car's own faces right behind either piece go
    gone = 0
    for piece in made:
        bm0 = bmesh.new()
        bm0.from_mesh(piece.data)
        bm0.transform(piece.matrix_world)
        tree = BVHTree.FromBMesh(bm0)
        for t in targets:
            bm = bmesh.new()
            bm.from_mesh(t.data)
            mw = t.matrix_world
            kill = []
            for f in bm.faces:
                fc = mw @ f.calc_center_median()
                if (fc - tc).length > 0.3:
                    continue
                for sgn in (1, -1):
                    if tree.ray_cast(fc - nt * 0.016 * sgn, nt * sgn, 0.032)[0] is not None:
                        kill.append(f)
                        break
            if kill:
                bmesh.ops.delete(bm, geom=kill, context="FACES")
                bm.to_mesh(t.data)
                gone += len(kill)
            bm.free()
        bm0.free()
    report["screen_fit"] = {"k_dial": round(k_dial, 4), "k_rest": round(k_rest, 4), "dial_centre": [round(x, 4) for x in tc], "faces_removed": gone}


if opt("--screen-fit"):
    screen_fit(json.load(open(opt("--screen-fit"))))


# ---------------------------------------------------------------- binnacle transplant
def similarity(A, B):
    """the rotation, scale and move taking points A onto B (least squares, Umeyama)"""
    import numpy as np
    A = np.array([list(a) for a in A])
    B = np.array([list(b) for b in B])
    ma, mb = A.mean(0), B.mean(0)
    A0, B0 = A - ma, B - mb
    U, S, Vt = np.linalg.svd(B0.T @ A0 / len(A))
    D = np.eye(3)
    if np.linalg.det(U @ Vt) < 0:
        D[2, 2] = -1
    Rm = U @ D @ Vt
    k = np.trace(np.diag(S) @ D) / (A0 ** 2).sum(1).mean()
    t = mb - k * Rm @ ma
    M = Matrix.Identity(4)
    for i in range(3):
        for j in range(3):
            M[i][j] = k * Rm[i, j]
        M[i][3] = t[i]
    err = float(np.sqrt(((k * (Rm @ A.T).T + t - B) ** 2).sum(1)).max())
    return M, float(k), err


SKIP_MATS = ("CUERO", "COSTURA", "GLASS", "MOTOSO", "rubber")


def in_dials(p, dials, rk, a0, a1):
    for c, r, n in dials:
        d = p - c
        a = d.dot(n)
        if a0 <= a <= a1 and (d - n * a).length < rk * r:
            return True
    return False


if opt("--binnacle"):
    blend, dj, tj = opt("--binnacle").split("|")
    DD = json.load(open(dj))
    TD = json.load(open(tj))
    kinds = [k for k in DD if k in TD]
    M, k_sc, err = similarity([vec(",".join(map(str, DD[k][0]))) for k in kinds], [vec(",".join(map(str, TD[k][0]))) for k in kinds])
    ddials = [(Vector(DD[k][0]), DD[k][1], Vector(DD[k][2]).normalized()) for k in kinds]
    tdials = [(Vector(TD[k][0]), TD[k][1], Vector(TD[k][2]).normalized()) for k in kinds]
    # this car's own faceted dials and bezels out
    cut = 0
    for o in list(bpy.data.objects):
        if o.type != "MESH" or o.name.startswith(("SteeringWheel", "Wheels")) or o.name[:2] in ("FL", "FR", "RL", "RR"):
            continue
        if o.name.startswith("Needle_"):
            bpy.data.objects.remove(o, do_unlink=True)
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        mw = o.matrix_world
        kill = [f for f in bm.faces if in_dials(mw @ f.calc_center_median(), tdials, 1.22, -0.012, 0.03)]
        if kill:
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(o.data)
            cut += len(kill)
        bm.free()
    for o in list(bpy.data.objects):
        if o.name.startswith("NeedlePivot_"):
            bpy.data.objects.remove(o, do_unlink=True)
    # the donor's binnacle in
    with bpy.data.libraries.load(blend) as (src, dst):
        dst.objects = list(src.objects)
    moved = 0
    for o in dst.objects:
        if o is None or o.type != "MESH":
            continue
        if o.name.startswith("Needle_"):
            sc.collection.objects.link(o)
            o.matrix_world = M @ o.matrix_world
            o.name = o.name.split(".")[0]
            moved += 1
            continue
        if o.name.startswith(("SteeringWheel", "Wheels", "NeedlePivot")) or o.name[:2] in ("FL", "FR", "RL", "RR"):
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        mw = o.matrix_world
        keep = []
        for f in bm.faces:
            m = o.data.materials[f.material_index] if f.material_index < len(o.data.materials) else None
            if m is None or any(w in m.name for w in SKIP_MATS):
                continue
            if in_dials(mw @ f.calc_center_median(), ddials, 1.35, -0.008, 0.045):
                keep.append(f.index)
        if keep:
            ks = set(keep)
            bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in ks], context="FACES")
            me = bpy.data.meshes.new("Binnacle")
            bm.to_mesh(me)
            for m in o.data.materials:
                me.materials.append(m)
            ob = bpy.data.objects.new("Body_Binnacle_" + o.name.replace("Body_", ""), me)
            ob.matrix_world = M @ mw
            sc.collection.objects.link(ob)
            moved += 1
        bm.free()
    report["binnacle"] = {"scale": round(k_sc, 4), "fit_error_m": round(err, 4), "own_faces_cut": cut, "pieces": moved}


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
