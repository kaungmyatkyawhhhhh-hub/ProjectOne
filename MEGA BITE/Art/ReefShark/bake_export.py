"""Bake the shark's colours into one 512 px texture and export a Roblox-ready FBX (mesh + rig + swim).
Usage (any Blender): open the .blend made by reef_shark.py, run this with OUT_DIR set."""
import bpy, os
OUT_DIR = globals().get("OUT_DIR", "/home/claude/megabite_art/export")
NAME = "ReefShark"
os.makedirs(OUT_DIR, exist_ok=True)
sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.samples = 16
shark = bpy.data.objects[NAME]; rig = bpy.data.objects[NAME + "Rig"]

# 1) UVs: one smart-projected UV map with a margin
bpy.ops.object.select_all(action="DESELECT"); shark.select_set(True); bpy.context.view_layer.objects.active = shark
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
bpy.ops.object.mode_set(mode="OBJECT")

# 2) bake base colour of every material into one image
img = bpy.data.images.new(NAME + "_Color", 512, 512); img.generated_color = (0.3, 0.5, 0.7, 1)
for m in shark.data.materials:
    nt = m.node_tree; n = nt.nodes.new("ShaderNodeTexImage"); n.image = img; n.name = "BakeTarget"
    nt.nodes.active = n
sc.cycles.bake_type = "DIFFUSE"
sc.render.bake.use_pass_direct = False; sc.render.bake.use_pass_indirect = False; sc.render.bake.use_pass_color = True
sc.render.bake.margin = 6
bpy.ops.object.bake(type="DIFFUSE")
img.filepath_raw = os.path.join(OUT_DIR, NAME + "_Color.png"); img.file_format = "PNG"; img.save()

# 3) one export material that only uses the baked texture (what Roblox will see)
em = bpy.data.materials.new(NAME + "_Export"); em.use_nodes = True
b = em.node_tree.nodes["Principled BSDF"]; t = em.node_tree.nodes.new("ShaderNodeTexImage"); t.image = img
em.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"]); b.inputs["Roughness"].default_value = 0.6
shark.data.materials.clear(); shark.data.materials.append(em)

# 4) FBX: mesh + armature + the Swim action, textures embedded
fbx = os.path.join(OUT_DIR, NAME + ".fbx")
bpy.ops.object.select_all(action="DESELECT"); shark.select_set(True); rig.select_set(True)
bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"ARMATURE", "MESH"},
                         add_leaf_bones=False, bake_anim=True, bake_anim_use_all_actions=False,
                         path_mode="COPY", embed_textures=True, apply_unit_scale=True)
print("exported", fbx, os.path.getsize(fbx), "bytes")
