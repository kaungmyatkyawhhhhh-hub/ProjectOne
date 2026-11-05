"""Step 4 of the second import job (Murcielagos, Urus Performante, California, 458 Spider and Speciale): run ONCE
after the owner's Import 3D. New cars, stats, cluster styles and spots; the old LP640's and California's badge
covers, wheels and needles go, their models are in ServerStorage.OldCarModels.

    python tools/lambo/step4_nov6.py
"""

import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "src")


def edit(path, pairs):
    p = os.path.join(ROOT, path)
    s = open(p, encoding="utf-8", newline="").read()
    crlf = "\r\n" in s
    s = s.replace("\r\n", "\n")
    for a, b in pairs:
        assert a in s, a[:70]
        s = s.replace(a, b, 1)
    if crlf:
        s = s.replace("\n", "\r\n")
    open(p, "w", encoding="utf-8", newline="").write(s)


BLACK = "Color3.fromRGB(16, 16, 18)"
NEW = [
    ("lambrini_lp670", "Enfurecido Murcielago LP670-4 SV", "Supercar", 212, 3.2, 0.9, 2400000, (236, 74, 16), 64.5),
    ("lambrini_urusp", "Enfurecido Urus Performante", "SUV", 190, 3.2, 0.74, 1900000, (226, 190, 96), 57.5),
    ("ferrara_458spider", "Rosso Rampante 458 Spider", "Supercar", 199, 3.3, 0.89, 1000000, (232, 196, 60), 52.2),
    ("ferrara_458speciale", "Rosso Rampante 458 Speciale", "Supercar", 202, 3.0, 0.94, 1250000, (226, 40, 22), 52.5),
]
lines = ""
for cid, name, cls, top, z60, hand, price, col, order in NEW:
    lines += '\t{ Id = "%s", Name = "%s", Class = "%s", Tier = "High", TopSpeed = %d, ZeroToSixty = %s, Handling = %s, Price = %d, Color = Color3.fromRGB(%d, %d, %d), Accent = %s, Order = %s },\n' % (
        cid, name, cls, top, z60, hand, price, *col, BLACK, order)

edit("shared/Cars.lua", [
    ('Name = "Enfurecido Murcielago LP640"', 'Name = "Enfurecido Murcielago LP650-4 Roadster"'),
    ('\t-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of th', '\t-- the second import job (2026-11-06): the LP670-4 SV, the Urus Performante, the 458 Spider and Speciale\n' + lines + '\t-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of th'),
    ('\t{ Name = "ROSSO RAMPANTE 599", Ids = { "ferrara_599" } },\n', '\t{ Name = "ROSSO RAMPANTE 599", Ids = { "ferrara_599" } },\n\t{ Name = "ROSSO RAMPANTE 458", Ids = { "ferrara_458spider", "ferrara_458speciale" } },\n'),
    ('{ Name = "ENFURECIDO MURCIELAGO", Ids = { "lambrini_lp640" } },', '{ Name = "ENFURECIDO MURCIELAGO", Ids = { "lambrini_lp640", "lambrini_lp670" } },'),
    ('{ Name = "ENFURECIDO URUS", Ids = { "lambrini_urus" } },', '{ Name = "ENFURECIDO URUS", Ids = { "lambrini_urus", "lambrini_urusp" } },'),
])
edit("shared/CarBuilder.lua", [
    ('\tferrara_458 = 2.65, ', '\tferrara_458 = 2.65, ferrara_458spider = 2.65, ferrara_458speciale = 2.65, lambrini_lp670 = 2.665, lambrini_urusp = 3.003, '),
])
edit("shared/CarStats.lua", [
    ('\tlambrini_urus = true, bugotti_veyron = true,', '\tlambrini_urus = true, lambrini_urusp = true, lambrini_lp670 = true, bugotti_veyron = true,'),
    ('lambrini_urus = 2200,', 'lambrini_urus = 2200, lambrini_urusp = 2150, lambrini_lp670 = 1565, ferrara_458spider = 1505, ferrara_458speciale = 1395,'),
    ('lambrini_urus = 641,', 'lambrini_urus = 641, lambrini_urusp = 666, lambrini_lp670 = 670, ferrara_458spider = 562, ferrara_458speciale = 597,'),
    ('lambrini_urus = 6.8,', 'lambrini_urus = 6.8, lambrini_urusp = 6.8, lambrini_lp670 = 8.0, ferrara_458spider = 9.0, ferrara_458speciale = 9.0,'),
])
edit("shared/Config.lua", [
    ('lambrini_lp640 = true, lambrini_lp700 = true,', 'lambrini_lp640 = true, lambrini_lp670 = true, lambrini_urusp = true, lambrini_lp700 = true,'),
])
edit("client/Driving.lua", [
    ('\t\t\tlambrini_lp640 = { 0, 0, 0.9 }, -- the LP640 design inside its own hood\n', ''),
])
edit("client/CarFinish.lua", [
    ('\tlambrini_revuelto = true,\n} :: { [string]: boolean }', '\tlambrini_revuelto = true,\n\tlambrini_lp640 = true,\n\tlambrini_lp670 = true,\n\tlambrini_urusp = true,\n\tferrara_california = true,\n\tferrara_458spider = true,\n\tferrara_458speciale = true,\n} :: { [string]: boolean }'),
])
# the old models' badge covers don't fit the new ones
p = os.path.join(ROOT, "client", "BrandMarks.lua")
s = open(p, encoding="utf-8", newline="").read()
crlf = "\r\n" in s
s = s.replace("\r\n", "\n")
for cid in ("ferrara_california", "lambrini_lp640"):
    m = re.search(r"\n\t" + cid + r" = \{\n.*?\n\t\},", s, re.S)
    assert m, cid
    s = s[: m.start()] + s[m.end() :]
if crlf:
    s = s.replace("\n", "\r\n")
open(p, "w", encoding="utf-8", newline="").write(s)

rects = """	-- the second import job (2026-11-06): the screens behind each model's frame (tools/lambo/panel_preview.py)
	lambrini_lp640 = { at = Vector3.new(0.0065, -0.0464, -0.3043), face = Vector3.new(0, 0.245, 0.97), w = 0.3578, h = 0.1519 },
	lambrini_lp670 = { at = Vector3.new(0.0065, -0.0464, -0.3041), face = Vector3.new(0, 0.245, 0.97), w = 0.3578, h = 0.1519 },
	lambrini_urusp = { at = Vector3.new(0, 0.0163, -0.2308), face = Vector3.new(0, 0.107, 0.994), w = 0.3472, h = 0.0967 },
	ferrara_california = { at = Vector3.new(0.0163, 0.033, -0.3044), face = Vector3.new(0, 0.145, 0.989), w = 0.4114, h = 0.1627 },
	ferrara_458spider = { at = Vector3.new(0.001, 0.0276, -0.2746), face = Vector3.new(0, 0.16, 0.987), w = 0.3822, h = 0.1449 },
	ferrara_458speciale = { at = Vector3.new(0.0009, 0.0237, -0.2499), face = Vector3.new(0, 0.16, 0.987), w = 0.3822, h = 0.1449 },
"""
edit("client/CarSkin.lua", [
    ('\tlambrini_urus = "Urus",\n', '\tlambrini_urus = "Urus",\n\tlambrini_urusp = "LiveUrus", -- the Performante\'s screen, from the owner\'s photo\n'),
    ('\tferrara_california = "FerrariCalifornia",\n', '\tferrara_california = "LiveCalifornia", -- from the owner\'s photo\n\tferrara_458spider = "Live458", -- from the owner\'s photo, shared in the line\n\tferrara_458speciale = "Live458",\n'),
    ('\tlambrini_lp640 = "MurcielagoLP640", -- the 2026-10-18 model\n', '\tlambrini_lp640 = "LiveMurcielago", -- the SV\'s dials, drawn sharp, without the SV mark (owner, 2026-11-05)\n\tlambrini_lp670 = "LiveMurcielagoSV",\n'),
    ('\tlambrini_lp640 = "LamboRound",\n', ''),
    ('ferrara_f430 = "FerrariF430", ferrara_599 = "FerrariF430", ferrara_california = "FerrariF430",', 'ferrara_f430 = "FerrariF430", ferrara_599 = "FerrariF430",'),
    ('\t-- the Lamborghini imports: the Revuelto\'s own screen, the EVO\'s in all four Huracans\n', rects + '\t-- the Lamborghini imports: the Revuelto\'s own screen, the EVO\'s in all four Huracans\n'),
])
print("ok")
