import sys, statistics as st, math, random
from mb_longsim import *
def megs(P, pm=135, n=3000, seed=5):
    rng = random.Random(seed); out = []; act = Counter()
    for _ in range(n):
        k = Kid(P, rng, pm * math.exp(rng.gauss(0, 0.6)))
        k.t = 0; k.last_new = 0; k.evo = 7; k.exp = 40000; k.meg_t = 0; k.found = {n2: 1e9 for n2 in LM}; k.seen = set(FISH) - {'EmperorPrawn', 'AbyssSquid', 'ElderTuna', 'ThunderMackerel'} | {'turtle', 'whale', 'eel'}
        k.next_kr = rng.uniform(0, 600)
        while k.t < 3600 and k.quit is None and k.fossil == 0: k.step()
        out.append(k.t / 60); act['fossilize' if k.fossil else 'quit'] += 1
        for t, w in k.log: act[w] += 1
    return round(st.median(out), 1), round(sum(1 for x in out if x >= 10) * 100 / n), dict(act)
for name, P in (('Megalodon before today (no Titan Sea, no colossal fish, no hunters, no Kraken)', dict(BEFORE)),
                ('+ Kraken + chests + giants (this morning)', dict(LIVE, titan=False, colossal=False, hunters=False)),
                ('+ red hunters', dict(LIVE, titan=False, colossal=False)),
                ('+ colossal fish in the Far Deep', dict(LIVE, titan=False)),
                ('+ the Titan Sea (live now)', dict(LIVE)),
                ('idea 1: live + TITAN LEVELS (a bar for the Megalodon)', dict(LIVE, meg_levels=True)),
                ('idea 2: live + 2 landmarks with chests in the Titan Sea', dict(LIVE, titan_lm=2)),
                ('ideas 1 + 2', dict(LIVE, meg_levels=True, titan_lm=2))):
    m, p10, act = megs(P)
    print(name.ljust(80), 'median minutes as a Megalodon', m, '| still a Megalodon at 10 min %', p10, '| new things each:', {k: round(v / 3000, 2) for k, v in act.items() if k in ('titan sea', 'new fish', 'kraken', 'hunt won', 'hunted', 'chest', 'titan level', 'landmark')}, '| fossilize %', round(act['fossilize'] / 60))
