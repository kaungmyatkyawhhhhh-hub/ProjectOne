import json,math
from shapely.geometry import LineString, Point
R=json.load(open(r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/osm_ygn/roads.json',encoding='utf8'))['roads']
T=json.load(open('ov2.json',encoding='utf8'))['elements']
KX=111320*math.cos(math.radians(16.82));KY=110574
def xy(p): return ((p[0]-96.14)*KX,(p[1]-16.82)*KY)
res=[r for r in R if r['t'].get('highway') in ('residential','living_street','unclassified') and (r['t'].get('name:en') or r['t'].get('name'))]
for r in res: r['ls']=LineString([xy(p) for p in r['p']])
sites=[]
for e in T:
    t=e['tags']
    if t.get('admin_level')!='7': continue
    lat,lon=e['center']['lat'],e['center']['lon']
    lat=min(max(lat,16.755),16.885); lon=min(max(lon,96.1),96.23)
    if t.get('name:en') in ('Dala Township','Twantay Township','Thanlyin','East Dagon','Dagon Seikkan','Hlaingtharya (East)','Seikgyikanaungto'): continue
    c=Point(xy((lon,lat)))
    best=sorted(res,key=lambda r:r['ls'].distance(c))
    best=[r for r in best if r['ls'].length>120][:1]
    for r in best:
        q=r['ls'].interpolate(r['ls'].project(c)); s=r['ls'].project(q)
        a=r['ls'].interpolate(max(0,s-8)); b=r['ls'].interpolate(min(r['ls'].length,s+8)); dx,dy=b.x-a.x,b.y-a.y; L=math.hypot(dx,dy) or 1
        sites.append(dict(name='%s - %s'%(t.get('name:en'),r['t'].get('name:en') or r['t'].get('name')),tags=r['t'],lat=16.82+q.y/KY,lon=96.14+q.x/KX,dir=(dx/L,dy/L),partner=None,prefix='street'))
json.dump(sites,open('street_sites.json','w',encoding='utf8'),ensure_ascii=False)
for s in sites: print(s['name'],round(s['lat'],5),round(s['lon'],5),s['tags'])
