import bpy, math, random, bmesh
from mathutils import Vector, Matrix, Euler
exec(open('/tmp/claude-0/blend/icons.py').read().split("def i_stardust")[0])
s=reset()
s.render.resolution_x=1600; s.render.resolution_y=900; s.render.film_transparent=False; s.cycles.samples=80
wn=s.world.node_tree.nodes; wn['Background'].inputs[0].default_value=(0.025,0.012,0.06,1); wn['Background'].inputs[1].default_value=1.0
for o in [o for o in s.objects if o.type=='LIGHT']: bpy.data.objects.remove(o)
cam=s.camera; cam.location=(6,-52,26); cam.rotation_euler=(math.radians(62),0,math.radians(5)); cam.data.lens=26
random.seed(7)
def L(name,typ,loc,e,c,size=4):
    l=bpy.data.lights.new(name,typ); l.energy=e; l.color=c
    if typ=='AREA': l.size=size
    o=bpy.data.objects.new(name,l); o.location=loc; s.collection.objects.link(o)
    d=Vector((0,0,0))-Vector(loc); o.rotation_euler=d.to_track_quat('-Z','Y').to_euler(); return o
L("sun",'SUN',(14,-12,22),2.0,(1,0.86,0.72)); bpy.data.lights["sun"].angle=0.25
L("rim",'AREA',(0,34,12),4000,(0.55,0.4,1.0),24)
L("core",'POINT',(0,0,4.5),3500,(1,0.6,0.25))
L("fill",'AREA',(0,-30,6),600,(0.6,0.7,1.0),20)
stone=mat("stone",(0.80,0.72,0.62),rough=0.65,coat=0.15)
stone2=mat("stone2",(0.64,0.56,0.49),rough=0.7,coat=0.1)
rockm=mat("rockm",(0.22,0.17,0.3),rough=0.8,coat=0)
brass=mat("brass",(0.95,0.66,0.26),rough=0.22,metal=1.0,coat=0.3)
def cyl(r,d,loc,m,v=24,bev=0.0,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=d,location=loc,rotation=rot); o=bpy.context.object; o.data.materials.append(m)
    if bev: b=o.modifiers.new("b",'BEVEL'); b.width=bev; b.segments=1
    return o
def tor(R,r,loc,m,maj=48,mn=6,rot=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R,minor_radius=r,major_segments=maj,minor_segments=mn,location=loc,rotation=rot); o=bpy.context.object; o.data.materials.append(m); return o
def ico(r,loc,m,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=loc); o=bpy.context.object; o.data.materials.append(m); return o
def box(loc,sc,m,rot=(0,0,0),bev=0.05):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.scale=sc; o.data.materials.append(m)
    if bev: b=o.modifiers.new("b",'BEVEL'); b.width=bev; b.segments=1
    return o
def emis(name,c,st): return mat(name,c,emit=c,estr=st,rough=0.3)
# ---------- island ----------
cyl(11,1.2,(0,0,-0.6),stone,32,0.3)
# tile ring pattern (alternating wedges, inner ring)
for i in range(16):
    a=i*2*math.pi/16
    if i%2==0:
        bpy.ops.mesh.primitive_cylinder_add(vertices=3,radius=3,depth=0.04,location=(math.cos(a)*7,math.sin(a)*7,0.01)); w=bpy.context.object; w.scale=(1.2,0.5,1); w.rotation_euler=(0,0,a); w.data.materials.append(stone2)
bpy.ops.mesh.primitive_cone_add(vertices=20,radius1=11,radius2=1.5,depth=10,location=(0,0,-6.2),rotation=(math.pi,0,0)); u=bpy.context.object; u.data.materials.append(rockm)
for v in u.data.vertices:
    if v.co.z<6.4: v.co.x*=random.uniform(0.82,1.08); v.co.y*=random.uniform(0.82,1.08)
# hanging crystal chunks under island
cm=mat("crys",(0.55,0.3,1),rough=0.06,emit=(0.45,0.2,1),estr=1.0)
def gemc(loc,h,rot=None,m=cm):
    verts=[(math.cos(i*math.pi/3)*0.3*h,math.sin(i*math.pi/3)*0.3*h,0) for i in range(6)]+[(0,0,h),(0,0,-0.25*h)]
    faces=[(i,(i+1)%6,6) for i in range(6)]+[((i+1)%6,i,7) for i in range(6)]
    o=mesh_obj("gem",verts,faces,m); o.location=loc; o.rotation_euler=rot or (random.uniform(-.35,.35),random.uniform(-.35,.35),random.uniform(0,6)); return o
for i in range(10):
    a=random.uniform(0,6.28); r=random.uniform(3,9)
    gemc((math.cos(a)*r,math.sin(a)*r,-random.uniform(3,8)),random.uniform(1,2.4),(math.pi+random.uniform(-.3,.3),random.uniform(-.3,.3),0))
tor(6.0,0.08,(0,0,0.03),brass,64,4); tor(10.9,0.3,(0,0,0),brass,96,6)
# steps / lamps on rim
lampM=emis("lamp",(1,0.75,0.4),6)
for i in range(12):
    a=i*2*math.pi/12+0.13
    p=Vector((math.cos(a)*10.3,math.sin(a)*10.3,0))
    cyl(0.12,1.6,p+Vector((0,0,0.8)),brass,8); ico(0.22,p+Vector((0,0,1.75)),lampM,1)
# ---------- core ----------
cyl(3.4,0.8,(0,0,0.4),stone2,8,0.15); cyl(2.8,0.5,(0,0,1.05),brass,8,0.08); cyl(2.0,0.4,(0,0,1.45),stone,8,0.08)
coreM=emis("coreM",(1,0.72,0.32),7); ico(1.6,(0,0,4.6),coreM,2)
spk=mat("spk",(1,0.5,0.1),rough=0.3,emit=(1,0.42,0.05),estr=2)
for i in range(16):
    a=i*2*math.pi/16; Lg=1.3 if i%2 else 1.8
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=0.32,depth=Lg,location=(math.cos(a)*(1.6+Lg/2-0.2),0,4.6+math.sin(a)*(1.6+Lg/2-0.2))); c=bpy.context.object; c.rotation_euler=(0,-a+math.pi/2,0); c.data.materials.append(spk)
tor(3.8,0.13,(0,0,4.6),brass,48,6,(math.radians(72),0,0)); tor(4.1,0.09,(0,0,4.6),brass,48,6,(math.radians(-58),math.radians(30),0)); tor(4.4,0.06,(0,0,4.6),brass,48,6,(math.radians(10),math.radians(-70),0))
# shockwave ring on floor (VFX moment)
sw=emis("sw",(1,0.65,0.3),4); tor(8.2,0.06,(0,0,0.08),sw,96,4); tor(30,0.1,(0,0,1.5),sw,128,4)
# ---------- pads (build-up tiers) ----------
pcols=[(0.45,0.2,0.95),(0.2,0.75,1.0),(0.25,0.9,0.45),(1.0,0.35,0.45),(1.0,0.8,0.3)]
pm=[mat("pm%d"%i,c,rough=0.3,coat=0.6,emit=c,estr=0.25) for i,c in enumerate(pcols)]
orbm=emis("orbm",(0.8,0.7,1.0),1.5)
starm=emis("starm",(1,0.72,0.3),4)
rockp=mat("rockp",(0.5,0.47,0.55),rough=0.7)
bannerC=[(0.9,0.3,0.2),(0.2,0.55,0.95),(0.3,0.8,0.4),(0.75,0.3,0.9),(0.95,0.7,0.2),(0.5,0.5,0.55),(0.2,0.8,0.8),(0.9,0.4,0.6)]
lv=[6,4,1,5,2,0,3,1]
bridgeM0=emis("bridge0",(0.55,0.45,1),1.4)
grass=mat("garden",(0.35,0.8,0.55),rough=0.6)
for i in range(8):
    a=i*2*math.pi/8+math.pi/8; P=Vector((math.cos(a)*24,math.sin(a)*24,0.5+math.sin(i*1.3)*0.8)); tier=lv[i]
    R=4.6
    # island body
    if tier==0:
        ico(2.4,P+Vector((0,0,-1.0)),rockp,1)
    else:
        cyl(R,0.8,P+Vector((0,0,-0.4)),stone if tier>=2 else stone2,14,0.15)
        bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=R,radius2=0.6,depth=4.5,location=P+Vector((0,0,-3.05)),rotation=(math.pi,0,0)); c=bpy.context.object; c.data.materials.append(rockm)
        for v in c.data.vertices:
            if v.co.z<2.1: v.co.x*=random.uniform(0.85,1.08); v.co.y*=random.uniform(0.85,1.08)
    if tier>=1: tor(R,0.12,P+Vector((0,0,0.02)),brass,28,4)
    if tier>=2:
        for k in range(6):
            q=P+Vector((math.cos(k*math.pi/3+a)*(R-0.4),math.sin(k*math.pi/3+a)*(R-0.4),0)); cyl(0.13,1.5+0.25*tier,q+Vector((0,0,0.75+0.12*tier)),brass,8); ico(0.18,q+Vector((0,0,1.55+0.25*tier)),lampM,1)
    if tier>=3:
        for k in range(5): gemc(P+Vector((random.uniform(-3,3),random.uniform(-3,3),0)),random.uniform(0.6,1.3))
        cyl(1.4,0.1,P+Vector((math.cos(a+2.4)*2.6,math.sin(a+2.4)*2.6,0.05)),grass,10)
    if tier>=4:
        bm=mat("ban%d"%i,bannerC[i],rough=0.5); q=P+Vector((math.cos(a)*(R-0.2),math.sin(a)*(R-0.2),0)); box(q+Vector((0,0,2.2)),(0.05,1.0,1.5),bm,(0,0,a),0)
        tor(R+0.9,0.07,P+Vector((0,0,1.6)),brass,40,4)
    if tier>=5:
        q=P+Vector((math.cos(a+1.6)*2.3,math.sin(a+1.6)*2.3,0)); cyl(0.1,1,q+Vector((0,0,0.5)),brass,8); cyl(0.25,1.6,q+Vector((0,0,1.3)),brass,12,0,(math.radians(55),0,a))
        cyl(1.6,0.3,P+Vector((0,0,0.15)),brass,12,0.05)
    h=4.2+0.3*tier
    beam=emis("beam%d"%i,(0.65,0.5,1),1.8); cyl(0.06,h-0.4,P+Vector((0,0,(h-0.4)/2)),beam,6)
    if tier==0: ico(0.6,P+Vector((0,0,h)),rockp,1)
    else:
        ico(0.45+0.12*tier,P+Vector((0,0,h)),starm,1)
        for k in range(tier):
            Rr=1.1+k*0.5; ang=k*1.9+i
            tor(Rr,0.025,P+Vector((0,0,h)),orbm,32,3,(math.radians(8*k),0,0))
            ico(0.17+0.035*k,P+Vector((math.cos(ang)*Rr,math.sin(ang)*Rr,h)),pm[k%5],1)
        for k in range(6): ico(0.06,P+Vector((random.uniform(-.7,.7),random.uniform(-.7,.7),h+0.9+k*0.55)),lampM,0)
    if tier>=4:
        for k in range(6): ico(0.08,P+Vector((random.uniform(-3,3),random.uniform(-3,3),random.uniform(0.8,3.5))),emis("spk%d%d"%(i,k),(1,0.95,0.7),8),0)
    # name plate (floating bar)
    box(P+Vector((0,0,h+2.6+0.3*tier)),(2.6,0.12,0.5),mat("np%d"%i,bannerC[i],rough=0.4,emit=bannerC[i],estr=0.6),(0,0,0),0.04)
    # short light bridge to the centre island
    A=Vector((math.cos(a)*11.2,math.sin(a)*11.2,0.05)); B=P-Vector((math.cos(a)*(R+0.2),math.sin(a)*(R+0.2),-0.05))
    n=10
    for k in range(n):
        t=(k+0.5)/n; q=A.lerp(B,t)+Vector((0,0,math.sin(t*math.pi)*0.8))
        box(q,(0.95,1.4,0.1),bridgeM0,(0,0,a),0)
# ---------- boards (bigger) ----------
def board(loc,rot,img,col):
    box(loc,(5.6,0.35,3.4),brass,(0,0,rot),0.08)
    bpy.ops.mesh.primitive_plane_add(size=1); p=bpy.context.object; p.scale=(5.2,3.0,1); p.rotation_euler=(math.radians(90),0,rot)
    off=Vector((0,-0.19,0)); off.rotate(Euler((0,0,rot))); p.location=Vector(loc)+off
    m=bpy.data.materials.new("img"); m.use_nodes=True; nt=m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=bpy.data.images.load(img); em=nt.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value=1.3; out=nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(tx.outputs['Color'],em.inputs['Color']); nt.links.new(em.outputs[0],out.inputs[0]); p.data.materials.append(m)
    for dx in (-2.4,2.4):
        o=Vector((dx,0,-2.4)); o.rotate(Euler((0,0,rot))); cyl(0.16,2.2,Vector(loc)+o+Vector((0,0,-0.3)),brass,8)
    o=Vector((0,0,1.95)); ico(0.35,Vector(loc)+o,emis("bt"+img[-8:],col,5),1)
board((-5.5,-7.8,3.2),math.radians(-30),'/tmp/claude-0/ui/v12.png',(1,0.6,0.2))
board((5.5,-7.8,3.2),math.radians(30),'/tmp/claude-0/ui/win_tree.png',(0.3,1,0.5))
for (x,y) in [(-8.6,-5.5),(8.6,-5.5),(0,-9.6)]:
    for k in range(3): gemc((x+random.uniform(-.5,.5),y+random.uniform(-.5,.5),0),random.uniform(0.9,1.9))
# ---------- forge (locked, visible on the right side) ----------
F=Vector((7.6,3.2,0))
cyl(2.2,0.5,F+Vector((0,0,0.25)),stone2,8,0.08); tor(2.2,0.1,F+Vector((0,0,0.5)),emis("fr",(0.3,0.7,1),2),24,4)
steel=mat("steel",(0.32,0.34,0.46),rough=0.22,metal=0.9,coat=0.5)
box(F+Vector((0,0,1.9)),(2.0,0.8,0.45),steel); box(F+Vector((0,0,1.2)),(0.75,0.6,0.9),steel); box(F+Vector((0,0,0.7)),(1.3,0.8,0.2),steel)
bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=0.4,depth=1.1,location=F+Vector((-1.5,0,1.95)),rotation=(0,math.radians(-90),0)); bpy.context.object.data.materials.append(steel)
lockM=mat("lockM",(0.85,0.85,0.9),rough=0.3,metal=0.6); box(F+Vector((0,0,3.2)),(0.7,0.25,0.55),lockM); tor(0.28,0.08,F+Vector((0,0,3.6)),lockM,16,4,(math.radians(90),0,0))
# ---------- black hole gate (left back) ----------
G=Vector((-6.5,6.8,0))
tor(3.4,0.5,G+Vector((0,0,4.0)),brass,40,6,(math.radians(90),0,math.radians(30)))
voidm=mat("void",(0.01,0,0.03),rough=0.05,coat=1.0,emit=(0.35,0.1,0.9),estr=0.5)
bpy.ops.mesh.primitive_circle_add(vertices=40,radius=3.0,fill_type='NGON',location=G+Vector((0,0,4.0)),rotation=(math.radians(90),0,math.radians(30))); bpy.context.object.data.materials.append(voidm)
diskM=emis("disk",(0.75,0.4,1),3); tor(2.4,0.07,G+Vector((0,0,4.0)),diskM,40,4,(math.radians(90),0,math.radians(30)))
cyl(2.6,0.6,G+Vector((0,0,0.3)),stone2,8,0.1)
# ---------- next sector island + light bridge ----------
N=Vector((-14,56,6))
cyl(7,1,N,stone,20,0.25)
bpy.ops.mesh.primitive_cone_add(vertices=14,radius1=7,radius2=1,depth=7,location=N+Vector((0,0,-4)),rotation=(math.pi,0,0)); bpy.context.object.data.materials.append(rockm)
ice=mat("ice",(0.5,0.85,1),rough=0.1,emit=(0.3,0.7,1),estr=0.8)
for k in range(7): gemc(N+Vector((random.uniform(-5,5),random.uniform(-5,5),0.5)),random.uniform(1.5,3),None,ice)
ico(1.4,N+Vector((0,0,4)),mat("lockI",(0.3,0.3,0.4),rough=0.5),1)
bridgeM=emis("bridge",(0.5,0.4,1),1.2)
A=Vector((-4,10.5,0.2)); B=N+Vector((4,-6,0.5))
for k in range(18):
    t=k/17; q=A.lerp(B,t)+Vector((0,0,math.sin(t*math.pi)*3))
    box(q,(1.2,0.5,0.12),bridgeM,(0,0,math.atan2(B.y-A.y,B.x-A.x)),0)
# ---------- comets ----------
cometM=emis("cometM",(0.7,0.95,1),3)
def comet(head,dirv,ln):
    ico(0.45,head,mat("ch",(0.6,0.9,1),rough=0.1,emit=(0.4,0.8,1),estr=1.5),1)
    for k in range(10):
        t=k/10; ico(0.38*(1-t)+0.05,head-dirv.normalized()*t*ln,emis("ct%d"%random.randint(0,99999),(0.5+0.4*t,0.85,1),3*(1-t)+0.4),1)
comet(Vector((22,-14,16)),Vector((-1,-0.3,-0.35)),10)
comet(Vector((-26,-6,18)),Vector((1,-0.2,-0.3)),8)
# ---------- sky: star sphere + nebula blobs + galaxy plane far ----------
st=emis("st",(0.95,0.9,1),6)
bm2=bmesh.new()
for i in range(900):
    v=Vector((random.uniform(-1,1),random.uniform(-1,1),random.uniform(-0.6,1))).normalized()*random.uniform(80,100)
    if v.y<-40 and v.z<10: continue
    bmesh.ops.create_icosphere(bm2,subdivisions=0,radius=random.uniform(0.1,0.35),matrix=Matrix.Translation(v))
me=bpy.data.meshes.new("sky"); bm2.to_mesh(me); o=bpy.data.objects.new("sky",me); s.collection.objects.link(o); o.data.materials.append(st)
for (loc,r,c,stn) in [((-40,90,30),40,(0.35,0.12,0.7),0.6),((50,95,10),35,(0.15,0.3,0.7),0.5),((0,100,-10),50,(0.5,0.15,0.5),0.4)]:
    m=bpy.data.materials.new("neb"); m.use_nodes=True; nt=m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out=nt.nodes.new('ShaderNodeOutputMaterial'); vol=nt.nodes.new('ShaderNodeEmission'); vol.inputs['Color'].default_value=(*c,1); vol.inputs['Strength'].default_value=stn
    lw=nt.nodes.new('ShaderNodeLayerWeight'); lw.inputs['Blend'].default_value=0.5; tr=nt.nodes.new('ShaderNodeBsdfTransparent'); mx=nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(lw.outputs['Facing'],mx.inputs['Fac']); nt.links.new(vol.outputs[0],mx.inputs[1]); nt.links.new(tr.outputs[0],mx.inputs[2]); nt.links.new(mx.outputs[0],out.inputs[0]); m.blend_method='BLEND'
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r,location=loc); bpy.context.object.data.materials.append(m)
bpy.ops.mesh.primitive_plane_add(size=1,location=(10,120,40)); p=bpy.context.object; p.scale=(260,146,1); p.rotation_euler=(math.radians(80),0,0)
m=bpy.data.materials.new("gbg"); m.use_nodes=True; nt=m.node_tree
for n in list(nt.nodes): nt.nodes.remove(n)
tx=nt.nodes.new('ShaderNodeTexImage'); tx.image=bpy.data.images.load('/tmp/claude-0/blend/out/galaxybg.png'); em=nt.nodes.new('ShaderNodeEmission'); em.inputs['Strength'].default_value=0.7; out=nt.nodes.new('ShaderNodeOutputMaterial')
tr=nt.nodes.new('ShaderNodeBsdfTransparent'); ad=nt.nodes.new('ShaderNodeAddShader')
nt.links.new(tx.outputs['Color'],em.inputs['Color']); nt.links.new(em.outputs[0],ad.inputs[0]); nt.links.new(tr.outputs[0],ad.inputs[1]); nt.links.new(ad.outputs[0],out.inputs[0]); m.blend_method='BLEND'
p.data.materials.append(m)
gl=[n for n in s.node_tree.nodes if n.bl_idname=='CompositorNodeGlare'][0]; gl.threshold=0.9; gl.size=8; gl.mix=0.05
s.render.filepath="/tmp/claude-0/blend/out/map_concept_v3.png"; bpy.ops.render.render(write_still=True)
