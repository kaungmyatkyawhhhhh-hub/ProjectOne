---
name: "pro-video-editing"
description: "Use for any video Claude edits or builds in code (shop ads, game edits, launch/motion-graphics videos, trend re-edits, collage trend edits). Beat grid first, real assets only (no placeholder UI), layered sound design, measured checks, critique loop."
---

# Pro video editing: edits that feel hand-made, with sound that carries half the weight

The prompt is 10% of the result; this harness is the other 90%. Work through the gates IN ORDER. Each gate exists because skipping it cost a re-render or produced a "placeholder-looking" edit.

Research behind this: vault note `Roblox Playbook\Research notes\2026-11-10 Research - Video editing craft (9 tutorials watched + practice edit).md`. Read it when a rule here is not enough. Also: `2026-11-11 Research - 5 viral TikToks watched (Claude motion design + Roblox) + trending sounds.md` (what small accounts with 70K-300K views did) and `2026-11-11 FlexiToys shop ad - footage edit (cut list, Burmese copy, method).md` (phone-footage method).
For footage-based Roblox game videos and trend re-edits, ALSO follow `roblox-game-video-pipeline` (recording, grading, cleanup, upscaling); this skill adds the craft, sound and QA layers on top.

## 0. Kit (don't rebuild from zero)
`C:\ObsidianOne\Claude+Obsidian\Roblox Playbook\Tools\Video kit\video-kit.zip` -> stage it, unzip into the scratchpad. Contains:
- `score.py` (music + SFX synth, writes `events.json`), `master.sh` (two-pass loudnorm + limiter), `check_audio.py`
- `src/Reel.tsx` + `Root.tsx` (reference Remotion comp), `sheet.sh` (one frame per beat), `finish.sh` (motion blur + mux), `check_video.py`
- `cap/cap.py` + `steps.py` (capture a real site at 1080x1920 with live data)
Same folder: `footage-kit.zip` (phone-footage edits: `shots.json` cut list, `build_shots.py` speed ramps with frame blending, `Ad.tsx` whips/zoom-through/captions, `score_kiosk.py` + `synth.py`; cut to a trending sound: `shots2.json` with the measured `hits`, `Ad2.tsx`, `score2.py`; `facescan.py`; collage trend-edit style, section 5c: `Dg.tsx`, `dg_assets.py`, `dg_photo.py`, `score_dg.py`, `fin.sh`, `dgsheet.sh`, `fonts_dg/`) and `tiktok_watch_in_browser.js` (watch and measure a TikTok in the built-in browser, no download).
Tools: Remotion 4 (`--browser-executable=/opt/pw-browsers/chromium-*/chrome-linux64/chrome`, `--concurrency=2` ALWAYS), ffmpeg, Python: librosa, scipy, soundfile, opencv, playwright. Long jobs -> `run_in_background`; never interrupt a writer.

## 1. Brief (settle everything in the first reply)
Write these before any code. Ask the owner only what is truly unknown (usually nothing; aspect ratio at most).
1. **Film in one line**: what the viewer should FEEL and then DO.
2. Format: 1080x1920, 30 fps, 12-20 s, loops (last frame flows into the first). 2K only if asked.
3. Genre with known rules (launch video, showreel, velocity edit, trend re-edit) AND one style, never a mix: **hype edit** (footage and shop ads: a cut or hit every beat, whips, punches, big captions) or **premium motion design** (product demos and launches: section 5b).
3b. Packaging for TikTok: section 10 (a claim or doubt in second 1, proof, where the screen lives, which sound, a reason to comment).
4. Structure: payoff in second 0-2 -> build -> stop-down -> DROP -> proof beats -> end card + CTA.
5. Language and local trust marks (Myanmar text, Ks prices, KPay/WavePay, flag) when the audience is Myanmar.
6. Facts list with their source (live site, owner's words). No fact without a source goes on screen.

## 2. Real assets only: the anti-placeholder gate (owner rule: AVOID STRICTLY)
Nothing mocked, nothing invented, nothing "representative".
- **Interfaces**: capture the REAL product. For a site: run the real page code locally with Playwright (viewport 360x640, deviceScaleFactor 3 = exactly 1080x1920), feed it the LIVE data (open the site's own `/api/...` in the built-in browser and copy the JSON, or regenerate from the repo), then take full-frame screenshots of each real state and element screenshots (`locator.screenshot`) of real tiles/buttons. Typing = one real screenshot per character. Hide sticky bars before element shots, `caret-color:transparent`.
- **Brand**: read the palette, fonts and background off the live product (screenshot it first). Use its own font files and art. Never assume the brand colours.
- **Copy**: take wording from the live page / the owner's poster. Prices and counts are re-read the same day.
- **Names and numbers**: a real account name, real prices, real results. Never "User123", "John Doe", lorem ipsum, round-number stats, or a "Delivered!" screen the product does not have.
- **If the real thing can't be captured**: leave the scene out or ask the owner for a screenshot/recording. A mock-up is not an acceptable fallback.

BANNED LOOK (two or more together = template/AI look):
purple-to-blue gradient background | glow on everything (glow as ONE light source on a dark base is fine: section 5b) | three equal cards in a row | everything centred with equal spacing | everything inside a bordered, shadowed card | emoji or text glyphs as icons | mixed icon styles | decorative rays, particles, floating shapes with no meaning | one border radius everywhere | every element fading up | default/linear easing | a centred title on a gradient | corner labels and frame borders | extra caption/header/CTA stacks over footage | landscape footage cropped to vertical with blurred bars.
Replace with: the product's own background and art; ONE accent colour (plus one colour reserved for prices); asymmetric layouts (one large + two small, growing sizes, diagonals); real captured elements; motion tied to a beat or a state change.

## 3. Beat grid BEFORE code
- Pick BPM (120 = 0.5 s per beat = 15 frames at 30 fps; easy maths). Pick the bar where the DROP lands.
- Write a table: beat | time | what appears | motion | sound layers. Rules:
  - The payoff is ON FRAME 1 and readable there (it is the cover frame): never a logo, greeting, slow fade, black frame or blurred blob first.
  - Something new every beat or two; nothing static for more than 2 beats; longest gap between visual beats under 2 s.
  - Scenes are NOT equal length; give the reveal room.
  - Before the drop: a riser, a suck-back, and 0.25 s of near-silence (stop-down). The biggest moment lands exactly on the drop.
  - Every scene answers "what should the viewer feel next?". Leave one question open until the end card (what is it? how much? how do I get it?).
- This table becomes `events.json` (t, kind, label). ONE timeline drives both the sound and the picture.

## 4. Sound first (it is half the edit)
Synthesize in code (numpy/scipy, 48 kHz stereo) unless the owner supplies a track. CC0 or own sounds only. Commit to ONE sound family per video.
**Music**: kick, clap on 2 and 4, hats, bass (sidechained to the kick), plucks/chords, a lead. Build section thin (high-passed ~260 Hz), drop full. End on a final hit with a reverb tail, then fade for the loop.
**Every SFX is a layer cake: low + mid + high.**
- impact = sub drop (100->30 Hz sine) + low-passed noise thud + high crack + short reverb
- whoosh = band noise 90-260 Hz + 500-1800 Hz + 3.5-9 kHz under one swell envelope
- riser = rising tone + noise through an opening filter, volume curve t^2
- suck-back = an impact reversed; pop = pitched blip + tick; click = band noise 1.8-6.5 kHz, 30 ms
- confirm = bell (inharmonic partials 1, 2.76, 5.4, 8.9); reward = a spray of small bells
One sound gives three: cut a whoosh at its peak = an impact; reverse it = a riser.
**Placement**: the LOUDEST point of a sound sits on the MOST VIOLENT frame (whoosh peak on the fastest frame, just before landing; impact on the contact frame). Pan follows the on-screen move. Nothing appears on screen without either an animation in or a sound.
**Mix**: give each element its own space.
- Remove the lead/busy parts while UI sounds or a voice play. With a voice-over: cut the music's mids (EQ pocket) instead of only lowering it; voice chain = denoise/gate -> EQ (cut <80 Hz, >12-16 kHz) -> compressor 2:1 -> de-esser -> limiter.
- Duck the music ~4 dB for 0.4 s under big hits. Risers only before a real payoff. High-pass the master at 30 Hz.
- Phone balance target (share of energy): sub <60 Hz at most ~20%, 60-250 Hz ~30%, 250 Hz-2 kHz ~35%, above 2 kHz ~15%. A mix with 75% under 250 Hz disappears on a phone.
**Master**: two-pass `loudnorm` (measure, then `linear=true`) to -14 LUFS, then `alimiter=limit=0.70`. One-pass loudnorm misses the target. AAC encoding ADDS about 1 dB of peak: measure loudness and true peak on the FINAL mp4, not the wav (target -14 +/-0.5 LUFS, true peak <= -1.5 dBFS).
Run `check_audio.py`: every hit event has an audio onset within 40 ms; the stop-down is really silent; no dead air; band balance; loudness.
**Cutting to a trending sound** (all 5 viral references used a trending "original sound", none used custom music): we still ship CC0/own audio only, so 
1. **Which sound**: never answer from chart websites (TokChart, Revid, Metricool, SocialBee, kworb were all wrong for the owner, 11 Nov 2026; TikTok's own Creative Center no longer shows songs). Sample TikTok itself in the BUILT-IN browser: search `edit` (or the niche), open the top ~12 results ONE PAGE AT A TIME about 4 s apart, and read `itemStruct.music` plus the caption (editors credit the real song there; the label is usually just "original sound"). Prefer a sound that shows up in more than one sample; skip titles that suggest swearing for a family shop; the owner's own feed beats any sample, so ask for a link when unsure.
2. **Measure it**: run `tiktok_watch_in_browser.js` (or its audio half) on a video that uses the sound and take the onset times. Do NOT trust the automatic BPM (it ran to its limit twice). Find the repeating pattern by hand (for example the same triple hit every 1.117 s = 2 beats), fit beat length + the drop time, then check every onset against that grid (should be within about 30 ms).
3. **Cut to it**: put the measured `hits` in the cut list. Every cut and every caption WORD lands on a hit; a quiet intro gets slow shots; a fill of quick hits = jump-zooms on one shot; the pickup before the drop = stop-down; the drop = the shop name; triple hits = a 3-step stutter punch.
4. **Deliver TWO files**: sound effects only, quiet (peak about -6 dBFS) so it sits under the trending sound, and our own music synthesized on the SAME grid.
5. **Tell the owner** the exact sound name + creator to add IN THE APP, and which moment to line up ("the drop lands on the shop-name slam at 0:06.1; drag the sound if it doesn't"). Always also offer the SFX-only file: the owner likes to add their own music.

## 5. Picture rules
**Render contract**: every pixel is a pure function of `t = frame / fps`. No CSS transitions, no timers, no state between frames, seeded randomness only (mulberry32). Camera shake is sampled once per OUTPUT frame.
**Motion**
- Springs, closed form, tiny overshoot: `1 - e^(-z w x) (cos(wd x) + (z w / wd) sin(wd x))`, z 0.42-0.62, f 2.6-3.6 Hz. Start a landing ~0.2 s before its beat so it ARRIVES on the beat. No linear moves, no fade-only entrances.
- Anticipation (a small opposite move before a big one), follow-through (settle), secondary motion (coins, sparks, ripples caused BY the main action).
- Impact kit for the drop only: flash 0.8 opacity for 0.16 s, decaying shake, +9% punch zoom, 0.1 s RGB split. Smaller hits get a 5-7% scale punch.
- One hero element never cuts: the logo slams, shrinks to the top, comes back for the end card. Containers morph instead of being replaced.
- Flow: each cut continues the previous movement (same direction, same screen position). The viewer's eye is already where the next subject appears. Plan the transition when choosing the shot. Break continuity on purpose only to jolt.
- Real UI is shown full-bleed with a slow push-in (zoom 1.05-1.1 at most, so no real text is cut off) and a spring pan to the active area. A tap gets a ripple and a click sound.
**Design**: hierarchy (one focal thing per moment), contrast, negative space, repetition. Text: max 3 words per beat, 100 px+ at 1080 wide, one display face + one UI face (the brand's own). Fill the frame; check at phone size.
**Type and finish (owner: "mind the text fonts, colors, style, blurs, opacity, vfx, sfx and every detail")**: never ship the first font that renders.
- **Specimen first**: render every candidate font in the real caption style on a REAL frame of the video (Playwright page with `@font-face` from local files), look, then choose. Do the same for 2-3 style options (fill, outline, depth) before touching the composition.
- **Burmese display fonts** heavy enough for video: Myanmar Kuttar (wide, chunky, rounded), Myanmar Khyay (wide, squarish), Myanmar Yinmar (slab-like), Myanmar Thuriya (condensed), Noto Sans Myanmar Black (neutral). Too thin: Sabae, Pauklay, Gantgaw, Sanpya, Tagu, Padauk. Source: `github.com/khmertype/<Name>` (SIL OFL, commercial use OK); Noto via `@fontsource`. Latin partners by mood: playful/rounded = Titan One, Lilita One, Baloo 2, Fredoka; shouted single words = Anton, Archivo Black; neutral = Montserrat, Poppins. Pair by SHAPE and WEIGHT (Kuttar + Titan One), and check each font's licence.
- **Roles**: one display pair for captions, one lighter UI pair for small lines (product name, address pill, handle); the wordmark stays in the face closest to the real logo.
- **Style that won for a toy shop**: gradient fill (light -> brand colour -> deeper tone) + outline 0.11 em in the brand's dark colour + a short solid extrusion 0.09 em + soft shadow. A white keyline "sticker" goes lumpy around Burmese stacked letters. ONE accent colour on the keyword; the same style all video.
- Wide display faces need 8-15% smaller sizes; re-check the 2-line maximum and the safe zone on stills after ANY font change.
- **Blur**: render footage edits at 120 fps and blend 4 sub-frames too (text pops, whips, punches and rings get real blur; the shots themselves are unchanged). Blur the footage 6-8 px behind an end card as well as tinting it.
- **Opacity**: caption scrim 50% -> 0 over the top third; end-card tint about 40-78%; echo copies start at 55%; colour ghosts 45%.
- **SFX under someone else's song**: NO pitched sounds (no bells, no tonal pops, noise riser only), peak about -6 dBFS; pitched pops only with our own music, in its key.
**Kinetic text (owner: "the texts look too simple and generic")**: one caption style popping in the same way all video is the generic look. Before designing text, re-read the reference notes (`2026-11-11 Research - 5 viral TikToks...`) and use the devices the references use, each tied to a hit (components `Kin`, `Plate`, `Count`, `Typed`, `BrandWord`, `Glyph` in `footage-kit.zip` -> `Ad3.tsx`):
- **Size contrast**: small lead-in words (or a plain label plate) + ONE big keyword at 1.2-1.45x.
- **Word by word**, each word on its own hit; the NEWEST word in the accent colour, turning white when the next lands.
- **Letter cascade**: letters fall in one by one (stagger 0.02 s, rotation, scale); the wordmark falls in along an arc on the end card.
- **A counting number** for a price or stat (0.34 s, ticks, then a landing punch); heavy condensed italic (Anton, skew -8 deg) for the number or claim.
- **A hand-drawn accent** drawn on after the landing (SVG scribble around the price, `stroke-dashoffset`).
- **Label plates** (white rounded plate, dark text, wipe open from the centre) for small lines; **typed text with a cursor** and key clicks for a handle or URL.
- **Light**: a sweep across the keyword after it lands (second background layer on the gradient text), a short glow on the hit.
- Text EXITS too (letters drop and fade with stagger before the cut).
- **Burmese is animated per SYLLABLE, never per character**: `Intl.Segmenter` splits the AA vowel (U+102C) off and the lone mark shows a dotted circle. A consonant starts a new unit unless followed by asat (U+103A), dot-below + asat, or virama (U+1039); marks join the unit before. Print the split for every word before rendering.
- Reserve the space of words that have not landed (render them invisible) so the line does not jump; clamp spring overshoot on big scale slams (3.4x -> 1 dipped to 0.57x).
**Footage edits**: cut on the song's hits (within ~70 ms of an onset; top trend edits do exactly this), speed ramps into the hit, whip/zoom transitions that continue the motion, warm saturated grade, one word per shot in the creator's own style.
Phone footage recipe (`footage-kit.zip`): iPhone clips are 4K60 HEVC **HDR (HLG)**; convert FIRST or they look washed out: `scale=1080:1920:flags=lanczos,zscale=t=linear:npl=203,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p`, 60 fps, `-g 6`. Watch a 6-frame strip per clip. `shots.json` is the cut list; `build_shots.py` maps time with `k*u+(1-k)*(1-(1-u)^p)` (k 0.35, p 2.4: about 2x speed in, 0.35x on the beat) and averages the source frames each output frame covers (real blur), with 0.2 s handles. In Remotion: one `OffthreadVideo` per shot; whip = both shots slide under an SVG `feGaussianBlur stdDeviation="x y"`; zoom-through = scale + blur; shake/flash only on the big hits. Captions: two layers per word (thick outline under, fill over), max two short lines, a soft dark gradient over the caption zone, hook text at most 1.1x on frame 1. Stage 4K clips 3-5 per call (big batches time out).

## 5b. Premium motion-design look (reference: zensu.visuals "Motion Design for Claude", 13 s, 2 cuts)
For product demos and launches. Calm and expensive, not loud.
- **One world, one camera**: lay every scene out in one space and MOVE THE CAMERA between them (down to the prompt, whip back up to the result). 2-3 hard cuts per 15 s at most. Elements morph into the next (wordmark -> buttons) instead of leaving.
- **Light**: black base, ONE blurred coloured light behind the focus, thin outlines with bloom, glass card with a rim light. Changing that one light's colour can BE the payoff (orange -> blue when the result changes).
- **Depth**: a card swings in with 3D tilt and settles; far layers are out of focus; fast moves carry real motion blur; a slow drift during every hold.
- **Close-up, then reveal**: start tight on the detail (the typed words), pull back to show the whole thing.
- **Typing**: word by word, the newest word in the accent colour, then white. End line: letters fall in along an arc with stagger.
- **Cursor**: a real cursor travels to the button; the button flashes on press.
- **Story = cause -> effect, twice**: ask -> result; ask for a change -> the result changes. Show the product being used; never describe it.
- Small calm type, no shake, no sparks, no rings. End: mark + one line, then about 1 s of black.
- With a ready-made sound, read its onsets first and land the moves on them (the reference was loose: median 119 ms; we can be within 40 ms).

## 5c. Collage trend-edit style (owner, 11 Nov 2026: "that video is VERY good"; the default look for shop/product ads)
Reference: the "dolce & gabbana trend" car edit cut to "the kill 2" (4.1M views). Full study + method: vault note `2026-11-11 Research - 5 viral TikToks watched ...`. Working build: `Dg.tsx` in `footage-kit.zip` (FlexiToys ad v3, 12.6 s). Start from it; do not rebuild.
Take the GRAMMAR only. Never the reference's logos, brand names or the song's lyrics. All content is the owner's: products cut out of their own photos/clips, real prices, the real shop, their words, their brand colours in place of the reference's.
This style is the approved exception to the banned look in section 2: glow, sparkles, blossoms and gradients are its grammar. The realness rule still holds in full (no invented product, price, name or screen).

**Format**: 1080x1920 (the reference is 4:3; an ad fills the phone), 11-13 s. Keep words above y = 1600 (the app's caption bar) and off the right-hand buttons.
**Timeline** (beat B from the measured sound; "the kill 2": B = 0.5825 s, first hit 0.086 s, DROP on beat 8 = 4.746 s):
- beat 0: hero product cut-out + caption on paper, readable on frame 1
- beat 1: giant wordmark scene
- beats 2-3: four more products, HALF a beat each
- beat 4: wordmark again with other cut-outs
- beats 5-6: type scene
- beat 7 and 7.5: two colour panels slide over the type scene (the second one carries the real price)
- beat 8 DROP: one collage scene PER BEAT: ribbon -> poster with price -> stamp cards -> "everything else" word scene -> ribbon 2 -> poster 2 -> cards 2 -> "where?" on crumpled paper -> the shop itself as a big stamp card
- last 2.5 s: dark end card: wordmark in light, address, handle typed, call to action

**Intro look (ink on paper)**
- Paper: very pale pink (about RGB 249,224,236), fine grain, a few fibres, vignette to the corners. Generated in `dg_assets.py`. No cloudy mottling.
- Wordmark: heavy geometric sans (League Spartan 900, the free Futura-Bold stand-in), near-black, soft dark halo, thin light edge top-left + dark edge bottom-right (embossed), a light band sweeping across once. Two stacked lines fill a vertical frame.
- Under it: one serif line (Abril Fatface; Noto Serif Myanmar 900 for Burmese) with GLITCH: 3 displaced horizontal slices + 2 hairlines, re-rolled every 2 output frames. Less glitch on Burmese so it stays readable. Small vertical side text.
- Ink: zigzag scribbles in two opposite corners (one firm line + two hair lines, drawn on), long tapered brush blades (filled polygons along a curve), some blurred 1-2 px for depth.
- Cut-outs: soft dark shadow, pop in with a spring and a few degrees of rotation.
- Type scene: one bold line (Montserrat 900 / Noto Sans Myanmar 900) with a heavy soft shadow underneath, syllables sliding in one by one, a coloured underline under one word, two small rounded squares above the first letters, then a smaller coloured slab line (Alfa Slab One) right-aligned.
- Panels: marker letters stacked (Permanent Marker) on the first; thin italic serif (Cormorant Garamond) + line doodles on the second.

**Drop look (collage)**
- Ground: two-colour brand gradient. Everything sits in CSS 3D (`perspective` + `preserve-3d`) and drifts for the whole beat: rotateY about -9 -> +7 deg, small rotateX, push-in 1.02 -> 1.09; layers at different translateZ for parallax.
- Ribbon: a wide diagonal band (38 deg) with the brand name repeated huge in a fat serif, dark, 1.6 px blur, sliding along the band; thin second band; hazard stripe on the bottom edge.
- Products: thick WHITE sticker outline (baked into the PNG: dilate alpha about 17 px per 1000 px) + white glow + drop shadow.
- Light: streaks travelling along curves (animated dash on an SVG path, yellow outer + white core, glow by drop-shadow), four-point sparkles that pulse, a warm light leak in two corners (screen blend), a band of light sweeping across each card/poster 0.1-0.5 s after it lands.
- Foreground: out-of-focus blossoms in two opposite corners (bigger = more blur).
- Poster: brand-colour panel, spaced Didone caps title (Bodoni Moda 900), star watermark turning slowly, product in the middle with light rings, price bar at the bottom (Alfa Slab One, extruded).
- Stamp cards: white card with a perforated coloured edge (radial-gradient dots), a real photo, big label over the photo, small caption strip; four of them tilted in space around a turning cut-out, over the real shop blurred.
- Extruded words: stacked 1 px text-shadows in the dark brand colour + glow.
- Drop kit: white flash, shake, 9% punch; 3.5% punch on every later beat; ONE two-frame negative flash.

**Transitions**
- Paper scenes: cut + zoom punch (1.2 -> 1). Two spins (scale 1.5 + 20 deg). After the drop: whips in changing directions; the incoming scene covers the outgoing one and both travel the same way; the FASTEST frame is on the beat (`whipE`).
- Every moving layer gets a directional blur from its own speed (section 7). Without it the whips show 4 ghost copies.

**Assets**
- Ask for sharp phone PHOTOS of the hero products first: they beat video frames by a wide margin.
- Flat box front shot straight on: 4 corner points -> perspective-rectify -> rounded alpha. 3D box: polygon mask by hand, eroded 3 px. Loose objects: `rembg` (u2net) on a tight crop; look at every result (it fails on wood grain and crowded tables).
- Draw the planned cut lines on the photo and LOOK before cutting.
- Low-res cut-outs stay small on screen; anything shown large or turning must come from a photo.
- Burmese: animate per syllable; put a Latin font after the Burmese one in the family list (`'MM, Mo'`) or "?" and "!" fall back to a default serif; no letter-spacing on Burmese.

**Sound**: `score_dg.py` on the same grid: effects-only file (neutral, peak -6 dBFS) for the trending sound + own-music file. Whooshes peak 85 ms before the beat at gain 0.34 (0.24 when centred) or they hide the scene thud. Price bell half a beat after the poster lands. Riser -> suck-back -> 0.26 s real silence -> drop.

## 5d. Launch-video look: white + one gradient + morphs (owner, 11 Nov 2026: "this edit is insane"; "yes save it in ur skill")
Reference: the "holo" launch video (tiktok.com/@alianimator6/video/7699900793071127828; 44.7 s landscape, 96K views, saves over half the likes). Full study: vault note `2026-11-11 Watch study - holo launch video (white + one gradient, morph transitions)`. Not built by us yet: write down what was learned in that note after the first build.
Grammar only: never the reference's name, logo, mascot or wording. The owner's own product, screens and words.

**Use it for**: a website or app (Stud Shop, Flash TopUp), a game's page video, anything that should feel clean and expensive. Use 5c (collage) for toys, games and the TikTok feed. Never mix the two in one film.
**Format**: 30-45 s with its own sound; 16:9 for a page/site video, 9:16 with the same layouts stacked for TikTok.

**Measured on the reference**
- 5.3 sound hits per second: a small tick on almost every word, card and shape.
- Only 5 hard cuts in 44.7 s, each within 60 ms of a sound hit. Everything else is a morph or a move.
- Something new about every 1.2 s; motion in every half second; the end card holds still for 3.2 s.
- Level about -15 dBFS RMS, peak -1 dBFS.

**Look**
- White ground, black type, ONE gradient (the brand's own colours, 3-4 stops) used as a MATERIAL: it fills giant letters, a soft blob with vertical glass ribs behind white text, a sphere, chart bars and the edges of cards. No second accent colour, no glow, no particles.
- One clean grotesque, 2-3 words per beat, centred and big. Giant single words ("You", "Now") filled with the gradient as punctuation between sections. Inactive list words in light grey.
- Mostly empty screen: one focal thing at a time.

**Structure (map the product onto it)**
1. 0-8 s, the viewer's situation in 4-5 short lines, one line per beat (who you are / what you have / what is missing).
2. A giant "Now"-type word, then a wide picture of the promise (the reference: a gradient globe with city pins popping on).
3. "Meet" + the real logo, black on white (hard cut 1).
4. The first real action: a search bar or input where the real value is typed (hard cut 2).
5. ONE surprise at about the one-third mark, when attention drops (the reference: a 3D mascot flies off with the input). Ours: only with a real asset (a Blender render from the owner's PC, or the product's own art); otherwise a bold morph, never a stock mascot.
6. Feature list: 3-4 words stacked on the left, the active one black with a dot, the rest grey; on the right ONE rounded card with a gradient edge showing the REAL output for that word; about 1.4 s per word.
7. A toggle or switch moment ("on"), then what it does while you are away (a scrolling task list with one line highlighted).
8. Results: the real outputs in a grid, then flying out.
9. Proof: a title or claim one word at a time, then a counter ticking up over rising gradient bars. Real numbers only (section 2); no number without a source means no counter.
10. End card: the address, black on white, still for 3 s.

**Motion**
- Morph chain: each shape becomes the next (blob -> pill -> pixels; pill -> search bar -> toggle; tiles collapse into the next word). Plan the chain in the beat table: write "becomes" between scenes, not "cut".
- Save hard cuts for at most one per 8 s, on the biggest changes, each on a sound hit.
- Springs with small overshoot for pops; slow push-in on every held frame; text enters by word.

**Sound**: one family of small ticks, pops and soft whooshes (section 4 recipes), one per element, 5 per second; a soft pad or simple beat underneath; one bigger hit on each hard cut; duck the bed under the proof counter.

**Checks on top of section 6**: count hard cuts (<= 1 per 8 s); every list word has a real output card; exactly one gradient; longest stretch without a new element <= 1.5 s before the end card.

## 6. Critique loop (before any full render)
1. `sheet.sh`: render ONE FRAME PER BEAT (stills one at a time, `--scale=0.25`) into a contact sheet and LOOK at it.
2. Score 1-10: hook in the first 2 s | readability at phone size | motion quality | variety | brand accuracy | sound sync | **realness (no placeholder, no template tells)**.
3. Fix the 3 worst. Repeat until every score is 8+. Realness must be 10: any mocked interface, invented name or banned-look item fails the round.
4. Only then the full render.

## 7. Render, finish, verify
- Motion blur: render at 120 fps, blend 4 sub-frames per output frame:
  `ffmpeg -i r120.mp4 -i mix.wav -filter_complex "[0:v]tmix=frames=4:weights='1 1 1 1',select='not(mod(n-3\,4))',setpts=N/30/TB[v]" -map "[v]" -map 1:a -r 30 -c:v libx264 -crf 15 -pix_fmt yuv420p -c:a aac -b:a 256k -movflags +faststart out.mp4` (about 7 min for 13 s on 2 CPUs; 3 sub-frames at 90 fps shows ghosting).
- **Fast moves need directional blur too**: when a layer travels over about 40 px per sub-frame (whips, big zooms, a word slamming in from 2.6x), the 4 blended samples show as 4 ghost copies. Give that layer an SVG filter `feGaussianBlur stdDeviation="sx sy"` with sx, sy = half the distance it moves per sub-frame (measure from the transform at t +/- 1/240 s), plus a small all-direction amount for scale and rotation. Check 3-4 sub-frame stills of a whip before the full render.
- **Finish pass** (collage style, after the blend, in the same ffmpeg call): `format=gbrp,split[a][b];[b]curves=all='0/0 0.78/0 1/1',gblur=sigma=24[bl];[a][bl]blend=all_mode=screen:all_opacity=0.6,eq=contrast=1.05:saturation=1.12,unsharp=5:5:0.4,noise=alls=4:allf=t,format=yuv420p`. Bloom from highlights only; blooming the whole picture washes pale paper to white.
- **Use `fin.sh`** (footage-kit): renders the 120 fps comp in 3 chunks with `--timeout=120000`, retries a failed chunk, `KEEP="0 1"` reuses finished chunks when only a later part changed, then blend + finish + both sound versions + all checks. Heavy scenes (3D + blur + blend layers) take about 3 s per sub-frame: plan 30-45 min for 13 s. Run ONE heavy job at a time (a background-removal job next to a render got the render killed for memory). Never edit a script while it is running.
- **AAC overshoot**: bright clicks sitting on the limiter ceiling can come out 2-4 dB hotter after encoding (-2.5 dBFS wav -> +1.3 dBFS mp4). Mux the music version through `volume=1.1dB,alimiter=limit=0.52` and lower the limit until the FINAL mp4 measures <= -1.5 dBFS.
- **Delivery size**: grain makes crf 15 huge (100 MB for 13 s). Re-encode the delivery copy once at `-preset slow -crf 20` (about 20 MB) and copy the audio.
- `check_video.py` on the FINAL file: frame 1 is bright (the payoff), every hit event shows a visible change, no stretch without motion over 1 s.
- `check_audio.py` on the FINAL file.
- Pull 12-16 frames from the final file into a sheet and look once more (wrong end states, clipped text, leftovers).
- **Faces**: when the owner says no faces (or "not the main character's face"), run `facescan.py` (OpenCV YuNet) on every candidate clip BEFORE choosing shots, drop or crop the ones with faces (hands and products only; start a shot later to skip a bystander), then scan EVERY frame of the final file and report the count. Printed characters on boxes and shop mannequins also trigger it: look at each hit.
- Deliver: SendUserFile, then device_commit_files with the fileUuid into Downloads. Report the measured numbers, and anything that is still a compromise. Never publish or post without the owner's OK.

## 8. Studying a reference ("make it like this")
- Watch it: `ytdlp-video-watch`. For TikTok the fastest route needs no download: open the link in the built-in browser and run `tiktok_watch_in_browser.js` (stats, sound name, onsets, tempo, cuts, cut-to-onset distance, contact sheets; TikTok's own captions when present). YouTube without yt-dlp: transcript panel + seeking + screenshots.
- Measure it when the file is available: cuts (frame difference), audio onsets and tempo (librosa), cut-to-onset distance, shot lengths, LUFS.
- Write a style guide: palette, type, shot lengths, transition types, camera moves, texture, how text enters and exits, sound family. Take the GRAMMAR of the reference, never its content, logos or characters.

## 9. Lessons that cost time (don't repeat)
- A mocked order form with a made-up user name, three equal cards and a purple gradient: rejected as placeholder-looking. The real site was black studs + green + gold. Capture first, design second.
- `loudnorm` in one pass: -12.9 instead of -14. AAC pushed the peak from -1.7 to 0.0 dBFS.
- 76% of the mix under 250 Hz: clicks and plucks vanished. Rebalance, then re-check.
- Random shake per sub-frame smeared every still object. Zoom 1.2+ on a real screen cut the text off. A hero that starts at 2.3x scale makes frame 1 a blur.
- Parallel `remotion still` runs clash; `--concurrency=4` crashes silently on this box.
- A failed render leaves the OLD output in place and the checks then pass on the old file. Move the previous final away before rendering, make scripts `set -euo pipefail`, test ONE still after every code edit, and read the render output for `Error` before trusting any check.
- Scripted text edits: never append a `//` comment inside a one-line statement (it comments out the rest of the line).
- Three-line captions and a hook word that slams in at 2x both ended up cropped or crowded on the cover frame.
- A whoosh peaking exactly on the cut hid the word-pop on the same beat: peak it 40 ms early and a little quieter (in a quiet intro: 90 ms early, gain 0.35).
- 80+ background fetches from inside a logged-in TikTok page in the owner's Chrome got that Chrome session "Access Denied". Never bulk-fetch TikTok and never try to get around a block (no incognito trick). One page at a time, in the built-in browser.
- Trending-sound lists from chart websites were wrong; the owner corrected them ("my feed is like christmas music"). Sample TikTok itself, and treat the owner's feed as the source of truth.
- A layer pushed back with translateZ vanished: it sat behind a background plane that had no Z. Give the background a larger negative Z.
- Zoom transitions that SHRINK the outgoing scene show its edge as a frame inside the frame. Scale the outgoing scene up, never down.
- A caption placed over a product, and words below y = 1600, both had to be moved after the first preview. Lay out with the app's bars in mind.
- Preview cheaply first: one 30 fps render at `--scale=0.4` (about 70 s) + `dgsheet.sh` to tile any frames; full 120 fps only when the sheet is clean.
- A destructive shell line (`rm` with a wildcard) inside a long command got the WHOLE command refused, so nothing ran. Write test stills into a new folder instead of clearing an old one.

## 10. Packaging for TikTok (from 5 viral references, small accounts, 70K-300K views each, Nov 2026)
Polish did not rank them: the rawest one had the most views. The idea and the proof did.
1. **Second 1 = a claim or a doubt the viewer already has**, on screen in plain TikTok-style text: "This took Claude just 30 minutes", a quote like "claude isn't good at making models", "everyone asks X. Wrong question", a number counting up. Never only a logo.
2. **Then proof, shown**: the product being used, a real chart, the real result on a real screen. Doubt -> proof on the first strong hit of the sound (reference: cut at 2.87 s, 0 ms from the hit).
3. **Put the screen in the real world** when it fits (3 of 5 did): a phone filming the monitor, a laptop on a desk, a monitor in a dark room with a lamp in the brand colour, plus one plain caption. It reads as a person, not an ad. Ask the owner to film it; never fake the room.
4. **10-16 s** for everything except voice-over tutorials.
5. **A trending original sound** added in the app (section 4), cuts on its hits.
6. **A reason to comment**: "comment 'word' and I'll DM it" (493 and 1,454 comments in the references) or a real question as the caption. Only promise what the owner will actually send.
7. One claim per beat; a character or mascot helps (the highest like rate had one); real data beats adjectives.
8. Iterate like a director: expect about six versions; notes are small and concrete ("fix this transition, lower that whoosh, hold the ending one beat longer"). The skill does about 75%; the owner's idea, taste and notes are the rest, so send drafts early.