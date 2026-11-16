"""look_calib.py: what colour to give a Roblox part so it RENDERS as a photo colour in Yangon's daylight.

Measured 2026-11-14 in Studio Edit with tools/yangon/PlayLight.luau at hour 13 (Play's Yangon light: blue sky
ambient, haze): panels of 8 materials x 10 greys (20..245), one facing the sun's horizontal direction, one in
shade, shot from 52 studs (build/landmarks/look_swatches_13h.json; the sun rows there are stored dark->light
reversed, fixed on load; since 2026-11-16 the file is look_swatches_13h_yangon.json, measured under Yangon's warmer daylight in the same order as the shade rows). Each material/channel gets a monotone curve grey -> rendered; inverting it gives the
albedo channel that renders as the target channel.

    albedo(material, target_rgb, side="mix") -> ((r, g, b), clipped)
side: "sun", "shade" or "mix" (0.6 sun + 0.4 shade: what a facade averages over its lit and shaded faces).
Targets brighter than the material can render are scaled down as a whole (hue kept) and flagged clipped.

Dark colours (fix 2026-11-16, kit critique): the rendered floor of every material is bluish (the sky ambient: grey 20
renders about (23, 34, 52)), so the plain per-channel inverse sent blue to 0 for any target under ~60 and every dark
part came out brown or olive ((30, 30, 32) -> (35, 12, 0)). Now, when a channel's inverse falls under FLOOR x its
target (or the inverse adds more than SAT_SHIFT saturation), the colour is solved on the channels' mean curve instead and the target's channel RATIOS are kept:
albedo = target x s, with s >= FLOOR. Dark stays dark and keeps its hue.

    pick(target, prefer, side="mix") -> (material, (r, g, b), note)
tries the preferred material (textured ones render much darker than their colour); when it can't reach the target
(clipped, k < PICK_K), or it is in BLACK (renders near black in this map), it falls back to SmoothPlastic.
Materials with no swatch panels use a measured proxy (PROXY) and say so in the note.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SW = os.path.normpath(os.path.join(HERE, "..", "..", "..", "build", "landmarks", "look_swatches_13h_yangon.json"))
GREYS = [20, 45, 70, 95, 120, 145, 170, 195, 220, 245]
# materials not on the panels use the closest measured one
ALIAS = {"Neon": "SmoothPlastic", "WoodPlanks": "Concrete", "Grass": "Concrete", "Pavement": "Concrete",
         "Asphalt": "Concrete", "DiamondPlate": "Metal", "Granite": "Sandstone", "Foil": "Metal"}
# no swatch panels yet: calibrated on the closest measured material (measure them in Studio with Swatches.luau)
PROXY = {"Plaster": "Concrete", "Fabric": "Concrete", "CorrodedMetal": "Metal", "WoodPlanks": "Concrete"}
ALIAS.update(PROXY)
BLACK = {"ClayRoofTiles", "Granite", "Marble"}  # render near black in this map (CLAUDE.md trap): never picked
FLOOR = 0.8   # a dark channel stays at or above this share of its target
SAT_SHIFT = 0.12  # ... and the inverse may not add more than this much saturation (the floor turning greys yellow)
PICK_K = 0.97  # a material must reach at least this share of the target to be picked

_data = None


def data():
    global _data
    if _data is None:
        d = json.load(open(SW))
        if "yangon" not in SW:
            d["sun"] = {m: list(reversed(rows)) for m, rows in d["sun"].items()}
        mix = {}
        for m in d["sun"]:
            mix[m] = [[0.6 * a + 0.4 * b for a, b in zip(s, h)] for s, h in zip(d["sun"][m], d["shade"][m])]
        d["mix"] = mix
        _data = d
    return _data


def _inv(curve, t):
    """curve: rendered values at GREYS (monotone up). Grey that renders as t (extrapolated linearly, 0..255)."""
    if t <= curve[0]:
        a, b, ga, gb = curve[0], curve[1], GREYS[0], GREYS[1]
    elif t >= curve[-1]:
        a, b, ga, gb = curve[-2], curve[-1], GREYS[-2], GREYS[-1]
    else:
        for i in range(len(curve) - 1):
            if curve[i] <= t <= curve[i + 1]:
                a, b, ga, gb = curve[i], curve[i + 1], GREYS[i], GREYS[i + 1]
                break
    g = ga + (gb - ga) * (t - a) / max(b - a, 1e-6)
    return g


def rendered_max(material, side="mix"):
    m = ALIAS.get(material, material)
    rows = data()[side][m]
    return rows[-1]


def albedo(material, target, side="mix"):
    m = ALIAS.get(material, material)
    rows = data()[side][m]
    curves = [[rows[i][c] for i in range(len(GREYS))] for c in range(3)]
    # top that can be reached (albedo 255, extrapolated) per channel
    tops = [curves[c][-1] + (curves[c][-1] - curves[c][-2]) * (255 - 245) / 25 for c in range(3)]
    k = min(1.0, min(tops[c] / max(target[c], 1) for c in range(3)))
    clipped = k < 0.999
    t = [target[c] * k for c in range(3)]
    raw = [_inv(curves[c], t[c]) for c in range(3)]
    def sat(v):
        return (max(v) - min(v)) / max(max(v), 1e-6)
    if any(raw[c] < FLOOR * t[c] for c in range(3)) or sat(raw) - sat(t) > SAT_SHIFT:
        # dark: solve the lightness on the mean curve, keep the target's channel ratios
        mean = [sum(curves[c][i] for c in range(3)) / 3 for i in range(len(GREYS))]
        lum = max(sum(t) / 3, 1e-6)
        s = max(FLOOR, _inv(mean, lum) / lum)
        raw = [t[c] * s for c in range(3)]
        top = max(raw)
        if top > 255:
            raw = [v * 255 / top for v in raw]
    out = tuple(int(round(min(255, max(0, v)))) for v in raw)
    return out, clipped


def reach(material, target, side="mix"):
    """Share of the target the material can render (1 = reachable)."""
    m = ALIAS.get(material, material)
    rows = data()[side][m]
    tops = [rows[-1][c] + (rows[-1][c] - rows[-2][c]) * (255 - 245) / 25 for c in range(3)]
    return min(1.0, min(tops[c] / max(target[c], 1) for c in range(3)))


def pick(target, prefer="SmoothPlastic", side="mix"):
    """(material, part rgb, note): the preferred material if it can render the target, else SmoothPlastic."""
    note = ""
    if prefer in BLACK:
        note = prefer + " renders near black: SmoothPlastic"
        prefer = None
    elif prefer != "SmoothPlastic" and reach(prefer, target, side) < PICK_K:
        note = "%s reaches only %.0f%%: SmoothPlastic" % (prefer, 100 * reach(prefer, target, side))
        prefer = None
    if prefer is None:
        prefer = "SmoothPlastic"
    elif prefer in PROXY:
        note = "%s calibrated on %s panels" % (prefer, PROXY[prefer])
    rgb, _ = albedo(prefer, target, side)
    return prefer, rgb, note


# ------------------------------------------------------------------ the building kit's groups (kit.py; landmark_glb3d K*)
# code: (preferred material, photo target sRGB, transparency, reflectance, double_sided, cast_shadow, what / source)
# Targets from build/landmarks/refs/kit/palette_measured.json and kit_critique.md (paint = cleanest lit paint).
# Regenerate the lines with: python look_calib.py --kit
KIT_SPEC = [
    # walls (Concrete where it can render the colour; the light paints fall back to SmoothPlastic)
    ("KW0", "Concrete", (226, 226, 222), 0, 0, False, True, "trim, ledges, cornices: neutral white (never cream)"),
    ("KW1", "Concrete", (225, 202, 159), 0, 0, False, True, "cream / butter yellow (walk-up paint 225,202,159)"),
    ("KW2", "Concrete", (170, 210, 215), 0, 0, False, True, "aqua (downtown 150,200,214 / stained 183,220,222)"),
    ("KW3", "Concrete", (180, 157, 130), 0, 0, False, True, "stained tan / ochre (downtown paint 179,156,129)"),
    ("KW4", "Concrete", (210, 220, 222), 0, 0, False, True, "blue-white (walk-up paint 210,221,220)"),
    ("KW5", "Concrete", (225, 190, 185), 0, 0, False, True, "pink, corner landmark plots only"),
    ("KW6", "Concrete", (238, 235, 228), 0, 0, False, True, "white (villa 243,238,227; downtown 222,219,215)"),
    ("KW7", "Concrete", (197, 222, 168), 0, 0, False, True, "pale green, corner landmark plots only (Pansodan)"),
    ("KWG", "Concrete", (150, 150, 146), 0, 0, False, True, "stained grey wall, walk-up slab edges"),
    ("KWD2", "Concrete", (95, 90, 85), 0, 0, False, True, "dark-stained colonial front (Merchant Rd seen 72,65,61)"),
    ("KWB", "Concrete", (160, 185, 205), 0, 0, False, True, "township pale blue (paint 145,169,188)"),
    ("KWC", "Concrete", (134, 137, 135), 0, 0, False, True, "villa compound wall, stained grey"),
    ("KBC", "Glass", (52, 86, 133), 0, 0.12, False, True, "condo blue cladding / glass stripe"),
    # weathering overlays (see-through)
    ("KST", "SmoothPlastic", (62, 60, 56), 0.45, 0, False, False, "dark rain streaks (stain lines 70,69,69)"),
    ("KSU", "SmoothPlastic", (96, 92, 84), 0.55, 0, False, False, "soft rain stain"),
    ("KGM1", "SmoothPlastic", (70, 66, 60), 0.72, 0, False, False, "grime overlay, young building"),
    ("KGM2", "SmoothPlastic", (66, 62, 57), 0.56, 0, False, False, "grime overlay, middle age"),
    ("KGM3", "SmoothPlastic", (60, 56, 52), 0.42, 0, False, False, "grime overlay, old (Merchant Rd tops)"),
    ("KGB", "SmoothPlastic", (76, 70, 62), 0.4, 0, False, False, "dark splash band at the base"),
    # openings, iron, wood
    ("KGL", "Glass", (48, 50, 50), 0, 0.15, False, True, "window glass, dark (curtain glass 50,51,48)"),
    ("KRL", "Glass", (170, 200, 200), 0.6, 0.05, True, False, "glass balcony rails"),
    ("KFR", "SmoothPlastic", (200, 198, 190), 0, 0, False, True, "window frames"),
    ("KGR", "Metal", (40, 42, 44), 0, 0, False, True, "black iron: grilles, louvre bars, cast-iron rails, mesh dishes"),
    ("KSH", "WoodPlanks", (110, 70, 40), 0, 0, False, True, "teak shutters, brown"),
    ("KSH2", "WoodPlanks", (90, 120, 100), 0, 0, False, True, "faded green shutters"),
    ("KSH3", "WoodPlanks", (86, 150, 190), 0, 0, False, True, "faded blue shutters (26th St 86,175,219)"),
    ("KSH4", "WoodPlanks", (178, 117, 70), 0, 0, False, True, "painted orange-teak shutters / doors"),
    ("KCG", "SmoothPlastic", (70, 74, 72), 0, 0, False, True, "steel posts, stands"),
    ("KCB", "Metal", (40, 42, 44), 0, 0, False, True, "black balcony cage"),
    ("KCU", "CorrodedMetal", (120, 75, 50), 0, 0, False, True, "rust balcony cage"),
    ("KCW", "SmoothPlastic", (223, 220, 212), 0, 0, False, True, "white-painted cage (Mahabandula pillars)"),
    ("KGT", "Metal", (25, 40, 35), 0, 0, False, True, "villa gate, near-black green (15,21,21)"),
    ("KGU", "CorrodedMetal", (166, 120, 83), 0, 0, False, True, "rusty steel gate"),
    ("KCO", "Concrete", (170, 166, 158), 0, 0, False, True, "bare concrete, poles"),
    ("KAC", "SmoothPlastic", (225, 225, 220), 0, 0, False, True, "air-con units"),
    ("KPP", "SmoothPlastic", (70, 130, 190), 0, 0, False, True, "blue PVC drainpipes"),
    ("KWI", "SmoothPlastic", (28, 28, 28), 0, 0, True, False, "overhead wires"),
    # cloth, awnings, signs
    ("KL1", "Fabric", (190, 70, 65), 0, 0, True, False, "laundry / goods red"),
    ("KL2", "Fabric", (60, 90, 150), 0, 0, True, False, "laundry / goods blue"),
    ("KL3", "Fabric", (230, 200, 70), 0, 0, True, False, "laundry / goods yellow"),
    ("KL4", "Fabric", (225, 225, 220), 0, 0, True, False, "laundry pale white"),
    ("KL5", "Fabric", (200, 160, 170), 0, 0, True, False, "laundry pale pink"),
    ("KL6", "Fabric", (120, 140, 160), 0, 0, True, False, "laundry grey-blue"),
    ("KAW", "Fabric", (60, 130, 200), 0, 0, True, True, "blue plastic / corrugated awnings (30th, 47th St)"),
    ("KAR", "Fabric", (140, 86, 80), 0, 0, True, True, "faded red canvas awning"),
    ("KNT", "Fabric", (48, 100, 60), 0.35, 0, True, False, "green shade net (critique 60,140,80, darkened: it reads as a solid green panel)"),
    ("KTP", "Fabric", (50, 110, 180), 0, 0, True, True, "blue tarp"),
    ("KS1", "SmoothPlastic", (192, 52, 45), 0, 0, False, True, "red sign"),
    ("KS2", "SmoothPlastic", (238, 186, 19), 0, 0, False, True, "yellow sign ground"),
    ("KS3", "SmoothPlastic", (30, 80, 170), 0, 0, False, True, "blue sign / logo"),
    ("KS4", "SmoothPlastic", (213, 94, 63), 0, 0, False, True, "orange sign"),
    ("KSW", "SmoothPlastic", (235, 235, 228), 0, 0, False, True, "white sign ground, lightbox"),
    ("KSV", "SmoothPlastic", (198, 182, 116), 0, 0, False, True, "pale yellow vinyl banner"),
    ("KSI", "SmoothPlastic", (60, 52, 44), 0, 0, False, True, "dark shop interiors"),
    ("KRS", "SmoothPlastic", (150, 150, 148), 0, 0, False, True, "roller shutters"),
    # roofs, tanks, dishes
    ("KRF", "CorrodedMetal", (105, 70, 56), 0, 0, True, True, "rusty corrugated roofs"),
    ("KRG", "CorrodedMetal", (116, 116, 110), 0, 0, True, True, "faded grey corrugated roofs"),
    ("KRB", "SmoothPlastic", (96, 145, 196), 0, 0, True, True, "blue metal roof"),
    ("KRT", "ClayRoofTiles", (165, 95, 80), 0, 0, False, True, "villa tile roof, muted brick red (148,88,79 to 231,174,149)"),
    ("KTK", "SmoothPlastic", (30, 30, 32), 0, 0, False, True, "black water tanks"),
    ("KDS", "SmoothPlastic", (190, 190, 186), 0, 0, False, True, "small satellite dishes"),
    # ground, greens, props
    ("KPV", "Concrete", (150, 145, 135), 0, 0, False, True, "paving"),
    ("KRD", "SmoothPlastic", (60, 60, 62), 0, 0, False, True, "road"),
    ("KWD", "WoodPlanks", (140, 100, 65), 0, 0, False, True, "wood stalls, crates"),
    ("KPL", "SmoothPlastic", (70, 110, 50), 0, 0, False, True, "potted plants, weed tufts"),
    ("KTL", "SmoothPlastic", (62, 92, 46), 0, 0, True, True, "tree leaves, palm fronds"),
    ("KTW", "SmoothPlastic", (95, 82, 70), 0, 0, False, True, "tree trunks"),
    ("KGS", "SmoothPlastic", (96, 120, 64), 0, 0, False, True, "villa lawn"),
    ("KCR", "SmoothPlastic", (230, 230, 230), 0, 0, False, True, "scale car"),
    ("KTY", "SmoothPlastic", (25, 25, 25), 0, 0, False, True, "tyres"),
    ("KSK", "SmoothPlastic", (190, 140, 100), 0, 0, False, True, "skin"),
]


def kit_lines():
    """The K* group lines for landmark_glb3d.GROUPS, each with its photo target and calibration note."""
    out = []
    for code, pref, tgt, tr, rf, ds, sh, what in KIT_SPEC:
        if pref == "Glass":
            mat, rgb, note = "Glass", albedo("Glass", tgt)[0], ""
        else:
            mat, rgb, note = pick(tgt, pref)
        key = '"%s":' % code
        out.append('    %-7s ("%s", (%d, %d, %d), %s, %s, %s, %s),  # kit: %s (photo %s)%s' % (
            key, mat, rgb[0], rgb[1], rgb[2], float(tr), float(rf), ds, sh, what, tgt, "; " + note if note else ""))
    return out


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["--kit"]:
        print("\n".join(kit_lines()))
        sys.exit(0)
    mat = sys.argv[1]
    rgb = tuple(int(v) for v in sys.argv[2].split(","))
    for side in ("sun", "shade", "mix"):
        print(side, albedo(mat, rgb, side))
