# ortho renders (material colours) of a hand-built OBJ in the sheet's 3 views pasted into the sheet layout + 3 heroes + backface check
import bpy, sys, math
from mathutils import Vector, Euler
argv = sys.argv[sys.argv.index('--') + 1:]; d = argv[0]; TOPROT = len(argv) > 1 and argv[1] == 'yx'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=d + '/model.obj', forward_axis='NEGATIVE_Z', up_axis='Y')
obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
sc.view_settings.view_transform = 'Standard'
sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'MATERIAL'; sh.show_backface_culling = True
sh.show_specular_highlight = False
if 'tex' in argv: sh.color_type = 'TEXTURE'
for o in obs:
    for m in o.data.materials:
        if m and m.use_nodes:
            bsdf = m.node_tree.nodes.get('Principled BSDF')
            if bsdf: m.diffuse_color = bsdf.inputs['Base Color'].default_value
sc.render.film_transparent = True
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in obs:
    for c in o.bound_box:
        p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
ctr = (mn + mx) / 2; size = mx - mn
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.type = 'ORTHO'
def shot2(loc, rot, w_, h_, path, res=900):
    cam.location = ctr + Vector(loc) * (max(size) * 3); cam.rotation_euler = Euler(rot)
    asp = w_ / h_
    if asp >= 1: sc.render.resolution_x, sc.render.resolution_y = res, max(16, int(res / asp))
    else: sc.render.resolution_x, sc.render.resolution_y = max(16, int(res * asp)), res
    cam.data.ortho_scale = max(w_, h_); sc.render.filepath = path; bpy.ops.render.render(write_still=True)
shot2((0, -1, 0), (math.pi / 2, 0, 0), size.x, size.z, d + '/o_side.png')
shot2((0, 0, 1), (0, 0, math.pi / 2) if TOPROT else (0, 0, 0), size.y if TOPROT else size.x, size.x if TOPROT else size.y, d + '/o_top.png')
shot2((1, 0, 0), (math.pi / 2, 0, math.pi / 2), size.y, size.z, d + '/o_front.png')
sc.render.film_transparent = False; w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.1, 0.3, 0.52)
cam.data.type = 'PERSP'; cam.data.lens = 50
for i, (az, el) in enumerate(((-45, 12), (-135, 22), (20, 8))):
    a, e = math.radians(az), math.radians(el); R = max(size) * 1.45
    cam.location = ctr + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * R
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = 900, 600; sc.render.filepath = d + f'/hero_{i}.png'; bpy.ops.render.render(write_still=True)
sc.render.film_transparent = True; sh.color_type = 'SINGLE'; sh.single_color = (0.85, 0.85, 0.85)
sc.render.resolution_x, sc.render.resolution_y = 300, 220
for i, (az, el) in enumerate(((0, 0), (90, 0), (180, 0), (270, 0), (0, 89), (0, -89))):
    a, e = math.radians(az), math.radians(el); R = max(size) * 2.0
    cam.location = ctr + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * R
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    for cull in (True, False):
        sh.show_backface_culling = cull; sc.render.filepath = d + f'/bf_{i}_{int(cull)}.png'; bpy.ops.render.render(write_still=True)
