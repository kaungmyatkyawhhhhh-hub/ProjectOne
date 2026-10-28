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
STATIONS = {  # league: [(gain, minSpeed)]  (GDD 7.2 gains; MinSpeed from Config after prompt 4)
    1: [(1, 0), (3, 1400), (8, 5000)],
    2: [(40, 0), (90, 1250000), (200, 4000000), (450, 12000000)],
    3: [(900, 0), (2000, 550000000), (4500, 1800000000), (10000, 5500000000)],
}
RANKS = {  # Bronze, Silver, Gold, Platinum, Champion (Config after prompt 4)
    1: [0, 3800, 20000, 36000, 70000],
    2: [0, 4000000, 16000000, 40000000, 80000000],
    3: [0, 1800000000, 7500000000, 18000000000, 36000000000],
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

# ---- M4: first 15 minutes, gifts, daily, quests -----------------------------------------------
NEW_RUNNER = (2, 900)  # x2 training for the first 15 min of play
GIFTS = [(180, 'min', 1), (480, 'min', 2), (900, 'boost', 300), (1500, 'min', 4), (2400, 'min', 6), (3600, 'roll', 1)]
DAILY_DAY1_MIN = 2
FIRST_TAP_COINS = 100
TUTORIAL_RACE_AT = 60  # a guaranteed win that doesn't count for Go Pro
QUESTS_DONE_AT = 1200  # a normal player finishes the 3 quests about 20 min in
QUEST_MIN, QUEST_BONUS_MIN = 3, 10
M4 = True

# ---- normal player -----------------------------------------------------------------------------
TAPS_PER_SEC = 4.5  # kids on phones: 4-6
BREAK_EVERY, BREAK_LEN = 50, 6  # walk to a new station, look around, open the Locker...


def rank_index(league, speed, scale):
    idx = 0
    for i, v in enumerate(RANKS[league]):
        if speed >= v * scale[league]:
            idx = i
    return idx


MILESTONES = {}  # (league, what) -> list of minutes, filled by run()


def mark(key, t):
    MILESTONES.setdefault(key, []).append(t / 60)


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

    gift_boost_until = -1

    def train_mult():
        c = sum(sorted(coaches, reverse=True)[:2])
        timed = 1
        if M4 and (t < NEW_RUNNER[1] or t < gift_boost_until):
            timed = 2
        return SHOES[shoe][0] * (1 + min(c, 3.0)) * LEAGUE_TRAIN_MULT ** (league - 1) * timed

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

    gifts = list(GIFTS) if M4 else []
    tut_race_done = not M4
    quests_done = not M4
    if M4:
        coins += DAILY_DAY1_MIN * CPM[0] + FIRST_TAP_COINS
    while t < 4 * 3600:
        t += 1
        while gifts and t >= gifts[0][0]:
            _, kind, v = gifts.pop(0)
            if kind == 'min':
                coins += v * CPM[league - 1]
            elif kind == 'boost':
                gift_boost_until = t + v
            else:
                free_roll += v
        if not quests_done and t >= QUESTS_DONE_AT:
            quests_done = True
            coins += (3 * QUEST_MIN + QUEST_BONUS_MIN) * CPM[league - 1]
            free_roll += 1
        if not tut_race_done and t >= TUTORIAL_RACE_AT:
            tut_race_done = True
            coins += (REWARD_MIN[0] + FINISH_MIN) * 1.5 * CPM[0]  # first race of the day bonus
            t += 30
            continue
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
            mark((league, "rank" + str(best_rank + 1)), t - start)
            coins += RANK_REWARD_MIN[best_rank] * CPM[league - 1]
            if M4 and league == 1 and best_rank == 1:
                free_roll += 1  # the tutorial's Silver roll
        # shopping: next shoe first, then coaches with spare coins
        if shoe + 1 < len(SHOES):
            tr, price, lg, rk = SHOES[shoe + 1]
            if (league > lg or (league == lg and best_rank >= rk)) and coins >= price:
                coins -= price
                shoe += 1
                mark((league, "shoe" + str(shoe)), t - start)
        roll_price = max(50, ROLL_MIN * CPM[league - 1])
        saving = shoe + 1 < len(SHOES) and SHOES[shoe + 1][2] <= league and SHOES[shoe + 1][1] < 40 * CPM[league - 1]  # kids save up for shoes they can see
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
    if "--m3" in sys.argv:
        M4 = False
        sys.argv.remove("--m3")
    if "--solve" in sys.argv:
        scale = {1: 1.0, 2: 1.0, 3: 1.0}
        for lg in (1, 2, 3):  # leagues in order: a later league depends on the earlier ones' coaches
            lo, hi = 0.2, 20000.0
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
        a = [float(x) for x in sys.argv[1:4]] or [1.0, 1.0, 1.0]
        scale = {1: a[0], 2: a[1], 3: a[2]}
    MILESTONES.clear()
    res = average(scale)
    import statistics
    print("Milestones (average minutes into the league):")
    for key in sorted(MILESTONES):
        print("  L%d %-6s %5.1f" % (key[0], key[1], statistics.mean(MILESTONES[key])))
    print("League | target min | sim min")
    for k in (1, 2, 3):
        print(f"  {k}    |   {TARGET[k]:3d}      | {res[k]:5.1f}")
    run(scale, seed=3, verbose=True)
