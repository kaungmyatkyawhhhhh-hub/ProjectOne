# textured preview of an OBJ: 4 hero shots + close-ups. usage: python3 viewtex.py -- <obj path> <out jpg> [focus x y z]
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; src, out = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=src, forward_axis='NEGATIVE_Z', up_axis='Y')
obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.view_settings.view_transform = 'Standard'
sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_cavity = False; sh.show_specular_highlight = False; sh.show_backface_culling = True
sh.studio_light = 'paint.sl' if False else sh.studio_light
w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.05, 0.22, 0.42)
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in obs:
    for c in o.bound_box:
        p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
ctr = (mn + mx) / 2; size = mx - mn
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 40; cam.data.clip_end = 9000
foc = Vector((float(a[2]), float(a[3]), float(a[4]))) if len(a) > 4 else ctr
shots = [(ctr, -105, 12, 0.95), (ctr, -55, 24, 0.95), (ctr, 125, 20, 0.95), (ctr, -140, 40, 0.95), (foc, -120, 10, 0.36), (foc, -70, 16, 0.36)]
from PIL import Image
tiles = []
for i, (tg, az, el, k) in enumerate(shots):
    A, E = math.radians(az), math.radians(el); R = max(size) * k
    cam.location = tg + Vector((math.cos(A) * math.cos(E), math.sin(A) * math.cos(E), math.sin(E))) * R
    cam.rotation_euler = (tg - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = 800, 500; sc.render.filepath = out + f'_{i}.png'; bpy.ops.render.render(write_still=True)
    tiles.append(Image.open(out + f'_{i}.png').convert('RGB'))
c = Image.new('RGB', (1600, 1500))
for i, t in enumerate(tiles): c.paste(t, ((i % 2) * 800, (i // 2) * 500))
c.save(out, quality=86)
