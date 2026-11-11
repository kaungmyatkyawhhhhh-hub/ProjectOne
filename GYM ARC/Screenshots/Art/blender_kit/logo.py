from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
def text_mask(txt,font,pad,stroke=0):
    d=ImageDraw.Draw(Image.new('L',(1,1))); bb=d.textbbox((0,0),txt,font=font)
    W=bb[2]-bb[0]+pad*2; H=bb[3]-bb[1]+pad*2
    m=Image.new('L',(W,H),0); ImageDraw.Draw(m).text((pad-bb[0],pad-bb[1]),txt,font=font,fill=255,stroke_width=stroke,stroke_fill=255)
    return m
def grad(size,top,bot,mid=None):
    W,H=size; g=Image.new('RGB',size); d=ImageDraw.Draw(g)
    for y in range(H):
        t=y/max(1,H-1)
        if mid and t<0.5: a,b,k=top,mid,t*2
        elif mid: a,b,k=mid,bot,(t-0.5)*2
        else: a,b,k=top,bot,t
        d.line((0,y,W,y),fill=tuple(int(a[i]+(b[i]-a[i])*k) for i in range(3)))
    return g
def logo_word(txt,size,top,mid,bot,depth=14,outline=(25,10,35),fontfile='fonts/luckiest-guy.ttf',shine=True):
    f=ImageFont.truetype(fontfile,size); pad=60
    core=text_mask(txt,f,pad)
    o1=text_mask(txt,f,pad,stroke=max(6,size//18))
    o2=text_mask(txt,f,pad,stroke=max(10,size//10))
    W,H=core.size; out=Image.new('RGBA',(W,H+depth+20),(0,0,0,0))
    # glow/shadow
    sh=o2.filter(ImageFilter.GaussianBlur(14)); out.paste(Image.new('RGBA',(W,H),(0,0,0,200)),(6,depth+10),sh)
    # extrusion
    for k in range(depth,0,-1):
        c=tuple(int(v*0.45) for v in bot)
        out.paste(Image.new('RGBA',(W,H),(*outline,255)),(0,k),o2)
    out.paste(Image.new('RGBA',(W,H),(*outline,255)),(0,0),o2)
    out.paste(Image.new('RGBA',(W,H),(255,255,255,255)),(0,0),o1)
    inner=text_mask(txt,f,pad,stroke=max(2,size//45))
    out.paste(Image.new('RGBA',(W,H),(*outline,255)),(0,0),inner)
    g=grad((W,H),top,bot,mid).convert('RGBA')
    out.paste(g,(0,0),core)
    if shine:
        # glossy top highlight: upper part of the letters lighter
        hl=Image.new('L',(W,H),0); d=ImageDraw.Draw(hl); bb=core.getbbox()
        d.ellipse((bb[0]-W*0.2,bb[1]-(bb[3]-bb[1])*1.1,bb[2]+W*0.2,bb[1]+(bb[3]-bb[1])*0.45),fill=110)
        hl=ImageChops.multiply(hl,core.filter(ImageFilter.MinFilter(5))).filter(ImageFilter.GaussianBlur(2))
        out.paste(Image.new('RGBA',(W,H),(255,255,255,255)),(0,0),hl)
    return out.crop(out.getbbox())
def ribbon(txt,size,fill=(255,255,255),bg=(200,30,40),bg2=(140,10,25)):
    f=ImageFont.truetype('fonts/luckiest-guy.ttf',size)
    t=text_mask(txt,f,10); tw,th=t.size; W=tw+size*1.2; H=int(th*1.45)
    im=Image.new('RGBA',(int(W+size),H+20),(0,0,0,0)); d=ImageDraw.Draw(im)
    x0=size//2; 
    d.polygon([(0,10+H*0.25),(x0+10,10+H*0.25),(x0+10,10+H),(0,10+H),(x0*0.5,10+H*0.62)],fill=bg2)
    R=im.width
    d.polygon([(R,10+H*0.25),(R-x0-10,10+H*0.25),(R-x0-10,10+H),(R,10+H),(R-x0*0.5,10+H*0.62)],fill=bg2)
    d.rounded_rectangle((x0,0,R-x0,H-4),radius=12,fill=(20,8,20),)
    d.rounded_rectangle((x0+6,6,R-x0-6,H-10),radius=10,fill=bg)
    w=logo_word(txt,size,fill,None,(255,215,120) if fill==(255,255,255) else fill,depth=4,shine=False)
    im.alpha_composite(w,(int((R-w.width)/2),int((H-6-w.height)/2)))
    return im
if __name__=='__main__':
    a=logo_word('GYM ARC',190,(255,248,180),(255,190,40),(235,90,10))
    bg=Image.new('RGBA',(a.width+40,a.height+240),(60,30,90,255)); bg.alpha_composite(a,(20,20))
    r=ribbon('HALL OF FAME',70); bg.alpha_composite(r,(20,a.height+20)); bg.save('logo_test.png')
