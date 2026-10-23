import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import art, aura2 as A, fx
import money
art.outline = lambda im, px: money.outline(im, px)
from kit import mix
S = 2
OL = (22, 14, 28)

def grad_mask(im, mask, top, bot, y0, y1):
    W, H = im.size
    g = Image.new('RGB', (W, H)); d = ImageDraw.Draw(g)
    for y in range(H):
        t = min(1, max(0, (y - y0) / max(1, y1 - y0))); d.line((0, y, W, y), fill=mix(top, bot, t))
    im.paste(g, (0, 0), mask)

def shine(im, mask, box, a=90):
    W, H = im.size
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).ellipse(box, fill=a)
    m = ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(W * .02)), mask)
    im.alpha_composite(Image.merge('RGBA', [Image.new('L', (W, H), 255)] * 3 + [m]))

def shade(im, mask, box, col=(0, 0, 0), a=70):
    W, H = im.size
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).ellipse(box, fill=a)
    m = ImageChops.multiply(m.filter(ImageFilter.GaussianBlur(W * .03)), mask)
    lay = Image.new('RGBA', (W, H), col + (0,)); lay.putalpha(m); im.alpha_composite(lay)

def finish(im, n, glowc=None):
    W = im.width
    im = art.outline(im, int(W * .022))
    out = im.resize((n, n), Image.LANCZOS)
    if glowc:
        g = Image.new('RGBA', (n, n), (0, 0, 0, 0)); g.alpha_composite(A.tint(fx.glow().resize((n, n)), glowc, .55)); g.alpha_composite(out); out = g
    return out

def ghost(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    m = Image.new('L', (W, W), 0); d = ImageDraw.Draw(m)
    d.ellipse((W*.24, W*.1, W*.76, W*.62), fill=255); d.rectangle((W*.24, W*.36, W*.76, W*.76), fill=255)
    for i in range(4):
        x = W*.24 + i*W*.13; d.ellipse((x, W*.68, x + W*.13, W*.86), fill=255)
    d.polygon([(W*.24, W*.5), (W*.08, W*.42), (W*.16, W*.36), (W*.24, W*.4)], fill=255)
    d.polygon([(W*.76, W*.5), (W*.92, W*.4), (W*.86, W*.34), (W*.76, W*.4)], fill=255)
    grad_mask(im, m, (255, 255, 255), (190, 210, 245), W*.1, W*.86)
    shade(im, m, (W*.5, W*.3, W*.95, W*.95), (90, 110, 170), 90)
    shine(im, m, (W*.32, W*.14, W*.5, W*.32), 160)
    d2 = ImageDraw.Draw(im)
    for sx in (-1, 1):
        cx = W*.5 + sx*W*.1; d2.ellipse((cx - W*.05, W*.3, cx + W*.05, W*.44), fill=OL); d2.ellipse((cx - W*.02, W*.32, cx + W*.005, W*.36), fill=(255, 255, 255))
        d2.ellipse((cx + sx*W*.04 - W*.04, W*.44, cx + sx*W*.04 + W*.04, W*.48), fill=(255, 150, 180))
    d2.arc((W*.44, W*.42, W*.56, W*.52), 20, 160, fill=OL, width=int(W*.012))
    return finish(im, n, (170, 210, 255))

def bat_shape(W, ox, oy, sc, col1, col2, flip=False):
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); m = Image.new('L', (W, W), 0); d = ImageDraw.Draw(m)
    c = W/2
    wing = [(0, .02), (-.1, -.06), (-.22, -.12), (-.34, -.1), (-.46, .0), (-.38, .02), (-.33, .1), (-.26, .04), (-.2, .13), (-.12, .06), (-.06, .14), (0, .1)]
    pts = [(c + x*W, c + y*W) for x, y in wing] + [(c - x*W, c + y*W) for x, y in reversed(wing)]
    d.polygon(pts, fill=255)
    d.ellipse((c - W*.07, c - W*.1, c + W*.07, c + W*.12), fill=255)
    d.polygon([(c - W*.06, c - W*.07), (c - W*.04, c - W*.17), (c - W*.01, c - W*.08)], fill=255)
    d.polygon([(c + W*.06, c - W*.07), (c + W*.04, c - W*.17), (c + W*.01, c - W*.08)], fill=255)
    grad_mask(im, m, col1, col2, c - W*.15, c + W*.15)
    shine(im, m, (c - W*.36, c - W*.12, c - W*.14, c - W*.04), 70)
    d2 = ImageDraw.Draw(im)
    for sx in (-1, 1):
        d2.ellipse((c + sx*W*.03 - W*.018, c - W*.04, c + sx*W*.03 + W*.018, c), fill=(255, 220, 60))
    d2.polygon([(c - W*.02, c + W*.03), (c - W*.01, c + W*.06), (c, c + W*.03)], fill=(255, 255, 255))
    d2.polygon([(c + W*.02, c + W*.03), (c + W*.01, c + W*.06), (c, c + W*.03)], fill=(255, 255, 255))
    im = art.outline(im, int(W * .014))
    im = im.resize((int(W*sc), int(W*sc)), Image.LANCZOS)
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    out = Image.new('RGBA', (W, W), (0, 0, 0, 0)); out.alpha_composite(im, (int(ox - im.width/2), int(oy - im.height/2))); return out

def bats(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    moon = Image.new('L', (W, W), 0); ImageDraw.Draw(moon).ellipse((W*.18, W*.14, W*.82, W*.78), fill=255)
    mm = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(mm, moon, (255, 230, 140), (255, 150, 40), W*.14, W*.78)
    mm.putalpha(moon.point(lambda v: v * 230 // 255)); im.alpha_composite(art.outline(mm, int(W*.018)))
    for (x, y, s, f) in ((.5, .48, .9, False), (.24, .26, .42, True), (.8, .22, .36, False), (.82, .74, .34, True)):
        im.alpha_composite(bat_shape(W, W*x, W*y, s, (90, 60, 110), (35, 20, 50), f))
    return im.resize((n, n), Image.LANCZOS)

def web(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im); c = W/2
    glow = Image.new('L', (W, W), 0); gd = ImageDraw.Draw(glow)
    lines = []
    for i in range(8):
        a = i*math.pi/4 + .2; lines.append(((c, c), (c + W*.46*math.cos(a), c + W*.46*math.sin(a))))
    for r in (.1, .19, .28, .37, .45):
        for i in range(8):
            a0, a1 = i*math.pi/4 + .2, (i+1)*math.pi/4 + .2
            p0 = (c + W*r*math.cos(a0), c + W*r*math.sin(a0)); p1 = (c + W*r*math.cos(a1), c + W*r*math.sin(a1))
            mid = ((p0[0]+p1[0])/2, (p0[1]+p1[1])/2); mid = (c + (mid[0]-c)*.88, c + (mid[1]-c)*.88)
            lines.append((p0, mid)); lines.append((mid, p1))
    for a, b in lines:
        gd.line((a, b), fill=255, width=int(W*.02)); 
    glow = glow.filter(ImageFilter.GaussianBlur(W*.012))
    gl = Image.new('RGBA', (W, W), (190, 120, 255, 0)); gl.putalpha(glow); im.alpha_composite(gl)
    for a, b in lines: d.line((a, b), fill=OL, width=int(W*.016))
    for a, b in lines: d.line((a, b), fill=(240, 240, 255), width=int(W*.008))
    # spider
    sp = Image.new('RGBA', (W, W), (0, 0, 0, 0)); sd = ImageDraw.Draw(sp)
    for sx in (-1, 1):
        for k in range(4):
            y0 = c + W*.0 + k*W*.03
            sd.line([(c, y0), (c + sx*W*.1, y0 - W*.06 + k*W*.025), (c + sx*W*.15, y0 + W*.02 + k*W*.03)], fill=(40, 25, 55), width=int(W*.016), joint='curve')
    m = Image.new('L', (W, W), 0); md = ImageDraw.Draw(m)
    md.ellipse((c - W*.08, c - W*.02, c + W*.08, c + W*.16), fill=255); md.ellipse((c - W*.05, c - W*.1, c + W*.05, c), fill=255)
    grad_mask(sp, m, (120, 70, 160), (40, 20, 60), c - W*.1, c + W*.16)
    shine(sp, m, (c - W*.06, c, c, c + W*.06), 110)
    sd = ImageDraw.Draw(sp)
    for sx in (-1, 1): sd.ellipse((c + sx*W*.022 - W*.014, c - W*.07, c + sx*W*.022 + W*.014, c - W*.04), fill=(255, 60, 80))
    sd.line((c, c - W*.1, c, c - W*.46), fill=(240, 240, 255), width=int(W*.006))
    im.alpha_composite(art.outline(sp, int(W*.012)))
    return im.resize((n, n), Image.LANCZOS)

def pumpkin(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    lobes = [(.1, .3, .44, .88), (.56, .3, .9, .88), (.24, .26, .5, .9), (.5, .26, .76, .9), (.34, .24, .66, .9)]
    for i, b in enumerate(lobes):
        m = Image.new('L', (W, W), 0); ImageDraw.Draw(m).ellipse(tuple(v*W for v in b), fill=255)
        part = Image.new('RGBA', (W, W), (0, 0, 0, 0))
        grad_mask(part, m, (255, 170, 50) if i == 4 else (245, 140, 30), (200, 80, 10), W*.26, W*.9)
        shade(part, m, (b[2]*W - W*.1, b[1]*W, b[2]*W + W*.05, b[3]*W), (120, 40, 0), 80)
        im.alpha_composite(art.outline(part, int(W*.008)))
    allm = im.getchannel('A')
    shine(im, allm, (W*.36, W*.3, W*.5, W*.42), 110)
    st = Image.new('L', (W, W), 0); ImageDraw.Draw(st).polygon([(W*.46, W*.27), (W*.48, W*.12), (W*.56, W*.08), (W*.58, W*.12), (W*.53, W*.15), (W*.54, W*.27)], fill=255)
    stem = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(stem, st, (120, 170, 60), (60, 100, 30), W*.08, W*.27); im.alpha_composite(stem)
    face = Image.new('L', (W, W), 0); fd = ImageDraw.Draw(face)
    fd.polygon([(W*.3, W*.56), (W*.38, W*.44), (W*.45, W*.57)], fill=255); fd.polygon([(W*.7, W*.56), (W*.62, W*.44), (W*.55, W*.57)], fill=255)
    fd.polygon([(W*.26, W*.66), (W*.74, W*.66), (W*.66, W*.8), (W*.58, W*.73), (W*.5, W*.82), (W*.42, W*.73), (W*.34, W*.8)], fill=255)
    fl = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(fl, face, (255, 250, 170), (255, 170, 30), W*.44, W*.82)
    im.paste((60, 20, 5, 255), (0, 0), face.filter(ImageFilter.MaxFilter(9)))
    im.alpha_composite(fl)
    g = face.filter(ImageFilter.GaussianBlur(W*.02)); glw = Image.new('RGBA', (W, W), (255, 200, 60, 0)); glw.putalpha(g.point(lambda v: v*170//255)); im.alpha_composite(glw)
    return finish(im, n, (255, 140, 30))

def cursed(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    def tongue(x, base, h, w, lean):
        m = Image.new('L', (W, W), 0); d = ImageDraw.Draw(m)
        pts = []
        for i in range(21):
            t = i / 20
            y = base - h * t
            half = w * (1 - t) ** 0.7 * (1 + 0.25 * math.sin(t * 6))
            pts.append((x - half + lean * t * t, y))
        for i in range(20, -1, -1):
            t = i / 20
            y = base - h * t
            half = w * (1 - t) ** 0.7 * (1 + 0.25 * math.sin(t * 6 + 1))
            pts.append((x + half + lean * t * t, y))
        d.polygon(pts, fill=255)
        d.ellipse((x - w, base - w * 0.9, x + w, base + w * 0.6), fill=255)
        return m
    for (x, h, w, lean, c1, c2) in ((.26, .42, .1, -.05, (150, 255, 120), (20, 140, 40)), (.74, .44, .1, .06, (150, 255, 120), (20, 140, 40)),
                                     (.4, .58, .12, -.04, (180, 255, 150), (30, 170, 50)), (.6, .6, .12, .05, (180, 255, 150), (30, 170, 50)),
                                     (.5, .72, .14, .02, (220, 255, 200), (60, 210, 70))):
        m = tongue(W*x, W*.84, W*h, W*w, W*lean)
        part = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(part, m, c1, c2, W*(.84-h), W*.84)
        inner = tongue(W*x, W*.84, W*h*.6, W*w*.5, W*lean*.6)
        grad_mask(part, inner, (240, 255, 230), (150, 255, 140), W*(.84-h*.6), W*.84)
        im.alpha_composite(art.outline(part, int(W*.01)))
    sk = Image.new('L', (W, W), 0); sd = ImageDraw.Draw(sk)
    sd.ellipse((W*.32, W*.3, W*.68, W*.64), fill=255); sd.rounded_rectangle((W*.38, W*.56, W*.62, W*.74), W*.03, fill=255)
    skull = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(skull, sk, (250, 252, 240), (190, 200, 180), W*.3, W*.74)
    shade(skull, sk, (W*.5, W*.4, W*.75, W*.75), (60, 80, 60), 70); shine(skull, sk, (W*.38, W*.33, W*.5, W*.42), 120)
    d = ImageDraw.Draw(skull)
    for sx in (-1, 1):
        cx = W*.5 + sx*W*.075; d.ellipse((cx - W*.055, W*.42, cx + W*.055, W*.53), fill=(20, 60, 25))
        d.ellipse((cx - W*.025, W*.455, cx + W*.025, W*.5), fill=(120, 255, 120))
    d.polygon([(W*.5, W*.54), (W*.48, W*.59), (W*.52, W*.59)], fill=(20, 60, 25))
    for k in range(4): d.line((W*.42 + k*W*.053, W*.62, W*.42 + k*W*.053, W*.73), fill=(90, 100, 90), width=int(W*.008))
    im.alpha_composite(art.outline(skull, int(W*.016)))
    return finish(im, n, (60, 255, 90))

def reaper(n=512):
    W = n * S; im = Image.new('RGBA', (W, W), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    # scythe behind
    sc = Image.new('RGBA', (W, W), (0, 0, 0, 0)); sd = ImageDraw.Draw(sc)
    sd.line((W*.76, W*.08, W*.64, W*.94), fill=(110, 70, 45), width=int(W*.03))
    bl = Image.new('L', (W, W), 0); bd = ImageDraw.Draw(bl)
    bd.pieslice((W*.3, W*.02, W*1.0, W*.46), 185, 290, fill=255); bd.pieslice((W*.38, W*.1, W*.94, W*.42), 180, 300, fill=0)
    blade = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(blade, bl, (240, 245, 255), (150, 160, 190), W*.02, W*.3)
    sc.alpha_composite(blade); im.alpha_composite(art.outline(sc, int(W*.012)))
    # cloak
    cl = Image.new('L', (W, W), 0); cd = ImageDraw.Draw(cl)
    cd.polygon([(W*.5, W*.14), (W*.3, W*.36), (W*.18, W*.92), (W*.36, W*.86), (W*.5, W*.94), (W*.64, W*.86), (W*.82, W*.92), (W*.7, W*.36)], fill=255)
    cd.ellipse((W*.34, W*.14, W*.66, W*.48), fill=255)
    cloak = Image.new('RGBA', (W, W), (0, 0, 0, 0)); grad_mask(cloak, cl, (90, 50, 120), (25, 12, 38), W*.14, W*.94)
    shine(cloak, cl, (W*.36, W*.16, W*.48, W*.34), 70)
    d2 = ImageDraw.Draw(cloak); d2.ellipse((W*.39, W*.24, W*.61, W*.46), fill=(6, 2, 12))
    for sx in (-1, 1): d2.ellipse((W*.5 + sx*W*.045 - W*.022, W*.32, W*.5 + sx*W*.045 + W*.022, W*.36), fill=(255, 50, 70))
    im.alpha_composite(art.outline(cloak, int(W*.016)))
    eyes = Image.new('L', (W, W), 0); ed = ImageDraw.Draw(eyes)
    for sx in (-1, 1): ed.ellipse((W*.5 + sx*W*.045 - W*.04, W*.3, W*.5 + sx*W*.045 + W*.04, W*.38), fill=200)
    eg = Image.new('RGBA', (W, W), (255, 40, 80, 0)); eg.putalpha(eyes.filter(ImageFilter.GaussianBlur(W*.02))); im.alpha_composite(eg)
    out = im.resize((n, n), Image.LANCZOS)
    g = Image.new('RGBA', (n, n), (0, 0, 0, 0)); g.alpha_composite(A.tint(fx.glow().resize((n, n)), (220, 40, 110), .55)); g.alpha_composite(out)
    return g

ALL = dict(ghost=ghost, bats=bats, web=web, pumpkin=pumpkin, cursed=cursed, reaper=reaper)
if __name__ == '__main__':
    sheet = Image.new('RGBA', (6*270+10, 280), (40, 22, 60, 255))
    for i, (k, f) in enumerate(ALL.items()):
        im = f(512); im.save(f'/home/user/ProjectOne/Break A Bed/Auras/aura-{k}.png')
        sheet.alpha_composite(im.resize((260, 260), Image.LANCZOS), (10 + i*270, 10))
    sheet.convert('RGB').save('hicons.png'); print('ok')
