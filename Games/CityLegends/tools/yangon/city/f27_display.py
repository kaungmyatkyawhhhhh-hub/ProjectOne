"""f27_display.py (2026-11-28): the retired Myanma Airways Fokker F27-600 Friendship (XY-ADZ) on display in People's
Park, Yangon (OSM node 3793702568, historic=aircraft). Real size (F27-600: length 23.56 m, span 29.0 m, height 8.5 m,
fuselage 2.7 m round), livery from the photo in vault `City Legends/refs_2026-11-28_aircraft/`: white top, navy cheatline
over the windows that widens into a navy rear fuselage and fin, orange chakra on the fin, orange MYANMA AIRWAYS, white
XY-ADZ, grey belly, grey wing / nacelles, black radome.
Run inside Blender (owner's Blender via the MCP: exec(open(<this file>).read())). Builds in metres, nose +X, span Y,
up Z, ground z = 0, then scales x3 (1 m = 3 studs) and writes imports/sync/aircraft/f27_xyadz.glb with vertex colours
(COLOR_0): 5 meshes Fuselage / Wing / Tail / Gear / Props."""
import bpy, bmesh, math, os
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "imports", "sync", "aircraft", "f27_xyadz.glb") \
    if "__file__" in globals() else r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/imports/sync/aircraft/f27_xyadz.glb"
S = 3.0  # studs per metre

C = dict(white=(236, 237, 234), navy=(22, 32, 86), belly=(168, 171, 176), wgrey=(150, 154, 160), black=(18, 19, 22),
         orange=(236, 140, 28), dorange=(200, 96, 18), tyre=(26, 26, 26), metal=(112, 114, 118), prop=(32, 32, 34),
         glass=(30, 40, 52), spin=(205, 207, 210))


def col(name):
    r, g, b = C[name]
    return (r / 255, g / 255, b / 255, 1.0)


def new_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


class B:
    """bmesh with a per-face colour stored in a dict, written as a CORNER byte colour attribute at the end"""
    def __init__(self):
        self.bm = bmesh.new()
        self.fc = {}

    def v(self, p):
        return self.bm.verts.new(Vector(p))

    def f(self, vs, c):
        fa = self.bm.faces.new(vs)
        self.fc[fa] = c
        return fa

    def finish(self, name):
        bm = self.bm
        bm.normal_update()
        lay = bm.loops.layers.color.new("Col")
        for fa, c in self.fc.items():
            for lp in fa.loops:
                lp[lay] = col(c)
        return new_obj(name, bm)


def loft(b, rings, colour_of, closed_ends=True):
    """rings: list of (list of 3D points, tag); faces between consecutive rings, colour_of(i, j) per quad"""
    vs = [[b.v(p) for p in r] for r, _ in rings]
    n = len(vs[0])
    for i in range(len(vs) - 1):
        for j in range(n):
            k = (j + 1) % n
            b.f([vs[i][j], vs[i][k], vs[i + 1][k], vs[i + 1][j]], colour_of(i, j))
    if closed_ends:
        b.f(list(reversed(vs[0])), colour_of(-1, 0))
        b.f(vs[-1], colour_of(len(vs), 0))
    return vs


# ---------------- fuselage ----------------
# stations: x, centre z, half height, half width (metres; the cabin is a 2.7 m tube, belly 1.1 m over the ground)
ST = [(0.0, 2.25, 0.10, 0.10), (0.3, 2.28, 0.55, 0.55), (0.8, 2.34, 0.92, 0.88), (1.6, 2.41, 1.18, 1.13),
      (2.6, 2.45, 1.32, 1.29), (3.8, 2.45, 1.35, 1.35), (9.0, 2.45, 1.35, 1.35), (14.0, 2.45, 1.35, 1.35),
      (16.0, 2.55, 1.29, 1.29), (18.0, 2.80, 1.05, 1.05), (20.0, 3.10, 0.76, 0.76), (22.0, 3.45, 0.42, 0.42),
      (23.56, 3.70, 0.10, 0.10)]
PHI = [-90, -65, -40, -20, 0, 12, 22, 30, 50, 70, 90]  # elevation angles; band edges get their own ring rows
ANG = [(p, 1) for p in PHI] + [(p, -1) for p in reversed(PHI[1:-1])]  # (phi, side) round the ring


def ring_pt(st, phi, side):
    x, zc, h, w = st
    a = math.radians(phi)
    return (x, side * w * math.cos(a), zc + h * math.sin(a))


def fus_colour(i, j):
    if i < 0:
        return "black"
    if i >= len(ST) - 1:
        return "navy"
    x0, x1 = ST[i][0], ST[i + 1][0]
    pa, pb = ANG[j][0], ANG[(j + 1) % len(ANG)][0]
    pm = (pa + pb) / 2
    xm = (x0 + x1) / 2
    if xm < 0.6:
        return "black"  # radome
    if 0.8 <= xm <= 1.6 and 12 <= pm <= 40:
        return "glass"  # cockpit glazing
    if xm > 15.0 and pm > 11:
        return "navy"  # navy rear fuselage up into the fin
    if 22 <= pm <= 30:
        return "navy"  # cheatline over the windows
    if pm < -40:
        return "belly"
    return "white"


b = B()
loft(b, [([ring_pt(st, p, s) for p, s in ANG], None) for st in ST], fus_colour)
fus = b.finish("Fuselage")

# cabin windows: dark ovals sitting 3 cm proud of the skin, both sides (F27-600: big oval windows)
b = B()
for side in (1, -1):
    for k in range(12):
        x = 4.3 + k * 0.92
        if 9.2 < x < 9.9:
            continue  # the door space under the wing root
        zc, w = 2.45, 1.35
        ph = math.radians(15)
        y0, z0 = side * (w * math.cos(ph) + 0.03), zc + 1.35 * math.sin(ph)
        ring = [b.v((x + 0.24 * math.cos(t * math.pi / 6), y0, z0 + 0.3 * math.sin(t * math.pi / 6))) for t in range(12)]
        b.f(ring if side > 0 else list(reversed(ring)), "glass")
    # rear passenger door outline (white door in a navy frame), left side only on the real aircraft: both here
    x0, z0 = 15.4, 1.75
win = b.finish("Windows")


# ---------------- wing + nacelles ----------------
def aerofoil(xle, chord, y, z, t):
    # LE, upper 25 %, upper 70 %, TE, lower 70 %, lower 25 %
    return [(xle, y, z), (xle + 0.25 * chord, y, z + t * 0.6), (xle + 0.7 * chord, y, z + t * 0.35), (xle + chord, y, z + 0.02),
            (xle + 0.7 * chord, y, z - t * 0.15), (xle + 0.25 * chord, y, z - t * 0.4)]


WS = []
for y in (-14.5, -10.0, -3.6, 0.0, 3.6, 10.0, 14.5):
    f = abs(y) / 14.5
    chord = 3.45 - (3.45 - 1.40) * f
    xle = 9.3 + 1.1 * f
    z = 3.85 + abs(y) * math.tan(math.radians(2.5))
    WS.append(aerofoil(xle, chord, y, z, 0.55 - 0.35 * f))
b = B()
loft(b, [(r, None) for r in WS], lambda i, j: "wgrey")
# nacelles (Rolls-Royce Dart), hanging under the wing at 3.6 m, running from the spinner to past the trailing edge
for side in (1, -1):
    yc = side * 3.6
    NS = [(6.85, 3.30, 0.30, 0.28), (7.2, 3.28, 0.55, 0.50), (8.5, 3.25, 0.68, 0.56), (11.5, 3.22, 0.66, 0.54),
          (13.3, 3.45, 0.40, 0.34), (14.2, 3.70, 0.12, 0.10)]
    rings = []
    for x, zc, h, w in NS:
        rings.append(([(x, yc + w * math.cos(t * math.pi / 6), zc + h * math.sin(t * math.pi / 6)) for t in range(12)], None))
    loft(b, rings, lambda i, j: "wgrey" if i >= 0 else "black")
wing = b.finish("Wing")

# ---------------- tail: fin, dorsal fillet, tailplanes, chakra, titles ----------------
b = B()


def fin_sec(xle, chord, z, t):
    return [(xle, 0, z), (xle + 0.2 * chord, t / 2, z), (xle + 0.8 * chord, t / 2, z), (xle + chord, 0, z),
            (xle + 0.8 * chord, -t / 2, z), (xle + 0.2 * chord, -t / 2, z)]


FIN = [fin_sec(16.6, 6.4, 3.55, 0.36), fin_sec(18.3, 4.6, 3.95, 0.36), fin_sec(19.3, 3.6, 5.0, 0.32),
       fin_sec(21.9, 1.75, 8.5, 0.16)]
loft(b, [(r, None) for r in FIN], lambda i, j: "navy")
TP = []
for y in (-4.85, 0.0, 4.85):
    f = abs(y) / 4.85
    TP.append(aerofoil(21.1 + 1.3 * f, 2.3 - 1.25 * f, y, 3.95 + 0.05 * f, 0.24 - 0.12 * f))
loft(b, [(r, None) for r in TP], lambda i, j: "wgrey")


def fin_half_t(z):
    return (0.32 + (0.16 - 0.32) * (z - 5.0) / 3.5) / 2


# the orange chakra (a petalled disc) on both sides of the fin
cx, cz, R = 21.75, 6.55, 0.82
for side in (1, -1):
    y = side * (fin_half_t(cz) + 0.05)
    out = [b.v((cx + (R if k % 2 == 0 else R * 0.86) * math.cos(k * math.pi / 16), y,
                cz + (R if k % 2 == 0 else R * 0.86) * math.sin(k * math.pi / 16))) for k in range(32)]
    b.f(out if side < 0 else list(reversed(out)), "orange")
    y2 = side * (fin_half_t(cz) + 0.08)
    inn = [b.v((cx + 0.34 * math.cos(k * math.pi / 8), y2, cz + 0.34 * math.sin(k * math.pi / 8))) for k in range(16)]
    b.f(inn if side < 0 else list(reversed(inn)), "dorange")
tail = b.finish("Tail")


def text_mesh(s, size, colour, loc, side, name):
    """flat text facing +Y (side 1) or -Y (side -1), reading nose-to-tail on the left side as on the photo"""
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = s
    cu.size = size
    cu.extrude = 0.01
    cu.align_x = "CENTER"
    ob = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(ob)
    # font lies in XY; stand it up in XZ, facing the side's outward normal
    ob.rotation_euler = (math.radians(90), 0, 0 if side < 0 else math.radians(180))
    ob.location = loc
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    me.transform(ob.matrix_world)
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    bm = bmesh.new()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)
    lay = bm.loops.layers.color.new("Col")
    for fa in bm.faces:
        for lp in fa.loops:
            lp[lay] = col(colour)
    return new_obj(name, bm)


texts = []
for side in (1, -1):
    # MYANMA AIRWAYS along the fin root (orange), XY-ADZ on the navy rear fuselage (white)
    texts.append(text_mesh("MYANMA AIRWAYS", 0.30, "orange", (20.7, side * (fin_half_t(4.9) + 0.07), 4.8), side, "TitleT"))
    texts.append(text_mesh("XY-ADZ", 0.42, "white", (17.3, side * 1.10, 3.15), side, "RegT"))
# hug the curved skin: shrinkwrap the registration onto the fuselage (4 cm proud)
for t in texts:
    if t.name.startswith("RegT"):
        m = t.modifiers.new("sw", "SHRINKWRAP")
        m.target = fus
        m.wrap_method = "NEAREST_SURFACEPOINT"
        m.offset = 0.04
        bpy.context.view_layer.objects.active = t
        bpy.ops.object.modifier_apply(modifier="sw")

# ---------------- gear ----------------
b = B()


def cyl(b, c, axis, r, half, n, colour):
    ax = Vector(axis).normalized()
    u = ax.orthogonal().normalized()
    v = ax.cross(u)
    cc = Vector(c)
    a = [b.v(cc - ax * half + (u * math.cos(k * 2 * math.pi / n) + v * math.sin(k * 2 * math.pi / n)) * r) for k in range(n)]
    z = [b.v(cc + ax * half + (u * math.cos(k * 2 * math.pi / n) + v * math.sin(k * 2 * math.pi / n)) * r) for k in range(n)]
    for k in range(n):
        b.f([a[k], a[(k + 1) % n], z[(k + 1) % n], z[k]], colour)
    b.f(list(reversed(a)), colour)
    b.f(z, colour)


for side in (1, -1):
    yc = side * 3.6
    cyl(b, (11.4, yc, 1.55), (0, 0, 1), 0.10, 1.05, 8, "metal")  # oleo leg from the nacelle
    for dy in (-0.32, 0.32):
        cyl(b, (11.4, yc + dy, 0.52), (0, 1, 0), 0.52, 0.17, 16, "tyre")  # twin main wheels (flat 2 cm into the ground)
    cyl(b, (11.4, yc, 0.52), (0, 1, 0), 0.06, 0.5, 8, "metal")
cyl(b, (2.6, 0, 0.75), (0, 0, 1), 0.08, 0.45, 8, "metal")  # nose leg up into the belly
for dy in (-0.2, 0.2):
    cyl(b, (2.6, dy, 0.36), (0, 1, 0), 0.38, 0.11, 14, "tyre")
gear = b.finish("Gear")

# ---------------- props + spinners ----------------
b = B()
for side in (1, -1):
    yc = side * 3.6
    # spinner: a cone from the nacelle front
    rr = [b.v((6.85, yc + 0.28 * math.cos(k * math.pi / 6), 3.30 + 0.28 * math.sin(k * math.pi / 6))) for k in range(12)]
    tip = b.v((6.05, yc, 3.30))
    for k in range(12):
        b.f([rr[(k + 1) % 12], rr[k], tip], "spin")
    for k in range(4):  # four blades, 3.5 m prop, parked at 45 deg
        a = math.radians(45 + 90 * k)
        d = Vector((0, math.cos(a), math.sin(a)))
        s = Vector((0.14, 0, 0))  # chord along x
        tw = Vector((0, -math.sin(a), math.cos(a))) * 0.04
        c0 = Vector((6.55, yc, 3.30)) + d * 0.2
        c1 = Vector((6.55, yc, 3.30)) + d * 1.75
        p = [b.v(c0 - s - tw), b.v(c0 + s - tw), b.v(c1 + s * 0.6 - tw), b.v(c1 - s * 0.6 - tw),
             b.v(c0 - s + tw), b.v(c0 + s + tw), b.v(c1 + s * 0.6 + tw), b.v(c1 - s * 0.6 + tw)]
        for q in ([0, 1, 2, 3], [7, 6, 5, 4], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]):
            b.f([p[i] for i in q], "prop")
props = b.finish("Props")


# ---------------- join, scale, fix normals, export ----------------
def join(target, others):
    bpy.ops.object.select_all(action="DESELECT")
    for o in others + [target]:
        o.select_set(True)
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.join()
    return target


regs = [t for t in texts if t.name.startswith("RegT")]
titles = [t for t in texts if t.name.startswith("TitleT")]
fus = join(fus, [win] + regs)
tail = join(tail, titles)
parts = [fus, wing, tail, gear, props]
for o in parts:
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    o.scale = (S, S, S)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(o.data)
    bm.free()
    o.data.color_attributes.active_color = o.data.color_attributes["Col"]

os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.object.select_all(action="DESELECT")
for o in parts:
    o.select_set(True)
for sc in bpy.data.scenes:  # objects selected in another scene would be exported too
    if sc != bpy.context.scene:
        for vl in sc.view_layers:
            for o in sc.objects:
                o.select_set(False, view_layer=vl)
for o in parts:
    o.data.name = o.name
# Blender 3.6's glTF exporter drops the colour attribute without a material using it, so write with the repo's glb.py
# (COLOR_0 per corner; positions per mesh relative to its box centre, x / z negated for Roblox's importer).
# Roblox frame: (x, y, z)_blender -> (x, z, -y), so nose = +X, up = +Y; the origin is the nose tip on the ground.
import sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(OUT.replace("imports" + os.sep + "sync" + os.sep + "aircraft", "tools/yangon/city"))))
sys.path.insert(0, r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city")
import importlib, glb
importlib.reload(glb)
named = []
for o in parts:
    me = o.data
    me.calc_loop_triangles()
    ca = me.color_attributes["Col"]
    m = glb.Mesh()
    for lt in me.loop_triangles:
        pts, cols = [], []
        for li in lt.loops:
            v = me.vertices[me.loops[li].vertex_index].co
            pts.append((v.x, v.z, -v.y))
            d = ca.data[li]
            cols.append(d.color_srgb if hasattr(d, "color_srgb") else d.color)
        c = cols[0]
        m.tri(pts[0], pts[1], pts[2], (0, 0), (0, 0), (0, 0), (c[0] * 255, c[1] * 255, c[2] * 255))
    named.append((o.name, m))
info = glb.write_glb(OUT, named, generator="f27_display.py")
json.dump(info, open(OUT.replace(".glb", ".json"), "w"), indent=1)
print("tris", {k: v["tris"] for k, v in info.items()}, OUT)
