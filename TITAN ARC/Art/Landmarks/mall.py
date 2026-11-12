# MEGA MALL (Downtown landmark) from sheet se_lm_mall (ChatGPT, 13 Nov). 1 sheet px = 0.15 studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
S = 0.15; CX = 1148; GY = 438
def X(px): return (px - CX) * S
def Z(py): return (GY - py) * S
W = (1484 - 812) * S; D = 60.0; fy = -D / 2
# WINGS (left + right), 3 floors, violet bands, glass bands, shopfronts with awnings
def wing(x0, x1, awn):
    w = X(x1) - X(x0); cx = (X(x0) + X(x1)) / 2
    box((w, D, Z(172) - Z(420)), (cx, 0, (Z(172) + Z(420)) / 2), 'cream', 0.5)
    box((w + 1, D + 1, Z(160) - Z(172) + 0.6), (cx, 0, Z(166)), 'cream2', 0.4)               # parapet cap
    for (yt, yb) in [(190, 205), (263, 280), (330, 345)]:
        box((w + 2.4, D + 2.4, (yb - yt) * S), (cx, 0, Z((yt + yb) / 2)), 'violet', 0.5)
    for (yt, yb) in [(215, 255), (285, 325)]:
        for face in (-1, 1):
            box((w - 6, 1.0, (yb - yt) * S), (cx, face * (D / 2 + 0.2), Z((yt + yb) / 2)), 'glass', 0.15)
            for k in range(5):
                box((0.6, 1.4, (yb - yt) * S), (cx - (w - 6) / 2 + k * (w - 6) / 4, face * (D / 2 + 0.35), Z((yt + yb) / 2)), 'blue2', 0)
        for sx in (-1, 1):
            box((1.0, D - 8, (yb - yt) * S), (cx + sx * (w / 2 + 0.2), 0, Z((yt + yb) / 2)), 'glass', 0.15)
    # shopfronts (front): 2 per wing with striped awnings
    for i, col in enumerate(awn):
        sx = cx + (-1 if i == 0 else 1) * w * 0.25
        box((w * 0.36, 1.0, (418 - 382) * S), (sx, fy - 0.2, Z(400)), 'glass', 0.15)
        box((w * 0.4, 1.2, 0.8), (sx, fy - 0.3, Z(380)), 'white', 0.2)
        n = 5
        for k in range(n):
            c = col if k % 2 == 0 else 'awn_white'; xx = sx - w * 0.2 + (k + 0.5) * w * 0.4 / n
            box((w * 0.4 / n, 4.6, 0.8), (xx, fy - 2.1, Z(352)), c, 0.2, rot=(-32, 0, 0))
            box((w * 0.4 / n, 0.8, 2.2), (xx, fy - 4.1, Z(352) - 2.2), c, 0.25)
    # roof: grey deck + a vent box
    box((w - 2, D - 2, 0.6), (cx, 0, Z(172) + 0.2), 'grey', 0.1)
    vx = cx + (-w * 0.2 if cx < 0 else w * 0.2)
    box((7.5, 6, 4), (vx, 4, Z(172) + 2.2), 'grey', 0.4)
    for k in range(4): box((6.2, 0.4, 0.5), (vx, 0.85, Z(172) + 1.0 + k * 0.9), 'grey2', 0)
wing(812, 1062, ['awn_red', 'awn_yellow']); wing(1255, 1484, ['awn_yellow', 'awn_teal' if 'awn_teal' in PAL else 'roof_teal'])
box((W + 3, D + 3, (438 - 420) * S), (0, 0, Z(429)), 'cream2', 0.5)          # base plinth
done("LM2_Mall_Wings")
# CENTRE: cream drum block, violet arch with glass + grid, doors, pillars with gold balls, steps
cw = (1310 - 1015) * S
box((cw, D * 0.9, Z(158) - Z(420)), (X(1162), 0, (Z(158) + Z(420)) / 2), 'cream', 0.5)
ax = X(1142); aw = (1225 - 1060) * S; ah = Z(185)
box((aw, 3.0, ah - aw / 2), (ax, fy - 3.5, (ah - aw / 2) / 2 + 2.7), 'violet', 0.6)
cyl(aw / 2, 3.0, (ax, fy - 3.5, ah - aw / 2 + 2.7), 'violet', seg=24, bev=0.4, rot=(90, 0, 0))
iw = (1200 - 1085) * S
box((iw, 3.2, ah - aw / 2 - 1.5), (ax, fy - 3.6, (ah - aw / 2 - 1.5) / 2 + 2.7), 'glass', 0.1)
cyl(iw / 2, 3.2, (ax, fy - 3.6, ah - aw / 2 + 1.2), 'glass', seg=24, bev=0.1, rot=(90, 0, 0))
for k in range(1, 4): box((0.5, 3.6, ah - 4), (ax - iw / 2 + k * iw / 4, fy - 3.7, ah / 2), 'white', 0)
for z in (Z(305), Z(270), Z(235)): box((iw, 3.6, 0.5), (ax, fy - 3.7, z), 'white', 0)
box((iw * 0.9, 3.8, Z(400) - Z(420) + 10), (ax, fy - 3.8, Z(420) + 5.3), 'blue', 0.2)
for sx in (-1, 1): box((0.9, 4.2, 4.5), (ax + sx * 1.2, fy - 3.9, Z(420) + 5), 'chrome', 0.1)
for px_ in (1047, 1237):
    cyl(2.2, Z(255) - Z(420), (X(px_), fy - 4.5, (Z(255) + Z(420)) / 2), 'violet', seg=14, bev=0.3)
    cyl(2.8, 1.2, (X(px_), fy - 4.5, Z(420) + 0.6), 'cream2', seg=14, bev=0.3)
    blob(3.3, (X(px_), fy - 4.5, Z(225)), 'gold', sub=2)
for k in range(3): box((aw + 6 - k * 2, 4 - k * 1.0, 0.9), (ax, fy - 7 + k * 0.6, Z(420) + 0.45 + k * 0.9), 'cream2' if k % 2 else 'cream', 0.25)
done("LM2_Mall_Centre")
# DOME: drum + glass half sphere with white ribs
dx = X(1160); dr = (1285 - 1035) * S / 2
cyl(dr + 1.2, Z(158) - Z(178) + 1, (dx, 0, Z(168)), 'cream2', seg=28, bev=0.4)
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=dr); o = bpy.context.object
import bmesh
bm = bmesh.new(); bm.from_mesh(o.data)
bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context='VERTS'); bm.to_mesh(o.data); bm.free()
o.location = (dx, 0, Z(158)); _finish(o, "glass", 0)
for k in range(6):
    torus(dr + 0.15, 0.45, (dx, 0, Z(158)), 'white', rot=(90, 0, k * 30), maj=40, mn=4)
    o = PARTS[-1]; o.scale = (1, 1, 1); 
for (zr, rr) in [(0.38, 0.925), (0.72, 0.694)]:
    torus(dr * rr + 0.15, 0.45, (dx, 0, Z(158) + dr * zr), 'white', rot=(0, 0, 0), maj=32, mn=4)
blob(1.6, (dx, 0, Z(158) + dr + 0.6), 'gold', sub=2)
done("LM2_Mall_Dome")
# squash the meridian tori to the dome's 0.88 height and drop their lower halves inside the drum
o = made[-1]
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/mall.blend")
