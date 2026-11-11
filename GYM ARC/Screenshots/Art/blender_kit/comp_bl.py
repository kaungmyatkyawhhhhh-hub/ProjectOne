from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops, ImageEnhance
import random, math
random.seed(3)
W,H=1920,1080
hero=Image.open('bl/final.png').convert('RGBA')
rgb=hero.convert('RGB').filter(ImageFilter.MedianFilter(3)); a=hero.split()[3]
rgb=ImageEnhance.Contrast(rgb).enhance(1.06); hero=Image.merge('RGBA',(*rgb.split(),a))
# background
bg=Image.new('RGB',(W,H)); d=ImageDraw.Draw(bg)
for y in range(H):
    t=y/H; d.line((0,y,W,y),fill=(int(26+30*t),int(10+8*t),int(52+40*t)))
glow=Image.new('L',(W,H),0); gd=ImageDraw.Draw(glow)
gd.ellipse((W*0.5-700,H*0.15-500,W*0.5+700,H*0.15+600),fill=150); glow=glow.filter(ImageFilter.GaussianBlur(220))
bg=Image.composite(Image.new('RGB',(W,H),(150,70,255)),bg,glow)
# gym silhouettes: dark rack shapes and ceiling beams, blurred
sil=Image.new('L',(W,H),0); sd=ImageDraw.Draw(sil)
for x in (160,420,1500,1760):
    sd.rectangle((x,250,x+26,1080),fill=255); sd.rectangle((x+150,250,x+176,1080),fill=255); sd.rectangle((x,250,x+176,280),fill=255)
for x in range(-200,W,380): sd.polygon([(x,0),(x+60,0),(x+260,190),(x+200,190)],fill=255)
sil=sil.filter(ImageFilter.GaussianBlur(10))
bg=Image.composite(Image.new('RGB',(W,H),(14,6,26)),bg,sil.point(lambda v:int(v*0.8)))
# ceiling light strips + bokeh
lights=Image.new('L',(W,H),0); ld=ImageDraw.Draw(lights)
for x in range(80,W,330): ld.rounded_rectangle((x,40,x+170,58),radius=9,fill=255)
for i in range(45):
    x=random.randint(0,W); y=random.randint(100,int(H*0.7)); r=random.randint(10,38)
    ld.ellipse((x-r,y-r,x+r,y+r),fill=random.randint(40,120))
lights=lights.filter(ImageFilter.GaussianBlur(7))
bg=Image.composite(Image.new('RGB',(W,H),(225,170,255)),bg,lights)
bloom=lights.filter(ImageFilter.GaussianBlur(30))
bg=Image.composite(Image.new('RGB',(W,H),(170,90,255)),bg,bloom.point(lambda v:int(v*0.7)))
# purple rim haze behind hero
ha=a.filter(ImageFilter.MaxFilter(31)).filter(ImageFilter.GaussianBlur(40))
bg=Image.composite(Image.new('RGB',(W,H),(190,110,255)),bg,ha.point(lambda v:int(v*0.55)))
out=bg.convert('RGBA'); 
# soft drop shadow under hero edges for separation
out.alpha_composite(hero)
out=out.convert('RGB')
vig=Image.new('L',(W,H),0); ImageDraw.Draw(vig).ellipse((-260,-200,W+260,H+260),fill=255); vig=vig.filter(ImageFilter.GaussianBlur(190))
out=Image.composite(out,ImageEnhance.Brightness(out).enhance(0.5),vig)
F='fonts/Montserrat-BlackItalic.ttf'
def logo(img,lines,x,y,size):
    f=ImageFont.truetype(F,size)
    for i,t in enumerate(lines):
        ty=y+i*int(size*0.98); tx=x+i*int(size*0.12)
        L=Image.new('L',(W,H),0); ImageDraw.Draw(L).text((tx,ty),t,font=f,fill=255)
        S2=Image.new('L',(W,H),0); ImageDraw.Draw(S2).text((tx,ty),t,font=f,fill=255,stroke_width=30,stroke_fill=255)
        img=Image.composite(Image.new('RGB',(W,H),(0,0,0)),img,S2.filter(ImageFilter.GaussianBlur(9)))
        S=Image.new('L',(W,H),0); ImageDraw.Draw(S).text((tx,ty),t,font=f,fill=255,stroke_width=19,stroke_fill=255)
        img=Image.composite(Image.new('RGB',(W,H),(255,255,255)),img,S)
        S1=Image.new('L',(W,H),0); ImageDraw.Draw(S1).text((tx,ty),t,font=f,fill=255,stroke_width=11,stroke_fill=255)
        img=Image.composite(Image.new('RGB',(W,H),(25,12,40)),img,S1)
        bb=ImageDraw.Draw(Image.new('L',(1,1))).textbbox((tx,ty),t,font=f)
        g=Image.new('RGB',(W,H)); gd=ImageDraw.Draw(g)
        for yy in range(bb[1],bb[3]+1):
            k=(yy-bb[1])/max(1,bb[3]-bb[1]); gd.line((0,yy,W,yy),fill=(255,int(222-150*k),int(70-55*k)))
        img=Image.composite(g,img,L)
    return img
out=logo(out,['GYM','ARC'],60,34,150)
out.save('/mnt/user-data/outputs/GYMARC_Thumbnail_F_Blender.png')
out.resize((480,270),Image.LANCZOS).save('f_small.png')
print('ok')
