import sys, random, math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops
from logo import logo_word, ribbon
mode=sys.argv[1]; src=sys.argv[2]; out=sys.argv[3]
random.seed(11)
im=Image.open(src).convert('RGB')
W,H=im.size
# light denoise (keeps edges) + grade
im=im.filter(ImageFilter.MedianFilter(3))
im=ImageEnhance.Contrast(im).enhance(1.08); im=ImageEnhance.Color(im).enhance(1.12)
# extra bloom from bright areas
br=im.point(lambda v:max(0,v-238)*5).filter(ImageFilter.GaussianBlur(25))
im=ImageChops.add(im,br.point(lambda v:int(v*0.3)))
# 4-point star sparkles (Sol's RNG style)
st=Image.new('L',(W,H),0); d=ImageDraw.Draw(st)
cx,cy=int(W*0.6),int(H*0.45)
for i in range(14):
    x=random.randint(int(W*0.3),W-60); y=random.randint(60,int(H*0.85))
    L=random.randint(14,40)
    d.polygon([(x,y-L),(x+L*0.13,y),(x,y+L),(x-L*0.13,y)],fill=255); d.polygon([(x-L,y),(x,y+L*0.13),(x+L,y),(x,y-L*0.13)],fill=255)
st=st.filter(ImageFilter.GaussianBlur(0.8))
col=(255,230,150) if mode=='hof' else (210,190,255)
im=Image.composite(Image.new('RGB',(W,H),col),im,st)
im=ImageChops.add(im,Image.composite(Image.new('RGB',(W,H),col),Image.new('RGB',(W,H)),st.filter(ImageFilter.GaussianBlur(8))))
# vignette
vig=Image.new('L',(W,H),0); ImageDraw.Draw(vig).ellipse((-W*0.15,-H*0.2,W*1.15,H*1.25),fill=255); vig=vig.filter(ImageFilter.GaussianBlur(200))
im=Image.composite(im,ImageEnhance.Brightness(im).enhance(0.55),vig).convert('RGBA')
# logo top-left, two lines, slight tilt
if mode=='hof': top,mid,bot=(255,250,200),(255,205,60),(220,120,10)
else: top,mid,bot=(255,250,200),(255,190,40),(235,90,10)
g=logo_word('GYM',230,top,mid,bot,depth=16); a=logo_word('ARC',230,top,mid,bot,depth=16)
L=Image.new('RGBA',(max(g.width,a.width)+80,g.height+a.height-40),(0,0,0,0))
L.alpha_composite(g,(0,0)); L.alpha_composite(a,(70,g.height-60))
if mode=='hof':
    r=ribbon('HALL OF FAME',78)
    L2=Image.new('RGBA',(max(L.width,r.width)+20,L.height+r.height-10),(0,0,0,0)); L2.alpha_composite(L,(0,0)); L2.alpha_composite(r,(0,L.height-20)); L=L2
L=L.rotate(6,resample=Image.BICUBIC,expand=True)
s=0.82 if mode=='hof' else 0.9
L=L.resize((int(L.width*s),int(L.height*s)),Image.LANCZOS)
im.alpha_composite(L,(30,10))
im=im.convert('RGB'); im.save(out)
im.resize((480,270),Image.LANCZOS).save(out.replace('.png','_small.png'))
print('ok')
