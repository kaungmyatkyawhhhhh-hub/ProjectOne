import json,math,sys,collections
sys.path.insert(0,r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import roadnet as rn
from shapely.geometry import LineString, Point
D=json.load(open('ov1.json',encoding='utf8'))['elements']
W=[e for e in D if e['type']=='way' and e.get('tags',{}).get('highway','') in ('trunk','primary','secondary','tertiary') and not e['tags'].get('bridge')]
KX=111320*math.cos(math.radians(16.82));KY=110574
def xy(g): return ((g['lon']-96.14)*KX,(g['lat']-16.82)*KY)
for e in W: e['ls']=LineString([xy(g) for g in e['geometry']]); e['nm']=e['tags'].get('name:en') or e['tags'].get('name')
byname=collections.defaultdict(list)
for e in W:
    if e['nm']: byname[e['nm']].append(e)
tot={n:sum(e['ls'].length for e in v) for n,v in byname.items()}
names=[n for n in sorted(tot,key=lambda n:-tot[n]) if tot[n]>1500][:34]
sites=[]
for n in names:
    ws=sorted(byname[n],key=lambda e:-e['ls'].length)
    picked=[]
    for e in ws:
        if e['ls'].length<150: continue
        c=e['ls'].interpolate(0.5,normalized=True)
        if any(c.distance(p)<2500 for p,_ in picked): continue
        picked.append((c,e))
        if len(picked)>=(2 if tot[n]>9000 else 1): break
    for c,e in picked:
        s=e['ls'].project(c); a=e['ls'].interpolate(max(0,s-10)); b=e['ls'].interpolate(min(e['ls'].length,s+10))
        dx,dy=b.x-a.x,b.y-a.y; L=math.hypot(dx,dy); dx,dy=dx/L,dy/L
        cx,cy=c.x,c.y; partner=None
        if rn.oneway_of(e['tags']):
            best=None
            for f in byname[n]:
                if f is e or not rn.oneway_of(f['tags']): continue
                d=f['ls'].distance(c)
                if d<70 and (best is None or d<best[0]): best=(d,f)
            if best:
                q=best[1]['ls'].interpolate(best[1]['ls'].project(c)); cx,cy=(c.x+q.x)/2,(c.y+q.y)/2; partner=(best[1]['id'],round(best[0],1),best[1]['tags'].get('lanes'))
        sites.append(dict(name=n,way=e['id'],tags=e['tags'],lat=16.82+cy/KY,lon=96.14+cx/KX,dir=(dx,dy),partner=partner))
json.dump(sites,open('main_sites.json','w',encoding='utf8'),ensure_ascii=False,indent=0)
for s in sites: print(s['name'][:30].ljust(30),round(s['lat'],5),round(s['lon'],5),s['tags'].get('highway'),s['tags'].get('lanes'),s['tags'].get('oneway'),s['partner'])
print(len(sites))
