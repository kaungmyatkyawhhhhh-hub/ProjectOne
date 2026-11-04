"""Step 4 of the Lamborghini imports: run ONCE, after the owner's Import 3D, when the nine new models are
in ReplicatedStorage.CarModels (it takes out the old LP700 / LP750 / LP570 cabin fixes, so run earlier it
would break the old models). New cars, stats, cluster spots, live needles.

    python tools/lambo/step4_patch.py
"""

import os

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


def cut(s, start, end):
    """the text from `start` up to (not with) `end`"""
    i = s.index(start)
    j = s.index(end, i)
    return s[i:j]


# ------------------------------------------------------------------ the cars
BLACK = "Color3.fromRGB(16, 16, 18)"
NEW = [
    ('lambrini_lp560', 'Enfurecido Gallardo LP560-4 Spyder', 'Supercar', 201, 3.9, 0.85, 680000, (236, 214, 40), 47.5),
    ('lambrini_huracan', 'Enfurecido Huracan EVO', 'Supercar', 202, 2.9, 0.92, 1300000, (226, 74, 24), 85),
    ('lambrini_performante', 'Enfurecido Huracan Performante Spyder', 'Supercar', 202, 3.1, 0.93, 1550000, (196, 18, 28), 86),
    ('lambrini_sto', 'Enfurecido Huracan STO', 'Supercar', 193, 3.0, 0.95, 1800000, (190, 26, 16), 87),
    ('lambrini_sterrato', 'Enfurecido Huracan Sterrato', 'Supercar', 162, 3.4, 0.8, 1450000, (84, 118, 62), 88),
    ('lambrini_revuelto', 'Enfurecido Revuelto', 'Hypercar', 217, 2.5, 0.96, 6000000, (232, 234, 238), 89),
]
lines = ""
for cid, name, cls, top, z60, hand, price, col, order in NEW:
    lines += '\t{ Id = "%s", Name = "%s", Class = "%s", Tier = "High", TopSpeed = %d, ZeroToSixty = %s, Handling = %s, Price = %d, Color = Color3.fromRGB(%d, %d, %d), Accent = %s, Order = %s },\n' % (
        cid, name, cls, top, z60, hand, price, *col, BLACK, order)
edit("shared/Cars.lua", [
    ('\t-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of th', '\t-- the Lamborghini imports (2026-11-04): the Gallardo Spyder, the Huracan line, the Revuelto\n' + lines + '\t-- owner (2026-11-02): the SVJ and the SVJ 63 roadster, the top of th'),
    ('{ Name = "ENFURECIDO GALLARDO", Ids = { "lambrini_lp570" } },', '{ Name = "ENFURECIDO GALLARDO", Ids = { "lambrini_lp560", "lambrini_lp570" } },\n\t{ Name = "ENFURECIDO HURACAN", Ids = { "lambrini_huracan", "lambrini_performante", "lambrini_sto", "lambrini_sterrato" } },'),
    ('{ Name = "ENFURECIDO AVENTADOR", Ids = { "lambrini_lp700", "lambrini_lp750", "lambrini_svj", "lambrini_svj63" } },', '{ Name = "ENFURECIDO AVENTADOR", Ids = { "lambrini_lp700", "lambrini_lp750", "lambrini_svj", "lambrini_svj63" } },\n\t{ Name = "ENFURECIDO REVUELTO", Ids = { "lambrini_revuelto" } },'),
])
edit("shared/CarBuilder.lua", [
    ('lambrini_lp570 = 2.56,', 'lambrini_lp570 = 2.56, lambrini_lp560 = 2.56, lambrini_huracan = 2.62, lambrini_performante = 2.62, lambrini_sto = 2.62, lambrini_sterrato = 2.63, lambrini_revuelto = 2.78,'),
])
edit("shared/CarStats.lua", [
    ('nisun_gtr = true, audy_r8 = true, lambrini_lp640 = true,', 'nisun_gtr = true, audy_r8 = true, lambrini_lp560 = true, lambrini_huracan = true, lambrini_performante = true, lambrini_sterrato = true, lambrini_revuelto = true, lambrini_lp640 = true,'),
    ('bentz_sl65bs = 1870, lambrini_lp570 = 1340,', 'bentz_sl65bs = 1870, lambrini_lp570 = 1340, lambrini_lp560 = 1550, lambrini_huracan = 1422, lambrini_performante = 1507, lambrini_sto = 1339, lambrini_sterrato = 1470, lambrini_revuelto = 1772,'),
    ('bentz_sl65bs = 661, lambrini_lp570 = 562,', 'bentz_sl65bs = 661, lambrini_lp570 = 562, lambrini_lp560 = 552, lambrini_huracan = 631, lambrini_performante = 631, lambrini_sto = 631, lambrini_sterrato = 602, lambrini_revuelto = 1001,'),
    ('lambrini_lp570 = 8.5, lambrini_lp640 = 8.0,', 'lambrini_lp570 = 8.5, lambrini_lp560 = 8.0, lambrini_huracan = 8.0, lambrini_performante = 8.0, lambrini_sto = 8.0, lambrini_sterrato = 8.0, lambrini_revuelto = 9.5, lambrini_lp640 = 8.0,'),
])
edit("shared/Config.lua", [
    ('lambrini_lp570 = true, lambrini_lp640 = true, lambrini_lp700 = true,', 'lambrini_lp570 = true, lambrini_lp560 = true, lambrini_huracan = true, lambrini_performante = true, lambrini_sterrato = true, lambrini_revuelto = true, lambrini_lp640 = true, lambrini_lp700 = true,'),
])

# ------------------------------------------------------------------ cockpits
p = os.path.join(ROOT, "client", "CarSkin.lua")
s = open(p, encoding="utf-8", newline="").read().replace("\r\n", "\n")
donor = cut(s, "\t-- owner (2026-10-17): the LP700's own cabin looks off and blocky", "\tlambrini_lp700 = { from = \"lambrini_lp750\", rear = 1.8 },\n") + "\tlambrini_lp700 = { from = \"lambrini_lp750\", rear = 1.8 },\n"
rect700 = cut(s, "\t-- the LP700 in the LP750's cabin: the LP750's whole screen", "\t-- the GT3 in the 718 cabin")
rect750 = cut(s, "\t-- the LP750 in its own cabin: the same screen", "\t-- the SVJ and SVJ 63 (owner, 2026-11-03")
recolour = cut(s, "\tlambrini_lp750 = {\n\t\t[\"133052779464309\"]", "} :: { [string]: { [string]: CabinLook } }")
needles = '''	-- the Lamborghini imports (2026-11-04): the needles the models only had painted (their pictures are
	-- clean now, tools/lambo/gallardo_dials.py, cluster_art.py --live), with the speed and the gear live
	lambrini_lp700 = {
		{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0024, 0.0389, -0.2402), face = Vector3.new(0, 0.108, 0.9942), length = 0.0456, scale = "0:180.0,3000:270.0,6000:360.0,9000:450.0" },
		{ kind = "digits", unit = "kmh", at = Vector3.new(0.0376, 0.028, -0.239), face = Vector3.new(0, 0.108, 0.9942), length = 0.0224, scale = "", bg = Color3.fromRGB(236, 240, 244), fg = Color3.fromRGB(14, 14, 16), aspect = 0.385, font = "Sarpanch" },
		{ kind = "gear", unit = "", at = Vector3.new(0.0124, 0.0132, -0.2374), face = Vector3.new(0, 0.108, 0.9942), length = 0.0086, scale = "", fg = Color3.fromRGB(232, 214, 32), aspect = 1.05, clear = true, font = "Sarpanch" },
	},
	lambrini_lp570 = {
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0831, 0.0228, -0.2408), face = Vector3.new(-0.0056, 0.5422, 0.8402), length = 0.0425, scale = "0:-129.7,1000:-103.2,2000:-76.6,3000:-52.1,4000:-27.5,5000:-3.6,6000:20.6,7000:46.0,8000:73.2,9000:99.5,10000:125.4" },
		{ kind = "speed", unit = "kmh", at = Vector3.new(0.0837, 0.0235, -0.2413), face = Vector3.new(-0.0415, 0.543, 0.8387), length = 0.0424, scale = "0:-130.0,40:-99.8,70:-77.1,100:-53.8,130:-30.5,160:-9.0,190:12.5,220:33.5,250:56.3,280:78.9,310:102.3,340:125.2" },
		{ kind = "gear", unit = "", at = Vector3.new(0.0009, -0.009, -0.2106), face = Vector3.new(0, 0.7421, 0.6703), length = 0.0586, scale = "", bg = Color3.fromRGB(22, 24, 28), fg = Color3.fromRGB(240, 240, 244), aspect = 0.17, font = "Sarpanch" },
	},
	lambrini_lp560 = { -- (the Superleggera's binnacle: tools/lambo/gallardo_dash.py)
		{ kind = "rpm", unit = "rpm", at = Vector3.new(-0.0833, 0.017, -0.251), face = Vector3.new(-0.0056, 0.5422, 0.8402), length = 0.0425, scale = "0:-129.7,1000:-103.2,2000:-76.6,3000:-52.1,4000:-27.5,5000:-3.6,6000:20.6,7000:46.0,8000:73.2,9000:99.5,10000:125.4" },
		{ kind = "speed", unit = "kmh", at = Vector3.new(0.0835, 0.0177, -0.2514), face = Vector3.new(-0.0415, 0.543, 0.8387), length = 0.0424, scale = "0:-130.0,40:-99.8,70:-77.1,100:-53.8,130:-30.5,160:-9.0,190:12.5,220:33.5,250:56.3,280:78.9,310:102.3,340:125.2" },
		{ kind = "gear", unit = "", at = Vector3.new(0.0008, -0.0148, -0.2208), face = Vector3.new(0, 0.7421, 0.6703), length = 0.0586, scale = "", bg = Color3.fromRGB(22, 24, 28), fg = Color3.fromRGB(240, 240, 244), aspect = 0.17, font = "Sarpanch" },
	},
'''
rects = '''	-- the LP750 on its 2026-11-04 model: the screen's middle window and both sides
	lambrini_lp750 = { at = Vector3.new(0.0022, 0.0434, -0.2271), face = Vector3.new(-0.002, 0.107, 0.994), w = 0.37, h = 0.1486 },
	-- the Lamborghini imports: the Revuelto's own screen, the EVO's in all four Huracans
	lambrini_revuelto = { at = Vector3.new(0, 0.0748, -0.201), face = Vector3.new(0, 0.081, 0.997), w = 0.2841, h = 0.1045 },
	lambrini_huracan = { at = Vector3.new(0.0006, 0.0395, -0.2386), face = Vector3.new(0, 0.407, 0.914), w = 0.283, h = 0.0977 },
	lambrini_performante = { at = Vector3.new(-0.0001, 0.0391, -0.2392), face = Vector3.new(0, 0.407, 0.914), w = 0.283, h = 0.0977 },
	lambrini_sto = { at = Vector3.new(0.0005, 0.0398, -0.233), face = Vector3.new(0, 0.407, 0.914), w = 0.283, h = 0.0977 },
	lambrini_sterrato = { at = Vector3.new(0.0004, 0.0379, -0.2385), face = Vector3.new(0, 0.407, 0.914), w = 0.283, h = 0.0977 },
'''
edit("client/CarSkin.lua", [
    ('\tlambrini_lp570 = "GallardoSL", -- the Superleggera\'s white dials\n', ''),
    ('\tlambrini_lp700 = "AventadorLP700", -- owner (2026-10-17): its own, copied from an LP700-4 video\n', ''),
    ('\tlambrini_svj = "AventadorSVJ",\n', '\tlambrini_huracan = "LiveHuracan", -- the EVO\'s screen, shared in the line (owner, 2026-11-04)\n\tlambrini_performante = "LiveHuracan",\n\tlambrini_sto = "LiveHuracan",\n\tlambrini_sterrato = "LiveHuracan",\n\tlambrini_revuelto = "LiveRevuelto",\n\tlambrini_svj = "AventadorSVJ",\n'),
    (rect700, ''),
    (rect750, rects),
    (donor, ''),
    (recolour, ''),
    ('\tlambrini_lp750 = { Body_Display = true },\n', ''),
    ('\tlambrini_lp700 = { back = 3.1, front = 4.4, top = 1.0, bottom = 3.2 },\n', ''),
    ('lambrini_lp570 = "LamboRound", lambrini_lp640 = "LamboRound",', 'lambrini_lp640 = "LamboRound",'),
    ('\t-- the Chiron family (owner, 2026-11-03): the 2016 Chiron\'s own screen', needles + '\t-- the Chiron family (owner, 2026-11-03): the 2016 Chiron\'s own screen'),
    ('\tbugotti_chiron = { { faceless = true, needle = Color3.fromRGB(225, 240, 255), needleW = 5 } },\n', '''	lambrini_lp700 = { { faceless = true, needle = Color3.fromRGB(235, 40, 46), needleW = 4 } },
	lambrini_lp570 = { { faceless = true, needle = Color3.fromRGB(238, 92, 40), needleW = 6, hubRing = Color3.fromRGB(58, 62, 68), hubR = 18 } },
	lambrini_lp560 = { { faceless = true, needle = Color3.fromRGB(238, 92, 40), needleW = 6, hubRing = Color3.fromRGB(58, 62, 68), hubR = 18 } },
	bugotti_chiron = { { faceless = true, needle = Color3.fromRGB(225, 240, 255), needleW = 5 } },
'''),
])
print("ok")
