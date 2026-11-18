# copy complete @Q pages and zipped @Z slices (zstd + base64 of pages joined by \n) from this run's tool-results
# into roads05_RB12/pages as plain @Q page files (roads05_bake.py collect reads them); print counts per cell
import base64, collections, glob, json, os, re, sys
import zstandard

TR = r"C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results"
OUT = r"D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/city_1to1/roads05_RB12/pages"
os.makedirs(OUT, exist_ok=True)
SINCE = os.path.getmtime(os.path.join(TR, 'mcp-Roblox_Studio-execute_luau-1794989639494.txt')) - 2
Z = collections.defaultdict(dict)
for p in sorted(glob.glob(os.path.join(TR, '*')), key=os.path.getmtime):
    if os.path.getmtime(p) < SINCE or not (p.endswith('.txt') or p.endswith('.json')) or os.path.getsize(p) < 1000:
        continue
    raw = open(p, encoding='utf-8', errors='replace').read()
    if raw.startswith('['):
        try:
            raw = ''.join(x.get('text', '') for x in json.loads(raw))
        except Exception:
            pass
    z = re.search(r'@Z([0-9]+x[0-9]+)_(\d\d)_(\d\d)_(\d\d)@', raw[:200])
    if z:
        e = raw.find('@END@', z.end())
        if e > 0:
            Z[(z.group(1), int(z.group(2)), int(z.group(4)))][int(z.group(3))] = raw[z.end():e]
        continue
    m = re.search(r'@Q([0-9]+x[0-9]+)_(\d\d)@', raw[:200])
    if not m or raw.find('@END@', m.end()) < 0:
        continue
    open(os.path.join(OUT, 'Q%s_%s.txt' % (m.group(1), m.group(2))), 'w', encoding='utf-8').write(raw[m.start():raw.find('@END@', m.end()) + 5])
for (cell, first, n), sl in Z.items():
    if len(sl) != n:
        print('zip', cell, first, 'has', sorted(sl), 'of', n)
        continue
    data = base64.b64decode(''.join(sl[i] for i in range(1, n + 1)))
    body = zstandard.ZstdDecompressor().decompressobj().decompress(data).decode()
    for i, pg in enumerate(body.split('\n')):
        open(os.path.join(OUT, 'Q%s_%02d.txt' % (cell, first + i)), 'w', encoding='utf-8').write('@Q%s_%02d@%s@END@' % (cell, first + i, pg))
c = collections.defaultdict(list)
for f in os.listdir(OUT):
    m = re.match(r'Q(\d+x\d+)_(\d+)\.txt', f)
    if m:
        c[m.group(1)].append(int(m.group(2)))
for k in sorted(c):
    ks = sorted(c[k])
    print(k, len(ks), 'max', ks[-1], 'missing', [i for i in range(1, ks[-1] + 1) if i not in ks])
