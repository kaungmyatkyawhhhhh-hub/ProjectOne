import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from matplotlib.colors import to_rgb, hsv_to_rgb
S = 512
rng = np.random.default_rng(7)

def grid():
    v, u = np.mgrid[0:S, 0:S] / (S-1)
    return u, 1 - v          # u right, v up (OBJ convention)

def C(c): return np.array(to_rgb(c))
def lerp(a, b, t): return a[None, None, :]*(1-t[..., None]) + b[None, None, :]*t[..., None]

def noise(scale=8, octaves=4, seed=0):
    r = np.random.default_rng(seed); out = np.zeros((S, S))
    for o in range(octaves):
        n = 2**o*scale
        g = r.random((n+1, n+1))
        img = Image.fromarray((g*255).astype(np.uint8)).resize((S, S), Image.BICUBIC)
        out += np.asarray(img, float)/255 / 2**o
    out -= out.min(); return out/out.max()

def to_img(a): return Image.fromarray((np.clip(a, 0, 1)*255).astype(np.uint8))

def feather(base, tip, shaft="#ffffff", dark_tip=None, flame=False):
    u, v = grid()
    dv = np.minimum(np.abs(v-0.25), np.abs(v-0.75))          # 0 at shaft, 0.25 at edge
    t = np.clip(u, 0, 1)**1.1
    col = lerp(C(base), C(tip), t)
    barbs = 0.5+0.5*np.sin(2*np.pi*(60*dv - 22*u))
    col *= (0.86 + 0.14*barbs)[..., None]
    col *= (1 - 0.35*(dv/0.25)**3)[..., None]                # darker edges
    sh = np.exp(-(dv/0.01)**2)
    col = col*(1-sh[..., None]*0.6) + C(shaft)[None, None, :]*sh[..., None]*0.6
    if dark_tip:
        m = np.clip((u-0.68)/0.08, 0, 1)
        col = col*(1-m[..., None]) + C(dark_tip)[None, None, :]*m[..., None]*(0.85+0.15*barbs[..., None])
    if flame:
        n = noise(6, 3, 3)
        hot = np.clip(u*1.2 + (n-0.5)*0.5 - dv*1.5, 0, 1)
        col = lerp(C("#8B0000"), C("#FF4500"), np.clip(hot*1.6, 0, 1))
        col = col*(1-np.clip(hot-0.6, 0, 1)[..., None]*2.2) + C("#FFE680")[None, None, :]*np.clip(hot-0.6, 0, 1)[..., None]*2.2
        col *= (0.88 + 0.12*barbs)[..., None]
    return to_img(col)

def scallops(base, edge, light, rows=10, cols=14, belly=None, belly_col=None):
    u, v = grid()
    y = v*rows; row = np.floor(y)
    x = u*cols + 0.5*(row % 2)
    fx = x - np.floor(x) - 0.5; fy = y - row
    d = np.sqrt((fx*1.6)**2 + (fy-0.0)**2)          # scale "cup" opening down
    inside = np.clip(1 - d, 0, 1)
    col = lerp(C(edge), C(base), np.clip(inside*2.2, 0, 1))
    col = col*(1-(inside**4)[..., None]*0.5) + C(light)[None, None, :]*(inside**4)[..., None]*0.5
    rim = np.exp(-((d-0.95)/0.05)**2)
    col *= (1 - 0.45*rim)[..., None]
    if belly is not None:
        lo, hi = belly
        m = np.clip(1 - np.abs(v - (lo+hi)/2)/((hi-lo)/2), 0, 1)
        m = np.clip(m*3, 0, 1)
        plates = 0.8 + 0.2*np.abs(np.sin(np.pi*u*24))**0.3
        bc = C(belly_col)[None, None, :]*plates[..., None]
        col = col*(1-m[..., None]) + bc*m[..., None]
    col *= (0.92 + 0.08*noise(16, 3, 11))[..., None]
    return to_img(col)

def tiger_fur(head=False):
    u, v = grid(); n = noise(10, 4, 5)
    col = lerp(C("#E0802C"), C("#F2A54A"), n)
    if head:
        bel = np.clip((0.42 - v)/0.15, 0, 1)
        stripe_coord = v*9 + 0.35*np.sin(2*np.pi*u*4)
        s = np.sin(2*np.pi*stripe_coord)
        sm = (s > 0.72) & (v > 0.45) & (np.abs(((u*4) % 1) - 0.5) < 0.38)
    else:
        bel = np.clip(1 - np.abs(v-0.75)/0.17, 0, 1)
        stripe_coord = u*16 + 0.25*np.sin(2*np.pi*v*2) + 0.12*n
        s = np.sin(2*np.pi*stripe_coord)
        width = 0.55 + 0.35*np.abs(np.sin(np.pi*(v-0.25)*2))
        sm = (s > width) & (bel < 0.3)
    col = col*(1-bel[..., None]) + C("#FFF6E8")[None, None, :]*bel[..., None]
    col[sm] = C("#1A120C")
    img = to_img(col).filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(img, float)/255
    hair = 0.92 + 0.08*np.sin(2*np.pi*(u*180 + v*40) + n*6)
    return to_img(a*hair[..., None])

def crystal(base, hi="#ffffff"):
    u, v = grid(); n = noise(5, 3, 9)
    facets = np.abs(np.sin(2*np.pi*(v*3 + n*0.4)))
    col = lerp(C(base)*0.7, C(base), facets)
    streak = np.clip(np.sin(2*np.pi*(u*2 + v*3 + n))*1.5 - 1.0, 0, 1)
    col = col*(1-streak[..., None]) + C(hi)[None, None, :]*streak[..., None]
    col = lerp(C(base)*0.55, np.array([1, 1, 1.0]), np.clip(u, 0, 1))*0.35 + col*0.65
    return to_img(col)

def galaxy():
    u, v = grid()
    n1 = noise(4, 5, 21); n2 = noise(6, 5, 22)
    col = lerp(C("#120626"), C("#4B1C8F"), np.clip(n1*1.4-0.3, 0, 1))
    col = col + C("#E048C8")[None, None, :]*np.clip(n2-0.62, 0, 1)[..., None]*2.0
    col = col + C("#3FA8FF")[None, None, :]*np.clip(n1-0.7, 0, 1)[..., None]*2.0
    img = to_img(col); d = ImageDraw.Draw(img); r = np.random.default_rng(5)
    for _ in range(900):
        x, y = r.integers(0, S, 2); b = r.random()
        rad = 0.6 if b < 0.85 else 1.6
        d.ellipse((x-rad, y-rad, x+rad, y+rad), fill=(255, 255, 255))
    for _ in range(14):
        x, y = r.integers(0, S, 2)
        d.line((x-6, y, x+6, y), fill=(255, 240, 255)); d.line((x, y-6, x, y+6), fill=(255, 240, 255))
    return img

def koi(fins=False):
    u, v = grid()
    if fins:
        hue = (u*0.8 + v*0.3) % 1
        col = hsv_to_rgb(np.stack([hue, np.full_like(u, 0.55), np.full_like(u, 1.0)], -1))
        rays = 0.85 + 0.15*np.abs(np.sin(2*np.pi*v*28))
        col = col*rays[..., None]*(0.75 + 0.25*u[..., None])
        return to_img(col)
    n = noise(5, 4, 31)
    hue = (n*1.3 + u*0.4) % 1
    patch = hsv_to_rgb(np.stack([hue, np.full_like(u, 0.8), np.full_like(u, 1.0)], -1))
    m = np.clip((noise(4, 4, 32) - 0.45)*6, 0, 1) * np.clip((0.95 - np.abs(v-0.75)*0)*1, 0, 1)
    belly = np.clip(1 - np.abs(v-0.75)/0.15, 0, 1)
    m = m*(1-belly)
    col = np.ones((S, S, 3))*C("#FFF8F2")
    col = col*(1-m[..., None]) + patch*m[..., None]
    sc = np.asarray(scallops("#ffffff", "#b8b0c8", "#ffffff", rows=14, cols=26), float)/255
    col = col*(0.82 + 0.18*sc)
    return to_img(col)

def wood(base, grain_dark=0.8, along_u=True):
    u, v = grid(); n = noise(3, 4, 41)
    coord = (v if along_u else u)*40 + n*6
    g = 0.5+0.5*np.sin(2*np.pi*coord)
    col = np.ones((S, S, 3))*C(base)
    col *= (grain_dark + (1-grain_dark)*g)[..., None]
    col *= (0.9 + 0.1*noise(20, 2, 42))[..., None]
    return to_img(col)

def plaque():
    img = wood("#3B2416", 0.75, along_u=False); d = ImageDraw.Draw(img)
    d.rectangle((14, 14, S-15, S-15), outline=(225, 180, 60), width=14)
    try: f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 110)
    except Exception: f = ImageFont.load_default()
    for i, line in enumerate(["BELT", "TEST"]):
        w = d.textlength(line, font=f)
        d.text(((S-w)/2+4, 120+i*150+4), line, font=f, fill=(20, 10, 5))
        d.text(((S-w)/2, 120+i*150), line, font=f, fill=(255, 205, 70))
    return img

def flat(c, n=0.06):
    a = np.ones((S, S, 3))*C(c)*(1-n + n*noise(12, 3, 51))[..., None]
    return to_img(a)

def eye(iris, pupil="#0a0a0a"):
    # sphere uv: u around, v up; front of eye is toward -Z (u ~ 0.75)
    u, v = grid()
    du = (u - 0.75); dv = (v - 0.5)
    r = np.sqrt((du*2.0)**2 + (dv*1.0)**2)
    col = np.ones((S, S, 3))*C("#f4f4f4")
    col[r < 0.36] = C(iris); col[(np.abs(du)*2.0 < 0.06) & (np.abs(dv) < 0.3)] = C(pupil)
    img = to_img(col); d = ImageDraw.Draw(img)
    d.ellipse((int(0.70*S), int(0.35*S), int(0.73*S), int(0.40*S)), fill=(255, 255, 255))
    return img.filter(ImageFilter.GaussianBlur(1))

# part name -> texture, per creature
def textures_for(name):
    if name == "0_ToriiGate":
        red = wood("#C8321F", 0.85); blk = wood("#1C1C1C", 0.85)
        return {"Pillars": red, "Nuki": red, "TopBeam": red, "Strut": red, "Bases": blk, "Roof": blk,
                "PlaqueFrame": flat("#1C1C1C"), "Plaque": plaque()}
    if name in ("1_Phoenix", "6_FirePhoenix"):
        fire = name == "6_FirePhoenix"
        if fire:
            fea = feather("#8B0000", "#FFD34D", flame=True)
            body = scallops("#E03A1E", "#7A0E06", "#FFB347", belly=(0.62, 0.88), belly_col="#FF8A2B")
        else:
            fea = feather("#F6B92B", "#E8551C", shaft="#FFF3C0")
            body = scallops("#FFC93C", "#B86A12", "#FFF1B0", belly=(0.62, 0.88), belly_col="#FFE08A")
        return {"Body": body, "Head": body if not fire else body, "WingR": fea, "WingL": fea, "Tail": fea,
                "Beak": flat("#3A2A12") if fire else flat("#B07A10"), "Eyes": eye("#FF2A00" if fire else "#C21807")}
    if name == "2_Tiger":
        return {"Body": tiger_fur(), "Legs": tiger_fur(), "Tail": tiger_fur(), "Head": tiger_fur(head=True),
                "Nose": flat("#2B1A14"), "Fangs": flat("#FFFDF5"), "Eyes": eye("#F2C12E")}
    if name == "3_Crane":
        fea = feather("#FFFFFF", "#E6ECF5", shaft="#C9D2DE", dark_tip="#1A1A22")
        body = scallops("#FFFFFF", "#C8CFDA", "#FFFFFF", rows=12, cols=18)
        return {"Body": body, "Head": flat("#F7F8FB", 0.03), "Crown": flat("#D21F2B"), "Beak": flat("#6B6A55"),
                "WingR": fea, "WingL": fea, "Tail": feather("#2A2A33", "#101014"), "Legs": flat("#2E2E2E"), "Eyes": eye("#C9A227")}
    if name == "4_GoldDragon":
        sc = scallops("#F2C230", "#8A5A00", "#FFF2A8", belly=(0.62, 0.88), belly_col="#F6DFA0")
        return {"Body": sc, "Legs": sc, "Head": scallops("#F2C230", "#8A5A00", "#FFF2A8", rows=8, cols=10),
                "Spines": feather("#E8401C", "#FFB000", shaft="#FFE7A0"), "TailTip": feather("#E8401C", "#FFB000"),
                "Horns": flat("#F3E7C9", 0.1), "Whiskers": feather("#E8401C", "#FFB000"), "Eyes": eye("#E01010")}
    if name == "5_IceDragon":
        sc = scallops("#9EE6FF", "#2C6E9C", "#E8FBFF", belly=(0.62, 0.88), belly_col="#DDF6FF")
        mem = koi(fins=True) if False else crystal("#7FD8FF")
        return {"Body": sc, "Legs": sc, "Head": scallops("#9EE6FF", "#2C6E9C", "#E8FBFF", rows=8, cols=10),
                "WingR": mem, "WingL": mem, "Crystals": crystal("#B8F0FF"), "Horns": crystal("#DDF8FF"), "Eyes": eye("#00C8FF")}
    if name == "7_RainbowKoi":
        return {"Body": koi(), "TailFin": koi(True), "Fins": koi(True), "Eyes": flat("#0A0A0A"), "Barbels": flat("#FF9A3C")}
    if name == "8_GalaxyDragon":
        g = galaxy()
        return {"Body": g, "Legs": g, "Head": g, "Spines": crystal("#C08CFF"), "TailTip": crystal("#C08CFF"),
                "Horns": crystal("#E2CCFF"), "Eyes": eye("#FFFFFF", "#7A2CFF")}
    return {}
