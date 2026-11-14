"""pleiad_gc8_split.py -- in.blend out.blend : the Pleiad GC8 Wide (`pleiad_gc8`, the 1998 22B .glb by Ddiaz Design, a racing
game's car asset) between auto_car.py and finish_car.py (2026-11-14; made from tools/logo_paint/ronin_cp9a_champ_split.py, the same
author's model layout). Cuts are done HERE, not in finish_car.py (its cover_nose() lays a paint disc over any cut near the nose; the
owner's rule of 2026-11-14 is remove, never cover).

1. The body colour made plain: the model's whole exterior is ONE atlas (material gc8_ext, Image_1: the blue paint with its shading,
   the lamp pictures, the exhaust, the arch liners' picture, the grille meshes). Each face of gc8_ext is sampled through its UV
   triangle (corners, edge middles and 7 inside points): a face whose samples are mostly the paint's blue (any shade: shadowed
   shuts and gap lines too) goes to its own part with material gc8_paint (no picture, the paint's blue): Customs then colours it and
   the paint keeps its gloss. Everything else stays textured (gc8_ext), and the paint's blue is turned neutral grey in that atlas
   (only gap lines and trim edges show it), so no blue shows whatever colour the car is painted.
2. Logos REMOVED (nothing laid over them): the six-star emblem on the grille (its own raised piece, 68 faces of the badge sheet
   Image_0) and the two "STi" decals on the front bumper's lower corners (4 faces): the faces that read the badge sheet's top part
   (the decal pictures) are deleted; the grille mesh (the sheet's lower part) stays. The emblem's mount (an oval boss on a short
   centre post between the grille's bars, 258 faces of the paint) is deleted too: the grille mesh runs on behind it.
   The small gauges' printed needles and caps (fuel, water; loose dash-atlas pieces 8-12 mm in front of their faces, through the
   live cluster panel) are deleted (the big dials' needle nodes are dropped in the paint job).
3. The four brake calipers (the model's own, misc atlas): auto_car.py leaves them in the body (they would not steer with the front
   wheels nor ride with the wheels): each goes to its corner as <corner>_static_Brake (steers, does not spin), material gc8_caliper
   (the misc atlas under its own name, so finish_car gives it the Brake role).
4. The steering wheel cleaned: pieces that auto_car cut out with the wheel but are not the wheel (column stalks, column shroud,
   cluster bits) go back into the cabin part of their material (pieces lying wholly more than 6 cm ahead of the rim's plane and
   more than 2 cm off its axis, or reaching over 8 cm ahead while more than 9 cm off the wheel's axis, or over 5 cm ahead while
   more than 15 cm off it (a stalk's tip), or more than 19.5 cm off the axis (past the rim, outer radius 19 cm); and every piece
   of the dash atlas int1, which this wheel does not wear: the column shroud's top on the axis 8-10 cm ahead, the stalks' tips).

    blender -b --python tools/logo_paint/pleiad_gc8_split.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
CORNERS = ("FL", "FR", "RL", "RR")

# picture areas (stored picture px, x0, y0, x1, y1, top-left origin) of Image_1 (1024) that are NOT paint although blue:
# the grille mesh pictures (navy with blue lines: the big block, the band over it, the small square), the boot vent, the grille
# picture (each drawn tight: the rear bumper's own island starts at x 680 under the band; checked with the paint turned red)
NOT_PAINT = [(440, 0, 650, 280), (650, 0, 822, 84), (636, 90, 678, 178), (868, 393, 937, 452), (808, 84, 1022, 122)]
STRIPES = []
# the badge sheet's decal pictures (rows above the grille mesh, the oval badge at the right): faces reading them are cut
UV_CUTS = [("Image_0", (0, 0, 511, 177), "the STi decals / the six-star emblem (badge sheet, top)"),
           ("Image_0", (345, 150, 511, 289), "the STi oval (badge sheet)")]


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
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in sorted(set(idx))], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()


def copy_with(o, idx, name, mat=None):
    """a new object `name`: a copy of o holding only the faces idx (o is not changed)"""
    keep = set(idx)
    n = o.copy()
    n.data = o.data.copy()
    n.name = name
    n.data.name = name
    for c in o.users_collection:
        c.objects.link(n)
    delete_faces(n, [p.index for p in n.data.polygons if p.index not in keep])
    if mat is not None:
        n.data.materials.clear()
        n.data.materials.append(mat)
        for p in n.data.polygons:
            p.material_index = 0
    return n


def split_off(o, idx, name, mat=None):
    """the faces idx of o become a new object `name` (a copy of o with the other faces deleted; same frame, UVs, normals)"""
    keep = set(idx)
    n = o.copy()
    n.data = o.data.copy()
    n.name = name
    n.data.name = name
    for c in o.users_collection:
        c.objects.link(n)
    delete_faces(n, [p.index for p in n.data.polygons if p.index not in keep])
    delete_faces(o, list(keep))
    if mat is not None:
        n.data.materials.clear()
        n.data.materials.append(mat)
        for p in n.data.polygons:
            p.material_index = 0
    return n


def tex_of(m):
    return next((k.image for k in m.node_tree.nodes if k.type == "TEX_IMAGE" and k.image), None) if m and m.use_nodes else None


def mat_has(o, word):
    return any(m and word.lower() == m.name.lower().split(".")[0] for m in o.data.materials)


# ---- 1. the plain body colour out of the exterior atlas
ext = [o for o in meshes() if mat_has(o, "gc8_ext") and not o.name.startswith(CORNERS + ("SteeringWheel", "SeeThrough"))]
for o in ext:
    m = o.data.materials[0]
    img = tex_of(m)
    W, H = img.size
    px = np.empty(W * H * img.channels, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(H, W, img.channels)[::-1]  # top-left origin, like the stored picture
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    red = (b > 0.2) & (r < 0.45 * b) & (g < 0.85 * b) & (b - g > 0.1)   # (the paint's blue, any shade; named red as in the
    # Champion's script it comes from)
    mx, mn = px[..., :3].max(-1), px[..., :3].min(-1)
    neutral = (mx - mn) < 0.16
    band = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in STRIPES:
        band[y0 : y1 + 1, x0 : x1 + 1] = True
    paint = red | (neutral & band)
    for x0, y0, x1, y1 in NOT_PAINT:
        paint[y0 : y1 + 1, x0 : x1 + 1] = False
    red_px = px[..., :3][red & ~band]
    colour = np.median(red_px, axis=0)
    uvl = o.data.uv_layers.active.data
    bary = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (0.5, 0.5, 0), (0, 0.5, 0.5), (0.5, 0, 0.5), (1 / 3, 1 / 3, 1 / 3),
            (0.6, 0.2, 0.2), (0.2, 0.6, 0.2), (0.2, 0.2, 0.6), (0.45, 0.45, 0.1), (0.1, 0.45, 0.45), (0.45, 0.1, 0.45)]
    pick, frac_hist = [], np.zeros(11, int)
    for p in o.data.polygons:
        L = list(p.loop_indices)
        uv = np.array([uvl[i].uv[:] for i in L])
        hits = tot = 0
        for k in range(1, len(L) - 1):
            tri = uv[[0, k, k + 1]]
            for w in bary:
                q = np.dot(w, tri)
                x = int((q[0] % 1.0) * W) % W
                y = int((1.0 - q[1] % 1.0) * H) % H
                hits += paint[y, x]
                tot += 1
        f = hits / max(tot, 1)
        frac_hist[int(f * 10)] += 1
        if f >= 0.5:
            pick.append(p.index)
    pm = bpy.data.materials.get("gc8_paint") or m.copy()
    pm.name = "gc8_paint"
    nt = pm.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    for k in [k for k in nt.nodes if k.type == "TEX_IMAGE"]:
        nt.nodes.remove(k)
    bsdf.inputs["Base Color"].default_value = (*[float(c) ** 2.2 for c in colour], 1.0)
    n = split_off(o, pick, "Body_gc8_paint", pm)
    # the paint's blue left in the atlas (seen only on the few textured faces that cross a panel's edge: the panel gaps' dark
    # lines, the edges of black trims) turned to neutral grey of the same lightness, so no red shows whatever colour the car is
    lum = (0.30 * r + 0.59 * g + 0.11 * b)[..., None]
    q = px.copy()
    q[..., :3] = np.where(paint[..., None], lum, px[..., :3])
    img.pixels.foreach_set(q[::-1].ravel())
    img.update()
    img.pack()
    print("SPLIT paint:", o.name, "->", n.name, len(n.data.polygons), "faces; left textured", len(o.data.polygons),
          "; paint colour (stored px)", [round(float(c) * 255) for c in colour], "; paint-fraction histogram (0..1 by 0.1)", frac_hist.tolist())

# ---- 2. decal / emblem faces by picture area
for img_name, (x0, y0, x1, y1), what in UV_CUTS:
    img = bpy.data.images.get(img_name)
    W, H = img.size
    for o in meshes():
        slots = {i for i, m in enumerate(o.data.materials) if tex_of(m) == img}
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
            co = world_co(o)
            P = co[[v for i in kill for v in o.data.polygons[i].vertices]]
            print("SPLIT cut:", what, o.name, len(kill), "faces box", P.min(0).round(3).tolist(), P.max(0).round(3).tolist())
            delete_faces(o, kill)

# ---- 2b. the emblem's mount on the grille: an oval boss on a short centre post between the grille's top and bottom bars (258 faces
# of the front bumper's paint, every corner within |x| < 0.048 m, between the bars, ahead of the grille mesh): deleted whole (an empty
# badge mount would read as a blank plate); the grille mesh runs on behind it and the bars are whole
for o in [o for o in meshes() if o.name.startswith("Body_") and (mat_has(o, "gc8_paint") or mat_has(o, "gc8_ext"))]:
    co = world_co(o)
    kill = []
    for p in o.data.polygons:
        q = co[list(p.vertices)]
        if np.abs(q[:, 0]).max() < 0.048 and q[:, 2].min() > 0.521 and q[:, 2].max() < 0.620 and q[:, 1].max() < -2.003:
            kill.append(p.index)
    if kill:
        q = co[[v for i in kill for v in o.data.polygons[i].vertices]]
        print("SPLIT cut: the grille's emblem mount (oval boss + centre post)", o.name, len(kill), "faces box", q.min(0).round(3).tolist(), q.max(0).round(3).tolist())
        delete_faces(o, kill)

# ---- 2c. the small gauges' printed needles and caps (fuel, water: loose pieces of the dash atlas int1 standing 8-12 mm in front of the
# dial faces, through the live panel that sits about 7 mm out; the big dials' needles are their own nodes, dropped in the paint job):
# deleted (the live cluster draws its own)
NEEDLES = [(-0.2421, -0.6689, 0.8102), (-0.2837, -0.6689, 0.8101), (-0.2320, -0.6691, 0.8210), (-0.2731, -0.6689, 0.8203)]
for o in [o for o in meshes() if o.name.startswith("Body_") and mat_has(o, "int1")]:
    co = world_co(o)
    kill = []
    for fs in pieces(o, co):
        q = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        mid = (q.min(0) + q.max(0)) / 2
        if (q.max(0) - q.min(0)).max() < 0.02 and min(np.linalg.norm(mid - np.array(n_)) for n_ in NEEDLES) < 0.006:
            kill += fs
            print("SPLIT cut: a small gauge's needle / cap", o.name, len(fs), "faces mid", mid.round(4).tolist())
    delete_faces(o, kill)

# ---- the wheels: corner centres from each corner's tyre
corner = {}
for c in CORNERS:
    ty = [o for o in meshes() if o.name.startswith(c + "_") and mat_has(o, "tire")]
    if ty:
        P = world_co(ty[0])
        corner[c] = ((P.min(0) + P.max(0)) / 2, (P.max(0)[2] - P.min(0)[2]) / 2)
print("SPLIT wheel centres", {c: (v[0].round(3).tolist(), round(float(v[1]), 3)) for c, v in corner.items()})

# ---- 3. calipers to their corners (pieces of the misc part wholly inside a wheel)
misc = next((o for o in meshes() if o.name.startswith("Body_") and mat_has(o, "misc")), None)
if misc is not None and corner:
    cm = misc.data.materials[0].copy()
    cm.name = "gc8_caliper"
    co = world_co(misc)
    by = {c: [] for c in corner}
    for fs in pieces(misc, co):
        P = co[[v for f in fs for v in misc.data.polygons[f].vertices]]
        mid = (P.min(0) + P.max(0)) / 2
        c = min(corner, key=lambda k: np.linalg.norm(mid - corner[k][0]))
        ctr, R = corner[c]
        if np.linalg.norm(P - ctr, axis=1).max() < R * 1.02 and abs(mid[0]) > abs(ctr[0]) - 0.2:
            by[c] += fs
    for c, fs in by.items():
        if not fs:
            continue
        hub = next((x for x in meshes() if x.name.startswith(c + "_")), None)
        n = copy_with(misc, fs, c + "_static_Brake", cm)
        mw = n.matrix_world.copy()
        n.parent = hub.parent if hub else None
        n.matrix_world = mw
        P = world_co(n)
        print("SPLIT caliper ->", n.name, len(n.data.polygons), "faces, box", P.min(0).round(3).tolist(), P.max(0).round(3).tolist(), "parent", n.parent.name if n.parent else "-")
    delete_faces(misc, [f for fs in by.values() for f in fs])


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


# ---- 4. the steering wheel: stalks / shroud / cluster bits back to the cabin
sws = [o for o in meshes() if o.name.startswith("SteeringWheel")]
rim = max(sws, key=lambda o: len(o.data.polygons))
R_ = world_co(rim)
_, _, ax = np.linalg.svd(R_ - R_.mean(0))
nrm = ax[2] * (1 if ax[2][1] > 0 else -1)   # towards the driver (back of the car = +y)
c0 = (R_.min(0) + R_.max(0)) / 2
print("SPLIT rim plane: middle", c0.round(4).tolist(), "normal", nrm.round(4).tolist())
for o in sws:
    co = world_co(o)
    mname = o.data.materials[0].name
    dst = max((b for b in meshes() if b not in sws and not b.name.startswith(CORNERS + ("SeeThrough",)) and b.data.materials
               and b.data.materials[0] and b.data.materials[0].name == mname), key=lambda b: len(b.data.polygons), default=None)
    move = []
    for fs in pieces(o, co):
        P = co[[v for f in fs for v in o.data.polygons[f].vertices]]
        d = (P - c0) @ nrm
        m = (P.min(0) + P.max(0)) / 2
        off = np.linalg.norm((m - c0) - nrm * ((m - c0) @ nrm))
        far = (d.max() < -0.06 and off > 0.02) or (off > 0.09 and d.min() < -0.08) or (off > 0.15 and d.min() < -0.05) or off > 0.195
        if mname.split(".")[0] == "int1":
            far = True   # (this wheel wears none of the dash atlas: its int1 pieces are the column shroud's top (on the axis, 8-10 cm
            #             ahead: it must not turn with the wheel) and the stalks' tips)
        print("SPLIT  wheel piece", o.name, len(fs), "faces mid", m.round(3).tolist(), "ahead %.3f..%.3f off-axis %.3f" % (-d.max(), -d.min(), off), "-> CABIN" if far else "")
        if far:
            move += fs
    if move:
        assert dst is not None, ("no cabin part for", mname)
        move_faces(o, move, dst)
        print("SPLIT ->", dst.name, len(dst.data.polygons), "faces")
for o in [o for o in meshes() if o.name.startswith("SteeringWheel")]:
    if len(o.data.polygons) == 0:
        print("SPLIT empty wheel part removed", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
        continue
    P = world_co(o)
    print("SPLIT wheel part", o.name, len(o.data.polygons), "faces box", P.min(0).round(4).tolist(), P.max(0).round(4).tolist())

bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("SPLIT saved", a[1])
