"""Live needles for a converted car's own dials (CarSkin.DIAL_NEEDLES), from readings in texture pixels.

    python tools/dial_fit.py -- spec.json [--write]

Find the dial texture first with tools/dial_probe.py (a render pixel -> texture pixel), read the hub,
labels and the painted needle off the texture, then run this. --write paints the old needle out of
the texture (and deletes modelled needles: "delete_objects" / "delete_uv_box") in the .blend.
Kind "digits" (with "w", width in px) is a live speed read-out over a fixed one.

spec json: {"car", "blend", "image", "hint": [x,y,z] (a probe point on the dials, picks among reused UVs),
  "dials": [{"kind": "speed"|"rpm", "unit": "kmh"|"mph"|"rpm", "c": [x, y] hub (tex px),
             "pts": [[value, [x, y]], ...] label or tick positions (tex px, any radius),
             "end": [[value, angle_tex_deg], ...] optional extra scale points in texture degrees,
             "len": needle length (tex px), "paint": [[x0, y0], [x1, y1], width] painted needle to remove (optional)}]}
Prints the DIAL_NEEDLES entries (car metres from the steering wheel part's box centre: right, up, back)
and writes the texture with painted needles removed (inpainted) into the blend (--write)."""
import bpy, sys, json, math
import numpy as np
from mathutils import Vector
spec = json.load(open(sys.argv[sys.argv.index("--") + 1]))
write = "--write" in sys.argv
bpy.ops.wm.open_mainfile(filepath=spec["blend"])
img = bpy.data.images[spec["image"]]
W, H = img.size
UV, CO = [], []
for o in bpy.data.objects:
    if o.type != "MESH": continue
    me = o.data
    use = set()
    for i, m in enumerate(me.materials):
        if m and m.node_tree and any(n.type == "TEX_IMAGE" and n.image == img for n in m.node_tree.nodes):
            use.add(i)
    if not use: continue
    me.calc_loop_triangles()
    uvl = me.uv_layers.active.data
    M = o.matrix_world
    for lt in me.loop_triangles:
        if lt.material_index in use:
            UV.append([tuple(uvl[l].uv) for l in lt.loops])
            CO.append([tuple(M @ me.vertices[v].co) for v in lt.vertices])
UV = np.array(UV); CO = np.array(CO)
UV = UV - np.floor(UV.mean(axis=1, keepdims=True))  # each triangle into the 0..1 tile
hint = np.array(spec["hint"])
cent = CO.mean(axis=1)

def to3d(px, py):
    p = np.array([px / W, 1 - py / H])
    a, b, c = UV[:, 0], UV[:, 1], UV[:, 2]
    v0, v1, v2 = b - a, c - a, p - a
    d00 = (v0 * v0).sum(1); d01 = (v0 * v1).sum(1); d11 = (v1 * v1).sum(1)
    d20 = (v2 * v0).sum(1); d21 = (v2 * v1).sum(1)
    den = d00 * d11 - d01 * d01
    ok = np.abs(den) > 1e-14
    v = np.where(ok, (d11 * d20 - d01 * d21) / np.where(ok, den, 1), -1)
    w = np.where(ok, (d00 * d21 - d01 * d20) / np.where(ok, den, 1), -1)
    u = 1 - v - w
    inside = ok & (u >= -1e-4) & (v >= -1e-4) & (w >= -1e-4)
    idx = np.nonzero(inside)[0]
    if not len(idx): return None
    k = idx[np.argmin(np.linalg.norm(cent[idx] - hint, axis=1))]
    return u[k] * CO[k, 0] + v[k] * CO[k, 1] + w[k] * CO[k, 2]

sw = next(o for o in bpy.data.objects if o.name.startswith("SteeringWheel"))
Msw = np.array(sw.matrix_world)
sv = np.array([Msw[:3, :3] @ np.array(x.co) + Msw[:3, 3] for x in sw.data.vertices])
swc = (sv.min(0) + sv.max(0)) / 2
def game(d):  # blender (x left, y back, z up) -> car right, up, back
    return [round(-d[0], 4), round(d[2], 4), round(d[1], 4)]

entries = []
mask_lines = []
for dl in spec["dials"]:
    cx, cy = dl["c"]
    C = to3d(cx, cy)
    for s in (12.0, 6.0, 3.0, 1.5):
        U3 = to3d(cx, cy - s); R3 = to3d(cx + s, cy)
        if U3 is not None and R3 is not None:
            break
    if C is None or U3 is None or R3 is None:
        print("MISS", dl); continue
    up_t, right_t = (U3 - C) / s, (R3 - C) / s  # 3D per texture px along texture up / right
    n = np.cross(right_t, up_t)
    n /= np.linalg.norm(n)
    # face towards the driver (+y back in blender, a little up)
    if n[1] < 0: n = -n
    u = np.array([0, 0, 1.0]) - n[2] * n; u /= np.linalg.norm(u)
    r = np.cross(u, n)
    def ang_of_tex(theta):
        t = math.radians(theta)
        d = math.cos(t) * up_t + math.sin(t) * right_t
        return math.degrees(math.atan2(d @ r, d @ u))
    if dl["kind"] == "digits":
        # a live speed read-out: its middle, width (tex px) and the way it faces
        e = {"kind": "digits", "unit": dl["unit"], "at": game(C - swc), "face": game(n), "length": round(float(np.linalg.norm(right_t)) * dl["w"], 4), "scale": ""}
        entries.append(e)
        print("DIAL", json.dumps(e))
        if "paint" in dl:
            mask_lines.append(dl["paint"])
        continue
    pts = []
    for val, deg in dl.get("scale3d", []):  # straight in the driver's view: degrees clockwise from 12
        pts.append((val, deg))
    for val, (x, y) in dl.get("pts", []):
        theta = math.degrees(math.atan2(x - cx, -(y - cy)))
        pts.append((val, ang_of_tex(theta)))
    for val, theta in dl.get("end", []):
        pts.append((val, ang_of_tex(theta)))
    pts.sort()
    # keep the sweep continuous: clockwise (increasing), or counter-clockwise ("ccw": Aston rev
    # counters)
    ccw = dl.get("ccw", False)
    out = [pts[0]]
    for val, a in pts[1:]:
        if ccw:
            while a > out[-1][1] + 5: a -= 360
        else:
            while a < out[-1][1] - 5: a += 360
        out.append((val, a))
    scale = ",".join("%g:%.1f" % (v, a) for v, a in out)
    length = float(np.linalg.norm(up_t)) * dl["len"]
    e = {"kind": dl["kind"], "unit": dl["unit"], "at": game(C - swc), "face": game(n), "length": round(length, 4), "scale": scale}
    entries.append(e)
    print("DIAL", json.dumps(e))
    if "paint" in dl:
        mask_lines.append(dl["paint"])

print("ENTRY", spec["car"], json.dumps(entries))
if write and spec.get("delete_objects"):
    for name in spec["delete_objects"]:
        o = bpy.data.objects.get(name)
        if o:
            bpy.data.objects.remove(o, do_unlink=True)
            print("DELETED object", name)
    bpy.ops.wm.save_mainfile()
if write and spec.get("delete_uv_box"):
    # needle pieces modelled on top of the dials: faces textured from the needle's picture, near a dial
    import bmesh
    x0, y0, x1, y1 = spec["delete_uv_box"]
    centres = [np.array(to3d(*dl["c"])) for dl in spec["dials"]]
    gone = 0
    for o in bpy.data.objects:
        if o.type != "MESH": continue
        me = o.data
        use = {i for i, m in enumerate(me.materials) if m and m.node_tree and any(n.type == "TEX_IMAGE" and n.image == img for n in m.node_tree.nodes)}
        if not use: continue
        bm = bmesh.new(); bm.from_mesh(me)
        uvl = bm.loops.layers.uv.active
        M = np.array(o.matrix_world)
        kill = []
        for f in bm.faces:
            if f.material_index not in use: continue
            uv = np.mean([l[uvl].uv for l in f.loops], axis=0)
            uv = uv - np.floor(uv)
            px_, py_ = uv[0] * W, (1 - uv[1]) * H
            if not (x0 <= px_ <= x1 and y0 <= py_ <= y1): continue
            c = M[:3, :3] @ np.array(f.calc_center_median()) + M[:3, 3]
            if min(np.linalg.norm(c - cc) for cc in centres) < spec.get("delete_near", 0.12):
                kill.append(f)
        if kill:
            bmesh.ops.delete(bm, geom=kill, context="FACES")
            bm.to_mesh(me); gone += len(kill)
        bm.free()
    bpy.ops.wm.save_mainfile()
    print("DELETED needle faces", gone)
if write and mask_lines:
    from scipy import ndimage
    px = np.array(img.pixels[:]).reshape(H, W, 4)[::-1].copy()  # top row first
    a = px[..., :3]
    yy, xx = np.mgrid[0:H, 0:W]
    mask = np.zeros((H, W), bool)
    for (x0, y0), (x1, y1), wd in mask_lines:
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy
        t = np.clip(((xx + 0.5 - x0) * dx + (yy + 0.5 - y0) * dy) / L2, 0, 1)
        dist = np.hypot(xx + 0.5 - (x0 + t * dx), yy + 0.5 - (y0 + t * dy))
        mask |= dist <= wd / 2
    known = ~mask
    res = a.copy()
    while not known.all():
        k = known.astype(float)
        cnt = ndimage.convolve(k, np.ones((3, 3)), mode="constant")
        front = (~known) & (cnt > 0)
        if not front.any(): break
        for ch in range(3):
            sm = ndimage.convolve(res[..., ch] * k, np.ones((3, 3)), mode="constant")
            res[..., ch][front] = sm[front] / cnt[front]
        known |= front
    px[..., :3] = res
    img.pixels[:] = px[::-1].ravel()
    img.update(); img.pack()
    bpy.ops.wm.save_mainfile()
    # a look at the result
    img.filepath_raw = spec.get("preview", spec["blend"] + ".dials.png"); img.file_format = "PNG"; img.save()
    print("PAINTED", int(mask.sum()))
