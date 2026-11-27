# Grade pass: cut the characters out with rembg, then make the background deeper and more saturated so the white shirt pops.
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
from rembg import remove, new_session
S = new_session('isnet-general-use')
def grade(src, out, bg_gain=0.80, bg_sat=1.35):
    im = Image.open(src).convert('RGB').resize((1024,1024), Image.LANCZOS)
    m = remove(im, session=S, only_mask=True).filter(ImageFilter.GaussianBlur(2))
    bg = ImageEnhance.Color(im).enhance(bg_sat)
    a = np.asarray(bg, float); yy, xx = np.mgrid[0:1024,0:1024]/1023
    v = 1 - 0.35*np.clip(np.hypot(xx-.6, yy-.45)/0.75, 0, 1)**2
    a = a*bg_gain*v[...,None]
    bg = Image.fromarray(np.clip(a,0,255).astype('uint8'))
    fg = ImageEnhance.Contrast(im).enhance(1.08)
    Image.composite(fg, bg, m).save(out); m.save(out.replace('.png','_mask.png'))
grade('gymarc_v3_normal_final_art.png', 'gymarc_v3_normal_graded.png')
grade('gymarc_v3_xmas_final_art.png', 'gymarc_v3_xmas_graded.png')
