# Stomp Evolution props v1: chunky premium-toy cartoon kit (concept sheet stomp_city_props.png).
# Authoring axes: x = Roblox X, y = Roblox Z, z = up. Units = studs. Fronts face -y (Roblox -Z). Vehicles face +x.
import bpy, bmesh, math, random
from mathutils import Vector, Matrix, Euler
PAL = {  # name: (r,g,b) 0-255 ; 16x16 swatch grid, 16 px cells
 'cream':(246,226,186),'cream2':(232,206,160),'white':(250,247,240),'trim':(236,226,204),'stone':(150,152,160),'stone2':(118,120,130),
 'roof_red':(214,58,48),'roof_red2':(176,40,38),'roof_blue':(44,98,214),'roof_blue2':(32,70,170),'roof_teal':(26,150,170),'roof_teal2':(18,112,130),
 'wall_mint':(124,224,196),'wall_yellow':(252,214,78),'wall_pink':(250,170,180),'wall_sky':(150,200,250),'wall_brick':(204,104,74),'wall_brick2':(170,80,60),
 'wood':(150,92,52),'wood2':(112,66,38),'door':(128,74,42),'gold':(250,196,40),'glass':(80,170,236),'glass2':(160,220,255),'glassdark':(40,96,160),
 'leaf':(110,200,60),'leaf2':(70,160,48),'leaf3':(150,226,80),'soil':(110,72,46),'bark':(120,80,50),
 'red':(222,52,52),'red2':(170,36,40),'blue':(44,120,230),'blue2':(28,82,180),'green':(52,190,110),'green2':(30,140,80),'orange':(255,150,40),'orange2':(220,110,24),
 'yellow':(255,214,40),'yellow2':(226,170,20),'violet':(150,100,230),'pink':(250,110,170),'sky':(90,200,250),'tyre':(46,48,58),'rim':(196,200,210),'chrome':(220,224,232),
 'light':(255,240,150),'tail':(255,80,70),'black':(36,38,48),'grey':(170,174,184),'grey2':(110,114,126),'concrete':(206,204,198),'concrete2':(178,176,170),
 'awn_red':(234,64,60),'awn_white':(252,248,240),'awn_green':(60,180,110),'awn_blue':(60,130,230),'awn_yellow':(255,200,50),'tank':(120,130,150),
 'petal_w':(252,252,252),'petal_y':(255,220,60),'petal_p':(255,120,180),'petal_v':(170,120,240),'petal_s':(110,200,255),'petal_o':(255,160,60),
 'seat':(60,52,48),'lilac':(200,180,250),'mint2':(90,190,160),'yellow3':(255,236,140),'sign':(255,250,235),
}
NAMES = list(PAL.keys())
assert len(NAMES) <= 256
def uv_of(col):
    i = NAMES.index(col); cx = (i % 16 + 0.5) / 16; cy = 1 - (i // 16 + 0.5) / 16; return (cx, cy)
def palette_png(path):
    img = bpy.data.images.new("pal", 256, 256); px = [0.0] * (256 * 256 * 4)
    for i, n in enumerate(NAMES):
        r, g, b = PAL[n]; c0, r0 = (i % 16) * 16, 15 - i // 16
        for y in range(r0 * 16, r0 * 16 + 16):
            for x in range(c0, c0 + 16):
                k = (y * 256 + x) * 4; px[k:k + 4] = [r / 255, g / 255, b / 255, 1]
    img.pixels = px; img.filepath_raw = path; img.file_format = 'PNG'; img.save()
PARTS = []
def _finish(o, col, bev, seg=2, ang=40):
    if bev and bev > 0:
        m = o.modifiers.new("b", 'BEVEL'); m.width = bev; m.segments = seg; m.limit_method = 'ANGLE'; m.angle_limit = math.radians(ang)
        m.harden_normals = False
        bpy.context.view_layer.objects.active = o; bpy.ops.object.modifier_apply(modifier="b")
    me = o.data
    if not me.uv_layers: me.uv_layers.new(name="UVMap")
    u = uv_of(col)
    for l in me.uv_layers.active.data: l.uv = u
    PARTS.append(o); return o
def _place(o, loc, rot):
    o.location = Vector(loc)
    if rot: o.rotation_euler = Euler([math.radians(a) for a in rot], 'XYZ')
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True); o.select_set(False)
def box(sz, loc, col, bev=0.12, rot=None, seg=1):
    bpy.ops.mesh.primitive_cube_add(size=1); o = bpy.context.object; o.scale = Vector(sz) ; _place(o, loc, rot)
    o.location = Vector(loc); return _finish(o, col, min(bev, min(sz) * 0.45), seg)
def cyl(r, h, loc, col, seg=16, bev=0.1, rot=None, r2=None):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r, depth=h)
    else: bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r2, depth=h)
    o = bpy.context.object; _place(o, (0, 0, 0), rot); o.location = Vector(loc); return _finish(o, col, min(bev, r * 0.4, h * 0.4), 1)
def blob(r, loc, col, sub=1, sq=(1, 1, 1), seed=0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r); o = bpy.context.object
    rnd = random.Random(seed)
    for v in o.data.vertices: v.co *= 1 + rnd.uniform(-0.08, 0.08)
    o.scale = Vector(sq); _place(o, (0, 0, 0), None); o.location = Vector(loc); return _finish(o, col, 0)
def torus(R, r, loc, col, rot=(90, 0, 0), maj=16, mn=6):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=maj, minor_segments=mn); o = bpy.context.object
    _place(o, (0, 0, 0), rot); o.location = Vector(loc); return _finish(o, col, 0)
def poly(verts, faces, col, loc=(0, 0, 0), bev=0.08):
    me = bpy.data.meshes.new("p"); me.from_pydata([Vector(v) for v in verts], [], faces); me.update()
    o = bpy.data.objects.new("p", me); bpy.context.collection.objects.link(o); o.location = Vector(loc)
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces); bm.to_mesh(me); bm.free()
    return _finish(o, col, bev)
def gable(w, d, h, loc, col, over=0.6, th=0.5):
    """gable roof: ridge along x. w = x length, d = depth (y), h = rise. Thick slabs."""
    x0, x1 = -w / 2 - over, w / 2 + over; y0 = -d / 2 - over
    def slab(sgn):
        # a slab from eave (y=sgn*(d/2+over), z=0) to ridge (y=0, z=h)
        ye = sgn * (d / 2 + over); v = []
        for x in (x0, x1):
            v += [(x, ye, 0), (x, 0, h), (x, 0, h + th), (x, ye, th)]
        f = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
        return poly(v, f, col, loc, 0.08)
    a = slab(-1); b = slab(1); return a, b
def hip(w, d, h, loc, col, over=0.6, top=0.25):
    x, y = w / 2 + over, d / 2 + over; tx, ty = max(x - h * 1.1, x * top), max(y - h * 1.1, y * top)
    v = [(-x, -y, 0), (x, -y, 0), (x, y, 0), (-x, y, 0), (-tx, -ty, h), (tx, -ty, h), (tx, ty, h), (-tx, ty, h)]
    v += [(-x, -y, -0.45), (x, -y, -0.45), (x, y, -0.45), (-x, y, -0.45)]
    f = [(4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (8, 9, 1, 0), (9, 10, 2, 1), (10, 11, 3, 2), (11, 8, 0, 3), (11, 10, 9, 8)]
    return poly(v, f, col, loc, 0.1)
def window(cx, cz, w, h, y, col_frame='white', glass='glass', sill=True, cross=True, face=-1):
    """window on a wall plane at y (face=-1 front facing -y). Frame, glass, glint, sill."""
    t = 0.18 * face
    box((w + 0.5, 0.3, h + 0.5), (cx, y + face * 0.05, cz), col_frame, 0.08)
    box((w, 0.3, h), (cx, y + face * 0.15, cz), glass, 0.03)
    box((w * 0.18, 0.3, h * 0.7), (cx - w * 0.2, y + face * 0.2, cz + h * 0.05), 'glass2', 0.02, rot=(0, 18, 0))
    if cross:
        box((0.16, 0.3, h), (cx, y + face * 0.25, cz), col_frame, 0.03)
    if sill: box((w + 0.9, 0.7, 0.28), (cx, y + face * 0.35, cz - h / 2 - 0.3), col_frame, 0.08)
def join(name, origin_center=True):
    objs = [o for o in PARTS]; PARTS.clear()
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]; bpy.ops.object.join(); o = bpy.context.object; o.name = name; o.data.name = name
    me = o.data; bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    o.select_set(False); return o
