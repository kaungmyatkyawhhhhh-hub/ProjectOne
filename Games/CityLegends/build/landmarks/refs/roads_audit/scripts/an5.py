import json,collections,math,sys
sys.path.insert(0,r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import geo
from shapely.geometry import Point, LineString
from shapely.strtree import STRtree
D=json.load(open('ov1.json',encoding='utf8'))['elements']
W=[e for e in D if e['type']=='way']
BP={t:geo.batch_poly(t) for t in ('05','1','2','3')}
def bt(lon,lat):
    p=Point(*geo.world(lon,lat))
    if BP['05'].contains(p): return '05'
    for t in '123':
        if BP[t].contains(p): return t
    return '-'
main=[e for e in W if e.get('tags',{}).get('highway','').split('_')[0] in ('trunk','primary','secondary','tertiary') and not e['tags'].get('bridge')]
ml=[LineString([(g['lon'],g['lat']) for g in e['geometry']]) for e in main]
tr=STRtree(ml)
res=[]
for e in W:
    t=e.get('tags',{})
    if t.get('bridge') and t.get('highway') in ('footway','path','pedestrian'):
        ls=LineString([(g['lon'],g['lat']) for g in e['geometry']])
        hit=[main[i] for i in tr.query(ls) if ml[i].intersects(ls)]
        if hit:
            names=sorted(set(h['tags'].get('name:en') or h['tags'].get('name') or h['tags']['highway'] for h in hit))
            c=ls.interpolate(0.5,normalized=True)
            res.append((round(c.y,5),round(c.x,5),bt(c.x,c.y),names,e['id'],t.get('covered')))
# cluster
out=[]
for r in res:
    if any(math.hypot((r[0]-o[0])*110574,(r[1]-o[1])*106500)<60 for o in out): continue
    out.append(r)
print(len(out), collections.Counter(o[2] for o in out))
for o in out: print(o)
json.dump(out,open('fb_road.json','w'),ensure_ascii=False)
