import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
from lib import *
from lib import _finish, _place
OUT = os.environ.get("OUT", "/home/claude/props/out"); os.makedirs(OUT, exist_ok=True)
ONLY = os.environ.get("ONLY")
made = []
def done(name):
    o = join(name); made.append(o); return o
def want(k): return (not ONLY) or k in ONLY.split(",")

# ---------------- FLOWER BED (3.6 x 3.6 x ~2.6) ----------------
def flower(px, py, base, petal, h, seed, stemcol='leaf2'):
    rnd = random.Random(seed)
    cyl(0.07, h, (px, py, base + h / 2), stemcol, seg=6, bev=0)
    box((0.5, 0.12, 0.22), (px + 0.2, py, base + h * 0.45), 'leaf', 0.05, rot=(0, -30, rnd.uniform(0, 180)))
    top = base + h
    for i in range(5):
        a = i * 2 * math.pi / 5 + rnd.uniform(0, 0.3)
        blob(0.2, (px + math.cos(a) * 0.24, py + math.sin(a) * 0.24, top), petal, sub=1, sq=(1.15, 1.15, 0.55), seed=seed + i)
    blob(0.14, (px, py, top + 0.06), 'yellow' if petal != 'petal_y' else 'orange', sub=1, sq=(1, 1, 0.7))
def bed(var):
    if var == 1:   # wooden planter
        box((3.6, 3.6, 0.9), (0, 0, 0.45), 'wood', 0.14)
        for x in (-1.2, 0, 1.2): box((1.12, 3.7, 0.08), (x, 0, 0.75), 'wood2', 0.02)
        box((3.2, 3.2, 0.2), (0, 0, 0.86), 'soil', 0.06)
        cols = ['petal_p', 'petal_y', 'petal_w', 'petal_v', 'petal_s']
    elif var == 2:  # round stone planter
        cyl(1.8, 0.9, (0, 0, 0.45), 'stone', seg=20, bev=0.14); cyl(1.85, 0.22, (0, 0, 0.9), 'concrete', seg=20, bev=0.08)
        cyl(1.5, 0.2, (0, 0, 0.95), 'soil', seg=20, bev=0.05)
        cols = ['petal_y', 'petal_o', 'petal_y', 'petal_w', 'petal_o']
    else:           # brick planter
        box((3.6, 3.6, 0.85), (0, 0, 0.42), 'wall_brick', 0.1)
        for z in (0.25, 0.6):
            for x in (-1.82, 1.82): box((0.06, 3.4, 0.08), (x, 0, z), 'wall_brick2', 0.0)
        box((3.8, 3.8, 0.2), (0, 0, 0.9), 'concrete', 0.08); box((3.2, 3.2, 0.2), (0, 0, 0.94), 'soil', 0.06)
        cols = ['petal_v', 'petal_p', 'petal_w', 'petal_p', 'petal_s']
    rnd = random.Random(var * 7)
    pts = [(-0.95, -0.95), (0.95, -0.9), (0, 0), (-0.9, 0.95), (0.95, 0.95), (0, -1.1), (0.1, 1.1)]
    for i, (x, y) in enumerate(pts):
        flower(x + rnd.uniform(-.15, .15), y + rnd.uniform(-.15, .15), 1.0, cols[i % len(cols)], 0.9 + rnd.uniform(0, 0.55), var * 100 + i * 9)
    for (x, y) in ((-1.2, 0.1), (1.2, -0.1), (0.2, 1.3), (-0.2, -1.3)):
        blob(0.42, (x, y, 1.15), 'leaf', sub=1, sq=(1.1, 1.1, 0.7), seed=int(x * 10 + y))
    done("Flower_%d" % var)

# ---------------- MAILBOX (1.9 x 1.9 x 4.8) ----------------
def mailbox(var):
    body, body2, post = {1: ('blue', 'blue2', 'grey2'), 2: ('red', 'red2', 'wood'), 3: ('green', 'green2', 'black')}[var]
    box((1.0, 1.0, 0.22), (0, 0, 0.11), 'stone2', 0.07)
    if post == 'wood': box((0.45, 0.45, 2.6), (0, 0, 1.5), 'wood', 0.08)
    else: cyl(0.22, 2.6, (0, 0, 1.5), post, seg=10, bev=0.05)
    box((0.9, 0.9, 0.2), (0, 0, 2.8), body2, 0.06)
    # box with a round top (tunnel)
    box((1.3, 1.9, 0.9), (0, 0, 3.35), body, 0.12)
    cyl(0.65, 1.9, (0, 0, 3.8), body, seg=16, bev=0.08, rot=(90, 0, 0))
    box((1.2, 0.12, 1.2), (0, -0.98, 3.5), body2, 0.05)          # door
    box((0.5, 0.1, 0.14), (0, -1.06, 3.85), 'chrome', 0.03)        # slot / handle
    box((0.12, 0.12, 1.0), (0.72, 0.25, 4.1), 'red' if body != 'red' else 'yellow', 0.03)  # flag pole
    box((0.1, 0.55, 0.38), (0.72, 0.05, 4.45), 'red' if body != 'red' else 'yellow', 0.04)
    done("Mailbox_%d" % var)

# ---------------- BIN (≈2.0 x 2.0 x 2.4) ----------------
def bin_(var):
    col, col2 = {1: ('green', 'green2'), 2: ('blue', 'blue2'), 3: ('grey', 'grey2')}[var]
    if var != 3:
        cyl(0.95, 2.0, (0, 0, 1.0), col, seg=18, bev=0.1, r2=None)
        for z in (0.45, 1.0, 1.55): cyl(1.0, 0.12, (0, 0, z), col2, seg=18, bev=0.03)
        cyl(1.08, 0.25, (0, 0, 2.1), col2, seg=18, bev=0.08)
        cyl(0.8, 0.22, (0, 0, 2.3), col, seg=18, bev=0.08)
        box((0.7, 0.25, 0.22), (0, 0, 2.48), col2, 0.07)
        for a in (0, 180): box((0.25, 0.4, 0.3), (math.cos(math.radians(a)) * 1.05, 0, 1.75), col2, 0.06)
    else:  # square wheelie bin, lid hinge at the back
        box((1.7, 1.8, 2.0), (0, 0, 1.15), col, 0.14)
        for x in (-0.88, 0.88): box((0.08, 1.4, 1.5), (x, 0, 1.1), col2, 0.03)
        box((1.9, 2.0, 0.22), (0, -0.05, 2.25), 'green2', 0.08)
        box((1.6, 0.35, 0.22), (0, 0.95, 2.05), 'black', 0.06)
        for x in (-0.65, 0.65): cyl(0.28, 0.25, (x, 0.75, 0.28), 'tyre', seg=12, bev=0.05, rot=(0, 90, 0))
    done("Bin_%d" % var)

# ---------------- BIKE (5.4 x 1.3 x 3.2) ----------------
def bike(var):
    frame, seatc = {1: ('red', 'seat'), 2: ('sky', 'seat'), 3: ('yellow', 'violet')}[var]
    R = 1.05
    for x in (-1.75, 1.75):
        torus(R, 0.16, (x, 0, R + 0.02), 'tyre', rot=(90, 0, 0), maj=20, mn=6)
        cyl(R - 0.18, 0.08, (x, 0, R + 0.02), 'rim', seg=16, bev=0, rot=(90, 0, 0))
        cyl(0.18, 0.4, (x, 0, R + 0.02), 'chrome', seg=8, bev=0.03, rot=(90, 0, 0))
    def tube(a, b, r=0.11, col=frame):
        a, b = Vector(a), Vector(b); d = b - a; L = d.length; mid = (a + b) / 2
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=r, depth=L); o = bpy.context.object
        o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler(); o.location = mid
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True); return _finish(o, col, 0)
    bb = (0, 0, 0.95); seat = (-0.45, 0, 2.25); head = (1.15, 0, 2.35)
    tube((-1.75, 0, R), bb); tube(bb, seat); tube(seat, (-1.75, 0, R)); tube(bb, head); tube(seat, (1.05, 0, 2.2)); tube(head, (1.75, 0, R))
    tube((1.15, 0, 2.35), (1.0, 0, 2.95), 0.1, 'grey2')
    box((0.18, 1.3, 0.18), (1.0, 0, 2.98), 'grey2', 0.05)
    for y in (-0.6, 0.6): box((0.4, 0.22, 0.22), (1.0, y, 2.98), 'black', 0.07)
    box((0.9, 0.5, 0.25), (-0.5, 0, 2.42), seatc, 0.1)
    cyl(0.32, 0.12, (0, 0, 0.95), 'chrome', seg=12, bev=0.03, rot=(90, 0, 0))
    if var == 1: box((0.9, 0.9, 0.5), (1.55, 0, 2.6), 'wood', 0.08)        # front basket
    if var == 3:
        for y in (-0.35, 0.35): box((1.2, 0.08, 0.08), (0.9, y * 1.6, 3.0), 'pink', 0.02)   # streamers
    done("Bike_%d" % var)

# ---------------- CAR (10.3 x 5.9 x 4.6) ----------------
def car(var):
    body, body2 = {1: ('red', 'red2'), 2: ('sky', 'blue2'), 3: ('yellow', 'yellow2')}[var]
    L, W = 10.0, 5.6
    box((L, W, 1.7), (0, 0, 1.55), body, 0.5, seg=3)                           # lower body
    box((L + 0.2, W + 0.15, 0.55), (0, 0, 0.85), 'cream' if var != 3 else 'black', 0.25)  # bumper band
    cab_x = -0.6 if var != 2 else -0.3
    box((5.6, W - 0.6, 1.9), (cab_x, 0, 3.25), body, 0.6, seg=3)              # cabin
    box((5.0, W - 0.5, 1.2), (cab_x, 0, 3.3), 'glassdark', 0.35)              # glass band (shows through)
    for y in (-1, 1):
        box((2.0, 0.2, 1.05), (cab_x + 1.25, y * (W / 2 - 0.25), 3.3), 'glass', 0.15)
        box((2.0, 0.2, 1.05), (cab_x - 1.25, y * (W / 2 - 0.25), 3.3), 'glass', 0.15)
        box((0.5, 0.22, 0.95), (cab_x + 1.45, y * (W / 2 - 0.2), 3.35), 'glass2', 0.05, rot=(0, 20, 0))
    box((0.22, W - 1.2, 1.1), (cab_x + 2.75, 0, 3.25), 'glass', 0.15, rot=(0, -28, 0))   # windscreen
    box((0.22, W - 1.2, 1.0), (cab_x - 2.75, 0, 3.25), 'glass', 0.15, rot=(0, 28, 0))
    if var == 1:
        for y in (-0.55, 0.55): box((L * 0.98, 0.45, 0.06), (0, y, 2.42), 'white', 0.02)   # racing stripes
        for y in (-0.55, 0.55): box((5.4, 0.45, 0.06), (cab_x, y, 4.21), 'white', 0.02)
    if var == 3:
        box((1.6, 0.8, 0.7), (cab_x, 0, 4.5), 'white', 0.18); box((1.7, 0.85, 0.15), (cab_x, 0, 4.15), 'black', 0.05)
        for x in range(-2, 3): box((0.8, 0.06, 0.4), (x * 0.95, -W / 2 - 0.02, 1.7), 'black' if x % 2 else 'yellow2', 0.0)
    if var == 2: box((3.0, W - 0.8, 0.25), (cab_x, 0, 4.3), 'grey2', 0.08)                  # roof rack
    for x in (-1, 1):
        for y in (-1, 1):
            cyl(1.0, 0.8, (x * 3.1, y * (W / 2 - 0.15), 1.0), 'tyre', seg=16, bev=0.18, rot=(90, 0, 0))
            cyl(0.55, 0.85, (x * 3.1, y * (W / 2 - 0.12), 1.0), 'rim', seg=12, bev=0.08, rot=(90, 0, 0))
            cyl(0.2, 0.9, (x * 3.1, y * (W / 2 - 0.1), 1.0), 'chrome', seg=8, bev=0.03, rot=(90, 0, 0))
    for y in (-1.7, 1.7):
        cyl(0.5, 0.3, (L / 2 + 0.05, y, 1.75), 'light', seg=12, bev=0.08, rot=(0, 90, 0))
        box((0.25, 0.9, 0.55), (-L / 2 - 0.05, y, 1.8), 'tail', 0.1)
    box((0.2, 1.8, 0.6), (L / 2 + 0.08, 0, 1.55), 'chrome', 0.1)                 # grille
    for z in (1.42, 1.62): box((0.22, 1.5, 0.06), (L / 2 + 0.15, 0, z), 'grey2', 0.0)
    for y in (-1, 1): box((0.35, 0.5, 0.3), (cab_x + 2.3, y * (W / 2 + 0.15), 2.75), body2, 0.1)   # mirrors
    done("Car_%d" % var)

# ---------------- BUS (26.3 x 9.0 x 8.6) ----------------
def bus(var):
    body, body2, band = {1: ('orange', 'orange2', 'cream'), 2: ('blue', 'blue2', 'white'), 3: ('green', 'green2', 'yellow3')}[var]
    L, W = 25.5, 8.6
    box((L, W, 5.6), (0, 0, 4.2), body, 0.7, seg=3)
    box((L + 0.2, W + 0.15, 1.2), (0, 0, 2.0), band, 0.35)
    box((L - 1.5, W - 1.0, 0.6), (0, 0, 7.2), band, 0.3)                        # roof cap
    if var == 1: box((5.0, W - 2.5, 0.5), (-2, 0, 7.6), 'cream2', 0.2)             # roof box like the concept
    for y in (-1, 1):
        for i in range(6):
            x = -9.3 + i * 3.3
            box((2.6, 0.3, 2.1), (x, y * (W / 2 + 0.02), 5.1), 'black', 0.2)
            box((2.3, 0.35, 1.8), (x, y * (W / 2 + 0.03), 5.1), 'glass', 0.12)
            box((0.4, 0.38, 1.4), (x - 0.6, y * (W / 2 + 0.05), 5.2), 'glass2', 0.04, rot=(0, 18, 0))
    box((0.3, W - 1.2, 3.0), (L / 2 + 0.05, 0, 5.0), 'glass', 0.3)               # windscreen
    box((0.34, 1.3, 2.6), (L / 2 + 0.08, -2.2, 5.2), 'glass2', 0.05, rot=(18, 0, 0))
    box((0.3, W - 1.8, 0.6), (L / 2 + 0.06, 0, 6.95), 'black', 0.12)             # destination sign
    box((0.32, W - 2.4, 0.4), (L / 2 + 0.08, 0, 6.95), 'yellow3', 0.08)
    box((2.0, 0.3, 4.2), (L / 2 - 2.2, -W / 2 - 0.02, 3.9), 'glassdark', 0.12)  # door
    box((0.12, 0.34, 4.0), (L / 2 - 2.2, -W / 2 - 0.05, 3.9), body2, 0.02)
    for y in (-1, 1):
        cyl(0.55, 0.3, (L / 2 + 0.1, y * 3.1, 2.4), 'light', seg=12, bev=0.08, rot=(0, 90, 0))
        box((0.3, 0.9, 0.7), (-L / 2 - 0.08, y * 3.1, 2.4), 'tail', 0.1)
        box((0.5, 0.7, 1.4), (L / 2 - 0.5, y * (W / 2 + 0.45), 5.6), 'black', 0.12)  # mirrors
    box((0.3, 4.0, 0.9), (L / 2 + 0.12, 0, 1.4), 'grey2', 0.2)                   # bumper
    box((0.3, 4.0, 0.9), (-L / 2 - 0.12, 0, 1.4), 'grey2', 0.2)
    for x in (-8.0, 8.0):
        for y in (-1, 1):
            cyl(1.4, 1.0, (x, y * (W / 2 - 0.2), 1.4), 'tyre', seg=18, bev=0.25, rot=(90, 0, 0))
            cyl(0.75, 1.05, (x, y * (W / 2 - 0.15), 1.4), 'rim', seg=12, bev=0.1, rot=(90, 0, 0))
            cyl(0.25, 1.1, (x, y * (W / 2 - 0.12), 1.4), 'chrome', seg=8, bev=0.04, rot=(90, 0, 0))
    done("Bus_%d" % var)

# ---------------- HOUSE (≈19.4 x 15.2 x 18.5) ----------------
def house(var):
    W, D = 15.0, 12.0
    wall, roof, roof2 = {1: ('cream', 'roof_red', 'roof_red2'), 2: ('wall_yellow', 'roof_blue', 'roof_blue2'), 3: ('wall_pink', 'roof_teal', 'roof_teal2')}[var]
    box((W + 1.2, D + 1.2, 1.0), (0, 0, 0.5), 'stone', 0.18)                       # base
    for i in range(7): box((2.1, 0.25, 0.9), (-6.6 + i * 2.2, -D / 2 - 0.62, 0.5), 'stone2', 0.08)  # base blocks
    box((W, D, 5.0), (0, 0, 3.5), wall, 0.2)
    box((W + 0.5, D + 0.5, 0.6), (0, 0, 6.2), 'trim', 0.15)                        # floor band
    box((W - 0.4, D - 0.4, 4.6), (0, 0, 8.8), wall, 0.2)
    for x in (-W / 2, W / 2):
        for z in range(4): box((0.9, 0.6, 0.9), (x, -D / 2, 1.6 + z * 1.15), 'trim', 0.1)     # quoins
    # door
    box((2.8, 0.6, 3.9), (0, -D / 2 - 0.05, 2.95), 'trim', 0.18)
    box((2.1, 0.5, 3.3), (0, -D / 2 - 0.25, 2.75), 'door', 0.1)
    for x in (-0.5, 0.5): box((0.75, 0.3, 2.9), (x, -D / 2 - 0.42, 2.7), 'wood2', 0.06)
    cyl(0.16, 0.2, (0.65, -D / 2 - 0.6, 2.7), 'gold', seg=10, bev=0.04, rot=(90, 0, 0))
    for i in range(2): box((3.4 - i * 0.5, 1.0, 0.35), (0, -D / 2 - 1.0 + i * 0.4, 1.17 + i * 0.35), 'cream2', 0.08)  # steps
    for x in (-4.6, 4.6): window(x, 3.6, 2.0, 2.2, -D / 2, 'white')
    for x in (-4.0, 0.0, 4.0): window(x, 8.8, 2.0, 2.2, -D / 2 + 0.2, 'white')
    for x in (-4.0, 4.0):     # flower boxes under the upper windows
        box((2.8, 0.9, 0.6), (x, -D / 2 - 0.25, 7.25), 'wood', 0.1)
        for k in range(3): blob(0.32, (x - 0.8 + k * 0.8, -D / 2 - 0.3, 7.65), 'leaf', sq=(1, 1, .8), seed=k)
        for k in range(2): blob(0.2, (x - 0.4 + k * 0.8, -D / 2 - 0.55, 7.85), 'petal_y' if var != 3 else 'petal_w', sq=(1, 1, .7), seed=k + 5)
    for side in (-1, 1):       # side + back windows
        for z in (3.6, 8.8): window(side * W / 2, z, 0.0001, 0.0001, 0, sill=False) if False else None
    for z in (3.6, 8.8):
        for y in (-2.5, 2.5):
            for s in (-1, 1):
                box((0.3, 1.8, 2.0), (s * (W / 2 + 0.05), y, z), 'white', 0.06); box((0.35, 1.4, 1.6), (s * (W / 2 + 0.1), y, z), 'glass', 0.05)
        for x in (-4, 4):
            box((1.8, 0.3, 2.0), (x, D / 2 + 0.05, z), 'white', 0.06); box((1.4, 0.35, 1.6), (x, D / 2 + 0.1, z), 'glass', 0.05)
    for x in (-5.4, 5.4): blob(1.05, (x, -D / 2 - 1.0, 1.7), 'leaf', sq=(1.2, 0.9, 0.9), seed=int(x))   # bushes
    top = 11.1
    if var == 1:   # red gable with a round attic window
        gable(W - 0.4, D - 0.4, 5.6, (0, 0, top), roof, over=0.7, th=0.55)
        for i in range(3): gable(W - 0.4, D - 0.4, 5.6, (0, 0, top + 0.02), roof2, over=0.7 - 0.0, th=0.08) if False else None
        poly([(-W / 2 + 0.3, -D / 2 + 0.3, 0), (W / 2 - 0.3, -D / 2 + 0.3, 0), (0, -D / 2 + 0.3, 0)], [], 'cream', (0, 0, top)) if False else None
        # gable end walls (front and back triangles)
        for yy in (-D / 2 + 0.2, D / 2 - 0.2):
            poly([(-W / 2 + 0.2, yy - .2, 0), (W / 2 - 0.2, yy - .2, 0), (0, yy - .2, 0), (-W / 2 + 0.2, yy + .2, 0), (W / 2 - 0.2, yy + .2, 0)], [], wall) if False else None
        # roof ridge runs along y for a front-facing gable: rebuild as along-y
        PARTS[-1].rotation_euler = (0, 0, 0)
        for o in PARTS[-2:]:
            o.data.transform(Matrix.Translation((0, 0, -top)) ); o.data.transform(Matrix.Rotation(math.radians(90), 4, 'Z')); o.data.transform(Matrix.Translation((0, 0, top)))
        tri = [(-D / 2, 0, 0), (D / 2, 0, 0), (0, 0, 5.4)]
        for yy in (-W / 2 + 0.6, ):
            pass
        # front gable triangle wall
        v = [(-W / 2 + 0.2, -D / 2 + 0.2, top), (W / 2 - 0.2, -D / 2 + 0.2, top), (0, -D / 2 + 0.2, top + 5.3),
             (-W / 2 + 0.2, D / 2 - 0.2, top), (W / 2 - 0.2, D / 2 - 0.2, top), (0, D / 2 - 0.2, top + 5.3)]
        poly(v, [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], wall, bev=0.05)
        cyl(1.25, 0.5, (0, -D / 2 - 0.05, top + 2.1), 'wood', seg=20, bev=0.08, rot=(90, 0, 0))
        cyl(0.95, 0.55, (0, -D / 2 - 0.1, top + 2.1), 'glass', seg=20, bev=0.05, rot=(90, 0, 0))
        box((1.9, 0.6, 0.16), (0, -D / 2 - 0.12, top + 2.1), 'wood', 0.03); box((0.16, 0.6, 1.9), (0, -D / 2 - 0.12, top + 2.1), 'wood', 0.03)
        for i in range(4):   # tile rows
            pass
    elif var == 2:  # blue hip roof, chimney, balcony
        hip(W - 0.4, D - 0.4, 4.6, (0, 0, top), roof, over=0.8, top=0.2)
        box((1.8, 1.8, 3.4), (4.0, 2.0, top + 3.6), 'wall_brick', 0.12); box((2.2, 2.2, 0.5), (4.0, 2.0, top + 5.4), 'cream', 0.12)
        box((1.2, 1.2, 0.3), (4.0, 2.0, top + 5.7), 'black', 0.05)
        box((W - 3.0, 2.2, 0.4), (0, -D / 2 - 1.0, 6.4), 'wood', 0.1)         # balcony floor
        box((W - 3.0, 0.3, 0.3), (0, -D / 2 - 2.0, 7.85), 'wood2', 0.08)       # rail
        for i in range(13): box((0.22, 0.22, 1.3), (-5.4 + i * 0.9, -D / 2 - 2.0, 7.15), 'wood', 0.04)
        for x in (-5.8, 5.8): box((0.5, 0.5, 2.0), (x, -D / 2 - 1.0, 5.3), 'wood2', 0.1)  # brackets
    else:           # teal flat roof with parapet + water tower (concept middle)
        box((W + 0.6, D + 0.6, 1.0), (0, 0, top + 0.5), roof, 0.2)
        box((W - 1.2, D - 1.2, 0.5), (0, 0, top + 0.9), 'roof_teal2', 0.1)
        for i in range(6): box((2.4, 0.3, 0.9), (-6.0 + i * 2.4, -D / 2 - 0.4, top + 0.5), 'roof_teal2', 0.08)
        cyl(1.7, 2.6, (3.0, 1.5, top + 4.6), 'tank', seg=10, bev=0.15); cyl(1.9, 0.5, (3.0, 1.5, top + 6.1), 'grey2', seg=10, r2=0.4, bev=0.05)
        for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)): box((0.25, 0.25, 2.4), (3.0 + dx * 1.1, 1.5 + dy * 1.1, top + 2.3), 'grey2', 0.05)
        box((2.4, 0.2, 0.2), (3.0, 0.4, top + 2.4), 'grey2', 0.04, rot=(0, 30, 0)); box((2.4, 0.2, 0.2), (3.0, 2.6, top + 2.4), 'grey2', 0.04, rot=(0, -30, 0))
        box((3.6, 1.0, 0.8), (-3.0, -D / 2 - 0.5, 4.9), 'awn_red', 0.12, rot=(-25, 0, 0))   # small striped awning over door side
        for i in range(4): box((0.45, 1.02, 0.82), (-4.35 + i * 0.9, -D / 2 - 0.5, 4.9), 'awn_white', 0.1, rot=(-25, 0, 0))
    done("House_%d" % var)

# ---------------- SHOP ROW (43 x 20 x 17.2): 3 shops ----------------
def shoprow(var):
    W, D = 42.0, 15.0
    walls = {1: ['wall_mint', 'wall_yellow', 'wall_sky'], 2: ['wall_pink', 'cream', 'wall_mint'], 3: ['wall_brick', 'wall_sky', 'wall_yellow']}[var]
    awn = {1: ['awn_red', 'awn_green', 'awn_blue'], 2: ['awn_blue', 'awn_red', 'awn_yellow'], 3: ['awn_green', 'awn_yellow', 'awn_red']}[var]
    box((W + 1.0, D + 1.0, 0.8), (0, 0, 0.4), 'concrete', 0.15)
    for k in range(3):
        cx = -14 + k * 14; h = (13.0, 15.0, 12.0)[(k + var) % 3]
        box((13.6, D, h), (cx, 0, 0.8 + h / 2), walls[k], 0.2)
        box((14.2, D + 0.6, 0.9), (cx, 0, 0.8 + h + 0.45), 'trim', 0.18)      # cornice
        rc = ['roof_teal', 'roof_red', 'roof_blue'][(k + var) % 3]
        box((12.6, D - 1.4, 0.4), (cx, 0, 0.8 + h + 1.0), rc, 0.1)            # coloured roof deck seen by giants
        for gx in (-4.0, 0.0, 4.0): box((0.25, D - 1.6, 0.12), (cx + gx, 0, 0.8 + h + 1.22), rc.replace('roof_', 'roof_') + '2' if rc + '2' in PAL else 'grey2', 0.0)
        box((1.4, 1.4, 0.9), (cx - 4.5, 3.5, 0.8 + h + 1.6), 'grey', 0.12); cyl(0.35, 0.8, (cx - 4.5, -3.0, 0.8 + h + 1.6), 'grey2', seg=8, bev=0.05)
        for i in range(5): box((2.5, 0.4, 0.5), (cx - 5.2 + i * 2.6, -D / 2 - 0.25, 0.8 + h + 1.1), 'trim', 0.1)
        # shop window + door
        box((8.0, 0.5, 4.6), (cx - 2.2, -D / 2 - 0.05, 3.6), 'white', 0.15); box((7.4, 0.55, 4.0), (cx - 2.2, -D / 2 - 0.1, 3.6), 'glass', 0.1)
        box((0.25, 0.6, 4.0), (cx - 2.2, -D / 2 - 0.15, 3.6), 'white', 0.04)
        box((1.0, 0.6, 3.0), (cx - 4.0, -D / 2 - 0.18, 3.7), 'glass2', 0.04, rot=(0, 18, 0))
        box((3.0, 0.5, 4.8), (cx + 4.4, -D / 2 - 0.05, 3.2), 'trim', 0.15); box((2.4, 0.5, 4.2), (cx + 4.4, -D / 2 - 0.2, 3.0), 'door', 0.1)
        box((1.6, 0.4, 1.8), (cx + 4.4, -D / 2 - 0.4, 3.6), 'glass', 0.06)
        cyl(0.15, 0.2, (cx + 5.2, -D / 2 - 0.5, 2.8), 'gold', seg=8, bev=0.04, rot=(90, 0, 0))
        box((8.8, 0.8, 0.5), (cx - 2.2, -D / 2 - 0.4, 1.1), walls[k], 0.12)          # planter ledge
        for j in range(4): blob(0.55, (cx - 5.4 + j * 2.1, -D / 2 - 0.6, 1.6), 'leaf', sq=(1.2, 0.9, 0.8), seed=j + k * 5)
        # striped awning
        for s in range(8):
            box((1.15, 3.4, 0.4), (cx - 6.4 + s * 1.15 + 0.57, -D / 2 - 1.6, 6.5), awn[k] if s % 2 == 0 else 'awn_white', 0.08, rot=(-24, 0, 0))
        for s in range(8):
            box((1.15, 0.35, 0.9), (cx - 6.4 + s * 1.15 + 0.57, -D / 2 - 3.2, 5.75), awn[k] if s % 2 == 0 else 'awn_white', 0.1)
        # sign board (no text), with a little icon shape
        box((7.0, 0.5, 1.6), (cx, -D / 2 - 0.1, 8.4), 'sign', 0.2); box((7.4, 0.4, 2.0), (cx, -D / 2 + 0.05, 8.4), awn[k], 0.2)
        icon = ['red', 'orange', 'violet'][k]
        if k == 0: blob(0.55, (cx - 2.4, -D / 2 - 0.45, 8.4), 'red', sq=(1, .4, 1), seed=3)          # apple
        elif k == 1: cyl(0.6, 0.3, (cx - 2.4, -D / 2 - 0.4, 8.4), 'yellow2', seg=12, bev=0.08, rot=(90, 0, 0))  # coin
        else: box((0.9, 0.3, 0.9), (cx - 2.4, -D / 2 - 0.4, 8.4), 'violet', 0.15, rot=(0, 45, 0))  # gem
        for b in range(3): box((0.6 + b * 0.25, 0.3, 0.32), (cx + 0.3 + b * 0.0, -D / 2 - 0.4, 8.85 - b * 0.45), 'grey2', 0.1)  # fake text bars
        # upper windows
        for x in (-3.5, 3.5):
            if 0.8 + h - 2.5 > 10.5: window(cx + x, 0.8 + h - 2.6, 2.2, 2.2, -D / 2, 'white')
        if (k + var) % 3 == 1:   # roof unit
            box((3.0, 3.0, 1.6), (cx + 2, 2, 0.8 + h + 1.7), 'grey', 0.15); cyl(0.9, 0.3, (cx + 2, 2, 0.8 + h + 2.6), 'grey2', seg=12, bev=0.05)
    done("ShopRow_%d" % var)

# ---------------- TOWER (23 x 23 x 75.7) ----------------
def tower(var):
    S = 21.0; H = 70.0
    wall, wall2, acc = {1: ('concrete', 'concrete2', 'roof_blue'), 2: ('wall_sky', 'blue2', 'white'), 3: ('cream', 'cream2', 'roof_red')}[var]
    box((S + 2, S + 2, 1.2), (0, 0, 0.6), 'stone2', 0.2)
    box((S, S, 6.0), (0, 0, 4.2), acc if var != 2 else 'blue2', 0.25)                  # lobby
    box((10, 0.8, 5.0), (0, -S / 2 - 0.1, 3.9), 'white', 0.15); box((9, 0.9, 4.4), (0, -S / 2 - 0.2, 3.8), 'glass', 0.1)
    box((0.3, 1.0, 4.4), (0, -S / 2 - 0.3, 3.8), 'white', 0.04)
    box((12, 3.0, 0.5), (0, -S / 2 - 1.4, 6.8), 'white', 0.15)                   # canopy
    box((S - 1.0, S - 1.0, H - 7.0), (0, 0, 7.2 + (H - 7.0) / 2), wall, 0.3)
    floors = 10; fh = (H - 8.5) / floors
    for f in range(floors):
        z = 8.8 + f * fh + fh / 2
        box((S - 0.2, S - 0.2, 0.5), (0, 0, z - fh / 2 + 0.1), wall2, 0.12)             # floor lines
        for side in range(4):
            for i in range(4):
                o = -7.5 + i * 5.0
                if side == 0: p, r = (o, -S / 2 + 0.4, z), 0
                elif side == 1: p, r = (S / 2 - 0.4, o, z), 90
                elif side == 2: p, r = (-o, S / 2 - 0.4, z), 180
                else: p, r = (-S / 2 + 0.4, -o, z), 270
                bpy.ops.mesh.primitive_cube_add(size=1)
                fr = bpy.context.object; fr.scale = (3.2, 0.5, 3.4); _place(fr, (0, 0, 0), (0, 0, r)); fr.location = p; _finish(fr, 'white', 0.08, 1)
                bpy.ops.mesh.primitive_cube_add(size=1)
                gl = bpy.context.object; gl.scale = (2.7, 0.55, 2.9); _place(gl, (0, 0, 0), (0, 0, r))
                off = Vector((0, -0.08, 0)); off.rotate(Euler((0, 0, math.radians(r)))); gl.location = Vector(p) + off
                _finish(gl, 'glass' if (f + i + side) % 5 else 'yellow3', 0)
        if var == 2 and f % 2 == 0:
            box((S + 0.8, 1.6, 0.35), (0, -S / 2 - 0.5, z - fh / 2 + 0.3), 'white', 0.1)   # balconies front
    top = 7.2 + H - 7.0
    box((S + 0.8, S + 0.8, 1.2), (0, 0, top + 0.5), acc, 0.25)
    box((S - 2, S - 2, 0.6), (0, 0, top + 1.2), wall2, 0.1)
    if var == 1:
        cyl(2.6, 4.0, (4, 4, top + 5.2), 'tank', seg=12, bev=0.2); cyl(2.9, 0.8, (4, 4, top + 7.6), 'grey2', seg=12, r2=0.6, bev=0.08)
        for dx, dy in ((-1, -1), (1, -1), (1, 1), (-1, 1)): box((0.4, 0.4, 3.0), (4 + dx * 1.8, 4 + dy * 1.8, top + 2.7), 'grey2', 0.08)
    elif var == 2:
        cyl(0.25, 6.0, (-5, -5, top + 4.5), 'grey2', seg=8, bev=0.04); blob(0.6, (-5, -5, top + 7.8), 'red', sq=(1, 1, 1), seed=2)
        box((6, 6, 2.5), (4, 3, top + 2.6), 'grey', 0.2)
    else:
        box((9, 9, 3.0), (0, 0, top + 2.8), acc, 0.25); hip(9, 9, 2.6, (0, 0, top + 4.3), 'roof_red2', over=0.5, top=0.15)
    done("Tower_%d" % var)

B = {'Flower': bed, 'Mailbox': mailbox, 'Bin': bin_, 'Bike': bike, 'Car': car, 'Bus': bus, 'House': house, 'ShopRow': shoprow, 'Tower': tower}
for k, fn in B.items():
    if want(k):
        for v in (1, 2, 3): fn(v)
info = {}
for o in made:
    me = o.data; me.calc_loop_triangles()
    info[o.name] = {"tris": len(me.loop_triangles), "dim": [round(d, 2) for d in o.dimensions]}
import json; json.dump(info, open(os.path.join(OUT, "info.json"), "w"), indent=1)
palette_png(os.path.join(OUT, "props_palette.png"))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "props.blend"))
for k, v in info.items(): print(k, v)
