import sys,io,contextlib; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
with contextlib.redirect_stdout(io.StringIO()):
    from d2_net import in_water, in_map, hull, RB, radius, resample, smooth_to_radius, cKDTree, lake
from d4_heights import make_field, sampler, gx, gy, LAKE
from common import *
import numpy as np, json, math, pickle
from collections import Counter, defaultdict
N=pickle.load(open('net2.pkl','rb')); MAIN=N['MAIN']; ST=N['streets']
SPM=1.6; VS=1.6; STEP=4.0
F,W=make_field(in_water); at=sampler(F)
def chain(p): return np.r_[0,np.cumsum(np.linalg.norm(np.diff(p,axis=0),axis=1))]
roads=[]
for n,p in MAIN.items():
    roads.append({'name':n,'kind':'main','lanes':'2+2','half':32,'P':resample(p,STEP),'rank':5,'edge':(False,False)})
maintree=cKDTree(np.vstack([r['P'] for r in roads]))
C=np.array([400.0,1500.0])    # middle of the loop, for North/South/East/West names
def compass(p):
    d=p-C; a=math.degrees(math.atan2(d[0],d[1]))%360
    return ['North','East','South','West'][int(((a+45)%360)//90)]
names=Counter()
tmp=[]
for s in sorted(ST,key=lambda s:(-s['rank'],-s['len'])):
    P=smooth_to_radius(s['P'],25.0,step=4.0)
    nm_=(s['name'] or 'Lane').replace('( 1 )','1').replace('( 2 )','2').replace('  ',' ')
    if nm_=='U Wisara Road': continue     # the loop link leaves the roundabout on this line
    tmp.append((nm_,s,P)); names[nm_]+=1
used=Counter()
for nm_,s,P in tmp:
    name=nm_
    if names[nm_]>1 or nm_=='Lane' or nm_ in MAIN:
        if nm_=='Lane': used[nm_]+=1; name='Lane %d'%used[nm_]
        else:
            dm0,_=maintree.query(P[0]); dm1,_=maintree.query(P[-1])
            v=(P[-1]-P[0]) if dm0<dm1 else (P[0]-P[-1]); a=math.degrees(math.atan2(v[0],v[1]))%360
            name='%s %s'%(nm_,['North','East','South','West'][int(((a+45)%360)//90)]); used[name]+=1
            if used[name]>1: name+=' %d'%used[name]
    roads.append({'name':name,'kind':'street','lanes':'1+1','half':16,'P':P,'rank':s['rank'],'edge':s.get('edge',(False,False)),'big':s['rank']>=3})
# ---- snap street ends onto the road they meet (mains first, then bigger streets)
def snap(r,others):
    T=cKDTree(np.vstack(others)); P=r['P'].copy(); allo=np.vstack(others)
    for end,(sl,far) in enumerate(((slice(0,None),0),(slice(None,None,-1),-1))):
        if r['edge'][end]: continue
        Q=P[sl]; d,j=T.query(Q[0])
        if d>1e-6 and d<=(80 if r['rank']>=3 else 40) and np.linalg.norm(Q[0]-RB)>70:
            n=min(25 if d>40 else 12,len(Q)-1); delta=allo[j]-Q[0]
            for i in range(n): Q[i]=Q[i]+delta*(1-i/n)**2
            P[sl]=Q
    r['P']=P
for i,r in enumerate(roads):
    if r['kind']=='main': continue
    snap(r,[q['P'] for q in roads[:i]] + [q['P'] for q in roads[i+1:] if q['kind']=='street' and q['rank']>r['rank']])
byname={r['name']:r for r in roads}
if 'Insein Road' in byname and 'Hledan Road' in byname:
    I=byname['Insein Road']; Hd=byname['Hledan Road']; mt=maintree
    hp=Hd['P'] if mt.query(Hd['P'][0])[0]<mt.query(Hd['P'][-1])[0] else Hd['P'][::-1]     # from the junction outwards
    tgt=hp[int(80/STEP)]
    P=I['P'] if np.linalg.norm(I['P'][0]-tgt)<np.linalg.norm(I['P'][-1]-tgt) else I['P'][::-1]
    n=min(30,len(P)-1); d0=tgt-P[0]
    for i in range(n): P[i]=P[i]+d0*(1-i/n)**2
    I['P']=P
for r in roads:
    if r['kind']=='street': r['P']=smooth_to_radius(r['P'],25.0,step=4.0)
# ---- heights (metres), chainage, checks
tot={'main':0,'street':0}; rep=[]
for r in roads:
    P=r['P']; r['s']=chain(P); r['h']=at(P); L=r['s'][-1]; tot[r['kind']]+=L
    g=np.abs(np.diff(r['h'])/np.maximum(np.diff(r['s']),1e-6)); rr=radius(P)
    r['maxgrade']=float(g.max()); r['minR']=float(rr.min()); r['len']=float(L)
    wet=in_water(P).mean()
    rep.append((r['name'],r['kind'],round(L),round(r['minR']),round(g.max()*100,1),round(wet*100)))
print('roads',len(roads),'| main %.1f km, streets %.1f km'%(tot['main']/1000,tot['street']/1000))
print('worst: tightest bend',min(rep,key=lambda x:x[3]),'| steepest',max(rep,key=lambda x:x[4]),'| in water',[x for x in rep if x[5]>0])
# ---- junctions: where two roads touch or cross
pts=[];rid=[];sidx=[]
for i,r in enumerate(roads):
    pts.append(r['P']); rid+= [i]*len(r['P']); sidx+=list(range(len(r['P'])))
pts=np.vstack(pts); rid=np.array(rid); sidx=np.array(sidx); T=cKDTree(pts)
J=[]
for i,r in enumerate(roads):
    for q in range(i+1,len(roads)):
        o=roads[q]; d,j=cKDTree(o['P']).query(r['P']); close=np.where(d<=3.5)[0]
        if len(close)==0: continue
        # split into separate contacts
        groups=np.split(close,np.where(np.diff(close)>8)[0]+1)
        for gcl in groups:
            k=gcl[np.argmin(d[gcl])]; p=r['P'][k]
            if np.linalg.norm(p-RB)<70: continue
            if (len(gcl))*STEP>120: continue     # running along each other, not a junction
            J.append({'p':p,'a':i,'b':q,'ia':int(k),'ib':int(j[k])})
# merge junctions closer than 25 m
merged=[]
for j_ in J:
    for m in merged:
        if np.linalg.norm(m['p']-j_['p'])<25: m['roads']|={j_['a'],j_['b']}; break
    else: merged.append({'p':j_['p'],'roads':{j_['a'],j_['b']}})
def arms(m):
    n=0
    for ri in m['roads']:
        P=roads[ri]['P']; k=np.linalg.norm(P-m['p'],axis=1).argmin()
        n+= (1 if k*STEP>30 else 0)+(1 if (len(P)-1-k)*STEP>30 else 0)
    return n
for m in merged:
    m['arms']=arms(m); m['main']=any(roads[i]['kind']=='main' for i in m['roads']); m['mains']=sum(1 for i in m['roads'] if roads[i]['kind']=='main')
print('junctions',len(merged),'| on main roads',sum(m['main'] for m in merged),'| by arms',dict(Counter(m['arms'] for m in merged)),'| main x main',sum(1 for m in merged if m['mains']>=2))
# roundabout arms
arm=[]
for i,r in enumerate(roads):
    P=r['P']; d=np.linalg.norm(P-RB,axis=1)
    for end in (0,-1):
        if d[end]<75:
            k=np.where(d>=70)[0]; k=k[0] if end==0 else k[-1]; v=P[k]-RB; arm.append((round(math.degrees(math.atan2(v[0],v[1]))%360),r['name'],r['kind']))
arm.sort(); print('roundabout arms (bearing):',arm,'gaps',[ (arm[(i+1)%len(arm)][0]-arm[i][0])%360 for i in range(len(arm))])
pickle.dump({'roads':roads,'junctions':merged,'F':F,'W':W,'arm':arm},open('design.pkl','wb'))
for m in merged:
    if m['mains']>=2 or m['arms'] in (2,5): print('  junction',[round(float(v)) for v in m['p']],m['arms'],'arms',[roads[i]['name'] for i in m['roads']])
print('  tight bends:',[(x[0],x[3]) for x in rep if x[3]<25])
