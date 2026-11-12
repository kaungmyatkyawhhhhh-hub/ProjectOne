import bpy, bmesh
bpy.ops.wm.open_mainfile(filepath="/home/claude/props/lm2/props3.blend")
for o in bpy.data.objects:
    if o.type != 'MESH': continue
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method='BEAUTY', ngon_method='EAR_CLIP')
    bm.to_mesh(o.data); bm.free()
    o.location = (0, 0, o.dimensions.z / 2)     # each prop at the origin, bottom on z=0 (positions don't matter: one MeshPart per prop)
    o.select_set(True)
bpy.ops.export_scene.fbx(filepath="/mnt/user-data/outputs/lm2/StompProps_v3.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
