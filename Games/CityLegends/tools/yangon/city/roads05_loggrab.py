# (20 Nov, P8) python roads05_loggrab.py <tag> [log file]: road-build slices printed into the Studio log by _G.P8PRINT
# ("P8SM <label> <k> <n> <i> <m> <chunk>", then "P8SMEND <label> <n> np <pages>") -> roads05_<tag>/pages/Q<label>_<kk>.txt
# (same page files as roads05_grab.py; an MCP result is cut at 100,000 chars, the log is not)
import base64, collections, glob, os, re, sys
import zstandard
G0 = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
tag = sys.argv[1]
log = sys.argv[2] if len(sys.argv) > 2 else max(glob.glob(os.path.join(os.environ['LOCALAPPDATA'], 'Roblox', 'logs', '*Studio*_last.log')), key=os.path.getmtime)
OUT = os.path.join(G0, 'build', 'city_1to1', 'roads05_' + tag, 'pages')
os.makedirs(OUT, exist_ok=True)
sl = collections.defaultdict(dict)
end = {}
for line in open(log, encoding='utf-8', errors='replace'):
    m = re.search(r'P8SM (\d+x\d+) (\d+) (\d+) (\d+) (\d+) (\S+)', line)
    if m:
        sl[m.group(1)][(int(m.group(2)), int(m.group(4)))] = (int(m.group(3)), int(m.group(5)), m.group(6))
    m = re.search(r'P8SMEND (\d+x\d+) (\d+) np (\d+)', line)
    if m:
        end[m.group(1)] = (int(m.group(2)), int(m.group(3)))
for label, (n, np_) in sorted(end.items()):
    d = sl[label]
    parts = []
    for k in range(1, n + 1):
        m = d[(k, 1)][1]
        parts.append(''.join(d[(k, i)][2] for i in range(1, m + 1)))  # KeyError = a lost log line
    body = zstandard.ZstdDecompressor().decompressobj().decompress(base64.b64decode(''.join(parts))).decode()
    pages = body.split('\n')
    assert len(pages) == np_, (label, len(pages), np_)
    for i, pg in enumerate(pages):
        open(os.path.join(OUT, 'Q%s_%02d.txt' % (label, 1 + i)), 'w', encoding='utf-8').write('@Q%s_%02d@%s@END@' % (label, 1 + i, pg))
    print(label, 'pages', np_, 'chars', len(body))
