"""City Legends economy model (19 Nov 2026): what players earn per hour, and fair car prices from it.

Run from Games/CityLegends:   python tools/economy/model.py [--md out.md] [--chart out.png]

Reads the real numbers from src/shared (Cars.lua, CarStats.lua, Config.lua, YangonWorld.lua) and ports the bits
of Luau it needs (trims, the PI, the job pay sums). Everything marked EST is a guess about how kids play, not a
number from the code: change it here and re-run. It changes nothing in the game.
"""
import math, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHARED = ROOT / "src" / "shared"
CARS = (SHARED / "Cars.lua").read_text(encoding="utf-8")
STATS = (SHARED / "CarStats.lua").read_text(encoding="utf-8")
WORLD = (SHARED / "YangonWorld.lua").read_text(encoding="utf-8")
CONFIG = (SHARED / "Config.lua").read_text(encoding="utf-8")

# ------------------------------------------------------------------ the roster (Cars.lua, ported)
def field(line, key, kind=str):
    m = re.search(r"\b%s = (\"[^\"]*\"|[-\d.]+|true|false)" % key, line)
    if not m:
        return None
    v = m.group(1)
    if kind is str:
        return v.strip('"')
    if kind is bool:
        return v == "true"
    return float(v)

cars, order = {}, []
for line in CARS.splitlines():
    if not re.match(r"\s*\{ Id = \"", line):
        continue
    c = {k: field(line, k) for k in ("Id", "Name", "Class", "Tier", "PriceSource")}
    for k in ("TopSpeed", "ZeroToSixty", "Handling", "Price", "StatPrice", "Order"):
        c[k] = field(line, k, float)
    c["Electric"] = bool(field(line, "Electric", bool))
    c["Pending"] = bool(field(line, "Pending", bool))
    c["Retired"] = False
    c["BaseId"] = field(line, "BaseId")  # (a trim written out in the list: the R35 Zenith, 19 Nov)
    cars[c["Id"]] = c
    order.append(c["Id"])
retired_block = re.search(r"Cars\.RETIRED = \{(.*?)\} ::", CARS, re.S).group(1)
for rid in re.findall(r"(\w+) = true", retired_block):
    cars[rid]["Retired"] = True

series = []  # Cars.Series then RETIRED_SERIES, then lone cars (allSeries order)
for m in re.finditer(r'\{ Name = "([^"]+)", Ids = \{([^}]*)\}([^}\n]*)\}', CARS):
    ids = re.findall(r'"(\w+)"', m.group(2))
    rest = m.group(3)
    tb = re.search(r'TrimBase = "(\w+)"', rest)
    series.append({"Name": m.group(1), "Ids": ids, "NoTrims": "NoTrims = true" in rest,
                   "OldTrims": "OldTrims = true" in rest, "TrimBase": tb.group(1) if tb else None})
for cid in order:
    if not any(cid in s["Ids"] for s in series):
        series.append({"Name": cars[cid]["Name"].upper(), "Ids": [cid], "NoTrims": False, "OldTrims": False, "TrimBase": None})

def lround(n, step):  # Luau round(): floor(n / step + 0.5) * step
    return math.floor(n / step + 0.5) * step

STEPS = [("sport", "Sport", 1.3, 1.05, 0.92, 0.03, 8000), ("top", "Top", 1.7, 1.1, 0.85, 0.06, 15000)]
for s in series:
    if (len(s["Ids"]) != 1 and not s["TrimBase"]) or s["NoTrims"]:
        continue
    base = cars[s["TrimBase"] or s["Ids"][0]]
    at = s["Ids"].index(base["Id"])
    for i, (key, label, pm, sm, am, gm, free) in enumerate(STEPS, 1):
        sp = base["StatPrice"] or base["Price"]
        t = dict(base, Id=base["Id"] + "_" + key, Name=base["Name"] + " " + label,
                 TopSpeed=math.floor(base["TopSpeed"] * sm + 0.5),
                 ZeroToSixty=max(2, lround(base["ZeroToSixty"] * am, 0.1)),
                 Handling=min(0.98, base["Handling"] + gm),
                 Price=lround(base["Price"] * pm, 1000) if base["Price"] > 0 else free,
                 StatPrice=lround(sp * pm, 1000) if sp > 0 else free,
                 Order=base["Order"] + i / 10, BaseId=base["Id"],
                 Retired=base["Retired"] or s["OldTrims"], Pending=base["Pending"])
        cars[t["Id"]] = t
        order.append(t["Id"])
        if not s["OldTrims"]:
            s["Ids"].insert(at + i, t["Id"])
for cid, price in re.findall(r"(\w+) = (\d+)", re.search(r"Cars\.TrimPrices = \{(.*?)\} ::", CARS, re.S).group(1)):
    cars[cid]["Price"] = float(price)
v = cars["bugotti_veyron_sport"]  # the Origine's trims got their own models and real numbers
v.update(Name="Velocité Noir Origine Super Sport", TopSpeed=258, ZeroToSixty=2.5, Handling=0.88)
v = cars["bugotti_veyron_top"]
v.update(Name="Velocité Noir Origine Roadster Vitesse", TopSpeed=254, ZeroToSixty=2.6, Handling=0.87)
on_sale = [cid for cid in order if not cars[cid]["Retired"] and not cars[cid]["Pending"]]

# ------------------------------------------------------------------ the PI (CarStats.of + CarStats.pi, stock cars)
def lua_table(name):
    body = re.search(r"local %s(?:: [^=]+)? = \{(.*?)\n\}" % name, STATS, re.S).group(1)
    return {k: v for k, v in re.findall(r"(\w+) = ([\w.]+)", body)}
KERB = {k: float(v) for k, v in lua_table("KERB").items()}
POWER = {k: float(v) for k, v in lua_table("POWER").items()}
WEIGHT = {"Sedan": 1550, "Coupe": 1480, "SUV": 2250, "Supercar": 1520, "Hypercar": 1750}
clamp = lambda x, lo, hi: max(lo, min(hi, x))

def stats(cid):
    c = cars[cid]
    base = c["BaseId"] or cid
    zts = max(c["ZeroToSixty"], 2)
    w = WEIGHT.get(c["Class"], 1600) + clamp(math.log10(max(c["StatPrice"] or c["Price"], 10000)) - 4, 0, 2.7) * 90
    if c["Electric"]:
        w += 280
    w = KERB.get(cid) or KERB.get(base) or w
    ptw = 110 * (9.5 / zts) ** 1.18
    hp = ptw * w / 1000
    real = POWER.get(cid)
    if real is None and c["BaseId"] and c["BaseId"] in POWER:
        real = POWER[c["BaseId"]] * (cars[c["BaseId"]]["ZeroToSixty"] / zts) ** 1.18
    if real:
        hp = real
    brake = clamp(0.35 + c["Handling"] * 0.55 + (0.1 if c["Class"] in ("Supercar", "Hypercar") else 0), 0, 1)
    return math.floor(hp + 0.5), math.floor(w / 5 + 0.5) * 5, brake

def pi(cid):
    c = cars[cid]
    hp, w, brake = stats(cid)
    k = lambda v, lo, hi: clamp((v - lo) / (hi - lo), 0, 1.1)
    a = clamp(math.log(11 / max(c["ZeroToSixty"], 1)) / math.log(11 / 2.2), 0, 1.1)
    p = clamp(math.log(hp * 1000 / w / 90) / math.log(800 / 90), 0, 1.1)
    score = 0.2 * a + 0.4 * p + 0.12 * k(c["TopSpeed"], 90, 275) ** 1.3 + 0.17 * k(c["Handling"], 0.45, 0.97) \
        + 0.05 * clamp(brake, 0, 1.15) + 0.06 * k(w, 2800, 1200)
    x = max(0, (score - 0.03) / (0.993 - 0.03))
    return int(clamp(math.floor(100 + 899 * x + 0.5), 100, 999))

CLASSES = [("D", 100), ("C", 401), ("B", 501), ("A", 601), ("S1", 701), ("S2", 751), ("R", 801), ("X", 901)]
def letter(p):
    return [l for l, lo in CLASSES if p >= lo][-1]

# self-check against the 3 Nov PI table (City Legends/Car classes - PI table.md, made by tools/pi_table.luau)
for cid, want in {"mclaran_12c": 771, "nisun_gtr": 700, "kio_ev6": 200, "rolls_cullinan": 402,
                  "bugotti_chiron_supersport": 933, "porsha_gt3": 749}.items():
    assert abs(pi(cid) - want) <= 5, (cid, pi(cid), want)  # (the GT-R got a new kerb weight since: 696 vs 700)

# ------------------------------------------------------------------ the economy numbers (Config.lua, scaled as in its "Harder cash" block)
def cash(v, k):  # Config's cash(): at least 5, rounded to 5
    return max(5, math.floor(v * k / 5 + 0.5) * 5)
ACTIVE, JOBMULT, HEIST, GIFT, TASK, LVLUP, LVLGIFT, WHEEL, SUPER = 0.15, 0.085, 0.1, 0.15, 0.1, 0.1, 0.02, 0.1, 0.03
STUDS_TO_MPH = 0.783
sps = lambda mph: mph / STUDS_TO_MPH
RANK_MULT = [1, 1.3, 1.65, 2.1, 2.7]
RACE = {"Gold": cash(9000, ACTIVE), "Silver": cash(5000, ACTIVE), "Bronze": cash(2500, ACTIVE), "Finish": cash(1000, ACTIVE)}
POT_PER_RACER = cash(4000, ACTIVE)
BAG = cash(60000, HEIST)
DRIVE_PER_S = 1 / 18 * ACTIVE  # $ per mph per second above 40 mph
CUT_BASE = 120 * ACTIVE
DELIV_PER_STUD, DELIV_TIME_BONUS = 4 * JOBMULT, cash(40, JOBMULT)  # (19 Nov 2026: 7 -> 4, owner approved)
STREAK = [cash(v, GIFT) for v in (5000, 8000, 12000, 18000, 25000, 35000)]
WEEKLY = cash(150000, GIFT)
PLAYTIME = [(5, 500), (15, 1000), (30, 1500), (60, 3000)]
TASK_CASH = sum(cash(v, TASK) for v in (6000, 6000, 5000, 6000, 6000, 5000, 6000, 6000, 8000, 8000, 6000)) / 11
POST_PAY, ACTIVE_PAY = 200, 100  # paycheck per minute at rank 1 (Config.Jobs)
WHEEL_EV = sum(c * w for c, w in ((5000, 22), (8000, 18), (12000, 15), (18000, 12), (25000, 9), (40000, 6), (60000, 4), (100000, 2), (200000, 1))) / 100
WHEEL_EV = cash(WHEEL_EV, WHEEL)  # one free SPIN a day (cash prizes only, EV)
SUPER_EV = 3 * sum(c * w for c, w in ((25000, 22), (40000, 16), (60000, 14), (90000, 11), (125000, 9), (175000, 7), (250000, 5),
                                      (400000, 3), (750000, 2), (1500000, 1.5), (5000000, 0.5))) / 100 * SUPER  # free SUPER SPIN a week
xp_for = lambda L: max(1, math.floor(32 * max(1, L) ** 1.3 + 0.5))
level_cash = lambda L: (cash(500, LVLUP) + cash(250, LVLUP) * L) + cash(2000, LVLGIFT) * L + (cash(8000, LVLGIFT) * L if L % 5 == 0 else 0)
task_cash = lambda L: math.floor(TASK_CASH * min(3, 1 + 0.05 * (L - 1)) / 100 + 0.5) * 100

# ------------------------------------------------------------------ task pay at real distances on the 1:1 map
def v3(s):
    return [tuple(float(x) for x in m) for m in re.findall(r"Vector3\.new\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)", s)]
disp = v3(re.search(r"dispatch = \{(.*?)\n\t\},", WORLD, re.S).group(1))
drops = v3(re.search(r"dropPoints = \{(.*?)\n\t\},", WORLD, re.S).group(1))
bus = [(float(a), float(c)) for a, b_, c in re.findall(r'pos = v\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)', re.search(r"BusStops = \{(.*?)\n\t\t\}", CONFIG, re.S).group(1))]
flat = lambda p, q: math.hypot(p[0] - q[0], p[-1] - q[-1])
places = [(p[0], p[2]) for p in drops + disp] + bus
disp2 = [(p[0], p[2]) for p in disp]
drops2 = [(p[0], p[2]) for p in drops]

# EST: how kids drive the jobs (not in the code)
JOB_MPH = 55        # average moving speed in town with traffic, turns and lights (job vans and taxis)
ROAD = 1.3          # road distance / straight-line distance (pay uses the straight line)
STOP_S = 8          # slowing into the ring, stopping, the next task coming up
rng = random.Random(19)

def drive_s(d):
    return d * ROAD / sps(JOB_MPH) + STOP_S

def pick(frm, lo, hi):
    fit = [p for p in places if lo <= flat(p, frm) <= hi]
    if fit:
        return rng.choice(fit)
    beyond = [p for p in places if flat(p, frm) > lo]
    return min(beyond, key=lambda p: flat(p, frm))

def measure(job, n=4000):
    """average $ per task at rank 1 (no passes), seconds per task, straight-line leg"""
    pay = secs = dist = 0.0
    pos = rng.choice(places)
    for i in range(n):
        if job == "bus":
            a, b = bus[i % len(bus)], bus[(i + 1) % len(bus)]
            d = flat(a, b); pay += 50 + 0.12 * d; secs += drive_s(d); dist += d
        elif job == "taxi":
            pu = pick(pos, 250, 1400); fare = pick(pu, 900, 1e9)
            d = flat(pu, fare); pay += 100 + 0.22 * d; secs += drive_s(flat(pos, pu)) + drive_s(d); dist += d; pos = fare
        elif job == "police":
            p = pick(pos, 600, 1800); d = flat(pos, p)
            pay += 80 + 0.15 * d; secs += drive_s(d) + 3; dist += d; pos = p
        elif job == "delivery":
            d0 = min(disp2, key=lambda q: flat(q, pos))
            secs += drive_s(flat(pos, d0)) if pos not in disp2 else 0
            drop = rng.choice([p for p in drops2 if flat(p, d0) >= 900]); d = flat(d0, drop)
            t = drive_s(d); left = max(0, d / sps(42) + 25 - t)
            pay += d * DELIV_PER_STUD + left * DELIV_TIME_BONUS; secs += t; dist += d; pos = drop
    return pay / n, secs / n, dist / n

JOBS = {j: measure(j) for j in ("bus", "taxi", "police", "delivery")}

def job_per_hour(job, rank, cash2x=False, dpay=False):
    """$ per hour on an active job: task pay x rank x passes, plus the paycheck, plus the driving income"""
    per, secs, _ = JOBS[job]
    m = RANK_MULT[rank - 1] * (2 if dpay else 1) * (2 if cash2x else 1)
    tasks = 3600 / secs * per * m
    paycheck = 60 * ACTIVE_PAY * m
    drive = 3600 * 0.7 * JOB_MPH * DRIVE_PER_S * (2 if cash2x else 1)  # EST 70% of the time above 40 mph
    return tasks + paycheck + drive

def post_per_hour(rank, cash2x=False, dpay=False, tips=False):
    # (19 Nov 2026, owner approved) post pay stops rising after R3; 2x Cash only on the tips, not the paycheck
    m = RANK_MULT[min(rank, 3) - 1] * (2 if dpay else 1)
    return 60 * POST_PAY * m + (180 * 40 * m * (2 if cash2x else 1) if tips else 0)  # tips: a tap every 20 s (not AFK)

# EST: free roam and races
def cut_per_hour(cuts_min, combo, mph=110, closeness=0.5, cash2x=False):
    per = CUT_BASE * (0.6 + 0.8 * closeness) * clamp(mph / 100, 0.6, 2.6) * (1 + 0.25 * (combo - 1))
    return (cuts_min * 60 * per + 3600 * 0.85 * mph * DRIVE_PER_S) * (2 if cash2x else 1)

def race_per_hour(medal_mix, racers=1, share=0.0):
    """solo time trials 5,200 studs (the 1:1 races); lobby 15 s + grid 8 s + back to the hub 35 s (EST)"""
    avg_mph = {"Gold": 82, "Silver": 70, "Bronze": 56, "Finish": 45}
    pay = secs = 0.0
    for medal, f in medal_mix.items():
        pay += f * RACE[medal]; secs += f * (5200 / sps(avg_mph[medal]) + 58)
    pay += POT_PER_RACER * racers * share if racers >= 2 else 0
    return pay * 3600 / secs  # races ignore 2x Cash and Double Pay (Activities.lua pays them raw)

def heist_per_hour(per_hour):
    return per_hour * BAG  # a full bag; the vault re-opens every 390 s for the whole server (no passes on it)

# ------------------------------------------------------------------ player types (EST: the time mix of an hour, hours a day)
TYPES = {
    "casual": dict(label="New casual (R1 jobs)", hpd=1.0, xp_h=2200, tasks=2,
                   mix=lambda c2, dp: 0.55 * sum(job_per_hour(j, 1, c2, dp) for j in JOBS) / 4 + 0.45 * cut_per_hour(4, 2, 95, 0.4, c2)),
    "mid": dict(label="Mid (R3 jobs + races)", hpd=2.0, xp_h=3500, tasks=3,
                mix=lambda c2, dp: 0.5 * (job_per_hour("delivery", 3, c2, dp) + job_per_hour("taxi", 3, c2, dp)) / 2
                + 0.3 * race_per_hour({"Gold": 0.4, "Silver": 0.4, "Bronze": 0.2}, 3, 0.5) + 0.2 * cut_per_hour(6, 4, 110, 0.5, c2)),
    "grinder": dict(label="Grinder (R5 + races + heists)", hpd=4.0, xp_h=5000, tasks=3,
                    mix=lambda c2, dp: 0.55 * job_per_hour("delivery", 5, c2, dp)
                    + 0.25 * race_per_hour({"Gold": 0.9, "Silver": 0.1}, 3, 0.7) + heist_per_hour(3) + 0.05 * cut_per_hour(8, 6, 130, 0.6, c2)),
    "afk": dict(label="AFK post (R1, tea shop)", hpd=8.0, xp_h=0, tasks=0, mix=lambda c2, dp: post_per_hour(1, c2, dp)),
    "afk5": dict(label="AFK post (R5)", hpd=8.0, xp_h=0, tasks=0, mix=lambda c2, dp: post_per_hour(5, c2, dp)),
}
PASSES = {"free": (False, False), "2x Cash": (True, False), "Double Pay": (False, True), "both": (True, True)}
START = 5000 + sum(cash(v, 0.4) for v in (1500, 2000, 3000, 3000, 3000, 4000, 3000, 3000, 4000, 6000))  # start cash + early Legends Path goals

def curve(t, passes="free", hours=600):
    """cash earned (never spent) after each minute of play, with the dailies at the start of each play-day"""
    P = TYPES[t]
    rate = P["mix"](*PASSES[passes]) / 60
    xp_rate = P["xp_h"] / 60
    total, level, xp, day, out = START, 1, 0.0, -1, [START]
    mins_day = int(P["hpd"] * 60)
    for minute in range(1, hours * 60 + 1):
        if (minute - 1) // mins_day != day:
            day = (minute - 1) // mins_day
            streak = STREAK[day % 7] if day % 7 < 6 else 0  # day 7 is a free Mid car, not cash
            total += streak + WHEEL_EV + P["tasks"] * task_cash(level)
            if day % 7 == 0:
                total += WEEKLY + SUPER_EV
        m_in_day = (minute - 1) % mins_day + 1
        total += sum(c for at, c in PLAYTIME if at == m_in_day)
        total += rate
        xp += xp_rate
        while xp >= xp_for(level):
            xp -= xp_for(level); level += 1; total += level_cash(level)
        out.append(total)
    return out

def hours_to(c, price):
    for m, v in enumerate(c):
        if v >= price:
            return m / 60
    return float("inf")

def per_hour(t, passes="free"):
    return TYPES[t]["mix"](*PASSES[passes])

# ------------------------------------------------------------------ targets and the proposal
# hours of play for the reference player (mid, free) to buy a car of this stock PI: our targets, log-interpolated
ANCHORS = [(200, 0), (300, 0.5), (400, 1.0), (500, 2.5), (600, 6), (700, 14), (750, 24), (800, 42), (850, 70), (900, 120), (935, 220)]
def target_hours(p):
    if p <= ANCHORS[0][0]:
        return 0
    for (p0, h0), (p1, h1) in zip(ANCHORS, ANCHORS[1:]):
        if p <= p1:
            if h0 == 0:
                return h1 * (p - p0) / (p1 - p0)
            return math.exp(math.log(h0) + (math.log(h1) - math.log(h0)) * (p - p0) / (p1 - p0))
    return ANCHORS[-1][1]

MAKES = re.findall(r'"([^"]+)"', re.search(r"Cars\.Makes = \{(.*?)\}", CARS, re.S).group(1))
def make_of(name):
    best = ""
    for m in MAKES:
        if len(m) > len(best) and name.startswith(m + " "):
            best = m
    return best or name.split()[0]
# brand prestige: luxury above economy at the same speed (EST, our call)
BRAND_K = {"Ecstasy": 1.3, "Sovereign": 1.25, "Rocket": 1.25, "Enfurecido": 1.25, "Rosso Rampante": 1.25, "Speedmark": 1.2,
           "British Vanguard": 1.15, "Velocité Noir": 1.0, "Stuttgart": 1.05, "Precision": 1.05, "Stealth-Apex": 1.05,
           "Tri-Star Silber": 1.05, "Bavarica Werkz": 1.0, "Trident Motors": 1.0}
# a status floor in hours: the cars kids want for what they are, not their lap time
FLOOR_H = {"Ecstasy": 22, "Sovereign": 12, "Rocket": 14, "Velocité Noir": 140, "Enfurecido": 12, "Rosso Rampante": 10, "Speedmark": 14,
           "British Vanguard": 7}
ID_FLOOR_H = {"bentz_g63": 6, "bentz_s680": 9, "bentz_gls": 6, "lambrini_countach": 30, "lambrini_urusp": 16,
              "lexis_lfa": 45, "lexis_lfa_circuit": 60, "lambrini_revuelto": 90, "lambrini_lp700": 60, "lambrini_lp750": 75,
              "lambrini_svj": 90, "lambrini_svj63": 100, "toyoka_supra_mk4": 4, "nisun_r34": 6}

def nice(p):  # round and readable: 2 significant figures ($48,000, $130,000, $1,200,000)
    if p <= 0:
        return 0
    step = 10 ** (int(math.floor(math.log10(p))) - 1)
    return int(round(p / step) * step)

# Local (sold in Myanmar, on the shelf for cash) or Import-only (crates / airport only). Owner reminder 19 Nov.
# Reason codes; "?" = unsure, the owner decides.
IMPORT_ALWAYS = {"Rosso Rampante", "Enfurecido", "Speedmark", "Velocité Noir", "British Vanguard", "Precision"}
LOCAL_IDS = {  # id (base car) -> reason
    "kio_ev6": "EVs sold new in Yangon", "byt_u8": "Chinese EVs sold new in Yangon", "xiaomo_su7": "Chinese EV, grey imports seen?",
    "toyoka_camri": "Toyota: everywhere in Yangon", "toyoka_alfard": "Japanese used import, very common", "toyoka_lc200": "Land Cruiser: very common",
    "toyoka_lc300": "Land Cruiser: very common", "toyoka_chaser": "Mark II / Chaser: classic Yangon JDM", "toyoka_supra_mk4": "JDM used import, rare but real",
    "toyoka_ae86": "JDM used import", "nisun_350z": "JDM used import", "nisun_r34": "JDM, very rare?", "nisun_gtr": "a few in Yangon?",
    "mazdo_rx7": "JDM used import", "lexis_lx700": "Lexus LX: common with the rich", "lexis_lc500": "Lexus, rare?",
    "bnw_540i": "BMW 5: common", "bnw_330i_g20": "BMW 3: common", "bnw_x6": "BMW X: common with the rich", "bnw_x7": "BMW X: common with the rich",
    "bnw_750li": "BMW 7: business cars", "bentz_e400": "Mercedes E: common", "bentz_e63s": "AMG E, rare?", "bentz_s65_w221": "S-Class: common with the rich",
    "bentz_s63": "S-Class", "bentz_s680": "Maybach: a few", "bentz_gle53": "GLE: common", "bentz_g63": "G-Class: popular with the rich",
    "bentz_gls": "GLS Maybach: a few", "bentz_190e": "old Mercedes, the Evo II is rare?", "dearb_focus_rs": "Ford: sold, the RS is rare?",
    "ronin_cp9a": "Mitsubishi: JDM used import", "ronin_ct9a": "JDM", "ronin_cz4a": "JDM", "pleiad_gc8": "Subaru: JDM", "pleiad_gdb": "JDM", "pleiad_zc6": "JDM",
    "rolls_cullinan": "a few Rolls in Yangon", "rolls_wraith": "a few Rolls in Yangon?", "bentlee_bentayga": "a few Bentleys", "lambrini_urusp": "one or two Urus in Yangon?",
    "porsha_panamera": "Porsche dealer in Yangon", "porsha_boxster": "Porsche dealer in Yangon", "maseroti_levante": "owner: Local",
    "bentlee_contgt": "owner: Local", "ferrara_458spider": "owner: Local (the 458 Spider)",
}
# owner decisions, 19 Nov 2026 (the "?" cars)
for _i in ("nisun_r34", "nisun_gtr", "lexis_lc500", "rolls_wraith", "lambrini_urusp", "xiaomo_su7", "toyoka_supra_mk4"):
    LOCAL_IDS[_i] = "owner: Local"
for _i in ("bentz_190e", "dearb_focus_rs", "bentz_e63s"):
    LOCAL_IDS.pop(_i, None)
IMPORT_IDS = {"bnw_m3_e92": "M cars not sold in MM", "bnw_m3_f80": "M cars not sold in MM", "bnw_m4_f82": "M cars not sold in MM",
              "bnw_m5_e60": "M cars not sold in MM", "bnw_m6_v10": "M cars not sold in MM", "bnw_m5_f10": "M cars not sold in MM",
              "bnw_m5_f90": "M cars not sold in MM", "bnw_m8gc": "M cars not sold in MM", "bentz_cls63s": "AMG import",
              "bentz_gt63s": "AMG GT import", "bentz_sl65bs": "Black Series: collector", "bentz_sls": "collector supercar",
              "dodger_challenger": "US muscle, LHD import", "chevo_camaro": "US muscle", "chevo_c7": "US muscle",
              "porsha_gt3": "track car", "bentlee_contgt": "rare?", "brabos_g63": "tuner G: import", "lexis_lfa": "collector, 500 built",
              "lexis_lfa_circuit": "collector", "ronin_cp9a_champ": "rare JDM edition", "astin_dbx": "British Vanguard brand",
              "bentz_190e": "owner: Import", "dearb_focus_rs": "owner: Import", "bentz_e63s": "owner: Import"}
IMPORT_IDS.pop("bentlee_contgt")
UNSURE = set()  # (all decided by the owner, 19 Nov 2026)

def source(cid):
    c = cars[cid]; base = c["BaseId"] or cid; mk = make_of(c["Name"])
    if base in LOCAL_IDS:
        return "Local", LOCAL_IDS[base], base in UNSURE
    if base in IMPORT_IDS:
        return "Import", IMPORT_IDS[base], base in UNSURE
    if mk in IMPORT_ALWAYS:
        return "Import", "exotic: not sold in Myanmar", False
    return "Import", "not sold in Myanmar", True

RARITY = [(0, "Common"), (1, "Uncommon"), (4, "Rare"), (12, "Epic"), (35, "Legendary"), (80, "Mythic")]
def rarity(cid, h):
    if make_of(cars[cid]["Name"]) == "Velocité Noir":
        return "Hypercar"
    return [r for lo, r in RARITY if h >= lo][-1]

def proposal():
    ref = curve("mid")
    rows = {}
    for cid in on_sale:
        c = cars[cid]; p = pi(cid); mk = make_of(c["Name"])
        h = target_hours(p) * BRAND_K.get(mk, 0.95)
        h = max(h, FLOOR_H.get(mk, 0), ID_FLOOR_H.get(c["BaseId"] or cid, 0) * (1.3 if c["BaseId"] else 1))
        price = 0 if cid == "kio_ev6" else nice(ref[min(len(ref) - 1, int(h * 60))])
        rows[cid] = dict(pi=p, cls=letter(p), hours=h, price=price)
    # a car's SPORT / TOP trims cost more than it (at least +10% a step)
    for s in series:
        ids = [i for i in s["Ids"] if i in rows]
        base_of = lambda x: cars[x]["BaseId"] or x
        for a, b in zip(ids, ids[1:]):
            if base_of(a) == base_of(b) and rows[b]["price"] < rows[a]["price"] * 1.1:
                rows[b]["price"] = nice(rows[a]["price"] * 1.15)
    for cid, r in rows.items():
        r["hours"] = hours_to(ref, r["price"])
        r["rarity"] = rarity(cid, r["hours"])
        r["source"], r["why"], r["unsure"] = source(cid)
    return rows

# ------------------------------------------------------------------ report
def money(n):
    return "$" + format(int(n), ",") if n == n and n != float("inf") else "-"

def hfmt(h):
    return "-" if h == float("inf") else ("%.0f min" % (h * 60) if h < 1 else "%.1f h" % h if h < 10 else "%.0f h" % h)

def crate_check(rows):
    """a cash crate must cost more than the 50% duplicate refund of what it gives on average, or crates print money"""
    avg = {}
    for r in rows.values():
        avg.setdefault(r["rarity"], []).append(r["price"])
    avg = {k: sum(v) / len(v) for k, v in avg.items()}
    out = []
    for name, price, odds in CRATES:
        ev = sum(avg.get(k, 0) * w for k, w in odds.items()) / 100
        out.append((name, price, odds, ev))
    return avg, out

# proposed cash crates (EST, our numbers; the 17 Nov design had Basic $5,000 and Premium $40,000, no odds for them)
DUP_REFUND = 0.3  # proposed: a duplicate from a CASH crate refunds 30% of its value (the design said ~50%: with fair crate prices that prints money)
CRATES = [("Basic", 90000, {"Common": 70, "Uncommon": 25, "Rare": 5}),
          ("Premium", 750000, {"Rare": 60, "Epic": 33, "Legendary": 6, "Mythic": 1})]

def main():
    sys.stdout.reconfigure(encoding="utf-8")
    out = []
    pr = out.append
    pr("## Task pay at real distances (rank 1, no passes)\n")
    pr("| Job | Avg leg (studs) | Avg pay / task | Seconds / task | Tasks / h |\n|---|---|---|---|---|")
    for j, (pay, secs, d) in JOBS.items():
        pr("| %s | %.0f | %s | %.0f | %.0f |" % (j, d, money(pay), secs, 3600 / secs))
    pr("\n## Cash per hour (play time, without the dailies)\n")
    pr("| Player | Free | 2x Cash | Double Pay | Both |\n|---|---|---|---|---|")
    for t in TYPES:
        f = per_hour(t)
        pr("| %s | %s | %s | %s | %s |" % (TYPES[t]["label"], money(f), *("%s (x%.1f)" % (money(per_hour(t, p)), per_hour(t, p) / f) for p in ("2x Cash", "Double Pay", "both"))))
    pr("\n## One job hour by rank (free / both passes)\n")
    pr("| Job | R1 | R3 | R5 | R5 + both |\n|---|---|---|---|---|")
    for j in JOBS:
        pr("| %s | %s | %s | %s | %s |" % (j, money(job_per_hour(j, 1)), money(job_per_hour(j, 3)), money(job_per_hour(j, 5)), money(job_per_hour(j, 5, True, True))))
    pr("| post (AFK) | %s | %s | %s | %s |" % (money(post_per_hour(1)), money(post_per_hour(3)), money(post_per_hour(5)), money(post_per_hour(5, True, True))))
    pr("\n## Dailies (per play-day)\n")
    pr("- Streak days 1-6: %s (day 7: a free Mid car up to $50,000, unscaled)" % ", ".join(money(s) for s in STREAK))
    pr("- Playtime gifts: %s if you play 60 min" % money(sum(c for _, c in PLAYTIME)))
    pr("- Daily tasks: about %s each at level 1, x3 by level 41" % money(task_cash(1)))
    pr("- Free SPIN EV %s a day; weekly gift %s + free SUPER SPIN EV %s a week" % (money(WHEEL_EV), money(WEEKLY), money(SUPER_EV)))
    pr("- Level-up cash (both kinds) at level 10 / 20 / 40: %s / %s / %s" % (money(level_cash(10)), money(level_cash(20)), money(level_cash(40))))
    pr("- Start: %s (start cash + the early Legends Path goals)" % money(START))
    rows = proposal()
    curves = {(t, p): curve(t, p) for t in ("casual", "mid", "grinder") for p in ("free", "both")}
    pr("\n## Price proposal (cars on sale)\n")
    pr("| Car | Class (PI) | Rarity | Source | Now | Proposed | Casual | Mid | Grinder | Mid + both passes | Why Local / Import |")
    pr("|---|---|---|---|---|---|---|---|---|---|---|")
    for cid in sorted(rows, key=lambda i: rows[i]["price"]):
        r = rows[cid]; c = cars[cid]
        shelf = r["source"] == "Local"
        new = (money(r["price"]) if shelf else "value " + money(r["price"])) if r["price"] else "free"
        hs = [hfmt(hours_to(curves[(t, "free")], r["price"])) for t in ("casual", "mid", "grinder")] + [hfmt(hours_to(curves[("mid", "both")], r["price"]))]
        pr("| %s | %s %d | %s | %s%s | %s | **%s** | %s | %s |" % (c["Name"], r["cls"], r["pi"], r["rarity"], r["source"], " ?" if r["unsure"] else "",
                                                          money(c["Price"]), new, " | ".join(hs), r["why"]))
    big = sorted(rows, key=lambda i: -abs(math.log(max(rows[i]["price"], 1) / max(cars[i]["Price"], 1))))
    pr("\n## Biggest changes\n")
    for cid in [i for i in big if cars[i]["Price"] > 0][:15]:
        pr("- %s: %s -> %s (x%.1f)" % (cars[cid]["Name"], money(cars[cid]["Price"]), money(rows[cid]["price"]), rows[cid]["price"] / cars[cid]["Price"]))
    pr("\n## Class floors (mid player, free)\n")
    ref = curves[("mid", "free")]
    for l, lo in CLASSES[4:]:
        pr("- %s from PI %d: %s (%s)" % (l, lo, money(nice(ref[int(target_hours(lo) * 60)])), hfmt(target_hours(lo))))
    pr("\n## Crates with cash (free path to an import)\n")
    for name, cost in (("Basic", 5000), ("Premium", 40000)):
        pr("- Designed %s crate %s (17 Nov): casual %s, mid %s, grinder %s" % (name, money(cost), *(hfmt(hours_to(curves[(t, "free")], cost)) for t in ("casual", "mid", "grinder"))))
    avg, crates = crate_check(rows)
    pr("- Average value by rarity: " + ", ".join("%s %s" % (k, money(avg[k])) for k in ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Hypercar") if k in avg))
    for name, price, odds, ev in crates:
        pr("- Proposed %s crate %s (%s): average car value %s, a duplicate refunds %s at 30%% (%.0f%% of the price; 50%% would be %.0f%%); casual %s, mid %s, grinder %s"
           % (name, money(price), ", ".join("%s %g%%" % kv for kv in odds.items()), money(ev), money(ev * DUP_REFUND), 100 * DUP_REFUND * ev / price, 50 * ev / price,
              *(hfmt(hours_to(curves[(t, "free")], price)) for t in ("casual", "mid", "grinder"))))
    pr("\n## Per play-day (AFK check)\n")
    pr("| Player | Hours a day | Free / day | Both passes / day |\n|---|---|---|---|")
    for t in TYPES:
        h = TYPES[t]["hpd"]
        pr("| %s | %g | %s | %s |" % (TYPES[t]["label"], h, money(per_hour(t) * h), money(per_hour(t, "both") * h)))
    text = "\n".join(out)
    args = sys.argv[1:]
    if "--md" in args:
        Path(args[args.index("--md") + 1]).write_text(text, encoding="utf-8")
    print(text)
    # src/shared/CarMeta.lua: price, Local / Import, rarity per car on sale. The live CarMeta was written from the
    # run BEFORE the 19 Nov job changes (git d7888d47 + the deleted trims): a run now prices lower, so only
    # write it again on purpose (a new price table the owner approved)
    if "--lua" in args:
        lua(Path(args[args.index("--lua") + 1]), rows)
    if "--chart" in args:
        chart(Path(args[args.index("--chart") + 1]), rows, curves)

def lua(path, rows):
    head = """--[[
	CarMeta (made by tools/economy/model.py --lua; do not edit by hand): the fair price, Local / Import and
	rarity of every car on sale (owner approved 19 Nov 2026, vault "2026-11-19 Economy - fair car prices proposal").
	  p = price ($; for an Import: its value, crates / refunds), s = "L" Local (the dealer sells it) or "I"
	  Import (crates only), r = rarity. Cars.lua puts these on the specs (Price, Source, Rarity).
	The prices are frozen at the approved run (before the delivery 7 -> 4 and post changes): re-running the
	model after those changes gives lower numbers.
]]
return {
"""
    body = "".join('\t%s = { p = %d, s = "%s", r = "%s" },\n' % (cid, rows[cid]["price"], rows[cid]["source"][0], rows[cid]["rarity"])
                   for cid in sorted(rows))
    path.write_text(head + body + "}\n", encoding="utf-8", newline="\n")

def chart(path, rows, curves):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(10, 5.6), dpi=130)
    styles = {"casual": "#7aa6c2", "mid": "#2f6db5", "grinder": "#0b2f63"}
    for t, col in styles.items():
        for p, ls in (("free", "-"), ("both", "--")):
            c = curves[(t, p)][: 200 * 60 + 1:30]
            ax.plot([i / 2 for i in range(len(c))], c, ls, color=col, lw=2 if p == "free" else 1.3,
                    label="%s, %s" % (TYPES[t]["label"], "free" if p == "free" else "2x Cash + Double Pay"))
    for cid, lab in (("toyoka_camri", "Apex Cambria"), ("bnw_m4_f82", "Bavarica F82"), ("nisun_gtr", "Horizon R35"),
                     ("lambrini_huracan", "Enfurecido LB724"), ("lambrini_svj", "LB834 ZVX"), ("bugotti_chiron", "Éclair")):
        y = rows[cid]["price"]
        ax.axhline(y, color="#bbbbbb", lw=0.8, zorder=0)
        ax.text(199, y * 1.08, "%s  %s" % (lab, money(y)), ha="right", fontsize=8, color="#555555")
    ax.set_yscale("log"); ax.set_xlim(0, 200); ax.set_ylim(5000, 3e7)
    ax.set_xlabel("hours of play"); ax.set_ylabel("cash earned (log scale)")
    ax.set_title("City Legends: cash earned vs hours played, with the proposed car prices")
    ax.legend(fontsize=7.5, loc="lower right", frameon=False)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout(); fig.savefig(path)

if __name__ == "__main__":
    main()
