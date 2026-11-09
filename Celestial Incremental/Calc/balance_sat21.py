"""Galaxy Incremental, Sat 21 Nov update: BALANCE SIM with PHYSICS + HUMAN TIMING (9 Nov 2026).

Owner: "calculate the balancing urself and also not just calculating in maths, in physics and how long it takes for the
player to think and their brain and response time too".

What it models (all Monte Carlo, seeded, deterministic):
  1. PHYSICS   - the jump and the jetpack integrated at 240 Hz (gravity felt 95, Lift 60, rise cap 26, fuel 3 s), the map
                 (8 islands, bridges, plaza), void gaps, walk routes vs straight flights.
  2. HUMANS    - 3 kid types (grinder PC, chaos kid PC, mobile kid 8-9 on a cheap phone): perception (simple reaction time),
                 Hick's law choice time, deliberation + attention lapses, the chance to notice a toast, Fitts' law aiming
                 at a moving comet, camera turns, path inefficiency, thumbstick speed, prompt press + 0.5 s hold.
  3. HEISTS    - a 2D agent sim at 10 Hz: loose comet lands -> owner / thieves notice, decide, walk (bridges) or fly ->
                 grab / hold -> carry at 0.7x -> chasers pursue (pure pursuit or intercept) -> tackle 3.5 -> scramble ->
                 bank / burst. Duels (thief type x defender type x distance) and whole servers (3-12 players).
  4. CREWS     - Core fill time per crew size / server size; the 30 s gather (notice + decide + travel); crew reward hours.
  5. FORGE     - sky-comet catch rate per kid (9 s life), Essence per hour, rolls per player-hour over a whole player
                 population (most players never reach Ignition), the real SECRET rate, mutations and what a VOID does.
  6. MINUTES 0-5 - does a loose comet on a NEW player's island change the tuned first minutes? (kidsim.py, variant G)

Run from this folder:  py balance_sat21.py        (about 1-3 minutes; prints every table)
A heuristic model, not real players: confirm with the Heist_* / ForgeRoll analytics after the 21 Nov publish.
"""
import math
import random
import statistics
import sys
import time

T0 = time.time()
FAST = "--fast" in sys.argv
SIZES = []          # (smaller samples, for quick checks)
SCALE = 0.35 if FAST else 1.0


def n_(x):
    return max(30, int(x * SCALE))


# ====================================================================================================================
# 0. helpers
# ====================================================================================================================
def lnm(rng, median, sigma):
    """lognormal by its median (human times are right-skewed)"""
    return median * math.exp(sigma * rng.gauss(0, 1))


def pct(xs, p):
    if not xs:
        return float("nan")
    xs = sorted(xs)
    k = (len(xs) - 1) * p / 100
    f = math.floor(k)
    c = min(f + 1, len(xs) - 1)
    return xs[f] + (xs[c] - xs[f]) * (k - f)


def table(title, headers, rows):
    print("\n### " + title)
    print("| " + " | ".join(headers) + " |")
    print("|" + "---|" * len(headers))
    for r in rows:
        print("| " + " | ".join(str(c) for c in r) + " |")


def f1(x):
    return f"{x:.1f}"


def f0(x):
    return f"{x:.0f}"


def p0(x):
    return f"{100 * x:.0f}%"


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def unit(v):
    d = math.hypot(v[0], v[1])
    return (v[0] / d, v[1] / d)


# ====================================================================================================================
# 1. HUMAN FACTORS (sources / rules of thumb in the vault note)
# ====================================================================================================================
# rt      = simple visual reaction time (median, lognormal sigma). Adults ~0.25 s; 8-12 year olds 0.35-0.5 s (Kail 1991:
#           processing speed rises exponentially with age; an 8-year-old is ~1.6-2x an adult).
# hick_b  = Hick-Hyman slope, s per bit of choice (adults ~0.15; kids slower). decide = hick + deliberation + lapses.
# lapse   = chance of an attention lapse (mind-wandering; kids' RT distributions have a much fatter slow tail) + its size.
# tau_*   = mean extra time to notice a toast / the comet while busy (exponential), p_never_* = never reads/notices it.
# ineff   = path length / straight length (kids zig-zag, over-correct the thumbstick, jump around): 1.08-1.45.
# stick   = average thumbstick deflection (phones rarely hold full speed).
# press   = time to hit the prompt (PC: E key; phone: find + tap the prompt button, Fitts on a ~1 cm button).
# fitts   = MT = a + b * log2(D/W + 1) (+ bits for a moving target); PC mouse vs finger (Parhi et al. 2006: targets
#           under ~9 mm lose many taps; moving targets cost ~0.5 bit more).
HT = {
    "grinder": dict(device="PC", rt=0.33, rt_sig=0.22, hick_b=0.18, dec=1.0, dec_sig=0.45, lapse=0.08, lapse_s=(2, 5),
                    tau_toast=1.5, never_other=0.08, never_owner=0.03, tau_crew=1.0, never_crew=0.03,
                    ineff=(1.08, 1.18), stick=1.0, press=0.15, afk=0.08, loc=(0.75, 0.20, 0.05),
                    p_go=0.55, chase_owner=0.95, chase_other=0.6, intercept=0.7, replan=0.4, giveup=25, jet=0.8,
                    regrab=0.9, portal=0.5, hes=(0.15, 0.5), lost=0.02,
                    on_screen=0.60, tau_sky=0.7, hear=0.85, tau_off=1.2, no_turn=0.05, cam=0.8, cam_sig=0.3,
                    fa=0.15, fb=0.14, D=(150, 600), W=45, miss=0.08, retry=0.25, busy=0.30, afk_sky=0.06,
                    speed=1.0, session=70, lure_every=30),
    "chaos": dict(device="PC", rt=0.36, rt_sig=0.25, hick_b=0.20, dec=0.6, dec_sig=0.5, lapse=0.12, lapse_s=(1.5, 4),
                  tau_toast=2.5, never_other=0.15, never_owner=0.06, tau_crew=1.6, never_crew=0.06,
                  ineff=(1.15, 1.32), stick=1.0, press=0.15, afk=0.05, loc=(0.35, 0.40, 0.25),
                  p_go=0.85, chase_owner=0.95, chase_other=0.8, intercept=0.2, replan=0.3, giveup=30, jet=0.9,
                  regrab=0.95, portal=0.7, hes=(0.1, 0.4), lost=0.08,
                  on_screen=0.50, tau_sky=0.9, hear=0.75, tau_off=1.5, no_turn=0.10, cam=0.9, cam_sig=0.3,
                  fa=0.15, fb=0.16, D=(150, 600), W=45, miss=0.18, retry=0.20, busy=0.25, afk_sky=0.05,
                  speed=1.15, session=40, lure_every=35),
    "mobile": dict(device="phone", rt=0.48, rt_sig=0.28, hick_b=0.25, dec=2.0, dec_sig=0.55, lapse=0.22, lapse_s=(2, 7),
                   tau_toast=4.0, never_other=0.30, never_owner=0.12, tau_crew=3.0, never_crew=0.12,
                   ineff=(1.25, 1.45), stick=0.9, press=0.6, afk=0.22, loc=(0.60, 0.30, 0.10),
                   p_go=0.35, chase_owner=0.8, chase_other=0.4, intercept=0.1, replan=0.7, giveup=15, jet=0.35,
                   regrab=0.6, portal=0.25, hes=(0.4, 1.2), lost=0.15,
                   on_screen=0.45, tau_sky=1.6, hear=0.45, tau_off=2.0, no_turn=0.30, cam=1.8, cam_sig=0.4,
                   fa=0.30, fb=0.18, D=(80, 260), W=22, miss=0.30, retry=0.5, busy=0.35, afk_sky=0.18,
                   speed=1.5, session=25, lure_every=40),
}
TYPES = list(HT)
MIX = {"grinder": 0.2, "chaos": 0.3, "mobile": 0.5}   # Roblox kids 8-12: about half on phones


def pick_type(rng):
    r = rng.random()
    for t, w in MIX.items():
        r -= w
        if r <= 0:
            return t
    return "mobile"


def rt(h, rng):
    return lnm(rng, h["rt"], h["rt_sig"])


def decide(h, rng, n_choices=3):
    t = h["hick_b"] * math.log2(n_choices + 1) + lnm(rng, h["dec"], h["dec_sig"])
    if rng.random() < h["lapse"]:
        t += rng.uniform(*h["lapse_s"])
    return t


def notice(h, rng, tau, p_never):
    """time from the event to 'I saw it' (inf = never)"""
    if rng.random() < p_never:
        return math.inf
    return rt(h, rng) + rng.expovariate(1 / tau)


# ====================================================================================================================
# 2. PHYSICS: jump + jetpack (integrated), map geometry, routes
# ====================================================================================================================
G_WORLD, JUMP_H, G_FEEL, WALK = 196.2, 5.3, 95.0, 24.0
JET = dict(Fuel=3.0, Refill=1.5, Lift=60.0, MaxRise=26.0, Ceiling=120.0)


def jump_numbers():
    v0 = math.sqrt(2 * G_WORLD * JUMP_H)
    apex = v0 * v0 / (2 * G_FEEL)
    air = 2 * v0 / G_FEEL
    return v0, apex, air, WALK * air


def jet_flight(strategy="hold", fuel=None, lift=None, maxrise=None, thrust_secs=None, floor_drop=0.0, dt=1 / 240):
    """Integrate one flight from a jump. strategy: 'hold' = hold Space from take-off until the fuel is gone (a kid);
    'pulse' = thrust only when falling (max air time); thrust_secs = stop after that many s (the 2.5 s measurement).
    floor_drop = landing this many studs LOWER than take-off. Returns apex, air time, horizontal range at 24."""
    fuel = JET["Fuel"] if fuel is None else fuel
    lift = JET["Lift"] if lift is None else lift
    maxrise = JET["MaxRise"] if maxrise is None else maxrise
    v0 = math.sqrt(2 * G_WORLD * JUMP_H)
    y, vy, t, used, apex = 0.0, v0, 0.0, 0.0, 0.0
    while True:
        vy -= G_FEEL * dt
        want = strategy == "hold" or (strategy == "pulse" and vy < 0)
        if thrust_secs is not None:
            want = t < thrust_secs
        if want and used < fuel:
            used += dt
            if vy < maxrise:
                vy = min(vy + (G_FEEL + lift) * dt, maxrise)
        y += vy * dt
        t += dt
        apex = max(apex, y)
        if y <= -floor_drop and vy < 0:
            break
        if t > 60:
            break
    return apex, t, WALK * t, used


# ---- the map (x, z), y is up; from the Studio build (9 Nov)
ISL = {1: (118.3, 49.0), 2: (49.0, 118.3), 3: (-49.0, 118.3), 4: (-118.3, 49.0), 5: (-118.3, -49.0), 6: (-49.0, -118.3),
       7: (49.0, -118.3), 8: (118.3, -49.0)}
LAND = {1: (93.2, 33.8), 2: (37.9, 91.5), 3: (-37.9, 91.5), 4: (-89.8, 42.0), 5: (-91.5, -37.9), 6: (-40.2, -97.0),
        7: (42.0, -89.8), 8: (89.8, -42.0)}
PLAZA_R, ISLAND_R, BRIDGE_HALF = 68.0, 22.0, 5.0
RIM = {i: tuple(68.0 * c for c in unit(LAND[i])) for i in LAND}
PORTAL = (-36.8, -36.8)
PLAZA_PTS = [(30 * math.cos(math.radians(22.5 + 45 * k)), 30 * math.sin(math.radians(22.5 + 45 * k))) for k in range(8)]


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    L2 = ax * ax + az * az
    u = max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / L2))
    return math.hypot(p[0] - a[0] - u * ax, p[1] - a[1] - u * az)


def zone_of(p):
    if math.hypot(*p) <= PLAZA_R + 0.5:
        return ("P", 0)
    for i in ISL:
        if dist(p, ISL[i]) <= ISLAND_R + 0.5 or seg_dist(p, ISL[i], LAND[i]) <= 7:
            return ("I", i)
    best, bi = 1e9, 1
    for i in RIM:
        d = seg_dist(p, RIM[i], LAND[i])
        if d < best:
            best, bi = d, i
    if best <= BRIDGE_HALF + 0.5:
        return ("B", bi)
    return ("V", bi)   # the void (should not happen for walkers)


def walkable(p):
    return zone_of(p)[0] != "V"


def walk_route(a, b):
    """waypoints a -> b over the walkable map (island -> landing -> bridge -> plaza -> bridge -> landing -> island)"""
    za, zb = zone_of(a), zone_of(b)
    if za[0] == "V":
        za = ("B", za[1])
    if zb[0] == "V":
        zb = ("B", zb[1])
    if za == zb:
        return [b]
    if za[1] == zb[1] and {za[0], zb[0]} == {"I", "B"}:
        return [LAND[za[1]], b]
    pts = []
    if za[0] == "I":
        pts += [LAND[za[1]], RIM[za[1]]]
    elif za[0] == "B":
        pts += [RIM[za[1]]]
    if zb[0] == "I":
        pts += [RIM[zb[1]], LAND[zb[1]]]
    elif zb[0] == "B":
        pts += [RIM[zb[1]]]
    return pts + [b]


def route(a, b, jet=False):
    if jet and zone_of(a) != zone_of(b):
        return [b]   # with a jetpack every straight line is flyable (longest void stretch < one tank: section 2)
    return walk_route(a, b)


def path_len(a, pts):
    L, p = 0.0, a
    for q in pts:
        L += dist(p, q)
        p = q
    return L


def longest_void_on_segment(a, b, step=1.0):
    n = max(2, int(dist(a, b) / step))
    best = cur = 0.0
    for k in range(n + 1):
        u = k / n
        p = (a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u)
        if walkable(p):
            cur = 0.0
        else:
            cur += dist(a, b) / n
            best = max(best, cur)
    return best


def rand_on_island(rng, i, rmin=4, rmax=20):
    a = rng.uniform(0, 2 * math.pi)
    r = rng.uniform(rmin, rmax)
    return (ISL[i][0] + r * math.cos(a), ISL[i][1] + r * math.sin(a))


def rand_in_plaza(rng):
    r = 66 * math.sqrt(rng.random())
    a = rng.uniform(0, 2 * math.pi)
    return (r * math.cos(a), r * math.sin(a))


def physics_section():
    print("\n" + "=" * 100 + "\n## 1. PHYSICS: jump, jetpack, map\n" + "=" * 100)
    v0, apex, air, rng_ = jump_numbers()
    rows = [["plain jump", f"v0 {v0:.1f} studs/s", f1(apex), f"{air:.2f}", f0(rng_), "-"]]
    a, t, r, u = jet_flight(thrust_secs=2.5)
    rows.append(["jump + 2.5 s of thrust (the Studio test: +67)", "", f1(a), f"{t:.2f}", f0(r), f"{u:.1f}"])
    a, t, r, u = jet_flight("hold")
    rows.append(["jump + hold Space until empty (a kid)", "", f1(a), f"{t:.2f}", f0(r), f"{u:.1f}"])
    a2, t2, r2, u2 = jet_flight("pulse")
    rows.append(["jump + pulse (thrust only when falling = hover)", "", f1(a2), f"{t2:.2f}", f0(r2), f"{u2:.1f}"])
    a3, t3, r3, _ = jet_flight("hold", floor_drop=10)
    rows.append(["hold, landing 10 studs lower", "", f1(a3), f"{t3:.2f}", f0(r3), "3.0"])
    table("Jump and jetpack (one tank, integrated at 240 Hz; gravity felt 95; air speed 24)",
          ["flight", "launch", "apex (studs)", "air time (s)", "horizontal range (studs)", "fuel used (s)"], rows)
    print(f"- Ceiling = plaza floor + {JET['Ceiling']:.0f}: one tank tops out at ~{a:.0f} studs above take-off, so the"
          f" ceiling only matters if you take off from something high.")
    # gaps
    c1, c2 = ISL[1], ISL[2]
    cc = dist(c1, c2)
    gap_edge = cc - 2 * ISLAND_R
    land_land = dist(LAND[1], LAND[2])
    inner_edge = math.hypot(*ISL[1]) - ISLAND_R
    rows = [["adjacent island centres (45 deg)", f0(cc)],
            [f"void between adjacent islands (edge to edge, radius {ISLAND_R:.0f})", f0(gap_edge)],
            ["landing to adjacent landing, straight", f0(land_land)],
            ["island inner edge to the plaza rim (no bridge)", f0(inner_edge - PLAZA_R)],
            ["a plain jump covers", f0(rng_)],
            ["one jetpack tank covers (holding Space)", f0(r)]]
    table("Void gaps vs what you can cover", ["gap", "studs"], rows)
    # longest void stretch on straight lines between random walkable points
    rng = random.Random(11)
    worst = 0.0
    for _ in range(n_(600)):
        i, j = rng.sample(list(ISL), 2)
        a_ = rand_on_island(rng, i, 0, 20) if rng.random() < 0.7 else rand_in_plaza(rng)
        b_ = rand_on_island(rng, j, 0, 20)
        worst = max(worst, longest_void_on_segment(a_, b_, 2.0))
    print(f"- Longest stretch of void on ANY straight line between two walkable points (600 random lines): {worst:.0f}"
          f" studs < one tank ({r:.0f}). So with the jetpack every straight line is flyable.")
    rows = []
    for k in (1, 2, 3, 4):
        j = 1 + k
        w = path_len(LAND[1], walk_route(LAND[1], LAND[j]))
        s = dist(LAND[1], LAND[j])
        rows.append([f"{45 * k} deg", f0(w), f0(s), p0(1 - s / w), f1(w / 24), f1(s / 24 + 0.4), f1(w / 16.8)])
    table("Landing to landing: walking (bridges) vs flying straight",
          ["islands apart", "walk (studs)", "straight (studs)", "jetpack saves", "walk 24 (s)", "fly (s)",
           "carrier walk 16.8 (s)"], rows)
    return dict(apex=a, range_hold=r, range_pulse=r2, gap=gap_edge, worst_void=worst)


# ====================================================================================================================
# 3. HEIST AGENT SIM (2D, 10 Hz)
# ====================================================================================================================
RULES_NOW = dict(tackle_range=3.5, tackler_lock=1.5, dropper_lock=0.0, carry_limit=45, carry_speed=0.7, hold=0.5,
                 reach=10, bank=10, portal=True, jet=True, comet_timer=False)
# PROPOSED: the tackled carrier can't re-grab for 3 s, the tackler waits 1 s, ONE 35 s timer per comet (a re-grab doesn't
# reset it) of 40 s, no Black Hole portal while carrying
RULES_NEW = dict(RULES_NOW, tackler_lock=1.0, dropper_lock=3.0, carry_limit=40, portal=False, comet_timer=True)

DT = 0.1


class Agent:
    __slots__ = ("i", "typ", "h", "island", "crew", "pos", "route", "state", "t_engage", "lock", "hold_end", "ineff",
                 "jet", "chase_since", "next_plan", "smart", "role", "gain", "is_owner", "wait_until")

    def __init__(self, i, typ, island, crew, pos, rng):
        self.i, self.typ, self.h, self.island, self.crew, self.pos = i, typ, HT[typ], island, crew, pos
        self.route, self.state, self.t_engage, self.lock, self.hold_end = [], "idle", math.inf, -1.0, None
        self.ineff = rng.uniform(*self.h["ineff"])
        self.jet = rng.random() < self.h["jet"]
        self.smart = rng.random() < self.h["intercept"]
        self.chase_since, self.next_plan, self.role, self.gain, self.is_owner = 0.0, 0.0, "", 0.0, False
        self.wait_until = 0.0

    def speed(self, carrying, rules):
        v = WALK * self.h["stick"] / self.ineff
        return v * rules["carry_speed"] if carrying else v


def move(ag, v, dt):
    d = v * dt
    while d > 1e-9 and ag.route:
        q = ag.route[0]
        L = dist(ag.pos, q)
        if L <= d:
            ag.pos = q
            ag.route.pop(0)
            d -= L
        else:
            ag.pos = (ag.pos[0] + (q[0] - ag.pos[0]) * d / L, ag.pos[1] + (q[1] - ag.pos[1]) * d / L)
            d = 0


def plan_chase(ch, car, rules, t):
    """pure pursuit (head for where the carrier IS) or intercept (head for where it WILL be, on its way home)"""
    use_jet = rules["jet"] and ch.jet
    vch = ch.speed(False, rules) * (1.05 if use_jet else 1.0)
    if ch.smart and dist(ch.pos, car.pos) > 10:
        vc = car.speed(True, rules)
        pts = [car.pos] + list(car.route)
        s_acc, p = 0.0, pts[0]
        for q in pts[1:]:
            L = dist(p, q)
            nseg = max(1, int(L / 6))
            for k in range(1, nseg + 1):
                x = (p[0] + (q[0] - p[0]) * k / nseg, p[1] + (q[1] - p[1]) * k / nseg)
                s = s_acc + L * k / nseg
                tc = s / vc
                tch = path_len(ch.pos, route(ch.pos, x, use_jet)) / vch + 0.3
                if tch <= tc:
                    ch.route = route(ch.pos, x, use_jet)
                    return
            s_acc += L
            p = q
    ch.route = route(ch.pos, car.pos, use_jet)


def simulate(agents, comet_pos, owner_i, rules, rng, carried_by=None, tmax=120.0, protected=False):
    """one loose comet from landing (or from the grab, if carried_by is set) to the end.
    Returns dict(outcome, banker, t, tackles, carry_times)."""
    byi = {a.i: a for a in agents}
    owner = byi.get(owner_i)
    comet = {"pos": comet_pos, "carrier": None, "carry_t0": 0.0}
    tackles, carry_times, t = 0, [], 0.0
    portal_used = False

    def start_carry(a, t):
        comet["carrier"] = a.i
        if not (rules["comet_timer"] and comet.get("grabbed")):
            comet["carry_t0"] = t
        comet["grabbed"] = True
        a.state = "carry"
        a.route = walk_route(a.pos, LAND[a.island])
        a.wait_until = t + rng.uniform(*a.h["hes"])   # turning round + "which bridge is mine?"
        if rng.random() < a.h["lost"]:
            a.wait_until += rng.uniform(3, 10)           # walked the wrong way first / looked for the island
        # who chases: the owner (toast "X IS TAKING YOUR COMET!"), others already on the way
        for b in agents:
            if b is a or b.crew == a.crew:
                if b.state in ("go", "chase"):
                    b.state = "escort"
                continue
            if b.state == "go":
                b.state = "chase" if (b.is_owner or rng.random() < b.h["chase_other"]) else "out"
                b.chase_since, b.next_plan = t, t
            elif b.is_owner and b.state == "idle" and b.role != "afk":
                n = notice(b.h, rng, b.h["tau_toast"] * 0.6, b.h["never_owner"])
                if rng.random() < b.h["chase_owner"]:
                    b.t_engage = min(b.t_engage, t + n + decide(b.h, rng, 2))
                    b.role = "late_chaser"

    if carried_by is not None:
        c = byi[carried_by]
        c.pos = comet_pos
        start_carry(c, 0.0)

    while t < tmax:
        t += DT
        car = byi[comet["carrier"]] if comet["carrier"] is not None else None
        if car is None and rules["comet_timer"] and comet.get("grabbed") and t - comet["carry_t0"] > rules["carry_limit"]:
            return dict(outcome="burst", banker=None, t=t, tackles=tackles, carry=carry_times, portal=portal_used)
        # engage (noticed + decided)
        for a in agents:
            if a.state == "idle" and t >= a.t_engage:
                if car is None:
                    a.state = "go"
                elif a.crew != car.crew:
                    a.state, a.chase_since, a.next_plan = "chase", t, t
                else:
                    a.state = "out"
        active = False
        for a in agents:
            if a.state == "go" and car is None:
                active = True
                d = dist(a.pos, comet["pos"])
                if d <= rules["reach"] * 0.6:
                    a.route = []
                elif not a.route or dist(a.route[-1], comet["pos"]) > 1:
                    a.route = route(a.pos, comet["pos"], rules["jet"] and a.jet)
                move(a, a.speed(False, rules), DT)
                # grab / hold
                if dist(a.pos, comet["pos"]) <= rules["reach"] and t >= a.lock and not (protected and not a.is_owner):
                    if a.hold_end is None:
                        a.hold_end = t + rt(a.h, rng) * 0.5 + a.h["press"] + (0 if a.is_owner else rules["hold"])
                    elif t >= a.hold_end:
                        a.hold_end = None
                        if a.is_owner:
                            return dict(outcome="owner", banker=a.i, t=t, tackles=tackles, carry=carry_times,
                                        portal=portal_used)
                        start_carry(a, t)
                        for b in agents:
                            b.hold_end = None
                        car = a
                        break
                else:
                    a.hold_end = None
            elif a.state == "chase" and car is not None:
                active = True
                if t - a.chase_since > a.h["giveup"]:
                    a.state = "out"
                    continue
                if t >= a.next_plan:
                    plan_chase(a, car, rules, t)
                    a.next_plan = t + a.h["replan"] * rng.uniform(0.7, 1.3)
                move(a, a.speed(False, rules) * (1.05 if (rules["jet"] and a.jet) else 1.0), DT)
            elif a.state == "escort":
                pass
        car = byi[comet["carrier"]] if comet["carrier"] is not None else None
        if car is not None:
            active = True
            if t >= car.wait_until:
                # the Black Hole portal: a chased carrier crossing the plaza may dive in
                if (rules["portal"] and not portal_used and zone_of(car.pos)[0] == "P"
                        and any(b.state == "chase" and dist(b.pos, car.pos) < 30 for b in agents)
                        and dist(car.pos, PORTAL) < 45 and rng.random() < car.h["portal"] * DT * 3):
                    portal_used = True
                    car.route = [PORTAL]
                if portal_used and car.route == [PORTAL] and dist(car.pos, PORTAL) < 3:
                    dest = rng.choice([("L", k) for k in LAND] + [("P", k) for k in range(8)])
                    car.wait_until = t + 1.2
                    car.pos = LAND[dest[1]] if dest[0] == "L" else PLAZA_PTS[dest[1]]
                    car.route = walk_route(car.pos, LAND[car.island])
                    for b in agents:
                        if b.state == "chase":
                            b.next_plan = t + rng.uniform(1.0, 3.0)   # "where did he go?"
                else:
                    move(car, car.speed(True, rules), DT)
            if dist(car.pos, LAND[car.island]) <= rules["bank"]:
                carry_times.append(t - comet["carry_t0"])
                return dict(outcome="thief" if car.crew != (owner.crew if owner else -1) else "crew", banker=car.i,
                            t=t, tackles=tackles, carry=carry_times, portal=portal_used)
            if t - comet["carry_t0"] > rules["carry_limit"] or (rules["comet_timer"] and comet.get("grabbed")
                                                                 and t - comet["carry_t0"] > rules["carry_limit"]):
                carry_times.append(t - comet["carry_t0"])
                return dict(outcome="burst", banker=None, t=t, tackles=tackles, carry=carry_times, portal=portal_used)
            # tackles
            for b in agents:
                if b is car or b.crew == car.crew or b.state not in ("chase", "go"):
                    continue
                if dist(b.pos, car.pos) <= rules["tackle_range"]:
                    tackles += 1
                    carry_times.append(t - comet["carry_t0"])
                    comet["carrier"] = None
                    comet["pos"] = car.pos
                    b.lock = max(b.lock, t + rules["tackler_lock"])
                    car.lock = max(car.lock, t + rules["dropper_lock"])
                    car.state = "go" if rng.random() < car.h["regrab"] else "out"
                    car.route = []
                    for x in agents:
                        if x.state in ("chase", "escort"):
                            x.state = "go"
                            x.route = []
                    b.state = "go"
                    break
        if not active and all(a.state not in ("idle",) or a.t_engage == math.inf for a in agents):
            return dict(outcome="unclaimed", banker=None, t=t, tackles=tackles, carry=carry_times, portal=portal_used)
    return dict(outcome="timeout", banker=None, t=t, tackles=tackles, carry=carry_times, portal=portal_used)


# ---- 3a. carry times with nobody chasing (is CarryLimit right?)
def carry_time_section():
    rng = random.Random(21)
    rows = []
    res = {}
    for typ in TYPES:
        for k in (1, 2, 4):
            ts = []
            for _ in range(n_(400)):
                th = Agent(0, typ, 1 + k, 0, None, rng)
                spot = rand_on_island(rng, 1, 9, 18)
                r = simulate([th], spot, -1, RULES_NOW, rng, carried_by=0, tmax=200)
                ts.append(r["carry"][-1] + 0.5 + th.h["press"])   # + the grab
            res[(typ, k)] = ts
            rows.append([typ, f"{45 * k} deg", f1(pct(ts, 50)), f1(pct(ts, 95)), f1(pct(ts, 99)), f1(max(ts))])
    table("Grab -> bank with NOBODY chasing (time from the start of the hold, s)",
          ["thief", "home island is", "median", "p95", "p99", "worst"], rows)
    worst_p99 = pct(res[("mobile", 4)], 99)
    print(f"- A mobile kid going the FAR way (180 deg) needs {worst_p99:.0f} s at the 99th percentile."
          f" CarryLimit 45 is {45 - worst_p99:.0f} s more than they need.")
    return res


# ---- 3b. duels: thief type x defender type x distance x where the defender starts
def duel(thief_t, def_t, k, start, rules, rng, defender_jet=None):
    owner_island, thief_island = 1, 1 + k
    spot = rand_on_island(rng, owner_island, 9, 18)
    th = Agent(0, thief_t, thief_island, 0, spot, rng)
    if start == "home":
        p = rand_on_island(rng, owner_island, 4, 20)
        while dist(p, spot) < 12:   # (if he were right there he'd have grabbed it first)
            p = rand_on_island(rng, owner_island, 4, 20)
    elif start == "plaza":
        p = rand_in_plaza(rng)
    else:
        p = rand_on_island(rng, rng.choice([5, 6, 7]), 4, 20)
    ow = Agent(1, def_t, owner_island, 1, p, rng)
    ow.is_owner = True
    if defender_jet is not None:
        ow.jet = defender_jet
    r = simulate([th, ow], spot, 1, rules, rng, carried_by=0, tmax=120)
    return r


def duel_section():
    print("\n" + "=" * 100 + "\n## 2. HEISTS: duels (one thief carrying, the owner chasing after the toast)\n" + "=" * 100)
    rng = random.Random(31)
    N = n_(160)
    out = {}
    rows = []
    for tt in TYPES:
        for dt_ in TYPES:
            line = [tt, dt_]
            for start in ("home", "plaza", "far"):
                for k in (1, 4):
                    s = [duel(tt, dt_, k, start, RULES_NOW, rng) for _ in range(N)]
                    w = sum(r["outcome"] == "thief" for r in s) / N
                    out[(tt, dt_, start, k)] = s
                    line.append(p0(w))
            rows.append(line)
    table("Steal success (grab -> bank) when the OWNER is awake and chases; current rules",
          ["thief", "owner", "home 45", "home 180", "plaza 45", "plaza 180", "far 45", "far 180"], rows)
    # outcome mix + tackles + stuck loops (current vs proposed)
    rows = []
    for name, rules in (("now", RULES_NOW), ("proposed", RULES_NEW)):
        rr = []
        for tt in TYPES:
            for dt_ in TYPES:
                for start in ("home", "plaza"):
                    for k in (1, 2, 4):
                        rr += [duel(tt, dt_, k, start, rules, rng) for _ in range(max(10, N // 4))]
        n = len(rr)
        rows.append([name, p0(sum(r["outcome"] == "thief" for r in rr) / n), p0(sum(r["outcome"] == "owner" for r in rr) / n),
                     p0(sum(r["outcome"] == "burst" for r in rr) / n), p0(sum(r["outcome"] == "timeout" for r in rr) / n),
                     f1(statistics.mean(r["tackles"] for r in rr)),
                     p0(sum(r["tackles"] >= 3 for r in rr) / n),
                     f1(pct([r["t"] for r in rr], 50)), f1(pct([r["t"] for r in rr], 95))])
    table("All duels (owner home/plaza, 45/90/180 deg, every type pair): outcomes, current vs proposed tackle rules",
          ["rules", "thief banks", "owner gets it back", "burst (time out)", "stuck >120 s (tackle loop)",
           "tackles per heist", "3+ tackles", "median length (s)", "p95 length (s)"], rows)
    # jetpack effect for defenders, portal effect
    rows = []
    for label, rules, dj in (("owner WITH jetpack", dict(RULES_NOW, portal=False), True),
                             ("owner WITHOUT jetpack", dict(RULES_NOW, portal=False), False),
                             ("portal allowed for carriers", dict(RULES_NOW, portal=True), None),
                             ("portal blocked for carriers", dict(RULES_NOW, portal=False), None)):
        rr = []
        for tt in TYPES:
            for dt_ in TYPES:
                for start in ("plaza", "far"):
                    for k in (1, 2, 4):
                        rr += [duel(tt, dt_, k, start, rules, rng, defender_jet=dj) for _ in range(max(10, N // 5))]
        n = len(rr)
        rows.append([label, p0(sum(r["outcome"] == "thief" for r in rr) / n),
                     p0(sum(r["portal"] for r in rr) / n), f1(statistics.mean(r["tackles"] for r in rr))])
    table("Jetpack (defender) and the Black Hole portal (carrier), owner starts on the plaza / far island",
          ["case", "thief banks", "carrier used the portal", "tackles per heist"], rows)
    rows = []
    for label, ch in (("TackleRange 2.5", dict(tackle_range=2.5)), ("TackleRange 3.5 (now)", {}),
                      ("TackleRange 5", dict(tackle_range=5.0)), ("CarrySpeed 0.6", dict(carry_speed=0.6)),
                      ("CarrySpeed 0.8", dict(carry_speed=0.8))):
        rules = dict(RULES_NEW, **ch)
        rr = []
        for tt in TYPES:
            for dt_ in TYPES:
                for start in ("home", "plaza"):
                    for k in (1, 2, 4):
                        rr += [duel(tt, dt_, k, start, rules, rng) for _ in range(max(8, N // 6))]
        n = len(rr)
        pc_ = [r for r, (tt, dt_) in zip(rr, [(a, b) for a in TYPES for b in TYPES for _s in range(2) for _k in range(3)
                                              for _ in range(max(8, N // 6))]) if dt_ != "mobile"]
        rows.append([label, p0(sum(r["outcome"] == "thief" for r in rr) / n),
                     p0(sum(r["outcome"] == "thief" for r in pc_) / max(1, len(pc_))),
                     f1(statistics.mean(r["tackles"] for r in rr))])
    HT["mobile_arrow"] = dict(HT["mobile"], tau_toast=1.5, never_owner=0.04, dec=1.0, intercept=0.5)
    rows2 = []
    for label, ow in (("phone owner (now)", "mobile"), ("phone owner + a CHASE! arrow on the toast", "mobile_arrow")):
        rr = []
        for tt in TYPES:
            for start in ("home", "plaza"):
                for k in (1, 2, 4):
                    rr += [duel(tt, ow, k, start, RULES_NEW, rng) for _ in range(max(10, N // 3))]
        rows2.append([label, p0(sum(r["outcome"] == "thief" for r in rr) / len(rr))])
    del HT["mobile_arrow"]
    table("Phone owners: does a CHASE! arrow (toast + arrow to the carrier: notice 1.5 s, decide 1 s) help? (proposed rules)",
          ["owner", "thief banks"], rows2)
    table("Sensitivity (proposed rules; owner home or plaza; all type pairs)",
          ["setting", "thief banks (all owners)", "thief banks (PC owners)", "tackles per heist"], rows)
    return out


# ---- 3c. the portal as pure maths (where a carrier lands)
def portal_maths():
    own = 1 / 16
    rows = []
    for k_name, home in (("from the portal", PORTAL),):
        t_walk = path_len(home, walk_route(home, LAND[1])) / 16.8
        lands = []
        for i in LAND:
            lands.append(0 if i == 1 else path_len(LAND[i], walk_route(LAND[i], LAND[1])) / 16.8)
        for p in PLAZA_PTS:
            lands.append(path_len(p, walk_route(p, LAND[1])) / 16.8)
        exp_after = 1.2 + statistics.mean(lands)
        rows.append([k_name, f1(t_walk), f1(exp_after), p0(own), p0(sum(1 for x in lands if x < t_walk - 1.2) / 16)])
    table("Carrier at the portal, home = Island_1: walk on vs dive in (s at 16.8, no chaser)",
          ["", "walk home", "portal, expected", "instant bank (own landing)", "portal is quicker"], rows)


# ---- 3d. whole servers: every player a random kid type, comet on a random island
def server_event(N, rules, rng, crews=None, eligible_new=0.0, track=None):
    """one loose comet in a server of N players. crews: list of crew ids per player (default all solo).
    Returns per-player gains (in seconds of income) and the event result."""
    crews = crews or list(range(N))
    agents = []
    for i in range(N):
        typ = pick_type(rng) if track is None or i >= len(track) else track[i]
        h = HT[typ]
        u = rng.random()
        if u < h["loc"][0]:
            pos = rand_on_island(rng, i + 1)
        elif u < h["loc"][0] + h["loc"][1]:
            pos = rand_in_plaza(rng)
        else:
            pos = rand_on_island(rng, rng.choice([k for k in range(1, 9) if k != i + 1]))
        a = Agent(i, typ, i + 1, crews[i], pos, rng)
        a.role = "afk" if rng.random() < h["afk"] else ""
        agents.append(a)
    o = rng.randrange(N)
    owner = agents[o]
    owner.is_owner = True
    protected = rng.random() < eligible_new    # the owner has no Supernova yet: only he may take it
    spot = rand_on_island(rng, o + 1, 9, 18)
    for a in agents:
        if a.role == "afk":
            continue
        if a.is_owner:
            n = notice(a.h, rng, a.h["tau_toast"] * 0.6, a.h["never_owner"])
            a.t_engage = n + decide(a.h, rng, 2)
            if rng.random() > a.h["chase_owner"]:
                a.t_engage = math.inf
        elif a.crew == owner.crew:
            n = notice(a.h, rng, a.h["tau_toast"], a.h["never_other"])
            a.t_engage = math.inf if rng.random() < 0.7 else n + decide(a.h, rng)   # (crewmates mostly leave it)
        elif not protected:
            n = notice(a.h, rng, a.h["tau_toast"], a.h["never_other"])
            dtrip = path_len(a.pos, walk_route(a.pos, spot)) / (WALK * a.h["stick"] / a.ineff)
            p = a.h["p_go"] * (0.5 if dtrip > 12 and a.typ == "grinder" else 1.0)
            a.t_engage = n + decide(a.h, rng) if rng.random() < p else math.inf
    r = simulate(agents, spot, o, rules, rng, protected=protected)
    gains = [0.0] * N
    if r["outcome"] == "owner":
        gains[o] = 2.0
    elif r["outcome"] in ("thief", "crew"):
        gains[r["banker"]] = 1.0
    r["owner"] = o
    r["types"] = [a.typ for a in agents]
    r["gains"] = gains
    return r


def server_section(phys):
    print("\n" + "=" * 100 + "\n## 3. HEISTS: whole servers (random kid mix 20% grinder / 30% chaos / 50% mobile)\n" + "=" * 100)
    rng = random.Random(41)
    pools = {}
    for N in (3, 6, 8):
        pools[N] = [server_event(N, RULES_NOW, rng) for _ in range(n_(700))]
    rows = []
    for N, pool in pools.items():
        n = len(pool)
        oc = lambda k: sum(r["outcome"] == k for r in pool) / n
        rows.append([N, p0(oc("owner")), p0(oc("thief")), p0(oc("unclaimed")), p0(oc("burst") + oc("timeout")),
                     f1(statistics.mean(r["tackles"] for r in pool)), f1(pct([r["t"] for r in pool if r["outcome"] != "unclaimed"], 50))])
    for N in (6, 8):
        pool = [server_event(N, RULES_NEW, rng) for _ in range(n_(700))]
        n = len(pool)
        oc = lambda k: sum(r["outcome"] == k for r in pool) / n
        rows.append([f"{N}, PROPOSED rules", p0(oc("owner")), p0(oc("thief")), p0(oc("unclaimed")), p0(oc("burst") + oc("timeout")),
                     f1(statistics.mean(r["tackles"] for r in pool)), f1(pct([r["t"] for r in pool if r["outcome"] != "unclaimed"], 50))])
        cont = [r for r in pool if r["tackles"] > 0]
        print(f"- {N} players, proposed rules: {len(cont) / n * 100:.0f}% of comets get tackled at least once;"
              f" of those, {sum(r['tackles'] >= 2 for r in cont) / max(1, len(cont)) * 100:.0f}% have a CHAIN (2+ tackles).")
    for N in (6, 8):
        pool = pools[N]
        cont = [r for r in pool if r["tackles"] > 0]
        print(f"- {N} players, current rules: {len(cont) / len(pool) * 100:.0f}% tackled at least once;"
              f" of those, {sum(r['tackles'] >= 2 for r in cont) / max(1, len(cont)) * 100:.0f}% have 2+ tackles"
              f" (mostly the same two kids: tackle, re-grab in ~1 s, tackle...).")
    table("What happens to a loose comet",
          ["players", "owner grabs it", "stolen + banked", "nobody comes (fades)", "burst / stuck", "tackles", "median s to resolve"], rows)
    return pools


# ---- income: sky comets (normal play) vs heists
def normal_income_per_hour(typ, catch, comet_every=35, comet_value_s=67):
    """seconds of income earned per hour of play: passive 3600 + sky comets (mid-game: Comet Value perks, golden)"""
    return 3600 + 3600 / comet_every * catch * comet_value_s


def heist_income_table(pools, catch):
    """per player type: heist seconds-of-income per hour = events/h x gain/event x Value; for LooseEvery options"""
    rows, best = [], {}
    configs = [("now: LooseEvery 60, Value 120", lambda N: 60, 120),
               ("per island: 600/N s, Value 120", lambda N: max(45, min(180, 600 / N)), 120),
               ("per island: 600/N s, Value 90", lambda N: max(45, min(180, 600 / N)), 90)]
    for label, every, value in configs:
        for N, pool in pools.items():
            ev_h = 3600 / every(N)
            line = [label, N, f0(every(N))]
            for typ in TYPES:
                g, cnt, gown, gsteal = 0.0, 0, 0.0, 0.0
                for r in pool:
                    for i, tp in enumerate(r["types"]):
                        if tp == typ:
                            cnt += 1
                            g += r["gains"][i]
                            if i == r["owner"]:
                                gown += r["gains"][i]
                            else:
                                gsteal += r["gains"][i]
                if cnt == 0:
                    line.append("-")
                    continue
                per_h = ev_h * g / cnt * value
                base = normal_income_per_hour(typ, catch[typ])
                line.append(f"{per_h / base * 100:.0f}% ({per_h / 3600 * 100:.0f}%)")
                best[(label, N, typ)] = (per_h, base, ev_h * gown / cnt * value, ev_h * gsteal / cnt * value)
            rows.append(line)
    table("Heist income on top of normal play, % of (passive + sky comets)  [in brackets: % of passive income only]",
          ["setting", "players", "LooseEvery (s)", "grinder", "chaos", "mobile"], rows)
    return best


def active_heister_table(pools, catch):
    """an ACTIVE heister (always goes, always chases) vs an AFK-ish kid, same server"""
    rng = random.Random(43)
    rows = []
    for N in (3, 6, 8):
        for who, typ, tweak in (("active chaos heister", "chaos", dict(p_go=1.0, chase_other=1.0, afk=0.0, never_other=0.05)),
                                ("AFK-ish mobile kid", "mobile", dict(afk=0.6, p_go=0.1))):
            HT["_x"] = dict(HT[typ], **tweak)
            g = gown = gst = 0.0
            M = n_(500)
            for _ in range(M):
                track = ["_x"] + [pick_type(rng) for _ in range(N - 1)]
                r = server_event(N, RULES_NOW, rng, track=track)
                g += r["gains"][0]
                if r["owner"] == 0:
                    gown += r["gains"][0]
                else:
                    gst += r["gains"][0]
            del HT["_x"]
            for label, every, value in (("now (60 s, 120)", 60, 120), ("proposed (600/N, 120)", max(45, min(180, 600 / N)), 120)):
                ev_h = 3600 / every
                per_h = ev_h * g / M * value
                base = normal_income_per_hour(typ, catch[typ] if who.startswith("active") else catch[typ] * 0.5)
                rows.append([who, N, label, f0(ev_h * gown / M * value), f0(ev_h * gst / M * value), f"{per_h / base * 100:.0f}%"])
    table("Active heister vs AFK-ish kid: heist seconds-of-income per hour (own-island grabs / steals) and % on top of normal",
          ["player", "players", "setting", "own grabs (s/h)", "steals (s/h)", "% on top"], rows)


# ====================================================================================================================
# 4. CREWS: Core fill, gather, reward
# ====================================================================================================================
def crew_core_section():
    print("\n" + "=" * 100 + "\n## 4. CREW CORE + CREW SUPERNOVA\n" + "=" * 100)
    rng = random.Random(51)
    rows = []
    fill = {}
    for N in (4, 6, 8):
        for k in (1, 2, 3, 4):
            if k > N:
                continue
            crews = [0] * k + list(range(1, N - k + 1))
            pts = 0.0
            M = n_(260)
            for _ in range(M):
                r = server_event(N, RULES_NOW, rng, crews=crews)
                b = r["owner"] if r["outcome"] == "owner" else r["banker"]
                if b is not None and crews[b] == 0:
                    pts += 1
            per_ev = pts / M
            line = [N, k]
            for label, every in (("now", 60), ("600/N", max(45, min(180, 600 / N)))):
                ph = 3600 / every * per_ev
                fill[(N, k, label)] = 10 / ph * 60 if ph > 0 else math.inf
                line += [f1(ph), f0(10 / ph * 60) if ph > 0 else "-"]
            rows.append(line)
    table("Crew Core points per hour and minutes to fill 10 points (active players, random kid mix)",
          ["players", "crew size", "pts/h now (60 s)", "min to 10 now", "pts/h at 600/N s", "min to 10 at 600/N"], rows)
    return fill


def gather_once(types, G, rng, rule="all", afk_scale=1.0):
    """the Core is full: every crewmate must stand in the 9-stud ring at the leader's landing within G s"""
    leader_island = 1
    arrive = []
    for m, typ in enumerate(types):
        h = HT[typ]
        if rng.random() < h["afk"] * afk_scale:
            arrive.append(math.inf)
            continue
        own = 1 + (m * 3) % 8 if m else leader_island
        u = rng.random()
        if u < h["loc"][0]:
            pos = rand_on_island(rng, own)
        elif u < h["loc"][0] + h["loc"][1]:
            pos = rand_in_plaza(rng)
        else:
            pos = rand_on_island(rng, rng.randrange(1, 9))
        n = notice(h, rng, h["tau_crew"], h["never_crew"])
        if n == math.inf:
            # the orb + the CREW badge: a second chance to notice
            n = 8 + rng.expovariate(1 / 10)
        jet = rng.random() < h["jet"]
        L = path_len(pos, route(pos, LAND[leader_island], jet))
        v = WALK * h["stick"] / rng.uniform(*h["ineff"]) * (1.05 if jet else 1)
        arrive.append(n + decide(h, rng, 2) + max(0.0, L - 7) / v)
    if rule == "all":
        return max(arrive) <= G
    # proposed: whoever is in the ring when the time is up counts, at least 2 (or everyone if the crew is 2)
    ok = sum(1 for a in arrive if a <= G)
    return ok >= min(2, len(types))


def gather_section():
    rng = random.Random(53)
    rows = []
    res = {}
    for label, comp in (("2 grinders", ["grinder"] * 2), ("2 mixed", None), ("3 mixed", None), ("4 mixed", None),
                        ("4 mobile kids", ["mobile"] * 4)):
        k = int(label[0])
        line = [label]
        for G in (30, 45, 60):
            M = n_(2000)
            ok = 0
            for _ in range(M):
                types = comp or [pick_type(rng) for _ in range(k)]
                ok += gather_once(types, G, rng)
            res[(label, G)] = ok / M
            line.append(p0(ok / M))
        M = n_(2000)
        ok = 0
        for _ in range(M):
            types = comp or [pick_type(rng) for _ in range(k)]
            ok += gather_once(types, 45, rng, rule="present")
        line.append(p0(ok / M))
        rows.append(line)
    table("Gather: chance the WHOLE crew is in the ring in time (AFK kids included; a missed toast gets a 2nd chance from the orb)",
          ["crew", "30 s (now)", "45 s", "60 s", "45 s, 'whoever is in the ring counts (min 2)'"], rows)
    # arrival time breakdown for a mobile kid, far side
    rng = random.Random(54)
    rows = []
    for typ in TYPES:
        h = HT[typ]
        ns, ds, ws = [], [], []
        for _ in range(2000):
            n = notice(h, rng, h["tau_crew"], 0)
            ns.append(n)
            ds.append(decide(h, rng, 2))
            pos = rand_on_island(rng, 5)
            L = path_len(pos, walk_route(pos, LAND[1]))
            ws.append(L / (WALK * h["stick"] / rng.uniform(*h["ineff"])))
        rows.append([typ, f1(pct(ns, 50)), f1(pct(ns, 90)), f1(pct(ds, 50)), f1(pct(ds, 90)), f1(pct(ws, 50)), f1(pct(ws, 90)),
                     f1(pct([a + b + c for a, b, c in zip(ns, ds, ws)], 90))])
    table("Gather time parts for a crewmate on the FAR island (180 deg) who does notice, s",
          ["kid", "notice p50", "notice p90", "decide p50", "decide p90", "walk p50", "walk p90", "total p90"], rows)
    return res


def crew_reward_section(fill, gather_ok):
    rows = []
    for label, N, k, G in (("solo, 8 players", 8, 1, "2 mixed"), ("crew of 2, 8 players", 8, 2, "2 mixed"),
                           ("crew of 3, 8 players", 8, 3, "3 mixed"), ("crew of 4, 8 players", 8, 4, "4 mixed"),
                           ("crew of 4, 6 players", 6, 4, "4 mixed")):
        for setting in ("now", "600/N"):
            m = fill[(N, k, setting)]
            p = 1.0 if k == 1 else gather_ok[(G, 30)]
            # a failed gather: assume the Core stays full and they try again (~+3 min each time)
            per = m + (1 / p - 1) * 3
            n_cap_now = 0.40 / 0.02
            n_cap_new = 0.30 / 0.02
            rows.append([label, setting, f0(per), f1(n_cap_now * per / 60), f1(n_cap_new * per / 60),
                         p0(10 / per)])
    table("Crew Supernovas: minutes between them, hours of play to the permanent cap, and what the x2 10 min adds",
          ["crew", "loose comets", "min per Crew Supernova", "h to cap now (+2% x20 = 40%)", "h to cap at +2% x15 = 30%",
           "x2 10 min = income on top"], rows)


# ====================================================================================================================
# 5. FORGE: sky comets, Essence, rolls per player-hour, SECRET, mutations
# ====================================================================================================================
def sky_comet(h, rng):
    """one comet in the sky, alive 9 s: notice -> (camera turn) -> aim + click/tap (Fitts, moving) -> retries"""
    if rng.random() < h["afk_sky"]:
        return False, None
    busy = rng.random() < h["busy"]
    tau = h["tau_sky"] * (2.0 if busy else 1.0)
    if rng.random() < h["on_screen"]:
        t = rt(h, rng) + rng.expovariate(1 / tau)
    else:
        if rng.random() > h["hear"]:
            return False, None
        if rng.random() < h["no_turn"]:
            return False, None
        t = rt(h, rng) + rng.expovariate(1 / (h["tau_off"] * (2.0 if busy else 1.0))) + lnm(rng, h["cam"], h["cam_sig"]) + 0.3
    if rng.random() < h["lapse"]:
        t += rng.uniform(*h["lapse_s"])
    D = rng.uniform(*h["D"])
    t += h["fa"] + h["fb"] * (math.log2(D / h["W"] + 1) + 0.6)     # +0.6 bit: a moving target
    tries = 0
    while rng.random() < h["miss"] and tries < 6:
        t += h["retry"]
        tries += 1
    return t <= 9.0, t


def comet_section():
    print("\n" + "=" * 100 + "\n## 3b. SKY COMETS (normal play: for the income comparison and the Forge)\n" + "=" * 100)
    rng = random.Random(61)
    catch, rows = {}, []
    for typ in TYPES:
        h = HT[typ]
        res = [sky_comet(h, rng) for _ in range(n_(20000))]
        ok = [t for c, t in res if c]
        catch[typ] = len(ok) / len(res)
        rows.append([typ, h["device"], p0(catch[typ]), f1(pct(ok, 50)), f1(pct(ok, 90))])
    table("Sky comets (live 9 s; notice + camera + Fitts tap): catch rate", ["kid", "device", "caught", "time to catch p50 (s)",
                                                                              "p90 (s)"], rows)
    return catch


# Supernova times (real minutes) from the Studio bot, run 4 (6 Nov): before + after Ignition 1 (26.2)
BOT_NOVAS = [2.6, 4.3, 6.5, 8.4, 10.8, 13.7, 16.1, 17.5, 20.0, 21.6, 23.8, 29.6, 31.8, 33.2, 36.4, 41.1, 48.1, 54.7, 61.5,
             67.8, 71.4, 84.1]
BOT_IGNITION = 26.2
ESS_AT_IGNITION = 37.0        # tutorial steps (~24) + Ignition's 10 + the first gifts (the bot had ~47 incl. daily)
GIFT_ROLL_AT = 2.5            # LUMI's free first roll right after the first tutorial (~2.5 min)


def nova_times(f, until_min):
    ts = [f * x for x in BOT_NOVAS]
    gap = 10.0
    while ts[-1] < until_min:
        ts.append(ts[-1] + f * gap)
        gap = min(14.0, gap + 0.15)
    return ts


def essence_curve(typ, catch, comets_per, minutes=6000, vip=False):
    """cumulative Forge rolls by active minute (Essence is spent as soon as the Forge is open)"""
    h = HT[typ]
    f = h["speed"]
    ign = BOT_IGNITION * f
    novas = nova_times(f, minutes)
    S = h["session"]
    # daily: streak (avg ~2.8 of 2-5), quests (3 a day, sized to ~30 min), playtime gifts 10 / 20 (+60: 2)
    daily = 2.8 + 3 * min(1.0, S / 30) * 0.85 + (1 if S >= 10 else 0) + (1 if S >= 20 else 0) + (2 if S >= 60 else 0)
    daily_rate = daily / S      # per active minute
    comet_rate = 60 / h["lure_every"] * catch[typ]   # caught per minute after Ignition
    out = [0.0] * (minutes + 1)
    ess, ign_paid = 0.0, False
    ni = 0
    comets_caught = 0.0
    for m in range(1, minutes + 1):
        ess += daily_rate
        while ni < len(novas) and novas[ni] <= m:
            n = ni + 1
            if novas[ni] >= ign:
                ess += 1 + n // 5 + (1 if vip else 0)
            ni += 1
        if m >= ign:
            comets_caught += comet_rate
            ess += comets_caught // comets_per
            comets_caught -= (comets_caught // comets_per) * comets_per
        if m >= ign and not ign_paid:
            ign_paid = True
            ess += ESS_AT_IGNITION
        rolls = ess if m >= ign else 0.0
        out[m] = rolls + (1 if m >= GIFT_ROLL_AT else 0)
    return out, ign


def forge_rates_section(catch):
    print("\n" + "=" * 100 + "\n## 5. STAR FORGE: Essence, rolls, SECRET, mutations\n" + "=" * 100)
    rows = []
    curves = {}
    for cp in (25, 10):
        for typ in TYPES:
            c, ign = essence_curve(typ, catch, cp)
            curves[(typ, cp)] = (c, ign)
            i0 = int(ign) + 1
            h1 = c[min(i0 + 60, 6000)] - c[i0]
            h23 = (c[min(i0 + 180, 6000)] - c[min(i0 + 60, 6000)]) / 2
            h4_10 = (c[min(i0 + 600, 6000)] - c[min(i0 + 180, 6000)]) / 7
            comet_ess = 60 * 60 / HT[typ]["lure_every"] * catch[typ] / cp
            rows.append([cp, typ, f0(ign), f0(c[i0] - c[i0 - 2]), f0(h1), f0(h23), f0(h4_10), f1(comet_ess)])
    table("Forge rolls per hour of play AFTER Ignition 1 (Essence spent at once); ~45 saved Essence lands as a burst at Ignition",
          ["CometsPerNext", "kid", "Ignition at (min)", "burst at Ignition", "hour 1", "hours 2-3 (per h)", "hours 4-10 (per h)",
           "of which comets (per h)"], rows)
    return curves


def population_section(curves):
    """rolls per player-hour over ALL players (most never reach Ignition) -> the real SECRET rate"""
    rng = random.Random(71)
    scen = [("today: 3.5 min/DAU", 2.5, 1.3), ("after the pacing fix (~25 min/DAU)", 12, 1.6),
            ("healthy, returning players", 20, 1.9)]
    rows, rph = [], {}
    for name, med, sig in scen:
        for cp in (25, 10):
            tot_rolls = tot_h = gift = 0.0
            reach = 0
            P = n_(40000)
            for _ in range(P):
                typ = pick_type(rng)
                L = min(5999, lnm(rng, med, sig))
                c, ign = curves[(typ, cp)]
                tot_rolls += c[int(L)]
                gift += 1 if L >= GIFT_ROLL_AT else 0
                tot_h += L / 60
                reach += L >= ign
            r = tot_rolls / tot_h
            rph[(name, cp)] = r
            q = 1 / (2000 * 8)
            rows.append([name, cp, f1(statistics.mean([0]) + tot_h / P * 60), p0(reach / P), f1(r), f1((tot_rolls - gift) / tot_h),
                         f0(1 / (r * q)), f0(r)])
    table("Rolls per player-hour over EVERY player (lifetime playtime lognormal) and the real SECRET rate with RollsPerHour = 8",
          ["population", "CometsPerNext", "avg lifetime min", "reach Ignition", "rolls / player-hour", "without the gift roll",
           "player-hours per SECRET now (target 2,000)", "RollsPerHour that hits 2,000"], rows)
    return rph


R_ODDS = [("Common", 60, 1.2), ("Uncommon", 25, 1.4), ("Rare", 10, 1.8), ("Epic", 4, 2.5), ("Legendary", 0.9, 4),
          ("Mythic", 0.09, 8), ("Celestial", 0.01, 20)]
KINDS = ["Stardust", "Shards", "Comets", "XP", "Luck", "Giant"]
MUTS = [("Void", 1 / 2000, 10), ("Rainbow", 1 / 200, 3), ("Golden", 1 / 20, 1.5)]


def core_power(mult, level, mut_power=1.0):
    p = 1 + (mult - 1) * (1 + 0.1 * (min(level, 10) - 1))
    return 1 + (p - 1) * mut_power


def roll_player(n_rolls, rng, muts=MUTS, secret_q=0.0):
    cores = {}   # (kind, rarity, mut) -> level
    have = set()
    pity = 0
    secret = 0
    for _ in range(n_rolls):
        if rng.random() < secret_q:
            secret += 1
            continue
        pity += 1
        u = rng.random() * 100
        ri = 0
        for i, (_, o, _) in enumerate(R_ODDS):
            u -= o
            if u <= 0:
                ri = i
                break
        if pity >= 200 and ri < 4:
            ri = 4
        if ri >= 4:
            pity = 0
        rar = R_ODDS[ri][0]
        free = [k for k in KINDS if (k, rar) not in have]
        kind = rng.choice(free) if free else rng.choice(KINDS)
        have.add((kind, rar))
        mut = None
        for name, p, _ in muts:
            if rng.random() < p:
                mut = name
                break
        key = (kind, rar, mut)
        cores[key] = cores.get(key, 0) + 1
    return cores, secret


def stardust_factor(cores, extra=None, muts=MUTS):
    mp = {m[0]: m[2] for m in muts}
    mp[None] = 1.0
    rmult = {r[0]: r[2] for r in R_ODDS}
    bonuses = [core_power(rmult[r], lv, mp[m]) - 1 for (k, r, m), lv in cores.items() if k == "Stardust"]
    if extra is not None:
        bonuses.append(extra)
    bonuses.sort(reverse=True)
    return 1 + sum(bonuses[:3])


def mutation_section(rph_active):
    rng = random.Random(81)
    stages = [("1 h after Ignition", 55), ("3 h", 150), ("10 h", 500), ("30 h", 1500)]
    base_F = {}
    rows = []
    for name, n in stages:
        Fs = [stardust_factor(roll_player(n, rng)[0]) for _ in range(n_(300))]
        base_F[name] = statistics.median(Fs)
        rows.append([name, n, f1(pct(Fs, 10)), f1(statistics.median(Fs)), f1(pct(Fs, 90))])
    table("Forge STARDUST factor (best 3 Stardust cores equipped; bonuses add) by rolls done",
          ["stage", "rolls", "p10", "median", "p90"], rows)
    # what one lucky pull does, at each stage; progression skipped = ln(ratio)/ln(need growth 1.7) Supernovas
    pulls = [("GOLDEN Epic Stardust", 2.5, 1.5), ("RAINBOW Epic Stardust", 2.5, 3), ("VOID Common Stardust", 1.2, 10),
             ("VOID Rare Stardust", 1.8, 10), ("VOID Epic Stardust", 2.5, 10), ("VOID Legendary Stardust", 4, 10),
             ("VOID Epic Stardust at x5", 2.5, 5), ("VOID Legendary Stardust at x5", 4, 5),
             ("SECRET Nebula Whale (mult 30)", 30, 1), ("GOLDEN SECRET (30, x1.5)", 30, 1.5), ("SECRET at mult 15", 15, 1)]
    run_min = {"1 h after Ignition": 6.5, "3 h": 10, "10 h": 12, "30 h": 14}
    rows = []
    for pname, m, mp in pulls:
        bonus = (m - 1) * mp
        line = [pname, f"+{bonus:.1f}"]
        for name, n in stages:
            F = base_F[name]
            # replace the weakest of the 3 (approx: the median player's 3rd core is ~0.3 of F-1)
            Fn = F + bonus - min(bonus, (F - 1) / 3)
            ratio = Fn / F
            skip = math.log(ratio) / math.log(1.7)
            line.append(f"x{ratio:.1f} = {skip * run_min[name]:.0f} min")
        rows.append(line)
    table("One lucky pull: income x and progression skipped (Supernova need grows x1.7; minutes per Supernova at that stage)",
          ["pull", "bonus"] + [s[0] for s in stages], rows)
    rows = []
    for typ, r in rph_active.items():
        rows.append([typ, f0(r), f0(2000 / r), f0(2000 * 6 / r), f0(1 / (r * (1 / 2000) * (0.04 / 6 + 0.01 / 6))),
                     f0(200 / r), f0(20 / r * 60)])
    table("How long until it happens, hours of post-Ignition play (rolls/h from section 5)",
          ["kid", "rolls/h", "any VOID", "a VOID Stardust", "a VOID Epic+ Stardust", "any RAINBOW", "any GOLDEN (min)"], rows)
    return base_F


# ====================================================================================================================
# 6. FIRST MINUTES: is minute 0-5 touched? (kidsim.py variant G + loose comets on a NEW player's island)
# ====================================================================================================================
def first_minutes_section():
    print("\n" + "=" * 100 + "\n## 6. FIRST MINUTES (kidsim.py, variant G = the live game + LUMI's gift roll)\n" + "=" * 100)
    try:
        import kidsim
        import variants
    except Exception as e:  # pragma: no cover
        print("- kidsim.py / variants.py not importable:", e)
        return None
    G = variants.V["G F+LUMI gift roll (Sat 21)"]
    base_game = kidsim.Game

    class LooseGame(base_game):
        def __init__(s, P, rng):
            super().__init__(P, rng)
            s._rate = P.get("loose_rate", 0)
            s._next = rng.expovariate(s._rate) if s._rate else 1e9
            s._grab = P.get("loose_grab", 0.6)
            s._busy = False

        def income(s, t):
            inc = super().income(t)
            if not s._busy and t >= s._next:
                s._busy = True
                s._next = t + s.rng.expovariate(s._rate)
                if s.rng.random() < s._grab:
                    if t <= 300:
                        SIZES.append(240 * inc / max(1.0, s.earned + s.sd * 0))
                    s.sd += 240 * inc
                    s.earned += 240 * inc
                s._busy = False
            return inc

    global SIZES
    SIZES = []
    rows = []
    for label, rate in (("G (no loose comets on new islands)", 0), ("G + loose comets, 6 players, 60 s", 1 / 360),
                        ("G + loose comets, 3 players, 60 s", 1 / 180)):
        P = dict(G, loose_rate=rate, loose_grab=0.6)
        kidsim.Game = LooseGame
        try:
            res = kidsim.evaluate(P, n=n_(1500), seed=1)
        finally:
            kidsim.Game = base_game
        p5 = 1 - math.exp(-rate * 300) if rate else 0
        rows.append([label, p0(p5), res["stay60"], res["stay180"], res["stay300"], res["first_buy_med"]])
    table("Minutes 0-5 with and without loose comets landing on a brand-new player's island (owner grab = 240 s of income)",
          ["version", "new player gets one in 5 min", "stay 60 s %", "stay 3 min %", "stay 5 min %", "first buy (s)"], rows)
    if SIZES:
        print(f"- A loose comet grabbed in minutes 0-5 = {statistics.median(SIZES):.1f}x everything the new kid had earned"
              f" until then (median; p90 {pct(SIZES, 90):.1f}x): a big unplanned jump in the tuned first minutes.")
    return rows


# ====================================================================================================================
# main
# ====================================================================================================================
if __name__ == "__main__":
    print("# Galaxy Incremental - Sat 21 balance sim (physics + human timing)" + ("  [--fast]" if FAST else ""))
    table("Human factors used (medians; see the note for sources)",
          ["kid", "device", "reaction", "deliberate", "lapse chance", "toast noticed (mean extra s / never)", "path x",
           "thumbstick", "prompt press", "AFK"],
          [[t, h["device"], f"{h['rt']:.2f} s", f"{h['dec']:.1f} s", p0(h["lapse"]), f"{h['tau_toast']:.1f} / {p0(h['never_other'])}",
            f"{h['ineff'][0]:.2f}-{h['ineff'][1]:.2f}", f"{h['stick']:.2f}", f"{h['press']:.2f} s", p0(h["afk"])]
           for t, h in HT.items()])
    phys = physics_section()
    carry = carry_time_section()
    duels = duel_section()
    portal_maths()
    pools = server_section(phys)
    catch = comet_section()
    heist_income_table(pools, catch)
    active_heister_table(pools, catch)
    fill = crew_core_section()
    gather = gather_section()
    crew_reward_section(fill, gather)
    curves = forge_rates_section(catch)
    rph = population_section(curves)
    active = {}
    for typ in TYPES:
        c, ign = curves[(typ, 10)]
        i0 = int(ign) + 1
        active[typ] = (c[min(i0 + 180, 6000)] - c[min(i0 + 60, 6000)]) / 2
    mutation_section(active)
    first_minutes_section()
    print(f"\n(done in {time.time() - T0:.0f} s)")
