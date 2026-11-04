# Render one shot of Thumbs_Nov.blend: blender -b Thumbs_Nov.blend -P render_shot.py -- <shot> <out.png> <scale%> <samples>
import bpy, sys
argv = sys.argv[sys.argv.index("--") + 1:]
shot, out, pct, samples = argv[0], argv[1], int(argv[2]), int(argv[3])
scene = bpy.data.scenes["Thumbs_Nov"]
A, B = bpy.data.collections["SHOT_A_icon_thumb2"], bpy.data.collections["SHOT_B_thumb1"]
A.hide_render = shot == "thumb1"; B.hide_render = shot != "thumb1"
spark = bpy.data.collections["Sparks"]; spark.hide_render = shot == "icon" or shot == "thumb1"
scene.camera = bpy.data.objects["CAM_" + shot]
flex = bpy.data.objects["GIANT_7ft_flex_ROOT"]
if shot == "icon":
    flex.location = (0.0, -5.0, 0.0); flex.scale = (1.3, 1.3, 1.3)
elif shot == "thumb2":
    flex.location = (0.4, -5.5, 0.0); flex.scale = (1.9, 1.9, 1.9)
if shot == "icon":
    scene.render.resolution_x = scene.render.resolution_y = 1024
else:
    scene.render.resolution_x, scene.render.resolution_y = 1920, 1080
scene.render.resolution_percentage = pct
for o in bpy.data.objects:
    if o.name.startswith("GymLamp"): o.hide_render = True
scene.cycles.samples = samples
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    prefs.compute_device_type = "CUDA"; prefs.get_devices()
    for d in prefs.devices: d.use = True
    scene.cycles.device = "GPU"
except Exception as e:
    print("GPU:", e)
scene.render.filepath = out
scene.render.image_settings.file_format = "PNG"
bpy.ops.render.render(write_still=True, scene=scene.name)
print("RENDERED", out)
