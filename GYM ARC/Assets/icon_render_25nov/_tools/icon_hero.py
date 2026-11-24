# GYM ARC icon render (25 Nov): load one exported pose as the hero (shirtless: the tank-top pieces get the skin).
import bpy, os
exec(open(r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Assets\icon_render_25nov\_tools\icon_lib.py").read(), globals())
def hero(file, colname):
    col = bpy.data.collections.get(colname) or collection(colname)
    root, pieces, marks = load_character(file, col, "face_bacon_smirk", face_glow=0.0)
    for p in pieces:
        if p.type == "MESH" and p.data.materials and p.data.materials[0].name == "TankTop":
            p.data.materials[0] = MAT["skin"]
    # centre the feet at the origin
    import mathutils
    zs = [ (p.matrix_world @ mathutils.Vector(c)).z for p in pieces if p.type=="MESH" for c in p.bound_box]
    xs = [ (p.matrix_world @ mathutils.Vector(c)).x for p in pieces if p.type=="MESH" for c in p.bound_box]
    ys = [ (p.matrix_world @ mathutils.Vector(c)).y for p in pieces if p.type=="MESH" for c in p.bound_box]
    o = Vector(((min(xs)+max(xs))/2, (min(ys)+max(ys))/2, min(zs)))
    for p in pieces:
        mw = p.matrix_world.copy(); mw.translation -= o
        p.parent = root; p.matrix_world = mw
    return root, pieces
