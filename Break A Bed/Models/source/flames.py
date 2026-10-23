import numpy as np, sys, os
from PIL import Image, ImageFilter
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)
F = 256

def flame_field(t, seed=0, tongues=3, sharp=1.0):
    """signed 'inside' field for a stylized anime flame at time t (0..1 loops)."""
    y, x = (np.mgrid[0:F, 0:F] + 0.5)/F
    x = x*2 - 1; y = 1 - y            # y: 0 bottom .. 1 top
    rng = np.random.default_rng(seed)
    ph = rng.random(8)*6.28
    tp = 2*np.pi*t
    # wobble the whole flame sideways, more toward the top
    xw = x + 0.10*np.sin(tp + y*5 + ph[0])*y + 0.05*np.sin(2*tp + y*9 + ph[1])*y**1.5
    # base body: round bottom, narrowing up
    body = 0.42*np.sqrt(np.clip(1 - ((y-0.24)/0.22)**2, 0, 1))*(y < 0.24) + \
           0.42*(1 - np.clip((y-0.24)/0.6, 0, 1))**1.1*(y >= 0.24)
    f = body - np.abs(xw)
    # tongues: sharp spikes rising from the top, heights pulse over time
    for k in range(tongues):
        cx = (k - (tongues-1)/2)*0.32 + 0.05*np.sin(tp + ph[2+k])
        h = 0.62 + 0.28*(0.5+0.5*np.sin(tp + ph[3+k] + k*2.1)) + (0.12 if k == tongues//2 else 0)
        base_y = 0.35; w = 0.20 if k != tongues//2 else 0.26
        yy = np.clip((y - base_y)/(h - base_y), 0, 1)
        tongue = w*(1 - yy)**(1.6*sharp) * (y >= base_y) * (y <= h)
        lean = 0.12*np.sin(tp*1 + ph[5] + k)*yy**2
        f = np.maximum(f, tongue - np.abs(xw - cx - lean))
    # small detached flicker blob near the top
    by = 0.82 + 0.1*((t*1.0) % 1); bx = 0.15*np.sin(tp + ph[6])
    blob = 0.06*(1 - (t % 1)) - np.sqrt((xw-bx)**2 + ((y-by)*1.3)**2)
    f = np.maximum(f, blob)
    return f, y

def cel(f, y, soft=1.2):
    inside = f > 0
    # depth inside the flame -> bands (hard edges = cartoon look)
    d = np.clip(f/0.26, 0, 1)
    core = (d > 0.62) & (y < 0.62)
    mid = (d > 0.3)
    a = inside.astype(float)
    lum = np.where(core, 1.0, np.where(mid, 0.82, 0.62))*inside
    A = np.asarray(Image.fromarray((a*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(soft)), float)/255
    L = np.asarray(Image.fromarray((lum*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(soft*0.8)), float)/255
    L = np.where(A > 0.01, L/np.maximum(A, 1e-3), 0)
    return np.clip(L, 0, 1), A

def rgba(L, A, tint=None):
    if tint is None: rgb = np.dstack([L, L, L])
    else:
        t = np.array(tint, float)
        rgb = np.dstack([L*t[0] + (L > 0.95)*(1-t[0]), L*t[1] + (L > 0.95)*(1-t[1]), L*t[2] + (L > 0.95)*(1-t[2])])
    return Image.fromarray((np.dstack([np.clip(rgb, 0, 1), A])*255).astype(np.uint8), "RGBA")

# 1) single stylized flame (tintable)
f, y = flame_field(0.3, 1)
L, A = cel(f, y); rgba(L, A).save(f"{OUT}/flame.png"); rgba(L, A).save(f"{OUT}/flame_white.png")
# 2) 4x4 flipbook (16 frames, loops), 1024x1024
sheet = Image.new("RGBA", (1024, 1024))
for i in range(16):
    f, y = flame_field(i/16, 1)
    L, A = cel(f, y)
    sheet.paste(rgba(L, A), ((i % 4)*256, (i//4)*256))
sheet.save(f"{OUT}/flame_flipbook.png")
# 3) aura spike: thin sharp energy spike for anime 'ki' auras (flipbook too)
sheet = Image.new("RGBA", (1024, 1024))
for i in range(16):
    t = i/16
    yy, xx = (np.mgrid[0:F, 0:F] + 0.5)/F; xx = xx*2-1; yy = 1-yy
    xw = xx + 0.08*np.sin(2*np.pi*t + yy*6)*yy
    h = 0.75 + 0.2*np.sin(2*np.pi*t)
    w = 0.22*(1 - np.clip(yy/h, 0, 1))**1.4*(yy < h)*(yy > 0.04)
    f = w - np.abs(xw)
    L, A = cel(f*2.2, yy*0.6, 1.0)
    A = A*np.clip(yy/0.18, 0, 1)
    sheet.paste(rgba(L, A), ((i % 4)*256, (i//4)*256))
sheet.save(f"{OUT}/aura_flipbook.png")
print("ok")
