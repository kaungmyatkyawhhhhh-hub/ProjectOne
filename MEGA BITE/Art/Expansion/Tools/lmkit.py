"""MEGA BITE landmark kit (13 Nov night). Procedural Blender modelling helpers for the expansion landmarks/creatures.
Every colour region is its own object named '<Part>__<colourkey>' (one MeshPart each in Roblox: flat colour + material,
no texture), smooth shading with an angle limit, Z up in Blender (exported Y up)."""
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, noise

PAL = {}
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
def mat(key, rgb):
    PAL[key] = rgb
    m = bpy.data.materials.get(key) or bpy.data.materials.new(key)
    c = (rgb[0]/255, rgb[1]/255, rgb[2]/255, 1); m.diffuse_color = c
    m.use_nodes = True; b = m.node_tree.nodes.get('Principled BSDF')
    if b: b.inputs['Base Color'].default_value = c
    return m
def obj_from_bm(bm, name, key):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name + '__' + key, me); bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(bpy.data.materials[key])
    for p in me.polygons: p.use_smooth = True
    return ob
def ring(c, t, n, rx, ry, rot=0.0, jitter=0.0, seed=0):
    """points of a ring at centre c, tangent t (Vector), n points, radii rx (side) ry (up-ish)"""
    t = t.normalized(); up = Vector((0, 0, 1)) if abs(t.z) < 0.95 else Vector((1, 0, 0))
    a = t.cross(up).normalized(); b = a.cross(t).normalized()
    rnd = random.Random(seed); pts = []
    for i in range(n):
        th = 2 * math.pi * i / n + rot
        j = 1 + (rnd.uniform(-jitter, jitter) if jitter else 0)
        pts.append(c + (a * math.cos(th) * rx + b * math.sin(th) * ry) * j)
    return pts
def loft(rings, name, key, cap0=True, cap1=True):
    bm = bmesh.new(); vs = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(rings[0])
    for k in range(len(vs) - 1):
        for i in range(n):
            bm.faces.new((vs[k][i], vs[k][(i+1) % n], vs[k+1][(i+1) % n], vs[k+1][i]))
    if cap0: bm.faces.new(list(reversed(vs[0])))
    if cap1: bm.faces.new(vs[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, key)
def tube(path, radii, name, key, sides=10, ry=None, jitter=0.0, seed=0, cap=True, side_ref=None):
    """a tube along a list of points with per-point radius (ry = second radius factor); parallel-transport frames (no twist)"""
    rnd = random.Random(seed)
    T = [(path[min(i+1, len(path)-1)] - path[max(i-1, 0)]).normalized() for i in range(len(path))]
    ref = side_ref or Vector((0, 1, 0))
    a = (ref - T[0] * ref.dot(T[0]))
    if a.length < 1e-4: a = T[0].orthogonal()
    a.normalize()
    rings = []
    for i, p in enumerate(path):
        if i > 0:
            q = T[i-1].rotation_difference(T[i]); a = (q @ a); a = (a - T[i] * a.dot(T[i])).normalized()
        b = T[i].cross(a).normalized()
        r = radii[i]; r2 = r * (ry[i] if ry else 1)
        pts = []
        for k in range(sides):
            th = 2 * math.pi * k / sides
            j = 1 + (rnd.uniform(-jitter, jitter) if jitter else 0)
            pts.append(p + (a * math.cos(th) * r2 + b * math.sin(th) * r) * j)
        rings.append(pts)
    return loft(rings, name, key, cap, cap)
def lathe(profile, name, key, sides=24, z0=0.0, cap=True, jitter=0.0, seed=0):
    """profile = [(r, z)] bottom to top"""
    rnd = random.Random(seed)
    rings = []
    for (r, z) in profile:
        rings.append([Vector((math.cos(2*math.pi*i/sides) * r * (1 + rnd.uniform(-jitter, jitter)),
                              math.sin(2*math.pi*i/sides) * r * (1 + rnd.uniform(-jitter, jitter)), z + z0)) for i in range(sides)])
    return loft(rings, name, key, cap, cap)
def rock(c, size, name, key, seed=0, sub=2, rough=0.22, flat_bottom=True):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    off = Vector((seed * 3.1, seed * 1.7, seed * 2.3))
    for v in bm.verts:
        d = 1 + rough * noise.noise(v.co * 1.3 + off) + rough * 0.5 * noise.noise(v.co * 2.9 + off)
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) * d
        if flat_bottom and v.co.z < -size[2] * 0.35: v.co.z = -size[2] * 0.35
        v.co += c
    return obj_from_bm(bm, name, key)
def crystal(base, direction, length, radius, name, key, sides=6, tip=0.35, seed=0):
    d = direction.normalized(); top = base + d * length * (1 - tip); apex = base + d * length
    r0 = ring(base - d * radius * 0.6, d, sides, radius * 0.85, radius * 0.85, rot=seed)
    r1 = ring(top, d, sides, radius, radius, rot=seed)
    bm = bmesh.new(); a = [bm.verts.new(p) for p in r0]; b = [bm.verts.new(p) for p in r1]; ap = bm.verts.new(apex)
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((a[i], a[j], b[j], b[i])); bm.faces.new((b[i], b[j], ap))
    bm.faces.new(list(reversed(a)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = obj_from_bm(bm, name, key)
    for p in ob.data.polygons: p.use_smooth = False   # crystals: crisp facets
    return ob
def disc(c, normal, r, h, name, key, sides=16, squash=1.0):
    n = normal.normalized()
    bm = bmesh.new(); r0 = [bm.verts.new(p) for p in ring(c, n, sides, r, r * squash)]
    r1 = [bm.verts.new(p) for p in ring(c + n * h, n, sides, r * 0.92, r * 0.92 * squash)]
    for i in range(sides):
        j = (i+1) % sides; bm.faces.new((r0[i], r0[j], r1[j], r1[i]))
    bm.faces.new(list(reversed(r0))); bm.faces.new(r1); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(bm, name, key)
def join_by_key():
    """merge every object with the same colour key into one object (one MeshPart per colour)"""
    groups = {}
    for ob in list(bpy.context.scene.objects):
        if ob.type != 'MESH': continue
        k = ob.name.split('__')[-1].split('.')[0]; groups.setdefault(k, []).append(ob)
    out = []
    for k, obs in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in obs: o.select_set(True)
        bpy.context.view_layer.objects.active = obs[0]
        if len(obs) > 1: bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active; o.name = k; o.data.name = k; out.append(o)
    return out
def finish(angle=40):
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            try:
                bpy.context.view_layer.objects.active = o; o.select_set(True)
                bpy.ops.object.shade_auto_smooth(angle=math.radians(angle))
            except Exception: pass
def tris():
    t = 0
    for o in bpy.context.scene.objects:
        if o.type == 'MESH':
            o.data.calc_loop_triangles(); t += len(o.data.loop_triangles)
    return t
def export(path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, axis_forward='-Z', axis_up='Y', apply_unit_scale=True,
                             global_scale=1.0, mesh_smooth_type='FACE', add_leaf_bones=False, bake_space_transform=True)
def export_obj(path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.obj_export(filepath=path, export_selected_objects=True, forward_axis='NEGATIVE_Z', up_axis='Y', export_materials=True, apply_modifiers=True, export_normals=True)
def render(prefix, shots=((35, 22), (145, 18), (-90, 8), (0, 0)), res=(900, 600), target=None, dist=1.7):
    sc = bpy.context.scene; sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'MATERIAL'; sh.show_backface_culling = True
    sh.show_cavity = True; sh.cavity_type = 'WORLD'
    sc.render.resolution_x, sc.render.resolution_y = res
    w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.12, 0.32, 0.55)
    sc.render.film_transparent = False
    mn = Vector((1e9,)*3); mx = Vector((-1e9,)*3)
    for o in sc.objects:
        if o.type == 'MESH':
            for c in o.bound_box:
                p = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, p)); mx = Vector(map(max, mx, p))
    centre = (mn + mx) / 2 if target is None else target; R = (mx - mn).length * dist
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam')); sc.collection.objects.link(cam); sc.camera = cam; cam.data.lens = 50
    files = []
    for i, (az, el) in enumerate(shots):
        a, e = math.radians(az), math.radians(el)
        cam.location = centre + Vector((math.cos(a)*math.cos(e), math.sin(a)*math.cos(e), math.sin(e))) * R
        cam.rotation_euler = (centre - cam.location).to_track_quat('-Z', 'Y').to_euler()
        f = f'{prefix}_{i}.png'; sc.render.filepath = f; bpy.ops.render.render(write_still=True); files.append(f)
    bpy.data.objects.remove(cam)
    return files
