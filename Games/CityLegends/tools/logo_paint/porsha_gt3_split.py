"""porsha_gt3_split.py -- in.blend out.blend : the 2019 model of `porsha_gt3` cut up by piece, between auto_car.py and
tools/lambo/finish_car.py (2026-11-12). The file is a racing game's car: a handful of materials each shared by pieces
that must not share a part in our game. Pieces = loose pieces after welding by position (the .glb splits them at
every seam). Boxes in car metres (x left, y back, z up).

  * the roll cage is in the body paint: its pieces (inside the cabin box behind the seats) get their own material
    "Cage_Tube", so Customs paint never recolours it;
  * the black paint ("Black_Gloss") keeps only the door mirrors' shells. The side stripes (the model script is cut out
    of them) and the maker's letters on the wing are not stuck on: the paint and the wing's carbon have holes their
    shape, flush. So the stripe pieces become body paint (joined into the paint part: a plain sill and door again) and
    the wing letters become carbon, with the wing top's own weave carried over them (UVs fitted from the faces round
    each letter);
  * the badge sheet goes (crest, scripts, maker's letters, sill plates, mat labels, stickers, filler caps, bolt-head
    stickers); its one real part, the plate round the gear lever, is kept as "Shift_Plate" (dropped here and not by
    finish_car.py, which would try a paint cover on the carbon bonnet where the crest was);
  * the cabin's carbon (seat shells, dash, door and console strips, sill guards, the steering wheel's trim) becomes
    "Cabin_Carbon" (glossy carbon inside a cabin mirrors the sky); the carbon plinth under the bonnet crest goes
    (the bonnet is closed under it);
  * the palette material ("Coloured"): the three mirror glasses become "Mirror_Glass", the exhaust (silencers, tips)
    "Exhaust_Metal", the pieces inside the cabin (belts, buckles, the mirror's housing, pedals) "Cabin_Black";
  * the model script's two letters at the top of the rear window are glass let into holes of the black trim band (holes
    right through into the cabin): each letter's upper glass layer becomes the band's own black and closes the hole,
    the lower layer and the letters' side walls go;
  * the cabin's other marks go: the shield's raised outline on the steering hub (the pad under it is closed), the
    package name's two plates on each headrest (the script under them is painted out of the cabin picture);
  * the faces of the two outer twin dials (oil; water / fuel) are pushed 22 mm back, like pits (walls join them to
    their old outlines): they stand 14 to 21 mm in front of the three middle dials' plane and lean 9 degrees inwards,
    so they would hide the live cluster panel (one flat picture just in front of the middle dials) where it draws
    those two dials. Pushed back they lie 1 to 11 mm behind the panel: a dark floor under it, and the tubes stay
    closed all round (a face only moved back left a slit that showed the body's paint from the passenger's side);
  * the wheels: the tyre valves go (they float after the wheel swap); each wheel is split into "Rim_Dark",
    "Tyre_Rubber" and "Disc_Ceramic";
  * the glow pictures are unlinked (they use the file's second UV set, which the conversion drops: sampled with the
    first they smear dial faces and words over the whole cabin and the lamps).
"""
import sys

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)

CABIN = (-0.80, -0.75, 0.19, 0.80, 1.45, 1.21)        # everything a piece must lie inside to count as "in the cabin"
CAGE = (-0.61, 0.54, 0.39, 0.61, 1.22, 1.25)          # the cage: hoop, cross, rear stays, their brackets
CABIN_CARBON = (-0.80, -0.50, 0.19, 0.80, 0.62, 1.12)
report = {}


def meshes():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def by_mat(word, body=True):
    r = [o for o in meshes() if o.data.materials and o.data.materials[0] and word.lower() in o.data.materials[0].name.lower() and (not body or o.name.startswith("Body_"))]
    assert r, word
    return r


def pieces(o):
    """[(polygon indices, lo, hi)] of the welded loose pieces, world metres"""
    me = o.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    M = np.array(o.matrix_world)
    w = co @ M[:3, :3].T + M[:3, 3]
    _, key = np.unique(np.round(co, 5), axis=0, return_inverse=True)
    key = key.reshape(-1)
    par = list(range(int(key.max()) + 1))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    polys = [list(p.vertices) for p in me.polygons]
    for vs in polys:
        r = find(key[vs[0]])
        for v in vs[1:]:
            par[find(key[v])] = r
    groups = {}
    for i, vs in enumerate(polys):
        groups.setdefault(find(key[vs[0]]), []).append(i)
    out = []
    for idx in groups.values():
        vi = np.unique(np.concatenate([polys[i] for i in idx]))
        out.append((idx, w[vi].min(0), w[vi].max(0)))
    return out


def inside(lo, hi, box):
    return lo[0] >= box[0] and lo[1] >= box[1] and lo[2] >= box[2] and hi[0] <= box[3] and hi[1] <= box[4] and hi[2] <= box[5]


def keep_faces(o, keep):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    kill = [f for f in bm.faces if not keep[f.index]]
    if kill:
        bmesh.ops.delete(bm, geom=kill, context="FACES")
    bm.to_mesh(o.data)
    bm.free()
    o.data.update()


def take(o, sel, name, mat):
    """the polygons sel (bool array) of o become a new part `name` wearing `mat`; o keeps the rest"""
    sel = np.asarray(sel, dtype=bool)
    if not sel.any():
        return None
    new = o.copy()
    new.data = o.data.copy()
    for c in o.users_collection:
        c.objects.link(new)
    keep_faces(new, sel)
    keep_faces(o, ~sel)
    new.name = name
    new.data.name = name
    if mat is not None:
        new.data.materials.clear()
        new.data.materials.append(mat)
    return new


def drop(o, sel):
    sel = np.asarray(sel, dtype=bool)
    if sel.any():
        keep_faces(o, ~sel)
    return int(sel.sum())


def mask(o, idx_lists):
    m = np.zeros(len(o.data.polygons), dtype=bool)
    for idx in idx_lists:
        m[idx] = True
    return m


def tris(o, m=None):
    t = np.array([len(p.vertices) - 2 for p in o.data.polygons])
    return int(t.sum() if m is None else t[m].sum())


def clone(mat, name):
    m = mat.copy()
    m.name = name
    return m


def plain(name, rgb):
    """a material of one plain colour, as auto_car.py bakes them (an 8 x 8 picture on the base colour)"""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    img = bpy.data.images.new("col_" + name, 8, 8)
    img.pixels = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0] * 64
    img.pack()
    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def remove(o):
    bpy.data.objects.remove(o, do_unlink=True)


def join(into, o):
    """o's faces into the part `into` (same material slot, same UV layer name)"""
    o.data.uv_layers[0].name = into.data.uv_layers[0].name
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    into.select_set(True)
    bpy.context.view_layer.objects.active = into
    bpy.ops.object.join()


# ------------------------------------------------------------------ glow pictures off (second UV set)
n = 0
for m in bpy.data.materials:
    if not (m.use_nodes and m.node_tree):
        continue
    b = m.node_tree.nodes.get("Principled BSDF")
    if b is None:
        continue
    for nm in ("Emission Color", "Emission Strength"):
        s = b.inputs.get(nm)
        if s is not None:
            for link in list(s.links):
                m.node_tree.links.remove(link)
                n += 1
    b.inputs["Emission Strength"].default_value = 0.0
report["glow links off"] = n

# ------------------------------------------------------------------ the cage out of the paint
(paint,) = by_mat("Paint_Material")
pcs = pieces(paint)
cage = [p for p in pcs if inside(p[1], p[2], CAGE)]
m = mask(paint, [p[0] for p in cage])
report["cage"] = [len(cage), tris(paint, m)]
assert 15 <= len(cage) <= 30 and 600 < tris(paint, m) < 1200, report
take(paint, m, "Body_Cage_Tube", plain("Cage_Tube", (24, 24, 26)))

# ------------------------------------------------------------------ black paint: only the mirrors' shells stay
(black,) = by_mat("Black_Gloss")
pcs = pieces(black)
low = [p for p in pcs if p[2][2] < 0.45]            # the side stripes and the bits inside the script's letters
high = [p for p in pcs if p[1][2] > 1.15]           # the seven wing letters
assert len(pcs) - len(low) - len(high) == 4 and len(high) == 7, (len(pcs), len(low), len(high))
m = mask(black, [p[0] for p in low])
report["black paint"] = {"stripe pieces into the paint": len(low), "tris": tris(black, m)}
join(paint, take(black, m, "Body_Stripe_Fill", paint.data.materials[0]))
m = mask(black, [p[0] for p in pieces(black) if p[1][2] > 1.15])
report["black paint"]["wing letters into the carbon"] = [7, tris(black, m)]
letters = take(black, m, "Body_Wing_Fill", None)
report["black paint"]["left (mirror shells and feet)"] = tris(black)

# ------------------------------------------------------------------ the badge sheet: the gear lever's plate stays
(badge,) = by_mat("BadgeA")
pcs = pieces(badge)
plate = [p for p in pcs if inside(p[1], p[2], (-0.06, -0.33, 0.55, 0.06, -0.17, 0.62)) and len(p[0]) > 20]
assert len(plate) == 1, len(plate)
m = mask(badge, [plate[0][0]])
report["shift plate"] = tris(badge, m)
take(badge, m, "Body_Shift_Plate", plain("Shift_Plate", (58, 58, 62)))
report["badge pieces dropped"] = [len(pcs) - 1, tris(badge)]
remove(badge)
for o in [o for o in meshes() if o.name.startswith("SteeringWheel") and "badge" in o.data.materials[0].name.lower()]:
    report["hub badge"] = tris(o)
    remove(o)

# ------------------------------------------------------------------ carbon
(carbon,) = by_mat("Carbon1")
cabcarbon = clone(carbon.data.materials[0], "Cabin_Carbon")
pcs = pieces(carbon)
plinth = [p for p in pcs if inside(p[1], p[2], (-0.05, -2.03, 0.61, 0.05, -1.92, 0.68))]
assert len(plinth) == 1, len(plinth)
m = mask(carbon, [p[0] for p in plinth])
report["carbon cut"] = {"crest plinth": len(plinth[0][0]), "tris": tris(carbon, m)}
drop(carbon, m)
# the wing letters: the wing top's own weave carried over them. A letter's outline points are the hole's points in the
# wing's carbon, so each takes that point's UV (the weave runs on without a seam); a point that has no twin gets a fit
# (second order) of the wing top's UVs round the letter
from mathutils import kdtree

me = carbon.data
M = np.array(carbon.matrix_world)
co = np.empty(len(me.vertices) * 3)
me.vertices.foreach_get("co", co)
cw = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
cuv = np.empty(len(me.loops) * 2, dtype=np.float32)
me.uv_layers.active.data.foreach_get("uv", cuv)
cuv = cuv.reshape(-1, 2)
top = []                                              # (x, y, z, u, v) of the wing top's corners
for p in me.polygons:
    c = cw[list(p.vertices)].mean(0)
    if c[2] > 1.15 and 1.90 < c[1] < 2.16 and abs(c[0]) < 0.78 and (M[:3, :3] @ np.array(p.normal))[2] > 0.8:
        for li, vi in zip(p.loop_indices, p.vertices):
            top.append((*cw[vi], *cuv[li]))
top = np.array(top)
kd = kdtree.KDTree(len(top))
for i, r in enumerate(top):
    kd.insert(r[:3], i)
kd.balance()
lme = letters.data
LM = np.array(letters.matrix_world)
lco = np.empty(len(lme.vertices) * 3)
lme.vertices.foreach_get("co", lco)
lw = lco.reshape(-1, 3) @ LM[:3, :3].T + LM[:3, 3]
luv = lme.uv_layers.active.data
twin = fitted = 0
worst = 0.0


def quad(x, y):
    return np.c_[np.ones(len(x)), x, y, x * x, x * y, y * y]


for idx, lo, hi in pieces(letters):
    near = top[(top[:, 0] > lo[0] - 0.03) & (top[:, 0] < hi[0] + 0.03)]
    x0, y0 = near[:, 0].mean(), near[:, 1].mean()
    A = quad(near[:, 0] - x0, near[:, 1] - y0)
    sol, *_ = np.linalg.lstsq(A, near[:, 3:5], rcond=None)
    worst = max(worst, float(np.abs(A @ sol - near[:, 3:5]).max()))
    for i in idx:
        p = lme.polygons[i]
        for li, vi in zip(p.loop_indices, p.vertices):
            _, k, d = kd.find(lw[vi])
            if d < 0.0004:
                luv[li].uv = tuple(top[k, 3:5])
                twin += 1
            else:
                luv[li].uv = tuple((quad(np.array([lw[vi][0] - x0]), np.array([lw[vi][1] - y0])) @ sol)[0])
                fitted += 1
report["wing letters"] = {"corners on the hole's own points": twin, "corners fitted": fitted, "the fit's worst miss (weave tiles)": round(worst, 4)}
assert twin > 5 * fitted and worst < 0.06, report
letters.data.materials.clear()
letters.data.materials.append(carbon.data.materials[0])
join(carbon, letters)
pcs = pieces(carbon)
cab = [p for p in pcs if inside(p[1], p[2], CABIN_CARBON)]
m = mask(carbon, [p[0] for p in cab])
report["cabin carbon"] = [len(cab), tris(carbon, m), "outside", tris(carbon) - tris(carbon, m)]
assert 5000 > tris(carbon, m) > 3000, report
take(carbon, m, "Body_Cabin_Carbon", cabcarbon)
for o in meshes():
    if o.name.startswith("SteeringWheel") and "carbon" in o.data.materials[0].name.lower():
        o.data.materials[0] = cabcarbon
        report["wheel carbon"] = tris(o)

# ------------------------------------------------------------------ the palette material
(col,) = by_mat("Coloured")
me = col.data
img = next(nd.image for nd in me.materials[0].node_tree.nodes if nd.type == "TEX_IMAGE" and nd.image and nd.image.size[0] == 256)
W, H = img.size
px = np.empty(W * H * 4, dtype=np.float32)
img.pixels.foreach_get(px)
px = (px.reshape(H, W, 4)[..., :3] * 255).round().astype(int)
uv = me.uv_layers.active.data
nl = len(me.loops)
uvs = np.empty(nl * 2, dtype=np.float32)
uv.foreach_get("uv", uvs)
uvs = uvs.reshape(nl, 2)
grey = np.zeros(len(me.polygons), dtype=int)
for p in me.polygons:
    u = uvs[p.loop_start : p.loop_start + p.loop_total].mean(0)
    c = px[min(H - 1, int((u[1] % 1) * H)), min(W - 1, int((u[0] % 1) * W))]
    grey[p.index] = c[0] if c[0] == c[1] == c[2] else -1
glass = grey == 193
report["mirror glass"] = tris(col, glass)
assert 80 <= tris(col, glass) <= 90, report
take(col, glass, "Body_Mirror_Glass", plain("Mirror_Glass", (150, 156, 166)))
# the exhaust: the silver and dark-silver cells low at the back
me = col.data
pcs = pieces(col)
uvs = np.empty(len(me.loops) * 2, dtype=np.float32)
me.uv_layers.active.data.foreach_get("uv", uvs)
uvs = uvs.reshape(-1, 2)
grey = np.zeros(len(me.polygons), dtype=int)
for p in me.polygons:
    u = uvs[p.loop_start : p.loop_start + p.loop_total].mean(0)
    c = px[min(H - 1, int((u[1] % 1) * H)), min(W - 1, int((u[0] % 1) * W))]
    grey[p.index] = c[0] if c[0] == c[1] == c[2] else -1
ex = [p for p in pcs if p[1][1] > 1.6 and p[2][2] < 0.45 and int(np.median(grey[p[0]])) in (129, 49, 50)]
m = mask(col, [p[0] for p in ex])
report["exhaust"] = [len(ex), tris(col, m)]
assert tris(col, m) > 3500, report
steel = clone(me.materials[0], "Exhaust_Metal")
take(col, m, "Body_Exhaust_Metal", steel)
pcs = pieces(col)
cab = [p for p in pcs if inside(p[1], p[2], CABIN)]
m = mask(col, [p[0] for p in cab])
report["cabin black"] = [len(cab), tris(col, m)]
for p in sorted(cab, key=lambda p: -len(p[0]))[:40]:
    print("CABINBLACK %5d lo %s hi %s" % (len(p[0]), p[1].round(3).tolist(), p[2].round(3).tolist()))
take(col, m, "Body_Cabin_Black", clone(col.data.materials[0], "Cabin_Black"))

# ------------------------------------------------------------------ small marks: rear window letters, hub shield, headrests
def drop_in(o, boxes, most, want):
    pcs = pieces(o)
    hit = [p for p in pcs if len(p[0]) <= most and any(inside(p[1], p[2], b) for b in boxes)]
    assert len(hit) == want, (o.name, [(len(p[0]), p[1].round(3).tolist(), p[2].round(3).tolist()) for p in hit])
    m = mask(o, [p[0] for p in hit])
    t = tris(o, m)
    drop(o, m)
    return [len(hit), t]


RS = [(-0.05, 0.92, 1.2, 0.05, 0.956, 1.222)]
# The trim band at the top of the rear window has two holes the script letters' shape, right through into the cabin. In each
# sit a glass letter (two layers) and black side walls. The upper glass layer of each letter becomes the band's own black
# (its cell of the palette picture) and part of the palette part: the band is closed and plain. The rest goes.
(win,) = by_mat("Window_Material", body=False)
(base,) = by_mat("Base_Material")
pcs = [p for p in pieces(win) if len(p[0]) <= 60 and inside(p[1], p[2], RS[0])]
assert len(pcs) == 4, [(len(p[0]), p[1].round(3).tolist()) for p in pcs]
top = sorted(pcs, key=lambda p: -p[1][2])[:2]                       # the two upper layers (one a letter)
assert abs(top[0][1][0] - top[1][1][0]) > 0.02, "two layers of one letter"
m = mask(win, [p[0] for p in top])
report["rear window letters"] = {"upper glass layers made band fills": [2, tris(win, m)]}
fill = take(win, m, "Body_Band_Fill", col.data.materials[0])
FM = np.array(fill.matrix_world)[:3, :3]
if sum((FM @ np.array(p.normal))[2] * p.area for p in fill.data.polygons) < 0:   # they must face up (only a face's front is drawn)
    fill.data.flip_normals()
    report["rear window letters"]["turned to face up"] = True
BAND_UV = (238.8 / 256, 1 - 176.8 / 256)            # the band's cell in the 256 px palette picture
for lp in fill.data.uv_layers.active.data:
    lp.uv = BAND_UV
join(col, fill)
report["rear window letters"]["lower glass layers dropped"] = drop_in(win, RS, 60, 2)
report["rear window letters"]["side walls dropped"] = drop_in(base, RS, 120, 2)
HEAD = [(0.24, 0.42, 0.96, 0.42, 0.44, 1.04), (-0.42, 0.48, 0.96, -0.24, 0.50, 1.04)]
(piping,) = by_mat("Interior_Piping")
report["headrest plates"] = drop_in(piping, HEAD, 12, 4)     # (the script under them is in the cabin picture: painted out there)
hub = [o for o in meshes() if o.name.startswith("SteeringWheel") and "interiora" in o.data.materials[0].name.lower()]
assert len(hub) == 1, [o.name for o in hub]
report["hub shield outline"] = drop_in(hub[0], [(0.314, -0.24, 0.754, 0.357, -0.214, 0.807)], 60, 1)

# ------------------------------------------------------------------ the two outer dial faces (by their place in the cabin picture)
(cabin,) = by_mat("InteriorA")
me = cabin.data
M = np.array(cabin.matrix_world)
co = np.empty(len(me.vertices) * 3)
me.vertices.foreach_get("co", co)
w = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
uvs = np.empty(len(me.loops) * 2, dtype=np.float32)
me.uv_layers.active.data.foreach_get("uv", uvs)
uvs = uvs.reshape(-1, 2)
OUTER = [(0, 196, 81, 284), (0, 284, 87, 375)]              # stored 512 px rects (v down) of the two twin dials
sel = np.zeros(len(me.polygons), dtype=bool)
for p in me.polygons:
    c = w[list(p.vertices)].mean(0)
    if not (0.14 < abs(c[0] - 0.3375) < 0.20 and -0.50 < c[1] < -0.45 and 0.76 < c[2] < 0.85):
        continue
    u = uvs[p.loop_start : p.loop_start + p.loop_total].mean(0)
    ux, uy = (u[0] % 1) * 512, (1 - u[1] % 1) * 512
    sel[p.index] = any(x0 <= ux <= x1 and y0 <= uy <= y1 for x0, y0, x1, y1 in OUTER)
report["outer dial faces moved back 22 mm"] = tris(cabin, sel)
assert report["outer dial faces moved back 22 mm"] == 48, report
back = np.linalg.inv(M[:3, :3]) @ (np.array([0.0, 0.9557, 0.2944]) * -0.022)      # along the middle dials' normal, away from the driver
bm = bmesh.new()
bm.from_mesh(me)
bm.faces.ensure_lookup_table()
old_faces = [f for f in bm.faces if sel[f.index]]
ext = bmesh.ops.extrude_face_region(bm, geom=old_faces)                               # pushed in like a pit: the faces go back,
moved = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]                 # walls join them to their old outlines
bmesh.ops.translate(bm, verts=moved, vec=tuple(back))
# (a whole loose piece pushed in keeps its old faces as a lid: they must go, or they hide the panel)
lids = [f for f in old_faces if f.is_valid]
bmesh.ops.delete(bm, geom=lids, context="FACES_ONLY")
bm.normal_update()
# every face of the two pits must look out of the pit, towards the driver (only a face's front is drawn)
N = np.array([0.0, 0.9557, 0.2944])
floors = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMFace)]
turn = [f for f in floors if (M[:3, :3] @ np.array(f.normal)) @ N < 0]
walls = [f for f in bm.faces if any(v in set(moved) for v in f.verts) and f not in floors]
cx = {}
for f in walls:      # a wall looks towards its pit's middle
    c = M[:3, :3] @ np.array(f.calc_center_median()) + M[:3, 3]
    side = 1 if c[0] > 0.3375 else -1
    cx.setdefault(side, []).append(c)
for f in walls:
    c = M[:3, :3] @ np.array(f.calc_center_median()) + M[:3, 3]
    mid = np.mean(cx[1 if c[0] > 0.3375 else -1], axis=0)
    inward = mid - c
    inward -= N * (inward @ N)
    if (M[:3, :3] @ np.array(f.normal)) @ inward < 0:
        turn.append(f)
bmesh.ops.reverse_faces(bm, faces=list(set(turn)))
report["outer dial pits"] = {"lids removed": len(lids), "floor faces": len(floors), "wall faces": len(walls), "turned round": len(set(turn))}
bm.to_mesh(me)
bm.free()
me.update()
report["outer dial pits"]["cabin tris now"] = tris(cabin)

# ------------------------------------------------------------------ wheels
rim = by_mat("Wheel_Rim", body=False)
tyre_m = clone(rim[0].data.materials[0], "Tyre_Rubber")
disc_m = clone(rim[0].data.materials[0], "Disc_Ceramic")
cnt = {"valves": 0, "tyre": 0, "disc": 0, "rim": 0}
for o in list(rim):
    if "static" in o.name:
        cnt["valves"] += tris(o)
        remove(o)
        continue
    corner = o.name[:2]
    me = o.data
    M = np.array(o.matrix_world)
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    w = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
    c = (w.min(0) + w.max(0)) / 2
    r = np.hypot(w[:, 1] - c[1], w[:, 2] - c[2])
    R = r.max()
    uvs = np.empty(len(me.loops) * 2, dtype=np.float32)
    me.uv_layers.active.data.foreach_get("uv", uvs)
    uvs = uvs.reshape(-1, 2)
    disc = np.zeros(len(me.polygons), dtype=bool)
    for idx, lo, hi in pieces(o):
        vi = np.unique(np.concatenate([list(me.polygons[i].vertices) for i in idx]))
        if 0.18 < r[vi].max() < 0.225 and r[vi].min() < 0.02 and len(idx) < 200:
            disc[idx] = True
    tyre = np.zeros(len(me.polygons), dtype=bool)
    for p in me.polygons:
        if disc[p.index]:
            continue
        u = uvs[p.loop_start : p.loop_start + p.loop_total].mean(0)
        ux, uy = (u[0] % 1) * 512, (1 - u[1] % 1) * 512
        swatch = 260 <= ux <= 282 and 0 <= uy <= 22          # the rim's own plain colour
        if not swatch and r[list(p.vertices)].min() > 0.20:
            tyre[p.index] = True
    cnt["tyre"] += tris(o, tyre)
    cnt["disc"] += tris(o, disc)
    cnt["rim"] += tris(o) - tris(o, tyre) - tris(o, disc)
    take(o, tyre, corner + "_Tyre_Rubber", tyre_m)
    disc = np.zeros(len(o.data.polygons), dtype=bool)   # (the indices changed: find the disc again in what is left)
    me = o.data
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    w = co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
    r = np.hypot(w[:, 1] - c[1], w[:, 2] - c[2])
    for idx, lo, hi in pieces(o):
        vi = np.unique(np.concatenate([list(me.polygons[i].vertices) for i in idx]))
        if 0.18 < r[vi].max() < 0.225 and r[vi].min() < 0.02 and len(idx) < 200:
            disc[idx] = True
    take(o, disc, corner + "_Disc_Ceramic", disc_m)
report["wheels"] = cnt
assert cnt["valves"] == 208 and cnt["disc"] == 420 and cnt["tyre"] > 3000, cnt

for o in meshes():
    if len(o.data.polygons) == 0:
        report.setdefault("empty removed", []).append(o.name)
        remove(o)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("SPLIT", report)
for o in sorted(meshes(), key=lambda o: o.name):
    print("PART %-34s %6d %s" % (o.name, tris(o), o.data.materials[0].name if o.data.materials else None))
