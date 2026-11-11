import bpy, sys, math
from mathutils import Vector
def render_views(objs,path,res=512):
    sc=bpy.context.scene
    sc.render.engine='CYCLES'; sc.cycles.samples=12; sc.cycles.device='CPU'; sc.cycles.use_denoising=False
    sc.world=sc.world or bpy.data.worlds.new('w'); sc.world.use_nodes=True
    bg=sc.world.node_tree.nodes['Background']; bg.inputs[0].default_value=(0.8,0.85,0.95,1); bg.inputs[1].default_value=0.8
    sc.render.film_transparent=True
    sc.view_settings.view_transform='Standard'
    if not bpy.data.objects.get('Sun'):
        s=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN')); sc.collection.objects.link(s)
        s.data.energy=2.2; s.rotation_euler=(math.radians(40),math.radians(-25),math.radians(-30))
    sc.render.resolution_x=res*2; sc.render.resolution_y=res
    # bounds
    mn=Vector((1e9,)*3); mx=Vector((-1e9,)*3)
    for o in objs:
        for c in o.bound_box:
            w=o.matrix_world@Vector(c); mn=Vector(map(min,mn,w)); mx=Vector(map(max,mx,w))
    ctr=(mn+mx)/2; size=max(mx-mn)*1.15
    cam=bpy.data.objects.get('Cam') or bpy.data.objects.new('Cam',bpy.data.cameras.new('Cam'))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    sc.camera=cam; cam.data.type='ORTHO'; cam.data.ortho_scale=size*2
    out=[]
    for nm,pos,rot in [('front',ctr+Vector((0,-50,0)),(math.radians(90),0,0)),('top',ctr+Vector((0,0,50)),(0,0,0)),('q',ctr+Vector((35,-35,25)),None)]:
        cam.location=pos
        if rot: cam.rotation_euler=rot
        else:
            d=(ctr-pos).normalized(); cam.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
        cam.data.ortho_scale=size*2
        sc.render.filepath=f'/home/claude/megabite_art/kit/{path}_{nm}.png'; bpy.ops.render.render(write_still=True); out.append(sc.render.filepath)
    return out
