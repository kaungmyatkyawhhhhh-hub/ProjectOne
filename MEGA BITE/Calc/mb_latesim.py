"""MEGA BITE late-game kid simulation (13 Nov 2026, evening): a fresh Megalodon kid (no Fossil, no pass) from the moment it
becomes a Megalodon, on the LIVE numbers read from Studio after the owner's AFK work order: 10 evolutions (Dunkleosteus,
Mosasaurus, Leviathan), the Kraken as the late-game boss in the Titan Sea (Megalodon+ only, every 10 min, 60 own bites to
beat it alone, 0.5% of the span a bite, 20% bonus + 12 s Gold Rush), the Titan's Gate chest (25% of the span, refill 15 min),
red titans in the Titan Sea (MB_PredatorServer), Titan Levels only for the TOP evolution, FOSSILIZE from the Megalodon on.
Fish EXP per minute comes from mb_longsim.fish_rate (Titan Sea, 55% kid, Gold Rush 1.2).
Boredom: the same meter as mb_longsim (a long bar = faster boredom; a NEW thing resets part of it). Patience calibrated in
round 7 (median 135 'boredom seconds' for the late game).  Run: python mb_latesim.py"""
import math, random, statistics as st
from collections import Counter
import mb_longsim as L
L.E = [7.0, 9.1, 16.0, 16.0, 22.1, 28.1, 40.0, 46.1, 52.7, 57.4]
L.TOP = [24, 26, 33, 34, 36, 39, 46, 48, 52, 54]
NAMES = ['Minnow', 'Clownfish', 'Barracuda', 'Reef Shark', 'Hammerhead', 'Great White', 'Megalodon', 'Dunkleosteus', 'Mosasaurus', 'Leviathan']

def run(EVO, n=3000, pm=135, seed=7, T=5400, kraken=True, gate=True, hunters=True, levels=True, fossil_at=7, titan_span=20000, kr_alone=60, levels_all=False, grow=0.08):
    TOPE = len(EVO)
    def span(e): return EVO[e] - EVO[e - 1] if e < TOPE else titan_span
    rate = {e: L.fish_rate(e, 'titan', L.LIVE)[0] * 1.2 for e in range(7, TOPE + 1)}   # EXP per second (13 Nov fix: was divided by 60 again)
    rng = random.Random(seed); res = []; act = Counter(); reach = Counter(); tto = {e: [] for e in range(8, TOPE + 1)}
    for _ in range(n):
        pat = pm * math.exp(rng.gauss(0, 0.6)); t = 0.0; e = 7; x = EVO[6]; bored = 0.0; last_new = 0.0
        next_kr = rng.uniform(0, 600); gate_at = 0.0 if gate else 1e9; hunt_at = 75.0; lv = 0; out = 'time'
        while t < T:
            dt = 10.0; busy = 0.0
            def gain(v):
                nonlocal x, e, last_new, bored
                x += v
                while e < TOPE and x >= EVO[e]:
                    e += 1; reach[e] += 1; tto[e].append(t / 60); bored = max(0, bored - 60); last_new = t; act['evolve'] += 1
            if kraken and t >= next_kr:
                next_kr += 600
                if rng.random() < 0.8:
                    travel = rng.uniform(15, 50); fight = 90 - travel; nb = int(fight * rng.uniform(0.5, 1.0) / 0.9)
                    won = nb >= kr_alone or rng.random() < 0.35          # other big sharks help on a full server
                    gain(min(nb, kr_alone) * 0.005 * span(e))
                    if won: gain(0.2 * span(e)); act['kraken won'] += 1
                    bored = max(0, bored - (55 if won else 35)); last_new = t; busy = 90
            if gate and busy == 0 and t >= gate_at and rng.random() < 0.02:
                gate_at = t + 900; gain(0.25 * span(e)); bored = max(0, bored - (45 if act['gate'] == 0 else 14)); last_new = t; busy = 40; act['gate'] += 1
            if hunters and busy == 0 and t >= hunt_at:
                hunt_at = t + 210
                if rng.random() < 0.5: gain(14400); bored = max(0, bored - 30); act['hunt won'] += 1
                else: bored = max(0, bored - 12)
                last_new = t; busy = 40
            gain(rate[e] * max(0.0, dt - busy))          # rate = EXP per SECOND (mb_longsim.fish_rate); no fish while fighting
            # boredom (as mb_longsim)
            f = 0.5
            if levels_all and e >= 7:                     # TITAN LEVELS for every shark from the Megalodon on (level L needs 20K x (1 + 8% x L) more)
                over = x - EVO[6]; l2 = 0; need = titan_span
                while over >= need: over -= need; l2 += 1; need = titan_span * (1 + grow * l2)
                if l2 > lv: lv = l2; bored = max(0, bored - 40); last_new = t; act['titan level'] += 1
                eta = (need - over) / max(rate[e], 1e-6)
                if over / need > 0.7: f *= 0.7
                if eta > 600: f *= 1.25
                if eta > 1500: f *= 1.25
            elif e < TOPE:
                prog = (x - EVO[e - 1]) / span(e); eta = (EVO[e] - x) / max(rate[e], 1e-6)
                if prog > 0.7: f *= 0.7
                if eta > 600: f *= 1.25
                if eta > 1500: f *= 1.25
            elif levels:
                over = x - EVO[TOPE - 1]; l2 = int(over // titan_span)
                if l2 > lv: lv = l2; bored = max(0, bored - 40); last_new = t; act['titan level'] += 1
                if (over % titan_span) / titan_span > 0.7: f *= 0.7
            else: f *= 1.5
            if t - last_new > 120: f *= 1.4
            elif t - last_new < 45: f *= 0.6
            bored += f * dt; t += dt
            if bored > pat:
                out = 'fossilize' if (e >= fossil_at and rng.random() < 0.6) else 'quit'; break
        res.append(t / 60); act[out] += 1; act['end as ' + NAMES[e - 1]] += 1
    r = dict(median_min=round(st.median(res), 1), at10=round(100 * sum(v >= 10 for v in res) / n), at20=round(100 * sum(v >= 20 for v in res) / n),
             at30=round(100 * sum(v >= 30 for v in res) / n), at60=round(100 * sum(v >= 60 for v in res) / n), fossil=round(100 * act['fossilize'] / n))
    for e2 in range(8, TOPE + 1):
        r['reach_' + NAMES[e2 - 1]] = (round(100 * reach[e2] / n), round(st.median(tto[e2]), 1) if tto[e2] else None)
    r['ends'] = {k[7:]: round(100 * v / n) for k, v in act.items() if k.startswith('end as ')}
    return r

if __name__ == '__main__':
    import json
    print('Titan Sea fish EXP/min (55% kid, Gold Rush):', {NAMES[e - 1]: round(L.fish_rate(e, 'titan', L.LIVE)[0] * 72) for e in range(7, 11)})
    LIVEV = [0, 25, 200, 620, 2400, 10000, 40000, 160000, 520000, 1500000]
    V = {}
    V['A this morning (Megalodon top + Titan Levels)'] = run([0, 25, 200, 620, 2400, 10000, 40000], gate=False)
    V['B noon: + Dunkleosteus 160K (levels only for the top)'] = run(LIVEV[:8])
    V['C live now: 160K / 520K / 1.5M, levels only for the top'] = run(LIVEV)
    V['G = C + Titan Levels for every shark from the Megalodon'] = run(LIVEV, levels_all=True)
    V['H = G + EXP lines 100K / 220K / 420K  (LIVE from 13 Nov evening)'] = run([0, 25, 200, 620, 2400, 10000, 40000, 100000, 220000, 420000], levels_all=True)
    V['I = G + EXP lines 90K / 180K / 320K'] = run([0, 25, 200, 620, 2400, 10000, 40000, 90000, 180000, 320000], levels_all=True)
    V['H without the Kraken'] = run([0, 25, 200, 620, 2400, 10000, 40000, 100000, 220000, 420000], levels_all=True, kraken=False)
    V['H, patience 90'] = run([0, 25, 200, 620, 2400, 10000, 40000, 100000, 220000, 420000], levels_all=True, pm=90)
    V['H, patience 200'] = run([0, 25, 200, 620, 2400, 10000, 40000, 100000, 220000, 420000], levels_all=True, pm=200)
    for k, v in V.items(): print(k.ljust(58), v)
    json.dump(V, open('late_out.json', 'w'), indent=1)
