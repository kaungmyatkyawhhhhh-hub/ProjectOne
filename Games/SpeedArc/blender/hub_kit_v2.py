"""SPEED ARC - Hub kit v2, made to the "Modelling like a human artist" rule (SPEED ARC/CLAUDE.md).

Every prop: rounded bevelled edges (weighted normals keep flat faces flat), real cut-outs / insets
(booleans), natural variation (seeded jitter, sculpted organic shapes), and vertex-colour shading in
3 tones: base, lighter edge highlight on convex bevels, darker corners/gaps (curvature + baked AO).

Same sizes and pivots as v1: each prop is built in the same design coordinates as hub_kit.py and
then fitted exactly to v1's bounding box (hub_v1_bbox.json), so it drops into the same places.

Run headless:
    blender --background --factory-startup --python hub_kit_v2.py -- <output folder> [names...]
1 Blender unit = 1 Roblox stud. Blender X = Roblox X, Blender Y = Roblox Z, Blender Z = up.
"""
import json
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Euler, Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = ARGS[0] if ARGS else os.path.join(os.path.expanduser("~"), "Downloads", "speed_arc_models", "hub", "v2")
ONLY = set(ARGS[1:])
os.makedirs(OUT, exist_ok=True)
V1 = json.load(open(os.path.join(HERE, "hub_v1_bbox.json")))


# ---------------------------------------------------------------------------
# colours (palette, converted to linear for colour attributes)
# ---------------------------------------------------------------------------
def hex_rgb(h):
    h = h.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return Vector([c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb])


P = {k: hex_rgb(v) for k, v in {
    "black": "#0B0D12", "carbon": "#171A22", "graphite": "#2A2F3A", "steel": "#3A4150",
    "blue": "#1E7BFF", "bright": "#4FC3FF", "deep": "#0E3A8A",
    "gold": "#FFC83D", "deepgold": "#E09A12", "white": "#F4F6FA",
    "alu": "#C9D1DD", "alu_d": "#9AA4B4", "concrete": "#B8BFCB", "rubber": "#1B1E25",
    "wood": "#B9824F", "wood_d": "#9C6A3C", "wood_l": "#CB9560",
    "leaf": "#4E9A47", "leaf_l": "#79C25C", "leaf_d": "#2F6B33", "pine": "#2E6B3E", "pine_l": "#4F9A55",
    "trunk": "#7A5236", "trunk_d": "#5A3A25",
    "cone": "#FF7A1F", "lamp": "#FFE3A0", "screen": "#4FC3FF",
    "skin1": "#F2CDA8", "skin2": "#C68B62", "skin3": "#8D5A3B",
    "hair1": "#2B1D14", "hair2": "#5A3A22", "hair3": "#E2B763", "shorts": "#1F2C4A",
}.items()}


def lerp(a, b, t):
    return a + (b - a) * t


# ---------------------------------------------------------------------------
# scene helpers
# ---------------------------------------------------------------------------
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 96
    scene.cycles.device = "CPU"
    world = bpy.data.worlds.new("World")
    scene.world = world


def active():
    return bpy.context.view_layer.objects.active


def select_only(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def paint(o, color, fn=None):
    """Fill colour attribute "Col": flat colour, or fn(world_position) -> colour."""
    me = o.data
    attr = me.color_attributes.get("Col") or me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    me.color_attributes.active_color = attr
    mw = o.matrix_world
    for poly in me.polygons:
        for li in poly.loop_indices:
            c = color
            if fn:
                c = fn(mw @ me.vertices[me.loops[li].vertex_index].co)
            attr.data[li].color = (c[0], c[1], c[2], 1.0)
    return o


def bevel(o, width, segments=3, angle=35, harden=True):
    m = o.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.harden_normals = harden
    m.use_clamp_overlap = True
    m.profile = 0.55
    return o


def weighted(o):
    o.data.shade_smooth()
    m = o.modifiers.new("WN", "WEIGHTED_NORMAL")
    m.keep_sharp = True
    m.mode = "FACE_AREA"
    return o


def finish(o):
    """Apply modifiers and transforms so the piece is plain geometry in design space."""
    select_only(o)
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def cut(target, *cutters, op="DIFFERENCE"):
    """Real cut-outs: boolean the cutters out of target (before bevelling)."""
    for c in cutters:
        m = target.modifiers.new("Cut", "BOOLEAN")
        m.operation = op
        m.object = c
        m.solver = "EXACT"
        select_only(target)
        bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.data.objects.remove(c, do_unlink=True)
    return target


def box(name, size, loc, color, bev=0.06, seg=2, rot=(0, 0, 0), cutters=(), angle=35):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = active()
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if cutters:
        cut(o, *[c() for c in cutters])
    if bev:
        bevel(o, min(bev, 0.45 * min(size)), seg, angle)
        weighted(o)
    return paint(o, color)


def cutter_box(size, loc, rot=(0, 0, 0)):
    def make():
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
        o = active()
        o.scale = size
        bpy.ops.object.transform_apply(scale=True)
        return o
    return make


def cutter_cyl(r, h, loc, rot=(0, 0, 0), verts=16):
    def make():
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
        return active()
    return make


def cutter_prism(points2d, depth, axis="x", offset=0.0):
    """Triangular / polygonal prism cutter: points in the plane across `axis`."""
    def make():
        bm = bmesh.new()
        a, b = [], []
        for (u, v) in points2d:
            if axis == "x":
                a.append(bm.verts.new((offset - depth / 2, u, v)))
                b.append(bm.verts.new((offset + depth / 2, u, v)))
            else:
                a.append(bm.verts.new((u, offset - depth / 2, v)))
                b.append(bm.verts.new((u, offset + depth / 2, v)))
        bm.faces.new(a)
        bm.faces.new(list(reversed(b)))
        n = len(points2d)
        for i in range(n):
            bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return to_object("cutter", bm)
    return make


def prism(name, pts_xz, depth, y, color):
    """A flat plate with any outline in the XZ plane, `depth` thick around y."""
    bm = bmesh.new()
    a = [bm.verts.new((x, y - depth / 2, z)) for x, z in pts_xz]
    b = [bm.verts.new((x, y + depth / 2, z)) for x, z in pts_xz]
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    n = len(a)
    for i in range(n):
        bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return paint(to_object(name, bm), color)


def cyl(name, r, h, loc, color, verts=12, bev=0.04, seg=2, rot=(0, 0, 0), r2=None, cutters=()):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=h, location=loc, rotation=rot)
    o = active()
    o.name = name
    if cutters:
        cut(o, *[c() for c in cutters])
    if bev:
        bevel(o, bev, seg, 40)
        weighted(o)
    else:
        o.data.shade_smooth()
    return paint(o, color)


def to_object(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    select_only(o)
    return o


def tube(name, pts, radii, color, sides=8, caps=True, smooth=True, jitter=0.0, seed=0):
    """A pipe along points (curved arms, rails, trunks). radii: one value or one per point."""
    rnd = random.Random(seed)
    bm = bmesh.new()
    rings = []
    pts = [Vector(p) for p in pts]
    prev_a = None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        if prev_a is None:
            ref = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
            a = d.cross(ref).normalized()
        else:  # carry the previous ring's frame along the curve so the tube never twists
            a = prev_a - d * prev_a.dot(d)
            a = a.normalized() if a.length > 1e-6 else d.cross(Vector((1, 0, 0))).normalized()
        prev_a = a
        b = d.cross(a).normalized()
        r = radii[i] if isinstance(radii, (list, tuple)) else radii
        ring = []
        for k in range(sides):
            t = 2 * math.pi * k / sides
            rr = r * (1 + rnd.uniform(-jitter, jitter))
            ring.append(bm.verts.new(p + (a * math.cos(t) + b * math.sin(t)) * rr))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(sides):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % sides], rings[i + 1][(k + 1) % sides], rings[i + 1][k]))
    if caps:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = to_object(name, bm)
    if smooth:
        o.data.shade_smooth()
    return paint(o, color)


def rounded_slab(name, w, d, h, r, z0, color, seg=4, center=(0, 0)):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, d / 2 - r, 0), (-w / 2 + r, d / 2 - r, 90), (-w / 2 + r, -d / 2 + r, 180), (w / 2 - r, -d / 2 + r, 270)):
        for s in range(seg + 1):
            a = math.radians(a0 + 90 * s / seg)
            pts.append((center[0] + cx + r * math.cos(a), center[1] + cy + r * math.sin(a)))
    bm = bmesh.new()
    bot = [bm.verts.new((x, y, z0)) for x, y in pts]
    top = [bm.verts.new((x, y, z0 + h)) for x, y in pts]
    bm.faces.new(list(reversed(bot)))
    bm.faces.new(top)
    n = len(pts)
    for i in range(n):
        bm.faces.new((bot[i], bot[(i + 1) % n], top[(i + 1) % n], top[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = to_object(name, bm)
    bevel(o, min(0.04, h * 0.3), 2, 30)
    weighted(o)
    return paint(o, color)


def blob(name, center, radius, bottom, top, seed, subdiv=2, rough=0.16, flatten=0.45, scale=(1, 1, 1), freq=1.7):
    """Sculpted organic shape (tree crowns): a displaced ico sphere with a flattened underside."""
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=1, location=(0, 0, 0))
    o = active()
    o.name = name
    off = Vector((seed * 13.1, seed * 7.7, seed * 3.3))
    c = Vector(center)
    for v in o.data.vertices:
        n = v.co.normalized()
        d = 1 + rough * noise.fractal(n * freq + off, 0.7, 2.0, 3)
        p = n * d
        p = Vector((p.x * scale[0], p.y * scale[1], p.z * scale[2]))
        if p.z < -flatten:
            p.z = -flatten + (p.z + flatten) * 0.3
        v.co = p * radius + c
    o.data.shade_smooth()
    z0, z1 = c.z - radius * flatten, c.z + radius * scale[2]

    def grad(co):
        t = max(0.0, min(1.0, (co.z - z0) / max(0.01, z1 - z0)))
        patch = 0.5 + 0.5 * noise.noise(co * 0.9 + off)
        return lerp(bottom, top, t * 0.8 + patch * 0.2)
    return paint(o, None, grad)


def join(objs, name):
    for o in objs:
        finish(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = active()
    o.name = name
    return o


# ---------------------------------------------------------------------------
# fit to v1 + shading + export
# ---------------------------------------------------------------------------
def fit(o, name, design_min, design_max):
    """Map the design bounding box onto the target design box, then centre like v1 (origin at the
    bottom centre). design_min/max: where v1's box sat in design coordinates (keeps reference points)."""
    me = o.data
    cmin = [min(v.co[i] for v in me.vertices) for i in range(3)]
    cmax = [max(v.co[i] for v in me.vertices) for i in range(3)]
    tsize = [V1[name]["max"][i] - V1[name]["min"][i] for i in range(3)]
    tmin = list(design_min)
    tmax = [tmin[i] + tsize[i] for i in range(3)] if design_max is None else list(design_max)
    scales = []
    for v in me.vertices:
        co = v.co.copy()
        for i in range(3):
            a = (tmax[i] - tmin[i]) / max(1e-6, cmax[i] - cmin[i])
            co[i] = tmin[i] + (co[i] - cmin[i]) * a
        v.co = co
    for i in range(3):
        scales.append((tmax[i] - tmin[i]) / max(1e-6, cmax[i] - cmin[i]))
    # centre: origin at bottom centre of the box, like v1
    cx, cy = (tmin[0] + tmax[0]) / 2, (tmin[1] + tmax[1]) / 2
    for v in me.vertices:
        v.co = Vector((v.co.x - cx, v.co.y - cy, v.co.z - tmin[2]))
    me.update()
    flag = "" if all(0.93 < s < 1.07 for s in scales) else "  <-- check proportions"
    print(f"[fit] {name}: scale x{scales[0]:.3f} y{scales[1]:.3f} z{scales[2]:.3f}{flag}")


def shade(o, highlight=0.32, cavity=0.4, ao=0.6, ao_dist=1.0, wear=0.05, seed=0):
    """3-tone vertex shading: convex bevels lighter, concave corners darker, baked AO in gaps,
    plus a soft low-frequency wear tone so no surface is perfectly flat-coloured."""
    me = o.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()
    curv = [0.0] * len(bm.verts)
    for v in bm.verts:
        s, n = 0.0, 0
        for e in v.link_edges:
            d = v.co - e.other_vert(v).co
            if d.length > 1e-6:
                s += v.normal.dot(d.normalized())
                n += 1
        curv[v.index] = s / n if n else 0.0
    bm.free()

    col = me.color_attributes["Col"]
    base = [Vector(d.color[:3]) for d in col.data]

    # bake AO into a temporary attribute
    aoattr = me.color_attributes.new("AO", "FLOAT_COLOR", "CORNER")
    me.color_attributes.active_color = aoattr
    mat = bpy.data.materials.new(o.name + "_bake")
    mat.use_nodes = True
    me.materials.clear()
    me.materials.append(mat)
    scene = bpy.context.scene
    scene.world.light_settings.distance = ao_dist
    scene.render.bake.target = "VERTEX_COLORS"
    select_only(o)
    bpy.ops.object.bake(type="AO", target="VERTEX_COLORS")
    off = Vector((seed * 3.7, seed * 1.3, seed * 5.1))
    for li, d in enumerate(col.data):
        vi = me.loops[li].vertex_index
        c = base[li]
        k = curv[vi] * 3.0
        if k > 0:
            c = lerp(c, Vector((1, 1, 1)), highlight * min(1.0, k) * 0.6) + c * (highlight * min(1.0, k) * 0.5)
        else:
            c = c * (1 - cavity * min(1.0, -k))
        a = aoattr.data[li].color[0]
        c = c * (1 - ao + ao * a)
        pos = me.vertices[vi].co
        c = c * (1 + wear * noise.noise(pos * 0.7 + off))
        d.color = (min(c[0], 1), min(c[1], 1), min(c[2], 1), 1.0)
    me.color_attributes.remove(me.color_attributes["AO"])
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = me.color_attributes.active_color_index
    me.materials.clear()


def export(o, name):
    select_only(o)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", mesh_smooth_type="OFF",
        use_mesh_modifiers=True, colors_type="SRGB", add_leaf_bones=False,
    )
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, name + ".blend"))
    tris = sum(len(p.vertices) - 2 for p in o.data.polygons)
    print(f"[kit] {name}.fbx  {tris} tris")
    return tris


# ---------------------------------------------------------------------------
# props (design coordinates = hub_kit.py: Z up, +Y front)
# ---------------------------------------------------------------------------
def bench(rnd):
    parts = []
    # cast-iron side frames: front leg, rear leg that rises into the back support, seat rail, armrest
    for x in (-2.62, 2.62):
        parts.append(box("legF", (0.26, 0.3, 1.5), (x, -0.62, 0.75), P["black"], bev=0.07, rot=(math.radians(-4), 0, 0)))
        parts.append(tube("back", [(x, 0.55, 0.0), (x, 0.6, 1.4), (x, 0.72, 2.3), (x, 0.86, 3.1)], [0.15, 0.14, 0.13, 0.12], P["black"], sides=6))
        parts.append(box("rail", (0.24, 1.55, 0.2), (x, -0.02, 1.45), P["black"], bev=0.05, seg=1))
        parts.append(tube("arm", [(x, -0.75, 2.05), (x, -0.4, 2.2), (x, 0.3, 2.25), (x, 0.66, 2.2)], 0.08, P["black"], sides=6))
        parts.append(box("foot", (0.34, 0.44, 0.08), (x, -0.62, 0.04), P["rubber"], bev=0))
        parts.append(box("foot", (0.34, 0.44, 0.08), (x, 0.55, 0.04), P["rubber"], bev=0))
    # seat: 4 slats with gaps, each a slightly different wood tone and a hair out of line
    tones = [P["wood"], P["wood_l"], P["wood_d"], P["wood"]]
    for i in range(4):
        y = -0.66 + i * 0.4
        parts.append(box("slat", (6.0, 0.34, 0.15), (rnd.uniform(-0.02, 0.02), y, 1.63 + rnd.uniform(-0.01, 0.01)), tones[i],
                         bev=0.045, rot=(0, math.radians(rnd.uniform(-0.3, 0.3)), math.radians(rnd.uniform(-0.25, 0.25)))))
    # back: 3 slats following the back support
    for i, (y, z) in enumerate(((0.68, 2.05), (0.76, 2.5), (0.84, 2.95))):
        parts.append(box("backslat", (6.0, 0.13, 0.32), (rnd.uniform(-0.02, 0.02), y, z), tones[(i + 1) % 4], bev=0.045,
                         rot=(math.radians(-10 + rnd.uniform(-0.4, 0.4)), 0, 0)))
    # centre support under the seat
    parts.append(box("brace", (0.2, 1.3, 0.14), (0, -0.05, 1.47), P["black"], bev=0.04))
    o = join(parts, "Bench")
    fit(o, "Bench", (-3, -0.85, 0), (3, 0.93, 3.2))
    shade(o, ao_dist=0.6, seed=1)
    return o


def bleacher_section(rnd):
    parts = []
    rows, depth, width = 6, 3.0, 20.0
    for k in range(1, rows + 1):
        h = 1 + 1.3 * k
        y = -1.5 - depth * (k - 1)
        tone = (P["graphite"] if k % 2 == 0 else P["carbon"]) * (1 + rnd.uniform(-0.04, 0.04))
        # riser, set back a little under a bull-nose cap that overhangs it (a real shadow groove)
        parts.append(box(f"step{k}", (width, depth - 0.12, h - 0.3), (0, y - 0.06, (h - 0.3) / 2), tone, bev=0.06, seg=1))
        parts.append(box(f"nose{k}", (width, depth, 0.3), (0, y, h - 0.15), tone * 1.15, bev=0.1, seg=2))
        # rounded aluminium plank with a blue lip under its front edge, on two brackets
        parts.append(box(f"seat{k}", (width - 0.6, 1.3, 0.42), (0, y + 0.6, h + 0.27), P["alu"], bev=0.13, seg=2))
        parts.append(box(f"lip{k}", (width - 0.8, 0.12, 0.2), (0, y + 1.2, h + 0.12), P["blue"], bev=0.03, seg=1))
        for bx in (-6.5, 6.5):
            parts.append(box("bracket", (0.22, 0.8, 0.08), (bx + rnd.uniform(-0.1, 0.1), y + 0.55, h + 0.03), P["steel"], bev=0))
    # front rail: posts + top rail + mid rail, rounded tubes
    for x in (-9.7, -3.2, 3.2, 9.7):
        parts.append(tube("post", [(x, 0.6, 0), (x, 0.6, 3.15)], 0.13, P["alu"], sides=6))
        parts.append(cyl("postfoot", 0.24, 0.12, (x, 0.6, 0.06), P["steel"], verts=6, bev=0))
    parts.append(tube("toprail", [(-10, 0.6, 3.2), (10, 0.6, 3.2)], 0.15, P["alu"], sides=8))
    parts.append(tube("midrail", [(-10, 0.6, 1.8), (10, 0.6, 1.8)], 0.09, P["alu_d"], sides=6))
    o = join(parts, "Bleacher_Section")
    fit(o, "Bleacher_Section", (-10, -18, 0), (10, 0.75, 9.3))
    shade(o, ao_dist=1.6, cavity=0.45, seed=2)
    return o


def cone(rnd):
    parts = [rounded_slab("base", 1.76, 1.76, 0.16, 0.3, 0, P["rubber"])]
    # recessed ring in the base where the cone sits
    parts.append(cyl("seat", 0.72, 0.06, (0, 0, 0.19), P["graphite"], verts=14, bev=0))
    body = cyl("body", 0.64, 1.56, (0, 0, 0.98), P["cone"], verts=14, r2=0.14, bev=0.03, seg=1,
               cutters=[cutter_cyl(0.085, 0.5, (0, 0, 1.76), verts=12)])  # hollow top
    parts.append(body)
    # two reflective bands, sitting just proud of the cone
    for z0, z1 in ((0.72, 0.92), (1.12, 1.27)):
        r0 = lerp(0.64, 0.14, (z0 - 0.2) / 1.56) + 0.015
        r1 = lerp(0.64, 0.14, (z1 - 0.2) / 1.56) + 0.015
        parts.append(cyl("band", r0, z1 - z0, (0, 0, (z0 + z1) / 2), P["white"], verts=14, r2=r1, bev=0))
    parts.append(cyl("lip", 0.17, 0.05, (0, 0, 1.765), P["cone"] * 0.8, verts=12, bev=0,
                     cutters=[cutter_cyl(0.09, 0.3, (0, 0, 1.765), verts=12)]))
    o = join(parts, "Cone")
    fit(o, "Cone", (-0.89, -0.89, 0), (0.89, 0.89, 1.8))
    shade(o, ao_dist=0.35, ao=0.45, seed=3)
    return o


FAN_LOOKS = {
    "Crowd_Fan_A": dict(shirt="blue", skin="skin1", hair="hair1", pose="cheer", box=((-0.85, -0.68, 0), (0.85, 0.68, 3.43))),
    "Crowd_Fan_B": dict(shirt="gold", skin="skin2", hair="hair2", pose="flag", box=((-0.85, -0.68, 0), (1.95, 0.68, 3.7))),
    "Crowd_Fan_C": dict(shirt="white", skin="skin3", hair="hair1", pose="wave", box=((-0.85, -0.68, 0), (0.85, 0.68, 3.42))),
}


def crowd_fan(name, rnd):
    look = FAN_LOOKS[name]
    shirt, skin, hair = P[look["shirt"]], P[look["skin"]], P[look["hair"]]
    trim = P["white"] if look["shirt"] != "white" else P["blue"]
    parts = []
    # seated hips/shorts, a soft rounded torso (wider at the shoulders), a collar trim
    parts.append(box("hips", (1.4, 0.95, 0.5), (0, 0, 0.25), P["shorts"], bev=0.16, seg=1))
    torso = box("torso", (1.42, 0.9, 1.55), (0, 0, 1.25), shirt, bev=0.3, seg=2, angle=30)
    for v in torso.data.vertices:  # shoulders a little wider than the waist
        t = max(0.0, min(1.0, (v.co.z + 0.775) / 1.55))
        v.co.x *= 0.92 + 0.12 * t
    parts.append(torso)
    parts.append(cyl("collar", 0.36, 0.1, (0, 0, 2.03), trim, verts=8, bev=0))
    parts.append(cyl("neck", 0.2, 0.25, (0, 0, 2.12), skin, verts=6, bev=0))
    # head + a hair shell with a clean hairline (cut with booleans), so it isn't a ball on a box
    hc = Vector((0, 0, 2.74))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=7, radius=0.62, location=hc)
    head = active()
    head.scale = (1.0, 1.0, 1.06)
    bpy.ops.object.transform_apply(scale=True)
    head.data.shade_smooth()
    parts.append(paint(head, skin))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=7, radius=0.665, location=hc + Vector((0, -0.03, 0.03)))
    cap = active()
    cap.scale = (1.0, 1.0, 1.04)
    bpy.ops.object.transform_apply(scale=True)
    cut(cap, cutter_box((2, 1.2, 0.9), hc + Vector((0, 0.5, -0.2)), rot=(math.radians(-28), 0, 0))(),  # the face, hairline sloping back
        cutter_box((2, 2, 1), hc + Vector((0, 0, -0.52)))())  # side hair ends above the ears
    cap.data.shade_smooth()
    parts.append(paint(cap, hair))
    # arms (rounded tubes): pose per fan
    sh = 0.66
    down = [(0.6, 0.0, 1.92), (0.76, 0.06, 1.4), (0.64, 0.34, 0.98)]  # resting on the knees

    def side(pts, sx):
        return [(x * sx, y, z) for x, y, z in pts]
    if look["pose"] == "cheer":
        for sx in (-1, 1):
            parts.append(tube("arm", side(down, sx), [0.18, 0.16, 0.15], shirt, sides=6))
            parts.append(cyl("hand", 0.14, 0.18, (0.62 * sx, 0.4, 0.92), skin, verts=6, bev=0))
    elif look["pose"] == "wave":
        parts.append(tube("armL", [(-0.6, 0.0, 1.92), (-0.8, 0.05, 2.45), (-0.72, 0.08, 2.95)], [0.18, 0.16, 0.15], shirt, sides=6))
        parts.append(cyl("handL", 0.15, 0.24, (-0.72, 0.08, 3.12), skin, verts=6, bev=0))
        parts.append(tube("armR", side(down, 1), [0.18, 0.16, 0.15], shirt, sides=6))
    else:  # flag: right arm up holding a waving team flag
        parts.append(tube("armL", side(down, -1), [0.18, 0.16, 0.15], shirt, sides=6))
        parts.append(tube("armR", [(0.6, 0.0, 1.92), (0.98, 0.0, 2.45), (1.18, 0.0, 2.95)], [0.18, 0.16, 0.15], shirt, sides=6))
        parts.append(tube("pole", [(1.2, 0.0, 2.6), (1.22, 0.0, 3.7)], 0.04, P["alu"], sides=5))
        bm = bmesh.new()  # cloth: a subdivided strip with a soft wave
        cols, rows_ = 4, 1
        verts = [[bm.verts.new((1.24 + 0.71 * i / cols, 0.07 * math.sin(i * 1.3), 3.1 + 0.55 * j / rows_ - 0.04 * i / cols)) for j in range(rows_ + 1)] for i in range(cols + 1)]
        for i in range(cols):
            for j in range(rows_):
                bm.faces.new((verts[i][j], verts[i + 1][j], verts[i + 1][j + 1], verts[i][j + 1]))
        flag = to_object("flag", bm)
        sol = flag.modifiers.new("Solid", "SOLIDIFY")
        sol.thickness = 0.05
        flag.data.shade_smooth()
        parts.append(paint(flag, P["blue"]))
        parts.append(cyl("hand", 0.15, 0.24, (1.2, 0.0, 3.05), skin, verts=6, bev=0))
    o = join(parts, name)
    fit(o, name, look["box"][0], look["box"][1])
    shade(o, ao_dist=0.5, highlight=0.25, seed=4)
    return o


def lamp_post(rnd):
    parts = [
        cyl("plinth", 0.6, 0.42, (0, 0, 0.21), P["graphite"], verts=8, bev=0.05),
        cyl("plinth2", 0.44, 0.32, (0, 0, 0.58), P["black"], verts=8, bev=0.05),
        cyl("pole", 0.25, 7.9, (0, 0, 4.68), P["black"], verts=12, r2=0.17, bev=0.02, seg=1),
        cyl("collar", 0.31, 0.14, (0, 0, 1.25), P["steel"], verts=12, bev=0.03, seg=1),
        cyl("collar2", 0.24, 0.12, (0, 0, 8.45), P["steel"], verts=12, bev=0.03, seg=1),
    ]
    # curved arm reaching out to -Y
    arc = [(0, 0.0, 8.5), (0, -0.25, 8.95), (0, -0.7, 9.08), (0, -1.2, 9.05), (0, -1.6, 8.98)]
    parts.append(tube("arm", arc, [0.12, 0.11, 0.1, 0.1, 0.1], P["black"], sides=8))
    # head with a recessed glow panel underneath (cut-out)
    head = box("head", (1.08, 1.52, 0.46), (0, -1.65, 8.71), P["black"], bev=0.14, seg=3,
               cutters=[cutter_box((0.88, 1.3, 0.16), (0, -1.65, 8.48))])
    parts.append(head)
    parts.append(box("glow", (0.86, 1.28, 0.05), (0, -1.65, 8.54), P["lamp"], bev=0))
    parts.append(cyl("cap", 0.32, 0.14, (0, -1.65, 9.0), P["steel"], verts=10, bev=0.04))
    o = join(parts, "Lamp_Post")
    fit(o, "Lamp_Post", (-0.6, -2.38, 0), (0.6, 0.6, 9.15))
    shade(o, ao_dist=0.6, seed=5)
    return o


def start_arch(rnd):
    parts = []
    for lx in (-15.0, 15.0):
        parts.append(box("foot", (4, 4, 1), (lx, 0, 0.5), P["graphite"], bev=0.16, seg=1,
                         cutters=[cutter_box((3.0, 4.2, 0.12), (lx, 0, 0.62)), cutter_box((4.2, 3.0, 0.12), (lx, 0, 0.62))]))
        parts.append(box("cap", (2.7, 2.7, 0.3), (lx, 0, 1.12), P["black"], bev=0.06))
        # open truss tower: 4 corner posts, rungs and zig-zag braces (real holes you can see through)
        c = 1.02
        corners = [(lx - c, -c), (lx + c, -c), (lx + c, c), (lx - c, c)]
        for (x, y) in corners:
            parts.append(tube("post", [(x, y, 1.2), (x, y, 17.6)], 0.17, P["black"], sides=6))
        levels = [1.3 + i * 2.72 for i in range(7)]
        for zi, z in enumerate(levels):
            for i in range(4):
                a, b = corners[i], corners[(i + 1) % 4]
                parts.append(tube("rung", [(a[0], a[1], z), (b[0], b[1], z)], 0.09, P["steel"], sides=4, caps=False, smooth=False))
                if zi < len(levels) - 1:
                    z2 = levels[zi + 1]
                    if zi % 2 == 0:
                        parts.append(tube("brace", [(a[0], a[1], z), (b[0], b[1], z2)], 0.08, P["steel"], sides=4, caps=False, smooth=False))
                    else:
                        parts.append(tube("brace", [(b[0], b[1], z), (a[0], a[1], z2)], 0.08, P["steel"], sides=4, caps=False, smooth=False))
        # solid collars where the glowing bands go
        for z in (6, 12):
            parts.append(box("collar", (2.5, 2.5, 0.6), (lx, 0, z), P["carbon"], bev=0.08, seg=1))
        # triangular gusset plates where the beam meets the tower, each with a round lightening hole
        s = -1 if lx > 0 else 1  # towards the middle of the arch
        xin = lx + s * 1.2
        for gy in (-1.02, 1.02):
            g = prism("gusset", [(xin, 17.55), (xin, 15.0), (xin + s * 2.5, 17.55)], 0.22, gy, P["black"])
            cut(g, cutter_cyl(0.36, 1.0, (xin + s * 0.8, gy, 16.7), rot=(math.radians(90), 0, 0))())
            bevel(g, 0.04, 1, 30)
            weighted(g)
            parts.append(paint(g, P["black"]))
    # beam: rounded, with panel grooves along both faces and chamfered ends
    groove = []
    for yy in (-1.5, 1.5):
        for zz in (17.95, 21.05):
            groove.append(cutter_box((32, 0.12, 0.1), (0, yy, zz)))
    parts.append(box("beam", (32.6, 3.0, 4.0), (0, 0, 19.5), P["black"], bev=0.16, seg=3, cutters=groove))
    parts.append(box("goldcap", (34.0, 3.3, 0.7), (0, 0, 21.85), P["gold"], bev=0.14, seg=3,
                     cutters=[cutter_box((34.5, 0.1, 0.08), (0, 1.66, 21.85)), cutter_box((34.5, 0.1, 0.08), (0, -1.66, 21.85))]))
    for ex in (-16.6, 16.6):
        parts.append(box("endcap", (0.5, 3.2, 4.3), (ex, 0, 19.55), P["carbon"], bev=0.12))
    o = join(parts, "Start_Arch")
    fit(o, "Start_Arch", (-17, -2, 0), (17, 2, 22.2))
    shade(o, ao_dist=1.2, highlight=0.4, seed=6)
    return o


def starting_block(rnd):
    teeth = [cutter_box((0.4, 0.1, 0.09), (0, -0.8 + i * 0.4, 0.2)) for i in range(5)]
    parts = [box("rail", (0.3, 2.2, 0.2), (0, 0, 0.1), P["alu"], bev=0.04, seg=1, cutters=teeth)]
    for y in (-1.0, 1.0):
        parts.append(box("crossbar", (1.6, 0.18, 0.1), (0, y, 0.05), P["steel"], bev=0.03, seg=1))
    for (px, py) in ((-0.48, -0.42), (0.48, 0.48)):
        grooves = [cutter_box((0.9, 0.06, 0.06), (px, py + 0.01, 0.42 + i * 0.16), rot=(math.radians(-35), 0, 0)) for i in range(2)]
        parts.append(box("pad", (0.72, 0.18, 0.7), (px, py + 0.05, 0.5), P["rubber"], bev=0.05, rot=(math.radians(-35), 0, 0), cutters=grooves))
        for sx in (-0.39, 0.39):
            parts.append(box("cheek", (0.06, 0.55, 0.55), (px + sx, py, 0.36), P["alu"], bev=0.02, seg=1))
        parts.append(box("clamp", (0.28, 0.36, 0.12), (px * 0.45, py, 0.22), P["steel"], bev=0.03, seg=1))
    o = join(parts, "Starting_Block")
    fit(o, "Starting_Block", (-0.95, -1.1, 0), (0.95, 1.1, 0.85))
    shade(o, ao_dist=0.25, seed=7)
    return o


def treadmill(rnd):
    parts = []
    # deck with a recessed belt (pocket cut in), foot rails either side, rubber feet
    deck = box("deck", (3.6, 7.0, 0.87), (0, 0, 0.435), P["graphite"], bev=0.12, seg=3,
               cutters=[cutter_box((2.72, 6.2, 0.2), (0, 0.15, 0.87))])
    parts.append(deck)
    parts.append(box("belt", (2.68, 6.16, 0.08), (0, 0.15, 0.79), P["rubber"], bev=0.02, seg=1))
    for x in (-1.12, 1.12):
        parts.append(box("beltstripe", (0.18, 6.1, 0.02), (x, 0.15, 0.835), P["blue"], bev=0))
    for x in (-1.55, 1.55):
        parts.append(box("footrail", (0.36, 6.4, 0.07), (x, 0.2, 0.9), P["alu"], bev=0.03, seg=2))
    for (x, y) in ((-1.55, -3.2), (1.55, -3.2), (-1.55, 3.2), (1.55, 3.2)):
        parts.append(cyl("foot", 0.18, 0.06, (x, y, 0.03), P["rubber"], verts=6, bev=0))
    parts.append(cyl("roller", 0.2, 3.0, (0, 3.3, 0.66), P["steel"], verts=8, rot=(0, math.radians(90), 0), bev=0))
    # motor hood over the front of the belt, with a gold accent groove
    parts.append(box("hood", (3.4, 1.0, 0.5), (0, -3.05, 1.08), P["carbon"], bev=0.22, seg=3,
                     cutters=[cutter_box((3.6, 0.08, 0.06), (0, -2.55, 1.15))]))
    parts.append(box("hoodstripe", (3.3, 0.05, 0.05), (0, -2.56, 1.15), P["gold"], bev=0))
    # uprights + handrails: curved tubes
    for x in (-1.5, 1.5):
        parts.append(tube("upright", [(x, -2.95, 1.0), (x * 1.02, -3.12, 2.6), (x, -3.25, 4.2)], 0.13, P["alu"], sides=8))
        parts.append(tube("handrail", [(x, -3.2, 4.12), (x, -2.4, 4.1), (x, -1.4, 4.02), (x, -1.15, 3.85)], 0.1, P["alu"], sides=8))
        parts.append(box("grip", (0.26, 0.7, 0.26), (x, -2.2, 4.1), P["rubber"], bev=0.1, seg=1))
    # console: rounded, with a recessed screen and three buttons on the ledge
    console = box("console", (3.3, 0.6, 1.25), (0, -3.3, 4.62), P["carbon"], bev=0.18, seg=3,
                  cutters=[cutter_box((2.2, 0.2, 0.74), (0, -3.0, 4.75))])
    parts.append(console)
    parts.append(box("screen", (2.18, 0.04, 0.72), (0, -3.07, 4.75), P["screen"], bev=0))
    parts.append(box("ledge", (2.6, 0.32, 0.1), (0, -2.92, 4.18), P["graphite"], bev=0.04, seg=2))
    for i, c in enumerate(("gold", "blue", "bright")):
        parts.append(cyl("button", 0.07, 0.06, (-0.4 + i * 0.4, -2.88, 4.25), P[c], verts=6, bev=0))
    o = join(parts, "Treadmill")
    fit(o, "Treadmill", (-1.8, -3.63, 0), (1.8, 3.5, 5.3))
    shade(o, ao_dist=0.7, seed=8)
    return o


def tree_round(name, seed):
    rnd = random.Random(seed)
    parts = []
    # trunk: a bent, tapering tube with a flared base; two branches up into the crown
    lean = Vector((rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.25), 0))
    path = [Vector((0, 0, 0)) + lean * (z / 7.5) ** 2 + Vector((0, 0, z)) for z in (0, 0.35, 1.5, 3.2, 5.0, 6.6, 7.6)]
    radii = [1.0, 0.8, 0.62, 0.55, 0.5, 0.44, 0.38]
    parts.append(tube("trunk", path, radii, P["trunk"], sides=9, jitter=0.06, seed=seed))
    for sx in (1, -1):
        tip = path[4] + Vector((sx * 1.6, rnd.uniform(-0.6, 0.6), 2.2))
        parts.append(tube("branch", [path[4], (path[4] + tip) / 2 + Vector((0, 0, 0.2)), tip], [0.3, 0.22, 0.14], P["trunk"], sides=6))
    # crown: a lumpy sculpted main mass with smaller clumps breaking up the outline (no plain balls)
    m = 1 if seed % 2 else -1
    parts.append(blob("crown", (0, 0, 8.9), 3.5, P["leaf_d"], P["leaf_l"], seed * 10, subdiv=2, rough=0.3, freq=2.1, scale=(1.1, 1.12, 0.9)))
    clumps = [((2.3 * m, 0.6, 10.2), 2.0), ((-2.2 * m, -0.9, 8.4), 1.9), ((0.4, 2.3, 9.6), 1.7), ((-0.6, -2.1, 10.6), 1.8), ((0.2, 0.2, 11.4), 1.6)]
    for i, (c, r) in enumerate(clumps):
        c = Vector(c) + Vector((rnd.uniform(-0.2, 0.2), rnd.uniform(-0.2, 0.2), rnd.uniform(-0.2, 0.2)))
        parts.append(blob(f"clump{i}", c, r * rnd.uniform(0.92, 1.08), P["leaf"], P["leaf_l"], seed * 10 + i + 1, subdiv=1, rough=0.25, freq=2.4))
    o = join(parts, name)
    v = V1[name]
    hx, hy = (v["max"][0] - v["min"][0]) / 2, (v["max"][1] - v["min"][1]) / 2
    fit(o, name, (-hx, -hy, 0), (hx, hy, v["max"][2] - v["min"][2]))
    shade(o, ao_dist=2.0, highlight=0.2, cavity=0.22, ao=0.4, wear=0.08, seed=seed)
    return o


def tree_pine(seed):
    rnd = random.Random(seed)
    parts = [tube("trunk", [(0, 0, 0), (0.05, 0, 1.5), (0.1, 0.05, 3.4)], [0.62, 0.45, 0.32], P["trunk"], sides=8, jitter=0.06, seed=seed)]
    tiers = [(3.5, 1.4, 4.6), (2.75, 3.6, 6.4), (2.0, 5.6, 8.2), (1.2, 7.5, 9.9)]
    for ti, (r, z0, z1) in enumerate(tiers):
        bm = bmesh.new()
        n = 14
        rot = rnd.uniform(0, math.pi)
        tilt = Vector((rnd.uniform(-0.12, 0.12), rnd.uniform(-0.12, 0.12), 0))
        apex = bm.verts.new(Vector((0, 0, z1)) + tilt)
        rim, inner = [], []
        for k in range(n):
            a = rot + 2 * math.pi * k / n
            tip = 1.0 if k % 2 == 0 else 0.78  # alternate long/short branch tips
            rr = r * tip * rnd.uniform(0.94, 1.04)
            droop = -0.35 if k % 2 == 0 else -0.05
            rim.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, z0 + droop)))
            inner.append(bm.verts.new((math.cos(a) * rr * 0.45, math.sin(a) * rr * 0.45, z0 + 0.35)))
        hub = bm.verts.new((0, 0, z0 + 0.45))
        for k in range(n):
            bm.faces.new((rim[k], rim[(k + 1) % n], apex))
            bm.faces.new((rim[(k + 1) % n], rim[k], inner[k], inner[(k + 1) % n]))
            bm.faces.new((inner[(k + 1) % n], inner[k], hub))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        o = to_object(f"tier{ti}", bm)
        o.data.shade_smooth()
        top_z = z1

        def grad(co, z0=z0, top_z=top_z, r=r):
            t = max(0.0, min(1.0, (co.z - z0 + 0.4) / (top_z - z0 + 0.4)))
            outer = min(1.0, math.hypot(co.x, co.y) / r)
            return lerp(P["pine"], P["pine_l"] * 1.1, 0.2 + 0.5 * outer + 0.3 * t)
        parts.append(paint(o, None, grad))
    o = join(parts, "Tree_Pine")
    v = V1["Tree_Pine"]
    hx = (v["max"][0] - v["min"][0]) / 2
    fit(o, "Tree_Pine", (-hx, -hx, 0), (hx, hx, v["max"][2] - v["min"][2]))
    shade(o, ao_dist=1.5, highlight=0.15, cavity=0.2, ao=0.35, wear=0.08, seed=seed)
    return o


BUILD = [
    ("Tree_Round_A", lambda r: tree_round("Tree_Round_A", 11)),
    ("Tree_Round_B", lambda r: tree_round("Tree_Round_B", 24)),
    ("Tree_Pine", lambda r: tree_pine(37)),
    ("Bleacher_Section", bleacher_section),
    ("Crowd_Fan_A", lambda r: crowd_fan("Crowd_Fan_A", r)),
    ("Crowd_Fan_B", lambda r: crowd_fan("Crowd_Fan_B", r)),
    ("Crowd_Fan_C", lambda r: crowd_fan("Crowd_Fan_C", r)),
    ("Start_Arch", start_arch),
    ("Treadmill", treadmill),
    ("Bench", bench),
    ("Cone", cone),
    ("Lamp_Post", lamp_post),
    ("Starting_Block", starting_block),
]

if __name__ == "__main__":
    report = []
    for name, fn in BUILD:
        if ONLY and name not in ONLY:
            continue
        reset()
        obj = fn(random.Random(sum(map(ord, name))))
        tris = export(obj, name)
        report.append(f"{name}: {tris} tris")
    print("[kit] done ->", OUT)
    print("\n".join(report))
