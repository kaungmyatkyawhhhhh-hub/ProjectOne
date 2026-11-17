# Livyatan T6 - Blender preview of the card look: EEVEE, glow, cyan OUTLINE, BLUE AURA, gold + cyan sparkle trail.
# Owner's card notes: "OUTLINES", "BLUE AURA", arrows at the sparkle trail. Run after livy6_build.py in scene "Livyatan T6".
# In Roblox the same look = Highlight (outline) + Neon runes/eye + ParticleEmitters + PointLight (see the install script).
import bpy, math
from mathutils import Vector
sc = bpy.context.scene
col = bpy.data.collections['Livyatan_T6']
parts = [o for o in col.objects if o.name.startswith('L6_') and 'Shell' not in o.name and 'Spark' not in o.name]
body = [o for o in parts if not o.name.startswith('L6_Runes') and o.name not in ('L6_Eye', 'L6_MouthInterior', 'L6_UpperTeethRow', 'L6_LowerTeethRow')]

def emit_mat(name, rgb, strength, alpha=1.0, back_only=False):
    # back_only: an inverted hull without flipping - only its BACK faces glow, so it shows as a rim round the silhouette
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear(); N, Lk = nt.nodes.new, nt.links.new
    out = N('ShaderNodeOutputMaterial'); em = N('ShaderNodeEmission')
    em.inputs['Color'].default_value = rgb + (1,); em.inputs['Strength'].default_value = strength
    lp = N('ShaderNodeLightPath'); geo = N('ShaderNodeNewGeometry')
    f = lp.outputs['Is Camera Ray']                    # shells never cast shadows (they enclose the body)
    if back_only:
        mul = N('ShaderNodeMath'); mul.operation = 'MULTIPLY'; Lk(f, mul.inputs[0]); Lk(geo.outputs['Backfacing'], mul.inputs[1]); f = mul.outputs[0]
    if alpha < 1:
        mul2 = N('ShaderNodeMath'); mul2.operation = 'MULTIPLY'; Lk(f, mul2.inputs[0]); mul2.inputs[1].default_value = alpha; f = mul2.outputs[0]
        try: m.surface_render_method = 'BLENDED'
        except Exception: pass
    if back_only or alpha < 1:
        m.surface_render_method = 'BLENDED'; m.use_backface_culling = False   # dithered hid the back faces in EEVEE
        tr = N('ShaderNodeBsdfTransparent'); mx = N('ShaderNodeMixShader')
        Lk(f, mx.inputs[0]); Lk(tr.outputs[0], mx.inputs[1]); Lk(em.outputs[0], mx.inputs[2]); Lk(mx.outputs[0], out.inputs['Surface'])
    else: Lk(em.outputs[0], out.inputs['Surface'])
    return m
OUTLINE = emit_mat('L6_Outline', (0.55, 0.95, 1.0), 3.0, back_only=True)
AURA = emit_mat('L6_Aura', (0.1, 0.55, 1.0), 2.5, alpha=0.3, back_only=True)

# outline + aura (preview only; Roblox uses a Highlight). One voxel-remeshed copy of the whole body pushed out along its
# normals, so it rims only the silhouette (per-part shells drew a ring at every armour groove).
import bmesh
for o in body:
    for mod in [m for m in o.modifiers if m.name in ('L6_Outline', 'L6_Aura')]: o.modifiers.remove(mod)
    while len(o.data.materials) > 1: o.data.materials.pop()
for nm, th, mt in (('L6_OutlineShell', 0.03, OUTLINE), ('L6_AuraShell', 0.13, AURA)):
    old = bpy.data.objects.get(nm)
    if old: bpy.data.objects.remove(old, do_unlink=True)
    bm = bmesh.new()
    for o in body: bm.from_mesh(o.data)
    me = bpy.data.meshes.new(nm); bm.to_mesh(me); bm.free(); me.materials.append(mt)
    sh = bpy.data.objects.new(nm, me); col.objects.link(sh)
    rm = sh.modifiers.new('Remesh', 'REMESH'); rm.mode = 'VOXEL'; rm.voxel_size = 0.05
    dp = sh.modifiers.new('Push', 'DISPLACE'); dp.strength = th; dp.mid_level = 0.0

# sparkle trail: tiny glowing octahedra drifting back and down off the body (gold + cyan, like the card)
for nm, rgb in (('L6_SparkGold', (1.0, 0.75, 0.25)), ('L6_SparkCyan', (0.3, 0.95, 1.0))):
    sp = bpy.data.objects.get(nm)
    if not sp:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.045); sp = bpy.context.object; sp.name = nm
        for c in sp.users_collection: c.objects.unlink(sp)
        col.objects.link(sp)
    sp.data.materials.clear(); sp.data.materials.append(emit_mat(nm + 'Mat', rgb, 8.0)); sp.hide_render = sp.hide_viewport = False
    sp.location = (0, 0, -50)
for src, nm, n in (('L6_ArmourSegment4', 'L6_SparkGold', 700), ('L6_ArmourSegment6', 'L6_SparkCyan', 700), ('L6_TailStock', 'L6_SparkCyan', 400), ('L6_ArmourSegment2', 'L6_SparkGold', 500), ('L6_PectoralFinLeft', 'L6_SparkGold', 200), ('L6_PectoralFinRight', 'L6_SparkCyan', 200)):
    o = bpy.data.objects[src]
    for mod in [m for m in o.modifiers if m.type == 'PARTICLE_SYSTEM' and m.name.startswith('Spark')]: o.modifiers.remove(mod)
    ps = o.modifiers.new('Spark_' + nm[3:], 'PARTICLE_SYSTEM').particle_system; s = ps.settings
    ps.point_cache.frame_start = -80   # the cache starts at 1 by default: the pre-roll was never simulated
    s.count = n; s.frame_start = -80; s.frame_end = 200; s.lifetime = 70; s.lifetime_random = 0.6
    s.emit_from = 'FACE'; s.normal_factor = 0.3; s.object_align_factor = (-1.4, 0, -0.5); s.factor_random = 0.25
    s.effector_weights.gravity = 0.0; s.render_type = 'OBJECT'; s.instance_object = bpy.data.objects[nm]
    s.particle_size = 1.0; s.size_random = 0.7; s.use_rotations = True; s.use_dynamic_rotation = True
    s.angular_velocity_mode = 'RAND'; s.angular_velocity_factor = 2.0

# render: EEVEE, Standard view (AgX turns cyan white), deep-sea world, one sun, bloom via compositor glare
for e in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE'):
    try: sc.render.engine = e; break
    except TypeError: pass
sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.get('L6_World') or bpy.data.worlds.new('L6_World'); sc.world = w; w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND'); bg.inputs['Color'].default_value = (0.004, 0.012, 0.045, 1); bg.inputs['Strength'].default_value = 1.0
sun = bpy.data.objects.get('L6_Sun') or bpy.data.objects.new('L6_Sun', bpy.data.lights.new('L6_Sun', 'SUN'))
if sun.name not in sc.collection.objects: sc.collection.objects.link(sun)
sun.data.energy = 3.0; sun.rotation_euler = (math.radians(40), math.radians(-25), math.radians(30))
fill = bpy.data.objects.get('L6_Fill') or bpy.data.objects.new('L6_Fill', bpy.data.lights.new('L6_Fill', 'SUN'))
if fill.name not in sc.collection.objects: sc.collection.objects.link(fill)
fill.data.energy = 1.2; fill.data.color = (0.5, 0.6, 1.0); fill.rotation_euler = (math.radians(120), 0, math.radians(-120))
# hero camera: the card's 3/4 front view
cam = bpy.data.objects.get('L6_HeroCam') or bpy.data.objects.new('L6_HeroCam', bpy.data.cameras.new('L6_HeroCam'))
if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
cam.data.lens = 50; cam.location = (9.5, -9.0, 2.2)
cam.rotation_euler = (Vector((0.6, 0, -0.1)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); sc.camera = cam
sc.render.resolution_x, sc.render.resolution_y = 1280, 960
# eye: its own hotter glow + a small cyan light so it reads like the card (Roblox: Neon + PointLight)
eye = bpy.data.objects['L6_Eye']; em = emit_mat('L6_EyeGlow', (0.45, 1.0, 1.0), 7.0); eye.data.materials.clear(); eye.data.materials.append(em)
for sd in (1, -1):
    nm = 'L6_EyeLight%s' % ('L' if sd > 0 else 'R'); L_ = bpy.data.objects.get(nm) or bpy.data.objects.new(nm, bpy.data.lights.new(nm, 'POINT'))
    if L_.name not in col.objects: col.objects.link(L_)
    vs = [v.co for v in eye.data.vertices if v.co.y * sd > 0]; c = sum(vs, Vector()) / len(vs)
    L_.location = c + Vector((0.05, sd * 0.12, 0)); L_.data.energy = 25; L_.data.color = (0.3, 0.95, 1.0); L_.data.shadow_soft_size = 0.05
for f in range(-80, 1): sc.frame_set(f)   # particle pre-roll: step frames in order or the trail won't form
print('preview ready', len(body), 'outlined parts')
