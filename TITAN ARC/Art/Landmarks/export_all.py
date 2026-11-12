import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
names = ["playground", "school", "mall", "crane", "ship", "twintowers", "stadium", "crowntower"]
for n in names:
    with bpy.data.libraries.load("/home/claude/props/lm2/%s.blend" % n) as (src, dst):
        dst.objects = [o for o in src.objects]
    for o in dst.objects:
        if o and o.type == 'MESH': bpy.context.scene.collection.objects.link(o)
tot = 0
for o in bpy.data.objects:
    o.data.calc_loop_triangles(); tot += len(o.data.loop_triangles)
    o.select_set(True)
print("objects", len(bpy.data.objects), "tris", tot)
bpy.ops.export_scene.fbx(filepath="/mnt/user-data/outputs/lm2/StompLandmarks_v2.fbx", use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE', axis_forward='-Z', axis_up='Y', path_mode='STRIP', add_leaf_bones=False)
for o in bpy.data.objects: print(o.name, [round(v, 2) for v in o.location], [round(v, 1) for v in o.dimensions])
