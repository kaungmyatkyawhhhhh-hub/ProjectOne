"""Builds the lamp shells (left from the model's islands, right mirrored) -> lampscan/shells.pkl, and a preview sheet."""
import math,pickle
import numpy as np
from lamp_roles import *
from PIL import Image,ImageDraw
TAIL_DONOR={'bugotti_veyron_top':'bugotti_veyron_sport','bugotti_veyron':'bugotti_veyron_sport'}
REAR={'lexis_lfa':(.40,.60,.72,.95),'lexis_lfa_circuit':(.40,.60,.72,.95),'bugotti_veyron':(.30,.47,.47,.70),'bugotti_veyron_sport':(.30,.47,.47,.70),'bugotti_veyron_top':(.30,.47,.47,.70),'bugotti_chiron':(.46,.58,.0,0),'bugotti_chiron_pursport':(.46,.58,.70,.95),'bugotti_chiron_supersport':(.46,.58,.70,.95)}
TWIN={'lambrini_svj':('lambrini_svj63',(0,.02,.01),(0,0,.02))}
OFF={'HeadCore':.006,'HeadGlass':.010,'TurnF':.012,'TurnR':.016,'Rev':.016,'Tail':.008}
SLICE=dict(turnF=.24,turnR=.30,rev=.24)
def soup(islands):
    V=[];T=[]
    for v,t in islands:
        n=len(V); V+=v; T+=[(a+n,b+n,c+n) for a,b,c in t]
    return np.array(V,float).reshape(-1,3),np.array(T,int).reshape(-1,3)
def weld_normals(V,T):
    key=np.round(V,3); uq,inv=np.unique(key,axis=0,return_inverse=True); inv=inv.reshape(-1)
    N=np.zeros((len(uq),3))
    a,b,c=V[T[:,0]],V[T[:,1]],V[T[:,2]]
    fn=np.cross(b-a,c-a)
    for i in range(3): np.add.at(N,inv[T[:,i]],fn)
    L=np.linalg.norm(N,axis=1,keepdims=True); L[L<1e-12]=1
    return (N/L)[inv]
def shell(V,T,off):
    if len(T)==0: return None
    used=np.unique(T); m=-np.ones(len(V),int); m[used]=np.arange(len(used))
    V2=V[used]; T2=m[T]
    return V2+weld_normals(V2,T2)*off,T2
def tslice(V,T,x0,lo,hi):
    ax=np.abs(V[T].mean(axis=1)[:,0]-x0)
    return T[(ax>=lo)&(ax<=hi)]
def build_car(id):
    d,ro=build(id); x0=d['x0']; zr=d['zmax']; out={}
    def put(name,ise=None,VT=None,off=0):
        if VT is None:
            if not ise: return False
            VT=soup(ise)
        V,T=VT
        s=shell(V,T,OFF[name])
        if s is None: return False
        out[name+'L']=s
        m=s[0].copy(); m[:,0]=2*x0-m[:,0]
        out[name+'R']=(m,s[1][:,::-1])
        return True
    put('HeadCore',ro['core'])
    gV,gT=soup(ro['glass'])
    put('HeadGlass',VT=(gV,gT))
    if id=='lambrini_revuelto':
        yV,yT=soup(ro['turnF'])
        put('HeadCore',ro['core']+ro['turnF'])
        put('TurnF',VT=(yV,yT[yV[yT].mean(axis=1)[:,1]<.36]))
    elif id!='bugotti_veyron_top' and sum(len(i[1]) for i in ro['turnF'])>=30: put('TurnF',ro['turnF'])
    else:
        span=np.abs(gV[gT].mean(axis=1)[:,0]-x0); lo,hi=span.min(),span.max()
        put('TurnF',VT=(gV,tslice(gV,gT,x0,hi-(hi-lo)*SLICE['turnF'],hi+1)))
    # the tail lens
    tails=list(ro['tail'])
    if id in EXTRA: tails=[geo[id][k] for k in EXTRA[id]]
    if id=='lambrini_revuelto' or id=='lambrini_svj': put('Tail',tails)
    if id in TAIL_DONOR:
        dd,r2=build(TAIL_DONOR[id]); tails=r2['tail']; sh=(x0-dd['x0'],(.07 if id=='bugotti_veyron' else 0),zr-dd['zmax']-(.03 if id=='bugotti_veyron' else 0))
        tails=[([(p[0]+sh[0],p[1]+sh[1],p[2]+sh[2]) for p in v],t) for v,t in tails]
    tV,tT=soup(tails)
    zc=tV[tT].mean(axis=1)
    # the main unit only: not a low bar across the bumper, not a bar across the middle
    side=np.abs(zc[:,0]-x0)>.24
    keep=(zc[:,1]>zc[side,1].max()-.24)&side
    tT2=tT[keep]
    ax=np.abs(tV[tT2].mean(axis=1)[:,0]-x0); lo,hi=np.percentile(ax,2),ax.max()
    amb=None if id=='lambrini_revuelto' else (ro['turnR'] or ([geo[id][k] for k in EXTRA_AMB[id]] if id in EXTRA_AMB else None))
    if id in REAR:
        a,b,c,e=REAR[id]
    else:
        a,b,c,e=lo-1,lo+(hi-lo)*SLICE['rev'],hi-(hi-lo)*SLICE['turnR'],hi+1
    if amb and sum(len(i[1]) for i in amb)>=8: put('TurnR',amb)
    else: put('TurnR',VT=(tV,tslice(tV,tT2,x0,c,e)))
    put('Rev',VT=(tV,tslice(tV,tT2,x0,a,b)))
    if id in TWIN:
        tw,fs,rs=TWIN[id]
        dd,oo=build_car(tw)
        for n,(V,T) in oo.items():
            if n[:-1] in ('HeadCore','TurnR','Rev'):
                sh=fs if n.startswith('Head') else rs
                V2=V.copy(); V2[:,0]+=x0-dd['x0']; V2[:,1]+=sh[1]; V2[:,2]+=sh[2]
                out[n]=(V2,T)
    return d,out
COL=dict(HeadCore=(255,255,255),HeadGlass=(120,200,255),TurnF=(255,160,0),TurnR=(255,160,0),Rev=(200,255,200),Tail=(230,0,0))
def view(id,d,out,front,W=480,H=200):
    im=Image.new('RGB',(W,H),(10,12,30)); dr=ImageDraw.Draw(im,'RGBA'); x0=d['x0']; S=W/2.3
    fs=[]
    for n,(V,T) in out.items():
        r=n[:-1]
        if (r in('HeadCore','HeadGlass','TurnF'))!=front: continue
        for t in T:
            p=V[t]; fs.append(((p[:,2].mean() if front else -p[:,2].mean()),p,r))
    fs.sort(key=lambda f:-f[0])
    ys=[f[1][:,1].mean() for f in fs]; ym=(min(ys)+max(ys))/2 if ys else 0
    for _,p,r in fs:
        pts=[((q[0]-x0+1.15)*S,H/2-(q[1]-ym)*S) for q in p]
        c=COL[r]; dr.polygon(pts,fill=c+(70 if r=='HeadGlass' else 255,))
    dr.text((3,2),id.replace('bugotti_','b_').replace('lambrini_','l_'),fill=(255,255,0))
    return im
if __name__=='__main__':
    all_={}
    s=Image.new('RGB',(960,200*13))
    for i,id in enumerate(IDS):
        d,o=build_car(id); all_[id]=o
        print(id,{k:len(v[1]) for k,v in o.items() if k.endswith('L')})
        s.paste(view(id,d,o,True),(0,i*200)); s.paste(view(id,d,o,False),(480,i*200))
    pickle.dump(all_,open(SP+'/lampscan/shells.pkl','wb'))
    s.crop((0,0,960,1400)).save(SP+'/lampscan/shell1.png'); s.crop((0,1400,960,2600)).save(SP+'/lampscan/shell2.png')
