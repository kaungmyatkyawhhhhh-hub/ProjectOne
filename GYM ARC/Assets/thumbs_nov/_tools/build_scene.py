# GYM ARC thumbnails (4 Nov): builds Thumbs_Nov.blend (ONE new scene "Thumbs_Nov", a new file: no other .blend is opened).
# Run: blender -b --factory-startup -P build_scene.py -- <objdir> <texdir> <brandpng> <out.blend>
import bpy, bmesh, math, random, sys
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OBJDIR, TEX, BRAND, OUT = argv[0], argv[1], argv[2], argv[3]
random.seed(7)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = "Thumbs_Nov"

# Roblox (x, y, z) -> Blender (x, -z, y); a Roblox CFrame -> a Blender matrix (objects built Z-up, front = +Y)
M3 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
def conv(x, y, z): return Vector((x, -z, y))
def cf_matrix(c):
    p = conv(c[0], c[1], c[2])
    R = Matrix(((c[3], c[4], c[5]), (c[6], c[7], c[8]), (c[9], c[10], c[11])))
    Rb = M3 @ R @ M3.transposed()
    m = Rb.to_4x4(); m.translation = p
    return m

def collection(name, parent=None):
    c = bpy.data.collections.new(name)
    (parent or scene.collection).children.link(c)
    return c

def link(obj, col):
    for c in obj.users_collection: c.objects.unlink(obj)
    col.objects.link(obj)

# ---------------------------------------------------------------- materials
def principled(name, color, rough=0.5, metal=0.0, **kw):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    for k, v in kw.items():
        b.inputs[k].default_value = v
    return m

def srgb(h):
    h = h.lstrip("#"); r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b))

def skin_material(name, veins=False):
    m = principled(name, srgb("#D9996A"), 0.36, 0.0, **{"Subsurface Weight": 0.18, "Subsurface Scale": 0.04, "Coat Weight": 0.35, "Coat Roughness": 0.18, "Specular IOR Level": 0.55})
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Subsurface Radius"].default_value = (1.0, 0.45, 0.25)
    nt = m.node_tree
    if veins:
        # thin raised veins: a narrow band of a stretched noise (squiggly lines), darker and a bit red
        tc = nt.nodes.new("ShaderNodeTexCoord")
        mp = nt.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1.0, 1.0, 0.45)
        nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
        nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 1.5; nz.inputs["Detail"].default_value = 3.0
        nz.inputs["Distortion"].default_value = 0.4
        nt.links.new(mp.outputs["Vector"], nz.inputs["Vector"])
        ramp = nt.nodes.new("ShaderNodeValToRGB"); el = ramp.color_ramp.elements
        el[0].position = 0.493; el[0].color = (0, 0, 0, 1); el[1].position = 0.5; el[1].color = (1, 1, 1, 1)
        e3 = el.new(0.507); e3.color = (0, 0, 0, 1)
        nt.links.new(nz.outputs["Fac"], ramp.inputs["Fac"])
        bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.25; bump.inputs["Distance"].default_value = 0.012
        nt.links.new(ramp.outputs["Color"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.inputs["Factor"].default_value = 0.0
        mix.inputs["A"].default_value = (*srgb("#D9996A"), 1); mix.inputs["B"].default_value = (*srgb("#B06A50"), 1)
        fac = nt.nodes.new("ShaderNodeMath"); fac.operation = "MULTIPLY"; fac.inputs[1].default_value = 0.35
        nt.links.new(ramp.outputs["Color"], fac.inputs[0]); nt.links.new(fac.outputs[0], mix.inputs["Factor"])
        nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    return m

MAT = {
    "skin": skin_material("Skin"),
    "skin_veins": skin_material("SkinVeins", True),
    "top": principled("TankTop", srgb("#E9E9E6"), 0.82, 0, **{"Sheen Weight": 0.5}),
    "shorts": principled("Shorts", srgb("#151519"), 0.7, 0, **{"Sheen Weight": 0.35}),
    "shadow": principled("Silhouette", srgb("#08080C"), 0.32, 0.0, **{"Coat Weight": 0.4, "Coat Roughness": 0.15, "Specular IOR Level": 0.7}),
    "hair": principled("Hair", srgb("#6A3416"), 0.45, 0, **{"Sheen Weight": 0.4, "Coat Weight": 0.2}),
    "hair_shadow": principled("HairShadow", srgb("#0B0A0E"), 0.4, 0),
}

def face_material(name, face, base_mat_color, glow_strength, dark=False):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    if dark:
        b.inputs["Base Color"].default_value = (*srgb("#08080C"), 1); b.inputs["Roughness"].default_value = 0.32
        b.inputs["Coat Weight"].default_value = 0.4
    else:
        b.inputs["Roughness"].default_value = 0.36; b.inputs["Subsurface Weight"].default_value = 0.18
        b.inputs["Subsurface Scale"].default_value = 0.04; b.inputs["Coat Weight"].default_value = 0.35
    return m, nt, b

def head_face_material(name, face, head_w, head_h, glow, dark=False):
    m, nt, b = face_material(name, face, None, glow, dark)
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
    # u = 0.5 - x / w (the viewer's right is -X), v = 0.5 + z / h
    mu = nt.nodes.new("ShaderNodeMath"); mu.operation = "MULTIPLY_ADD"; mu.inputs[1].default_value = -1.0 / head_w; mu.inputs[2].default_value = 0.5
    mv = nt.nodes.new("ShaderNodeMath"); mv.operation = "MULTIPLY_ADD"; mv.inputs[1].default_value = 1.0 / head_h; mv.inputs[2].default_value = 0.5
    nt.links.new(sep.outputs["X"], mu.inputs[0]); nt.links.new(sep.outputs["Z"], mv.inputs[0])
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    nt.links.new(mu.outputs[0], comb.inputs["X"]); nt.links.new(mv.outputs[0], comb.inputs["Y"])
    img = nt.nodes.new("ShaderNodeTexImage"); img.image = bpy.data.images.load(f"{TEX}/{face}.png"); img.extension = "CLIP"
    gim = nt.nodes.new("ShaderNodeTexImage"); gim.image = bpy.data.images.load(f"{TEX}/{face}_glow.png"); gim.extension = "CLIP"
    nt.links.new(comb.outputs[0], img.inputs["Vector"]); nt.links.new(comb.outputs[0], gim.inputs["Vector"])
    front = nt.nodes.new("ShaderNodeMath"); front.operation = "GREATER_THAN"; front.inputs[1].default_value = 0.0
    nt.links.new(sep.outputs["Y"], front.inputs[0])
    a = nt.nodes.new("ShaderNodeMath"); a.operation = "MULTIPLY"
    nt.links.new(img.outputs["Alpha"], a.inputs[0]); nt.links.new(front.outputs[0], a.inputs[1])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    mix.inputs["A"].default_value = b.inputs["Base Color"].default_value if dark else (*srgb("#D9996A"), 1)
    nt.links.new(a.outputs[0], mix.inputs["Factor"]); nt.links.new(img.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    gm = nt.nodes.new("ShaderNodeMix"); gm.data_type = "RGBA"; gm.inputs["A"].default_value = (0, 0, 0, 1)
    nt.links.new(front.outputs[0], gm.inputs["Factor"]); nt.links.new(gim.outputs["Color"], gm.inputs["B"])
    nt.links.new(gm.outputs["Result"], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = glow
    return m

def emission(name, color, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    e = nt.nodes.new("ShaderNodeEmission"); e.inputs["Color"].default_value = (*color, 1); e.inputs["Strength"].default_value = strength
    o = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(e.outputs[0], o.inputs[0])
    return m

# ---------------------------------------------------------------- OBJ (our export) + marks
def read_obj(path):
    objs, verts, marks = [], [], []
    cur = None
    with open(path) as f:
        for line in f:
            if line.startswith("v "):
                _, x, y, z = line.split(); verts.append(conv(float(x), float(y), float(z)))
            elif line.startswith("f "):
                cur["faces"].append(tuple(int(i) - 1 for i in line.split()[1:4]))
            elif line.startswith("o "):
                cur = {"name": line[2:].strip(), "faces": []}; objs.append(cur)
            elif line.startswith("# MARK"):
                head, comps = line[7:].split("|")
                p = head.split()
                marks.append({"name": p[0], "shape": p[1], "size": (float(p[2]), float(p[3]), float(p[4])), "color": p[5],
                              "cf": [float(v) for v in comps.split()]})
    return objs, verts, marks

def make_mesh(name, verts, faces, col):
    used = sorted({i for f in faces for i in f}); remap = {g: i for i, g in enumerate(used)}
    me = bpy.data.meshes.new(name)
    me.from_pydata([verts[g] for g in used], [], [tuple(remap[i] for i in f) for f in faces]); me.update()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0008)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = True
    ob = bpy.data.objects.new(name, me); col.objects.link(ob)
    return ob

def rounded_box(name, size, bevel, col):
    bpy.ops.mesh.primitive_cube_add(size=1)
    ob = bpy.context.active_object; ob.name = name
    ob.scale = size; bpy.ops.object.transform_apply(scale=True)
    md = ob.modifiers.new("Bevel", "BEVEL"); md.width = bevel; md.segments = 5; md.limit_method = "NONE"
    bpy.ops.object.modifier_apply(modifier="Bevel")
    bpy.ops.object.shade_smooth()
    link(ob, col); return ob

def roblox_head(name, w, h, col):
    bpy.ops.mesh.primitive_cylinder_add(vertices=72, radius=w / 2, depth=h)
    ob = bpy.context.active_object; ob.name = name
    md = ob.modifiers.new("Bevel", "BEVEL"); md.width = h * 0.26; md.segments = 10; md.limit_method = "ANGLE"
    bpy.ops.object.modifier_apply(modifier="Bevel")
    bpy.ops.object.shade_smooth()
    link(ob, col); return ob

def bacon_hair(name, w, h, col, mat):
    # our own swept "bacon" hair: a cap over the top / back, a thick fringe swept to the viewer's left
    parts = []
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1)
    cap = bpy.context.active_object
    cap.scale = (w * 0.56, w * 0.58, h * 0.52); cap.location = (0, -w * 0.05, h * 0.16)
    bpy.ops.object.transform_apply(location=True, scale=True)
    bm = bmesh.new(); bm.from_mesh(cap.data)
    kill = [v for v in bm.verts if (v.co.z < -h * 0.05) or (v.co.y > w * 0.12 and v.co.z < h * 0.24)]
    bmesh.ops.delete(bm, geom=kill, context="VERTS"); bm.to_mesh(cap.data); bm.free()
    md = cap.modifiers.new("Solid", "SOLIDIFY"); md.thickness = w * 0.06
    parts.append(cap)
    # fringe locks: flattened, curved cones across the forehead
    for i in range(6):
        t = i / 5
        bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=w * 0.13, radius2=0.0, depth=w * (0.62 - 0.12 * t))
        lock = bpy.context.active_object
        lock.scale = (1.0, 0.45, 1.0)
        x = w * (0.34 - 0.62 * t)
        lock.location = (x, w * 0.43, h * (0.30 - 0.02 * t))
        lock.rotation_euler = (math.radians(-12), math.radians(-62 - 10 * t), math.radians(6))
        parts.append(lock)
    # side tufts over the ears
    for s in (-1, 1):
        bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=w * 0.12, radius2=0, depth=h * 0.42)
        tuft = bpy.context.active_object; tuft.scale = (0.5, 1, 1)
        tuft.location = (s * w * 0.5, w * 0.08, h * 0.08); tuft.rotation_euler = (0, math.radians(180 + s * 8), 0)
        parts.append(tuft)
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = cap
    for p in parts:
        for md in list(p.modifiers):
            bpy.context.view_layer.objects.active = p; bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts: p.select_set(True)
    bpy.context.view_layer.objects.active = cap
    bpy.ops.object.join()
    ob = bpy.context.active_object; ob.name = name
    sub = ob.modifiers.new("Sub", "SUBSURF"); sub.levels = 1; sub.render_levels = 2
    tex = bpy.data.textures.new(name + "_clumps", "CLOUDS"); tex.noise_scale = 0.18
    dis = ob.modifiers.new("Clumps", "DISPLACE"); dis.texture = tex; dis.strength = w * 0.05
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(mat)
    link(ob, col); return ob

# ---------------------------------------------------------------- a character from our export
def load_character(file, col, face, face_glow=4.0, dark=False, veins=False):
    objs, verts, marks = read_obj(f"{OBJDIR}/{file}.obj")
    root = bpy.data.objects.new(file + "_ROOT", None); col.objects.link(root)
    pieces = []
    for o in objs:
        name, kind, _hex = (o["name"].split("__") + ["", ""])[:3]
        ob = make_mesh(name, verts, o["faces"], col)
        if dark: mat = MAT["shadow"]
        elif kind == "top": mat = MAT["top"]
        elif kind == "shorts": mat = MAT["shorts"]
        else: mat = MAT["skin_veins" if veins else "skin"]
        ob.data.materials.append(mat); pieces.append(ob)
    head = None
    for mk in marks:
        nm, sx, sy, sz = mk["name"], *mk["size"]
        if nm == "Head":
            head = roblox_head(file + "_Head", sx, sy, col)
            head.data.materials.append(head_face_material(file + "_Face", face, sx, sy, face_glow, dark))
            head.matrix_world = cf_matrix(mk["cf"])
            hair = bacon_hair(file + "_Hair", sx, sy, col, MAT["hair_shadow" if dark else "hair"])
            hair.matrix_world = cf_matrix(mk["cf"]); pieces += [head, hair]
        elif nm.endswith("Hand") or nm.endswith("Foot"):
            ob = rounded_box(file + "_" + nm, (sx, sz, sy), min(sx, sy, sz) * 0.22, col)
            ob.data.materials.append(MAT["shadow"] if dark else MAT["skin_veins" if veins else "skin"])
            ob.matrix_world = cf_matrix(mk["cf"]); pieces.append(ob)
        elif mk["shape"] == "Ball":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=sx / 2)
            ob = bpy.context.active_object; ob.name = file + "_" + nm; bpy.ops.object.shade_smooth(); link(ob, col)
            ob.data.materials.append(MAT["shadow"] if dark else MAT["skin"])
            ob.matrix_world = cf_matrix(mk["cf"]); pieces.append(ob)
    return root, pieces, marks

def parent_all(root, pieces, origin_roblox):
    o = conv(*origin_roblox)
    for p in pieces:
        mw = p.matrix_world.copy(); mw.translation -= o
        p.parent = root; p.matrix_world = mw

# ---------------------------------------------------------------- the gym (dark): rubber floor, brick back wall, racks
def build_gym(col):
    bpy.ops.mesh.primitive_plane_add(size=80); floor = bpy.context.active_object; floor.name = "GymFloor"; link(floor, col)
    fm = bpy.data.materials.new("RubberFloor"); fm.use_nodes = True; nt = fm.node_tree; b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = 0.55
    tc = nt.nodes.new("ShaderNodeTexCoord"); br = nt.nodes.new("ShaderNodeTexBrick")
    br.inputs["Scale"].default_value = 0.25; br.inputs["Color1"].default_value = (*srgb("#18181B"), 1); br.inputs["Color2"].default_value = (*srgb("#1E1E22"), 1)
    br.inputs["Mortar"].default_value = (*srgb("#0C0C0E"), 1); br.inputs["Mortar Size"].default_value = 0.01; br.offset = 0.0
    nt.links.new(tc.outputs["Object"], br.inputs["Vector"]); nt.links.new(br.outputs["Color"], b.inputs["Base Color"])
    floor.data.materials.append(fm)
    bpy.ops.mesh.primitive_plane_add(size=1); wall = bpy.context.active_object; wall.name = "BrickWall"
    wall.scale = (60, 24, 1); wall.rotation_euler = (math.radians(90), 0, 0); wall.location = (0, -14, 12); link(wall, col)
    wm = bpy.data.materials.new("Brick"); wm.use_nodes = True; nt = wm.node_tree; b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = 0.85
    tc = nt.nodes.new("ShaderNodeTexCoord"); br = nt.nodes.new("ShaderNodeTexBrick")
    br.inputs["Scale"].default_value = 1.4; br.inputs["Color1"].default_value = (*srgb("#4A1C14"), 1); br.inputs["Color2"].default_value = (*srgb("#35140F"), 1)
    br.inputs["Mortar"].default_value = (*srgb("#141010"), 1); br.inputs["Mortar Size"].default_value = 0.03
    nt.links.new(tc.outputs["Generated"], br.inputs["Vector"]); nt.links.new(br.outputs["Color"], b.inputs["Base Color"])
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.4
    nt.links.new(br.outputs["Fac"], bump.inputs["Height"]); nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    wall.data.materials.append(wm)
    # dumbbell racks along the wall (dark steel, silhouettes in the blur)
    steel = principled("RackSteel", srgb("#1A1B1F"), 0.35, 0.9)
    bell = principled("BellIron", srgb("#0E0E10"), 0.4, 0.6)
    for s in (-1, 1):
        for k in range(2):
            x = s * (6.5 + k * 6)
            bpy.ops.mesh.primitive_cube_add(size=1); r = bpy.context.active_object; r.scale = (5, 1.4, 0.2); r.location = (x, -12.5, 2.4); link(r, col); r.data.materials.append(steel)
            for j in range(7):
                bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.28, depth=0.9)
                d = bpy.context.active_object; d.rotation_euler = (0, math.radians(90), 0); d.location = (x - 2.1 + j * 0.7, -12.3, 2.75); link(d, col); d.data.materials.append(bell)
    # warm hanging lamps (far, small hot spots) and a faint red neon strip like the starter gym
    lamp = emission("LampGlow", srgb("#FFB070"), 3)
    for x in (-9, 0, 9):
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.9, depth=0.1); l = bpy.context.active_object; l.name = 'GymLamp'; l.location = (x, -9, 13.5); link(l, col); l.data.materials.append(lamp)
    neon = emission("RedNeon", srgb("#FF2A3A"), 12)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.06, depth=22); n = bpy.context.active_object
    n.rotation_euler = (0, math.radians(90), 0); n.location = (0, -13.8, 7.2); link(n, col); n.data.materials.append(neon)

# ---------------------------------------------------------------- M WEIGHTS crystal plates
def crystal_plate(name, x, R, T, kind, col, brand=False):
    diamond = kind == "diamond"
    body = principled(name + "_Crystal", srgb("#DDF4FF" if diamond else "#C0102A"), 0.04, 0.0,
                      **{"Transmission Weight": 1.0, "IOR": 2.1 if diamond else 1.76})
    core = emission(name + "_Core", srgb("#8FDDFF" if diamond else "#FF2440"), 26 if diamond else 18)
    rim = principled(name + "_Rim", srgb("#E5E4E2" if diamond else "#3A4048"), 0.18 if diamond else 0.28, 1.0)
    hubm = principled(name + "_Hub", srgb("#C9CED6"), 0.15, 1.0)
    objs = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=R - 0.05, depth=T * 0.86); c = bpy.context.active_object
    md = c.modifiers.new("Bevel", "BEVEL"); md.width = T * 0.25; md.segments = 4; bpy.ops.object.modifier_apply(modifier="Bevel")
    c.data.materials.append(body); objs.append(c)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=R * 0.62, depth=T * 0.4); k = bpy.context.active_object
    k.data.materials.append(core); objs.append(k)
    bpy.ops.mesh.primitive_torus_add(major_radius=R - 0.05, minor_radius=T * 0.5, major_segments=96, minor_segments=16); r = bpy.context.active_object
    r.data.materials.append(rim); objs.append(r)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.26, depth=T * 1.15); h = bpy.context.active_object
    h.data.materials.append(hubm); objs.append(h)
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o; bpy.ops.object.shade_smooth()
        o.rotation_euler = (0, math.radians(90), 0); o.location = (x, 0, 0); link(o, col)
    if brand:
        bpy.ops.mesh.primitive_plane_add(size=1); p = bpy.context.active_object
        p.scale = (R * 1.1, R * 0.275, 1); p.rotation_euler = (math.radians(90), 0, math.radians(90 if x > 0 else -90))
        p.location = (x + (T * 0.47 + 0.004) * (1 if x > 0 else -1), 0, R * 0.62); link(p, col)
        bm_ = bpy.data.materials.new(name + "_Brand"); bm_.use_nodes = True
        nt = bm_.node_tree; b = nt.nodes["Principled BSDF"]
        im = nt.nodes.new("ShaderNodeTexImage"); im.image = bpy.data.images.load(BRAND)
        nt.links.new(im.outputs["Color"], b.inputs["Base Color"]); nt.links.new(im.outputs["Alpha"], b.inputs["Alpha"])
        nt.links.new(im.outputs["Color"], b.inputs["Emission Color"]); b.inputs["Emission Strength"].default_value = 1.5
        p.data.materials.append(bm_); objs.append(p)
    L = bpy.data.lights.new(name + "_Light", "POINT"); L.energy = 420 if diamond else 220; L.shadow_soft_size = R * 0.5
    L.color = (0.72, 0.9, 1.0) if diamond else (1.0, 0.16, 0.22)
    lo = bpy.data.objects.new(name + "_Light", L); lo.location = (x * 1.0, 0.0, 0); col.objects.link(lo); objs.append(lo)
    return objs

def build_barbell(col, length, plate_layout):
    steel = principled("BarSteel", srgb("#D6DAE0"), 0.22, 1.0)
    objs = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.085, depth=length); bar = bpy.context.active_object
    bar.rotation_euler = (0, math.radians(90), 0); link(bar, col); bar.data.materials.append(steel); objs.append(bar)
    for s in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.15, depth=2.2); sl = bpy.context.active_object
        sl.rotation_euler = (0, math.radians(90), 0); sl.location = (s * (length / 2 - 1.1), 0, 0); link(sl, col); sl.data.materials.append(steel); objs.append(sl)
        x = s * 2.75
        for i, (kind, R, T) in enumerate(plate_layout[0 if s < 0 else 1]):
            x_mid = x + s * T / 2
            objs += crystal_plate(f"Plate_{'R' if s > 0 else 'L'}{i}", x_mid, R, T, kind, col, brand=(i == len(plate_layout[0]) - 1))
            x += s * (T + 0.05)
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.24, depth=0.18); cl = bpy.context.active_object
        cl.rotation_euler = (0, math.radians(90), 0); cl.location = (x + s * 0.09, 0, 0); link(cl, col); cl.data.materials.append(steel); objs.append(cl)
    return objs

# ---------------------------------------------------------------- build
GYM = collection("GYM")
build_gym(GYM)

# shot A (icon + thumb 2): the bacon in front, the giant (flex) behind as a dark silhouette
A = collection("SHOT_A_icon_thumb2")
bacon_root, bacon_pieces, _ = load_character("BACON_4ft", A, "face_bacon_smirk", face_glow=6.0)
parent_all(bacon_root, bacon_pieces, (0, 5000.0, 0))
flex_root, flex_pieces, _ = load_character("GIANT_7ft_flex", A, "face_glow_eyes", face_glow=30.0, dark=True)
parent_all(flex_root, flex_pieces, (34, 5000.0, 0))
flex_root.location = (0, -6.0, 0); flex_root.scale = (1.45, 1.45, 1.45)
# the small dumbbell in the bacon's right hand (gem heads)
dbc = collection("Dumbbell", A)
hand = bpy.data.objects.get("BACON_4ft_RightHand")
gemp = principled("GemPurple", srgb("#8E3BFF"), 0.05, 0, **{"Transmission Weight": 0.85, "IOR": 1.7, "Emission Color": (*srgb("#9B4DFF"), 1), "Emission Strength": 3.0})
handle_m = principled("DBHandle", srgb("#C9CED6"), 0.2, 1.0)
db_root = bpy.data.objects.new("Dumbbell_ROOT", None); dbc.objects.link(db_root)
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.07, depth=1.0); hd = bpy.context.active_object; link(hd, dbc); hd.data.materials.append(handle_m)
hd.rotation_euler = (0, math.radians(90), 0); hd.parent = db_root
for s in (-1, 1):
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.26, depth=0.32); hx = bpy.context.active_object; link(hx, dbc); hx.data.materials.append(gemp)
    md = hx.modifiers.new("Bevel", "BEVEL"); md.width = 0.04; md.segments = 3
    hx.rotation_euler = (0, math.radians(90), 0); hx.location = (s * 0.5, 0, 0); hx.parent = db_root
if hand:
    db_root.matrix_world = hand.matrix_world @ Matrix.Translation((0, 0, -0.1))
db_root.parent = bacon_root; db_root.matrix_parent_inverse = bacon_root.matrix_world.inverted()

# sparks / debris (small glowing specks, purple / teal / white)
sp = collection("Sparks", A)
cols = [srgb("#B04CFF"), srgb("#28F0D7"), (1, 1, 1)]
spark_mats = [emission(f"Spark{i}", c, 30) for i, c in enumerate(cols)]
for i in range(110):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=random.uniform(0.012, 0.03))
    s = bpy.context.active_object; link(s, sp)
    s.location = (random.uniform(-7, 7), random.uniform(-5, 4), random.uniform(0.3, 9))
    s.scale = (1, 1, random.uniform(1.5, 4)); s.rotation_euler = (random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), 0)
    s.data.materials.append(random.choice(spark_mats))

def area(name, col, loc, target, color, power, size):
    L = bpy.data.lights.new(name, "AREA"); L.energy = power; L.color = color; L.size = size
    o = bpy.data.objects.new(name, L); o.location = loc; col.objects.link(o)
    d = Vector(target) - Vector(loc); o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return o

LA = collection("LIGHTS_A", A)
area("A_KeyPurpleL", LA, (-6, 1.5, 5), (0, 0, 3), srgb("#A848FF"), 700, 3)
area("A_KeyTealR", LA, (6, 1.5, 5), (0, 0, 3), srgb("#22E8D2"), 700, 3)
area("A_FaceFill", LA, (0.8, 6, 4.6), (0, 0, 3.8), (1.0, 0.82, 0.68), 420, 2.5)
area("A_RimPurpleL", LA, (-6, -11, 8), (0, -6, 7), srgb("#B04CFF"), 14000, 5)
area("A_RimTealR", LA, (6, -11, 8), (0, -6, 7), srgb("#28F0D7"), 14000, 5)

# shot B (thumb 1): the giant with the barbell, Diamond + Ruby plates
B = collection("SHOT_B_thumb1")
g_root, g_pieces, g_marks = load_character("GIANT_7ft", B, "face_giant_strain", face_glow=0.0, veins=True)
parent_all(g_root, g_pieces, (20, 5000.0, 0))
bar = next(m for m in g_marks if m["name"] == "BARBELL")
bc = conv(bar["cf"][0] - 20, bar["cf"][1] - 5000.0, bar["cf"][2])
barc = collection("Barbell", B)
bar_root = bpy.data.objects.new("Barbell_ROOT", None); barc.objects.link(bar_root)
for o in build_barbell(barc, 9.8, ([("diamond", 2.0, 0.25)] * 4, [("ruby", 2.0, 0.25)] * 4)):
    if o.parent is None: o.parent = bar_root
bar_root.location = bc
LB = collection("LIGHTS_B", B)
area("B_Fill", LB, (2, 6, 5), (0, 0, 6.2), (1.0, 0.86, 0.78), 260, 2.5)
area("B_WallBlue", LB, (-8, -6, 1), (-6, -14, 6), srgb("#5FB8FF"), 1800, 6)
area("B_WallRed", LB, (8, -6, 1), (6, -14, 6), srgb("#FF2A40"), 1800, 6)
area("B_RimL", LB, (-6, -8, 8), (0, 0, 5), srgb("#FF3048"), 2200, 5)
area("B_RimR", LB, (6, -8, 8), (0, 0, 5), srgb("#7FD8FF"), 2200, 5)

# world: almost black, a little blue
w = bpy.data.worlds.new("Dark"); scene.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.004, 0.005, 0.009, 1)
w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0

# cameras
def camera(name, loc, target, lens, sensor=36, fstop=2.8, focus=None):
    cd = bpy.data.cameras.new(name); cd.lens = lens; cd.sensor_width = sensor
    cd.dof.use_dof = True; cd.dof.aperture_fstop = fstop
    o = bpy.data.objects.new(name, cd); o.location = loc; scene.collection.objects.link(o)
    d = Vector(target) - Vector(loc); o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cd.dof.focus_distance = (Vector(focus or target) - Vector(loc)).length
    return o
camera("CAM_icon", (0.15, 3.9, 3.45), (0.0, 0.0, 4.6), 50, fstop=4.0, focus=(0, 0.3, 3.9))
camera("CAM_thumb2", (0.8, 6.6, 1.0), (0.0, -2.0, 5.2), 22, fstop=2.0, focus=(0, 0.3, 3.2))
camera("CAM_thumb1", (0.7, 5.0, 3.9), (0.15, 0, 6.3), 18, fstop=3.2, focus=(0.2, 0.2, 6.2))

# render
scene.render.engine = "CYCLES"
scene.cycles.samples = 128
scene.cycles.use_denoising = True
scene.cycles.transmission_bounces = 12
scene.cycles.max_bounces = 12
scene.view_settings.view_transform = "AgX"
try:
    scene.view_settings.look = "AgX - Punchy"
except Exception as e:
    print("look:", e)
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "OPTIX"; prefs.get_devices()
    for d in prefs.devices: d.use = True
    scene.cycles.device = "GPU"
except Exception as e:
    print("GPU setup:", e)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("BUILT", OUT)
