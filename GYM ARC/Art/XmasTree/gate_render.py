# Gate: render the tree ortho from the front at the sheet's px scale on magenta, compare silhouettes with the SIDE view.
# Run in Blender after build_tree.py: exec(open(r"...\XmasTree\gate_render.py").read())
import bpy, os, math
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\XmasTree"
sc = bpy.context.scene
S = 30.68 / (559 - 11)
W, H = 768, 600                                    # the sheet's side-view window (x 0-768, y 0-600)
cam = bpy.data.objects.get("GateCam") or bpy.data.objects.new("GateCam", bpy.data.cameras.new("GateCam"))
if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = W * S
# sheet centre x 446 -> world 0; sheet y 300 -> z
cam.location = ((384 - 446) * S * -1 * -1, -60, (559 - 300) * S); cam.rotation_euler = (math.pi / 2, 0, 0)
cam.location.x = (384 - 446) * S
sc.camera = cam
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = W, H, 100
try: sc.render.engine = "BLENDER_WORKBENCH"
except TypeError: pass
sc.display.shading.light = "FLAT"; sc.display.shading.color_type = "MATERIAL"
sc.render.film_transparent = True
for o in sc.objects: o.hide_render = o.get("xmas_part") != "tree" and o.type == "MESH"
sc.render.filepath = os.path.join(HERE, "gate", "front.png")
os.makedirs(os.path.join(HERE, "gate"), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("rendered", sc.render.filepath)
