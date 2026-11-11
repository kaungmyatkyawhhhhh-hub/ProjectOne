// Watch a TikTok video INSIDE the built-in browser (no yt-dlp, nothing saved to disk).
// 1. Open the video link in the built-in browser. 2. Run this whole file with the browser's javascript tool.
// 3. Poll window.__R.state until 'done' (about 12 frames/s; 15 fps sampling for videos over 20 s).
// 4. window.__R = {meta, audio, video}. 5. window.__sheet(t0, step, cols, rows) or await window.__big([times], cols) draws frames over the page;
//    take a browser screenshot to look at them. 6. Captions (when TikTok has them): itemStruct.video.subtitleInfos[].Url -> WebVTT.
// Tip: sessionStorage.setItem('__cl', <this source>) once, then after each navigation: (0,eval)(sessionStorage.getItem('__cl')).
window.__R = {state: 'start'};
window.__run = async () => { const R = window.__R; try {
  const el = document.getElementById('__UNIVERSAL_DATA_FOR_REHYDRATION__');
  const it = JSON.parse(el.textContent).__DEFAULT_SCOPE__['webapp.video-detail'].itemInfo.itemStruct;
  R.meta = {url: location.href.split('?')[0], desc: it.desc, create: new Date(it.createTime * 1000).toISOString().slice(0, 10), author: it.author.uniqueId,
    followers: it.authorStats && it.authorStats.followerCount, stats: it.stats,
    music: {title: it.music.title, author: it.music.authorName, original: it.music.original, dur: it.music.duration}, video: [it.video.width, it.video.height, it.video.duration]};
  document.querySelectorAll('video').forEach(v => { try { v.pause(); v.muted = true; } catch (e) {} });
  const r = await fetch(it.video.playAddr, {credentials: 'include'}); const buf = await r.arrayBuffer(); R.bytes = buf.byteLength;
  const blob = new Blob([buf.slice(0)], {type: 'video/mp4'});
  // ---- sound: spectral-flux onsets, tempo guess, band balance, level ----
  const ac = new AudioContext(); const ab = await ac.decodeAudioData(buf); const sr = ab.sampleRate, c0 = ab.getChannelData(0), c1 = ab.numberOfChannels > 1 ? ab.getChannelData(1) : c0, n = c0.length, x = new Float32Array(n);
  for (let i = 0; i < n; i++) x[i] = .5 * (c0[i] + c1[i]);
  const N = 2048, H = 480, win = new Float32Array(N); for (let i = 0; i < N; i++) win[i] = .5 - .5 * Math.cos(2 * Math.PI * i / N);
  const fft = (re, im) => { const n = re.length; for (let i = 1, j = 0; i < n; i++) { let b = n >> 1; for (; j & b; b >>= 1) j ^= b; j ^= b; if (i < j) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
    for (let len = 2; len <= n; len <<= 1) { const a = -2 * Math.PI / len, wr = Math.cos(a), wi = Math.sin(a); for (let i = 0; i < n; i += len) { let cr = 1, ci = 0; for (let k = 0; k < len / 2; k++) { const ur = re[i + k], ui = im[i + k], vr = re[i + k + len / 2] * cr - im[i + k + len / 2] * ci, vi = re[i + k + len / 2] * ci + im[i + k + len / 2] * cr; re[i + k] = ur + vr; im[i + k] = ui + vi; re[i + k + len / 2] = ur - vr; im[i + k + len / 2] = ui - vi; const t = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = t; } } } };
  const F = Math.floor((n - N) / H), flux = new Float32Array(F), rms = new Float32Array(F); let prev = new Float32Array(N / 2); const bands = [0, 0, 0, 0, 0], edges = [60, 250, 2000, 6000, 1e9];
  for (let f = 0; f < F; f++) { const re = new Float32Array(N), im = new Float32Array(N); let s = 0; for (let i = 0; i < N; i++) { const v = x[f * H + i]; re[i] = v * win[i]; s += v * v; } rms[f] = Math.sqrt(s / N); fft(re, im); let fl = 0;
    for (let k = 1; k < N / 2; k++) { const m = Math.hypot(re[k], im[k]), lm = Math.log(1 + 50 * m), d = lm - prev[k]; if (d > 0) fl += d; prev[k] = lm; let b = 0; const fr = k * sr / N; while (fr >= edges[b]) b++; bands[b] += m * m; } flux[f] = fl; }
  const hop = H / sr, on = []; for (let f = 2; f < F - 2; f++) { let mx = 0, mean = 0, c = 0; for (let j = Math.max(0, f - 8); j <= Math.min(F - 1, f + 8); j++) { mean += flux[j]; c++; if (j !== f && flux[j] > mx) mx = flux[j]; } mean /= c; if (flux[f] > mx && flux[f] > mean * 1.5 && flux[f] > 30) on.push(+(f * hop + N / 2 / sr).toFixed(2)); }
  const acr = []; for (let bpm = 70; bpm <= 190; bpm += .5) { const lag = 60 / bpm / hop; let s = 0; for (let f = 0; f < F - lag - 1; f++) { const j = f + lag, j0 = Math.floor(j), w = j - j0; s += flux[f] * (flux[j0] * (1 - w) + flux[j0 + 1] * w); } acr.push([bpm, s / (F - lag)]); } acr.sort((a, b) => b[1] - a[1]);
  const tot = bands.reduce((a, b) => a + b, 0); let ss = 0, pk = 0; for (let i = 0; i < n; i++) { ss += x[i] * x[i]; const a = Math.abs(x[i]); if (a > pk) pk = a; }
  R.audio = {dur: +(n / sr).toFixed(2), onsets: on, tempo: acr.slice(0, 4).map(a => a[0]), bands: bands.map(b => Math.round(100 * b / tot)), rms: +(10 * Math.log10(ss / n)).toFixed(1), peak: +(20 * Math.log10(pk)).toFixed(1)}; R.state = 'audio';
  // ---- picture: step an off-screen copy frame by frame; frame difference -> cuts, motion, stillness ----
  const v = document.createElement('video'); v.muted = true; v.playsInline = true; v.preload = 'auto'; v.src = URL.createObjectURL(blob); await new Promise((res, rej) => { v.onloadeddata = res; v.onerror = () => rej('verr'); }); window.__v2 = v;
  const port = v.videoHeight > v.videoWidth, W = port ? 144 : 256, Hh = port ? 256 : 144, cv = document.createElement('canvas'); cv.width = W; cv.height = Hh; const g = cv.getContext('2d', {willReadFrequently: true});
  const fps = v.duration > 20 ? 15 : 30, nf = Math.floor(v.duration * fps), diff = [], lum = [], frames = []; let pv = null;
  for (let i = 0; i < nf; i++) { v.currentTime = i / fps + .001; await new Promise(res => { v.onseeked = res; }); g.drawImage(v, 0, 0, W, Hh); const d = g.getImageData(0, 0, W, Hh), a = d.data; let s = 0, l = 0; const y = new Uint8Array(W * Hh);
    for (let p = 0, q = 0; p < a.length; p += 4, q++) { const yy = (a[p] * 3 + a[p + 1] * 6 + a[p + 2]) / 10; y[q] = yy; l += yy; if (pv) s += Math.abs(yy - pv[q]); } diff.push(pv ? +(s / (W * Hh)).toFixed(1) : 0); lum.push(Math.round(l / (W * Hh))); pv = y; frames.push(d); R.i = i; }
  const cuts = []; for (let i = 1; i < nf - 1; i++) { const loc = (diff[i - 1] + diff[i + 1]) / 2; if (diff[i] > 16 && diff[i] > 3 * loc + 4) cuts.push(+(i / fps).toFixed(2)); }
  const near = cuts.map(c => { let b = 9; on.forEach(t => { if (Math.abs(t - c) < Math.abs(b)) b = t - c; }); return Math.round(b * 1000); }); const ab2 = near.map(Math.abs).sort((a, b) => a - b);
  let st = 0, ms = 0; for (let i = 1; i < nf; i++) { if (diff[i] < .6) { st++; if (st > ms) ms = st; } else st = 0; }
  window.__vf = {diff, lum, frames, fps, n: nf, W, Hh, port};
  R.video = {dur: +v.duration.toFixed(2), size: [v.videoWidth, v.videoHeight], fps, cuts, cutToOnsetMs: near, medianCutOnsetMs: ab2[Math.floor(ab2.length / 2)], meanDiff: +(diff.reduce((a, b) => a + b, 0) / nf).toFixed(1), lum0: lum[0], maxStill: +(ms / fps).toFixed(2)}; R.state = 'done';
} catch (e) { R.state = 'err'; R.err = String(e && e.stack || e); } };
// contact sheet from the stored small frames (pane is ~618 px wide): returns [w, h]; then take a screenshot
window.__sheet = (t0, step, cols, rows) => { const f = window.__vf; let o = document.getElementById('__ov'); if (!o) { o = document.createElement('canvas'); o.id = '__ov'; o.style.cssText = 'position:fixed;left:0;top:0;z-index:2147483647;background:#222'; document.documentElement.appendChild(o); }
  const cw = Math.floor(618 / cols), ch = Math.round(cw * f.Hh / f.W); o.width = cols * cw; o.height = rows * ch; o.style.width = o.width + 'px'; o.style.height = o.height + 'px'; const g = o.getContext('2d'), tmp = document.createElement('canvas'); tmp.width = f.W; tmp.height = f.Hh; const tg = tmp.getContext('2d');
  for (let k = 0; k < cols * rows; k++) { const t = t0 + k * step, i = Math.round(t * f.fps); if (i >= f.n) break; tg.putImageData(f.frames[i], 0, 0); const x = (k % cols) * cw, y = Math.floor(k / cols) * ch; g.drawImage(tmp, x, y, cw, ch); g.fillStyle = 'rgba(0,0,0,.65)'; g.fillRect(x, y, 40, 14); g.fillStyle = '#0f0'; g.font = '11px monospace'; g.fillText(t.toFixed(2), x + 2, y + 11); } return [o.width, o.height]; };
// a few frames at full sharpness (call __sheet once first so the overlay exists)
window.__big = async (ts, cols) => { const v = window.__v2; let o = document.getElementById('__ov'); const cw = Math.floor(618 / cols), ch = Math.round(cw * v.videoHeight / v.videoWidth), rows = Math.ceil(ts.length / cols); o.width = cols * cw; o.height = rows * ch; o.style.width = o.width + 'px'; o.style.height = o.height + 'px'; const g = o.getContext('2d');
  for (let k = 0; k < ts.length; k++) { v.currentTime = ts[k]; await new Promise(r => { v.onseeked = r; }); g.drawImage(v, (k % cols) * cw, Math.floor(k / cols) * ch, cw, ch); } return [o.width, o.height]; };
window.__run();
