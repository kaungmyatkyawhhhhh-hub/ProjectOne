# Whale skeleton: one atlas for every part (flat colours x a baked soft sky light), then OBJ (gates/renders) + FBX (Roblox).
import bpy, bmesh, math, numpy as np, sys
OUT = '/tmp/claude-0/lm2/skel'; NAME = 'MB_LM_WhaleSkeleton_v2'; TEX = 1024
bpy.ops.wm.open_mainfile(filepath=OUT + '/model.blend')
sc = bpy.context.scene
obs = [o for o in sc.objects if o.type == 'MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in obs: o.select_set(True)
bpy.context.view_layer.objects.active = obs[0]
bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active; ob.name = 'All'
# UVs: every part unwrapped into one atlas
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.004, area_weight=0.0, scale_to_bounds=False)
bpy.ops.object.mode_set(mode='OBJECT')
img = bpy.data.images.new('atlas', TEX, TEX, alpha=False)
for m in ob.data.materials:
    m.use_nodes = True
    n = m.node_tree.nodes.new('ShaderNodeTexImage'); n.image = img; m.node_tree.nodes.active = n
    b = m.node_tree.nodes.get('Principled BSDF')
    if b:
        c0 = b.inputs['Base Color'].default_value; b.inputs['Base Color'].default_value = tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c0[:3]) + (1,)
        b.inputs['Roughness'].default_value = 1.0
        for k in ('Specular IOR Level', 'Specular'):
            if k in b.inputs: b.inputs[k].default_value = 0.0
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = int(sys.argv[sys.argv.index('--') + 1]) if '--' in sys.argv else 48
sc.cycles.use_denoising = False
# a soft sky: bright above, dimmer at the horizon, dark below (so tops are light and undersides shaded, like the sheet)
w = bpy.data.worlds.new('sky'); sc.world = w; w.use_nodes = True
nt = w.node_tree; bg = nt.nodes['Background']
tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); ramp = nt.nodes.new('ShaderNodeValToRGB'); mp = nt.nodes.new('ShaderNodeMapRange')
nt.links.new(tc.outputs['Generated'], sep.inputs[0]); nt.links.new(sep.outputs['Z'], mp.inputs[0])
mp.inputs[1].default_value = -1; mp.inputs[2].default_value = 1; mp.inputs[3].default_value = 0; mp.inputs[4].default_value = 1
nt.links.new(mp.outputs[0], ramp.inputs[0])
cr = ramp.color_ramp; cr.elements[0].position = 0.0; cr.elements[0].color = (0.30, 0.30, 0.34, 1); cr.elements[1].position = 1.0; cr.elements[1].color = (1.15, 1.13, 1.08, 1)
e = cr.elements.new(0.5); e.color = (0.72, 0.72, 0.74, 1)
nt.links.new(ramp.outputs[0], bg.inputs['Color']); bg.inputs['Strength'].default_value = 1.0
# a floor so the undersides near the sand get darker
bpy.ops.mesh.primitive_plane_add(size=900, location=(100, 0, -0.6)); floor = bpy.context.active_object
fm = bpy.data.materials.new('floor'); fm.diffuse_color = (0.75, 0.72, 0.62, 1); floor.data.materials.append(fm)
bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active = ob
sc.cycles.bake_type = 'DIFFUSE'
sc.render.bake.use_pass_direct = True; sc.render.bake.use_pass_indirect = True; sc.render.bake.use_pass_color = True; sc.render.bake.margin = 6
bpy.ops.object.bake(type='DIFFUSE')
px = np.array(img.pixels[:], np.float32).reshape(TEX, TEX, 4)
rgb = px[..., :3]
# linear -> sRGB, gentle contrast so the flat colours stay bright (Roblox adds its own light)
rgb = np.clip(rgb * 1.22, 0, 1)
srgb = np.where(rgb <= 0.0031308, rgb * 12.92, 1.055 * np.power(np.maximum(rgb, 1e-6), 1 / 2.4) - 0.055)
from PIL import Image
Image.fromarray((np.clip(srgb, 0, 1) * 255).astype(np.uint8)[::-1]).save(OUT + f'/{NAME}_atlas.png')
bpy.data.objects.remove(floor)
# one atlas material; split back into parts (one MeshPart per colour family)
img2 = bpy.data.images.load(OUT + f'/{NAME}_atlas.png')
at = bpy.data.materials.new('Atlas'); at.use_nodes = True; tn = at.node_tree.nodes.new('ShaderNodeTexImage'); tn.image = img2
at.node_tree.links.new(tn.outputs['Color'], at.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
GROUP = {'Bone': 'Bones', 'BoneDark': 'Bones', 'AnemPurple': 'Anemones', 'AnemTeal': 'Anemones', 'AnemPink': 'Anemones', 'Crystal': 'Crystals',
         'CoralOrange': 'Corals', 'CoralPink': 'Corals', 'CoralYellow': 'Corals', 'Rock': 'Rocks', 'Kelp': 'Kelp'}
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.separate(type='MATERIAL'); bpy.ops.object.mode_set(mode='OBJECT')
groups = {}
for o in [o for o in sc.objects if o.type == 'MESH']:
    key = o.data.materials[0].name.split('.')[0]
    flat = key in ('Crystal', 'Rock')
    for p in o.data.polygons: p.use_smooth = not flat
    o.data.materials.clear(); o.data.materials.append(at)
    groups.setdefault(GROUP.get(key, 'Bones'), []).append(o)
for g, lst in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in lst: o.select_set(True)
    bpy.context.view_layer.objects.active = lst[0]
    if len(lst) > 1: bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active; o.name = g; o.data.name = g
    try: bpy.ops.object.shade_auto_smooth(angle=math.radians(50))
    except Exception: pass
t = 0
for o in sc.objects:
    if o.type == 'MESH': o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); t += n; print('part', o.name, n)
print('TRIS', t)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.obj_export(filepath=OUT + '/tex/model.obj', export_selected_objects=True, forward_axis='NEGATIVE_Z', up_axis='Y', export_materials=True, apply_modifiers=True, export_normals=True, path_mode='COPY')
bpy.ops.export_scene.fbx(filepath=f'{OUT}/{NAME}.fbx', use_selection=True, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, global_scale=1.0,
                         mesh_smooth_type='FACE', add_leaf_bones=False, bake_space_transform=True, path_mode='COPY', embed_textures=True)
