"""download.py: fetch the CC0 1K maps for every spec entry into build/materials/<slug>/src/<asset>/ and write
<slug>/sources.json. Poly Haven: api.polyhaven.com/files/<id> -> 1k jpg/png per map. ambientCG: the 1K-JPG zip
(only image files are extracted, flat names). Skips files already there. Run: python -I download.py [slug ...]"""
import io
import json
import os
import re
import sys
import time
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from spec import S  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "..", "build", "materials"))  # the maps live in build/ (gitignored)
UA = {"User-Agent": "Mozilla/5.0 (texture-library fetch)"}
PH_MAPS = {"Diffuse": "color", "nor_gl": "normal_gl", "Rough": "roughness", "arm": "arm"}


def get(url, tries=4):
    for k in range(tries):
        try:
            return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=90).read()
        except Exception as e:  # noqa: BLE001
            print("   retry", k + 1, url, e)
            time.sleep(2 + 3 * k)
    raise RuntimeError("download failed: " + url)


def ph(aid, out, metal):
    files = json.loads(get("https://api.polyhaven.com/files/" + aid))
    info = json.loads(get("https://api.polyhaven.com/info/" + aid))
    got = {}
    for key, role in PH_MAPS.items():
        if key == "arm" and not metal:
            continue
        if key not in files:
            continue
        res = files[key].get("1k", {})
        f = res.get("jpg") or res.get("png")
        if not f:
            continue
        ext = ".jpg" if "jpg" in res else ".png"
        fn = os.path.join(out, role + ext)
        if not os.path.exists(fn):
            open(fn, "wb").write(get(f["url"]))
            time.sleep(0.4)
        got[role] = {"file": os.path.basename(fn), "url": f["url"]}
    dims = info.get("dimensions")
    return dict(site="Poly Haven", asset_id=aid, page="https://polyhaven.com/a/" + aid, licence="CC0 1.0",
                authors=list(info.get("authors", {}).keys()), real_size_mm=dims, maps=got)


def acg(aid, out):
    url = "https://ambientcg.com/get?file=%s_1K-JPG.zip" % aid
    marker = os.path.join(out, "_zip_done")
    got = {}
    if not os.path.exists(marker):
        z = zipfile.ZipFile(io.BytesIO(get(url)))
        for n in z.namelist():
            base = os.path.basename(n)
            if not re.match(r"^[A-Za-z0-9_.-]+\.(jpg|png)$", base):
                continue
            open(os.path.join(out, base), "wb").write(z.read(n))
        open(marker, "w").write(url)
        time.sleep(0.6)
    for base in os.listdir(out):
        for tag, role in (("_Color", "color"), ("_NormalGL", "normal_gl"), ("_NormalDX", "normal_dx"),
                          ("_Roughness", "roughness"), ("_Metalness", "metalness"), ("_Opacity", "opacity")):
            if tag in base:
                got[role] = {"file": base}
    meta = json.loads(get("https://ambientcg.com/api/v2/full_json?type=Material&include=dimensionsData&id=" + aid))
    a = meta["foundAssets"][0] if meta.get("foundAssets") else {}
    dx = a.get("dimensionX") or 0
    return dict(site="ambientCG", asset_id=aid, page="https://ambientcg.com/view?id=" + aid, licence="CC0 1.0",
                download=url, real_size_cm=[dx, a.get("dimensionY") or 0] if dx else None, maps=got)


def main(only):
    for e in S:
        if only and e["slug"] not in only:
            continue
        d = os.path.join(ROOT, e["slug"])
        os.makedirs(d, exist_ok=True)
        recs = []
        for site, aid in e["src"]:
            out = os.path.join(d, "src", aid)
            os.makedirs(out, exist_ok=True)
            print(e["slug"], site, aid)
            recs.append(ph(aid, out, e.get("metal") == "map") if site == "ph" else acg(aid, out))
        rec = dict(surface=e["slug"], variant=e["variant"], sources=recs,
                   procedural=bool(e.get("proc")), procedural_step=e.get("proc"),
                   note=("fully procedural (numpy / PIL), no CC0 source used" if not recs else
                         "CC0 source maps" + (" + a procedural step (prepare.py)" if e.get("proc") else "")))
        json.dump(rec, open(os.path.join(d, "sources.json"), "w"), indent=1)


if __name__ == "__main__":
    main(set(sys.argv[1:]))
