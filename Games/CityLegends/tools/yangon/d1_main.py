# Main-road centre lines: the owner's drawn line, moved to the middle of the real road(s) it follows, then smoothed.
import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from render import *
import pickle
RMIN_MAIN=60.0   # metres
def perp_centre(key):
    m=main[key]; P=m['P']; on=m['on']
    segs=[(a,b) for a,b,wi in real_main[key] if hw[wi]['tags'].get('junction')!='roundabout' and not hw[wi]['tags'].get('bridge')]
    A=np.array([s[0] for s in segs]); B=np.array([s[1] for s in segs]); D=B-A
    t=np.gradient(P,axis=0); t/=np.linalg.norm(t,axis=1)[:,None]+1e-9
    # smooth direction so corners in the coarse drawing do not flip the normal
    k=np.ones(7)/7; ts=np.column_stack([np.convolve(np.pad(t[:,j],3,mode='edge'),k,'valid') for j in (0,1)]); ts/=np.linalg.norm(ts,axis=1)[:,None]
    n=np.column_stack([-ts[:,1],ts[:,0]])
    off=np.full(len(P),np.nan); sep=np.full(len(P),np.nan)
    for i in range(len(P)):
        if not on[i]: off[i]=0; continue
        # intersect line P+s*n with each segment A+u*D
        den=n[i,0]*D[:,1]-n[i,1]*D[:,0]
        with np.errstate(divide='ignore',invalid='ignore'):
            w=A-P[i]
            s=(w[:,0]*D[:,1]-w[:,1]*D[:,0])/den
            u=(w[:,0]*n[i,1]-w[:,1]*n[i,0])/den
        ok=(np.abs(den)>1e-9)&(u>=0)&(u<=1)&(np.abs(s)<=50)
        if ok.any(): off[i]=(s[ok].min()+s[ok].max())/2; sep[i]=s[ok].max()-s[ok].min()
    idx=np.arange(len(P)); good=~np.isnan(off)
    off=np.interp(idx,idx[good],off[good])
    # median 9 then mean 15 (about 150 m)
    from scipy.ndimage import median_filter,uniform_filter1d
    off=uniform_filter1d(median_filter(off,size=9,mode='nearest'),size=15,mode='nearest')
    C=P+off[:,None]*n
    return C,sep
def resample(pts,step):
    pts=np.asarray(pts); d=np.r_[0,np.cumsum(np.linalg.norm(np.diff(pts,axis=0),axis=1))]
    n=max(2,int(round(d[-1]/step))+1); s=np.linspace(0,d[-1],n)
    return np.column_stack([np.interp(s,d,pts[:,0]),np.interp(s,d,pts[:,1])])
def radius(pts):
    a,b,c=pts[:-2],pts[1:-1],pts[2:]
    ab=np.linalg.norm(b-a,axis=1); bc=np.linalg.norm(c-b,axis=1); ca=np.linalg.norm(a-c,axis=1)
    area=np.abs((b[:,0]-a[:,0])*(c[:,1]-a[:,1])-(b[:,1]-a[:,1])*(c[:,0]-a[:,0]))/2
    r=ab*bc*ca/(4*area+1e-9); return np.r_[1e9,r,1e9]
def smooth_to_radius(pts,rmin,step=5.0,pin_ends=True,maxit=4000):
    p=resample(pts,step).copy()
    # light overall smoothing first (removes digitising wiggle)
    for _ in range(12):
        q=p.copy(); q[1:-1]=0.25*p[:-2]+0.5*p[1:-1]+0.25*p[2:]; p=q
    for it in range(maxit):
        r=radius(p); bad=r<rmin
        if not bad.any(): break
        # widen the bad zone a little so the fix blends in
        b2=bad.copy()
        for sft in (1,2,3): b2[sft:]|=bad[:-sft]; b2[:-sft]|=bad[sft:]
        b2[0]=b2[-1]=False
        q=p.copy(); i=np.where(b2)[0]; q[i]=0.25*p[i-1]+0.5*p[i]+0.25*p[i+1]; p=q
    return resample(p,step)
if __name__=='__main__':
    out={}
    for key in ['loop','blue','green']:
        C,sep=perp_centre(key)
        S=smooth_to_radius(C,RMIN_MAIN)
        r=radius(S); L=np.linalg.norm(np.diff(S,axis=0),axis=1).sum()
        # how far the final line moved from the drawn line
        from scipy.spatial import cKDTree
        d,_=cKDTree(resample(main[key]['P'],2)).query(S)
        print(key,'len %.0f m'%L,'min radius %.0f m'%r.min(),'moved from drawn line: median %.1f max %.0f m'%(np.median(d),d.max()),'| real road split: median %.0f max %.0f m'%(np.nanmedian(sep),np.nanmax(sep)))
        out[key]=S
    pickle.dump(out,open('centre.pkl','wb'))
