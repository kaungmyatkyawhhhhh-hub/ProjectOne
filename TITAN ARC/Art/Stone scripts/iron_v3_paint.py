# STOMP EVOLUTION - STONE set v3: build the 3D model and PAINT its textures on the real shapes (no sheet picture is projected).
# Runs inside Blender (the owner's Blender on the PC, or headless).  exec(open(r"<vault>\TITAN ARC\Art\Stone\stone_v3_paint.py").read())
# 1) build the model (stone_v3.py: the Bacon Hair avatar wearing the armour)  2) unwrap every part into one atlas  3) for every texel work out where it sits on the model
# 4) paint it in 3D: stone colour per block, top-light, worn edges, dirt in the gaps, cracks, speckle, moss tint, glow spill
# 5) save the colour map + glow map next to this script and put them on the model
import bpy
import bmesh, sys, os, math, time
from mathutils import Vector
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

# v10c: give the VISIBLE surfaces the texels (Korblox spends almost its whole map on what you see).
# Each UV island is scaled by how exposed its faces are (rays cast outwards hit other armour = hidden), then everything is re-packed.
if os.environ.get("STONE_VISPACK", "1") == "1":
    import bmesh as _bm
    from mathutils.bvhtree import BVHTree as _BVH
    _allv, _allf, _off = [], [], 0
    for o in objs:
        mw = o.matrix_world; me = o.data
        _allv += [mw @ v.co for v in me.vertices]; _allf += [[i + _off for i in p_.vertices] for p_ in me.polygons]; _off += len(me.vertices)
    _tree = _BVH.FromPolygons(_allv, _allf, all_triangles=False, epsilon=0.0)
    _dirs = [Vector((0, 0, 1)), Vector((0.6, 0, 0.8)), Vector((-0.6, 0, 0.8)), Vector((0, 0.6, 0.8)), Vector((0, -0.6, 0.8))]
    _nis, _vsum = 0, []
    for o in objs:
        mw = o.matrix_world; nm = mw.to_3x3().inverted().transposed()
        bm = _bm.new(); bm.from_mesh(o.data); bm.faces.ensure_lookup_table(); uvl = bm.loops.layers.uv.active
        # visibility per face
        vis = {}
        for f in bm.faces:
            c = mw @ f.calc_center_median(); n = (nm @ f.normal).normalized()
            q = n.to_track_quat('Z', 'Y'); hits = 0
            for d in _dirs:
                dd = (q @ d).normalized(); loc, _, _, dist = _tree.ray_cast(c + n * 0.6, dd, 60.0)
                if loc is not None: hits += 1
            vis[f.index] = 1.0 - hits / len(_dirs)
        # UV islands (faces joined where the shared edge has the same UVs on both sides)
        par = list(range(len(bm.faces)))
        def fnd(a):
            while par[a] != a: par[a] = par[par[a]]; a = par[a]
            return a
        for e in bm.edges:
            lf = e.link_faces
            if len(lf) != 2: continue
            f1, f2 = lf
            def uvs(f):
                return {l.vert.index: l[uvl].uv.copy() for l in f.loops if l.vert in e.verts}
            u1, u2 = uvs(f1), uvs(f2)
            if all((u1[k] - u2[k]).length < 1e-5 for k in u1): par[fnd(f1.index)] = fnd(f2.index)
        isl = {}
        for f in bm.faces: isl.setdefault(fnd(f.index), []).append(f)
        for fs in isl.values():
            ar = sum(f.calc_area() for f in fs) or 1.0
            v = sum(vis[f.index] * f.calc_area() for f in fs) / ar
            sc_ = 0.22 + 0.78 * v                                   # hidden islands shrink to ~1/20 of the area
            us = [l[uvl].uv for f in fs for l in f.loops]
            cu = sum((u.x for u in us)) / len(us); cv = sum((u.y for u in us)) / len(us)
            for f in fs:
                for l in f.loops:
                    l[uvl].uv.x = cu + (l[uvl].uv.x - cu) * sc_; l[uvl].uv.y = cv + (l[uvl].uv.y - cv) * sc_
            _nis += 1; _vsum.append(v)
        bm.to_mesh(o.data); bm.free()
    def _pack():
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.uv.select_all(action='SELECT')
        try: bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.0015, shape_method='CONCAVE')
        except TypeError: bpy.ops.uv.pack_islands(rotate=True, margin=0.0015)
        bpy.ops.object.mode_set(mode='OBJECT')
    in_view3d(_pack)
    print("vis-pack: %d islands, mean visibility %.2f, %.1fs" % (_nis, sum(_vsum) / max(len(_vsum), 1), time.time() - t0))

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

# v10 (owner 13:36 "korblox ... textures and materials are just so good, ours look plasticky"): Korblox paints
# cloudy mottled stone, a dense web of fine dark cracks, DARK plate outlines, carved glyph bands along plate borders and grain.
cr3 = cracks(11.0, 61, 1.6)
# carved glyphs: 5x5 bitmaps (meander / key shapes, no swastika-like shapes), laid on the dominant plane of each texel
GLY = [np.array(g, np.float32) for g in (
    [[1,1,1,1,1],[0,0,0,0,1],[1,1,1,0,1],[1,0,0,0,1],[1,1,1,1,1]],
    [[1,1,1,1,1],[1,0,0,0,0],[1,0,1,1,1],[1,0,0,0,1],[1,1,1,1,1]],
    [[1,0,1,1,1],[1,0,1,0,0],[1,0,1,1,1],[1,0,0,0,1],[1,1,1,1,1]],
    [[1,1,1,1,1],[1,0,0,0,1],[1,0,1,0,1],[0,0,1,0,1],[1,1,1,0,1]],
    [[1,1,1,0,0],[0,0,1,0,0],[1,1,1,1,1],[1,0,0,0,1],[1,1,0,1,1]],
    [[0,1,1,1,1],[0,1,0,0,0],[0,1,1,1,0],[0,0,0,1,0],[1,1,1,1,0]])]
GLYS = np.stack(GLY)
def glyph_mask(P, Nn, cell=17.0, seed=7):
    ax = np.argmax(np.abs(Nn), 1)
    u = np.where(ax == 0, P[:, 1], P[:, 0]); v = np.where(ax == 2, P[:, 1], P[:, 2])
    cu = np.floor(u / cell); cv = np.floor(v / cell)
    fu = (u / cell - cu); fv = (v / cell - cv)
    gi = (hsh(cu.astype(np.int64), cv.astype(np.int64), ax.astype(np.int64), seed) * len(GLY)).astype(np.int64) % len(GLY)
    # 1 texel-cell margin so neighbouring glyphs don't touch: draw the 5x5 inside 0.12..0.88
    gx = np.clip(((fu - 0.12) / 0.76 * 5).astype(np.int64), 0, 4); gy = np.clip(((fv - 0.12) / 0.76 * 5).astype(np.int64), 0, 4)
    inside = (fu > 0.12) & (fu < 0.88) & (fv > 0.12) & (fv < 0.88)
    on = GLYS[gi, 4 - gy, gx] * inside
    # light lip on the lower edge of each carved stroke (sun from top): sample one step below
    gy2 = np.clip(((fv + 0.06 - 0.12) / 0.76 * 5).astype(np.int64), 0, 4)
    lip = (GLYS[gi, 4 - gy2, gx] * inside) * (1 - on)
    return on.astype(np.float32), lip.astype(np.float32)

def paint_stone(sel, base, lightc, darkc, crack_amt, moss_amt, wear=1.0, glyphs=0.0):
    P = pos[sel]
    b = np.tile(base, (sel.sum(), 1))
    # cloudy mottling (Korblox: soft light/dark blotches) + grain
    cloud = fbm(P, 34.0, 3, 101)
    v = 1.0 + 0.05 * ct[sel, 0] + 0.20 * (big[sel] - 0.5) + 0.22 * (cloud - 0.5) + 0.06 * (med[sel] - 0.5) + 0.04 * (fine[sel] - 0.5)
    b = b * v[:, None]
    b[:, 0] *= 1 + 0.045 * ct[sel, 1]; b[:, 2] *= 1 - 0.06 * ct[sel, 1] + 0.05 * (big[sel] - 0.5)
    b = b * (0.62 + 0.62 * shade_dir[sel])[:, None]                                                       # painted light, a bit softer
    b = b * (0.78 + 0.36 * loc[sel, 2] ** 1.2)[:, None]
    occ = np.clip(ao[sel], 0, 1) ** 1.6; b = mix(b * (0.30 + 0.70 * occ)[:, None], darkc, (1 - occ) * 0.55)
    cav = sstep(5.0, 0.0, d_ccv[sel]); b = mix(b, darkc * 0.55, cav * 0.95)
    # DARK plate outline right on the edge, faint light lip just inside it (no bright plastic rim)
    rim_dark = sstep(1.6, 0.2, d_cvx[sel]) * wear
    rim_lip = sstep(1.4, 2.4, d_cvx[sel]) * sstep(5.5, 2.6, d_cvx[sel]) * wear
    b = mix(b, lightc, rim_lip * 0.22)
    b = mix(b, darkc * 0.8, rim_dark * 0.62)
    # crack web: big cracks + medium + a fine network everywhere (thin dark line, faint light lip below)
    k1 = (0.55 + 0.45 * sstep(0.3, 0.55, fbm(P, 40.0, 2, 31))) * crack_amt
    l1 = sstep(1.5, 0.35, cr1[sel]); l2 = sstep(0.95, 0.2, cr2[sel]) * sstep(0.42, 0.62, fbm(P, 22.0, 2, 33))
    l3 = sstep(0.55, 0.12, cr3[sel]) * sstep(0.48, 0.66, fbm(P, 14.0, 2, 35))
    ln = np.clip(l1 + 0.85 * l2 + 0.6 * l3, 0, 1) * k1
    lip = sstep(3.4, 1.5, cr1[sel]) * k1 * (1 - ln)
    b = mix(b, lightc, lip * 0.16); b = mix(b, darkc * 0.6, ln * 0.85)
    # carved glyph band along plate borders
    if glyphs > 0:
        on, glip = glyph_mask(P, nor[sel])
        flat = sstep(0.86, 0.93, np.abs(nor[sel]).max(1))      # only on flat faces: on curved ones the plane flips and the glyphs turn into scribbles
        band = sstep(3.0, 4.0, d_cvx[sel]) * sstep(17.5, 16.0, d_cvx[sel]) * (span[sel].max(1) > 140.0) * flat * glyphs
        b = mix(b, darkc * 0.8, on * band * 0.58); b = mix(b, lightc, glip * band * 0.28)
    # moss / lichen on tops and in corners
    ms = sstep(0.52, 0.72, fbm(P, 26.0, 3, 41)) * np.clip(0.3 + 0.7 * np.maximum(up[sel], 0) + 0.15 * (1 - occ), 0, 1) * moss_amt
    b = mix(b, c255(104, 118, 38) * (0.8 + 0.4 * fine[sel])[:, None], np.clip(ms, 0, 1) * 0.62)
    return b

# ---- IRON: painted metal (Korblox-style hand-painted look, not PBR): sky/ground reflection on the plate, brushed streaks,
#      dark outline + crisp light bevel on every edge, a few light scratches, grime in the gaps, engraved border line ----
def paint_metal(sel, base, lightc, darkc, wear=1.0, engrave=0.0, glyphs=0.0):
    """IRON v2 (owner 15:04 "u still did the same mistakes"): forged, MATTE dark iron painted like Korblox:
    no bright rims, no shiny sky reflection (it turned the boots pale and plastic), dark values, hammered mottling,
    grime, scratches, dark outlines, carved glyph band on big flat plates."""
    P = pos[sel]
    b = np.tile(base, (sel.sum(), 1))
    hammer = fbm(P, 9.0, 3, 211)                                                       # hammered / forged dents
    cloud = fbm(P, 34.0, 3, 101)
    brushed = fbm(P * np.array([1.0, 1.0, 0.07], np.float32), 5.0, 2, 201)
    v = 1.0 + 0.05 * ct[sel, 0] + 0.16 * (big[sel] - 0.5) + 0.16 * (cloud - 0.5) + 0.10 * (hammer - 0.5) + 0.05 * (brushed - 0.5)
    b = b * v[:, None]
    b = b * (0.62 + 0.58 * shade_dir[sel])[:, None]                                   # painted light only (no environment reflection)
    b = b * (0.80 + 0.32 * loc[sel, 2] ** 1.2)[:, None]
    occ = np.clip(ao[sel], 0, 1) ** 1.6; b = mix(b * (0.30 + 0.70 * occ)[:, None], darkc, (1 - occ) * 0.6)
    cav = sstep(5.0, 0.0, d_ccv[sel]); b = mix(b, darkc * 0.5, cav * 0.95)
    rust = sstep(0.60, 0.78, fbm(P, 22.0, 3, 215)) * np.clip(0.4 + 0.6 * (1 - occ), 0, 1)  # a little dark rust in hollows
    b = mix(b, c255(58, 38, 30), rust * 0.35)
    out = sstep(1.6, 0.2, d_cvx[sel]) * wear                                           # DARK plate outline (like Korblox)
    lip = sstep(1.4, 2.4, d_cvx[sel]) * sstep(5.0, 2.6, d_cvx[sel]) * wear            # only a faint light lip inside it
    b = mix(b, lightc, lip * 0.16); b = mix(b, darkc * 0.75, out * 0.68)
    scr = sstep(0.42, 0.08, cr2[sel]) * sstep(0.60, 0.72, fbm(P, 20.0, 2, 207))
    b = mix(b, lightc, scr * 0.22)                                                     # scratches: subtle
    dent = sstep(0.55, 0.12, cr3[sel]) * sstep(0.52, 0.68, fbm(P, 14.0, 2, 35))
    b = mix(b, darkc * 0.7, dent * 0.35)                                               # fine dark wear lines
    if engrave > 0:
        ln = sstep(1.3, 0.3, np.abs(d_cvx[sel] - 9.0)) * (span[sel].max(1) > 90.0)
        b = mix(b, darkc * 0.7, ln * 0.6 * engrave)
    if glyphs > 0:
        on, glip = glyph_mask(P, nor[sel])
        flat = sstep(0.86, 0.93, np.abs(nor[sel]).max(1))
        band = sstep(11.0, 12.0, d_cvx[sel]) * sstep(26.0, 24.5, d_cvx[sel]) * (span[sel].max(1) > 140.0) * flat * glyphs
        b = mix(b, darkc * 0.75, on * band * 0.55); b = mix(b, lightc, glip * band * 0.18)
    return b

S_ = mat == MI["stone"]; col[S_] = paint_metal(S_, c255(66, 74, 90), c255(176, 194, 214), c255(10, 12, 18), engrave=1.0, glyphs=1.0)
S2 = mat == MI["stone2"]; col[S2] = paint_metal(S2, c255(40, 45, 56), c255(140, 158, 182), c255(8, 9, 14))
SL = mat == MI["slate"]; col[SL] = paint_stone(SL, c255(58, 60, 70), c255(126, 132, 150), c255(18, 18, 24), 0.8, 0.12, wear=0.8)
SO = mat == MI["sole"]; col[SO] = paint_stone(SO, c255(46, 46, 50), c255(96, 98, 104), c255(16, 16, 18), 0.6, 0.0, wear=0.7)

L = mat == MI["leather"]
if L.any():
    b = np.tile(c255(70, 44, 32), (L.sum(), 1)) * (0.86 + 0.28 * med[L] + 0.12 * (fine[L] - 0.5))[:, None]
    b = b * (0.82 + 0.3 * shade_dir[L])[:, None]; occ = ao[L] ** 1.3; b = b * (0.5 + 0.5 * occ)[:, None]
    st = sstep(4.2, 3.4, d_cvx[L]) * sstep(2.2, 3.0, d_cvx[L]) * (np.sin((pos[L] @ np.array([1.0, 1.0, 1.0], np.float32)) * 1.6) > 0.2)   # stitches
    b = mix(b, c255(214, 170, 120), st * 0.7); b = mix(b, c255(70, 30, 16), sstep(1.4, 0.0, d_cvx[L]) * 0.6); col[L] = b
M_ = mat == MI["metal"]
if M_.any():                                     # IRON v3: polished steel trims = the contrast colour (like Korblox's pale trims), tube-shaded
    hl = np.clip(nor[M_] @ np.array([-0.4, -0.5, 0.77], np.float32), 0, 1)
    b = mix(np.tile(c255(92, 112, 140), (M_.sum(), 1)), c255(214, 230, 246), hl ** 1.6)
    b = b * (0.55 + 0.45 * ao[M_])[:, None]
    b = mix(b, c255(20, 26, 36), sstep(0.9, 0.1, d_cvx[M_]) * 0.5)
    col[M_] = b
G_ = mat == MI["glow"]
if G_.any():
    dd = np.minimum(d_cvx[G_], d_ccv[G_]) if False else kd_dist(edge_cvx + edge_ccv, pos[G_], 12.0)
    core = sstep(0.3, 3.4, dd); b = mix(np.tile(c255(30, 170, 255), (G_.sum(), 1)), c255(225, 250, 255), core)
    col[G_] = b; emi[G_] = mix(np.tile(c255(30, 160, 255), (G_.sum(), 1)), c255(220, 248, 255), core)
GR = mat == MI["groove"]
if GR.any():
    b = np.tile(c255(28, 120, 180), (GR.sum(), 1)) * (0.7 + 0.5 * med[GR])[:, None]; col[GR] = b; emi[GR] = b * 0.55
C_ = mat == MI["crystal"]
if C_.any():
    h = loc[C_, 2]; fac = np.clip(nor[C_] @ np.array([-0.5, -0.55, 0.67], np.float32), -1, 1) * 0.5 + 0.5
    Pc = pos[C_]; streak = fbm(Pc * np.array([3.0, 3.0, 0.35], np.float32), 10.0, 3, 91)                 # long streaks along the crystal
    b = mix(np.tile(c255(8, 34, 110), (C_.sum(), 1)), c255(80, 190, 255), np.clip(0.1 + 0.55 * h + 0.5 * (fac - 0.5) + 0.35 * (streak - 0.5), 0, 1))
    b = mix(b, c255(120, 120, 255), sstep(0.55, 0.8, fbm(Pc, 18.0, 2, 93)) * 0.35)                          # cool teal inner tint
    b = mix(b, c255(4, 14, 50), sstep(1.6, 0.1, d_ccv[C_]) * 0.6)                                         # dark facet joins
    b = mix(b, c255(215, 245, 255), sstep(1.5, 0.15, d_cvx[C_]) * 0.7)                                    # bright facet ridges
    b = mix(b, c255(235, 252, 255), sstep(0.68, 0.8, streak) * sstep(0.55, 0.9, fac) * 0.6)               # specular streaks
    col[C_] = b; emi[C_] = b * (0.2 + 0.35 * h)[:, None]
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
    b = paint_stone(SU, c255(30, 34, 46), c255(84, 92, 118), c255(10, 10, 14), 0.2, 0.0, wear=0.5)
    gk = sstep(1.5, 0.45, cr1[SU]) * sstep(0.70, 0.76, fbm(pos[SU], 85.0, 2, 77)); halo = sstep(7.0, 1.0, cr1[SU]) * sstep(0.70, 0.76, fbm(pos[SU], 85.0, 2, 77))
    b = mix(b, c255(30, 150, 230), halo * 0.35); b = mix(b, c255(200, 245, 255), gk)
    col[SU] = b; emi[SU] = c255(40, 190, 255)[None, :] * (gk + 0.25 * halo)[:, None]
FA = mat == MI["face"]; col[FA] = c255(24, 22, 20)
GP = mat == MI["gap"]; col[GP] = c255(34, 22, 18) * (0.7 + 0.6 * med[GP])[:, None]

# glow spilling onto the stone next to runes, knuckles and cracks
spill_ok = ~(G_ | GR | C_ | SK | FA | HA)
sp = np.exp(-d_glow / 7.0) * spill_ok
col = mix(col, np.maximum(col, 0.0) * 0.55 + c255(40, 170, 255) * 0.55, np.clip(sp * 0.85, 0, 1))
emi = emi + c255(40, 180, 255)[None, :] * (np.exp(-d_glow / 5.0) * spill_ok * 0.30)[:, None]
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
