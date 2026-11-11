import numpy as np
from PIL import Image, ImageDraw, ImageFilter
S=4
def bez(p0,p1,p2,n=32):
    t=np.linspace(0,1,n)[:,None]; return ((1-t)**2*p0+2*(1-t)*t*p1+t**2*p2)
def fang(cx,base,length,width,dirn,curve):
    tip=np.array([cx+curve*width,base+dirn*length])
    L=np.array([cx-width/2,base]); R=np.array([cx+width/2,base])
    left=bez(L,np.array([cx-width*0.40,base+dirn*length*0.55]),tip)
    right=bez(tip,np.array([cx+width*0.42,base+dirn*length*0.55]),R)
    return [tuple(p) for p in np.vstack([left,right])]
def masks_teeth(top,shift):
    W=1024*S
    xs=[140,215,300,385,469,554,639,724,809,884]
    dirn=1 if top else -1; base=410 if top else 614
    m=Image.new('L',(W,W),0); d=ImageDraw.Draw(m)
    hl=Image.new('L',(W,W),0); h=ImageDraw.Draw(hl)
    for i,x in enumerate(xs):
        x+=shift; canine=i in (1,8); edge=i in (0,9)
        length=232 if canine else 148 if edge else 158
        width=78 if canine else 58 if edge else 66
        curve=0.10*np.sign(512-x)
        d.polygon(fang(x*S,base*S,length*S,width*S,dirn,curve),fill=255)
        # highlight: thin sliver on the left of each tooth
        h.polygon(fang((x-width*0.18)*S,base*S,length*0.78*S,width*0.22*S,dirn,curve*2),fill=255)
    gum=((xs[0]+shift-40)*S,(base-(26 if top else 0))*S,(xs[-1]+shift+40)*S,(base+(0 if top else 26))*S)
    d.rounded_rectangle(gum,radius=13*S,fill=255)
    return m,hl,base,dirn
def colorize(m,hl,base,dirn,rim,out_size,name,ow=14,glow=16):
    W=m.size[0]
    inner=np.array(m).astype(float)/255
    dil=np.array(m.filter(ImageFilter.GaussianBlur(ow*S*0.55))).astype(float)
    dil=np.clip((dil-6)/20,0,1)
    yy=(np.arange(W)[:,None]/S)
    t=np.clip(np.abs(yy-base)/230,0,1)*np.ones((1,W))
    rim=np.array(rim,float)/255
    white=np.array([1,1,1.0])
    # tooth body: rim-coloured near the gum fading to white-hot at the tips
    body=(1-t[...,None]*0.0)*0
    body=rim*0.55*(1-t[...,None])+white*(0.45+0.55*t[...,None])
    body=np.clip(body+0.5*(np.array(hl).astype(float)/255)[...,None]*0.6,0,1)
    col=np.where(inner[...,None]>0, body, rim[None,None,:]*np.ones((W,W,3)))
    col=col*inner[...,None]+rim*0.9*(1-inner[...,None])
    a=np.maximum(inner,dil)
    big=np.dstack([col*255,a*255]).astype(np.uint8)
    im=Image.fromarray(big,'RGBA')
    # premultiply before resize to avoid dark fringes
    arr=np.array(im).astype(float); pm=arr[...,:3]*arr[...,3:]/255
    small_pm=np.array(Image.fromarray(pm.astype(np.uint8)).resize((out_size,out_size),Image.LANCZOS)).astype(float)
    small_a=np.array(Image.fromarray(arr[...,3].astype(np.uint8)).resize((out_size,out_size),Image.LANCZOS)).astype(float)
    g=np.array(Image.fromarray(small_a.astype(np.uint8)).filter(ImageFilter.GaussianBlur(glow))).astype(float)*0.55
    A=np.maximum(small_a,g)
    rgb=np.where(small_a[...,None]>2, small_pm/np.maximum(small_a[...,None]/255,1e-3), rim*255)
    # where glow dominates use rim colour
    w=np.clip(small_a/np.maximum(A,1),0,1)[...,None]
    rgb=rgb*w+rim*255*(1-w)
    Image.fromarray(np.dstack([np.clip(rgb,0,255),A]).astype(np.uint8),'RGBA').save(name)
def star_mask(rays,inner,size):
    W=size*S; im=Image.new('L',(W,W),0); d=ImageDraw.Draw(im); c=W/2; pts=[]
    for k in range(rays*2):
        ang=np.pi/2+k*np.pi/rays; r=(0.47 if k%2==0 else inner)*W
        pts.append((c+r*np.cos(ang),c-r*np.sin(ang)))
    d.polygon(pts,fill=255); return im
def colorize_star(m,rim,size,name):
    W=m.size[0]
    yy,xx=np.mgrid[:W,:W]; rr=np.hypot(xx-W/2,yy-W/2)/(W/2)
    inner=np.array(m).astype(float)/255
    rim=np.array(rim,float)/255
    t=np.clip(rr/0.75,0,1)[...,None]
    col=np.array([1,1,1.0])*(1-t)+rim*t
    a=inner
    arr_pm=col*a[...,None]
    pm=np.array(Image.fromarray((arr_pm*255).astype(np.uint8)).resize((size,size),Image.LANCZOS)).astype(float)
    sa=np.array(Image.fromarray((a*255).astype(np.uint8)).resize((size,size),Image.LANCZOS)).astype(float)
    g=np.array(Image.fromarray(sa.astype(np.uint8)).filter(ImageFilter.GaussianBlur(9))).astype(float)*0.6
    ys,xs=np.mgrid[:size,:size]; r2=np.hypot(xs-size/2,ys-size/2)/(size/2)
    core=np.clip(1-r2/0.16,0,1)*255
    A=np.maximum(np.maximum(sa,g),core)
    rgb=np.where(sa[...,None]>2,pm/np.maximum(sa[...,None]/255,1e-3),rim*255)
    w=np.clip(np.maximum(sa,core)/np.maximum(A,1),0,1)[...,None]
    rgb=rgb*w+rim*255*(1-w)
    rgb=np.where(core[...,None]>sa[...,None],255,rgb)
    Image.fromarray(np.dstack([np.clip(rgb,0,255),A]).astype(np.uint8),'RGBA').save(name)
for tag,rim in [('normal',(40,200,255)),('crit',(255,60,50))]:
    m,hl,b,dn=masks_teeth(True,0); colorize(m,hl,b,dn,rim,1024,f'bite_top_{tag}.png')
    m,hl,b,dn=masks_teeth(False,42); colorize(m,hl,b,dn,rim,1024,f'bite_bottom_{tag}.png')
    colorize_star(star_mask(4,0.06,512),rim,512,f'bite_spark_{tag}.png')
    colorize_star(star_mask(8,0.11,512),rim,512,f'bite_flare_{tag}.png')
def comp(names,bg):
    t=[]
    for n in names:
        im=np.array(Image.open(n).convert('RGBA').resize((400,400),Image.LANCZOS)).astype(float)
        a=im[...,3:]/255; t.append(np.array(bg)*(1-a)+im[...,:3]*a)
    return np.hstack(t)
rows=[]
for tag in ['normal','crit']:
    rows.append(comp([f'bite_top_{tag}.png',f'bite_bottom_{tag}.png',f'bite_spark_{tag}.png',f'bite_flare_{tag}.png'],(24,40,70)))
Image.fromarray(np.vstack(rows).astype(np.uint8)).save('preview2.png')
# zoom crop check (sharpness at full res)
Image.open('bite_top_normal.png').crop((150,380,550,680)).save('zoom.png')
