# Downloads live game icons from the public thumbnails API and lays them out as a labelled sheet.
import json, sys, urllib.request, io
from PIL import Image, ImageDraw
def sheet(games, cols, out, title):
    ids = ','.join(g[0] for g in games)
    data = json.load(urllib.request.urlopen(f'https://thumbnails.roblox.com/v1/games/icons?universeIds={ids}&size=256x256&format=Png&isCircular=false'))['data']
    url = {str(d['targetId']): d['imageUrl'] for d in data}
    cs, pad, lh = 200, 8, 34
    rows = -(-len(games) // cols)
    im = Image.new('RGB', (cols * (cs + pad) + pad, rows * (cs + lh + pad) + pad + 30), (242, 242, 242)); dr = ImageDraw.Draw(im)
    dr.text((pad, 8), title, fill=(0, 0, 0))
    for k, (u, p, n) in enumerate(games):
        x, y = pad + (k % cols) * (cs + pad), 30 + pad + (k // cols) * (cs + lh + pad)
        try:
            ic = Image.open(io.BytesIO(urllib.request.urlopen(url[u]).read())).convert('RGB').resize((cs, cs))
            im.paste(ic, (x, y))
        except Exception as e: print('fail', n, e)
        dr.text((x, y + cs + 4), n[:30], fill=(0, 0, 0)); dr.text((x, y + cs + 18), f'{int(p):,} playing', fill=(90, 90, 90))
    im.save(out); print(out, len(games))
top = """10563114921|581059|Steal An Egg
1686885941|266103|Brookhaven RP
383310974|212939|Adopt Me
994732206|206782|Blox Fruits
7326934954|155383|99 Nights in the Forest
10766972131|143984|Throw Food For Animals
66654135|110365|Murder Mystery 2
7660436108|106625|Anime Crusaders
6035872082|97479|RIVALS
5569032992|96793|Dandys World
10773618503|88463|Hyper Realistic Ragdoll
3508322461|68559|Jujutsu Shenanigans
10778869268|29518|The Great Build
10773971368|14338|Barber Empire
10774598960|4931|Wings Fight
10774753641|8519|Silent Killer Simulator
10775182046|33437|Throw a Seed
10771159260|6793|Dig Deep
10770526777|38001|100 Miles Down the River
10777305926|21075|untitled monkey game
10777337522|26336|Crash Engine"""
sheet([l.split('|') for l in top.splitlines()], 7, 'icons_top_charts.png', 'Top Playing Now + Top Trending + Up-and-Coming, 27 Nov 2026')
