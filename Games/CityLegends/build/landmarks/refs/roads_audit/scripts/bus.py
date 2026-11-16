import json,sys,math; sys.path.insert(0,'.')
import annot,tiles
from PIL import Image
D=json.load(open('ov1.json',encoding='utf8'))['elements']
bs=[e for e in D if e['type']=='node' and e.get('tags',{}).get('highway')=='bus_stop' and e['tags'].get('shelter')=='yes']
print(len(bs))
picks=[]
for want in [(16.8215,96.1318),(16.8400,96.1560),(16.7790,96.1560),(16.8600,96.1400),(16.8450,96.1690),(16.8000,96.1370)]:
    b=min(bs,key=lambda e:(e['lat']-want[0])**2+(e['lon']-want[1])**2); picks.append(b)
ims=[]
for i,b in enumerate(picks):
    im,_,_=tiles.mosaic(b['lat'],b['lon'],19,400,400)
    from PIL import ImageDraw; d=ImageDraw.Draw(im); d.ellipse([190,190,210,210],outline=(255,0,255),width=2); d.text((5,5),'%s %.5f %.5f'%(b['tags'].get('name:en') or b['tags'].get('name') or 'bus stop',b['lat'],b['lon']),fill=(255,255,0))
    ims.append(im)
S=Image.new('RGB',(1200,800))
for j,im in enumerate(ims): S.paste(im,((j%3)*400,(j//3)*400))
S.save(tiles.OUT+'/busstops_6.jpg',quality=88)
