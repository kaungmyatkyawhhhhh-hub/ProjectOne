"""A free sound bank: every effect, ambience and the music bed is synthesised in numpy (no account, no API, no cost).

sfx.py asks for a clip as  "name": ["prompt", seconds]  or  "name": ["prompt", seconds, "kind"]  or
"name": ["prompt", seconds, "kind", {"param": value}]. With no kind, it is read from the prompt and the name
(first matching keyword wins, see KINDS). The prompt is also the cache key, so a clip is made once.

Kinds: hit boom whoosh click pop tink ding sparkle buzzer drone hum room wind step crunch rewind glitch riser fall
       chirp laugh gasp yowl swallow switch music
Each returns a mono float array at 44.1 kHz, peak-levelled to 1.0 by the caller, starting with its attack at (or
very near) sample 0 so that onset alignment works.
"""
import hashlib, re

import numpy as np

SR = 44100


def _rng(seed):
    return np.random.default_rng(int(hashlib.sha1(str(seed).encode()).hexdigest()[:8], 16))


def _t(secs):
    return np.arange(int(secs * SR)) / SR


def _env(n, attack=0.002, decay=0.15):
    """Fast attack, exponential decay (decay = time constant in seconds)."""
    t = np.arange(n) / SR
    a = np.minimum(1, t / max(attack, 1e-4))
    return a * np.exp(-t / max(decay, 1e-4))


def _fft_filter(x, lo=None, hi=None, edge=0.25):
    """Band-pass (or low/high-pass) by FFT with soft edges (edge = fraction of the corner frequency)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if lo:
        m *= np.clip((f - lo * (1 - edge)) / (lo * 2 * edge), 0, 1)
    if hi:
        m *= np.clip((hi * (1 + edge) - f) / (hi * 2 * edge), 0, 1)
    return np.fft.irfft(X * m, len(x))


def _noise(rng, n):
    return rng.standard_normal(n)


def _sweep(f0, f1, secs, curve='exp'):
    t = _t(secs)
    r = t / secs
    f = f0 * (f1 / f0) ** r if curve == 'exp' else f0 + (f1 - f0) * r
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def _formant(x, f1, f2, q=0.18):
    """A crude vowel: keep two bands of x around f1 and f2."""
    return _fft_filter(x, f1 * (1 - q), f1 * (1 + q)) + 0.6 * _fft_filter(x, f2 * (1 - q), f2 * (1 + q))


def _saw(freq, secs):
    f = np.broadcast_to(freq, (int(secs * SR),)) if np.isscalar(freq) else freq
    ph = np.cumsum(f) / SR
    return 2 * (ph % 1) - 1


# ---------------------------------------------------------------- one-shots
def hit(secs, rng, f0=140, f1=45, **k):
    n = int(secs * SR)
    body = _sweep(f0, f1, secs) * _env(n, 0.001, 0.09)
    crack = _fft_filter(_noise(rng, n), 800, 6000) * _env(n, 0.0005, 0.02)
    return body + 0.5 * crack


def boom(secs, rng, **k):
    n = int(secs * SR)
    body = _sweep(90, 28, secs) * _env(n, 0.003, secs * 0.35)
    rumble = _fft_filter(_noise(rng, n), 20, 160) * _env(n, 0.005, secs * 0.4)
    return body + 0.8 * rumble * 4


def whoosh(secs, rng, f0=300, f1=3500, **k):
    n = int(secs * SR)
    x = _noise(rng, n)
    out = np.zeros(n)
    steps = 12  # slide a band upward, then fade
    edges = np.linspace(0, n, steps + 1).astype(int)
    for i in range(steps):
        c = f0 * (f1 / f0) ** (i / (steps - 1))
        seg = np.zeros(n)
        seg[edges[i]:edges[i + 1]] = x[edges[i]:edges[i + 1]]
        out += _fft_filter(seg, c * 0.7, c * 1.4)
    t = np.linspace(0, 1, n)
    return out * np.sin(np.pi * t ** 0.8) ** 1.5


def click(secs, rng, **k):
    n = int(secs * SR)
    return _fft_filter(_noise(rng, n), 2500, 9000) * _env(n, 0.0003, 0.006)


def pop(secs, rng, f0=900, f1=250, **k):
    n = int(secs * SR)
    return _sweep(f0, f1, secs) * _env(n, 0.0005, 0.035) + 0.2 * click(secs, rng)


def _bell(freqs, amps, secs, decay):
    n = int(secs * SR)
    t = _t(secs)
    return sum(a * np.sin(2 * np.pi * f * t) * np.exp(-t / (decay / (1 + 0.4 * i))) for i, (f, a) in enumerate(zip(freqs, amps))) * np.minimum(1, t / 0.001)


def tink(secs, rng, f=2400, **k):
    return _bell([f, f * 2.76, f * 5.4], [1, 0.5, 0.25], secs, 0.12)


def ding(secs, rng, f=1320, **k):
    return _bell([f, f * 2, f * 3.01], [1, 0.4, 0.2], secs, 0.5)


def sparkle(secs, rng, **k):
    n = int(secs * SR)
    out = np.zeros(n)
    notes = [1568, 1976, 2349, 2637, 3136, 3951]
    for i in range(int(secs * 18)):
        at = int(i / 18 * SR * 0.9 + rng.integers(0, 600))
        f = notes[rng.integers(0, len(notes))]
        seg = _bell([f, f * 2.01], [1, 0.3], 0.25, 0.08)
        j = min(n, at + len(seg))
        out[at:j] += seg[: j - at] * (1 - i / (secs * 18) * 0.6)
    return out


def buzzer(secs, rng, f=150, **k):
    t = _t(secs)
    x = np.sign(np.sin(2 * np.pi * f * t)) + 0.5 * np.sign(np.sin(2 * np.pi * f * 1.5 * t))
    return _fft_filter(x, 100, 3000) * np.minimum(1, t / 0.005) * np.minimum(1, (secs - t) / 0.03)


def step(secs, rng, **k):
    n = int(secs * SR)
    return _sweep(120, 55, secs) * _env(n, 0.001, 0.05) + 0.4 * _fft_filter(_noise(rng, n), 300, 2500) * _env(n, 0.001, 0.03)


def crunch(secs, rng, **k):
    n = int(secs * SR)
    out = np.zeros(n)
    for _ in range(int(secs * 40) + 3):
        at = rng.integers(0, max(1, int(n * 0.7)))
        L = rng.integers(int(0.002 * SR), int(0.012 * SR))
        out[at:at + L] += _noise(rng, min(L, n - at)) * rng.uniform(0.3, 1) * np.exp(-np.arange(min(L, n - at)) / (L / 4))
    return _fft_filter(out, 700, 7000)


def rewind(secs, rng, **k):
    """A tape spooling backwards: a fast rising squeal under chattering noise."""
    n = int(secs * SR)
    tone = _sweep(300, 2600, secs, 'exp') * 0.5
    chat = _fft_filter(_noise(rng, n), 1200, 7000) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 38 * _t(secs))))
    return (tone + 0.7 * chat) * np.sin(np.pi * np.linspace(0, 1, n) ** 0.7)


def glitch(secs, rng, **k):
    n = int(secs * SR)
    x = np.sign(np.sin(2 * np.pi * rng.uniform(300, 900) * _t(secs))) * 0.5 + _noise(rng, n) * 0.3
    gate = np.repeat(rng.integers(0, 2, int(secs * 60) + 1), SR // 60 + 1)[:n]
    return _fft_filter(x, 200, 8000) * gate


def riser(secs, rng, **k):
    n = int(secs * SR)
    return (_sweep(150, 1800, secs) * 0.6 + _fft_filter(_noise(rng, n), 500, 8000) * 0.4) * np.linspace(0.1, 1, n) ** 2


def fall(secs, rng, **k):
    n = int(secs * SR)
    return _sweep(1500, 220, secs) * np.sin(np.pi * np.linspace(0, 1, n) ** 0.5) * 0.9


def chirp(secs, rng, **k):
    n = int(secs * SR)
    c = _sweep(1900, 3400, 0.1) * _env(int(0.1 * SR), 0.003, 0.05)
    return np.pad(c, (0, max(0, n - len(c))))[:n]


def switch(secs, rng, **k):
    n = int(secs * SR)
    c = _fft_filter(_noise(rng, n), 1500, 6000) * _env(n, 0.0003, 0.008)
    return c + 0.6 * _sweep(260, 120, secs) * _env(n, 0.0005, 0.03)


def swallow(secs, rng, **k):
    n = int(secs * SR)
    return _sweep(380, 140, secs) * np.sin(np.pi * np.linspace(0, 1, n)) * 0.8 + 0.1 * _fft_filter(_noise(rng, n), 200, 1200)


# voice-like effects ----------------------------------------------------------
def laugh(secs, rng, **k):
    n = int(secs * SR)
    out = np.zeros(n)
    hs = max(3, int(secs / 0.17))
    for i in range(hs):
        at = int(i * 0.17 * SR)
        L = int(0.11 * SR)
        f0 = 260 - i * 6
        src = _saw(np.full(L, f0 * (1 + 0.03 * np.sin(np.arange(L) / SR * 40))), L / SR) + 0.15 * _noise(rng, L)
        h = _formant(src, 700, 1200) * _env(L, 0.008, 0.05)
        j = min(n, at + L)
        out[at:j] += h[: j - at] * (1 - i / hs * 0.5)
    return out


def gasp(secs, rng, **k):
    n = int(secs * SR)
    x = _formant(_noise(rng, n), 900, 2200, 0.3) * np.linspace(0.2, 1, n) ** 1.5
    return x * np.minimum(1, (secs - _t(secs)) / 0.05)


def yowl(secs, rng, **k):
    n = int(secs * SR)
    t = _t(secs)
    f = 520 + 380 * np.sin(np.pi * t / secs) + 12 * np.sin(2 * np.pi * 7 * t)
    return _formant(_saw(f, secs), 900, 1800, 0.2) * np.sin(np.pi * np.linspace(0, 1, n) ** 0.6)


# beds ------------------------------------------------------------------------
def drone(secs, rng, f=55, **k):
    t = _t(secs)
    x = sum(_saw(f * m * (1 + d), secs) * a for m, d, a in [(1, 0, 1), (1.5, 0.004, 0.4), (2, -0.003, 0.3)])
    return _fft_filter(x, 30, 500) * np.minimum(1, t / 0.2) * np.minimum(1, (secs - t) / 0.3)


def hum(secs, rng, f=60, **k):
    t = _t(secs)
    x = sum(np.sin(2 * np.pi * f * h * t) / h for h in (1, 2, 3, 4)) + 0.05 * _noise(rng, len(t))
    return x * np.minimum(1, t / 0.1) * np.minimum(1, (secs - t) / 0.15)


def room(secs, rng, **k):
    n = int(secs * SR)
    x = _fft_filter(_noise(rng, n), 60, 700) + 0.3 * _fft_filter(_noise(rng, n), 2000, 5000)
    return x * np.minimum(1, _t(secs) / 0.2) * np.minimum(1, (secs - _t(secs)) / 0.2)


def wind(secs, rng, **k):
    n = int(secs * SR)
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * rng.uniform(0.15, 0.3) * _t(secs) + rng.uniform(0, 6))
    x = _fft_filter(_noise(rng, n), 150, 1400) * lfo
    return x * np.minimum(1, _t(secs) / 0.3) * np.minimum(1, (secs - _t(secs)) / 0.3)


def music(secs, rng, bpm=110, **k):
    """A light, playful bed: pizzicato arpeggio, a soft bass on the beat, glockenspiel accents (C major pentatonic)."""
    n = int(secs * SR)
    out = np.zeros(n)
    beat = 60 / bpm
    scale = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25]
    prog = [0, 3, 4, 2]  # root scale degrees per bar
    for i in range(int(secs / (beat / 2)) + 1):
        at = int(i * beat / 2 * SR)
        if at >= n:
            break
        bar = (i // 8) % len(prog)
        deg = (prog[bar] + [0, 2, 4, 2, 5, 4, 2, 1][i % 8]) % len(scale)
        pluck = _bell([scale[deg], scale[deg] * 2.0], [1, 0.25], 0.35, 0.09)
        j = min(n, at + len(pluck))
        out[at:j] += pluck[: j - at] * 0.5
        if i % 2 == 0:
            b = np.sin(2 * np.pi * scale[prog[bar]] / 2 * _t(0.4)) * _env(int(0.4 * SR), 0.005, 0.18)
            j = min(n, at + len(b))
            out[at:j] += b[: j - at] * 0.7
        if i % 8 in (3, 7):
            g = _bell([scale[(deg + 4) % 8] * 2, scale[(deg + 4) % 8] * 4.01], [1, 0.3], 0.6, 0.25)
            j = min(n, at + len(g))
            out[at:j] += g[: j - at] * 0.25
    return out * np.minimum(1, (secs - _t(secs)) / 0.4)


KINDS = [  # (keywords in prompt or name, kind): first match wins
    (('music', 'background music', 'bed'), 'music'),
    (('boom', 'title'), 'boom'),
    (('rewind', 'tape', 'reverse'), 'rewind'),
    (('glitch', 'static', 'digital'), 'glitch'),
    (('laugh', 'giggle', 'chuckle'), 'laugh'),
    (('gasp',), 'gasp'),
    (('chirp', 'bird', 'tweet', 'dizzy'), 'chirp'),
    (('yowl', 'meow', 'cat'), 'yowl'),
    (('gulp', 'swallow'), 'swallow'),
    (('switch', 'light off', 'power down', 'power_down'), 'switch'),
    (('buzzer', 'buzz', 'error', 'wrong'), 'buzzer'),
    (('sparkle', 'twinkle', 'magic', 'shimmer'), 'sparkle'),
    (('ding', 'bell', 'chime', 'shades'), 'ding'),
    (('clink', 'tink', 'glass', 'shatter', 'smash'), 'tink'),
    (('crunch', 'crisp', 'cookie', 'munch'), 'crunch'),
    (('step', 'foot', 'walk', 'tiptoe'), 'step'),
    (('whoosh', 'swoosh', 'swish', 'fly', 'zoom'), 'whoosh'),
    (('fall', 'drop', 'tumble'), 'fall'),
    (('riser', 'rise', 'build'), 'riser'),
    (('drone', 'rumble'), 'drone'),
    (('hum', 'power', 'electric', 'buzzing'), 'hum'),
    (('wind', 'breeze'), 'wind'),
    (('room', 'tone', 'ambience', 'ambient', 'murmur'), 'room'),
    (('click', 'tick', 'tap', 'copy', 'clock', 'select'), 'click'),
    (('pop', 'paste', 'bubble', 'bulb'), 'pop'),
    (('land', 'thud', 'hit', 'impact', 'slam', 'bump', 'catch', 'crack', 'paper'), 'hit'),
]
GEN = {k: v for k, v in globals().items() if k in {
    'hit', 'boom', 'whoosh', 'click', 'pop', 'tink', 'ding', 'sparkle', 'buzzer', 'drone', 'hum', 'room', 'wind', 'step', 'crunch',
    'rewind', 'glitch', 'riser', 'fall', 'chirp', 'laugh', 'gasp', 'yowl', 'swallow', 'switch', 'music'}}


def _find(hay):
    for words, kind in KINDS:
        if any(re.search(r'\b' + re.escape(w) + r'(s|es|ing|ed)?\b', hay) for w in words):
            return kind
    return None


def infer_kind(name, prompt):
    """The clip's name decides first (whole words only), then its prompt; a plain thud if neither says."""
    return _find(name.replace('_', ' ').lower()) or _find(prompt.lower()) or 'hit'


def make(name, prompt, secs, kind=None, params=None):
    """Synthesise one clip: a float array at 44.1 kHz."""
    kind = kind or infer_kind(name, prompt)
    if kind not in GEN:
        raise SystemExit(f'Unknown clip kind "{kind}" for {name}. Kinds: {", ".join(sorted(GEN))}')
    x = GEN[kind](secs, _rng(name + prompt), **(params or {}))
    n = int(secs * SR)
    x = np.pad(x, (0, max(0, n - len(x))))[:n]
    return x
