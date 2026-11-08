"""
Road meshes for a few cells again, after a road was changed in the place (2026-11-08, the East Switchbacks loop link).

Takes the full export of 2026-11-06 (collect.py's folder), and for the given cells swaps in what the place holds now:
  R  the road triangles, from Studio pages "@W<n>@<count>;x y z x y z x y z ..." (each wedge's top face, x50)
  L  the lines, from a Studio page "@V1@<count>;cx cy cz hlx hly hlz hwx hwy hwz ..." (x50)
  C  the kerb / pavement / shoulder chains: the old ones with the points on the removed stretch taken out, plus new
     chains along tools/riviera/looplink.json
Then build.py and export_fbx.py run as usual; keep only the meshes of the cells (cells.json in the out folder).

run:  python tools/road_mesh/patch_cells.py <collect folder> <out folder> <W/V page files...>
"""
import json
import math
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+,-./:;<=>?@[]^_{|}"
B = len(BASE)
M = (B * B - 1) // 2
IDX = {c: i for i, c in enumerate(BASE)}
Q = 50.0
CELL = 384
CELLS = {(44, -2), (44, -1), (45, -2), (45, -1)}

src, out = sys.argv[1], sys.argv[2]
pages = sys.argv[3:]
os.makedirs(out, exist_ok=True)


def decode(s, i=0):
    n = len(s)
    while i < n:
        c = s[i]
        if c == "~":
            j = s.index("~", i + 1)
            yield int(s[i + 1 : j])
            i = j + 1
        else:
            yield (IDX[c] * B + IDX[s[i + 1]]) - M
            i += 2


def enc(v):
    v = int(v)
    if -M <= v <= M:
        u = v + M
        return BASE[u // B] + BASE[u % B]
    return "~%d~" % v


def cell(x, z):
    return (int(x // CELL), int(z // CELL))


def page_text(p):
    raw = open(p, encoding="utf-8").read()
    if p.endswith(".json"):
        raw = "".join(x.get("text", "") for x in json.loads(raw))
    m = re.search(r"@([WV])(\d+)@(\d+);(.*?)@END@", raw, re.S)
    return m.group(1), int(m.group(2)), m.group(4)


# --- R ---------------------------------------------------------------------------------------------------------------
v = list(decode(open(os.path.join(src, "R.txt"), encoding="utf-8").read()))
tris = []
px = py = pz = 0
for k in range(0, len(v), 9):
    px += v[k]
    py += v[k + 1]
    pz += v[k + 2]
    a = (px, py, pz)
    b = (px + v[k + 3], py + v[k + 4], pz + v[k + 5])
    c = (px + v[k + 6], py + v[k + 7], pz + v[k + 8])
    tris.append((a, b, c))
old_n = len(tris)
tris = [t for t in tris if cell((t[0][0] + t[1][0] + t[2][0]) / 3 / Q, (t[0][2] + t[1][2] + t[2][2]) / 3 / Q) not in CELLS]
new_lines = []
added = 0
for p in pages:
    kind, _, body = page_text(p)
    nums = [int(x) for x in body.split()]
    if kind == "W":
        for k in range(0, len(nums), 9):
            a, b, c = tuple(nums[k : k + 3]), tuple(nums[k + 3 : k + 6]), tuple(nums[k + 6 : k + 9])
            if cell((a[0] + b[0] + c[0]) / 3 / Q, (a[2] + b[2] + c[2]) / 3 / Q) in CELLS:
                tris.append((a, b, c))
                added += 1
    else:
        for k in range(0, len(nums), 9):
            new_lines.append(tuple(nums[k : k + 9]))
print("R", old_n, "->", len(tris), "(added", added, ")")
parts = []
px = py = pz = 0
for a, b, c in tris:
    parts.append(enc(a[0] - px) + enc(a[1] - py) + enc(a[2] - pz))
    px, py, pz = a
    parts.append(enc(b[0] - a[0]) + enc(b[1] - a[1]) + enc(b[2] - a[2]) + enc(c[0] - a[0]) + enc(c[1] - a[1]) + enc(c[2] - a[2]))
open(os.path.join(out, "R.txt"), "w", encoding="utf-8", newline="\n").write("".join(parts))

# --- L ---------------------------------------------------------------------------------------------------------------
v = list(decode(open(os.path.join(src, "L.txt"), encoding="utf-8").read()))
lines = []
px = py = pz = 0
for k in range(0, len(v), 9):
    px += v[k]
    py += v[k + 1]
    pz += v[k + 2]
    lines.append((px, py, pz) + tuple(v[k + 3 : k + 9]))
old_n = len(lines)
lines = [ln for ln in lines if cell(ln[0] / Q, ln[2] / Q) not in CELLS]
lines += [ln for ln in new_lines if cell(ln[0] / Q, ln[2] / Q) in CELLS]
print("L", old_n, "->", len(lines))
parts = []
px = py = pz = 0
for ln in lines:
    parts.append(enc(ln[0] - px) + enc(ln[1] - py) + enc(ln[2] - pz) + "".join(enc(x) for x in ln[3:9]))
    px, py, pz = ln[0], ln[1], ln[2]
open(os.path.join(out, "L.txt"), "w", encoding="utf-8", newline="\n").write("".join(parts))

# --- C ---------------------------------------------------------------------------------------------------------------
link = json.load(open(os.path.join(HERE, "..", "riviera", "looplink.json")))
OLD = link["old_path"]
PATH = link["pts"]
Mn = len(OLD)
P0 = OLD[0]
QQ = OLD[-1]
qd = (PATH[-1][3], PATH[-1][4])


def nearest(lst, x, z, i0=0, i1=None):
    best, by = 1e18, 0
    i1 = len(lst) - 1 if i1 is None else i1
    for k in range(i0, i1):
        a, b = lst[k], lst[k + 1]
        dx, dz = b[0] - a[0], b[2] - a[2]
        L2 = dx * dx + dz * dz
        u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[2]) * dz) / L2)) if L2 > 0 else 0.0
        d = math.hypot(x - a[0] - dx * u, z - a[2] - dz * u)
        if d < best:
            best, by = d, a[1] + (b[1] - a[1]) * u
    return best, by


def removed(x, y, z):
    """the same test as LoopLink.clear (+ the mouth and the leg past the join kept)"""
    rel = (x - QQ[0], z - QQ[2])
    if rel[0] * qd[0] + rel[1] * qd[1] > 0.5 and math.hypot(*rel) < 75:
        return False
    if 110 < y < 205:
        d, _ = nearest(OLD, x, z, 1, Mn - 2)
        if d <= 32 + 0.9 + 10 + 3 and math.hypot(x - P0[0], z - P0[2]) > 40:
            dq = math.hypot(x - QQ[0], z - QQ[2])
            dl, _ = nearest(OLD, x, z, Mn - 4, Mn - 1)
            if not (dq < 30 and dl <= d + 0.01):
                return True
    if 170 < y < 200:
        d, _ = nearest(OLD, x, z, 0, 11)
        if d < 46 and math.hypot(x - P0[0], z - P0[2]) < 75:
            return True
    return False


def at(s, off):
    if s < 0:
        a = PATH[0]
        return (a[0] + a[3] * s - a[4] * off, a[1], a[2] + a[4] * s + a[3] * off)
    k = 0
    while k < len(PATH) - 2 and PATH[k + 1][5] < s:
        k += 1
    a, b = PATH[k], PATH[k + 1]
    t = max(0.0, min(1.0, (s - a[5]) / max(b[5] - a[5], 1e-6)))
    x = a[0] + (b[0] - a[0]) * t
    y = a[1] + (b[1] - a[1]) * t
    z = a[2] + (b[2] - a[2]) * t
    dx, dz = a[3] + (b[3] - a[3]) * t, a[4] + (b[4] - a[4]) * t
    L = math.hypot(dx, dz)
    dx, dz = dx / L, dz / L
    return (x - dz * off, y, z + dx * off)


def read_chains():
    out_ = []
    for line in open(os.path.join(src, "C.txt"), encoding="utf-8").read().split("\n"):
        if not line:
            continue
        kind, road, side, variant, width, data = line.split("|", 5)
        pts, cols = [], []
        i, n = 0, len(data)
        px = py = pz = 0
        while i < n:
            vals = []
            while len(vals) < 3:
                if data[i] == "~":
                    j = data.index("~", i + 1)
                    vals.append(int(data[i + 1 : j]))
                    i = j + 1
                else:
                    vals.append((IDX[data[i]] * B + IDX[data[i + 1]]) - M)
                    i += 2
            px += vals[0]
            py += vals[1]
            pz += vals[2]
            pts.append((px, py, pz))
            cols.append(int(data[i]))
            i += 1
        out_.append([kind, road, side, variant, width, pts, cols])
    return out_


chains = read_chains()
# how high an East Switchbacks kerb / pavement point sits over the road's middle (to lay the new ones the same)
lift = {"K": [], "P": []}
for ch in chains:
    if ch[1] == "East Switchbacks" and ch[0] in lift:
        for p in ch[5][::7]:
            d, y = nearest(OLD, p[0] / Q, p[2] / Q, 30, Mn - 2)
            if d < 40:
                lift[ch[0]].append(p[1] / Q - y)
lift = {k: (sorted(v)[len(v) // 2] if v else 0.0) for k, v in lift.items()}
print("chain heights over the road's middle", {k: round(x, 2) for k, x in lift.items()})
kept = []
cut = 0
for ch in chains:
    kind, road, side, variant, width, pts, cols = ch
    run, rc = [], []
    for p, c in zip(pts, cols):
        if road == "East Switchbacks" and removed(p[0] / Q, p[1] / Q, p[2] / Q):
            cut += 1
            if len(run) >= 2:
                kept.append([kind, road, side, variant, width, run, rc])
            run, rc = [], []
        else:
            run.append(p)
            rc.append(c)
    if len(run) >= 2:
        kept.append([kind, road, side, variant, width, run, rc])
print("C points cut", cut, "chains", len(chains), "->", len(kept))
total = PATH[-1][5]
for kind, width, off, first_l, first_r in (("K", "0.90", 32.45, -12.0, 30.0), ("P", "10.00", 37.05, -12.0, 30.0)):
    for side, sign, first in ((-1, -1, first_l), (1, 1, first_r)):
        pts = []
        s = first
        while s < total:
            x, y, z = at(s, sign * off)
            pts.append((round(x * Q), round((y + lift[kind]) * Q), round(z * Q)))
            s += 4.0
        x, y, z = at(total, sign * off)
        pts.append((round(x * Q), round((y + lift[kind]) * Q), round(z * Q)))
        # on to the end of the leg's own kerb / pavement just past the join (a gap and a notch there otherwise)
        best, bp = 8.0 * Q, None
        for ch in kept:
            if ch[1] == "East Switchbacks" and ch[0] == kind:
                for e in (ch[5][0], ch[5][-1]):
                    dd = math.hypot(e[0] - pts[-1][0], e[2] - pts[-1][2])
                    if dd < best:
                        best, bp = dd, e
        if bp is not None:
            pts.append(bp)
        kept.append([kind, "East Switchbacks", str(side), "", width, pts, [0] * len(pts)])
lines_out = []
for kind, road, side, variant, width, pts, cols in kept:
    parts = []
    px = py = pz = 0
    for p, c in zip(pts, cols):
        parts.append(enc(p[0] - px) + enc(p[1] - py) + enc(p[2] - pz) + str(c))
        px, py, pz = p
    lines_out.append("|".join([kind, road, str(side), variant, width, "".join(parts)]))
open(os.path.join(out, "C.txt"), "w", encoding="utf-8", newline="\n").write("\n".join(lines_out) + "\n")
for f in ("A.txt", "I.txt"):
    shutil.copy(os.path.join(src, f), os.path.join(out, f))
json.dump(sorted(CELLS), open(os.path.join(out, "cells.json"), "w"))
print("wrote", out)
