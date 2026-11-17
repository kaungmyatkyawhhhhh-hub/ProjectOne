# Livyatan T6: built .blend -> rigged, textured FBX for Roblox (+ pose test renders).
# Rig = the FishKit species rig (Root, Spine0..7 head->tail, Jaw under Spine0) at the old Leviathan's bone layout
# (Leviathan_hse/rig.json, 7 m) stretched to this 8 m model, so the existing Leviathan swim/bite clips play on it.
# Run: blender -b livyatan_t6.blend -P livy6_export.py -- livy6_data.json export
import bpy, bmesh, json, math, os, sys
import numpy as np
from mathutils import Vector, Matrix

A = sys.argv[sys.argv.index('--') + 1:]; D = json.load(open(A[0])); OUT = os.path.abspath(A[1])   # absolute: relative image/render paths land under C:\
NAME, TEX = 'Livyatan_T6', 512
X0, X1 = D['side_x']; S = D['len_m'] / (X1 - X0)
SHIFT = -D['len_m'] / 2                                    # nose to x=0, tail to -8 (FishKit layout)
def X(x): return (x - X0) * S - D['len_m'] / 2 + SHIFT
def Z(y): return (D['yc'] - y) * S
def line(pts, x): p = np.array(pts, float); return float(np.interp(x, p[:, 0], p[:, 1]))
sc = bpy.context.scene
parts = [o for o in sc.objects if o.name.startswith('L6_') and o.type == 'MESH']
for o in parts: o.data.transform(Matrix.Translation((SHIFT, 0, 0)))
JAW_PARTS = {'L6_LowerJaw', 'L6_LowerTeethRow'}

# ---------- join into skinned meshes: body (textured) + cyan runes, gold runes, eye (each set to Neon in Studio) ----------
def join(objs, name):
    for o in sc.objects: o.select_set(False)
    for o in objs:
        o.select_set(True)
        jaw = 1.0 if o.name in JAW_PARTS else 0.0               # remember jaw verts through the join
        a = o.data.attributes.new('jaw', 'FLOAT', 'POINT')
        for d in a.data: d.value = jaw
    bpy.context.view_layer.objects.active = objs[0]
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs): bpy.ops.object.join()
    o = objs[0]; o.name = name; o.data.name = name; return o
cy = [bpy.data.objects['L6_RunesCyan']]; go = [bpy.data.objects['L6_RunesGold']]; eyes = [bpy.data.objects['L6_Eye']]
body = join([o for o in parts if o not in cy + go + eyes], NAME)
crys = join(cy, NAME + '_RunesCyan'); gold = join(go, NAME + '_RunesGold'); eye = join(eyes, NAME + '_Eye')

# ---------- palette atlas: every face's flat colour gets its own cell ----------
cols = {}
for o in (body, crys, gold, eye):
    ca = o.data.color_attributes['Col']
    for p in o.data.polygons:
        c = tuple(int(round(v * 255)) for v in ca.data[p.loop_start].color_srgb[:3]); cols.setdefault(c, len(cols))
CELL = 8 if len(cols) <= (TEX // 8) ** 2 else 4
assert len(cols) <= (TEX // CELL) ** 2, 'too many colours for the atlas'
img = np.zeros((TEX, TEX, 3), np.uint8); per = TEX // CELL
for c, i in cols.items():
    r, q = divmod(i, per); img[r * CELL:(r + 1) * CELL, q * CELL:(q + 1) * CELL] = c
os.makedirs(OUT, exist_ok=True); tex_path = os.path.join(OUT, NAME + '_tex.png')
im = bpy.data.images.new(NAME + '_tex', TEX, TEX, alpha=False)          # byte image: pixels are stored as given (sRGB)
px = np.ones((TEX, TEX, 4), np.float32); px[..., :3] = img[::-1] / 255.0; im.pixels.foreach_set(px.ravel())
im.filepath_raw = tex_path; im.file_format = 'PNG'; im.save()
mat = bpy.data.materials.new(NAME + '_mat'); mat.use_nodes = True; nt = mat.node_tree
tn = nt.nodes.new('ShaderNodeTexImage'); tn.image = im; tn.interpolation = 'Closest'
bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); nt.links.new(tn.outputs['Color'], bs.inputs['Base Color'])
for o in (body, crys, gold, eye):
    me = o.data; uv = me.uv_layers.new(name='UVMap'); ca = me.color_attributes['Col']
    for p in me.polygons:
        i = cols[tuple(int(round(v * 255)) for v in ca.data[p.loop_start].color_srgb[:3])]; r, q = divmod(i, per)
        u, v = (q + 0.5) * CELL / TEX, 1 - (r + 0.5) * CELL / TEX
        for li in p.loop_indices: uv.data[li].uv = (u, v)
    me.materials.clear(); me.materials.append(mat)
    for p in me.polygons: p.use_smooth = False
print('colours', len(cols), 'cell', CELL)

# ---------- rig ----------
x0, x1, NB = -0.168 * 8 / 7, -6.643 * 8 / 7, 8       # old Leviathan bone span (Leviathan_hse/rig.json) x 8/7
arm = bpy.data.armatures.new(NAME + 'Rig'); rig = bpy.data.objects.new(NAME + 'Rig', arm); sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
with bpy.context.temp_override(active_object=rig, object=rig): bpy.ops.object.mode_set(mode='EDIT')
xs = [x0 - i * (x0 - x1) / NB for i in range(NB + 1)]
rb = arm.edit_bones.new('Root'); rb.head = (0, 0, 0); rb.tail = (0.4, 0, 0); prev = rb
for i in range(NB):
    b = arm.edit_bones.new(f'Spine{i}'); b.head = (xs[i], 0, 0); b.tail = (xs[i + 1], 0, 0); b.parent = prev; b.use_connect = i > 0; prev = b
H = D['head']; hinge_x = 1100                     # exploded sheet: the jaw hinges at its back end
j = arm.edit_bones.new('Jaw'); j.head = (X(hinge_x), 0, Z(line(H['lower_lip'], hinge_x)))
j.tail = (X(H['jaw_bot'][-1][0]), 0, Z(line(H['lower_lip'], H['jaw_bot'][-1][0]))); j.parent = arm.edit_bones['Spine0']
with bpy.context.temp_override(active_object=rig, object=rig): bpy.ops.object.mode_set(mode='OBJECT')
seg = (xs[0] - xs[-1]) / NB; maxinf = 0
for o in (body, crys, gold, eye):
    o.parent = rig; md = o.modifiers.new('Armature', 'ARMATURE'); md.object = rig
    gs = [o.vertex_groups.new(name=f'Spine{i}') for i in range(NB)]; jg = o.vertex_groups.new(name='Jaw')
    jaw = o.data.attributes['jaw'].data
    for v in o.data.vertices:
        if jaw[v.index].value > 0.5: jg.add([v.index], 1.0, 'REPLACE'); continue
        u = (xs[0] - v.co.x) / seg - 0.5
        ws = sorted(((math.exp(-((u - k) / 0.75) ** 2), k) for k in range(NB)), reverse=True)[:3]; tot = sum(w for w, _ in ws)
        for w, k in ws: gs[k].add([v.index], w / tot, 'REPLACE')
        maxinf = max(maxinf, 3)
    o.data.attributes.remove(o.data.attributes['jaw'])
    o.data.color_attributes.remove(o.data.color_attributes['Col'])

# ---------- Swim action (carangiform: wave grows toward the tail) + Bite, kept in the .blend for preview ----------
rig.animation_data_create(); act = bpy.data.actions.new('Swim'); act.use_fake_user = True; rig.animation_data.action = act
for f in range(0, 25, 3):
    ph = 2 * math.pi * f / 24
    for i in range(NB):
        pb = rig.pose.bones[f'Spine{i}']; pb.rotation_mode = 'XYZ'
        pb.rotation_euler = (0, 0, math.radians(2 + 7 * i / NB) * math.sin(ph - i * 0.7))
        pb.keyframe_insert('rotation_euler', frame=f)
rig.animation_data.action = None

for o in sc.objects: o.select_set(False)
for o in (body, crys, gold, eye, rig): o.select_set(True)
bpy.context.view_layer.objects.active = rig
fbx = os.path.join(OUT, NAME + '.fbx')
with bpy.context.temp_override(selected_objects=[body, crys, gold, eye, rig], active_object=rig):
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={'ARMATURE', 'MESH'}, add_leaf_bones=False, bake_anim=False,
        path_mode='COPY', embed_textures=True, apply_unit_scale=True, use_armature_deform_only=False, mesh_smooth_type='FACE')
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in (body, crys, gold, eye))
print('EXPORT', fbx, os.path.getsize(fbx), 'bytes; tris', tris, 'max influences', maxinf)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, NAME + '_rigged.blend'))

# ---------- pose test: swim bend from above + bite from the side ----------
sc.render.engine = 'BLENDER_WORKBENCH'; sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'TEXTURE'; sh.show_backface_culling = True
sc.view_settings.view_transform = 'Standard'; sc.render.resolution_x, sc.render.resolution_y = 1100, 420
sc.world = sc.world or bpy.data.worlds.new('W'); sc.world.color = (0.03, 0.16, 0.32)
cam = bpy.data.objects.new('PoseCam', bpy.data.cameras.new('PoseCam')); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = 'ORTHO'; cam.data.ortho_scale = 9.0
for name, loc, rot, fn in (('swim_top', (-4.0, 0, 12), (0, 0, 0), 'swim'), ('bite_side', (-4.0, -12, 0), (math.radians(90), 0, 0), 'bite'), ('rest_side', (-4.0, -12, 0), (math.radians(90), 0, 0), None)):
    rig.animation_data.action = act if fn == 'swim' else None
    if fn == 'swim' and act.slots: rig.animation_data.action_slot = act.slots[0]
    for pb in rig.pose.bones: pb.rotation_mode = 'XYZ'; pb.rotation_euler = (0, 0, 0)
    if fn == 'swim': sc.frame_set(6); print('SWIM Spine7 deg', round(math.degrees(rig.pose.bones['Spine7'].rotation_euler.z), 2))
    if fn == 'bite': rig.pose.bones['Jaw'].rotation_euler = (math.radians(-22), 0, 0)
    bpy.context.view_layer.update()
    cam.location = loc; cam.rotation_euler = rot
    p = os.path.join(OUT, f'pose_{name}.png'); sc.render.filepath = p; bpy.ops.render.render(write_still=True)
