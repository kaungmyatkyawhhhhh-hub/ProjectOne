"""look_calib.py: what colour to give a Roblox part so it RENDERS as a photo colour in Yangon's daylight.

Measured 2026-11-14 in Studio Edit with tools/yangon/PlayLight.luau at hour 13 (Play's Yangon light: blue sky
ambient, haze): panels of 8 materials x 10 greys (20..245), one facing the sun's horizontal direction, one in
shade, shot from 52 studs (build/landmarks/look_swatches_13h.json; the sun rows there are stored dark->light
reversed, fixed on load). Each material/channel gets a monotone curve grey -> rendered; inverting it gives the
albedo channel that renders as the target channel.

    albedo(material, target_rgb, side="mix") -> ((r, g, b), clipped)
side: "sun", "shade" or "mix" (0.6 sun + 0.4 shade: what a facade averages over its lit and shaded faces).
Targets brighter than the material can render are scaled down as a whole (hue kept) and flagged clipped.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SW = os.path.normpath(os.path.join(HERE, "..", "..", "..", "build", "landmarks", "look_swatches_13h.json"))
GREYS = [20, 45, 70, 95, 120, 145, 170, 195, 220, 245]
# materials not on the panels use the closest measured one
ALIAS = {"Neon": "SmoothPlastic", "WoodPlanks": "Concrete", "Grass": "Concrete", "Pavement": "Concrete",
         "Asphalt": "Concrete", "DiamondPlate": "Metal", "Granite": "Sandstone", "Foil": "Metal"}

_data = None


def data():
    global _data
    if _data is None:
        d = json.load(open(SW))
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
    out = []
    for c in range(3):
        g = _inv(curves[c], target[c] * k)
        out.append(int(round(min(255, max(0, g)))))
    return tuple(out), clipped


if __name__ == "__main__":
    import sys
    mat = sys.argv[1]
    rgb = tuple(int(v) for v in sys.argv[2].split(","))
    for side in ("sun", "shade", "mix"):
        print(side, albedo(mat, rgb, side))
