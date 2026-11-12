
import bpy, sys, math
from mathutils import Vector, Euler, Matrix
d = '/tmp/claude-0/chest'
RIM, HINGE_Z = 5.82, -(4.9 - (7.0 - 6.74))
def scene(open_deg):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=d + '/model.obj', forward_axis='NEGATIVE_Z', up_axis='Y')
    obs = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    # OBJ (x, y up, z front) -> Blender (x, -z, y): hinge axis = X through (y_b = -HINGE_Z, z_b = RIM)
    piv = Vector((0, -HINGE_Z, RIM))
    for o in obs:
        if o.name.startswith('Lid') and open_deg:
            M = Matrix.Translation(piv) @ Matrix.Rotation(math.radians(-open_deg), 4, 'X') @ Matrix.Translation(-piv)
            o.matrix_world = M @ o.matrix_world
        if o.name.startswith('Gold') and not open_deg: o.hide_render = True
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'; sc.view_settings.view_transform = 'Standard'
    sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_backface_culling = True; sh.show_specular_highlight = False
    w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.1, 0.3, 0.52)
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
    return sc, cam
ctr = Vector((0, 0, 6))
shots = [(0, -55, 18, 'c0'), (0, -125, 20, 'c1'), (0, 60, 30, 'c2'), (100, -60, 24, 'o0'), (100, -100, 40, 'o1'), (100, 110, 25, 'o2')]
for (od, az, el, name) in shots:
    sc, cam = scene(od)
    a, e = math.radians(az), math.radians(el); R = 44
    cam.location = ctr + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * R
    cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.resolution_x, sc.render.resolution_y = 600, 460; sc.render.filepath = d + '/r_' + name + '.png'; bpy.ops.render.render(write_still=True)
