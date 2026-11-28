"""Satellite (Esri World Imagery) + OSM outlines for a small box; prints named / tall things with game coordinates.
python osm_sat.py name lat0 lon0 lat1 lon1 [zoom]  (2026-11-28)"""
import sys, math, io, json, urllib.request
from PIL import Image, ImageDraw
UA = {"User-Agent": "map-research-client/1.0"}
def tile(lat, lon, z):
    n = 2 ** z
    return (lon + 180) / 360 * n, (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n
def game(lat, lon):
    return 30000 + (lon - 96.14) * 106558 * 3, 30000 - (lat - 16.82) * 110540 * 3
name, lat0, lon0, lat1, lon1 = sys.argv[1], *[float(x) for x in sys.argv[2:6]]
z = int(sys.argv[6]) if len(sys.argv) > 6 else 19
x0, y1 = tile(lat0, lon0, z); x1, y0 = tile(lat1, lon1, z)
tx0, ty0, tx1, ty1 = int(x0), int(y0), int(x1), int(y1)
W, H = (tx1 - tx0 + 1) * 256, (ty1 - ty0 + 1) * 256
img = Image.new("RGB", (W, H))
for tx in range(tx0, tx1 + 1):
    for ty in range(ty0, ty1 + 1):
        u = f"https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{ty}/{tx}"
        try: img.paste(Image.open(io.BytesIO(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30).read())).convert("RGB"), ((tx - tx0) * 256, (ty - ty0) * 256))
        except Exception as e: print("tile fail", tx, ty, e)
def px(lat, lon):
    x, y = tile(lat, lon, z); return ((x - tx0) * 256, (y - ty0) * 256)
u = f"https://api.openstreetmap.org/api/0.6/map.json?bbox={lon0},{lat0},{lon1},{lat1}"
j = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=60))
json.dump(j, open(name + "_osm.json", "w"))
nodes = {e["id"]: (e["lat"], e["lon"]) for e in j["elements"] if e["type"] == "node"}
d = ImageDraw.Draw(img)
rows = []
for e in j["elements"]:
    if e["type"] != "way": continue
    t = e.get("tags", {})
    pts = [nodes[n] for n in e["nodes"] if n in nodes]
    if len(pts) < 2: continue
    if "building" in t or t.get("landuse") or t.get("leisure") or t.get("amenity") or t.get("name"):
        col = (255, 220, 0) if "building" in t else (0, 255, 255)
        if "highway" in t: col = (255, 120, 255)
        d.line([px(*p) for p in pts], fill=col, width=2)
        la = sum(p[0] for p in pts) / len(pts); lo = sum(p[1] for p in pts) / len(pts)
        if t.get("name") or t.get("building:levels") or t.get("height"):
            gx, gz = game(la, lo)
            rows.append((t.get("name", ""), t.get("building", ""), t.get("building:levels", ""), t.get("height", ""), t.get("highway", ""), e["id"], round(la, 6), round(lo, 6), round(gx), round(gz), len(pts)))
            if "building" in t and (t.get("name") or t.get("building:levels")):
                d.text(px(la, lo), (t.get("name", "") or "")[:18] + " " + t.get("building:levels", ""), fill=(255, 255, 255))
mpp = 156543.03392 * math.cos(math.radians((lat0 + lat1) / 2)) / 2 ** z
d.line([(20, H - 20), (20 + 100 / mpp, H - 20)], fill=(255, 255, 255), width=4); d.text((24, H - 40), "100 m, north up", fill=(255, 255, 255))
img.save(name + "_sat.jpg", quality=86); print("saved", img.size, "m/px", round(mpp, 3))
sys.stdout.reconfigure(encoding="utf-8")
for r in sorted(rows, key=lambda r: (r[4] != "", r[0])): print(r)
