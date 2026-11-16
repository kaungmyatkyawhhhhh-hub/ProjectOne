import json,math,sys,os,re
sys.path.insert(0,'.'); sys.path.insert(0,r'D:/ObsidianOne/Claude+Obsidian/Games/CityLegends/tools/yangon/city')
import tiles, roadnet as rn
from PIL import Image, ImageDraw, ImageFont
try: F=ImageFont.truetype('arial.ttf',14); FS=ImageFont.truetype('arial.ttf',11)
except: F=FS=ImageFont.load_default()
OUT=tiles.OUT
def slug(s): return re.sub(r'[^A-Za-z0-9]+','_',s).strip('_')[:40]
def game_xs(t, paired):
    cs=rn.cross_section(t); LW=4.0  # 12 studs = 4 m (owner choice)
    if cs['oneway'] and paired:   # divided: 1 m median half + n lanes each side
        return cs, [-(1+cs['nf']*LW),-1,1,1+cs['nf']*LW]
    if cs['oneway']:
        w=cs['nf']*LW; return cs,[-w/2,w/2]
    return cs,[-cs['nb']*LW,cs['nf']*LW]
def draw(site, idx, z=19, size=800, half=45, extra=''):
    lat,lon=site['lat'],site['lon']
    im,x0,y0=tiles.mosaic(lat,lon,z,size,size); d=ImageDraw.Draw(im)
    m=tiles.mpp(lat,z); dx,dy=site.get('dir',(1,0))
    # image coords: +x east, +y south. road dir (east,north) -> perpendicular
    px,py=-dy,dx   # left normal in (east,north)
    cx,cy=size/2,size/2
    def P(t,off=0):  # t metres along normal (+left), off metres along road
        e=px*t+dx*off; n=py*t+dy*off; return (cx+e/m, cy-n/m)
    d.line([P(-half),P(half)],fill=(255,255,0),width=1)
    for k in range(-half,half+1):
        L=5 if k%5 else 11
        a=P(k,-L*m/2*1.0); b=P(k,L*m/2*1.0)
        a=(P(k)[0]-dx*L/2, P(k)[1]+dy*L/2); b=(P(k)[0]+dx*L/2, P(k)[1]-dy*L/2)
        d.line([a,b],fill=(255,255,0) if k%5 else (255,80,0),width=1)
        if k%10==0: d.text((P(k)[0]+dx*9,P(k)[1]-dy*9),str(k),fill=(255,255,255),font=FS,stroke_width=2,stroke_fill=(0,0,0))
    if 'tags' in site:
        cs,edges=game_xs(site['tags'],bool(site.get('partner')))
        for t in edges:
            q=P(t,6); r=4; d.ellipse([q[0]-r,q[1]-r,q[0]+r,q[1]+r],outline=(0,255,255),width=2)
        gx=('one-way %d'%cs['nf'] if cs['oneway'] else '%d+%d'%(cs['nf'],cs['nb']))+(' divided' if site.get('partner') else '')
        extra=extra+'  GAME rule: %s @4m lanes = %.1f m (cyan rings)'%(gx, edges[-1]-edges[0])
    # header
    d.rectangle([0,0,size,40],fill=(0,0,0))
    t=site.get('tags',{})
    d.text((6,3),'%02d %s  (%.5f, %.5f) z%d  %.3f m/px'%(idx,site['name'],lat,lon,z,m),fill=(255,255,255),font=F)
    d.text((6,22),('OSM %s lanes=%s oneway=%s surface=%s partner=%s'%(t.get('highway'),t.get('lanes'),t.get('oneway'),t.get('surface'),site.get('partner')) if t else '')+extra,fill=(200,255,200),font=FS)
    # scale bar 20 m
    L=20/m; d.rectangle([10,size-22,10+L,size-16],fill=(255,255,255)); d.text((14+L,size-26),'20 m',fill=(255,255,255),font=FS,stroke_width=2,stroke_fill=(0,0,0))
    fn=os.path.join(OUT,'%s_%02d_%s.jpg'%(site.get('prefix','road'),idx,slug(site['name'])))
    im.save(fn,quality=88); return fn
if __name__=='__main__':
    S=json.load(open(sys.argv[1],encoding='utf8'))
    for i,s in enumerate(S):
        if not (96.095<=s['lon']<=96.235 and 16.75<=s['lat']<=16.89): print('skip',s['name']); continue
        print(draw(s,i))
