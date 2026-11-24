# GYM ARC icon render (25 Nov): shared helpers, copied from thumbs_nov/_tools/build_scene.py (4 Nov) with a tanned skin.
import bpy, bmesh, math, random
from mathutils import Matrix, Vector
BASE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Assets"
OBJDIR = BASE + r"\icon_render_25nov"
TEX = BASE + r"\icon_render_25nov\_tools\faces"
scene = bpy.context.scene
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
    m = principled(name, srgb("#B86E3A"), 0.36, 0.0, **{"Subsurface Weight": 0.18, "Subsurface Scale": 0.04, "Coat Weight": 0.15, "Coat Roughness": 0.25, "Specular IOR Level": 0.55})
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
        mix.inputs["A"].default_value = (*srgb("#B86E3A"), 1); mix.inputs["B"].default_value = (*srgb("#A05A3A"), 1)
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
    mix.inputs["A"].default_value = b.inputs["Base Color"].default_value if dark else (*srgb("#B86E3A"), 1)
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
