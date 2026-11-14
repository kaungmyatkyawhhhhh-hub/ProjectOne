"""toyoka_chaser_split.py -- in.blend out.blend wood.png : the Chaser JZX100's per-car Blender step, between auto_car.py and
finish_car.py (2026-11-14, the 10 JDM imports; replaces the model of toyoka_chaser).

The model is a Roblox export (plain colours, material names like "Meshesuntihgjjtled1Mtl"), so this step gives every surface
a plain name by what it is and takes the logos out of the meshes (owner, 2026-11-14: remove, never cover):
  * the two column stalk / shroud bits auto_car.py cut into "SteeringWheel_t18.001" go back into the cabin (they would turn
    with the wheel and pull the wheel's box off its axis); the wheel keeps only its own pieces;
  * the badges are loose chrome pieces: the boot's oval emblem, the boot letters left ("CHASER", 6 pieces) and right
    ("TOURER V", 7 pieces), the grille emblem (2 chrome pieces + its dark base): deleted whole (they sit on the panels; the
    paint under them is whole, checked in renders);
  * the emblem's mounting strip behind the grille's middle (a body-paint piece, 588 triangles, 3.5 cm wide, z 0.33-0.68)
    showed through the slats as a pale (in the game: paint-coloured) bar where the emblem was: it goes into the outside
    black trim, like the grille's backing (added 14:40, the resumed run);
  * the dark material (seats, dash, door cards, carpet AND the outside black trims and lamp insides) is split by place:
    cabin_black (matt), trim_black (outside), light_dark (headlamp and tail lamp insides), mirror_glass (the two door mirror
    glasses);
  * the black planes that close the engine bay and the boot -> base_black; the tyres get their own rubber colour;
  * the wood (a pale Roblox wood picture drawn as emission over a white 1-bit picture: it would come in white) -> one plain
    material with a dark walnut-grey picture (tools/logo_paint/toyoka_chaser_wood.png) as its base colour;
  * no emission anywhere (the export drew the rims', chrome's, steering wheel's and lamps' pictures as emission too).

    blender -b --python tools/logo_paint/toyoka_chaser_split.py -- in.blend out.blend tools/logo_paint/toyoka_chaser_wood.png
"""
import sys

import bmesh
import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])
bpy.context.scene.tool_settings.mesh_select_mode = (False, False, True)
OB = bpy.data.objects


def srgb2lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def make_mat(name, rgb, image=None):
    """a plain material: base colour from an 8 x 8 picture of that colour (as auto_car.py bakes them), or from a picture"""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage")
    if image is None:
        image = bpy.data.images.new("col_" + name, 8, 8)
        lin = [srgb2lin(c) for c in rgb]
        image.pixels.foreach_set(np.tile(np.array(lin + [1.0], np.float32), 64))
        image.pack()
    t.image = image
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.5
    b.inputs["Metallic"].default_value = 0.0
    return m


def recolour(m, name, rgb=None):
    """rename a material (and its baked colour picture); a new colour if given"""
    m.name = name
    for n in m.node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image and n.image.name.startswith("col_"):
            n.image.name = "col_" + name
            if rgb is not None:
                img = n.image
                W, H = img.size
                lin = [srgb2lin(c) for c in rgb]
                img.pixels.foreach_set(np.tile(np.array(lin + [1.0], np.float32), W * H))
                img.pack()
    return m


def world_co(o):
    me = o.data
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    M = np.array(o.matrix_world)
    return co @ M[:3, :3].T + M[:3, 3]


def pieces(o):
    """[(face index array, lo, hi)] of the loose pieces (welded by place)"""
    me = o.data
    co = world_co(o)
    key = np.unique(np.round(co, 5), axis=0, return_inverse=True)[1].reshape(-1)
    par = list(range(int(key.max()) + 1)) if len(key) else []

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x

    for p in me.polygons:
        r = find(key[p.vertices[0]])
        for v in p.vertices[1:]:
            par[find(key[v])] = r
    lab = np.array([find(key[p.vertices[0]]) for p in me.polygons])
    out = []
    for l in np.unique(lab):
        f = np.where(lab == l)[0]
        v = sorted({i for k in f for i in me.polygons[k].vertices})
        out.append((f, co[v].min(0), co[v].max(0)))
    return out


def inside(lo, hi, box, absx=False):
    x0, y0, z0, x1, y1, z1 = box
    if absx:
        if lo[0] >= 0:
            lx, hx = lo[0], hi[0]
        elif hi[0] <= 0:
            lx, hx = -hi[0], -lo[0]
        else:
            return False
    else:
        lx, hx = lo[0], hi[0]
    return lx >= x0 and hx <= x1 and lo[1] >= y0 and hi[1] <= y1 and lo[2] >= z0 and hi[2] <= z1


def delete_faces(o, faces):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[int(i)] for i in faces], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()


def assign(o, faces_by_mat):
    """{material: [faces]}: new slots on the object, those faces take them"""
    me = o.data
    for m, faces in faces_by_mat.items():
        if not len(faces):
            continue
        if m.name not in [x.name for x in me.materials if x]:
            me.materials.append(m)
        idx = [x.name if x else "" for x in me.materials].index(m.name)
        for f in faces:
            me.polygons[int(f)].material_index = idx


def separate_by_material(o):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="MATERIAL")
    bpy.ops.object.mode_set(mode="OBJECT")
    for x in bpy.context.selected_objects:
        used = {p.material_index for p in x.data.polygons}
        if len(used) == 1:
            m = x.data.materials[used.pop()]
            for i in range(len(x.data.materials) - 1, -1, -1):
                if x.data.materials[i] != m:
                    x.data.materials.pop(index=i)
            x.name = "Body_" + m.name
            x.data.name = x.name


log = []
# ------------------------------------------------------------------ 1. the stalk bits back into the cabin
dark = OB["Body_Meshesuntihgjjtled1Mtl"]
for sw in [o for o in OB if o.type == "MESH" and o.name.startswith("SteeringWheel") and o.data.materials[0] == dark.data.materials[0]]:
    M = sw.matrix_world
    src = bmesh.new()
    src.from_mesh(sw.data)
    suv = src.loops.layers.uv.active
    dst = bmesh.new()
    dst.from_mesh(dark.data)
    duv = dst.loops.layers.uv.active
    Ci = dark.matrix_world.inverted()
    n = 0
    for f in src.faces:  # (corners' order kept: auto_car.py's mirrored frame does not touch it, see bnw_m3_e92_split.py)
        loops = list(f.loops)
        nf = dst.faces.new([dst.verts.new(Ci @ (M @ l.vert.co)) for l in loops])
        nf.smooth = f.smooth
        nf.material_index = 0
        for nl, l in zip(nf.loops, loops):
            nl[duv].uv = l[suv].uv
        n += 1
    dst.to_mesh(dark.data)
    src.free()
    dst.free()
    log.append("stalk bits %s: %d faces into the cabin" % (sw.name, n))
    bpy.data.objects.remove(sw, do_unlink=True)

# ------------------------------------------------------------------ 2. badges (loose chrome pieces) out
chrome = OB["Body_Meshesuchromar1Mtl"]
BADGES = [
    ("boot emblem", (-0.05, 2.40, 0.86, 0.05, 2.42, 0.93), False),
    ("boot letters (both)", (0.40, 2.37, 0.865, 0.61, 2.41, 0.905), True),
    ("grille emblem", (-0.03, -2.09, 0.57, 0.03, -2.06, 0.63), False),
]
kill = []
for f, lo, hi in pieces(chrome):
    for nm, box, ax in BADGES:
        if inside(lo, hi, box, ax):
            kill += list(f)
            log.append("badge %s: %d faces, lo %s hi %s" % (nm, len(f), lo.round(3).tolist(), hi.round(3).tolist()))
delete_faces(chrome, kill)
kill = []
for f, lo, hi in pieces(dark):
    if inside(lo, hi, (-0.03, -2.09, 0.57, 0.03, -2.07, 0.63)):
        kill += list(f)
        log.append("badge grille emblem base (dark): %d faces" % len(f))
delete_faces(dark, kill)
recolour(chrome.data.materials[0], "chrome")


def move_faces(src_o, faces, dst_o):
    """copy those faces of src_o into dst_o (its first material, same world place, UVs kept), then delete them from src_o"""
    faces = set(int(i) for i in faces)
    M = src_o.matrix_world
    Ci = dst_o.matrix_world.inverted()
    src = bmesh.new()
    src.from_mesh(src_o.data)
    suv = src.loops.layers.uv.active
    dst = bmesh.new()
    dst.from_mesh(dst_o.data)
    duv = dst.loops.layers.uv.active
    src.faces.ensure_lookup_table()
    for i in sorted(faces):
        f = src.faces[i]
        loops = list(f.loops)
        nf = dst.faces.new([dst.verts.new(Ci @ (M @ l.vert.co)) for l in loops])
        nf.smooth = f.smooth
        nf.material_index = 0
        if suv is not None and duv is not None:
            for nl, l in zip(nf.loops, loops):
                nl[duv].uv = l[suv].uv
    dst.to_mesh(dst_o.data)
    src.free()
    dst.free()
    delete_faces(src_o, sorted(faces))


paint = OB["Body_Meshesdoor1Mtl"]
strip = []
for f, lo, hi in pieces(paint):
    if inside(lo, hi, (-0.03, -1.995, 0.30, 0.035, -1.935, 0.69)):
        strip += list(f)
        log.append("grille strip (paint -> trim_black): %d faces, lo %s hi %s" % (len(f), lo.round(3).tolist(), hi.round(3).tolist()))
if strip:
    move_faces(paint, strip, dark)

# ------------------------------------------------------------------ 3. the dark material by place
cabin = make_mat("cabin_black", (46, 46, 47))
trim = recolour(dark.data.materials[0], "trim_black", (40, 40, 41))
ldark = make_mat("light_dark", (34, 34, 36))
mirror = make_mat("mirror_glass", (70, 74, 80))
CABIN_BOX = (-0.85, -1.07, 0.14, 0.85, 1.95, 1.335)
HEAD_BOX = (0.29, -2.11, 0.52, 0.87, -1.60, 0.70)  # |x|
TAIL_BOX = (0.38, 2.20, 0.64, 0.79, 2.44, 0.86)  # |x|
MIRROR_BOX = (0.76, -0.53, 0.92, 0.96, -0.43, 1.05)  # |x|
sets = {cabin: [], ldark: [], mirror: []}
for f, lo, hi in pieces(dark):
    if inside(lo, hi, MIRROR_BOX, True):
        sets[mirror] += list(f)
    elif inside(lo, hi, HEAD_BOX, True) or inside(lo, hi, TAIL_BOX, True):
        sets[ldark] += list(f)
    elif inside(lo, hi, CABIN_BOX):
        sets[cabin] += list(f)
assign(dark, sets)
log.append("dark split: cabin %d, lamp insides %d, mirror glass %d, outside trim %d faces" % (len(sets[cabin]), len(sets[ldark]), len(sets[mirror]), len(dark.data.polygons) - sum(len(v) for v in sets.values())))
separate_by_material(dark)

# ------------------------------------------------------------------ 4. the rest: plain names, colours
recolour(OB["Body_Meshesdoor1Mtl"].data.materials[0], "carpaint")
recolour(OB["Body_Meshesinteriorwhite1Mtl"].data.materials[0], "cabin_lining", (68, 68, 70))
recolour(OB["Body_Meshesmeshpart1Mtl"].data.materials[0], "cabin_lamp", (226, 224, 216))
recolour(OB["Body_Meshesred1Mtl"].data.materials[0], "light_reflector_r")
recolour(OB["Body_Mesheswhite1Mtl"].data.materials[0], "light_reflector", (205, 205, 208))
recolour(OB["Body_Exhaust1Mtl"].data.materials[0], "exhausttips")
recolour(OB["Body_Hole1Mtl"].data.materials[0], "exhaust_hole", (12, 12, 12))
recolour(OB["SeeThrough_Mesheslightcovers1Mtl"].data.materials[0], "glass_light")
recolour(OB["SeeThrough_Meshesredtrasnpar1Mtl"].data.materials[0], "red_glass")
recolour(OB["SeeThrough_Meshesuorenhc1Mtl"].data.materials[0], "orange_glass")
recolour(OB["SeeThrough_Mesheswhindowxz1Mtl"].data.materials[0], "window_glass")
recolour(OB["FL_Meshesrim1Mtl"].data.materials[0], "rims1")
# Part2Mtl: the tyres and the black planes closing the engine bay / boot
tyre = make_mat("tyre_rubber", (30, 30, 32))
base = make_mat("base_black", (14, 14, 15))
for o in list(OB):
    if o.type == "MESH" and o.data.materials and o.data.materials[0].name == "Part2Mtl":
        o.data.materials[0] = tyre if o.name[:2] in ("FL", "FR", "RL", "RR") else base
# the wood: one plain material with the dark veneer as its base colour (no alpha, no emission)
wimg = bpy.data.images.load(a[2])
wimg.name = "cabin_wood"
wimg.pack()
wood_obj = OB["Body_Mesheswood1Mtl"]
wood_obj.data.materials[0] = make_mat("cabin_wood", None, wimg)
sw = next(o for o in OB if o.type == "MESH" and o.name.startswith("SteeringWheel"))
sw.data.materials[0].name = "steer_wheel"
for m in list(bpy.data.materials):
    if m.users == 0:
        bpy.data.materials.remove(m)
        continue
    # the export drew most pictures as emission too (the rims, chrome, steering wheel, lamps would glow): base colour only
    b = m.node_tree.nodes.get("Principled BSDF") if m.use_nodes else None
    if b is not None:
        for l in list(b.inputs["Emission Color"].links):
            m.node_tree.links.remove(l)
        b.inputs["Emission Strength"].default_value = 0.0
for i in list(bpy.data.images):
    if i.users == 0:
        bpy.data.images.remove(i)
# object names after their material (finish_car.py renames them by role anyway)
for o in OB:
    if o.type == "MESH" and o.data.materials and not o.name.startswith(("SteeringWheel", "SeeThrough")):
        head = o.name.split("_")[0]
        o.name = head + "_" + o.data.materials[0].name
        o.data.name = o.name
P = world_co(sw)
log.append("wheel %s: %d faces, box middle %s" % (sw.name, len(sw.data.polygons), ((P.min(0) + P.max(0)) / 2).round(4).tolist()))
for l in log:
    print("SPLIT", l)
print("SPLIT objects", sorted((o.name, len(o.data.polygons)) for o in OB if o.type == "MESH"))
bpy.ops.wm.save_as_mainfile(filepath=a[1])
