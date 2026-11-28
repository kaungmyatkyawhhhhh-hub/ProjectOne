# YardKit2 props (ChatGPT R4 8.2 / Gemini 8.0 -> R5): remodelled sleigh, signature candy-cane barbell display,
# irregular snow drifts, one premium volumetric bow (reused on lamps), two gift-cluster variants, tree snow cap.
# Spliced into build_yardkit2.py between the kit helpers and the export tail.
PAL.update({"Burgundy": (120, 28, 40), "RedDark": (130, 20, 35)})

# 0 Sleigh v2: curved side panels, raised rear, curled front, continuous gold runners with struts, burgundy cushion, 5 gifts
o = at("Sleigh2", 0); P = "Sleigh2"
side = [(-3.3, 0.7), (2.4, 0.7), (3.1, 1.0), (3.5, 1.7), (3.5, 2.5), (3.15, 2.85), (2.8, 2.6), (2.7, 2.0), (2.0, 1.75),
        (0.2, 1.8), (-1.2, 2.2), (-2.2, 3.0), (-3.0, 3.4), (-3.4, 3.2)]
for y in (-1.45, 1.45):
    prism(P, "Red", side, 0.28, o + Vector((0, y, 0)))
box(P, "Red", o + Vector((-0.1, 0, 0.85)), (6.4, 2.9, 0.3))                       # floor
box(P, "Red", o + Vector((3.25, 0, 1.7)), (0.3, 2.9, 1.6), (0, -0.35, 0))           # front panel
box(P, "Red", o + Vector((-3.2, 0, 2.2)), (0.3, 2.9, 2.6), (0, 0.2, 0))             # back panel
# gold trim along the top edge of each side panel
top = [(3.5, 2.5), (3.15, 2.85), (2.8, 2.6), (2.7, 2.0), (2.0, 1.75), (0.2, 1.8), (-1.2, 2.2), (-2.2, 3.0), (-3.0, 3.4), (-3.4, 3.2)]
for y in (-1.6, 1.6):
    tube(P, ["Gold"], [(x, y, z + 0.06) for x, z in top], 0.1, 6)
# runners: continuous curve, curled front, with 3 struts each
run = [(-3.5, 0.15), (-2.0, 0.12), (0.0, 0.12), (2.0, 0.14), (3.2, 0.3), (3.9, 0.8), (4.1, 1.5), (3.8, 2.0), (3.4, 2.0)]
for y in (-1.25, 1.25):
    tube(P, ["Gold"], [(x, y, z) for x, z in run], 0.13, 6)
    for x in (-2.4, 0.0, 2.2):
        cyl(P, "Gold", o + Vector((x, y, 0.45)), 0.09, 0.62, 6)
        box(P, "Gold", o + Vector((x, y, 0.72)), (0.36, 0.22, 0.1))
# burgundy cushions (seat + backrest), bevelled
box(P, "Burgundy", o + Vector((0.6, 0, 1.25)), (1.9, 2.6, 0.5))
box(P, "Burgundy", o + Vector((-0.45, 0, 1.85)), (0.45, 2.6, 1.3), (0, 0.25, 0))
# gift load behind the seat: 5 boxes, different sizes
for (x, y, z, s, c, rc, yaw) in ((-1.9, -0.6, 1.0, 1.25, "Green", "Gold", 0.2), (-2.0, 0.65, 1.0, 1.0, "Blue", "White", -0.35),
                                 (-1.95, 0.0, 2.15, 0.85, "Gold", "Red", 0.5), (-2.75, -0.2, 1.0, 0.8, "White", "Red", 0.1),
                                 (-1.2, 0.95, 1.0, 0.6, "Red", "Gold", 0.7)):
    base = o + Vector((x, y, z + s / 2)); box(P, c, base, (s, s, s), (0, 0, yaw))
    box(P, rc, base, (s * 1.04, s * 0.2, s * 1.04), (0, 0, yaw)); box(P, rc, base, (s * 0.2, s * 1.04, s * 1.04), (0, 0, yaw))
# make the run/trim tubes local to the prop origin (tube() takes absolute points)
# (handled below by offsetting: tube points above are prop-local, so shift them now)
for k in ((P, "Gold"),):
    pass

# 1 Signature display: giant candy-cane barbell resting on a decorated rack (9 wide)
o = at("BarbellDisplay", 1); P = "BarbellDisplay"
box(P, "WoodDark", o + Vector((0, 0, 0.25)), (9.6, 3.2, 0.5))
box(P, "Snow", o + Vector((0, 0, 0.55)), (9.4, 3.0, 0.14))
for x in (-3.2, 3.2):
    for dy in (-0.9, 0.9):
        box(P, "Wood", o + Vector((x, dy * 0.55, 1.9)), (0.45, 0.45, 2.9), (dy * 0.33, 0, 0))
    box(P, "Gold", o + Vector((x, 0, 3.35)), (0.7, 0.7, 0.25))
    cyl(P, "Gold", o + Vector((x, 0, 3.45)), 0.55, 0.2, 8, rot=(math.pi / 2, 0, 0))
# striped bar
bar = [(-5.6 + 0.8 * i, 0, 3.95) for i in range(15)]
tube(P, ["Red", "White"], [tuple(o + Vector(b)) for b in bar], 0.26, 8)
# peppermint plates (8 wedges, red/white) + gold collars
for x in (-4.6, -4.0, 4.0, 4.6):
    r = 1.7 if abs(x) > 4.3 else 1.45
    for w in range(8):
        a0 = 2 * math.pi * w / 8; a1 = 2 * math.pi * (w + 1) / 8
        pts = [(0, 0), (r * math.cos(a0), r * math.sin(a0)), (r * math.cos(a1), r * math.sin(a1))]
        prism(P, "Red" if w % 2 else "White", [(px, pz) for px, pz in pts], 0.42, o + Vector((x, 0, 3.95)), (0, 0, math.pi / 2))
    cyl(P, "Gold", o + Vector((x + (0.32 if x > 0 else -0.32), 0, 3.95)), 0.38, 0.2, 8, rot=(0, math.pi / 2, 0))

# 2/3 snow drifts (irregular low mounds)
for i, (name, sx, sy, h) in enumerate((("DriftA", 3.0, 2.0, 0.8), ("DriftB", 2.4, 1.6, 0.6))):
    o = at(name, 2 + i)
    sphere(name, "Snow", o, 1.0, 9, 4, s=(sx, sy, h), jit=0.16, flat_bottom=0.0)
    sphere(name, "Snow", o + Vector((sx * 0.55, sy * 0.3, 0)), 1.0, 7, 4, s=(sx * 0.45, sy * 0.5, h * 0.7), jit=0.18, flat_bottom=0.0)

# 4 premium bow (1.4 wide): broad folded loops, knot, two tails
o = at("Bow", 4); P = "Bow"
for s_ in (-1, 1):
    loop = [(s_ * (0.12 + 0.55 * (1 - math.cos(a)) / 2), 0, 0.3 * math.sin(a)) for a in [2 * math.pi * k / 9 for k in range(10)]]
    tube(P, ["Red"], [tuple(o + Vector(p)) for p in loop], 0.17, 5)
    tube(P, ["RedDark"], [tuple(o + Vector(p)) for p in ((s_ * 0.08, 0.05, -0.05), (s_ * 0.25, 0.05, -0.5), (s_ * 0.38, 0.05, -0.85))], 0.12, 4)
sphere(P, "RedDark", o + Vector((0, -0.05, 0)), 0.2, 6, 3)

# 5/6 gift cluster variants
o = at("GiftsB", 5); P = "GiftsB"
for (x, y, s, c, rc, yaw, z) in ((0, 0, 1.9, "Green", "Red", 0.1, 0), (1.5, 0.6, 1.1, "Red", "Gold", -0.4, 0), (-1.3, 0.5, 0.9, "White", "Red", 0.5, 0), (0.2, 0.1, 0.9, "Gold", "Red", 0.8, 1.9)):
    base = o + Vector((x, y, z + s / 2)); box(P, c, base, (s, s * 0.8, s), (0, 0, yaw))
    box(P, rc, base, (s * 1.04, s * 0.18, s * 1.04), (0, 0, yaw)); box(P, rc, base, (s * 0.18, s * 0.84, s * 1.04), (0, 0, yaw))
o = at("GiftsC", 6); P = "GiftsC"
for (x, y, s, c, rc, yaw) in ((0, 0, 1.3, "Blue", "Gold", 0.3), (1.2, -0.3, 0.8, "Red", "White", -0.2), (-1.1, -0.2, 1.0, "Gold", "Green", 0.6), (0.4, 1.1, 0.7, "Green", "Gold", 0.9)):
    base = o + Vector((x, y, s / 2)); box(P, c, base, (s * 1.3, s, s * 0.8), (0, 0, yaw))
    box(P, rc, base, (s * 1.34, s * 0.18, s * 0.84), (0, 0, yaw))

# 7 tree snow cap (small faceted patch to sit on a tier edge)
o = at("TreeSnow", 7)
sphere("TreeSnow", "Snow", o, 1.0, 7, 4, s=(0.9, 0.6, 0.28), jit=0.2, flat_bottom=-0.05)
