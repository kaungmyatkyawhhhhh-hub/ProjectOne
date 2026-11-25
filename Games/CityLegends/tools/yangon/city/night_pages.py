"""night_pages.py (26 Nov 2026, OverlapFix): night-window cell meshes from Studio export pages.

Studio prints pages "@<tag><n>@" + text: "#<cell> cx cy cz" headers, then one line per kept triangle: 9 x 3 base-64
digits (corner offsets from the cell centre x 20 + 131072) + a colour letter (a 255,220,170 / b 220,236,255 /
c 255,236,200). Pages may end padded with '#'.
    python night_pages.py <outdir> <page files in order...>
-> <outdir>/night_<cell>.glb per cell (glb.write_glb: world positions, centred, x / z negated for the importer) and
night_info.json (centre / size to place each new MeshPart at).
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb import Mesh, write_glb, check_glb  # noqa: E402

B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
V = {c: i for i, c in enumerate(B64)}
COL = {"a": (255, 220, 170), "b": (220, 236, 255), "c": (255, 236, 200)}


def d3(s):
    return (V[s[0]] * 4096 + V[s[1]] * 64 + V[s[2]] - 131072) / 20


def main(out, files):
    text = ""
    for f in files:
        s = open(f, encoding="utf-8").read()
        if s.startswith("["):  # a tool-result JSON wrapper
            s = json.load(open(f, encoding="utf-8"))[0]["text"]
        m = re.match(r"@[A-Za-z]+\d+@", s)
        text += s[m.end():].rstrip("#")
    cells, cur = {}, None
    for line in text.split("\n"):
        if not line:
            continue
        if line[0] == "#":
            name, x, y, z = line[1:].split()
            cur = (name, float(x), float(y), float(z))
            cells[name] = []
            continue
        assert len(line) == 28, (len(line), line[:40])
        _, cx, cy, cz = cur
        pts = [(cx + d3(line[o:o + 3]), cy + d3(line[o + 3:o + 6]), cz + d3(line[o + 6:o + 9])) for o in (0, 9, 18)]
        cells[cur[0]].append((pts, COL[line[27]]))
    os.makedirs(out, exist_ok=True)
    res = {}
    for name, tris in cells.items():
        m = Mesh()
        for p, col in tris:
            m.tri(p[0], p[1], p[2], (0, 0), (0, 0), (0, 0), col)
        path = os.path.join(out, "night_%s.glb" % name)
        info = write_glb(path, [("NWH", m)], generator="night_pages.py")
        res[name] = dict(info=info["NWH"], tris=len(tris), check=check_glb(path, info))
        print(name, len(tris), info["NWH"]["centre"], info["NWH"]["size"], res[name]["check"])
    json.dump(res, open(os.path.join(out, "night_info.json"), "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
