# v16: like v7/compose_v7.py, plus a thicker dark-navy outer stroke round the logo (Gemini: logo must read at 64 px).
# usage: python compose_v16.py <art.png> <out.png> [logo_frac=0.53] [stroke_px=9]
import sys, numpy as np
from PIL import Image, ImageFilter
LOGO = Image.open('../../icon_render_25nov/gymarc_logo_v10_tone22_lb.png').convert('RGBA')
src, out = sys.argv[1], sys.argv[2]
frac = float(sys.argv[3]) if len(sys.argv) > 3 else 0.53; st = int(sys.argv[4]) if len(sys.argv) > 4 else 9
im = Image.open(src).convert('RGBA').resize((1024, 1024), Image.LANCZOS)
w = int(1024*frac); lg = LOGO.resize((w, int(LOGO.height*w/LOGO.width)), Image.LANCZOS)
pad = st + 4; big = Image.new('RGBA', (lg.width+2*pad, lg.height+2*pad), (0,0,0,0)); big.alpha_composite(lg, (pad, pad))
a = big.split()[3].point(lambda v: 255 if v > 40 else 0).filter(ImageFilter.MaxFilter(2*st+1)).filter(ImageFilter.GaussianBlur(1.2))
stroke = Image.new('RGBA', big.size, (8,16,40,255)); stroke.putalpha(a)
sh = Image.new('RGBA', im.size, (0,0,0,0)); s2 = Image.new('RGBA', big.size, (5,10,30,255)); s2.putalpha(a.point(lambda v: v*0.6))
x, y = 22-pad+st, 18-pad+st
sh.alpha_composite(s2, (x+8, y+10)); im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
im.alpha_composite(stroke, (x, y)); im.alpha_composite(lg, (x+pad, y+pad))
im = im.convert('RGB'); im.save(out); im.resize((512,512), Image.LANCZOS).save(out.replace('.png','_512.png'))
a64 = np.asarray(im.resize((64,64)), float)/255; l = a64@[.299,.587,.114]
print(out, f"lum {l.mean():.2f} dark {(l<45/255).mean():.0%}")
