"""ortho view along a normal: blender -b --python ortho.py -- car.blend out.png cx,cy,cz nx,ny,nz width [hide_prefix]"""
import bpy, sys
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
sc = bpy.context.scene
c = Vector([float(v) for v in args[2].split(",")]); n = Vector([float(v) for v in args[3].split(",")]).normalized(); W = float(args[4])
hide = args[5] if len(args) > 5 else None
for o in bpy.data.objects:
    if o.type == "MESH" and (o.name.startswith("SteeringWheel") or (hide and o.name.startswith(hide))):
        o.hide_render = True
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.5
sc.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(bpy.types, "EEVEE_NEXT") else "CYCLES"
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 16; sc.cycles.use_denoising = True
pl = bpy.data.lights.new("p", "POINT"); pl.energy = 15; po = bpy.data.objects.new("p", pl); po.location = c + n * 0.25; sc.collection.objects.link(po)
cam = bpy.data.cameras.new("c"); cam.type = "ORTHO"; cam.ortho_scale = W; cam.clip_start = 0.001
co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
co.location = c + n * 0.12
co.rotation_euler = (-n).to_track_quat("-Z", "Z").to_euler()
sc.render.resolution_x = sc.render.resolution_y = 800
sc.render.filepath = args[1]
bpy.ops.render.render(write_still=True)
# report the camera's image axes in world space (for pixel -> world)
M = co.matrix_world.to_3x3()
print("AXES", tuple(round(v, 4) for v in M @ Vector((1, 0, 0))), tuple(round(v, 4) for v in M @ Vector((0, 1, 0))))
