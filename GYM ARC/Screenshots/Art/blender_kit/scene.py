import bpy, math, mathutils, sys, os
D=bpy.data; C=bpy.context
argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
SAMPLES=int(argv[0]) if argv else 32
RES=float(argv[1]) if len(argv)>1 else 0.5
OUT=argv[2] if len(argv)>2 else '/tmp/r.png'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.obj_import(filepath=os.path.abspath('hero.obj'))
drop=('Arrow','Wood','Trim','Seam','Base','Barjack','Chalk')
for o in list(C.scene.objects):
    if o.name.startswith(drop): D.objects.remove(o,do_unlink=True)
def mat(name,col,rough=0.45,spec=0.5,sss=0.0,metal=0.0,coat=0.0):
    m=D.materials.new(name); m.use_nodes=True; b=m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value=(*col,1); b.inputs['Roughness'].default_value=rough
    b.inputs['Metallic'].default_value=metal
    if 'Specular IOR Level' in b.inputs: b.inputs['Specular IOR Level'].default_value=spec
    if 'Coat Weight' in b.inputs: b.inputs['Coat Weight'].default_value=coat
    if sss>0 and 'Subsurface Weight' in b.inputs:
        b.inputs['Subsurface Weight'].default_value=sss; b.inputs['Subsurface Radius'].default_value=(0.3,0.12,0.06)
        b.inputs['Subsurface Scale'].default_value=0.05
    return m
def srgb(r,g,b): return tuple(((c/255)**2.2) for c in (r,g,b))
SKIN=mat('skin',srgb(232,180,140),0.38,0.6,0.15,coat=0.15)
SHIRT=mat('shirt',srgb(245,245,248),0.75,0.3)
SHORTS=mat('shorts',srgb(28,28,34),0.6,0.4)
PLATE=mat('plate',srgb(220,30,30),0.25,0.6,coat=0.6)
METAL=mat('metal',srgb(200,200,205),0.18,0.8,metal=1.0)
DARK=mat('dark',srgb(30,30,32),0.4,0.5)
for o in C.scene.objects:
    if o.type!='MESH': continue
    n=o.name.lower(); o.data.materials.clear()
    if 'uppertorso' in n: m=SHIRT
    elif 'shorts' in n or 'waist' in n: m=SHORTS
    elif any(k in n for k in ('arm','leg','hand','foot','head','calves','skin')): m=SKIN
    elif n.startswith(('body','rim')): m=PLATE
    elif n.startswith(('hub','hole')): m=METAL
    elif n.startswith(('bar','sleeve','collar','endcap','clamp')): m=METAL
    else: m=DARK
    o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth=True
# head: hide exported head, make a classic head
head=D.objects.get('Head1')
hc=head.matrix_world @ (sum((mathutils.Vector(c) for c in head.bound_box),mathutils.Vector())/8)
hd=head.dimensions.copy()
D.objects.remove(head,do_unlink=True)
bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=0.64,depth=1.25,location=hc+mathutils.Vector((0,0,-0.08)))
h=C.active_object; h.name='ClassicHead'
bv=h.modifiers.new('bv','BEVEL'); bv.width=0.42; bv.segments=12; bv.limit_method='NONE'
bpy.ops.object.shade_smooth(); h.data.materials.append(SKIN)
# face: curved plane in front (+X)
fm=D.materials.new('face'); fm.use_nodes=True; nt=fm.node_tree; b=nt.nodes['Principled BSDF']
tex=nt.nodes.new('ShaderNodeTexImage'); tex.image=D.images.load(os.path.abspath('face.png'))
nt.links.new(tex.outputs['Color'],b.inputs['Base Color']); nt.links.new(tex.outputs['Alpha'],b.inputs['Alpha'])
b.inputs['Roughness'].default_value=0.5
fm.blend_method='BLEND' if hasattr(fm,'blend_method') else None
bpy.ops.mesh.primitive_plane_add(size=1.0,location=hc+mathutils.Vector((0.645,0,-0.1)))
f=C.active_object; f.rotation_euler=(math.radians(90),0,math.radians(90))
f.data.materials.append(fm)
bpy.ops.object.modifier_add(type='SUBSURF'); f.modifiers[-1].levels=3; f.modifiers[-1].subdivision_type='SIMPLE'
sd=f.modifiers.new('bend','SIMPLE_DEFORM'); sd.deform_method='BEND'; sd.angle=math.radians(-100); sd.deform_axis='Y'
# lights
def area(name,loc,rot,size,energy,col):
    L=D.lights.new(name,'AREA'); L.size=size; L.energy=energy; L.color=col
    o=D.objects.new(name,L); C.scene.collection.objects.link(o); o.location=loc
    o.rotation_euler=rot; return o
def look(o,target):
    d=(mathutils.Vector(target)-o.location); o.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
cx,cy,cz=-20.3,19.9,3.2
key=area('key',(cx+7,cy-2.5,cz+4),(0,0,0),4,1400,(1.0,0.86,0.72)); look(key,(cx,cy,cz))
fill=area('fill',(cx+6,cy+4,cz+0.5),(0,0,0),5,250,(0.75,0.8,1.0)); look(fill,(cx,cy,cz))
rimL=area('rimL',(cx-3.5,cy-4.5,cz+3),(0,0,0),2.5,1600,(0.62,0.32,1.0)); look(rimL,(cx,cy,cz+0.5))
rimR=area('rimR',(cx-3.5,cy+4.5,cz+3),(0,0,0),2.5,1600,(0.62,0.32,1.0)); look(rimR,(cx,cy,cz+0.5))
top=area('top',(cx+0.5,cy,cz+6),(0,0,0),3,500,(1,0.6,0.85)); look(top,(cx,cy,cz))
# world dark purple
w=D.worlds.new('w'); C.scene.world=w; w.use_nodes=True
w.node_tree.nodes['Background'].inputs['Color'].default_value=(0.03,0.012,0.06,1)
w.node_tree.nodes['Background'].inputs['Strength'].default_value=0.6
# camera: low, front, wide
cam=D.cameras.new('cam'); cam.lens=26
co=D.objects.new('cam',cam); C.scene.collection.objects.link(co)
co.location=(cx+7.9,cy-1.7,cz-1.35); look(co,(cx,cy+0.45,cz+1.0)); C.scene.camera=co
s=C.scene; s.render.engine='CYCLES'; s.cycles.samples=SAMPLES; s.cycles.use_denoising=False
s.cycles.device='CPU'; s.render.film_transparent=True
s.render.resolution_x=1920; s.render.resolution_y=1080; s.render.resolution_percentage=int(RES*100)
s.view_settings.view_transform='Filmic' if 'Filmic' in [v.identifier for v in s.view_settings.bl_rna.properties['view_transform'].enum_items] else 'Standard'
s.view_settings.look='Filmic - Medium High Contrast' if s.view_settings.view_transform=='Filmic' else 'None'
s.render.filepath=OUT
bpy.ops.render.render(write_still=True)
print('DONE',OUT)
