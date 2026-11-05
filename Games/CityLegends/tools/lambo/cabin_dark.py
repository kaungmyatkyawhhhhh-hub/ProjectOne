"""Cabins of the new imports come in pale: the game files tint a grey picture and darken it with metal, and
Studio's importer drops both. Each cabin picture is pushed down to a black interior's level along a curve,
so white button icons and stitches stay bright; a colour factor from the .glb goes on as a tint.

    python tools/lambo/cabin_dark.py donedir "imports/importing cars" outfile.json

done/<key>_cab holds tools/lambo/cabin_export.py's output. Writes d_*.png next to it, and outfile.json:
{ car id: { "dark": { representative part: file }, "tint": { part: [r, g, b] 0..255 } } }.
"""

import json
import os
import re
import struct
import sys

import numpy as np
from PIL import Image

done, glbs, outfile = sys.argv[1], sys.argv[2], sys.argv[3]
CARS = {
    "lp700": ("lambrini_lp700", "2012_lamborghini_aventador_lp700-4"),
    "sv": ("lambrini_lp750", "2016_lamborghini_aventador_lp750-4_sv"),
    "revuelto": ("lambrini_revuelto", "2024_lamborghini_revuelto"),
    "sl": ("lambrini_lp570", "2011_lamborghini_gallardo_lp570-4_superleggera"),
    "spyder560": ("lambrini_lp560", "2009_lamborghini_gallardo_lp560-4_spyder"),
    "evo": ("lambrini_huracan", "2019_lamborghini_huracan_evo"),
    "perf": ("lambrini_performante", "2019_lamborghini_huracan_performante_spyder"),
    "sto": ("lambrini_sto", "2021_lamborghini_huracan_sto"),
    "sterrato": ("lambrini_sterrato", "2024_lamborghini_huracan_sterrato"),
    "lp650r": ("lambrini_lp640", "2010_lamborghini_murcielago_lp670-4_superveloce"),  # (the SV's cabin)
    "lp670sv": ("lambrini_lp670", "2010_lamborghini_murcielago_lp670-4_superveloce"),
    "urusp": ("lambrini_urusp", "2023_lamborghini_urus_performante"),
    "california": ("ferrara_california", "2012_ferrari_california"),
    "f458spider": ("ferrara_458spider", "2013_ferrari_458_spider"),
    "f458speciale": ("ferrara_458speciale", "2014_ferrari_458_speciale"),
}
DARK_ROLES = ("Cabin", "CabinTile", "Suede", "Leather")
TARGET = 22.0
BRAND = re.compile(r"Lamborghini|Aventador|Huracan|Revuelto|Gallardo|Superveloce|Superleggera|Sterrato|RewardRecycled|Performante|Murcielago|Urus|Ferrari|California|Speciale", re.I)


def srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def factors(path):
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + n])
    out = {}
    for m in j["materials"]:
        p = m.get("pbrMetallicRoughness", {})
        f = p.get("baseColorFactor")
        if "baseColorTexture" in p and f and max(f[:3]) < 0.985:
            out[BRAND.sub("", m["name"])[:60]] = [round(srgb(c) * 255) for c in f[:3]]
    return out


def darken(src, dst):
    im = Image.open(src).convert("RGBA")
    a = np.asarray(im).astype(float)
    lum = a[..., :3].max(axis=2) / 255
    med = np.median(lum[lum > 0.02]) * 255 if (lum > 0.02).any() else 0
    if med <= TARGET or med >= 200:  # (dark already, or a white picture that lives on its tint)
        return None
    gamma = np.log(TARGET / 255) / np.log(med / 255)
    new = np.where(lum > 0, lum ** gamma / np.maximum(lum, 1e-4), 1)
    a[..., :3] = np.clip(a[..., :3] * new[..., None], 0, 255)
    Image.fromarray(a.astype("uint8"), "RGBA").save(dst)
    return round(float(gamma), 2)


out = {}
for key, (cid, glb) in CARS.items():
    if not os.path.exists(os.path.join(done, key + "_cab", "cabin.json")):
        continue  # (each job's cars only)
    d = json.load(open(os.path.join(done, key + "_cab", "cabin.json")))
    fac = factors(os.path.join(glbs, glb + ".glb"))
    row = {"dark": {}, "tint": {}}
    seen = {}
    for part, r in d["parts"].items():
        name = (r.get("mat") or "")[:60]
        t = fac.get(name)
        if t:
            row["tint"][part] = t
        base = r["base"]
        if r["role"] in DARK_ROLES and base in d["saved"]:
            if base not in seen:
                f = d["saved"][base]
                dst = "d_" + f[2:]
                seen[base] = darken(os.path.join(done, key + "_cab", f), os.path.join(done, key + "_cab", dst)), dst
            gamma, dst = seen[base]
            if gamma:
                row["dark"].setdefault(dst, part)
    out[cid] = row
    print(cid, "dark", {k: v for k, v in seen.items()}, "tints", len(row["tint"]))
json.dump(out, open(outfile, "w"), indent=0)
