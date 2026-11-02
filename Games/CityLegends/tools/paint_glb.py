"""Paints makers' logos, badges and brand text out of a downloaded car's .glb before conversion
(owner: no logos anywhere; the textures of Sketchfab cars carry shields, name plates and tyre
lettering). Pure Python (Pillow).

    python tools/paint_glb.py in.glb out.glb spec.json

spec.json:
  {
    "images": {
      "14": [ {"rect": [x0, y0, x1, y1]},          # each row filled from the pixel left of x0 to
                                                   # the pixel right of x1 (blended across), so
                                                   # stripes and plates carry on through
              {"ring": [cx, cy, r0, r1]},          # a tyre's sidewall: the ring filled with its
                                                   # own middle colour (lettering gone)
              {"solid": [x0, y0, x1, y1, r, g, b]},  # one plain colour
              {"clear": true} ]                    # the whole image see-through
    },
    "drop": ["Badge_Geo_lodA"]                     # nodes whose meshes go (badge geometry)
  }
Pixel coordinates are in the image's own size (top left 0, 0).
"""

import io
import json
import struct
import sys

from PIL import Image


def read_glb(path):
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20 : 20 + n])
    off = 20 + n
    blen = struct.unpack("<I", b[off : off + 4])[0]
    binc = b[off + 8 : off + 8 + blen]
    return j, binc


def write_glb(path, j, binc):
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    binc += b"\0" * ((4 - len(binc) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binc)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A))
        f.write(js)
        f.write(struct.pack("<II", len(binc), 0x004E4942))
        f.write(binc)


def fill_rect(im, x0, y0, x1, y1):
    px = im.load()
    W, H = im.size
    x0, x1 = max(0, x0), min(W - 1, x1)
    y0, y1 = max(0, y0), min(H - 1, y1)
    for y in range(y0, y1 + 1):
        a = px[x0 - 1, y] if x0 > 0 else None
        b = px[x1 + 1, y] if x1 < W - 1 else None
        a = a or b
        b = b or a
        for x in range(x0, x1 + 1):
            t = (x - x0 + 1) / (x1 - x0 + 2)
            px[x, y] = tuple(int(round(a[k] + (b[k] - a[k]) * t)) for k in range(len(a)))


def fill_ring(im, cx, cy, r0, r1):
    px = im.load()
    W, H = im.size
    pts = []
    for y in range(max(0, cy - r1), min(H, cy + r1 + 1)):
        for x in range(max(0, cx - r1), min(W, cx + r1 + 1)):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if r0 * r0 <= d2 <= r1 * r1:
                pts.append((x, y))
    if not pts:
        return
    vals = sorted(px[x, y] for x, y in pts)
    # the middle colour by brightness (the plain rubber, not the lettering)
    vals.sort(key=lambda c: sum(c[:3]))
    mid = vals[len(vals) // 2]
    for x, y in pts:
        px[x, y] = mid


def main():
    src, out, spec_path = sys.argv[1:4]
    spec = json.load(open(spec_path))
    j, binc = read_glb(src)
    chunks = []  # (bufferView index, new bytes)
    for key, ops in spec.get("images", {}).items():
        im_entry = j["images"][int(key)]
        bv = j["bufferViews"][im_entry["bufferView"]]
        o = bv.get("byteOffset", 0)
        im = Image.open(io.BytesIO(binc[o : o + bv["byteLength"]]))
        mode = "RGBA" if im.mode in ("RGBA", "LA", "P") else "RGB"
        im = im.convert(mode)
        for op in ops:
            if "rect" in op:
                fill_rect(im, *op["rect"])
            elif "ring" in op:
                fill_ring(im, *op["ring"])
            elif "solid" in op:
                x0, y0, x1, y1, r, g, b = op["solid"]
                im.paste((r, g, b, 255) if im.mode == "RGBA" else (r, g, b), (x0, y0, x1 + 1, y1 + 1))
            elif op.get("clear"):
                im = im.convert("RGBA")
                im.putalpha(0)
        buf = io.BytesIO()
        im.save(buf, "PNG", optimize=True)
        chunks.append((im_entry["bufferView"], buf.getvalue()))
        im_entry["mimeType"] = "image/png"
    # rebuild the binary chunk: every buffer view copied in order, the changed ones replaced
    changed = dict(chunks)
    order = sorted(range(len(j["bufferViews"])), key=lambda i: j["bufferViews"][i].get("byteOffset", 0))
    new = bytearray()
    for i in order:
        bv = j["bufferViews"][i]
        data = changed.get(i)
        if data is None:
            o = bv.get("byteOffset", 0)
            data = binc[o : o + bv["byteLength"]]
        while len(new) % 4:
            new += b"\0"
        bv["byteOffset"] = len(new)
        bv["byteLength"] = len(data)
        new += data
    j["buffers"][0]["byteLength"] = len(new)
    dropped = 0
    names = set(spec.get("drop", []))
    if names:
        def walk(i, under):
            nd = j["nodes"][i]
            hit = under or nd.get("name") in names
            nonlocal dropped
            if hit and "mesh" in nd:
                del nd["mesh"]
                dropped += 1
            for c in nd.get("children", []):
                walk(c, hit)
        for s in j["scenes"]:
            for r in s["nodes"]:
                walk(r, False)
    write_glb(out, j, bytes(new))
    print(f"{len(chunks)} images painted, {dropped} meshes dropped -> {out}")


if __name__ == "__main__":
    main()
