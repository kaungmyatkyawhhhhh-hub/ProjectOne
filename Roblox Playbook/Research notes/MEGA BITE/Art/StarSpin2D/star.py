import bpy, bmesh, math, sys
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True); sc=bpy.context.scene
# a puffy 5-point star: flat star outline, extruded, heavy bevel, then subdivided + smoothed so it reads chunky and toy-like
R1,R2,N=1.0,0.48,5
pts=[]
for i in range(2*N):
    r=R1 if i%2==0 else R2; a=math.pi/2+i*math.pi/N
    pts.append((r*math.cos(a),r*math.sin(a)))
me=bpy.data.meshes.new('star'); ob=bpy.data.objects.new('star',me); sc.collection.objects.link(ob)
bm=bmesh.new()
# a raised centre: fan from front/back centre points, so the star has a ridge to each tip (classic 3D reward star)
D=0.28
fc=bm.verts.new((0,0,D)); bc=bm.verts.new((0,0,-D))
rim=[bm.verts.new((x,y,0)) for x,y in pts]
for i in range(2*N):
    a,b=rim[i],rim[(i+1)%(2*N)]
    bm.faces.new((fc,a,b)); bm.faces.new((bc,b,a))
bm.to_mesh(me); bm.free()
bv=ob.modifiers.new('bv','BEVEL'); bv.width=0.07; bv.segments=4; bv.limit_method='ANGLE'; bv.angle_limit=math.radians(25)
ss=ob.modifiers.new('ss','SUBSURF'); ss.levels=1; ss.render_levels=1
for p in me.polygons: p.use_smooth=False
# gold: warm yellow, a bit metallic, low roughness for crisp highlights
mat=bpy.data.materials.new('gold'); mat.use_nodes=True; bs=mat.node_tree.nodes['Principled BSDF']
bs.inputs['Base Color'].default_value=(1.0,0.66,0.06,1); bs.inputs['Metallic'].default_value=0.55; bs.inputs['Roughness'].default_value=0.22
try: bs.inputs['Coat Weight'].default_value=0.6; bs.inputs['Coat Roughness'].default_value=0.05
except Exception: pass
me.materials.append(mat)
# lights: big soft key from top-left, warm fill, rim from behind
def area(name,loc,energy,size,col=(1,1,1)):
    l=bpy.data.lights.new(name,'AREA'); l.energy=energy; l.size=size; l.color=col
    o=bpy.data.objects.new(name,l); sc.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector((0,0,0))-Vector(loc)).to_track_quat('-Z','Y').to_euler(); return o
area('key',(-2.5,3,4),900,3); area('fill',(3,-1,3),250,4,(1,0.85,0.6)); area('rim',(0,1.5,-4),500,3,(1,0.95,0.8))
w=bpy.data.worlds.new('W'); sc.world=w; w.use_nodes=True
bg=w.node_tree.nodes['Background']; bg.inputs['Color'].default_value=(0.9,0.75,0.5,1); bg.inputs['Strength'].default_value=0.6
cam=bpy.data.cameras.new('C'); co=bpy.data.objects.new('C',cam); sc.collection.objects.link(co); sc.camera=co
cam.type='ORTHO'; cam.ortho_scale=2.5; co.location=(0,0,10); co.rotation_euler=(0,0,0)
sc.render.engine='CYCLES'; sc.cycles.samples=48; sc.cycles.device='CPU'
sc.render.film_transparent=True; sc.render.resolution_x=sc.render.resolution_y=256
sc.view_settings.view_transform='Standard'; sc.view_settings.look='None'
NF=int(sys.argv[-1]) if sys.argv[-1].isdigit() else 16
for f in range(NF):
    t=f/NF
    # a full turn on a tilted axis (coin-spin with a little wobble), so it reads as a solid 3D star in every frame
    ob.rotation_euler=(math.radians(18)*math.sin(t*2*math.pi), t*math.pi, math.radians(-8))
    sc.render.filepath=f'/tmp/claude-0/star2d/f{f:02d}.png'; bpy.ops.render.render(write_still=True)
