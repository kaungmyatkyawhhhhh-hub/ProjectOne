import json, sys, itertools, numpy as np
d=json.load(open(sys.argv[1])); keep=np.load(sys.argv[2]); depth=float(sys.argv[3])
rows=d['rows']; V=len(rows); U=len(rows[0]); S=d['step']
dep=np.full((V,U),np.nan)
for j,r in enumerate(rows):
    for i,(z,k) in enumerate(r):
        if z is not None: dep[j,i]=z
u=d['u0']+np.arange(U)*S; v=d['v0']-np.arange(V)*S
UU,VV=np.meshgrid(u,v)
hidden=np.nan_to_num(dep,nan=-1)>depth+0.002
def panels(x,y):
    mid=(x>212)&(x<948)&(y>4)&(y<396)
    mid&=~(((x<262)|(x>898))&(y<54)&(np.hypot(np.minimum(abs(x-262),abs(x-898)),y-54)>50))
    side=((x>12)&(x<202)|(x>958)&(x<1098))&(y>112)&(y<392)
    return mid|side, mid, side
best=None
for cu,cv,w,h in itertools.product(np.arange(-0.006,0.0061,0.002),np.arange(0.0,0.03,0.002),np.arange(0.32,0.40,0.004),np.arange(0.12,0.17,0.004)):
    x=(UU-(cu-w/2))/w*1110; y=(cv+h/2-VV)/h*400
    p,mid,side=panels(x,y)
    poke=(p&~keep&~hidden).sum()
    unc=(keep&~p).sum()
    # aspect cost: stretching the art away from 1110:400
    asp=abs((w/h)/(1110/400)-1)
    cost=poke*3+unc+asp*float(sys.argv[5])
    if best is None or cost<best[0]: best=(cost,cu,cv,w,h,poke,unc,asp)
print('best cost %.0f cu %.3f cv %.3f w %.3f h %.3f poke %d uncovered %d (of %d) stretch %.2f' % (best[0],*best[1:5],best[5],best[6],keep.sum(),best[7]))
cu,cv,w,h=best[1:5]
x=(UU-(cu-w/2))/w*1110; y=(cv+h/2-VV)/h*400
p,_,_=panels(x,y)
img=np.zeros((V,U,3),np.uint8); img[keep]=(60,60,200); img[p&hidden]=(60,160,60); img[p&keep]=(90,140,255); img[p&~keep&~hidden]=(255,0,0); img[keep&~p]=(255,255,0)
np.save(sys.argv[4], img)
json.dump({'cu':cu,'cv':cv,'w':w,'h':h}, open(sys.argv[4]+'.json','w'))
