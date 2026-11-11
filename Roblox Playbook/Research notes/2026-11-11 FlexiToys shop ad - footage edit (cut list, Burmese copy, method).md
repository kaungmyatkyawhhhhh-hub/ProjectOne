---
date: 2026-11-11
tags: [video, flexitoys, shop-ad, footage-edit, burmese, research]
---
# FlexiToys shop ad: footage edit from the owner's 28 phone clips (11 Nov 2026)

Owner: "edit with the clips in here ... its my kiosk ad" + "burmese people dont know what a kiosk is, so write in burmese."
Result: `Downloads\FlexiToys - shop ad (22s, with music).mp4` and `...(22s, sound effects only).mp4` (1080x1920, 30 fps, 22 s). Nothing posted.
Skill used: `pro-video-editing`. Related note: [[2026-11-10 Research - Video editing craft (9 tutorials watched + practice edit)]].

## Research used (local shop short-video ads)
- TikTok video advertising guide (ads.tiktok.com/business/en/guides/video-advertising-guide): hook in the first 3 s, product in use within 2 s; 21-34 s performs best; cuts synced to the beat; text inside the safe zones; price/offer on the final frame; CTA as the obvious next step; refresh creatives every 2-4 weeks.
- Humble Help, TikTok for local marketing (humblehelp.studio/blog/ultimate-guide-to-tiktok-for-local-marketing): show the storefront and the team; about 30 s; phone-shot look beats studio look; location tag + city hashtags on every post; CTA "visit us".

## Facts on screen and where each came from
- Shop name FlexiToys, TikTok @flexitoysmm: read off the shop's own sign card in IMG_0155 (purple card, "FlexiToys | MM").
- Brand colours purple + yellow: same card.
- Blox Fruits Blind Box 29,500 Ks: price tag in IMG_0141. (Minecraft Blind Box tag in IMG_0138 says 19,500 Ks; not put in text.)
- Junction Centre, Nay Pyi Taw: the mall banner in the footage + owner's words.
- Building sets are the new products this autumn: owner's words (Oct 2026).
- NOT stated because unknown: floor / exact spot in the mall, opening hours, any discount. The "Spring Sale" boards are the mall's signage, so the text never claims a sale.

## Burmese copy (no "kiosk": the shop is "အရုပ်ဆိုင်" = toy shop)
ဘာထွက်မလဲ? | Blind Box ရောက်ပြီ! | 29,500 Ks | Minecraft + Roblox လည်း ရှိတယ် | FlexiToys အရုပ်ဆိုင် | Blind Box အစုံ | အသစ်တွေ ရောက်ပြီ! | ကိုယ်တိုင် ဆက်ကြမယ် | Keychain တွေလည်း ရှိတယ် | ကြိုဆိုပါတယ်! | ဘယ်မှာလဲ? | Junction Centre နေပြည်တော် | end card: FlexiToys အရုပ်ဆိုင် / Junction Centre · နေပြည်တော် / TikTok @flexitoysmm / ဒီနေ့ပဲ လာခဲ့နော်!
Owner should proofread the Burmese once (written by Claude, not checked by a native speaker).

## Cut list (120 BPM, 1 beat = 0.5 s)
| Time | Clip | Shot | Into it |
|---|---|---|---|
| 0.0 | 0117 | Blox Fruits box in hand (hook) | impact |
| 1.0 | 0143 | staff pointing at the box | whip left |
| 2.0 | 0141 | boxes + 29,500 Ks tag | punch |
| 3.0 | 0138 | Minecraft + Roblox boxes, then stop-down | whip up |
| 4.0 | 0131 | DROP: orbit of the counter, shop name | flash + shake |
| 5.5-8.0 | 0120, 0150, 0128, 0146, 0163 | five half-second product shots | punch / whip |
| 8.0 | 0118 | staff with the Technic car set | whip up |
| 9.0 | 0126 | hands building | punch |
| 10.0 | 0147 | mini cars on the counter | whip right |
| 11.0 | 0142 | keychains | punch |
| 12.0 | 0113 | staff dance move | whip left |
| 13.0 | 0116 | three staff | punch |
| 14.0 | 0151 | walk through the mall to the shop (3x speed) | zoom-through |
| 16.0 | 0135 | ARRIVE: the shop, wide | flash + shake |
| 18.0-22.0 | 0144 | end card over the shop front | impact |
Unused: 0112, 0115, 0127, 0130, 0149, 0152, 0155, 0157, 0164 (spare shots for a second version).

## Method that worked (footage edit in code)
1. iPhone clips are 4K 60 fps HEVC **HDR (HLG)** and rotated. Convert first or everything looks washed out:
   `scale=1080:1920:flags=lanczos,zscale=t=linear:npl=203,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p` at 60 fps, crf 14, `-g 6`. About 12 min for 97 s of footage.
2. Watch: a 6-frame strip per clip, stacked 7 clips per sheet (4 sheets for 28 clips), then 10-frame strips of the chosen ones.
3. `shots.json` = the cut list (start, length, clip, source window, transition in). One file drives the shot builder, the picture and the sound times.
4. `build_shots.py`: per shot, map output time to source time with an eased curve (`k*u + (1-k)*(1-(1-u)^p)`, k 0.35, p 2.4 = about 2x speed at the start, 0.35x at the end, so each shot lands slow on its beat) and AVERAGE the 60 fps source frames each output frame covers (real motion blur on the fast part). 0.2 s handles before and after for transitions.
5. Remotion: one `OffthreadVideo` per shot inside a `Sequence`; whip = both shots slide with an SVG `feGaussianBlur stdDeviation="x y"` (directional blur); zoom-through = scale + blur; punch zoom on hard cuts; shake, flash and colour ghosts only on the 5 big hits; captions = two layers per word (thick outline under, fill over), words pop one by one, echo, bounce on the beat.
6. Sound: `score_kiosk.py` (C major, bright plucks; breakdown + riser during the walk; stop-downs before 4.0 and 16.0) + SFX on every cut. A second file with SFX only for the owner's own music.
7. Checks on the final file: 31/31 sound hits within 40 ms, every hit has a visible change, longest still stretch 0.03 s, -14.6 LUFS, true peak -1.9 dBFS.

## Lessons
- A caption that slams in at 2x on frame 1 is cropped on the cover frame; the hook text starts at 1.1x at most.
- Three-line captions crowd the frame; two short lines maximum, about 100-130 px.
- A soft dark gradient over the top third keeps upper-third captions readable on busy shop backgrounds.
- Whoosh peak 40 ms before the cut and a little quieter, or it hides the word-pop on the same beat.
- Device file staging times out on big batches: stage 4K clips 3-5 at a time.
