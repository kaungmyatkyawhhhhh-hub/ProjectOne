# OBJ (per-corner UVs) -> Blender: groups joined, smooth shading with sharp edges split at 40 deg, one atlas material -> FBX
import bpy, bmesh, math, sys
OUT = '/tmp/claude-0/lm/st2'; NAME = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'MB_LM_OceanKing_v1'
GROUP = {'Core': 'Head', 'Cave': 'Head', 'Ear': 'Head', 'Nose': 'Head', 'Brow': 'Head', 'Moustache': 'Head', 'Braid': 'Head', 'Ring': 'Head', 'Gem': 'Head',
         'Spike': 'Head', 'Block': 'Head', 'Rock': 'Rocks', 'Sand': 'Sand', 'CoralF': 'Coral', 'CoralS': 'Coral'}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=OUT + '/model.obj', forward_axis='NEGATIVE_Z', up_axis='Y')
img = bpy.data.images.load(OUT + '/MB_LM_OceanKing_atlas.png')
mt = bpy.data.materials.new('Atlas'); mt.use_nodes = True; tn = mt.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img
mt.node_tree.links.new(tn.outputs['Color'], mt.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
groups = {}
for o in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
    key = o.name.split('_')[0]; flat = key in ('CoralF', 'CoralS', 'Rock', 'Block', 'Gem')
    bm = bmesh.new(); bm.from_mesh(o.data)
    if flat:
        for f in bm.faces: f.smooth = False
    else:
        sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(40)]
        if sharp: bmesh.ops.split_edges(bm, edges=sharp)
        for f in bm.faces: f.smooth = True
    bm.to_mesh(o.data); bm.free()
    o.data.materials.clear(); o.data.materials.append(mt)
    groups.setdefault(GROUP.get(key, 'Head'), []).append(o)
for g, obs in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs: o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    if len(obs) > 1: bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active; o.name = g; o.data.name = g
t = 0
for o in bpy.context.scene.objects:
    if o.type == 'MESH': o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); t += n; print('part', o.name, n)
print('TRIS', t)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=f'{OUT}/{NAME}.fbx', use_selection=True, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, global_scale=1.0,
                         mesh_smooth_type='FACE', add_leaf_bones=False, bake_space_transform=True, path_mode='COPY', embed_textures=True)
