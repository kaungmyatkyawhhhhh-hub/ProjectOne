# STOMP EVOLUTION - STONE set v3: build the 3D model and PAINT its textures on the real shapes (no sheet picture is projected).
# Runs inside Blender (the owner's Blender on the PC, or headless).  exec(open(r"<vault>\TITAN ARC\Art\Stone\stone_v3_paint.py").read())
# 1) build the model (stone_v3.py: the Bacon Hair avatar wearing the armour)  2) unwrap every part into one atlas  3) for every texel work out where it sits on the model
# 4) paint it in 3D: stone colour per block, top-light, worn edges, dirt in the gaps, cracks, speckle, moss tint, glow spill
# 5) save the colour map + glow map next to this script and put them on the model
import bpy, bmesh, sys, os, math, time
import numpy as np
HERE = os.environ.get("STONE_DIR") or r"C:\ObsidianOne\Claude+Obsidian\TITAN ARC\Art\Stone"
LIBS = os.environ.get("STONE_LIBS") or r"C:\ObsidianOne\Claude+Obsidian\Tools\blender_pylibs"     # scipy lives here (Blender ships without it)
if os.path.isdir(LIBS) and LIBS not in sys.path: sys.path.append(LIBS)
from scipy.spatial import cKDTree
from scipy import ndimage as ndi
t0 = time.time()
SRC = os.path.join(HERE, os.environ.get("STONE_SRC", "stone_v3.py")); OUT = HERE; R = int(os.environ.get("STONE_RES", "2048"))
exec(open(SRC).read())
objs = list(bpy.data.collections[COLL].objects)
sc = bpy.context.scene
# everything that is not this model stays out of the picture (the old v1 block-out, the start-up cube)
for o in sc.objects:
    if o.type == 'MESH' and o.name not in bpy.data.collections[COLL].objects:
        o.hide_render = True
        try: o.hide_set(True)
        except Exception: pass
try: sc.view_settings.view_transform = 'Standard'          # true texture colours in the viewport (game art is judged unfiltered)
except Exception: pass
print("built %.1fs" % (time.time() - t0))

def in_view3d(fn):
    win = bpy.context.window or (bpy.context.window_manager.windows[0] if bpy.context.window_manager.windows else None)
    area = next((a for a in win.screen.areas if a.type == 'VIEW_3D'), None) if win else None
    if area:
        reg = next(r for r in area.regions if r.type == 'WINDOW')
        with bpy.context.temp_override(window=win, area=area, region=reg): return fn()
    return fn()

# ---------------- unwrap all parts into one atlas ----------------
if bpy.context.object and bpy.context.object.mode != 'OBJECT': bpy.ops.object.mode_set(mode='OBJECT')
for o in sc.objects:
    try: o.select_set(False)
    except Exception: pass
for o in objs:
    o.select_set(True)
    if not o.data.uv_layers: o.data.uv_layers.new(name="atlas")
bpy.context.view_layer.objects.active = objs[0]
def _unwrap():
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.0012, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode='OBJECT')
in_view3d(_unwrap)
print("unwrapped %.1fs" % (time.time() - t0))

# ---------------- gather triangles ----------------
P, UVc, N, MATI, COMP, OBJ, NC, SM = [], [], [], [], [], [], [], []
edge_cvx, edge_ccv, comp_box = [], [], []
cbase = 0
for oi, o in enumerate(objs):
    me = o.data; me.calc_loop_triangles()
    nv = len(me.vertices); co = np.zeros(nv * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    nl = len(me.loops); uv = np.zeros(nl * 2); me.uv_layers[0].data.foreach_get("uv", uv); uv = uv.reshape(-1, 2)
    nt = len(me.loop_triangles); tl = np.zeros(nt * 3, np.int32); me.loop_triangles.foreach_get("loops", tl); tl = tl.reshape(-1, 3)
    tv = np.zeros(nt * 3, np.int32); me.loop_triangles.foreach_get("vertices", tv); tv = tv.reshape(-1, 3)
    tp = np.zeros(nt, np.int32); me.loop_triangles.foreach_get("polygon_index", tp)
    npol = len(me.polygons); pn = np.zeros(npol * 3); me.polygons.foreach_get("normal", pn); pn = pn.reshape(-1, 3)
    pm = np.zeros(npol, np.int32); me.polygons.foreach_get("material_index", pm)
    psm = np.zeros(npol, bool); me.polygons.foreach_get("use_smooth", psm)
    cn = np.zeros(nl * 3)
    try: me.corner_normals.foreach_get("vector", cn); cn = cn.reshape(-1, 3)
    except Exception: cn = np.repeat(pn, [len(q.vertices) for q in me.polygons], 0)
    # connected shells = separate stones
    bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table(); comp = -np.ones(npol, np.int32); c = 0
    for f in bm.faces:
        if comp[f.index] >= 0: continue
        stack = [f]; comp[f.index] = c
        while stack:
            g = stack.pop()
            for e in g.edges:
                for h in e.link_faces:
                    if comp[h.index] < 0: comp[h.index] = c; stack.append(h)
        c += 1
    for e in bm.edges:
        if len(e.link_faces) != 2: continue
        f1, f2 = e.link_faces
        ang = f1.normal.angle(f2.normal, 0.0)
        if ang < math.radians(18): continue
        a, b = e.verts[0].co, e.verts[1].co; L = (b - a).length; k = max(2, int(L / 1.2))
        pts = [a + (b - a) * (i / (k - 1)) for i in range(k)]
        convex = f1.normal.dot(f2.calc_center_median() - f1.calc_center_median()) < 0
        glowy = (f1.material_index == MI["glow"]) or (f2.material_index == MI["glow"])
        (edge_cvx if convex else edge_ccv).extend([(p.x, p.y, p.z) for p in pts] if not (glowy and not convex) else [])
    bm.free()
    for k in range(c):
        m = comp[tp] == k; vv = co[tv[m].ravel()]
        comp_box.append((vv.min(0), vv.max(0)))
    NC.append(cn[tl]); SM.append(psm[tp]); P.append(co[tv]); UVc.append(uv[tl]); N.append(pn[tp]); MATI.append(pm[tp]); COMP.append(comp[tp] + cbase); OBJ.append(np.full(nt, oi)); cbase += c
NC = np.concatenate(NC); SM = np.concatenate(SM); P = np.concatenate(P); UVc = np.concatenate(UVc); N = np.concatenate(N); MATI = np.concatenate(MATI); COMP = np.concatenate(COMP)
comp_lo = np.array([b[0] for b in comp_box]); comp_hi = np.array([b[1] for b in comp_box])
print("tris", len(P), "stones", cbase, "%.1fs" % (time.time() - t0))

# ---------------- rasterise: which triangle owns each texel ----------------
tri = -np.ones((R, R), np.int32); bw = np.zeros((R, R, 3), np.float32)
px = UVc[..., 0] * R; py = (1.0 - UVc[..., 1]) * R
for i in range(len(P)):
    x0, x1 = int(max(0, math.floor(px[i].min() - 1))), int(min(R - 1, math.ceil(px[i].max() + 1)))
    y0, y1 = int(max(0, math.floor(py[i].min() - 1))), int(min(R - 1, math.ceil(py[i].max() + 1)))
    if x1 < x0 or y1 < y0: continue
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    ax, ay, bx, by, cx_, cy_ = px[i, 0], py[i, 0], px[i, 1], py[i, 1], px[i, 2], py[i, 2]
    d = (by - cy_) * (ax - cx_) + (cx_ - bx) * (ay - cy_)
    if abs(d) < 1e-9: continue
    w0 = ((by - cy_) * (xs - cx_) + (cx_ - bx) * (ys - cy_)) / d; w1 = ((cy_ - ay) * (xs - cx_) + (ax - cx_) * (ys - cy_)) / d; w2 = 1 - w0 - w1
    eps = 0.6 / max(1.0, math.sqrt(abs(d)))
    m = (w0 >= -eps) & (w1 >= -eps) & (w2 >= -eps)
    inner = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
    sub = tri[y0:y1 + 1, x0:x1 + 1]; take = m & ((sub < 0) | inner)
    sub[take] = i
    b = bw[y0:y1 + 1, x0:x1 + 1]; b[take] = np.stack([w0, w1, w2], -1)[take]
filled = tri >= 0
print("coverage %.1f%%  %.1fs" % (filled.mean() * 100, time.time() - t0))
ti = tri[filled]; w = np.clip(bw[filled], 0, 1); w /= w.sum(1, keepdims=True)
pos = (P[ti] * w[:, :, None]).sum(1)          # cm, model space
nor = N[ti].astype(np.float32); mat = MATI[ti]; comp = COMP[ti]
sm = SM[ti]
if sm.any():                                     # rounded parts (the avatar): use the smoothed normal so the painted light is soft
    ns = (NC[ti[sm]] * w[sm][:, :, None]).sum(1); ns /= np.maximum(np.linalg.norm(ns, axis=1, keepdims=True), 1e-6); nor[sm] = ns
npx = len(pos)

# ---------------- ambient occlusion (Cycles) ----------------
AOR = min(R, 1024)
if bpy.data.images.get("SS2_AO"): bpy.data.images.remove(bpy.data.images["SS2_AO"])
aoimg = bpy.data.images.new("SS2_AO", AOR, AOR)
for m_ in MATS:
    nt_ = m_.node_tree; n_ = nt_.nodes.new("ShaderNodeTexImage"); n_.image = aoimg; nt_.nodes.active = n_
eng0 = sc.render.engine; sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; smp0 = sc.cycles.samples; sc.cycles.samples = 24
sc.render.bake.margin = 3; sc.render.bake.use_selected_to_active = False
try:
    bpy.ops.object.bake(type='AO')
    ao = np.array(aoimg.pixels[:], np.float32).reshape(AOR, AOR, 4)[::-1, :, 0]
    if AOR != R: ao = ndi.zoom(ao, R / AOR, order=1)
    ao = ao[filled]
except Exception as e:
    print("AO bake failed:", e); ao = np.ones(npx, np.float32)
sc.render.engine = eng0; sc.cycles.samples = smp0; bpy.data.images.remove(aoimg)
print("AO %.1fs  mean %.2f" % (time.time() - t0, ao.mean()))

# ---------------- noise ----------------
def hsh(ix, iy, iz, seed):
    h = (ix.astype(np.uint32) * np.uint32(374761393) + iy.astype(np.uint32) * np.uint32(668265263) + iz.astype(np.uint32) * np.uint32(2246822519) + np.uint32(seed * 3266489917 & 0xFFFFFFFF))
    h = (h ^ (h >> np.uint32(13))) * np.uint32(1274126177); h = h ^ (h >> np.uint32(16))
    return h.astype(np.float32) / np.float32(4294967295.0)
def vnoise(p, scale, seed):
    q = p / scale + 1000.0; i = np.floor(q).astype(np.int64); f = (q - i).astype(np.float32); f = f * f * (3 - 2 * f)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                wgt = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + wgt * hsh(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz, seed)
    return out
def fbm(p, scale, octv, seed):
    a, tot, out = 1.0, 0.0, 0
    for k in range(octv): out = out + a * vnoise(p, scale / (2 ** k), seed + k * 17); tot += a; a *= 0.5
    return out / tot
def sstep(a, b, x): t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)
def mix(a, b, t): return a + (np.asarray(b, np.float32) - a) * t[:, None]
def kd_dist(points, q, cap=60.0):
    if len(points) == 0: return np.full(len(q), cap, np.float32)
    d, _ = cKDTree(np.asarray(points, np.float32)).query(q, k=1, distance_upper_bound=cap, workers=-1); return np.minimum(d, cap).astype(np.float32)

big = fbm(pos, 70.0, 3, 1); med = fbm(pos, 16.0, 3, 2); fine = fbm(pos, 3.2, 2, 3); grit = vnoise(pos, 1.6, 4); pitn = vnoise(pos, 3.4, 44)
d_cvx = kd_dist(edge_cvx, pos); d_ccv = kd_dist(edge_ccv, pos)
glowm = (mat == MI["glow"])
gsrc = pos[glowm][::7]
d_glow = kd_dist(gsrc, pos, 40.0)
print("noise+dist %.1fs" % (time.time() - t0))

# cracks: thin wandering lines where the texel sits between two random cells
rng = np.random.default_rng(5)
lo, hi = pos.min(0) - 20, pos.max(0) + 20
def cracks(cell, seed, wob=5.0):
    rng = np.random.default_rng(seed); n = int(np.prod((hi - lo) / cell)); seeds = rng.uniform(lo, hi, (n, 3))
    q = pos + np.stack([fbm(pos, 9.0, 2, seed + 1), fbm(pos, 9.0, 2, seed + 2), fbm(pos, 9.0, 2, seed + 3)], 1) * wob * 2 - wob
    d, _ = cKDTree(seeds).query(q, k=2, workers=-1); return (d[:, 1] - d[:, 0]).astype(np.float32)
cr1 = cracks(46.0, 11); cr2 = cracks(24.0, 21, 3.0)
print("cracks %.1fs" % (time.time() - t0))

# per-stone tint and a soft gradient inside every stone
crng = np.random.default_rng(9); ctint = crng.uniform(-1, 1, (cbase, 3)).astype(np.float32)
ct = ctint[comp]
span = np.maximum(comp_hi[comp] - comp_lo[comp], 1e-3); loc = (pos - comp_lo[comp]) / span      # 0..1 inside its own stone
up = nor[:, 2]; shade_dir = np.clip(0.5 + 0.5 * (nor @ np.array([-0.35, -0.45, 0.82], np.float32)), 0, 1)

col = np.zeros((npx, 3), np.float32); emi = np.zeros((npx, 3), np.float32)
def c255(*c): return np.array(c, np.float32) / 255.0

def paint_stone(sel, base, lightc, darkc, crack_amt, moss_amt, wear=1.0):
    b = np.tile(base, (sel.sum(), 1))
    v = 1.0 + 0.10 * ct[sel, 0] + 0.16 * (big[sel] - 0.5) + 0.12 * (med[sel] - 0.5) + 0.07 * (fine[sel] - 0.5)
    b = b * v[:, None]
    b[:, 0] *= 1 + 0.045 * ct[sel, 1]; b[:, 2] *= 1 - 0.06 * ct[sel, 1] + 0.05 * (big[sel] - 0.5)          # warm / cool drift
    b = b * (0.74 + 0.46 * shade_dir[sel])[:, None]                                                         # painted light from top-front-left
    b = b * (0.90 + 0.20 * loc[sel, 2])[:, None]                                                            # each stone lighter at its top
    occ = np.clip(ao[sel], 0, 1) ** 1.4; b = mix(b * (0.42 + 0.58 * occ)[:, None], darkc, (1 - occ) * 0.35)   # dirt in the gaps
    cav = sstep(3.2, 0.0, d_ccv[sel]); b = mix(b, darkc, cav * 0.7)
    # cracks: dark line with a light lip under it
    k1 = sstep(0.34, 0.5, fbm(pos[sel], 40.0, 2, 31)) * crack_amt
    ln = sstep(1.9, 0.5, cr1[sel]) * k1 + sstep(1.1, 0.25, cr2[sel]) * k1 * sstep(0.5, 0.7, fbm(pos[sel], 22.0, 2, 33)) * 0.85
    ln = np.clip(ln, 0, 1); lip = sstep(4.2, 1.9, cr1[sel]) * k1 * (1 - ln)
    b = mix(b, lightc, lip * 0.34); b = mix(b, darkc * 0.7, ln * 0.92)
    # worn edges
    wr = sstep(2.6, 0.2, d_cvx[sel]) * (0.55 + 0.9 * med[sel]) * wear
    b = mix(b, lightc, np.clip(wr, 0, 1) * 0.62)
    # pits and speckle
    pit = sstep(0.74, 0.86, pitn[sel]) * sstep(0.4, 0.6, med[sel]); b = mix(b, darkc, pit * 0.5)
    b = mix(b, lightc, sstep(0.76, 0.9, vnoise(pos[sel] + np.array([0, 0, 1.3], np.float32), 3.4, 44)) * sstep(0.4, 0.6, med[sel]) * 0.22)
    b = b * (0.965 + 0.07 * grit[sel])[:, None]
    # moss / lichen on tops and in corners
    ms = sstep(0.52, 0.72, fbm(pos[sel], 26.0, 3, 41)) * np.clip(0.3 + 0.7 * np.maximum(up[sel], 0) + 0.15 * (1 - occ), 0, 1) * moss_amt
    b = mix(b, c255(104, 118, 38) * (0.8 + 0.4 * fine[sel])[:, None], np.clip(ms, 0, 1) * 0.62)
    return b

S_ = mat == MI["stone"]; col[S_] = paint_stone(S_, c255(156, 116, 88), c255(238, 200, 156), c255(52, 34, 28), 1.0, 0.75)
S2 = mat == MI["stone2"]; col[S2] = paint_stone(S2, c255(120, 98, 76), c255(200, 174, 132), c255(40, 30, 24), 1.35, 0.9)
SL = mat == MI["slate"]; col[SL] = paint_stone(SL, c255(58, 60, 70), c255(126, 132, 150), c255(18, 18, 24), 0.8, 0.12, wear=0.8)
SO = mat == MI["sole"]; col[SO] = paint_stone(SO, c255(46, 46, 50), c255(96, 98, 104), c255(16, 16, 18), 0.6, 0.0, wear=0.7)

L = mat == MI["leather"]
if L.any():
    b = np.tile(c255(132, 66, 36), (L.sum(), 1)) * (0.86 + 0.28 * med[L] + 0.12 * (fine[L] - 0.5))[:, None]
    b = b * (0.82 + 0.3 * shade_dir[L])[:, None]; occ = ao[L] ** 1.3; b = b * (0.5 + 0.5 * occ)[:, None]
    st = sstep(4.2, 3.4, d_cvx[L]) * sstep(2.2, 3.0, d_cvx[L]) * (np.sin((pos[L] @ np.array([1.0, 1.0, 1.0], np.float32)) * 1.6) > 0.2)   # stitches
    b = mix(b, c255(214, 170, 120), st * 0.7); b = mix(b, c255(70, 30, 16), sstep(1.4, 0.0, d_cvx[L]) * 0.6); col[L] = b
M_ = mat == MI["metal"]
if M_.any():
    hl = np.clip(nor[M_] @ np.array([-0.4, -0.5, 0.77], np.float32), 0, 1)
    b = mix(np.tile(c255(96, 98, 108), (M_.sum(), 1)), c255(236, 238, 244), hl ** 2.2); b = b * (0.6 + 0.4 * ao[M_])[:, None]; col[M_] = b
G_ = mat == MI["glow"]
if G_.any():
    dd = np.minimum(d_cvx[G_], d_ccv[G_]) if False else kd_dist(edge_cvx + edge_ccv, pos[G_], 12.0)
    core = sstep(0.3, 3.4, dd); b = mix(np.tile(c255(128, 214, 10), (G_.sum(), 1)), c255(253, 252, 70), core)
    col[G_] = b; emi[G_] = mix(np.tile(c255(120, 210, 8), (G_.sum(), 1)), c255(250, 250, 60), core)
GR = mat == MI["groove"]
if GR.any():
    b = np.tile(c255(120, 168, 28), (GR.sum(), 1)) * (0.7 + 0.5 * med[GR])[:, None]; col[GR] = b; emi[GR] = b * 0.55
C_ = mat == MI["crystal"]
if C_.any():
    h = loc[C_, 2]; fac = np.clip(nor[C_] @ np.array([-0.5, -0.55, 0.67], np.float32), -1, 1) * 0.5 + 0.5
    b = mix(np.tile(c255(36, 132, 8), (C_.sum(), 1)), c255(170, 250, 60), np.clip(0.15 + 0.6 * h + 0.45 * (fac - 0.5), 0, 1))
    b = mix(b, c255(238, 255, 190), sstep(1.8, 0.2, d_cvx[C_]) * 0.75); b = mix(b, c255(250, 255, 170), sstep(0.62, 0.9, fac) * sstep(0.5, 1.0, h) * 0.5)
    col[C_] = b; emi[C_] = b * (0.25 + 0.4 * h)[:, None]
MO = mat == MI["moss"]
if MO.any():
    b = mix(np.tile(c255(74, 96, 22), (MO.sum(), 1)), c255(160, 172, 48), np.clip(0.2 + 0.5 * loc[MO, 2] + 0.5 * (fine[MO] - 0.3) + 0.3 * shade_dir[MO], 0, 1))
    b = b * (0.55 + 0.45 * ao[MO] ** 1.2)[:, None]; b = mix(b, c255(196, 200, 80), sstep(1.2, 0.0, d_cvx[MO]) * 0.35); col[MO] = b
SK = mat == MI["skin"]; col[SK] = c255(250, 206, 164) * (0.9 + 0.1 * np.clip(ao[SK] * 1.6, 0, 1))[:, None]      # plain avatar skin
HA = mat == MI["hair"]
if HA.any():
    b = np.tile(c255(132, 70, 38), (HA.sum(), 1)) * (0.82 + 0.22 * (big[HA] - 0.5) + 0.3 * med[HA])[:, None]
    b = b * ((0.62 + 0.5 * shade_dir[HA]) * (0.5 + 0.5 * ao[HA] ** 1.2))[:, None]
    b = mix(b, c255(226, 150, 92), sstep(2.4, 0.2, d_cvx[HA]) * 0.55); b = mix(b, c255(46, 20, 10), sstep(2.6, 0.0, d_ccv[HA]) * 0.6); col[HA] = b
SU = mat == MI["suit"]
if SU.any():                                     # the dark under-suit (the avatar's body) with thin glowing cracks
    b = paint_stone(SU, c255(58, 60, 70), c255(120, 126, 144), c255(18, 18, 24), 0.7, 0.05, wear=0.5)
    gk = sstep(1.5, 0.45, cr1[SU]) * sstep(0.56, 0.66, fbm(pos[SU], 85.0, 2, 77)); halo = sstep(7.0, 1.0, cr1[SU]) * sstep(0.56, 0.66, fbm(pos[SU], 85.0, 2, 77))
    b = mix(b, c255(120, 190, 30), halo * 0.35); b = mix(b, c255(238, 250, 70), gk)
    col[SU] = b; emi[SU] = c255(170, 235, 30)[None, :] * (gk + 0.25 * halo)[:, None]
FA = mat == MI["face"]; col[FA] = c255(24, 22, 20)
GP = mat == MI["gap"]; col[GP] = c255(34, 22, 18) * (0.7 + 0.6 * med[GP])[:, None]

# glow spilling onto the stone next to runes, knuckles and cracks
spill_ok = ~(G_ | GR | C_ | SK | FA | HA)
sp = np.exp(-d_glow / 7.0) * spill_ok
col = mix(col, np.maximum(col, 0.0) * 0.55 + c255(150, 215, 30) * 0.55, np.clip(sp * 0.85, 0, 1))
emi = emi + c255(150, 230, 25)[None, :] * (np.exp(-d_glow / 5.0) * spill_ok * 0.30)[:, None]
col = np.clip(col, 0, 1); emi = np.clip(emi, 0, 1)
print("painted %.1fs" % (time.time() - t0))

# ---------------- write images (with edge padding) ----------------
def atlas(vals):
    img = np.zeros((R, R, 3), np.float32); img[filled] = vals
    idx = ndi.distance_transform_edt(~filled, return_distances=False, return_indices=True)
    return img[idx[0], idx[1]]
def save_png(arr, name):
    path = os.path.join(OUT, name + ".png")
    old = bpy.data.images.get(name)
    if old: bpy.data.images.remove(old)
    img = bpy.data.images.new(name, R, R, alpha=False)
    px = np.ones((R, R, 4), np.float32); px[..., :3] = arr[::-1]; img.pixels.foreach_set(px.ravel())
    img.filepath_raw = path; img.file_format = 'PNG'; img.save(); return img
VER = os.environ.get("STONE_VER", "v3")
ci = save_png(atlas(col), "stone_%s_color" % VER); ei = save_png(atlas(emi), "stone_%s_glow" % VER)

# ---------------- final material ----------------
fm = bpy.data.materials.get(COLL) or bpy.data.materials.new(COLL); fm.use_nodes = True; nt_ = fm.node_tree; nt_.nodes.clear()
out_ = nt_.nodes.new("ShaderNodeOutputMaterial"); b_ = nt_.nodes.new("ShaderNodeBsdfPrincipled"); nt_.links.new(b_.outputs["BSDF"], out_.inputs["Surface"])
tc = nt_.nodes.new("ShaderNodeTexImage"); tc.image = ci; te = nt_.nodes.new("ShaderNodeTexImage"); te.image = ei
nt_.links.new(tc.outputs["Color"], b_.inputs["Base Color"]); nt_.links.new(te.outputs["Color"], b_.inputs["Emission Color"])
b_.inputs["Emission Strength"].default_value = 1.15; b_.inputs["Roughness"].default_value = 0.9
for o in objs:
    me = o.data
    for p in me.polygons: p.material_index = 0
    me.materials.clear(); me.materials.append(fm); o.select_set(False)
for m_ in list(bpy.data.materials):
    if m_.name.startswith("SS2_") and m_.users == 0: bpy.data.materials.remove(m_)
print("painted and applied %.1fs" % (time.time() - t0), "| tris", len(P), "| atlas", R, "| texels used %.0f%%" % (filled.mean() * 100))
