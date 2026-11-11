// Watch (and MEASURE THE SOUND of) a YouTube video inside Chrome. Nothing is downloaded and nothing plays out loud.
// YouTube's file cannot be fetched from the page (it streams in pieces), so the sound is tapped while the video plays:
// video element -> Web Audio -> a recorder node -> gain 0. The tab stays silent; the samples are analysed in the page.
// 1. Open the video. 2. Click once on the page (Chrome needs one real click before it lets audio start).
// 3. Run this file with the javascript tool, then: window.__yrec(startSeconds, lengthSeconds, 2)   (2 = play at double speed)
// 4. Poll window.__Y.state until 'done'. window.__Y.audio = level, band balance, onsets (each with time, level, brightness, length).
// 5. await window.__ysheet(t0, t1, 12) draws 12 frames over a spectrogram of the same seconds; take a screenshot.
// Tip: sessionStorage.setItem('__yw', <this source>) once, then after each navigation: (0,eval)(sessionStorage.getItem('__yw')).
// 6. VOICE REMOVAL: set window.__side = true before __yrec. It records LEFT minus RIGHT, which cancels a voice recorded in the
//    middle (a YouTuber's microphone) and keeps the stereo part of the game (music, positioned SFX). Tested 11 Nov 2026:
//    the speech lines vanish from the spectrogram. The game sound left is about 30 dB quieter, and anything the game plays
//    dead centre (some UI sounds) is cancelled too.
// 7. window.__yfx() = onset counts and times per band (60-120 Hz thumps, 300-3000 Hz, 5-10.5 kHz sparkle and whoosh).
// 8. await window.__ygrid([times], cols) = frames only, as one grid, for one screenshot (no sound needed).
// 9. window.__yevents(n) = the n biggest sound events (time, length, how far above the bed, brightness): look at them with __ygrid.
// Speed: 2 = double speed with pitch not corrected, so the true frequencies are kept up to ~12 kHz. Keep each tool call under ~50 s.
// Limits: the sound is MEASURED, not heard. A YouTuber's voice and music are mixed with the game's sounds unless __side is used.
window.__Y = {state: 'idle'};
window.__fft = (re, im) => { const n = re.length; for (let i = 1, j = 0; i < n; i++) { let b = n >> 1; for (; j & b; b >>= 1) j ^= b; j ^= b; if (i < j) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
  for (let len = 2; len <= n; len <<= 1) { const a = -2 * Math.PI / len, wr = Math.cos(a), wi = Math.sin(a); for (let i = 0; i < n; i += len) { let cr = 1, ci = 0; for (let k = 0; k < len / 2; k++) { const ur = re[i + k], ui = im[i + k], vr = re[i + k + len / 2] * cr - im[i + k + len / 2] * ci, vi = re[i + k + len / 2] * ci + im[i + k + len / 2] * cr; re[i + k] = ur + vr; im[i + k] = ui + vi; re[i + k + len / 2] = ur - vr; im[i + k + len / 2] = ui - vi; const t = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = t; } } } };
window.__yrec = async (t0, dur, rate) => { const Y = window.__Y = {state: 'start'}; rate = rate || 1; try {
  const v = document.querySelector('video.html5-main-video') || document.querySelector('video'); window.__yv = v;
  Y.meta = {title: document.title.replace(/^\(\d+\)\s*/, ''), dur: +v.duration.toFixed(1), size: [v.videoWidth, v.videoHeight], url: location.href.split('&')[0], t0, len: dur, rate};
  if (!window.__ac || window.__acv !== v) { window.__ac = new AudioContext(); window.__acv = v; window.__src = window.__ac.createMediaElementSource(v);
    const sp = window.__ac.createScriptProcessor(4096, 2, 1), g0 = window.__ac.createGain(); g0.gain.value = 0; window.__src.connect(sp); sp.connect(g0); g0.connect(window.__ac.destination); window.__sp = sp; }
  const ac = window.__ac; await ac.resume(); Y.ac = ac.state;
  const chunks = []; let rec = false;
  window.__sp.onaudioprocess = e => { if (!rec) return; const a = e.inputBuffer.getChannelData(0), b = e.inputBuffer.numberOfChannels > 1 ? e.inputBuffer.getChannelData(1) : a, m = new Float32Array(a.length); for (let i = 0; i < a.length; i++) m[i] = window.__side ? .5 * (a[i] - b[i]) : .5 * (a[i] + b[i]); chunks.push(m); };
  const mu0 = v.muted, vo0 = v.volume; v.muted = false; v.volume = 1; v.preservesPitch = false; v.playbackRate = rate; v.currentTime = t0;
  await new Promise(r => { const h = () => { v.removeEventListener('seeked', h); r(); }; v.addEventListener('seeked', h); setTimeout(r, 5000); });
  await v.play(); const tStart = v.currentTime; rec = true; Y.state = 'rec';
  await new Promise(r => { const iv = setInterval(() => { Y.t = +v.currentTime.toFixed(1); if (v.currentTime >= t0 + dur || v.ended) { clearInterval(iv); r(); } }, 150); });
  rec = false; const tEnd = v.currentTime; v.pause(); window.__sp.onaudioprocess = null; v.playbackRate = 1; v.muted = mu0; v.volume = vo0;
  let n = 0; chunks.forEach(c => n += c.length); const x = new Float32Array(n); let o = 0; chunks.forEach(c => { x.set(c, o); o += c.length; });
  // true seconds per recorded sample: the video time that passed / samples recorded (covers the double speed)
  const spt = (tEnd - tStart) / n, sr = 1 / spt; Y.meta.srEff = Math.round(sr); Y.meta.tStart = +tStart.toFixed(2); Y.state = 'analyse';
  const N = 1024, H = 256, win = new Float32Array(N); for (let i = 0; i < N; i++) win[i] = .5 - .5 * Math.cos(2 * Math.PI * i / N);
  const F = Math.max(0, Math.floor((n - N) / H)), NB = 72, fmin = 60, fmax = Math.min(11000, sr / 2), flux = new Float32Array(F), lev = new Float32Array(F), cen = new Float32Array(F), flat = new Float32Array(F), spec = new Float32Array(F * NB);
  const bandOf = new Int16Array(N / 2); for (let k = 0; k < N / 2; k++) { const fr = k * sr / N; bandOf[k] = fr < fmin || fr >= fmax ? -1 : Math.min(NB - 1, Math.floor(NB * Math.log(fr / fmin) / Math.log(fmax / fmin))); }
  let prev = new Float32Array(N / 2); const big = [0, 0, 0, 0, 0], edges = [60, 250, 2000, 6000, 1e9];
  for (let f = 0; f < F; f++) { const re = new Float32Array(N), im = new Float32Array(N); let s = 0; for (let i = 0; i < N; i++) { const q = x[f * H + i]; re[i] = q * win[i]; s += q * q; } lev[f] = 10 * Math.log10(s / N + 1e-12); window.__fft(re, im);
    let fl = 0, num = 0, den = 0, lg = 0, cnt = 0; for (let k = 1; k < N / 2; k++) { const m = Math.hypot(re[k], im[k]), lm = Math.log(1 + 50 * m), d = lm - prev[k]; if (d > 0) fl += d; prev[k] = lm; const fr = k * sr / N; num += fr * m; den += m; if (fr > 100 && fr < 8000) { lg += Math.log(m + 1e-9); cnt++; } const b = bandOf[k]; if (b >= 0) spec[f * NB + b] += m * m; let e = 0; while (fr >= edges[e]) e++; big[e] += m * m; }
    flux[f] = fl; cen[f] = den > 0 ? num / den : 0; flat[f] = cnt ? Math.exp(lg / cnt) / (den / (N / 2) + 1e-9) : 0; }
  const hop = H * spt, on = [];
  for (let f = 3; f < F - 3; f++) { let mx = 0, mean = 0, c = 0; for (let j = Math.max(0, f - 10); j <= Math.min(F - 1, f + 10); j++) { mean += flux[j]; c++; if (j !== f && flux[j] > mx) mx = flux[j]; } mean /= c;
    if (flux[f] > mx && flux[f] > mean * 1.6 && flux[f] > 12) { let e = f + 1; const top = Math.max(lev[f], lev[f + 1], lev[f + 2]); while (e < F && lev[e] > top - 12 && e - f < 120) e++; let cc = 0, k2 = 0; for (let j = f; j < Math.min(F, f + 4); j++) { cc += cen[j]; k2++; }
      on.push({t: +(tStart + (f * H + N / 2) * spt).toFixed(2), db: +top.toFixed(0), hz: Math.round(cc / k2), len: +((e - f) * hop).toFixed(2), tonal: +(1 - Math.min(1, flat[f + 1] * 3)).toFixed(2)}); } }
  const tot = big.reduce((a, b) => a + b, 0); let ss = 0, pk = 0; for (let i = 0; i < n; i++) { ss += x[i] * x[i]; const a = Math.abs(x[i]); if (a > pk) pk = a; }
  const gaps = []; for (let i = 1; i < on.length; i++) gaps.push(+(on[i].t - on[i - 1].t).toFixed(2)); const sg = gaps.slice().sort((a, b) => a - b);
  window.__ys = {spec, F, NB, hop, tStart, lev, fmin, fmax};
  Y.audio = {seconds: +(tEnd - tStart).toFixed(1), rmsDb: +(10 * Math.log10(ss / Math.max(1, n) + 1e-12)).toFixed(1), peakDb: +(20 * Math.log10(pk + 1e-9)).toFixed(1), bandsPct: big.map(b => Math.round(100 * b / (tot + 1e-12))), onsets: on.length, perSecond: +(on.length / Math.max(.1, tEnd - tStart)).toFixed(2), medianGap: sg.length ? sg[Math.floor(sg.length / 2)] : null, list: on};
  Y.state = 'done';
} catch (e) { Y.state = 'err'; Y.err = String(e && e.stack || e); } };
// frames (top) over the spectrogram (bottom) for the same seconds; onsets are the white ticks. Take a screenshot after it resolves.
window.__ysheet = async (ta, tb, nf) => { const S = window.__ys, v = window.__yv, Y = window.__Y; let o = document.getElementById('__ov'); if (!o) { o = document.createElement('canvas'); o.id = '__ov'; o.style.cssText = 'position:fixed;left:0;top:0;z-index:2147483647;background:#111'; document.documentElement.appendChild(o); }
  const W = Math.min(1500, window.innerWidth - 8), cw = Math.floor(W / nf), ch = Math.round(cw * v.videoHeight / v.videoWidth), SH = 216, HH = Math.min(ch, window.innerHeight - SH - 40); o.width = W; o.height = HH + SH + 34; o.style.width = W + 'px'; o.style.height = o.height + 'px'; const g = o.getContext('2d'); g.fillStyle = '#111'; g.fillRect(0, 0, o.width, o.height);
  v.pause(); for (let k = 0; k < nf; k++) { const t = ta + (k + .5) * (tb - ta) / nf; v.currentTime = t; await new Promise(r => { const h = () => { v.removeEventListener('seeked', h); r(); }; v.addEventListener('seeked', h); setTimeout(r, 2500); }); await new Promise(r => setTimeout(r, 120));
    const w2 = Math.round(HH * v.videoWidth / v.videoHeight); g.drawImage(v, k * cw + Math.max(0, (cw - w2) / 2), 0, Math.min(cw, w2), HH); g.fillStyle = 'rgba(0,0,0,.7)'; g.fillRect(k * cw, 0, 46, 14); g.fillStyle = '#0f0'; g.font = '11px monospace'; g.fillText(t.toFixed(1), k * cw + 2, 11); }
  let mx = 1e-12; for (let i = 0; i < S.spec.length; i++) if (S.spec[i] > mx) mx = S.spec[i]; const img = g.createImageData(W, SH);
  for (let px = 0; px < W; px++) { const t = ta + (px + .5) * (tb - ta) / W, f = Math.round((t - S.tStart) / S.hop); for (let py = 0; py < SH; py++) { const b = Math.min(S.NB - 1, Math.floor((SH - 1 - py) * S.NB / SH)); let q = 0; if (f >= 0 && f < S.F) { const d = 10 * Math.log10(S.spec[f * S.NB + b] / mx + 1e-9); q = Math.max(0, Math.min(1, (d + 60) / 60)); } const i = 4 * (py * W + px); img.data[i] = 255 * Math.min(1, q * 1.6); img.data[i + 1] = 255 * Math.max(0, q * 1.8 - .6); img.data[i + 2] = 255 * (q < .5 ? q * 1.2 : 1.2 - q); img.data[i + 3] = 255; } }
  g.putImageData(img, 0, HH + 4); g.fillStyle = '#fff'; (Y.audio ? Y.audio.list : []).forEach(e => { if (e.t >= ta && e.t <= tb) g.fillRect(Math.round((e.t - ta) / (tb - ta) * W), HH + 4, 1, 10); });
  g.fillStyle = '#ccc'; g.font = '11px monospace'; for (let s = Math.ceil(ta); s <= tb; s++) { const px = (s - ta) / (tb - ta) * W; g.fillRect(px, HH + SH + 4, 1, 6); if ((tb - ta) <= 30 || s % 5 === 0) g.fillText(s + 's', px + 2, HH + SH + 22); }
  g.fillText('low ' + S.fmin + ' Hz (bottom) to ' + Math.round(S.fmax) + ' Hz (top)', W - 250, HH + SH + 30); return [o.width, o.height]; };
window.__yclear = () => { const o = document.getElementById('__ov'); if (o) o.remove(); };
window.__yband = (lo, hi) => { const S = window.__ys, F = S.F, NB = S.NB, bi = f => Math.max(0, Math.min(NB - 1, Math.round(NB * Math.log(f / S.fmin) / Math.log(S.fmax / S.fmin)))), a = bi(lo), b = bi(hi), e = new Float32Array(F); for (let f = 0; f < F; f++) { let s = 0; for (let k = a; k <= b; k++) s += S.spec[f * NB + k]; e[f] = 10 * Math.log10(s + 1e-9); } return e; };
window.__yfx = () => { const S = window.__ys, F = S.F;
  const ons = (e, rise) => { const out = []; let mx = -1e9; for (let f = 0; f < F; f++) if (e[f] > mx) mx = e[f]; for (let f = 4; f < F - 8; f++) { const d = Math.max(e[f], e[f + 1]) - Math.min(e[f - 2], e[f - 3]); if (d < rise || e[f + 1] < mx - 30) continue; let ok = true; for (let j = f - 8; j <= f + 8; j++) { if (j === f || j < 4 || j >= F - 8) continue; const dj = Math.max(e[j], e[j + 1]) - Math.min(e[j - 2], e[j - 3]); if (dj > d) { ok = false; break; } } if (ok) out.push(+(S.tStart + f * S.hop).toFixed(2)); } return out; };
  const stat = l => { const g = []; for (let i = 1; i < l.length; i++) g.push(l[i] - l[i - 1]); const s = g.slice().sort((a, b) => a - b), m = s.length ? s[Math.floor(s.length / 2)] : 0; return {n: l.length, medGap: +m.toFixed(2), regular: s.length ? +(g.filter(x => Math.abs(x - m) < .15 * m).length / g.length).toFixed(2) : 0}; };
  const sub = ons(window.__yband(60, 120), 14), hi = ons(window.__yband(5000, 10500), 14), mid = ons(window.__yband(300, 3000), 14); return {sub: stat(sub), hi: stat(hi), mid: stat(mid), subT: sub, hiT: hi}; };
// the biggest sound events: stretches where the whole band sits well above its running level (a 20 s median)
window.__yevents = (n) => { const S = window.__ys, F = S.F, all = window.__yband(60, 10500), hi = window.__yband(4000, 10500), lo = window.__yband(60, 250), W = Math.round(10 / S.hop), step = Math.round(1 / S.hop), med = new Float32Array(F);
  for (let c = 0; c < F; c += step) { const a = Math.max(0, c - W), b = Math.min(F, c + W), tmp = []; for (let j = a; j < b; j += 8) tmp.push(all[j]); tmp.sort((x, y) => x - y); const m = tmp[Math.floor(tmp.length / 2)]; for (let j = c; j < Math.min(F, c + step); j++) med[j] = m; }
  const ev = []; let st = -1, pk = 0, sum = 0; for (let f = 0; f <= F; f++) { const up = f < F && all[f] > med[f] + 9; if (up) { if (st < 0) { st = f; pk = 0; sum = 0; } const d = all[f] - med[f]; sum += d; if (d > pk) pk = d; } else if (st >= 0) { const len = (f - st) * S.hop; if (len >= 0.25) { let h = 0, l = 0; for (let j = st; j < f; j++) { h += hi[j]; l += lo[j]; } ev.push({t: +(S.tStart + st * S.hop).toFixed(1), len: +len.toFixed(2), above: +pk.toFixed(0), score: Math.round(sum * S.hop), hiMinusLow: Math.round((h - l) / (f - st))}); } st = -1; } }
  return ev.sort((a, b) => b.score - a.score).slice(0, n || 15); };
// frames only, one grid, one screenshot
window.__ygrid = async (times, cols) => { const v = document.querySelector('video.html5-main-video') || document.querySelector('video'); let o = document.getElementById('__ov'); if (!o) { o = document.createElement('canvas'); o.id = '__ov'; o.style.cssText = 'position:fixed;left:0;top:0;z-index:2147483647;background:#111'; document.documentElement.appendChild(o); } const rows = Math.ceil(times.length / cols), W = Math.min(1520, window.innerWidth - 8), cw = Math.floor(W / cols), ch = Math.min(Math.round(cw * v.videoHeight / v.videoWidth), Math.floor((window.innerHeight - 4) / rows)); o.width = cw * cols; o.height = ch * rows; o.style.width = o.width + 'px'; o.style.height = o.height + 'px'; const g = o.getContext('2d'); g.fillStyle = '#111'; g.fillRect(0, 0, o.width, o.height); v.pause(); for (let k = 0; k < times.length; k++) { v.currentTime = times[k]; await new Promise(r => { const h = () => { v.removeEventListener('seeked', h); r(); }; v.addEventListener('seeked', h); setTimeout(r, 3000); }); await new Promise(r => setTimeout(r, 150)); const x = (k % cols) * cw, y = Math.floor(k / cols) * ch, w2 = Math.round(ch * v.videoWidth / v.videoHeight); g.drawImage(v, x + Math.max(0, (cw - w2) / 2), y, Math.min(cw, w2), ch); g.fillStyle = 'rgba(0,0,0,.7)'; g.fillRect(x, y, 60, 15); g.fillStyle = '#0f0'; g.font = '12px monospace'; g.fillText(times[k].toFixed(1) + 's', x + 3, y + 12); } return [o.width, o.height]; };
'ready'
