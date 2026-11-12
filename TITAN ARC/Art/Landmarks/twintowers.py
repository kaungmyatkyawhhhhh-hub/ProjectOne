# TWIN TOWERS (Skyline landmark) from sheet se_lm_twintowers (ChatGPT, 13 Nov). 1 sheet px = 0.55 studs. Front = -y.
import sys; sys.path.insert(0, "/home/claude/props/lm2")
import bpy; bpy.ops.wm.read_factory_settings(use_empty=True)
from common import *
from lib import _finish, _place
made = []
def done(n): made.append(join(n))
S = 0.55; GY = 391
def Z(py): return (GY - py) * S
TW = 94 * S                 # tower width 51.7
R = TW / 2 / math.cos(math.pi / 8)          # octagon circumradius for a flat-to-flat width TW
GAP = (944 - 866) * S
XS = [-(GAP / 2 + TW / 2), GAP / 2 + TW / 2]
def octo(r, h, loc, col, bev=0.3):
    return cyl(r, h, loc, col, seg=8, bev=bev, rot=(0, 0, 22.5))
# PLAZA (shared white base, steps)
PW, PD = 347 * S, 150 * S
box((PW, PD, Z(367) - 0.0), (0, 0, Z(367) / 2), 'white', 0.8)
for k in range(3):
    box((40, 6 + (2 - k) * 3, 1.4), (0, -PD / 2 - 1.5 - (2 - k) * 1.5, 0.7 + k * 1.4), 'trim' if k % 2 else 'white', 0.4)
for x in XS:
    for k in range(3):
        box((22, 4 + (2 - k) * 2.5, 1.2), (x, -PD / 2 - 1.2 - (2 - k) * 1.2, 0.6 + k * 1.2), 'white', 0.3)
done("LM2_Twin_Plaza")
zl = Z(367); zg = Z(305); ztop = Z(100); zmid = (zg + ztop) / 2
def tower_part(x, z0, z1, lobby=False, top=False):
    if lobby:
        octo(R * 1.08, zg - zl, (x, 0, (zl + zg) / 2), 'white', 0.6)
        octo(R * 1.12, 1.6, (x, 0, zg), 'trim', 0.4)
        # lobby glass doors on the front
        box((TW * 0.55, 1.2, (zg - zl) * 0.72), (x, -R * 1.08 * math.cos(math.pi / 8) - 0.3, zl + (zg - zl) * 0.36 + 0.3), 'glass', 0.2)
        for k in range(1, 4): box((0.6, 1.6, (zg - zl) * 0.72), (x - TW * 0.275 + k * TW * 0.1375, -R * 1.08 * math.cos(math.pi / 8) - 0.5, zl + (zg - zl) * 0.36 + 0.3), 'white', 0)
        z0 = zg + 0.8
    octo(R, z1 - z0, (x, 0, (z0 + z1) / 2), 'glass', 0.2)
    # horizontal white floor rings
    n = int((z1 - z0) / 11)
    for k in range(n + 1):
        octo(R + 0.45, 1.3, (x, 0, z0 + k * (z1 - z0) / max(n, 1)), 'white', 0.2)
    # vertical corner posts + one mid mullion per face
    for k in range(8):
        a = math.radians(22.5 + k * 45)
        box((1.6, 1.6, z1 - z0), (x + math.cos(a) * R, math.sin(a) * R, (z0 + z1) / 2), 'white', 0.3, rot=(0, 0, math.degrees(a)))
        b = math.radians(k * 45); rr = R * math.cos(math.pi / 8)
        box((0.9, 0.9, z1 - z0), (x + math.cos(b) * (rr + 0.2), math.sin(b) * (rr + 0.2), (z0 + z1) / 2), 'white', 0, rot=(0, 0, math.degrees(b)))
    if top:
        z = z1
        for k, f in enumerate((0.92, 0.8, 0.66)):
            octo(R * f, 4.2, (x, 0, z + 2.1), 'white', 0.5); z += 4.2
        octo(R * 0.52, 3.6, (x, 0, z + 1.8), 'gold', 0.5); z += 3.6
        octo(R * 0.36, 2.4, (x, 0, z + 1.2), 'white', 0.4); z += 2.4
        cyl(0.9, Z(30) - z, (x, 0, (z + Z(30)) / 2), 'white', seg=8, bev=0.2)
        cyl(2.1, 1.0, (x, 0, z + 2), 'grey', seg=8, bev=0.2)
        blob(2.6, (x, 0, Z(24)), 'tail', sub=2)
for i, x in enumerate(XS):
    tower_part(x, zg, zmid, lobby=True); done("LM2_Twin_Low%d" % (i + 1))
    tower_part(x, zmid, ztop, top=True); done("LM2_Twin_Top%d" % (i + 1))
# SKY BRIDGE
zb0, zb1 = Z(180), Z(144)
bw = XS[1] - XS[0]
box((bw, 16, zb1 - zb0), (0, 0, (zb0 + zb1) / 2), 'glass', 0.3)
for z in (zb0, zb1): box((bw, 17.5, 1.8), (0, 0, z), 'white', 0.4)
for k in range(5): box((1.0, 17, zb1 - zb0), (-bw / 2 + 4 + k * (bw - 8) / 4, 0, (zb0 + zb1) / 2), 'white', 0)
done("LM2_Twin_Bridge")
tot = 0
for o in made:
    o.data.calc_loop_triangles(); n = len(o.data.loop_triangles); tot += n
    print(o.name, n, [round(v, 1) for v in o.dimensions])
print("TOTAL", tot)
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/props/lm2/twintowers.blend")
