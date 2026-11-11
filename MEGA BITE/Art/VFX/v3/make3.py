# MEGA BITE bite VFX v3: matched to the Gabriel Aguiar reference (bullet teeth, hot core, white flash, star rays, needle sparks)
import numpy as np
from PIL import Image, ImageFilter
S=4  # supersample
def sdf_tooth(X,Y,cx,base,L,W,dirn):
    # bullet tooth: round cap at the gum (radius W/2), straight-ish body, then a pointy tip.
    # local coords: u across, v along length from gum (0) to tip (L)
    u=(X-cx); v=(Y-base)*dirn
    r=W/2
    # width profile w(v): cap 0..r, body r..0.55L full width, taper to 0 at L (slight concave)
    w=np.where(v<r, np.sqrt(np.clip(r*r-(r-v)**2,0,None)),
       np.where(v<0.5*L, r, r*np.clip(1-(v-0.5*L)/(0.5*L),0,1)**0.85))
    inside=(v>=0)&(v<=L)&(np.abs(u)<=w)
    # normalised distance to edge for shading (0 centre .. 1 edge)
    e=np.where(w>0,np.abs(u)/np.maximum(w,1e-6),1)
    t=np.clip(v/L,0,1)
    return inside,e,t
def teeth(top,shift,size=1024,tint=((255,246,190),(255,150,45))):
    N=size*S
    Y,X=np.mgrid[0:N,0:N].astype(np.float32)
    # 9 teeth: fang at each end, spacing tight like the reference
    xs=np.linspace(300,724,9)+shift
    base=(430 if top else 594)
    dirn=1 if top else -1
    ins=np.zeros((N,N),bool); E=np.ones((N,N),np.float32); T=np.zeros((N,N),np.float32)
    for i,x in enumerate(xs):
        fang=i in (0,8)
        L=(150 if fang else 104)*(1.0 if top else 0.82)
        W=(50 if fang else 44)
        I,e,t=sdf_tooth(X,Y,x*S,base*S,L*S,W*S,dirn)
        ins|=I; E=np.where(I,np.minimum(E,e),E); T=np.where(I,t,T)
    core=np.array(tint[0],np.float32)/255; edge=np.array(tint[1],np.float32)/255
    # hot core in the middle of each tooth, orange towards the edges and the tip
    k=np.clip(E**1.6+0.45*T**1.5,0,1)[...,None]
    col=core*(1-k)+edge*k
    a=ins.astype(np.float32)
    big_pm=(col*a[...,None]*255).astype(np.uint8); big_a=(a*255).astype(np.uint8)
    pm=np.array(Image.fromarray(big_pm).resize((size,size),Image.LANCZOS)).astype(np.float32)
    al=np.array(Image.fromarray(big_a).resize((size,size),Image.LANCZOS)).astype(np.float32)
    # tight orange halo (keeps the shape crisp)
    g1=np.array(Image.fromarray(al.astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))).astype(np.float32)*0.75
    g2=np.array(Image.fromarray(al.astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))).astype(np.float32)*0.35
    A=np.maximum(al,np.maximum(g1,g2))
    rgb=np.where(al[...,None]>1,pm/np.maximum(al[...,None]/255,1e-3),0)
    w=(al/np.maximum(A,1))[...,None]
    rgb=rgb*w+edge*255*(1-w)
    return np.dstack([np.clip(rgb,0,255),A]).astype(np.uint8)
def rays(size=1024,n=5,seed=3,tint=((255,250,235),(255,140,60))):
    rng=np.random.default_rng(seed)
    N=size*S; Y,X=np.mgrid[0:N,0:N].astype(np.float32); c=N/2
    ang=np.arctan2(Y-c,X-c); r=np.hypot(X-c,Y-c)/(N/2)
    A=np.zeros((N,N),np.float32)
    angs=[0.35, 1.25, 2.55, 3.6, 4.9][:n]
    lens=[1.0,0.62,0.9,0.55,0.8]
    for a0,L in zip(angs,lens):
        d=np.angle(np.exp(1j*(ang-a0)))
        width=0.10*(1-np.clip(r/L,0,1))  # tapered ray
        A=np.maximum(A,np.where((np.abs(d)<width)&(r<L),1.0,0.0))
    a=np.array(Image.fromarray((A*255).astype(np.uint8)).resize((size,size),Image.LANCZOS)).astype(np.float32)
    g=np.array(Image.fromarray(a.astype(np.uint8)).filter(ImageFilter.GaussianBlur(10))).astype(np.float32)*0.6
    yy,xx=np.mgrid[0:size,0:size]; rr=np.hypot(xx-size/2,yy-size/2)/(size/2)
    core=np.clip(1-rr/0.22,0,1)**1.5*255
    AA=np.maximum(np.maximum(a,g),core)
    c0=np.array(tint[0],np.float32); c1=np.array(tint[1],np.float32)
    t=np.clip(rr/0.6,0,1)[...,None]
    rgb=c0*(1-t)+c1*t
    return np.dstack([rgb,AA]).astype(np.uint8)
def flash(size=512,tint=((255,255,255),(255,200,140))):
    yy,xx=np.mgrid[0:size,0:size]
    # rounded-rectangle white blowout like the reference (wide)
    dx=np.abs(xx-size/2)/(size*0.40); dy=np.abs(yy-size/2)/(size*0.24)
    d=(dx**4+dy**4)**0.25
    A=np.clip(1.25-d,0,1)**1.2*255
    c0=np.array(tint[0],np.float32); c1=np.array(tint[1],np.float32)
    t=np.clip(d,0,1)[...,None]
    rgb=c0*(1-t)+c1*t
    return np.dstack([rgb,A]).astype(np.uint8)
def needle(size=256,tint=((255,255,240),(255,150,60))):
    N=size*S; Y,X=np.mgrid[0:N,0:N].astype(np.float32); c=N/2
    u=np.abs(X-c)/(N*0.07); v=np.abs(Y-c)/(N*0.48)
    d=u+v  # diamond
    a=np.where(d<1,1.0,0.0)
    al=np.array(Image.fromarray((a*255).astype(np.uint8)).resize((size,size),Image.LANCZOS)).astype(np.float32)
    g=np.array(Image.fromarray(al.astype(np.uint8)).filter(ImageFilter.GaussianBlur(4))).astype(np.float32)*0.6
    A=np.maximum(al,g)
    yy,xx=np.mgrid[0:size,0:size]
    dd=np.abs(xx-size/2)/(size*0.07)+np.abs(yy-size/2)/(size*0.48)
    t=np.clip(dd,0,1)[...,None]
    rgb=np.array(tint[0],np.float32)*(1-t)+np.array(tint[1],np.float32)*t
    return np.dstack([rgb,A]).astype(np.uint8)
def spiky(size=1024,pts=16,seed=5,tint=((255,220,150),(255,120,40))):
    rng=np.random.default_rng(seed)
    N=size*S; Y,X=np.mgrid[0:N,0:N].astype(np.float32); c=N/2
    ang=np.arctan2(Y-c,X-c); r=np.hypot(X-c,Y-c)/(N/2)
    k=np.arange(pts)
    outer=0.55+0.42*rng.random(pts); inner=0.16
    seg=(ang+np.pi)/(2*np.pi)*pts; i0=np.floor(seg).astype(int)%pts; f=seg-np.floor(seg)
    tip=np.where(f<0.5, inner+(outer[i0]-inner)*(f*2), inner+(outer[i0]-inner)*(2-f*2))
    a=(r<tip).astype(np.float32)
    al=np.array(Image.fromarray((a*255).astype(np.uint8)).resize((size,size),Image.LANCZOS)).astype(np.float32)
    g=np.array(Image.fromarray(al.astype(np.uint8)).filter(ImageFilter.GaussianBlur(14))).astype(np.float32)*0.5
    A=np.maximum(al,g)
    yy,xx=np.mgrid[0:size,0:size]; rr=np.hypot(xx-size/2,yy-size/2)/(size/2)
    t=np.clip(rr/0.8,0,1)[...,None]
    rgb=np.array(tint[0],np.float32)*(1-t)+np.array(tint[1],np.float32)*t
    return np.dstack([rgb,A]).astype(np.uint8)
PAL={'normal':((255,232,140),(255,118,18)),'crit':((255,226,200),(235,30,30))}
out={}
for tag,tint in PAL.items():
    Image.fromarray(teeth(True,0,tint=tint),'RGBA').save(f'bite3_top_{tag}.png')
    Image.fromarray(teeth(False,26,tint=tint),'RGBA').save(f'bite3_bottom_{tag}.png')
    Image.fromarray(rays(tint=((255,250,235),tint[1])),'RGBA').save(f'bite3_rays_{tag}.png')
    Image.fromarray(needle(tint=((255,255,240),tint[1])),'RGBA').save(f'bite3_needle_{tag}.png')
    Image.fromarray(spiky(tint=(tint[0],tint[1])),'RGBA').save(f'bite3_burst_{tag}.png')
Image.fromarray(flash(),'RGBA').save('bite3_flash.png')
# preview: composite a timeline like the reference on a dark grey bg
def over(bg,im,cx,cy,scale,alpha=1.0):
    im=Image.fromarray(im) if isinstance(im,np.ndarray) else im
    w=int(im.width*scale); h=int(im.height*scale)
    im=im.resize((w,h),Image.LANCZOS); a=np.array(im).astype(np.float32)
    x0=int(cx-w/2); y0=int(cy-h/2)
    H,W=bg.shape[:2]
    xa,ya=max(0,x0),max(0,y0); xb,yb=min(W,x0+w),min(H,y0+h)
    if xa>=xb or ya>=yb: return bg
    sub=a[ya-y0:yb-y0, xa-x0:xb-x0]; al=sub[...,3:]/255*alpha
    bg[ya:yb,xa:xb]=bg[ya:yb,xa:xb]*(1-al)+sub[...,:3]*al
    return bg
def addv(bg,im,cx,cy,scale,alpha=1.0):  # additive-ish (screen) for flash
    im=Image.fromarray(im); w=int(im.width*scale); h=int(im.height*scale)
    a=np.array(im.resize((w,h),Image.LANCZOS)).astype(np.float32)
    x0=int(cx-w/2); y0=int(cy-h/2); H,W=bg.shape[:2]
    xa,ya=max(0,x0),max(0,y0); xb,yb=min(W,x0+w),min(H,y0+h)
    sub=a[ya-y0:yb-y0, xa-x0:xb-x0]; al=sub[...,3:]/255*alpha
    bg[ya:yb,xa:xb]=np.clip(bg[ya:yb,xa:xb]+sub[...,:3]*al,0,255); return bg
frames=[]
top=Image.open('bite3_top_normal.png'); bot=Image.open('bite3_bottom_normal.png')
for k,(off,ph) in enumerate([(150,'in'),(80,'in'),(30,'in'),(0,'snap'),(0,'hold'),(0,'sparks')]):
    bg=np.full((360,400,3),(46,46,52),np.float32)
    if ph!='sparks':
        bg=over(bg,top,200,180-off,0.42); bg=over(bg,bot,200,180+off,0.42)
    if ph=='snap':
        bg=addv(bg,np.array(Image.open('bite3_rays_normal.png')),200,180,0.42)
        bg=addv(bg,np.array(Image.open('bite3_flash.png')),200,180,0.5)
    if ph=='hold':
        bg=over(bg,Image.open('bite3_burst_normal.png'),200,180,0.30,0.8)
        bg=over(bg,top,200,180,0.42); bg=over(bg,bot,200,180,0.42)
    if ph=='sparks':
        bg=addv(bg,np.array(Image.open('bite3_burst_normal.png')),200,185,0.18,0.5)
        nd=Image.open('bite3_needle_normal.png')
        rng=np.random.default_rng(1)
        for i in range(12):
            a=rng.uniform(0,360); s=rng.uniform(0.12,0.3)
            im=nd.rotate(a,expand=True,resample=Image.BICUBIC)
            r=rng.uniform(40,140); th=np.radians(a+90)
            bg=addv(bg,np.array(im),200+r*np.cos(th),180-r*np.sin(th),s)
    frames.append(bg)
Image.fromarray(np.hstack(frames).astype(np.uint8)).save('preview3.png')
