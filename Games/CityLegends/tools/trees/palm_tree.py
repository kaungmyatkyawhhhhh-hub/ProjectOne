"""City Legends palms (2026-11-27): the old map's palms were a flat star card on a stick. Real-looking ones here.

"C:/Program Files/Blender Foundation/Blender 3.6/blender.exe" -b --factory-startup --python tools/trees/palm_tree.py -- [render]

One atlas (imports/trees/palm_atlas.png, tools/trees/palm_atlas.py) for all of them. Metres, z up, origin = trunk foot.
  CocoPalm    coconut palm ~12 m (old op1 / the FANPALM models): curved ringed trunk, 16 drooping pinnate fronds of
              V-folded leaflet cards, 2 dry hanging fronds, a coconut cluster
  CocoPalmT   a taller, straighter one ~16 m (old op2)
  ToddyPalm   toddy / palmyra (fan) palm ~19.5 m (RoadsideKit.ToddyPalm): straight dark trunk, a ball of fan leaves
Writes imports/trees/palms.fbx and imports/trees/palms.json (bounding boxes in studs, Roblox axes X, Y up, Z = -y).
"""
import json
import math
import os
import random
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
IMP = os.path.join(ROOT, "imports", "trees")
OUTR = os.path.join(ROOT, "build", "trees", "palms")
LAY = json.load(open(os.path.join(IMP, "palm_atlas.json")))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

from rain_tree import Geo, frame, bez, to_object, bbox_studs  # noqa: E402


def tube(g, pts, radii, sides, u_span, rect, along_u=True):
    """a bark tube; texture rect (u0, v0, u1, v1) with u ALONG the trunk (ring scars run across u) and v around"""
    rings = []
    prev_x = None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        x, y = frame(d)
        if prev_x is not None:
            x = (prev_x - d * prev_x.dot(d)).normalized()
            y = d.cross(x).normalized()
        prev_x = x
        rings.append([(g.add_v(p + (x * math.cos(a) + y * math.sin(a)) * radii[i]), (x * math.cos(a) + y * math.sin(a)))
                      for a in (2 * math.pi * k / sides for k in range(sides + 1))])
    # u along the trunk by real length (rings keep their spacing), v around
    acc = [0.0]
    for i in range(1, len(pts)):
        acc.append(acc[-1] + (pts[i] - pts[i - 1]).length)
    for i in range(len(pts) - 1):
        u0 = rect[0] + (rect[2] - rect[0]) * acc[i] / acc[-1] * u_span
        u1 = rect[0] + (rect[2] - rect[0]) * acc[i + 1] / acc[-1] * u_span
        for k in range(sides):
            v0 = rect[1] + (rect[3] - rect[1]) * k / sides
            v1 = rect[1] + (rect[3] - rect[1]) * (k + 1) / sides
            a, b = rings[i][k], rings[i][k + 1]
            c, d = rings[i + 1][k + 1], rings[i + 1][k]
            g.tri_or_quad([a[0], b[0], c[0], d[0]], [(u0, v0), (u0, v1), (u1, v1), (u1, v0)], [a[1], b[1], c[1], d[1]])


def env(t):   # same as palm_atlas.env: the card tapers with the leaflets
    return max(0.12, min(1.0, 0.25 + 2.6 * t)) * (1 - 0.82 * max(0, (t - 0.35) / 0.65) ** 1.3)


def rect_uv(r, u, v):
    """(u, v) 0..1 inside atlas rect r = (u0, v0, u1, v1)"""
    return (r[0] + (r[2] - r[0]) * u, r[1] + (r[3] - r[1]) * v)


def frond(g, base, az, elev, length, half_w, droop, sprite, crown_c, rng, segs=8):
    """a pinnate frond: rachis bends down as it goes (droop rad / m); each segment = a left and a right card,
    V-folded down from the rachis (leaflets hang), card width = env(t) like the sprite's leaflets"""
    r = LAY["frond"][sprite]
    dh = Vector((math.cos(az), math.sin(az), 0))
    pts, tans = [], []
    p = base.copy()
    ds = length / segs
    for i in range(segs + 1):
        e = elev - droop * (i * ds) * (1 + 0.6 * i / segs)
        tng = dh * math.cos(e) + Vector((0, 0, math.sin(e)))
        pts.append(p.copy())
        tans.append(tng)
        p = p + tng * ds
    roll = rng.uniform(-0.25, 0.25)
    prev = None
    for i in range(segs + 1):
        t = i / segs
        tng = tans[i]
        side = tng.cross(Vector((0, 0, 1))).normalized()
        up = side.cross(tng).normalized()
        fold = math.radians(16 + 20 * t)
        w = half_w * env(min(1.0, 0.04 + t * 0.96))
        row = []
        for s in (-1, 1):
            out = (side * s * math.cos(fold) - up * math.sin(fold)).normalized()
            out = (out + up * roll * s).normalized()
            row.append(pts[i] + out * w)
        u_half = 0.5 * env(min(1.0, 0.04 + t * 0.96))
        v = 0.005 + 0.99 * t
        cur = (pts[i], row, u_half, v)
        if prev:
            p0, r0, uh0, v0 = prev
            p1, r1, uh1, v1 = cur
            for k, s in enumerate((-1, 1)):
                ids = [g.add_v(p0), g.add_v(r0[k]), g.add_v(r1[k]), g.add_v(p1)]
                uvs = [rect_uv(r, 0.5, v0), rect_uv(r, 0.5 + s * uh0, v0), rect_uv(r, 0.5 + s * uh1, v1), rect_uv(r, 0.5, v1)]
                if s < 0:
                    ids, uvs = ids[::-1], uvs[::-1]
                # crown-shaped normals: lit as one head, not leaf by leaf
                ns = [(0.55 * (g.v[q] - crown_c).normalized() + Vector((0, 0, 0.6))).normalized() for q in ids]
                g.tri_or_quad(ids, uvs, ns)
        prev = cur


def ball(g, c, rad, uvr, segs=6, rings=4):
    """a low sphere (coconut) with its texture in rect uvr"""
    verts = []
    for j in range(rings + 1):
        th = math.pi * j / rings
        ring = []
        for k in range(segs + 1):
            ph = 2 * math.pi * k / segs
            n = Vector((math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th) * 1.15))
            ring.append((g.add_v(c + n * rad), n.normalized(), rect_uv(uvr, k / segs, 1 - j / rings)))
        verts.append(ring)
    for j in range(rings):
        for k in range(segs):
            a, b, cc, d = verts[j][k], verts[j][k + 1], verts[j + 1][k + 1], verts[j + 1][k]
            if j == 0:
                g.tri_or_quad([a[0], d[0], cc[0]], [a[2], d[2], cc[2]], [a[1], d[1], cc[1]])
            elif j == rings - 1:
                g.tri_or_quad([a[0], d[0], b[0]], [a[2], d[2], b[2]], [a[1], d[1], b[1]])
            else:
                g.tri_or_quad([a[0], d[0], cc[0], b[0]], [a[2], d[2], cc[2], b[2]], [a[1], d[1], cc[1], b[1]])


def coconut(seed, height, lean, n_fronds, frond_len):
    rng = random.Random(seed)
    g = Geo()
    # curved trunk: a gentle S, leaning `lean` m at the top; root flare
    top = Vector((lean, 0.15 * lean, height - 1.1))
    pts = bez(Vector((0, 0, 0)), Vector((lean * 0.1, 0, height * 0.55)), top, 12)
    pts = [Vector((0, 0, -0.15))] + pts
    radii = [0.34, 0.31] + [0.24 - 0.07 * (i / 11) for i in range(11)] + [0.19]
    radii = radii[:len(pts)]
    tube(g, pts, radii, 8, 1.0, tuple(LAY["bark_coco"][k] for k in (0, 1, 2, 3)), along_u=True)
    # crown shaft: fibrous leaf bases
    c0 = top
    tube(g, [c0, c0 + Vector((0.03, 0, 0.45)), c0 + Vector((0.05, 0, 0.9)), c0 + Vector((0.05, 0, 1.15))],
         [0.21, 0.3, 0.27, 0.12], 7, 1.0, tuple(LAY["fibre"]), along_u=True)
    crown_c = c0 + Vector((0.05, 0, 1.0))
    # fronds: upper ones rise then arch, lower ones droop hard; golden-angle azimuths
    for i in range(n_fronds):
        k = i / (n_fronds - 1)
        az = i * 2.39996 + rng.uniform(-0.2, 0.2)
        elev = math.radians(68 - 95 * k + rng.uniform(-8, 8))
        L = frond_len * rng.uniform(0.85, 1.05) * (0.8 if k < 0.12 else 1.0)
        droop = rng.uniform(0.16, 0.24) * (6.0 / frond_len)
        base = crown_c + Vector((math.cos(az) * 0.15, math.sin(az) * 0.15, 0.1 - 0.5 * k))
        sprite = 0 if (k < 0.55 and rng.random() < 0.75) else 1
        frond(g, base, az, elev, L, 1.15 * frond_len / 5.0, droop, sprite, crown_c, rng)
    # dry fronds hanging against the trunk
    for i in range(2):
        az = rng.uniform(0, 2 * math.pi)
        base = crown_c + Vector((math.cos(az) * 0.18, math.sin(az) * 0.18, -0.55))
        frond(g, base, az, math.radians(-55), frond_len * 0.75, 0.8 * frond_len / 5.0, 0.15, 2, crown_c, rng, segs=5)
    # coconuts under the fronds
    for i in range(9):
        az = i * 2.39996
        rr = 0.3 + 0.08 * (i % 2)
        c = crown_c + Vector((math.cos(az) * rr, math.sin(az) * rr, -0.45 - 0.14 * (i % 3)))
        ball(g, c, 0.14, LAY["husk"])
    return g


def toddy(seed, height):
    rng = random.Random(seed)
    g = Geo()
    zs = [-0.15, 0.0, 0.6, 3.0, 7.0, 10.0, 13.0, height - 2.2]
    rs = [0.42, 0.40, 0.33, 0.29, 0.31, 0.33, 0.29, 0.27]      # palmyra trunks swell a little in the middle
    tube(g, [Vector((0, 0, z)) for z in zs], rs, 8, 1.0, tuple(LAY["bark_toddy"]), along_u=True)
    c0 = Vector((0, 0, height - 2.2))
    tube(g, [c0, c0 + Vector((0, 0, 0.6)), c0 + Vector((0, 0, 1.1))], [0.3, 0.34, 0.15], 7, 1.0, tuple(LAY["fibre"]), along_u=True)
    crown_c = c0 + Vector((0, 0, 0.9))
    hub_v = LAY["fan_hub_v"]
    n = 40
    for i in range(n):
        k = (i + 0.5) / n
        az = i * 2.39996 + rng.uniform(-0.15, 0.15)
        # elevation: a ball of leaves, more of them up, a few drooping old ones (dry sprite)
        elev = math.radians(85 - 150 * k ** 0.85 + rng.uniform(-8, 8))
        dry = k > 0.88
        r = LAY["fan"][1 if dry else 0]
        size = rng.uniform(3.7, 4.4) * (0.9 if dry else 1.0)   # card height (petiole + blade), m
        d = Vector((math.cos(az) * math.cos(elev), math.sin(az) * math.cos(elev), math.sin(elev)))
        side = d.cross(Vector((0, 0, 1)))
        side = side.normalized() if side.length > 1e-3 else Vector((1, 0, 0))
        nrm = side.cross(d).normalized()
        # the blade turns to face up / out a little and is folded along its middle
        tilt = math.radians(rng.uniform(-25, 25))
        side = (side * math.cos(tilt) + nrm * math.sin(tilt)).normalized()
        nrm = side.cross(d).normalized()
        wdt = size * (256 / 384)
        base = crown_c + d * 0.15
        fold = math.radians(18)
        mid_b, mid_t = base, base + d * size
        for s in (-1, 1):
            o = (side * s * math.cos(fold) - nrm * math.sin(fold)) * (wdt / 2)
            ids = [g.add_v(mid_b), g.add_v(mid_b + o), g.add_v(mid_t + o), g.add_v(mid_t)]
            uvs = [rect_uv(r, 0.5, 0), rect_uv(r, 0.5 + s * 0.5, 0), rect_uv(r, 0.5 + s * 0.5, 1), rect_uv(r, 0.5, 1)]
            if s < 0:
                ids, uvs = ids[::-1], uvs[::-1]
            ns = [(0.6 * (g.v[q] - crown_c).normalized() + Vector((0, 0, 0.5))).normalized() for q in ids]
            g.tri_or_quad(ids, uvs, ns)
    _ = hub_v
    return g


def render(obs):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.eevee.use_soft_shadows = True
    sc.render.resolution_x, sc.render.resolution_y = 1400, 800
    sc.view_settings.view_transform = "Filmic"
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.45, 0.62, 0.85, 1)
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    sc.collection.objects.link(sun)
    bpy.ops.mesh.primitive_plane_add(size=300)
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = (0.18, 0.22, 0.1, 1)
    bpy.context.object.data.materials.append(gm)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    for i, ob in enumerate(obs):
        ob.location = (i * 14 - 14, 0, 0)
    shots = {"row": ((0, -42, 6.0), (0, 0, 9.0), 35), "street": ((-8, -14, 1.6), (-12, 0, 10.0), 22),
             "crown": ((-14, -9, 13.0), (-13, 0, 11.0), 30)}
    for name, (pos, at, lens) in shots.items():
        cam.location = Vector(pos)
        cam.data.lens = lens
        cam.rotation_euler = (Vector(at) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTR, "render_%s.png" % name)
        bpy.ops.render.render(write_still=True)


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    specs = {"CocoPalm": coconut(3, 12.2, 1.3, 18, 5.0), "CocoPalmT": coconut(8, 16.3, 0.7, 18, 5.4),
             "ToddyPalm": toddy(5, 19.5)}
    obs, info = [], {}
    for name, g in specs.items():
        ob = to_object(name, g, os.path.join(IMP, "palm_atlas.png"), True)
        obs.append(ob)
        info[name] = dict(tris=g.tris(), **bbox_studs(ob))
    print(json.dumps(info, indent=1))
    json.dump(info, open(os.path.join(IMP, "palms.json"), "w"), indent=1)
    for ob in bpy.data.objects:
        ob.select_set(ob in obs)
    bpy.ops.export_scene.fbx(filepath=os.path.join(IMP, "palms.fbx"), use_selection=True, object_types={"MESH"},
                             axis_forward="-Z", axis_up="Y", apply_unit_scale=True, mesh_smooth_type="OFF",
                             path_mode="AUTO", embed_textures=False, use_custom_props=False)
    if "render" in ARGS:
        os.makedirs(OUTR, exist_ok=True)
        render(obs)


main()
