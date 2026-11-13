import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from common import *
import numpy as np, json, pickle
from collections import defaultdict,Counter
ws=load_osm(); k=load_kml()
hw=[w for w in ws if 'highway' in w['tags']]
def nm(w): t=w['tags']; return t.get('name:en') or t.get('name') or ''
def canon(n):
    n=n.lower()
    for a,b in [('pyi road','pyay road'),('pyay ( prome) road','pyay road'),('kabar aye pagoda','kabar aye pagoda road')]:
        if a in n: return b
    return n
MAJ=['trunk','primary','secondary','tertiary','unclassified','residential','living_street']
segs=[];meta=[]
for i,w in enumerate(hw):
    for a,b in zip(w['xy'],w['xy'][1:]): segs.append((*a,*b)); meta.append(i)
S=np.array(segs); meta=np.array(meta); A=S[:,:2];B=S[:,2:];D=B-A;L2=(D**2).sum(1);L2[L2==0]=1
cls=np.array([hw[i]['tags']['highway'] for i in meta]); major=np.isin(cls,MAJ)
def nearest(p,mask):
    t=np.clip(((p-A)*D).sum(1)/L2,0,1); d=np.hypot(*(p-A-t[:,None]*D).T); d=np.where(mask,d,1e9); j=d.argmin(); return d[j],meta[j]
MAIN={'loop':'YANGON MAP GAME','blue':'new roasd','green':'more roads'}
out={}
for key,name in MAIN.items():
    pts=densify(k[name],10); P=np.array(pts)
    d=[];wi=[]
    for p in P:
        dd,i=nearest(p,major); d.append(dd); wi.append(i)
    d=np.array(d); on=d<=15
    # close gaps < 80 m (junction mouths), drop snapped runs < 150 m
    def runs(mask):
        r=[];s=0
        for i in range(1,len(mask)+1):
            if i==len(mask) or mask[i]!=mask[s]: r.append((s,i,mask[s])); s=i
        return r
    for s,e,v in runs(on):
        if not v and (e-s)*10<80 and s>0 and e<len(on): on[s:e]=True
    for s,e,v in runs(on):
        if v and (e-s)*10<150: on[s:e]=False
    for s,e,v in runs(on):
        if not v and (e-s)*10<80 and s>0 and e<len(on): on[s:e]=True
    names=[canon(nm(hw[i])) if o else '' for i,o in zip(wi,on)]
    out[key]={'pts':pts,'on':on.tolist(),'dist':d.tolist(),'names':names,'runs':[(s*10,e*10,bool(v)) for s,e,v in runs(on)]}
    print(key,'len',round(length(k[name])),'snapped %.0f%%'%(100*on.mean()),[(s,e,v) for s,e,v in out[key]['runs']])
    c=Counter(n for n in names if n); print('   follows',[(n,v*10) for n,v in c.most_common(8)])
pickle.dump(out,open('main.pkl','wb'))
