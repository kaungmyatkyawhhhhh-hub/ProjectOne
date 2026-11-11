"""Export the current MEGA BITE Reef Shark for Roblox: one mesh, ONE material with a tiny palette texture
(every face's UVs sit in the centre of its colour's cell: crisp flat colours, no baking), rig with the Root
bone at the origin, Swim baked in. Writes ReefShark.fbx + ReefShark_palette.png to OUT_DIR."""
import bpy, os, bmesh
OUT_DIR = globals().get("OUT_DIR", r"C:\ObsidianOne\Claude+Obsidian\MEGA BITE\Art\ReefShark\export")
os.makedirs(OUT_DIR, exist_ok=True)
sh = bpy.data.objects["ReefShark"]; rig = bpy.data.objects["ReefSharkRig"]
mats = [m for m in sh.data.materials]
n = len(mats); CELL = 16
img = bpy.data.images.get("ReefShark_palette") or bpy.data.images.new("ReefShark_palette", CELL * n, CELL)
img.scale(CELL * n, CELL)
px = []
for y in range(CELL):
    for i, m in enumerate(mats):
        c = m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value
        # linear -> sRGB for the PNG
        srgb = [((v ** (1 / 2.4)) * 1.055 - 0.055) if v > 0.0031308 else v * 12.92 for v in c[:3]]
        for x in range(CELL): px += [srgb[0], srgb[1], srgb[2], 1.0]
img.pixels = px
png = os.path.join(OUT_DIR, "ReefShark_palette.png"); img.filepath_raw = png; img.file_format = "PNG"; img.save()
# UVs: every face -> the centre of its material's cell
me = sh.data
if not me.uv_layers: me.uv_layers.new(name="UVMap")
uv = me.uv_layers.active.data
for p in me.polygons:
    u = (p.material_index + 0.5) / n
    for li in p.loop_indices: uv[li].uv = (u, 0.5)
# export copy of the materials: one material using the palette
em = bpy.data.materials.get("ReefShark_Export") or bpy.data.materials.new("ReefShark_Export"); em.use_nodes = True
nt = em.node_tree; b = nt.nodes["Principled BSDF"]
t = nt.nodes.get("Palette") or nt.nodes.new("ShaderNodeTexImage"); t.name = "Palette"; t.image = img; t.interpolation = "Closest"
nt.links.new(t.outputs["Color"], b.inputs["Base Color"]); b.inputs["Roughness"].default_value = 0.8
orig = [m for m in me.materials]; orig_idx = [p.material_index for p in me.polygons]
me.materials.clear(); me.materials.append(em)
for p in me.polygons: p.material_index = 0
sc = bpy.context.scene
rig.animation_data.action = bpy.data.actions["Swim"]; sc.frame_start, sc.frame_end = 0, 30; sc.render.fps = 30
bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
bpy.ops.object.select_all(action="DESELECT"); sh.select_set(True); rig.select_set(True); bpy.context.view_layer.objects.active = rig
fbx = os.path.join(OUT_DIR, "ReefShark.fbx")
bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"ARMATURE", "MESH"}, add_leaf_bones=False,
                         bake_anim=True, bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
                         path_mode="COPY", embed_textures=True, apply_unit_scale=True, use_armature_deform_only=False,
                         mesh_smooth_type="FACE")
# restore the preview materials
me.materials.clear()
for m in orig: me.materials.append(m)
for p, i in zip(me.polygons, orig_idx): p.material_index = i
print("exported", fbx, os.path.getsize(fbx), "palette", png, n, "colours")
