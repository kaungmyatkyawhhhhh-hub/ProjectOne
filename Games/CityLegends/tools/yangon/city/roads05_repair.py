"""Last-resort repair of the joins mouthsim still predicts as "MOUTH FAILED" (17 Nov 2026, roads05 fix 3).

For each failed end it tries small edits, smallest first, and keeps the first one the builder's own edge walk
(roads05_mouthsim, on the roads round the end) accepts with no new failure or dropped road nearby:
  1. corner: the bigger road ends right there (an L, or a Y of mains): it runs on past its end by this road's half + 2,
     so this road's far edge meets its side
  2. run on: this road's end goes on straight 4 .. 40 studs (both edges into the bigger road)
  3. pull back: this road loses 1 .. 12 end samples (an end lying along the bigger road: a shallow merge closes once
     its end is near the edge, MOUTH_SNAP)
  4. continuation: within 60 studs of the bigger road's end and about in line: flagged startsOnEnd / endsOnEnd
     (no mouth), like roads05_chain.continuations
An end that none fixes is listed (fix.json 'repair_left').

    used by roads05_fix.py: repair(data) -> stats
"""
import copy, math

import roads05_mouthsim as MS

LOCAL = 700.0


def _local(data, x, z, extra=()):
    sub = [r for r in data['roads'] if r['name'] in extra or any(abs(q[0] - x) < LOCAL and abs(q[2] - z) < LOCAL for q in r['s'][::4] + [r['s'][-1]])]
    names = set(r['name'] for r in sub)
    return dict(roads=sub, cut={k: v for k, v in data['cut'].items() if k in names}, roundabouts=data['roundabouts'], decks=[])


def _score(sub, x, z):
    box = (x - 400, z - 400, x + 400, z + 400)
    net = MS.Net(sub)
    mouths, dropped = net.find_mouths(box)
    failed = []
    for m in mouths:
        if net.walk(m):
            failed.append(dict(road=m['road'], end='start' if m['i0'] == 0 else 'end'))
    ends = set((m['road'], 'start' if m['i0'] == 0 else 'end') for m in mouths)
    return len(failed), len(dropped), dict(failed=failed, ends=ends)


def _fails_at(res, road, end):
    return any(f['road'] == road and f['end'] == end for f in res['failed'])


DECK_OF = set()


SHIFT = {}  # road -> samples added / removed at its start by the last trial (its decks' indices follow on commit)


def _run_on(r, k, t, cut):
    s = r['s']
    q = s[k]
    L = math.hypot(q[3], q[4]) or 1
    d = (q[3] / L, q[4] / L) if k == -1 else (-q[3] / L, -q[4] / L)
    n = max(1, int(math.ceil(t / 8.0)))
    add = []
    for i in range(1, n + 1):
        nq = list(q)
        nq[0] = round(q[0] + d[0] * t * i / n, 2)
        nq[2] = round(q[2] + d[1] * t * i / n, 2)
        add.append(nq)
    if k == -1:
        s.extend(add)
        return 0
    for nq in add:
        s.insert(0, nq)
    if r['name'] in cut:
        cut[r['name']] = [i + n for i in cut[r['name']]]
    SHIFT[r['name']] = n
    return n


def _pull(r, k, n, cut):
    if k == 0 and r['name'] in DECK_OF:
        return False
    s = r['s']
    if len(s) - n < 3:
        return False
    c = set(cut.get(r['name'], ()))
    idx = range(n) if k == 0 else range(len(s) - n, len(s))
    if any(i in c for i in idx):
        return False
    if k == 0:
        del s[:n]
        if r['name'] in cut:
            cut[r['name']] = [i - n for i in cut[r['name']]]
    else:
        del s[len(s) - n:]
    return True


def candidates(data, f):
    by = {r['name']: r for r in data['roads']}
    A = by.get(f['road'])
    B = by.get(f['on'])
    if A is None:
        return
    k = 0 if f['end'] == 'start' else -1
    q = A['s'][k]
    if B is not None and not B.get('closed'):
        for kb in (0, -1):
            e = B['s'][kb]
            if math.hypot(e[0] - q[0], e[2] - q[2]) < 60 and not B.get('startsOnEnd' if kb == 0 else 'endsOnEnd') \
                    and not ((0 if kb == 0 else len(B['s']) - 1) in set(data['cut'].get(B['name'], ()))):
                for extra in (2.0, 8.0, 16.0):
                    yield 'corner %+d %.0f' % (kb, extra), (lambda d, kb=kb, extra=extra: _run_on(_by(d, B['name']), kb, max(q[6], q[7]) + extra, d['cut']))
    for t in (4.0, 8.0, 16.0, 24.0, 32.0, 40.0):
        yield 'run on %.0f' % t, (lambda d, t=t: _run_on(_by(d, A['name']), k, t, d['cut']))
    for n in range(1, 13):
        yield 'pull back %d' % n, (lambda d, n=n: _pull(_by(d, A['name']), k, n, d['cut']))
    if B is not None and not B.get('closed'):
        for kb in (0, -1):
            e = B['s'][kb]
            if math.hypot(e[0] - q[0], e[2] - q[2]) < 90:
                yield 'continuation', (lambda d, kb=kb: _butt(d, A['name'], k, B['name'], kb))
        # under a flyover: the bigger road's ground is cut there (its deck passes over): no ground join to make
        cb = set(data['cut'].get(B['name'], ()))
        if cb and any(i in cb and math.hypot(B['s'][i][0] - q[0], B['s'][i][2] - q[2]) < max(B['s'][i][6], B['s'][i][7]) + 40 for i in range(len(B['s']))):
            yield 'square end under the deck', (lambda d: _by(d, A['name']).__setitem__('startsOnEnd' if k == 0 else 'endsOnEnd', B['name'] + ' (deck)'))


def _butt(d, a, ka, b, kb):
    """A carries on from B's end: trimmed / run on to B's end line, flagged (no mouth), like roads05_chain"""
    import collections
    from roads05_chain import butt
    A, B = _by(d, a), _by(d, b)
    if (ka == 0 and A['name'] in DECK_OF):
        return False
    cut = {k: set(v) for k, v in d['cut'].items()}
    if not butt(d, cut, A, ka, B, kb, collections.Counter()):
        return False
    d['cut'] = {k: sorted(v) for k, v in cut.items() if v}
    A['startsOnEnd' if ka == 0 else 'endsOnEnd'] = B['name']
    return True


def _by(d, name):
    for r in d['roads']:
        if r['name'] == name:
            return r
    raise KeyError(name)


def repair(data):
    DECK_OF.clear()
    DECK_OF.update(d['of'] for d in data['decks'])
    res = MS.run(data)
    st = dict(failed_before=len(res['failed']), fixed=[], repair_left=[])
    for f in res['failed']:
        sub = _local(data, f['x'], f['z'], extra=(f['road'], f['on']))
        nf0, nd0, r0 = _score(sub, f['x'], f['z'])
        if not _fails_at(r0, f['road'], f['end']):
            continue  # fixed by an earlier repair
        done = False
        for label, edit in candidates(data, f):
            trial = copy.deepcopy(sub)
            SHIFT.clear()
            try:
                if edit(trial) is False:
                    continue
            except KeyError:
                continue
            nf, nd, r1 = _score(trial, f['x'], f['z'])
            a = _by(trial, f['road'])
            flagged = a.get('startsOnEnd' if f['end'] == 'start' else 'endsOnEnd')
            # the end must still be a join (a mouth, or flagged as a continuation): pulling it off the road is a gap
            if nf < nf0 and nd <= nd0 and not _fails_at(r1, f['road'], f['end']) and (flagged or (f['road'], f['end']) in r1['ends']):
                # apply to the real data (same edit; the trial's roads are copies)
                keep = {r['name']: r for r in trial['roads']}
                data['roads'] = [keep.get(r['name'], r) for r in data['roads']]
                for nm in keep:
                    if nm in trial['cut']:
                        data['cut'][nm] = trial['cut'][nm]
                for nm, n in SHIFT.items():
                    for dk in data['decks']:
                        if dk['of'] == nm:
                            dk['from'] += n
                            dk['to'] += n
                st['fixed'].append(dict(road=f['road'], on=f['on'], end=f['end'], how=label, x=f['x'], z=f['z']))
                done = True
                break
        if not done:
            st['repair_left'].append(f)
    st['failed_after'] = len(MS.run(data)['failed'])
    return st
