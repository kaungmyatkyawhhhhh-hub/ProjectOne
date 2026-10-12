import colorsys
from PIL import Image, ImageChops
from kit import box, label, x_mark

def white_header(w=1100, h=130):
    # neutral light version: keeps rim, studs and 3D edge as shades, so a UIGradient can colour it
    return box(w, h, (236, 236, 240), rim_mix=0.6, lip_mix=0.32, top_mix=0.25, bot_mix=0.0)

def rainbow(w, h, t, sat=0.72):
    strip = Image.new('RGB', (w, 1))
    for x in range(w):
        hue = (t + x / w * 0.9) % 1
        r, g, b = colorsys.hsv_to_rgb(hue, sat, 1)
        strip.putpixel((x, 0), (int(r*255), int(g*255), int(b*255)))
    return strip.resize((w, h))

if __name__ == '__main__':
    base = white_header()
    base.save('out/panel-header-white.png')
    W, H = 900, 110
    hdr = white_header(W - 92, 96)
    frames = []
    for i in range(30):
        t = i / 30
        tint = rainbow(hdr.width, hdr.height, -t)
        rgb = ImageChops.multiply(hdr.convert('RGB'), tint)
        col = rgb.convert('RGBA'); col.putalpha(hdr.getchannel('A'))
        label(col, (40, 44), 'SHOP!', 46, anchor='lm')
        f = Image.new('RGBA', (W, H), (34, 38, 50, 255))
        f.alpha_composite(col, (4, 7))
        f.alpha_composite(x_mark(box(92, 96, 'red')), (W - 96, 7))
        frames.append(f.convert('P', palette=Image.ADAPTIVE, colors=255))
    frames[0].save('rainbow-header.gif', save_all=True, append_images=frames[1:], duration=50, loop=0, disposal=2)
    frames[0].convert('RGB').save('rainbow-header.png')
    print('ok')
