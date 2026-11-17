from PIL import Image
h=Image.open('../video/big/t_266.jpg').convert('RGB'); o=Image.open('exact.png').convert('RGB')
import sys
xs=list(range(*map(int,sys.argv[1:3]))) if len(sys.argv)>2 else list(range(626,656))+list(range(790,826))
def m(im,y): 
    px=[im.getpixel((x,y)) for x in xs]; return tuple(sum(p[i] for p in px)//len(px) for i in range(3))
tot=0
for y in range(298,482,8):
    a,b=m(h,y),m(o,y); d=sum(abs(a[i]-b[i]) for i in range(3)); tot+=d
    print(y, '#%02X%02X%02X'%a, '#%02X%02X%02X'%b, d, 'unit-frac %.2f'%((y-295)/1.409/131))
print('total',tot)
