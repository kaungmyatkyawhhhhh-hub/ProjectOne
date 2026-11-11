import bpy, bmesh, math
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
bm=bmesh.new()
# chunky 5-point star: puffy (front/back apex) with bevelled points, like a toy collectible
R,r,T=1.0,0.48,0.32
outer=[]
for i in range(10):
    a=math.pi/2+i*math.pi/5; rad=R if i%2==0 else r
    outer.append(Vector((math.cos(a)*rad, math.sin(a)*rad, 0)))
ring=[bm.verts.new(v) for v in outer]
# a mid ring slightly inset and raised = rounded edge
mid_f=[bm.verts.new(v*0.82+Vector((0,0,T*0.55))) for v in outer]
mid_b=[bm.verts.new(v*0.82+Vector((0,0,-T*0.55))) for v in outer]
cf=bm.verts.new((0,0,T)); cb=bm.verts.new((0,0,-T))
n=len(outer)
for i in range(n):
    j=(i+1)%n
    bm.faces.new([ring[i],ring[j],mid_f[j],mid_f[i]])
    bm.faces.new([mid_f[i],mid_f[j],cf])
    bm.faces.new([ring[j],ring[i],mid_b[i],mid_b[j]])
    bm.faces.new([mid_b[j],mid_b[i],cb])
me=bpy.data.meshes.new('Star3D'); bm.to_mesh(me); bm.free()
ob=bpy.data.objects.new('Star3D',me); bpy.context.collection.objects.link(ob)
for p in me.polygons: p.use_smooth=False
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath='/tmp/claude-0/vfxkit/mb_ui_star3d.fbx',use_selection=True,apply_unit_scale=True,bake_space_transform=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y')
print('ok')
