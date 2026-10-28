"""SPEED ARC step pacing sim (prompt 11, the "+1 SPEED every step" game). A 'normal player' bot:
runs the wall course (steps from real running, WalkSpeed grows with SPEED), takes some AFK
treadmill time, joins the race every 3 minutes, buys the next shoes when it can, rolls coaches with
spare coins, smashes a wall as soon as it has the SPEED, Goes Pro after the last wall.
Numbers are copied from src/ReplicatedStorage/Shared/Config (keep in sync).

  python tools/step_pacing_sim.py           -> the table for the current Config numbers
  python tools/step_pacing_sim.py --solve   -> wall needs that hit the target times (paste into Config/Course Walls)
"""
import math
import random
import sys

# ---- Config copy ------------------------------------------------------------------------------
STUDS_PER_STEP = 3
STEP_GAIN = [1, 40, 900]  # Config/Course StepGain
WALL_BONUS = 1.25  # x per wall smashed in your league
LEAGUE_MULT = 8
AFK_STEPS, AUTO_RUN_MULT = 1.6, 2.4
CPM = [60, 400, 3000]
TRAINING_SHARE, ASSUMED_SPS = 0.2, 5  # coins per step = CPM x share / (60 x 5)
WALL_REWARD_MIN = [0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.2, 1.5, 1.8, 2.5]
FIRST_SMASH_MULT = 3
WALK = (16, 6, 10, 30)  # base, factor, divider, cap
SHOES = [  # (train, price, league, rank needed: 0 Bronze .. 4 Champion)
    (1.0, 0, 1, 0), (1.3, 250, 1, 0), (1.7, 900, 1, 1), (2.3, 3000, 1, 2),
    (3.2, 15000, 2, 0), (4.5, 150000, 3, 0),
]
ROLL_MIN = 1.5
COACHES = [(40, 0.05), (28, 0), (18, 0.12), (9.5, 0.20), (3.5, 0.35), (0.8, 0.5), (0.17, 0.65), (0.03, 0.8)]
RACE_EVERY, RACE_BUSY = 180, 55
RACE_MIN = 0.30 * 6 + 0.28 * 4 + 0.22 * 3 + 1.5  # expected minutes of coins a race (places + finishing)
NEW_RUNNER = (2, 900)
GIFT_BOOST_AT, GIFT_BOOST_LEN = 900, 300
GIFT_MIN = [(180, 1), (480, 2), (1500, 4), (2400, 6)]
QUESTS_AT, QUEST_MIN = 1200, 3 * 3 + 10
FIRST_STEP = (10, 100)  # +10 SPEED, +100 coins
TUTORIAL_RACE_WIN_MIN = 6
# a normal kid in a 3-minute cycle: 55 s race, then mostly running, a bit of AFK and menus
RUN_SHARE, AFK_SHARE = 0.78, 0.12  # of the non-race time (the rest = menus, looking around)
RUN_EFFICIENCY = 0.85  # turns, bounces, standing at a wall

# target times (minutes after the league starts) for walls 1..10
TARGETS = {
    1: [0.6, 2.0, 3.3, 4.6, 7.0, 8.5, 10.0, 11.5, 13.2, 15.0],
    2: [1.5, 4.0, 7.0, 10.0, 14.0, 18.0, 22.0, 26.0, 30.0, 35.0],
    3: [2.0, 6.0, 11.0, 16.0, 22.0, 28.0, 35.0, 42.0, 50.0, 60.0],
}
# current needs (Config/Course Walls) - the table run uses these
WALLS = {
    1: [310, 1600, 3200, 4700, 8600, 15000, 18000, 28000, 34000, 53000],
    2: [410000, 1600000, 2800000, 4200000, 7700000, 11000000, 17000000, 26000000, 37000000, 55000000],
    3: [130000000, 630000000, 1200000000, 2100000000, 3400000000, 5700000000, 9100000000, 13000000000, 20000000000, 30000000000],
}


def walk_speed(speed):
    b, f, d, cap = WALK
    return min(cap, b + f * math.log10(1 + max(0, speed) / d))


def two_sig(v):
    if v <= 0:
        return 0
    p = 10 ** max(0, math.floor(math.log10(v)) - 1)
    return math.floor(v / p) * p  # round down so the target time is met, not missed


def simulate(walls, solve=False, seed=7, leagues=3):
    rng = random.Random(seed)
    t = 0.0
    speed, coins, league = 0.0, 0.0, 1
    league_start = 0.0
    smashed = 0
    shoe = 0
    coaches = []
    log = []  # (league, event, minutes since league start, speed)
    first_step_done = False
    gifts = list(GIFT_MIN)
    quests_done = False
    tut_race_done = False
    needs = {k: list(v) for k, v in walls.items()}
    shoe_bought_at = {}
    rate_log = {}
    dt = 1.0
    while league <= leagues:
        cpm = CPM[league - 1]
        cyc = t % RACE_EVERY
        in_race = t >= 60 and cyc < RACE_BUSY  # first race after ~1 min (the tutorial race)
        boost = 1.0
        if t < NEW_RUNNER[1]:
            boost = NEW_RUNNER[0]
        elif GIFT_BOOST_AT <= t < GIFT_BOOST_AT + GIFT_BOOST_LEN:
            boost = 2
        coach_train = sum(sorted(coaches, reverse=True)[:2])
        gain = STEP_GAIN[league - 1] * LEAGUE_MULT ** (league - 1) * SHOES[shoe][0] * (1 + coach_train) * boost * WALL_BONUS ** smashed
        steps = 0.0
        if t >= 8:  # PLAY + the welcome line
            if not first_step_done:
                first_step_done = True
                speed += FIRST_STEP[0]
                coins += FIRST_STEP[1]
                log.append((league, "first step", t / 60, speed))
            if in_race:
                if t % RACE_EVERY < 1:
                    if not tut_race_done:
                        tut_race_done = True
                        coins += TUTORIAL_RACE_WIN_MIN * cpm
                    else:
                        coins += RACE_MIN * cpm
            else:
                run_sps = walk_speed(speed) / STUDS_PER_STEP * RUN_EFFICIENCY
                steps = run_sps * RUN_SHARE + AFK_STEPS * AFK_SHARE
                rate_log.setdefault(league, (run_sps, AFK_STEPS, AFK_STEPS * AUTO_RUN_MULT, gain))
        speed += steps * gain * dt
        coins += steps * cpm * TRAINING_SHARE / (60 * ASSUMED_SPS) * dt
        # playtime gifts / quests
        while gifts and t >= gifts[0][0]:
            coins += gifts.pop(0)[1] * cpm
        if not quests_done and t >= QUESTS_AT:
            quests_done = True
            coins += QUEST_MIN * cpm
        # walls
        lt = (t - league_start) / 60
        if smashed < 10:
            k = smashed
            ready = speed >= needs[league][k]
            if solve:
                # solving: the wall falls exactly at its target time, its need = the SPEED then
                ready = lt >= TARGETS[league][k] and speed > 0
                if ready:
                    needs[league][k] = max(two_sig(speed), (needs[league][k - 1] + 1) if k > 0 else 1)
            if ready:
                smashed += 1
                coins += WALL_REWARD_MIN[k] * FIRST_SMASH_MULT * cpm
                log.append((league, "wall %d" % smashed, lt, speed))
        # shoes (needs rank: Silver = wall 4, Gold = wall 6 in your league)
        nxt = shoe + 1
        if nxt < len(SHOES):
            tr, price, sl, rank = SHOES[nxt]
            rank_wall = {0: 0, 1: 4, 2: 6}[rank]
            if coins >= price and (league > sl or (league == sl and smashed >= rank_wall)):
                coins -= price
                shoe = nxt
                shoe_bought_at[nxt] = (league, lt)
                log.append((league, "shoes x%.1f" % tr, lt, speed))
        # coach rolls with spare coins (keep the next shoe's price)
        roll = ROLL_MIN * cpm
        keep = SHOES[shoe + 1][1] if shoe + 1 < len(SHOES) and SHOES[shoe + 1][2] <= league else 0
        if coins - roll > keep and t > 240:
            coins -= roll
            r = rng.random() * 100
            acc = 0
            for ch, tr in COACHES:
                acc += ch
                if r <= acc:
                    coaches.append(tr)
                    break
        # Go Pro
        if smashed >= 10:
            log.append((league, "GO PRO", lt, speed))
            league += 1
            speed = 0
            smashed = 0
            league_start = t + 20  # the cutscene
            t += 20
        t += dt
        if t > 6 * 3600:
            break
    return log, needs, rate_log


def main():
    solve = "--solve" in sys.argv
    log, needs, rates = simulate(WALLS, solve=solve)
    if solve:
        print("Solved wall needs (Config/Course Walls):")
        for lg in (1, 2, 3):
            print("  [%d] = { %s }," % (lg, ", ".join(str(int(v)) for v in needs[lg])))
        log, needs, rates = simulate(needs)
    print("\n| League | Event | Minutes into the league | SPEED then |")
    print("|---|---|---|---|")
    for lg, ev, m, sp in log:
        print("| %d | %s | %.1f | %s |" % (lg, ev, m, f"{sp:,.0f}"))
    print("\nSteps a second (league start): running / AFK treadmill / Auto Run")
    for lg, (run, afk, auto, gain) in sorted(rates.items()):
        print("  League %d: %.1f / %.1f / %.1f  (running = %.1fx AFK, Auto Run = %.2fx running)" % (lg, run, afk, auto, run / afk, auto / run))


if __name__ == "__main__":
    main()
