# District props v3 (13 Nov) from sheet se_props3_sheet (ChatGPT): containers, oil tank, warehouse, glass skyscraper, neon tower, gold palace spire.
# 2 colour variants each. Units = studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
def container(L, W, H, loc, col, rot=0):
    m = mark()
    box((L, W, H), (0, 0, H / 2), col, 0.35)
    dark = col + '2' if col + '2' in PAL else 'grey2'
    for k in range(int(L / 1.6)):
        x = -L / 2 + 1.0 + k * 1.6
        for s in (-1, 1): box((0.55, 0.4, H - 1.0), (x, s * (W / 2 + 0.1), H / 2), dark, 0)
    for s in (-1, 1):
        box((0.6, W + 0.3, H + 0.2), (s * (L / 2 - 0.3), 0, H / 2), dark, 0.15)
        for k in (-1, 1): box((0.3, 0.3, H - 1.6), (s * (L / 2 + 0.05), k * W * 0.18, H / 2), 'grey2', 0)
    for o in PARTS[m:]:
        o.data.transform(o.matrix_basis); o.matrix_basis = Matrix.Identity(4)
        o.data.transform(Matrix.Translation(loc) @ Matrix.Rotation(math.radians(rot), 4, 'Z'))
# 1 CONTAINERS (need 12)
for v, (a, b, c) in enumerate([('orange', 'roof_teal', 'red'), ('blue', 'green', 'yellow')]):
    container(20, 8.4, 8.6, (0, -4.6, 0), a); container(20, 8.4, 8.6, (0, 4.6, 0), b); container(20, 8.4, 8.6, (0, 0, 8.6), c, rot=8)
    done("P3_Containers_%d" % (v + 1))
# 2 OIL TANK (need 18)
for v, band in enumerate(['red', 'blue']):
    R, H = 13, 26
    cyl(R + 1, 2, (0, 0, 1), 'grey', seg=24, bev=0.4)
    cyl(R, H, (0, 0, 2 + H / 2), 'white', seg=24, bev=0.5)
    cyl(R + 0.15, 5, (0, 0, 2 + H * 0.45), band, seg=24, bev=0.2)
    for z in (2 + H * 0.2, 2 + H * 0.75): cyl(R + 0.1, 0.5, (0, 0, z), 'grey', seg=24, bev=0)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=8, radius=R); o = bpy.context.object
    import bmesh
    bm = bmesh.new(); bm.from_mesh(o.data); bmesh.ops.delete(bm, geom=[vv for vv in bm.verts if vv.co.z < -0.01], context='VERTS'); bm.to_mesh(o.data); bm.free()
    o.scale = (1, 1, 0.32); o.location = (0, 0, 2 + H); _place(o, (0, 0, 2 + H), None); o.location = (0, 0, 2 + H); _finish(o, 'grey', 0)
    cyl(2.2, 1.6, (0, 0, 2 + H + R * 0.32), 'grey2', seg=10, bev=0.2)
    # rail ring on top
    torus(R * 0.72, 0.3, (0, 0, 2 + H + R * 0.32 * 0.75 + 2.4), 'yellow', rot=(0, 0, 0), maj=28, mn=4)
    for k in range(10):
        a = k * math.pi / 5; cyl(0.25, 2.6, (math.cos(a) * R * 0.72, math.sin(a) * R * 0.72, 2 + H + R * 0.32 * 0.75 + 1.2), 'yellow', seg=6, bev=0)
    # ladder on the front-right
    a = math.radians(-60); lx, ly = math.cos(a) * (R + 1.0), math.sin(a) * (R + 1.0)
    for s in (-1, 1): box((0.6, 0.6, H + 3), (lx + s * 1.3 * math.sin(a), ly - s * 1.3 * math.cos(a), 2 + (H + 3) / 2), 'yellow', 0.15, rot=(0, 0, math.degrees(a)))
    for k in range(12): box((0.4, 3.0, 0.4), (lx, ly, 3.5 + k * (H - 1) / 11), 'yellow', 0, rot=(0, 0, math.degrees(a)))
    done("P3_OilTank_%d" % (v + 1))
# 3 WAREHOUSE (need 26): saw-tooth roof, skylights, roll door with hazard stripes, chimney
for v, door in enumerate(['yellow', 'blue']):
    W, D, H = 46, 30, 18
    box((W, D, H), (0, 0, H / 2), 'grey', 0.5)
    box((W + 1, D + 1, 2), (0, 0, 1), 'grey2', 0.4)
    for k in range(3):
        x0 = -W / 2 + k * W / 3; w = W / 3
        v_ = [(x0, -D / 2, H), (x0 + w, -D / 2, H), (x0 + w, -D / 2, H + 9), (x0, D / 2, H), (x0 + w, D / 2, H), (x0 + w, D / 2, H + 9)]
        poly(v_, [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], 'grey2' if k % 2 else 'grey', bev=0.2)
        # skylights on the sloped face
        for j in range(3):
            y = -D / 2 + 4 + j * (D - 8) / 2
            o = box((w * 0.62, 5, 0.4), (x0 + w * 0.5, y, H + 4.7), 'glass', 0.1, rot=(0, -math.degrees(math.atan2(9, w)), 0))
    box((16, 1.0, 13), (0, -D / 2 - 0.3, 6.5 + 1), 'white', 0.3)
    box((14, 1.2, 11), (0, -D / 2 - 0.5, 6.5), door, 0.2)
    for k in range(7): box((14, 1.3, 0.35), (0, -D / 2 - 0.6, 2 + k * 1.5), door + '2' if door + '2' in PAL else 'grey2', 0)
    for s in (-1, 1):
        for k in range(4):
            box((1.6, 1.4, 1.6), (s * 10.5, -D / 2 - 0.6, 0.9 + k * 1.7), 'yellow' if k % 2 == 0 else 'black', 0.1)
    for s in (-1, 1):
        for k in range(2): box((4.5, 1.0, 3.2), (s * (W / 2 - 6 - k * 6.5), -D / 2 - 0.3, 11), 'glass', 0.2)
    cx, cy = W / 2 - 6, D / 2 - 6
    for k in range(5): cyl(2.6 - k * 0.1, 7, (cx, cy, H + 3.5 + k * 7), 'red' if k % 2 == 0 else 'white', seg=12, bev=0.15)
    done("P3_Warehouse_%d" % (v + 1))
# 4 GLASS SKYSCRAPER (need 40): white lobby, glass grid, narrower top, helipad
for v, glass in enumerate(['glass', 'roof_teal']):
    B = 30; H1 = 76; B2 = 24; H2 = 16
    box((B + 4, B + 4, 10), (0, 0, 5), 'white', 0.6)
    for s in (-1, 1): box((B * 0.5, 1, 7), (0, s * (B / 2 + 2.1), 4), 'glass', 0.2)
    box((B, B, H1), (0, 0, 10 + H1 / 2), glass, 0.4)
    for k in range(9): box((B + 0.7, B + 0.7, 0.9), (0, 0, 10 + 4 + k * 8.4), 'white', 0.1)
    for k in range(5):
        x = -B / 2 + k * B / 4
        for s in (-1, 1):
            box((0.9, 0.9, H1), (x, s * (B / 2 + 0.3), 10 + H1 / 2), 'white', 0)
            box((0.9, 0.9, H1), (s * (B / 2 + 0.3), x, 10 + H1 / 2), 'white', 0)
    box((B + 2, B + 2, 2), (0, 0, 10 + H1 + 1), 'white', 0.5)
    box((B2, B2, H2), (0, 0, 12 + H1 + H2 / 2), glass, 0.4)
    for k in range(3): box((B2 + 0.6, B2 + 0.6, 0.8), (0, 0, 12 + H1 + 3 + k * 5), 'white', 0)
    cyl(B2 * 0.62, 2.2, (0, 0, 12 + H1 + H2 + 1.1), 'white', seg=24, bev=0.6)
    torus(B2 * 0.42, 0.9, (0, 0, 12 + H1 + H2 + 2.3), 'red', rot=(0, 0, 0), maj=24, mn=4)
    done("P3_GlassTower_%d" % (v + 1))
# 5 NEON TOWER (need 55): tapered dark violet glass, bright strips at the corners, crystal spike
for v, strip in enumerate(['pink', 'sky']):
    H = 104; b0, b1 = 30, 15
    box((b0 + 10, b0 + 10, 5), (0, 0, 2.5), 'violet', 0.8)
    for s in (-1, 1): box((b0 + 10.4, 1.2, 1.2), (0, s * (b0 / 2 + 5), 5), strip, 0)
    for s in (-1, 1): box((1.2, b0 + 10.4, 1.2), (s * (b0 / 2 + 5), 0, 5), strip, 0)
    v_ = []; segs = [(b0, 5), (b1, 5 + H)]
    for (bb, z) in segs:
        h = bb / 2; v_ += [(-h, -h, z), (h, -h, z), (h, h, z), (-h, h, z)]
    poly(v_, [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7), (3, 2, 1, 0)], 'violet', bev=0.3)
    # inner darker panels + floor lines
    for k in range(10):
        t = (k + 0.5) / 10; bb = b0 + (b1 - b0) * t; z = 5 + H * t
        box((bb + 0.4, bb + 0.4, 0.6), (0, 0, z), 'lilac', 0)
    # corner light strips
    for sx in (-1, 1):
        for sy in (-1, 1):
            a = Vector((sx * b0 / 2, sy * b0 / 2, 5)); b = Vector((sx * b1 / 2, sy * b1 / 2, 5 + H))
            c = (a + b) / 2; L = (b - a).length
            o = box((1.6, 1.6, L), (0, 0, 0), strip, 0.2); o.matrix_world = Matrix.Translation(c) @ (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
    box((b1 + 6, b1 + 6, 3), (0, 0, 5 + H + 1.5), 'violet', 0.6)
    box((b1 + 6.4, b1 + 6.4, 0.8), (0, 0, 5 + H + 3), strip, 0)
    cyl(b1 * 0.32, 6, (0, 0, 5 + H + 6), 'violet', seg=6, bev=0.3)
    cyl(b1 * 0.38, 4, (0, 0, 5 + H + 11), 'lilac', seg=6, bev=0.2, r2=b1 * 0.42)
    cyl(b1 * 0.42, 12, (0, 0, 5 + H + 19), 'glass2', seg=6, bev=0.2, r2=0.3)
    done("P3_NeonTower_%d" % (v + 1))
# 6 GOLD PALACE SPIRE (need 75): cream base, arched windows, gold corner domes, gold dome, spire + star
def star(r1, r2, th, loc, col):
    pts = []
    for k in range(10):
        r = r1 if k % 2 == 0 else r2; t = math.pi / 2 + k * math.pi / 5; pts.append((math.cos(t) * r, math.sin(t) * r))
    v_ = [(a, -th / 2, b) for (a, b) in pts] + [(a, th / 2, b) for (a, b) in pts]
    f = [tuple(range(10)), tuple(range(19, 9, -1))] + [(k, (k + 1) % 10, (k + 1) % 10 + 10, k + 10) for k in range(10)]
    return poly(v_, f, col, loc=loc, bev=min(th * 0.3, 0.3))
for v, win in enumerate(['blue', 'violet']):
    S = 2.0
    box((44 * S, 44 * S, 3 * S), (0, 0, 1.5 * S), 'cream2', 0.6)
    box((40 * S, 40 * S, 2.5 * S), (0, 0, 4.25 * S), 'cream', 0.6)
    box((32 * S, 32 * S, 22 * S), (0, 0, 5.5 * S + 11 * S), 'cream', 0.8)
    box((34 * S, 34 * S, 2 * S), (0, 0, 5.5 * S + 22 * S + 1 * S), 'gold', 0.8)
    m = mark()
    for x in (-8 * S, 8 * S): arch_window(x, 5.5 * S + 3 * S, 8 * S, 13 * S, -16 * S, frame='gold', glass=win)
    ring4(m)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((7 * S, 7 * S, 26 * S), (sx * 16 * S, sy * 16 * S, 5.5 * S + 13 * S), 'cream2', 0.6)
            box((8 * S, 8 * S, 1.6 * S), (sx * 16 * S, sy * 16 * S, 5.5 * S + 26 * S), 'gold', 0.5)
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=4 * S); o = bpy.context.object
            o.location = (sx * 16 * S, sy * 16 * S, 5.5 * S + 27 * S); _finish(o, 'gold', 0)
    z0 = 5.5 * S + 24 * S
    cyl(13 * S, 7 * S, (0, 0, z0 + 3.5 * S), 'cream', seg=20, bev=0.6)
    for k in range(8):
        a = k * math.pi / 4; box((2.4 * S, 1.0, 4.6 * S), (math.cos(a) * 13 * S, math.sin(a) * 13 * S, z0 + 3.6 * S), win, 0.2, rot=(0, 0, math.degrees(a) + 90))
    cyl(13.8 * S, 1.2 * S, (0, 0, z0 + 7 * S), 'gold', seg=20, bev=0.4)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=12.5 * S); o = bpy.context.object
    bm = bmesh.new(); bm.from_mesh(o.data); bmesh.ops.delete(bm, geom=[vv for vv in bm.verts if vv.co.z < -0.01], context='VERTS'); bm.to_mesh(o.data); bm.free()
    o.location = (0, 0, z0 + 7.5 * S); _finish(o, 'gold', 0)
    for k in range(8):
        a = k * math.pi / 4; torus(12.6 * S, 0.35 * S, (0, 0, z0 + 7.5 * S), 'yellow2', rot=(90, 0, k * 22.5), maj=24, mn=3); clip_below(PARTS[-1], z0 + 7.5 * S)
    zt = z0 + 7.5 * S + 12.5 * S
    cyl(2.2 * S, 3 * S, (0, 0, zt + 1.5 * S), 'gold', seg=10, bev=0.3)
    blob(2.2 * S, (0, 0, zt + 4 * S), 'gold', sub=2)
    cyl(0.8 * S, 14 * S, (0, 0, zt + 12 * S), 'gold', seg=8, bev=0.1, r2=0.35 * S)
    star(4.2 * S, 1.8 * S, 1.4 * S, (0, 0, zt + 21 * S), 'yellow')
    done("P3_Palace_%d" % (v + 1))
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/props3.blend")
