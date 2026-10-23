import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from textures import *

def phoenix_wood():
    u, v = grid(); n = noise(3, 4, 61)
    g = 0.5+0.5*np.sin(2*np.pi*(u*30 + n*5))
    col = lerp(C("#E9C46A"), C("#FFF1C1"), g)
    # gold rune bands around the post
    band = (np.abs(((v*6) % 1) - 0.5) < 0.04)
    col[band] = C("#FFB000")
    col *= (0.9 + 0.1*noise(20, 2, 62))[..., None]
    return to_img(col)

def glove_leather():
    u, v = grid(); n = noise(16, 3, 71)
    col = lerp(C("#C8261A"), C("#FF6A2A"), np.clip(v*0.8 + n*0.3, 0, 1))
    seam = (np.abs(((u*4) % 1) - 0.5) < 0.012) | (np.abs(v - 0.5) < 0.008)
    col[seam] = C("#FFD34D")
    stitch = seam & (((u*120 + v*120).astype(int) % 2) == 0)
    col[stitch] = C("#8A4A00")
    col *= (0.88 + 0.12*n)[..., None]
    return to_img(col)

def cuff():
    u, v = grid(); col = np.ones((S, S, 3))*C("#FFC93C")
    col[np.abs(v-0.5) < 0.12] = C("#FF7A1A")
    col *= (0.85 + 0.15*np.abs(np.sin(2*np.pi*u*12)))[..., None]
    return to_img(col)

def gi_cloth():
    u, v = grid(); n = noise(6, 4, 81)
    folds = 0.5+0.5*np.sin(2*np.pi*(u*7 + n*1.5))
    col = np.ones((S, S, 3))*C("#F7F5EE")*(0.86 + 0.14*folds)[..., None]
    weave = 0.97 + 0.03*np.sin(2*np.pi*u*200)*np.sin(2*np.pi*v*200)
    return to_img(col*weave[..., None])

def skin(): return flat("#F1C9A5", 0.05)

def bed_blanket():
    """Phoenix Bed skin: blanket top (use as a Texture on the blanket's top face)."""
    img = galaxy().copy()
    a = np.asarray(img, float)/255
    a = a*np.array([0.35, 0.45, 1.0])*0.9 + np.array([0.03, 0.04, 0.16])   # night blue
    img = to_img(a); d = ImageDraw.Draw(img); r = np.random.default_rng(9)
    for _ in range(40):
        x, y = r.integers(10, S-10, 2); R = r.integers(4, 9)
        pts = [(x+R*(1 if i % 2 == 0 else 0.45)*np.cos(-np.pi/2+i*np.pi/5), y+R*(1 if i % 2 == 0 else 0.45)*np.sin(-np.pi/2+i*np.pi/5)) for i in range(10)]
        d.polygon(pts, fill=(255, 205, 70))
    d.rectangle((4, 4, S-5, S-5), outline=(230, 180, 60), width=8)
    d.rectangle((18, 18, S-19, S-19), outline=(255, 215, 110), width=2)
    return img

def bed_pillow():
    img = Image.new("RGB", (S, S), (250, 244, 228)); d = ImageDraw.Draw(img)
    d.rectangle((6, 6, S-7, S-7), outline=(230, 180, 60), width=10)
    cx, cy = S//2, S//2 + 10
    gold = (245, 165, 35); orange = (235, 95, 30); red = (205, 45, 30)
    for s_ in (1, -1):                      # symmetric wings: fan of 5 feathers each side
        for k in range(5):
            a = np.radians(15 + k*16)
            L = 150 - k*14
            tipx = cx + s_*np.cos(a)*L; tipy = cy - 25 - np.sin(a)*L
            basex = cx + s_*22; basey = cy - 20
            nx, ny = -(tipy-basey), (tipx-basex); nl = np.hypot(nx, ny); nx, ny = nx/nl*13, ny/nl*13
            d.polygon([(basex+nx, basey+ny), (tipx, tipy), (basex-nx, basey-ny)], fill=gold if k % 2 == 0 else orange)
    for k in range(5):                      # tail plumes
        ang = np.radians(-90 + (k-2)*16); L = 120
        tx = cx + np.cos(ang+np.pi)*0 + (k-2)*30; ty = cy + 125
        d.polygon([(cx-10, cy+15), (tx, ty), (cx+10, cy+15)], fill=red if k % 2 == 0 else orange)
    d.ellipse((cx-26, cy-55, cx+26, cy+30), fill=(255, 195, 45))
    d.ellipse((cx-16, cy-88, cx+16, cy-56), fill=(255, 195, 45))
    d.polygon([(cx, cy-80), (cx-8, cy-104), (cx+4, cy-96), (cx+10, cy-112), (cx+10, cy-84)], fill=orange)   # crest
    d.ellipse((cx+3, cy-77, cx+9, cy-71), fill=(40, 20, 10))
    return img.filter(ImageFilter.SMOOTH)

def koi_v2():
    """more saturated koi with dark outlines on the patches so it doesn't wash out under glow."""
    u, v = grid(); n = noise(5, 4, 31)
    hue = (n*1.3 + u*0.4) % 1
    patch = hsv_to_rgb(np.stack([hue, np.full_like(u, 1.0), np.full_like(u, 0.95)], -1))
    m = noise(4, 4, 32)
    inside = m > 0.48; edge = (m > 0.45) & ~inside
    belly = np.abs(v-0.75) < 0.12
    col = np.ones((S, S, 3))*C("#FFF4EA")
    col[inside & ~belly] = patch[inside & ~belly]
    col[edge & ~belly] = C("#1A1020")
    sc = np.asarray(scallops("#ffffff", "#a89ab8", "#ffffff", rows=14, cols=26), float)/255
    return to_img(col*(0.8 + 0.2*sc))

def koi_fins_v2():
    u, v = grid()
    hue = (u*0.8 + v*0.3) % 1
    col = hsv_to_rgb(np.stack([hue, np.full_like(u, 0.95), np.full_like(u, 1.0)], -1))
    rays = 0.75 + 0.25*np.abs(np.sin(2*np.pi*v*28))
    return to_img(col*rays[..., None])

def tex_for(name):
    if name == "R1_PhoenixDummy":
        return {"Post": phoenix_wood(), "Arms": phoenix_wood(), "Leg": phoenix_wood(), "Frame": wood("#B8862B", 0.8),
                "Star": flat("#FFD34D", 0.03), "Pad": flat("#FF8A1E", 0.08)}
    if name == "R2_PhoenixGlove_R" or name == "R2_PhoenixGlove_L":
        return {"Glove": glove_leather(), "Cuff": cuff(), "Wings": feather("#FFD34D", "#FF7A1A", shaft="#FFF3C0")}
    if name == "SenseiLegs":
        return {"Legs": gi_cloth(), "Feet": skin()}
    return {}
