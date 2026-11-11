import bpy, math, numpy as np
from mathutils import Vector
from PIL import Image
def setup():
    sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=24; sc.cycles.use_denoising=False
    sc.render.film_transparent=True; sc.view_settings.view_transform='Standard'
    w=bpy.data.worlds.get('W') or bpy.data.worlds.new('W'); w.use_nodes=True; sc.world=w
    bg=w.node_tree.nodes['Background']; bg.inputs[0].default_value=(1,1,1,1); bg.inputs[1].default_value=0.75
    if not bpy.data.objects.get('Key'):
        for nm,rot,e in [('Key',(math.radians(35),math.radians(15),math.radians(-20)),2.0),('Fill',(math.radians(-60),0,math.radians(160)),0.6)]:
            l=bpy.data.objects.new(nm,bpy.data.lights.new(nm,'SUN')); l.data.energy=e; l.rotation_euler=rot; sc.collection.objects.link(l)
    cam=bpy.data.objects.get('Cam') or bpy.data.objects.new('Cam',bpy.data.cameras.new('Cam'))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    sc.camera=cam; cam.data.type='ORTHO'; sc.render.resolution_x=1536; sc.render.resolution_y=1024
    return sc,cam
def render_side(path,S,NOSE,BASEZ):
    sc,cam=setup(); cam.data.ortho_scale=1536*S
    cam.location=((768-NOSE)*S,-20,(BASEZ-512)*S); cam.rotation_euler=(math.radians(90),0,0)
    sc.render.filepath=path; bpy.ops.render.render(write_still=True)
def render_top(path,S,NOSE,K,TX0,TY0):
    sc,cam=setup(); cam.data.ortho_scale=1536*S*K
    # image centre (768,512) in top px -> world
    cx=(63+(768-TX0)*K-NOSE)*S; cy=(512-TY0)*K*S
    cam.location=(cx,-cy,20); cam.rotation_euler=(0,0,0)   # looking down, image up = +y -> sheet down = -y
    sc.render.filepath=path; bpy.ops.render.render(write_still=True)
def render_front(path,S,FK,FX0,FY0):
    sc,cam=setup(); cam.data.ortho_scale=1536*S*FK
    cy=(768-FX0)*FK*S; cz=(300-(298+(512-FY0)*FK))*S
    cam.location=(20,cy,cz); cam.rotation_euler=(math.radians(90),0,math.radians(90))
    sc.render.filepath=path; bpy.ops.render.render(write_still=True)
