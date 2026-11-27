# v7 (grow-taller story, bigger legs): logo top-left in the empty zone the layout reserves, size test vs live gym icons, 64 px stats.
import json, urllib.request, io, numpy as np
from PIL import Image, ImageDraw, ImageFilter
LOGO = Image.open('../../icon_render_25nov/gymarc_logo_v10_blue_simple.png').convert('RGBA')
def compose(src, out, frac=0.36):
    im = Image.open(src).convert('RGBA').resize((1024, 1024), Image.LANCZOS)
    w = int(1024*frac); lg = LOGO.resize((w, int(LOGO.height*w/LOGO.width)), Image.LANCZOS)
    sh = Image.new('RGBA', im.size, (0,0,0,0)); a = lg.split()[3].point(lambda v: v*0.55)
    blk = Image.new('RGBA', lg.size, (10,20,50,255)); blk.putalpha(a); sh.alpha_composite(blk, (30, 30))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10))); im.alpha_composite(lg, (22, 18))
    im = im.convert('RGB'); im.save(out); im.resize((512,512), Image.LANCZOS).save(out.replace('.png','_512.png')); return im
def stats(im):
    a = np.asarray(im.convert('RGB').resize((64,64)), float)/255; l = a@[.299,.587,.114]; s=(a.max(2)-a.min(2))/(a.max(2)+1e-6)
    return f"lum {l.mean():.2f} dark {(l<45/255).mean():.0%} white {((l>215/255)&(s<.25)).mean():.0%}"
n = compose('gymarc_v7_normal_gpt.png', 'gymarc_v7_normal_logo.png')
x = Image.open('../v6/gymarc_v6a_aesthetic_normal_logo_512.png')
G = {'1268927906':'Muscle Legends','6443367640':'Gym Star','9867866217':'Gym Universe','10131026507':'Power Lifters','5972059550':'Gym League','2564505263':'Strongman Sim'}
d = json.load(urllib.request.urlopen('https://thumbnails.roblox.com/v1/games/icons?universeIds='+','.join(G)+'&size=256x256&format=Png&isCircular=false'))['data']
comp = [(G[str(e['targetId'])], Image.open(io.BytesIO(urllib.request.urlopen(e['imageUrl']).read())).convert('RGB')) for e in d]
old = Image.open('../../icon_render_25nov/GYMARC_ICON_v2_closeup_logo_512.png').convert('RGB')
tiles = [('v7 normal', n), ('v6a', x)] + comp
sheet = Image.new('RGB', (len(tiles)*170+20, 360), (245,245,245)); dr = ImageDraw.Draw(sheet)
for i,(nm,t) in enumerate(tiles):
    sheet.paste(t.resize((150,150), Image.LANCZOS), (20+i*170, 20)); sheet.paste(t.resize((100,100), Image.LANCZOS), (20+i*170, 185)); sheet.paste(t.resize((60,60), Image.LANCZOS), (125+i*170, 225))
    dr.text((20+i*170, 330), nm, fill=(20,20,20)); print(nm, stats(t))
sheet.save('icon_size_test_v7.png')
