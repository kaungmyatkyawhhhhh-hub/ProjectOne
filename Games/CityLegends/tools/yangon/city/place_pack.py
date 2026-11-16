"""place_pack.py <tag> (2026-11-16, step 6, P3 downtown): a 1:1 district's whole placement in as few .rbxmx files as
possible, so the Studio turn is: one LoadAsset per file, parent, a few loops, the terrain writer.

    YANGON_SCALE=1to1 python place_pack.py P3

Reads what the offline tools wrote (all under Games/CityLegends):
  imports/sync/ygn1to1_<tag>/terrain_<tag>_a.rbxmx / _b.rbxmx   terrain.py modules packed by pack_strings.py (Folders
                                                                 P3TerrainA / B of ModuleScripts Terrain<tag>_<n>)
  imports/sync/ygn1to1_<tag>/ygnkit_<tag>.rbxmx                  buildings_1to1.py's Folder Data_<tag> (client detail)
  imports/sync/ygn1to1_green/green_<tag>.rbxmx                    green_1to1.py's Folder GreenHolding_<tag>
  build/city_1to1/buildings_<tag>/Shell_<n>.txt                   S shell boxes (written here as real Parts) and R
                                                                  pitched roofs (kit MeshParts: left as a StringValue
                                                                  `Roofs` for YangonKitPlace.shells, which clones them)
  build/city_1to1/pagodas_<tag>.txt                               PagodaPlace rows (StringValue `PagodaData`)
Writes imports/sync/ygn1to1_<tag>/place_<tag>_<k>.rbxmx (each < 19 MB, the Open Cloud limit is 20), one Folder
`<tag>Place_<k>` each:
  1: P3TerrainA (ModuleScripts), Data_<tag>, GreenHolding_<tag>
  2: P3TerrainB, Roofs, PagodaData
  3: Shell (Models Cell_<i>_<j> of Parts: the shells, already named by wall code, coloured, attribute T =
     tile, flat roofs with the concrete slab Texture; Material / MaterialVariant are set in Studio from the name by the
     same `look` as YangonKitPlace). Each Part is NAMED "<wall code>|<tile T>|<MaterialVariant>" (the variant
     YangonShellFacades would pick): AttributesSerialized written here did NOT survive the Open Cloud upload (16 Nov
     test), so the Studio load loop splits the name into Name, attribute T and MaterialVariant, and sets Plaster
The shell Parts are the same as YangonKitPlace.shells makes (Anchored, CanCollide / CanQuery on, CanTouch off, smooth
surfaces, CastShadow on).
"""
import base64
import sys as _s
_s.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
import math
import os
import re
import struct
import sys
from collections import defaultdict
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
TAG = sys.argv[1] if len(sys.argv) > 1 else "P3"
T = TAG.lower()
SYNC = os.path.join(ROOT, "imports", "sync", "ygn1to1_%s" % T)
B1 = os.path.join(ROOT, "build", "city_1to1")
LIMIT = 19_000_000

WALL = {"KW0": (252, 255, 250), "KW1": (255, 215, 153), "KW2": (178, 242, 255), "KW3": (199, 168, 130),
        "KW4": (226, 248, 255), "KW5": (255, 197, 187), "KW6": (255, 252, 243), "KW7": (208, 255, 165),
        "KWG": (162, 160, 150), "KWB": (173, 209, 250), "KWC": (144, 145, 136), "KWD2": (181, 172, 162)}
CONC_MAP = "rbxassetid://90233226321161"   # YgnConcreteBare colour map (build/materials/uploaded_ids.json)
CONC_TILE = 2.71 * 3                       # its StudsPerTile (tile 2.71 m)
HEAD = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'version="4">')


def inner(path, prefix):
    """the Items of an .rbxmx (without the <roblox> wrapper), referents renamed with a prefix"""
    s = open(path, encoding="utf-8").read()
    a = s.index(">", s.index("<roblox")) + 1
    b = s.rindex("</roblox>")
    return re.sub(r'referent="([^"]+)"', lambda m: 'referent="%s%s"' % (prefix, m.group(1)), s[a:b])


def attrs(d):
    out = struct.pack("<I", len(d))
    for k, v in d.items():
        kb, vb = k.encode(), v.encode()
        out += struct.pack("<I", len(kb)) + kb + b"\x02" + struct.pack("<I", len(vb)) + vb
    return base64.b64encode(out).decode()


def cframe(x, y, z, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    return ('<CoordinateFrame name="CFrame"><X>%.3f</X><Y>%.3f</Y><Z>%.3f</Z><R00>%.6f</R00><R01>0</R01><R02>%.6f</R02>'
            '<R10>0</R10><R11>1</R11><R12>0</R12><R20>%.6f</R20><R21>0</R21><R22>%.6f</R22></CoordinateFrame>'
            % (x, y, z, c, s, -s, c))


class Refs:
    def __init__(self, p):
        self.p, self.n = p, 0

    def __call__(self):
        self.n += 1
        return "%s%d" % (self.p, self.n)


GF = {"Walkup": 11.7, "Shop": 13.0, "Villa": 10.3}   # YangonShellFacades.F.GF
STAINED = {"KWG", "KWD2", "KWC"}


def facade_of(plots_tree, x, z, code, h):
    """the shell's MaterialVariant, as YangonShellFacades.apply picks it (the plot its middle lies in -> set, phase from
    the box height); attribute MV, set in Studio by the load loop"""
    from shapely.geometry import Point
    from shell_facades import SET_OF
    tree, polys, plots = plots_tree
    pt = Point(x, z)
    hit = [i for i in tree.query(pt) if polys[i].buffer(1.0).contains(pt)]
    arch = plots[hit[0]]["arch"] if hit else "house"
    st = SET_OF.get(arch, "none")
    if st == "none":
        return "YgnRenderStained" if code in STAINED else "YgnRenderPainted"
    s = {"walkup": "Walkup", "shop": "Shop", "villa": "Villa"}[st]
    d = (h - 1 - GF[s]) % 10.0
    return "YgnShell%s%d" % (s, int(math.floor(d / 2.5 + 0.5)) % 4)


def shell_items(ref):
    import json
    from shapely.geometry import Polygon
    from shapely.strtree import STRtree
    plots = json.load(open(os.path.join(B1, "buildings_%s" % TAG, "plots.json")))
    polys = [Polygon(q["poly"]) for q in plots]
    ptree = (STRtree(polys), polys, plots)
    cells = defaultdict(list)
    roofs = []
    n = 0
    for f in sorted(os.listdir(os.path.join(B1, "buildings_%s" % TAG))):
        if not f.startswith("Shell_"):
            continue
        for line in open(os.path.join(B1, "buildings_%s" % TAG, f)).read().split("\n"):
            w = line.split(" ")
            if w[0] == "R":
                roofs.append(line)
            elif w[0] == "S":
                x, y, z, sx, sy, sz, yaw = (float(v) for v in w[2:9])
                code = w[9]
                r, g, b = WALL.get(code, (255, 255, 255))
                tex = ""
                if len(w) > 10 and w[10] == "1":
                    tex = ('<Item class="Texture" referent="%s"><Properties><token name="Face">1</token>'
                           '<Content name="Texture"><url>%s</url></Content><float name="StudsPerTileU">%.2f</float>'
                           '<float name="StudsPerTileV">%.2f</float><Color3 name="Color3"><R>%.4f</R><G>%.4f</G>'
                           '<B>%.4f</B></Color3></Properties></Item>'
                           % (ref(), CONC_MAP, CONC_TILE, CONC_TILE, 196 / 255, 192 / 255, 184 / 255))
                cells[(math.floor(x / 1792), math.floor(z / 1792))].append(
                    '<Item class="Part" referent="%s"><Properties><string name="Name">%s</string>%s'
                    '<Vector3 name="size"><X>%.3f</X><Y>%.3f</Y><Z>%.3f</Z></Vector3>'
                    '<Color3uint8 name="Color3uint8">%d</Color3uint8><bool name="Anchored">true</bool>'
                    '<bool name="CanCollide">true</bool><bool name="CanQuery">true</bool><bool name="CanTouch">false</bool>'
                    '<bool name="CastShadow">true</bool><token name="TopSurface">0</token><token name="BottomSurface">0</token>'
                    '<BinaryString name="AttributesSerialized">%s</BinaryString></Properties>%s</Item>'
                    % (ref(), "%s|%s|%s" % (code, w[1], facade_of(ptree, x, z, code, sy)), cframe(x, y, z, yaw), sx, sy, sz,
                       (0xFF << 24) | (r << 16) | (g << 8) | b, attrs({"T": w[1]}), tex))
                n += 1
    models = ['<Item class="Model" referent="%s"><Properties><string name="Name">Cell_%d_%d</string></Properties>%s</Item>'
              % (ref(), i, j, "".join(parts)) for (i, j), parts in sorted(cells.items())]
    # (up to batch 3) packs over ~10 MB timed out on the Open Cloud upload: then the shells go in halves (packs 3 and 4)
    halves = [models] if sum(len(m) for m in models) < 10_000_000 else [models[:len(models) // 2], models[len(models) // 2:]]
    shell = ['<Item class="Folder" referent="%s"><Properties><string name="Name">Shell</string></Properties>%s</Item>' % (ref(), "".join(h))
             for h in halves]
    return shell, "\n".join(roofs) + "\n", n, len(cells)


def string_value(ref, name, text):
    return ('<Item class="StringValue" referent="%s"><Properties><string name="Name">%s</string>'
            '<string name="Value">%s</string></Properties></Item>' % (ref(), name, escape(text)))


def write(k, items):
    x = HEAD + '<Item class="Folder" referent="TOP%d"><Properties><string name="Name">%sPlace_%d</string></Properties>%s</Item></roblox>' % (
        k, TAG, k, "".join(items))
    p = os.path.join(SYNC, "place_%s_%d.rbxmx" % (T, k))
    open(p, "w", encoding="utf-8", newline="\n").write(x)
    size = len(x.encode("utf-8"))
    assert size < LIMIT, (p, size)
    print("wrote %s, %.1f MB" % (p, size / 1e6))


def main():
    ref = Refs("Q")
    items1 = [inner(os.path.join(SYNC, "terrain_%s_a.rbxmx" % T), "TA"),
              inner(os.path.join(SYNC, "ygnkit_%s.rbxmx" % T), "DK"),
              inner(os.path.join(ROOT, "imports", "sync", "ygn1to1_green", "green_%s.rbxmx" % T), "GR")]
    write(1, items1)
    shell, roofs, n, nc = shell_items(ref)
    items2 = [inner(os.path.join(SYNC, "terrain_%s_b.rbxmx" % T), "TB"), string_value(ref, "Roofs", roofs)]
    pg = os.path.join(B1, "pagodas_%s.txt" % TAG)
    if os.path.exists(pg):
        items2.append(string_value(ref, "PagodaData", open(pg, encoding="utf-8").read()))
    write(2, items2)
    for k, sh in enumerate(shell):
        write(3 + k, [sh])
    print("shell parts %d in %d cells, roofs %d" % (n, nc, roofs.count("\n")))


if __name__ == "__main__":
    main()
