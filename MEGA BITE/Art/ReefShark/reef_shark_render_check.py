import bpy, math
from mathutils import Vector
exec(open('/home/claude/megabite_art/reef_shark_v4.py').read(), {"__name__":"x","WITH_RIG":False})
sc=bpy.context.scene
for o in [o for o in sc.objects if o.type=="LIGHT"]: bpy.data.objects.remove(o)
w=sc.world; bg=w.node_tree.nodes["Background"]; bg.inputs[0].default_value=(0.8,0.82,0.85,1); bg.inputs[1].default_value=0.6
def sun(rot,e):
    ld=bpy.data.lights.new("s","SUN"); ld.energy=e; ld.angle=0.2; o=bpy.data.objects.new("s",ld); sc.collection.objects.link(o); o.rotation_euler=rot
sun((math.radians(35),math.radians(-15),math.radians(20)),3.6); sun((math.radians(120),0,math.radians(-60)),0.8)
sc.render.engine="CYCLES"; sc.cycles.samples=24; sc.cycles.use_denoising=True; sc.view_settings.view_transform="Standard"
sc.render.film_transparent=True
cam=bpy.data.objects.new("C",bpy.data.cameras.new("C")); sc.collection.objects.link(cam); sc.camera=cam; cam.data.type="ORTHO"
def shot(name,loc,rot,scale,w,h):
    sc.render.resolution_x,sc.render.resolution_y=w,h
    cam.location=loc; cam.rotation_euler=rot; cam.data.ortho_scale=scale
    sc.render.filepath=f"/home/claude/megabite_art/v3/r_{name}.png"; bpy.ops.render.render(write_still=True)
shot("side",(0.15,-10,0),(math.radians(90),0,0),5.2,1000,560)
shot("top",(0.15,0,10),(0,0,0),5.2,1000,560)
shot("front",(10,0,0),(math.radians(90),0,math.radians(90)),3.0,600,600)
sc.render.film_transparent=False; cam.data.type="PERSP"; cam.data.lens=50
sc.render.resolution_x,sc.render.resolution_y=1000,620
for nm,pos in (("34",(5.5,-5.0,1.6)),):
    cam.location=pos; d=Vector((0.3,0,0))-Vector(pos); cam.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=f"/home/claude/megabite_art/v3/r_{nm}.png"; bpy.ops.render.render(write_still=True)
