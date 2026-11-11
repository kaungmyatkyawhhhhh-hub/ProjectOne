"""Build the Tap-style Minnow in Blender from out/minnow_tap_geo.json + out/MB_Minnow_tap_tex.png: smooth shading, inverted-hull
outline, Minnow v1 rig (Root + Spine0..7), FBX for Roblox (same export settings as Minnow v1), check renders."""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector
OUT=os.path.abspath('out'); D=json.load(open('out/minnow_tap_geo.json'))
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
me=bpy.data.meshes.new('Minnow'); ob=bpy.data.objects.new('Minnow',me); sc.collection.objects.link(ob)
bm=bmesh.new()
vs=[bm.verts.new(v) for v in D['V']]; bm.verts.ensure_lookup_table()
uvl=bm.loops.layers.uv.new('UVMap')
part=bm.faces.layers.int.new('part'); PK={'body':0,'eye':1,'fin':2}
for f,uv,k in zip(D['F'],D['UV'],D['K']):
    try: face=bm.faces.new([vs[i] for i in f])
    except ValueError: continue
    face[part]=PK[k]
    for l,u in zip(face.loops,uv): l[uvl].uv=u
# weld the fin rims (top/bottom shells share their edge points) and the body poles
fin_verts=list({v for f in bm.faces if f[part]==2 for v in f.verts})
bmesh.ops.remove_doubles(bm,verts=fin_verts,dist=1e-5)
for f in bm.faces: f.smooth=True
# orient every face outward: body/eyes/mouth away from the body's centre line; fins (closed pillows) by Blender's recalc
import numpy as _np
Gz=json.load(open('out/axis.json'))
def zc_at(x): return float(_np.interp(x,Gz['x'],Gz['zc']))
bm.normal_update()
for f in bm.faces:
    if f[part]==2: continue
    c=f.calc_center_median(); ref=Vector((c.x,0,zc_at(c.x)))
    if c.x>-0.02 or c.x<Gz['x'][0]: ref=Vector((-1.9,0,zc_at(-1.9)))
    if f.normal.dot(c-ref)<0: f.normal_flip()
fins=[f for f in bm.faces if f[part]==2]
bmesh.ops.recalc_face_normals(bm,faces=fins)
bm.to_mesh(me); bm.free()
img=bpy.data.images.load(OUT+'/MB_Minnow_tap_tex.png')
mat=bpy.data.materials.new('Minnow_Tap'); mat.use_nodes=True
nt=mat.node_tree; bsdf=nt.nodes['Principled BSDF']; tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=img
nt.links.new(tx.outputs['Color'],bsdf.inputs['Base Color']); bsdf.inputs['Roughness'].default_value=0.55
mat.use_backface_culling=True   # Roblox draws one side only: needed for the inverted-hull outline
me.materials.append(mat)
# ---------------- inverted hull outline (dark), same weights later
OUTW=0.024
bm=bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table(); uvl=bm.loops.layers.uv.active; part=bm.faces.layers.int['part']
bm.normal_update()
src_faces=[f for f in bm.faces if f[part]!=1]           # eyes carry their own drawn rim
vmap={}
for f in src_faces:
    for v in f.verts:
        if v not in vmap: vmap[v]=bm.verts.new(v.co+v.normal*OUTW)
for f in src_faces:
    nf=bm.faces.new([vmap[v] for v in reversed(f.verts)]); nf.smooth=True; nf[part]=3
    for l in nf.loops: l[uvl].uv=(0.53,0.97)
bm.to_mesh(me); bm.free()
tris=sum(len(p.vertices)-2 for p in me.polygons); print('tris',tris)
# ---------------- rig: identical to Minnow v1
arm=bpy.data.armatures.new('MinnowRig'); rig=bpy.data.objects.new('MinnowRig',arm); sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig; bpy.ops.object.mode_set(mode='EDIT')
x0,x1,NB=-0.10439,-3.32234,8
xs=[x0-i*(x0-x1)/NB for i in range(NB+1)]
rb=arm.edit_bones.new('Root'); rb.head=(0,0,0); rb.tail=(0.4,0,0); prev=rb
for i in range(NB):
    b=arm.edit_bones.new(f'Spine{i}'); b.head=(xs[i],0,0); b.tail=(xs[i+1],0,0); b.parent=prev; b.use_connect=i>0; prev=b
bpy.ops.object.mode_set(mode='OBJECT')
ob.parent=rig; mod=ob.modifiers.new('Armature','ARMATURE'); mod.object=rig
seg=(xs[0]-xs[-1])/NB
groups=[ob.vertex_groups.new(name=f'Spine{i}') for i in range(NB)]
for v in me.vertices:
    u=(xs[0]-v.co.x)/seg-0.5
    ws=sorted(((math.exp(-((u-k)/0.75)**2),k) for k in range(NB)),reverse=True)[:3]
    tot=sum(w for w,_ in ws)
    for w,k in ws: groups[k].add([v.index],w/tot,'REPLACE')
print('SEG',arm.bones['Spine0'].length)
# ---------------- export (same as Minnow v1)
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=OUT+'/Minnow_tap_v1.fbx',use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,
    bake_anim=False,path_mode='COPY',embed_textures=True,apply_unit_scale=True,use_armature_deform_only=False,mesh_smooth_type='FACE')
print('fbx',os.path.getsize(OUT+'/Minnow_tap_v1.fbx'))
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/Minnow_tap_v1.blend')
# ---------------- check renders (Eevee): side / top / front ortho on magenta + a 3/4 hero
w=bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(1,0,1,1); w.node_tree.nodes['Background'].inputs[1].default_value=0.0
sc.render.engine='BLENDER_WORKBENCH'
sh_=sc.display.shading; sh_.light='STUDIO'; sh_.color_type='TEXTURE'; sh_.show_backface_culling=True; sh_.show_shadows=False; sh_.show_specular_highlight=True; sh_.show_cavity=False
sc.render.film_transparent=True; sc.render.resolution_x=768; sc.render.resolution_y=512
sc.view_settings.view_transform='Standard'
for nm,rot,en in [('Key',(math.radians(50),math.radians(10),math.radians(30)),3.2),('Fill',(math.radians(60),0,math.radians(200)),1.2),('Top',(0,0,0),1.0)]:
    l=bpy.data.lights.new(nm,'SUN'); l.energy=en; lo=bpy.data.objects.new(nm,l); lo.rotation_euler=rot; sc.collection.objects.link(lo)
cam=bpy.data.cameras.new('C'); co=bpy.data.objects.new('C',cam); sc.collection.objects.link(co); sc.camera=co
cx=-1.7
views={'side':((cx,-12,0),(math.radians(90),0,0),'ORTHO',3.85),'top':((cx,0,12),(0,0,0),'ORTHO',3.85),
       'front':((12,0,0),(math.radians(90),0,math.radians(90)),'ORTHO',2.6),'hero':None}
for name,v in views.items():
    if v:
        co.location=v[0]; co.rotation_euler=v[1]; cam.type=v[2]; cam.ortho_scale=v[3]
    else:
        cam.type='PERSP'; cam.lens=50
        target=Vector((-1.4,0,0.04)); pos=Vector((1.9,-4.8,1.2)); co.location=pos
        co.rotation_euler=(target-pos).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=OUT+f'/r_{name}.png'; bpy.ops.render.render(write_still=True)
print('done')
