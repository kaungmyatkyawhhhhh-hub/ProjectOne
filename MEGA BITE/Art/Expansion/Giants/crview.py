# creature preview: 6 fixed views of an OBJ (side, 3/4 front, top, front, 3/4 back from below, close head). usage: -- <obj> <out.jpg> [flat]
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; src, out = a[0], a[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=src, forward_axis='NEGATIVE_Z', up_axis='Y')
obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.view_settings.view_transform = 'Standard'
sh = sc.display.shading; sh.light = 'FLAT' if len(a) > 2 and a[2] == 'flat' else 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_cavity = False; sh.show_specular_highlight = False; sh.show_backface_culling = True
w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.03, 0.16, 0.32)
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in obs:
    for p in o.data.polygons: p.use_smooth = True
    for c in o.bound_box:
        p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
ctr = (mn + mx) / 2; size = mx - mn
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.type = 'ORTHO'
head = Vector((mx.x - size.x * 0.14, ctr.y, ctr.z))
shots = [(ctr, -90, 0, 1.08), (ctr, -50, 18, 1.0), (ctr, -90, 89.9, 1.08), (ctr, 0, 0, 0.62), (ctr, -140, -25, 1.0), (head, -62, 8, 0.36)]
from PIL import Image
tiles = []
for i, (tg, az, el, k) in enumerate(shots):
    A, E = math.radians(az), math.radians(el)
    cam.location = tg + Vector((math.cos(A) * math.cos(E), math.sin(A) * math.cos(E), math.sin(E))) * 500
    cam.rotation_euler = (tg - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.ortho_scale = max(size) * k
    sc.render.resolution_x, sc.render.resolution_y = 800, 480; sc.render.filepath = out + f'_{i}.png'; bpy.ops.render.render(write_still=True)
    tiles.append(Image.open(out + f'_{i}.png').convert('RGB'))
c = Image.new('RGB', (1600, 1440))
for i, t in enumerate(tiles): c.paste(t, ((i % 2) * 800, (i // 2) * 480))
c.save(out, quality=86)
