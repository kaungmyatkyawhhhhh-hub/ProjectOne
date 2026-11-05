"""Render a cluster from the original .glb (keeps its second UV set, so glow pictures land right).
   blender -b --python glb_view.py -- car.blend car.glb out [up,back,lens,clip]"""
import bpy, sys, json
from mathutils import Vector, Matrix
a=sys.argv[sys.argv.index("--")+1:]
blend,glb,out=a[0],a[1],a[2]
up,back,lens,clip=[float(v) for v in (a[3] if len(a)>3 else "0.10,0.25,42,0.33").split(",")]
rep=json.load(open(blend+".json")); c=Vector(rep["steering"]["centre"])
def bbox():
    lo,hi=Vector((1e9,)*3),Vector((-1e9,)*3)
    for o in bpy.data.objects:
        if o.type!="MESH": continue
        for v in o.bound_box:
            p=o.matrix_world@Vector(v); lo=Vector(map(min,lo,p)); hi=Vector(map(max,hi,p))
    return lo,hi
bpy.ops.wm.open_mainfile(filepath=blend)
lo0,hi0=bbox()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
bpy.context.view_layer.update()
for o in list(bpy.data.objects):
    if o.type=="MESH" and max(o.dimensions)>0.2:
        print("GV stray",o.name,o.dimensions); bpy.data.objects.remove(o)
bpy.context.view_layer.update()
lo1,hi1=bbox()
print("GV bbox blend",lo0,hi0); print("GV bbox glb",lo1,hi1)
d0,d1=hi0-lo0,hi1-lo1
s=d0.y/d1.y
# compare orientation: dims must match after scaling
print("GV scale",s,"dims",d1*s,d0)
root=bpy.data.objects.new("root",None); bpy.context.scene.collection.objects.link(root)
for o in list(bpy.data.objects):
    if o is not root and o.parent is None: o.parent=root
root.matrix_world=Matrix.Scale(s,4)
bpy.context.view_layer.update()
lo2,hi2=bbox()
root.location=(lo0+hi0)/2-(lo2+hi2)/2
bpy.context.view_layer.update()
sc=bpy.context.scene
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True
w.node_tree.nodes["Background"].inputs[0].default_value=(0.8,0.84,0.9,1)
sc.render.engine="CYCLES"; sc.cycles.device="CPU"; sc.cycles.samples=48; sc.cycles.use_denoising=True
sc.render.image_settings.file_format="PNG"
sc.render.resolution_x,sc.render.resolution_y=1400,800
cam=bpy.data.cameras.new("c"); co=bpy.data.objects.new("cam",cam); sc.collection.objects.link(co); sc.camera=co
lamp=bpy.data.lights.new("l","POINT"); lamp.energy=10; lo=bpy.data.objects.new("l",lamp); sc.collection.objects.link(lo)
target=c+Vector((0,-back,up)); eye=target+Vector((0,0.46,0.12))
cam.lens=lens; cam.clip_start=clip; co.location=eye
co.rotation_euler=(target-eye).normalized().to_track_quat("-Z","Y").to_euler()
lo.location=eye+Vector((0,0.04,0.05))
sc.render.filepath=out+"_lit.png"
bpy.ops.render.render(write_still=True)
print("GV done",out)
# the steering wheel from the driver's eye, same shot as cluster_close.py
sc.render.resolution_x,sc.render.resolution_y=900,750
eye=c+Vector((0,0.62,0.10))
cam.lens=35; cam.clip_start=0.05; co.location=eye
co.rotation_euler=(c-eye).normalized().to_track_quat("-Z","Y").to_euler()
lo.location=eye+Vector((0,0.04,0.05))
sc.render.filepath=out+"_sw.png"
bpy.ops.render.render(write_still=True)
