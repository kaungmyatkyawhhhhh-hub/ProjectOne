"""Impatient-kid simulation of City Legends' first 5 minutes (24 Nov 2026, method: Brain/Methods/Impatient kid simulation).

Boredom rates (calibrated 24 Nov so the live start loses ~half by 5 min, a typical Roblox first session):
loading 0.3/s, car pick 0.3, spawn wait 0.6, driving with no goal 0.35 (x1.3 after 25 s with nothing new, x1.2
after 40 s lost), driving to a shown target 0.2, delivering 0.18, circling an invisible spot 0.8.
Numbers are the LIVE game (Studio v1883, repo = Studio): phone start (engine auto-on), 3 free starter cars, $5,000 start,
spawn on Kabar Aye Pagoda Road ~300 studs from the Myanmar Plaza dispatch, delivery pay = 0.34/stud + $5 per second left,
time limit = dist / 53.6 sps + 25 s, drops >= 900 studs (12 drops, avg ~1,500 from MP), Legends Path goal 1 = drive a
mile (~4,600 studs, $600), cut-ups need 55+ mph and traffic. Dispatch rings are invisible (21 Nov), jobs live in the
JOBS tab. A heuristic model, not real players: the real check is the onboarding funnel after publishing.

  python tools/kidsim_first5.py            -> the version table at patience 7 / 11 / 16
  python tools/kidsim_first5.py timeline E -> one median kid's first 5 minutes in version E
"""
import math, random, statistics, sys

DROPS_MP = [955, 947, 1228, 1361, 1355, 1619, 1540, 1260, 1990, 2070, 1780, 2430]  # flat studs, MP dispatch -> each drop >= 900
NEAREST = min(DROPS_MP)

BASE = dict(guide=False, nearest=False, extra_time=0, hint_near=False, next_goal=False, new_time=0)
VERSIONS = {
    'A': dict(),                                               # live
    'B': dict(guide=True),                                     # auto-take Delivery + one-line hint + turning arrow + beam
    'C': dict(guide=True, nearest=True),                       # + the first drop is the nearest one (Hledan Market, 947)
    'D': dict(guide=True, nearest=True, extra_time=40),        # + 40 s more on the first run (no "Too late")
    'E': dict(guide=True, nearest=True, extra_time=40, hint_near=True),                  # + "stop on the spot" when close
    'F': dict(guide=True, nearest=True, extra_time=40, hint_near=True, next_goal=True),  # + NEXT GOAL line after the pay
    'G': dict(guide=True, nearest=True, extra_time=40, hint_near=True, next_goal=True, new_time=40),  # + 40 s on every run below level 5
}


def kid(P, rng, patience_median, T=300.0, dt=0.25, log=None):
    pat = min(40, max(4, rng.lognormvariate(math.log(patience_median), 0.45)))
    react = lambda: rng.uniform(0.6, 2.2)
    sps = rng.uniform(32, 60)            # average road speed of this kid (studs/s, ~25-47 mph with junctions)
    reads = rng.random() < 0.55          # reads a one-line hint (else follows the arrow / beam only)
    B, t, last_new, n_rew = 0.0, 0.0, 0.0, 0

    def reward(a, what, new=False):
        nonlocal B, last_new, n_rew
        n_rew += 1
        if new: last_new = t
        B = max(0.0, B - a * (0.997 if new else 0.985) ** n_rew)
        if log is not None: log.append((round(t, 1), what, round(B, 1)))

    # the timeline as phases: (name, seconds, boredom rate)
    load = rng.uniform(6, 12)
    pick = rng.uniform(4, 12)
    phases = [('loading', load, 0.3), ('pick car', pick, 0.3)]
    plan = []  # (at, reward, what, new)
    t_drive = load + pick + rng.uniform(0.8, 1.5)   # claim -> car out (engine on: phone); Play test 24 Nov: 6.7 s, then 1.0 s after the isJump fix
    phases.append(('car spawn', t_drive - load - pick, 0.6))
    plan.append((load + pick, 8, 'YOUR FIRST CAR', True))

    stage = 'free'
    guided = P['guide']
    t_stage = t_drive
    found_jobs_at = None
    goal_known = False
    has_goal = False
    xp, lvl = 0.0, 1
    run = None
    mile_left = 4600.0
    cut_rate = rng.uniform(1 / 30, 1 / 12)
    while t < T:
        # what is happening now
        rate = 1.0
        ph_end = 0.0
        in_phase = False
        for name, dur, r in phases:
            if ph_end <= t < ph_end + dur:
                rate, in_phase = r, True
            ph_end += dur
        for p in [p for p in plan if p[0] <= t]:
            reward(p[1], p[2], p[3]); plan.remove(p)
        if not in_phase and t >= t_drive:
            # driving
            if stage == 'free':
                rate = 0.35 if not goal_known else 0.22                # driving is fun, but where to?
                if t - last_new > 25: rate *= 1.3
                if not goal_known and t - t_drive > 40: rate *= 1.2    # lost: no idea what to do
                if guided and t >= t_stage:                            # the guide: delivery taken, hint + arrow + beam
                    stage, run = 'to dispatch', dict(dist=300 * rng.uniform(1.0, 1.4), find=0.0)
                    if not P['hint_near']: run['find'] = rng.uniform(0, 8) if not reads else rng.uniform(0, 3)
                    reward(3, 'HINT: drive to the beam', True)
                elif not guided and found_jobs_at is None and rng.random() < 0.012 * dt:
                    found_jobs_at = t                                   # opened JOBS by chance, browses, takes Delivery
                    plan.append((t + rng.uniform(8, 20), 5, 'took Delivery (JOBS tab)', True))
                    stage, t_stage = 'browsing', t
                mile_left -= sps * dt
            elif stage == 'browsing':
                rate = 0.3
                if not [p for p in plan if 'took' in p[2]]:
                    stage, run = 'to dispatch', dict(dist=rng.uniform(250, 2000), find=rng.uniform(5, 30))
            elif stage == 'to dispatch':
                rate = (0.2 if (guided or goal_known) else 0.3) * (0.85 if has_goal else 1)
                run['dist'] -= sps * dt
                mile_left -= sps * dt
                if run['dist'] <= 0:
                    run['find'] -= dt; rate = 0.8                         # circling: where is the invisible spot?
                    if run['find'] <= 0:
                        d = NEAREST if P['nearest'] and guided else rng.choice(DROPS_MP)
                        road = d * rng.uniform(1.2, 1.5)
                        limit = d / 53.6 + 25 + (P['extra_time'] if guided else (P['new_time'] if lvl < 5 else 0))
                        stage, run = 'deliver', dict(d=d, left=road, t0=t, limit=limit)
                        reward(6, 'DELIVERY STARTED', True)
            elif stage == 'deliver':
                rate = 0.18 * (0.85 if has_goal else 1)
                run['left'] -= sps * dt
                mile_left -= sps * dt
                if not reads and not guided:
                    run['left'] += sps * dt * 0.25                     # wrong turns with no arrow
                if run['left'] <= 0:
                    took = t - run['t0']
                    if took > run['limit']:
                        reward(1, 'TOO LATE: no pay'); B += 4
                        stage, run = 'to dispatch', dict(dist=run['d'] * 1.2, find=rng.uniform(2, 10))
                    else:
                        cash = run['d'] * 0.34 + (run['limit'] - took) * 5
                        reward(12, f'DELIVERED +${cash:.0f}', True); xp += 80
                        goal_known = True
                        if P['next_goal'] and guided:
                            plan.append((t + 3, 5, 'NEXT GOAL: 2nd car', True)); has_goal = True
                        # the Delivery job stays on: JobsClient's label + beam point back to the nearest dispatch
                        guided = False
                        stage, run = 'to dispatch', dict(dist=run['d'] * rng.uniform(0.6, 1.2), find=rng.uniform(0, 6))
            # XP: driving (mph / 90 per s), +80 a delivery; level n -> n+1 needs 32 * n^1.3 (Config.Progression)
            xp += sps * 0.783 / 90 * dt
            if xp >= 32 * lvl ** 1.3:
                xp -= 32 * lvl ** 1.3; lvl += 1; reward(5, f'LEVEL {lvl}', True)
            # cut-ups and the first-mile goal
            if rng.random() < cut_rate * dt and sps > 40:
                reward(2, 'cut-up +$')
            if mile_left <= 0:
                mile_left = 1e12; reward(6, 'GOAL: first mile +$600', True)
        B += rate * dt
        if B > pat:
            return t, log
        t += dt
    return T, log


def run(P, pm, n=2500, seed=1):
    rng = random.Random(seed)
    out = [kid(P, rng, pm)[0] for _ in range(n)]
    return {s: sum(1 for x in out if x >= s) / n for s in (15, 30, 60, 120, 180, 300)}


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == 'timeline':
        P = dict(BASE, **VERSIONS[sys.argv[2]])
        log = []
        t, _ = kid(P, random.Random(7), 11, log=log)
        for e in log: print(e)
        print('quit at' if t < 300 else 'stayed', round(t, 1))
        sys.exit()
    for pm in (7, 11, 16):
        print(f'patience median {pm} s: stay % at 15/30/60/120/180/300 s')
        for v, d in VERSIONS.items():
            r = run(dict(BASE, **d), pm)
            print(f'  {v}: ' + '  '.join(f'{int(r[s] * 100):3d}' for s in r))
