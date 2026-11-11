"""Join each prop, put its origin at the bottom centre, bake every K_ colour into ONE shared palette strip,
export one FBX with all props (Roblox imports a Model with one MeshPart per prop)."""
import bpy, bmesh, os, math, sys
OUT=globals().get('OUT','/home/claude/megabite_art/kit/export'); os.makedirs(OUT,exist_ok=True)
NAME=globals().get('NAME','MB_Kit_A')
groups=globals()['GROUPS']   # prop name -> list of object names
mats=[m for m in bpy.data.materials if m.name.startswith('K_')]
n=len(mats); CELL=8
img=bpy.data.images.new(NAME+'_palette',CELL*n,CELL)
px=[]
for y in range(CELL):
    for m in mats:
        c=m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value
        srgb=[((v**(1/2.4))*1.055-0.055) if v>0.0031308 else v*12.92 for v in c[:3]]
        for x in range(CELL): px+= [*srgb,1.0]
img.pixels=px; png=os.path.join(OUT,NAME+'_palette.png'); img.filepath_raw=png; img.file_format='PNG'; img.save()
em=bpy.data.materials.new(NAME+'_mat'); em.use_nodes=True
t=em.node_tree.nodes.new('ShaderNodeTexImage'); t.image=img; t.interpolation='Closest'
em.node_tree.links.new(t.outputs['Color'],em.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
exported=[]
for prop,names in groups.items():
    objs=[bpy.data.objects[nm] for nm in names]
    for o in objs:
        me=o.data
        if not me.uv_layers: me.uv_layers.new(name='UVMap')
        uv=me.uv_layers.active.data
        for p in me.polygons:
            mname=me.materials[p.material_index].name
            u=(mats.index(bpy.data.materials[mname])+0.5)/n
            for li in p.loop_indices: uv[li].uv=(u,0.5)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    if len(objs)>1: bpy.ops.object.join()
    o=bpy.context.view_layer.objects.active; o.name=prop; o.data.name=prop
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # origin at bottom centre
    import numpy as np
    co=np.array([v.co[:] for v in o.data.vertices]); c=((co[:,0].min()+co[:,0].max())/2,(co[:,1].min()+co[:,1].max())/2,co[:,2].min())
    for v in o.data.vertices: v.co.x-=c[0]; v.co.y-=c[1]; v.co.z-=c[2]
    o.location=(0,0,0)
    o.data.materials.clear(); o.data.materials.append(em)
    for p in o.data.polygons: p.material_index=0
    # Roblox draws one side: make sure normals point out
    bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.recalc_face_normals(bm,faces=bm.faces); bm.to_mesh(o.data); bm.free()
    exported.append((prop,len(o.data.polygons),tuple(round(d,2) for d in o.dimensions)))
# spread them out on a line for import
x=0
for prop,_,dims in exported:
    o=bpy.data.objects[prop]; o.location.x=x+dims[0]/2; x+=dims[0]+3
bpy.ops.object.select_all(action='DESELECT')
for prop,_,_ in exported: bpy.data.objects[prop].select_set(True)
fbx=os.path.join(OUT,NAME+'.fbx')
bpy.ops.export_scene.fbx(filepath=fbx,use_selection=True,object_types={'MESH'},path_mode='COPY',embed_textures=True,apply_unit_scale=True,mesh_smooth_type='FACE',axis_forward='-Z',axis_up='Y')
print('EXPORTED',fbx,os.path.getsize(fbx),exported)
