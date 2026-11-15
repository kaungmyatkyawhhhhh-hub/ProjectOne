"""MM Outfit Catalog UI sounds: our own synthesis (roblox-game-sounds skill, section 2.2).

One family: soft, clean, boutique. Everything sits in C major pentatonic (C E G A) so UI
sounds never clash with each other or the music. Identity lives in 1-5 kHz (phone speakers).
Layers per sound: transient (0-30 ms) + body (100-400 ms) + tail where it matters.
Output: 48 kHz mono OGG, start trimmed, 6 ms fade-in, tail fade, peak <= -1 dBFS,
loudness about -18 LUFS (signature sounds) / -20 LUFS (taps), measured with pyloudnorm.

Run: python make_ui_sounds.py   -> writes ./out/*.ogg and ./out/listen.html
"""
from pathlib import Path

import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy import signal

SR = 48000
OUT = Path(__file__).parent / "out"
rng = np.random.default_rng(7)

# C major pentatonic, octave 5-6
N = {"C5": 523.25, "E5": 659.25, "G5": 783.99, "A5": 880.0, "C6": 1046.5, "E6": 1318.5, "G6": 1568.0, "C7": 2093.0}


def t_axis(sec):
    return np.arange(int(SR * sec)) / SR


def env(sec, attack=0.004, decay=0.25):
    t = t_axis(sec)
    a = np.clip(t / attack, 0, 1)
    return a * np.exp(-t / decay)


def bell(freq, sec, decay=0.3, bright=0.35):
    """Soft glassy bell: fundamental + slightly inharmonic partials."""
    t = t_axis(sec)
    tone = np.sin(2 * np.pi * freq * t)
    tone += bright * np.sin(2 * np.pi * freq * 2.01 * t) * np.exp(-t / (decay * 0.5))
    tone += 0.18 * np.sin(2 * np.pi * freq * 3.98 * t) * np.exp(-t / (decay * 0.25))
    return tone * env(sec, 0.003, decay)


def click(sec=0.03, freq=3200, q=4.0):
    """Short filtered noise tick = the transient layer."""
    n = rng.standard_normal(int(SR * sec))
    b, a = signal.iirpeak(freq, q, fs=SR)
    x = signal.lfilter(b, a, n)
    return x * env(sec, 0.0008, sec / 4)


def whoosh(sec, f0, f1, width=0.9, level=1.0):
    """Filtered noise whose band sweeps f0 -> f1 (rising or falling air)."""
    n = rng.standard_normal(int(SR * sec))
    out = np.zeros_like(n)
    block = 256
    freqs = np.geomspace(f0, f1, len(n) // block + 1)
    zi = None
    for i, f in enumerate(freqs):
        s = slice(i * block, (i + 1) * block)
        if s.start >= len(n):
            break
        lo, hi = f * (1 - width / 2), f * (1 + width / 2)
        b, a = signal.butter(2, [max(lo, 60), min(hi, SR / 2 - 100)], btype="band", fs=SR)
        if zi is None or len(zi) != max(len(a), len(b)) - 1:
            zi = signal.lfilter_zi(b, a) * 0
        out[s], zi = signal.lfilter(b, a, n[s], zi=zi)
    t = t_axis(sec)
    shape = np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 1.6
    return out * shape * level


def pop(sec=0.12, f_start=900, f_end=380):
    """Bubbly pop: fast downward pitch sweep."""
    t = t_axis(sec)
    f = f_end + (f_start - f_end) * np.exp(-t / 0.02)
    phase = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(phase) * env(sec, 0.002, 0.05)


def mix(*parts):
    length = max(len(p) for p, _ in parts)
    out = np.zeros(length)
    for p, offset in parts:
        start = int(SR * offset)
        end = min(length, start + len(p))
        if start < length:
            out[start:end] += p[: end - start]
    return out


def place(x, offset):
    return (x, offset)


def finish(x, lufs=-18.0):
    # trim leading silence, fade in 6 ms, fade the last 25 ms
    nz = np.flatnonzero(np.abs(x) > 1e-4)
    if len(nz):
        x = x[max(0, nz[0] - 24):]
    fi = int(SR * 0.006)
    x[:fi] *= np.linspace(0, 1, fi)
    fo = min(len(x), int(SR * 0.025))
    x[-fo:] *= np.linspace(1, 0, fo)
    # loudness (pad short sounds to 0.5 s for the meter), then peak guard -1 dBFS
    meter = pyln.Meter(SR)
    padded = np.concatenate([x, np.zeros(max(0, int(SR * 0.5) - len(x)))])
    loud = meter.integrated_loudness(padded)
    if np.isfinite(loud):
        x = x * (10 ** ((lufs - loud) / 20))
    peak = np.max(np.abs(x))
    if peak > 0.89:
        x = x * (0.89 / peak)
    return x.astype(np.float32)


SOUNDS = {}

# Tap: dry tick + tiny pitched body (3 variants, pitch steps inside the key)
for i, f in enumerate([N["G6"], N["A5"] * 2, N["E6"]]):
    SOUNDS[f"ui_tap_{i + 1}"] = (mix(place(click(0.025, 3600 + i * 300), 0), place(0.35 * bell(f, 0.07, 0.02, 0.1), 0.002)), -21)

# Panel open / close: rising / falling air with a soft note
SOUNDS["ui_open"] = (mix(place(whoosh(0.26, 700, 3200, 0.8), 0), place(0.25 * bell(N["G5"], 0.25, 0.09), 0.1)), -20)
SOUNDS["ui_close"] = (mix(place(whoosh(0.22, 2800, 600, 0.8), 0), place(0.2 * bell(N["C5"], 0.2, 0.07), 0.06)), -21)

# Viewer open (signature): studio-light swell = rising air + shimmer C-E-G
SOUNDS["viewer_open"] = (mix(
    place(whoosh(0.5, 300, 5000, 1.0, 0.9), 0),
    place(0.32 * bell(N["C6"], 0.5, 0.18), 0.22),
    place(0.26 * bell(N["E6"], 0.45, 0.16), 0.27),
    place(0.22 * bell(N["G6"], 0.42, 0.15), 0.32),
    place(0.5 * click(0.02, 5200, 3.0), 0.22),
), -18)

# Outfit switch: quick swipe + tick
SOUNDS["outfit_switch"] = (mix(place(whoosh(0.2, 1400, 4200, 0.7), 0), place(0.6 * click(0.02, 4200), 0.13)), -20)

# Buy prompt: confirm, two notes rising (major third)
SOUNDS["buy_prompt"] = (mix(place(click(0.02, 3000), 0), place(bell(N["E6"], 0.18, 0.08), 0.0), place(bell(N["G6"], 0.24, 0.11), 0.08)), -18)

# Purchase success (signature): C-E-G-C arpeggio + sparkle tail
sparkle = np.zeros(int(SR * 0.6))
for k in range(9):
    f = rng.choice([N["C7"], N["G6"] * 2, N["E6"] * 2])
    s = 0.12 * bell(f, 0.12, 0.04, 0.2)
    st = int(SR * rng.uniform(0.0, 0.45))
    sparkle[st:st + len(s)] += s[: len(sparkle) - st]
SOUNDS["purchase_success"] = (mix(
    place(bell(N["C6"], 0.5, 0.2), 0.0),
    place(bell(N["E6"], 0.5, 0.2), 0.07),
    place(bell(N["G6"], 0.55, 0.22), 0.14),
    place(1.1 * bell(N["C7"], 0.8, 0.32), 0.21),
    place(sparkle, 0.28),
    place(0.5 * click(0.02, 4800), 0.0),
), -17)

# Can't buy / info toast: gentle falling two notes (G -> E), soft, never harsh
SOUNDS["ui_soft_no"] = (mix(place(bell(N["G5"], 0.16, 0.07, 0.15), 0), place(bell(N["E5"], 0.22, 0.09, 0.15), 0.09)), -22)

# Wishlist add: bubbly pop + high ding
SOUNDS["wishlist_add"] = (mix(place(pop(0.12, 1100, 420), 0), place(0.55 * bell(N["A5"] * 2, 0.3, 0.12), 0.05)), -19)

# Floor arrival (replaces the stock electronic ping): two-tone elevator chime G5 -> C6
SOUNDS["floor_chime"] = (mix(place(bell(N["G5"], 0.5, 0.28, 0.25), 0), place(bell(N["C6"], 0.7, 0.35, 0.25), 0.28)), -20)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    meter = pyln.Meter(SR)
    for name, (x, lufs) in SOUNDS.items():
        y = finish(x.copy(), lufs)
        sf.write(OUT / f"{name}.ogg", y, SR, format="OGG", subtype="VORBIS")
        padded = np.concatenate([y, np.zeros(max(0, int(SR * 0.5) - len(y)))])
        rows.append((name, len(y) / SR, meter.integrated_loudness(padded), 20 * np.log10(np.max(np.abs(y)) + 1e-9)))
    html = ["<!doctype html><meta charset=utf-8><title>MM UI sounds</title>",
            "<body style='font-family:system-ui;background:#15171d;color:#eee;padding:24px'>",
            "<h2>MM Outfit Catalog: UI sounds (listen on a phone speaker too)</h2><table>"]
    for name, dur, loud, peak in rows:
        html.append(f"<tr><td style='padding:6px 16px 6px 0'>{name}</td><td>{dur:.2f}s</td>"
                    f"<td style='padding:0 16px'>{loud:.1f} LUFS</td><td>{peak:.1f} dBFS</td>"
                    f"<td><audio controls src='{name}.ogg'></audio></td></tr>")
    html.append("</table></body>")
    (OUT / "listen.html").write_text("\n".join(html), encoding="utf-8")
    for r in rows:
        print(f"{r[0]:18s} {r[1]:.2f}s  {r[2]:6.1f} LUFS  peak {r[3]:5.1f} dBFS")


if __name__ == "__main__":
    main()
