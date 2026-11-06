"""
Road meshes, step 1 (2026-11-06): gathers what Studio exported.

Studio's execute_luau returns at most 100,000 characters, and a big result lands in a file in the
session's tool-results folder. The export (see the road notes) returned the road triangles (@R..@), the
kerb / pavement / shoulder lines (@C..@), the white lines (@L..@) and the drives (@A00@) in slices.
This finds those files and joins each kind into one file.

run:  python tools/road_mesh/collect.py <tool-results folder> <out folder>
"""
import glob
import json
import os
import re
import sys

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
parts = {}
for p in glob.glob(os.path.join(src, "*")):
    if not (p.endswith(".txt") or p.endswith(".json")):
        continue
    if os.path.getsize(p) < 1000:
        continue
    raw = open(p, encoding="utf-8").read()
    if p.endswith(".json"):
        try:
            raw = "".join(x.get("text", "") for x in json.loads(raw))
        except Exception:
            continue
    m = re.match(r"@([RCLAI])(\d\d)@", raw)
    if not m:
        continue
    body = raw[m.end():]
    end = body.find("@END@")
    if end >= 0:
        body = body[:end]
    key = (m.group(1), int(m.group(2)))
    # (a later export of the same slice wins)
    if key not in parts or os.path.getmtime(p) > parts[key][0]:
        parts[key] = (os.path.getmtime(p), body)

for kind in "RCLAI":
    keys = sorted(k for k in parts if k[0] == kind)
    text = "".join(parts[k][1] for k in keys)
    open(os.path.join(out, kind + ".txt"), "w", encoding="utf-8", newline="\n").write(text)
    print(kind, len(keys), "slices", len(text), "chars")
