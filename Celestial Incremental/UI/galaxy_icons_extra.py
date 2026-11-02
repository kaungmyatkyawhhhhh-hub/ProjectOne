# Galaxy Incremental - extra icons for the friends test (2 Nov), same look as supernova_icons_blender.py (faceted low-poly +
# clearcoat shine, warm key + violet / orange rim lights, transparent 512 px): asteroid, moon, gas giant, essence, lock.
# Run: blender -b --python galaxy_icons_extra.py -- <out dir> [names...]
import bpy, math, sys, random, os
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = (args[0] if args else os.path.join(os.path.dirname(__file__), "..", "Icons", "rendered")) + os.sep
which = args[1:]


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.samples = 160
    s.cycles.use_denoising = True
    s.render.resolution_x = s.render.resolution_y = 512
    s.render.film_transparent = True
    names = [i.identifier for i in s.view_settings.bl_rna.properties['view_transform'].enum_items]
    s.view_settings.view_transform = 'Filmic' if 'Filmic' in names else ('AgX' if 'AgX' in names else 'Standard')
    w = bpy.data.worlds.new("W"); s.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.03, 0.09, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 0.6
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); s.collection.objects.link(cam); s.camera = cam
    cam.location = (0, -9, 1.2); cam.rotation_euler = (math.radians(83), 0, 0); cam.data.lens = 70

    def light(name, loc, energy, color, size):
        l = bpy.data.lights.new(name, 'AREA'); l.energy = energy; l.color = color; l.size = size
        o = bpy.data.objects.new(name, l); o.location = loc; s.collection.objects.link(o)
        o.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    light("Key", (-4, -6, 6), 900, (1, 0.93, 0.85), 4)
    light("Rim1", (5, 3, 3), 700, (0.65, 0.45, 1.0), 3)
    light("Rim2", (-5, 3, -2), 400, (1.0, 0.55, 0.25), 3)
    light("Fill", (0, -6, -3), 120, (0.6, 0.7, 1.0), 6)
    return s


def mat(name, base, rough=0.25, metal=0.0, emit=None, estr=0.0, coat=0.6):
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
    return m


def banded(name, colours, positions, axis_scale=1.3):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    bsdf = nt.nodes['Principled BSDF']; bsdf.inputs['Roughness'].default_value = 0.3
    for k in ('Coat Weight', 'Clearcoat'):
        if k in bsdf.inputs: bsdf.inputs[k].default_value = 0.6
    tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    cr = nt.nodes.new('ShaderNodeValToRGB'); cr.color_ramp.interpolation = 'CONSTANT'; e = cr.color_ramp.elements
    e[0].position = 0.0; e[0].color = (*colours[0], 1)
    e[1].position = positions[-1]; e[1].color = (*colours[-1], 1)
    for p, c in zip(positions[1:-1], colours[1:-1]):
        e.new(p).color = (*c, 1)
    mp = nt.nodes.new('ShaderNodeMapRange'); mp.inputs['From Min'].default_value = -axis_scale; mp.inputs['From Max'].default_value = axis_scale
    nt.links.new(tc.outputs['Object'], sep.inputs[0]); nt.links.new(sep.outputs['Z'], mp.inputs['Value'])
    nt.links.new(mp.outputs['Result'], cr.inputs['Fac']); nt.links.new(cr.outputs['Color'], bsdf.inputs['Base Color'])
    return m


def rock(radius, loc, m, seed, sub=1, jitter=0.18):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=radius, location=loc)
    o = bpy.context.object; o.data.materials.append(m)
    random.seed(seed)
    for v in o.data.vertices: v.co *= 1 + random.uniform(-jitter, jitter)
    return o


def render(name):
    bpy.context.scene.render.filepath = OUT + "icon_" + name + ".png"
    bpy.ops.render.render(write_still=True)


def i_asteroid():
    reset()
    m = mat("rock", (0.46, 0.4, 0.48), rough=0.45, coat=0.4)
    m2 = mat("rock2", (0.62, 0.52, 0.5), rough=0.4, coat=0.4)
    a = rock(1.45, (0, 0, 0), m, 4, 1, 0.22); a.scale = (1.15, 1, 0.85); a.rotation_euler = (0.3, 0.2, 0.5)
    rock(0.55, (1.65, -0.4, 1.05), m2, 7, 1, 0.2)
    rock(0.32, (-1.75, -0.3, -1.0), m2, 9, 1, 0.2)
    render("asteroid")


def i_moon():
    reset()
    m = mat("moon", (0.78, 0.82, 0.9), rough=0.35, emit=(0.5, 0.65, 1.0), estr=0.08, coat=0.5)
    cr = mat("crater", (0.52, 0.56, 0.68), rough=0.5, coat=0.3)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.5)
    s = bpy.context.object; s.data.materials.append(m); s.rotation_euler = (0.2, 0.3, 0.1)
    for (x, z, r) in ((-0.55, 0.55, 0.42), (0.6, -0.35, 0.32), (0.15, 0.95, 0.22), (-0.3, -0.75, 0.25)):
        y = -math.sqrt(max(1.5 ** 2 - x * x - z * z, 0)) + 0.12
        bpy.ops.mesh.primitive_cylinder_add(vertices=7, radius=r, depth=0.08, location=(x, y, z))
        c = bpy.context.object; c.data.materials.append(cr)
        c.rotation_euler = (Vector((x, y, z)).normalized()).to_track_quat('Z', 'Y').to_euler()
    render("moon")


def i_gasgiant():
    reset()
    m = banded("gas", [(0.85, 0.38, 0.12), (1.0, 0.7, 0.35), (0.95, 0.52, 0.2), (1.0, 0.86, 0.6), (0.85, 0.38, 0.12)],
               [0.0, 0.3, 0.45, 0.62, 0.8], 1.6)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.62)
    p = bpy.context.object; p.data.materials.append(m); p.rotation_euler = (math.radians(14), 0, math.radians(-12))
    spot = mat("spot", (0.75, 0.25, 0.1), rough=0.3)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.28, location=(0.55, -1.42, -0.3))
    o = bpy.context.object; o.scale = (1.4, 0.5, 0.8); o.data.materials.append(spot)
    render("gasgiant")


def i_essence():
    reset()
    teal = mat("teal", (0.15, 0.85, 0.8), rough=0.08, emit=(0.1, 0.9, 0.8), estr=0.7, coat=0.8)
    core = mat("core", (1.0, 0.95, 0.7), rough=0.1, emit=(1.0, 0.9, 0.55), estr=3.0)
    # an octahedron gem (Star Essence) with a glowing star in front
    verts = [(0, 0, 1.9), (0, 0, -1.9), (1.15, 0, 0), (-1.15, 0, 0), (0, 1.15, 0), (0, -1.15, 0)]
    faces = [(0, 2, 4), (0, 4, 3), (0, 3, 5), (0, 5, 2), (1, 4, 2), (1, 3, 4), (1, 5, 3), (1, 2, 5)]
    me = bpy.data.meshes.new("gem"); me.from_pydata(verts, [], faces); me.update()
    g = bpy.data.objects.new("gem", me); bpy.context.scene.collection.objects.link(g); g.data.materials.append(teal)
    g.rotation_euler = (math.radians(8), 0, math.radians(30))
    # 4-point star
    outline = []
    for i in range(8):
        a = math.pi / 2 + i * math.pi / 4
        rr = 0.75 if i % 2 == 0 else 0.22
        outline.append((math.cos(a) * rr, 0, math.sin(a) * rr))
    sv = outline + [(0, -0.28, 0), (0, 0.28, 0)]
    sf = []
    for i in range(8):
        j = (i + 1) % 8
        sf += [(i, j, 8), (j, i, 9)]
    me2 = bpy.data.meshes.new("st"); me2.from_pydata(sv, [], sf); me2.update()
    s = bpy.data.objects.new("st", me2); bpy.context.scene.collection.objects.link(s); s.data.materials.append(core)
    s.location = (0, -1.2, 0.1)
    render("essence")


def i_lock():
    reset()
    steel = mat("steel", (0.7, 0.7, 0.78), rough=0.22, metal=0.9, coat=0.5)
    dark = mat("hole", (0.05, 0.04, 0.08), rough=0.5)
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, -0.45)); b = bpy.context.object; b.scale = (1.15, 0.45, 0.95)
    b.data.materials.append(steel)
    bv = b.modifiers.new("b", 'BEVEL'); bv.width = 0.12; bv.segments = 1
    bpy.ops.mesh.primitive_torus_add(major_radius=0.72, minor_radius=0.2, major_segments=12, minor_segments=6, location=(0, 0, 0.55))
    t = bpy.context.object; t.rotation_euler = (math.radians(90), 0, 0); t.data.materials.append(steel)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.18, depth=0.2, location=(0, -0.5, -0.35), rotation=(math.radians(90), 0, 0))
    bpy.context.object.data.materials.append(dark)
    for o in list(bpy.context.scene.objects):
        if o.type == 'MESH':
            o.location.rotate(__import__('mathutils').Euler((0, 0, math.radians(-18))))
            o.rotation_euler.z += math.radians(-18)
    render("lock")


ALL = {"asteroid": i_asteroid, "moon": i_moon, "gasgiant": i_gasgiant, "essence": i_essence, "lock": i_lock}
for k in (which or ALL.keys()):
    ALL[k]()
