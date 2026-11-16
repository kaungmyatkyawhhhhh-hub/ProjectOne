import json,collections,math,sys
sys.path.insert(0,r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import roadnet as rn, geo
from shapely.geometry import Point
D=json.load(open('ov1.json',encoding='utf8'))['elements']
W=[e for e in D if e['type']=='way' and e.get('tags',{}).get('highway','') in ('trunk','primary','secondary','tertiary','trunk_link','primary_link','secondary_link','tertiary_link')]
BP={t:geo.batch_poly(t) for t in ('1','2','3')}; B05=geo.batch_poly('05')
def L(e):
    g=e.get('geometry',[]);s=0
    for a,b in zip(g,g[1:]):
        dx=(b['lon']-a['lon'])*111320*math.cos(math.radians(16.82));dy=(b['lat']-a['lat'])*110574;s+=math.hypot(dx,dy)
    return s
def batch(e):
    g=e['geometry'][len(e['geometry'])//2];x,z=geo.world(g['lon'],g['lat']);p=Point(x,z)
    if B05.contains(p): return '05'
    for t,P in BP.items():
        if P.contains(p): return t
    return '-'
agg=collections.defaultdict(lambda: dict(km=0,cls=collections.Counter(),osm=collections.Counter(),game=collections.Counter(),one=0,surf=collections.Counter(),turn=0,bridge=0,ms=collections.Counter(),batch=collections.Counter(),side=collections.Counter(),width=[],smooth=collections.Counter(),lm=collections.Counter(),park=0,bus=0))
for e in W:
    t=e['tags'];n=t.get('name:en') or t.get('name') or '(unnamed %s)'%t['highway']
    l=L(e)/1000;a=agg[n];a['km']+=l;a['cls'][t['highway']]+=l
    one=rn.oneway_of(t)
    tot=t.get('lanes');a['osm'][('1w ' if one else '2w ')+str(tot)+('' if not t.get('lanes:forward') else ' f%s b%s'%(t.get('lanes:forward'),t.get('lanes:backward')))]+=l
    cs=rn.cross_section(t)
    a['game'][('1w %d'%cs['nf']) if one else '%d+%d'%(cs['nf'],cs['nb'])]+=l
    if one:a['one']+=l
    a['surf'][t.get('surface')]+=l
    if any(k.startswith('turn:lanes') for k in t):a['turn']+=l
    if t.get('bridge'):a['bridge']+=l
    a['ms'][t.get('maxspeed')]+=l; a['batch'][batch(e)]+=l
    for k in t:
        if k.startswith('sidewalk'):a['side'][k+'='+t[k]]+=l
        if k.startswith('parking'):a['park']+=0
    if any(k.startswith('parking') for k in t):a['park']+=l
    if any('bus' in k for k in t):a['bus']+=l
    if t.get('width'):a['width'].append(t['width'])
    if t.get('smoothness'):a['smooth'][t['smoothness']]+=l
    if t.get('lane_markings'):a['lm'][t['lane_markings']]+=l
rows=sorted(agg.items(),key=lambda kv:-kv[1]['km'])
out=[]
for n,a in rows:
    if a['km']<0.4: continue
    f=lambda c:', '.join('%s:%.1f'%(k,v) for k,v in c.most_common(4))
    out.append(dict(name=n,km=round(a['km'],2),cls=f(a['cls']),osm=f(a['osm']),game=f(a['game']),oneway_km=round(a['one'],2),surface=f(a['surf']),turn_km=round(a['turn'],2),bridge_km=round(a['bridge'],2),maxspeed=f(a['ms']),batch=f(a['batch']),sidewalk=f(a['side']),width=a['width'],smooth=f(a['smooth']),lane_markings=f(a['lm']),park_km=round(a['park'],2),bus_km=round(a['bus'],2)))
json.dump(out,open('main_roads.json','w',encoding='utf8'),ensure_ascii=False,indent=1)
for r in out[:70]: print(r['name'][:34].ljust(34),r['km'],'|',r['cls'][:30],'|OSM',r['osm'][:60],'|GAME',r['game'][:40],'|1w',r['oneway_km'],'|',r['batch'],'|turn',r['turn_km'],'|br',r['bridge_km'],'|',r['surface'][:30])
print(len(out))
