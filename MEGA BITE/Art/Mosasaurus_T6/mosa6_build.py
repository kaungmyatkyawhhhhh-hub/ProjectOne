# Mosasaurus Tier 6 - build from mosa6_data.json (measured from mosasaurus_turnaround_v1.png,
# parts named after mosasaurus_exploded_v1.png). Rebuild from this script, never hand-edit.
# Run:  blender -b --factory-startup -P mosa6_build.py -- <data.json> <out_dir> [render]
#  or inside Blender: set ARGS below and exec.
import bpy, bmesh, json, math, sys, os, random
import numpy as np
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else globals().get('ARGS', [])
DATA, OUT = argv[0], argv[1]
RENDER = 'render' in argv
D = json.load(open(DATA))
X0, X1 = D['side_x']
S = D['len_m'] / (X1 - X0)            # metres per sheet px
YC = D.get('yc', 270)                  # sheet row that maps to z = 0
def X(x): return (x - X0) * S - D['len_m'] / 2
def Z(y): return (YC - y) * S
st = D['stations']
_sx = np.array([s['x'] for s in st], float)
def T(x): return float(np.interp(x, _sx, [s['top'] for s in st]))
def B(x): return float(np.interp(x, _sx, [s['bot'] for s in st]))
def HW(x): return float(np.interp(x, _sx, [s['hw'] for s in st]))
def line(pts, x): p = np.array(pts, float); return float(np.interp(x, p[:, 0], p[:, 1]))
P = {k: tuple(c / 255 for c in v) + (1.0,) for k, v in D['palette'].items()}
H = D['head']

# ---------- scene ----------
for o in list(bpy.data.objects):
    if o.name.startswith('M6_') or (o.name == 'Cube' and RENDER): bpy.data.objects.remove(o, do_unlink=True)
col = bpy.data.collections.get('Mosasaurus_T6') or bpy.data.collections.new('Mosasaurus_T6')
if col.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(col)

def mat(name, glow):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); attr = nt.nodes.new('ShaderNodeAttribute'); attr.attribute_name = 'Col'
    bs = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(attr.outputs['Color'], bs.inputs['Base Color']); bs.inputs['Roughness'].default_value = 0.75
    if glow:
        nt.links.new(attr.outputs['Color'], bs.inputs['Emission Color']); bs.inputs['Emission Strength'].default_value = 2.5
    nt.links.new(bs.outputs['BSDF'], out.inputs['Surface'])
    return m
M_BODY, M_GLOW = mat('M6_Body', False), mat('M6_Glow', True)

YZK = D.get('yz_k', 1.0)   # card: chunkier than the sheets - deeper and wider for the same length (rig span unchanged)
def make(name, verts, faces, fcol, glow=False):
    me = bpy.data.meshes.new(name); me.from_pydata([(v[0], v[1] * YZK, v[2] * YZK) for v in verts], [], faces); me.update()
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    vol = sum(f.verts[0].co.dot(f.verts[i].co.cross(f.verts[i + 1].co)) for f in bm.faces for i in range(1, len(f.verts) - 1))
    if vol < 0: bmesh.ops.reverse_faces(bm, faces=bm.faces)   # recalc guesses wrong on thin twisted parts
    bm.to_mesh(me); bm.free()
    ca = me.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')
    for p in me.polygons:
        c = fcol(p) if callable(fcol) else fcol
        for li in p.loop_indices: ca.data[li].color_srgb = c
    for p in me.polygons: p.use_smooth = False
    me.materials.append(M_GLOW if glow else M_BODY)
    o = bpy.data.objects.new(name, me); col.objects.link(o); return o

def jit(c, k, a=0.12):   # per-face colour variation, deterministic
    r = random.Random(k).uniform(-a, a); return tuple(max(0, min(1, v * (1 + r))) for v in c[:3]) + (1,)

# ---------- body lofts ----------
NR, PEX = 16, 2.4
def ring_pt(x, top, bot, hw, th):
    zc, hz, w = (Z(top) + Z(bot)) / 2, (Z(top) - Z(bot)) / 2, hw * S
    sy, cz = math.sin(th), math.cos(th)
    y = w * math.copysign(abs(sy) ** (2 / PEX), sy)
    z = zc + hz * math.copysign(abs(cz) ** (2 / (PEX if cz >= 0 else 3.0)), cz)
    return Vector((X(x), y, z))
def ring(x, top, bot, hw, jitter=0.03):
    out = []
    for k in range(NR):
        p = ring_pt(x, top, bot, hw, 2 * math.pi * k / NR)
        r = random.Random(int(x * 10) * 31 + k).uniform(-jitter, jitter)   # same jitter on a shared boundary ring
        c = Vector((p.x, 0, (Z(top) + Z(bot)) / 2)); p = c + (p - c) * (1 + r); out.append(p)
    return out

def belly_z(x): return Z(line(D['belly_line'], x))
def body_colour(o_name, centres, belly_faces=()):
    def f(p):
        if p.index in belly_faces: base = P['belly']     # whole ring quads: a straight band edge, as the exploded sheet
        else:   # card: mottled camo green - smooth patches of dark/mid/light by position, not per-face noise
            c = centres(p); n = (math.sin(c.x * 2.3 + c.z * 3.1) * math.sin(c.y * 4.7 - c.x * 1.3) + 0.6 * math.sin(c.x * 5.9 + c.y * 2.2 + c.z * 4.4)) / 1.6
            t = max(0.0, min(1.0, 0.5 + 0.6 * n)); lo, hi = (P['dark'], P['green']) if t < 0.5 else (P['green'], P['light']); u = (t % 0.5) * 2
            base = tuple(lo[k] + (hi[k] - lo[k]) * u for k in range(3)) + (1,)
        return jit(base, p.index * 13 + len(o_name), 0.07)
    return f

def loft(name, xs, prof, tip_start=None, tip_end=None, colour=None, glow=False, belly_band=True):
    rings = [ring(x, *prof(x)) for x in xs]
    verts = [v for r in rings for v in r]; faces = []
    for i in range(len(rings) - 1):
        for k in range(NR):
            a, b = i * NR + k, i * NR + (k + 1) % NR
            c, d = b + NR, a + NR
            faces += [(a, b, c), (a, c, d)] if (i + k) % 2 else [(a, b, d), (b, c, d)]
    for end, tip in ((0, tip_start), (len(rings) - 1, tip_end)):
        r = rings[end]; ctr = tip if tip is not None else sum(r, Vector()) / NR
        ci = len(verts); verts.append(ctr)
        for k in range(NR):
            a, b = end * NR + k, end * NR + (k + 1) % NR
            faces.append((a, b, ci) if end else (b, a, ci))
    me_name = 'M6_' + name
    o = make(me_name, verts, faces, (0, 0, 0, 1), glow)
    me = o.data
    ba = D.get('belly_angle_deg', 180); step = 360 / NR
    belly = {f for f in range(2 * NR * (len(rings) - 1)) if ba < ((f // 2) % NR + 0.5) * step < 360 - ba} if belly_band else set()
    cf = colour or body_colour(me_name, lambda p: p.center, belly)
    ca = me.color_attributes['Col']
    for p in me.polygons:
        cc = cf(p)
        for li in p.loop_indices: ca.data[li].color_srgb = cc
    return o

def xs_between(a, b, step=22):
    v = list(np.arange(a, b, step)) + [b]; return [float(x) for x in v]
body = lambda x: (T(x), B(x), HW(x))
cut = D['cuts']
loft('TailTip', xs_between(60, cut['tail_tip'][1]), body, tip_start=Vector((X(X0), 0, (Z(T(60)) + Z(B(60))) / 2)))
loft('TailBase', xs_between(*cut['tail_base']), body)
loft('Torso', xs_between(*cut['torso']), body)
loft('Neck', xs_between(*cut['neck']), body)

# head: upper skull (bottom rises to the upper lip at the mouth corner), lower jaw, mouth interior
CORNER = H['corner']; XB = 1150
def skull(x):
    if x <= XB: bot = B(x)
    elif x < CORNER: bot = B(XB) + (line(H['upper_lip'], CORNER) - B(XB)) * (x - XB) / (CORNER - XB)
    else: bot = line(H['upper_lip'], x)
    return (T(x), bot, HW(x))
loft('UpperSkull', xs_between(cut['head'][0], cut['head'][1], 16), skull, belly_band=False)   # its underside is the green upper lip
JX0, JX1 = 1150, H['jaw_bot'][-1][0]
def jaw(x):
    if x < 1200:
        f = (x - JX0) / 50; top = (B(JX0) - 40) * (1 - f) + line(H['lower_lip'], 1200) * f
        bot = B(JX0) * (1 - f) + line(H['jaw_bot'], 1200) * f
    else: top, bot = line(H['lower_lip'], x), line(H['jaw_bot'], x)
    return (top, bot, max(6, 0.9 * HW(x)))
red = lambda p: jit(P['red'], p.index, 0.08)
def jaw_col(p):
    # top faces: a thin cream lip line along the outer edge, mouth red inside; underside = belly, sides green
    if p.normal.z > 0.5 and p.center.x > X(CORNER - 5):
        jhw = 0.9 * HW((p.center.x + D['len_m'] / 2) / S + X0) * S
        return jit(P['teeth'], p.index, 0.05) if abs(p.center.y) > 0.86 * jhw else jit(P['red'], p.index, 0.05)
    if p.normal.z < -0.75: return jit(P['belly'], p.index, 0.05)
    return body_colour('LowerJaw', lambda q: Vector((q.center.x, 0, 99)))(p)
loft('LowerJaw', xs_between(JX0, JX1, 10), jaw, colour=jaw_col)
MX1 = H['mouth_top'][-1][0]
def mouth(x):
    top = line(H['mouth_top'], x); bot = line(H['lower_lip'], x) + 5
    return (min(top, bot - 3), bot, 0.7 * HW(x))
loft('MouthInterior', xs_between(CORNER - 15, MX1, 15), mouth, colour=red)

# ---------- teeth ----------
def teeth(name, spec, lip, up):
    verts, faces = [], []
    for side in (1, -1):
        for i in range(spec['n']):
            x = spec['x'][0] + (spec['x'][1] - spec['x'][0]) * i / max(1, spec['n'] - 1)
            L = spec['len'] * (0.75 + 0.25 * math.sin(i * 1.7) ** 2) * S
            hw = 0.82 * (HW(x) if up else 0.9 * HW(x)) * S
            y0 = line(lip, x) + (3 if up else -3)
            base = Vector((X(x), side * hw, Z(y0))); r = L * 0.48
            b = len(verts)
            verts += [base + Vector((r, 0, 0)), base + Vector((-r * 0.5, side * r * 0.87, 0)), base + Vector((-r * 0.5, -side * r * 0.87, 0)),
                      base + Vector((0, 0, -L if up else L))]
            faces += [(b, b + 1, b + 2), (b, b + 1, b + 3), (b + 1, b + 2, b + 3), (b + 2, b, b + 3)]
    make('M6_' + name, verts, faces, lambda p: jit(P['teeth'], p.index, 0.05))
teeth('UpperTeethRow', H['up_teeth'], H['upper_lip'], True)
teeth('LowerTeethRow', H['lo_teeth'], H['lower_lip'], False)

# ---------- eye (dome lens + slit pupil), seated on the skull, turned 30 deg forward ----------
E = H['eye']
def eye_obj():
    top, bot, hw = skull(E['x'])
    lo, hi = 0.0, math.pi / 2
    for _ in range(40):
        mid = (lo + hi) / 2
        if ring_pt(E['x'], top, bot, hw, mid).z > Z(E['y']): lo = mid
        else: hi = mid
    verts, faces, pv, pf = [], [], [], []   # lens (glows: own Neon part in Roblox) and pupil (dark, body mesh)
    for side in (1, -1):
        p = ring_pt(E['x'], top, bot, hw, lo); p.y *= side
        n = Vector((0, p.y, p.z - (Z(top) + Z(bot)) / 2)).normalized()
        n = (Matrix.Rotation(math.radians(30) * -side, 3, 'Z') @ n).normalized()
        u = Vector((1, 0, 0)); u = (u - n * u.dot(n)).normalized(); v = n.cross(u) * side
        a, b, h = E['w'] / 2 * S, E['h'] / 2 * S, 5 * S
        b0 = len(verts); K = 10
        for k in range(K):   # base ring (sunk), mid ring, apex
            t = 2 * math.pi * k / K; verts.append(p + u * a * math.cos(t) + v * b * math.sin(t) - n * 2 * S)
        for k in range(K):
            t = 2 * math.pi * k / K; verts.append(p + u * a * 0.65 * math.cos(t) + v * b * 0.65 * math.sin(t) + n * h * 0.7)
        verts.append(p + n * h); ap = len(verts) - 1
        verts.append(p - n * 3 * S); bc = len(verts) - 1
        for k in range(K):
            k2 = (k + 1) % K
            faces += [(b0 + k, b0 + k2, b0 + K + k2, b0 + K + k), (b0 + K + k, b0 + K + k2, ap), (b0 + k2, b0 + k, bc)]
        # slit pupil: thin diamond prism just proud of the lens
        q0 = len(pv); pw, ph = 2.2 * S, E['h'] * 0.45 * S
        for dn in (h * 0.8, h * 1.05):
            for du, dv in ((0, ph), (pw, 0), (0, -ph), (-pw, 0)): pv.append(p + n * dn + u * du + v * dv)
        pf += [(q0, q0 + 1, q0 + 2, q0 + 3), (q0 + 7, q0 + 6, q0 + 5, q0 + 4)] + [(q0 + i, q0 + (i + 1) % 4, q0 + 4 + (i + 1) % 4, q0 + 4 + i) for i in range(4)]
    make('M6_EyePupil', pv, pf, P['pupil'])
    return make('M6_Eye', verts, faces, P['eye'], glow=True)
eye_obj()

# ---------- dorsal crystals (each its own object, largest mid-back) ----------
def shard(verts, faces, cx, base_z, top_z, r, tilt_deg):
    # hexagonal crystal: base ring (sunk), shoulder ring, point; tilted about its base (+ leans forward)
    o = len(verts); ht = top_z - base_z; sh_z = top_z - 0.38 * ht; piv = Vector((cx, 0, base_z))
    R = Matrix.Rotation(math.radians(tilt_deg), 3, 'Y'); pts = []
    for z, rr in ((base_z, r * 0.8), (sh_z, r)):
        for k in range(6):
            t = 2 * math.pi * k / 6 + math.pi / 6; pts.append(Vector((cx + rr * math.cos(t), rr * math.sin(t), z)))
    pts += [Vector((cx, 0, top_z)), Vector((cx, 0, base_z))]
    verts += [piv + R @ (v - piv) for v in pts]
    faces += [(o + k, o + (k + 1) % 6, o + 6 + (k + 1) % 6, o + 6 + k) for k in range(6)] + [(o + 6 + k, o + 6 + (k + 1) % 6, o + 12) for k in range(6)] + [(o + (k + 1) % 6, o + k, o + 13) for k in range(6)]
CK = D.get('crystal_k', 1.0)
for i, c in enumerate(D['crystals']):
    x = c['x']; r = c['w'] / 2 * S * CK; ht = (c['bot'] - c['top']) * S * CK
    base_z = Z(T(x)) - 12 * S; top_z = base_z + ht + 12 * S
    verts, faces = [], []
    shard(verts, faces, X(x), base_z, top_z, r, -10)   # card: separate spikes with gaps, leaning back a little
    make('M6_DorsalCrystal_%02d' % (i + 1), verts, faces, lambda p: jit(P['cyan'] if p.index % 3 else (0.55, 1, 1, 1), p.index, 0.04), glow=True)

# ---------- raised hexagonal scale plates (one object) ----------
pv, pf = [], []
def plate(c, n, r, th, asp=1.0):
    t1 = Vector((1, 0, 0)); t1 = (t1 - n * t1.dot(n)).normalized(); t2 = n.cross(t1)
    b = len(pv)
    for k in range(6):
        a = 2 * math.pi * k / 6; pv.append(c - n * 2 * S + t1 * r * 1.25 * math.cos(a) + t2 * r * asp * math.sin(a))
    for k in range(6):
        a = 2 * math.pi * k / 6; pv.append(c + n * th + t1 * r * 0.95 * math.cos(a) + t2 * r * 0.7 * asp * math.sin(a))
    pf.extend([(b + k, b + (k + 1) % 6, b + 6 + (k + 1) % 6, b + 6 + k) for k in range(6)])
    pf.append(tuple(b + 6 + k for k in range(6))); pf.append(tuple(b + 5 - k for k in range(6)))
PL = D['plates']   # exploded sheet: two rows of large flat plates, staggered
for row, th_deg in enumerate(PL['rows_deg']):
    for x in np.arange(cut['tail_base'][0] + 25 + (row % 2) * PL['step'] / 2, cut['neck'][1] - 10, PL['step']):
        x = float(x); top, bot, hw = body(x)
        if hw < 30: continue
        for side in (1, -1):
            p = ring_pt(x, top, bot, hw, math.radians(th_deg)); p.y *= side
            n = Vector((0, p.y, p.z - (Z(top) + Z(bot)) / 2)).normalized()
            plate(p, n, PL['r'] * S * min(1, hw / 80), PL['th'] * S, 0.45)
for x, y in ((1238, 248), (1268, 256), (1225, 218)):     # the few plates on the skull
    top, bot, hw = skull(x)
    lo, hi = 0.0, math.pi
    for _ in range(40):
        mid = (lo + hi) / 2
        if ring_pt(x, top, bot, hw, mid).z > Z(y): lo = mid
        else: hi = mid
    for side in (1, -1):
        p = ring_pt(x, top, bot, hw, lo); p.y *= side
        plate(p, Vector((0, p.y, p.z - (Z(top) + Z(bot)) / 2)).normalized(), 13 * S, 5 * S)
make('M6_ScalePlates', pv, pf, lambda p: jit(P['plate'] if p.index % 8 == 6 else P['dark'], p.index, 0.05))   # light top, dark bevel sides

# ---------- flippers: faceted paddles, root sunk into the lower flank ----------
for f in D['flippers']:
    for side, sname in ((1, 'Left'), (-1, 'Right')):
        rx, ry = f['root']; top, bot, hw = body(rx)
        R = ring_pt(rx, top, bot, hw, math.radians(118)); R.y *= side
        R = R - Vector((0, side * 18 * S, -6 * S))               # sink the root into the body
        Tp = Vector((X(f['tip'][0]), side * f['spread'] * S, Z(f['tip'][1])))
        A = (Tp - R) * f.get('len_k', 1.0); Ah = A.normalized()   # len_k: owner asked for bigger flippers
        W = Vector((1, 0, 0)); W = (W - Ah * W.dot(Ah)).normalized()
        W = (Matrix.Rotation(math.radians(f.get('twist_deg', 0)) * side, 3, Ah) @ W).normalized(); N = Ah.cross(W).normalized()
        secs = ((0.0, 0.55, 14), (0.25, 1.0, 11), (0.55, 0.95, 8), (0.82, 0.6, 5), (1.0, 0.15, 2))
        verts, faces = [], []
        for t, wf, th in secs:
            c = R + A * t; w = f['width'] / 2 * wf * S; h = th / 2 * S
            # hexagon section, leading edge (front, +W) slightly thicker
            for du, dn in ((w, 0), (w * 0.45, h), (-w * 0.5, h * 0.7), (-w, 0), (-w * 0.5, -h * 0.7), (w * 0.45, -h)):
                verts.append(c + W * du + N * dn)
        K = 6
        for i in range(len(secs) - 1):
            for k in range(K):
                a, b = i * K + k, i * K + (k + 1) % K; faces.append((a, b, b + K, a + K))
        faces.append(tuple(range(K - 1, -1, -1))); L = (len(secs) - 1) * K; faces.append(tuple(L + k for k in range(K)))
        make('M6_%sFlipper%s' % (f['name'], sname), verts, faces, lambda p: jit(P['light'] if p.index % 2 else P['green'], p.index, 0.08))   # fine mid-green check, like the sheet

objs = [o for o in col.objects if o.name.startswith('M6_')]
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
print('M6 parts', len(objs), 'triangles', tris)

# ---------- renders at the sheet's pixel scale (side / top / front) ----------
if RENDER:
    sc = bpy.context.scene
    try: sc.render.engine = 'BLENDER_WORKBENCH'
    except TypeError as e: print(e)
    sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'VERTEX'
    sh.background_type = 'VIEWPORT'; sh.background_color = (1, 0, 1)
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = 1536, 1024; sc.render.resolution_percentage = 100
    sc.render.film_transparent = False
    cam = bpy.data.objects.get('M6cam') or bpy.data.objects.new('M6cam', bpy.data.cameras.new('M6cam'))
    if cam.name not in sc.collection.objects: sc.collection.objects.link(cam)
    cam.data.type = 'ORTHO'; cam.data.ortho_scale = 1536 * S; sc.camera = cam
    cx, cz = X(768), Z(512)
    views = {'side': ((cx, -20, cz), (math.radians(90), 0, 0)),
             'top': ((cx, 0, 20), (0, 0, 0)),
             'front': ((20, 0, cz), (math.radians(90), 0, math.radians(90)))}
    for k, (loc, rot) in views.items():
        cam.location = loc; cam.rotation_euler = rot
        sc.render.filepath = os.path.join(OUT, 'render_%s.png' % k); bpy.ops.render.render(write_still=True)
    # backface check: back faces magenta-red from 6 angles
    sh.show_backface_culling = False
for a in argv[2:]:
    if a.endswith('.blend'): bpy.ops.wm.save_as_mainfile(filepath=a)
