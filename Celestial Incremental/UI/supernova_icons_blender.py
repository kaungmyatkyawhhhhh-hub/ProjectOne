import bpy, math, sys, random
from mathutils import Vector
OUT = "/tmp/claude-0/blend/out/"
which = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.samples = 160
    s.cycles.use_denoising = False
    try: s.cycles.denoiser = 'OPENIMAGEDENOISE'
    except: pass
    s.render.resolution_x = s.render.resolution_y = 512
    s.render.film_transparent = True
    s.view_settings.view_transform = 'Filmic' if 'Filmic' in [i.identifier for i in s.view_settings.bl_rna.properties['view_transform'].enum_items] else 'Standard'
    s.view_settings.look = 'None'
    s.render.use_freestyle = False
    w = bpy.data.worlds.new("W"); s.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.03, 0.09, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 0.6
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); s.collection.objects.link(cam); s.camera = cam
    cam.location = (0, -9, 1.2); cam.rotation_euler = (math.radians(83), 0, 0); cam.data.lens = 70
    def light(name, typ, loc, energy, color, size=2):
        l = bpy.data.lights.new(name, typ); l.energy = energy; l.color = color
        if typ == 'AREA': l.size = size
        o = bpy.data.objects.new(name, l); o.location = loc; s.collection.objects.link(o)
        d = Vector((0, 0, 0)) - Vector(loc); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        return o
    light("Key", 'AREA', (-4, -6, 6), 900, (1, 0.93, 0.85), 4)
    light("Rim1", 'AREA', (5, 3, 3), 700, (0.65, 0.45, 1.0), 3)
    light("Rim2", 'AREA', (-5, 3, -2), 400, (1.0, 0.55, 0.25), 3)
    light("Fill", 'AREA', (0, -6, -3), 120, (0.6, 0.7, 1.0), 6)
    # compositor glow
    s.use_nodes = True; nt = s.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    rl = nt.nodes.new('CompositorNodeRLayers'); gl = nt.nodes.new('CompositorNodeGlare'); co = nt.nodes.new('CompositorNodeComposite')
    gl.glare_type = 'FOG_GLOW'; gl.quality = 'HIGH'; gl.threshold = 0.55; gl.size = 8; gl.mix = 0.15
    sa = nt.nodes.new('CompositorNodeSetAlpha')
    nt.links.new(rl.outputs['Image'], gl.inputs['Image']); nt.links.new(gl.outputs['Image'], sa.inputs['Image']); nt.links.new(rl.outputs['Alpha'], sa.inputs['Alpha'])
    nt.links.new(sa.outputs['Image'], co.inputs['Image'])
    return s

def mat(name, base, rough=0.25, metal=0.0, emit=None, estr=0.0, coat=0.6, trans=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*base, 1)
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    for k in ('Coat Weight', 'Clearcoat'):
        if k in b.inputs: b.inputs[k].default_value = coat
    if emit:
        k = 'Emission Color' if 'Emission Color' in b.inputs else 'Emission'
        b.inputs[k].default_value = (*emit, 1)
        if 'Emission Strength' in b.inputs: b.inputs['Emission Strength'].default_value = estr
    if trans:
        k = 'Transmission Weight' if 'Transmission Weight' in b.inputs else 'Transmission'
        b.inputs[k].default_value = trans
    return m

def mesh_obj(name, verts, faces, m):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); o.data.materials.append(m)
    return o

def star4(name, R, r, d, m, loc=(0,0,0), rot=(0,0,0)):
    # 4-point star bipyramid in the XZ plane (faces camera along -Y)
    outline = []
    for i in range(8):
        a = math.pi/2 + i*math.pi/4
        rr = R if i % 2 == 0 else r
        outline.append((math.cos(a)*rr, 0, math.sin(a)*rr))
    verts = outline + [(0, -d, 0), (0, d, 0)]
    faces = []
    for i in range(8):
        j = (i+1) % 8
        faces.append((i, j, 8)); faces.append((j, i, 9))
    o = mesh_obj(name, verts, faces, m); o.location = loc; o.rotation_euler = rot
    return o

def gem(name, h, w, m, loc=(0,0,0), rot=(0,0,0), sides=6):
    verts = []
    for i in range(sides):
        a = i*2*math.pi/sides
        verts.append((math.cos(a)*w, math.sin(a)*w, 0))
    verts += [(0, 0, h*0.62), (0, 0, -h*0.38)]
    faces = []
    for i in range(sides):
        j = (i+1) % sides
        faces.append((i, j, sides)); faces.append((j, i, sides+1))
    o = mesh_obj(name, verts, faces, m); o.location = loc; o.rotation_euler = rot
    return o

def render(name):
    bpy.context.scene.render.filepath = OUT + name + ".png"
    bpy.ops.render.render(write_still=True)

# ---------- icons ----------
def i_stardust():
    reset()
    g = mat("gold", (1.0, 0.68, 0.12), rough=0.18, metal=0.35, emit=(1.0, 0.55, 0.1), estr=0.6)
    o = mat("orange", (1.0, 0.42, 0.08), rough=0.2, metal=0.3, emit=(1.0, 0.35, 0.05), estr=0.5)
    p = mat("pale", (1.0, 0.95, 0.65), rough=0.15, emit=(1.0, 0.85, 0.4), estr=1.2)
    star4("s1", 1.75, 0.5, 0.8, g, (-0.35, 0, 0.1), (math.radians(-10), math.radians(6), math.radians(6)))
    star4("s2", 0.85, 0.26, 0.42, o, (1.15, -0.2, -1.0), (0, 0, math.radians(-12)))
    star4("s3", 0.6, 0.16, 0.22, p, (1.0, -0.3, 1.25), (0, 0, math.radians(20)))
    star4("s4", 0.35, 0.1, 0.12, p, (-1.6, -0.3, 1.3))
    render("stardust")

def i_shard():
    reset()
    pm = mat("purple", (0.45, 0.15, 0.95), rough=0.06, emit=(0.4, 0.1, 1.0), estr=0.6, trans=0.1)
    lm = mat("lilac", (0.85, 0.7, 1.0), rough=0.1, emit=(0.6, 0.4, 1.0), estr=1.0)
    gem("g1", 3.4, 0.85, pm, (0, 0, 0), (math.radians(12), math.radians(-18), math.radians(20)))
    gem("g2", 1.3, 0.35, lm, (1.25, -0.3, -0.9), (math.radians(30), 0, math.radians(-30)))
    gem("g3", 0.9, 0.25, lm, (-1.2, -0.2, 1.0), (math.radians(-20), 0, math.radians(40)))
    gem("g4", 0.55, 0.16, pm, (1.0, -0.4, 1.3), (0, 0, math.radians(10)))
    render("shard")

def i_sun():
    reset()
    core = mat("core", (1.0, 0.62, 0.12), rough=0.3, emit=(1.0, 0.45, 0.05), estr=0.7, coat=0.4)
    spk = mat("spike", (0.95, 0.25, 0.04), rough=0.25, emit=(1.0, 0.2, 0.02), estr=0.35)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.15, location=(0, 0, 0))
    s = bpy.context.object; s.data.materials.append(core)
    for i in range(12):
        a = i*2*math.pi/12
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.36, depth=0.95, location=(math.cos(a)*1.55, 0.2, math.sin(a)*1.55))
        c = bpy.context.object; c.data.materials.append(spk)
        c.rotation_euler = (0, -a + math.pi/2, 0)
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH': o.rotation_euler.rotate_axis('X', math.radians(-12)); o.rotation_euler.rotate_axis('Z', math.radians(14))
    render("sun")

def i_planet():
    reset()
    m = bpy.data.materials.new("pl"); m.use_nodes = True; nt = m.node_tree
    bsdf = nt.nodes['Principled BSDF']; bsdf.inputs['Roughness'].default_value = 0.3
    for k in ('Coat Weight','Clearcoat'):
        if k in bsdf.inputs: bsdf.inputs[k].default_value = 0.6
    tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    cr = nt.nodes.new('ShaderNodeValToRGB'); cr.color_ramp.interpolation = 'CONSTANT'; e = cr.color_ramp.elements
    e[0].position = 0.0; e[0].color = (0.32, 0.14, 0.85, 1)
    e[1].position = 0.62; e[1].color = (0.62, 0.45, 1.0, 1)
    e.new(0.30).color = (0.48, 0.28, 0.95, 1)
    e.new(0.45).color = (0.75, 0.62, 1.0, 1)
    e.new(0.80).color = (0.48, 0.28, 0.95, 1)
    mp = nt.nodes.new('ShaderNodeMapRange'); mp.inputs['From Min'].default_value = -1.3; mp.inputs['From Max'].default_value = 1.3
    nt.links.new(tc.outputs['Object'], sep.inputs[0]); nt.links.new(sep.outputs['Z'], mp.inputs['Value']); nt.links.new(mp.outputs['Result'], cr.inputs['Fac']); nt.links.new(cr.outputs['Color'], bsdf.inputs['Base Color'])
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.3)
    p = bpy.context.object; p.data.materials.append(m)
    p.rotation_euler = (math.radians(18), 0, math.radians(-15))
    rm = mat("ring", (1.0, 0.82, 0.35), rough=0.25, emit=(1.0, 0.7, 0.2), estr=0.3)
    bpy.ops.mesh.primitive_torus_add(major_radius=2.15, minor_radius=0.16, major_segments=14, minor_segments=4)
    r = bpy.context.object; r.scale = (1, 1, 0.5); r.data.materials.append(rm)
    r.rotation_euler = (math.radians(14), math.radians(-16), 0)
    mo = mat("moon", (0.55, 0.9, 1.0), rough=0.3, emit=(0.4, 0.8, 1.0), estr=0.4)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.3, location=(1.75, -0.5, 1.2)); bpy.context.object.data.materials.append(mo)
    render("planet")

def i_comet():
    reset()
    ice = mat("ice", (0.55, 0.85, 1.0), rough=0.12, emit=(0.2, 0.6, 1.0), estr=0.35)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.85, location=(0.9, 0, -0.5))
    c = bpy.context.object; c.data.materials.append(ice)
    random.seed(3)
    for v in c.data.vertices: v.co *= 1 + random.uniform(-0.12, 0.12)
    # tail: 3 stretched emissive cones
    for k, (rad, col, st, off) in enumerate([(0.75, (0.15, 0.55, 1.0), 1.0, 0), (0.48, (0.35, 0.8, 1.0), 1.4, 0.12), (0.28, (0.8, 0.95, 1.0), 2.0, -0.08)]):
        tm = bpy.data.materials.new("tail%d" % k); tm.use_nodes = True; nt = tm.node_tree
        for n in list(nt.nodes): nt.nodes.remove(n)
        out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission'); tr = nt.nodes.new('ShaderNodeBsdfTransparent'); mx = nt.nodes.new('ShaderNodeMixShader')
        gr = nt.nodes.new('ShaderNodeTexGradient'); tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping')
        em.inputs['Color'].default_value = (*col, 1); em.inputs['Strength'].default_value = st
        mp.inputs['Rotation'].default_value = (0, math.radians(90), 0); mp.inputs['Location'].default_value=(0.5,0,0)
        nt.links.new(tc.outputs['Generated'], mp.inputs['Vector']); nt.links.new(mp.outputs['Vector'], gr.inputs['Vector'])
        nt.links.new(gr.outputs['Fac'], mx.inputs['Fac']); nt.links.new(tr.outputs[0], mx.inputs[1]); nt.links.new(em.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], out.inputs[0])
        tm.blend_method = 'BLEND'
        bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=rad, depth=3.6, location=(-0.9, 0.2+k*0.05, 0.55+off))
        t = bpy.context.object; t.data.materials.append(tm); t.rotation_euler = (0, math.radians(-58), 0); bpy.ops.object.shade_smooth()
        t.visible_shadow = False
    render("comet")

def i_forge():
    reset()
    steel = mat("steel", (0.32, 0.34, 0.46), rough=0.22, metal=0.9, coat=0.5)
    hot = mat("hot", (1.0, 0.45, 0.1), rough=0.3, emit=(1.0, 0.4, 0.05), estr=4)
    # anvil from boxes
    def box(loc, scale, m):
        bpy.ops.mesh.primitive_cube_add(location=loc); b = bpy.context.object; b.scale = scale; b.data.materials.append(m)
        bm = b.modifiers.new("b", 'BEVEL'); bm.width = 0.06; bm.segments = 2; return b
    box((0, 0, 0.55), (1.5, 0.55, 0.28), steel)
    box((0, 0, -0.1), (0.55, 0.42, 0.4), steel)
    box((0, 0, -0.7), (1.0, 0.6, 0.18), steel)
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.48, depth=1.2, location=(-1.95, 0, 0.62)); h = bpy.context.object; h.rotation_euler = (0, math.radians(-90), 0); h.scale=(0.6,1,1); h.data.materials.append(steel)
    # glowing star on top
    star4("hs", 1.0, 0.28, 0.35, hot, (0.2, -0.1, 1.6))
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH' and o.name!='hs':
            o.location.rotate(__import__('mathutils').Euler((0,0,math.radians(-32))))
            o.rotation_euler.z += math.radians(-32)
    render("forge")

ALL = {"stardust": i_stardust, "shard": i_shard, "sun": i_sun, "planet": i_planet, "comet": i_comet, "forge": i_forge}

def i_gear():
    reset()
    st = mat("gsteel", (0.75, 0.75, 0.82), rough=0.2, metal=1.0, coat=0.5)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1.2, depth=0.45, rotation=(math.radians(90),0,0)); g = bpy.context.object; g.data.materials.append(st)
    for i in range(10):
        a = i*2*math.pi/10
        bpy.ops.mesh.primitive_cube_add(size=1, location=(math.cos(a)*1.35, 0, math.sin(a)*1.35)); t = bpy.context.object
        t.scale = (0.42, 0.45, 0.42); t.rotation_euler = (0, -a, 0); t.data.materials.append(st)
    hole = mat("hole", (0.05, 0.04, 0.08), rough=0.5)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.45, depth=0.5, location=(0,-0.05,0), rotation=(math.radians(90),0,0)); bpy.context.object.data.materials.append(hole)
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH': o.location.rotate(__import__('mathutils').Euler((math.radians(-20),0,math.radians(25)))); o.rotation_euler.x += math.radians(-20); o.rotation_euler.z += math.radians(25)
    render("gear")
ALL["gear"]=i_gear

for k in (which or ALL.keys()):
    ALL[k]()
