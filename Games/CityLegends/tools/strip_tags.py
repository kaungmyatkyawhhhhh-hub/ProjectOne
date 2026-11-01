"""Copies a binary place/model file without its "Tags" property chunks, so Lune can read it
(Lune 0.10 fails on new Studio files: "Property X.Tags should be SharedString, but it was Tags").
usage: python -I tools/strip_tags.py in.rbxl out.rbxl"""
import sys, struct
import lz4.block
try:
    import zstandard
except ImportError:
    zstandard = None
src, dst = sys.argv[1], sys.argv[2]
b = open(src, "rb").read()
out = bytearray(b[:32])
pos, dropped = 32, 0
while pos < len(b):
    name = b[pos:pos + 4]
    clen, ulen, _ = struct.unpack_from("<III", b, pos + 4)
    body = b[pos + 16: pos + 16 + (clen if clen else ulen)]
    whole = b[pos: pos + 16 + len(body)]
    pos += 16 + len(body)
    if name == b"PROP":
        if clen == 0:
            data = body
        elif body[:4] == b"\x28\xb5\x2f\xfd":
            data = zstandard.ZstdDecompressor().decompress(body, max_output_size=ulen)
        else:
            data = lz4.block.decompress(body, uncompressed_size=ulen)
        n, = struct.unpack_from("<I", data, 4)
        if data[8:8 + n] == b"Tags":
            dropped += 1
            continue
    out += whole
    if name == b"END\0":
        out += b[pos:]
        break
open(dst, "wb").write(out)
print("dropped", dropped, "Tags chunks")
