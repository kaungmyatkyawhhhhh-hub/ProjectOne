"""Step 2: the voice. FREE and offline: Piper text-to-speech, word times from a small Whisper model, then the pauses
tightened to the genre's pace. No account, no key, no credits.

python <skill>/scripts/voice.py <slug> [--force]
Reads  src/episodes/<slug>/episode.json  (script, voice, gaps)
Writes public/<slug>/voice_raw.wav, public/<slug>/voice.wav (tightened), src/episodes/<slug>/words.json (word timings
       after tightening, used by plan.py) and out/<slug>/words_raw.json.
The voice is only synthesised again when the text or the voice settings change (cached by a hash), so re-running to
retune the gaps is instant.

Setup (once): pip install piper-tts faster-whisper numpy
The Piper voice downloads itself on the first run into library/voices/ (about 120 MB, from Hugging Face).

episode.json "voice" (all optional): {"name": "en_US-ryan-high", "path": "D:/voices/x.onnx", "length_scale": 0.92,
  "noise_scale": 0.667, "noise_w_scale": 0.8, "speaker_id": null, "sentence_gap": 0.3}
  name = any voice in https://huggingface.co/rhasspy/piper-voices (en/en_US/<voice>/<quality>/<lang>-<voice>-<quality>);
  length_scale below 1 speaks faster (0.9 to 0.95 suits the genre's pace).
episode.json "gaps" (seconds, all optional): {"word": 0.12, "comma": 0.2, "sentence": 0.3, "question": 0.45,
  "pairs": {"anything|One": 0.6}}  -> every pause longer than its limit is cut to the limit, from its middle.
"""
import difflib, hashlib, json, os, re, subprocess, sys, tempfile, urllib.request, wave

import numpy as np

from wi import SR, STUDIO, decode, ep_dir, load_episode, load_json, norm, out_dir, pub_dir, save_json, write_wav

slug = sys.argv[1]
force = '--force' in sys.argv
ep = load_episode(slug)
V = {'name': 'en_US-ryan-high', 'length_scale': 0.95, 'noise_scale': 0.667, 'noise_w_scale': 0.8, 'speaker_id': None, 'sentence_gap': 0.3}
V.update(ep.get('voice', {}))
text = ' '.join(b['text'].strip() for b in ep['script'])
sig = hashlib.sha1(json.dumps([text, V], sort_keys=True).encode()).hexdigest()[:12]
raw_wav = pub_dir(slug) / 'voice_raw.wav'
raw_words = out_dir(slug) / 'words_raw.json'
meta = load_json(out_dir(slug) / 'voice_meta.json', {})

def voice_file():
    if V.get('path'):
        return V['path']
    name = V['name']
    p = STUDIO / 'library' / 'voices' / f'{name}.onnx'
    if not p.exists():
        lang, speaker, quality = name.split('-')
        base = f'https://huggingface.co/rhasspy/piper-voices/resolve/main/{lang.split("_")[0]}/{lang}/{speaker}/{quality}/{name}'
        p.parent.mkdir(parents=True, exist_ok=True)
        print(f'Downloading the Piper voice {name} (once)...')
        for ext in ('.onnx.json', '.onnx'):
            urllib.request.urlretrieve(base + ext, str(p.parent / (name + ext)))
    return str(p)


SENTS = [s.strip() for s in re.split(r'(?<=[.!?…])\s+', text) if s.strip()]
RATE_TMP = {}


def to16k(x, rate):
    return np.frombuffer(subprocess.run(['ffmpeg', '-v', 'error', '-f', 'f32le', '-ar', str(rate), '-ac', '1', '-i', '-', '-f', 'f32le', '-ac', '1', '-ar', '16000', '-'], input=x.astype(np.float32).tobytes(), capture_output=True, check=True).stdout, dtype=np.float32)


def voiced(x, rate, thr_db=-42):
    """Seconds of the first and last voiced sample of x (the speech edge, ignoring breath and tail)."""
    win = int(0.01 * rate)
    n = len(x) // win
    rms = np.sqrt((x[:n * win].reshape(n, win) ** 2).mean(1)) + 1e-9
    on = np.where(20 * np.log10(rms) > thr_db + 20 * np.log10(max(1e-6, np.abs(x).max())) + 0)[0]
    if not len(on):
        return 0.0, len(x) / rate
    return on[0] * 0.01, (on[-1] + 1) * 0.01


def synthesize():
    """One Piper call per sentence; returns the sentences' audio and writes voice_raw.wav (44.1 kHz)."""
    from piper import PiperVoice, SynthesisConfig
    v = PiperVoice.load(voice_file())
    cfg = SynthesisConfig(length_scale=V['length_scale'], noise_scale=V['noise_scale'], noise_w_scale=V['noise_w_scale'], speaker_id=V['speaker_id'])
    out, rate = [], None
    for s in SENTS:
        x = np.concatenate([ch.audio_float_array for ch in v.synthesize(s, syn_config=cfg)])
        rate = rate or v.config.sample_rate
        out.append(x)
    return out, rate


def build_raw(sent_audio, rate):
    """Concatenate the sentences with the gap between them; return each sentence's start offset in seconds."""
    gap = np.zeros(int(V['sentence_gap'] * rate), dtype=np.float32)
    parts, starts, at = [], [], 0.0
    for i, x in enumerate(sent_audio):
        starts.append(at)
        parts.append(x)
        at += len(x) / rate
        if i < len(sent_audio) - 1:
            parts.append(gap)
            at += len(gap) / rate
    x = np.concatenate(parts)
    with tempfile.TemporaryDirectory() as d:
        tmp = os.path.join(d, 'p.wav')
        with wave.open(tmp, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
        write_wav(raw_wav, decode(tmp))
    return starts


def word_times(sent_audio, rate, starts):
    """Per sentence: Whisper word timestamps matched to the script's own words (Whisper may rewrite 'ten' as '10' or
    drop a word: anything unmatched is placed by character length between its matched neighbours), then the first
    and last word are snapped to where the sentence's speech really begins and ends."""
    from faster_whisper import WhisperModel
    model = WhisperModel(V.get('aligner', 'small.en'), compute_type='int8')
    res, k0, unheard = [], 0, 0
    for s, x, off in zip(SENTS, sent_audio, starts):
        sw = [{'w': m.group(1), 'p': m.group(2)} for m in re.finditer(r"([\w'’]+)([^\w\s'’]*)", s)]
        segs, _ = model.transcribe(to16k(x, rate), language='en', word_timestamps=True, initial_prompt=s, condition_on_previous_text=False)
        heard = [(norm(w.word), w.start, w.end) for sg in segs for w in sg.words if norm(w.word)]
        want = [norm(w['w']) for w in sw]
        sm = difflib.SequenceMatcher(a=want, b=[h[0] for h in heard], autojunk=False)
        t = [None] * len(want)
        for a, b, n in sm.get_matching_blocks():
            for k in range(n):
                t[a + k] = [heard[b + k][1], heard[b + k][2]]
        v0, v1 = voiced(x, rate)
        i = 0
        while i < len(t):  # runs of unmatched words: by character length between their matched neighbours
            if t[i] is None:
                j = i
                while j < len(t) and t[j] is None:
                    j += 1
                unheard += j - i
                lo = t[i - 1][1] if i > 0 else v0
                hi = t[j][0] if j < len(t) else v1
                lens = [max(1, len(want[k])) for k in range(i, j)]
                at = lo
                for k, ln in zip(range(i, j), lens):
                    d = max(0.04, (hi - lo) * ln / sum(lens))
                    t[k] = [at, at + d]
                    at += d
                i = j
            else:
                i += 1
        t[0][0], t[-1][1] = v0, v1
        for k in range(1, len(t)):  # no overlaps, nothing negative
            t[k][0] = max(t[k][0], t[k - 1][0] + 0.03)
            t[k - 1][1] = min(max(t[k - 1][1], t[k - 1][0] + 0.03), t[k][0])
        t[-1][1] = max(t[-1][1], t[-1][0] + 0.05)
        res += [{'w': w['w'], 's': round(off + a, 3), 'e': round(off + b, 3), 'p': w['p']} for w, (a, b) in zip(sw, t)]
    if unheard:
        print(f'{unheard} word(s) were not heard by the aligner and were placed by length: check their times below.')
    return res


if force or meta.get('sig') != sig or not raw_wav.exists() or not raw_words.exists():
    print(f'{len(text)} characters to Piper (voice {V.get("path") or V["name"]}), free and offline')
    sent_audio, rate = synthesize()
    starts = build_raw(sent_audio, rate)
    save_json(raw_words, word_times(sent_audio, rate, starts))
    save_json(out_dir(slug) / 'voice_meta.json', {'sig': sig, 'chars': len(text)})
else:
    print('Voice unchanged since the last run: reusing it.')

# ---------------------------------------------------------------- tighten the pauses
words = load_json(raw_words)
G = {'word': 0.12, 'comma': 0.2, 'sentence': 0.3, 'question': 0.45, 'pairs': {}}
G.update(ep.get('gaps', {}))
x = decode(raw_wav)
cuts = []


def bare(w):
    return re.sub(r'[^\w]', '', w)


for a, b in zip(words, words[1:]):
    gap = b['s'] - a['e']
    key = bare(a['w']) + '|' + bare(b['w'])
    if key in G['pairs']:
        keep = G['pairs'][key]
    elif '?' in a['p'] or '!' in a['p']:
        keep = G['question']
    elif '.' in a['p'] or ':' in a['p'] or ';' in a['p'] or '…' in a['p']:
        keep = G['sentence']
    elif ',' in a['p'] or '—' in a['p'] or '-' in a['p']:
        keep = G['comma']
    else:
        keep = G['word']
    if gap > keep:
        mid = (a['e'] + b['s']) / 2
        rm = gap - keep
        cuts.append((mid - rm / 2, mid + rm / 2))
parts, last = [], 0.0
for s, e in cuts:
    parts.append(x[int(last * SR):int(s * SR)])
    last = e
parts.append(x[int(last * SR):])
fade = int(0.004 * SR)  # a 4 ms fade either side of each join, so no click
for i, part in enumerate(parts):
    part = part.copy()
    if i > 0 and len(part) > fade:
        part[:fade] *= np.linspace(0, 1, fade)
    if i < len(parts) - 1 and len(part) > fade:
        part[-fade:] *= np.linspace(1, 0, fade)
    parts[i] = part
y = np.concatenate(parts)
write_wav(pub_dir(slug) / 'voice.wav', y)


def shift(t):
    return t - sum(min(e, t) - s for s, e in cuts if t > s)


out = [{'w': w['w'], 's': round(shift(w['s']), 3), 'e': round(shift(w['e']), 3), 'p': w.get('p', '')} for w in words]
save_json(ep_dir(slug) / 'words.json', out)
print(f'Tightened {len(cuts)} pauses, removed {sum(e - s for s, e in cuts):.2f} s: {len(x) / SR:.2f} s -> {len(y) / SR:.2f} s')
print(' '.join(f"{w['w']}@{w['s']}" for w in out))
