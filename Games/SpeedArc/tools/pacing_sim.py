"""SPEED ARC pacing sim (prompt 3). A 'normal player' bot: trains at its best station, joins the
race every 3 minutes, buys the next shoe when it can, rolls coaches with spare coins, Goes Pro as
soon as it may. Numbers are copied from src/ReplicatedStorage/Shared/Config (keep in sync).

Run:  python tools/pacing_sim.py            -> table for the current Config numbers
      python tools/pacing_sim.py --solve    -> finds threshold scales that hit the targets
"""
import random
import sys

# ---- Config copy -------------------------------------------------------------------------------
LEAGUE_TRAIN_MULT = 8
CPM = [60, 400, 3000, 25000, 200000]
TRAINING_SHARE, ASSUMED_TPS = 0.2, 5
COMBO_MAX, COMBO_BUILD = 1.5, 10
STATIONS = {  # league: [(gain, minSpeed)]  (GDD 7.2 base numbers)
    1: [(1, 0), (3, 40), (8, 150)],
    2: [(40, 0), (90, 3000), (200, 10000), (450, 30000)],
    3: [(900, 0), (2000, 150000), (4500, 500000), (10000, 1500000)],
}
RANKS = {  # Bronze, Silver, Gold, Platinum, Champion
    1: [0, 100, 400, 1000, 2000],
    2: [0, 10000, 40000, 100000, 200000],
    3: [0, 500000, 2000000, 5000000, 10000000],
}
RANK_REWARD_MIN = [0, 1, 2, 3, 5]
WINS_NEEDED = {1: 1, 2: 2, 3: 3}
SHOES = [  # (train, price, league, rank index needed 0..4)
    (1.0, 0, 1, 0), (1.3, 250, 1, 0), (1.7, 1500, 1, 1), (2.3, 8000, 1, 2),
    (3.2, 60000, 2, 0), (4.5, 400000, 3, 0),
]
ROLL_MIN = 1.5
COACHES = [(40, 0.05, 0), (28, 0, 0.08), (18, 0.12, 0), (9.5, 0.20, 0.10), (3.5, 0.35, 0), (0.8, 0.5, 0), (0.17, 0.65, 0), (0.03, 0.8, 0)]
RACE_EVERY, RACE_BUSY = 180, 55  # a race every 3 min; join + countdown + race + results ~55 s
REWARD_MIN = [6, 4, 3]  # 1st, 2nd, 3rd
FINISH_MIN = 1.5
PLACE_ODDS = [0.30, 0.28, 0.22, 0.20]  # a normal kid vs NPCs set around their own speed

# ---- normal player -----------------------------------------------------------------------------
TAPS_PER_SEC = 4.5  # kids on phones: 4-6
BREAK_EVERY, BREAK_LEN = 50, 6  # walk to a new station, look around, open the Locker...


def rank_index(league, speed, scale):
    idx = 0
    for i, v in enumerate(RANKS[league]):
        if speed >= v * scale[league]:
            idx = i
    return idx


def run(scale, seed=1, verbose=False):
    rnd = random.Random(seed)
    league, speed, coins = 1, 0.0, 0.0
    shoe = 0
    coaches = []  # train boosts
    coin_boost = 0.0
    wins = 0
    best_rank = 0
    t = 0
    combo_t = 0.0
    since_break = 0
    out = {}
    start = 0
    free_roll = 0
    next_race = 45

    def train_mult():
        c = sum(sorted(coaches, reverse=True)[:2])
        return SHOES[shoe][0] * (1 + min(c, 3.0)) * LEAGUE_TRAIN_MULT ** (league - 1)

    def roll():
        nonlocal coin_boost
        r = rnd.uniform(0, sum(c[0] for c in COACHES))
        for ch, tr, co in COACHES:
            r -= ch
            if r <= 0:
                if tr:
                    coaches.append(tr)
                else:
                    coin_boost = max(coin_boost, co)
                return

    while t < 4 * 3600:
        t += 1
        if t >= next_race:  # the race (no training while it runs)
            next_race = t + RACE_EVERY
            place = rnd.choices(range(4), PLACE_ODDS)[0]
            if place == 0:
                wins += 1
            minutes = (REWARD_MIN[place] if place < 3 else 0) + FINISH_MIN
            coins += minutes * CPM[league - 1] * (1 + coin_boost)
            t += RACE_BUSY
            combo_t = 0
            continue
        since_break += 1
        if since_break >= BREAK_EVERY:
            since_break = 0
            t += BREAK_LEN
            combo_t = 0
            continue
        combo_t += 1
        combo = 1 + (COMBO_MAX - 1) * min(combo_t / COMBO_BUILD, 1)
        gain = max(g for g, m in STATIONS[league] if speed >= m * scale[league])
        speed += gain * combo * train_mult() * TAPS_PER_SEC
        coins += CPM[league - 1] * TRAINING_SHARE / (60 * ASSUMED_TPS) * TAPS_PER_SEC * (1 + coin_boost)
        r = rank_index(league, speed, scale)
        while best_rank < r:
            best_rank += 1
            coins += RANK_REWARD_MIN[best_rank] * CPM[league - 1]
        # shopping: next shoe first, then coaches with spare coins
        if shoe + 1 < len(SHOES):
            tr, price, lg, rk = SHOES[shoe + 1]
            if (league > lg or (league == lg and best_rank >= rk)) and coins >= price:
                coins -= price
                shoe += 1
        roll_price = max(50, ROLL_MIN * CPM[league - 1])
        saving = shoe + 1 < len(SHOES) and SHOES[shoe + 1][2] <= league and SHOES[shoe + 1][1] < 6 * CPM[league - 1]
        if free_roll:
            free_roll -= 1
            roll()
        elif not saving and coins >= roll_price * 2:
            coins -= roll_price
            roll()
        # Go Pro / league done
        if best_rank == 4 and wins >= WINS_NEEDED[league]:
            out[league] = (t - start) / 60
            if verbose:
                print(f"  L{league} done at {t/60:5.1f} min (league took {out[league]:4.1f}), shoe {shoe}, coaches {len(coaches)}, coins {coins:,.0f}")
            if league == 3:
                return out
            league += 1
            speed, wins, best_rank, combo_t = 0.0, 0, 0, 0
            free_roll += 1
            start = t
    return out


def average(scale, n=60):
    tot = {1: 0, 2: 0, 3: 0}
    for s in range(n):
        r = run(scale, seed=s)
        for k in tot:
            tot[k] += r.get(k, 240)
    return {k: v / n for k, v in tot.items()}


TARGET = {1: 15, 2: 35, 3: 60}

if __name__ == "__main__":
    if "--solve" in sys.argv:
        scale = {1: 1.0, 2: 1.0, 3: 1.0}
        for lg in (1, 2, 3):  # leagues in order: a later league depends on the earlier ones' coaches
            lo, hi = 0.2, 200.0
            for _ in range(40):
                mid = (lo * hi) ** 0.5
                scale[lg] = mid
                if average(scale, 30)[lg] < TARGET[lg]:
                    lo = mid
                else:
                    hi = mid
            scale[lg] = round((lo * hi) ** 0.5, 2)
        print("scales", scale)
    else:
        scale = {1: float(a) for a in sys.argv[1:2]} or {1: 1.0}
        scale = {1: 1.0, 2: 1.0, 3: 1.0}
    res = average(scale)
    print("League | target min | sim min")
    for k in (1, 2, 3):
        print(f"  {k}    |   {TARGET[k]:3d}      | {res[k]:5.1f}")
    run(scale, seed=3, verbose=True)
