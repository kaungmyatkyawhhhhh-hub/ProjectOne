# per converted car: every cover (blank patch or fictional emblem) in the game's model frame:
# metres from the middle of the four wheel centres along right / up / back, its facing, size, colour
import bpy, sys, re, json, math
from mathutils import Vector
from mathutils.geometry import barycentric_transform
sys.path.insert(0, "/tmp/claude-0/logo")
from picks import PICKS, PLATES, KEEP
blend, car, out = sys.argv[-3], sys.argv[-2], sys.argv[-1]
HUB_R = {"brabos_g63": 0.05, "bentz_s63": 0.05, "bentz_sls": 0.045, "bentz_s680": 0.045, "bentz_gls": 0.038, "toyoka_lc300": 0.045,
         "chevo_camaro": 0.046, "mazdo_rx8": 0.037, "bentz_sl65bs": 0.035, "bentz_gle53": 0.033, "bentz_maybach": 0.03, "bentz_cls63s": 0.032,
         "bentz_gt63s": 0.04, "byt_u8": 0.045, "lexis_lfa": 0.04, "lexis_lx700": 0.045}
bpy.ops.wm.open_mainfile(filepath=blend)
dg = bpy.context.evaluated_depsgraph_get(); sc = bpy.context.scene
MARK = re.compile(r"badge|logo|emblem|letter|decal_badg|sign\b", re.I)
keep = set(KEEP.get(car, []))
for o in bpy.data.objects:
    if o.name.startswith("SeeThrough"): o.hide_set(True); o.hide_render = True
bpy.context.view_layer.update(); dg = bpy.context.evaluated_depsgraph_get()
def g(v): return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]
def lin2s(c): return [round(((x * 12.92) if x <= 0.0031308 else (1.055 * x ** (1 / 2.4) - 0.055)), 3) for x in c]
def colour_at(obj, loc, fi):
    me = obj.data
    if fi >= len(me.polygons): return None
    poly = me.polygons[fi]
    mat = me.materials[poly.material_index] if me.materials else None
    if not mat or not mat.node_tree: return None
    b = mat.node_tree.nodes.get("Principled BSDF")
    if not b: return None
    inp = b.inputs["Base Color"]
    if not inp.is_linked: return lin2s(inp.default_value[:3])
    todo = [inp.links[0].from_node]; img = None; seen = 0
    while todo and seen < 20:
        x = todo.pop(0); seen += 1
        if x.type == "TEX_IMAGE" and x.image: img = x.image; break
        for i in x.inputs:
            for l in i.links: todo.append(l.from_node)
    if not img or not me.uv_layers.active: return None
    lp = obj.matrix_world.inverted() @ loc
    li = poly.loop_indices
    best = None
    for k in range(1, len(li) - 1):
        ids = [li[0], li[k], li[k + 1]]
        vs = [me.vertices[me.loops[i].vertex_index].co for i in ids]
        uvs = [Vector((*me.uv_layers.active.data[i].uv, 0)) for i in ids]
        best = barycentric_transform(lp, *vs, *uvs); break
    W, H = img.size
    if W == 0: return None
    x = int((best.x % 1) * W) % W; y = int((best.y % 1) * H) % H
    if not hasattr(img, "_px"):
        pass
    px = img.pixels[(y * W + x) * 4:(y * W + x) * 4 + 3]
    if img.colorspace_settings.name != "sRGB" and img.is_float: px = lin2s(px)
    return [round(v, 3) for v in px]
def cast(o, d):
    hit, loc, nrm, idx, obj, _ = sc.ray_cast(dg, o, d)
    return (loc, nrm, idx, obj) if hit else None
def median(cs):
    cs = [c for c in cs if c]
    if not cs: return [0.1, 0.1, 0.1]
    # the sample closest to all the others (a light or a letter at the edge doesn't win)
    best = min(cs, key=lambda c: sorted(sum(abs(c[i] - o[i]) for i in range(3)) for o in cs)[len(cs) // 2])
    return list(best)
# wheel middle
wc = {}
for k in ("FL", "FR", "RL", "RR"):
    o = bpy.data.objects[k]; wc[k] = o.matrix_world @ (sum((Vector(v) for v in o.bound_box), Vector()) / 8)
mid = sum(wc.values(), Vector()) / 4
covers = []
# ---- picked texture logos and plates, from the views
views = json.load(open(f"/tmp/claude-0/logo/v/{car}.views.json"))
def ray_for(view, px, py):
    v = views[view]; W, H = v["W"], v["H"]
    eye, look = Vector(v["eye"]), Vector(v["look"])
    fwd = (look - eye).normalized()
    rot = fwd.to_track_quat("-Z", "Y")
    right = rot @ Vector((1, 0, 0)); up = rot @ Vector((0, 1, 0))
    sens = 36.0; f = v["lens"]
    # Blender fits the sensor width to the larger side
    wpp = sens / f / W  # tan-plane units per pixel
    d = (fwd + right * (px - W / 2) * wpp - up * (py - H / 2) * wpp).normalized()
    return eye, d, wpp
def add_pick(view, cx, cy, w, h, kind, mirror_ok=True):
    eye, d, wpp = ray_for(view, cx, cy)
    hits = []
    for fx in (-0.4, -0.2, 0, 0.2, 0.4):
        for fy in (-0.35, 0, 0.35):
            e2, d2, _ = ray_for(view, cx + fx * w, cy + fy * h)
            hh = cast(e2, d2)
            if hh: hits.append(((hh[0] - e2).length, hh, d2))
    if not hits: print("MISS", car, view, cx, cy); return
    dmin = min(x[0] for x in hits)
    near = [x for x in hits if x[0] < dmin + 0.03]
    nrm = Vector()
    for x in near:
        n = x[1][1]
        nrm += -n if n.dot(x[2]) > 0 else n
    nrm.normalize()
    stand = kind == "stand"
    if stand: nrm = -d; kind = "emblem"
    loc = eye + d * (dmin - (0.008 if kind == "emblem" else 0))
    dist = dmin
    mpp = dist * wpp
    wm, hm = w * mpp * 1.15, h * mpp * 1.15
    samp = []
    for ax, ay in ([(-0.62, 0), (0.62, 0), (0, -0.75), (0, 0.75), (-0.62, -0.75), (0.62, 0.75), (-0.62, 0.75), (0.62, -0.75)] if kind != "plate" else [(fx, fy) for fx in (-0.36, -0.18, 0, 0.18, 0.36) for fy in (-0.3, 0, 0.3)]):
        e2, d2, _ = ray_for(view, cx + ax * w * (1.15 if kind != "plate" else 1), cy + ay * h * (1.15 if kind != "plate" else 1))
        hh = cast(e2, d2)
        if hh: samp.append(colour_at(hh[3].original if hasattr(hh[3], "original") else hh[3], hh[0], hh[2]))
    col = median(samp)
    if kind == "plate":
        wm, hm = w * mpp * 0.98, h * mpp * 0.96
        loc = loc + nrm * 0.006  # plates sit at a slant in a recess
    c = {"kind": "emblem" if kind == "emblem" else "blank", "shape": "disc" if kind == "emblem" else "rect", "at": g(loc - mid), "face": g(nrm), "w": round(wm, 4), "h": round(hm, 4), "color": col, "view": view}
    covers.append(c)
    if view == "S" and mirror_ok:
        p2 = Vector((-loc.x, loc.y, loc.z)); n2 = Vector((-nrm.x, nrm.y, nrm.z))
        hh = cast(p2 + n2 * 0.3, -n2)
        if hh and (hh[0] - p2).length < 0.05:
            c2 = dict(c); c2["at"] = g(hh[0] - mid); n3 = hh[1] if hh[1].dot(n2) > 0 else -hh[1]; c2["face"] = g(n3); covers.append(c2)
        else:
            print("NOMIRROR", car, view, cx, cy)
for p in PICKS.get(car, []):
    add_pick(*p)
for p in PLATES.get(car, []):
    add_pick(*p, "plate")
# ---- badge-named parts: their pieces (for the emblems of BNW / Mercer / Lexis cars)
groups = []
for ob in bpy.data.objects:
    if ob.type != "MESH" or ob.name.startswith(("FL", "FR", "RL", "RR", "SteeringWheel")) or ob.name in keep: continue
    if not (MARK.search(ob.name) or any(m and MARK.search(m.name) for m in ob.data.materials)): continue
    import bmesh
    bm = bmesh.new(); bm.from_mesh(ob.data); bm.transform(ob.matrix_world); bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
    seen = set(); isl = []
    for v in bm.verts:
        if v.index in seen: continue
        st = [v]; seen.add(v.index); pts = []; nsum = Vector()
        while st:
            x = st.pop(); pts.append(x.co.copy())
            for f in x.link_faces: nsum += f.normal * f.calc_area()
            for e in x.link_edges:
                y = e.other_vert(x)
                if y.index not in seen: seen.add(y.index); st.append(y)
        lo = Vector(map(min, zip(*pts))); hi = Vector(map(max, zip(*pts)))
        isl.append([lo, hi, nsum])
    merged = True
    while merged:
        merged = False
        for i in range(len(isl)):
            for j in range(i + 1, len(isl)):
                a, b = isl[i], isl[j]
                gap = max(max(a[0][k] - b[1][k], b[0][k] - a[1][k]) for k in range(3))
                if gap < 0.02:
                    isl[i] = [Vector(map(min, a[0], b[0])), Vector(map(max, a[1], b[1])), a[2] + b[2]]; isl.pop(j); merged = True; break
            if merged: break
    for lo, hi, n in isl:
        groups.append({"obj": ob.name, "at": g((lo + hi) / 2 - mid), "size": [round(abs(x), 4) for x in g(hi - lo)], "n": g(n.normalized()) if n.length > 1e-9 else [0, 0, 0]})
    bm.free()
# ---- wheel caps: the flat middle of each wheel, its radius, and the colour round it
caps = {}
for k, c in wc.items():
    s = 1 if c.x > mid.x else -1
    def at_r(r, a=0.0):
        o = c + Vector((s * 1.0, math.cos(a) * r, math.sin(a) * r))
        h = cast(o, Vector((-s, 0, 0)))
        return h
    h0 = at_r(0)
    if not h0: continue
    x0 = h0[0].x
    R = 0.03
    for i in range(1, 30):
        r = 0.005 * i
        hs = [at_r(r, a * math.pi / 4) for a in range(8)]
        jump = any((not h) or abs(h[0].x - x0) > 0.008 for h in hs)
        if jump: R = max(0.018, r - 0.002); break
    else:
        R = 0.06
    ring = [at_r(min(R * 1.3, R + 0.012), a * math.pi / 4) for a in range(8)]
    col = median([colour_at(h[3], h[0], h[2]) for h in ring if h])
    face = Vector((s, 0, 0))
    caps[("F" if c.y < mid.y else "R") + ("L" if -c.x < 0 else "R")] = {"at": g(Vector((c.x + s * 0.0, c.y, c.z)) - mid), "surface": round(abs(x0 - c.x), 4), "r": round(R, 4), "color": col, "obj": h0[3].name}
# ---- steering hub
hub = None
sw = next((o for o in bpy.data.objects if o.name.startswith("SteeringWheel")), None)
if sw:
    from mathutils.bvhtree import BVHTree
    v = [sw.matrix_world @ x.co for x in sw.data.vertices]
    a = Vector(map(min, zip(*v))); b = Vector(map(max, zip(*v))); c = (a + b) / 2
    t = math.radians(int(re.match(r"SteeringWheel_t(\d+)", sw.name).group(1)))
    axis = Vector((0, -math.cos(t), -math.sin(t)))
    bvh = BVHTree.FromObject(sw, dg); M = sw.matrix_world; Mi = M.inverted()
    up = Vector((0, 0, 1)); up = (up - axis * up.dot(axis)).normalized()
    def hc(p):
        loc, nrm, idx, dist = bvh.ray_cast(Mi @ p, (Mi.to_3x3() @ axis).normalized())
        return (M @ loc, idx) if loc is not None else None
    R = HUB_R.get(car, 0.03)
    up0 = Vector((0, 0, 1)); upp0 = (up0 - axis * up0.dot(axis)).normalized(); rt0 = axis.cross(upp0).normalized()
    # where the logo is: the wheel's own badge faces, else the middle of its round rim
    me = sw.data; logo = None
    bad = [i for i, m in enumerate(me.materials) if m and MARK.search(m.name)]
    if bad:
        pts = []
        for p in me.polygons:
            if p.material_index in bad:
                q = M @ p.center
                if (q - c).length < 0.12: pts.append(q)
        if pts: logo = sum(pts, Vector()) / len(pts)
    if logo is None:
        ang = {}
        for q in v:
            d0 = q - c; x = d0.dot(rt0); y = d0.dot(upp0); r = math.hypot(x, y)
            k = int((math.atan2(y, x) + math.pi) / (2 * math.pi) * 72) % 72
            if r > ang.get(k, (0, 0, 0))[0]: ang[k] = (r, x, y)
        P = [(x, y) for r, x, y in ang.values()]
        def fit(P):
            import numpy as np
            A = np.array([[2 * x, 2 * y, 1] for x, y in P]); bb = np.array([x * x + y * y for x, y in P])
            s = np.linalg.lstsq(A, bb, rcond=None)[0]; return s[0], s[1], math.sqrt(s[2] + s[0] ** 2 + s[1] ** 2)
        cx, cy, rr = fit(P)
        for _ in range(3):
            P2 = [(x, y) for x, y in P if abs(math.hypot(x - cx, y - cy) - rr) < 0.008]
            if len(P2) < 12: break
            cx, cy, rr = fit(P2)
        logo = c + rt0 * cx + upp0 * cy
    eye = logo - axis * 0.5; dv = axis
    h = None
    loc, nrm, idx, dist = bvh.ray_cast(Mi @ eye, (Mi.to_3x3() @ dv).normalized())
    if loc is not None: h = (M @ loc, idx, (M.to_3x3() @ nrm).normalized())
    hs = cast(eye, dv)
    if h:
        hp, hn = h[0], h[2]
        if hn.dot(dv) > 0: hn = -hn
        if hs and (hs[0] - eye).length < (hp - eye).length - 0.002:
            hp = hs[0]
        ring = []
        right = Vector((1, 0, 0)); upp = hn.cross(right).normalized(); right = upp.cross(hn).normalized()
        for k in range(8):
            q = hp + (upp * math.cos(k * math.pi / 4) + right * math.sin(k * math.pi / 4)) * R * 1.35
            loc2, n2, i2, d2 = bvh.ray_cast(Mi @ (q + hn * 0.2), (Mi.to_3x3() @ -hn).normalized())
            if loc2 is not None: ring.append(colour_at(sw, M @ loc2, i2))
        ag = Vector(g(axis)); zg = -ag; xg = Vector((0, 1, 0)).cross(zg).normalized(); yg = zg.cross(xg)
        dd = Vector(g(hp - c)); nn = Vector(g(hn))
        dims = [abs(x) for x in g(b - a)]
        hub = {"local": [round(dd.dot(xg), 4), round(dd.dot(yg), 4), round(dd.dot(zg), 4)], "face": [round(nn.dot(xg), 4), round(nn.dot(yg), 4), round(nn.dot(zg), 4)], "r": R, "color": median(ring), "dims": [round(x, 4) for x in dims]}
wb = ((wc["FL"] + wc["FR"]) / 2 - (wc["RL"] + wc["RR"]) / 2).length
json.dump({"car": car, "wb": round(wb, 4), "mid": list(mid), "covers": covers, "groups": groups, "caps": caps, "hub": hub}, open(out, "w"), indent=1)
print("OK", car, len(covers), len(groups))
