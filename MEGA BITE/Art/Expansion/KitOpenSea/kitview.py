import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; src, out = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=src, forward_axis='NEGATIVE_Z', up_axis='Y')
obs = sorted([o for o in bpy.context.scene.objects if o.type == 'MESH'], key=lambda o: sum((o.matrix_world @ Vector(c)).x for c in o.bound_box))
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.view_settings.view_transform = 'Standard'
sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'TEXTURE'; sh.show_backface_culling = True
w = bpy.data.worlds.new('w'); sc.world = w; w.color = (1.0, 0.0, 1.0)
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.type = 'ORTHO'
from PIL import Image
tiles = []
for o in obs:
    for q in obs: q.hide_render = q is not o
    mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
    for c in o.bound_box:
        p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
    ctr = (mn + mx) / 2; size = mx - mn
    A, E = math.radians(-78), math.radians(20)
    cam.location = ctr + Vector((math.cos(A) * math.cos(E), math.sin(A) * math.cos(E), math.sin(E))) * 200
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.ortho_scale = max(size) * 1.35
    sc.render.resolution_x, sc.render.resolution_y = 384, 384; sc.render.filepath = out + '_t.png'; bpy.ops.render.render(write_still=True)
    tiles.append(Image.open(out + '_t.png').convert('RGB'))
    print(o.name, [round(v, 1) for v in size], len(o.data.polygons))
c = Image.new('RGB', (384 * 4, 768))
for i, t in enumerate(tiles): c.paste(t, ((i % 4) * 384, (i // 4) * 384))
c.save(out, quality=88)
