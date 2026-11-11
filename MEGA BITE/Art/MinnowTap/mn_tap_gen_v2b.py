"""MEGA BITE Minnow v4 'Tap style' (11 Nov). Traced from mb_minnow_tapstyle_sheet_v1.png (ChatGPT, style ref = Tap Simulator
REBORN pets). Smooth superellipse loft body (side heights + top widths), colours PROJECTED from the sheet (side/top/front view
picked per texel by the surface normal) and snapped to a 6-colour palette; glossy domed eyes seated on the surface with a drawn
iris/pupil/catch-lights; pillow fins (thickness from the distance to the fin edge); an inverted-hull dark outline like the
reference pets. Same rig as Minnow v1 (Root + Spine0..7 along -X, x0=-0.104, x1=-3.322) so MinnowClips.lua keeps working."""
import numpy as np, json, math, cv2
from PIL import Image
from scipy import ndimage as ndi
from scipy.spatial import Delaunay
SH=np.array(Image.open('sheet.png').convert('RGB')).astype(np.float32)
P=json.load(open('prof.json'))
NOSE,TAILTIP=1028,381
S=3.3936/(NOSE-TAILTIP)   # same length as Minnow v1 (7 studs at SrcScale 0.0206), so the rig is identical
WSC=1.06                     # top view is 11% narrower than the front view: split the difference
TOFF=271                     # top-view x + TOFF = side-view x (noses aligned)
TCEN=P['tcen']; FCX=P['front']['cx']; FCY=P['front']['cy']; FN=2.05   # v2 'less toy': a natural rounded section (2.1 measured)
HS=0.88   # v2 height scale vs the chibi sheet (owner 11 Nov: 'too cartoony and toy')
WY=0.70   # v2 width scale: a real fish is narrower than it is tall (the sheet's bean was round)
side_body=np.load('side_body.npy'); top_body=np.load('top_body.npy'); front_body=np.load('front_body.npy')
Sx={int(k):v for k,v in P['S'].items()}; Tx={int(k):v for k,v in P['T'].items()}
xs=np.arange(497,NOSE+1)
zt=np.array([Sx[x][0] for x in xs],float); zb=np.array([Sx[x][1] for x in xs],float)
tw=np.array([ (Tx[x-TOFF][1]-Tx[x-TOFF][0])/2 if (x-TOFF) in Tx else np.nan for x in xs],float)
tw=np.where(np.isnan(tw),np.nanmin(tw),tw)
g=lambda a:ndi.gaussian_filter1d(a,2.0,mode='nearest')
zt,zb,tw=g(zt),g(zb),g(tw)
imax=np.argmax(zb-zt); BASEZ=(zt[imax]+zb[imax])/2
def X(px): return (px-NOSE)*S
def Z(py): return (BASEZ-py)*S
def PXs(x): return NOSE+x/S
def PYs(z): return BASEZ-z/S
# profile as functions of model x (metres)
XM=X(xs); ZC=Z((zt+zb)/2)
# v2: a real fish narrows to a tail stalk (the chibi sheet ends blunt): taper the rear 45% down to 50% at the cut
def TP(x):
    x=np.asarray(x,float); t=np.clip((x-XM[-1]*0.0-(-1.45))/(XM[0]-(-1.45)),0,1)
    t=np.where(x< -1.45, t, 0.0); return 1-0.5*t*t*(3-2*t)
TPX=TP(XM)
HH=(zb-zt)/2*S*HS*TPX; WW=tw*WSC*S*WY*TPX
# rounded cap behind the cut where the tail fin hides the body end
XEND=XM[0]; CAP=30*S
def prof(x):
    x=np.asarray(x,float)
    xc=np.clip(x,XM[0],XM[-1])
    zc=np.interp(xc,XM,ZC); h=np.interp(xc,XM,HH); w=np.interp(xc,XM,WW)
    f=np.where(x<XEND, np.sqrt(np.clip(1-((XEND-x)/CAP)**2,0,1)), 1.0)
    # nose: the measured columns end at ~0 extent already
    return zc,h*f,w*f
def sp(c,n): return np.sign(c)*np.abs(c)**(2.0/n)
def body_pt(x,th):
    zc,h,w=prof(x)
    return np.stack([np.broadcast_to(x,np.shape(th)) if np.ndim(x)==0 else x, w*sp(np.sin(th),FN), zc+h*sp(np.cos(th),FN)],-1)
X0B,X1B=XEND-CAP*0.999, X(NOSE)+0.0
def u2x(u): return X0B+(X1B-X0B)*u
def v2th(v): return math.pi+2*math.pi*v      # seam on the belly
def inside(p):
    zc,h,w=prof(p[...,0])
    return (np.abs(p[...,1])/np.maximum(w,1e-6))**FN+(np.abs(p[...,2]-zc)/np.maximum(h,1e-6))**FN
# ---------------------------------------------------------------- texture
TEX=1024
A=np.zeros((TEX,TEX,3),np.float32)
PAL=dict(yellow=(255,214,58),stripe=(255,178,40),cream=(255,240,200),blush=(255,160,150),mouth=(70,36,40),dark=(42,34,51))
def bil(img,px,py):
    px=np.clip(px,0,img.shape[1]-1.001); py=np.clip(py,0,img.shape[0]-1.001)
    x0=np.floor(px).astype(int); y0=np.floor(py).astype(int); fx=(px-x0)[...,None]; fy=(py-y0)[...,None]
    return img[y0,x0]*(1-fx)*(1-fy)+img[y0,x0+1]*fx*(1-fy)+img[y0+1,x0]*(1-fx)*fy+img[y0+1,x0+1]*fx*fy
NV=768
U,V=np.meshgrid((np.arange(TEX)+0.5)/TEX,(np.arange(NV)+0.5)/NV)
x=u2x(U); th=v2th(V)
p=body_pt(x,th)
du=1e-3; dv=1e-3
pu=body_pt(u2x(np.clip(U+du,0,1)),th)-body_pt(u2x(np.clip(U-du,0,1)),th)
pv=body_pt(x,th+dv)-body_pt(x,th-dv)
n=np.cross(pu,pv); n/=np.linalg.norm(n,axis=-1,keepdims=True)+1e-9
if (n[...,2]*(p[...,2]-prof(p[...,0])[0])).mean()<0: n=-n
# view choice
wf=np.maximum(n[...,0],0)*1.1; ws=np.abs(n[...,1]); wt=np.maximum(n[...,2],0)*0.95; wb=np.maximum(-n[...,2],0)
view=np.argmax(np.stack([ws,wt,wf,wb],-1),-1)
col=np.zeros(p.shape,np.float32)
# sample the sheet in ITS proportions (the body is slimmer than the drawing)
_zc0=prof(p[...,0])[0]; ps=p.copy(); _tp=TP(np.clip(p[...,0],XM[0],XM[-1])); ps[...,1]=p[...,1]/(WY*_tp); ps[...,2]=_zc0+(p[...,2]-_zc0)/(HS*_tp)
# side
sx=PXs(ps[...,0]); sy=PYs(ps[...,2]); cs=bil(SH,sx,sy)
# top
tx=PXs(ps[...,0])-TOFF; ty=TCEN-ps[...,1]/(S*WSC); ct=bil(SH,tx,ty)
# front (viewer's right = fish's left = +y)
fx=FCX+ps[...,1]/S*1.06; fy=FCY-(ps[...,2]-Z(BASEZ))/S; cf=bil(SH,fx,fy)
src=np.where(view[...,None]==0,cs,np.where(view[...,None]==1,ct,np.where(view[...,None]==2,cf,np.array(PAL['cream'],np.float32))))
R,G,B=src[...,0],src[...,1],src[...,2]; gr=G/np.maximum(R,1); br=B/np.maximum(R,1)
# Colours by RULES (a noisy per-texel projection gave jagged belly lines): yellow base; stripes from the side/top views
# (upper back only, cleaned); cream below the side view's belly line; blush as a soft oval under each eye.
cls=np.full(R.shape,'yellow',object)
Ri,Gi,Bi=SH[...,0],SH[...,1],SH[...,2]
creamS=(Bi/np.maximum(Ri,1)>0.5)&(Gi/np.maximum(Ri,1)>0.78)&(Ri>200)&(Bi<215)&side_body
pectS=np.load('side_fin.npy')&side_body
bl=np.full(len(xs),np.nan)
for k,xx_ in enumerate(xs):
    if pectS[:,xx_].any() or xx_>1000: continue
    r_=np.where(creamS[:,xx_])[0]
    if len(r_)>8: bl[k]=r_.min()
ok_=(~np.isnan(bl))&(xs>515)&(xs<985)
cf_=np.polyfit(xs[ok_],bl[ok_],3)
for _ in range(3):   # robust refit: drop outliers (blush, outline)
    res=np.abs(np.polyval(cf_,xs[ok_])-bl[ok_]); keep=res<np.percentile(res,80)+2
    cf_=np.polyfit(xs[ok_][keep],bl[ok_][keep],3)
bl=np.polyval(cf_,np.clip(xs,515,1000))
belly_z=Z(bl)
zc_=prof(p[...,0])[0]
stripe=(gr>0.665)&(gr<0.785)&(br<0.32)&(R>200)&((view==1)|((view==0)&(ps[...,2]>zc_)))
stripe=ndi.binary_closing(ndi.binary_opening(stripe,iterations=2),iterations=2)
cls[stripe]='stripe'
below=ps[...,2]<np.interp(p[...,0],XM,belly_z)
cls[below]='cream'
import os as _os
_e=json.load(open('out/eye.json')) if _os.path.exists('out/eye.json') else [X(901.5),0,Z(262)]
BX,BZ,BRX,BRZ=_e[0]-49*S,_e[2]-76*S,27*S,16*S     # the sheet's blush sits 49 px behind and 76 px below the eye centre
blush=(((p[...,0]-BX)/BRX)**2+((p[...,2]-BZ)/BRZ)**2<1)&(np.abs(n[...,1])>0.35)
# v2: no blush (too toy)
np.save('out/cls.npy',np.stack([(cls==k) for k in PAL]).astype(np.uint8)); json.dump(list(PAL),open('out/cls_keys.json','w'))
for k,v in PAL.items(): A_k=(cls==k); col[A_k]=v
# 2x2 majority clean-up then a soft 1 px blend
stripeM=(cls=='stripe'); col[stripeM]=col[stripeM]*0.55+np.array(PAL['yellow'],np.float32)*0.45   # v2: softer stripes
# darker, warmer back -> bright flank (countershading)
hgt=np.clip((p[...,2]-_zc0)/np.maximum(prof(p[...,0])[1],1e-6),-1,1)
back=np.clip(hgt,0,1)[...,None]**1.3
col=col*(1-0.22*back)+np.array((205,120,20),np.float32)*0.22*back
# scales: offset rows of small arcs, darker on their tail-side rim, fading out on the head and belly
cs_=16.0; uu=np.arange(TEX)[None,:].repeat(NV,0).astype(np.float32); vv=np.arange(NV)[:,None].repeat(TEX,1).astype(np.float32)
row=np.floor(vv/cs_); off=(row%2)*cs_/2
fu=((uu+off)%cs_)/cs_-0.5; fv=(vv%cs_)/cs_-0.5
dd=np.hypot(fu*1.0,fv*1.0)
arc=np.clip(1-np.abs(dd-0.42)/0.09,0,1)*(fu<0.05)
fade=np.clip((0.80-U)/0.12,0,1)*np.clip(1-(cls=='cream')*0.7,0,1)
col=col*(1-0.13*(arc*fade)[...,None])
body_img=cv2.GaussianBlur(col,(0,0),0.8)
A[TEX-NV:,:,:]=body_img[::-1]                        # body: uv v 0..0.75 -> image rows 1023..256
np.save('out/view.npy',view.astype(np.uint8))
# eye (rows 0..255, cols 0..255): navy rim, blue iris (dark top -> light bottom), pupil, 2 catch-lights
E=256; yy,xx=np.mgrid[0:E,0:E]; cx=cy=(E-1)/2; r=np.hypot(xx-cx,yy-cy)/(E/2)
ey=np.zeros((E,E,3),np.float32)+PAL['dark']
# v2b (owner 11 Nov 14:38 'the eyes should be cute'): the glossy cute eye again on the less-toy body
irisT=np.array((25,95,205),np.float32); irisB=np.array((120,215,255),np.float32)
t=np.clip((yy/E-0.12)/0.8,0,1)[...,None]; iris=irisT*(1-t)+irisB*t
ey=np.where((r<0.88)[...,None],iris,ey)
ring=(r<0.88)&(r>0.76); ey=np.where(ring[...,None],ey*0.82,ey)
pr=np.hypot(xx-cx,yy-(cy+E*0.03))/(E/2); ey=np.where((pr<0.5)[...,None],np.array((22,26,52),np.float32),ey)
for (ax,ay,ar) in [(0.28,-0.30,0.24),(-0.28,0.30,0.10)]:   # +x toward the nose, -y up
    cr=np.hypot(xx-(cx+ax*E/2),yy-(cy+ay*E/2))/(E/2); ey=np.where((cr<ar)[...,None],np.array((255,255,255),np.float32),ey)
ey=cv2.GaussianBlur(ey,(0,0),0.8)
A[0:E,0:E]=ey
# fin gradient strip (cols 256..511): edge darker -> root/centre lighter
s=np.linspace(0,1,256); fin=np.array((255,196,96))[None]*(1-s[:,None])+np.array((232,118,20))[None]*s[:,None]   # v2: lighter thin edge -> deeper orange root
A[0:E,256:512]=fin[None,:,:]
A[0:64,512:576]=PAL['dark']
Image.fromarray(np.clip(A,0,255).astype(np.uint8)).save('out/MB_Minnow_tap_tex.png')
# ---------------------------------------------------------------- geometry (verts in metres, Blender axes X fwd, Y left, Z up)
V_=[];F_=[];UV_=[];K_=[]   # K: part key per face
def addv(p): V_.append(tuple(map(float,p))); return len(V_)-1
NR,NA=46,40
us=np.concatenate([[0.0],(1-np.cos(np.linspace(0,math.pi,NR)))/2])   # dense at both ends
us=np.unique(np.clip(us,0.004,0.998))
ring_idx=[]
for u in us:
    row=[]
    for j in range(NA):
        v=j/NA; row.append(addv(body_pt(np.array(u2x(u)),np.array(v2th(v)))))
    ring_idx.append(row)
tailpole=addv((u2x(0.0),0,prof(u2x(0.0))[0])); nosepole=addv((X1B+0.004,0,float(prof(X1B-0.002)[0])))
def uvb(u,v): return (u,0.003+0.744*v)   # padded: bilinear filtering must not bleed in the eye/fin tiles at the seam
for i in range(len(us)-1):
    for j in range(NA):
        a,b=ring_idx[i][j],ring_idx[i][(j+1)%NA]; c,d=ring_idx[i+1][(j+1)%NA],ring_idx[i+1][j]
        v0,v1=j/NA,(j+1)/NA
        F_.append((a,b,c,d)); UV_.append([uvb(us[i],v0),uvb(us[i],v1),uvb(us[i+1],v1),uvb(us[i+1],v0)]); K_.append('body')
for j in range(NA):
    a,b=ring_idx[0][j],ring_idx[0][(j+1)%NA]
    F_.append((tailpole,b,a)); UV_.append([uvb(0.0,(j+.5)/NA),uvb(us[0],(j+1)/NA),uvb(us[0],j/NA)]); K_.append('body')
    a,b=ring_idx[-1][j],ring_idx[-1][(j+1)%NA]
    F_.append((a,b,nosepole)); UV_.append([uvb(us[-1],j/NA),uvb(us[-1],(j+1)/NA),uvb(1.0,(j+.5)/NA)]); K_.append('body')
# ---------------- eyes: side centre (901.5,262) r~62; front eyes at +-104 px, 11.8 px above the front centre
def surf_along(p0,d,lo=-0.05,hi=1.2):   # body surface from p0 along d (bisection on the superellipse function)
    for _ in range(40):
        m=(lo+hi)/2; f=inside(np.array(p0)+d*m)
        if f<1: lo=m
        else: hi=m
    return np.array(p0)+d*(lo+hi)/2
def body_normal(q):
    e=1e-3; gx=[(inside(q+np.eye(3)[k]*e)-inside(q-np.eye(3)[k]*e)) for k in range(3)]
    g=np.array(gx); return g/np.linalg.norm(g)
ex_side=X(901.5); ez=(Z(262.2)+ (Z(BASEZ)+11.8*S))/2
_zce=float(prof(np.array(ex_side))[0]); ez=_zce+(ez-_zce)*HS
ey_front=104*S/1.06
# x where (y=ey_front, z=ez) meets the front of the body
lo,hi=X(800),X(NOSE)
for _ in range(40):
    m=(lo+hi)/2
    if inside(np.array([m,ey_front,ez]))<1: lo=m
    else: hi=m
ex_front=lo
EX=ex_side*0.95+ex_front*0.05
EDIR=math.radians(16)   # eyes look a little forward (the sheet's front view has them close together)
print('eye x side',ex_side,'front',ex_front,'->',EX)
ER=54*S   # v2b: big cute eye (sheet 62 px; v2 natural 42)
for sgn in (1,-1):
    q=surf_along(np.array([EX-0.15,0,ez]),np.array([math.sin(EDIR),sgn*math.cos(EDIR),0.0]))
    q[1]=sgn*abs(q[1])
    print('eye centre',q)
    json.dump(list(map(float,q)),open('out/eye.json','w'))
    nn=body_normal(q); fwd=np.array([1,0,0.0]); fwd=fwd-nn*fwd.dot(nn); fwd/=np.linalg.norm(fwd)
    up=np.cross(nn,fwd)*sgn; up=up if up[2]>0 else -up
    NRI,NS=7,28; base=[]
    def ept(rho,a):
        o=q+(fwd*math.cos(a)*1.0+up*math.sin(a)*1.06)*ER*rho
        s=surf_along(o,nn,-0.4,0.4)
        return s+nn*(0.004+ER*0.14*(1-rho*rho))
    cidx=addv(ept(0,0)); rings=[]
    for k in range(1,NRI+1):
        rho=k/NRI; rings.append([addv(ept(rho,2*math.pi*a/NS)) for a in range(NS)])
    def euv(rho,a): return ((0.5+0.5*rho*math.cos(a))*0.25, 1-(0.5-0.5*rho*math.sin(a)*1.0)*0.25)
    for a in range(NS):
        a0,a1=2*math.pi*a/NS,2*math.pi*(a+1)/NS
        tri=(cidx,rings[0][a],rings[0][(a+1)%NS]) if sgn>0 else (cidx,rings[0][(a+1)%NS],rings[0][a])
        uvs=[euv(0,0),euv(1/NRI,a0),euv(1/NRI,a1)] if sgn>0 else [euv(0,0),euv(1/NRI,a1),euv(1/NRI,a0)]
        F_.append(tri); UV_.append(uvs); K_.append('eye')
        for k in range(NRI-1):
            r0,r1=(k+1)/NRI,(k+2)/NRI
            qd=(rings[k][a],rings[k+1][a],rings[k+1][(a+1)%NS],rings[k][(a+1)%NS])
            uq=[euv(r0,a0),euv(r1,a0),euv(r1,a1),euv(r0,a1)]
            if sgn<0: qd=qd[::-1]; uq=uq[::-1]
            F_.append(qd); UV_.append(uq); K_.append('eye')
    # skirt: the rim folds back into the body so no gap shows at grazing angles
    skirt=[addv(np.array(V_[i])-nn*0.022) for i in rings[-1]]
    for a in range(NS):
        qd=(rings[-1][a],skirt[a],skirt[(a+1)%NS],rings[-1][(a+1)%NS])
        if sgn<0: qd=qd[::-1]
        F_.append(qd); UV_.append([euv(1,0)]*4); K_.append('eye')
# ---------------- mouth: the sheet's front-view smile as a small dark tube on the face
mp=[]
for t in np.linspace(-1,1,13):
    px=1171.5+t*19; py=806-7*(t*t)      # front view: corners (1142,790) .. bottom (1171,812)
    y=(px-FCX)*S/1.06*WY; z=Z(BASEZ)+(FCY-py)*S; _zm=float(prof(np.array(X(1020)))[0]); z=_zm+(z-_zm)*HS
    mp.append(surf_along(np.array([-0.6,y,z]),np.array([1.0,0,0]),0.0,1.2))
mp=np.array(mp); MR=0.011; rings=[]
for k,c in enumerate(mp):
    tg=mp[min(k+1,len(mp)-1)]-mp[max(k-1,0)]; tg/=np.linalg.norm(tg)
    a=np.array([1.0,0,0]); a=a-tg*a.dot(tg); a/=np.linalg.norm(a); b=np.cross(tg,a)
    rings.append([addv(c+(a*math.cos(2*math.pi*j/6)+b*math.sin(2*math.pi*j/6))*MR) for j in range(6)])
for k in range(len(rings)-1):
    for j in range(6):
        F_.append((rings[k][j],rings[k][(j+1)%6],rings[k+1][(j+1)%6],rings[k+1][j])); UV_.append([(0.53,0.97)]*4); K_.append('eye')
for rr,flip in ((rings[0],True),(rings[-1],False)):
    f=tuple(rr[::-1]) if flip else tuple(rr); F_.append(f); UV_.append([(0.53,0.97)]*6); K_.append('eye')
# ---------------- fins (pillow plates traced from the side view)
side_all=np.load('side_all.npy'); side_fin=np.load('side_fin.npy')
finm=ndi.binary_opening(side_fin,iterations=2)
lab,nf=ndi.label(finm); sizes=ndi.sum(finm,lab,range(1,nf+1))
fins={}
for i in np.argsort(-sizes)[:4]:
    ys_,xs_=np.where(lab==i+1); cx_,cy_=xs_.mean(),ys_.mean()
    name='tail' if cx_<520 else ('dorsal' if cy_<150 else ('anal' if cy_>380 else 'pect'))
    m=lab==i+1
    if name!='pect': m=m|(ndi.binary_dilation(m,iterations=22)&side_body)      # push the root into the body
    m=ndi.binary_fill_holes(ndi.binary_closing(m,iterations=2))
    fins[name]=m
print('fins',{k:int(v.sum()) for k,v in fins.items()})
FINT=dict(tail=8,dorsal=7,anal=6.5,pect=6)   # v2: thinner, less puffy fins
def pillow(name,mask,place):
    dt=ndi.distance_transform_edt(mask); dmax=dt.max()
    cs_,_=cv2.findContours(mask.astype(np.uint8),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    c=max(cs_,key=len)[:,0,:].astype(float)
    # smooth the traced edge (pixel stair-steps read as a torn rim with the outline)
    c=np.stack([ndi.gaussian_filter1d(c[:,0],7,mode='wrap'),ndi.gaussian_filter1d(c[:,1],7,mode='wrap')],1)
    step=7.0; pts=[c[0]]; acc=0
    for k in range(1,len(c)):
        acc+=np.hypot(*(c[k]-c[k-1]))
        if acc>=step: pts.append(c[k]); acc=0
    edge=np.array(pts)
    gy,gx=np.mgrid[0:mask.shape[0]:11,0:mask.shape[1]:11]
    inner=np.stack([gx.ravel(),gy.ravel()],1).astype(float)
    inner=inner[dt[inner[:,1].astype(int),inner[:,0].astype(int)]>5]
    allp=np.concatenate([edge,inner]); ne=len(edge)
    tri=Delaunay(allp)
    keep=[t for t in tri.simplices if mask[int(allp[t,1].mean()),int(allp[t,0].mean())]]
    dd=np.array([0.0]*ne+[dt[int(y),int(x)] for x,y in inner])
    ht=FINT[name]*(dd/dmax)**0.55*S
    tt=np.clip(dd/dmax,0,1)
    for sgn_side in ([1,-1] if name=='pect' else [0]):
        top=[];bot=[]
        for k,(px,py) in enumerate(allp):
            for arr,s in ((top,1),(bot,-1)):
                arr.append(addv(place(X(px),Z(py),s*ht[k],sgn_side)))
        for t in keep:
            a,b,c_=t
            for arr,flip in ((top,False),(bot,True)):
                tri_=(arr[a],arr[b],arr[c_])
                uv=[(0.25+0.25*tt[a],0.875),(0.25+0.25*tt[b],0.875),(0.25+0.25*tt[c_],0.875)]
                if flip: tri_=tri_[::-1]; uv=uv[::-1]
                F_.append(tri_); UV_.append(uv); K_.append('fin')
        # weld the rim: top and bottom edge verts are the same point -> merge later by distance
    return
for name in ('tail','dorsal','anal'):
    # v2: the body is lower than the sheet's: slide each fin so its root still meets the body (shape kept)
    def place_v(x,z,o,s,_n=name):
        zc,h,w=prof(np.array(x)); zc=float(zc); h=float(h)
        hs=h/(HS*float(TP(np.clip(x,XM[0],XM[-1]))))
        if _n=='dorsal': dz=(zc+h)-(zc+hs)
        elif _n=='anal': dz=(zc-h)-(zc-hs)
        else: dz=(z-zc)*(HS-1)            # tail: squeeze toward the centre line with the body
        return (x,o,z+dz)
    pillow(name,fins[name],place_v)
# pectoral: drawn on the flank; hinge at its front/top edge, splayed out from the body
pm=fins['pect']; ys_,xs_=np.where(pm); hx,hz=X(xs_.max()-6),Z(ys_.min()+10)
SPLAY=math.radians(55)
def place_pect(x,z,o,s):
    zc,h,w=prof(np.array(hx))
    z=float(zc)+(z-float(zc))*HS; hz2=float(zc)+(hz-float(zc))*HS
    # local: along x stays, the fin plane rotates about the X axis through the hinge
    dz=z-hz2; dy=o
    a=SPLAY
    y=float(w)*0.86+dy*math.cos(a)-dz*math.sin(a)*(-1)
    zz=hz2+dz*math.cos(a)+dy*math.sin(a)
    y=float(w)*0.86+ (-dz)*math.sin(a)+dy*math.cos(a)
    return (x,s*y,zz)
pillow('pect',pm,place_pect)
json.dump(dict(x=list(map(float,XM)),zc=list(map(float,ZC))),open('out/axis.json','w'))
json.dump(dict(V=V_,F=F_,UV=UV_,K=K_,S=S,EX=EX),open('out/minnow_tap_geo.json','w'))
print('verts',len(V_),'faces',len(F_))
