# Per-icon stats at 64 px: mean luminance, % near-black, % near-white, mean saturation, centre-box saturation.
import json, urllib.request, io, numpy as np
from PIL import Image
G = {'10629695169':'Tap Sim','10776408857':'Spider Arms','10775483673':'Ragdolls','10767110259':'1 Arm Length','6443367640':'Gym Star','9867866217':'Gym Universe','2583564222':'Boxing Beta','1268927906':'Muscle Legends','10131026507':'Power Lifters','10771997908':'1 Spider Arm','4582358979':'Arm Wrestle','10771388664':'Muscle Parade','6601115643':'Prison Pump','10152905521':'1 Muscle Walls','10774712093':'1 Gym Evo','8669550197':'Muscle Transform','10020612607':'1 Muscle AW','5972059550':'Gym League','2564505263':'Strongman Sim'}
d = json.load(urllib.request.urlopen('https://thumbnails.roblox.com/v1/games/icons?universeIds='+','.join(G)+'&size=256x256&format=Png&isCircular=false'))['data']
def stats(im):
    a = np.asarray(im.convert('RGB').resize((64,64)), float)/255
    l = a@[.299,.587,.114]; mx, mn = a.max(2), a.min(2); s = (mx-mn)/(mx+1e-6)
    return l.mean(), (l<45/255).mean(), ((l>215/255)&(s<.25)).mean(), s.mean()
rows=[]
for x in d:
    rows.append((G[str(x['targetId'])],)+stats(Image.open(io.BytesIO(urllib.request.urlopen(x['imageUrl']).read()))))
base='../../Assets/icon_2026-11-27/'
for n in ['gymarc_icon_normal_logo.png','gymarc_icon_xmas_logo.png']:
    try: rows.append(('OURS '+n[12:18],)+stats(Image.open(base+n)))
    except Exception as e: print(n,e)
rows.append(('OLD ours',)+stats(Image.open('../../Assets/icon_render_25nov/GYMARC_ICON_v2_closeup_logo_512.png')))
print(f"{'icon':18} lum  dark white sat")
for r in rows: print(f"{r[0]:18} {r[1]:.2f} {r[2]:.2f} {r[3]:.2f} {r[4]:.2f}")
g=np.array([r[1:] for r in rows[:-3]]); print('GYM MEDIAN', np.round(np.median(g,0),2))
