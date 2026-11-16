"""kit_pack.py (2026-11-16, light pass): the packed detail format of the 1:1 kit buildings.

The place keeps only each building's shell; the detail (facade panels, piers, party walls, flat roof slabs, roof props,
drainpipes, AC units, compound walls, gates) is data, made on each client near the camera by
src/client/YangonKitStream.client.lua (decoder: src/shared/YangonKitData.lua). Fixed-width records, no separators,
64-symbol digits (B64 below), positions relative to the record's 256-stud tile:

  P  pid(2) x(4) y(3) z(4) yaw(3) sx(3) code(1)                  21 chars   a kit piece (stretched sx along X)
  Q  pid(2) x(4) y(3) z(4) yaw(3) sx(3) code(1) sy(3) sz(3)      27 chars   a kit piece scaled in Y / Z too
  B  x(4) y(3) z(4) yaw(3) sx(3) sy(3) sz(3) code(1)             25 chars   a plain Part (party walls, roof slabs)

  x, z: (v - tile origin + 16384) * 500      y: (v + 200) * 200        yaw: v / 2pi * 262144
  sx: (v - 0.1) * 50000    sy, sz: (v - 0.05) * 5000    B sizes: v * 200
pid and code are indices into the Meta lists (PIDS, CODES). The pid of a piece is the same in every district
(kit_panels.stable_id), so one template set serves the whole city.

    line(rec)               -> the readable line (Inst / Shell pages)
    write_rbxmx(path, name, detail, tile[, compact]) -> a Folder `name` of StringValues: Meta + one per tile ("i_j")
(2026-11-16) FORMAT=2 (buildings_1to1.py): a tile string starting with "!" holds kit_layout.py records (H buildings,
W compound-wall chains, laid out on the client) + old records; Meta adds FORMAT / ARCH / WALLS / WCOLS / LAYOUT.
"""
import math
import os
from xml.sax.saxutils import escape

B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
TWO_PI = 2 * math.pi


def enc(v, n):
    v = int(round(v))
    assert 0 <= v < 64 ** n, (v, n)
    return "".join(B64[(v >> (6 * (n - 1 - i))) & 63] for i in range(n))


def dec(s):
    v = 0
    for ch in s:
        v = v * 64 + B64.index(ch)
    return v


def line(rec):
    t = rec[0]
    if t == "P":
        _, pid, x, y, z, yaw, sx, code = rec
        return "%s %.5f %.3f %.3f %.3f %.5f %s" % (pid, sx, x, y, z, yaw, code)
    if t == "Q":
        _, pid, x, y, z, yaw, sx, code, sy, sz = rec
        return "%s %.5f %.3f %.3f %.3f %.5f %s %.4f %.4f" % (pid, sx, x, y, z, yaw, code, sy, sz)
    if t == "B":
        _, x, y, z, sx, sy, sz, yaw, code = rec
        return "B %.3f %.3f %.3f %.3f %.3f %.3f %.5f %s" % (x, y, z, sx, sy, sz, yaw, code)
    if t == "S":
        _, tile, x, y, z, sx, sy, sz, yaw, code, flat = rec
        return "S %s %.3f %.3f %.3f %.3f %.3f %.3f %.5f %s %d" % (tile, x, y, z, sx, sy, sz, yaw, code, flat)
    if t == "R":
        _, pid, sx, x, y, z, yaw, wall, sy, sz, roof = rec
        return "R %s %.4f %.3f %.3f %.3f %.5f %s %.4f %.4f %s" % (pid, sx, x, y, z, yaw, wall, sy, sz, roof)
    if t == "W":
        _, x, y, z, sx, sy, sz, yaw = rec
        return "W %.3f %.3f %.3f %.3f %.3f %.3f %.5f" % (x, y, z, sx, sy, sz, yaw)
    raise ValueError(t)


def _yaw(v):
    return enc(int(round((v % TWO_PI) / TWO_PI * 262144)) % 262144, 3)


def pack_tile(recs, x0, z0, pids, codes):
    out = []
    for rec in recs:
        t = rec[0]
        if t in ("P", "Q"):
            pid, x, y, z, yaw, sx, code = rec[1:8]
            s = ("P" if t == "P" else "Q") + enc(pids[pid], 2) + enc((x - x0 + 16384) * 500, 4) + enc((y + 200) * 200, 3) + \
                enc((z - z0 + 16384) * 500, 4) + _yaw(yaw) + enc((sx - 0.1) * 50000, 3) + B64[codes[code]]
            if t == "Q":
                s += enc((rec[8] - 0.05) * 5000, 3) + enc((rec[9] - 0.05) * 5000, 3)
            out.append(s)
        elif t == "B":
            x, y, z, sx, sy, sz, yaw, code = rec[1:9]
            out.append("B" + enc((x - x0 + 16384) * 500, 4) + enc((y + 200) * 200, 3) + enc((z - z0 + 16384) * 500, 4) +
                       _yaw(yaw) + enc(sx * 200, 3) + enc(sy * 200, 3) + enc(sz * 200, 3) + B64[codes[code]])
        else:
            raise ValueError(t)
    return "".join(out)


def write_rbxmx(path, name, detail, tile, compact=None):
    """compact = (records, raw, meta lines) (kit_layout, FORMAT=2): each tile string is "!" + its kit_layout records +
    its raw old records; `detail` (the expanded records) still gives PIDS / CODES"""
    pids, codes = {}, {}
    for recs in detail.values():
        for rec in recs:
            if rec[0] in ("P", "Q"):
                pids.setdefault(rec[1], len(pids))
                codes.setdefault(rec[7], len(codes))
            else:
                codes.setdefault(rec[8], len(codes))
    assert len(pids) < 4096 and len(codes) <= 64
    items = []
    meta = "TILE=%g\nPIDS=%s\nCODES=%s\n" % (tile, " ".join(sorted(pids, key=pids.get)), " ".join(sorted(codes, key=codes.get)))
    if compact:
        meta += compact[2]
    items.append(("Meta", meta))
    chars = 0
    for (i, j), recs in sorted(detail.items()):
        if compact:
            s = "!" + "".join(compact[0].get((i, j), ())) + pack_tile(compact[1].get((i, j), ()), i * tile, j * tile, pids, codes)
        else:
            s = pack_tile(recs, i * tile, j * tile, pids, codes)
        assert len(s) < 190000, (i, j, len(s))
        items.append(("%d_%d" % (i, j), s))
        chars += len(s)
    body = "".join('<Item class="StringValue" referent="R%d"><Properties><string name="Name">%s</string>'
                   '<string name="Value">%s</string></Properties></Item>' % (k + 2, n, escape(v)) for k, (n, v) in enumerate(items))
    x = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
         'version="4"><Item class="Folder" referent="R1"><Properties><string name="Name">%s</string></Properties>%s</Item>'
         '</roblox>' % (name, body))
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    open(path, "w", encoding="utf-8", newline="\n").write(x)
    return dict(chars=chars, tiles=len(detail), pids=len(pids), codes=len(codes), bytes=len(x.encode("utf-8")))
