import bpy, os, sys, math
os.environ["STONE_DIR"]="/home/claude/work/stone"
bpy.ops.wm.read_factory_settings(use_empty=True)
exec(open(sys.argv[-1]).read())
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=24; sc.cycles.device='CPU'; sc.render.film_transparent=True
sc.view_settings.view_transform='Standard'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes["Background"].inputs[0].default_value=(1,1,1,1); w.node_tree.nodes["Background"].inputs[1].default_value=0.9
sun=bpy.data.objects.new("sun",bpy.data.lights.new("sun",'SUN')); sun.data.energy=2.0; sun.rotation_euler=(math.radians(50),0,math.radians(-30)); sc.collection.objects.link(sun)
cam=bpy.data.objects.new("cam",bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera=cam; cam.data.type='ORTHO'
S=0.01; WPX,HPX=640,660; sc.render.resolution_x=WPX; sc.render.resolution_y=HPX; cam.data.ortho_scale=HPX*S
zc=(650-340)*S     # the window is sheet y 10..670
views={"front":((0,-20,zc),(math.radians(90),0,0)),"side":((-20,0,zc),(math.radians(90),0,math.radians(-90))),"back":((0,20,zc),(math.radians(90),0,math.radians(180))),
       "q34":((-14,-14,zc+3),(math.radians(80),0,math.radians(-45)))}
for k,(loc,rot) in views.items():
    cam.location=loc; cam.rotation_euler=rot; sc.render.filepath=f"/home/claude/work/stone/r_{k}.png"; bpy.ops.render.render(write_still=True)
