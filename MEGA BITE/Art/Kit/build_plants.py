import sys; sys.path.insert(0,'.')
from kitlib import *
if not globals().get('NOCLEAR'): clear()
PX=1/32.0
objs={}
# ---------------- Sea palm ----------------
LEAF=[mat('palm_leaf',(74,91,214)),mat('palm_leaf_d',(56,68,170)),mat('palm_rib',(124,140,255))]
TRUNK=[mat('trunk',(36,160,180)),mat('trunk_ring',(22,110,128))]
def add_faces(verts,faces,mats_idx,name,mats):
    o=mesh_from(verts,faces,name)
    for m in mats: o.data.materials.append(m)
    for p,i in zip(o.data.polygons,mats_idx): p.material_index=i
    flat(o); return o
# trunk: centre line from the front view (px, y down): (178,192)->(162,384), radius 19->30 px, 6 sides, 7 segments w/ rings
V=[];F=[];MI=[]
segs=8; sides=6
def ring(t):
    y=192+(384-192)*t; x=178+(150-178)*t**1.4; r=15+(25-15)*t**2
    return x,y,r
rings=[]
for i in range(segs+1):
    t=i/segs; x,y,r=ring(t)
    ids=[]
    for k in range(sides):
        a=2*math.pi*k/sides+0.3
        V.append(((x-173.5)*PX+math.cos(a)*r*PX, math.sin(a)*r*PX, (384-y)*PX)); ids.append(len(V)-1)
    rings.append(ids)
    if i<segs and i>0:
        # a slightly fatter ring lip
        pass
for i in range(segs):
    for k in range(sides):
        a,b=rings[i][k],rings[i][(k+1)%sides]; c,d=rings[i+1][(k+1)%sides],rings[i+1][k]
        F.append([a,b,c,d]); MI.append(1 if i%2==0 else 0)
F.append(rings[0][::-1]); MI.append(0)
trunk=add_faces(V,F,MI,'Palm_trunk',TRUNK)
# crown centre
cx,cy=(176-173.5)*PX, 0; cz=(384-160)*PX
# fronds: 7, angles from the top-view polar peaks; arc: up 100 px at 40%, tip at -15 px, length ~178 px
angs=[8,62,118,172,218,266,312]
V=[];F=[];MI=[]
for j,ad in enumerate(angs):
    a=math.radians(ad); PK=520+220*abs(math.sin(a)); L=(176+((j*37)%9)-4)*PX
    dirx,diry=math.cos(a),math.sin(a)
    n=7; prev=None
    for i in range(n+1):
        t=i/n
        h=(PK*t*(1-t)**1.8 - 25*t**2)*PX   # rise then droop (sheet: +100 px peak, tips 30 px below the crown)
        w=(0.0 if i==0 else (46*math.sin(math.pi*min(1,t*1.15))**0.7)*PX)*(1 if i<n else 0)
        px_,py_=cx+dirx*L*t, cy+diry*L*t
        # perpendicular in the horizontal plane
        ox,oy=-diry*w,dirx*w
        fold=w*0.35  # V-fold: edges lower than the midrib
        mid=(px_,py_,cz+h); le=(px_+ox,py_+oy,cz+h-fold); re=(px_-ox,py_-oy,cz+h-fold)
        cur=[len(V),len(V)+1,len(V)+2]; V+= [mid,le,re]
        if prev:
            pm,pl,pr=prev; m_,l_,r_=cur
            F.append([pm,pl,l_,m_]); MI.append(0)
            F.append([pr,pm,m_,r_]); MI.append(1)
        prev=cur
    # midrib strip (thin raised light band)
    prev=None
    for i in range(n):
        t=(i+0.5)/n if i>0 else 0.05
    rb=[]
    for i in range(n):
        t=i/n
        h=(PK*t*(1-t)**1.8 - 25*t**2)*PX+0.02
        w=(5*(1-t))*PX
        px_,py_=cx+dirx*L*t, cy+diry*L*t; ox,oy=-diry*w,dirx*w
        rb.append((len(V),len(V)+1)); V+=[(px_+ox,py_+oy,cz+h),(px_-ox,py_-oy,cz+h)]
    for i in range(n-1):
        a1,b1=rb[i]; a2,b2=rb[i+1]; F.append([a1,b1,b2,a2]); MI.append(2)
fr=add_faces(V,F,MI,'Palm_fronds',LEAF)
fr.data.flip_normals() if False else None
objs['SeaPalm']=[trunk,fr]
# ---------------- Bubble coral: circles fitted on the front + top views ----------------
BUB=[mat('bub_l',(255,212,106)),mat('bub_m',(255,176,32)),mat('bub_d',(217,131,26))]
def circles(mask,n=9,minr=12):
    m=mask.copy(); out=[]
    for _ in range(n):
        dt=ndi.distance_transform_edt(m)
        r=dt.max()
        if r<minr: break
        y,x=np.unravel_index(dt.argmax(),dt.shape); out.append((x,y,r))
        yy,xx=np.mgrid[0:m.shape[0],0:m.shape[1]]
        m[(xx-x)**2+(yy-y)**2<(r*1.05)**2]=False
    return out
# balls measured on the sheet (full-sheet px: centre x, centre y, radius) + depth order from the top view
balls=[(150,50,70,-0.45),(158,172,80,0.3),(65,122,45,-0.25),(239,98,48,-0.45),(40,195,42,0.25),(288,182,51,-0.05),(241,215,38,0.6)]  # crop px, measured on a 25 px grid
x0,y0=0,0; fm=np.load('plants2_front.npy'); Hf,Wf=fm.shape
parts=[]
for i,(x,y,r,z) in enumerate(balls):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=r*PX/0.95,location=((x-Wf/2)*PX,-z*r*PX*1.6,(Hf-y)*PX))
    o=bpy.context.object; o.name=f'Bubble_{i}'; o.rotation_euler=(i*0.7,i*1.3,i*0.4); flat(o)
    shade_by_normal(o,BUB); parts.append(o)
objs['BubbleCoral']=parts
print('bubbles',len(balls))
# ---------------- Kelp bunch ----------------
KELP=[mat('kelp',(61,190,90)),mat('kelp_d',(35,128,58))]
STONE=[mat('stone_l',(170,170,176)),mat('stone_m',(130,130,138)),mat('stone_d',(96,96,104))]
km=np.load('plants3_front.npy'); a=np.array(Image.open('plants3_front.png').convert('RGBA')).astype(int)
green=km&(a[...,1]>a[...,0]+40)
Hk,Wk=km.shape
# blade tips: local maxima of the top edge of green columns
topy=np.array([np.where(green[:,x])[0].min() if green[:,x].any() else Hk for x in range(Wk)])
from scipy.signal import find_peaks
pk,_=find_peaks(-topy,distance=25,prominence=25)
print('kelp tips',[(int(x),int(topy[x])) for x in pk])
V=[];F=[];MI=[]
base=(Wk/2, Hk-40)
rng=np.random.default_rng(3)
for j,x in enumerate(pk):
    tipx,tipy=x,topy[x]; n=8; prev=None
    phase=rng.uniform(0,6.28); ang=rng.uniform(0,6.28)
    for i in range(n+1):
        t=i/n
        bx=base[0]+(tipx-base[0])*t+ 22*math.sin(phase+t*7)*(t)   # wavy
        bz=base[1]+(tipy-base[1])*t
        w=(28*math.sin(math.pi*min(1,t*1.05+0.08))**0.8)*(1 if i<n else 0.0)
        tw=ang+t*1.2  # blade twists slowly
        ox,oy=math.cos(tw)*w,math.sin(tw)*w
        c=((bx-Wk/2)*PX,(j-2)*0.12,(Hk-bz)*PX)
        l=(c[0]+ox*PX,c[1]+oy*PX,c[2]); r_=(c[0]-ox*PX,c[1]-oy*PX,c[2])
        cur=[len(V),len(V)+1,len(V)+2]; V+=[c,l,r_]
        if prev:
            F.append([prev[0],prev[1],cur[1],cur[0]]); MI.append(0)
            F.append([prev[2],prev[0],cur[0],cur[2]]); MI.append(1)
        prev=cur
kelp=add_faces(V,F,MI,'Kelp_blades',KELP)
st=np.zeros_like(km); st[Hk-45:,:]=km[Hk-45:,:]&~green[Hk-45:,:]
yy,xx=np.where(st); sm=st[yy.min():yy.max()+1,xx.min():xx.max()+1]
P=inflated_points(sm,np.ones((int(sm.shape[1]*0.7),sm.shape[1]),bool),power=0.5); P=fps(P,18)
stone=hull_mesh(P,'Kelp_stone'); s=sm.shape[1]*PX; stone.scale=(s,s,s); stone.location=((xx.min()+sm.shape[1]/2-Wk/2)*PX,0,(Hk-1-yy.max())*PX)
shade_by_normal(stone,STONE)
objs['Kelp']=[kelp,stone]
# ---------------- Starfish: top-view mask inflated into a low dome ----------------
SF=[mat('star_l',(255,138,120)),mat('star',(255,90,78)),mat('star_d',(214,62,56)),mat('star_dot',(255,214,200))]
smk=np.load('plants4_top.npy'); Hs,Ws=smk.shape
s2=np.array(Image.fromarray(smk.astype(np.uint8)*255).resize((80,int(80*Hs/Ws))))>127
dt=ndi.distance_transform_edt(np.pad(s2,1))[1:-1,1:-1]; mx=dt.max()
# contour polygon of the outline, simplified to ~40 points (the star outline)
cs=measure.find_contours(np.pad(s2,1).astype(float),0.5)[0]-1
from skimage.measure import approximate_polygon
poly=approximate_polygon(cs,1.2)[:-1]
S=Ws*PX*0.55/80   # starfish ~ 5.6 studs across
cxs,cys=s2.shape[1]/2,s2.shape[0]/2
ring_o=[((p[1]-cxs)*S,-(p[0]-cys)*S) for p in poly]
V=[(0,0,mx*S*0.55)]
for x,y in ring_o: V.append((x,y,0.0))
# a mid ring along the arm ridges: points halfway to the centre, raised by the distance field
for x,y in ring_o:
    px_,py_=x*0.55,y*0.55
    ix=int(np.clip(px_/S+cxs,0,s2.shape[1]-1)); iy=int(np.clip(-py_/S+cys,0,s2.shape[0]-1))
    V.append((px_,py_,dt[iy,ix]*S*0.55+0.02))
n=len(ring_o); F=[];MI=[]
for i in range(n):
    j=(i+1)%n; o1,o2=1+i,1+j; m1,m2=1+n+i,1+n+j
    F.append([o1,o2,m2,m1]); F.append([m1,m2,0])
star=mesh_from(V,F,'Starfish'); flat(star)
shade_by_normal(star,SF[:3])
# dots: little flat discs on the arms (from the sheet: 4-5 per arm)
dots=[]
for k in range(5):
    a0=math.radians(90+72*k)
    for t in (0.35,0.5,0.65,0.8):
        r=Ws*PX*0.55*0.5*t
        x,y=math.cos(a0)*r,math.sin(a0)*r
        ix=int(np.clip(x/S+cxs,0,s2.shape[1]-1)); iy=int(np.clip(-y/S+cys,0,s2.shape[0]-1))
        bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=0.09*(1.1-t*0.4),depth=0.06,location=(x,y,dt[iy,ix]*S*0.55*0.9+0.03))
        d=bpy.context.object; d.data.materials.append(SF[3]); flat(d); dots.append(d)
objs['Starfish']=[star]+dots
for k,v in objs.items(): print(k,sum(len(x.data.polygons) for x in v),'faces')
bpy.ops.wm.save_as_mainfile(filepath='/home/claude/megabite_art/kit/kit_plants.blend')
