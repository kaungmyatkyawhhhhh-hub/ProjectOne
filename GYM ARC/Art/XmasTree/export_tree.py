# Export the tree objects (xmas_part == "tree") to XmasTree.glb, one mesh per colour object, Y-up for Roblox.
import bpy, os
HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\XmasTree"
sc = bpy.data.scenes["GYM ARC Xmas"]
vl = sc.view_layers[0]
for o in sc.objects:
    o.select_set(o.get("xmas_part") == "tree", view_layer=vl)
with bpy.context.temp_override(window=bpy.context.window, scene=sc, view_layer=vl):
  bpy.ops.export_scene.gltf(filepath=os.path.join(HERE, "XmasTree.glb"), use_selection=True, export_format="GLB", export_yup=True, export_apply=True)
print("glb", os.path.getsize(os.path.join(HERE, "XmasTree.glb")))
