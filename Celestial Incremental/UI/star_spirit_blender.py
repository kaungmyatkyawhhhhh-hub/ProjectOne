# Galaxy Incremental - the tutorial's STAR SPIRIT portrait (5 Nov, Tutorial 2: "an original character portrait, a small star
# spirit, hand-made in our icon style, Blender render, NOT AI art"). Same look as the icons (supernova_icons_blender.py):
# low-poly faceted, gold, warm key + violet rim, transparent background. 512 px -> UI/roblox/star_spirit.png
# Run: blender -b -P star_spirit_blender.py
import bpy, math, os
from mathutils import Vector
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "roblox", "star_spirit.png")

bpy.ops.wm.read_factory_settings(use_empty=True)
s = bpy.context.scene
s.render.engine = 'CYCLES'
s.cycles.samples = 128
s.render.resolution_x = s.render.resolution_y = 512
s.render.film_transparent = True
try:
    s.view_settings.view_transform = 'Standard'
except Exception:
    pass
w = bpy.data.worlds.new("W"); s.world = w; w.use_nodes = True
w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.03, 0.09, 1)
w.node_tree.nodes['Background'].inputs[1].default_value = 0.5
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); s.collection.objects.link(cam); s.camera = cam
cam.location = (0, -9, 0.4); cam.rotation_euler = (math.radians(88), 0, 0); cam.data.lens = 50

def light(name, typ, loc, energy, color, size=2):
    l = bpy.data.lights.new(name, typ); l.energy = energy; l.color = color
    if typ == 'AREA': l.size = size
    o = bpy.data.objects.new(name, l); o.location = loc; s.collection.objects.link(o)
    d = Vector((0, 0, 0)) - Vector(loc); o.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
light("Key", 'AREA', (-4, -6, 6), 650, (1, 0.93, 0.85), 4)
light("Rim1", 'AREA', (5, 3, 3), 800, (0.65, 0.45, 1.0), 3)
light("Rim2", 'AREA', (-5, 3, -2), 450, (1.0, 0.55, 0.25), 3)
light("Fill", 'AREA', (0, -6, -3), 160, (0.6, 0.7, 1.0), 6)

def mat(name, base, rough=0.25, metal=0.0, emit=None, estr=0.0, coat=0.6):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*base, 1)
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if 'Coat Weight' in b.inputs: b.inputs['Coat Weight'].default_value = coat
    if emit:
        b.inputs['Emission Color'].default_value = (*emit, 1)
        b.inputs['Emission Strength'].default_value = estr
    return m

def mesh_obj(name, verts, faces, m):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.update()
    o = bpy.data.objects.new(name, me); s.collection.objects.link(o); o.data.materials.append(m)
    return o

def star(name, R, r, d, m, loc=(0, 0, 0), rot=(0, 0, 0), points=5):
    # a faceted star bipyramid facing the camera (-Y)
    outline = []
    for i in range(points * 2):
        a = math.pi / 2 + i * math.pi / points
        rr = R if i % 2 == 0 else r
        outline.append((math.cos(a) * rr, 0, math.sin(a) * rr))
    n = len(outline)
    verts = outline + [(0, -d, 0), (0, d, 0)]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n)); faces.append((j, i, n + 1))
    o = mesh_obj(name, verts, faces, m); o.location = loc; o.rotation_euler = rot
    return o

gold = mat("gold", (1.0, 0.55, 0.05), rough=0.22, metal=0.35, emit=(1.0, 0.45, 0.04), estr=0.45)
cheek = mat("cheek", (1.0, 0.45, 0.35), rough=0.4, emit=(1.0, 0.35, 0.3), estr=0.6)
ink = mat("ink", (0.03, 0.02, 0.06), rough=0.08, coat=1.0)
white = mat("white", (1, 1, 1), rough=0.1, emit=(1, 1, 1), estr=3.0)
pale = mat("pale", (1.0, 0.95, 0.7), rough=0.15, emit=(1.0, 0.85, 0.45), estr=1.6)
violet = mat("violet", (0.7, 0.5, 1.0), rough=0.2, metal=0.4, emit=(0.6, 0.4, 1.0), estr=1.2)

# the body: a chubby 5-point star, tilted a little (friendly), with a small 4-point star "tuft" on top
body = star("Body", 2.55, 1.35, 0.95, gold, (0, 0, -0.1), (0, math.radians(-8), 0))
star("Tuft", 0.55, 0.16, 0.2, pale, (0.35, -0.3, 2.75), (0, math.radians(18), 0), points=4)
# the face: two big glossy eyes with highlights, rosy cheeks, a little smile
for x in (-0.62, 0.62):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.36, location=(x, -0.95, 0.35), segments=24, ring_count=12)
    e = bpy.context.object; e.scale = (1, 0.45, 1.25); e.data.materials.append(ink)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.11, location=(x - 0.1, -1.12, 0.55), segments=12, ring_count=8)
    bpy.context.object.data.materials.append(white)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.05, location=(x + 0.1, -1.12, 0.22), segments=10, ring_count=6)
    bpy.context.object.data.materials.append(white)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.2, location=(x * 1.55, -0.92, -0.12), segments=12, ring_count=8)
    c = bpy.context.object; c.scale = (1, 0.3, 0.6); c.data.materials.append(cheek)
bpy.ops.mesh.primitive_torus_add(major_radius=0.3, minor_radius=0.055, location=(0, -0.98, -0.25), rotation=(math.radians(90), 0, 0))
smile = bpy.context.object; smile.data.materials.append(ink)
# cut the torus to a smile: keep only the lower half
bpy.ops.object.mode_set(mode='EDIT')
import bmesh
bm = bmesh.from_edit_mesh(smile.data)
for v in bm.verts:
    if v.co.y < -0.02:  # (the torus is rotated: its local Y is world Z)
        pass
dele = [v for v in bm.verts if v.co.y > 0.0]
bmesh.ops.delete(bm, geom=dele, context='VERTS')
bmesh.update_edit_mesh(smile.data)
bpy.ops.object.mode_set(mode='OBJECT')
# a thin violet halo ring behind, and small sparkles round it
bpy.ops.mesh.primitive_torus_add(major_radius=3.05, minor_radius=0.07, location=(0, 0.8, 0.1), rotation=(math.radians(75), math.radians(-15), 0))
bpy.context.object.data.materials.append(violet)
for (x, z, R) in [(-2.6, 2.1, 0.42), (2.7, 1.7, 0.3), (2.3, -2.2, 0.36), (-2.4, -1.9, 0.22)]:
    star("Sp", R, R * 0.28, R * 0.3, pale, (x, -0.4, z), (0, math.radians(15), 0), points=4)

s.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("saved", OUT)
