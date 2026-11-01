# Galaxy Incremental - map kit (2 Nov 2026, Claude Code). Blender 5.2:
#   "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P galaxy_kit.py
# Builds the reusable kit as low-poly FLAT-SHADED meshes (faceted, like the icons), one colour block per piece (the colour
# and material are set in Roblox per piece: stone / brass / neon), and writes:
#   Downloads\galaxy_kit.fbx          every piece, named, each with its origin at its own centre (import into the
#                                     P&L Studios XP place: the map swaps the stand-ins for these by name)
#   Celestial Incremental\Map\galaxy_kit_preview.png   a contact sheet
# Sizes here are in "kit units"; the map sets each MeshPart's Size, so only the proportions matter.
import bpy, bmesh, math, random, os
from mathutils import Vector, Matrix

random.seed(11)
OUT_FBX = os.path.join(os.path.expanduser("~"), "Downloads", "galaxy_kit.fbx")
OUT_PNG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "galaxy_kit_preview.png")

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
PIECES = []


def new_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False  # faceted
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    PIECES.append(o)
    return o


def cyl(bm, r, h, n, z0=0.0, r_top=None, rot=0.0):
    """a prism (or frustum) from z0 to z0+h"""
    r_top = r if r_top is None else r_top
    bot = [bm.verts.new((math.cos(rot + i * 2 * math.pi / n) * r, math.sin(rot + i * 2 * math.pi / n) * r, z0)) for i in range(n)]
    top = [bm.verts.new((math.cos(rot + i * 2 * math.pi / n) * r_top, math.sin(rot + i * 2 * math.pi / n) * r_top, z0 + h)) for i in range(n)]
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    return bot, top


def torus(bm, R, r, maj, mn, mat=None):
    rings = []
    for i in range(maj):
        a = i * 2 * math.pi / maj
        c = Vector((math.cos(a) * R, math.sin(a) * R, 0))
        out = Vector((math.cos(a), math.sin(a), 0))
        ring = []
        for k in range(mn):
            b = k * 2 * math.pi / mn
            p = c + out * math.cos(b) * r + Vector((0, 0, math.sin(b) * r))
            ring.append(bm.verts.new(mat @ p if mat else p))
        rings.append(ring)
    for i in range(maj):
        for k in range(mn):
            a, b = rings[i][k], rings[i][(k + 1) % mn]
            c, d = rings[(i + 1) % maj][(k + 1) % mn], rings[(i + 1) % maj][k]
            bm.faces.new((a, d, c, b))


def ico(bm, r, sub, jitter=0.0, scale=(1, 1, 1), offset=(0, 0, 0)):
    tmp = bmesh.new()
    bmesh.ops.create_icosphere(tmp, subdivisions=sub, radius=r)
    for v in tmp.verts:
        if jitter:
            v.co *= random.uniform(1 - jitter, 1 + jitter)
        v.co = Vector((v.co.x * scale[0] + offset[0], v.co.y * scale[1] + offset[1], v.co.z * scale[2] + offset[2]))
    me = bpy.data.meshes.new("t")
    tmp.to_mesh(me)
    tmp.free()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)


def box(bm, sx, sy, sz, at=(0, 0, 0)):
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(at) @ Matrix.Diagonal((sx, sy, sz, 1)))


def crystal(bm, h, w, at=(0, 0, 0), tilt=(0, 0)):
    m = Matrix.Translation(at) @ Matrix.Rotation(tilt[0], 4, 'X') @ Matrix.Rotation(tilt[1], 4, 'Y')
    ring = [bm.verts.new(m @ Vector((math.cos(i * math.pi / 3) * w, math.sin(i * math.pi / 3) * w, h * 0.12))) for i in range(6)]
    ring2 = [bm.verts.new(m @ Vector((math.cos(i * math.pi / 3) * w * 0.95, math.sin(i * math.pi / 3) * w * 0.95, h * 0.72))) for i in range(6)]
    tip = bm.verts.new(m @ Vector((0, 0, h)))
    bottom = bm.verts.new(m @ Vector((0, 0, 0)))
    for i in range(6):
        j = (i + 1) % 6
        bm.faces.new((ring[i], ring[j], ring2[j], ring2[i]))
        bm.faces.new((ring2[i], ring2[j], tip))
        bm.faces.new((ring[j], ring[i], bottom))


# ------------------------------------------------------------------ the pieces
def p_island_top():
    bm = bmesh.new()
    # a 14-sided slab with a bevelled top edge, a slightly lower inner disc (tile ring)
    cyl(bm, 1.0, 0.14, 14, 0.0, 1.0)
    cyl(bm, 0.97, 0.04, 14, 0.14, 0.93)
    return new_obj("IslandTop", bm)


def p_island_under():
    bm = bmesh.new()
    n = 12
    rows = [(1.0, 0.0), (0.86, -0.25), (0.62, -0.55), (0.32, -0.82), (0.08, -1.0)]
    verts = []
    for ri, (r, z) in enumerate(rows):
        row = []
        for i in range(n):
            a = i * 2 * math.pi / n + ri * 0.13
            jr = r * (random.uniform(0.86, 1.06) if 0 < ri < len(rows) - 1 else 1)
            row.append(bm.verts.new((math.cos(a) * jr, math.sin(a) * jr, z + (random.uniform(-0.04, 0.04) if ri else 0))))
        verts.append(row)
    bm.faces.new(verts[0])
    for ri in range(len(rows) - 1):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((verts[ri][j], verts[ri][i], verts[ri + 1][i], verts[ri + 1][j]))
    bm.faces.new(list(reversed(verts[-1])))
    return new_obj("IslandUnder", bm)


def p_rock():
    bm = bmesh.new()
    ico(bm, 1.0, 1, jitter=0.16, scale=(1.1, 1.0, 0.85))
    return new_obj("RockBare", bm)


def p_ring(name, ratio, maj=48, mn=6):
    bm = bmesh.new()
    torus(bm, 1.0, ratio, maj, mn)
    return new_obj(name, bm)


def p_pillar():
    bm = bmesh.new()
    cyl(bm, 0.22, 0.12, 8, 0.0)          # base
    cyl(bm, 0.12, 1.6, 8, 0.12, 0.1)     # shaft
    cyl(bm, 0.2, 0.1, 8, 1.72)           # capital
    return new_obj("Pillar", bm)


def p_lamp():
    bm = bmesh.new()
    ico(bm, 1.0, 1)
    return new_obj("LampOrb", bm)


def p_crystal_cluster():
    bm = bmesh.new()
    crystal(bm, 1.6, 0.3, (0, 0, 0), (0.05, 0.08))
    crystal(bm, 1.1, 0.24, (0.35, 0.15, 0), (0.3, 0.35))
    crystal(bm, 0.9, 0.2, (-0.32, 0.2, 0), (-0.25, -0.4))
    crystal(bm, 0.7, 0.18, (0.05, -0.36, 0), (0.45, -0.1))
    return new_obj("CrystalCluster", bm)


def p_crystal():
    bm = bmesh.new()
    crystal(bm, 1.0, 0.22)
    return new_obj("Crystal", bm)


def p_banner():
    bm = bmesh.new()
    # a hanging flag with a swallowtail, a slight wave (3 columns), thin
    cols = 4
    pts_top, pts_bot = [], []
    for i in range(cols + 1):
        x = i / cols
        dy = math.sin(x * math.pi * 1.3) * 0.06
        pts_top.append((x - 0.5, dy, 0.5))
        pts_bot.append((x - 0.5, dy, -0.5 + (0.22 if i == cols // 2 else 0)))
    front = []
    for i in range(cols):
        a = bm.verts.new(pts_bot[i]); b = bm.verts.new(pts_bot[i + 1]); c = bm.verts.new(pts_top[i + 1]); d = bm.verts.new(pts_top[i])
        bm.faces.new((a, b, c, d))
    box(bm, 1.08, 0.08, 0.06, (0, 0, 0.53))  # the rod on top
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.03) if hasattr(bmesh.ops, "solidify") else None
    return new_obj("Banner", bm)


def p_telescope():
    bm = bmesh.new()
    # tripod
    for k in range(3):
        a = k * 2 * math.pi / 3
        m = Matrix.Translation((math.cos(a) * 0.28, math.sin(a) * 0.28, 0.45)) @ Matrix.Rotation(-0.35, 4, Vector((-math.sin(a), math.cos(a), 0)))
        tmp = bmesh.new()
        cyl(tmp, 0.035, 0.95, 6, -0.475)
        bmesh.ops.transform(tmp, matrix=m, verts=tmp.verts)
        me = bpy.data.meshes.new("t"); tmp.to_mesh(me); tmp.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    # the tube, tilted up, wider at the front
    tmp = bmesh.new()
    cyl(tmp, 0.1, 1.2, 10, -0.5, 0.15)
    cyl(tmp, 0.17, 0.12, 10, 0.7)
    bmesh.ops.transform(tmp, matrix=Matrix.Translation((0, 0, 1.0)) @ Matrix.Rotation(-0.95, 4, 'X'), verts=tmp.verts)
    me = bpy.data.meshes.new("t"); tmp.to_mesh(me); tmp.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    return new_obj("Telescope", bm)


def p_dais():
    bm = bmesh.new()
    cyl(bm, 1.0, 0.12, 12, 0.0)
    cyl(bm, 0.82, 0.12, 12, 0.12)
    cyl(bm, 0.6, 0.1, 12, 0.24, 0.56)
    return new_obj("Dais", bm)


def p_board_frame():
    bm = bmesh.new()
    # a brass frame round a screen (1.0 x 0.6), a crest on top, two legs
    w, h, t, d = 1.0, 0.62, 0.06, 0.08
    box(bm, w + 2 * t, d, t, (0, 0, h / 2 + t / 2))
    box(bm, w + 2 * t, d, t, (0, 0, -h / 2 - t / 2))
    box(bm, t, d, h, (-w / 2 - t / 2, 0, 0))
    box(bm, t, d, h, (w / 2 + t / 2, 0, 0))
    box(bm, w, 0.02, h, (0, d / 2 - 0.01, 0))  # back plate
    box(bm, 0.22, d, 0.08, (0, 0, h / 2 + t + 0.04))
    for x in (-0.42, 0.42):
        box(bm, 0.05, 0.05, 0.42, (x, 0, -h / 2 - t - 0.21))
    return new_obj("BoardFrame", bm)


def p_bridge_segment():
    bm = bmesh.new()
    # a slab with chamfered long edges (faceted), 1 long x 1 wide x 0.12
    pts = [(-0.5, -0.5, 0.0), (0.5, -0.5, 0.0), (0.5, 0.5, 0.0), (-0.5, 0.5, 0.0)]
    tmp = bmesh.new()
    box(tmp, 1.0, 1.0, 0.12)
    bmesh.ops.bevel(tmp, geom=[e for e in tmp.edges if abs(e.verts[0].co.y - e.verts[1].co.y) < 1e-6 and abs(e.verts[0].co.x - e.verts[1].co.x) > 0.5],
                    offset=0.03, segments=1, affect='EDGES')
    me = bpy.data.meshes.new("t"); tmp.to_mesh(me); tmp.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    _ = pts
    return new_obj("BridgeSegment", bm)


def p_grass():
    bm = bmesh.new()
    n = 9
    ring = [bm.verts.new((math.cos(i * 2 * math.pi / n) * random.uniform(0.8, 1.0), math.sin(i * 2 * math.pi / n) * random.uniform(0.8, 1.0), 0)) for i in range(n)]
    top = [bm.verts.new((v.co.x * 0.92, v.co.y * 0.92, 0.06)) for v in ring]
    bm.faces.new(list(reversed(ring)))
    bm.faces.new(top)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((ring[i], ring[j], top[j], top[i]))
    return new_obj("GrassPatch", bm)


def p_altar():
    bm = bmesh.new()
    cyl(bm, 1.0, 0.24, 8, 0.0, rot=math.pi / 8)
    cyl(bm, 0.82, 0.16, 8, 0.24, rot=math.pi / 8)
    cyl(bm, 0.6, 0.14, 8, 0.40, 0.55, rot=math.pi / 8)
    return new_obj("Altar", bm)


def p_spike():
    bm = bmesh.new()
    cyl(bm, 0.5, 1.0, 4, -0.5, 0.0)
    return new_obj("CoreSpike", bm)


def p_orb(name, sub):
    bm = bmesh.new()
    ico(bm, 1.0, sub)
    return new_obj(name, bm)


def p_anvil():
    bm = bmesh.new()
    box(bm, 1.0, 0.42, 0.24, (0, 0, 0.62))      # face
    box(bm, 0.38, 0.3, 0.36, (0, 0, 0.32))      # waist
    box(bm, 0.66, 0.42, 0.14, (0, 0, 0.07))     # foot
    tmp = bmesh.new()
    cyl(tmp, 0.21, 0.42, 8, 0.0, 0.0)           # horn
    bmesh.ops.transform(tmp, matrix=Matrix.Translation((-0.5, 0, 0.62)) @ Matrix.Rotation(-math.pi / 2, 4, 'Y'), verts=tmp.verts)
    me = bpy.data.meshes.new("t"); tmp.to_mesh(me); tmp.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    return new_obj("Anvil", bm)


def p_padlock():
    bm = bmesh.new()
    box(bm, 0.7, 0.26, 0.56, (0, 0, 0.28))
    torus(bm, 0.24, 0.06, 16, 6, Matrix.Translation((0, 0, 0.6)) @ Matrix.Rotation(math.pi / 2, 4, 'X'))
    return new_obj("Padlock", bm)


def p_arch():
    bm = bmesh.new()
    # two square posts and a pointed arch top, chunky
    box(bm, 0.18, 0.18, 1.3, (-0.6, 0, 0.65))
    box(bm, 0.18, 0.18, 1.3, (0.6, 0, 0.65))
    n = 9
    for i in range(n):
        a0 = math.pi * i / n
        a1 = math.pi * (i + 1) / n
        p0 = Vector((math.cos(a0) * 0.6, 0, 1.3 + math.sin(a0) * 0.45))
        p1 = Vector((math.cos(a1) * 0.6, 0, 1.3 + math.sin(a1) * 0.45))
        mid = (p0 + p1) / 2
        ln = (p1 - p0).length
        ang = math.atan2(p1.z - p0.z, p1.x - p0.x)
        tmp = bmesh.new()
        box(tmp, ln + 0.06, 0.18, 0.18)
        bmesh.ops.transform(tmp, matrix=Matrix.Translation(mid) @ Matrix.Rotation(-ang, 4, 'Y'), verts=tmp.verts)
        me = bpy.data.meshes.new("t"); tmp.to_mesh(me); tmp.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    box(bm, 0.24, 0.24, 0.12, (-0.6, 0, 0.06))
    box(bm, 0.24, 0.24, 0.12, (0.6, 0, 0.06))
    return new_obj("GateArch", bm)


def p_gate_ring():
    bm = bmesh.new()
    torus(bm, 1.0, 0.15, 40, 6)
    for k in range(8):  # brass studs round it
        a = k * math.pi / 4
        box(bm, 0.14, 0.14, 0.34, (math.cos(a) * 1.13, math.sin(a) * 1.13, 0))
    return new_obj("GateRing", bm)


def p_void():
    bm = bmesh.new()
    n = 40
    c = bm.verts.new((0, 0, 0))
    ring = [bm.verts.new((math.cos(i * 2 * math.pi / n), math.sin(i * 2 * math.pi / n), 0)) for i in range(n)]
    for i in range(n):
        bm.faces.new((c, ring[i], ring[(i + 1) % n]))
    bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.04) if hasattr(bmesh.ops, "solidify") else None
    return new_obj("VoidDisc", bm)


p_island_top(); p_island_under(); p_rock()
p_ring("RimRing", 0.03); p_ring("GyroRing", 0.035, 48, 6); p_ring("OrbitRing", 0.012, 48, 4); p_ring("ShockRing", 0.02, 64, 4)
p_pillar(); p_lamp(); p_crystal_cluster(); p_crystal(); p_banner(); p_telescope(); p_dais(); p_board_frame()
p_bridge_segment(); p_grass(); p_altar(); p_spike(); p_orb("CoreOrb", 2); p_orb("Planet", 1); p_anvil(); p_padlock()
p_arch(); p_gate_ring(); p_void()

# every piece's origin at its own bounds centre; Blender Z up -> the FBX exporter turns it to Y up for Roblox
for o in PIECES:
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
for o in PIECES:
    o.select_set(False)
# lay them out in a grid (only for the preview and a tidy import; the map places them itself)
for i, o in enumerate(PIECES):
    o.location = ((i % 7) * 3.2, -(i // 7) * 3.2, 0)
    dims = max(o.dimensions)
    if dims > 2.4:
        pass

for o in PIECES:
    o.select_set(True)
bpy.ops.export_scene.fbx(filepath=OUT_FBX, use_selection=True, apply_unit_scale=True, axis_forward='-Z', axis_up='Y',
                         mesh_smooth_type='FACE', object_types={'MESH'})
print("FBX:", OUT_FBX, len(PIECES), "pieces:", ", ".join(o.name for o in PIECES))

# preview sheet
mat = bpy.data.materials.new("prev")
mat.diffuse_color = (0.85, 0.72, 0.5, 1)
for o in PIECES:
    o.data.materials.append(mat)
cam_d = bpy.data.cameras.new("cam")
cam_d.type = 'ORTHO'
cam_d.ortho_scale = 24
cam = bpy.data.objects.new("cam", cam_d)
scene.collection.objects.link(cam)
cam.location = (9.6, -14, 14)
cam.rotation_euler = (math.radians(50), 0, 0)
scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", 'SUN'))
sun.data.energy = 3
sun.rotation_euler = (math.radians(40), math.radians(20), math.radians(30))
scene.collection.objects.link(sun)
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.display.shading.show_cavity = True
scene.render.resolution_x, scene.render.resolution_y = 1400, 1000
scene.render.filepath = OUT_PNG
bpy.ops.render.render(write_still=True)
print("PNG:", OUT_PNG)
