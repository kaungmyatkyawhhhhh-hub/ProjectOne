import bpy, bmesh
bpy.ops.wm.open_mainfile(filepath="/home/claude/props/sumo/sumo.blend")
for o in bpy.data.objects:
    if o.type != 'MESH': continue
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method='BEAUTY', ngon_method='EAR_CLIP')
    bmesh.ops.dissolve_degenerate(bm, dist=0.0001, edges=bm.edges[:])
    bm.to_mesh(o.data); bm.free(); o.select_set(True)
import os; os.makedirs("/mnt/user-data/outputs/sumo", exist_ok=True)
bpy.ops.export_scene.fbx(filepath="/mnt/user-data/outputs/sumo/SumoArena_v1.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
for o in bpy.data.objects: print("OBJ", o.name, [round(v, 2) for v in o.location], [round(v, 1) for v in o.dimensions])
