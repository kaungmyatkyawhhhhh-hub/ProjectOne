import numpy as np, json
from scipy import ndimage as ndi
from scipy.optimize import minimize_scalar
sb=np.load('side_body.npy'); tb=np.load('top_body.npy'); fb=np.load('front_body.npy')
def ext(m,axis):
    cols=np.where(m.any(0))[0]; res={}
    for x in cols:
        ys=np.where(m[:,x])[0]; res[int(x)]=(int(ys.min()),int(ys.max()))
    return res
S=ext(sb,0); T=ext(tb,0)
sx=sorted(S); tx=sorted(T)
print('side body x',sx[0],sx[-1],'maxh',max(b-a for a,b in S.values()))
print('top body x',tx[0],tx[-1],'maxw',max(b-a for a,b in T.values()))
tcen=np.median([ (a+b)/2 for a,b in T.values()]); print('top centre y',tcen)
ys,xs=np.where(fb); print('front body bbox',xs.min(),xs.max(),ys.min(),ys.max(), 'w',xs.max()-xs.min(),'h',ys.max()-ys.min())
# superellipse fit on front body (normalised)
cx=(xs.min()+xs.max())/2; cy=(ys.min()+ys.max())/2; a=(xs.max()-xs.min())/2; b=(ys.max()-ys.min())/2
yy,xx=np.mgrid[ys.min()-5:ys.max()+6, xs.min()-5:xs.max()+6]
M=fb[ys.min()-5:ys.max()+6, xs.min()-5:xs.max()+6]
def loss(n):
    P=(np.abs((xx-cx)/a)**n+np.abs((yy-cy)/b)**n)<=1
    return (P^M).sum()
r=minimize_scalar(loss,bounds=(1.6,4),method='bounded'); print('front exponent',r.x, loss(r.x)/M.sum())
# where is the widest point vertically (front): centre of width row
rows=[(y,(fb[y].nonzero()[0].max()-fb[y].nonzero()[0].min())) for y in range(ys.min(),ys.max()) if fb[y].any()]
ym=max(rows,key=lambda t:t[1]); print('widest row',ym,'rel',(ym[0]-ys.min())/(ys.max()-ys.min()))
json.dump(dict(S=S,T=T,tcen=float(tcen),front=dict(cx=cx,cy=cy,a=a,b=b,n=r.x,widest=(ym[0]-ys.min())/(ys.max()-ys.min()))),open('prof.json','w'))
