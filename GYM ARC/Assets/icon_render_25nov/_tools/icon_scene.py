# GYM ARC icon render (25 Nov): one call builds a shot. compose(hero_file, hand_name, db_axis, cam_loc, cam_target, lens, fstop, R)
import bpy
D = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Assets\icon_render_25nov\_tools"
G = {}
exec(open(D + r"\icon_hero.py").read(), G); exec(open(D + r"\icon_set.py").read(), G)
def compose(hero_file, db_axis=(0.1, 1, 0.08), cam_loc=(-1.6, 8.2, 2.6), cam_target=(0.9, 0, 4.4), lens=27, fstop=2.8, R=1.6, head_scale=1.25, samples=64, hand="RightHand", db_offset=(0,0,0)):
    for c in list(bpy.data.collections):
        if c.name.startswith("HERO"):
            for o in list(c.objects): bpy.data.objects.remove(o)
            bpy.data.collections.remove(c)
    for m in list(bpy.data.materials):
        if m.users == 0: bpy.data.materials.remove(m)
    root, pieces = G["hero"](hero_file, "HERO_" + hero_file)
    for n in ("_Head", "_Hair"):
        bpy.data.objects[hero_file + n].scale = (head_scale,) * 3
    bpy.context.view_layer.update()
    if "SET" not in bpy.data.collections: G["build_set"]()
    G["lights_and_world"]((0, 0, 4.5))
    h = bpy.data.objects[hero_file + "_" + hand]
    db = G["build_dumbbell"](h, db_axis, R=R)
    db.location = db.location + __import__("mathutils").Vector(db_offset)
    G["render_settings"](1024, samples)
    G["camera"](cam_loc, cam_target, lens=lens, fstop=fstop)
    return root
