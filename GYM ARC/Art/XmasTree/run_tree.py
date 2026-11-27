# Headless: blender -b --python run_tree.py  -> builds the tree, renders the gate, exports XmasTree.glb, prints open edges
import bpy, bmesh
D = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\XmasTree\\"
exec(open(D + "build_tree.py").read())
exec(open(D + "gate_render.py").read())
sc = bpy.data.scenes["GYM ARC Xmas"]
for o in sc.objects:
    if o.get("xmas_part") == "tree":
        bm = bmesh.new(); bm.from_mesh(o.data); print(o.name, "open", sum(1 for e in bm.edges if not e.is_manifold)); bm.free()
exec(open(D + "export_tree.py").read())
