# Draws the aesthetic proportion guide (front double biceps, mid-thigh crop) used as the ChatGPT reference.
from PIL import Image, ImageDraw
W = 1024; H = 200  # H = head width
im = Image.new('RGB', (W, W), (30, 90, 220)); d = ImageDraw.Draw(im)
cx = 545; F = (225, 225, 230); L = (60, 60, 80)
sh = 3 * H; wa = sh // 2                          # shoulders 3 heads, waist half the shoulders
sy, wy = 400, 760
sl, sr = cx - sh // 2, cx + sh // 2
# thighs sweep out below the waist (X-frame), cut at the bottom edge
d.polygon([(cx - wa//2, wy), (cx + wa//2, wy), (cx + wa//2 + 70, W), (cx - wa//2 - 70, W)], fill=(70, 70, 80))
# torso V: lats flare from the armpits down to a tight waist
d.polygon([(sl + 30, sy), (sr - 30, sy), (sr - 60, 520), (cx + wa//2, wy), (cx - wa//2, wy), (sl + 60, 520)], fill=F, outline=L)
# pecs, abs
d.arc((sl + 70, 400, cx + 5, 590), 20, 160, fill=L, width=5); d.arc((cx - 5, 400, sr - 70, 590), 20, 160, fill=L, width=5)
for r in range(3):
    for s in (-1, 1): d.rounded_rectangle((cx + s*8 + (0 if s > 0 else -70), 600 + r*52, cx + s*8 + (70 if s > 0 else 0), 645 + r*52), 12, outline=L, width=4)
for s in (-1, 1):
    x0 = sl if s < 0 else sr
    ex = 75 if s < 0 else W - 75
    d.line([(x0, sy + 20), (ex, sy + 10)], fill=F, width=95)           # upper arm out
    d.ellipse((min(x0, ex) + 20, sy - 115, max(x0, ex) - 20, sy + 40), fill=F, outline=L, width=4)  # biceps peak ~ head size
    d.line([(ex, sy + 30), (ex, 170)], fill=F, width=80)               # forearm up
    d.ellipse((ex - 55, 110, ex + 55, 215), fill=F, outline=L, width=4) # fist
    d.ellipse((x0 - 75, sy - 70, x0 + 75, sy + 80), fill=F, outline=L, width=4)  # round capped delt
d.rectangle((cx - 60, 320, cx + 60, sy + 10), fill=F)                  # neck = arm thickness
d.rectangle((cx - H//2, 120, cx + H//2, 320), fill=(245, 210, 160), outline=L, width=5)  # blocky head, 1 head wide
# measurement marks
R = (255, 60, 60)
d.line([(sl, 455), (sr, 455)], fill=R, width=4); d.line([(cx - wa//2, wy - 15), (cx + wa//2, wy - 15)], fill=R, width=4)
d.line([(cx - H//2, 95), (cx + H//2, 95)], fill=R, width=4)
d.text((cx - 40, 72), "1 head", fill=R); d.text((sl + 10, 462), "shoulders = 3 heads", fill=R); d.text((cx - 60, wy - 38), "waist = 1/2 shoulders", fill=R)
im.save('proportion_guide.png'); print('ok')
