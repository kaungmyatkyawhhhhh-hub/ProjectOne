import os,pickle,sys
import bpy
sp=r'C:\Users\USER\AppData\Local\Temp\claude\7a3e934f062f0b7d\35c534ef-1102-4c78-a067-cd9366e2fe81\scratchpad'
out=r'C:\Users\USER\ProjectOne\Games\CityLegends\imports\lamps'
data=pickle.load(open(sp+r'\lampscan\shells_plain.pkl','rb'))
IDS=data['ids']; shells=data['shells']
def code(v):
    n=int(round(v*1000))
    return ('n'+str(-n)) if n<0 else str(n)
items=[]
for i,id in enumerate(IDS):
    for role,(V,T) in shells[id].items():
        items.append((i+1,role,V,T))
BATCH=70
for b in range(0,len(items),BATCH):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for i,role,V,T in items[b:b+BATCH]:
        xs=[p[0] for p in V];ys=[p[1] for p in V];zs=[p[2] for p in V]
        c=((min(xs)+max(xs))/2,(min(ys)+max(ys))/2,(min(zs)+max(zs))/2)
        s=(max(xs)-min(xs),max(ys)-min(ys),max(zs)-min(zs))
        name='_'.join(['LF%d'%i,role,code(c[0]),code(c[1]),code(c[2]),code(s[0]),code(s[1]),code(s[2])])
        me=bpy.data.meshes.new(name)
        me.from_pydata([(p[0]-c[0],-(p[2]-c[2]),p[1]-c[1]) for p in V],[],[tuple(int(x) for x in t) for t in T])
        me.uv_layers.new(name='UVMap')
        me.polygons.foreach_set('use_smooth',[True]*len(me.polygons))
        me.update()
        ob=bpy.data.objects.new(name,me)
        bpy.context.collection.objects.link(ob)
    for ob in bpy.context.scene.objects: ob.select_set(True)
    path=os.path.join(out,'lamps_fix_%d.fbx'%(b//BATCH))
    bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},global_scale=1.0,apply_unit_scale=True,bake_space_transform=False,add_leaf_bones=False,bake_anim=False,axis_forward="-Z",axis_up="Y",mesh_smooth_type="FACE",use_mesh_modifiers=False)
    print('FILE',path,len(items[b:b+BATCH]),os.path.getsize(path)//1024,'KB')
