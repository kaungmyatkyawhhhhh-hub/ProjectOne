"""GYM ARC crowd (CCU) growth model, 26 Nov 2026 -> 10 Jan 2027. Made to close the debate-kids con
"nobody plays it, it's dead" (Trend chaser veto: crowd < 4/10 = under ~1,100 players on the game tile).
Daily model: new players = ads + organic (Roblox recommendations) + friends brought in (viral k);
returners follow a retention curve per daily cohort; CCU = sessions x minutes / 1440; tile CCU at after-school peak.
Calibrated to GYM ARC history: RELEASE ads 23 Oct (35,173 ad plays, ~7 days) -> CCU 50-100; mid-Nov ~15; 24 Nov ~2-15.
Ad cost per play $0.0055 (RELEASE) -> $0.007 assumed in December (Christmas ad prices up).
Uncertain inputs are drawn from ranges (600 runs), so the answer is a chance, not one number. A model, not a forecast.
Run: python growth_gymarc.py
"""
import math, random, statistics as st, datetime as dt

START = dt.date(2026, 11, 26); DAYS = 46
LAUNCH = dt.date(2026, 12, 5)
def day(i): return START + dt.timedelta(days=i)

def crowd_score(ccu):   # fitted to rivals: 301 -> 2, 622 -> 3, 1,100 -> 4, 1,830 -> 5, 3,244 -> 6
    return 2 + 4 * math.log10(max(ccu, 1) / 300) / math.log10(3244 / 300)

LIVE = dict(session=12.0, d1=0.06, k=0.03, organic=380, ptr_boost=1.0, peak=2.0, xmas=False,
            ad_usd=200, ad_days=3, d7_keep=0.35, events=False, reinvest=0.0, ad_start=None, videos=0, notify=False, afk=0.0, cpp_mul=1.0)

def sim(P, rng=None, u=None):
    u = u or dict(org=1.0, resp=1.0, kmul=1.0, d1mul=1.0, cpp=0.007, season=1.35)
    cohorts = []; out = []; ccu_prev = 5.0; robux_usd = 0.0
    for i in range(DAYS):
        d = day(i); live = P["xmas"] and d >= LAUNCH
        # engagement multiplier on Roblox recommendations (playtime + retention vs the live build)
        eng = (P["session"] / 12.0) ** (0.8 * u["resp"]) * ((P["d1"] * u["d1mul"]) / 0.06) ** (0.6 * u["resp"])
        momentum = 1 + 0.25 * u["resp"] * max(0.0, math.log(ccu_prev / 8.0))
        season = u["season"] if dt.date(2026, 12, 19) <= d <= dt.date(2027, 1, 4) else 1.0   # school holidays
        org = P["organic"] * u["org"] * eng * momentum * season * P["ptr_boost"] * (1.25 if live else 1.0)
        ads = 0.0
        a0 = P["ad_start"] or LAUNCH
        if live and 0 <= (d - a0).days < P["ad_days"]: ads = P["ad_usd"] / P["ad_days"] / (u["cpp"] * P["cpp_mul"])
        if P["reinvest"] and live and (d - a0).days >= P["ad_days"]:  # owner choice: put game earnings back into ads
            ads += P["reinvest"] * robux_usd / (u["cpp"] * P["cpp_mul"]); robux_usd *= (1 - P["reinvest"])
        vid = P["videos"] * u.get("vid", 1.0) if live else 0.0   # plays/day from our own TikTok/Shorts clips
        new = (org + ads + vid) * (1 + P["k"] * u["kmul"])
        cohorts.append(new)
        d1 = min(0.4, P["d1"] * u["d1mul"] * (1.5 if live else 1.0) * (1.0 if not P["events"] else 1.1) * (1.15 if P["notify"] and live else 1.0))
        ret = 0.0
        for age, n in enumerate(cohorts[:-1][::-1], start=1):   # power-law retention, d7 keep sets the tail
            ret += n * d1 * (age ** (math.log(P["d7_keep"]) / math.log(7)))
        sessions = new + ret
        avg = sessions * (P["session"] + P["afk"]) / 1440   # AFK minutes count on the tile, not in recommendations
        peak = avg * P["peak"] * (1.3 if P["events"] and live else 1.0) * (1.15 if P["notify"] and P["events"] and live else 1.0)
        robux_usd += sessions * 0.0011   # ~$0.0011 earned per session (DevEx value), only matters with reinvest
        ccu_prev = avg; out.append((d, avg, peak, new, ads))
    return out

def summary(P, runs=600, seed=1):
    rng = random.Random(seed); peaks = []; xmas = []; jan = []
    for _ in range(runs):
        u = dict(org=math.exp(rng.gauss(0, 0.35)), resp=rng.uniform(0.6, 1.4), kmul=rng.uniform(0.6, 1.4),
                 d1mul=rng.uniform(0.75, 1.25), cpp=rng.uniform(0.0055, 0.009), season=rng.uniform(1.15, 1.6),
                 vid=math.exp(rng.gauss(0, 0.8)))
        o = sim(P, u=u)
        peaks.append(max(x[2] for x in o))
        xmas.append(st.mean(x[2] for x in o if dt.date(2026, 12, 20) <= x[0] <= dt.date(2026, 12, 31)))
        jan.append(st.mean(x[2] for x in o if x[0] >= dt.date(2027, 1, 4)))
    q = lambda a, p: sorted(a)[int(p * (len(a) - 1))]
    return dict(med_peak=st.median(peaks), xmas_lo=q(xmas, 0.1), xmas_med=st.median(xmas), jan_med=st.median(jan),
                p1100=100 * sum(x >= 1100 for x in xmas) / runs, p1830=100 * sum(x >= 1830 for x in xmas) / runs)

def calibrate():
    P = dict(LIVE); P.update(xmas=False, ad_usd=0)
    o = sim(P); print(f"calibration, live build no ads: tile CCU late Nov {o[2][2]:.0f}, mid Dec {o[20][2]:.0f}  (real: 2-15)")
    # RELEASE check: 35,173 ad plays over 7 days, live engagement
    cohorts = []; mx = 0
    for i in range(14):
        new = (380 + (35173 / 7 if i < 7 else 0)) * 1.03; cohorts.append(new)
        ret = sum(n * 0.06 * (a ** (math.log(0.35) / math.log(7))) for a, n in enumerate(cohorts[:-1][::-1], 1))
        mx = max(mx, (new + ret) * 12 / 1440 * 2.0)
    print(f"calibration, RELEASE ad week: tile CCU peak {mx:.0f}  (real: 50-100)")

VERS = [("A  live v1914 + $200 ads at Christmas", {}),
        ("B  + first-5-min fixes (Phase 2b): session 12 -> 16 min, D1 6 -> 8%", dict(session=16, d1=0.08)),
        ("C  + Christmas update: Advent calendar (daily return), winter gym", dict(xmas=True, d1=0.10, d7_keep=0.42)),
        ("D  + lag pass on phones (fewer phone quits)", dict(session=18, d1=0.11)),
        ("E  + play together: SPOT ME duo lifts, gift drops pay everyone nearby", dict(k=0.10)),
        ("F  + friend invite = a bonus Advent present for BOTH (Roblox invite prompt)", dict(k=0.18)),
        ("G  + new icon G + thumbnails (Home click rate 3.3% -> ~4.5%)", dict(ptr_boost=1.35)),
        ("H  + ranked arm-wrestle weekly board (weekly return)", dict(d7_keep=0.48)),
        ("I  + fixed-time GIFT RUSH events 3x a day (players log in together = higher peaks)", dict(events=True)),
        ("J  + Roblox experience notifications (opt-in): 'Gift Rush in 10 min', 'today's present is ready'", dict(notify=True, d7_keep=0.52)),
        ("K  + 1 short video a day (TikTok/Shorts: the GROW transform, Benny) ~ +150 plays/day", dict(videos=150)),
        ("M  + AFK training spot: auto-lifts at 30% speed while idle, a gift every 20 min AFK (avg +10 min stay)", dict(afk=10)),
        ("N  + 7-day login streak + codes in Discord/group (D1 +, D7 +)", dict(d1=0.12, d7_keep=0.56)),
        ("O  + move the $200 into the school holiday (19-23 Dec) instead of 5-7 Dec", dict(ad_start=dt.date(2026, 12, 19), ad_days=5)),
       ]
BUDGETS = [("$200 in the holiday (plan after L)", dict()),
           ("$200 + half the game's earnings back into ads", dict(ad_usd=200, reinvest=0.5)),
           ("$200 + all earnings back into ads", dict(reinvest=1.0)),
           ("$400 in the holiday", dict(ad_usd=400)),
           ("$400 + half the earnings back", dict(ad_usd=400, reinvest=0.5)),
           ("$800 in the holiday", dict(ad_usd=800, ad_days=7)),
           ("5%-CTR creatives (cost per play x0.66) + half the earnings back", dict(reinvest=0.5, cpp_mul=0.66)),
           ("5%-CTR creatives + all the earnings back", dict(reinvest=1.0, cpp_mul=0.66)),
           ("SENSITIVITY: AFK spot only +5 min, 5% creatives + half back", dict(reinvest=0.5, cpp_mul=0.66, afk=5)),
           ("SENSITIVITY: Roblox recommends us half as much, 5% creatives + half back", dict(reinvest=0.5, cpp_mul=0.66, organic=190))]

if __name__ == "__main__":
    calibrate()
    P = dict(LIVE)
    print(f"\n{'version (cumulative)':86} tile CCU 20-31 Dec: low(10%) / median   Jan   chance >=1,100  >=1,830")
    for name, kw in VERS:
        P.update(kw); s = summary(P)
        print(f"{name:86} {s['xmas_lo']:6.0f} / {s['xmas_med']:6.0f}  {s['jan_med']:6.0f}     {s['p1100']:4.0f}%     {s['p1830']:4.0f}%"
              f"   crowd {crowd_score(s['xmas_med']):.1f}")
    print("\nwith everything A-I built, ad budget options (owner's decision):")
    for name, kw in BUDGETS:
        Q = dict(P); Q.update(kw); s = summary(Q)
        print(f"  {name:48} low {s['xmas_lo']:6.0f}  median {s['xmas_med']:6.0f}  Jan {s['jan_med']:6.0f}   >=1,100 {s['p1100']:4.0f}%  >=1,830 {s['p1830']:4.0f}%  crowd {crowd_score(s['xmas_med']):.1f}")
