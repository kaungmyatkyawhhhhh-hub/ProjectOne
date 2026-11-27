# One row: our v3 icon next to the strongest live gym icons, same size, for critique.
import json, urllib.request, io
from PIL import Image, ImageDraw
G = {'6443367640':'Gym Star','9867866217':'Gym Universe','10771388664':'Muscle Parade','2564505263':'Strongman Sim','1268927906':'Muscle Legends'}
d = json.load(urllib.request.urlopen('https://thumbnails.roblox.com/v1/games/icons?universeIds='+','.join(G)+'&size=512x512&format=Png&isCircular=false'))['data']
tiles = [('A: OURS', Image.open('gymarc_v3_normal_logo_512.png'))] + [(chr(66+i)+': '+G[str(e['targetId'])], Image.open(io.BytesIO(urllib.request.urlopen(e['imageUrl']).read()))) for i,e in enumerate(d)]
S=320; sh = Image.new('RGB', (len(tiles)*(S+16)+16, S+50), (240,240,240)); dr = ImageDraw.Draw(sh)
for i,(n,t) in enumerate(tiles):
    sh.paste(t.convert('RGB').resize((S,S), Image.LANCZOS), (16+i*(S+16), 16)); dr.text((16+i*(S+16), S+24), n, fill=(0,0,0))
sh.save('compare_v3_vs_top.png'); print(sh.size)
