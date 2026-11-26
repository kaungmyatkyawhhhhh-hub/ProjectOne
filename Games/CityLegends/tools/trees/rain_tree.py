"""City Legends rain tree (2026-11-27, owner: "Trees next" after the TorqX comparison).

"C:/Program Files/Blender Foundation/Blender 3.6/blender.exe" -b --factory-startup --python tools/trees/rain_tree.py -- [render]

A Yangon rain tree (Samanea saman): short trunk, 5 limbs that fork into an umbrella crown. The crown is ~16 lobes
of two-sided leaf-cluster cards (imports/trees/rain_atlas.png, tools/trees/leaf_atlas.py) with crown-shaped normals
(lit like a dome, not card by card). Light / mid / dark sprites by where a card sits: top light, underside dark.
Writes imports/trees/rain_tree.fbx with two objects (one material each, metres, origin = trunk foot):
  RainTree      near look (the streamer's ot1 template, the placed trees)        ~3k triangles
  RainTreeFar   far look: one lumpy opaque dome + trunk (rain_far.png)           ~250 triangles
and imports/trees/rain_tree.json (bounding boxes in studs, Roblox axes: X, Y up, Z = -Blender Y).
With "render": build/trees/render_*.png (front, 3/4, driver's view from below, near vs far).
"""
import json
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
IMP = os.path.join(ROOT, "imports", "trees")
OUTR = os.path.join(ROOT, "build", "trees")
ATL = json.load(open(os.path.join(IMP, "rain_atlas.json")))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RNG = random.Random(11)
# Roblox imports the leaf mesh with MeshPart.DoubleSided on, so the cards need no back faces
BACKFACES = "backfaces" in ARGS

BARK_V0, BARK_V1 = 0.012, 0.238       # bark rows of the atlas (v up; bottom quarter of the image)


# ------------------------------------------------------------------------------------------------ geometry store
class Geo:
    def __init__(self):
        self.v, self.f, self.uv, self.n = [], [], [], []     # uv / n per face corner

    def tri_or_quad(self, ids, uvs, nrm):
        self.f.append(ids)
        self.uv.append(uvs)
        self.n.append(nrm)

    def add_v(self, p):
        self.v.append(Vector(p))
        return len(self.v) - 1

    def tris(self):
        return sum(len(f) - 2 for f in self.f)


def frame(d):
    d = d.normalized()
    a = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
    x = d.cross(a).normalized()
    y = d.cross(x).normalized()
    return x, y


def tube(g, pts, radii, sides, u_span=1.0, v_span=(BARK_V0, BARK_V1)):
    """a bark tube through pts (list of Vectors) with radii; smooth normals; u around, v along (bark rows)"""
    rings = []
    prev_x = None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)])
        x, y = frame(d)
        if prev_x is not None:     # keep the ring from twisting
            x = (prev_x - d.normalized() * prev_x.dot(d.normalized())).normalized()
            y = d.normalized().cross(x).normalized()
        prev_x = x
        ring = []
        for k in range(sides + 1):
            a = 2 * math.pi * k / sides
            nrm = (x * math.cos(a) + y * math.sin(a))
            ring.append((g.add_v(p + nrm * radii[i]), nrm.copy()))
        rings.append(ring)
    L = len(pts) - 1
    for i in range(L):
        v0 = v_span[0] + (v_span[1] - v_span[0]) * i / L
        v1 = v_span[0] + (v_span[1] - v_span[0]) * (i + 1) / L
        for k in range(sides):
            u0, u1 = u_span * k / sides, u_span * (k + 1) / sides
            a, b = rings[i][k], rings[i][k + 1]
            c, d = rings[i + 1][k + 1], rings[i + 1][k]
            g.tri_or_quad([a[0], b[0], c[0], d[0]], [(u0, v0), (u1, v0), (u1, v1), (u0, v1)], [a[1], b[1], c[1], d[1]])


def bez(p0, p1, p2, n):
    return [p0 * (1 - t) ** 2 + p1 * 2 * t * (1 - t) + p2 * t * t for t in (i / n for i in range(n + 1))]


# ------------------------------------------------------------------------------------------------ the tree plan
def plan(seed=11):
    """skeleton: trunk, limbs, secondary branches, crown lobes (metres, z up, foot at 0)"""
    r = random.Random(seed)
    fork = Vector((0.15, -0.1, 3.0))
    limbs, lobes = [], []
    n = 5
    for i in range(n):
        az = 2 * math.pi * i / n + r.uniform(-0.25, 0.25)
        reach = r.uniform(4.6, 6.2)
        top = r.uniform(5.6, 6.6)
        d = Vector((math.cos(az), math.sin(az), 0))
        start = fork + d * 0.15 + Vector((0, 0, r.uniform(-0.4, 0.1)))
        end = Vector((d.x * reach, d.y * reach, top))
        mid = start.lerp(end, 0.45) + Vector((0, 0, 1.3))    # steep out of the fork, flatter at the end
        limbs.append((start, mid, end))
        lobes.append((end + Vector((0, 0, 0.6)), r.uniform(2.6, 3.2)))
        # two secondary branches off each limb, sideways and up, each ending in a lobe
        for side in (-1, 1):
            t = r.uniform(0.45, 0.65)
            p = bez(start, mid, end, 20)[int(t * 20)]
            az2 = az + side * r.uniform(0.55, 0.85)
            d2 = Vector((math.cos(az2), math.sin(az2), 0))
            e2 = p + d2 * r.uniform(2.2, 3.4) + Vector((0, 0, r.uniform(1.4, 2.3)))
            limbs.append((p, p.lerp(e2, 0.5) + Vector((0, 0, 0.35)), e2))
            lobes.append((e2 + Vector((0, 0, 0.8)), r.uniform(2.3, 2.9)))
    # a top lobe over the fork closes the dome
    lobes.append((Vector((0, 0, 9.2)), 3.4))
    return fork, limbs, lobes


ZSQ = 0.78     # lobes are flattened: rain tree crowns are umbrellas


def build_near(seed=11):
    fork, limbs, lobes = plan(seed)
    g = Geo()
    # trunk with a root flare
    pts = [Vector((0, 0, z)) for z in (0.0, 0.35, 1.1, 2.1, 3.0)]
    pts[-1] = fork
    tube(g, pts, [0.62, 0.46, 0.39, 0.36, 0.33], 9, 1.0)
    for i, (a, b, c) in enumerate(limbs):
        main = i % 3 == 0
        p = bez(a, b, c, 4 if main else 3)
        if main:
            rad = [0.25, 0.2, 0.15, 0.11, 0.07]
        else:
            rad = [0.11, 0.08, 0.06, 0.035]
        tube(g, p, rad, 6 if main else 5, 1.0 if main else 0.5)
    # leaf cards
    crown_c = Vector((0, 0, 6.2))
    rects = ATL["rects"]
    cw, ch = ATL["cell"]
    cards = 0
    for lc, lr in lobes:
        n = int(34 * (lr / 2.8) ** 2)
        for k in range(n):
            # Fibonacci-ish points over the lobe, a few pulled inside to fill it
            zz = 1 - 2 * (k + 0.5) / n
            az = k * 2.39996 + RNG.uniform(-0.3, 0.3)
            rr = math.sqrt(max(0, 1 - zz * zz))
            unit = Vector((rr * math.cos(az), rr * math.sin(az), zz))
            depth = 1.0 if RNG.random() > 0.18 else RNG.uniform(0.35, 0.7)
            p = lc + Vector((unit.x * lr, unit.y * lr, unit.z * lr * ZSQ)) * depth * RNG.uniform(0.85, 1.05)
            if p.z < 3.8:
                continue
            # card plane faces out of the lobe, tilted at random; size 2.0 - 2.9 m
            nrm = (unit + Vector((RNG.uniform(-0.25, 0.25), RNG.uniform(-0.25, 0.25), RNG.uniform(-0.15, 0.3)))).normalized()
            # never flatter than ~35-55 degrees: a flat card on the crown top is a hard streak seen from the street
            nrm.z = min(0.55, nrm.z)   # (underside cards stay flat: seen face-on from below)
            nrm.normalize()
            x, y = frame(nrm)
            spin = RNG.uniform(0, 2 * math.pi)
            x, y = x * math.cos(spin) + y * math.sin(spin), -x * math.sin(spin) + y * math.cos(spin)
            s = RNG.uniform(1.8, 2.6) * (0.85 if depth < 1 else 1.0)
            # tone: top of lobe and crown -> light, underside / inside -> dark
            up = 0.55 * unit.z + 0.45 * max(-1, min(1, (p.z - crown_c.z) / 2.6))
            tone = 0 if up > 0.28 else (2 if up < -0.22 or depth < 1 else 1)
            shape = RNG.randrange(2)
            x0, y0, x1, y1, _row = rects[shape]
            du = tone * cw
            u0, u1 = x0 + du, x1 + du
            v0, v1 = 1 - y1, 1 - y0           # image rows -> v up
            corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            ids, uvs, ns = [], [], []
            for cx, cy in corners:
                q = p + x * cx * s / 2 + y * cy * s / 2 * ((y1 - y0) / (x1 - x0))
                ids.append(g.add_v(q))
                uvs.append((u0 if cx < 0 else u1, v0 if cy < 0 else v1))
                # dome normal: lobe outward blended with the crown's
                dn = (0.6 * (q - lc).normalized() + 0.4 * (q - crown_c).normalized() + Vector((0, 0, 0.25))).normalized()
                ns.append(dn)
            g.tri_or_quad(ids, uvs, ns)
            if BACKFACES:
                g.tri_or_quad(ids[::-1], uvs[::-1], ns[::-1])  # back side, same dome normal
            cards += 1
    return g, cards, lobes, limbs


def build_far(lobes, limbs):
    """far look: the convex hull of the lobes (a lumpy umbrella, ~200 triangles), trunk and the 5 main limbs"""
    g = Geo()
    tube(g, [Vector((0, 0, 0)), Vector((0, 0, 1.6)), Vector((0.15, -0.1, 3.0))], [0.6, 0.4, 0.34], 6, 1.0, (0.02, 0.23))
    for a, b, c in limbs[::3]:
        tube(g, bez(a, b, c, 2), [0.24, 0.16, 0.1], 4, 1.0, (0.02, 0.23))
    pts = []
    for lc, lr in lobes:
        for k in range(14):
            zz = 1 - 2 * (k + 0.5) / 14
            az = k * 2.39996
            rr = math.sqrt(1 - zz * zz)
            pts.append(lc + Vector((rr * math.cos(az) * lr, rr * math.sin(az) * lr, zz * lr * ZSQ)) * 1.0)
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(bm, input=vs)
    for v in res["geom_interior"] + res["geom_unused"]:
        if isinstance(v, bmesh.types.BMVert) and v.is_valid:
            bm.verts.remove(v)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()
    zmin = min(v.co.z for v in bm.verts)
    zmax = max(v.co.z for v in bm.verts)
    c = sum((v.co for v in bm.verts), Vector()) / len(bm.verts)
    for f in bm.faces:
        ids, uvs, ns = [], [], []
        for v in f.verts:
            p = v.co.copy()
            ids.append(g.add_v(p))
            az = math.atan2(p.y, p.x)
            uvs.append((0.5 + az / (2 * math.pi), 0.25 + 0.74 * (p.z - zmin) / (zmax - zmin)))
            ns.append(((p - c) * Vector((1, 1, 1.8))).normalized())
        # keep the u seam from wrapping across a face
        us = [u for u, _ in uvs]
        if max(us) - min(us) > 0.5:
            uvs = [(u + 1 if u < 0.5 else u, v) for u, v in uvs]
        g.tri_or_quad(ids, uvs, ns)
    bm.free()
    return g


# ------------------------------------------------------------------------------------------------ blender objects
def to_object(name, g, image, alpha):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in g.v], [], g.f)
    uvl = me.uv_layers.new(name="UVMap")
    li = 0
    for poly in me.polygons:
        for k, l in enumerate(poly.loop_indices):
            uvl.data[l].uv = g.uv[poly.index][k]
    me.use_auto_smooth = True
    me.normals_split_custom_set([tuple(n) for f in g.n for n in f])
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mat = bpy.data.materials.new(name + "Mat")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(IMP, image), check_existing=True)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Specular"].default_value = 0.2
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        mat.blend_method = "CLIP"
        mat.shadow_method = "CLIP"
        mat.alpha_threshold = 0.5
        mat.use_backface_culling = False
    me.materials.append(mat)
    return ob


def bbox_studs(ob):
    """Roblox axes: X = x, Y = z, Z = -y; studs = metres x 3"""
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    mn = Vector((min(v.x for v in vs), min(v.z for v in vs), min(-v.y for v in vs))) * 3
    mx = Vector((max(v.x for v in vs), max(v.z for v in vs), max(-v.y for v in vs))) * 3
    return {"size": list(mx - mn), "centre": list((mx + mn) / 2), "min": list(mn), "max": list(mx)}


def render(obs, far):
    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE"
    except TypeError:
        pass
    sc.eevee.use_soft_shadows = True
    sc.eevee.shadow_cascade_size = "2048"
    sc.eevee.use_gtao = True
    sc.render.resolution_x, sc.render.resolution_y = 1200, 800
    sc.view_settings.view_transform = "Filmic"
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.45, 0.62, 0.85, 1)
    bg.inputs["Strength"].default_value = 0.9
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 4.0
    sun.data.angle = 0.05
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    sc.collection.objects.link(sun)
    bpy.ops.mesh.primitive_plane_add(size=200)
    ground = bpy.context.object
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = (0.18, 0.22, 0.1, 1)
    ground.data.materials.append(gm)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    near = obs[0]
    shots = {
        "front": ((0, -30, 2.0), (0, 0, 5.0), 50),
        "three_quarter": ((-20, -22, 8.0), (0, 0, 5.0), 50),
        "driver_below": ((3.0, -9.0, 1.2), (0, 0, 7.0), 24),
        "near_vs_far": ((14, -48, 3.0), (14, 0, 5.0), 50),
    }
    for name, (pos, at, lens) in shots.items():
        far.location = (28, 0, 0) if name == "near_vs_far" else (1000, 0, 0)
        cam.location = Vector(pos)
        cam.data.lens = lens
        d = Vector(at) - Vector(pos)
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(OUTR, "render_%s.png" % name)
        bpy.ops.render.render(write_still=True)


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    g, cards, lobes, limbs = build_near()
    near = to_object("RainTree", g, "rain_atlas.png", True)
    gf = build_far(lobes, limbs)
    far = to_object("RainTreeFar", gf, "rain_far.png", False)
    info = {"RainTree": dict(tris=g.tris(), cards=cards, **bbox_studs(near)),
            "RainTreeFar": dict(tris=gf.tris(), **bbox_studs(far))}
    print(json.dumps(info, indent=1))
    json.dump(info, open(os.path.join(IMP, "rain_tree.json"), "w"), indent=1)
    for ob in bpy.data.objects:
        ob.select_set(ob.name in ("RainTree", "RainTreeFar"))
    bpy.ops.export_scene.fbx(filepath=os.path.join(IMP, "rain_tree.fbx"), use_selection=True, object_types={"MESH"},
                             axis_forward="-Z", axis_up="Y", apply_unit_scale=True, mesh_smooth_type="OFF",
                             path_mode="AUTO", embed_textures=False, use_custom_props=False)
    if "render" in ARGS:
        os.makedirs(OUTR, exist_ok=True)
        render([near], far)


main()
