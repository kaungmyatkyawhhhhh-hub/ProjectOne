"""night_cut.py (26 Nov 2026, OverlapFix): rebuild one night-window cell mesh (Buildings.Night.Cell_<c>.NWH) without
the panes of buildings that were deleted.

Studio (tools/yangon/OverlapFix.luau `F.nightExport(part, boxes)`) prints the KEPT triangles as pages:
    @N<k>@ then lines "ax ay az bx by bz cx cy cz r g b" (world studs, 2 decimals; colour 0-255)
Save the pages (in order) to one text file, then:
    python night_cut.py pages.txt out.glb
-> out.glb (one mesh "NWH", world positions; glb.write_glb centres it and negates x / z for the importer) and prints the
centre / size to place the new MeshPart at (CFrame.new(centre), Size = size).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glb import Mesh, write_glb, check_glb  # noqa: E402


def main(src, out):
    m = Mesh()
    for line in open(src, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("@"):
            continue
        v = [float(x) for x in line.split()]
        a, b, c = tuple(v[0:3]), tuple(v[3:6]), tuple(v[6:9])
        m.tri(a, b, c, (0, 0), (0, 0), (0, 0), tuple(v[9:12]))
    info = write_glb(out, [("NWH", m)], generator="night_cut.py")
    bad = check_glb(out, info)
    print(json.dumps(dict(info=info, bad=bad)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
