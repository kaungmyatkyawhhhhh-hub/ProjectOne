import bpy, bmesh, math, numpy as np, os
for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
N=56; Lh=4.0  # 8 BU = 800 studs after import (1 BU -> 100 studs)
rng=np.random.default_rng(7)
def h(x,y):
    v=0
    for k,(a,f,ph) in enumerate([(0.05,0.9,0.3),(0.03,1.7,1.1),(0.015,3.1,2.0),(0.008,5.3,0.7)]):
        v+=a*math.sin(f*x+ph)*math.cos(f*0.8*y+ph*1.3)
    # flat-ish centre (spawn area), bowl rising toward the edges so the borders read
    r=math.hypot(x,y)/Lh
    v*=0.4+0.6*min(1,r*1.5)
    v+=0.12*max(0,r-0.62)**2*8
    return v
bm=bmesh.new(); verts=[]
for j in range(N+1):
    row=[]
    for i in range(N+1):
        x=-Lh+2*Lh*i/N+ (rng.uniform(-0.25,0.25)*2*Lh/N if 0<i<N else 0)
        y=-Lh+2*Lh*j/N+ (rng.uniform(-0.25,0.25)*2*Lh/N if 0<j<N else 0)
        row.append(bm.verts.new((x,y,h(x,y))))
    verts.append(row)
for j in range(N):
    for i in range(N):
        a,b,c,d=verts[j][i],verts[j][i+1],verts[j+1][i+1],verts[j+1][i]
        if (i+j)%2: bm.faces.new((a,b,c)); bm.faces.new((a,c,d))
        else: bm.faces.new((a,b,d)); bm.faces.new((b,c,d))
me=bpy.data.meshes.new('SandFloor'); bm.to_mesh(me); bm.free()
o=bpy.data.objects.new('SandFloor',me); bpy.context.scene.collection.objects.link(o)
for p in me.polygons: p.use_smooth=False
me.uv_layers.new(name='UVMap')
for l in me.loops: pass
m=bpy.data.materials.new('Sand'); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(0.64,0.77,0.84,1); me.materials.append(m)
bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
os.makedirs('export',exist_ok=True)
bpy.ops.export_scene.fbx(filepath='export/MB_SandFloor.fbx',use_selection=True,object_types={'MESH'},apply_unit_scale=True,mesh_smooth_type='FACE',axis_forward='-Z',axis_up='Y')
print('floor tris',len(me.polygons))
