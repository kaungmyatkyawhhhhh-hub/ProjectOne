# Galaxy Incremental - store art (3 Nov): the x2 STARDUST game pass icon and the ALPHA PLAYER badge, same look as
# galaxy_icons_extra.py / supernova_icons_blender.py (faceted low-poly + clearcoat shine, warm key + violet / orange rim
# lights, transparent 512 px). No text. Roblox shows both round, so everything stays inside the centre circle.
# Run: blender -b --python galaxy_store_art.py -- <out dir> [pass|badge]
import bpy, math, sys, os
from mathutils import Vector, Euler

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = (args[0] if args else os.path.join(os.path.expanduser("~"), "Downloads", "galaxy_store_art")) + os.sep
which = args[1:]


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.samples = 200
    s.cycles.use_denoising = True
    s.render.resolution_x = s.render.resolution_y = 512
    s.render.film_transparent = True
    names = [i.identifier for i in s.view_settings.bl_rna.properties['view_transform'].enum_items]
    s.view_settings.view_transform = 'Filmic' if 'Filmic' in names else ('AgX' if 'AgX' in names else 'Standard')
    w = bpy.data.worlds.new("W"); s.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.03, 0.09, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 0.6
    # (looking straight along +Y so the centre of the picture is the world centre: the round crop stays centred)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); s.collection.objects.link(cam); s.camera = cam
    cam.location = (0, -9, 0); cam.rotation_euler = (math.radians(90), 0, 0); cam.data.lens = 70

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


def star4(name, R, r, d, m, loc=(0, 0, 0), rot=(0, 0, 0)):
    # the game's 4-point star (a bipyramid in the XZ plane, facing the camera)
    outline = []
    for i in range(8):
        a = math.pi / 2 + i * math.pi / 4
        rr = R if i % 2 == 0 else r
        outline.append((math.cos(a) * rr, 0, math.sin(a) * rr))
    verts = outline + [(0, -d, 0), (0, d, 0)]
    faces = []
    for i in range(8):
        j = (i + 1) % 8
        faces += [(i, j, 8), (j, i, 9)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o); o.data.materials.append(m)
    o.location = loc; o.rotation_euler = rot
    return o


def render(name):
    bpy.context.scene.render.filepath = OUT + name + ".png"
    bpy.ops.render.render(write_still=True)


def a_pass():
    # x2 STARDUST pass: one bold glowing gold star with its twin behind it (the "x2", without text)
    reset()
    gold = mat("gold", (1.0, 0.68, 0.12), rough=0.18, metal=0.35, emit=(1.0, 0.55, 0.1), estr=0.8)
    orange = mat("orange", (1.0, 0.42, 0.08), rough=0.2, metal=0.3, emit=(1.0, 0.35, 0.05), estr=0.6)
    star4("twin", 1.05, 0.31, 0.5, orange, (0.95, 0.8, 0.85), (math.radians(-8), math.radians(5), math.radians(-8)))
    star4("main", 1.6, 0.47, 0.78, gold, (-0.25, 0, -0.22), (math.radians(-10), math.radians(6), math.radians(6)))
    render("pass_x2_stardust")


def a_badge():
    # ALPHA PLAYER badge: a round gold medal (fits Roblox's circle) with a violet face, the 4-point star and its glow,
    # three small sparkles; tilted a little so the facets catch the light
    reset()
    gold = mat("gold", (1.0, 0.72, 0.22), rough=0.18, metal=0.85, emit=(1.0, 0.6, 0.15), estr=0.25, coat=0.6)
    face = mat("face", (0.3, 0.14, 0.6), rough=0.3, emit=(0.25, 0.1, 0.55), estr=0.15, coat=0.7)
    starm = mat("star", (1.0, 0.68, 0.12), rough=0.18, metal=0.35, emit=(1.0, 0.55, 0.1), estr=0.8)
    core = mat("core", (1.0, 0.97, 0.8), rough=0.1, emit=(1.0, 0.9, 0.55), estr=3.0)
    pale = mat("pale", (1.0, 0.95, 0.65), rough=0.15, emit=(1.0, 0.85, 0.4), estr=1.6)
    parts = []
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.82, depth=0.3, location=(0, 0.05, 0), rotation=(math.radians(90), 0, 0))
    o = bpy.context.object; o.data.materials.append(face); parts.append(o)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.82, minor_radius=0.2, major_segments=16, minor_segments=6, location=(0, 0, 0),
                                     rotation=(math.radians(90), 0, 0))
    o = bpy.context.object; o.data.materials.append(gold); parts.append(o)
    # an inner gold ring
    bpy.ops.mesh.primitive_torus_add(major_radius=1.42, minor_radius=0.06, major_segments=16, minor_segments=4, location=(0, -0.12, 0),
                                     rotation=(math.radians(90), 0, 0))
    o = bpy.context.object; o.data.materials.append(gold); parts.append(o)
    parts.append(star4("star", 1.15, 0.32, 0.42, starm, (0, -0.3, 0)))
    parts.append(star4("core", 0.45, 0.13, 0.22, core, (0, -0.62, 0)))
    for (x, z, r) in ((0.78, 0.72, 0.2), (-0.8, -0.62, 0.16), (-0.72, 0.78, 0.12)):
        parts.append(star4("sp", r, r * 0.28, r * 0.35, pale, (x, -0.3, z)))
    for p in parts:
        p.location.rotate(Euler((math.radians(-6), 0, math.radians(-12))))
        p.rotation_euler.x += math.radians(-6)
        p.rotation_euler.z += math.radians(-12)
    render("badge_alpha_player")


ALL = {"pass": a_pass, "badge": a_badge}
os.makedirs(OUT, exist_ok=True)
for k in (which or ALL.keys()):
    ALL[k]()
