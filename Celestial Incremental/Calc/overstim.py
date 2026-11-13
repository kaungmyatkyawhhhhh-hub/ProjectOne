"""Overstimulated-kid simulation of Galaxy Incremental (13 Nov 2026).

Timeline: the impatient-kid sim's LIVE economy (kidsim.py, config G = what is built) for the first 10 min,
and a mid-game 10 min (minutes 20-30, Supernovas 6-9, Ignition 1 at ~27 min) built from the Phase 2 bot pacing.
Every trigger becomes the UI it really shows (emitter table read from Studio 13 Nov, and the Ignition chain fired
in Play). Kids: age 6-12, attention slots 2 / 3 / 3.5, reading 1.5 words/s at 7 and 3 at 10 (estimates).
A heuristic model with ESTIMATED weights and reading speeds, not measured players.

Run:  py overstim.py          (from the Calc folder; imports kidsim)
"""
import math, random, statistics, sys
from collections import Counter, defaultdict
import kidsim
from variants import V as KV

ECON = KV['G F+LUMI gift roll (Sat 21)']
DT = 0.05
W = dict(modal=2.0, centre=1.5, banner=1.0, toast=0.5, float=0.25, lumi=0.5, pill=0.5)
BIG_STINGS = {'milestone', 'boom', 'cometAppear', 'buyBody', 'rescue', 'windup'}

# ------------------------------------------------------------------ timelines (triggers)
def first10_timelines(n=120, seed=3):
    rng = random.Random(seed); out = []
    # a kid who stays 10 min: we want the triggers, not the quits (big_pop only changes the boredom meter,
    # never the economy)
    P = dict(ECON, big_pop=50)
    tries = 0
    while len(out) < n and tries < n * 5:
        tries += 1
        q, ev, _ = kidsim.run_kid(P, rng, T=600, log=True)
        if q >= 600: out.append([(t, w) for t, w, *_ in ev])
    return out

def mid_timeline(rng):
    """Minutes 20-30 (t = 0..600 inside the window). Supernova runs 80-140 s, a buy burst after each (tier
    crossings), level ups, comets, tutorial steps 15-19 and step 20 = IGNITION 1 at 25.5-28.5 min."""
    ev = []; t = rng.uniform(5, 60)
    while t < 600:
        ev.append((t, 'SUPERNOVA 7'))
        b = t + 12
        for _ in range(max(1, int(rng.gauss(4, 1.5)))):   # re-buying after the reset: NEW tier minis
            b += rng.expovariate(1 / 2.5); ev.append((b, 'BUY up TIER 0'))
        t += rng.uniform(80, 140)
    t = rng.uniform(5, 40)
    while t < 600: ev.append((t, 'LEVEL')); t += rng.uniform(35, 75)
    t = rng.uniform(0, 20)
    while t < 600: ev.append((t, 'COMET')); t += 20
    ign = rng.uniform(330, 510)
    for k, tt in enumerate(sorted(rng.uniform(0, ign - 20) for _ in range(4))): ev.append((tt, f'TUT STEP {16 + k}'))
    ev.append((ign, 'IGNITION'))
    return sorted(ev)

# ------------------------------------------------------------------ the screen (emitters -> elements, per version)
class Screen:
    def __init__(s, flags, rng, kid):
        s.f, s.rng, s.kid = flags, rng, kid
        s.els = []                 # dict(name, region, w, t0, t1, key, words, kind, hidden_by_cine)
        s.cines = []               # (t0, t1) full cutscenes (hide the HUD)
        s.stings = []; s.flashes = []
        s.collide = Counter(); s.blocked = 0; s.merged = 0; s.delays = []
        s.toast_free = 0.0; s.banner_free = 0.0; s.centre_free = 0.0; s.mini_free = 0.0
        s.last_sting = -9; s.mini_batch = None; s.key_free = 0.0

    # --- helpers
    def in_cine(s, t):
        return any(a <= t < b for a, b in s.cines)
    def cine_end(s, t):
        for a, b in s.cines:
            if a <= t < b: return b
        return t
    def after_calm(s, t):
        moved = True
        while moved:
            moved = False
            for e in s.els:
                if e['region'] in ('centre', 'modal') and e['t0'] <= t < e['t1'] and not e.get('stays'):
                    t = e['t1'] + 0.3; moved = True
            if s.in_cine(t): t = s.cine_end(t) + 0.4; moved = True
        return t
    def W(s, words, short):   # v8: the KEY texts rewritten shorter (the live text's words -> the new one's)
        return short if s.f.get('short_text') else words
    def visible_at(s, t, region):
        return [e for e in s.els if e['region'] == region and e['t0'] <= t < e['t1']]
    def need(s, words):  # reading time for a SLOW 7-year-old (1.2 words/s) + 0.5 s to notice
        return words / 1.2 + 0.5
    def add(s, **e):
        e.setdefault('key', False); e.setdefault('words', 0); e.setdefault('kind', e['name'])
        e['w'] = W[e['region']] if 'w' not in e else e['w']
        s.els.append(e); return e
    def sting(s, t, name):
        if name not in BIG_STINGS: return
        if s.f.get('sting_cap') and t - s.last_sting < 1.0: return    # ducked under the one big sound
        s.last_sting = t; s.stings.append(t)

    # --- toasts: LIVE = one at a time, a new one REPLACES the old at once; hidden while a cutscene owns the screen
    def toast(s, t, name, words, key, kind=None):
        kind = kind or name
        if s.f.get('demote') and not key and (s.in_cine(t) or s.visible_at(t, 'centre') or s.visible_at(t, 'modal')):
            return                                                  # minor news: not while something big is up
        if s.f.get('hold_cine') and s.in_cine(t):
            t2 = s.cine_end(t) + 0.4; s.delays.append(t2 - t); t = t2
        hold = 2.3 + 0.25
        if not s.f.get('toast_queue'):
            for e in s.visible_at(t, 'toast'):
                if e['t1'] > t:
                    s.collide[f"{e['name']} x {name} (toast replaced)"] += 1; e['t1'] = t
            s.add(name=name, region='toast', t0=t, t1=t + hold, key=key, words=words, kind=kind)
            return
        # QUEUE: same kind merges into the one waiting / showing; KEY ones stay up long enough to read
        for e in s.els:
            if e['region'] == 'toast' and e['kind'] == kind and e['t1'] > t and s.f.get('merge'):
                e['t1'] = max(e['t1'], t + hold); s.merged += 1; return
        if key: hold = max(hold, s.need(words))
        start = max(t, s.toast_free)
        if s.f.get('hold_cine') and s.in_cine(start): start = s.cine_end(start) + 0.4
        if key and s.f.get('calm_wait'):                            # KEY news waits until no card / window is up
            start = s.after_calm(start)
            if s.toast_free > start: start = s.toast_free
        if key and s.f.get('key_queue'):                            # ONE KEY message at a time, anywhere on screen
            while start < s.key_free:
                start = s.after_calm(s.key_free)
            s.key_free = start + hold
        if not key and start - t > 4: return                        # stale minor news is dropped
        s.delays.append(start - t)
        s.toast_free = start + hold + 0.15
        s.add(name=name, region='toast', t0=start, t1=start + hold, key=key, words=words, kind=kind)

    def banner(s, t, name, words):
        if s.f.get('demote') and (s.in_cine(t) or s.visible_at(t, 'centre') or s.visible_at(t, 'modal') or s.kid['tut']):
            return                                                  # other players' news -> chat line only
        if s.f.get('hold_cine') and s.in_cine(t): t = s.cine_end(t) + 0.4
        for e in s.visible_at(t, 'banner'):
            s.collide[f"{e['name']} x {name} (banner replaced)"] += 1; e['t1'] = t
        e = s.add(name=name, region='banner', t0=t, t1=t + 3.3, words=words)
        if not s.f.get('banner_band'):
            # LIVE: the banner (top, 56 px) and the toast row (y ~51) overlap on phones
            for o in s.els:
                if o['region'] == 'toast' and o['t0'] < e['t1'] and o['t1'] > e['t0']:
                    s.collide[f"{name} x {o['name']} (top band)"] += 1
                    o.setdefault('covered', []).append((max(o['t0'], e['t0']), min(o['t1'], e['t1'])))
        s.sting(t, 'milestone')

    # --- centre: the NEW-tier mini (1.2 s); LIVE: dropped during a full cutscene, the old 1.5 s moment card when a mini runs
    def mini(s, t, title_words, key=True):
        if s.f.get('centre_queue'):
            b = s.mini_batch
            if b and t < b['t1'] - 0.3:                              # merge: "NEW: IRON ASTEROID! +2 MORE"
                b['t1'] = max(b['t1'], t + 1.0); s.merged += 1; return
            start = max(t, s.centre_free)
            if s.in_cine(start): start = s.cine_end(start) + 0.4
            if s.f.get('key_queue'):
                start = max(start, s.key_free); s.key_free = start + max(1.2, s.need(title_words))
            s.delays.append(start - t)
            e = s.add(name='NEW tier mini', region='centre', t0=start, t1=start + max(1.2, s.need(title_words)), key=key, words=title_words)
            s.mini_batch = e; s.centre_free = e['t1'] + 0.2; s.sting(start, 'milestone')
            return
        if s.in_cine(t):
            s.add(name='NEW tier mini', region='centre', t0=t, t1=t, key=key, words=title_words, dropped=True); return
        if t < s.mini_free:     # CutsceneMod.busy() -> the legacy moment card, on top of the running mini
            s.add(name='NEW tier card (legacy)', region='centre', t0=t, t1=t + 1.5, key=key, words=title_words, kind='NEW tier mini')
            s.sting(t, 'milestone'); return
        s.add(name='NEW tier mini', region='centre', t0=t, t1=t + 1.2, key=key, words=title_words)
        s.mini_free = t + 1.2; s.sting(t, 'milestone')

    def card(s, t, name, dur, key, words, region='centre', choice=False):
        start = t
        if s.f.get('centre_queue'):
            start = max(t, s.centre_free)
            if s.in_cine(start): start = s.cine_end(start) + 0.4
            s.delays.append(start - t)
        e = s.add(name=name, region=region, t0=start, t1=start + dur, key=key, words=words, choice=choice)
        if s.f.get('centre_queue'): s.centre_free = e['t1'] + 0.2
        if s.f.get('key_queue'):
            # a card the kid opened PAUSES the KEY queue: what was showing / waiting comes back after it, in order
            push = e['t1'] + 0.3
            for o in sorted(s.els, key=lambda o: o['t0']):
                if o is e or not o['key'] or o.get('stays') or o.get('cine') or o['region'] not in ('toast', 'centre'): continue
                if o['t1'] > e['t0'] and o['t0'] < e['t1'] and o['t1'] > o['t0']:
                    d = o['t1'] - o['t0']; o['t0'] = max(push, o['t0']); o['t1'] = o['t0'] + d; push = o['t1'] + 0.15
            s.key_free = max(s.key_free, push); s.toast_free = max(s.toast_free, push)
        return e

    def cutscene(s, t, name, length, key_words):
        # a full cutscene waits for the one before; it hides the whole HUD (every ScreenGui) until it ends
        start = max([t] + [b for a, b in s.cines if b > t])
        if s.f.get('centre_queue'):
            for e in s.els:     # windows / cards close first (LIVE: the Supernova card stays open under it)
                if e['region'] in ('centre', 'modal') and e['t0'] <= start < e['t1'] and not e.get('stays'):
                    if s.f.get('key_queue') and e['key'] and e['region'] == 'centre': continue   # requeued below
                    e['t1'] = start
            start = max(start, s.centre_free)
        s.cines.append((start, start + length))
        if s.f.get('key_queue'):
            # the cutscene PAUSES the KEY queue too: what was showing / waiting comes back after it
            push = start + length + 0.4
            for o in sorted(s.els, key=lambda o: o['t0']):
                if not o['key'] or o.get('stays') or o.get('cine') or o['region'] not in ('toast', 'centre'): continue
                if o['t1'] > start and o['t0'] < start + length and o['t1'] > o['t0']:
                    d = o['t1'] - o['t0']; o['t0'] = max(push, o['t0']); o['t1'] = o['t0'] + d; push = o['t1'] + 0.15
                    o.pop('hidden_from', None)
            s.key_free = max(s.key_free, push); s.toast_free = max(s.toast_free, push)
        s.add(name=name, region='modal', t0=start, t1=start + length, key=True, words=key_words, cine=True)
        s.flashes.append(start + length * 0.8)
        s.sting(start, 'windup'); s.sting(start + length * 0.8, 'boom')
        if s.f.get('centre_queue'): s.centre_free = start + length + 0.2
        return start + length

# ------------------------------------------------------------------ one kid
def kid_profile(rng, age=None):
    age = age if age is not None else rng.choice([6, 7, 7, 8, 8, 9, 10, 10, 11, 12])
    slots = 2 if age <= 6 else 3 if age <= 9 else 3.5
    speed = max(0.9, 1.5 + 0.5 * (age - 7)) * rng.uniform(0.8, 1.2)
    return dict(age=age, slots=slots, speed=speed, tut=True)

def build(flags, events, rng, kid, phase):
    S = Screen(flags, rng, kid)
    others = []
    t = rng.expovariate(1 / 240)
    while t < 600: others.append(t); t += rng.expovariate(1 / 240)     # someone's FIRST SUPERNOVA banner (8-player server)
    minor = []
    t = rng.expovariate(1 / 200)
    while t < 600: minor.append(t); t += rng.expovariate(1 / 200)      # daily / party quest done, tips
    tut_on = True
    items = [(t, w) for t, w in events] + [(t, 'OTHER BANNER') for t in others] + [(t, 'MINOR') for t in minor]
    if phase == 'first10': items.append((rng.uniform(60, 400), 'FRIENDS TIP'))
    items.sort()
    pill_until = None
    novas_seen = 0 if phase == 'first10' else 6
    for t, w in items:
        if w.startswith('SUPERNOVA'): novas_seen += 1
        kid['tut'] = tut_on
        if w == 'WELCOME GIFT':
            S.toast(t, 'WELCOME GIFT toast', S.W(8, 5), True); S.sting(t, 'buyBody')
            S.add(name='+30 float', region='float', t0=t, t1=t + 1.2)
        elif flags.get('demote_new') and (w.startswith('BUY up TIER') or w.startswith('BUY unlock')):
            # v11 (owner 13 Nov: "the star thing overstimulates me"): the star moment only for a body that is really new
            # (first run); a re-bought body = its chime; a named tier = one small merged toast
            if w.startswith('BUY unlock') and phase == 'first10' and novas_seen == 0:
                S.mini(t, 3)
            elif 'TIER' in w:
                S.toast(t, 'TIER UP toast', 5, True, kind='TIER')
        elif w.startswith('BUY up TIER') or w.startswith('BUY unlock'):
            S.mini(t, 3)
        elif w.startswith('BUY'):
            pass                                   # the body chime / buy click: small sounds, no UI
        elif w.startswith('LEVEL'):
            S.toast(t, 'LEVEL UP toast', 5, True, kind='LEVEL'); S.sting(t, 'milestone')
        elif w == 'COMET':
            S.sting(t, 'cometAppear')
            blocked = any(e['region'] == 'modal' and e['t0'] <= t < e['t1'] for e in S.els) or S.in_cine(t)
            if blocked: S.blocked += 1
            if phase == 'first10' and tut_on and t < 150 and not flags.get('lumi_says_comet'):
                S.toast(t, 'LUMI tap-the-comet toast', S.W(4, 3), True, kind='LUMI comet')
            if not blocked and rng.random() < 0.7:
                S.add(name='comet +N float', region='float', t0=t + 2, t1=t + 3.2)
        elif w.startswith('TUT STEP'):
            S.add(name='+ESSENCE floats', region='float', t0=t, t1=t + 1.2)
            t_l = S.after_calm(t) if flags.get('calm_wait') else t
            if flags.get('key_queue'):
                t_l = max(t_l, S.key_free); S.key_free = t_l + S.need(5)
            for o in S.els:                      # the card shows ONE step: the new text replaces the old
                if o['name'] == 'LUMI card new step' and o['t1'] > t_l: o['t1'] = t_l; o['superseded'] = True
            S.add(name='LUMI card new step', region='lumi', t0=t_l, t1=t_l + 30, key=True, words=5, stays=True, w=0)
            S.sting(t, 'buy')
        elif w == 'GIFT 2x':
            S.toast(t, 'x2 GIFT toast', S.W(7, 5), True); S.sting(t, 'buyBody')
        elif w.startswith('SUPERNOVA'):
            first = w == 'SUPERNOVA 1'
            # the kid opens the card and presses GO when done reading: kid-paced
            c = S.card(t - 3.0, 'SUPERNOVA card', max(3.0, 7 / kid['speed'] + 1.0), True, 7, region='modal')
            end = S.cutscene(max(t, c['t1']), 'SUPERNOVA cutscene', 10 if first else 4.5, 1)
            S.add(name='shards float', region='float', t0=end, t1=end + 1.2)
            if first:
                S.toast(end - 6, 'BADGE first Supernova toast', 6, False, kind='BADGE')
        elif w == 'IGNITION':
            # the LIVE chain (fired in Play 13 Nov): last step's tier mini + LEVEL UP + BADGE toasts + 5 stings in 1 s,
            # TUTORIAL COMPLETE at +0.4 s, the 8 s Ignition cutscene, the PATH card (a choice), the free Forge roll
            S.mini(t, 3); S.toast(t, 'LEVEL UP toast', 5, True, kind='LEVEL'); S.sting(t, 'milestone')
            for k in range(5): S.sting(t + 0.9 + 0.01 * k, 'milestone')
            S.toast(t + 0.9, 'BADGE island complete toast', 5, False, kind='BADGE')
            sn_open = rng.random() < 0.35            # the kid had the Supernova card / a window open
            if sn_open:
                e = S.add(name='SUPERNOVA card (left open)', region='modal', t0=t - 2, t1=t + 30, key=False, words=0)
                if not flags.get('centre_queue'): e['stays'] = True
            if not flags.get('centre_queue'):
                tc = S.card(t + 0.4, 'TUTORIAL COMPLETE card', 3.05, True, S.W(10, 7))
                end = S.cutscene(t + 1.4, 'IGNITION cutscene', 8, 9)
                tc['hidden_from'] = t + 1.4        # the cutscene hides the HUD 1 s after the card appeared
            else:
                # queued: the cutscene first (it is the big moment), then TUTORIAL COMPLETE, the path card, the gift
                S.centre_free = t + 0.4
                end = S.cutscene(t + 0.4, 'IGNITION cutscene', 8, 9)
                tc = S.card(end + 0.4, 'TUTORIAL COMPLETE card', max(3.05, S.need(S.W(10, 7))), True, S.W(10, 7))
            S.toast(t + 4.1, 'LUMI play-with-friends toast', 10, False, kind='TIP')
            pc = S.card(end, 'PATH card (choose)', max(6, 8 / kid['speed'] + 4), True, 8, region='modal', choice=True)
            gift_t = t + 0.5
            if flags.get('centre_queue'): gift_t = pc['t1'] + 0.3
            if flags.get('calm_wait'):
                # the gift's own window says it (title "LUMI'S GIFT!"): no toast racing the window
                fw = S.card(gift_t, "FORGE window (LUMI'S GIFT roll)", max(6, 6 / kid['speed'] + 2), True, 6, region='modal')
            else:
                S.toast(gift_t, "LUMI'S GIFT toast", 6, True, kind='GIFT')
                fw = S.card(gift_t + 0.6, 'FORGE window (gift roll)', 6, True, 4, region='modal')
            if not flags.get('centre_queue') and S.in_cine(gift_t + 0.6):
                fw['hidden_from'] = gift_t + 0.6; fw['t1'] = end + 6     # opened under the cutscene, shows after it
            tut_on = False
        elif w == 'OTHER BANNER':
            S.banner(t, "someone's FIRST SUPERNOVA banner", 4)
        elif w == 'MINOR':
            S.toast(t, 'quest / tip toast', 6, False, kind='MINOR')
        elif w == 'FRIENDS TIP':
            S.toast(t, 'LUMI play-with-friends toast', 10, False, kind='TIP')
    if phase == 'first10' and tut_on:
        pass
    return S

def score(S, kid):
    """walk the 10 minutes: load, overload, reading of KEY elements."""
    T = 600; n = int(T / DT)
    els = [e for e in S.els if e['t1'] > e['t0'] or e.get('dropped')]
    keys = [e for e in els if e['key']]
    for e in keys: e['read'] = 0.0
    over_run = 0.0; overload = 0.0; worst = []
    live = [e for e in els if not e.get('dropped') and e['t1'] > e['t0']]
    live.sort(key=lambda e: e['t0'])
    stings = sorted(S.stings); flashes = sorted(S.flashes)
    for e in live:
        if e.get('hidden_from') is not None: e['hid_to'] = S.cine_end(e['hidden_from'])
    active = []; nxt = 0
    for i in range(n):
        t = i * DT
        while nxt < len(live) and live[nxt]['t0'] <= t: active.append(live[nxt]); nxt += 1
        active = [e for e in active if e['t1'] > t]
        if not active and not stings and not flashes: continue
        cine = S.in_cine(t)
        vis = [e for e in active if not (e.get('hidden_from') is not None and e['hidden_from'] <= t < e['hid_to'])]
        if cine:  # the cutscene owns the screen: everything else is hidden
            vis = [e for e in vis if e.get('cine')]
        load = sum(e['w'] for e in vis)
        load += 0.5 * sum(1 for st in stings if st <= t < st + 0.5)
        load += 1.0 * sum(1 for fl in flashes if fl <= t < fl + 0.3)
        if load > kid['slots']:
            over_run += DT
        else:
            if over_run >= 0.5: overload += over_run; worst.append((round(t - over_run, 1), round(over_run, 2)))
            over_run = 0.0
        # reading: the newest KEY in a region covers older ones; banners over toasts cover them
        reading = []
        for e in vis:
            if not e['key'] or e.get('cine'): continue
            if e['read'] >= e['words'] / kid['speed'] + 0.5: continue     # already read: stops competing
            if any(a <= t < b for a, b in e.get('covered', [])): continue
            same = [o for o in vis if o['region'] == e['region'] and o is not e and o['t0'] > e['t0']]
            if same: continue
            if e['region'] in ('centre', 'toast', 'lumi', 'float') and any(o['region'] == 'modal' for o in vis if o is not e) and not cine:
                if e['region'] == 'centre': continue      # a card under a window / under another card
            reading.append(e)
        modal_keys = [e for e in reading if e['region'] == 'modal']
        if modal_keys: reading = modal_keys        # a card / window the kid opened has their attention
        if load <= kid['slots'] and reading:
            for e in reading: e['read'] += DT / len(reading)
    if over_run >= 0.5: overload += over_run
    missed = Counter(); shown = Counter()
    for e in keys:
        need = e['words'] / kid['speed'] + 0.5
        if e['t1'] <= e['t0'] and not e.get('dropped'): continue      # replaced in the same frame: never shown
        if e.get('superseded'): continue      # a step already DONE: only the current instruction matters
        k = e['kind'] if e['kind'] in ('LEVEL', 'NEW tier mini', 'LUMI comet', 'GIFT') else e['name']
        shown[k] += 1
        if e.get('cine'): continue
        if e.get('stays'):  # the LUMI step card stays until the next step: missed only if never readable
            if e['read'] < need: missed[k] += 1
            continue
        if e.get('dropped') or e['read'] < need: missed[k] += 1
    noise = 0
    st = sorted(S.stings); j = 0
    for i2, a in enumerate(st):
        while st[j] < a - 2: j += 1
        if i2 - j + 1 > 3: noise += 1
    fl = sorted(S.flashes); flash_fail = sum(1 for i2 in range(len(fl)) if i2 >= 3 and fl[i2] - fl[i2 - 3] < 1)
    return dict(overload=overload, missed=missed, shown=shown, noise=noise, flash=flash_fail, worst=worst)

VERSIONS = [
    ('v0 LIVE', {}),
    ('v1 + toast queue (no replace, KEY read time)', dict(toast_queue=True)),
    ('v2 + hold HUD news during cutscenes', dict(toast_queue=True, hold_cine=True)),
    ('v3 + one centre queue (cards wait, cutscene closes cards, minis merge)', dict(toast_queue=True, hold_cine=True, centre_queue=True)),
    ('v4 + one big sting per second', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True)),
    ('v5 + merge same toasts, demote minor news', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True)),
    ('v6 + banner gets its own band', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True)),
    ('v7 + KEY news waits for calm (no card / window up)', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True, calm_wait=True)),
    ('v8 + shorter KEY texts', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True, calm_wait=True, short_text=True)),
    ('v9 + ONE queue for every KEY message (toast, mini, LUMI step)', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True, calm_wait=True, short_text=True, key_queue=True)),
    ('v9b = BUILT: v9 + star moment only for really new bodies, tier ups = merged toast (owner 13 Nov)', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True, calm_wait=True, short_text=True, key_queue=True, demote_new=True)),
    ('v10 + "tap the comet" lives on the LUMI card (no toast)', dict(toast_queue=True, hold_cine=True, centre_queue=True, sting_cap=True, merge=True, demote=True, banner_band=True, calm_wait=True, short_text=True, key_queue=True, lumi_says_comet=True)),
]

def run(flags, n=2000, seed=11, F10=None, age=None):
    rng = random.Random(seed)
    agg = dict(over10=[], over_mid=[], noise=0, flash=0, blocked=0)
    missed = Counter(); shown = Counter(); coll = Counter(); delays = []
    for i in range(n):
        for phase in ('first10', 'mid'):
            kid = kid_profile(rng, age)
            ev = rng.choice(F10) if phase == 'first10' else mid_timeline(rng)
            S = build(flags, ev, rng, kid, phase)
            r = score(S, kid)
            agg['over10' if phase == 'first10' else 'over_mid'].append(r['overload'])
            agg['noise'] += r['noise']; agg['flash'] += r['flash']; agg['blocked'] += S.blocked
            missed.update(r['missed']); shown.update(r['shown']); coll.update(S.collide); delays += S.delays
    return dict(over10=statistics.mean(agg['over10']), over_mid=statistics.mean(agg['over_mid']),
                noise=agg['noise'] / n, flash=agg['flash'], blocked=agg['blocked'] / n,
                missed_pct=100 * sum(missed.values()) / max(1, sum(shown.values())),
                by_type={k: round(100 * missed[k] / shown[k], 1) for k in shown}, top=coll.most_common(5),
                max_delay=max(delays) if delays else 0, p95_delay=sorted(delays)[int(0.95 * len(delays))] if delays else 0)

def worst_moment(flags, F10, seed=5):
    """the Ignition chain for one 8-year-old with the Supernova card left open: a timeline of what is on screen."""
    rng = random.Random(seed)
    ev = [(100.0, 'IGNITION')]
    kid = kid_profile(rng, 8)
    rng2 = random.Random(1)
    class R(random.Random):
        def random(self): return 0.1        # forces 'card left open'
    S = build(flags, ev, R(2), kid, 'mid')
    rows = []
    for e in sorted(S.els, key=lambda e: e['t0']):
        if e['t0'] < 90 or e['t0'] > 140: continue
        rows.append(f"  {e['t0']-100:6.1f}s -> {e['t1']-100:6.1f}s  {e['region']:6s} {e['name']}" + ('  (DROPPED)' if e.get('dropped') else '')
                    + ('  (hidden by cutscene)' if e.get('hidden_from') else ''))
    st = [round(x - 100, 2) for x in S.stings if 90 < x < 140]
    return "\n".join(rows) + f"\n  big stings at: {st}"

if __name__ == '__main__':
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
    F10 = first10_timelines()
    print(f"{len(F10)} live first-10-min timelines; {n} kids x 2 windows per version\n")
    for name, fl in VERSIONS:
        r = run(fl, n=n, F10=F10)
        r7 = run(fl, n=max(300, n // 4), F10=F10, age=7, seed=99)
        r6 = run(fl, n=max(100, n // 10), F10=F10, age=6, seed=98)
        print(f"{name}\n  overload s/10min: first10 {r['over10']:.1f}  mid {r['over_mid']:.1f} | KEY missed: all ages {r['missed_pct']:.1f}%  "
              f"7 y {r7['missed_pct']:.1f}%  6 y {r6['missed_pct']:.1f}% | noise {r['noise']:.2f}/kid  flash fails {r['flash']}  comets blocked {r['blocked']:.2f}/kid"
              f" | news delay p95 {r['p95_delay']:.1f}s max {r['max_delay']:.1f}s")
        print("  missed by type (7 y):", {k: v for k, v in sorted(r7['by_type'].items(), key=lambda x: -x[1]) if v > 0})
        print("  top collisions:", r['top'])
        print()
    for name, fl in (VERSIONS[0], VERSIONS[-1]):
        print(f"WORST MOMENT (Ignition 1, card left open, age 8): {name}\n" + worst_moment(fl, F10) + "\n")
