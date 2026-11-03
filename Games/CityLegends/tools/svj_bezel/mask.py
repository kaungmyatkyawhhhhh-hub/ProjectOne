import json, numpy as np
def allowed_in_design(probe, keepf, fit, depth):
    d=json.load(open(probe)); keep=np.load(keepf)
    rows=d['rows']; V=len(rows); U=len(rows[0]); S=d['step']
    dep=np.full((V,U),np.nan)
    for j,r in enumerate(rows):
        for i,(z,k) in enumerate(r):
            if z is not None: dep[j,i]=z
    allowed=keep|(np.nan_to_num(dep,nan=-1)>depth-0.015)  # (only far-behind spots: past the hood, the windscreen)
    cu,cv,w,h=fit
    xs=np.arange(1110)+0.5; ys=np.arange(400)+0.5
    X,Y=np.meshgrid(xs,ys)
    uu=cu-w/2+X/1110*w; vv=cv+h/2-Y/400*h
    ii=np.clip(np.round((uu-d['u0'])/S).astype(int),0,U-1)
    jj=np.clip(np.round((d['v0']-vv)/S).astype(int),0,V-1)
    return allowed[jj,ii]
a=allowed_in_design('svj.json','keep.npy',(-0.002,0.002,0.336,0.136),0.003)
b=allowed_in_design('svj63.json','keep63.npy',(0.0,0.002,0.324,0.132),0.005)
m=a&b
print('opaque share', m.mean().round(3), 'svj', a.mean().round(3), 'svj63', b.mean().round(3))
np.save('mask.npy', m.astype(np.uint8))
