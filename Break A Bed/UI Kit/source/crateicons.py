from PIL import Image, ImageDraw
import halloween as H, aura2 as A, kit, sim
N = 512
def make(count, tag):
    c = Image.new('RGBA', (N, N), (0,0,0,0))
    c.alpha_composite(sim.sbox(N, N, (130, 50, 170), radius=0.08, cell=22, stud=(22, 30)))
    sc = H.scene(N - 40, N - 40); m = Image.new('L', sc.size, 0); ImageDraw.Draw(m).rounded_rectangle((0,0,sc.width-1,sc.height-1), 24, fill=255)
    sc.putalpha(m); c.alpha_composite(sc, (20, 20))
    c.alpha_composite(A.burst(420, (255, 130, 30), 14, 80), (46, 10))
    if count == 1:
        c.alpha_composite(H.pumpkin(320), (96, 70))
    elif count == 3:
        c.alpha_composite(H.ghost(170), (40, 120)); c.alpha_composite(H.bats_art(170), (300, 110)); c.alpha_composite(H.pumpkin(260), (126, 60))
    else:
        c.alpha_composite(H.ghost(140), (30, 60)); c.alpha_composite(H.web(140), (340, 50)); c.alpha_composite(H.cursed(150), (40, 230))
        c.alpha_composite(H.reaper(160), (320, 220)); c.alpha_composite(H.pumpkin(260), (126, 70))
    A.stroke_text(c, (N/2, 360), f'x{count}', 120, (255, 220, 70), (255, 120, 10), ital=True, anchor='mm')
    rb = sim.sbox(330, 72, 'orange' if count != 10 else 'red', cell=12); A.stroke_text(rb, (165, 34), tag, 34, (255,255,255), (235,235,240), anchor='mm')
    c.alpha_composite(rb, ((N - 330)//2, N - 104))
    return A.bloom(c, 6, .2, 230)
D = '/home/user/ProjectOne/Break A Bed/Product Icons/'
for n, t in ((1, 'AURA CRATE'), (3, 'AURA CRATES'), (10, 'BEST VALUE')):
    make(n, t).save(D + f'aura-crate-x{n}.png')
sheet = Image.new('RGB', (3*330+10, 340), (24,26,34))
for i, n in enumerate((1, 3, 10)): sheet.paste(Image.open(D + f'aura-crate-x{n}.png').resize((320,320)), (10+i*330, 10), Image.open(D + f'aura-crate-x{n}.png').resize((320,320)))
sheet.save(D + '_aura-crates.png'); print('ok')
