import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import json, numpy as np, math, os
from common import *
D=json.load(open('ygn_road_design.json')); g=D['ground']
A=json.load(open('ygn_osm_areas.json',encoding='utf-8')); O=json.load(open('ygn_osm_roads.json',encoding='utf-8'))
def simp(pts,tol=1.5):
    # Douglas-Peucker
    pts=np.array(pts)
    def rec(a,b):
        if b<=a+1: return []
        P=pts[a+1:b]; A_,B_=pts[a],pts[b]; d=B_-A_; L=np.hypot(*d)
        dist=np.abs((P[:,0]-A_[0])*d[1]-(P[:,1]-A_[1])*d[0])/L if L>0 else np.hypot(*(P-A_).T)
        i=dist.argmax()
        return rec(a,a+1+i)+[a+1+i]+rec(a+1+i,b) if dist[i]>tol else []
    idx=[0]+rec(0,len(pts)-1)+[len(pts)-1]
    return pts[idx]
water=[]
def stitch(parts):
    parts=[list(map(tuple,p)) for p in parts]; out=[]
    while parts:
        cur=parts.pop(0)
        while cur[0]!=cur[-1]:
            for i,p in enumerate(parts):
                if p[0]==cur[-1]: cur+=p[1:]; parts.pop(i); break
                if p[-1]==cur[-1]: cur+=p[::-1][1:]; parts.pop(i); break
            else: break
        out.append(cur)
    return out
for r in A:
    if r['tags'].get('natural')!='water': continue
    body=[]
    for role in ('outer','inner'):
        for ring in stitch([[xy(p) for p in m['pts']] for m in r['members'] if m['role']==role]):
            if ring[0]==ring[-1] and len(ring)>=4: body.append(simp(ring[:-1]))
            else: print('open ring skipped',r['tags'],role,len(ring))
    water.append(body)
for w in O['ways']:
    if w['tags'].get('natural')=='water':
        p=[xy(q) for q in w['geometry']]
        if p[0]==p[-1] and len(p)>=4: water.append([simp(p[:-1])])
rings=[r for b_ in water for r in b_]
print('water bodies',len(water),[len(b_) for b_ in water],'rings',len(rings),'points',sum(len(r) for r in rings))
terrain={'x0':g['west_m'],'y0':g['south_m'],'dx':(g['east_m']-g['west_m'])/(g['nx']-1),'dy':(g['north_m']-g['south_m'])/(g['ny']-1),'nx':g['nx'],'ny':g['ny'],
         'h':[v for row in g['height_m'] for v in row],'water':[[[round(float(v),1) for p in r for v in p] for r in b_] for b_ in water]}
tj=json.dumps(terrain,separators=(',',':'))
def esc(s): return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
items=[]; ref=[0]
def module(name,src):
    assert ']]>' not in src and len(src)<199000, (name,len(src))
    ref[0]+=1
    return '<Item class="ModuleScript" referent="R%d"><Properties><string name="Name">%s</string><ProtectedString name="Source"><![CDATA[%s]]></ProtectedString></Properties></Item>'%(ref[0],name,src)
def folder(name,inner):
    ref[0]+=1
    return '<Item class="Folder" referent="R%d"><Properties><string name="Name">%s</string></Properties>%s</Item>'%(ref[0],name,inner)
def chunks(name,s,n=180000):
    assert ']==]' not in s
    parts=[s[i:i+n] for i in range(0,len(s),n)]
    return ''.join(module('%s%s'%(name,'' if len(parts)==1 else '_%d'%(i+1)),'return [==['+p+']==]') for i,p in enumerate(parts)),len(parts)
body=''
m,n1=chunks('Terrain',tj); body+=m
m,n2=chunks('Roads',open('ygn_roads.json').read()); body+=m
D2=dict(D); D2.pop('ground'); D2['roads']=[{k:v for k,v in r.items() if k!='pts'} for r in D['roads']]
m,n3=chunks('Design',json.dumps(D2,separators=(',',':'))); body+=m
tools=module('YangonTerrain',open('studio/YangonTerrain.luau').read())
body+=folder('Tools',tools)
x='<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4">'+folder('YangonData',body)+'</roblox>'
os.makedirs('/mnt/user-data/outputs/ygn3',exist_ok=True)
open('/mnt/user-data/outputs/ygn3/yangon_data_2.rbxmx','w',encoding='utf-8').write(x)
print('terrain json',len(tj),'chunks',n1,n2,n3,'rbxmx bytes',len(x.encode()))
import xml.dom.minidom; xml.dom.minidom.parseString(x.encode()); print('xml ok')
