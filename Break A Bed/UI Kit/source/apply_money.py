import money, art, shop3, freegift, aura2 as A
from PIL import Image
cache = {}
def pile(n, count=1):
    key = (n, count)
    if key not in cache:
        f = {1: money.cash1, 3: money.cash2, 5: money.cash3}[count]
        cache[key] = f(n)
    return cache[key]
art.cash_pile = pile
B = '/home/user/ProjectOne/Break A Bed/Ad Assets/thumbnail-1-break-a-bed.png'
shop3.main(B, 'shop3.png')
freegift.popup(B, 'free_popup.png'); freegift.billboard(B, 'free_chest.png')
# images
U = '/home/user/ProjectOne/Break A Bed/UI Kit/images/'
P = '/home/user/ProjectOne/Break A Bed/Product Icons/'
big = {'small': money.cash1(512), 'medium': money.cash2(512), 'big': money.cash3(512), 'bag': money.bag(512), 'safe': money.safe(512)}
for k, v in big.items(): v.save(U + f'money-{k}.png')
for k in ('small', 'medium', 'big'): big[k].save(U + f'art-cash-{k}.png')
big['small'].save(U + 'icon-cash.png')
# product pictures with the new money
import products as PR
PR.ic_orig = PR.ic
def ic2(kind, n):
    m = {'cash': big['small'], 'cashpile': big['medium'], 'bag': big['bag'], 'vault': big['safe'], 'cashbig': big['big']}
    return m[kind].resize((n, n), Image.LANCZOS) if kind in m else PR.ic_orig(kind, n)
PR.ic = ic2
import products2 as P2
P2.P.ic = lambda kind, n: P2.EXTRA[kind](n) if kind in P2.EXTRA and kind not in ('bag', 'vault') else ic2(kind, n)
for name, kw in [('small-cash', dict(bg='green', kind='cash', small='SMALL')),
                 ('x3-cash-10min', dict(bg='green', kind='cash', big='x3', small='10 MIN')),
                 ('x5-cash-10min', dict(bg='green', kind='cash', big='x5', small='10 MIN'))]:
    PR.make(**kw).save(P + name + '.png')
for name, kw in [('x2-cash-10min', dict(bg='green', kind='cash', big='x2', small='10 MIN')),
                 ('cash-pile', dict(bg='green', kind='cashpile', small='CASH PILE')),
                 ('cash-bag', dict(bg='cyan', kind='bag', small='CASH BAG')),
                 ('cash-vault', dict(bg='slate', kind='vault', small='CASH VAULT')),
                 ('pass-x2-cash', dict(bg='green', kind='cash', big='x2', small='FOREVER'))]:
    P2.make(ribbon_col='green' if kw.get('small') == 'FOREVER' else None, **kw).save(P + name + '.png')
print('ok')
import sim, hud
_orig = shop3.icon
def icon2(k, n): return money.cash1(n) if k == 'cash' else _orig(k, n)
shop3.icon = icon2; sim.icon = icon2
shop3.main(B, 'shop3.png'); sim.hud_main(B, 'sim_hud.png')
