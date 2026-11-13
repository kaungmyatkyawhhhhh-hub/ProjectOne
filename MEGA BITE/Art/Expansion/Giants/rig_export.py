# Giant kit: mesh.npz + rig.json + texture -> skinned FBX for Roblox, plus a pose test render.  usage: python3 rig_export.py -- <dir> <NAME> [pose json]
import bpy, sys, json, math, numpy as np
from mathutils import Vector, Matrix, Euler
A = sys.argv[sys.argv.index('--') + 1:]; D, NAME = A[0], A[1]
R = json.load(open(D + '/rig.json')); Z = np.load(D + '/mesh.npz'); P, ind, uvs = Z['P'], Z['ind'], Z['uvs']
bpy.ops.wm.read_factory_settings(use_empty=True); sc = bpy.context.scene
me = bpy.data.meshes.new(NAME); me.from_pydata([tuple(p) for p in P], [], [tuple(int(i) for i in f) for f in ind]); me.validate()
ob = bpy.data.objects.new(NAME, me); sc.collection.objects.link(ob)
uv = me.uv_layers.new(name='UVMap')
for poly in me.polygons:
    for li, vi in zip(poly.loop_indices, poly.vertices): uv.data[li].uv = (float(uvs[vi][0]), float(uvs[vi][1]))
    poly.use_smooth = True
img = bpy.data.images.load(D + '/' + R['tex'])
mat = bpy.data.materials.new(NAME + '_mat'); mat.use_nodes = True; nt = mat.node_tree; tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = img
b = nt.nodes['Principled BSDF']; nt.links.new(tx.outputs['Color'], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.85
me.materials.append(mat)
arm = bpy.data.armatures.new(NAME + 'Rig'); rig = bpy.data.objects.new(NAME + 'Rig', arm); sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
with bpy.context.temp_override(active_object=rig, object=rig): bpy.ops.object.mode_set(mode='EDIT')
for bn in R['bones']:
    e = arm.edit_bones.new(bn['name']); e.head = Vector(bn['head']); e.tail = Vector(bn['tail']); e.roll = 0
    if bn['parent']: e.parent = arm.edit_bones[bn['parent']]
with bpy.context.temp_override(active_object=rig, object=rig): bpy.ops.object.mode_set(mode='OBJECT')
W = np.array(R['weights'])
for j, bn in enumerate(R['bones']):
    g = ob.vertex_groups.new(name=bn['name'])
    for i in np.where(W[:, j] > 0.004)[0]: g.add([int(i)], float(W[i, j]), 'REPLACE')
ob.parent = rig; md = ob.modifiers.new('Armature', 'ARMATURE'); md.object = rig
infl = (W > 0.004).sum(1).max(); print('max influences', int(infl), 'verts', len(P), 'tris', len(ind))
for o in sc.objects: o.select_set(False)
ob.select_set(True); rig.select_set(True)
with bpy.context.temp_override(selected_objects=[ob, rig], active_object=rig):
    bpy.ops.export_scene.fbx(filepath=f'{D}/{NAME}.fbx', use_selection=True, add_leaf_bones=False, path_mode='COPY', embed_textures=True, axis_forward='-Z', axis_up='Y',
                             apply_scale_options='FBX_SCALE_ALL', object_types={'ARMATURE', 'MESH'}, bake_anim=False, bake_space_transform=True, mesh_smooth_type='FACE')
import os; print('fbx', os.path.getsize(f'{D}/{NAME}.fbx'))
# ---- pose test: world-axis rotations per bone (degrees), rendered from the side and from above
if len(A) > 2:
    poses = json.load(open(A[2]))
    scn = sc; scn.render.engine = 'BLENDER_WORKBENCH'; scn.view_settings.view_transform = 'Standard'
    sh = scn.display.shading; sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_backface_culling = True
    w = bpy.data.worlds.new('w'); scn.world = w; w.color = (0.03, 0.16, 0.32)
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); scn.collection.objects.link(cam); scn.camera = cam; cam.data.type = 'ORTHO'
    ctr = Vector(P.mean(0)); size = float((P.max(0) - P.min(0)).max())
    from PIL import Image
    tiles = []
    for pi, pose in enumerate(poses):
        for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        for bn in [b_['name'] for b_ in R['bones']]:
            if bn not in pose: continue
            ax, deg = pose[bn][0], pose[bn][1]; pb = rig.pose.bones[bn]
            Rw = Matrix.Rotation(math.radians(deg), 4, Vector(ax)); h = pb.matrix.to_translation()
            pb.matrix = Matrix.Translation(h) @ Rw @ Matrix.Translation(-h) @ pb.matrix
            bpy.context.view_layer.update()
        for (az, el) in pose.get('_views', [(-90, 0), (-60, 25)]):
            Aa, E = math.radians(az), math.radians(el)
            cam.location = ctr + Vector((math.cos(Aa) * math.cos(E), math.sin(Aa) * math.cos(E), math.sin(E))) * 600
            cam.rotation_euler = (ctr - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.ortho_scale = size * 1.12
            scn.render.resolution_x, scn.render.resolution_y = 800, 440; scn.render.filepath = f'{D}/pose_{pi}.png'; bpy.ops.render.render(write_still=True)
            tiles.append(Image.open(f'{D}/pose_{pi}.png').convert('RGB'))
    c = Image.new('RGB', (1600, 440 * ((len(tiles) + 1) // 2)))
    for i, t in enumerate(tiles): c.paste(t, ((i % 2) * 800, (i // 2) * 440))
    c.save(D + '/poses.jpg', quality=85)
