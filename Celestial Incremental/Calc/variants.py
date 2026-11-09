from kidsim import *
V = {}
V['A live'] = dict(LIVE)
B = dict(LIVE, welcome_gift=30, welcome_at=1.5); V['B +30 welcome gift'] = B
C = dict(B, pads=[5, 25, 80] + LIVE['pads'][3:]); V['C B+cheap pads 1-3'] = C
D = dict(C, early_discount=(5, 0.5)); V['D C+asteroid Lv1-5 half price'] = D
E = dict(D, comet_early=True, comet_first=8, comet_every=15); V['E D+comets from 8s (every 15s)'] = E
F = dict(E, first_copy=25); V['F E+2nd asteroid 25'] = F
if __name__ == "__main__":
    for k, p in V.items(): print(k.ljust(34), evaluate(p, n=1500))
