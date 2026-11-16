"""street_signs.py <tag> (2026-11-16, the 1:1 street detail layer): the name-plate atlases of a pilot district.

Only REAL names (owner rule: no invented text): the OSM `name` / `name:en` of the district's streets (green YCDC street
plates: Burmese on top, English below, white on green, a white rim) and of its YBS bus stops (white plates: a dark-blue
"YBS" band, the stop's Burmese and English names). Burmese is drawn by burmese_text.ps1 (WPF / DirectWrite shaping,
font Myanmar Text Bold: Pillow would put the marks in the wrong places), English with Arial Bold.

    YANGON_SCALE=1to1 python street_signs.py P1
      -> imports/sync/ygn1to1_street/signs_<tag>_<a>.png (1024 x 1024 atlases, cells 256 x 88: 4 x 11)
         build/city_1to1/street_<tag>/atlas.json  {cw, ch, cols, ids (filled after the upload), cells: [{key, atlas, cell}]}
After the Open Cloud upload (assetType Image) put the image ids in atlas.json "ids" (street_signs.py --ids id1 id2 ...).
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import geo  # noqa: E402

TAG = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else "P1"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OUT = os.path.join(ROOT, "build", "city_1to1", "street_%s" % TAG)
GLB = os.path.join(ROOT, "imports", "sync", "ygn1to1_street")
CW, CH, COLS, ROWS = 256, 88, 4, 11
GREEN = (24, 112, 64)
WHITE = (250, 250, 248)
NAVY = (22, 52, 130)


def plate_name(tags):
    import re
    nm = tags.get("name", "")
    en = tags.get("name:en", "")
    my = "".join(ch for ch in nm if "\u1000" <= ch <= "\u109f" or ch in " ()0123456789").strip()
    my = re.sub(r"\s+", " ", my)
    my = my if any("\u1000" <= ch <= "\u109f" for ch in my) else ""
    my = re.sub(r"\(\s*\)", "", re.sub(r"[0-9]", "", my)).strip()     # the English part's digits / brackets
    my = re.sub(r"\s+", " ", my)
    if not my:
        alt = "".join(ch for ch in en if "\u1000" <= ch <= "\u109f" or ch in " ()0123456789").strip()
        my = re.sub(r"\s+", " ", alt) if any("\u1000" <= ch <= "\u109f" for ch in alt) else ""
    if not en:
        en = nm
    en = re.sub(r"[\u1000-\u109f]", "", en).strip(" -")
    en = re.sub(r"\s+", " ", en) if re.search(r"[A-Za-z]", en) else ""
    return my, en


def road_tags():
    """OSM road tags by name and by name:en (the profile keeps one of them)"""
    roads = json.load(open(os.path.join(geo.OSM, "roads.json"), encoding="utf-8"))["roads"]
    by = {}
    for r in roads:
        t = r.get("t", {})
        for k in ("name", "name:en"):
            if t.get(k):
                by.setdefault(t[k], t)
    return by


def names():
    prof = json.load(open(os.path.join(ROOT, "build", "city_1to1", "roads_%s_profile.json" % TAG)))
    by = road_tags()
    keys = []
    for e in prof:
        if e["name"]:
            my, en = plate_name(by.get(e["name"], {"name": e["name"]}))
            if (my or en) and ("street", my, en) not in keys:
                keys.append(("street", my, en))
    d = json.load(open(os.path.join(ROOT, "build", "landmarks", "refs", "street_kit", "osm_street_items.json"), encoding="utf-8"))
    lo0, la0, lo1, la1 = geo.PILOT_LL[TAG]
    for it in d["items"]:
        if it["kind"] == "bus_stop" and lo0 <= it["lon"] <= lo1 and la0 <= it["lat"] <= la1:
            my, en = plate_name(it["tags"])
            if (my or en) and ("stop", my, en) not in keys:
                keys.append(("stop", my, en))
    return keys


def burmese(lines):
    raw = os.path.join(OUT, "_my")
    os.makedirs(raw, exist_ok=True)
    lst = os.path.join(raw, "list.json")
    json.dump([{"id": "m%d" % i, "text": t} for i, t in enumerate(lines)], open(lst, "w", encoding="utf-8"), ensure_ascii=False)
    res = subprocess.run(["powershell.exe", "-NoProfile", "-STA", "-ExecutionPolicy", "Bypass", "-File",
                          os.path.join(HERE, "burmese_text.ps1"), "-In", lst, "-Out", raw, "-Size", "120", "-Bold"],
                         capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit("burmese_text.ps1 failed:\n" + res.stdout + res.stderr)
    out = {}
    for i, t in enumerate(lines):
        a = np.array(Image.open(os.path.join(raw, "m%d_raw.png" % i)).convert("RGBA"))[:, :, 3]
        rows = np.where(a.max(axis=1) > 6)[0]
        cols = np.where(a.max(axis=0) > 6)[0]
        out[t] = Image.fromarray(a[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1], "L")
    return out


def fit(mask, w, h):
    k = min(w / mask.width, h / mask.height)
    return mask.resize((max(1, int(mask.width * k)), max(1, int(mask.height * k))), Image.LANCZOS)


def text_mask(s, h):
    f = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 64)
    box = f.getbbox(s)
    img = Image.new("L", (box[2] - box[0] + 8, box[3] - box[1] + 8), 0)
    ImageDraw.Draw(img).text((4 - box[0], 4 - box[1]), s, fill=255, font=f)
    return img


def draw_cell(key, my_img):
    kind, my, en = key
    bg = GREEN if kind == "street" else WHITE
    fg = WHITE if kind == "street" else (20, 20, 24)
    im = Image.new("RGB", (CW, CH), bg)
    d = ImageDraw.Draw(im)
    if kind == "street":
        d.rectangle([3, 3, CW - 4, CH - 4], outline=WHITE, width=3)
        x0, x1 = 12, CW - 12
    else:
        d.rectangle([0, 0, 58, CH - 1], fill=NAVY)
        ys = fit(text_mask("YBS", 40), 50, 34)
        im.paste((250, 250, 248), (4 + (50 - ys.width) // 2, (CH - ys.height) // 2), ys)
        d.rectangle([1, 1, CW - 2, CH - 2], outline=(150, 150, 150), width=2)
        x0, x1 = 66, CW - 8
    lines = []
    if my:
        lines.append(("my", my_img[my]))
    if en:
        lines.append(("en", text_mask(en.upper() if kind == "street" else en, 40)))
    if len(lines) == 2:
        boxes = [(10, 46), (52, 78)]
    else:
        boxes = [(14, 74)]
    for (k, m), (y0, y1) in zip(lines, boxes):
        mm = fit(m, x1 - x0, y1 - y0)
        im.paste(fg, (x0 + (x1 - x0 - mm.width) // 2, y0 + (y1 - y0 - mm.height) // 2), mm)
    return im


def main():
    if "--ids" in sys.argv:
        ids = sys.argv[sys.argv.index("--ids") + 1:]
        p = os.path.join(OUT, "atlas.json")
        A = json.load(open(p, encoding="utf-8"))
        A["ids"] = ids
        json.dump(A, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("ids", ids)
        return
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(GLB, exist_ok=True)
    keys = names()
    my_img = burmese(sorted({k[1] for k in keys if k[1]}))
    per = COLS * ROWS
    atlases, cells = [], []
    for n, key in enumerate(keys):
        a, c = divmod(n, per)
        if a == len(atlases):
            atlases.append(Image.new("RGB", (1024, 1024), (40, 40, 40)))
        atlases[a].paste(draw_cell(key, my_img), ((c % COLS) * CW, (c // COLS) * CH))
        cells.append(dict(key=list(key), atlas=a, cell=c))
    files = []
    for a, im in enumerate(atlases):
        f = os.path.join(GLB, "signs_%s_%d.png" % (TAG.lower(), a))
        im.save(f)
        files.append(f)
    json.dump(dict(cw=CW, ch=CH, cols=COLS, ids=[], files=files, cells=cells), open(os.path.join(OUT, "atlas.json"), "w",
              encoding="utf-8"), ensure_ascii=False, indent=1)
    print("%d plates (%d street, %d stop) in %d atlases" % (len(keys), sum(k[0] == "street" for k in keys),
                                                          sum(k[0] == "stop" for k in keys), len(atlases)), files)


if __name__ == "__main__":
    main()
