import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from d2_net import *
SPACING=float(sys.argv[1]) if len(sys.argv)>1 else 200.0
MINLEN=300.0
# ---- New Road north end: straight on over the junction (the flyover), joining the loop 220 m further north
bl=cen['blue']                                   # unsnapped: starts at J5 going south
J5=bl[0]; lt=cKDTree(loop); _,j5=lt.query(J5)
# loop index 280 m beyond J5 in the northward direction
step=np.linalg.norm(loop[1]-loop[0]); n280=int(280/step)
jn=j5+n280 if loop[min(j5+n280,len(loop)-1)][1]>loop[j5][1] else j5-n280
north=loop[min(j5,jn):max(j5,jn)+1]
north=north if north[0][1]<north[-1][1] else north[::-1]
north=north[north[:,1]>J5[1]+110]                 # only the part past the curve
newroad=np.vstack([blue[::-1][:-int(140/5)] if False else cen['blue'][::-1], north])   # south-west end ... J5 ... north
# cen['blue'][::-1] runs from the loop link to J5; re-snap its south-west end to the loop
newroad,_=snap_end(newroad,loop,True)
newroad=smooth_to_radius(newroad,60.0)
# pin the north end exactly on the loop
newroad,dn=snap_end(newroad,loop,False)
MAIN['New Road']=newroad
print('New Road now %.0f m, min R %.0f, north end snap %.1f m'%(np.linalg.norm(np.diff(newroad,axis=0),axis=1).sum(),radius(newroad).min(),dn))
allmain=np.vstack([resample(p,5) for p in MAIN.values()]); mtree=cKDTree(allmain)
# ---- clip strokes to the map, split at gaps
def clip(st):
    P=resample(st['pts'],5); ok=in_map(P)&~in_water(P)
    out=[];s=None
    for i,o in enumerate(ok):
        if o and s is None: s=i
        if (not o or i==len(ok)-1) and s is not None:
            e=i+1 if o else i
            if (e-s)*5>=120: out.append(P[s:e])
            s=None
    return out
pieces=[]
for st in strokes:
    for P in clip(st): pieces.append({'name':st['name'],'rank':st['rank'],'P':P,'len':(len(P)-1)*5.0})
print('pieces in map',len(pieces),'km %.1f'%(sum(p['len'] for p in pieces)/1000))
# ---- greedy pick: big roads first, then long named streets; skip a street that mostly runs beside one already picked
picked=[]; pts=[allmain]; dirs=[np.vstack([np.gradient(resample(p,5),axis=0) for p in MAIN.values()])]
def score(p): return (p['rank']>=3, p['len']*(1.25 if p['name'] else 1.0))
for p in sorted(pieces,key=score,reverse=True):
    if p['rank']<3 and p['len']<MINLEN: continue
    T=cKDTree(np.vstack(pts)); Dv=np.vstack(dirs); Dv=Dv/(np.linalg.norm(Dv,axis=1)[:,None]+1e-9)
    d,j=T.query(p['P']); v=np.gradient(p['P'],axis=0); v/=np.linalg.norm(v,axis=1)[:,None]+1e-9
    beside=(d<(SPACING if p['rank']<3 else 70))&(np.abs((v*Dv[j]).sum(1))>0.8)
    if beside.mean()>0.45: continue
    picked.append(p); pts.append(p['P']); dirs.append(np.gradient(p['P'],axis=0))
print('picked',len(picked),'km %.1f'%(sum(p['len'] for p in picked)/1000))
# ---- no dead ends: trim each street back to its first and last junction with another kept road; repeat
ring=np.array([RB+45*np.array([math.cos(a),math.sin(a)]) for a in np.linspace(0,2*math.pi,60)])
def junction_idx(p,others):
    T=cKDTree(np.vstack(others)); d,_=T.query(p['P']); idx=set(np.where(d<=9)[0].tolist())
    dm,_=mtree.query(p['P'][[0,-1]]); dr=np.linalg.norm(p['P'][[0,-1]]-RB,axis=1)
    if dm[0]<=30 or dr[0]<=60: idx.add(0)
    if dm[1]<=30 or dr[1]<=60: idx.add(len(p['P'])-1)
    return np.array(sorted(idx),dtype=int)
changed=True
while changed:
    changed=False; keep=[]
    for i,p in enumerate(picked):
        others=[allmain]+[q['P'] for k,q in enumerate(picked) if k!=i]
        idx=junction_idx(p,others)
        # a big road may run out of the map at one end (its far end is at the map edge)
        edge0=not in_map(p['P'][0]+ (p['P'][0]-p['P'][3]))[0] if len(p['P'])>3 else False
        edge1=not in_map(p['P'][-1]+(p['P'][-1]-p['P'][-4]))[0] if len(p['P'])>3 else False
        if len(idx)==0: changed=True; continue
        a=0 if (p['rank']>=3 and edge0) else idx.min(); b=len(p['P'])-1 if (p['rank']>=3 and edge1) else idx.max()
        if (b-a)*5 < (150 if p['rank']>=3 else 220): changed=True; continue
        if a>0 or b<len(p['P'])-1: changed=True
        q=dict(p); q['P']=p['P'][a:b+1]; q['len']=(b-a)*5.0; q['edge']=(bool(p['rank']>=3 and edge0),bool(p['rank']>=3 and edge1)); keep.append(q)
    picked=keep
tot=sum(p['len'] for p in picked)/1000
print('after trimming dead ends:',len(picked),'streets, %.1f km'%tot,'| big roads',sum(1 for p in picked if p['rank']>=3),'%.1f km'%(sum(p['len'] for p in picked if p['rank']>=3)/1000))
pickle.dump({'MAIN':MAIN,'streets':picked,'RB':RB},open('net2.pkl','wb'))
