from PIL import Image, ImageDraw, ImageFont
im = Image.open('thumb_raw.png').convert('RGB')
W, H = im.size  # 1536x1024 -> 16:9
ch = int(W * 9 / 16)
top = 40
im = im.crop((0, top, W, top + ch)).resize((1920, 1080), Image.LANCZOS)
d = ImageDraw.Draw(im)
def label(text, xy, size, fill, anchor):
    f = ImageFont.truetype('C:/Windows/Fonts/impact.ttf', size)
    x, y = xy
    # thick navy outline + a drop shadow (house style: thick ink outline)
    d.text((x + 8, y + 10), text, font=f, fill=(6, 18, 43), anchor=anchor, stroke_width=16, stroke_fill=(6, 18, 43))
    d.text((x, y), text, font=f, fill=fill, anchor=anchor, stroke_width=14, stroke_fill=(10, 24, 60))
label('HOUR 1', (80, 70), 170, (255, 255, 255), 'la')
label('HOUR 100', (1840, 70), 190, (255, 214, 64), 'ra')
im.save('mb_thumb_hour1_hour100.png', optimize=True)
im.resize((768, 432), Image.LANCZOS).save('mb_thumb_preview_small.png')
print(im.size)
