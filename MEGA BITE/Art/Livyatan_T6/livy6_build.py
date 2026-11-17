# Livyatan Tier 6 - build from livy6_data.json (measured from livyatan_turnaround_v1.png;
# part names from the exploded sheet). Rebuild from this script, never hand-edit.
# Run:  blender -b --factory-startup -P livy6_build.py -- livy6_data.json <out_dir> [render] [file.blend]
#  or inside Blender: set ARGS = [data, out_dir] and exec.
import bpy, bmesh, json, math, sys, os, random
import numpy as np
from mathutils import Vector, Matrix, geometry
from mathutils.bvhtree import BVHTree

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else globals().get('ARGS', [])
DATA, OUT = argv[0], os.path.abspath(argv[1])   # Blender resolves relative render paths against C:\, not the cwd
RENDER = 'render' in argv
HERE = os.path.dirname(os.path.abspath(DATA))
D = json.load(open(DATA))
X0, X1 = D['side_x']
S = D['len_m'] / (X1 - X0)            # metres per sheet px
YC = D['yc']
def X(x): return (x - X0) * S - D['len_m'] / 2
def Z(y): return (YC - y) * S
st = D['stations']; _sx = np.array([s['x'] for s in st], float)
def T(x): return float(np.interp(x, _sx, [s['top'] for s in st]))
def B(x): return float(np.interp(x, _sx, [s['bot'] for s in st]))
def HW(x): return float(np.interp(x, _sx, [s['hw'] for s in st]))
def line(pts, x): p = np.array(pts, float); return float(np.interp(x, p[:, 0], p[:, 1]))
P = {k: tuple(c / 255 for c in v) + (1.0,) for k, v in D['palette'].items()}
H = D['head']; PRE = 'L6_'

# ---------- scene ----------
for o in list(bpy.data.objects):
    if o.name.startswith(PRE) or (o.name == 'Cube' and RENDER): bpy.data.objects.remove(o, do_unlink=True)
col = bpy.data.collections.get('Livyatan_T6') or bpy.data.collections.new('Livyatan_T6')
if col.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(col)

def mat(name, glow):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); attr = nt.nodes.new('ShaderNodeAttribute'); attr.attribute_name = 'Col'
    bs = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(attr.outputs['Color'], bs.inputs['Base Color']); bs.inputs['Roughness'].default_value = 0.8
    if glow:
        nt.links.new(attr.outputs['Color'], bs.inputs['Emission Color']); bs.inputs['Emission Strength'].default_value = 3.0
    nt.links.new(bs.outputs['BSDF'], out.inputs['Surface'])
    return m
M_BODY, M_GLOW = mat('L6_Body', False), mat('L6_Glow', True)

def make(name, verts, faces, fcol, glow=False, closed=True):
    me = bpy.data.meshes.new(name); me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    if closed:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        vol = sum(f.verts[0].co.dot(f.verts[i].co.cross(f.verts[i + 1].co)) for f in bm.faces for i in range(1, len(f.verts) - 1))
        if vol < 0: bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    ca = me.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')
    for p in me.polygons:
        c = fcol(p) if callable(fcol) else fcol
        for li in p.loop_indices: ca.data[li].color_srgb = c
        p.use_smooth = False
    me.materials.append(M_GLOW if glow else M_BODY)
    o = bpy.data.objects.new(PRE + name, me); col.objects.link(o); return o

def jit(c, k, a=0.08):
    r = random.Random(k).uniform(-a, a); return tuple(max(0, min(1, v * (1 + r))) for v in c[:3]) + (1,)
def recolour(o, fcol):
    ca = o.data.color_attributes['Col']
    for p in o.data.polygons:
        c = fcol(p)
        for li in p.loop_indices: ca.data[li].color_srgb = c

# ---------- lofts ----------
def ring_pt(x, top, bot, hw, th, pex=2.4):
    zc, hz, w = (Z(top) + Z(bot)) / 2, (Z(top) - Z(bot)) / 2, hw * S
    sy, cz = math.sin(th), math.cos(th)
    y = w * math.copysign(abs(sy) ** (2 / pex), sy)
    z = zc + hz * math.copysign(abs(cz) ** (2 / pex), cz)
    return Vector((X(x), y, z))

def loft(name, xs, prof, nr=16, pex=2.4, scale=None, colour=None, glow=False, jitter=0.025, tip_end=None):
    rings = []
    for i, x in enumerate(xs):
        top, bot, hw = prof(x); k = scale(i, x) if scale else 1.0
        zc = (Z(top) + Z(bot)) / 2; r = []
        for j in range(nr):
            p = ring_pt(x, top, bot, hw, 2 * math.pi * j / nr, pex)
            q = random.Random(int(x * 10) * 31 + j).uniform(-jitter, jitter)
            c = Vector((p.x, 0, zc)); r.append(c + (p - c) * k * (1 + q))
        rings.append(r)
    verts = [v for r in rings for v in r]; faces = []
    for i in range(len(rings) - 1):
        for j in range(nr):
            a, b = i * nr + j, i * nr + (j + 1) % nr; c, d = b + nr, a + nr
            faces += [(a, b, c), (a, c, d)] if (i + j) % 2 else [(a, b, d), (b, c, d)]
    for end in (0, len(rings) - 1):
        r = rings[end]; ctr = (tip_end if (end and tip_end is not None) else sum(r, Vector()) / nr)
        ci = len(verts); verts.append(ctr)
        for j in range(nr):
            a, b = end * nr + j, end * nr + (j + 1) % nr
            faces.append((a, b, ci) if end else (b, a, ci))
    return make(name, verts, faces, colour or skin(name), glow)

def skin(key):   # indigo top, lavender lower flank / belly, by facet normal (flat facets give a clean faceted edge)
    def f(p):
        base = P['belly'] if p.normal.z < -0.32 else P['top']
        return jit(base, p.index // 2 * 7 + len(key), 0.045)   # one shade per quad (tri pair), not per tri
    return f

def xs_between(a, b, step=12):
    v = list(np.arange(a, b, step)) + [b]; return [float(x) for x in v]
body = lambda x: (T(x), B(x), HW(x))

# armour segments (exploded sheet: SEGMENT 1 at the head .. 7 at the tail), each its own closed part.
# Ends shrink to 0.86 and overlap the neighbour by 2 px, so the groove is a V with no see-through slit.
G = D['grooves']; HX = D['head_x']
def seg_scale(xs):
    a, b = xs[0], xs[-1]
    def f(i, x):
        d = min(x - a, b - x); return 0.86 + 0.14 * min(1.0, d / 7.0) + 0.025 * math.sin(math.pi * (x - a) / (b - a))
    return f
for n, (a, b) in enumerate(reversed(list(zip(G[:-1], G[1:]))), 1):
    xs = [a - 2, a + 1, a + 7] + [x for x in xs_between(a + 7, b - 7, 14)][1:-1] + [b - 7, b - 1, b + 2]
    def seg_col(p, a=a, b=b, key='Seg%d' % n):   # the V groove at each end is dark
        return jit(P['groove'], p.index, 0.05) if not X(a + 3) < p.center.x < X(b - 3) else skin(key)(p)
    loft('ArmourSegment%d' % n, xs, body, pex=2.9, scale=seg_scale(xs), colour=seg_col)
# tail stock: from the fluke root to the first groove, tapering
xs = [150.0] + xs_between(160, G[0] - 7, 14)[1:] + [G[0] - 1, G[0] + 2]
loft('TailStock', xs, body, nr=12, scale=lambda i, x: 0.86 if x > G[0] - 2 else 1.0)

# ---------- head ----------
CX, CY = H['corner']
def skull(x):
    if x <= HX + 5: bot = B(x)
    elif x < CX: bot = B(HX + 5) + (CY - B(HX + 5)) * (x - HX - 5) / (CX - HX - 5)
    else: bot = line(H['upper_lip'], x)
    return (T(x), bot, HW(x))
hxs = [HX - 2, HX + 1, HX + 7] + xs_between(HX + 7, 1480, 9)[1:] + [1495, 1507, 1515]
head = loft('UpperHead', hxs, skull, nr=24, pex=3.2, scale=lambda i, x: 0.86 if x < HX + 3 else (0.93 if x > 1510 else 1.0),
            tip_end=Vector((X(X1), 0, Z((T(1517) + line(H['upper_lip'], 1517)) / 2))))
# eye socket CARVED into the head: verts inside the eye ellipse pushed in, deepest at the back
E = H['eye']
ex, ey, erx, ery = E['x'], E['y'], E['w'] * 0.95, E['h'] * 1.25
for v in head.data.vertices:
    u = ((v.co.x - X(ex)) / (erx * S)) ** 2 + ((v.co.z - Z(ey)) / (ery * S)) ** 2
    if u < 1 and abs(v.co.y) > 0.6 * HW(ex) * S:
        d = (1 - u) * 9 * S * (1.2 if v.co.x < X(ex) else 0.8)
        v.co.y -= math.copysign(d, v.co.y)
head.data.update()
def head_col(p):
    c = p.center; u = ((c.x - X(ex)) / (erx * S)) ** 2 + ((c.z - Z(ey)) / (ery * S)) ** 2
    if u < 1 and abs(c.y) > 0.5 * HW(ex) * S: return jit(P['socket'], p.index, 0.05)
    if p.normal.z < -0.6 and c.x > X(CX): return jit(P['maroon'], p.index, 0.05)     # roof of the mouth
    return skin('UpperHead')(p)
recolour(head, head_col)

JX0, JX1 = 1100, H['jaw_bot'][-1][0]
def jaw(x):
    t = (x - JX0) / (JX1 - JX0)
    return (line(H['lower_lip'], x), line(H['jaw_bot'], x), max(10, HW(min(x, 1300)) * (0.86 - 0.26 * max(0, t - 0.5) * 2)))
def jaw_col(p):
    c = p.center
    if p.normal.z > 0.45:
        xp = (c.x + D['len_m'] / 2) / S + X0; jhw = jaw(min(max(xp, JX0), JX1))[2] * S
        return jit(P['maroon'], p.index, 0.05) if abs(c.y) < 0.78 * jhw and xp > CX - 10 else jit(P['jaw'], p.index, 0.05)
    return jit(P['belly'] if p.normal.z < -0.3 else P['jaw'], p.index, 0.07)
loft('LowerJaw', xs_between(JX0, JX1, 10), jaw, nr=16, pex=2.8, colour=jaw_col)
def mouth(x):
    top = line(H['upper_lip'], x) + 2; bot = line(H['lower_lip'], x) + 6
    return (top, bot, 0.84 * HW(x))
loft('MouthInterior', xs_between(CX - 20, 1290, 12), mouth, nr=12, colour=lambda p: jit(P['maroon'], p.index, 0.1))   # sheet: the gape in front of x1290 is see-through

# ---------- teeth: U rows (both sides + across the front), 4-sided cones ----------
def teeth(name, spec, lip, up, wk):
    verts, faces = [], []
    x0, x1 = spec['x']; n = spec['n']
    pts = []
    for side in (1, -1):
        for i in range(n):
            x = x0 + (x1 - x0) * i / (n - 1); pts.append((x, side * wk(x), i))
    hw1 = wk(x1); nf = max(2, int(2 * hw1 / ((x1 - x0) / (n - 1))) - 1)
    for i in range(1, nf + 1):
        pts.append((x1 + 2, -hw1 + 2 * hw1 * i / (nf + 1), n + i))
    for x, yl, i in pts:
        L = spec['len'] * (0.7 + 0.3 * math.sin(i * 1.9) ** 2) * (0.85 if abs(yl) < hw1 * 0.8 and x > x1 else 1.0) * S
        y0 = line(lip, min(x, x1)) + (2 if up else -2)
        base = Vector((X(x), yl * S, Z(y0))); r = L * 0.42
        b = len(verts)
        verts += [base + Vector((r, 0, 0)), base + Vector((0, r, 0)), base + Vector((-r, 0, 0)), base + Vector((0, -r, 0)),
                  base + Vector((0, 0, -L if up else L))]
        faces += [(b, b + 1, b + 2, b + 3), (b, b + 1, b + 4), (b + 1, b + 2, b + 4), (b + 2, b + 3, b + 4), (b + 3, b, b + 4)]
    return make(name, verts, faces, lambda p: jit(P['teeth'], p.index, 0.04))
teeth('UpperTeethRow', H['up_teeth'], H['upper_lip'], True, lambda x: 0.9 * HW(x))
teeth('LowerTeethRow', H['lo_teeth'], H['lower_lip'], False, lambda x: 0.8 * jaw(x)[2])

# ---------- eye: domed glowing lens seated in the socket, turned 35 deg forward ----------
def eye():
    top, bot, hw = skull(ex); verts, faces = [], []
    for side in (1, -1):
        p = Vector((X(ex), side * (hw * S * 0.97 - 6 * S), Z(ey)))
        n = Matrix.Rotation(math.radians(35) * side, 3, 'Z') @ Vector((0, side, 0))
        u = Vector((1, 0, 0)); u = (u - n * u.dot(n)).normalized(); v = n.cross(u).normalized()
        a, b, h = E['w'] / 2 / math.cos(math.radians(35)) * 0.85 * S, E['h'] / 2 * S, 7 * S
        b0 = len(verts); K = 12
        for k in range(K):
            t = 2 * math.pi * k / K; verts.append(p + u * a * math.cos(t) + v * b * math.sin(t) - n * 3 * S)
        for k in range(K):
            t = 2 * math.pi * k / K; verts.append(p + u * a * 0.7 * math.cos(t) + v * b * 0.7 * math.sin(t) + n * h * 0.7)
        verts.append(p + n * h); ap = len(verts) - 1; verts.append(p - n * 4 * S); bc = len(verts) - 1
        for k in range(K):
            k2 = (k + 1) % K
            faces += [(b0 + k, b0 + k2, b0 + K + k2, b0 + K + k), (b0 + K + k, b0 + K + k2, ap), (b0 + k2, b0 + k, bc)]
    return make('Eye', verts, faces, P['eye'], glow=True)
eye()

# ---------- pectoral fins: faceted paddles, roots sunk into the lower flank ----------
F = D['fins']
for side, sname in ((1, 'Left'), (-1, 'Right')):
    rx, ry = F['root']; top, bot, hw = body(rx)
    R = ring_pt(rx, top, bot, hw, math.radians(122)); R.y *= side
    R = R - Vector((0, side * 22 * S, -4 * S))
    Tp = Vector((X(F['tip'][0]), side * F['spread'] * S, Z(F['tip'][1])))
    A = (Tp - R) * F['len_k']; Ah = A.normalized()
    W = Vector((1, 0, 0)); W = (W - Ah * W.dot(Ah)).normalized(); N = Ah.cross(W).normalized()
    secs = ((0.0, 0.6, 16), (0.2, 1.0, 13), (0.55, 0.95, 9), (0.85, 0.6, 5), (1.0, 0.18, 2))
    verts, faces = [], []
    for t, wf, th in secs:
        c = R + A * t; w = F['width'] / 2 * wf * S; h = th / 2 * S
        for du, dn in ((w, 0), (w * 0.45, h), (-w * 0.5, h * 0.7), (-w, 0), (-w * 0.5, -h * 0.7), (w * 0.45, -h)):
            verts.append(c + W * du + N * dn)
    K = 6
    for i in range(len(secs) - 1):
        for k in range(K):
            a, b = i * K + k, i * K + (k + 1) % K; faces.append((a, b, b + K, a + K))
    faces.append(tuple(range(K - 1, -1, -1))); L = (len(secs) - 1) * K; faces.append(tuple(L + k for k in range(K)))
    make('PectoralFin' + sname, verts, faces, lambda p: jit(P['belly'] if p.normal.z < -0.2 else P['top'], p.index, 0.08))

# ---------- tail fluke: flat horizontal plate from the top-view outline, thick at the root ----------
fl = [Vector((X(x), y * S, 0)) for x, y in D['fluke']]
if geometry.normal(fl).z < 0: fl.reverse()
tris = geometry.tessellate_polygon([fl])
def th(v):   # half-thickness: 7 px at the root (x>170) to 1.5 px at the tips
    t = max(0.0, min(1.0, ((v.x - X(40)) / (X(200) - X(40)))))
    return (1.5 + 5.5 * t - 2.5 * min(1, abs(v.y) / (150 * S))) * S
nv = len(fl); zc = Z(276)
verts = [v + Vector((0, 0, zc + max(1.2 * S, th(v)))) for v in fl] + [v + Vector((0, 0, zc - max(1.2 * S, th(v)))) for v in fl]
faces = [tuple(t) for t in tris] + [tuple(nv + i for i in reversed(t)) for t in tris]
faces += [(i, (i + 1) % nv, nv + (i + 1) % nv, nv + i) for i in range(nv)]
make('TailFluke', verts, faces, lambda p: jit(P['belly'] if p.normal.z < -0.2 else P['top'], p.index, 0.08))

# ---------- runes: traced from the sheet, ray-cast onto the skin as thin glowing decals ----------
RUNES = json.load(open(os.path.join(HERE, 'runes_2d.json')))   # traced by runes.py (outside Blender: needs cv2)
skin_objs = [o for o in col.objects if o.name.startswith(PRE) and ('Segment' in o.name or o.name in (PRE + 'UpperHead', PRE + 'TailStock'))]
bm_all = bmesh.new()
for o in skin_objs: bm_all.from_mesh(o.data)
bm_all.normal_update(); BVH = BVHTree.FromBMesh(bm_all)
TP, FP = D['top'], D['front']
VIEWS = {   # view -> (component label, px->(origin, dir) per mirror side, keep-if normal test)
  'side':  (1, lambda u, w, s: (Vector((X(u), -s * 3, Z(w))), Vector((0, s, 0))), lambda n, s: -s * n.y > 0.35),
  'top':   (2, lambda u, w, s: (Vector((X(X0 + (u - TP['tx'][0]) * TP['k']), (w - TP['tc']) * TP['k'] * S, 3)), Vector((0, 0, -1))), lambda n, s: n.z > 0.45),
  'front': (3, lambda u, w, s: (Vector((3, (u - FP['cx']) / FP['k'] * S, Z(40 + (w - FP['y0']) / FP['k']))), Vector((-1, 0, 0))), lambda n, s: n.x > 0.45),
}
for cname in ('Cyan', 'Gold'):
    verts, faces = [], []
    for vname, (L, ray, keep) in VIEWS.items():
        for loops in RUNES['%s_%s' % (cname, vname)]:
            flat = [[Vector((float(p[0]), float(p[1]), 0)) for p in l] for l in loops]
            tri = geometry.tessellate_polygon(flat)
            pts = [p for l in flat for p in l]
            # split every triangle into a ~6 px grid so no chord cuts into the curved skin
            for s in ((1, -1) if vname == 'side' else (1,)):   # side runes go on both flanks
                for t in tri:
                    a, b, cc = (pts[k] for k in t)
                    nsub = max(1, int(max((a - b).length, (b - cc).length, (cc - a).length) / 10))
                    grid = {}
                    for ii in range(nsub + 1):
                        for jj in range(nsub + 1 - ii):
                            q = a + (b - a) * (ii / nsub) + (cc - a) * (jj / nsub)
                            o_, d_ = ray(q.x, q.y, s); hit = BVH.ray_cast(o_, d_)
                            grid[ii, jj] = None if hit[0] is None or not keep(hit[1], s) else len(verts)
                            if grid[ii, jj] is not None: verts.append(hit[0] + hit[1] * 0.9 * S)
                    for ii in range(nsub):
                        for jj in range(nsub - ii):
                            for f in ((grid[ii, jj], grid[ii + 1, jj], grid[ii, jj + 1]),
                                      (grid[ii + 1, jj], grid[ii + 1, jj + 1], grid[ii, jj + 1]) if jj < nsub - ii - 1 else (None,)):
                                if None not in f: faces.append(f)
    o = make('Runes' + cname, verts, faces, P['cyan' if cname == 'Cyan' else 'gold'], glow=True, closed=False)
    me = o.data; bm = bmesh.new(); bm.from_mesh(me)   # face the decal outward: along the skin normal under it
    for f in bm.faces:
        h = BVH.find_nearest(f.calc_center_median())
        if h[0] is not None and f.normal.dot(h[1]) < 0: f.normal_flip()
    bm.to_mesh(me); bm.free()
bm_all.free()

objs = [o for o in col.objects if o.name.startswith(PRE)]
tris_n = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
print('L6 parts', len(objs), 'triangles', tris_n, {o.name[3:]: len(o.data.polygons) for o in objs})

# ---------- renders at the sheet's pixel scale (side / top / front) ----------
if RENDER:
    sc = bpy.context.scene
    try: sc.render.engine = 'BLENDER_WORKBENCH'
    except TypeError as e: print(e)
    sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'VERTEX'
    sh.background_type = 'VIEWPORT'; sh.background_color = (1, 0, 1)
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = 1536, 1024; sc.render.resolution_percentage = 100
    cam = bpy.data.objects.get('L6cam') or bpy.data.objects.new('L6cam', bpy.data.cameras.new('L6cam'))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = 1536 * S; sc.camera = cam
    cx, cz = X(768), Z(512)
    views = {'side': ((cx, -20, cz), (math.radians(90), 0, 0)),
             'top': ((cx, 0, 20), (0, 0, 0)),
             'front': ((20, 0, cz), (math.radians(90), 0, math.radians(90))),
             'q34': ((X(1500) + 9, -9, 4), None)}
    for k, (loc, rot) in views.items():
        cam.location = loc
        if rot: cam.rotation_euler = rot
        else:
            cam.data.type = 'PERSP'; cam.rotation_euler = (Vector((X(900), 0, 0)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
        sc.render.filepath = os.path.join(OUT, 'render_%s.png' % k); bpy.ops.render.render(write_still=True)
    cam.data.type = 'ORTHO'
for a in argv[2:]:
    if a.endswith('.blend'): bpy.ops.wm.save_as_mainfile(filepath=a)
