import sys, math
from PIL import Image, ImageDraw, ImageFilter
from kit import box, window, label, x_mark, rays, OUTLINE, S
from preview import paste, icon

def gear(n):
    W = n * S
    im = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = W / 2
    def shape(scale, col):
        pts = []
        for i in range(48):
            a = i / 48 * 2 * math.pi
            r = (0.46 if (i // 3) % 2 == 0 else 0.36) * W * scale
            pts.append((c + r * math.cos(a), c + r * math.sin(a)))
        d.polygon(pts, fill=col)
    shape(1.0, OUTLINE)
    shape(0.86, (200, 208, 222))
    r = W * 0.15
    d.ellipse((c - r - W*0.05, c - r - W*0.05, c + r + W*0.05, c + r + W*0.05), fill=OUTLINE)
    d.ellipse((c - r, c - r, c + r, c + r), fill=(90, 100, 120))
    return im.resize((n, n), Image.LANCZOS)

def toggle(on):
    b = box(130, 54, 'green' if on else 'red', stud_cell=10)
    label(b, (65, 24), 'ON' if on else 'OFF', 24)
    return b

def slider(w, v):
    im = Image.new('RGBA', (w, 54), (0, 0, 0, 0))
    track = box(w - 20, 22, (60, 66, 82), pattern=False)
    im.alpha_composite(track, (10, 16))
    fill = box(int((w - 20) * v), 22, 'cyan', pattern=False)
    im.alpha_composite(fill, (10, 16))
    k = box(40, 46, 'yellow', stud_cell=8)
    im.alpha_composite(k, (int(10 + (w - 20) * v - 20), 4))
    return im

ROWS = [('Music', 'slider', 0.6), ('Sound Effects', 'slider', 0.85), ('Low Graphics', 'toggle', False),
        ('Other Players\' Effects', 'toggle', True), ('Damage Numbers', 'toggle', True), ('Screen Shake', 'toggle', True),
        ('Hide HUD', 'toggle', False)]

def main(bgpath, out):
    Wd, Hd = 1600, 900
    bg = Image.open(bgpath).convert('RGBA').resize((Wd, Hd)).filter(ImageFilter.GaussianBlur(10))
    img = Image.blend(bg, Image.new('RGBA', (Wd, Hd), (10, 15, 35, 255)), 0.2)
    cx, cy, ww, wh = 800, 440, 760, 780
    paste(img, rays(1500, 14, 170), (cx, cy))
    paste(img, window(ww, wh), (cx, cy))
    top = cy - wh / 2
    hdr = box(ww - 96, 96, 'cyan'); label(hdr, (120, 44), 'SETTINGS', 46, anchor='lm')
    paste(img, hdr, (cx - 48, top + 48))
    img.alpha_composite(gear(100), (int(cx - ww/2 + 12), int(top - 2)))
    paste(img, x_mark(box(96, 96, 'red')), (cx + ww/2 - 48, top + 48))
    rh, y = 60, top + 96 + 16
    for name, kind, val in ROWS:
        row = box(ww - 44, rh, 'slate', stud_cell=12)
        label(row, (24, rh/2 - 3), name, 26, anchor='lm')
        ctl = slider(270, val) if kind == 'slider' else toggle(val)
        row.alpha_composite(ctl, (row.width - ctl.width - 20, int(rh/2 - ctl.height/2 - 3)))
        img.alpha_composite(row, (int(cx - ww/2 + 22), int(y)))
        y += rh + 9
    # codes row
    y += 6
    code = box(ww - 44, 84, 'yellow', stud_cell=14)
    label(code, (24, 38), 'CODES', 34, fill=(255, 226, 12), anchor='lm')
    field = box(300, 54, (245, 245, 250), pattern=False)
    from kit import FONT
    from PIL import ImageFont
    ImageDraw.Draw(field).text((18, 26), 'Enter code...', font=ImageFont.truetype(FONT, 22), fill=(150, 155, 170), anchor='lm')
    code.alpha_composite(field, (180, 12))
    rb = box(170, 58, 'green', stud_cell=10); label(rb, (85, 26), 'REDEEM', 24)
    code.alpha_composite(rb, (code.width - 186, 10))
    img.alpha_composite(code, (int(cx - ww/2 + 22), int(y)))
    y += 84 + 12
    rp = box(300, 56, 'blue', stud_cell=10); label(rp, (150, 25), 'Replay Tutorial', 24)
    img.alpha_composite(rp, (int(cx - ww/2 + 22), int(y)))
    # HUD settings button
    sb = box(100, 100, 'slate'); sb.alpha_composite(gear(72), (14, 10))
    paste(img, sb, (90, 820))
    img.convert('RGB').save(out, quality=92)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
