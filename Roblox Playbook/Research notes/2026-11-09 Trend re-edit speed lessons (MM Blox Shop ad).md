---
date: 2026-11-09
tags: [video, remotion, speed, trend-edit, mm-blox-shop]
---
# Trend re-edit: speed lessons (MM Blox Shop color-wheel ad, 9 Nov 2026)

Final file: `Downloads\MM Blox Shop - avatar glow up ad (3x4 2K).mp4` (1440x1920, 16 s). Owner: "these are good" but took ~5 h. Skill `roblox-game-video-pipeline` updated with these rules.

## What wasted time
- Spec discovered by re-rendering: 16:9 box → full 9:16 → wider with bars → 3:4 full-bleed with text inside. Settle aspect + "text on the video" + local language + 2K in the first reply.
- `--concurrency=4` crashed silently → an OLD file was sent. Always `--concurrency=2`, check duration/mtime, look at frames from the final file.
- Parallel `remotion still` runs clash.
- Interrupted cleanup left a truncated clean.mp4 (8 s of 16 s).
- Wrong text style twice (Lilita, then Cinzel, then a 3D extrusion). Study the creator's lettering close-up first: it was a Didone serif (Playfair Display 700), scene-tinted, screen blend, soft glow, raindrop speckles.
- Extra captions/header/CTA over the trend = "slop". One word per shot.

## Fixed order
clean source (OpenCV inpaint) → AI upscale (Real-ESRGAN animevideov3, 960w x4 → 2880, ~50 min on 2 CPUs; run on the RTX 4060 if possible) → layout → one preview sheet → one final render → loudnorm -14.

## Defaults for Myanmar shop ads
Full-bleed, text on the video with soft shading, Myanmar flag + shop name top, headline in Burmese, price in ကျပ် + KPay/WavePay bottom (kept above TikTok's caption zone), intro/outro reuse the trend's own card footage.
