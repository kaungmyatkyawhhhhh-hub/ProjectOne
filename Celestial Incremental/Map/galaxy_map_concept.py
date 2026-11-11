import bpy, math, random, bmesh
from mathutils import Vector, Matrix, Euler
exec(open('/tmp/claude-0/blend/icons.py').read().split("def i_stardust")[0])
s=reset()
s.render.resolution_x=1600; s.render.resolution_y=900; s.render.film_transparent=False; s.cycles.samples=64
s.world.node_tree.nodes['Background'].inputs[0].default_value=(0.03,0.015,0.08,1); s.world.node_tree.nodes['Background'].inputs[1].default_value=1.0
for o in [o for o in s.objects if o.type=='LIGHT']: bpy.data.objects.remove(o)
cam=s.camera; cam.location=(0,-34,20); cam.rotation_euler=(math.radians(58),0,0); cam.data.lens=30
def L(name,typ,loc,e,c,size=4,rot=None):
    l=bpy.data.lights.new(name,typ); l.energy=e; l.color=c
    if typ=='AREA': l.size=size
    o=bpy.data.objects.new(name,l); o.location=loc; s.collection.objects.link(o)
    d=Vector((0,0,0))-Vector(loc); o.rotation_euler=d.to_track_quat('-Z','Y').to_euler(); return o
L("sun",'SUN',(10,-10,20),2.2,(1,0.88,0.75)); bpy.data.lights["sun"].angle=0.2
L("rim",'AREA',(0,30,10),3000,(0.5,0.4,1.0),20)
L("core",'POINT',(0,0,4),2500,(1,0.6,0.25))
stone=mat("stone",(0.78,0.7,0.6),rough=0.7,coat=0.1)
stone2=mat("stone2",(0.62,0.55,0.48),rough=0.75,coat=0.05)
rockm=mat("rockm",(0.25,0.2,0.32),rough=0.8,coat=0)
brass=mat("brass",(0.95,0.65,0.25),rough=0.25,metal=1.0,coat=0.3)
def cyl(r,d,loc,m,v=24,bev=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=d,location=loc); o=bpy.context.object; o.data.materials.append(m)
    if bev: b=o.modifiers.new("b",'BEVEL'); b.width=bev; b.segments=1
    return o
def tor(R,r,loc,m,maj=48,mn=6,rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R,minor_radius=r,major_segments=maj,minor_segments=mn,location=loc,rotation=rot); o=bpy.context.object; o.data.materials.append(m); return o
def ico(r,loc,m,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=loc); o=bpy.context.object; o.data.materials.append(m); return o
# island: top disc + rocky underside
cyl(16,1.2,(0,0,-0.6),stone,32,0.3)
bpy.ops.mesh.primitive_cone_add(vertices=20,radius1=16,radius2=2,depth=12,location=(0,0,-7.2),rotation=(math.pi,0,0)); u=bpy.context.object; u.data.materials.append(rockm)
random.seed(4)
for v in u.data.vertices:
    if v.co.z<5.9: v.co.x*=random.uniform(0.85,1.08); v.co.y*=random.uniform(0.85,1.08)
# floor rings (star-chart etched)
tor(6.5,0.08,(0,0,0.02),brass,64,4); tor(12.5,0.08,(0,0,0.02),brass,96,4); tor(15.8,0.25,(0,0,0),brass,96,6)
for i in range(8):
    a=i*math.pi/4
    bpy.ops.mesh.primitive_cube_add(size=1,location=(math.cos(a)*9.5,math.sin(a)*9.5,0.02)); c=bpy.context.object; c.scale=(6,0.08,0.02); c.rotation_euler=(0,0,a); c.data.materials.append(brass)
# central core altar
cyl(3.2,0.8,(0,0,0.4),stone2,8,0.15); cyl(2.6,0.5,(0,0,1.0),brass,8,0.08)
coreM=mat("coreM",(1,0.7,0.3),emit=(1,0.55,0.15),estr=5); ico(1.6,(0,0,4.2),coreM,2)
spk=mat("spk",(1,0.5,0.1),rough=0.3,emit=(1,0.4,0.05),estr=1.5)
for i in range(14):
    a=i*2*math.pi/14
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=0.35,depth=1.3,location=(math.cos(a)*2.3,0,4.2+math.sin(a)*2.3)); c=bpy.context.object; c.rotation_euler=(0,-a+math.pi/2,0); c.data.materials.append(spk)
tor(3.6,0.12,(0,0,4.2),brass,48,6,(math.radians(70),0,0)); tor(3.9,0.08,(0,0,4.2),brass,48,6,(math.radians(-60),math.radians(30),0))
# player pads with star systems at different progress
pcols=[(0.45,0.2,0.95),(0.2,0.75,1.0),(0.25,0.9,0.45),(1.0,0.35,0.45),(1.0,0.8,0.3)]
pm=[mat("pm%d"%i,c,rough=0.3,coat=0.6,emit=c,estr=0.2) for i,c in enumerate(pcols)]
orbm=mat("orbm",(0.85,0.75,1.0),emit=(0.7,0.6,1.0),estr=1.2)
starm=mat("starm",(1,0.7,0.25),emit=(1,0.55,0.12),estr=3)
rockp=mat("rockp",(0.5,0.47,0.55),rough=0.7)
for i in range(8):
    a=i*2*math.pi/8+math.pi/8; px,py=math.cos(a)*11,math.sin(a)*11
    cyl(2.2,0.4,(px,py,0.2),stone2,12,0.08); tor(2.2,0.1,(px,py,0.42),brass,24,4)
    lvl=[5,3,1,4,2,0,3,1][i]
    h=3.2
    if lvl==0: ico(0.5,(px,py,h),rockp,1)
    else:
        ico(0.45+0.08*lvl,(px,py,h),starm,1)
        for k in range(lvl):
            R=0.9+k*0.45; ang=k*1.7+i
            tor(R,0.02,(px,py,h),orbm,32,3)
            ico(0.14+0.03*k,(px+math.cos(ang)*R,py+math.sin(ang)*R,h),pm[k%5],1)
    # beam from pad to system
    bm=mat("beam%d"%i,(0.6,0.5,1),emit=(0.6,0.45,1),estr=1.5); cyl(0.05,h-0.6,(px,py,0.4+(h-0.6)/2),bm,6)
# boards (upgrade board + star map) with v12 texture
def board(loc,rot,img):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); b=bpy.context.object; b.scale=(4.2,0.25,2.6); b.rotation_euler=(0,0,rot); b.data.materials.append(brass)
    bpy.ops.mesh.primitive_plane_add(size=1,location=loc); p=bpy.context.object; p.scale=(3.9,2.3,1); p.rotation_euler=(math.radians(90),0,rot)
    off=Vector((0,-0.14,0)); off.rotate(Euler((0,0,rot))); p.location=Vector(loc)+off
    m=bpy.data.materials.new("img"); m.use_nodes=True; nt=m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=bpy.data.images.load(img); em=nt.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value=1.4; out=nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(tx.outputs['Color'],em.inputs['Color']); nt.links.new(em.outputs[0],out.inputs[0]); p.data.materials.append(m)
    for dx in (-1.9,1.9):
        o=Vector((dx,0,-1.6)); o.rotate(Euler((0,0,rot))); cyl(0.12,1.4,Vector(loc)+o+Vector((0,0,-0.5)),brass,8)
board((-6.5,-13.2,2.4),math.radians(-20),'/tmp/claude-0/ui/v12.png')
board((6.5,-13.2,2.4),math.radians(20),'/tmp/claude-0/ui/win_tree.png')
# forge (locked) and black hole gate on the back edge
cyl(2.6,0.5,(-12,8,0.25),stone2,8,0.08)
steel=mat("steel",(0.32,0.34,0.46),rough=0.22,metal=0.9,coat=0.5)
for loc,sc in [((-12,8,1.3),(1.6,0.6,0.35)),((-12,8,0.8),(0.6,0.45,0.5))]:
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); c=bpy.context.object; c.scale=sc; c.data.materials.append(steel)
lock=mat("lock",(0.4,0.4,0.45),rough=0.5); ico(0.3,(-12,8,2.4),lock,1)
tor(3.2,0.45,(11,9,3.6),brass,32,6,(math.radians(90),0,math.radians(-35)))
voidm=mat("void",(0.02,0,0.05),rough=0.1,emit=(0.3,0.1,0.8),estr=0.6)
bpy.ops.mesh.primitive_circle_add(vertices=32,radius=2.9,fill_type='NGON',location=(11,9,3.6),rotation=(math.radians(90),0,math.radians(-35))); g=bpy.context.object; g.data.materials.append(voidm)
# crystal clusters framing boards
cm=mat("crys",(0.55,0.3,1),rough=0.08,emit=(0.45,0.2,1),estr=0.8)
def gemc(loc,h):
    verts=[(math.cos(i*math.pi/3)*0.3,math.sin(i*math.pi/3)*0.3,0) for i in range(6)]+[(0,0,h),(0,0,-0.2)]
    faces=[(i,(i+1)%6,6) for i in range(6)]+[((i+1)%6,i,7) for i in range(6)]
    o=mesh_obj("gem",verts,faces,cm); o.location=loc; o.rotation_euler=(random.uniform(-.3,.3),random.uniform(-.3,.3),0)
for (x,y) in [(-10,-12),(10,-12),(-14,4),(14.5,4),(0,14)]:
    for k in range(3): gemc((x+random.uniform(-.6,.6),y+random.uniform(-.6,.6),0),random.uniform(0.8,1.8))
# far ring nebula island (locked) + stars
cyl(5,0.8,(-26,30,-3),stone,16,0.2); tor(4,0.15,(-26,30,1),orbm,32,4,(math.radians(80),0,0))
st=mat("st",(1,1,1),emit=(0.9,0.85,1),estr=6)
bm2=bmesh.new()
for i in range(500):
    v=Vector((random.uniform(-1,1),random.uniform(-0.2,1),random.uniform(-0.4,1))).normalized()*random.uniform(70,90)
    bmesh.ops.create_icosphere(bm2,subdivisions=0,radius=random.uniform(0.08,0.25),matrix=Matrix.Translation(v))
me=bpy.data.meshes.new("sky"); bm2.to_mesh(me); o=bpy.data.objects.new("sky",me); s.collection.objects.link(o); o.data.materials.append(st)
# nebula backdrop plane with galaxy render
bpy.ops.mesh.primitive_plane_add(size=1,location=(0,80,30)); p=bpy.context.object; p.scale=(220,124,1); p.rotation_euler=(math.radians(90),0,0)
m=bpy.data.materials.new("gbg"); m.use_nodes=True; nt=m.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=bpy.data.images.load('/tmp/claude-0/blend/out/galaxybg.png'); em=nt.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value=0.9; out=nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(tx.outputs['Color'],em.inputs['Color']); nt.links.new(em.outputs[0],out.inputs[0]); p.data.materials.append(m)
gl=[n for n in s.node_tree.nodes if n.bl_idname=='CompositorNodeGlare'][0]; gl.threshold=0.8; gl.size=8; gl.mix=0.0
s.render.filepath="/tmp/claude-0/blend/out/map_concept.png"; bpy.ops.render.render(write_still=True)
