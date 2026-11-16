"""burmese_text.py [outdir]: real Burmese shop-sign words as white-on-transparent PNGs for the facade atlas (atlas.py).

Burmese needs complex shaping (vowel reordering, stacked consonants, medials). This Pillow has no raqm, so it would
draw the letters in storage order with the marks in the wrong places. The words are rendered instead by
burmese_text.ps1 (Windows PowerShell + WPF = DirectWrite, which shapes Myanmar properly) in the Windows font
"Myanmar Text" Bold (mmrtextb.ttf), then cropped and scaled here.

In:  burmese_words.json next to this file (each word's Burmese text and English meaning; plus the latin sign words).
Out: outdir (default build/signs/words/):
  <id>.png     white text, alpha = coverage. Every PNG is 96 px tall and shares one line band (the union of all the
               words' ink from the highest mark to the lowest stacked consonant), so letters are the same size and
               sit on the same baseline in every word; cropped tight left and right.
  words.json   [{id, my, en, file, w, h, baseline, latin (the English line for the same sign, optional)}] + "latin"
               (the English sign words).
Needs Windows (powershell.exe, WPF) and the Myanmar Text font (Windows 8 and later).
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "..", "build", "signs", "words")
H = 96  # px tall
SIZE = 160  # em size the words are drawn at before scaling down
INK = 6  # alpha that counts as ink when cropping


def render(out):
    src = json.load(open(os.path.join(HERE, "burmese_words.json"), encoding="utf-8"))
    words = src["words"]
    raw = os.path.join(out, "_raw")
    os.makedirs(raw, exist_ok=True)
    lst = os.path.join(raw, "list.json")
    with open(lst, "w", encoding="utf-8") as f:
        json.dump([{"id": w["id"], "text": w["my"]} for w in words], f, ensure_ascii=False)
    cmd = ["powershell.exe", "-NoProfile", "-STA", "-ExecutionPolicy", "Bypass", "-File",
           os.path.join(HERE, "burmese_text.ps1"), "-In", lst, "-Out", raw, "-Size", str(SIZE), "-Bold"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit("burmese_text.ps1 failed:\n" + res.stdout + res.stderr)
    base = {}
    for ln in res.stdout.splitlines():
        p = ln.split("\t")
        if len(p) == 3:
            base[p[0]] = float(p[1])
    # every raw PNG has the same top padding and baseline (one font, one size), so one vertical band fits them all
    alphas = {}
    top, bot = 10 ** 9, -1
    for w in words:
        a = np.array(Image.open(os.path.join(raw, w["id"] + "_raw.png")).convert("RGBA"))[:, :, 3]
        alphas[w["id"]] = a
        rows = np.where(a.max(axis=1) > INK)[0]
        if len(rows) == 0:
            sys.exit("nothing drawn for " + w["id"])
        top, bot = min(top, rows[0]), max(bot, rows[-1])
    top, bot = top - 2, bot + 3
    meta = []
    for w in words:
        a = alphas[w["id"]]
        cols = np.where(a[top:bot].max(axis=0) > INK)[0]
        x0, x1 = cols[0] - 2, cols[-1] + 3
        crop = a[top:bot, x0:x1]
        k = H / crop.shape[0]
        img = Image.fromarray(crop, "L").resize((max(1, round(crop.shape[1] * k)), H), Image.LANCZOS)
        white = Image.new("RGBA", img.size, (255, 255, 255, 0))
        white.putalpha(img)
        fn = w["id"] + ".png"
        white.save(os.path.join(out, fn))
        m = dict(id=w["id"], my=w["my"], en=w["en"], file=fn, w=img.width, h=H,
                 baseline=round((base.get(w["id"], 0) - top) * k, 1))
        if w.get("latin"):
            m["latin"] = w["latin"]
        meta.append(m)
    with open(os.path.join(out, "words.json"), "w", encoding="utf-8") as f:
        json.dump(dict(note="Burmese shop-sign words (white on transparent, %d px tall, one shared line band). "
                            "Made by tools/yangon/city/burmese_text.py." % H,
                       font="Myanmar Text Bold (WPF / DirectWrite shaping)", words=meta, latin=src["latin"]),
                  f, ensure_ascii=False, indent=1)
    print(len(meta), "words ->", os.path.abspath(out))
    return meta


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    render(OUT)
