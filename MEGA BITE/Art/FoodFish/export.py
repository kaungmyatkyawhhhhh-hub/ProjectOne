import bpy, sys, os
SP=sys.argv[1]; OUT=f'/home/claude/megabite_fish/out/{SP}'
bpy.ops.wm.open_mainfile(filepath=f'{OUT}/{SP}.blend')
ob=bpy.data.objects[SP]; rig=bpy.data.objects[SP+'Rig']
img=bpy.data.images[f'{SP}_atlas']; img.filepath=f'{OUT}/{SP}_atlas.png'
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
fbx=f'{OUT}/MB_Fish_{SP}.fbx'
bpy.ops.export_scene.fbx(filepath=fbx,use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,
    bake_anim=False,path_mode='COPY',embed_textures=True,apply_unit_scale=True,use_armature_deform_only=False,mesh_smooth_type='FACE')
print('FBX',SP,os.path.getsize(fbx))
