"""compare3.py (2026-11-16): photo | before | after strip at one height, labelled.
    python compare3.py <out.jpg> <photo> <before> <after> [height]"""
import sys

from PIL import Image, ImageDraw


def main():
    out, paths = sys.argv[1], sys.argv[2:5]
    H = int(sys.argv[5]) if len(sys.argv) > 5 else 520
    ims = []
    for p in paths:
        im = Image.open(p).convert("RGB")
        ims.append(im.resize((int(im.width * H / im.height), H)))
    W = sum(i.width for i in ims) + 8 * (len(ims) - 1)
    sheet = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(sheet)
    x = 0
    for im, lab in zip(ims, ("photo", "before", "after (ornament kit)")):
        sheet.paste(im, (x, 0))
        d.rectangle([x, 0, x + 8 + 7 * len(lab), 18], fill=(0, 0, 0))
        d.text((x + 4, 3), lab, fill=(255, 255, 255))
        x += im.width + 8
    sheet.save(out, quality=90)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
