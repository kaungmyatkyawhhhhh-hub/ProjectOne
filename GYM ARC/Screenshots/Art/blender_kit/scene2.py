import bpy, math, mathutils, sys, os, random, bmesh
from mathutils import Vector, Matrix
D=bpy.data; C=bpy.context
a=sys.argv[sys.argv.index('--')+1:]
MODE=a[0]; SAMPLES=int(a[1]); RES=float(a[2]); OUT=os.path.abspath(a[3])
random.seed(5)
bpy.ops.wm.read_factory_settings(use_empty=True)
here=os.path.dirname(os.path.abspath(__file__))
def imp(fn):
    before=set(D.objects); bpy.ops.wm.obj_import(filepath=os.path.join(here,fn)); return [o for o in D.objects if o not in before]
hero=imp('hero2.obj')
env=imp('hof.obj' if MODE=='hof' else 'gym.obj')
for o in list(hero):
    if o.name.lower().startswith(('tbbase','tbtrim','tbwood','tbseam','tbbarjack','tbchalk')):
        hero.remove(o); D.objects.remove(o,do_unlink=True)
def srgb(r,g,b): return tuple(((c/255)**2.2) for c in (r,g,b))
def pbsdf(m): return m.node_tree.nodes['Principled BSDF']
def mat(name,col,rough=0.45,spec=0.5,metal=0.0,coat=0.0,coatr=0.05,sss=0.0):
    m=D.materials.new(name); m.use_nodes=True; b=pbsdf(m)
    b.inputs['Base Color'].default_value=(*col,1); b.inputs['Roughness'].default_value=rough
    b.inputs['Metallic'].default_value=metal; b.inputs['Specular IOR Level'].default_value=spec
    b.inputs['Coat Weight'].default_value=coat; b.inputs['Coat Roughness'].default_value=coatr
    if sss: 
        b.inputs['Subsurface Weight'].default_value=sss; b.inputs['Subsurface Radius'].default_value=(0.3,0.12,0.06); b.inputs['Subsurface Scale'].default_value=0.04
    return m
SKIN=mat('skin',srgb(236,184,140),0.36,0.6,coat=0.25,coatr=0.25,sss=0.12)
SHIRT=mat('shirt',srgb(246,246,250),0.7,0.3)
SHORTS=mat('shorts',srgb(24,24,30),0.5,0.5,coat=0.2)
PLATE=mat('plate',srgb(215,18,24),0.12,0.7,coat=1.0,coatr=0.02)
CHROME=mat('chrome',srgb(235,235,240),0.06,1.0,metal=1.0)
def texmat(o):
    # keep imported texture but make it nicer
    for s in o.material_slots:
        m=s.material
        if not m or not m.use_nodes: continue
        b=pbsdf(m); b.inputs['Roughness'].default_value=0.5; b.inputs['Specular IOR Level'].default_value=0.4
        b.inputs['Emission Strength'].default_value=0.0
        m.blend_method='HASHED' if hasattr(m,'blend_method') else None
for o in hero:
    n=o.name.lower()
    if o.type!='MESH': continue
    for p in o.data.polygons: p.use_smooth=True
    if n.startswith('accmesh'): texmat(o); continue
    o.data.materials.clear()
    if 'uppertorso' in n: m=SHIRT
    elif 'shorts' in n or 'waist' in n: m=SHORTS
    elif n.startswith('tb'):
        m=PLATE if any(k in n for k in ('body','rim')) else CHROME
    else: m=SKIN
    o.data.materials.append(m)
# environment materials: kill imported emission, slightly glossier floors
for o in env:
    if o.type!='MESH': continue
    for s in o.material_slots:
        m=s.material
        if m and m.use_nodes:
            b=pbsdf(m)
            if b: b.inputs['Emission Strength'].default_value=0.0
for m in D.materials:
    if not m.use_nodes: continue
    for n in list(m.node_tree.nodes):
        if n.type=='TEX_IMAGE':
            if n.image is None or not os.path.exists(bpy.path.abspath(n.image.filepath)): m.node_tree.nodes.remove(n)
# --- place hero
root=Vector((-20.64,19.9,3.99))
if MODE=='hof':
    M=Matrix.Translation(Vector((0,-86,3.99)))@Matrix.Rotation(math.radians(90),4,'Z')@Matrix.Translation(-root)
    for o in hero: o.matrix_world=M@o.matrix_world
    root=Vector((0,-86,3.99)); fwd=Vector((0,1,0)); side=Vector((-1,0,0))
else:
    fwd=Vector((1,0,0)); side=Vector((0,1,0))
C.view_layer.update()
# --- AURA (Sol's RNG style: spirals, rings, sparkles, glow)
AC={'hof':((1.0,0.72,0.15),(1.0,0.95,0.6)),'gym':((0.55,0.2,1.0),(0.3,0.85,1.0))}[MODE]
def emis(name,col,strength):
    m=D.materials.new(name); m.use_nodes=True; nt=m.node_tree; nt.nodes.clear()
    o=nt.nodes.new('ShaderNodeOutputMaterial'); e=nt.nodes.new('ShaderNodeEmission'); e.inputs['Color'].default_value=(*col,1); e.inputs['Strength'].default_value=strength
    nt.links.new(e.outputs[0],o.inputs[0]); return m
E1=emis('aura1',AC[0],4); E2=emis('aura2',AC[1],6); E3=emis('spark',(1,1,0.95),10)
cz=root.z+0.6
def helix(name,r0,r1,h0,h1,turns,phase,depth,mat_):
    cu=D.curves.new(name,'CURVE'); cu.dimensions='3D'; sp=cu.splines.new('NURBS'); N=120
    sp.points.add(N-1)
    for i in range(N):
        t=i/(N-1); ang=phase+t*turns*2*math.pi; r=r0+(r1-r0)*t
        p=root+fwd*(math.cos(ang)*r)+side*(math.sin(ang)*r)+Vector((0,0,h0+(h1-h0)*t))
        sp.points[i].co=(p.x,p.y,p.z,1)
    sp.use_endpoint_u=True; sp.order_u=4
    cu.bevel_depth=depth; cu.bevel_resolution=3
    # taper ends
    o=D.objects.new(name,cu); C.scene.collection.objects.link(o); o.data.materials.append(mat_)
    tp=D.curves.new(name+'_tp','CURVE'); s2=tp.splines.new('BEZIER'); s2.bezier_points.add(2)
    for i,(x,y) in enumerate([(0,0),(0.5,1),(1,0)]): bp=s2.bezier_points[i]; bp.co=(x,y,0); bp.handle_left_type=bp.handle_right_type='AUTO'
    to=D.objects.new(name+'_tpo',tp); C.scene.collection.objects.link(to); to.hide_render=True; cu.taper_object=to
    return o
def arc(name,r,h0,h1,a0,a1,depth,mat_,wob=0.0):
    cu=D.curves.new(name,'CURVE'); cu.dimensions='3D'; sp=cu.splines.new('NURBS'); N=80
    sp.points.add(N-1)
    for i in range(N):
        t=i/(N-1); ang=math.radians(a0+(a1-a0)*t); rr=r+wob*math.sin(t*9)
        p=root+fwd*(math.cos(ang)*rr)+side*(math.sin(ang)*rr)+Vector((0,0,h0+(h1-h0)*t))
        sp.points[i].co=(p.x,p.y,p.z,1)
    sp.use_endpoint_u=True; sp.order_u=4; cu.bevel_depth=depth; cu.bevel_resolution=3
    o=D.objects.new(name,cu); C.scene.collection.objects.link(o); o.data.materials.append(mat_)
    tp=D.curves.new(name+'_tp','CURVE'); s2=tp.splines.new('BEZIER'); s2.bezier_points.add(2)
    for i,(x,y) in enumerate([(0,0),(0.4,1),(1,0)]): bp=s2.bezier_points[i]; bp.co=(x,y,0); bp.handle_left_type=bp.handle_right_type='AUTO'
    to=D.objects.new(name+'_tpo',tp); C.scene.collection.objects.link(to); to.hide_render=True; cu.taper_object=to
# rising arcs that wrap the BACK half (front stays clear so the face/body read)
for k in range(9):
    a0=random.uniform(60,110); a1=random.uniform(250,300)
    if k%2: a0,a1=a1,a0
    h0=random.uniform(-3,2.5); arc('arc%d'%k,random.uniform(2.2,3.4),h0,h0+random.uniform(1.5,4),a0,a1,random.choice([0.02,0.03,0.045]),E1 if k%3 else E2,0.15)
# halo ring behind the upper back + one low ring
bpy.ops.mesh.primitive_torus_add(major_radius=2.6,minor_radius=0.035,major_segments=160,minor_segments=8,location=root-fwd*1.6+Vector((0,0,2.6)))
t=C.active_object; t.rotation_euler=(fwd.to_track_quat('Z','Y').to_euler()); t.data.materials.append(E2)
bpy.ops.mesh.primitive_torus_add(major_radius=2.25,minor_radius=0.02,major_segments=160,minor_segments=8,location=root-fwd*1.7+Vector((0,0,2.6)))
t=C.active_object; t.rotation_euler=(fwd.to_track_quat('Z','Y').to_euler()); t.data.materials.append(E1)
# sparkles around + behind
bm=bmesh.new()
for i in range(500):
    ang=random.uniform(0,2*math.pi)
    if math.cos(ang)>0.55 and random.random()<0.85: continue
    r=random.uniform(1.8,4.6); h=random.uniform(-3.5,7)
    p=root+fwd*(math.cos(ang)*r)+side*(math.sin(ang)*r)+Vector((0,0,h))
    sz=random.choice([0.015,0.02,0.025,0.035,0.05])
    bmesh.ops.create_icosphere(bm,subdivisions=1,radius=sz,matrix=Matrix.Translation(p))
me=D.meshes.new('sparks'); bm.to_mesh(me); so=D.objects.new('sparks',me); C.scene.collection.objects.link(so); so.data.materials.append(E3)
if MODE=='hof':
    bm2=bmesh.new()
    for i in range(260):
        p=root+fwd*random.uniform(-6,5)+side*random.uniform(-9,9)+Vector((0,0,random.uniform(-1,9)))
        mtx=Matrix.Translation(p)@Matrix.Rotation(random.uniform(0,6.3),4,'X')@Matrix.Rotation(random.uniform(0,6.3),4,'Y')
        g=bmesh.ops.create_grid(bm2,x_segments=1,y_segments=1,size=random.uniform(0.05,0.1),matrix=mtx)
    mc=D.meshes.new('confetti'); bm2.to_mesh(mc); oc=D.objects.new('confetti',mc); C.scene.collection.objects.link(oc)
    GOLD=mat('gold',srgb(255,200,60),0.2,0.8,metal=1.0); oc.data.materials.append(GOLD)
    WHITE=mat('cw',srgb(255,255,255),0.4,0.5); RED=mat('cr',srgb(230,40,40),0.4,0.5)
    oc.data.materials.append(WHITE); oc.data.materials.append(RED)
    for i,poly in enumerate(oc.data.polygons): poly.material_index=random.choice([0,0,0,1,2])
# aura light on hero
def pl(loc,col,w,r=1.5):
    L=D.lights.new('pl','POINT'); L.energy=w; L.color=col; L.shadow_soft_size=r
    o=D.objects.new('pl',L); C.scene.collection.objects.link(o); o.location=loc
for k in range(6):
    ang=k/6*2*math.pi; pl(root+fwd*(math.cos(ang)*2.6)+side*(math.sin(ang)*2.6)+Vector((0,0,1.5)),AC[0],70)
# --- studio lights
def area(name,loc,target,size,energy,col):
    L=D.lights.new(name,'AREA'); L.size=size; L.energy=energy; L.color=col
    o=D.objects.new(name,L); C.scene.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler(); return o
tgt=root+Vector((0,0,0.8))
area('key',root+fwd*7+side*(-3)+Vector((0,0,5)),tgt,4,(2200 if MODE=='hof' else 1500),(1,0.9,0.8))
area('fill',root+fwd*6+side*4+Vector((0,0,1)),tgt,6,500,(0.75,0.82,1))
rim=(1.0,0.75,0.3) if MODE=='hof' else (0.6,0.3,1.0)
area('rimL',root-fwd*3.5+side*(-4)+Vector((0,0,3.5)),tgt,2.5,3200,rim)
area('rimR',root-fwd*3.5+side*4+Vector((0,0,3.5)),tgt,2.5,3200,rim)
area('top',root+Vector((0,0,7)),tgt,3,(900 if MODE=='hof' else 350),(1,0.95,0.9))
# softboxes for reflections on the weights (not seen by camera)
for sgn in (-1,1):
    bpy.ops.mesh.primitive_plane_add(size=4,location=root+fwd*5+side*(sgn*7)+Vector((0,0,4)))
    p=C.active_object; p.rotation_euler=(Vector(tgt)-p.location).to_track_quat('Z','Y').to_euler()
    p.data.materials.append(emis('soft',(1,1,1),6)); p.visible_camera=False
# world
w=D.worlds.new('w'); C.scene.world=w; w.use_nodes=True
bg=w.node_tree.nodes['Background']
bg.inputs['Color'].default_value=(0.95,0.55,0.28,1) if MODE=='hof' else (0.05,0.02,0.1,1); bg.inputs['Strength'].default_value=0.9 if MODE=='hof' else 0.15
# env lights for the gym/hall
if MODE=='gym':
    area('gymback',root-fwd*14+Vector((0,0,9)),root-fwd*14,14,2500,(0.55,0.3,1.0))
else:
    area('sun1',root+Vector((0,-30,0))*0+Vector((10,8,25)),root+Vector((0,25,8)),20,9000,(1,0.85,0.6))
    L=D.lights.new('sun','SUN'); L.energy=3.0; L.color=(1,0.88,0.7); so2=D.objects.new('sun',L); C.scene.collection.objects.link(so2); so2.rotation_euler=(math.radians(55),0,math.radians(200))
# camera
cam=D.cameras.new('cam'); cam.lens=24; cam.dof.use_dof=True; cam.dof.aperture_fstop=2.2
co=D.objects.new('cam',cam); C.scene.collection.objects.link(co)
co.location=root+fwd*8.2+side*(0.6)+Vector((0,0,-1.7))
look=root+side*(-1.5)+Vector((0,0,1.25))
co.rotation_euler=(look-co.location).to_track_quat('-Z','Y').to_euler(); C.scene.camera=co
cam.dof.focus_distance=(root-co.location).length-0.6
s=C.scene; s.render.engine='CYCLES'; s.cycles.samples=SAMPLES; s.cycles.use_adaptive_sampling=True; s.cycles.adaptive_threshold=0.03
s.cycles.use_denoising=False; s.cycles.max_bounces=6; s.cycles.caustics_reflective=False; s.cycles.caustics_refractive=False
s.cycles.blur_glossy=1.0
s.render.resolution_x=1920; s.render.resolution_y=1080; s.render.resolution_percentage=int(RES*100)
s.view_settings.view_transform='Filmic'; s.view_settings.look='Medium High Contrast'
# compositor glow
s.use_nodes=True; nt=s.node_tree; nt.nodes.clear()
rl=nt.nodes.new('CompositorNodeRLayers'); g=nt.nodes.new('CompositorNodeGlare'); g.glare_type='FOG_GLOW'; g.quality='HIGH'; g.threshold=1.6; g.size=8; g.mix=-0.4
g2=nt.nodes.new('CompositorNodeGlare'); g2.glare_type='STREAKS'; g2.streaks=4; g2.threshold=6.0; g2.mix=-0.85; g2.fade=0.9
out=nt.nodes.new('CompositorNodeComposite')
nt.links.new(rl.outputs['Image'],g.inputs['Image']); nt.links.new(g.outputs['Image'],g2.inputs['Image']); nt.links.new(g2.outputs['Image'],out.inputs['Image'])
s.render.filepath=OUT
bpy.ops.render.render(write_still=True)
print('DONE',OUT)
