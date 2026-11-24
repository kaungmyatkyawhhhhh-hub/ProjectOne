# GYM ARC icon render (25 Nov): bright daylight gym set, lights, giant dumbbell, camera. Run after icon_hero.py in the same globals.
import bpy, math
from mathutils import Vector, Matrix

def clear_col(name):
    c = bpy.data.collections.get(name)
    if c:
        for o in list(c.objects): bpy.data.objects.remove(o)
        bpy.data.collections.remove(c)
    c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c); return c

def mat(name, color, rough=0.5, metal=0.0, **kw):
    m = bpy.data.materials.get(name) or principled(name, srgb(color), rough, metal, **kw)
    return m

def box(name, size, loc, m, col, bevel=0.0, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        md = o.modifiers.new("B", "BEVEL"); md.width = bevel; md.segments = 3
    o.data.materials.append(m); link(o, col); return o

def cyl(name, r, depth, loc, m, col, rot=(0,0,0), verts=48, bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    if bevel:
        md = o.modifiers.new("B", "BEVEL"); md.width = bevel; md.segments = 4; md.limit_method = "ANGLE"
    bpy.ops.object.shade_smooth(); o.data.materials.append(m); link(o, col); return o

def build_set():
    col = clear_col("SET")
    floor_m = mat("RubberFloor", "#3A3D42", 0.85)
    wall_m = mat("WallWhite", "#E8E6E1", 0.8)
    frame_m = mat("WindowFrame", "#1B1D22", 0.4, 0.6)
    chrome = mat("Chrome", "#E6E9ED", 0.12, 1.0)
    iron = mat("IronBlack", "#16171A", 0.45, 0.6)
    sky = bpy.data.materials.get("SkyWindow") or emission("SkyWindow", srgb("#DCEBFF"), 9.0)
    box("Floor", (60, 60, 0.2), (0, -10, -0.1), floor_m, col)
    box("BackWall", (60, 0.4, 22), (0, -16, 11), wall_m, col)
    box("Ceiling", (60, 40, 0.3), (0, -4, 17), wall_m, col)
    panel = bpy.data.materials.get("CeilPanel") or emission("CeilPanel", srgb("#FFF6E8"), 12.0)
    for i in range(-3, 4):
        for j in range(4):
            box(f"CeilLight{i}{j}", (5.5, 0.9, 0.1), (i * 7.5, -13 + j * 6, 16.8), panel, col)
    # three tall windows in the back wall, bright sky behind
    for i, x in enumerate((-12, 0, 12)):
        box(f"WinSky{i}", (8, 0.1, 11), (x, -15.75, 8.5), sky, col)
        for dx in (-4, 0, 4):
            box(f"WinMullV{i}{dx}", (0.25, 0.3, 11.4), (x + dx, -15.6, 8.5), frame_m, col)
        for z in (3.0, 8.5, 14.0):
            box(f"WinMullH{i}{z}", (8.4, 0.3, 0.25), (x, -15.6, z), frame_m, col)
    # squat racks (chrome) with black iron plates, left and right behind him
    for side, x in (("L", -7.5), ("R", 7.5)):
        for dx in (-1.4, 1.4):
            for dy in (-0.9, 0.9):
                cyl(f"Rack{side}{dx}{dy}", 0.12, 8, (x + dx, -9 + dy, 4), chrome, col, verts=24)
        for z in (7.9, 4.5):
            box(f"RackBar{side}{z}", (3.1, 0.18, 0.18), (x, -8.1, z), chrome, col)
        bar = cyl(f"RackBarbell{side}", 0.09, 7, (x, -8.1, 4.75), chrome, col, rot=(0, math.radians(90), 0), verts=24)
        for s in (-1, 1):
            for k in range(3):
                cyl(f"RackPlate{side}{s}{k}", 1.1 - 0.12 * k, 0.22, (x + s * (2.2 + 0.25 * k), -8.1, 4.75), iron, col, rot=(0, math.radians(90), 0), verts=64, bevel=0.03)
    # a plate tree / dumbbell rack row on the floor further back
    for i in range(7):
        cyl(f"FloorPlate{i}", 0.9, 0.2, (-10 + i * 3.3, -13.2, 0.9), iron, col, rot=(math.radians(90), 0, 0), verts=64, bevel=0.03)
    return col

def plate_text_material():
    return bpy.data.materials.get("PlateText") or principled("PlateText", srgb("#FFFFFF"), 0.35)

def build_dumbbell(hand_obj, axis, R=1.85, scale=1.0, inner=1.55, center=None, inner_text=False):
    """giant dumbbell held in hand_obj; axis = handle direction (world). Plates: deep electric-blue rubber, '1000 LB' in white."""
    col = clear_col("DUMBBELL")
    blue = mat("PlateBlue", "#0E5BFF", 0.42, 0.0, **{"Coat Weight": 0.25, "Coat Roughness": 0.3})
    rimm = mat("PlateRim", "#0A1A3A", 0.35, 0.4)
    chrome = mat("Chrome", "#E6E9ED", 0.12, 1.0)
    txt_m = plate_text_material()
    root = bpy.data.objects.new("DB_ROOT", None); col.objects.link(root)
    pieces = []
    pieces.append(cyl("DB_Handle", 0.28 if inner < 2 else 0.2, 2 * inner + 0.1, (0, 0, 0), chrome, col, verts=48))
    for s in (-1, 1):
        pieces.append(cyl(f"DB_Collar{s}", 0.42, 0.35, (0, 0, s * (inner - 0.4)), chrome, col, verts=48, bevel=0.04))
        for k in range(2):
            z = s * (inner + 0.62 * k)
            p = cyl(f"DB_Plate{s}{k}", R - 0.1 * k, 0.55, (0, 0, z), blue, col, verts=96, bevel=0.08); pieces.append(p)
            pieces.append(cyl(f"DB_Rim{s}{k}", R - 0.1 * k + 0.02, 0.18, (0, 0, z), rimm, col, verts=96, bevel=0.05))
        # the hub + label on the OUTER face
        zf = s * (inner + 0.62 + 0.28)
        pieces.append(cyl(f"DB_Hub{s}", 0.34, 0.12, (0, 0, zf), chrome, col, verts=48, bevel=0.03))
        faces = [(zf, s)] + ([(s * (inner - 0.28 - 0.02), -s)] if inner_text else [])
        for (zface, sgn), (j, (word, yy)) in [(f, w) for f in faces for w in enumerate((("1000", 0.50), ("LB", -0.53)))]:
            bpy.ops.object.text_add(location=(0, 0, 0))
            t = bpy.context.active_object; t.name = f"DB_Text{s}{sgn}{j}"
            t.data.body = word; t.data.align_x = "CENTER"; t.data.align_y = "CENTER"
            t.data.size = 0.66 * R if word == "1000" else 0.6 * R; t.data.extrude = 0.04
            try:
                t.data.font = bpy.data.fonts.load(r"C:\Windows\Fonts\impact.ttf", check_existing=True)
            except Exception: pass
            t.data.materials.append(txt_m)
            link(t, col)
            # flat on the OUTER face (local XY plane), above / below the hub, reading upright
            t.location = (0, yy * R, zface + sgn * 0.07)
            t.rotation_euler = (0, 0 if sgn > 0 else math.pi, 0)
            pieces.append(t)
    for p in pieces: p.parent = root
    # orient: local Z -> axis, centred on the hand
    z = Vector(axis).normalized(); up = Vector((0, 0, 1))
    y = (up - z * up.dot(z)).normalized(); x = y.cross(z)
    m = Matrix((x, y, z)).transposed().to_4x4(); m.translation = Vector(center) if center is not None else hand_obj.matrix_world.translation
    root.matrix_world = m @ Matrix.Scale(scale, 4)
    return root

def lights_and_world(target=(0, 0, 4.5)):
    col = clear_col("LIGHTS")
    def area(name, loc, color, power, size):
        d = bpy.data.lights.new(name, "AREA"); d.color = color; d.energy = power; d.size = size; d.shape = "DISK"
        o = bpy.data.objects.new(name, d); col.objects.link(o); o.location = loc
        dirv = Vector(target) - Vector(loc); o.rotation_euler = dirv.to_track_quat("-Z", "Y").to_euler()
        return o
    sun = bpy.data.lights.new("SunKey", "SUN"); sun.energy = 4.5; sun.color = (1.0, 0.86, 0.68); sun.angle = math.radians(4)
    so = bpy.data.objects.new("SunKey", sun); col.objects.link(so)
    so.rotation_euler = (math.radians(55), 0, math.radians(150))
    area("KeySoft", (-7, 9, 9), (1.0, 0.9, 0.78), 2600, 6)
    area("Fill", (8, 10, 4), (0.82, 0.9, 1.0), 900, 8)
    area("RimL", (-6, -6, 9), (0.85, 0.92, 1.0), 2200, 3)
    area("RimR", (6, -6, 9), (0.85, 0.92, 1.0), 2200, 3)
    w = bpy.context.scene.world or bpy.data.worlds.new("W"); bpy.context.scene.world = w
    w.use_nodes = True; bg = w.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (*srgb("#CFE2FF"), 1); bg.inputs[1].default_value = 0.9
    return col

def camera(loc, target, lens=32, fstop=2.2, focus=None, name="CAM_icon"):
    o = bpy.data.objects.get(name)
    if not o:
        cd = bpy.data.cameras.new(name); o = bpy.data.objects.new(name, cd); bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    o.data.lens = lens; o.data.dof.use_dof = True; o.data.dof.aperture_fstop = fstop
    o.data.dof.focus_distance = focus or (Vector(target) - Vector(loc)).length
    bpy.context.scene.camera = o
    return o

def render_settings(res=1024, samples=256):
    s = bpy.context.scene
    s.render.engine = "CYCLES"; s.cycles.samples = samples; s.cycles.use_denoising = True
    s.render.resolution_x = s.render.resolution_y = res; s.render.resolution_percentage = 100
    s.view_settings.view_transform = "AgX"; s.view_settings.look = "AgX - Medium High Contrast"
    s.render.film_transparent = False
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        for t in ("OPTIX", "CUDA"):
            try:
                prefs.compute_device_type = t; prefs.get_devices()
                if any(d.type == t for d in prefs.devices): break
            except Exception: pass
        for d in prefs.devices: d.use = d.type != "CPU"
        s.cycles.device = "GPU"
    except Exception as e: print("GPU", e)
