"""MEGA BITE impatient-kid simulation of the first 5 minutes (12 Nov 2026, night).
Economy = the LIVE GameConfig read from Studio after the first-minute pass 1. A heuristic model, not real players:
a kid who may not know the controls, swims to fish (helped by the hint / EAT marker / ground arrows), chases and eats,
travels between schools, follows the quest card, and has a boredom meter that rises every second nothing happens and
drops on rewards (bites wear off, NEW things don't). It quits when boredom passes its patience."""
import math, random, statistics, sys, json

# ---- LIVE numbers (Studio 12 Nov 23:50) ----
LIVE = dict(
    evo_exp=[0, 25, 200, 620],                    # Minnow -> Piranha 25 -> Barracuda 200
    reef_groups={'Shrimp': (10, 6, 1), 'Damsel': (14, 2, 1), 'Puffer': (9, 1, 2), 'Sardine': (6, 7, 1)},  # groups in the reef, school, exp
    open_groups={'Mackerel': (5, 5, 3), 'Squid': (6, 3, 4), 'Sardine': (3, 7, 1)},
    open_mult=2, index_page_every=3, index_page_reward=10,
    quests=[('eat', 5, 3), ('eat', 10, 5), ('index', 3, 6), ('evo', 2, 10), ('open', 1, 10), ('openeat', 15, 20), ('escape', 1, 30), ('evo', 3, 40)],
    golden_first=40, golden_every=120, golden_near=False, golden_exp=25,
    reef_gap_med=55, open_gap_med=90, open_travel=(150, 260),   # studs: between schools; spawn area -> open sea ring
    speed=15,                                # studs/s a kid actually swims (cruise 13, top 24)
    # first-minute pass 1 (live now)
    swim_hint=True, hint_after=3.0, welcome_ahead=16, welcome_waits=True, welcome_hold=8, eat_marker=True,
    arrows_minnow=True,                      # ground chevrons to the nearest fish while a Minnow (MB_GuideArrows)
    open_pointer=False,                      # an arrow toward the Open Sea during the "Swim out to the OPEN SEA" quest
    quest_reward_mult=1.0, first_evo_exp=25, welcome_school_size=6, piranha_arrows=False,
    open_arrows=False, predator_rate=1/45, practice_predator=False, openeat_goal=15,
)

def lognorm(rng, med, s): return med * math.exp(rng.gauss(0, s))

class Kid:
    def __init__(k, P, rng, pat):
        k.P, k.rng, k.pat = P, rng, pat
        k.t = 0.0; k.bored = 0.0; k.exp = 0; k.evo = 1; k.eaten = 0; k.openeaten = 0
        k.species = set(); k.q = 0; k.qbase = 0; k.quit = None; k.last_new = 0.0
        k.events = []; k.first_bite = None; k.evo_t = {}; k.dead = 0.0; k.max_dead = 0.0
        k.skill = rng.uniform(0.75, 1.3)
        k.knows = rng.random() < 0.55          # already knows how to swim (other Roblox swim / shark games)
        k.golden_next = P['golden_first']
        k.in_open = False
        k.escaped = 0
        q = list(P['quests']); q[5] = ('openeat', P['openeat_goal'], q[5][2]); k.P = dict(P, quests=q)

    def reward(k, kind, amt):
        k.bored = max(0.0, k.bored - amt)
        k.events.append((round(k.t, 1), kind))
        if kind != 'bite': k.last_new = k.t
        k.dead = 0.0

    def tick(k, dt, mode):
        # mode: 'chase' (fish in view), 'guided' (arrow/marker), 'lost' (nothing visible), 'wait' (doesn't know controls)
        f = {'chase': 0.3, 'guided': 0.75, 'lost': 1.4, 'wait': 1.0, 'hint': 0.8}[mode]
        k.mode = mode
        nxt = k.P['evo_exp'][min(k.evo, len(k.P['evo_exp']) - 1)]
        prev = k.P['evo_exp'][k.evo - 1]
        if k.evo < len(k.P['evo_exp']) and (k.exp - prev) / max(1, nxt - prev) > 0.7: f *= 0.7
        if k.t - k.last_new > 25: f *= 1.3
        k.bored += f * dt
        k.dead += dt; k.max_dead = max(k.max_dead, k.dead) if k.t < 60 else k.max_dead
        # golden fish announcement
        if k.t >= k.golden_next:
            k.golden_next += k.P['golden_every']; k.reward('golden_seen', 2)
            if k.P['golden_near'] and k.rng.random() < 0.7:   # spawns near you: you chase and eat it
                k.reward('GOLDEN!', 8); k.gain(k.P['golden_exp'])
        k.t += dt
        if k.bored > k.pat and k.quit is None:
            k.quit = k.t; k.quit_ctx = (k.mode, k.P['quests'][k.q][0] if k.q < len(k.P['quests']) else 'rep-' + ['eat', 'openeat', 'escape'][(k.q - len(k.P['quests'])) % 3], 'open' if k.in_open else 'reef', k.evo); return False
        return True

    def gain(k, e):
        k.exp += e
        evo = k.evo
        while k.evo < len(k.P['evo_exp']) and k.exp >= k.P['evo_exp'][k.evo]:
            k.evo += 1; k.evo_t[k.evo] = round(k.t, 1); k.reward('EVOLVE', 25)
        k.check_quest()

    def check_quest(k):
        P = k.P
        while True:
            if k.q < len(P['quests']): kind, goal, rew = P['quests'][k.q]
            else:
                e = k.evo; i = (k.q - len(P['quests'])) % 3
                kind, goal, rew = [('eat', P.get('rep_eat_base', 15) + P.get('rep_eat_step', 5) * e, 6 * e * e), ('openeat', P.get('rep_open_base', 10) + P.get('rep_eat_step', 5) * e, 5 * e * e), ('escape', 2, 10 * e * e)][i]
            done = (kind == 'eat' and k.eaten - k.qbase >= goal) or (kind == 'index' and len(k.species) >= goal) or \
                   (kind == 'evo' and k.evo >= goal) or (kind == 'open' and k.in_open) or (kind == 'openeat' and k.openeaten - k.qbase >= goal) or (kind == 'escape' and k.escaped >= goal)
            if not done: return
            k.q += 1
            nk = P['quests'][k.q][0] if k.q < len(P['quests']) else ['eat', 'openeat', 'escape'][(k.q - len(P['quests'])) % 3]
            k.qbase = k.eaten if nk == 'eat' else (k.openeaten if nk == 'openeat' else k.qbase)
            if nk == 'escape': k.escaped = 0
            k.reward('quest', 6)
            k.exp += int(rew * P['quest_reward_mult'])
            while k.evo < len(P['evo_exp']) and k.exp >= P['evo_exp'][k.evo]:
                k.evo += 1; k.evo_t[k.evo] = round(k.t, 1); k.reward('EVOLVE', 25)

    def wait(k, secs, mode):
        n = int(secs / 0.1)
        for _ in range(n):
            if not k.tick(0.1, mode): return False
            if k.t >= 300: return False
        return True

    def eat_group(k, sp, school, exp, open_=False):
        caught = max(1, round(school * k.rng.uniform(0.55, 0.9)))
        for _ in range(caught):
            if not k.wait(k.rng.uniform(0.6, 1.5) / k.skill, 'chase'): return False
            k.eaten += 1
            if open_: k.openeaten += 1
            if k.first_bite is None: k.first_bite = round(k.t, 1)
            habit = 1 / (1 + 0.12 * k.eaten)
            k.reward('bite', 2.6 * habit)
            if k.eaten % 8 == 0: k.reward('size up', 3.5)   # the body grows every 8 bites (SizeUpEvery 8)
            if sp not in k.species:
                k.species.add(sp); k.reward('NEW fish', 7)
                if len(k.species) % k.P['index_page_every'] == 0:
                    k.reward('index page', 5); k.exp += k.P['index_page_reward']
            k.gain(exp * (k.P['open_mult'] if open_ else 1))
        return True

    def pick(k, groups):
        names = list(groups); w = [groups[n][0] for n in names]
        n = k.rng.choices(names, w)[0]; return n, groups[n][1], groups[n][2]

    def run(k):
        P, rng = k.P, k.rng
        # 0) learning to swim
        react = rng.uniform(0.6, 2.2)
        if k.knows:
            if not k.wait(react, 'wait'): return k
        else:
            if P['swim_hint']:
                if not k.wait(P['hint_after'], 'wait'): return k
                k.reward('hint', 1.5)
                if not k.wait(react + rng.uniform(0.5, 2.5), 'hint'): return k
            else:   # finds the controls by trying: ~15 % a second
                while rng.random() > 0.015:
                    if not k.wait(0.1, 'wait'): return k
        # 1) the welcome school
        if P['welcome_waits'] or k.t < P['welcome_hold']:
            if not k.wait(P['welcome_ahead'] / P['speed'] / k.skill + rng.uniform(0.3, 1.0), 'guided' if P['eat_marker'] else 'chase'): return k
            if not k.eat_group('Shrimp', P['welcome_school_size'], 1): return k
        # 2) the reef loop until the Open Sea quest, then the open sea
        while k.t < 300 and k.quit is None:
            quest = P['quests'][k.q][0] if k.q < len(P['quests']) else ['eat', 'openeat', 'escape'][(k.q - len(P['quests'])) % 3]
            if quest == 'open' and not k.in_open:
                d = rng.uniform(*P['open_travel'])
                eff = 0.85 if P['open_pointer'] else rng.uniform(0.35, 0.7)   # no pointer: wanders by the minimap
                if not k.wait(d / (P['speed'] * k.skill * eff), 'guided' if P['open_pointer'] else 'lost'): break
                k.in_open = True; k.check_quest(); k.reward('zone', 6)
                continue
            if k.in_open:
                P = k.P
                if quest == 'escape':
                    wait_pred = rng.uniform(3, 8) if P['practice_predator'] else rng.expovariate(P['predator_rate'])
                    if wait_pred < 6:
                        if not k.wait(wait_pred, 'chase'): break
                        k.reward('predator!', 4)
                        if rng.random() < 0.8: k.escaped += 1; k.reward('ESCAPED', 6); k.check_quest(); continue
                gap = lognorm(rng, P['open_gap_med'], 0.5)
                if not k.wait(gap / (P['speed'] * k.skill * (0.85 if P['open_arrows'] else 0.75)), 'guided' if P['open_arrows'] else 'lost'): break
                if quest == 'escape' and not P['practice_predator'] and rng.random() < gap / P['speed'] * P['predator_rate']:
                    k.reward('predator!', 4)
                    if rng.random() < 0.8: k.escaped += 1; k.reward('ESCAPED', 6); k.check_quest()
                if not k.eat_group(*k.pick(P['open_groups']), open_=True): break
            else:
                gap = lognorm(rng, P['reef_gap_med'], 0.5)
                guided = (k.evo == 1 and P['arrows_minnow']) or (k.evo >= 2 and P['piranha_arrows'])
                if not k.wait(gap / (P['speed'] * k.skill * (0.85 if guided else 0.6)), 'guided' if guided else 'lost'): break
                if not k.eat_group(*k.pick(P['reef_groups'])): break
        return k

def sim(P, n=2500, pat_med=11, seed=1):
    rng = random.Random(seed); kids = []
    for i in range(n):
        pat = lognorm(rng, pat_med, 0.45)
        kids.append(Kid(P, random.Random(rng.random()), pat).run())
    out = {}
    for T in (15, 30, 60, 120, 180, 300):
        out[f'stay{T}'] = round(100 * sum(1 for k in kids if k.quit is None or k.quit > T) / n, 1)
    fb = [k.first_bite for k in kids if k.first_bite is not None]
    out['first_bite_med'] = round(statistics.median(fb), 1) if fb else None
    pir = [k.evo_t.get(2) for k in kids if k.evo_t.get(2)]
    bar = [k.evo_t.get(3) for k in kids if k.evo_t.get(3)]
    out['piranha_med'] = round(statistics.median(pir), 1) if pir else None
    out['piranha_pct'] = round(100 * len(pir) / n, 1)
    out['barracuda_med'] = round(statistics.median(bar), 1) if bar else None
    out['barracuda_pct'] = round(100 * len(bar) / n, 1)
    out['max_dead_min1_med'] = round(statistics.median([k.max_dead for k in kids]), 1)
    from collections import Counter
    c = Counter(k.quit_ctx for k in kids if k.quit is not None and k.quit <= 300)
    out['quit_where'] = [(str(a), round(100*b/n,1)) for a, b in c.most_common(4)]
    return out, kids

if __name__ == '__main__':
    print(json.dumps(sim(LIVE)[0]))
