# Stone v4 -> Roblox: straight arms (R15 rest pose), no head, glow faces as separate Neon parts, three 1024 colour atlases.
import bpy, bmesh, os, sys, json, math, time
import numpy as np
from mathutils import Vector, Matrix
os.environ["STONE_STRAIGHT"] = "1"; os.environ.setdefault("STONE_DIR", "/home/claude/stone"); os.environ.setdefault("STONE_CHAR", "/home/claude/stone/baconhair.obj")
os.environ["STONE_SRC"] = "iron_v3.py"; os.environ["STONE_VER"] = "iron3r"; os.environ.setdefault("STONE_RES", "2048")
OUTD = "/home/claude/stone/rbx_iron3"; os.makedirs(OUTD, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
exec(open("/home/claude/stone/iron_v3_paint.py").read())
sc = bpy.context.scene
col_img = bpy.data.images["stone_iron3r_color"]; glo_img = bpy.data.images["stone_iron3r_glow"]
RR = col_img.size[0]
C = np.array(col_img.pixels[:], np.float32).reshape(RR, RR, 4)[..., :3]
E = np.array(glo_img.pixels[:], np.float32).reshape(RR, RR, 4)[..., :3]
def samp(img, uv):
    x = min(max(int(uv[0] * RR), 0), RR - 1); y = min(max(int(uv[1] * RR), 0), RR - 1); return img[y, x]
head = bpy.data.objects.get("Head")
if head: bpy.data.objects.remove(head, do_unlink=True)
objs = [o for o in bpy.data.collections[COLL].objects]
for o in objs:  # apply the 0.01 scale
    o.data.transform(Matrix.Diagonal((0.01, 0.01, 0.01, 1))); o.scale = (1, 1, 1)
# v4b: NO glow split. Each body part is ONE mesh (like a catalog bundle); the glow is an emissive mask.
# ---- 2) three region atlases (1024 each), baked from the 2048 paint ----
REG = {"Torso": ["UpperTorso", "LowerTorso"]}                     # v10c: one map per limb like Korblox (5 maps, each 1024)
for sd in ("Left", "Right"):
    REG[sd + "Arm"] = [sd + n for n in ("UpperArm", "LowerArm")]          # hands = ROBLOX Boy meshes in game, no texels for ours
    REG[sd + "Leg"] = [sd + n for n in ("UpperLeg", "LowerLeg", "Foot")]
src_mat = bpy.data.materials.new("bake_src"); src_mat.use_nodes = True; nt = src_mat.node_tree; nt.nodes.clear()
uvn = nt.nodes.new("ShaderNodeUVMap"); uvn.uv_map = "atlas"
tc = nt.nodes.new("ShaderNodeTexImage"); tc.image = col_img; te = nt.nodes.new("ShaderNodeTexImage"); te.image = glo_img
nt.links.new(uvn.outputs["UV"], tc.inputs["Vector"]); nt.links.new(uvn.outputs["UV"], te.inputs["Vector"])
mx = nt.nodes.new("ShaderNodeMix"); mx.data_type = 'RGBA'; mx.blend_type = 'ADD'; mx.inputs["Factor"].default_value = 0.85
nt.links.new(tc.outputs["Color"], mx.inputs[6]); nt.links.new(te.outputs["Color"], mx.inputs[7])
em = nt.nodes.new("ShaderNodeEmission"); nt.links.new(mx.outputs[2], em.inputs["Color"])
out = nt.nodes.new("ShaderNodeOutputMaterial"); nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
tgt = nt.nodes.new("ShaderNodeTexImage")
gmat = bpy.data.materials.new("bake_glow"); gmat.use_nodes = True; gt = gmat.node_tree; gt.nodes.clear()
guv = gt.nodes.new("ShaderNodeUVMap"); guv.uv_map = "atlas"; gte = gt.nodes.new("ShaderNodeTexImage"); gte.image = glo_img
gt.links.new(guv.outputs["UV"], gte.inputs["Vector"])
gbw = gt.nodes.new("ShaderNodeRGBToBW"); gt.links.new(gte.outputs["Color"], gbw.inputs["Color"])
gcr = gt.nodes.new("ShaderNodeMapRange"); gcr.inputs["From Min"].default_value = 0.08; gcr.inputs["From Max"].default_value = 0.55
gt.links.new(gbw.outputs["Val"], gcr.inputs["Value"])
gem = gt.nodes.new("ShaderNodeEmission"); gt.links.new(gcr.outputs["Result"], gem.inputs["Color"])
gout = gt.nodes.new("ShaderNodeOutputMaterial"); gt.links.new(gem.outputs["Emission"], gout.inputs["Surface"])
gtgt = gt.nodes.new("ShaderNodeTexImage")
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 4; sc.render.bake.margin = 6
for rn, names in REG.items():
    ro = [bpy.data.objects[n] for n in names]
    for o in ro:
        if "rbx" not in o.data.uv_layers: o.data.uv_layers.new(name="rbx")
        o.data.uv_layers["rbx"].active = True
        o.data.materials.clear(); o.data.materials.append(src_mat)
        for p in o.data.polygons: p.material_index = 0
    bpy.ops.object.select_all(action='DESELECT')
    for o in ro: o.select_set(True)
    bpy.context.view_layer.objects.active = ro[0]
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.select_all(action='SELECT')
    try:
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.004, shape_method='CONCAVE')
    except TypeError:
        bpy.ops.uv.pack_islands(rotate=True, margin=0.004)
    bpy.ops.object.mode_set(mode='OBJECT')
    img = bpy.data.images.new("Stone_" + rn, 1024, 1024, alpha=False); tgt.image = img; nt.nodes.active = tgt
    bpy.ops.object.bake(type='EMIT')
    img.filepath_raw = os.path.join(OUTD, "Stone_%s.png" % rn); img.file_format = 'PNG'; img.save()
    for o in ro:
        o.data.materials.clear(); o.data.materials.append(gmat)
    mimg = bpy.data.images.new("StoneGlow_" + rn, 1024, 1024, alpha=False); gtgt.image = mimg; gt.nodes.active = gtgt
    bpy.ops.object.bake(type='EMIT')
    mimg.filepath_raw = os.path.join(OUTD, "Stone_%s_glow.png" % rn); mimg.file_format = 'PNG'; mimg.save()
    fm = bpy.data.materials.new("Stone_" + rn)
    for o in ro:
        o.data.uv_layers.remove(o.data.uv_layers["atlas"]); o.data.materials.clear(); o.data.materials.append(fm); o["region"] = rn
    print("baked", rn, "%.1fs" % (time.time() - t0))
# ---- 3) Roblox axes: x -> -x, y -> -y (FBX then gives X=-x, Y=z, Z=y), metres -> studs x0.8 ----
R180 = Matrix.Diagonal((-1, -1, 1, 1)); info = {}
for o in bpy.data.collections[COLL].objects:
    o.data.transform(R180)
    vs = np.array([v.co[:] for v in o.data.vertices]); mn = vs.min(0); mxx = vs.max(0)
    # Roblox coordinates of the bounding box (studs): X = x', Y = z', Z = -y'
    cx, cy, cz = (mn + mxx) / 2; sx, sy, sz = mxx - mn
    info[o.name] = {"limb": o.name.replace("_Glow", ""), "glow": o.name.endswith("_Glow"), "region": o.get("region", ""),
                    "center": [cx * 0.8, cz * 0.8, -cy * 0.8], "size": [sx * 0.8, sz * 0.8, sy * 0.8], "tris": sum(len(p.vertices) - 2 for p in o.data.polygons)}
json.dump(info, open(os.path.join(OUTD, "iron_v3_parts.json"), "w"), indent=1)
bpy.ops.object.select_all(action='DESELECT')
for o in bpy.data.collections[COLL].objects: o.select_set(True)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUTD, "IronSet_v3.fbx"), use_selection=True, object_types={'MESH'}, mesh_smooth_type='FACE',
                         apply_unit_scale=True, use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False, path_mode='STRIP')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUTD, "IronSet_v3_roblox.blend"))
print("exported", len(info), "objects", sum(v["tris"] for v in info.values()), "tris", "%.1fs" % (time.time() - t0))
