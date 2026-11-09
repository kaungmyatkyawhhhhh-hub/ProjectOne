"""Impatient-kid simulation of Galaxy Incremental's first minutes.
Economy = the LIVE EconConfig/GameConfig (Studio, 9 Nov). A 'kid' follows the arrow, taps the cheapest green button,
catches some comets, and has a boredom meter that fills every second nothing new happens and drops on rewarding
moments. When it passes the kid's patience, the kid quits. A heuristic model, not real players."""
import math, random, statistics, copy, sys, json
PAT = [11]

LIVE = dict(
    start_stardust=0, start_xp=2,
    cost_base=10, cost_tier=8, level_growth=1.8,
    copy_base=50, copy_growth=4,
    unlocks=[80, 640, 5120],
    pads=[15, 60, 150, 400, 1200, 3000, 8000, 20000, 60000, 150000],
    pad_bonus_idx={2, 5, 8}, pad_bonus=1.15,
    early_discount=None,          # (levels, mult) cheaper first asteroid levels
    comet_first=20, comet_every=20, comet_value=(30, 60), comet_golden=0.1, comet_golden_x=5,
    xp_mult=1.3, xp_floor=0.12, xp_until=5,
    tut_pay_sec=20, tut_pay_min=10,
    welcome_gift=0,               # stardust given with a fanfare at t=welcome_at
    welcome_at=2,
    first_buy_free=False,
    gift_at=150, gift_boost_sec=300,
    asteroid_income=1.0,
    big_pop=1.0,                  # how strong purchase feedback is (1 = live juice)
    next_bar=True,                # the HUD NEXT goal bar (live since 9 Nov)
    auto_moon_reveal=False,       # LUMI shows the Moon flying in when it's affordable
    tap_burst=0,                  # stardust per tap on the asteroid (0 = no tapping)
    tap_cooldown=0.25,
)

TUT = [("own", 0, 3), ("perk", "FirstLight", 1), ("pads", 1), ("unlock", 1), ("copy", 0, 2), ("comets", 2),
       ("unlock", 2), ("pads", 4), ("level", 3), ("unlock", 3), ("own", 0, 10)]

def xp_for_level(n):  # total XP to reach level n
    return 8 * (1.3 ** (n - 1) - 1) / 0.3

class Game:
    def __init__(s, P, rng):
        s.P, s.rng = P, rng
        s.sd = P['start_stardust']; s.lv = [1, 0, 0, 0]; s.cp = [1, 0, 0, 0]
        s.unl = [True, False, False, False]; s.pads = 0
        s.xp_total = P['start_xp']; s.xp = P['start_xp']; s.perks = {'FirstLight': 0, 'Stardust': 0}
        s.tut = 0; s.comets = 0; s.boost_until = -1; s.gift_done = False
        s.earned = 0.0; s.need = 2.5e5; s.novas = 0

    def level(s):
        n = 1
        while s.xp_total >= xp_for_level(n + 1): n += 1
        return n

    def income(s, t):
        tot = 0
        for k in range(4):
            if s.lv[k] > 0:
                tier = s.lv[k] // 10
                inc = (5 ** k) * s.lv[k] * max(s.cp[k], 1) * (2 ** tier)
                if k == 0: inc *= s.P['asteroid_income'] * (1 + 0.5 * s.perks['FirstLight'])
                tot += inc
        tot *= 1 + 0.1 * s.perks['Stardust']
        for i in range(s.pads):
            if i in s.P['pad_bonus_idx']: tot *= s.P['pad_bonus']
        if t < s.boost_until: tot *= 2
        return tot

    def up_cost(s, k):
        c = s.P['cost_base'] * s.P['cost_tier'] ** k * s.P['level_growth'] ** s.lv[k]
        ed = s.P['early_discount']
        if ed and k == 0 and s.lv[0] < ed[0]: c *= ed[1]
        return c

    def options(s):
        o = []
        for k in range(4):
            if s.unl[k]:
                o.append(('up', k, s.up_cost(k)))
                if s.cp[k] < 5:
                    cc = s.P['copy_base'] * 8 ** k * 4 ** (s.cp[k] - 1)
                    if k == 0 and s.cp[0] == 1 and s.P.get('first_copy'): cc = s.P['first_copy']
                    o.append(('copy', k, cc))
            elif k > 0 and s.unl[k - 1]:
                o.append(('unlock', k, s.P['unlocks'][k - 1]))
        if s.pads < len(s.P['pads']): o.append(('pad', s.pads, s.P['pads'][s.pads]))
        return o

    def tut_target(s):
        if s.tut >= len(TUT): return None
        st = TUT[s.tut]
        if st[0] == 'own': return ('up', st[1])
        if st[0] == 'pads': return ('pad', None)
        if st[0] == 'unlock': return ('unlock', st[1])
        if st[0] == 'copy': return ('copy', st[1])
        return None

    def tut_done(s):
        if s.tut >= len(TUT): return False
        st = TUT[s.tut]
        return ((st[0] == 'own' and s.lv[st[1]] >= st[2]) or (st[0] == 'perk' and s.perks[st[1]] >= st[2])
                or (st[0] == 'pads' and s.pads >= st[1]) or (st[0] == 'unlock' and s.unl[st[1]])
                or (st[0] == 'copy' and s.cp[st[1]] >= st[2]) or (st[0] == 'comets' and s.comets >= st[1])
                or (st[0] == 'level' and s.level() >= st[1]))


def run_kid(P, rng, T=300, dt=0.25, log=False):
    g = Game(P, rng)
    patience = min(35, max(5, rng.lognormvariate(math.log(PAT[0]), 0.45)))   # impatient kids: median ~11 s of dead time
    catch_p = rng.uniform(0.45, 0.9)
    react = lambda: rng.uniform(0.6, 2.2)
    taps_rate = rng.uniform(2, 5)  # taps per second when there's something to tap
    B = 0.0; t = 0.0; next_act = react(); next_comet = P['comet_first']; same = {}; events = []
    last_lvl = g.level(); welcomed = False

    nrew = {'n': 0, 'last_new': 0.0}
    def reward(amount, what):
        nonlocal B
        nrew['n'] += 1
        new = any(w in what for w in ('unlock', 'pad', 'copy', 'GIFT', 'WELCOME', 'LEVEL', 'TIER', 'SUPERNOVA'))
        if new: nrew['last_new'] = t
        hab = 0.992 ** nrew['n'] if not new else 0.997 ** nrew['n']
        B = max(0.0, B - amount * P['big_pop'] * hab)
        if log: events.append((round(t, 1), what, round(g.sd), round(g.income(t), 1)))

    while t < T:
        inc = g.income(t)
        g.sd += inc * dt; g.earned += inc * dt
        if g.earned >= g.need and t >= next_act:
            g.novas += 1; g.need = 1.8e6 if g.novas == 1 else g.need * 6
            g.sd = 0; g.earned = 0; g.lv = [1, 0, 0, 0]; g.cp = [1, 0, 0, 0]; g.unl = [True, False, False, False]
            reward(25, f'SUPERNOVA {g.novas}'); next_act = t + react()
        # XP
        xr = 0.12 * math.log10(1 + inc) ** 1.5
        if g.level() < P['xp_until']: xr = max(xr * P['xp_mult'], P['xp_floor'])
        g.xp_total += xr * dt; g.xp += xr * dt
        if g.level() > last_lvl:
            last_lvl = g.level(); reward(4, f'LEVEL {last_lvl}')
        if P['welcome_gift'] and not welcomed and t >= P['welcome_at']:
            welcomed = True; g.sd += P['welcome_gift']; reward(5, 'WELCOME GIFT')
        if not g.gift_done and t >= P['gift_at']:
            g.gift_done = True; g.boost_until = t + P['gift_boost_sec']; reward(8, 'GIFT 2x')
        # comets
        # (live: no comets during tutorial steps 1-5; step 6 = tutorial comets every ~15.5 s until 2 caught;
        #  then regular comets 20 s later, every 20 s in run 1. P['comet_early'] = the design option of comets from t)
        if P.get('comet_early') is None and g.tut < 5:
            next_comet = t + 2.5
        elif P.get('comet_early') is None and g.tut == 5:
            if t >= next_comet:
                next_comet = t + 15.5
                if rng.random() < 0.9:
                    v = rng.uniform(*P['comet_value']) * max(inc, 1); g.sd += v; g.earned += v; g.comets += 1; reward(6, 'COMET')
            reg_started = False
        elif t >= next_comet:
            next_comet = t + P['comet_every']
            if rng.random() < catch_p:
                v = rng.uniform(*P['comet_value']) * max(inc, 1)
                if rng.random() < P['comet_golden']: v *= P['comet_golden_x']
                g.sd += v; g.earned += v; g.comets += 1; reward(6, 'COMET')
        # tapping (if the design has it): a kid with nothing to buy taps
        if P['tap_burst'] > 0:
            g.sd += P['tap_burst'] * min(taps_rate, 1 / P['tap_cooldown']) * dt
            B = max(0.0, B - 0.35 * dt * P['big_pop'])  # tapping is mildly fun, not a cure
        # act
        if t >= next_act:
            next_act = t + react()
            # free perk
            if g.xp >= 2 * 1.6 ** g.perks['FirstLight'] and g.perks['FirstLight'] < 10:
                g.xp -= 2 * 1.6 ** g.perks['FirstLight']; g.perks['FirstLight'] += 1; reward(5, 'PERK FirstLight')
            elif g.xp >= 2 * 1.6 ** g.perks['Stardust'] and g.perks['Stardust'] < 10 and g.perks['FirstLight'] >= 1:
                g.xp -= 2 * 1.6 ** g.perks['Stardust']; g.perks['Stardust'] += 1; reward(4, 'PERK Stardust')
            else:
                opts = [o for o in g.options() if o[2] <= g.sd]
                tgt = g.tut_target()
                pick = None
                if tgt:
                    for o in opts:
                        if o[0] == tgt[0] and (tgt[1] is None or o[1] == tgt[1]): pick = o
                if not pick and opts:
                    pick = min(opts, key=lambda o: o[2])
                if pick:
                    kind, k, c = pick
                    if kind == 'pad': next_act += rng.uniform(3, 6)   # pads are walked onto (step-on pads)
                    if P['first_buy_free'] and not same: c = 0
                    g.sd -= c
                    key = (kind, k); same[key] = same.get(key, 0) + 1
                    before = inc
                    if kind == 'up':
                        old_tier = g.lv[k] // 10; g.lv[k] += 1
                        rw = 3.5 * 0.88 ** (same[key] - 1) + 1
                        if g.lv[k] // 10 > old_tier: rw += 10; kind = 'up TIER'
                    elif kind == 'copy': g.cp[k] += 1; rw = 8
                    elif kind == 'unlock': g.unl[k] = True; g.lv[k] = 1; g.cp[k] = 1; rw = 12
                    else: g.pads += 1; rw = 9
                    after = g.income(t)
                    if after >= 1.5 * max(before, 0.1): rw += 3
                    reward(rw, f'BUY {kind} {k}')
        paid = False
        while g.tut_done():
            g.tut += 1
            if not paid: g.sd += max(P['tut_pay_min'], g.income(t) * P['tut_pay_sec'])
            paid = True; reward(4, f'TUT STEP {g.tut}')
            if g.tut == 6 and P.get('comet_early') is None: next_comet = t + P['comet_first']
        # boredom
        opts_now = [o for o in g.options()]
        cheapest = min((o[2] for o in opts_now), default=1e18)
        wait = (cheapest - g.sd) / max(g.income(t), 1e-6)
        rate = 1.0
        if wait <= 0: rate = 0.5          # something to press right now
        elif P['next_bar'] and wait < 8: rate = 0.7   # a bar visibly about to fill
        elif wait > 30: rate = 1.4        # nothing in reach: "this is boring"
        if t - nrew['last_new'] > 25: rate *= 1.3   # nothing NEW for a while
        B += rate * dt
        if B >= patience:
            return t, events, patience
        t += dt
    return T, events, patience


def evaluate(P, n=3000, seed=1):
    rng = random.Random(seed)
    qt = []; firsts = []; gaps = []
    for _ in range(n):
        q, ev, _p = run_kid(P, rng, log=True)
        qt.append(q)
        buys = [e[0] for e in ev if e[1].startswith('BUY')]
        firsts.append(buys[0] if buys else 999)
        pts = [0.0] + [e[0] for e in ev if e[0] <= 60] + [min(60, q)]
        gaps.append(max(b - a for a, b in zip(pts, pts[1:])))
    res = {f'stay{s}': round(100 * sum(q >= s for q in qt) / n, 1) for s in (15, 30, 60, 120, 180, 300)}
    res['median_quit'] = round(statistics.median(qt), 1)
    res['mean_play'] = round(statistics.mean(qt), 1)
    res['first_buy_med'] = round(statistics.median(firsts), 1)
    res['gap60_med'] = round(statistics.median(gaps), 1)
    return res


def timeline(P, seed=7):
    rng = random.Random(seed)
    # a patient kid so we see the whole first 3 minutes
    while True:
        r = run_kid(P, rng, log=True)
        if r[0] >= 300: return r[1]
