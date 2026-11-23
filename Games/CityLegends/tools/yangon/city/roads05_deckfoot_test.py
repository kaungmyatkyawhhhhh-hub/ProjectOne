"""self-check for the flyover-foot rules (21 Nov, owner's two pictures + "yellow where real life uses yellow"):
  * roads05_fix.deck_joints: a deck WITH side lanes keeps the road's gore width at its foot; a bridge without still
    narrows its road to the deck (J18)
  * roads05_fix.gore_medians: no kerbed median inside the gore flare of a sided deck
  * roads05_bake.gore_barriers: 6 yellow barriers on each deck edge line past each foot, none on a sideless deck
  * roads05_bake.strip_box: a deck box never takes the ground road's height under it
  * roads05_paint.centre_line: the centre line is two yellow lines
    YANGON_SCALE=1to1 python roads05_deckfoot_test.py"""
import copy
from shapely.geometry import LineString
import roads05_fix as F
import roads05_bake as B
import roads05_paint as PT


def row(z, y, half, med=0.0):
    return [0.0, y, float(z), 0.0, 1.0, 0, half, half, med, 2, 10.5, 0.0]


# a road along +z, samples 8 apart; the deck over samples 10..20 (cut 11..19), gore width 46 at both feet
road = dict(name='Main', s=[row(8 * i, 30.0, 46.0 if i in (10, 20) else 21.0, 5.0 if i >= 24 else 0.0) for i in range(40)])
deck = dict(name='Main Flyover', of='Main', half=24.0, sides=['Main #2', 'Main #3'], **{'from': 10, 'to': 20},
            s=[row(8 * i, 30.0 if i in (10, 20) else 50.0, 24.0) for i in range(10, 21)])
data = dict(roads=[road], decks=[deck], cut={'Main': list(range(11, 20))})

d = copy.deepcopy(data)
F.deck_joints(d)
assert d['roads'][0]['s'][10][6:8] == [46.0, 46.0] and d['roads'][0]['s'][20][6:8] == [46.0, 46.0], 'sided deck: gore kept'
d = copy.deepcopy(data)
d['decks'][0]['sides'] = []
F.deck_joints(d)
assert d['roads'][0]['s'][10][6:8] == [24.0, 24.0], 'bridge with no side lanes: road as wide as the deck (J18)'

d = copy.deepcopy(data)
assert F.gore_medians(d) > 0
s = d['roads'][0]['s']
assert all(q[8] == 0 for q in s if q[2] < 160 + F.GORE_REACH) and s[-1][8] == 5.0, 'median only past the flare'

g = B.gore_barriers(data)
assert len(g) == 2 * 2 * B.GORE_N, len(g)
assert all(abs(abs(p[2][0]) - 24.5) < 1e-6 and (p[2][2] < 80 or p[2][2] > 160) for p in g), 'on the edge lines, past the feet'
assert B.gore_barriers(dict(data, cut={'Main': list(range(0, 20))}))[0][2][2] > 160, 'no row where no ground road goes on'
assert B.gore_barriers(dict(data, decks=[dict(deck, sides=[])])) == []


class Ground:   # only a ground road (y 30) under the deck
    def heights(self, x, z):
        return [30.0]


a, b = row(0, 60.0, 24.0), row(16, 60.0, 24.0)
assert abs(float(B.strip_box(a, b, -24, 24, 'D', 0.0, Ground(), 2.0, prefer='max')[0].split()[2]) - 59.0) < 0.01, 'deck box at data height'
assert abs(float(B.strip_box(a, b, -24, 24, 'R', 0.0, Ground(), 2.0)[0].split()[2]) - 29.0) < 0.01, 'ground boxes as before'

P = PT.Paint()
PT.centre_line(P, LineString([(0, 0), (0, 40)]), 'centre', 'Main', None)
assert [it['k'] for it in P.items] == ['LY', 'LY'] and all(it['w'] == 'centre' for it in P.items), P.items
xs = sorted(sum(q[0] for q in it['p']) / len(it['p']) for it in P.items)
assert abs(xs[0] + 0.45) < 0.01 and abs(xs[1] - 0.45) < 0.01, xs
print('ok')
