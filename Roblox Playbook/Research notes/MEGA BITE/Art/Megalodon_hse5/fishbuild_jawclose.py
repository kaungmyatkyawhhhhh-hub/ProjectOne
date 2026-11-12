"""Build a fish-kit model in Blender: smooth mesh, outward faces, fine inverted-hull edge line, the species' old rig
(Root + Spine0..7 [+ Jaw]) so its clips keep working, FBX for Roblox, Workbench check renders."""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector
import numpy as _np
R=json.load(open(sys.argv[-1])) if sys.argv[-1].endswith('.json') else RIGCFG
D=R['dir']; OUT=os.path.abspath(D+'/out'); G=json.load(open(OUT+'/geo.json'))
bpy.ops.wm.read_factory_settings(use_empty=True); sc=bpy.context.scene
me=bpy.data.meshes.new(R['name']); ob=bpy.data.objects.new(R['name'],me); sc.collection.objects.link(ob)
bm=bmesh.new(); vs=[bm.verts.new(v) for v in G['V']]; bm.verts.ensure_lookup_table()
uvl=bm.loops.layers.uv.new('UVMap'); part=bm.faces.layers.int.new('part')
PK={'upper':0,'jaw':1,'eye':2,'fin':3,'brow':4,'tooth_up':5,'tooth_lo':6,'wall':7}
for f,uv,k in zip(G['F'],G['UV'],G['K']):
    try: face=bm.faces.new([vs[i] for i in f])
    except ValueError: continue
    face[part]=PK[k]
    for l,u in zip(face.loops,uv): l[uvl].uv=u
fin_verts=list({v for f in bm.faces if f[part]==3 for v in f.verts})
bmesh.ops.remove_doubles(bm,verts=fin_verts,dist=1e-5)
for f in bm.faces: f.smooth=True
ax=G['axis']; zc_at=lambda x:float(_np.interp(x,ax['x'],ax['zc']))
bm.normal_update()
mid=(ax['x'][0]+ax['x'][-1])/2
for f in bm.faces:
    if f[part] in (3,5,6,7): continue
    c=f.calc_center_median()
    if f[part]==1 and G.get('jaw') and G['jaw'].get('axis'):
        ja=G['jaw']['axis']; ref=Vector((c.x,0,float(_np.interp(c.x,ja['x'],ja['zc']))))
    elif f[part]==1 and G.get('jaw'): ref=Vector((c.x,0,G['jaw']['head'][2]-0.05))
    else:
        xx=min(max(c.x,ax['x'][0]+0.05),ax['x'][-1]-0.05); ref=Vector((xx,0,zc_at(xx)))
    if f.normal.dot(c-ref)<0: f.normal_flip()
bmesh.ops.recalc_face_normals(bm,faces=[f for f in bm.faces if f[part] in (3,5,6)])
bm.to_mesh(me); bm.free()
img=bpy.data.images.load(OUT+'/'+R.get('tex','tex.png'))
mat=bpy.data.materials.new(R['name']+'_mat'); mat.use_nodes=True; nt=mat.node_tree
tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=img; nt.links.new(tx.outputs['Color'],nt.nodes['Principled BSDF'].inputs['Base Color'])
mat.use_backface_culling=True; me.materials.append(mat)
# inverted hull edge line (eyes, teeth excluded)
OUTW=R.get('outline',0.011)*R['length']/3.39
bm=bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table(); uvl=bm.loops.layers.uv.active; part=bm.faces.layers.int['part']; bm.normal_update()
JX=G['jaw']['head'][0] if G.get('jaw') else 1e9
def hull_ok(f):
    if f[part] not in (0,1,3,4): return False
    if R.get('mouth_nohull'):
        c=f.calc_center_median()
        if f[part]==0 and c.x>JX and f.normal.z<-0.45: return False
        if f[part]==1 and f.normal.z>R.get('jaw_hull_nz',-0.15): return False
    return True
src=[f for f in bm.faces if hull_ok(f)]; vmap={}
for f in src:
    for v in f.verts:
        if v not in vmap: vmap[v]=bm.verts.new(v.co+v.normal*OUTW)
for f in src:
    nf=bm.faces.new([vmap[v] for v in reversed(f.verts)]); nf.smooth=True; nf[part]=10+f[part]
    for l in nf.loops: l[uvl].uv=(544/1024,1-32/1024) if not R.get('hull_debug') else {0:(700/1024,1-10/1024),1:(608/1024,1-32/1024),3:(100/1024,1-128/1024),4:(544/1024,1-32/1024)}[f[part]]
bm.to_mesh(me); bm.free()
print('tris',sum(len(p.vertices)-2 for p in me.polygons))
# rig (old species rig)
arm=bpy.data.armatures.new(R['name']+'Rig'); rig=bpy.data.objects.new(R['name']+'Rig',arm); sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig; bpy.ops.object.mode_set(mode='EDIT')
x0,x1,NB=R['x0'],R['x1'],R.get('nb',8); xs=[x0-i*(x0-x1)/NB for i in range(NB+1)]
rx=R.get('root_x',0.0); rb=arm.edit_bones.new('Root'); rb.head=(rx,0,0); rb.tail=(rx+0.4,0,0); prev=rb
for i in range(NB):
    b=arm.edit_bones.new(f'Spine{i}'); b.head=(xs[i],0,0); b.tail=(xs[i+1],0,0); b.parent=prev; b.use_connect=i>0; prev=b
if R.get('jaw') and G.get('jaw'):
    j=arm.edit_bones.new('Jaw'); j.head=G['jaw']['head']; j.tail=G['jaw']['tail']; j.parent=arm.edit_bones['Spine0']
bpy.ops.object.mode_set(mode='OBJECT')
ob.parent=rig; mod=ob.modifiers.new('Armature','ARMATURE'); mod.object=rig
seg=(xs[0]-xs[-1])/NB; groups=[ob.vertex_groups.new(name=f'Spine{i}') for i in range(NB)]
jg=ob.vertex_groups.new(name='Jaw') if R.get('jaw') else None
pl=me.attributes['part'].data
jawv=set()
if jg:
    for p in me.polygons:
        if pl[p.index].value in (1,6,11): jawv|=set(p.vertices)
    jawv|=set(G.get('jaw_verts',[]))
for v in me.vertices:
    if v.index in jawv: jg.add([v.index],1.0,'REPLACE'); continue
    u=(xs[0]-v.co.x)/seg-0.5
    ws=sorted(((math.exp(-((u-k)/0.75)**2),k) for k in range(NB)),reverse=True)[:3]; tot=sum(w for w,_ in ws)
    for w,k in ws: groups[k].add([v.index],w/tot,'REPLACE')
JC=R.get('jaw_close')
if JC and jawv:
    # 12 Nov: bake a CLOSED mouth into the rest mesh (owner: the bone-closed jaw looked unconnected).
    # Jaw turns up about its rear hinge, narrows and tucks under the upper lip toward the front (0 at the hinge,
    # so the corner stays joined); the throat just behind/below the hinge follows part of the turn.
    co_=_np.array([v.co[:] for v in me.vertices]); jm=_np.zeros(len(co_),bool); jm[list(jawv)]=True
    J_=co_[jm]; xb=J_[:,0].min(); bk=J_[J_[:,0]<xb+0.12]; piv=_np.array([bk[:,0].mean(),0,bk[:,2].max()])
    th=-math.radians(JC['ang']); BL=JC.get('blend',0.6)
    def _rot(p,t):
        d=p-piv; c,s_=math.cos(t),math.sin(t); return piv+_np.array([d[0]*c+d[2]*s_,d[1],-d[0]*s_+d[2]*c])
    for i,v in enumerate(me.vertices):
        p=co_[i]
        if jm[i]:
            q=_rot(p,th); f=min(1,max(0,(p[0]-piv[0])/0.35))
            q[1]*=1-(1-JC['sy'])*f; q[0]+=JC['dx']*f; q[2]+=JC['dz']*f; v.co=q
        else:
            d=p-piv
            if d[2]<0.05 and -BL<d[0]<0.5:
                w=max(0,1-(-d[0])/BL) if d[0]<0 else 1.0
                w*=min(1,max(0,(0.05-d[2])/0.25)); w=w*w*(3-2*w)
                if w>0: v.co=_rot(p,th*w)
    print('jaw_close pivot',piv)
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active=rig
if not R.get('render_only'): bpy.ops.export_scene.fbx(filepath=OUT+f"/{R['name']}_{R['ver']}.fbx",use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,
    bake_anim=False,path_mode='COPY',embed_textures=True,apply_unit_scale=True,use_armature_deform_only=False,mesh_smooth_type='FACE')
if not R.get('render_only'): print('fbx',os.path.getsize(OUT+f"/{R['name']}_{R['ver']}.fbx"))
# test pose: open the jaw 25 deg for one render
w=bpy.data.worlds.new('W'); sc.world=w
sc.render.engine='BLENDER_WORKBENCH'; sh_=sc.display.shading; sh_.light='STUDIO'; sh_.color_type='TEXTURE'; sh_.show_backface_culling=True
sc.render.film_transparent=True; sc.render.resolution_x=768; sc.render.resolution_y=512; sc.view_settings.view_transform='Standard'
cam=bpy.data.cameras.new('C'); co=bpy.data.objects.new('C',cam); sc.collection.objects.link(co); sc.camera=co
L=R['length']; cx=-L/2
views={'side':((cx,-12,0),(math.radians(90),0,0),'ORTHO',L*1.13),'top':((cx,0,12),(0,0,0),'ORTHO',L*1.13),
       'front':((12,0,0),(math.radians(90),0,math.radians(90)),'ORTHO',L*0.8),'hero':None,'bite':None}
PRE=R.get('prefix','')
for name,v in ({} if R.get('render_only') else views).items():
    if name=='bite' and R.get('jaw'):
        pb=rig.pose.bones['Jaw']; pb.rotation_mode='XYZ'; pb.rotation_euler=(math.radians(-28),0,0)
    if v:
        co.location=v[0]; co.rotation_euler=v[1]; cam.type=v[2]; cam.ortho_scale=v[3]
    else:
        cam.type='PERSP'; cam.lens=50; t=Vector((-L*0.4,0,0.0)); p=Vector((L*0.56,-L*1.42,L*0.35)); co.location=p; co.rotation_euler=(t-p).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=OUT+f'/r_{name}.png'; bpy.ops.render.render(write_still=True)
if R.get('jaw'): rig.pose.bones['Jaw'].rotation_euler=(0,0,0)
if G.get('px'):
    P=G['px']; sh_.light='FLAT'; sc.render.resolution_x=P['W']; sc.render.resolution_y=P['H']
    cam.type='ORTHO'; cam.ortho_scale=P['W']*P['S']; co.location=((P['W']/2-P['nose'])*P['S'],-12,(P['basez']-P['H']/2)*P['S']); co.rotation_euler=(math.radians(90),0,0)
    sc.render.filepath=OUT+'/'+PRE+'f_sheet.png'; bpy.ops.render.render(write_still=True)
    sc.render.resolution_x=1280; sc.render.resolution_y=800
    VK=R.get('view_k',1.0)
    for nm,pp,tt_ in (('f_hero',Vector((L*0.3,-L*1.0,L*0.28)),Vector((-L*0.45,0,0.0))),('f_front',Vector((L*0.75,-L*0.5,L*0.1)),Vector((-L*0.25,0,0.0))),('f_low',Vector((L*0.1,-L*0.9,-L*0.4)),Vector((-L*0.45,0,0.0))),('f_top',Vector((-L*0.5,-L*0.02,L*1.25)),Vector((-L*0.5,0,0.0))),('f_shop',Vector((L*0.42,-L*0.62,L*0.2)),Vector((-L*0.42,0,-L*0.02)))):
        cam.type='PERSP'; cam.lens=50; pp=tt_+(pp-tt_)*VK; co.location=pp; co.rotation_euler=(tt_-pp).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=OUT+'/'+PRE+nm+'.png'; bpy.ops.render.render(write_still=True)
print('done')
