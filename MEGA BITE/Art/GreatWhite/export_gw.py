"""Export the Hammerhead for Roblox: one mesh + rig, palette texture (each face UV = its colour cell), FBX;
and sample every clip into a Lua table (bone quaternions + Root translation), same convention as the Reef Shark."""
import bpy, os, json, math
exec(open('greatwhite_v1.py').read())
OUT='/home/claude/megabite_art/gw/export'; os.makedirs(OUT,exist_ok=True)
sh=bpy.data.objects['GreatWhite']; rig=RIGOB
me=sh.data; mats=list(me.materials); n=len(mats); CELL=8
img=bpy.data.images.new('GreatWhite_palette',CELL*n,CELL); px=[]
for y in range(CELL):
    for m in mats:
        c=m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value if m else (1,0,1,1)
        srgb=[((v**(1/2.4))*1.055-0.055) if v>0.0031308 else v*12.92 for v in c[:3]]
        px+= [*srgb,1.0]*CELL
img.pixels=px; img.filepath_raw=OUT+'/GreatWhite_palette.png'; img.file_format='PNG'; img.save()
if not me.uv_layers: me.uv_layers.new(name='UVMap')
if me.uv_layers.active is None: me.uv_layers.active=me.uv_layers[0]
uv=me.uv_layers.active.data
for p in me.polygons:
    u=(p.material_index+0.5)/n
    for li in p.loop_indices: uv[li].uv=(u,0.5)
em=bpy.data.materials.new('GreatWhite_Export'); em.use_nodes=True
t=em.node_tree.nodes.new('ShaderNodeTexImage'); t.image=img; t.interpolation='Closest'
em.node_tree.links.new(t.outputs['Color'],em.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
eye_idx=[i for i,m in enumerate(mats) if m and m.name=='GW_eye'][0]
print('none slots',[i for i,m in enumerate(mats) if m is None], 'faces on them', sum(1 for p in me.polygons if mats[p.material_index] is None))
eyefaces=[p.index for p in me.polygons if p.material_index==eye_idx]
me.materials.clear(); me.materials.append(em)
for p in me.polygons: p.material_index=0
sc=bpy.context.scene
rig.animation_data.action=CLIPS['Swim'][0]; sc.frame_start,sc.frame_end=0,30; sc.render.fps=30
bpy.ops.object.select_all(action='DESELECT'); sh.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=OUT+'/GreatWhite.fbx',use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,
    bake_anim=False,path_mode='COPY',embed_textures=True,apply_unit_scale=True,use_armature_deform_only=False,mesh_smooth_type='FACE')
print('FBX',os.path.getsize(OUT+'/GreatWhite.fbx'),'tris',sum(len(p.vertices)-2 for p in me.polygons))
# ---- clips -> Lua (same axis convention as reef_clips_roblox: q -> {qw,-qx,qy,-qz}, loc -> {-lx,ly,-lz} * K, K applied in Roblox)
bones=[b.name for b in rig.pose.bones]
seg=rig.data.bones['Spine0'].length
out={}
for name,(act,length) in CLIPS.items():
    rig.animation_data.action=act
    keys=[]
    step={'Idle':3,'Swim':2,'Dart':2,'Bite':1,'SharkSense':3,'Hurt':1,'Breach':1}.get(name,2)
    frames=list(range(0,length+1,step))
    if frames[-1]!=length: frames.append(length)
    for fr in frames:
        sc.frame_set(fr)
        pose={}
        for pb in rig.pose.bones:
            m=pb.matrix_basis; q=m.to_quaternion(); l=m.to_translation()
            if abs(q.w-1)<1e-4 and l.length<1e-5: continue
            e=[round(q.w,3),round(-q.x,3),round(q.y,3),round(-q.z,3)]
            if l.length>1e-5: e+= [round(-l.x,4),round(l.y,4),round(-l.z,4)]
            pose[pb.name]=e
        keys.append((round(fr/30,3),pose))
    out[name]=dict(loop=bool(act.get('loop',True)) if name in ('Idle','Swim') else False,keys=keys)
def lua(v):
    if isinstance(v,dict): return '{'+','.join(f'{k}={lua(x)}' for k,x in v.items())+'}'
    if isinstance(v,(list,tuple)): return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,bool): return 'true' if v else 'false'
    if isinstance(v,float):
        r=('%.4f'%v).rstrip('0').rstrip('.')
        return '0' if r in ('-0','') else r
    return repr(v)
src='-- Great White clips (Blender, 30 fps). Root translations are in Blender metres: BonePlayer scales them by BoneScale.\nreturn {SEG='+repr(round(seg,4))+',clips='+lua(out)+'}'
open(OUT+'/GreatWhiteClips.lua','w').write(src)
print('clips lua',len(src))
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/GreatWhite_v1.blend')
