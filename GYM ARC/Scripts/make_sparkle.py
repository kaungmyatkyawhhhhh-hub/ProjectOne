import math, sys
from PIL import Image, ImageDraw, ImageFilter
S=256; c=S/2
def star(r_out, r_in, scale=4):
    big=S*scale; im=Image.new("L",(big,big),0); d=ImageDraw.Draw(im); pts=[]
    for i in range(8):
        a=math.pi/4*i - math.pi/2; r=(r_out if i%2==0 else r_in)*scale
        pts.append((c*scale+math.cos(a)*r, c*scale+math.sin(a)*r))
    # concave sides: subdivide with a pull toward centre
    curve=[]
    for i in range(8):
        p=pts[i]; q=pts[(i+1)%8]; curve.append(p)
        for t in (0.33,0.66):
            x=p[0]+(q[0]-p[0])*t; y=p[1]+(q[1]-p[1])*t
            curve.append((c*scale+(x-c*scale)*0.82, c*scale+(y-c*scale)*0.82))
    d.polygon(curve, fill=255)
    return im.resize((S,S), Image.LANCZOS)
core=star(118, 22)
glow=core.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v*0.85))
alpha=Image.new("L",(S,S),0)
alpha.paste(255,(0,0),glow); a=Image.composite(Image.new("L",(S,S),255), glow, core)
out=Image.merge("RGBA",(Image.new("L",(S,S),255),)*3+(a,))
out.save(sys.argv[1]); assert out.size==(S,S); print("ok")
