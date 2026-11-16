# Mosasaurus T6: set up the preview scene in the owner's Blender from export/Mosasaurus_T6_rigged.blend.
# Rig + 3 meshes, glow materials, Swim loop + CardPose, sparkle VFX, bloom, hero + card cameras.
# Run inside Blender: exec with ARGS = [<path to Mosasaurus_T6_rigged.blend>, 'card' or 'swim'].
import bpy, bmesh, math
from mathutils import Vector
SRC, MODE = ARGS[0], (ARGS[1] if len(ARGS) > 1 else 'card')
sc = bpy.data.scenes.get('Mosasaurus T6') or bpy.data.scenes.new('Mosasaurus T6'); bpy.context.window.scene = sc
for win in bpy.context.window_manager.windows:
    if win.screen.is_animation_playing:
        with bpy.context.temp_override(window=win): bpy.ops.screen.animation_cancel(restore_frame=False)

# ---------- model (replace) ----------
for o in list(bpy.data.objects):
    if o.name.startswith('Mosasaurus_T6'): bpy.data.objects.remove(o, do_unlink=True)
for a in [a for a in bpy.data.actions if a.name.startswith(('Swim', 'CardPose'))]: bpy.data.actions.remove(a)
for m in [m for m in bpy.data.materials if m.name.startswith('Mosasaurus_T6')]: bpy.data.materials.remove(m)
for i in [i for i in bpy.data.images if i.name.startswith('Mosasaurus_T6_tex')]: bpy.data.images.remove(i)
for p in [p for p in bpy.data.particles if p.name in ('SparkleTrail', 'CrystalGlints')]: bpy.data.particles.remove(p)
names = ['Mosasaurus_T6Rig', 'Mosasaurus_T6', 'Mosasaurus_T6_Crystals', 'Mosasaurus_T6_Eyes']
with bpy.data.libraries.load(SRC, link=False) as (src, dst):
    dst.objects = [n for n in src.objects if n in names]; dst.actions = [a for a in src.actions if a == 'Swim']
col = bpy.data.collections.get('Mosasaurus_T6') or bpy.data.collections.new('Mosasaurus_T6')
if col.name not in sc.collection.children: sc.collection.children.link(col)
for o in dst.objects: col.objects.link(o)
for im in bpy.data.images:
    if im.name.startswith('Mosasaurus_T6_tex') and not im.packed_file: im.pack()
body, crys, eyes, rig = (bpy.data.objects[n] for n in ('Mosasaurus_T6', 'Mosasaurus_T6_Crystals', 'Mosasaurus_T6_Eyes', 'Mosasaurus_T6Rig'))
base = body.data.materials[0]; bsb = next(n for n in base.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
bsb.inputs['Roughness'].default_value = 0.95
for k in ('Specular IOR Level', 'Specular'):
    if k in bsb.inputs: bsb.inputs[k].default_value = 0.0
def glow(o, name, strength):          # Roblox: Neon on that MeshPart
    m = base.copy(); m.name = name; nt = m.node_tree
    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'); tx = next(n for n in nt.nodes if n.type == 'TEX_IMAGE')
    nt.links.new(tx.outputs['Color'], bs.inputs['Emission Color']); bs.inputs['Emission Strength'].default_value = strength
    o.data.materials[0] = m
glow(crys, 'Mosasaurus_T6_CrystalGlow', 1.6); glow(eyes, 'Mosasaurus_T6_EyeGlow', 3.0)

# ---------- actions: Swim (loop) and CardPose (the card's dive: tail raised, back arched, head down) ----------
swim = dst.actions[0]
for fc in [fc for l in swim.layers for s in l.strips for cb in s.channelbags for fc in cb.fcurves]:
    if not fc.modifiers: fc.modifiers.new('CYCLES')
rig.animation_data_create()
card = bpy.data.actions.new('CardPose'); card.use_fake_user = True; rig.animation_data.action = card
# local X = world +Y on these bones: + pitches the tail up. Spine0 is at the head.
PITCH = [6, 14, 16, 12, 2, -10, -16, -14]     # S-curve: up behind the head, curling back at the tail
YAW = [4, 4, 3, 0, -3, -4, -4, -3]            # a little sideways bend so it reads in 3/4
for i in range(8):
    pb = rig.pose.bones[f'Spine{i}']; pb.rotation_mode = 'XYZ'
    pb.rotation_euler = (math.radians(PITCH[i]), 0, math.radians(YAW[i])); pb.keyframe_insert('rotation_euler', frame=0)
pr = rig.pose.bones['Root']; pr.rotation_mode = 'XYZ'; pr.rotation_euler = (math.radians(-28), 0, 0); pr.keyframe_insert('rotation_euler', frame=0)
pj = rig.pose.bones['Jaw']; pj.rotation_mode = 'XYZ'; pj.rotation_euler = (math.radians(-14), 0, 0); pj.keyframe_insert('rotation_euler', frame=0)
if MODE == 'swim':
    for pb in rig.pose.bones: pb.rotation_euler = (0, 0, 0)
    rig.animation_data.action = swim
act = rig.animation_data.action
if act.slots: rig.animation_data.action_slot = act.slots[0]

# ---------- VFX: sparkle trail + crystal glints (instances of a tiny glowing octahedron), bloom ----------
sp = bpy.data.objects.get('MosaVFX_Sparkle')
if not sp:
    me = bpy.data.meshes.new('MosaVFX_Sparkle'); bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=0, radius=1.0); bm.to_mesh(me); bm.free()
    sp = bpy.data.objects.new('MosaVFX_Sparkle', me); col.objects.link(sp)
sp.location = (0, 0, -500)
sm = bpy.data.materials.get('MosaVFX_SparkleMat') or bpy.data.materials.new('MosaVFX_SparkleMat'); sm.use_nodes = True
bs = next(n for n in sm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
bs.inputs['Base Color'].default_value = (0.4, 1, 1, 1); bs.inputs['Emission Color'].default_value = (0.35, 1, 1, 1); bs.inputs['Emission Strength'].default_value = 8
sp.data.materials.clear(); sp.data.materials.append(sm)
def sparkles(o, name, count, size, vel, life, normal):
    md = o.modifiers.new(name, 'PARTICLE_SYSTEM'); ps = md.particle_system; ps.name = name; s = ps.settings; s.name = name
    s.count = count; s.frame_start = -60; s.frame_end = 200; s.lifetime = life; s.lifetime_random = 0.6
    s.emit_from = 'FACE'; s.use_emit_random = True; s.normal_factor = normal; s.object_align_factor = vel; s.factor_random = 0.25
    s.effector_weights.gravity = 0.0; s.render_type = 'OBJECT'; s.instance_object = sp
    s.particle_size = size; s.size_random = 0.7; s.use_rotations = True; s.rotation_factor_random = 1.0
    ps.point_cache.frame_start = -60; ps.point_cache.frame_end = 250
sparkles(body, 'SparkleTrail', 2600, 0.016, (-1.1, 0, -0.22), 64, 0.25)
sparkles(crys, 'CrystalGlints', 260, 0.02, (-0.4, 0, 0.12), 30, 0.15)
ng = bpy.data.node_groups.get('MosaBloom') or bpy.data.node_groups.new('MosaBloom', 'CompositorNodeTree')
if not ng.nodes:
    ng.interface.new_socket('Image', in_out='INPUT', socket_type='NodeSocketColor'); ng.interface.new_socket('Image', in_out='OUTPUT', socket_type='NodeSocketColor')
    gi, go, gl = ng.nodes.new('NodeGroupInput'), ng.nodes.new('NodeGroupOutput'), ng.nodes.new('CompositorNodeGlare')
    for k, v in (('Threshold', 0.8), ('Strength', 0.9), ('Size', 0.6)): gl.inputs[k].default_value = v
    ng.links.new(gi.outputs[0], gl.inputs['Image']); ng.links.new(gl.outputs['Image'], go.inputs[0])
sc.compositing_node_group = ng

# ---------- world, light, cameras ----------
sc.view_settings.view_transform = 'Standard'
w = sc.world or bpy.data.worlds.new('MosaWorld'); sc.world = w; w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs['Color'].default_value = (0.01, 0.05, 0.12, 1)
if not bpy.data.objects.get('MosaSun'):
    sun = bpy.data.objects.new('MosaSun', bpy.data.lights.new('MosaSun', 'SUN')); sun.data.energy = 3.0; sun.rotation_euler = (0.7, 0.2, 0.6); col.objects.link(sun)
try: sc.render.engine = 'BLENDER_EEVEE'
except TypeError as e: print(e)
def camera(name, pos, target, lens):
    c = bpy.data.objects.get(name) or bpy.data.objects.new(name, bpy.data.cameras.new(name))
    if c.name not in sc.collection.objects: sc.collection.objects.link(c)
    c.location = pos; c.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat('-Z', 'Y').to_euler(); c.data.lens = lens; return c
hero = camera('MosaHeroCam', (2.2, -6.2, 1.6), (-3.0, 0, 0), 40)
cardcam = camera('MosaCardCam', (1.4, -7.2, -0.6), (-2.2, 0, 0.9), 38)   # portrait, like the card
if MODE == 'card': sc.camera = cardcam; sc.render.resolution_x, sc.render.resolution_y = 768, 1024
else: sc.camera = hero; sc.render.resolution_x, sc.render.resolution_y = 1280, 720

# ---------- pre-roll the particles in order, then show ----------
sc.frame_start, sc.frame_end = -60, 23
for f in range(-60, 1): sc.frame_set(f)
sc.frame_start = 0
for win in bpy.context.window_manager.windows:
    for area in win.screen.areas:
        if area.type == 'VIEW_3D':
            sp3 = area.spaces.active; sp3.shading.type = 'RENDERED'; sp3.shading.use_compositor = 'ALWAYS'
            r = next(r for r in area.regions if r.type == 'WINDOW')
            with bpy.context.temp_override(window=win, area=area, region=r):
                sp3.region_3d.view_perspective = 'CAMERA'
                if MODE == 'swim': bpy.ops.screen.animation_play()
            break
print('preview ready:', MODE, sorted(o.name for o in col.objects))
