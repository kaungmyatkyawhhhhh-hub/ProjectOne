import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import json, numpy as np, math, pickle
from scipy.ndimage import minimum_filter, gaussian_filter
from common import *
H=json.load(open('ygn_heights.json')); Z=np.array(H['heights_m'])   # [ny][nx], south->north, west->east
ny,nx=Z.shape
gx=(np.linspace(H['west'],H['east'],nx)-LON0)*KX; gy=(np.linspace(H['south'],H['north'],ny)-LAT0)*KY
LAKE=16.0
def make_field(in_water):
    X,Y=np.meshgrid(gx,gy); W=in_water(np.column_stack([X.ravel(),Y.ravel()])).reshape(Z.shape)
    land=~W
    z=np.where(land,Z,np.nan)
    # roofs and trees: take the lowest of the 3x3 neighbourhood (about 180 m) over land
    zmin=minimum_filter(np.where(land,Z,1e9),size=3,mode='nearest'); zmin=np.where(zmin>1e8,LAKE+1.5,zmin)
    # smooth over land only (normalised blur, sigma 150 m)
    sig=2.5
    num=gaussian_filter(np.where(land,zmin,0.0),sig,mode='nearest'); den=gaussian_filter(land.astype(float),sig,mode='nearest')
    F=np.where(den>0.05,num/np.maximum(den,1e-6),LAKE+1.5)
    F=np.maximum(F,LAKE+1.5)
    return F,W
def sampler(F):
    def at(P):
        P=np.atleast_2d(P); fi=np.clip((P[:,0]-gx[0])/(gx[1]-gx[0]),0,nx-1.001); fj=np.clip((P[:,1]-gy[0])/(gy[1]-gy[0]),0,ny-1.001)
        i=fi.astype(int); j=fj.astype(int); a=fi-i; b=fj-j
        return F[j,i]*(1-a)*(1-b)+F[j,i+1]*a*(1-b)+F[j+1,i]*(1-a)*b+F[j+1,i+1]*a*b
    return at
if __name__=='__main__':
    from d2_net import in_water
    F,W=make_field(in_water)
    gyv,gxv=np.gradient(F,gy,gx); slope=np.hypot(gxv,gyv)
    print('ground field: min %.1f max %.1f m | steepest %.1f%% | 99th pct %.1f%%'%(F.min(),F.max(),slope.max()*100,np.percentile(slope,99)*100))
    N=pickle.load(open('net2.pkl','rb')); at=sampler(F)
    for n,p in N['MAIN'].items():
        h=at(p); s=np.r_[0,np.cumsum(np.linalg.norm(np.diff(p,axis=0),axis=1))]; g=np.abs(np.diff(h)/np.diff(s))
        print(n,'height %.1f to %.1f m, steepest %.1f%%'%(h.min(),h.max(),g.max()*100))
    np.save('field.npy',F); np.save('water.npy',W)
