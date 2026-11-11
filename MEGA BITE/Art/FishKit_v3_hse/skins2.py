"""Designed skins for the HSE fish-kit models (12 Nov): not a colour swap. Each skin = its own palette per body zone
(back / belly, luminance-preserving so the sheet's shading, gills and brow stay) + its own PATTERN painted in texture
space (spots, photophores, ribs, lava cracks) + its own eye, fin strip, fin tips and edge-line colour.
usage: skins2.py <dir> [NV NJ]   (reads <dir>/cfg.py for the eye/lid/mouth colours)"""
import numpy as np, sys, json, cv2
from PIL import Image
from scipy import ndimage as ndi
from scipy.spatial import cKDTree
D=sys.argv[1]; NV=int(sys.argv[2]) if len(sys.argv)>2 else 640; NJ=int(sys.argv[3]) if len(sys.argv)>3 else 128
exec(open(D+'/cfg.py').read())
A=np.array(Image.open(D+'/out/tex.png').convert('RGB')).astype(np.float32); TEX=1024; R0=TEX-NV; J0=R0-NJ; E=min(256,J0)
cl=np.load(D+'/out/cls.npy')[::-1]                      # body classes in atlas row order (0 back, 1 belly, 2 mouth)
wb=cv2.GaussianBlur((cl==list(C['palette']).index(C['belly_class'])).astype(np.float32),(0,0),1.6)[...,None]   # belly weight
MC=np.array(C['mouth_col'],np.float32)
import os
MT=json.load(open(D+'/out/meta.json')) if os.path.exists(D+'/out/meta.json') else dict(sx=1.08,sy=0.5)
SX,SY=MT['sx'],MT['sy']      # texture px -> sheet px (so spots stay round on a tall fish)
rng=np.random.default_rng(7)
rr,cc=np.mgrid[0:NV,0:TEX]; U=cc/TEX; V=rr/NV; MX=cc*SX; MY=rr*SY       # metric ~ sheet pixels
def lum(px): return (0.299*px[...,0]+0.587*px[...,1]+0.114*px[...,2])/255.0
def ramp(px,stops,mask=None):
    L=lum(px); m=np.ones(L.shape,bool) if mask is None else mask
    lo,hi=np.percentile(L[m],3),np.percentile(L[m],97); t=np.clip((L-lo)/max(hi-lo,1e-3),0,1)[...,None]
    r=[np.array(c,np.float32) for c in stops]
    return np.where(t<0.5,r[0]*(1-t*2)+r[1]*(t*2),r[1]*(1-(t-0.5)*2)+r[2]*((t-0.5)*2))
def over(base,col,a): return base*(1-a[...,None])+np.array(col,np.float32)*a[...,None]
def orb(top_,bot_,lid_col,socket=(14,30,58)):
    yy,xx=np.mgrid[0:E,0:E]; cx=cy=(E-1)/2; r=np.hypot(xx-cx,yy-cy)/(E/2); OR_=C.get('orb_r',0.84)
    if C.get('sclera'):   # cartoon eye (white ball, coloured iris, pupil, glints): the skin colours the iris and the lid
        ey=np.zeros((E,E,3),np.float32)+np.array((42,34,51),np.float32); ey=np.where((r<0.9)[...,None],np.array((246,246,246),np.float32),ey); ir=0.62
        t=np.clip((yy/E-0.12)/0.8,0,1)[...,None]; iris=np.array(top_,np.float32)*(1-t)+np.array(bot_,np.float32)*t
        LF=C.get('look_fwd',0.0)*E/2; ri=np.hypot(xx-(cx+LF),yy-cy)/(E/2)
        ey=np.where(((ri<ir)&(r<0.9))[...,None],iris,ey); ey=np.where(((ri<ir)&(ri>ir-0.12)&(r<0.9))[...,None],ey*0.82,ey)
        pr=np.hypot(xx-(cx+LF*1.15),yy-(cy+E*0.03))/(E/2); ey=np.where(((pr<ir*0.56)&(r<0.9))[...,None],np.array((22,26,52),np.float32),ey)
        for (ax,ay,ar) in [(0.28*ir/0.88,-0.30*ir/0.88,0.24*ir/0.88),(-0.28*ir/0.88,0.30*ir/0.88,0.10*ir/0.88)]:
            crr=np.hypot(xx-(cx+LF+ax*E/2),yy-(cy+ay*E/2))/(E/2); ey=np.where(((crr<ar)&(r<0.9))[...,None],np.array((255,255,255),np.float32),ey)
        if C.get('lid'):
            tp,fr=C['lid']; u=(xx-cx)/(E/2); edge=cy+(tp+(fr-tp)*(u+1)/2)*E/2
            ey=np.where(((yy<edge)&(r<1.0))[...,None],np.array(lid_col,np.float32),ey)
            ey=np.where(((yy>=edge)&(yy<edge+E*0.035)&(r<0.93))[...,None],np.array((15,15,25),np.float32),ey)
        return cv2.GaussianBlur(ey,(0,0),0.8)
    ey=np.zeros((E,E,3),np.float32)+np.array(socket,np.float32)
    ci=np.array(bot_,np.float32); co=np.array(top_,np.float32); t=np.clip(r/OR_,0,1)[...,None]; o=ci*(1-t**2.2)+co*t**2.2
    hr=np.hypot(xx-(cx+0.10*E/2),yy-(cy-0.14*E/2))/(E/2); k_=np.clip(1-hr/0.42,0,1)[...,None]**1.5
    o=o*(1-k_)+255*k_; ey=np.where((r<OR_)[...,None],o,ey)
    if C.get('lid'):
        tp,fr=C['lid']; u=(xx-cx)/(E/2); edge=cy+(tp+(fr-tp)*(u+1)/2)*E/2
        ey=np.where(((yy<edge)&(r<1.0))[...,None],np.array(lid_col,np.float32),ey)
        ey=np.where(((yy>=edge)&(yy<edge+E*0.035)&(r<0.93))[...,None],np.array((15,15,25),np.float32),ey)
    return cv2.GaussianBlur(ey,(0,0),0.8)
def finstrip(edge,root,tip,g=1.0):
    s=np.linspace(0,1,256)**g; g=(np.array(edge,np.float32)[None]*(1-s[:,None])+np.array(root,np.float32)[None]*s[:,None])[None,:,:].repeat(E,0)
    kk=np.clip((np.arange(E)/E-0.5)/0.45,0,1)[:,None,None]; return g*(1-kk)+np.array(tip,np.float32)*kk
body=A[R0:]; jaw=A[J0:R0]
mouth_b=np.linalg.norm(body-MC,axis=-1)<34; mouth_j=np.linalg.norm(jaw-MC,axis=-1)<34
backm=(cl==0)&~mouth_b; bellym=(cl==1)&~mouth_b
def recolour(back_stops,belly_stops,mouth=None):
    b=ramp(body,back_stops,backm)*(1-wb)+ramp(body,belly_stops,bellym)*wb
    j=ramp(jaw,belly_stops,~mouth_j)
    mc=MC if mouth is None else np.array(mouth,np.float32)
    b[mouth_b]=mc; j[mouth_j]=mc
    return b,j
def spots(n,rmin,rmax,vmax,umax,seed):
    r_=np.random.default_rng(seed); a=np.zeros((NV,TEX),np.float32); ring=np.zeros((NV,TEX),np.float32); pts=[]
    tries=0
    while len(pts)<n and tries<n*40:
        tries+=1; u,v,rad=r_.uniform(0.03,umax),r_.uniform(0.03,vmax)**1.0,r_.uniform(rmin,rmax)
        x,y=u*TEX*SX,v*NV*SY
        if any(np.hypot(x-px,y-py)<rad+pr+5 for px,py,pr in pts): continue
        pts.append((x,y,rad))
    for x,y,rad in pts:
        d=np.hypot(MX-x,MY-y)
        a=np.maximum(a,np.clip((rad-d)/2.0,0,1)); ring=np.maximum(ring,np.clip(1-np.abs(d-rad-1.5)/2.5,0,1))
    return a,ring
SK={}
# ---- CORAL: warm coral back, cream belly, pale reef spots with a rose ring, turquoise fins, tips and eye
b,j=recolour([(120,28,58),(250,104,112),(255,196,170)],[(214,150,140),(255,236,222),(255,252,246)])
a,ring=spots(120,5,12,0.52,0.80,3); bk=(1-wb[...,0])
b=over(b,(170,40,70),ring*bk*0.75); b=over(b,(255,236,214),a*bk*0.92)
SK['Coral']=dict(body=b,jaw=j,eye=orb((0,170,165),(120,255,232),(150,40,66)),fin=finstrip((235,92,104),(255,150,140),(20,176,170)),line=(96,24,52),finramp=[(16,150,150),(236,96,108),(255,190,176)])
# ---- LANTERN: deep-sea navy, rows of glowing photophores, glowing fin rims, yellow lantern eye
b,j=recolour([(6,9,24),(20,32,70),(58,92,150)],[(14,26,52),(36,70,108),(92,152,178)])
glow=np.zeros((NV,TEX),np.float32); core=np.zeros((NV,TEX),np.float32)
for (v0,step,rad,u0,u1,ph) in ((0.50,30,4.6,0.05,0.80,0),(0.70,24,3.2,0.08,0.74,12),(0.30,44,3.0,0.12,0.62,20)):
    for x in np.arange(u0*TEX*SX+ph,u1*TEX*SX,step):
        y=(v0+0.035*np.sin(x/90.0))*NV*SY; d=np.hypot(MX-x,MY-y)
        core=np.maximum(core,np.clip((rad-d)/1.6,0,1)); glow=np.maximum(glow,np.clip(1-d/(rad*3.2),0,1)**1.6)
b=over(b,(80,220,140),glow*0.7); b=over(b,(240,255,170),core)
SK['Lantern']=dict(body=b,jaw=j,eye=orb((240,160,10),(255,248,150),(10,16,40),socket=(4,6,16)),fin=finstrip((225,255,150),(14,24,56),(8,12,30),0.2),line=(3,5,14),finramp=[(6,10,26),(22,40,84),(214,250,150)])
# ---- GHOST: spectral white-blue, a faint glowing spine and ribs showing through, icy fins (in game it is also see-through)
b,j=recolour([(96,128,186),(206,226,248),(255,255,255)],[(176,206,238),(236,246,255),(255,255,255)],mouth=(104,120,180))
rib=np.zeros((NV,TEX),np.float32)
spine_y=(0.30+0.02*np.sin(MX/160.0))*NV*SY
rib=np.maximum(rib,np.clip(1-np.abs(MY-spine_y)/2.2,0,1)*((U>0.06)&(U<0.84)))
for x in np.arange(0.30*TEX*SX,0.78*TEX*SX,26):
    ln=1-((x/(TEX*SX)-0.30)/0.48-0.5)**2*2.2                      # longest ribs mid-body
    yy_=MY-spine_y; curve=x-0.10*yy_-0.0016*yy_**2*8
    m=np.clip(1-np.abs(MX-curve)/2.0,0,1)*(yy_>0)*(yy_<ln*NV*SY*0.44)
    rib=np.maximum(rib,m*np.clip(1-yy_/(ln*NV*SY*0.44),0,1)**0.4)
for x in np.arange(0.07*TEX*SX,0.84*TEX*SX,13):                 # vertebrae
    rib=np.maximum(rib,np.clip(1-np.hypot(MX-x,(MY-spine_y)*1.0)/3.6,0,1))
rib=cv2.GaussianBlur(rib,(0,0),0.7)
b=over(b,(150,214,255),cv2.GaussianBlur(rib,(0,0),4)*0.55); b=over(b,(70,150,225),rib*0.8)
SK['Ghost']=dict(body=b,jaw=j,eye=orb((120,200,255),(255,255,255),(150,180,225),socket=(60,96,150)),fin=finstrip((246,252,255),(170,208,244),(110,190,246)),line=(104,134,182),mouth=(104,120,180),finramp=[(96,170,236),(196,224,250),(255,255,255)])
# ---- EMBER: charcoal rock with glowing lava cracks, embers under the belly, molten fin rims and eye
b,j=recolour([(10,8,10),(46,34,34),(104,78,66)],[(34,12,8),(104,34,16),(204,96,34)],mouth=(214,84,20))
NP_=int(np.clip(230*(SX*SY)/(1.08*0.5)*0.8,110,300)); pts=np.stack([rng.uniform(0,TEX*SX,NP_),rng.uniform(0,NV*SY,NP_)],1)
dd,_=cKDTree(pts).query(np.stack([MX.ravel(),MY.ravel()],1),k=2); f=(dd[:,1]-dd[:,0]).reshape(NV,TEX)
fade=np.clip((0.90-U)/0.10,0,1)                                      # keep the face clean
b=over(b,(255,96,10),np.clip(1-f/9.0,0,1)**1.5*0.8*fade); b=over(b,(255,150,30),np.clip(1-f/4.2,0,1)*fade); b=over(b,(255,236,150),np.clip(1-f/1.6,0,1)*fade)
SK['Ember']=dict(body=b,jaw=j,eye=orb((255,92,6),(255,238,130),(26,16,16),socket=(8,4,4)),fin=finstrip((255,150,30),(30,20,20),(255,176,44),0.15),line=(14,7,7),mouth=(214,84,20),finramp=[(24,14,14),(92,40,22),(255,170,50)])
import os
FR=json.load(open(D+'/out/fin_atlas.json')) if os.path.exists(D+'/out/fin_atlas.json') else []
out={}
for name,s in SK.items():
    B=A.copy(); B[R0:]=s['body']; B[J0:R0]=s['jaw']; B[0:E,0:E]=s['eye']; B[0:E,256:512]=s['fin']; B[0:64,512:576]=s['line']
    for (fx,fy,fw,fh) in FR:   # the fins' own pieces of the sheet: dark parts (tips, shadows) -> the skin's tip colour, mid -> fin colour, light rays -> highlight
        B[fy:fy+fh,fx:fx+fw]=ramp(A[fy:fy+fh,fx:fx+fw],s['finramp'])
    if s.get('mouth'): B[0:64,640:704]=s['mouth']
    Image.fromarray(np.clip(B,0,255).astype(np.uint8)).save(f'{D}/out/skin_{name}.png'); out[name]=f'{D}/out/skin_{name}.png'
print(json.dumps(out))
