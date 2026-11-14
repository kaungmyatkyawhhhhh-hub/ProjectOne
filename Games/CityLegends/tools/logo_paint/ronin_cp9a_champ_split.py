"""ronin_cp9a_champ_split.py -- in.blend out.blend : the Ronin CP9A Champion (`ronin_cp9a_champ`, the 1999 Evo VI champion's edition
.glb by Ddiaz Design, a racing-game rip) between auto_car.py and finish_car.py (2026-11-14). Cuts are done HERE, not in finish_car.py
(its cover_nose() lays a paint disc over any cut near the nose; the owner's rule of 2026-11-14 is remove, never cover).

1. The body colour made plain: the model's whole exterior is ONE atlas (material champ_ext, Image_1: the red paint with the livery
   stripes, the grilles, black trims, lamp pictures, chrome caps). Each face of champ_ext is sampled through its UV triangle
   (corners, edge middles and 7 inside points): a face whose samples are mostly the paint's red (any shade: shadowed door shuts
   too) or the livery stripes' white / grey / black inside the stripe bands goes to its own part with material champ_paint (no
   picture, the paint's red): Customs then colours it and the paint keeps its gloss. Everything else stays textured (champ_ext),
   and the paint's red is turned neutral grey in that atlas (only gap lines and trim edges show it). The livery stripes and the
   rear wing's white top go with the paint (plain): they would stay red-backed whatever colour the car is painted.
2. Logos REMOVED (nothing laid over them): the grille emblem (its own raised piece in the misc atlas, Image_3: the faces that
   read the emblem's picture area).
3. The four brake calipers (the model's own, red, misc atlas): auto_car.py left them in the body (they would not steer with the
   front wheels nor ride with the wheels): each goes to its corner as <corner>_static_Brake (steers, does not spin), material
   champ_caliper (the misc atlas under its own name, so finish_car gives it the Brake role).
4. The steering wheel cleaned: pieces that auto_car cut out with the wheel but are not the wheel (column stalks, column shroud,
   cluster bits) go back into the cabin part of their material (pieces lying wholly more than 6 cm ahead of the rim's plane and
   more than 2 cm off its axis (the hub's back cover, on the axis, stays and turns with the wheel), or
   reaching over 8 cm ahead while more than 9 cm off the wheel's axis, or over 5 cm ahead while more than 15 cm off it (a
   stalk's tip), or more than 22 cm off the axis).

5. The rear doors' outer skins made their own loose pieces (the model has the rear door skin joined to the body side; the
   front doors are their own pieces): faces of the body atlas parts (paint and textured) whose middle lies inside the rear
   door's outline (y-z, |x| > 0.6, the door side of the panel gaps measured on the mesh: front gap y 0.284-0.304, rear gap y
   1.236-1.254, the flare's gap from (0.795, 0.35) to (1.213, 0.789), the sill at z 0.345, the belt) get their edges split along
   that outline, so tools/doors.py takes each rear door whole by its box. Nothing moves; the gaps' own faces stay with the body.
   The rear door cards likewise (part of the low cabin sheet's one piece with the rear seats: |x| >= 0.64, y 0.30-1.22, z up to
   1.02), cut first along the door's outline drawn 1.5 cm inside the skin's (the bottom, the flare, the rear edge): the strips
   outside it stay with the body.

6. The lamps' clear covers (head and tail) taken out of the window glass into their own part (material champ_lens: finish_car's
   lens role makes it SeeThrough_Lens_Clear).

    blender -b --python tools/logo_paint/ronin_cp9a_champ_split.py -- in.blend out.blend
"""
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
CORNERS = ("FL", "FR", "RL", "RR")

# picture areas (stored picture px, x0, y0, x1, y1, top-left origin) of Image_1 (1024) that are NOT paint although red-ish:
# lamp lenses, the side reflector, the swatch block, the third brake lamp strip
NOT_PAINT = [(845, 990, 945, 1024), (688, 207, 805, 252)]
# (each checked by the faces that read it and by renders with the paint turned blue: the third brake lamp's strip, the headlamp
#  picture; every other red of the atlas is paint: body faces that read the tail-lamp pictures' edges showed as red slivers)
# the livery stripe bands (their white / grey / black pixels count as paint): both sides' stripe + wedge, the wing swooshes; and
# the rear wing blade's white top (the real car's wing is body colour)
STRIPES = [(100, 330, 910, 382), (100, 438, 268, 472), (100, 738, 268, 766), (100, 822, 910, 874), (305, 472, 400, 730)]
UV_CUTS = [("Image_3", (316, 344, 511, 511), "the grille emblem (raised piece)")]


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
ext = [o for o in meshes() if mat_has(o, "champ_ext") and not o.name.startswith(CORNERS + ("SteeringWheel", "SeeThrough"))]
for o in ext:
    m = o.data.materials[0]
    img = tex_of(m)
    W, H = img.size
    px = np.empty(W * H * img.channels, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(H, W, img.channels)[::-1]  # top-left origin, like the stored picture
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    red = (r > 0.12) & (g < 0.55 * r) & (b < 0.55 * r) & (np.abs(g - b) < 0.12)
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
    pm = bpy.data.materials.get("champ_paint") or m.copy()
    pm.name = "champ_paint"
    nt = pm.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    for k in [k for k in nt.nodes if k.type == "TEX_IMAGE"]:
        nt.nodes.remove(k)
    bsdf.inputs["Base Color"].default_value = (*[float(c) ** 2.2 for c in colour], 1.0)
    n = split_off(o, pick, "Body_champ_paint", pm)
    # the paint's red left in the atlas (seen only on the few textured faces that cross a panel's edge: the panel gaps' dark
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
    cm.name = "champ_caliper"
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
        far = (d.max() < -0.06 and off > 0.02) or (off > 0.09 and d.min() < -0.08) or (off > 0.15 and d.min() < -0.05) or off > 0.22
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

# ---- 5. the rear doors' outer skins as their own loose pieces (edges split along the outline)
FRONT = [(0.30, 0.3035), (0.376, 0.3023), (0.407, 0.2993), (0.435, 0.2963), (0.472, 0.2943), (0.54, 0.2893), (0.60, 0.2883),
         (0.70, 0.2873), (0.77, 0.2883), (0.81, 0.2883), (0.84, 0.2903), (0.864, 0.2923), (0.90, 0.2963), (0.932, 0.3003),
         (0.95, 0.3033), (1.05, 0.3033)]            # (z, y): the front gap's door-side line (its rear line - 0.7 mm)
REAR = [(0.785, 1.2125), (0.814, 1.2355), (0.852, 1.2428), (0.876, 1.2459), (0.90, 1.2475), (0.94, 1.2476), (0.99, 1.2430),
        (1.0, 1.2401), (1.05, 1.2401)]               # (z, y): the rear gap's door-side line
FLARE = [(0.34, 0.7945), (0.384, 0.7955), (0.412, 0.7985), (0.442, 0.8035), (0.474, 0.8125), (0.507, 0.8245), (0.539, 0.8375),
         (0.587, 0.8645), (0.614, 0.8805), (0.630, 0.8995), (0.645, 0.9155), (0.702, 0.9775), (0.733, 1.0295), (0.758, 1.0815),
         (0.775, 1.1365), (0.786, 1.1915), (0.789, 1.2125)]   # (z, y): the flare's gap, door side
Z_SILL = 0.345
TOP = ((0.29, 0.965), (1.25, 1.015))                 # the belt (y, z) and a little over it: the door skin's top edge


def interp(tab, z):
    zs, ys = zip(*tab)
    return float(np.interp(z, zs, ys))


def in_rear_door(c):
    x, y, z = abs(c[0]), c[1], c[2]
    if x < 0.6 or z < Z_SILL or y < 0.25 or y > 1.3:
        return False
    (y0, z0), (y1, z1) = TOP
    if z > z0 + (z1 - z0) * (y - y0) / (y1 - y0):
        return False
    if y <= interp(FRONT, z):
        return False
    if z >= 0.789:
        return y < interp(REAR, z)
    return y < interp(FLARE, z)


# the card's outline (y, z), 1.5 cm inside the door skin's: the rear edge, the flare, down to the sill line (in order round the door)
CARD_EDGE = [(1.225, 1.05), (1.225, 0.80), (1.198, 0.797), (1.068, 0.766), (0.966, 0.710), (0.888, 0.638), (0.826, 0.547),
             (0.792, 0.450), (0.783, 0.345), (0.25, 0.345)]


def in_card_outline(c):
    y, z = c[1], c[2]
    if z < Z_SILL:
        return False
    if z >= 0.797:
        return y < 1.225
    zs = [q[1] for q in CARD_EDGE[1:-1]][::-1]
    ys = [q[0] for q in CARD_EDGE[1:-1]][::-1]
    return y < float(np.interp(z, zs, ys))


def in_rear_card(c):
    """the rear door card in the low cabin sheet's mesh (champ_cab: one piece with the rear seats and the C-pillar trims)"""
    return abs(c[0]) >= 0.64 and 0.30 <= c[1] <= 1.22 and 0.25 <= c[2] <= 1.02


for o in [o for o in meshes() if o.name.startswith("Body_") and (mat_has(o, "champ_paint") or mat_has(o, "champ_ext") or mat_has(o, "champ_cab"))]:
    bm = bmesh.new()
    bm.from_mesh(o.data)
    M = o.matrix_world
    test = in_rear_card if mat_has(o, "champ_cab") else in_rear_door
    if mat_has(o, "champ_cab"):
        # (the card is a coarse fan that reaches 9 cm under the door's bottom edge and past its rear / flare edge: its faces are cut
        #  along the door's own outline drawn 1.5 cm inside the skin's (CARD_EDGE: the bottom z 0.345, the flare, the rear edge),
        #  so the door takes only the card that lies inside the door and the strips outside stay with the body)
        Mi = M.inverted()
        for (y0, z0), (y1, z1) in zip(CARD_EDGE[:-1], CARD_EDGE[1:]):
            card = [f for f in bm.faces if in_rear_card(M @ f.calc_center_median())]
            if not card:
                break
            geom = list({v for f in card for v in f.verts}) + list({e for f in card for e in f.edges}) + card
            co = Mi @ Vector((0.0, y0, z0))
            no = (Mi.to_3x3() @ Vector((0.0, -(z1 - z0), (y1 - y0)))).normalized()
            bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=no)
        bm.faces.ensure_lookup_table()
        test = lambda c: in_rear_card(c) and in_card_outline(c)
    door = {f.index for f in bm.faces if test(M @ f.calc_center_median())}
    bm.faces.ensure_lookup_table()
    edges = [e for e in bm.edges if len(e.link_faces) >= 2 and len({f.index in door for f in e.link_faces}) == 2]
    if door:
        bmesh.ops.split_edges(bm, edges=edges)
        bm.to_mesh(o.data)
    bm.free()
    print("SPLIT rear doors:", o.name, len(door), "faces inside the outlines,", len(edges), "edges split")

# ---- 6. the lamps' clear covers out of the window glass (material windows is both): their own part (material champ_lens), so
# finish_car names it SeeThrough_Lens_Clear (the game's clear lens look, not the dark window tint)
win = next((o for o in meshes() if o.name.startswith("SeeThrough") and mat_has(o, "windows")), None)
if win is not None:
    M = win.matrix_world
    lens = [p.index for p in win.data.polygons
            if ((M @ p.center).y < -1.6 and (M @ p.center).z < 0.76) or ((M @ p.center).y > 1.9 and (M @ p.center).z < 1.06)]
    lm = win.data.materials[0].copy()
    lm.name = "champ_lens"
    n = split_off(win, lens, "SeeThrough_champ_lens", lm)
    P = world_co(n)
    print("SPLIT lamp covers ->", n.name, len(n.data.polygons), "faces, box", P.min(0).round(3).tolist(), P.max(0).round(3).tolist(), "; windows left", len(win.data.polygons))

bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("SPLIT saved", a[1])
