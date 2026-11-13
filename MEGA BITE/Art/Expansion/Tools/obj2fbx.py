# a textured OBJ (one material, tex.png beside it) -> FBX with the texture embedded. usage: python3 obj2fbx.py -- <dir> <NAME> [smooth_angle]
import bpy, bmesh, math, sys, shutil
a = sys.argv[sys.argv.index('--') + 1:]; d, NAME = a[0], a[1]; ANG = float(a[2]) if len(a) > 2 else 50
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=d + '/model.obj', forward_axis='NEGATIVE_Z', up_axis='Y')
shutil.copy(d + '/tex.png', d + f'/{NAME}_atlas.png')
img = bpy.data.images.load(d + f'/{NAME}_atlas.png')
mt = bpy.data.materials.new('Atlas'); mt.use_nodes = True; tn = mt.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img
mt.node_tree.links.new(tn.outputs['Color'], mt.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
t = 0
for o in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
    bm = bmesh.new(); bm.from_mesh(o.data)
    sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(ANG)]
    if sharp: bmesh.ops.split_edges(bm, edges=sharp)
    for f in bm.faces: f.smooth = True
    bm.to_mesh(o.data); bm.free()
    o.data.materials.clear(); o.data.materials.append(mt); o.name = a[3] if len(a) > 3 else 'Body'; o.data.name = o.name
    o.data.calc_loop_triangles(); t += len(o.data.loop_triangles)
print('TRIS', t)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=f'{d}/{NAME}.fbx', use_selection=True, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, global_scale=1.0,
                         mesh_smooth_type='FACE', add_leaf_bones=False, bake_space_transform=True, path_mode='COPY', embed_textures=True)
