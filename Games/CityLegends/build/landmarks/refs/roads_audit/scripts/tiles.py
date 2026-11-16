import math, os, io, time, requests, json
from PIL import Image, ImageDraw, ImageFont
OUT=r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/build/landmarks/refs/roads_audit'
TD=os.path.join(OUT,'tiles')
URL='https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
S=requests.Session(); S.headers['User-Agent']='Mozilla/5.0 (road-audit)'
def ll2px(lat,lon,z):
    n=256*2**z; x=(lon+180)/360*n; s=math.sin(math.radians(lat)); y=(0.5-math.log((1+s)/(1-s))/(4*math.pi))*n; return x,y
def px2ll(x,y,z):
    n=256*2**z; lon=x/n*360-180; lat=math.degrees(math.atan(math.sinh(math.pi*(1-2*y/n)))); return lat,lon
def mpp(lat,z): return 156543.03392*math.cos(math.radians(lat))/2**z
def tile(z,x,y):
    p=os.path.join(TD,'%d_%d_%d.jpg'%(z,x,y))
    if not os.path.exists(p) or os.path.getsize(p)<100:
        for k in range(4):
            try:
                r=S.get(URL.format(z=z,x=x,y=y),timeout=30)
                if r.status_code==200: open(p,'wb').write(r.content); break
            except Exception as e: time.sleep(2)
    try: return Image.open(p).convert('RGB')
    except Exception: return Image.new('RGB',(256,256),(255,0,255))
def mosaic(lat,lon,z=19,w=768,h=768):
    cx,cy=ll2px(lat,lon,z); x0=int(cx-w/2); y0=int(cy-h/2)
    im=Image.new('RGB',(w,h))
    for tx in range(x0//256,(x0+w)//256+1):
        for ty in range(y0//256,(y0+h)//256+1):
            im.paste(tile(z,tx,ty),(tx*256-x0,ty*256-y0))
    return im,x0,y0
