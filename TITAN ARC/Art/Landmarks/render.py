import bpy, math, sys
from mathutils import Vector
blend = sys.argv[sys.argv.index("--") + 1]; out = sys.argv[sys.argv.index("--") + 2]
bpy.ops.wm.open_mainfile(filepath=blend)
sc = bpy.context.scene
img = bpy.data.images.load("/home/claude/props/out/props_palette.png")
mat = bpy.data.materials.new("pal"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]; t = nt.nodes.new("ShaderNodeTexImage"); t.image = img; t.interpolation = 'Closest'
nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
objs = [o for o in bpy.data.objects if o.type == 'MESH']
for o in objs: o.data.materials.clear(); o.data.materials.append(mat)
sc.render.engine = 'BLENDER_WORKBENCH'; sh = sc.display.shading; sh.light = "FLAT" if False else "STUDIO"; sh.studio_light = "outdoor.sl" if "outdoor.sl" in [l.name for l in bpy.context.preferences.studio_lights] else sh.studio_light; sh.color_type = 'TEXTURE'; sh.show_shadows = True; sh.show_cavity = True; sh.cavity_type = 'BOTH'; sh.show_object_outline = True; sh.object_outline_color = (0.1, 0.1, 0.15)
sc.render.resolution_x, sc.render.resolution_y = 1536, 1024
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (1, 0, 1, 1)
sc.view_settings.view_transform = 'Standard'
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in objs:
    for c in o.bound_box:
        v = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, v)); mx = Vector(map(max, mx, v))
ctr = (mn + mx) / 2; size = mx - mn; H = size.z; Wd = max(size.x, size.y)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"; cam.data.clip_end = 5000; cam.data.clip_start = 0.1
views = {"front": (Vector((0, -1, 0)), 0), "side": (Vector((1, 0, 0)), 0), "hero": (Vector((0.75, -1, 0.75)).normalized(), 1), "top": (Vector((0, 0, 1)), 2)}
for name, (d, kind) in views.items():
    cam.data.ortho_scale = max(H * 1.5, Wd) * 1.12
    cam.location = ctr + d * 1000
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = out + "_" + name + ".png"; bpy.ops.render.render(write_still=True)
