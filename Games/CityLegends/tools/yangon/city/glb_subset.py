"""glb_subset.py out.glb prefixes.txt in1.glb [in2.glb ...] (2026-11-16, step 5): a .glb with only the meshes whose node
name starts with one of the prefixes (one a line, e.g. KGR_p0d46cd4b). Used to upload just the kit pieces a new district
needs that the shared template set (ReplicatedStorage.YgnKit.Templates) lacks, so no piece is uploaded twice."""
import json, struct, sys


def read(path):
    b = open(path, 'rb').read()
    assert b[:4] == b'glTF'
    off, js, bin_ = 12, None, b''
    while off < len(b):
        ln, typ = struct.unpack_from('<II', b, off)
        chunk = b[off + 8: off + 8 + ln]
        if typ == 0x4E4F534A:
            js = json.loads(chunk)
        else:
            bin_ = chunk
        off += 8 + ln
    return js, bin_


def main():
    out, pref_p, ins = sys.argv[1], sys.argv[2], sys.argv[3:]
    prefs = [l.strip() for l in open(pref_p) if l.strip()]
    J = dict(asset={'version': '2.0', 'generator': 'glb_subset.py'}, scene=0, scenes=[{'nodes': []}], nodes=[], meshes=[],
             accessors=[], bufferViews=[], buffers=[])
    blob = bytearray()
    found = set()
    for path in ins:
        js, b = read(path)
        for node in js['nodes']:
            nm = node.get('name', '')
            hit = [p for p in prefs if nm.startswith(p + '_') or nm == p]
            if not hit or 'mesh' not in node:
                continue
            found.update(hit)
            mesh = json.loads(json.dumps(js['meshes'][node['mesh']]))
            for prim in mesh['primitives']:
                def take(ai):
                    acc = dict(js['accessors'][ai])
                    bv = dict(js['bufferViews'][acc['bufferView']])
                    data = b[bv.get('byteOffset', 0): bv.get('byteOffset', 0) + bv['byteLength']]
                    while len(blob) % 4:
                        blob.append(0)
                    bv['byteOffset'] = len(blob)
                    bv['buffer'] = 0
                    blob.extend(data)
                    J['bufferViews'].append(bv)
                    acc['bufferView'] = len(J['bufferViews']) - 1
                    J['accessors'].append(acc)
                    return len(J['accessors']) - 1
                prim['attributes'] = {k: take(v) for k, v in prim['attributes'].items()}
                if 'indices' in prim:
                    prim['indices'] = take(prim['indices'])
                prim.pop('material', None)
            J['meshes'].append(mesh)
            n2 = {k: v for k, v in node.items() if k != 'children'}
            n2['mesh'] = len(J['meshes']) - 1
            J['nodes'].append(n2)
            J['scenes'][0]['nodes'].append(len(J['nodes']) - 1)
    while len(blob) % 4:
        blob.append(0)
    J['buffers'] = [{'byteLength': len(blob)}]
    if any('materials' in read(p)[0] for p in ins[:1]):
        pass
    js_b = json.dumps(J, separators=(',', ':')).encode()
    while len(js_b) % 4:
        js_b += b' '
    total = 12 + 8 + len(js_b) + 8 + len(blob)
    with open(out, 'wb') as f:
        f.write(struct.pack('<III', 0x46546C67, 2, total))
        f.write(struct.pack('<II', len(js_b), 0x4E4F534A) + js_b)
        f.write(struct.pack('<II', len(blob), 0x004E4942) + bytes(blob))
    miss = [p for p in prefs if p not in found]
    print('%d meshes, %d bytes; not found: %s' % (len(J['meshes']), total, miss))


if __name__ == '__main__':
    main()
