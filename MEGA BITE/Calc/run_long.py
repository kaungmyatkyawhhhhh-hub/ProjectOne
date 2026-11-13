import json, sys
sys.argv = ['x']
from mb_longsim import *
PAT = 135
def show(name, P, pm=PAT):
    r, kids = sim(P, pat_med=pm)
    print(name.ljust(46), 'stay 10/15/20/30/45/60:', r['stay10'], r['stay15'], r['stay20'], r['stay30'], r['stay45'], r['stay60'])
    print('    reach (pct, median min): Reef Shark', r['evo4'], 'Hammerhead', r['evo5'], 'Great White', r['evo6'], 'Megalodon', r['evo7'])
    print('    EXP from:', r['exp_share'], '| Megalodon: min until fossilize/quit', r.get('meg_minutes_after'), 'fossilized %', r.get('meg_fossil_pct'), 'saw Titan Sea %', r.get('meg_titan_pct'))
    print('    quits as:', r['quit_evo'])
    return r
res = {}
res['before'] = show('A  before today (fish only)', BEFORE)
res['live'] = show('B  live today', LIVE)
res['no_kraken'] = show('   live without the Kraken', dict(LIVE, kraken=False))
res['no_chests'] = show('   live without chests', dict(LIVE, chests=False))
res['no_turtle'] = show('   live without the turtle EXP', dict(LIVE, turtle=False))
C1 = dict(LIVE, turtle_cap=45)
res['c1'] = show('C  B + slipstream pays 45 s per shark', C1)
C2 = dict(C1, kr_bite=0.002, kr_bonus=0.08)
res['c2'] = show('D  C + Kraken: 0.2% a bite, 8% bonus', C2)
C3 = dict(C2, chest_refill_frac=0.35)
res['c3'] = show('E  D + refilled chest pays 35%', C3)
for pm in (90, 200):
    res['live_%d' % pm] = show('B  live, patience %d' % pm, LIVE, pm); res['e_%d' % pm] = show('E  tuned, patience %d' % pm, C3, pm)
json.dump(res, open('long_out.json', 'w'), default=str)
