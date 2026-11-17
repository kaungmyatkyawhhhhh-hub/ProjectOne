"""Build the Lua ART table: asset id, trim rect (alpha bbox) and 9-slice insets from the recipe proportions."""
import json, os, re
from PIL import Image
SKIN = os.environ.get('SKIN', '')  # SKIN=neon -> ids_neon.json + export_neon/ (icons stay from ids.json)
IDS = json.load(open('ids.json'))
if SKIN: IDS.update(json.load(open(f'ids_{SKIN}.json')))
EXP = 'export' + ('_' + SKIN if SKIN else '')
S, M = 2, 6
src = open('kitgen.html', encoding='utf8').read()
pieces = {n: (int(w), int(h), rec) for n, w, h, rec in re.findall(r"^\s+(\w+):\s*\[(\d+),\s*(\d+),\s*\(\) => (?:piece\(\d+, \d+, '(\w+)'|panel)", src, re.M)}
def recipe(rec, w, h):
    if rec == 'pill':   return dict(o=.089*h, r=.164*h, lip=.233*h, e=.082*h, line=0)
    if rec == 'button': return dict(o=.031*h*1.6, r=.095*h, lip=.109*h, e=.054*h, line=0)
    if rec == 'card':   return dict(o=.0217*w, r=.053*w, lip=.05*w, e=.027*w, line=.06*w)
    return dict(o=4, r=18, lip=0, e=0, line=10)   # panel: ring sits 10..15 pt in
out = []
for name, aid in IDS.items():
    im = Image.open(f'{EXP}/{name}.png' if os.path.exists(f'{EXP}/{name}.png') else f'export/{name}.png'); x0, y0, x1, y1 = im.getchannel('A').getbbox()
    if name in pieces:
        w, h, rec = pieces[name]; R = recipe(rec or 'panel', w, h)
        side = (R['o'] + max(R['r'], R['e']) + 1) * S
        top = (R['o'] + max(R['r'], R['e']) + 1) * S
        bot = (R['o'] + R['lip'] + max(R['r'], R['e'], R['line']) + 1) * S
        if rec is None: side = top = bot = (4 + 18 + 1) * S          # panel ring + corner
        out.append(f"\t{name} = {{ id = {aid}, rect = {{ {x0}, {y0}, {x1 - x0}, {y1 - y0} }}, slice = {{ {round(side)}, {round(top)}, {round(side)}, {round(bot)} }} }},")
    else:
        out.append(f"\t{name} = {{ id = {aid}, rect = {{ {x0}, {y0}, {x1 - x0}, {y1 - y0} }} }},")
print('\n'.join(out))
