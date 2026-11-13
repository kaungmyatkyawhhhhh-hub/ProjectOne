# Road network design: loop cut at the roundabout, junction nodes, street selection.
import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from render import *
from d1_main import resample, radius, smooth_to_radius
from scipy.spatial import cKDTree, ConvexHull
from matplotlib.path import Path
import pickle
cen=pickle.load(open('centre.pkl','rb'))
RB=np.array([-580.0,-733.0])            # Hanthawaddy roundabout centre (OSM)
# ---- loop: open road from the roundabout round to the roundabout
L=cen['loop']
if np.linalg.norm(L[0]-L[-1])>15: L=np.vstack([L,L[0]])
i0=np.linalg.norm(L-RB,axis=1).argmin()
L=np.vstack([L[i0:],L[1:i0+1]])
# direction: must leave the roundabout going EAST along the drawn link (towards Optima) -> check
if L[30][0]<L[0][0]: L=L[::-1]
# pull both ends onto the roundabout centre, blended over 120 m
def pin_end(P,target,n=24):
    P=P.copy(); d=target-P[0]
    for i in range(n): P[i]+=d*(1-i/n)**2
    return P
L=pin_end(L,RB); L=pin_end(L[::-1],RB)[::-1]
L=smooth_to_radius(L,60.0)
loop=L
def snap_end(P,target_line,at_start):
    t=cKDTree(target_line); P=P.copy()
    e=P[0] if at_start else P[-1]; d,j=t.query(e); tgt=target_line[j]
    return (pin_end(P,tgt) if at_start else pin_end(P[::-1],tgt)[::-1]), d
blue,d1=snap_end(cen['blue'],loop,True); blue,d2=snap_end(blue,loop,False)
green,d3=snap_end(cen['green'],loop,True); green,d4=snap_end(green,loop,False)
print('end snaps (m):',[round(float(x),1) for x in (d1,d2,d3,d4)])
MAIN={'Yangon Loop':loop,'New Road':blue,'University Avenue':green}
for n,p in MAIN.items(): print(n,'%.0f m'%np.linalg.norm(np.diff(p,axis=0),axis=1).sum(),'min R %.0f'%radius(p).min())
allmain=np.vstack([resample(p,5) for p in MAIN.values()]); mtree=cKDTree(allmain)
mdir={}
# ---- map boundary: convex hull of the main roads, or within 300 m of a main road
hull=Path(allmain[ConvexHull(allmain).vertices])
def in_map(p): 
    p=np.atleast_2d(p); return hull.contains_points(p)|(mtree.query(p)[0]<=300)
# ---- water mask
lake=[]
for r in areas:
    if r['tags'].get('natural')!='water': continue
    parts=[[xy(q) for q in mm['pts']] for mm in r['members'] if mm['role']=='outer']
    # stitch
    while parts:
        cur=parts.pop(0)
        while cur[0]!=cur[-1]:
            for i,p in enumerate(parts):
                if p[0]==cur[-1]: cur+=p[1:]; parts.pop(i); break
                if p[-1]==cur[-1]: cur+=p[::-1][1:]; parts.pop(i); break
            else: break
        lake.append(Path(np.array(cur)))
def in_water(p):
    p=np.atleast_2d(p); m=np.zeros(len(p),bool)
    for l in lake: m|=l.contains_points(p)
    return m
# ---- candidate real streets
RANK={'trunk':4,'primary':4,'secondary':3,'tertiary':3,'unclassified':2,'residential':2,'living_street':1}
main_dirs=np.vstack([np.gradient(resample(p,5),axis=0) for p in MAIN.values()]); main_dirs/=np.linalg.norm(main_dirs,axis=1)[:,None]
cand=[]
for wi,w in enumerate(hw):
    t=w['tags']
    if t['highway'] not in RANK or t.get('junction')=='roundabout' or wi in main_way_ids: continue
    P=resample(np.array(w['xy']),5) if length(w['xy'])>5 else np.array(w['xy'])
    d,j=mtree.query(P); v=np.gradient(P,axis=0); v/=np.linalg.norm(v,axis=1)[:,None]+1e-9
    par=(d<38)&(np.abs((v*main_dirs[j]).sum(1))>0.85)
    if par.mean()>0.6: continue          # the other side of a main road
    cand.append(w)
print('candidate ways',len(cand))
# ---- strokes: chain ways end to end by name, then by straightness
def key(p): return (round(p[0],1),round(p[1],1))
ends=defaultdict(list)
for ci,w in enumerate(cand):
    ends[key(w['xy'][0])].append((ci,0)); ends[key(w['xy'][-1])].append((ci,1))
link={}
def outdir(ci,e):
    p=cand[ci]['xy']; a,b=(p[0],p[min(2,len(p)-1)]) if e==0 else (p[-1],p[max(-3,-len(p))]); v=np.array(b)-np.array(a); return v/(np.linalg.norm(v)+1e-9)
for k_,lst in ends.items():
    if len(lst)<2: continue
    pairs=[]
    for i in range(len(lst)):
        for j in range(i+1,len(lst)):
            a,b=lst[i],lst[j]
            if a[0]==b[0]: continue
            ang=math.degrees(math.acos(np.clip(-(outdir(*a)*outdir(*b)).sum(),-1,1)))   # 0 = straight on
            same=canon(nm(cand[a[0]]))==canon(nm(cand[b[0]])) and nm(cand[a[0]])!=''
            if ang<=35 or (same and ang<=60): pairs.append((0 if same else 1,ang,a,b))
    used=set()
    for _,ang,a,b in sorted(pairs):
        if a in used or b in used: continue
        used.add(a);used.add(b); link[a]=b; link[b]=a
strokes=[];seen=set()
for ci in range(len(cand)):
    if ci in seen: continue
    # walk back to a chain start
    cur=(ci,0); guard=0
    while cur in link and guard<500:
        nxt=link[cur]; cur=(nxt[0],1-nxt[1]); guard+=1
        if cur[0]==ci: break
    chain=[];e=cur; guard=0
    while guard<500:
        guard+=1; c,en=e
        if c in seen: break
        seen.add(c); pts=cand[c]['xy'] if en==0 else cand[c]['xy'][::-1]; chain.append((c,pts))
        far=(c,1-en)
        if far not in link: break
        e=link[far]
    if not chain: continue
    pts=[]; 
    for c,p in chain: pts+= (p if not pts else p[1:])
    names=Counter(nm(cand[c]) for c,_ in chain for _ in range(max(1,int(length(cand[c]['xy'])))))
    name=max(names,key=lambda n:(n!='',names[n])) if any(names) else ''
    rank=max(RANK[cand[c]['tags']['highway']] for c,_ in chain)
    strokes.append({'name':name,'rank':rank,'pts':np.array(pts),'len':length(pts)})
print('strokes',len(strokes),'total km %.1f'%(sum(s['len'] for s in strokes)/1000))
pickle.dump({'MAIN':MAIN,'strokes':strokes,'RB':RB},open('net1.pkl','wb'))
print(sorted([(round(s['len']),s['name'],s['rank']) for s in strokes],reverse=True)[:25])
