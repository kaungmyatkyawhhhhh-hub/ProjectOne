import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from common import *
import numpy as np, json, pickle, math
from collections import defaultdict,Counter
from scipy.spatial import cKDTree
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle, FancyBboxPatch
from matplotlib.lines import Line2D
import matplotlib.patheffects as pe
ws=load_osm(); k=load_kml(); main=pickle.load(open('main.pkl','rb'))
areas=json.load(open('ygn_osm_areas.json',encoding='utf-8'))
hw=[w for w in ws if 'highway' in w['tags']]
def nm(w): t=w['tags']; return t.get('name:en') or t.get('name') or ''
def canon(n):
    n=n.lower()
    for a,b in [('pyi road','pyay road'),('pyay ( prome) road','pyay road'),('kabar aye pagoda','kabar aye pagoda road')]:
        if a in n: return b
    return n
BG='#12141a'; COL={'loop':'#ffc233','blue':'#4fb3ff','green':'#5fd38a'}
LABEL={'loop':'Main loop','blue':'"new roasd"','green':'"more roads"'}
# ---- final snapped / drawn status
def runs(mask):
    r=[];s=0
    for i in range(1,len(mask)+1):
        if i==len(mask) or mask[i]!=mask[s]: r.append((s,i,mask[s])); s=i
    return r
for key,m in main.items():
    on=np.array(m['on']); d=np.array(m['dist'])
    for s,e,v in runs(on):
        if not v and (e-s)*10<250 and d[s:e].max()<=30: on[s:e]=True
    for s,e,v in runs(on):
        if v and (e-s)*10<200: on[s:e]=False
    m['on']=on; m['P']=np.array(m['pts'])
    m['runs2']=runs(on)
# ---- colour real segments that a main road follows
real_main=defaultdict(list)   # key -> list of (a,b,way index)
MAJ={'trunk','primary','secondary','tertiary','unclassified','residential','living_street'}
for key,m in main.items():
    idx=np.where(m['on'])[0]
    if len(idx)==0: continue
    P=m['P']; tree=cKDTree(P[idx])
    dirs=np.gradient(P,axis=0); dirs/=np.linalg.norm(dirs,axis=1)[:,None]+1e-9
    cnt=Counter(n for n,o in zip(m['names'],m['on']) if o and n)
    names_ok={n for n,c in cnt.items() if c*10>=200}
    m['names_ok']=names_ok
    for wi,w in enumerate(hw):
        t=w['tags']
        if t['highway'] not in MAJ: continue
        rb=t.get('junction')=='roundabout'
        for a,b in zip(w['xy'],w['xy'][1:]):
            mid=((a[0]+b[0])/2,(a[1]+b[1])/2); ds,j=tree.query(mid); j=idx[j]
            if ds>45: continue
            v=np.array(b)-np.array(a); L=np.linalg.norm(v)
            par=abs(np.dot(v/(L+1e-9),dirs[j]))>math.cos(math.radians(32))
            same=canon(nm(w)) in names_ok
            if (rb and ds<=45) or (par and (ds<=9 or (same and ds<=45))):
                real_main[key].append((a,b,wi))
main_way_ids=set(wi for v in real_main.values() for _,_,wi in v)
# ---- roundabouts
rb=[w for w in hw if w['tags'].get('junction')=='roundabout']
par={i:i for i in range(len(rb))}
def find(i):
    while par[i]!=i: par[i]=par[par[i]]; i=par[i]
    return i
ends=defaultdict(list)
for i,w in enumerate(rb):
    for p in w['geometry']: ends[tuple(p)].append(i)
for v in ends.values():
    for j in v[1:]: par[find(j)]=find(v[0])
grp=defaultdict(list)
for i in range(len(rb)): grp[find(i)].append(rb[i])
roundabouts=[]
for g in grp.values():
    pts=np.array([p for w in g for p in w['xy']]); c=pts.mean(0); r=np.linalg.norm(pts-c,axis=1).mean()
    roundabouts.append((c,r))
# ---- bridges
br=[w for w in hw if w['tags'].get('bridge')]
bgrp=[]
for w in br:
    c=np.array(w['xy']).mean(0)
    for g in bgrp:
        if min(np.linalg.norm(np.array(w['xy'])[:,None,:]-np.array(x['xy'])[None,:,:],axis=2).min() for x in g['ways'])<120: g['ways'].append(w); break
    else: bgrp.append({'ways':[w]})
for g in bgrp:
    pts=np.array([p for w in g['ways'] for p in w['xy']]); g['c']=pts.mean(0); g['len']=sum(length(w['xy']) for w in g['ways'])/(2 if len(g['ways'])>2 else 1)
    g['name']=Counter(canon(nm(w)) for w in g['ways']).most_common(1)[0][0].title()
    g['main']=any(hw.index(w) in main_way_ids for w in g['ways'])
STY={'service':(0.5,'#30343d'),'living_street':(0.8,'#474c58'),'residential':(0.9,'#4d5360'),'unclassified':(0.9,'#4d5360'),
     'tertiary':(1.6,'#6d7482'),'secondary':(2.0,'#7b8291'),'secondary_link':(1.0,'#6d7482'),'primary':(2.4,'#8b92a1'),'primary_link':(1.1,'#7b8291'),'trunk':(2.6,'#979eac'),'trunk_link':(1.1,'#7b8291')}
ORDER=['service','living_street','residential','unclassified','tertiary','secondary_link','secondary','primary_link','primary','trunk_link','trunk']
def draw(ax,ext,scale=1.0,labels=True,zoom=False):
    x0,x1,y0,y1=ext
    ax.set_facecolor(BG); ax.set_xlim(x0,x1); ax.set_ylim(y0,y1); ax.set_aspect('equal'); ax.set_xticks([]); ax.set_yticks([])
    for s in ax.spines.values(): s.set_visible(False)
    # water
    for r in areas:
        if r['tags'].get('natural')!='water': continue
        rings=defaultdict(list)
        for mm in r['members']: rings[mm['role']].append([xy(p) for p in mm['pts']])
        def stitch(parts):
            parts=[list(p) for p in parts]; out=[]
            while parts:
                cur=parts.pop(0)
                while cur[0]!=cur[-1]:
                    for i,p in enumerate(parts):
                        if p[0]==cur[-1]: cur+=p[1:]; parts.pop(i); break
                        if p[-1]==cur[-1]: cur+=p[::-1][1:]; parts.pop(i); break
                    else: break
                out.append(cur)
            return out
        for ring in stitch(rings['outer']): ax.add_patch(Polygon(ring,closed=True,fc='#173650',ec='#235a80',lw=0.6*scale,zorder=1))
        for ring in stitch(rings['inner']): ax.add_patch(Polygon(ring,closed=True,fc=BG,ec='#235a80',lw=0.4*scale,zorder=1.1))
    for w in ws:
        t=w['tags']
        if t.get('natural')=='water': ax.add_patch(Polygon(w['xy'],closed=True,fc='#173650',ec='#235a80',lw=0.4*scale,zorder=1))
        elif t.get('waterway'): ax.plot(*zip(*w['xy']),color='#235a80',lw=0.8*scale,zorder=1)
    # real streets
    for c in ORDER:
        lw,col=STY[c]
        for w in hw:
            if w['tags']['highway']==c: ax.plot(*zip(*w['xy']),color=col,lw=lw*scale*(1.6 if zoom else 1),solid_capstyle='round',zorder=2+ORDER.index(c)*0.01)
    # main roads on real roads
    mw=(5.2 if not zoom else 7.5)*scale
    for key in ['green','blue','loop']:
        for a,b,wi in real_main[key]:
            ax.plot([a[0],b[0]],[a[1],b[1]],color=COL[key],lw=mw,solid_capstyle='round',zorder=5)
        m=main[key]
        for s,e,v in m['runs2']:
            if not v:
                seg=m['P'][max(s-7,0):min(e+1,len(m['P']))]
                ax.plot(seg[:,0],seg[:,1],color=COL[key],lw=mw*0.8,ls=(0,(2.2,1.6)),zorder=5,dash_capstyle='butt')
    # bridges: hatched band
    for g in bgrp:
        for w in g['ways']:
            ax.plot(*zip(*w['xy']),color='#ffffff',lw=(3.4 if not zoom else 6)*scale,ls=(0,(0.6,0.6)),zorder=6,dash_capstyle='butt')
    # roundabouts
    for c,r in roundabouts:
        ax.add_patch(Circle(c,r+ (9 if not zoom else 5),fc=BG,ec='none',zorder=6.5))
        ax.add_patch(Circle(c,r,fc='none',ec='#ffffff',lw=(2.2 if not zoom else 4)*scale,zorder=7))
        ax.add_patch(Circle(c,r*0.45,fc='#2a2f3a',ec='none',zorder=7))
    return
def txt(ax,x,y,s,size=9,color='white',rot=0,ha='center',va='center',weight='bold',z=20,box=True):
    t=ax.text(x,y,s,fontsize=size,color=color,rotation=rot,ha=ha,va=va,fontweight=weight,zorder=z,rotation_mode='anchor')
    t.set_path_effects([pe.withStroke(linewidth=3.2,foreground=BG)])
    return t
if __name__=='__main__':
    import sys
    print('roundabouts',[(c.round().tolist(),round(r)) for c,r in roundabouts])
    for g in bgrp: print('bridge',g['name'],g['c'].round().tolist(),round(g['len']),len(g['ways']),'on main' if g['main'] else '')
    for key in main: print(key,[(s*10,e*10,bool(v)) for s,e,v in main[key]['runs2']], 'real segs',len(real_main[key]), 'km real %.2f'%(sum(math.hypot(b[0]-a[0],b[1]-a[1]) for a,b,_ in real_main[key])/1000))
