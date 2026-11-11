import sys; sys.path.insert(0,'.')
from kitlib import *
from skimage.morphology import skeletonize
if not globals().get('NOCLEAR'): clear()
PX=1/32.0
objs={}
def add_faces(verts,faces,mats_idx,name,mats):
    o=mesh_from(verts,faces,name)
    for m in mats: o.data.materials.append(m)
    for p,i in zip(o.data.polygons,mats_idx): p.material_index=i
    flat(o); return o
# ---------- Branch coral: tubes along the front-view skeleton, tips pushed into depth by the top-view arm directions
BR=[mat('br_l',(255,176,196)),mat('br_m',(255,111,145)),mat('br_d',(214,80,112))]
fm=np.load('corals1_front.npy'); H,W=fm.shape
sk=skeletonize(fm); dt=ndi.distance_transform_edt(fm)
ys,xs=np.where(sk)
pts=set(zip(ys.tolist(),xs.tolist()))
def nbrs(p):
    y,x=p; return [(y+dy,x+dx) for dy in (-1,0,1) for dx in (-1,0,1) if (dy or dx) and (y+dy,x+dx) in pts]
root=max(pts,key=lambda p:p[0])   # lowest skeleton pixel
# BFS tree from the root
parent={root:None}; order=[root]; q=[root]
while q:
    nq=[]
    for p in q:
        for n in nbrs(p):
            if n not in parent: parent[n]=p; order.append(n); nq.append(n)
    q=nq
kids={}
for p,par in parent.items():
    if par: kids.setdefault(par,[]).append(p)
tips=[p for p in parent if p not in kids and dt[p]>0]
# keep real tips (long branches only)
def path_to_root(p):
    out=[p]
    while parent[out[-1]]: out.append(parent[out[-1]])
    return out[::-1]
paths=[path_to_root(t) for t in tips]
paths=[pp for pp in paths if len(pp)>40]
def private_len(pp,others):
    shared=set().union(*[set(o) for o in others if o is not pp]) if len(others)>1 else set()
    return sum(1 for p in pp if p not in shared)
paths=[pp for pp in paths if private_len(pp,paths)>28]
# top-view arm angles
tm=np.load('corals1_top.npy'); th,tw=tm.shape; ty,tx=np.where(tm)
ang=np.degrees(np.arctan2(-(ty-th/2),tx-tw/2))%360; rr=np.hypot(ty-th/2,tx-tw/2)
prof=np.array([rr[(ang>=b)&(ang<b+10)].max() if ((ang>=b)&(ang<b+10)).any() else 0 for b in range(0,360,10)])
from scipy.signal import find_peaks
pk,_=find_peaks(np.concatenate([prof,prof[:3]]),distance=3,prominence=15)
arm=sorted(set(int(p%36)*10+5 for p in pk))
print('branch tips',len(paths),'top arms',arm)
# assign each tip a depth: sort tips by x, arms by cos -> pair them up
tips_x=sorted(range(len(paths)),key=lambda i:paths[i][-1][1])
arms_sorted=sorted(arm,key=lambda a:math.cos(math.radians(a)))
V=[];F=[];MI=[]
sides=8
done=set()
for rank,i in enumerate(tips_x):
    a=math.radians(arms_sorted[min(len(arms_sorted)-1,int(rank*len(arms_sorted)/len(paths)))])
    zt=math.sin(a)*0.45   # depth as a fraction of the horizontal reach
    pp=paths[i][::6]+[paths[i][-1]]
    xr=(paths[i][-1][1]-root[1])
    prev=None
    for k,(y,x) in enumerate(pp):
        t=k/(len(pp)-1)
        if (y,x) in done and k<len(pp)-1 and prev is None: continue
        r=max(6,dt[y,x])*0.95
        cx=(x-W/2)*PX; cz=(H-y)*PX; cy=zt*abs(x-root[1])*PX*1.4+zt*t*0.6
        ring=[]
        for s in range(sides):
            ag=2*math.pi*s/sides
            ring.append(len(V)); V.append((cx+math.cos(ag)*r*PX, cy+math.sin(ag)*r*PX, cz))
        if prev:
            for s in range(sides):
                F.append([prev[s],prev[(s+1)%sides],ring[(s+1)%sides],ring[s]]); MI.append(1)
        prev=ring
        done.add((y,x))
    # rounded tip cap (lighter)
    c=len(V); V.append((cx,cy,cz+r*PX*0.9))
    for s in range(sides): F.append([prev[s],prev[(s+1)%sides],c]); MI.append(0)
br=add_faces(V,F,MI,'BranchCoral',BR)
shade_by_normal(br,BR,mask_fn=None)
# lighter tips: faces in the top 18% of each branch length -> light
objs['BranchCoral']=[br]
# ---------- Table coral: lathe from the front view widths, top-view round outline
TB=[mat('tb_l',(255,154,122)),mat('tb_m',(255,100,64)),mat('tb_d',(214,72,46))]
fm=np.load('corals3_front.npy'); H,W=fm.shape
rows=list(range(0,H,max(1,H//16)))+[H-1]
prof=[]
for y in rows:
    xs_=np.where(fm[y])[0]
    if len(xs_): prof.append(((H-1-y)*PX,(xs_.max()-xs_.min())/2*PX))
prof=prof[::-1]  # bottom -> top
sides=16; V=[];F=[];MI=[]
rings=[]
for z,r in prof:
    ring=[]
    for s in range(sides):
        a=2*math.pi*s/sides+ (0.08 if len(rings)%2 else 0)
        ring.append(len(V)); V.append((math.cos(a)*r,math.sin(a)*r,z))
    rings.append(ring)
for i in range(len(rings)-1):
    for s in range(sides):
        F.append([rings[i][s],rings[i][(s+1)%sides],rings[i+1][(s+1)%sides],rings[i+1][s]]); MI.append(0)
c=len(V); V.append((0,0,prof[-1][0]+0.05)); 
for s in range(sides): F.append([rings[-1][s],rings[-1][(s+1)%sides],c]); MI.append(0)
c=len(V); V.append((0,0,0))
for s in range(sides): F.append([rings[0][(s+1)%sides],rings[0][s],c]); MI.append(0)
tb=add_faces(V,F,MI,'TableCoral',TB); shade_by_normal(tb,TB); objs['TableCoral']=[tb]
# ---------- Brain coral: dome heightfield + the groove pattern from the top view
BRN=[mat('brain_l',(176,232,72)),mat('brain_m',(155,216,58)),mat('brain_d',(100,160,36))]
a=np.array(Image.open('corals4_top.png').convert('RGBA')).astype(float)
tm=a[...,3]>127; lum=(a[...,:3].mean(-1))
G=64; th,tw=tm.shape
mk=np.array(Image.fromarray(tm.astype(np.uint8)*255).resize((G,G)))>127
lm=np.array(Image.fromarray(lum.astype(np.uint8)).resize((G,G))).astype(float)
G=128
mk=np.array(Image.fromarray(tm.astype(np.uint8)*255).resize((G,G)))>127
lm=np.array(Image.fromarray(lum.astype(np.uint8)).resize((G,G))).astype(float)
groove=ndi.binary_dilation(lm<np.percentile(lm[mk],28),iterations=1)
ridge=ndi.gaussian_filter((~groove).astype(float),0.7)
ridge=np.clip((ridge-0.35)/0.3,0,1)
ridge_s=ndi.gaussian_filter(ridge,2.2)
Hf=np.load('corals4_front.npy').shape[0]; R=tw/2
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=5,radius=1)
bn=bpy.context.object; bn.name='BrainCoral'
for m in BRN: bn.data.materials.append(m)
for v in bn.data.vertices:
    x,y,z=v.co
    th_=math.acos(max(-1,min(1,z))); rr_=math.hypot(x,y)+1e-6
    u=x/rr_*min(1,th_/(math.pi/2)); w=y/rr_*min(1,th_/(math.pi/2))
    i_=int(np.clip((u*0.5+0.5)*G,0,G-1)); j_=int(np.clip((-w*0.5+0.5)*G,0,G-1))
    rd=ridge_s[j_,i_]
    k=1+0.14*rd
    v.co.x=x*k*R*PX; v.co.y=y*k*R*PX; v.co.z=max(z,-0.05)*k*Hf*PX*1.02
for p in bn.data.polygons:
    c=p.center; x,y,z=c.x/(R*PX),c.y/(R*PX),c.z/(Hf*PX)
    nrm=math.sqrt(x*x+y*y+z*z)+1e-6; x,y,z=x/nrm,y/nrm,z/nrm
    th_=math.acos(max(-1,min(1,z))); rr_=math.hypot(x,y)+1e-6
    u=x/rr_*min(1,th_/(math.pi/2)); w=y/rr_*min(1,th_/(math.pi/2))
    i_=int(np.clip((u*0.5+0.5)*G,0,G-1)); j_=int(np.clip((-w*0.5+0.5)*G,0,G-1))
    p.material_index=(0 if p.normal.z>0.6 else 1) if ridge[j_,i_]>0.5 else 2
flat(bn)
dd=bn.modifiers.new('d','DECIMATE'); dd.decimate_type='UNSUBDIV'; dd.iterations=1; bpy.context.view_layer.objects.active=bn; bpy.ops.object.modifier_apply(modifier='d')
objs['BrainCoral']=[bn]
# ---------- Sea fan: the front lattice extruded thin, bent along the top-view arc
FN=[mat('fan_l',(195,162,255)),mat('fan_m',(142,91,232)),mat('fan_d',(108,64,190))]
a2=np.array(Image.open('corals2_front.png').convert('RGB')).astype(float)
fm=np.sqrt(((a2-[255,0,255])**2).sum(-1))>110   # keep the lattice holes (inner magenta)
H,W=fm.shape
s=0.8; m2=np.array(Image.fromarray(fm.astype(np.uint8)*255).resize((int(W*s),int(H*s))))>127
vol=np.zeros((m2.shape[1]+4,9,m2.shape[0]+4))
vol[2:-2,2:-2,2:-2]=m2.T[:,None,::-1]
vol=ndi.gaussian_filter(vol,0.45)
v,f,_,_=measure.marching_cubes(vol,0.5)
v=(v-2)/s
verts=np.stack([(v[:,0]-W/2)*PX,(v[:,1]-2.5)*PX*0.9,v[:,2]*PX],1)
# bend: the top view is a shallow arc (centre forward)
verts[:,1]+=-((verts[:,0]/(W/2*PX))**2)*0.45
fan=mesh_from(verts,f,'SeaFan'); 
dd=fan.modifiers.new('d','DECIMATE'); dd.ratio=6000/max(1,len(fan.data.polygons)); bpy.context.view_layer.objects.active=fan; bpy.ops.object.modifier_apply(modifier='d')
flat(fan); shade_by_normal(fan,FN); objs['SeaFan']=[fan]
for k,v in objs.items(): print(k,sum(len(x.data.polygons) for x in v),'faces',tuple(round(d,2) for d in v[0].dimensions))
