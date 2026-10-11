"""Rewrite a binary place so Studio can open it.

Rojo can LZ4-compress a chunk to more bytes than it holds (the big SSTR chunk of
shared mesh data). Studio refuses such a chunk ("readData error ... chunk#0").
This stores any chunk that didn't shrink uncompressed instead.

    python3 tools/fix_rbxl.py CityLegends.rbxl
"""
import struct
import sys

import lz4.block

path = sys.argv[1]
b = open(path, "rb").read()
out = bytearray(b[:32])
i, fixed = 32, 0
while i < len(b):
    name = b[i:i + 4]
    clen, ulen, reserved = struct.unpack("<III", b[i + 4:i + 16])
    i += 16
    data = b[i:i + (clen or ulen)]
    i += clen or ulen
    if clen and clen >= ulen and data[:4] != b"\x28\xb5\x2f\xfd":
        data = lz4.block.decompress(data, uncompressed_size=ulen)
        clen = 0
        fixed += 1
    out += name + struct.pack("<III", clen, ulen, reserved) + data
    if name == b"END\x00":
        break
open(path, "wb").write(out)
print(f"stored {fixed} chunk(s) uncompressed")
