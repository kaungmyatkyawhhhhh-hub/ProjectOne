# Livyatan T6 - Blender preview of the card look: EEVEE, glow, cyan OUTLINE, BLUE AURA, gold + cyan sparkle trail.
# Owner's card notes: "OUTLINES", "BLUE AURA", arrows at the sparkle trail. Run after livy6_build.py in scene "Livyatan T6".
# In Roblox the same look = Highlight (outline) + Neon runes/eye + ParticleEmitters + PointLight (see the install script).
import bpy, math
from mathutils import Vector
sc = bpy.context.scene
col = bpy.data.collections['Livyatan_T6']
parts = [o for o in col.objects if o.name.startswith('L6_')]
body = [o for o in parts if not o.name.startswith('L6_Runes') and o.name not in ('L6_Eye', 'L6_MouthInterior', 'L6_UpperTeethRow', 'L6_LowerTeethRow')]

def emit_mat(name, rgb, strength, alpha=1.0, cull=True):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Color'].default_value = rgb + (1,); em.inputs['Strength'].default_value = strength
    if alpha < 1:
        tr = nt.nodes.new('ShaderNodeBsdfTransparent'); mix = nt.nodes.new('ShaderNodeMixShader')
        mix.inputs[0].default_value = alpha
        nt.links.new(tr.outputs[0], mix.inputs[1]); nt.links.new(em.outputs[0], mix.inputs[2]); nt.links.new(mix.outputs[0], out.inputs['Surface'])
        try: m.surface_render_method = 'BLENDED'
        except Exception: pass
    else: nt.links.new(em.outputs[0], out.inputs['Surface'])
    # shells must not cast shadows (they enclose the body and black it out): transparent for shadow rays
    lp = nt.nodes.new('ShaderNodeLightPath'); tr2 = nt.nodes.new('ShaderNodeBsdfTransparent'); mx = nt.nodes.new('ShaderNodeMixShader')
    src = out.inputs['Surface'].links[0].from_socket
    nt.links.new(lp.outputs['Is Shadow Ray'], mx.inputs[0]); nt.links.new(src, mx.inputs[1]); nt.links.new(tr2.outputs[0], mx.inputs[2])
    nt.links.new(mx.outputs[0], out.inputs['Surface'])
    m.use_backface_culling = cull   # inverted hull: only the far side of the shell shows = a rim around the silhouette
    return m
OUTLINE = emit_mat('L6_Outline', (0.55, 0.95, 1.0), 3.0)
AURA = emit_mat('L6_Aura', (0.1, 0.55, 1.0), 2.5, alpha=0.28)

# inverted-hull outline + aura on the visible body parts (preview only; Roblox uses a Highlight)
for o in body:
    for mod in [m for m in o.modifiers if m.name in ('L6_Outline', 'L6_Aura')]: o.modifiers.remove(mod)
    while len(o.data.materials) > 1: o.data.materials.pop()
    o.data.materials.append(OUTLINE); o.data.materials.append(AURA)
    for name, th, off in (('L6_Outline', 0.025, 1), ('L6_Aura', 0.11, 2)):
        m = o.modifiers.new(name, 'SOLIDIFY'); m.thickness = th; m.offset = 1; m.use_flip_normals = True
        m.use_rim = False; m.material_offset = off; m.use_even_offset = True

# sparkle trail: tiny glowing octahedra drifting back and down off the body (gold + cyan, like the card)
for nm, rgb in (('L6_SparkGold', (1.0, 0.75, 0.25)), ('L6_SparkCyan', (0.3, 0.95, 1.0))):
    sp = bpy.data.objects.get(nm)
    if not sp:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.025); sp = bpy.context.object; sp.name = nm
        for c in sp.users_collection: c.objects.unlink(sp)
        col.objects.link(sp)
    sp.data.materials.clear(); sp.data.materials.append(emit_mat(nm + 'Mat', rgb, 8.0)); sp.hide_render = sp.hide_viewport = False
    sp.location = (0, 0, -50)
for src, nm, n in (('L6_ArmourSegment4', 'L6_SparkGold', 500), ('L6_ArmourSegment6', 'L6_SparkCyan', 500), ('L6_TailStock', 'L6_SparkCyan', 300), ('L6_ArmourSegment2', 'L6_SparkGold', 300)):
    o = bpy.data.objects[src]
    for mod in [m for m in o.modifiers if m.type == 'PARTICLE_SYSTEM' and m.name.startswith('Spark')]: o.modifiers.remove(mod)
    ps = o.modifiers.new('Spark_' + nm[3:], 'PARTICLE_SYSTEM').particle_system; s = ps.settings
    s.count = n; s.frame_start = -80; s.frame_end = 200; s.lifetime = 70; s.lifetime_random = 0.6
    s.emit_from = 'FACE'; s.normal_factor = 0.15; s.object_align_factor = (-0.5, 0, -0.25); s.factor_random = 0.25
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
sc.frame_set(0)
print('preview ready', len(body), 'outlined parts')
