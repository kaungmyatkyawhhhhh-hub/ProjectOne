# UI Motion, Juice, UI VFX and UI SFX for Roblox (TweenService) — Motion Bible

Scope note: researched 11 Nov 2026. Primary sources found were thin on *published exact numbers* from Supercell / BIG Games / Tap Simulator; most hard numbers come from platform motion systems (Microsoft Fluent, web.dev, Val Head), DevForum implementations, and a Zynga postmortem (Empires & Allies). Everything that is my synthesis is marked under Inferences. Numbers from my prior training knowledge (not verified this session) are explicitly flagged "(unverified, prior knowledge)".

## 1. Exact timings/easings polished games use per UI event

### Takeaway
No studio (Supercell, BIG Games, Tap Sim devs) publishes its timing tables; the defensible baseline is: feedback under ~100 ms, most UI transitions 150–300 ms, big/travelling motion 400–500 ms, bounce/elastic settles 800–1200 ms; enter = decelerate (ease-out), exit = accelerate (ease-in) and shorter. Reward flows layer staggered pieces (burst 0.5 s Quad Out, wait ~0.25 s, fly 0.8 s Quad In, counter bump ~0.1 s up / 0.15 s Back down; HUD icon pulse ~30% over ~0.25 s).

### Cited Findings
- Microsoft Fluent/WinUI standard durations: Normal 250 ms, Fast 167 ms, Faster 83 ms. — [Microsoft Learn: Timing and easing](https://learn.microsoft.com/en-us/windows/apps/design/motion/timing-and-easing)
- Fluent easing: entering UI uses "Fast Out, Slow In" decelerate `cubic-bezier(0,0,0,1)`; exiting UI uses "Slow Out, Fast In" accelerate `cubic-bezier(1,0,1,1)`. Entering objects decelerate to rest (feels responsive even after a delay); exiting objects build momentum to clear the way. — [Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/design/motion/timing-and-easing)
- General UI range 200–500 ms: small elements/small changes ~200–300 ms; large motion covering a lot of ground ~400–500 ms; complex bounce/elastic at the high end. Reasoning: <100 ms feels instant (Nielsen Norman); ~1 s is the limit of flow of thought, halved to 500 ms; visual perception ~230 ms so ~200 ms animations are perceived, much shorter may go unnoticed. — [Val Head: How fast should your UI animations be?](https://valhead.com/?p=2978)
- Ease-out is the default for UI ("quick to start", feels responsive); quintic ease-out recommended as "a very nice, albeit quick, ease"; ease-ins "jolt at the end"; ease-out/in ~200–500 ms; bounce/elastic ~800–1200 ms so it can settle; bounce only for lighthearted projects. — [web.dev: Choosing the right easing](https://web.dev/articles/choosing-the-right-easing)
- Coin-fly to counter (Roblox DevForum implementation): random burst count `math.random(5,15)`, burst outward to random point near screen centre with 0.5 s Quad/Out while growing, stagger wait 0.25 s (+ randomness), then fly to counter 0.8 s Quad/In (accelerates into target), destroy on Completed, counter "bounces when the coin image labels touch it"; example bump 0.1 s up (+8 px) then 0.15 s Back back to base. — [DevForum: How would I make an animation UI for coins?](https://devforum.roblox.com/t/how-to-make-this-coin-ui-animation/1812608)
- Zynga Empires & Allies reward flow: rewards appear with a slight delay between each; each plays a sound on appearing, arcs up and out, squashes on landing, emits short-lived particles; on click, particles + sound, reward flies to its HUD meter while floating text ("+288 coins") rises and fades in the meter's colour; status text rises ~1 s then fades. — [Game Developer: Clicking and Rewards in Empires & Allies](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Same source: HUD icon pulses ~30% larger over ~0.25 s when the reward arrives; uncollected rewards pulse once slowly at 7 s then four times quickly over the next second before auto-flying (with no sound/particles, so missing a reward gives no positive feedback — a deliberate contrast). — [Game Developer](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Same source, idle: building icons bob up and down non-linearly with randomly staggered start times. — [Game Developer](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Combo meter: each successive fill plays a higher-pitched sound to build tension; after 2 s idle the meter flashes red, ~2 s later expires with a reward sound and "Bonus: 480 Coins!" scales up and stays ~3 s. — [Game Developer](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Shine sweep on Roblox: tween only `UIGradient.Offset` from `Vector2.new(-1,0)` to `Vector2.new(1,0)`, 1 s, `Circular`/`Out`, gradient Rotation set ~45°, ColorSequence = base colour → lighter band → base colour; 2 sweeps then 2.5 s pause. — [DevForum: 4 UIGradient Animations](https://devforum.roblox.com/t/4-uigradient-animations-including-rainbow/557922)
- Brawl Stars Starr Drops: start at "Rare" and visibly "upgrade" through rarities in a dramatic animation; rarity is fixed when awarded, not when tapped; odds ~50% Rare / 28% Super Rare / 15% Epic / 5% Mythic / 2% Legendary; near-miss to Legendary drove replay. — [Mechanics of Magic: How Brawl Stars Rebuilt Chance](https://mechanicsofmagic.com/2026/05/22/how-brawl-stars-rebuilt-chance-after-swearing-it-off/)
- Loot box reveal advice (Roblox devs): more build-up before opening; camera orbit / faster push-in; box punched from inside, inflate-and-burst, lid lifts with light spilling out, drop-and-slam with bounce; vary the animation per opening; more drama per higher rarity; rarity-coloured particles; "tasteful" particles. No timings given. — [DevForum: What makes a good loot box opening animation?](https://devforum.roblox.com/t/what-makes-a-good-loot-box-opening-animation/1999029)

### Inferences
Synthesis: a timing table mapped to Roblox `TweenInfo`. Treat it as a starting point, then tune by eye on a phone.

| Event | Duration | Roblox EasingStyle / Direction | Notes |
|---|---|---|---|
| Button hover (PC) | 0.12–0.15 s | Quad Out | UIScale 1 → 1.06; slight brightness/stroke up |
| Button press (down) | 0.06–0.08 s | Quad Out | UIScale → 0.92 (squash). Must start within 1 frame of input (<100 ms rule) |
| Button release | 0.18–0.25 s | Back Out | UIScale → 1.0 (or hover 1.06). Back gives a small overshoot |
| Window open | 0.25–0.35 s | Back Out (scale 0.85 → 1) + Quad Out (fade) | Fade can run ~60% of the scale duration |
| Window close | 0.15–0.2 s | Quad In / Back In | Exit ≈ 60–70% of enter time (Fluent accelerate-out rule) |
| Tab switch | 0.15–0.25 s | Quint/Quad Out | Underline/indicator slides; content cross-fades and shifts 8–16 px |
| List/grid stagger | per item 0.2–0.3 s, offset 0.03–0.06 s | Back Out or Quad Out | Cap total stagger ~0.4–0.5 s; beyond ~10 items, animate the first rows only |
| Number count-up | 0.4–1.0 s (scale with size of gain) | Quad/Quint Out (drive a NumberValue) | Tick SFX every N steps; small bump on finish |
| Currency fly-to-counter | burst 0.4–0.5 s Quad Out, stagger 0.02–0.05 s/coin, fly 0.5–0.8 s Quad In | per DevForum | Counter bump +10–30% over ~0.1 s, then 0.15–0.25 s Back Out settle |
| Notification toast | in 0.25–0.3 s Back Out (slide from edge), hold 2–3 s, out 0.2 s Quad In | | Empires & Allies held bonus text ~3 s |
| Progress bar fill | 0.3–0.6 s | Quad/Quint Out | Use a "ghost" trailing bar (delay 0.1–0.2 s) for a damage/gain read; flash at 100% |
| Reward reveal | anticipation 0.4–1.0 s (shake/grow), burst 0.1 s, settle 0.3–0.5 s Back/Elastic Out | | Higher rarity = longer build-up + more layers; always allow tap-to-skip |
| Level up | 1.5–2.5 s total sequence | Back/Elastic Out for the badge | Flash frame, scale punch 0 → 1.2 → 1, number roll, confetti |
| Unlock | 0.6–1.0 s | | Lock shake 0.2 s → lock pops/falls away (Quad In) → item scale-punch + shine sweep |
| Rarity reveal (multi-step) | 0.4–0.6 s per tier step | | Brawl Stars-style "upgrade" steps; each step raises pitch + colour; pause before the final tier |
| Idle breathing | 1.5–3 s per cycle | Sine InOut, reverses, repeat -1 | Scale 1 → 1.03–1.05 or ±2–4 px bob; randomise phase per element |
| Idle shine | sweep 0.6–1.0 s, pause 2–5 s | Circular/Quad Out on UIGradient.Offset | Per DevForum: 1 s Circular Out, 2.5 s pause |

- Material 3 values (unverified, prior knowledge; could not be fetched this session): standard easing `cubic-bezier(0.2,0,0,1)`; emphasized decelerate `(0.05,0.7,0.1,1)`; emphasized accelerate `(0.3,0,0.8,0.15)`; duration tokens short1–4 = 50/100/150/200 ms, medium1–4 = 250/300/350/400 ms, long1–4 = 450/500/550/600 ms, extra-long up to 1000 ms. (Short1 = 50 ms and ExtraLong4 = 1000 ms were confirmed by [skill-wiki M3 tokens](https://skill-wiki.github.io/atom/android-compose/rule-motion-easing-tokens).)
- Roblox TweenService has no cubic-bezier. Rough mapping: Fluent decelerate / M3 emphasized decelerate ≈ Quint or Exponential Out; standard ≈ Quad/Cubic Out; exit ≈ Quad/Cubic In; overshoot ≈ Back Out (default overshoot ~10%); wobble ≈ Elastic Out (use sparingly, ≥0.6 s).
- For ViewportFrame/rare-reveal sequences, a "dramatic pause" (0.2–0.4 s of near-stillness) before the final payoff makes the payoff read bigger (classic animation anticipation; matches the "more build-up" DevForum advice).

### Gaps
- No primary source found publishing Supercell, BIG Games (Pet Simulator 99) or Tap Simulator REBORN timing values; frame-by-frame measurement of their videos (ytdlp-video-watch skill) would be needed.
- Material 3 Expressive spring constants were not confirmed this session.

## 2. Principles: anticipation, squash and stretch, overshoot, follow-through, staggering, easing, springs

### Takeaway
Juice = non-essential visual/audio/haptic feedback that amplifies a response. Core moves: anticipate (wind-up), squash on contact, overshoot then settle, follow-through/secondary motion, stagger groups, ease everything, and stop adding once the interaction communicates enough. Springs (spr) give the overshoot/settle for free and stay interruptible.

### Cited Findings
- Juice definition: "the non-essential visual, audio & haptic effects that enhance the player's experience." — [DEV: Juice (Brad Woods)](https://dev.to/bradwoods/juice-1bbl)
- "Juice It or Lose It" (Martin Jonasson & Petri Purho, GDC Europe 2012) is the canonical talk. — [GDC Vault](https://gdcvault.com/play/1016789/Juice-It-or-Lose)
- Vlambeer "Art of Screenshake" effect list (recreation): lower time-to-kill, higher fire rate, bigger bullets, muzzle flash, faster bullets, lower accuracy, impact effect, hit reaction, enemy knockback, permanence, camera lerp, screenshake, player knockback, hit pause, weapon recoil, random enemy explosion. No numbers published. — [Art of Screenshake recreation devlog](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects)
- Nijman: screen shakes slightly opposite the direction of gunfire; enemies have a 33% chance of exploding harmlessly on death (randomised extra payoff); talk demonstrates 30 small tweaks. — [Game Developer: Vlambeer co-founder advice](https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)
- Screenshake implementation: store a 2D offset, set it to a nudge like (+10, 0) (bigger events = bigger magnitude), ease back to (0,0) with out-cubic or out-elastic. Collision gets a "very slight upward push" so momentum seems to go somewhere; particles emitted proportional to speed. — [Practical Juicing for Game Devs (dvdfu)](https://medium.com/@dvdfu/practical-juicing-for-game-devs-efe9b06c246b)
- Over-juicing warning: "It's easy to go overboard"; chromatic aberration/lens flare become "a gaudy mess"; stop once the interaction communicates enough and fits the style; "Perfection is achieved... when there is nothing left to take away." — [dvdfu](https://medium.com/@dvdfu/practical-juicing-for-game-devs-efe9b06c246b)
- spr (Roblox spring library): `spr.target(object, dampingRatio, frequency, properties)`; damping <1 overshoots/wobbles, =1 critically damped, >1 overdamped; frequency = speed. Examples: smooth (1, 0.5), quick wobble (0.6, 4), moderate bounce (0.6, 1). Critical damping is the neutral default, underdamping to "pop". Supports UDim2, Color3, CFrame, ColorSequence, booleans, Model Pivot/Scale; NumberSequence not supported. Analytical solver; Driving Simulator uses it for 500+ animations; `spr.stop`, `spr.completed`. — [DevForum: spr](https://devforum.roblox.com/t/spring-driven-motion-spr/714728)
- Other Roblox libraries exist: roact-spring, Physics Based Spring Module v2, UIFX animation module, Shime (shine module). — [roact-spring](https://devforum.roblox.com/t/bring-ui-animations-to-life-with-roact-spring-a-modern-spring-based-animation-library/1670138); [Spring Module V2](https://devforum.roblox.com/t/physics-based-spring-module/1287742); [UIFX](https://devforum.roblox.com/t/uifx-animation-module/3295824); [Shime on GitHub](https://github.com/ryanlua/Shime)

### Inferences
- Button recipe (squash and stretch + overshoot): press = UIScale 0.92 over 0.07 s; release = spring (damping 0.5–0.6, frequency 4–5) back to 1.0, or Back Out 0.2 s. Optional: non-uniform squash (X 1.05, Y 0.92) by tweening Size of an inner frame, since UIScale is uniform.
- Use UIScale (not Size) for punches so layout and children scale together without reflowing UIListLayouts; keep Size for real layout changes.
- Prefer springs for anything that can be interrupted (hover in/out spam, toggles): a tween restarted mid-flight snaps its curve, a spring keeps velocity.
- Stagger: delay 0.03–0.06 s per item reads as "a cascade"; >0.1 s reads as slow. Stagger in reading order (top-left → bottom-right) or radially from the tapped point.
- Follow-through: after a window lands, let an inner element (icon, title badge) arrive 0.05–0.1 s later with its own small overshoot.
- Screenshake on UI: apply to a container's Position offset (±4–10 px), decay over 0.15–0.3 s; reserve for big moments (rare hatch, level up), never for ordinary clicks. Hit-pause analogue in UI: hold the frame ~0.05–0.1 s right before a reward bursts.

### Gaps
- No published Juice-It-or-Lose-It numeric values (the talk is demo-driven).

## 3. Making UI feel alive at rest without noise

### Takeaway
Idle motion should be slow (multi-second Sine cycles), small (2–5% scale, a few px), phase-randomised, and concentrated on what you want tapped (claimable reward, shop deal, new item). Escalate only when something needs attention (Empires & Allies: slow pulse, then fast pulses).

### Cited Findings
- Building icons bob up and down non-linearly with randomly staggered start times (avoids lockstep). — [Empires & Allies](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Attention escalation: one slow pulse at 7 s, then four quick pulses over 1 s. — [Empires & Allies](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Shine sweep pacing: 2 sweeps then a 2.5 s rest. — [DevForum UIGradient](https://devforum.roblox.com/t/4-uigradient-animations-including-rainbow/557922)
- Roblox ships accessibility settings including a Reduce Motion option (a bug report confirms the client setting "Reduce Motion"). — [DevForum: Introducing accessibility settings](https://devforum.roblox.com/t/introducing-accessibility-settings/2723187); [DevForum bug: Reduce Motion](https://devforum.roblox.com/t/closing-roblox-escape-menu-breaks-coregui-if-reduce-motion-is-on/3021555); [Roblox accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility)

### Inferences
- Budget rule: at most 1–2 idle-animated elements per screen region, and only one "loud" one (pulse/shine) at a time. Everything else static.
- Idle vocabulary: breathing (UIScale 1↔1.04, Sine InOut, 2 s, reverses), bob (±3 px, 2.5 s), slow rotate on background rays/glow (≤10°/s), shine sweep every 3–5 s, gradient hue drift for mythic-tier frames only.
- Randomise each element's phase/start (task.wait(math.random()*cycle)) so the screen never "beats" in unison.
- Respect Reduce Motion: check `GuiService.ReducedMotionEnabled` (property name from prior knowledge, verify in API docs) and disable idle bob/shake/rays, keep fades.
- Stop idle loops when the GUI is not visible (tween:Cancel / disconnect) to save CPU on phones.

### Gaps
- No quantitative research found on how much idle motion kids tolerate before it becomes noise.

## 4. UI VFX layers and 3D-in-UI (ViewportFrames, coins/gems flying) as in Tap Simulator REBORN

### Takeaway
Layer cheap 2D elements (glow image, shine UIGradient, sparkle ImageLabels, confetti) behind/over the item; render the hero object (pet, gem, egg) in a ViewportFrame for stable framing. ParticleEmitters and Highlights do not render inside ViewportFrames, so particles must be 2D UI sprites or done in the real world/camera. CanvasGroup gives true group fades but costs texture memory and can render blank past the memory cap.

### Cited Findings
- ViewportFrame vs real camera for egg hatch: ParticleEmitters and Highlights on pets did not show in a ViewportFrame but did with a real-camera setup; ViewportFrame kept pets steady when the camera moved; judged better for performance; an experienced simulator dev called ViewportFrames "reliable, efficient". — [DevForum: ViewportFrame or camera to open egg](https://devforum.roblox.com/t/is-it-better-to-use-viewportframe-or-camera-position-to-open-egg/2861023)
- CanvasGroup: "consumes extra texture memory", quality/memory capped by client QualityLevel; "when exceeding the memory cap, CanvasGroup will render as a blank texture"; resizing requires a new texture so keep size static; ClipsDescendants always true; needs ZIndexBehavior Sibling; put UICorner/UIGradient directly under it. — [Roblox Docs: CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup.md)
- Reported issues: CanvasGroups filled black / not rendered on some mobile devices; low-quality/blurry content at certain sizes and graphics level ≤3. — [DevForum: black on mobile](https://devforum.roblox.com/t/canvas-group-filled-with-black-for-mobile-devices/2208465); [DevForum: not rendered on mobile](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119); [DevForum: low quality at graphics ≤3](https://devforum.roblox.com/t/canvasgroup-makes-its-content-low-quality-at-certain-sizes-and-graphics-level-3-or-below/2946471)
- Alternative to CanvasGroup fades: tween each child's transparency properties. — [DevForum: transparency transition without CanvasGroups](https://devforum.roblox.com/t/how-to-make-a-transparency-transition-without-canvasgroups/2499941)
- 3D coins from world to UI: DevForum threads cover positioning parts relative to UI / WorldToViewportPoint mapping. — [DevForum: client coin effect, parts to UI](https://devforum.roblox.com/t/client-based-coin-effect-how-do-i-position-parts-to-ui/3125395); [DevForum: Frame same position as Vector3 object](https://devforum.roblox.com/t/how-to-make-a-frame-udim2-the-same-size-and-position-as-a-object-vector3-in-the-workspace/1822695)
- Community "3D particles in ViewportFrame style" effects exist as a workaround for missing particles. — [DevForum: 3D Particles, ViewportFrame style](https://devforum.roblox.com/t/3d-particles-viewport-frame-style-effect/4088439)

### Inferences
- Reward-reveal layer stack (back → front): dim backdrop (black, 0.4–0.5 transparency, fade 0.2 s) → slow-rotating soft glow/beam texture in rarity colour (NOT a spiky ring of rays — owner forbids sunbursts; use soft radial glow, light shafts from below, or a soft bokeh field instead) → ViewportFrame hero (spin via CFrame on a RenderStepped, 30–60°/s, scale-punch 0 → 1.15 → 1) → 2D sparkle ImageLabels (4–8 star glints, random positions, scale 0 → 1 → 0 over 0.3–0.5 s, staggered) → shine sweep over name plate → rarity text scale-punch → confetti only for epic+.
- "3D objects flying out of the UI" (Tap Sim style): two options. (a) Small ViewportFrames per coin/gem (each with one mesh, rotate it) tweened like the 2D coin fly; cap ~10–15 simultaneous VPFs on phones. (b) Real world parts in front of the camera (CFrame relative to Camera, a few studs away) so particles/lighting work, then hand off to a 2D icon at the counter. Option (b) is how particles stay visible.
- Depth-of-field look: Lighting.DepthOfFieldEffect / BlurEffect (Size 12–24 tweened in over 0.2 s) behind a modal makes UI pop; turn off on low-end.
- Glow pulse: duplicate the icon as a white/rarity-tinted ImageLabel behind it, ImageTransparency 0.6 ↔ 0.2 and UIScale 1 ↔ 1.08, Sine InOut 1–1.5 s.
- Frame budget: at 60 fps there are ~16.7 ms per frame; keep live tweens on screen to tens, not hundreds; pool cloned coins/sparkles instead of Destroy/Clone each time.

### Gaps
- No primary breakdown of Tap Simulator REBORN or Pet Simulator 99 reveal internals found; BIG Games does not publish them. Measuring from gameplay video is the remaining route.
- No official Roblox numbers on ViewportFrame cost per instance.

## 5. UI SFX: per-event sound, layering, pitch variation, rising combos

### Takeaway
Every interaction gets a short sound that matches its visual weight; repeated sounds get small random pitch variation; successive combo/count events rise in pitch (1 semitone = ×1.0595 PlaybackSpeed); rewards layer (whoosh + impact + sparkle); missing a reward is silent by design.

### Cited Findings
- Rising pitch: shift by one semitone per step, multiplier 2^(1/12) ≈ 1.06; N semitones = 1.06^N (3 semitones ≈ 1.19); ×2 = one octave up, ×0.5 one down. Random small pitch shifts on each playback reduce repetition (amount unquantified). Pitch can carry information (harder impact = higher pitch). — [Game Developer: The Power of Pitch Shifting](https://gamedeveloper.com/audio/the-power-of-pitch-shifting)
- Combo meter: each fill plays a higher pitch than the last to build tension; final payout plays a reward sound. — [Empires & Allies](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Each reward plays its own sound as it appears (staggered), click on reward = sound + particles; expired auto-collected rewards get no sound — the positive feedback is reserved for the player's action. — [Empires & Allies](https://gamedeveloper.com/design/clicking-and-rewards-in-empires-and-allies)
- Button press + sound pattern in Roblox (TweenService + Sound on toggle). — [DevForum: ON/OFF button effects](https://devforum.roblox.com/t/classic-on-and-off-button-effects-sound-tweenservice/981249)

### Inferences
- Per-event palette (all short, one "family" of timbres so the UI sounds like one product):
  - Hover (PC only): very soft tick, ~20–40 ms, quiet (−12 dB vs click).
  - Press: soft "pop"/plastic click, 30–80 ms; release can be a slightly higher second tick.
  - Back/close: same family, lower pitch (e.g. ×0.9) and shorter.
  - Window open: short airy whoosh (150–300 ms) + soft pop on land; close = reverse/shorter whoosh.
  - Tab switch: light tick/flip.
  - Error/locked: low dull "bonk" or two-note descending, never harsh for kids.
  - Coin fly: one tick per coin arriving, PlaybackSpeed random 0.95–1.05 and rising +1 semitone per coin (cap at ~+12, then hold) — the classic "coin ladder".
  - Count-up: ticks at a capped rate (~15–25/s), rising pitch, final "ding" on completion.
  - Reward reveal: build-up riser (rising noise/shimmer tied to the anticipation length) → impact "boom/pop" on burst → sparkle/chime tail; rarity escalates the layers (common = pop + chime; legendary = riser + sub-boom + choir/chime + confetti crackle).
  - Level up: short fanfare 1–2 s, major-key, bright.
  - Unlock: metallic click/clunk then chime.
  - Toast: soft two-note chime, unobtrusive.
- Pitch randomisation in Roblox: `sound.PlaybackSpeed = base * (1 + (math.random()-0.5)*0.1)` (±5%, ≈ ±0.8 semitone). Use SoundService/SoundGroups so UI sits under music; preload and reuse Sound instances (or clone few) instead of creating per tick.
- Rate-limit: never play more than ~3–4 overlapping copies of the same UI sound; drop extras.
- Owner workflow (from task context): make sounds in Fish Audio, process and upload — see roblox-game-sounds skill.

### Gaps
- Audiokinetic "Approaching UI Audio" article would not render (JS required); A Sound Effect / CreatorSoundsPro pages returned no concrete guidance. No sourced numbers for click lengths, loudness offsets or kid-specific UI audio guidance; the per-event values above are synthesis.

## 6. How much motion is too much (phones, kids)

### Takeaway
Motion must never delay the player: input feedback instant (<100 ms), frequent actions short (≤250 ms), long sequences skippable, big effects reserved for rare events, and a Reduce Motion path. Juice is tuned by subtracting.

### Cited Findings
- Too short feels aggressive, too long feels obstructive and annoying; bounces only where tone fits. — [web.dev](https://web.dev/articles/choosing-the-right-easing)
- <100 ms feels instant; 500 ms upper target for UI animation. — [Val Head](https://valhead.com/?p=2978)
- Stop when the interaction communicates enough; effects become "a gaudy mess". — [dvdfu](https://medium.com/@dvdfu/practical-juicing-for-game-devs-efe9b06c246b)
- Roblox accessibility settings include Reduce Motion. — [DevForum: Introducing accessibility settings](https://devforum.roblox.com/t/introducing-accessibility-settings/2723187)
- CanvasGroups can render blank past texture memory cap or fail on some mobile devices — overuse is a phone risk. — [Roblox Docs: CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup.md); [DevForum mobile issue](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119)

### Inferences
- Intensity ladder: tap (tiny) < claim (small) < common reward (medium) < rare (large) < legendary/level up (full screen). If everything is "large", nothing is.
- Repetition rule: anything seen 50+ times per session (button, coin pickup) stays under ~0.3 s and gets lighter after the first few; hatch-type sequences offer tap-to-skip after the first view and an auto/fast mode for multi-hatch.
- Never block input during a cosmetic tween; let a new tap cancel/finish the current one.
- Test on a low-end phone at graphics level 1–3: drop blur, CanvasGroups and extra ViewportFrames there.

### Gaps
- No studies found specifically measuring motion tolerance in child players on Roblox.
