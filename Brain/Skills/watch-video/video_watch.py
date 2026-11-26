#!/usr/bin/env python3
"""video_watch.py - turn videos into things Claude can look at.

Claude can't play a video. This script makes, for each video:
  sheets/sheet_01.jpg ...  labelled contact sheets (one frame every N seconds)
  frames/                  small single frames at the same times (for close looks)
  cuts.txt                 times of every scene cut (edits, camera jumps)
  audio/audio_01.png ...   loudness line + spectrogram, 30 s per row
  audio/audio.json         loudness per 0.5 s, frequency balance, loudest moments, sound starts
  info.json                length, size, fps, rotation, recording time, GPS, camera
  transcript.txt           speech with timestamps (only with --transcript and faster-whisper)
  WATCH.md                 what to open, in order

Usage (from Claude Code, Git Bash or PowerShell):
  python video_watch.py <video or folder> [more ...] [--out DIR] [--every 2] [--transcript]
  python video_watch.py <video> --at 12.5,31,40.2 [--out DIR]   # sharp full-size frames at those seconds
  python video_watch.py <video> --zoom 100 115 [--out DIR]       # detailed sound picture of 100-115 s

Needs: Python 3.9+, numpy, pillow, and ffmpeg (on PATH, or `pip install imageio-ffmpeg`).
"""
import argparse, json, math, os, re, shutil, subprocess, sys, wave
from pathlib import Path

VIDEO_EXT = {".mp4", ".mov", ".m4v", ".mkv", ".webm", ".avi", ".wmv", ".mts", ".3gp", ".flv"}


def need(mod, pipname=None):
    try:
        return __import__(mod)
    except ImportError:
        sys.exit(f"Missing Python package '{mod}'. Run:  python -m pip install {pipname or mod}")


np = need("numpy")
PIL = need("PIL", "pillow")
from PIL import Image, ImageDraw, ImageFont  # noqa: E402


def find_ffmpeg():
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    for p in [r"C:\ffmpeg\bin\ffmpeg.exe", os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe")]:
        if os.path.isfile(p):
            return p
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        sys.exit("ffmpeg not found. Install one of:\n  winget install Gyan.FFmpeg   (then open a new terminal)\n"
                 "  python -m pip install imageio-ffmpeg")


FF = find_ffmpeg()


def run(args, binary=False):
    r = subprocess.run([FF, "-hide_banner", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return r.stdout if binary else r.stdout.decode("utf-8", "replace"), r.stderr.decode("utf-8", "replace")


def font(size):
    for f in ["arialbd.ttf", "arial.ttf", "C:/Windows/Fonts/arialbd.ttf", "DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(f, size)
        except Exception:
            pass
    return ImageFont.load_default()


def stamp(sec):
    m, s = divmod(sec, 60)
    return f"{int(m)}:{s:04.1f}"


# ---------------------------------------------------------------- info
def probe(path):
    _, err = run(["-i", str(path)])
    meta, _ = run(["-v", "error", "-i", str(path), "-f", "ffmetadata", "-"])
    info = {"file": str(path), "bytes": path.stat().st_size}
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", err)
    info["duration_s"] = round(int(m[1]) * 3600 + int(m[2]) * 60 + float(m[3]), 2) if m else None
    v = re.search(r"Stream #\S+.*Video: (\w+).*?, (\d{2,5})x(\d{2,5})", err)
    if v:
        info["codec"], w, h = v[1], int(v[2]), int(v[3])
        info["stored_size"] = [w, h]
    fps = re.search(r"([\d.]+) fps", err)
    info["fps"] = float(fps[1]) if fps else None
    rot = re.search(r"rotation of (-?[\d.]+)", err) or re.search(r"rotate\s*:\s*(-?\d+)", err)
    info["rotation"] = float(rot[1]) if rot else 0
    if v:
        portrait_turn = abs(info["rotation"]) % 180 == 90
        info["shown_size"] = [h, w] if portrait_turn else [w, h]
        info["portrait"] = info["shown_size"][1] > info["shown_size"][0]
    info["has_audio"] = "Audio:" in err
    tags = {}
    for line in meta.splitlines():
        if "=" in line and not line.startswith(";"):
            k, _, val = line.partition("=")
            tags[k.strip()] = val.strip()
    for line in err.splitlines():  # stream/format tags printed by -i
        mm = re.match(r"\s+([\w.\-]+)\s*:\s(.+)", line)
        if mm and mm[1] not in tags and len(mm[2]) < 120:
            tags[mm[1]] = mm[2].strip()
    keep = {}
    for k, val in tags.items():
        kl = k.lower()
        if any(s in kl for s in ("creation", "date", "location", "make", "model", "software", "title",
                                 "comment", "artist", "description", "encoder")):
            keep[k] = val
    info["tags"] = keep
    loc = next((val for k, val in tags.items() if "iso6709" in k.lower() or k.lower() == "location"), None)
    if loc:
        g = re.match(r"([+-]\d+\.?\d*)([+-]\d+\.?\d*)", loc)
        if g:
            info["gps_start"] = {"lat": float(g[1]), "lon": float(g[2]),
                                 "maps": f"https://www.google.com/maps?q={float(g[1])},{float(g[2])}"}
    return info


# ---------------------------------------------------------------- frames
def grab_frames(path, out, every, width):
    fdir = out / "frames"
    fdir.mkdir(parents=True, exist_ok=True)
    for f in fdir.glob("f_*.jpg"):
        f.unlink()
    # one frame every N seconds, at the middle of each slot; ffmpeg applies rotation itself
    run(["-v", "error", "-i", str(path), "-vf", f"fps=1/{every}:start_time={every/2},scale={width}:-2",
         "-q:v", "3", str(fdir / "f_%05d.jpg")])
    frames = sorted(fdir.glob("f_*.jpg"))
    named = []
    for i, f in enumerate(frames):
        t = every / 2 + i * every
        nf = fdir / f"t{t:07.1f}s.jpg"
        if nf.exists():
            nf.unlink()
        f.rename(nf)
        named.append((t, nf))
    return named


def sheets(named, out, portrait, title):
    sdir = out / "sheets"
    sdir.mkdir(parents=True, exist_ok=True)
    for f in sdir.glob("*.jpg"):
        f.unlink()
    cols, rows = (6, 3) if portrait else (4, 4)
    per = cols * rows
    fnt, fnt_t = font(22), font(26)
    paths = []
    for si in range(0, len(named), per):
        chunk = named[si:si + per]
        ims = [Image.open(p).convert("RGB") for _, p in chunk]
        tw = 300 if portrait else 460
        th = int(ims[0].height * tw / ims[0].width)
        head = 40
        S = Image.new("RGB", (cols * tw + (cols + 1) * 4, head + rows * (th + 4) + 4), (20, 20, 20))
        d = ImageDraw.Draw(S)
        d.text((8, 6), f"{title}   {stamp(chunk[0][0])} - {stamp(chunk[-1][0])}", fill=(255, 255, 255), font=fnt_t)
        for i, ((t, _), im) in enumerate(zip(chunk, ims)):
            x, y = 4 + (i % cols) * (tw + 4), head + (i // cols) * (th + 4)
            S.paste(im.resize((tw, th)), (x, y))
            label = stamp(t)
            bw = d.textlength(label, font=fnt) + 10
            d.rectangle([x, y, x + bw, y + 28], fill=(0, 0, 0))
            d.text((x + 5, y + 2), label, fill=(255, 230, 0), font=fnt)
        p = sdir / f"sheet_{si // per + 1:02d}.jpg"
        S.save(p, quality=82)
        paths.append(p)
    return paths


def scene_cuts(path, thresh=0.3):
    _, err = run(["-i", str(path), "-vf", f"scale=320:-2,select='gt(scene,{thresh})',showinfo", "-an", "-f", "null", "-"])
    return [round(float(t), 2) for t in re.findall(r"pts_time:([\d.]+)", err)]


def sharp_frames(path, out, times):
    adir = out / "at"
    adir.mkdir(parents=True, exist_ok=True)
    res = []
    for t in times:
        p = adir / f"t{t:07.2f}s.jpg"
        run(["-v", "error", "-y", "-ss", str(t), "-i", str(path), "-frames:v", "1", "-q:v", "2", str(p)])
        if p.exists():
            res.append(p)
    return res


# ---------------------------------------------------------------- audio
SR = 22050


def load_audio(path, a=None, b=None):
    # iPhones can store spatial audio (APAC) as the first track, which ffmpeg can't decode:
    # try the default pick first, then each audio track in turn until one decodes.
    for amap in (None, 0, 1, 2, 3):
        x = _load_audio(path, a, b, amap)
        if len(x):
            return x
    return x


def _load_audio(path, a=None, b=None, amap=None):
    args = ["-v", "error"]
    if a is not None:
        args += ["-ss", str(a)]
    args += ["-i", str(path)]
    if b is not None:
        args += ["-t", str(b - (a or 0))]
    if amap is not None:
        args += ["-map", f"0:a:{amap}"]
    args += ["-vn", "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"]
    raw, _ = run(args, binary=True)
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def stft_db(x, nfft=1024, hop=256):
    if len(x) < nfft:
        x = np.pad(x, (0, nfft - len(x)))
    n = 1 + (len(x) - nfft) // hop
    idx = np.arange(nfft)[None, :] + hop * np.arange(n)[:, None]
    win = np.hanning(nfft).astype(np.float32)
    P = np.abs(np.fft.rfft(x[idx] * win, axis=1)) ** 2
    f = np.fft.rfftfreq(nfft, 1 / SR)
    return f, np.arange(n) * hop / SR, P.T  # P: freq x time


def colorize(S):
    # simple magma-like ramp: black -> purple -> orange -> pale yellow
    stops = np.array([[0, 0, 4], [80, 18, 123], [182, 54, 121], [251, 136, 97], [252, 253, 191]], float)
    v = np.clip(S, 0, 1) * (len(stops) - 1)
    i = np.minimum(v.astype(int), len(stops) - 2)
    fr = (v - i)[..., None]
    return (stops[i] * (1 - fr) + stops[i + 1] * fr).astype(np.uint8)


def spectro_strip(f, t, P, t0, t1, width, fmax=8000, height=220):
    m = f <= fmax
    sel = (t >= t0) & (t < t1)
    S = 10 * np.log10(P[m][:, sel] + 1e-12)
    return S


def audio_study(path, out, duration):
    adir = out / "audio"
    adir.mkdir(parents=True, exist_ok=True)
    for p in adir.glob("audio_*.png"):
        p.unlink()
    x = load_audio(path)
    if len(x) < SR // 2:
        return None
    hop = SR // 2
    rms = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2) + 1e-12) for i in range(0, len(x) - hop + 1, hop)])
    db = 20 * np.log10(rms)
    f, t, P = stft_db(x)
    tot = P.sum(0) + 1e-12
    bands = {"rumble <150 Hz": (0, 150), "low 150-600": (150, 600), "mid 600-2k": (600, 2000),
             "presence 2-5k": (2000, 5000), "air 5k+": (5000, SR / 2)}
    share = {k: round(float((P[(f >= a) & (f < b)].sum(0) / tot).mean()), 3) for k, (a, b) in bands.items()}
    # sound starts (onsets): spectral flux peaks
    L = np.log10(P + 1e-10)
    flux = np.maximum(np.diff(L, axis=1), 0).sum(0)
    flux = (flux - np.median(flux)) / (np.std(flux) + 1e-9)
    on = [i for i in range(1, len(flux) - 1) if flux[i] > 3 and flux[i] >= flux[i - 1] and flux[i] >= flux[i + 1]]
    onsets, last = [], -1
    for i in on:
        tt = float(t[i + 1])
        if tt - last > 0.15:
            onsets.append(round(tt, 2)); last = tt
    order = np.argsort(db)[::-1]
    loud = []
    for i in order:
        tt = round(float(i) * 0.5, 1)
        if all(abs(tt - q) > 2 for q in loud):
            loud.append(tt)
        if len(loud) == 8:
            break
    rep = {"level_dbfs_per_0.5s": [round(float(v), 1) for v in db],
           "level_summary": {"median": round(float(np.median(db)), 1), "quiet_10pct": round(float(np.percentile(db, 10)), 1),
                             "loud_10pct": round(float(np.percentile(db, 90)), 1), "max": round(float(db.max()), 1)},
           "band_share": share,
           "loudest_moments_s": loud,
           "sound_starts_s": onsets,
           "sound_starts_per_s": round(len(onsets) / max(duration or len(x) / SR, 1), 2),
           "silent": bool(db.max() < -60)}
    json.dump(rep, open(adir / "audio.json", "w"), indent=1)
    # pictures: 30 s per row, 5 rows per image (2.5 min)
    S = 10 * np.log10(P[f <= 8000] + 1e-12)
    lo, hi = np.percentile(S, 30), np.percentile(S, 99.7)
    S = (S - lo) / (hi - lo + 1e-9)
    row_s, rows_per, W, H, LH = 30, 5, 1500, 200, 60
    nrows = math.ceil((len(x) / SR) / row_s)
    fnt = font(16)
    pics = []
    dmin, dmax = max(db.min(), -70), db.max() + 1
    for pi in range(0, nrows, rows_per):
        rr = range(pi, min(nrows, pi + rows_per))
        img = Image.new("RGB", (W + 60, len(rr) * (H + LH + 30) + 10), (15, 15, 15))
        d = ImageDraw.Draw(img)
        for k, r in enumerate(rr):
            y0 = 10 + k * (H + LH + 30)
            t0, t1 = r * row_s, (r + 1) * row_s
            # loudness line
            seg = db[int(t0 * 2):int(t1 * 2)]
            pts = [(60 + (i + 0.5) / (row_s * 2) * W, y0 + LH - (v - dmin) / (dmax - dmin) * LH) for i, v in enumerate(seg)]
            d.rectangle([60, y0, 60 + W, y0 + LH], outline=(60, 60, 60))
            if len(pts) > 1:
                d.line(pts, fill=(120, 220, 255), width=2)
            d.text((2, y0), f"{seg.max():.0f}dB" if len(seg) else "", fill=(150, 150, 150), font=fnt)
            # spectrogram
            sel = (t >= t0) & (t < t1)
            if sel.any():
                arr = colorize(S[::-1][:, sel])
                im = Image.fromarray(arr).resize((max(1, int(W * (t[sel][-1] - t0 + 0.01) / row_s)), H))
                img.paste(im, (60, y0 + LH + 4))
            for hz in (1000, 2000, 4000, 8000):
                yy = y0 + LH + 4 + H - hz / 8000 * H
                d.text((2, yy - 8), f"{hz // 1000}k", fill=(150, 150, 150), font=fnt)
            for s in range(0, row_s + 1, 2):
                xx = 60 + s / row_s * W
                d.line([xx, y0 + LH + H + 4, xx, y0 + LH + H + 10], fill=(200, 200, 200))
                if s % 4 == 0:
                    d.text((xx - 10, y0 + LH + H + 10), stamp(t0 + s), fill=(200, 200, 200), font=fnt)
        p = adir / f"audio_{pi // rows_per + 1:02d}.png"
        img.save(p)
        pics.append(p)
    return rep, pics


def zoom(path, out, a, b):
    x = load_audio(path, a, b)
    f, t, P = stft_db(x, nfft=4096, hop=512)
    m = f <= 6000
    S = 10 * np.log10(P[m] + 1e-12)
    lo, hi = np.percentile(S, 30), np.percentile(S, 99.8)
    arr = colorize((S[::-1] - lo) / (hi - lo + 1e-9))
    W, H = 1500, 600
    img = Image.new("RGB", (W + 60, H + 40), (15, 15, 15))
    img.paste(Image.fromarray(arr).resize((W, H)), (60, 0))
    d = ImageDraw.Draw(img); fnt = font(16)
    for hz in range(0, 6001, 500):
        yy = H - hz / 6000 * H
        d.text((2, yy - 8), f"{hz}", fill=(170, 170, 170), font=fnt)
    span = b - a
    step = 0.5 if span <= 15 else 1 if span <= 40 else 5
    s = 0.0
    while s <= span + 1e-6:
        xx = 60 + s / span * W
        d.line([xx, H, xx, H + 6], fill=(220, 220, 220))
        d.text((xx - 14, H + 10), f"{a + s:.1f}", fill=(220, 220, 220), font=fnt)
        s += step
    p = out / "audio" / f"zoom_{a:.1f}-{b:.1f}s.png"
    p.parent.mkdir(parents=True, exist_ok=True)
    img.save(p)
    return p


def transcript(path, out, model_size):
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        return "faster-whisper not installed (python -m pip install faster-whisper) - no transcript made"
    m = WhisperModel(model_size, compute_type="int8")
    segs, info = m.transcribe(str(path), vad_filter=True)
    lines = [f"language: {info.language} (p={info.language_probability:.2f})"]
    for s in segs:
        lines.append(f"[{stamp(s.start)} - {stamp(s.end)}] {s.text.strip()}")
    (out / "transcript.txt").write_text("\n".join(lines), encoding="utf-8")
    return f"{len(lines) - 1} lines, language {info.language}"


# ---------------------------------------------------------------- main
def watch(path, root, every, width, do_tx, model_size):
    out = root / path.stem
    out.mkdir(parents=True, exist_ok=True)
    info = probe(path)
    dur = info.get("duration_s") or 0
    if every is None:
        every = 0.5 if dur <= 20 else 1 if dur <= 60 else 2 if dur <= 300 else 5 if dur <= 1200 else 10
    info["sheet_every_s"] = every
    named = grab_frames(path, out, every, width)
    sp = sheets(named, out, info.get("portrait", False), path.name)
    cuts = scene_cuts(path)
    (out / "cuts.txt").write_text("\n".join(stamp(c) + f"  ({c} s)" for c in cuts) or "no cuts found (one continuous shot)",
                                  encoding="utf-8")
    info["scene_cuts"] = len(cuts)
    aud = audio_study(path, out, dur) if info.get("has_audio") else None
    tx = transcript(path, out, model_size) if do_tx and info.get("has_audio") else None
    json.dump(info, open(out / "info.json", "w"), indent=1)
    lines = [f"# Watch: {path.name}", "",
             f"- Length {stamp(dur)} ({dur} s), shown size {info.get('shown_size')}, {info.get('fps')} fps, "
             f"{'portrait' if info.get('portrait') else 'landscape'}",
             f"- Recorded: {next((v for k, v in info['tags'].items() if 'creationdate' in k.lower() or k == 'creation_time'), 'unknown')}",
             f"- GPS at start: {info['gps_start']['lat']}, {info['gps_start']['lon']} ({info['gps_start']['maps']})" if "gps_start" in info else "- GPS: none",
             f"- Scene cuts: {len(cuts)} (cuts.txt)", ""]
    lines += ["## Open in this order", "1. Every contact sheet (yellow labels = time in the video, one frame every "
              f"{every} s):"] + [f"   - {p.relative_to(out).as_posix()}" for p in sp]
    if aud:
        rep, pics = aud
        lines += ["2. Sound pictures (blue line = loudness, below = spectrogram 0-8 kHz, 30 s per row):"] + \
                 [f"   - {p.relative_to(out).as_posix()}" for p in pics]
        lines += [f"   - level median {rep['level_summary']['median']} dBFS, loud 10% {rep['level_summary']['loud_10pct']}, "
                  f"band share {rep['band_share']}", f"   - loudest moments (s): {rep['loudest_moments_s']}",
                  f"   - sound starts per second: {rep['sound_starts_per_s']} (audio/audio.json has the list)"]
    else:
        lines += ["2. No sound track."]
    lines += ["3. " + ("transcript.txt: " + tx if tx else "No transcript (add --transcript)."),
              "4. Close looks: frames/t<seconds>s.jpg (small), or run again with --at <s,s,s> for full-size frames,",
              "   and --zoom <a> <b> for a detailed sound picture of a stretch."]
    (out / "WATCH.md").write_text("\n".join(lines), encoding="utf-8")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--out", default=None, help="output folder (default: <video folder>/_watch)")
    ap.add_argument("--every", type=float, default=None, help="seconds between sheet frames (default: by length)")
    ap.add_argument("--width", type=int, default=540, help="width of saved frames")
    ap.add_argument("--transcript", action="store_true")
    ap.add_argument("--model", default="small", help="whisper model size (tiny/base/small/medium)")
    ap.add_argument("--at", default=None, help="comma list of seconds: save full-size frames there")
    ap.add_argument("--zoom", nargs=2, type=float, default=None, metavar=("A", "B"))
    a = ap.parse_args()
    vids = []
    for s in a.inputs:
        p = Path(s)
        if p.is_dir():
            vids += sorted(q for q in p.iterdir() if q.suffix.lower() in VIDEO_EXT)
        elif p.is_file():
            vids.append(p)
        else:
            print(f"not found: {s}")
    if not vids:
        sys.exit("no videos given")
    for v in vids:
        root = Path(a.out) if a.out else v.parent / "_watch"
        out = root / v.stem
        if a.at or a.zoom:
            out.mkdir(parents=True, exist_ok=True)
            if a.at:
                for p in sharp_frames(v, out, [float(t) for t in a.at.split(",") if t.strip()]):
                    print(p)
            if a.zoom:
                print(zoom(v, out, *a.zoom))
            continue
        print(f"watching {v.name} ...", flush=True)
        o = watch(v, root, a.every, a.width, a.transcript, a.model)
        print(f"  -> {o / 'WATCH.md'}", flush=True)


if __name__ == "__main__":
    main()
