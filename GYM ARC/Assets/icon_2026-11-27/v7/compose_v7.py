# v7: character-focused icon, smaller logo top-left, size test vs locally cached top gym icons (ref_icons/), 64 px stats.
# usage: python compose_v7.py <art.png> <out_logo.png> [logo_frac] [logo_png]
import sys, glob, os, numpy as np
from PIL import Image, ImageDraw, ImageFilter
LOGO = Image.open(sys.argv[4] if len(sys.argv) > 4 else '../../icon_render_25nov/gymarc_logo_v10_blue_simple.png').convert('RGBA')
def compose(src, out, frac):
    im = Image.open(src).convert('RGBA').resize((1024, 1024), Image.LANCZOS)
    w = int(1024*frac); lg = LOGO.resize((w, int(LOGO.height*w/LOGO.width)), Image.LANCZOS)
    sh = Image.new('RGBA', im.size, (0,0,0,0)); a = lg.split()[3].point(lambda v: v*0.55)
    blk = Image.new('RGBA', lg.size, (10,20,50,255)); blk.putalpha(a); sh.alpha_composite(blk, (30, 30))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10))); im.alpha_composite(lg, (22, 18))
    im = im.convert('RGB'); im.save(out); im.resize((512,512), Image.LANCZOS).save(out.replace('.png','_512.png')); return im
def stats(im):
    a = np.asarray(im.convert('RGB').resize((64,64)), float)/255; l = a@[.299,.587,.114]; s=(a.max(2)-a.min(2))/(a.max(2)+1e-6)
    return f"lum {l.mean():.2f} dark {(l<45/255).mean():.0%} white {((l>215/255)&(s<.25)).mean():.0%}"
src, out = sys.argv[1], sys.argv[2]; frac = float(sys.argv[3]) if len(sys.argv) > 3 else 0.28
n = compose(src, out, frac)
comp = [(os.path.basename(p)[:-4].replace('_',' '), Image.open(p).convert('RGB')) for p in sorted(glob.glob('ref_icons/*.png')) if 'Muscle' not in p]
tiles = [('NEW', n)] + comp
sheet = Image.new('RGB', (len(tiles)*170+20, 360), (245,245,245)); dr = ImageDraw.Draw(sheet)
for i,(nm,t) in enumerate(tiles):
    sheet.paste(t.resize((150,150), Image.LANCZOS), (20+i*170, 20)); sheet.paste(t.resize((100,100), Image.LANCZOS), (20+i*170, 185)); sheet.paste(t.resize((60,60), Image.LANCZOS), (125+i*170, 225))
    dr.text((20+i*170, 330), nm, fill=(20,20,20)); print(nm, stats(t))
sheet.save(out.replace('.png', '_sizetest.png'))
