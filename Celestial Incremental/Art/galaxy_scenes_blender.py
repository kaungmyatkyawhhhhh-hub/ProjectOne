import bpy, math, random, sys
exec(open('/tmp/claude-0/blend/icons.py').read().split("def i_stardust")[0])
OUT="/tmp/claude-0/blend/out/"
which = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
def ico(r,loc,m,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc); o=bpy.context.object; o.data.materials.append(m); return o
def rock():
    reset(); m=mat("rock",(0.36,0.33,0.40),rough=0.6,coat=0.2)
    o=ico(1.4,(0,0,0),m,2); random.seed(5)
    for v in o.data.vertices: v.co*=1+random.uniform(-0.18,0.14)
    c=mat("crack",(1.0,0.45,0.1),emit=(1.0,0.4,0.05),estr=1.5)
    ico(0.18,(0.4,-1.2,0.3),c,1); ico(0.12,(-0.5,-1.15,-0.4),c,1)
    render("rock")
def blackhole():
    reset(); core=mat("bh",(0.02,0.0,0.05),rough=0.15,coat=1.0)
    disk=mat("disk",(1.0,0.5,0.12),rough=0.3,emit=(1.0,0.4,0.06),estr=1.2)
    disk2=mat("disk2",(0.6,0.35,1.0),emit=(0.5,0.25,1.0),estr=1.0)
    ico(1.0,(0,0,0),core,3)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.9,minor_radius=0.32,major_segments=24,minor_segments=6); t=bpy.context.object; t.scale=(1,1,0.25); t.rotation_euler=(math.radians(14),math.radians(-12),0); t.data.materials.append(disk)
    bpy.ops.mesh.primitive_torus_add(major_radius=2.5,minor_radius=0.1,major_segments=24,minor_segments=4); t=bpy.context.object; t.scale=(1,1,0.25); t.rotation_euler=(math.radians(14),math.radians(-12),0); t.data.materials.append(disk2)
    render("blackhole")
def supernova():
    reset()
    core=mat("snc",(1.0,0.8,0.35),emit=(1.0,0.75,0.3),estr=2.2)
    sp=mat("sns",(1.0,0.45,0.08),rough=0.25,emit=(1.0,0.35,0.05),estr=0.8)
    sp2=mat("sns2",(1.0,0.75,0.2),rough=0.25,emit=(1.0,0.65,0.15),estr=0.9)
    ico(0.9,(0,0,0),core,2)
    random.seed(2)
    for i in range(18):
        a=i*2*math.pi/18+random.uniform(-.1,.1); L=random.uniform(1.4,2.6)
        bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=0.32,depth=L,location=(math.cos(a)*(0.6+L/2),0,math.sin(a)*(0.6+L/2)))
        c=bpy.context.object; c.rotation_euler=(0,-a+math.pi/2,0); c.data.materials.append(sp if i%2 else sp2)
    ring=mat("snr",(1.0,0.6,0.25),emit=(1.0,0.5,0.15),estr=1.0)
    bpy.ops.mesh.primitive_torus_add(major_radius=2.9,minor_radius=0.07,major_segments=40,minor_segments=4); t=bpy.context.object; t.rotation_euler=(math.radians(80),0,0); t.data.materials.append(ring)
    bpy.context.scene.camera.data.lens=58
    render("supernova")
def system():
    reset(); s=bpy.context.scene; s.camera.location=(0,-11,3.2); s.camera.rotation_euler=(math.radians(76),0,0); s.camera.data.lens=50
    core=mat("sc",(1.0,0.62,0.12),rough=0.3,emit=(1.0,0.45,0.05),estr=0.6,coat=0.4)
    ico(1.1,(0,0,0),core,2)
    orb=mat("orbit",(0.8,0.7,1.0),emit=(0.6,0.5,1.0),estr=0.8)
    cols=[(0.45,0.2,0.95),(0.2,0.75,1.0),(0.25,0.9,0.45),(1.0,0.35,0.45)]
    for i,(R,col,a) in enumerate([(2.2,cols[0],0.6),(3.1,cols[1],2.3),(4.0,cols[2],4.0),(4.9,cols[3],5.4)]):
        bpy.ops.mesh.primitive_torus_add(major_radius=R,minor_radius=0.025,major_segments=64,minor_segments=4); t=bpy.context.object; t.data.materials.append(orb)
        pm=mat("p%d"%i,col,rough=0.3,coat=0.6,emit=col,estr=0.15)
        ico(0.28+0.06*i,(math.cos(a)*R,math.sin(a)*R,0),pm,2)
    random.seed(9); st=mat("dust",(1.0,0.85,0.4),emit=(1.0,0.8,0.3),estr=4)
    for i in range(40):
        a=random.uniform(0,6.28); R=random.uniform(1.6,5.6); ico(random.uniform(0.03,0.07),(math.cos(a)*R,math.sin(a)*R,random.uniform(-0.3,0.3)),st,1)
    render("system")
def galaxybg():
    reset(); s=bpy.context.scene; s.render.film_transparent=False; s.render.resolution_x=1920; s.render.resolution_y=1080; s.cycles.samples=48
    s.world.node_tree.nodes['Background'].inputs[0].default_value=(0.01,0.006,0.02,1)
    s.camera.location=(0,-30,14); s.camera.rotation_euler=(math.radians(62),0,math.radians(0)); s.camera.data.lens=32
    for l in [o for o in s.objects if o.type=='LIGHT']: bpy.data.objects.remove(l)
    cols=[(0.6,0.3,1.0),(0.3,0.6,1.0),(1.0,0.5,0.8),(1.0,0.8,0.5)]
    mats=[mat("g%d"%i,c,emit=c,estr=6) for i,c in enumerate(cols)]
    core=mat("gc",(1,0.85,0.6),emit=(1,0.8,0.55),estr=12); ico(1.2,(0,0,0),core,2)
    random.seed(1)
    # instance via one mesh per star is heavy: build a single mesh of tiny tetrahedra
    import bmesh
    for mi,m in enumerate(mats):
        bm=bmesh.new()
        for i in range(700):
            arm=random.randint(0,2); t=random.uniform(0.2,1.0)**1.4
            ang=arm*2*math.pi/3 + t*4.2 + random.gauss(0,0.22)
            r=t*22+random.gauss(0,0.8)
            x,y=math.cos(ang)*r,math.sin(ang)*r; z=random.gauss(0,0.4)
            sz=random.uniform(0.04,0.14)*(1.4 if random.random()<0.05 else 1)
            bmesh.ops.create_icosphere(bm,subdivisions=0,radius=sz,matrix=__import__('mathutils').Matrix.Translation((x,y,z)))
        me=bpy.data.meshes.new("stars%d"%mi); bm.to_mesh(me); o=bpy.data.objects.new("stars%d"%mi,me); s.collection.objects.link(o); o.data.materials.append(m)
    nt=s.node_tree; gl=[n for n in nt.nodes if n.bl_idname=='CompositorNodeGlare'][0]; gl.threshold=0.3; gl.size=9; gl.mix=0.3
    s.render.filepath=OUT+"galaxybg.png"; bpy.ops.render.render(write_still=True)
F={"rock":rock,"blackhole":blackhole,"supernova":supernova,"system":system,"galaxybg":galaxybg}
for k in (which or F.keys()): F[k]()
