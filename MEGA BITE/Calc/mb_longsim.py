"""MEGA BITE long-run kid simulation (13 Nov 2026): minute 5 to minute 90, on the LIVE numbers read from Studio.
It continues where mb_kidsim.py (the first 5 minutes) stops: the kids who are still there at 5:00 (47% at median patience).
A heuristic model, not real players. What it answers: how fast is each evolution now, what pays the EXP (fish, chests,
the Kraken, the turtle's slipstream, hunters), where do kids get bored, and what does a Megalodon do next.
Run: python mb_longsim.py"""
import math, random, statistics as st, json
from collections import Counter, defaultdict

EVO = [0, 25, 200, 620, 2400, 10000, 40000]            # GameConfig.Evolutions[i].exp
NAME = ['Minnow', 'Clownfish', 'Barracuda', 'Reef Shark', 'Hammerhead', 'Great White', 'Megalodon']
E = [7.0, 9.1, 16.0, 16.0, 22.1, 28.1, 40.0]            # EatLength = the source model's length
TOP = [24, 26, 33, 34, 36, 39, 46]
TOPSPAN = 20000
def span(e): return EVO[e] - EVO[e - 1] if e < 7 else TOPSPAN       # e = 1..7: EXP from this evolution to the next
FISH = {  # len, exp, school
 'Sardine': (3.5, 1, 7), 'Damsel': (4.0, 1, 2), 'Puffer': (4.2, 2, 1), 'Mackerel': (8.5, 3, 5), 'Shrimp': (2.5, 1, 6), 'Squid': (6.0, 4, 3),
 'Tuna': (12.0, 8, 4), 'KingMackerel': (19.6, 21, 3), 'ColossalSquid': (26.7, 39, 1), 'MonsterPuffer': (35.6, 70, 1), 'TitanTuna': (38.6, 82, 1),
 'EmperorPrawn': (60, 200, 1), 'AbyssSquid': (66, 240, 1), 'ElderTuna': (69, 270, 1), 'ThunderMackerel': (72, 290, 1)}
RINGS = {  # species weights (Fish.Pop.Tiers), zone EXP multiplier, hunters {length: count}, area in 0.5 M studs^2
 'reef':  (dict(Shrimp=10, Damsel=14, Puffer=9, Sardine=6), 1, {}, 0.56),
 'sea1':  (dict(Sardine=3, Mackerel=4, Squid=3, Puffer=1), 2, {16: 6}, 1.07),
 'sea2':  (dict(Mackerel=4, Squid=3, Tuna=3, KingMackerel=2), 2, {16: 3, 22.4: 5}, 1.62),
 'sea3':  (dict(Tuna=5, Squid=2, Mackerel=2, KingMackerel=3, ColossalSquid=2), 2, {22.4: 4, 35.1: 4, 42: 2}, 2.18),
 'sea4':  (dict(Tuna=4, KingMackerel=2, ColossalSquid=3, TitanTuna=3, MonsterPuffer=2, EmperorPrawn=1, AbyssSquid=1, ElderTuna=1, ThunderMackerel=1), 2, {35.1: 4, 42: 4, 54: 2}, 2.87),
 'titan': (dict(EmperorPrawn=3, AbyssSquid=3, ElderTuna=3, ThunderMackerel=3, TitanTuna=3, MonsterPuffer=2, KingMackerel=2, Tuna=2), 3, {54: 6, 42: 4, 35.1: 3}, 18.7),
}
ORDER = ['reef', 'sea1', 'sea2', 'sea3', 'sea4', 'titan']
GAP, MAXB = 58.0, 6
def bites(l, e): return math.ceil(l * l / (0.8 * E[e - 1]) ** 2)
def fish_rate(e, ring, P):
    """EXP per second for evolution e (1..7) feeding in a ring, and the species it can eat there."""
    spw, mult, preds, area = RINGS[ring]
    if ring == 'titan' and not P['titan']: return 0.0, []
    sp = dict(spw)
    if not P['colossal']:
        for k in ('EmperorPrawn', 'AbyssSquid', 'ElderTuna', 'ThunderMackerel'): sp.pop(k, None)
    W = sum(sp.values()); t = x = 0.0; can = []
    v = 0.7 * TOP[e - 1]
    for k, w in sp.items():
        l, ex, n = FISH[k]; b = bites(l, e); p = w / W
        if b <= MAXB:
            t += p * (GAP / v + n * (1.0 + (b - 1) * 0.6)); x += p * n * ex * mult; can.append(k)
        else:
            t += p * (GAP / v) * 0.5
    # hunters that can eat you: meetings per minute x the time one costs (flee about 12 s; if chomped, the swim back from the reef)
    RAD = {'reef': 150, 'sea1': 400, 'sea2': 615, 'sea3': 825, 'sea4': 1040, 'titan': 2100}[ring]
    loss = 0.0
    for L, c in preds.items():
        if L * 0.8 >= E[e - 1]:
            pc = 0.25 + (0.3 if L * 0.8 >= 2 * E[e - 1] else 0)
            loss += (0.18 * c / area) * (12 + pc * (RAD / v + 6)) / 60
    if ring == 'titan' and e < 6: return 0.0, []          # the way there is through the Red Trench: only the big sharks go
    return (x / t) * (1 - min(0.9, loss)) * P['skill_eff'], can

LM = {'Lighthouse': ('sea2', 0.08), 'CrystalArch': ('sea2', 0.08), 'WhaleArch': ('sea2', 0.11), 'OceanKing': ('sea3', 0.14), 'Galleon': ('sea4', 0.20)}
LIVE = dict(titan=True, colossal=True, chests=True, chest_refill_frac=1.0, chest_refill=900, kraken=True, kr_first=360, kr_every=600, kr_bite=0.005, kr_bonus=0.20,
            kr_hp_bites=60, turtle=True, turtle_base=1, turtle_per_evo=1, turtle_cap=None, hunters=True, giants_new=True, skill_eff=0.55, rush=1.2)
BEFORE = dict(LIVE, titan=False, colossal=False, chests=False, kraken=False, turtle=False, hunters=False, giants_new=False)

class Kid:
    def __init__(k, P, rng, pat):
        k.P, k.rng, k.pat = P, rng, pat
        k.t = 300.0; k.evo = rng.choices([2, 3, 4], [0.18, 0.47, 0.35])[0]      # where the first-5-minutes sim leaves them
        k.exp = EVO[k.evo - 1] + rng.random() * 0.5 * span(k.evo)
        k.bored = 0.0; k.last_new = 300.0; k.quit = None; k.src = defaultdict(float); k.evo_t = {}
        k.seen = set(); k.found = {}; k.mapkid = rng.random() < 0.3; k.exploit = rng.random() < 0.2
        k.next_kr = P['kr_first']; k.fossil = 0; k.meg_t = None; k.log = []; k.turtle_left = 0.0; k.turtle_used = 0.0; k.next_hunt = None
        k.titan_seen = False
    def mult(k): return 1 if k.fossil == 0 else 1.5 + 0.5 * k.fossil
    def gain(k, x, src):
        x *= k.mult(); k.exp += x; k.src[src] += x
        while k.evo < 7 and k.exp >= EVO[k.evo]:
            k.evo += 1; k.evo_t.setdefault((k.fossil, k.evo), k.t); k.new(60, 'evolve')
            if k.evo == 7 and k.meg_t is None: k.meg_t = k.t
    def new(k, amt, what):
        k.bored = max(0.0, k.bored - amt); k.last_new = k.t; k.log.append((round(k.t), what))
    def ring(k):
        best, br, bc = 'reef', 0, []
        for r in ORDER:
            x, can = fish_rate(k.evo, r, k.P)
            if x > br: best, br, bc = r, x, can
        if k.rng.random() < 0.3:                      # kids are not optimal: often one ring too close to home
            i = max(0, ORDER.index(best) - 1); x, can = fish_rate(k.evo, ORDER[i], k.P)
            if x > 0: best, br, bc = ORDER[i], x, can
        return best, br, bc
    def step(k, dt=10.0):
        P, rng = k.P, k.rng
        r, rate, can = k.ring()
        busy = 0.0
        # the Kraken (everyone gets the toast + the red light)
        if P['kraken'] and k.t >= k.next_kr:
            k.next_kr += P['kr_every']
            if rng.random() < (0.75 if k.evo >= 3 else 0.45):
                travel = rng.uniform(25, 80); fight = max(0, 90 - travel)
                nb = int(fight * 0.6 / 0.6 * rng.uniform(0.5, 1.0))
                won = nb >= P['kr_hp_bites']; nb = min(nb, P['kr_hp_bites'])
                if nb > 0:
                    k.gain(nb * P['kr_bite'] * span(k.evo), 'kraken')
                    if won and nb >= 3: k.gain(P['kr_bonus'] * span(k.evo), 'kraken')
                    k.new(55 if won else 35, 'kraken'); busy = travel + fight
        # landmarks: discovery (once) and chests (refill)
        if P['chests'] and busy == 0:
            for name, (lr, share) in LM.items():
                reach = ORDER.index(lr) <= ORDER.index(r) + (1 if k.mapkid else 0)
                if name not in k.found:
                    if reach and rng.random() < (0.035 if k.mapkid else 0.018) * dt / 10:
                        k.found[name] = k.t + P['chest_refill']
                        k.gain(2 * share * span(k.evo), 'chest'); k.new(45, 'landmark'); busy = 40; break
                elif k.t >= k.found[name] and reach and rng.random() < (0.05 if k.mapkid else 0.012) * dt / 10:
                    k.found[name] = k.t + P['chest_refill']
                    k.gain(share * span(k.evo) * P['chest_refill_frac'], 'chest'); k.new(14, 'chest'); busy = 45; break
        # the turtle's slipstream (N side of rings 1-2)
        if P['turtle'] and busy == 0 and r in ('sea1', 'sea2', 'sea3'):
            tr = (P['turtle_base'] + P['turtle_per_evo'] * k.evo)
            if k.turtle_left <= 0 and rng.random() < 0.012 * dt / 10:
                k.turtle_left = 1e9 if (k.exploit and tr * (1 if P['turtle_cap'] is None else 0) > rate) else rng.lognormvariate(math.log(35), 0.5)
                if 'turtle' not in k.seen: k.seen.add('turtle'); k.new(30, 'turtle')
            if k.turtle_left > 0:
                if P['turtle_cap'] is not None and k.turtle_used >= P['turtle_cap']: k.turtle_left = 0
                else:
                    k.gain(tr * dt, 'turtle'); k.turtle_left -= dt; k.turtle_used += dt; busy = dt
                    if tr <= rate and k.turtle_left > 1e6: k.turtle_left = 0
        # scenery giants seen for the first time (whale passes every ring; the eel at the Ocean King)
        if P['giants_new'] and busy == 0 and r != 'reef':
            for g, p in (('whale', 0.02), ('eel', 0.006 if r in ('sea3', 'sea4') else 0)):
                if g not in k.seen and rng.random() < p * dt / 10: k.seen.add(g); k.new(30, g)
        # red hunters for the big sharks
        if P['hunters'] and k.evo >= 6 and r in ('sea1', 'sea2', 'sea3', 'sea4'):
            if k.next_hunt is None: k.next_hunt = k.t + 75
            if k.t >= k.next_hunt:
                k.next_hunt = k.t + 210
                if rng.random() < 0.5: k.gain(2500 if k.evo == 6 else 14400, 'hunters'); k.new(30, 'hunt won')
                else: k.new(12, 'hunted')
                busy = 40
        # idea: landmarks with chests in the Titan Sea
        if P.get('titan_lm') and r == 'titan' and busy == 0:
            for name in ('TitanLM1', 'TitanLM2')[:P['titan_lm']]:
                if name not in k.found and rng.random() < 0.03 * dt / 10:
                    k.found[name] = k.t + P['chest_refill']; k.gain(0.3 * TOPSPAN, 'chest'); k.new(45, 'landmark'); busy = 40; break
        # the Titan Sea
        if P['titan'] and r == 'titan' and not k.titan_seen: k.titan_seen = True; k.new(70, 'titan sea')
        # eating
        if busy < dt:
            k.gain(rate * P['rush'] * (dt - busy), 'fish')
            for s in can:
                if s not in k.seen and rng.random() < 0.08 * dt / 10: k.seen.add(s); k.new(14, 'new fish'); break
        # boredom
        f = 0.5 if busy == 0 else 0.3                    # feeding = 'chase' / 'guided' in the first-5-minutes model
        nxt = EVO[k.evo] if k.evo < 7 else None
        if nxt:
            prog = (k.exp - EVO[k.evo - 1]) / span(k.evo)
            eta = (nxt - k.exp) / max(rate * P['rush'] * k.mult(), 1e-6)
            if prog > 0.7: f *= 0.7
            if eta > 600: f *= 1.25
            if eta > 1500: f *= 1.25
        elif P.get('meg_levels'):                         # idea: TITAN LEVELS, a bar that keeps filling for a Megalodon
            lv = int((k.exp - EVO[6]) // TOPSPAN)
            if lv > getattr(k, 'lv', 0): k.lv = lv; k.new(40, 'titan level')
            if ((k.exp - EVO[6]) % TOPSPAN) / TOPSPAN > 0.7: f *= 0.7
        else: f *= 1.5                                   # a Megalodon has no bar to fill
        if k.t - k.last_new > 120: f *= 1.4
        elif k.t - k.last_new < 45: f *= 0.6
        k.bored += f * dt
        k.t += dt
        if k.bored > k.pat:
            if k.evo == 7 and k.fossil < 3 and rng.random() < 0.6:      # FOSSILIZE: back to a Minnow with more EXP
                k.fossil += 1; k.evo = 1; k.exp = 0; k.new(k.pat, 'fossilize'); k.seen.discard('x')
            else: k.quit = k.t

def sim(P, n=3000, pat_med=210, seed=3, T=5400):
    rng = random.Random(seed); kids = []
    for _ in range(n):
        k = Kid(P, rng, pat_med * math.exp(rng.gauss(0, 0.6)))
        while k.t < T and k.quit is None: k.step()
        kids.append(k)
    out = {}
    for m in (10, 15, 20, 30, 45, 60, 90): out['stay%d' % m] = round(100 * sum(1 for k in kids if k.quit is None or k.quit > m * 60) / n, 1)
    for e in (4, 5, 6, 7):
        ts = [k.evo_t[(0, e)] for k in kids if (0, e) in k.evo_t]
        out['evo%d' % e] = (round(100 * len(ts) / n), round(st.median(ts) / 60, 1) if ts else None)
    tot = defaultdict(float)
    for k in kids:
        for s, x in k.src.items(): tot[s] += x
    S = sum(tot.values()); out['exp_share'] = {s: round(100 * x / S) for s, x in sorted(tot.items(), key=lambda q: -q[1])}
    megs = [k for k in kids if k.meg_t]
    if megs:
        after = [(k.quit or T) - k.meg_t for k in megs if k.fossil == 0 or True]
        out['meg_minutes_after'] = round(st.median([( (next((t for t, w in k.log if w == 'fossilize'), None) or (k.quit or T)) - k.meg_t) for k in megs]) / 60, 1)
        out['meg_fossil_pct'] = round(100 * sum(1 for k in megs if k.fossil > 0) / len(megs))
        out['meg_titan_pct'] = round(100 * sum(1 for k in megs if k.titan_seen) / len(megs))
    out['quit_evo'] = Counter(NAME[k.evo - 1] for k in kids if k.quit is not None).most_common(4)
    return out, kids

if __name__ == '__main__':
    print('fish EXP per minute by evolution and ring (live numbers, a kid at 55% efficiency, Gold Rush on):')
    for e in range(2, 8):
        print(' ', NAME[e - 1].ljust(11), ' '.join('%s %5.0f' % (r, fish_rate(e, r, LIVE)[0] * 60 * 1.2) for r in ORDER), '| span', span(e))
    # calibrate patience on the game BEFORE today (fish only): about 45% of the kids at 5:00 are still there at 15:00
    for pm in (110, 150, 200, 260):
        r, _ = sim(BEFORE, pat_med=pm); print('calibrate pat', pm, 'stay15', r['stay15'], 'stay30', r['stay30'])
