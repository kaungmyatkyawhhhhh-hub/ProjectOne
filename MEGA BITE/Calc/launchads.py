"""MEGA BITE launch with $200 of Roblox ads and no YouTubers (owner 9 Nov 2026).
How many players does $100 buy, what does the game tile then show, and do the debate kids still
say "nobody plays it, it's dead"? Run: python launchads.py
Cost per play: official Maximize Plays ~$0.008 (DevForum Aug 2025); Galaxy's real ads (7 Nov 2026):
$0.011 per click but only ~6% of clickers pressed Play (page leak) = ~$0.18 per player.
"""
import sys
sys.path.insert(0, ".")
import debatekids as d

SESSION_MIN = 12        # average minutes per player (sims + research: median Roblox ~10, Be Fish 19)
ACTIVE_HOURS = 18       # an ad day delivers over ~18 hours
PEAK = 1.6              # peak CCU vs the day's average

SCEN = [
    ("best case: official cost per play", 0.008),
    ("good page: 25% of clickers press Play", 0.011 / 0.25),
    ("Galaxy-like page: 6% press Play", 0.011 / 0.06),
]

def crowd_score(ccu):
    """What kids see on the game tile ('playing'): 0-10."""
    for limit, sc in ((10, 1), (50, 2), (150, 3), (500, 4), (2000, 5), (8000, 6)):
        if ccu < limit: return sc
    return 7

def mega_final():
    m = dict(d.MEGA)
    for name, kw in d.VERS:
        if not name.startswith("M8"): m.update(kw)       # everything except the old 'launch push'
    return m

if __name__ == "__main__":
    print(f"{'$100 of ads, one day':42} plays   avg CCU  peak CCU  tile  agree  1st pick  (week after: agree)")
    for name, cpp in SCEN:
        plays = 100 / cpp
        avg = plays * SESSION_MIN / (ACTIVE_HOURS * 60); peak = avg * PEAK
        m = mega_final(); m["crowd"] = crowd_score(peak); r = d.run(m)
        after = dict(m); after["crowd"] = crowd_score(peak * 0.12); ra = d.run(after)  # ~D1 10% + some organic
        print(f"{name:42} {plays:6.0f}   {avg:6.0f}   {peak:6.0f}    {m['crowd']:3d}   {r['agree']:4.0f}%  {r['first']:4.0f}%     ({ra['agree']:.0f}%)")
    # which kid still says no at a low crowd, and what fixes it without a bigger crowd
    m = mega_final(); m["crowd"] = 2
    r = d.run(m)
    print("\nat tile 2/10 the objections are:", r["top"][:3])
