# MEGA BITE manta v1: build in Blender from manta_v1.json (made by manta_gen.py), rig, export FBX.
# Usage (inside Blender): JSON, OUTDIR set below or via env.
import bpy, bmesh, json, os, math
from mathutils import Vector

JSON = os.environ.get('MANTA_JSON', r'C:\ObsidianOne\Claude+Obsidian\MEGA BITE\Art\Manta\manta_v1.json')
OUTDIR = os.environ.get('MANTA_OUT', os.path.dirname(JSON))
D = json.load(open(JSON))

scn_name = 'MEGA BITE Manta'
scn = bpy.data.scenes.get(scn_name) or bpy.data.scenes.new(scn_name)
if bpy.context.window:
    bpy.context.window.scene = scn
for o in list(scn.collection.objects):
    bpy.data.objects.remove(o, do_unlink=True)

# palette texture: 8 px swatches in one row
pal = D['pal']
SW = 8
img = bpy.data.images.get('MB_Manta_palette') or bpy.data.images.new('MB_Manta_palette', SW * len(pal), SW)
img.scale(SW * len(pal), SW)
px = []
for y in range(SW):
    for i, c in enumerate(pal):
        for x in range(SW):
            px += [c[0] / 255, c[1] / 255, c[2] / 255, 1]
img.pixels = px
img.filepath_raw = os.path.join(OUTDIR, 'MB_Manta_palette.png')
img.file_format = 'PNG'
img.save()

me = bpy.data.meshes.new('MB_Manta')
me.from_pydata([tuple(v) for v in D['verts']], [], [tuple(f) for f in D['faces']])
me.validate()
ob = bpy.data.objects.new('MB_Manta', me)
scn.collection.objects.link(ob)
uv = me.uv_layers.new(name='UVMap')
for poly, ci in zip(me.polygons, D['col']):
    u = (ci + 0.5) / len(pal)
    for li in poly.loop_indices:
        uv.data[li].uv = (u, 0.5)
for p in me.polygons:
    p.use_smooth = False
mat = bpy.data.materials.get('MB_Manta_mat') or bpy.data.materials.new('MB_Manta_mat')
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes.get('Principled BSDF')
tex = nt.nodes.get('MBTex') or nt.nodes.new('ShaderNodeTexImage')
tex.name = 'MBTex'; tex.image = img; tex.interpolation = 'Closest'
nt.links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
bsdf.inputs['Roughness'].default_value = 0.8
me.materials.clear(); me.materials.append(mat)

# fix normals outward (closed parts) with bmesh
bm = bmesh.new(); bm.from_mesh(me)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(me); bm.free()

# ---------------- rig: Root, WingL1/L2, WingR1/R2, Tail1/Tail2
arm = bpy.data.armatures.new('MB_MantaRig')
rig = bpy.data.objects.new('MB_MantaRig', arm)
scn.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT') if bpy.context.window else None
eb = arm.edit_bones
def bone(name, h, t, parent=None):
    b = eb.new(name); b.head = Vector(h); b.tail = Vector(t)
    if parent: b.parent = eb[parent]
    return b
if bpy.context.window is None:
    # background mode: need an explicit context for edit mode
    with bpy.context.temp_override(active_object=rig, object=rig):
        bpy.ops.object.mode_set(mode='EDIT')
eb = arm.edit_bones
bone('Root', (0, 0, 0), (0, 0.8, 0))
bone('WingL1', (-1.3, 0, 0), (-2.9, 0, 0), 'Root')
bone('WingL2', (-2.9, 0, 0), (-5.0, 0, 0), 'WingL1')
bone('WingR1', (1.3, 0, 0), (2.9, 0, 0), 'Root')
bone('WingR2', (2.9, 0, 0), (5.0, 0, 0), 'WingR1')
bone('Tail1', (0, -2.3, 0), (0, -3.4, 0), 'Root')
bone('Tail2', (0, -3.4, 0), (0, -4.45, 0), 'Tail1')
if bpy.context.window is None:
    with bpy.context.temp_override(active_object=rig, object=rig):
        bpy.ops.object.mode_set(mode='OBJECT')
else:
    bpy.ops.object.mode_set(mode='OBJECT')

for n in ['Root', 'WingL1', 'WingL2', 'WingR1', 'WingR2', 'Tail1', 'Tail2']:
    ob.vertex_groups.new(name=n)
def sm(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)
for v in me.vertices:
    x, y, z = v.co
    ax = abs(x)
    w1 = sm(0.9, 1.7, ax) * (1 - sm(2.6, 3.3, ax))
    w2 = sm(2.6, 3.3, ax)
    wr = 1 - w1 - w2
    side = 'L' if x < 0 else 'R'
    wt1 = sm(-2.2, -3.0, y) * (1 - sm(-3.2, -3.7, y)) if y < -2.2 else 0
    wt2 = sm(-3.2, -3.7, y) if y < -3.2 else 0
    if ax < 0.4 and (wt1 + wt2) > 0:
        wr = max(0.0, wr - wt1 - wt2)
        if wt1: ob.vertex_groups['Tail1'].add([v.index], wt1, 'REPLACE')
        if wt2: ob.vertex_groups['Tail2'].add([v.index], wt2, 'REPLACE')
    if wr > 0: ob.vertex_groups['Root'].add([v.index], wr, 'REPLACE')
    if w1 > 0: ob.vertex_groups['Wing' + side + '1'].add([v.index], w1, 'REPLACE')
    if w2 > 0: ob.vertex_groups['Wing' + side + '2'].add([v.index], w2, 'REPLACE')
ob.parent = rig
mod = ob.modifiers.new('Armature', 'ARMATURE'); mod.object = rig

print('built', len(me.vertices), 'verts', len(me.polygons), 'tris')

if os.environ.get('MANTA_EXPORT', '1') == '1':
    for o in bpy.context.view_layer.objects: o.select_set(False)
    ob.select_set(True); rig.select_set(True)
    out = os.path.join(OUTDIR, os.environ.get('MANTA_NAME', 'MB_Manta_v1') + '.fbx')
    with bpy.context.temp_override(selected_objects=[ob, rig], active_object=rig):
        bpy.ops.export_scene.fbx(filepath=out, use_selection=True, add_leaf_bones=False, path_mode='COPY',
                                 embed_textures=True, axis_forward='-Z', axis_up='Y', apply_scale_options='FBX_SCALE_ALL',
                                 object_types={'ARMATURE', 'MESH'}, bake_anim=False)
    print('exported', out, os.path.getsize(out))
