# Side-by-side pictures: real photo (Wikimedia Commons, credited on the picture) | the game (Studio screen capture).
#   python tools/yangon/landmarks3d/maha_wizaya_compare.py <out.jpg> <photo> <game shot> "<credit line>"
import sys
from PIL import Image, ImageDraw, ImageFont


def fit(im, h):
    return im.resize((int(im.width * h / im.height), h), Image.LANCZOS)


def main(out, photo, game, credit):
    H = 640
    a = fit(Image.open(photo).convert("RGB"), H)
    b = fit(Image.open(game).convert("RGB"), H)
    im = Image.new("RGB", (a.width + b.width + 12, H + 40), (24, 24, 24))
    im.paste(a, (0, 0))
    im.paste(b, (a.width + 12, 0))
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        f = ImageFont.load_default()
    d.text((8, H + 10), "Photo: " + credit, fill=(230, 230, 230), font=f)
    d.text((a.width + 20, H + 10), "City Legends (Studio, PlayLight 13)", fill=(230, 230, 230), font=f)
    im.save(out, quality=88)
    print("wrote", out)


if __name__ == "__main__":
    main(*sys.argv[1:5])
