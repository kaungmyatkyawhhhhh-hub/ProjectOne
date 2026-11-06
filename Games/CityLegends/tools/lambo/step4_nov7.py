"""Step 4 of the third import job (LFA, LFA Circuit, Maybach S-Class, Maybach GLS, Countach 5000): the code side.
Run once for each part: python tools/lambo/step4_nov7.py lfa | s680 | gls | countach
"""

import os
import re
import sys

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


def no_marks(cid):
    p = os.path.join(ROOT, "client", "BrandMarks.lua")
    s = open(p, encoding="utf-8", newline="").read()
    crlf = "\r\n" in s
    s = s.replace("\r\n", "\n")
    m = re.search(r"\n\t" + cid + r" = \{\n.*?\n\t\},", s, re.S)
    assert m, cid
    s = s[: m.start()] + s[m.end() :]
    if crlf:
        s = s.replace("\n", "\r\n")
    open(p, "w", encoding="utf-8", newline="").write(s)


def rect(line):
    edit("client/CarSkin.lua", [("\t-- the second import job (2026-11-06): the screens behind each model's frame", line + "\t-- the second import job (2026-11-06): the screens behind each model's frame")])


def finish(*ids):
    add = "".join("\t%s = true,\n" % i for i in ids)
    edit("client/CarFinish.lua", [("\tdearb_focus_rs = true,\n} :: { [string]: boolean }", "\tdearb_focus_rs = true,\n" + add + "} :: { [string]: boolean }")])


what = sys.argv[1]
if what == "lfa":
    edit("shared/Cars.lua", [
        ('Price = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 62 },\n',
         'Price = 3000000, Color = Color3.fromRGB(235, 236, 238), Accent = Color3.fromRGB(16, 16, 18), Order = 62 },\n'
         '\t{ Id = "lexis_lfa_circuit", Name = "Stealth-Apex V10 Halo Circuit", Class = "Hypercar", Tier = "High", TopSpeed = 202, ZeroToSixty = 3.5, Handling = 0.95, Price = 3600000, Color = Color3.fromRGB(240, 110, 20), Accent = Color3.fromRGB(16, 16, 18), Order = 62.5 },\n'),
        ('{ Name = "STEALTH-APEX V10 HALO", Ids = { "lexis_lfa" } },', '{ Name = "STEALTH-APEX V10 HALO", Ids = { "lexis_lfa", "lexis_lfa_circuit" } },'),
    ])
    edit("shared/CarBuilder.lua", [("lexis_lfa = 2.605,", "lexis_lfa = 2.605, lexis_lfa_circuit = 2.605,")])
    edit("shared/CarStats.lua", [
        ("lexis_lfa = 1480,", "lexis_lfa = 1480, lexis_lfa_circuit = 1450,"),
        ("lexis_lfa = 553,", "lexis_lfa = 553, lexis_lfa_circuit = 563,"),
        ("lexis_lfa = 9.0,", "lexis_lfa = 9.0, lexis_lfa_circuit = 9.0,"),
    ])
    edit("shared/Config.lua", [('\t"Dearborn C346 model by Ddiaz Design",\n', '\t"Dearborn C346 model by Ddiaz Design",\n\t"Stealth-Apex V10 Halo and Halo Circuit models by Ddiaz Design",\n')])
    edit("client/CarSkin.lua", [
        ('\tlexis_lfa = "LFAFitted", -- the ring sized to the model\'s own round pod\n', '\tlexis_lfa = "LiveLFA", -- from the owner\'s photo\n\tlexis_lfa_circuit = "LiveLFA",\n'),
        ('lexis_lfa = "LexusSport", lexis_lc500 = "LexusSport",', 'lexis_lc500 = "LexusSport",'),
        ("\tlexis_lfa = { 0, 0.075, 0, 1.42 }, -- the ring on the model's round pod (owner, 2026-10-24)\n", ""),
    ])
    rect('\t-- the third import job (2026-11-07): the owner\'s cluster photos, over the model\'s own ring\n'
         '\tlexis_lfa = { at = Vector3.new(-0.003, 0.0411, -0.1761), face = Vector3.new(0, 0.14, 0.99), w = 0.267, h = 0.175 },\n'
         '\tlexis_lfa_circuit = { at = Vector3.new(-0.003, 0.0411, -0.1761), face = Vector3.new(0, 0.14, 0.99), w = 0.267, h = 0.175 },\n')
    finish("lexis_lfa", "lexis_lfa_circuit")
    no_marks("lexis_lfa")
if what == "countach":
    edit("shared/Cars.lua", [('Name = "Enfurecido Classico 400"', 'Name = "Enfurecido Classico 5000"')])
    edit("shared/Config.lua", [('\t"Stealth-Apex V10 Halo and Halo Circuit models by Ddiaz Design",\n', '\t"Stealth-Apex V10 Halo and Halo Circuit models by Ddiaz Design",\n\t"Enfurecido Classico 5000 model by Ddiaz Design (CC BY)",\n')])
    p = os.path.join(ROOT, "client", "CarSkin.lua")
    s = open(p, encoding="utf-8", newline="").read()
    crlf = "\r\n" in s
    s = s.replace("\r\n", "\n")
    m = re.search(r"\tlambrini_countach = \{ -- Countach\n.*?\n\t\},\n", s, re.S)
    assert m
    s = s[: m.start()] + """\tlambrini_countach = { -- the 5000's own two big dials, redrawn sharp (tools/lambo/countach_art.py)
\t\t{ kind = "speed", unit = "kmh", at = Vector3.new(-0.0922, 0.0258, -0.2031), face = Vector3.new(-0.0086, 0.1833, 0.983), length = 0.0356, scale = "0:-135,40:-101.3,80:-67.5,120:-33.8,160:0,200:33.8,240:67.5,280:101.3,320:135" },
\t\t{ kind = "rpm", unit = "rpm", at = Vector3.new(0.0907, 0.0258, -0.2031), face = Vector3.new(-0.0086, 0.1833, 0.983), length = 0.0359, scale = "0:-114.1,1000:-90,2000:-61,3000:-35.4,4000:-14,5000:10.4,6000:34,7000:58,8000:90,9000:118" },
\t},
""" + s[m.end() :]
    a = "\tbugotti_chiron = { { faceless = true, needle"
    assert a in s
    s = s.replace(a, """\tlambrini_countach = {
\t\t{ faceless = true, image = "rbxassetid://90634108999362", faceR = 124, needle = Color3.fromRGB(240, 160, 30), needleW = 6, hubRing = Color3.fromRGB(46, 48, 54), hubR = 16 },
\t\t{ faceless = true, image = "rbxassetid://81321173656948", faceR = 120, needle = Color3.fromRGB(240, 160, 30), needleW = 6, hubRing = Color3.fromRGB(46, 48, 54), hubR = 16 },
\t},
""" + a, 1)
    a = '\tlambrini_countach = "Countach",\n'
    assert a in s
    s = s.replace(a, "", 1)
    if crlf:
        s = s.replace("\n", "\r\n")
    open(p, "w", encoding="utf-8", newline="").write(s)
    finish("lambrini_countach")
    no_marks("lambrini_countach")
if what == "s680":
    edit("client/CarSkin.lua", [
        ('\tbentz_s680 = "W213",\n', '\tbentz_s680 = "LiveMaybach", -- from the owner\'s photo\n'),
        ('bentz_s680 = "MercLuxury", ', ''),
    ])
    rect('\tbentz_s680 = { at = Vector3.new(0.0005, 0.0508, -0.203), face = Vector3.new(0, 0.14, 0.99), w = 0.366, h = 0.146 },\n')
    edit("shared/Config.lua", [('\t"Enfurecido Classico 5000 model by Ddiaz Design (CC BY)",\n', '\t"Enfurecido Classico 5000 model by Ddiaz Design (CC BY)",\n\t"Tri-Star Silber Z223 Royale V12 model by Ddiaz Design",\n')])
    finish("bentz_s680")
    no_marks("bentz_s680")
if what == "gls":
    edit("client/CarSkin.lua", [
        ('\tbentz_gls = "W213", -- Maybach GLS 600: wide glass screen\n', '\tbentz_gls = "LiveMaybach", -- from the owner\'s photo\n'),
        ('bentz_gls = "MercLuxury",', ''),
    ])
    edit("shared/Config.lua", [('\t"Tri-Star Silber Z223 Royale V12 model by Ddiaz Design",\n', '\t"Tri-Star Silber Z223 Royale V12 model by Ddiaz Design",\n\t"Tri-Star Silber X167 Royale model by Black Snow (CC BY)",\n')])
    no_marks("bentz_gls")
    rect('	bentz_gls = { at = Vector3.new(-0.0073, 0.0551, -0.1773), face = Vector3.new(-0.007, 0.109, 0.994), w = 0.335, h = 0.1336 },
')
print("ok")
