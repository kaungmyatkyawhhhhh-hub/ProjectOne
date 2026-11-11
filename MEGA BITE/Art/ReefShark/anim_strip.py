import bpy, sys
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath='/home/claude/megabite_art/reef_shark.blend')
exec(open('/home/claude/megabite_art/render_preview.py').read().split("views = ")[0])
sc = bpy.context.scene; sc.render.resolution_x, sc.render.resolution_y = 400, 300; sc.cycles.samples = 12
cam.location = (0.0, 0.2, 7.5); cam.rotation_euler = (0, 0, 0)  # top view shows the side-to-side wiggle
cam.data.lens = 40
for f in (0, 6, 12, 18):
    sc.frame_set(f); sc.render.filepath = f'/home/claude/megabite_art/anim_{f:02d}.png'
    bpy.ops.render.render(write_still=True)
print("ok")
