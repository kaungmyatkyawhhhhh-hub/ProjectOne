"""ronin_cp9a_split.py -- in.blend out.blend : the Ronin CP9A (Evo VI GSR .glb by Ddiaz Design, a racing-game rip) between
auto_car.py and finish_car.py (2026-11-14). The logo cuts are done HERE, not in finish_car.py: finish_car.py lays a
paint-coloured disc over the spot of any badge it cuts near the nose (cover_nose), and the owner's rule (2026-11-14) is
remove, never cover. (tools/paint_glb.py with tools/logo_paint/ronin_cp9a.json already dropped the whole badge nodes: the
front bumper emblem, the boot's script sticker, the seat badges, the model's still gauge needles, the stacked side skirts.)

1. Logos REMOVED (nothing laid over them): loose chrome pieces (material EXT_CHROME) wholly inside a box, each under "limit"
   long: the maker's name in chrome letters on the rear panel's right, the maker's emblem in the middle of the boot lid. The
   two door locks and the boot lock in the same nodes stay (no lettering).
2. The cluster face (material gauge_emissive1) lost its picture in the export (plain light grey): it gets the cabin picture
   back (its UVs are laid on the cabin picture's dials), so round the live panel the model shows its own dark dials.
3. The steering wheel cleaned: pieces that auto_car.py cut out with the wheel but that belong to the column or the dash go
   back into the cabin part of their material (lying wholly more than 6 cm ahead of the rim's plane, or more than 15 cm
   off its axis).
4. The brake parts in the wheels get their own material copies, so finish_car.py names them by what they are: the discs and
   hubs "brake_disc" (Disc), the calipers "brake_caliper" (Caliper) (in the .glb they wear the body's chrome material).
5. Every material's emission off (the export drew the lamps' and decals' pictures as glow too).

Points are given in the frame of tools/../glbgeo.py (the .glb's own frame x 100, front -y, left +x, up z) and moved onto the
car as auto_car.py laid it by the front and rear tyres' middles (scale and shift found here).

    blender -b --python tools/logo_paint/ronin_cp9a_split.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
CORNERS = ("FL", "FR", "RL", "RR")

# the .glb frame (x100) -> the car: from the tyres' middles (glb: FL (0.747, -1.2785, 0.1655), RL (0.747, 1.214, 0.1655))
GLB_FL = np.array([0.747, -1.2785, 0.1655])
GLB_RL = np.array([0.747, 1.214, 0.1655])

CHROME = [  # (x0, y0, z0, x1, y1, z1 in the glb frame, limit (m, car), what)
    (-0.65, 2.005, 0.552, -0.435, 2.07, 0.592, 0.05, "rear panel right: the maker's name in chrome letters"),
    (-0.05, 2.055, 0.815, 0.05, 2.085, 0.895, 0.10, "boot lid middle: the maker's emblem"),
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
    if not len(co):
        return []
    key = np.unique(np.round(co, 4), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(key.max()) + 1))

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
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in sorted(set(idx))], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()


def move_faces(src, idx, dst):
    """faces of src (world place, UVs, material by name) appended to dst, then deleted from src"""
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
    delete_faces(src, idx)


def mat_has(o, word):
    return any(m and word.lower() in m.name.lower() for m in o.data.materials)


def wheel_obj(o):
    p = o
    while p is not None:
        if p.name in CORNERS or p.name[:2] in CORNERS and p.name[2:3] in ("_", ""):
            return True
        p = p.parent
    return o.name[:3] in tuple(c + "_" for c in CORNERS)


# ---- the frame: the tyres' middles
tyre_mid = {}
for o in meshes():
    if o.name[:3] in tuple(c + "_" for c in CORNERS) and mat_has(o, "tire"):
        P = world_co(o)
        tyre_mid[o.name[:2]] = (P.min(0) + P.max(0)) / 2
print("SPLIT tyre middles", {k: v.round(4).tolist() for k, v in tyre_mid.items()})
fl = tyre_mid.get("FL")
rl = tyre_mid.get("RL")
if fl is None or rl is None or abs(fl[0]) < 0.3:
    raise SystemExit("SPLIT: no FL / RL tyres found")
S = (rl[1] - fl[1]) / (GLB_RL[1] - GLB_FL[1])
SX = np.sign(fl[0]) * np.sign(GLB_FL[0])
OFF = fl - np.array([GLB_FL[0] * SX, GLB_FL[1], GLB_FL[2]]) * S
print("SPLIT glb frame -> car: scale %.5f, x sign %+d, shift %s" % (S, SX, OFF.round(4).tolist()))
__import__("json").dump({"scale": S, "xsign": SX, "shift": OFF.tolist()}, open(a[1] + ".frame.json", "w"))


def to_car(x, y, z):
    return np.array([x * SX, y, z]) * S + OFF


def box_car(x0, y0, z0, x1, y1, z1):
    p, q = to_car(x0, y0, z0), to_car(x1, y1, z1)
    return np.minimum(p, q), np.maximum(p, q)


# ---- 1. chrome letters and emblem
for o in meshes():
    if not mat_has(o, "EXT_CHROME") or wheel_obj(o) or o.name.startswith("SteeringWheel"):
        continue
    co = world_co(o)
    kill = []
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        lo, hi = P.min(0), P.max(0)
        for x0, y0, z0, x1, y1, z1, lim, what in CHROME:
            blo, bhi = box_car(x0, y0, z0, x1, y1, z1)
            if np.all(lo >= blo) and np.all(hi <= bhi) and (hi - lo).max() < lim:
                kill += fs
                print("SPLIT chrome cut:", what, o.name, len(fs), "faces mid", ((lo + hi) / 2).round(3).tolist())
                break
    delete_faces(o, kill)

# ---- 1b. decal faces that show nothing in the model (their picture is fully clear there: a strip under the boot lid's edge):
#      Roblox draws a part's own colour under a picture's clear pixels, so they would show as a white strip: they go
for o in list(meshes()):
    if not mat_has(o, "EXT_MISC") or not o.data.uv_layers:
        continue
    m = next(m for m in o.data.materials if m and "EXT_MISC" in m.name)
    t = next((n for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image), None) if m.use_nodes else None
    if t is None or len(a) < 3:
        continue
    # (auto_car.py's fix_models.py already laid this cut-out picture over near-black, alpha solid: the clear pixels are read from
    #  the .glb's own picture, the material's base colour texture there)
    import json as _js, struct as _st, tempfile as _tf, os as _os
    _b = open(bpy.path.abspath(a[2]), "rb").read()
    _n = _st.unpack("<I", _b[12:16])[0]
    _g = _js.loads(_b[20:20 + _n])
    _bin = _b[20 + _n + 8: 20 + _n + 8 + _st.unpack("<I", _b[20 + _n: 24 + _n])[0]]
    _mi = next(i for i, mm in enumerate(_g["materials"]) if mm.get("name") == "EXT_MISC")
    _src = _g["textures"][_g["materials"][_mi]["pbrMetallicRoughness"]["baseColorTexture"]["index"]]["source"]
    _bv = _g["bufferViews"][_g["images"][_src]["bufferView"]]
    _tmp = _os.path.join(_tf.gettempdir(), "ronin_cp9a_misc_alpha.png")
    open(_tmp, "wb").write(_bin[_bv.get("byteOffset", 0): _bv.get("byteOffset", 0) + _bv["byteLength"]])
    _im = bpy.data.images.load(_tmp)
    Wd, Hd = _im.size
    px = np.empty(Wd * Hd * 4, dtype=np.float32)
    _im.pixels.foreach_get(px)
    bpy.data.images.remove(_im)
    alpha = px.reshape(Hd, Wd, 4)[..., 3]
    uvl = o.data.uv_layers.active.data
    kill = []
    for p in o.data.polygons:
        uv = np.array([uvl[l].uv[:] for l in p.loop_indices]) % 1.0
        pts = np.vstack([uv, uv.mean(0)])
        a_ = alpha[np.clip((pts[:, 1] * Hd).astype(int), 0, Hd - 1), np.clip((pts[:, 0] * Wd).astype(int), 0, Wd - 1)]
        if a_.max() < 0.1:
            kill.append(p.index)
    if kill:
        P = world_co(o)[sorted({v for i in kill for v in o.data.polygons[i].vertices})]
        print("SPLIT clear decal faces cut:", o.name, len(kill), "faces box", P.min(0).round(3).tolist(), P.max(0).round(3).tolist())
        delete_faces(o, kill)

# ---- 2. the cluster face gets the cabin picture back
cab_img = None
for m in bpy.data.materials:
    if m.name.startswith("INT_Plastic") and m.use_nodes:
        t = [n for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
        if t:
            cab_img = t[0].image
            break
for m in bpy.data.materials:
    if m.name.startswith("gauge_emissive1") and m.use_nodes and cab_img is not None:
        nt = m.node_tree
        b = nt.nodes.get("Principled BSDF")
        for l in list(b.inputs["Base Color"].links):
            nt.links.remove(l)
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = cab_img
        nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
        b.inputs["Metallic"].default_value = 0.0
        b.inputs["Roughness"].default_value = 0.5
        print("SPLIT cluster face: picture", cab_img.name, "on", m.name)

# ---- 3. the steering wheel: stalk / column / dash pieces back to the cabin
sws = [o for o in meshes() if o.name.startswith("SteeringWheel")]
if sws:
    W_ = np.concatenate([world_co(o) for o in sws])
    _, _, ax = np.linalg.svd(W_ - W_.mean(0))
    n = ax[2] * (1 if ax[2][1] > 0 else -1)
    c0 = W_.mean(0)
    for o in sws:
        co = world_co(o)
        moves = {}
        for fs in pieces(o, co):
            P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
            d = (P - c0) @ n
            m = (P.min(0) + P.max(0)) / 2
            off = np.linalg.norm((m - c0) - n * ((m - c0) @ n))
            if d.max() < -0.06 or off > 0.15:
                mname = o.data.materials[o.data.polygons[fs[0]].material_index].name
                moves.setdefault(mname, []).extend(fs)
                print("SPLIT wheel piece back to the cabin", o.name, mname, len(fs), "faces mid", m.round(3).tolist(), "ahead %.3f..%.3f off-axis %.3f" % (-d.max(), -d.min(), off))
        for mname, fs in moves.items():
            dst = max((b for b in meshes() if b not in sws and not wheel_obj(b) and not b.name.startswith("SeeThrough") and b.data.materials and b.data.materials[0] and b.data.materials[0].name == mname), key=lambda b: len(b.data.polygons), default=None)
            assert dst is not None, ("no cabin part for", mname)
            move_faces(o, fs, dst)
            print("SPLIT ->", dst.name, len(dst.data.polygons), "faces")
    # pieces that are not the .glb's own steering wheel nodes (auto_car.py's ring search also took the column shroud and the
    # stalks round the wheel's foot): their points are matched against the .glb's steering_wheel_* points (1 mm)
    import json as _json
    import struct as _struct
    from scipy.spatial import cKDTree
    _src = bpy.path.abspath(a[2]) if len(a) > 2 else None
    if _src:
        _b = open(_src, "rb").read()
        _n = _struct.unpack("<I", _b[12:16])[0]
        _g = _json.loads(_b[20:20 + _n])
        _bin = _b[20 + _n + 8: 20 + _n + 8 + _struct.unpack("<I", _b[20 + _n: 24 + _n])[0]]

        def _local(nd):
            if "matrix" in nd:
                return np.array(nd["matrix"]).reshape(4, 4).T
            x, y, z, w = nd.get("rotation", [0, 0, 0, 1])
            R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
            M = np.eye(4); M[:3, :3] = R @ np.diag(nd.get("scale", [1, 1, 1])); M[:3, 3] = nd.get("translation", [0, 0, 0])
            return M

        _world = {}

        def _walk(i, P_):
            M = P_ @ _local(_g["nodes"][i]); _world[i] = M
            for ch in _g["nodes"][i].get("children", []):
                _walk(ch, M)

        for r in _g["scenes"][0]["nodes"]:
            _walk(r, np.eye(4))
        pts = []
        for i, nd in enumerate(_g["nodes"]):
            if "mesh" in nd and "steering_wheel" in nd["name"]:
                for p in _g["meshes"][nd["mesh"]]["primitives"]:
                    acc = _g["accessors"][p["attributes"]["POSITION"]]; bv = _g["bufferViews"][acc["bufferView"]]
                    v = np.frombuffer(_bin, dtype=np.float32, count=acc["count"] * 3, offset=bv.get("byteOffset", 0) + acc.get("byteOffset", 0)).reshape(-1, 3).astype(float)
                    v = (np.c_[v, np.ones(len(v))] @ _world[i].T)[:, :3]
                    v = np.c_[v[:, 0], -v[:, 2], v[:, 1]] * 100.0
                    pts.append(np.c_[v[:, 0] * SX, v[:, 1], v[:, 2]] * S + OFF)
        tree = cKDTree(np.vstack(pts))
        print("SPLIT the .glb's steering wheel points", sum(len(p) for p in pts))
        for o in sws:
            co = world_co(o)
            moves = {}
            for fs in pieces(o, co):
                vi = sorted({v for f in fs for v in o.data.polygons[f].vertices})
                d, _ = tree.query(co[vi])
                share = float((d < 0.001).mean())
                if share < 0.5:
                    mname = o.data.materials[o.data.polygons[fs[0]].material_index].name
                    moves.setdefault(mname, []).extend(fs)
                    P = co[vi]
                    print("SPLIT not the wheel's own (%.0f %% matched): %s %s %d faces box %s..%s" % (share * 100, o.name, mname, len(fs), P.min(0).round(3).tolist(), P.max(0).round(3).tolist()))
            for mname, fs in moves.items():
                dst = max((b for b in meshes() if b not in sws and not wheel_obj(b) and not b.name.startswith("SeeThrough") and b.data.materials and b.data.materials[0] and b.data.materials[0].name == mname), key=lambda b: len(b.data.polygons), default=None)
                assert dst is not None, ("no cabin part for", mname)
                move_faces(o, fs, dst)
                print("SPLIT ->", dst.name, len(dst.data.polygons), "faces")
    # the tilt in the part's name (CarSkin turns the wheel about the axis it gives): auto_car.py's ring fit read 17.7 deg (it took
    # the column shroud in); the wheel's own points (the flattest direction of all of them) lean 26.5 deg
    W_ = np.concatenate([world_co(o) for o in sws])
    _, _, ax = np.linalg.svd(W_ - W_.mean(0))
    n = ax[2] * (1 if ax[2][1] > 0 else -1)
    tilt = float(np.degrees(np.arctan2(n[2], n[1])))
    for o in sws:
        new = "SteeringWheel_t%d" % round(tilt) + (o.name[o.name.index("."):] if "." in o.name else "")
        print("SPLIT wheel part renamed", o.name, "->", new, "(tilt %.1f deg)" % tilt)
        o.name = new
        o.data.name = new
    for o in sws:
        P = world_co(o)
        print("SPLIT wheel part", o.name, len(o.data.polygons), "faces box", P.min(0).round(4).tolist(), P.max(0).round(4).tolist())

# ---- 4. brake parts: their own materials
chrome = bpy.data.materials.get("EXT_CHROME")
if chrome is not None:
    disc_m = chrome.copy()
    disc_m.name = "brake_disc"
    cal_m = chrome.copy()
    cal_m.name = "brake_caliper"
    for o in meshes():
        if not wheel_obj(o) or not mat_has(o, "EXT_CHROME"):
            continue
        static = "_static" in o.name
        new = cal_m if static else disc_m
        for i, m in enumerate(o.data.materials):
            if m and m.name.startswith("EXT_CHROME"):
                o.data.materials[i] = new
        print("SPLIT brake material", o.name, "->", new.name, len(o.data.polygons), "faces")

# ---- 4b. the calipers: auto_car.py left them in the body's chrome; each goes to its corner as <corner>_static_caliper (steers
#      with a front wheel, does not spin), the way the wheels' other still pieces are kept
cal_m = bpy.data.materials.get("brake_caliper")
for o in list(meshes()):
    if not o.name.startswith("Body_") or not mat_has(o, "EXT_CHROME"):
        continue
    co = world_co(o)
    by = {c: [] for c in tyre_mid}
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        m = (P.min(0) + P.max(0)) / 2
        c = min(tyre_mid, key=lambda k: np.linalg.norm(m - tyre_mid[k]))
        if np.linalg.norm((m - tyre_mid[c])[1:]) < 0.25 and abs(m[0]) > 0.65 and abs(m[0] - tyre_mid[c][0]) < 0.12:
            by[c] += fs
    for c, fs in by.items():
        if not fs:
            continue
        name = c + "_static_caliper"
        hub = next((x for x in meshes() if x.name.startswith(c + "_static")), None) or next(x for x in meshes() if x.name.startswith(c + "_"))
        me = bpy.data.meshes.new(name)
        dst = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(dst)
        dst.parent = hub.parent
        dst.matrix_world = hub.matrix_world.copy()
        me.materials.append(cal_m if cal_m is not None else o.data.materials[0])
        dst.data.uv_layers.new(name="UVMap")
        bs = bmesh.new()
        bs.from_mesh(o.data)
        bs.faces.ensure_lookup_table()
        suv = bs.loops.layers.uv.active
        bd = bmesh.new()
        duv = bd.loops.layers.uv.new("UVMap")
        Ms, Di = o.matrix_world, dst.matrix_world.inverted()
        for i in sorted(fs):
            f = bs.faces[i]
            loops = list(f.loops)
            try:
                nf = bd.faces.new([bd.verts.new(Di @ (Ms @ l.vert.co)) for l in loops])
            except ValueError:
                continue
            nf.smooth = f.smooth
            if suv:
                for nl, l in zip(nf.loops, loops):
                    nl[duv].uv = l[suv].uv
        bd.to_mesh(me)
        bd.free()
        bs.free()
        print("SPLIT caliper ->", name, len(me.polygons), "faces (parent", dst.parent.name if dst.parent else "-", ")")
    delete_faces(o, [f for fs in by.values() for f in fs])
# ---- 4c. auto_car.py's spin / still sorting fixed: the tyre valve (a small rim piece outside the rim face) spins with the rim;
#      the front knuckle / strut foot (undercarriage material, 98 faces, inboard of the disc) steers but does not spin
def join_into(src, dst):
    if src is None or dst is None:
        return
    move_faces(src, list(range(len(src.data.polygons))), dst)
    print("SPLIT", src.name, "->", dst.name, len(dst.data.polygons), "faces")
    bpy.data.objects.remove(src, do_unlink=True)


for c in CORNERS:
    ob = {o.name: o for o in meshes()}
    join_into(ob.get(c + "_static_material"), ob.get(c + "_material"))
    ob = {o.name: o for o in meshes()}
    join_into(ob.get(c + "_Under"), ob.get(c + "_static_Under"))
for o in meshes():
    if wheel_obj(o):
        P = world_co(o)
        print("SPLIT wheel object", o.name, len(o.data.polygons), "faces box", P.min(0).round(3).tolist(), P.max(0).round(3).tolist())

# ---- 4d. auto_car.py named the cabin's rubber part "Body_Rubber" (its material is "Rubber"): finish_car.py then calls the outside
#      rubber "Body_Rubber.001" (the name is taken while it works): give the cabin's one another name first
for o in meshes():
    if o.name == "Body_Rubber":
        o.name = o.data.name = "Body_IntRubber"

# ---- 5. no glow
for m in bpy.data.materials:
    if m.use_nodes and "Principled BSDF" in m.node_tree.nodes:
        b = m.node_tree.nodes["Principled BSDF"]
        for l in list(b.inputs["Emission Color"].links):
            m.node_tree.links.remove(l)
        b.inputs["Emission Strength"].default_value = 0.0

bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("SPLIT saved", a[1])
