import json,collections,math,sys
sys.path.insert(0,r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import geo
from shapely.geometry import Point
D=json.load(open('ov1.json',encoding='utf8'))['elements']
BP={t:geo.batch_poly(t) for t in ('05','1','2','3')}
def bt(lon,lat):
    p=Point(*geo.world(lon,lat))
    if BP['05'].contains(p): return '05'
    for t in '123':
        if BP[t].contains(p): return t
    return '-'
def clus(pts,r):
    cs=[]
    for x,y in pts:
        for c in cs:
            if math.hypot((c[0]-x)*106500,(c[1]-y)*110574)<r: c[2]+=1;break
        else: cs.append([x,y,1])
    return cs
N=[e for e in D if e['type']=='node']
sig=[(e['lon'],e['lat']) for e in N if e.get('tags',{}).get('highway')=='traffic_signals' or e.get('tags',{}).get('crossing')=='traffic_signals']
cnt=collections.Counter(bt(*p) for p in sig); print('signal nodes',cnt)
cl=clus(sig,40); print('signal junction clusters', collections.Counter(bt(c[0],c[1]) for c in cl))
bs=[(e['lon'],e['lat']) for e in N if e.get('tags',{}).get('highway')=='bus_stop']; print('bus stops',collections.Counter(bt(*p) for p in bs))
cr=[(e['lon'],e['lat'],e['tags'].get('crossing'),e['tags'].get('crossing:markings')) for e in N if e.get('tags',{}).get('highway')=='crossing']
print('crossings',collections.Counter(bt(p[0],p[1]) for p in cr), collections.Counter((p[2],p[3]) for p in cr))
W=[e for e in D if e['type']=='way']
fb=[]
for e in W:
    t=e.get('tags',{})
    if t.get('bridge') and t.get('highway') in ('footway','path','steps','pedestrian'):
        g=e['geometry'][len(e['geometry'])//2]; fb.append((g['lon'],g['lat']))
fc=clus(fb,40); print('footbridge clusters',len(fc), collections.Counter(bt(c[0],c[1]) for c in fc))
json.dump([[c[0],c[1],c[2],bt(c[0],c[1])] for c in fc],open('fb_clusters.json','w'))
dirn=collections.Counter(e['tags'].get('traffic_signals:direction') for e in N if e.get('tags',{}).get('highway')=='traffic_signals'); print(dirn)
tc=collections.Counter(e['tags'].get('traffic_calming') for e in N if e.get('tags',{}).get('traffic_calming')); print('calming',tc)
