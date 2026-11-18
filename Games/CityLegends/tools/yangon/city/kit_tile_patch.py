"""kit_tile_patch.py (19 Nov 2026, map bug fixes): write changed YgnKit Data_* tiles from Studio into the repo copies.

Studio side returns '@KT<folder>|<tile>|<zstd+base64 of the new tile string>@' lines (an empty payload = tile removed).
  python tools/yangon/city/kit_tile_patch.py <dump file> [<dump file> ...]
Updates build/city_1to1/kit_place_P123/data_place_18nov.json and the canonical rbxmx copy of each folder, then
re-reads each file and checks every patched tile.
"""
import base64, json, re, sys
from xml.sax.saxutils import escape
import zstandard

ROOT = 'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/'
JSON = ROOT + 'build/city_1to1/kit_place_P123/data_place_18nov.json'
FILES = {
    'Data_P1': 'imports/sync/ygn1to1_p1/ygnkit_p1.rbxmx', 'Data_P2': 'imports/sync/ygn1to1_p2/ygnkit_p2.rbxmx',
    'Data_P3': 'imports/sync/ygn1to1_p3/ygnkit_p3.rbxmx', 'Data_P1G': 'imports/sync/ygn1to1_green/green_p1.rbxmx',
    'Data_P2G': 'imports/sync/ygn1to1_green/green_p2.rbxmx', 'Data_P3G': 'imports/sync/ygn1to1_green/green_p3.rbxmx',
    'Data_P1S': 'imports/sync/ygn1to1_street/ygnstreet_p1.rbxmx',
    'Data_P1P': 'build/city_1to1/places_P1/ygnplaces_p1.rbxmx', 'Data_P2P': 'build/city_1to1/places_P2/ygnplaces_p2.rbxmx',
}
PAT = re.compile(r'@KT(Data_\w+)\|(-?\d+_-?\d+)\|([A-Za-z0-9+/=]*)@')


def folder_span(s, name):
    """(start, end) of the Folder item called name in an rbxmx string."""
    k = s.find('<string name="Name">%s</string>' % name)
    assert k >= 0, name
    a = s.rfind('<Item class="Folder"', 0, k)
    depth, i = 0, a
    while True:
        o, c = s.find('<Item ', i + 1), s.find('</Item>', i + 1)
        if o != -1 and o < c:
            depth += 1
            i = o
        else:
            if depth == 0:
                return a, c + 7
            depth -= 1
            i = c


def tile_re(tile):
    return re.compile(r'(<Item class="StringValue" referent="[^"]*"><Properties><string name="Name">%s</string>'
                      r'<string name="Value">)(.*?)(</string>)' % re.escape(tile), re.S)


def main(paths):
    dz = zstandard.ZstdDecompressor()
    new = {}
    for p in paths:
        for f, t, b in PAT.findall(open(p, encoding='utf-8', errors='replace').read()):
            new.setdefault(f, {})[t] = dz.decompress(base64.b64decode(b), max_output_size=1 << 26).decode('utf-8') if b else None
    data = json.load(open(JSON, encoding='utf-8'))
    for f, tiles in new.items():
        path = ROOT + FILES[f]
        s = open(path, encoding='utf-8').read()
        a, e = folder_span(s, f)
        body = s[a:e]
        for t, v in tiles.items():
            rx = tile_re(t)
            m = rx.search(body)
            assert m, (f, t)
            if v is None:
                body = body[:m.start()] + body[m.end():].split('</Item>', 1)[1]
                data[f].pop(t, None)
            else:
                body = body[:m.start(2)] + escape(v) + body[m.end(2):]
                data[f][t] = v
        s = s[:a] + body + s[e:]
        open(path, 'w', encoding='utf-8', newline='').write(s)
        # check
        s2 = open(path, encoding='utf-8').read()
        a, e = folder_span(s2, f)
        for t, v in tiles.items():
            m = tile_re(t).search(s2[a:e])
            assert (m is None) if v is None else (m and m.group(2) == escape(v)), (f, t)
        print(f, len(tiles), 'tiles patched + checked in', FILES[f])
    json.dump(data, open(JSON, 'w', encoding='utf-8'))


if __name__ == '__main__':
    main(sys.argv[1:])
