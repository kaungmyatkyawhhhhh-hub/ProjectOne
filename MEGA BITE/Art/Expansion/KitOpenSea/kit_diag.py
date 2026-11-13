# diagnostic views of one kit prop: front faces by texture-free normal colour, back faces magenta
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; src, name, out = a[0], a[1], a[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=src, forward_axis='NEGATIVE_Z', up_axis='Y')
o = [q for q in bpy.context.scene.objects if q.type == 'MESH' and name in q.name][0]
for q in list(bpy.context.scene.objects):
    if q is not o: bpy.data.objects.remove(q)
m = bpy.data.materials.new('d'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
outn = nt.nodes.new('ShaderNodeOutputMaterial'); mix = nt.nodes.new('ShaderNodeMixShader'); geo = nt.nodes.new('ShaderNodeNewGeometry')
e1 = nt.nodes.new('ShaderNodeEmission'); e2 = nt.nodes.new('ShaderNodeEmission'); e2.inputs[0].default_value = (1, 0, 1, 1)
tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = bpy.data.images.load(a[3])
nt.links.new(tex.outputs[0], e1.inputs[0])
nt.links.new(geo.outputs['Backfacing'], mix.inputs[0]); nt.links.new(e1.outputs[0], mix.inputs[1]); nt.links.new(e2.outputs[0], mix.inputs[2]); nt.links.new(mix.outputs[0], outn.inputs[0])
o.data.materials.clear(); o.data.materials.append(m)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 4; sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.02, 0.02, 0.02, 1)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.type = 'ORTHO'
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for c in o.bound_box:
    p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
ctr = (mn + mx) / 2; size = mx - mn
from PIL import Image
tiles = []
for (A, E) in [(-78, 20), (-30, 10), (20, 35), (90, 20), (160, 5), (-110, -15), (-78, 70), (-150, 30)]:
    A, E = math.radians(A), math.radians(E)
    cam.location = ctr + Vector((math.cos(A) * math.cos(E), math.sin(A) * math.cos(E), math.sin(E))) * 200
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.ortho_scale = max(size) * 1.3
    sc.render.resolution_x, sc.render.resolution_y = 384, 384; sc.render.filepath = out + '_t.png'; bpy.ops.render.render(write_still=True)
    tiles.append(Image.open(out + '_t.png').convert('RGB'))
c = Image.new('RGB', (384 * 4, 768))
for i, t in enumerate(tiles): c.paste(t, ((i % 4) * 384, (i // 4) * 384))
c.save(out, quality=88)
