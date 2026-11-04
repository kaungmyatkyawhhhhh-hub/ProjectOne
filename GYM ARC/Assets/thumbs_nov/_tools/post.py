# Final touch for the GYM ARC renders: bloom, grade, text (white + dark outline), logo, the preview sheet.
import sys
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw, ImageFont, ImageChops

R, OUT, FONT, LOGO = sys.argv[1:5]

def bloom(img, threshold=170, strength=0.75):
    rgb = img.convert("RGB")
    lum = rgb.convert("L").point(lambda v: 255 if v > threshold else int(v * v / (threshold * 2.2)) if v > threshold * 0.6 else 0)
    bright = Image.composite(rgb, Image.new("RGB", rgb.size), lum)
    w = rgb.size[0]
    glow = Image.blend(bright.filter(ImageFilter.GaussianBlur(w / 160)), bright.filter(ImageFilter.GaussianBlur(w / 45)), 0.5)
    glow = ImageEnhance.Brightness(glow).enhance(strength * 2)
    return ImageChops.screen(rgb, glow)

def grade(img, sat=1.18, con=1.07):
    img = ImageEnhance.Color(img).enhance(sat)
    return ImageEnhance.Contrast(img).enhance(con)

def vignette(img, amount=0.35):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((-w * 0.15, -h * 0.2, w * 1.15, h * 1.2), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(w / 8))
    dark = ImageEnhance.Brightness(img).enhance(1 - amount)
    return Image.composite(img, dark, mask)

def outlined(draw, xy, text, font, fill=(255, 255, 255), stroke=(18, 12, 20), sw=10, anchor="la"):
    draw.text((xy[0] + sw * 0.5, xy[1] + sw * 0.8), text, font=font, fill=(0, 0, 0, 150), stroke_width=sw, stroke_fill=(0, 0, 0, 150), anchor=anchor)
    draw.text(xy, text, font=font, fill=fill, stroke_width=sw, stroke_fill=stroke, anchor=anchor)

def sticker(base, text, center, size, angle):
    font = ImageFont.truetype(FONT, size)
    layer = Image.new("RGBA", (size * 6, size * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    outlined(d, (layer.size[0] // 2, layer.size[1] // 2), text, font, sw=max(4, size // 9), anchor="mm")
    layer = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
    base.alpha_composite(layer, (int(center[0] - layer.size[0] / 2), int(center[1] - layer.size[1] / 2)))

# ICON (512)
icon = Image.open(f"{R}/final_icon.png").convert("RGB")
icon = vignette(grade(bloom(icon, 205, 0.45), 1.3, 1.08), 0.3)
icon = icon.resize((512, 512), Image.LANCZOS)
icon.save(f"{OUT}/icon_v1.png")

# THUMB 1: the giant + Diamond / Ruby plates, ONE number (Crystal Deadlift, Diamond 13/13 = 1,735 lb), small wordmark
t1 = Image.open(f"{R}/final_thumb1.png").convert("RGB")
t1 = vignette(grade(bloom(t1, 225, 0.35), 1.2, 1.08), 0.35).convert("RGBA")
d = ImageDraw.Draw(t1)
big = ImageFont.truetype(FONT, 230); small = ImageFont.truetype(FONT, 120)
outlined(d, (70, 820), "1,735", big, sw=14, anchor="ls")
nb = d.textbbox((70, 820), "1,735", font=big, anchor="ls")
outlined(d, (nb[2] + 24, 820), "LB", small, sw=10, anchor="ls")
logo = Image.open(LOGO).convert("RGBA"); lw = 230
logo = logo.resize((lw, int(logo.size[1] * lw / logo.size[0])), Image.LANCZOS)
t1.alpha_composite(logo, (1920 - lw - 40, 32))
t1.convert("RGB").save(f"{OUT}/thumb1_v1.png")

# THUMB 2: the bacon + the giant shadow, "+1 STR" stickers, small wordmark
t2 = Image.open(f"{R}/final_thumb2.png").convert("RGB")
t2 = vignette(grade(bloom(t2, 215, 0.45), 1.2, 1.07), 0.3).convert("RGBA")
for text, c, s, a in (("+1 STR", (330, 420), 78, 9), ("+1 STR", (1590, 360), 84, -8), ("+1 STR", (250, 700), 64, -6),
                      ("+1 STR", (1660, 690), 70, 7), ("+1 STR", (1370, 170), 54, 5)):
    sticker(t2, text, c, s, a)
t2.alpha_composite(logo, (40, 32))
t2.convert("RGB").save(f"{OUT}/thumb2_v1.png")

# PREVIEW SHEET at Roblox's real sizes: icon 150 + 50, thumbnails 384x216
sheet = Image.new("RGB", (1240, 560), (22, 22, 26)); sd = ImageDraw.Draw(sheet)
lab = ImageFont.truetype(FONT, 20)
sd.text((30, 20), "GYM ARC - icon + thumbnails at Roblox sizes (v1, 4 Nov)", font=lab, fill=(230, 230, 235))
sheet.paste(icon.resize((150, 150), Image.LANCZOS), (30, 70)); sd.text((30, 228), "icon 150 px", font=lab, fill=(170, 170, 180))
sheet.paste(icon.resize((50, 50), Image.LANCZOS), (200, 170)); sd.text((200, 228), "50 px", font=lab, fill=(170, 170, 180))
a = Image.open(f"{OUT}/thumb1_v1.png").resize((384, 216), Image.LANCZOS); b = Image.open(f"{OUT}/thumb2_v1.png").resize((384, 216), Image.LANCZOS)
sheet.paste(a, (320, 70)); sd.text((320, 292), "#1 thumb1 (384x216)", font=lab, fill=(170, 170, 180))
sheet.paste(b, (730, 70)); sd.text((730, 292), "thumb2 (384x216)", font=lab, fill=(170, 170, 180))
sheet.paste(a.resize((192, 108), Image.LANCZOS), (320, 340)); sheet.paste(b.resize((192, 108), Image.LANCZOS), (530, 340))
sd.text((320, 456), "small tiles (192x108)", font=lab, fill=(170, 170, 180))
sheet.save(f"{OUT}/preview_sheet_v1.png")
print("post ok")
