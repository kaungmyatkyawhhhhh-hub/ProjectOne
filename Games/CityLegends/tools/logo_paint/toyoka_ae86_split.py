"""toyoka_ae86_split.py -- in.blend out.blend : the AE86 (Ddiaz Design .glb, a Racing Master rip) between auto_car.py and
finish_car.py (2026-11-14). The logo cuts are done HERE, not in finish_car.py: finish_car.py lays a paint-coloured disc over the
spot of any badge it cuts near the nose (cover_nose), and the owner's rule (2026-11-14) is remove, never cover.

1. Logos REMOVED (nothing laid over them):
   - chrome letters (material AE86MI_Exhaust1, loose pieces wholly inside a box, each under "limit" long): the maker's name on the
     front bumper and in the middle of the rear panel, the model name on the rear panel's right, the hatch letters, the mud flap
     letters, the rear wing letters (boxes below, car metres as auto_car lays the car);
   - the raised maker's name on each wheel's centre cap (small loose pieces of the Rim part round the axle on the cap's face);
   - decal faces by their picture area: the maker's word on the steering hub (cabin decal sheet Image_3), the engine bay's labels
     with the car maker's / parts makers' names and the cam cover letters (Image_17).
2. The steering wheel cleaned: the column stalk and the cluster / column decals that auto_car.py cut out with the wheel go back
   into the cabin parts of their material (pieces lying wholly more than 6 cm ahead of the rim's plane, or reaching over 8 cm
   ahead while more than 9 cm off the wheel's axis, or more than 15 cm off the axis).
3. The four brake calipers (the model's own, material AE86MI_Change_Brake1): auto_car.py left three of them in the body (fixed:
   they would not steer with the front wheels nor ride with the wheels); each goes to its corner as <corner>_static_Brake (steers
   with the wheel, does not spin), as the right rear one already is.

    blender -b --python tools/logo_paint/toyoka_ae86_split.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
CORNERS = ("FL", "FR", "RL", "RR")

CHROME_LETTERS = [  # (x0, y0, z0, x1, y1, z1, limit, what)
    (-0.10, -1.995, 0.50, 0.10, -1.965, 0.555, 0.04, "front bumper: the maker's name"),
    (-0.08, 2.055, 0.778, 0.08, 2.085, 0.815, 0.04, "rear panel middle: the maker's name"),
    (-0.58, 2.03, 0.775, -0.37, 2.08, 0.812, 0.04, "rear panel right: the model name"),
    (0.28, 2.00, 0.84, 0.60, 2.05, 0.88, 0.045, "hatch left: letters"),
    (-0.56, 2.00, 0.84, -0.37, 2.05, 0.885, 0.045, "hatch right: letters"),
    (0.59, 1.55, 0.19, 0.76, 1.585, 0.235, 0.035, "left mud flap: letters"),
    (-0.76, 1.55, 0.19, -0.59, 1.585, 0.235, 0.035, "right mud flap: letters"),
    (0.79, 0.69, 0.53, 0.82, 0.80, 0.56, 0.025, "left rear wing: letters"),
    (-0.82, 0.69, 0.53, -0.79, 0.80, 0.56, 0.025, "right rear wing: letters"),
]
UV_CUTS = [  # (image, stored-picture px rect x0, y0, x1, y1 (v down), what)
    ("Image_3", (0, 310, 136, 345), "the maker's word decal on the steering hub"),
    ("Image_17", (190, 233, 266, 285), "master cylinder label (car maker's and brake-parts maker's names)"),
    ("Image_17", (296, 141, 359, 183), "vacuum sensor label (the maker's name)"),
    ("Image_17", (304, 68, 423, 142), "the maker's identification plate"),
    ("Image_17", (432, 64, 510, 232), "the cam cover letters (engine code, intake system name)"),
]


def meshes():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def world_co(o):
    me = o.data
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    M = np.array(o.matrix_world)
    return co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]


def pieces(o, co=None):
    """face index lists of the loose pieces (points welded by place, 0.1 mm)"""
    co = world_co(o) if co is None else co
    key = np.unique(np.round(co, 4), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(key.max()) + 1 if len(key) else 0))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for p in o.data.polygons:
        r = find(key[p.vertices[0]])
        for v in p.vertices[1:]:
            par[find(key[v])] = r
    groups = {}
    for p in o.data.polygons:
        groups.setdefault(find(key[p.vertices[0]]), []).append(p.index)
    return list(groups.values())


def delete_faces(o, idx):
    if not idx:
        return
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in sorted(idx)], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()


def move_faces(src, idx, dst, delete=True):
    """faces of src (world place, UVs, material by name) appended to dst, then deleted from src (delete=False: the caller deletes
    them later, when several destinations take faces of one part: the indices must not change in between)"""
    if not idx:
        return
    bs = bmesh.new()
    bs.from_mesh(src.data)
    bs.faces.ensure_lookup_table()
    suv = bs.loops.layers.uv.active
    bd = bmesh.new()
    bd.from_mesh(dst.data)
    duv = bd.loops.layers.uv.active or bd.loops.layers.uv.new("UVMap")
    Ms, Di = src.matrix_world, dst.matrix_world.inverted()
    names = [m.name if m else None for m in dst.data.materials]
    for i in sorted(idx):
        f = bs.faces[i]
        mname = src.data.materials[f.material_index].name if src.data.materials else None
        if mname not in names:
            dst.data.materials.append(bpy.data.materials[mname])
            names.append(mname)
        loops = list(f.loops)
        try:
            nf = bd.faces.new([bd.verts.new(Di @ (Ms @ l.vert.co)) for l in loops])
        except ValueError:
            continue
        nf.smooth = f.smooth
        nf.material_index = names.index(mname)
        if suv:
            for nl, l in zip(nf.loops, loops):
                nl[duv].uv = l[suv].uv
    bd.to_mesh(dst.data)
    bd.free()
    bs.free()
    if delete:
        delete_faces(src, idx)


def mat_has(o, word):
    return any(m and word.lower() in m.name.lower() for m in o.data.materials)


# ---- 1a. chrome letters
for o in meshes():
    if not mat_has(o, "AE86MI_Exhaust1") or o.name.startswith(("FL", "FR", "RL", "RR", "SteeringWheel")):
        continue
    co = world_co(o)
    kill = []
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        lo, hi = P.min(0), P.max(0)
        for x0, y0, z0, x1, y1, z1, lim, what in CHROME_LETTERS:
            if lo[0] >= x0 and lo[1] >= y0 and lo[2] >= z0 and hi[0] <= x1 and hi[1] <= y1 and hi[2] <= z1 and (hi - lo).max() < lim:
                kill += fs
                print("SPLIT letter cut:", what, o.name, len(fs), "faces mid", ((lo + hi) / 2).round(3).tolist())
                break
    delete_faces(o, kill)


# ---- the wheels: corner centres and axle (x) from each corner's tyre
corner = {}
for c in CORNERS:
    ty = [o for o in meshes() if o.name.startswith(c + "_") and mat_has(o, "Thick_Tire")]
    if ty:
        P = world_co(ty[0])
        corner[c] = ((P.min(0) + P.max(0)) / 2, (P.max(0)[2] - P.min(0)[2]) / 2)
print("SPLIT wheel centres", {c: (v[0].round(3).tolist(), round(v[1], 3)) for c, v in corner.items()})

# ---- 1b. the raised maker's name on each centre cap: small loose pieces of the rim near the axle, on the outer face
for o in meshes():
    c = o.name[:2]
    if c not in corner or "_static" in o.name or not mat_has(o, "ChangeA_Rim"):
        continue
    ctr, R = corner[c]
    side = 1.0 if ctr[0] > 0 else -1.0
    co = world_co(o)
    kill, seen = [], 0
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        lo, hi = P.min(0), P.max(0)
        mid = (lo + hi) / 2
        rr = np.hypot(mid[1] - ctr[1], mid[2] - ctr[2])
        size = max(hi[1] - lo[1], hi[2] - lo[2])
        cut = rr < 0.035 and size < 0.022 and len(fs) < 400
        if rr < 0.07 and size < 0.05 and o.name.startswith("FL"):
            print("SPLIT  FL rim piece", len(fs), "faces rr %.3f size %.3f x %.3f..%.3f" % (rr, size, lo[0], hi[0]), "CUT" if cut else "")
        if cut:
            kill += fs
            seen += 1
    print("SPLIT cap letters cut", o.name, seen, "pieces", len(kill), "faces")
    delete_faces(o, kill)

# ---- 1c. decal faces by picture area
for img_name, (x0, y0, x1, y1), what in UV_CUTS:
    img = bpy.data.images.get(img_name)
    if img is None:
        print("SPLIT no image", img_name)
        continue
    W, H = img.size
    for o in meshes():
        slots = {i for i, m in enumerate(o.data.materials) if m and m.use_nodes and any(k.type == "TEX_IMAGE" and k.image == img for k in m.node_tree.nodes)}
        if not slots or not o.data.uv_layers:
            continue
        uvl = o.data.uv_layers.active.data
        kill = []
        for p in o.data.polygons:
            if p.material_index in slots:
                u = sum(uvl[l].uv.x for l in p.loop_indices) / p.loop_total % 1.0
                v = sum(uvl[l].uv.y for l in p.loop_indices) / p.loop_total % 1.0
                if x0 <= u * W <= x1 and y0 <= (1 - v) * H <= y1:
                    kill.append(p.index)
        if kill:
            print("SPLIT decal cut:", what, o.name, len(kill), "faces")
            delete_faces(o, kill)

# ---- 2. the steering wheel: stalk and column / cluster decals back to the cabin
sws = [o for o in meshes() if o.name.startswith("SteeringWheel")]
W_ = np.concatenate([world_co(o) for o in sws])
_, _, ax = np.linalg.svd(W_ - W_.mean(0))
n = ax[2] * (1 if ax[2][1] > 0 else -1)
c0 = W_.mean(0)
mid0 = (W_.min(0) + W_.max(0)) / 2
for o in sws:
    co = world_co(o)
    mname = o.data.materials[0].name
    dst = max((b for b in meshes() if b not in sws and not b.name.startswith(("FL", "FR", "RL", "RR", "SeeThrough")) and b.data.materials and b.data.materials[0] and b.data.materials[0].name == mname), key=lambda b: len(b.data.polygons), default=None)
    move = []
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        d = (P - c0) @ n
        m = (P.min(0) + P.max(0)) / 2
        off = np.linalg.norm((m - c0) - n * ((m - c0) @ n))
        if d.max() < -0.06 or (off > 0.09 and d.min() < -0.08) or off > 0.15:
            move += fs
            print("SPLIT wheel piece back to the cabin", o.name, len(fs), "faces mid", m.round(3).tolist(), "ahead %.3f..%.3f off-axis %.3f" % (-d.max(), -d.min(), off))
    if move:
        assert dst is not None, ("no cabin part for", mname)
        move_faces(o, move, dst)
        print("SPLIT ->", dst.name, len(dst.data.polygons), "faces")
for o in sws:
    P = world_co(o)
    print("SPLIT wheel part", o.name, len(o.data.polygons), "faces box", P.min(0).round(4).tolist(), P.max(0).round(4).tolist())

# ---- 3. calipers to their corners
for o in list(meshes()):
    if not o.name.startswith("Body_") or not mat_has(o, "Change_Brake"):
        continue
    co = world_co(o)
    by = {c: [] for c in corner}
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        m = (P.min(0) + P.max(0)) / 2
        c = min(corner, key=lambda k: np.linalg.norm(m - corner[k][0]))
        if np.linalg.norm(m - corner[c][0]) < corner[c][1]:
            by[c] += fs
    for c, fs in by.items():
        if not fs:
            continue
        name = c + "_static_Brake"
        dst = bpy.data.objects.get(name)
        if dst is None:
            hub = next((x for x in meshes() if x.name.startswith(c + "_static")), None) or next(x for x in meshes() if x.name.startswith(c + "_"))
            me = bpy.data.meshes.new(name)
            dst = bpy.data.objects.new(name, me)
            bpy.context.scene.collection.objects.link(dst)
            dst.parent = hub.parent
            dst.matrix_world = hub.matrix_world.copy()
            me.materials.append(o.data.materials[0])
            dst.data.uv_layers.new(name="UVMap")
        move_faces(o, fs, dst, delete=False)
        print("SPLIT caliper ->", name, len(dst.data.polygons), "faces (parent", dst.parent.name if dst.parent else "-", ")")
    delete_faces(o, [f for fs in by.values() for f in fs])
    if len(o.data.polygons) == 0:
        print("SPLIT empty part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)

bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("SPLIT saved", a[1])
