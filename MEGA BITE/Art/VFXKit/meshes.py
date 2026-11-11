import bpy, bmesh, math
from mathutils import Vector, Matrix
def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
    for m in list(bpy.data.meshes): bpy.data.meshes.remove(m)
def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(filepath=f'/tmp/claude-0/vfxkit/{name}.fbx', use_selection=True, apply_unit_scale=True, global_scale=1.0, bake_space_transform=True, add_leaf_bones=False, axis_forward='-Z', axis_up='Y')
def obj_from_bm(bm,name):
    me=bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(ob)
    for p in me.polygons: p.use_smooth=True
    return ob
def tube_arc(bm,R,r,a0,a1,seg,ring=10,taper=False):
    # torus segment in the XY plane (Blender Z up -> ring lies flat when exported with Y up? we build in XZ so it's flat in Roblox)
    verts=[]
    n=max(2,int(seg*(a1-a0)/(2*math.pi))+1)
    full=abs((a1-a0)-2*math.pi)<1e-6
    if full: n=seg
    for i in range(n):
        t=a0+(a1-a0)*i/(n if full else n-1)
        k=1.0
        if taper and not full:
            u=i/(n-1); k=max(0.05,math.sin(u*math.pi)**0.6)
        c=Vector((math.cos(t)*R, math.sin(t)*R, 0)); outward=Vector((math.cos(t),math.sin(t),0))
        row=[]
        for j in range(ring):
            p=j/ring*2*math.pi
            v=c+outward*math.cos(p)*r*k+Vector((0,0,1))*math.sin(p)*r*k
            row.append(bm.verts.new(v))
        verts.append(row)
    rng=range(n) if full else range(n-1)
    for i in rng:
        a=verts[i]; b=verts[(i+1)%n]
        for j in range(ring):
            bm.faces.new([a[j],a[(j+1)%ring],b[(j+1)%ring],b[j]])
    if not full:
        bm.faces.new(verts[0][::-1]); bm.faces.new(verts[-1])
clear()
# 1) thin full ring, radius 1
bm=bmesh.new(); tube_arc(bm,1.0,0.018,0,2*math.pi,128,8); obj_from_bm(bm,'RingThin'); export('mb_vfx_ringthin'); clear()
# 2) broken arcs: 3 tapered arcs (a gyroscope band)
bm=bmesh.new()
for k in range(3):
    a0=k*2*math.pi/3+0.15; tube_arc(bm,1.0,0.035,a0,a0+2*math.pi/3-0.55,96,8,taper=True)
obj_from_bm(bm,'ArcBroken'); export('mb_vfx_arcbroken'); clear()
# 3) tooth halo: a ring band + 18 shark teeth (flat triangular cones) pointing outward
bm=bmesh.new(); tube_arc(bm,1.0,0.03,0,2*math.pi,128,8)
for i in range(18):
    t=i/18*2*math.pi
    o=Vector((math.cos(t),math.sin(t),0)); side=Vector((-math.sin(t),math.cos(t),0)); up=Vector((0,0,1))
    base=o*1.0; tip=o*1.32
    w=0.075; th=0.03
    vs=[bm.verts.new(base+side*w+up*th),bm.verts.new(base-side*w+up*th),bm.verts.new(base-side*w-up*th),bm.verts.new(base+side*w-up*th),bm.verts.new(tip)]
    bm.faces.new([vs[0],vs[1],vs[2],vs[3]][::-1])
    for a,b in [(0,1),(1,2),(2,3),(3,0)]: bm.faces.new([vs[a],vs[b],vs[4]])
obj_from_bm(bm,'ToothHalo'); export('mb_vfx_toothhalo'); clear()
# 4) crescent blade (flat, sharp ends, slight thickness): for slashes / ram arcs
bm=bmesh.new(); n=64; outer=[]; inner=[]
for i in range(n):
    u=i/(n-1); t=-1.2+2.4*u
    wdt=math.sin(u*math.pi)**0.8*0.22
    outer.append((math.cos(t)*1.0, math.sin(t)*1.0)); inner.append((math.cos(t)*(1.0-wdt)-0.0, math.sin(t)*(1.0-wdt)))
top=[]; bot=[]
for (x,y) in outer+inner[::-1]:
    top.append(bm.verts.new((x,y,0.02))); bot.append(bm.verts.new((x,y,-0.02)))
m=len(top)
bm.faces.new(top); bm.faces.new(bot[::-1])
for i in range(m): bm.faces.new([top[i],bot[i],bot[(i+1)%m],top[(i+1)%m]])
ob=obj_from_bm(bm,'Crescent')
for p in ob.data.polygons: p.use_smooth=False
export('mb_vfx_crescent'); clear()
print('done')
