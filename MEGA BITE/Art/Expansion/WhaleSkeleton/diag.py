import sys, json, numpy as np, cv2, trimesh
vs=np.load('v_side.npy'); vt=np.load('v_top.npy')
C=json.load(open('cfg.json'))
sc = trimesh.load('model.obj', force='scene', process=False)
P=[];F=[];off=0
for m in sc.geometry.values():
    v=np.asarray(m.vertices); P.append(v); F.append(np.asarray(m.faces)+off); off+=len(v)
P=np.concatenate(P); F=np.concatenate(F); P=np.stack([P[:,0],-P[:,2],P[:,1]],1)
def rast(au,av,s,a,b):
    im=np.zeros(vs.shape,np.uint8); pts=np.stack([au+P[:,a]*s, av-P[:,b]*s],1)
    for f in F: cv2.fillConvexPoly(im,np.round(pts[f]).astype(np.int32),1)
    return im.astype(bool)
S=rast(30,450,7.425,0,2); T=rast(40,755,4.175,0,1)
np.save('r_side.npy',S); np.save('r_top.npy',T)
def table(R,M,au,s,name,rows):
    print(name, "IoU", round((R&M).sum()/(R|M).sum(),3))
    tot=(R|M).sum()
    for X0 in range(0,200,10):
        x0=int(au+X0*s); x1=int(au+(X0+10)*s)
        g=(M[:,x0:x1]&~R[:,x0:x1]); r=(R[:,x0:x1]&~M[:,x0:x1])
        line=f"  X {X0:3d}-{X0+10:3d}: sheet-only {100*g.sum()/tot:4.1f}%  model-only {100*r.sum()/tot:4.1f}%"
        for (nm,(ya,yb)) in rows:
            line+=f" | {nm} g{100*g[ya:yb].sum()/tot:4.1f} r{100*r[ya:yb].sum()/tot:4.1f}"
        print(line)
zrow=lambda z0,z1:(int(450-z1*7.425),int(450-z0*7.425))
table(S,vs,30,7.425,"SIDE",[("z<8",zrow(-3,8)),("8-24",zrow(8,24)),("24-40",zrow(24,40)),(">40",zrow(40,60))])
yrow=lambda y0,y1:(int(755-y1*4.175),int(755-y0*4.175))
table(T,vt,40,4.175,"TOP",[("y<-20",yrow(-50,-20)),("-20..0",yrow(-20,0)),("0..20",yrow(0,20)),(">20",yrow(20,50))])
