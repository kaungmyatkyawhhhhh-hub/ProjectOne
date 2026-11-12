import bpy, math, sys
from mathutils import Vector
blend = sys.argv[sys.argv.index("--") + 1]; out = sys.argv[sys.argv.index("--") + 2]; suffix = sys.argv[sys.argv.index("--") + 3]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
img = bpy.data.images.load("/home/claude/props/out/props_palette.png")
mat = bpy.data.materials.new("pal"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]; t = nt.nodes.new("ShaderNodeTexImage"); t.image = img; t.interpolation = 'Closest'
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
objs = sorted([o for o in bpy.data.objects if o.type == 'MESH' and o.name.endswith(suffix)], key=lambda o: o.name)
for o in bpy.data.objects: o.hide_render = o not in objs
for o in objs: o.data.materials.clear(); o.data.materials.append(mat)
x = 0
for o in objs:
    o.location = (x + o.dimensions.x / 2, 0, o.dimensions.z / 2); x += o.dimensions.x + 12
sc.render.engine = 'BLENDER_WORKBENCH'; sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_shadows = True; sh.show_cavity = True; sh.cavity_type = 'BOTH'; sh.show_object_outline = True
sc.render.resolution_x, sc.render.resolution_y = 1800, 700
sc.view_settings.view_transform = 'Standard'
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = 'ORTHO'; cam.data.clip_end = 5000
H = max(o.dimensions.z for o in objs)
cam.data.ortho_scale = max(x, H * 2.6) * 1.02
ctr = Vector((x / 2, 0, H * 0.45))
d = Vector((0.6, -1, 0.55)).normalized()
cam.location = ctr + d * 1500; cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
sc.render.filepath = out; bpy.ops.render.render(write_still=True)
