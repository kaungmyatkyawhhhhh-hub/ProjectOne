"""
Turns build/riviera/hairpin.json (tools/map_plan/hairpin.py) into real curved meshes for one Import 3D
(2026-11-04): smooth ribbons with points every 1.5 studs, so the kerbs and pavements have no saw teeth.
Each piece is its own object, named HP_*, in world studs round the bend's middle:
  HP_Road, HP_Lines, HP_Pavement, HP_KerbStone, HP_KerbRed (red-and-white strip on the bend's outside and
  round the island), HP_Island (the planter's soil top), HP_Wall (the curved retaining wall)

The bounding box of each piece goes to build/riviera/hairpin_parts.json: Studio's Import 3D may change
the scale and centres each mesh, so these numbers put every piece back exactly.

run:  blender.exe -b --factory-startup --python tools/hairpin_fbx.py -- <repo folder Games/CityLegends>
"""
import json
import math
import os
import sys

import bpy

ROOT = sys.argv[sys.argv.index("--") + 1]
d = json.load(open(os.path.join(ROOT, "build", "riviera", "hairpin.json")))
S = d["s"]
CX, CZ = d["centre"]
Y0 = sum(q[1] for q in S) / len(S)
WALK, KERB = d["walk"], d["kerb"]
UP = 0.5  # kerb and pavement over the road
n = len(S)


def to_b(x, y, z):
    """world studs -> Blender (round the bend's middle; Z up)"""
    return (x - CX, -(z - CZ), y - Y0)


def side(i, off):
    """world point `off` studs right of sample i's centre line"""
    q = S[i]
    return (q[0] - q[4] * off, q[2] + q[3] * off)


arc = [0.0]
for i in range(1, n):
    arc.append(arc[-1] + math.dist((S[i][0], S[i][2]), (S[i - 1][0], S[i - 1][2])))


class Mesh:
    def __init__(self):
        self.v, self.f, self.uv = [], [], []

    def quad_strip(self, a, b, ua, ub):
        """a, b: lists of world points (x, y, z); ua, ub: their uv"""
        base = len(self.v)
        m = len(a)
        self.v += a + b
        self.uv += ua + ub
        for k in range(m - 1):
            self.f.append((base + k, base + k + 1, base + m + k + 1, base + m + k))


def ribbon(mesh, i0, i1, off_a, off_b, up_a, up_b, u_scale=8.0):
    """a strip beside the centre line: off = studs right of it (a number, or a function of the sample)"""
    a, b, ua, ub = [], [], [], []
    for i in range(i0, i1):
        oa = off_a(i) if callable(off_a) else off_a
        ob = off_b(i) if callable(off_b) else off_b
        pa, pb = side(i, oa), side(i, ob)
        y = S[i][1]
        a.append((pa[0], y + up_a, pa[1]))
        b.append((pb[0], y + up_b, pb[1]))
        ua.append((arc[i] / u_scale, 0.0))
        ub.append((arc[i] / u_scale, 1.0))
    mesh.quad_strip(a, b, ua, ub)


# which side the bend's inside is: the island lies left or right of the road
midi = n // 2
mx, mz = S[midi][0], S[midi][2]
left = side(midi, -10)
in_sign = -1 if math.dist(left, (CX, CZ)) < math.dist((mx, mz), (CX, CZ)) else 1  # +1: inside is on the right
half = lambda i: S[i][5]  # noqa: E731
out_edge = lambda i: -in_sign * half(i)  # noqa: E731
in_edge = lambda i: in_sign * half(i)  # noqa: E731


def near_island(i):
    return math.dist((S[i][0], S[i][2]), (CX, CZ)) < d["R"] + 6 and S[i][0] < 10925


meshes = {}
road = meshes.setdefault("HP_Road", Mesh())
ribbon(road, 0, n, lambda i: -half(i), lambda i: half(i), 0, 0)

# the outside: stone kerb on the legs, red and white round the bend; pavement behind it
kerb = meshes.setdefault("HP_KerbStone", Mesh())
red = meshes.setdefault("HP_KerbRed", Mesh())
walk = meshes.setdefault("HP_Pavement", Mesh())


def runs(test):
    out, i = [], 0
    while i < n:
        if test(i):
            j = i
            while j + 1 < n and test(j + 1):
                j += 1
            if j > i:
                out.append((i, j + 1))
            i = j + 1
        else:
            i += 1
    return out


def kerb_strip(mesh, i0, i1, edge, sign):
    # a small rounded profile: rises from the road edge over the kerb's width
    ribbon(mesh, i0, i1, lambda i: edge(i), lambda i: edge(i) + sign * 0.3, 0.0, UP * 0.7, u_scale=8.0)
    ribbon(mesh, i0, i1, lambda i: edge(i) + sign * 0.3, lambda i: edge(i) + sign * KERB, UP * 0.7, UP + 0.08, u_scale=8.0)


s_out = -in_sign
for i0, i1 in runs(near_island):
    kerb_strip(red, i0, i1, out_edge, s_out)
for i0, i1 in runs(lambda i: not near_island(i)):
    kerb_strip(kerb, i0, i1, out_edge, s_out)
ribbon(walk, 0, n, lambda i: out_edge(i) + s_out * KERB, lambda i: out_edge(i) + s_out * (KERB + WALK), UP, UP)
# the inside: kerb and pavement along the legs, stopping at the island (its own kerb goes round it)
s_in = in_sign
for i0, i1 in runs(lambda i: not near_island(i)):
    kerb_strip(kerb, i0, i1, in_edge, s_in)
    ribbon(walk, i0, i1, lambda i: in_edge(i) + s_in * KERB, lambda i: in_edge(i) + s_in * (KERB + WALK), UP, UP)

# lines: solid edges, a dashed middle (each its own thin strip, 0.06 over the road)
lines = meshes.setdefault("HP_Lines", Mesh())
LIFT = 0.1
ribbon(lines, 0, n, lambda i: -half(i) + 1.0, lambda i: -half(i) + 1.6, LIFT, LIFT)
ribbon(lines, 0, n, lambda i: half(i) - 1.6, lambda i: half(i) - 1.0, LIFT, LIFT)
DASH, GAP = 10.0, 8.0
i = 0
while i < n - 1:
    j = i
    while j + 1 < n and arc[j] - arc[i] < DASH:
        j += 1
    ribbon(lines, i, j + 1, -0.3, 0.3, LIFT, LIFT)
    k = j
    while k + 1 < n and arc[k] - arc[j] < GAP:
        k += 1
    i = k + 1

# the island: a low planter, red-and-white kerb round its outline, a soil top
isl = d["island"]
# its height: the road's at the nearest sample, with a little over
ring_y = []
for (x, z) in isl:
    best = min(range(0, n, 4), key=lambda q: (S[q][0] - x) ** 2 + (S[q][2] - z) ** 2)
    ring_y.append(S[best][1])
top_y = [v + 0.9 for v in ring_y]  # (the planter climbs with the road)
kx, kz = sum(p[0] for p in isl) / len(isl), sum(p[1] for p in isl) / len(isl)
inner = []
for (x, z) in isl:
    dx, dz = x - kx, z - kz
    L = math.hypot(dx, dz) or 1
    inner.append((x - dx / L * KERB, z - dz / L * KERB))
m = len(isl)
a = [(x, ring_y[k], z) for k, (x, z) in enumerate(isl)] + [(isl[0][0], ring_y[0], isl[0][1])]
b = [(p[0], top_y[k], p[1]) for k, p in enumerate(inner)] + [(inner[0][0], top_y[0], inner[0][1])]
pl = [0.0]
for k in range(1, len(a)):
    pl.append(pl[-1] + math.dist((a[k][0], a[k][2]), (a[k - 1][0], a[k - 1][2])))
red.quad_strip(a, b, [(u / 8.0, 0.0) for u in pl], [(u / 8.0, 1.0) for u in pl])
top = meshes.setdefault("HP_Island", Mesh())
base = len(top.v)
top.v.append((kx, sum(top_y) / len(top_y), kz))
top.uv.append((0.5, 0.5))
for k, p in enumerate(inner):
    top.v.append((p[0], top_y[k], p[1]))
    top.uv.append(((p[0] - kx) / 60 + 0.5, (p[1] - kz) / 60 + 0.5))
for k in range(m):
    top.f.append((base, base + 1 + k, base + 1 + (k + 1) % m))

# the retaining wall: behind the pavement on the bend's outside, 34 studs high, leaning back a little
wall = meshes.setdefault("HP_Wall", Mesh())
w0 = min(i for i in range(n) if near_island(i)) - 40
w1 = max(i for i in range(n) if near_island(i)) + 40
fa, fb, ua, ub = [], [], [], []
for i in range(max(w0, 0), min(w1, n)):
    o = out_edge(i) + s_out * (KERB + WALK + 0.2)
    p0, p1 = side(i, o), side(i, o + s_out * 5)
    y = S[i][1]
    fa.append((p0[0], y + 0.2, p0[1]))
    fb.append((p1[0], y + 34, p1[1]))
    ua.append((arc[i] / 22.0, 0.0))
    ub.append((arc[i] / 22.0, 1.6))
wall.quad_strip(fa, fb, ua, ub)

# to Blender
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
report = {}
for name, me in meshes.items():
    verts = [to_b(*p) for p in me.v]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], me.f)
    mesh.update()
    # (every flat piece faces up: the first pack's road and lines faced down and showed only two-sided)
    if name != "HP_Wall":
        for poly in mesh.polygons:
            if poly.normal.z < 0:
                poly.flip()
        mesh.update()
    uvl = mesh.uv_layers.new(name="UV")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            uvl.data[li].uv = me.uv[mesh.loops[li].vertex_index]
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    xs, ys, zs = zip(*me.v)
    report[name] = {"min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)], "tris": sum(len(f) - 2 for f in me.f)}
    print(name, report[name])

out_dir = os.path.join(ROOT, "imports", "new_map")
os.makedirs(out_dir, exist_ok=True)
path = os.path.join(out_dir, "Grand Hairpin.fbx")
bpy.ops.export_scene.fbx(filepath=path, use_selection=False, axis_forward="-Z", axis_up="Y", apply_unit_scale=True, global_scale=1.0, bake_space_transform=True, mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
json.dump(report, open(os.path.join(ROOT, "build", "riviera", "hairpin_parts.json"), "w"))
print("written", path, os.path.getsize(path))
