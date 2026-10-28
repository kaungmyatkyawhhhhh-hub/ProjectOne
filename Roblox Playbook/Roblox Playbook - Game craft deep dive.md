---
title: Roblox game craft deep dive
type: research-report
created: 2026-10-28
projects: [GYM ARC, SPEED ARC, MOW ARC]
tags: [roblox, game-design, sound, vfx, ui, optimization, qa, core-loop, incremental, mobile, kids-games]
related: "[[Roblox Playbook - Making games better]]"
---

# Build the feel once, reuse it everywhere

A solo Roblox developer gets craft-level quality by building a small set of systems once and reusing them in every game, not by polishing screens one at a time. The core loop comes first. It has to be fun with the rewards stripped out, and its pacing should come from a cost-and-prestige spreadsheet, not guesswork. Around that loop sit four reusable kits: an audio bus graph with a master compressor and pooled reward sounds, a VFX library of burst emitters kept within a phone particle budget, a UI kit built from tokens with native modifiers instead of images, and a profiling routine run on a real cheap phone before every release. Roblox never scores how a game looks. It ranks games on what players do, such as bouncing in the first 60-180 seconds or returning over 28 days ([Discovery](https://create.roblox.com/docs/discovery)). So polish counts only through behaviour, and the evidence says the feedback tied to the player's own actions does most of the work. In a controlled 2024 study, character and action sounds significantly raised immersion and fun, while ambient sound only trended upward ([Applied Sciences 2024, via Preprints.org](https://www.preprints.org/manuscript/202312.0324)). Roblox and the industry publish few hard numbers for craft. The firm ones are 100 particles per second per emitter on mobile, up to 1 ms of mobile GPU for the first Highlight, 16.67 ms per frame, -16 LUFS for mobile loudness and 1,000 bytes per unreliable remote. Most other values in this note are practitioner conventions and are labelled as such. Treat them as starting points to tune on your own phone, not as rules.

> **How to read this note.** This builds on [[Roblox Playbook - Making games better]] and does not repeat it. Discovery, monetization, the basic performance rules (streaming, transparency 0/1, 512 px textures), data stores, security, safe-area UI basics and the first-session checklist are all there. Here, a claim with an inline link is **sourced**. ***(rule of thumb)*** marks a practitioner convention or my own synthesis: a sensible default, not a measured fact. ***(low reliability)*** marks blogs or vendor articles. The **Hand these to Claude Code** section near the end turns each part into prompts you can paste.

---

## 1. A loop that is fun with the rewards removed

### Seconds, minutes, hours, days

Michail Katkoff's definition still holds up. The core loop is the repeated action that drives play, and it should be "short, accessible and rewarding." Each core loop holds two session loops, so a player can stop after the first or carry on into the second, which supports both a 2-minute bus-stop visit and a 30-minute sitting ([Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)). Around it sits the **metagame**: planning, sub-goals, optimisation and other players. Katkoff's advice is to *hide* that complexity so players discover it, and his Clash of Clans example nests timescales. Collection takes seconds, training takes minutes, and building takes hours to days ([Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)). Self-Determination Theory explains why the layering works. Across four studies of about 1,000 players, game appeal and intent to keep playing tracked how well a game satisfied **competence, autonomy and relatedness**, more than "fun" alone ([ScienceDaily on Ryan, Rigby & Przybylski 2006](https://www.sciencedaily.com/releases/2006/12/061226134706.htm)).

For your games that becomes a four-layer template *(rule of thumb)*:

| Timescale | Layer | GYM ARC | SPEED ARC ("+1 SPEED every step") | MOW ARC (planned) |
|---|---|---|---|---|
| Seconds | Verb + juicy feedback | Tap to lift → "+N STR" pop | Run → speed ticks up, trail grows | Walk through grass → blades burst, "+N" |
| Minutes | Earn → upgrade → new goal | Better weights, next gym | Smash the next wall, which needs speed X | Range, speed and value upgrades |
| Hours | Prestige / collection | Rebirth, EXP-earned Alters | Rebirth, "Go Pro" final wall, race event | Regrow (prestige), tiers, automation |
| Days | Social and live | Leaderboards, flexing Alters | Races every 3 min, relay or co-op boosts | Seasons, weekly events |

Map each feature to an SDT need while designing. Numbers going up and harder walls give **competence**. Choosing which upgrade path or zone to chase gives **autonomy**. Races, co-op boosts and showing off give **relatedness**. Variable-ratio eggs and countdown timers sit on top of these needs. They are where the ethical and policy risk lives, not where the fun comes from *(rule of thumb)*.

### Strip the rewards and watch kids play

The test a solo developer can run cheaply is to remove every reward, multiplier and popup and ask whether the bare verb still feels good. If it doesn't, progression will only delay the drop-off ([RoWatcher](https://rowatcher.com/news/the-core-loop-mistake-killing-most-roblox-games), *low reliability*). The same opinion piece notes that Tower of Hell held players for most of its life with almost no progression. SPEED ARC belongs to a real micro-genre of "every second you get +1 speed/jump" games, where a stat grows from simple activity and players spend it on courses ([Bloxodes](https://bloxodes.com/stats/games/roblox-but-every-second-you-get-1-speed-4122139330)). The bare verb there is *movement that visibly accelerates*. That puts the craft budget on run feel, FOV, trails and footstep audio, more than on menus *(rule of thumb)*.

The cautionary case is Kotaku's reviewer on Steal a Brainrot. They built a large collection in about 40 minutes, lost it to theft and felt real anger, yet "saw no reason to keep playing" ([Kotaku](https://kotaku.com/steal-a-brainrot-roblox-empire-review-popular-memes-1851787027)). That is high minute-to-minute intensity on top of a thin long-term goal. GameAnalytics credits 2025 retention gains to **re-entry design, offline/idle progression and social co-play**, and says the "next return within hours" is stronger with friends ([GameAnalytics 2025 Roblox Report](https://www.gameanalytics.com/cn/reports/2025-roblox-report)). Depth should come from *multiplicative modifiers on an unchanged verb*, such as mutations, weather and pet bonuses, which a child can ignore at first and discover later. Grow a Garden's crop and pet mutations are the reference ([PCGamesN](https://www.pcgamesn.com/grow-a-garden/mutations)).

### What "good" looks like in numbers

The newest GameAnalytics benchmark covers 500+ Roblox games with 1M+ MAU, August 2025 to July 2026 ([Game Dev Reports summary](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)):

| Metric | Median game | Top 1% |
|---|---|---|
| D1 retention | **10.3%** | **22.2%** |
| D7 retention | 1.6% | 9.1% |
| D30 retention | 0.5% | 4.7% |
| Game session length | 9.8 min | 21.1 min |
| Sessions per day | 1.56 | 8.3 |

Session length is the clearest maturity signal. In the 2025 report, games averaging **0-3 minute** sessions had a median D1 of **4.3%**, while **19-24 minute** games reached **11.5%** and the highest ARPPU spread. Long sessions were "necessary but not sufficient" ([GameAnalytics 2025](https://www.gameanalytics.com/cn/reports/2025-roblox-report)). These medians sit far below the vendor simulator figures (32% D1) quoted in the earlier playbook. Trust GameAnalytics more, because it is larger and its method is published. Derived thresholds *(rule of thumb, not a published standard)*: D1 well under 8% with sessions under 6 minutes means rework or kill the loop. D1 around 10% with 13+ minute sessions is normal for scaled games, so keep iterating. D1 of 20%+ with D7 of 8%+ is top-1% territory. Small new games produce noisy numbers, so compare cohorts of at least a few hundred players.

Two refinements to the egg rules in the earlier playbook. Roblox's paid-random-items policy covers more than eggs. It also covers **enhancement items** (random-duration potions, upgrades with a success chance), **combination items** (fusing for a chance at better results) and **probability modifiers** (luck boosts, pity, rate-ups). When `ArePaidRandomItemsRestricted` is true, the allowed alternatives are a free earnable path, a disclosed fixed outcome order, direct purchase at expected value, or hiding the item ([Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)). A "50% chance to upgrade your Alter" button bought with Robux-purchasable currency needs the same odds panel as an egg.

---

## 2. Spreadsheet the economy: exponential costs, polynomial income, prestige

### The four formulas that run every incremental

Anthony Pecorella's Kongregate series is the canonical reference ([Math of Idle Games I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)):

| What | Formula |
|---|---|
| Next cost | `cost = base × r^owned` |
| Total production | `prod = (prodBase × owned) × multipliers` |
| Cost to buy n more (k owned) | `base × r^k × (r^n − 1) / (r − 1)` |
| Max affordable with currency c | `floor( log(c·(r−1) / (base·r^k) + 1) / log(r) )` |

Costs grow **exponentially** while production grows linearly or polynomially through multipliers. Pecorella calls this "a seesaw": fast early progress, then a wall, and exponential growth eventually beats any polynomial, which is what makes prestige meaningful. AdVenture Capitalist's Lemonade Stand uses **r = 1.07**, base cost about 4 and 1.67/s, with a stacking **×2 at 25 and 50 owned** ([Part I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)). Common growth rates run **1.07-1.15**. Clicker Heroes uses 1.07, Cookie Clicker 1.15, and 2.5 is "very steep". A rate of 1 gives linear costs, which are boring ([Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)). If only the newest generator gets milestone boosts, every older one becomes irrelevant. Spreading milestones out so the best buy keeps shifting is "much more interesting" ([Part I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)).

To find pacing spikes before players do, simulate a greedy player. The Tuts+ heuristic buys whichever upgrade minimises `cost/income + cost/(income + gain)`. At 5/s, buying a cost-20 (+1/s) upgrade before a cost-100 (+10/s) one reaches 16/s in 20.67 s, against 21.33 s the other way round ([Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)). One indie postmortem names "no automated balancing" as the motivation-killer, alongside having no deadline ([Game Developer postmortem](https://www.gamedeveloper.com/design/lessons-of-my-first-incremental-game)). Have Claude Code write a headless simulation that logs time-to-each-unlock, and tune against target windows. That is a job it can do well, and you can judge the output without reading code.

### Prestige formulas and what they cost the player

| Game | Prestige currency | To double it, earn about |
|---|---|---|
| Realm Grinder | `(sqrt(1 + 8·c_max/1e12) − 1)/2` | 4× |
| AdVenture Capitalist | `150 × sqrt(c_lifetime/1e15)` | 3-4× |
| Cookie Clicker | `cbrt(c_lifetime/1e12)` | 8× |
| Egg, Inc. | `(c_run/1e6)^0.14` per run | 128× |

Source: [Math of Idle Games III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii). A square root is generous, a cube root is harsh, and Egg, Inc.'s seventh root rewards active play under a 2-hour offline cap. Formulas based on **lifetime or best-ever earnings** force each run further. Formulas based on **current-run earnings** can let players reset at the same spot forever ([Part III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)). Chains of generators that produce generators grow like xⁿ/n!, which stays below exponential, so exponential costs still win ([Part II](https://www.gamedeveloper.com/disciplines/the-math-of-idle-games-part-ii)). Later layers repeat the pattern. Antimatter Dimensions puts its first big reset at 2^1024 ≈ **1.79e308**, the float limit, and unlocks challenges and automation there ([AD wiki](https://antimatterdimensions.wiki.gg/wiki/Infinite)).

The same maths drives SPEED ARC's walls and GYM ARC's rebirths. The earlier playbook gave `100 × 1.5^rebirths` for rebirth cost. The step this note adds is to put it in a spreadsheet with one row per wall or upgrade and these columns: level, cost (`base × r^level`), income per second after buying, **seconds to afford** (`cost / income`) and cumulative minutes. Check each "next goal" against a target window: **30-90 s early, 2-5 min mid-session, first prestige in 10-20 min, later prestiges on return days**. Set the prestige point where time-to-next-goal starts to exceed the session target, so resetting is obviously the better move *(rule of thumb)*.

### MOW ARC: a worked starting spec

The genre leader is LethalDolphin's **Grass Cutting Incremental**. It has **30.1M visits, an 89% like ratio and a 32.6-minute average session**, and monetises with **0 game passes and 4 developer products** ([RoTrends](https://rotrends.com/game/3478678937)). Grass spawns at about 1 per second and is cut by walking through it. Levels grant Perks, and **Prestige unlocks at level 31**, resetting grass, upgrades and perks for permanent upgrades. **Automation, including offline cutting, unlocks at Tier 2**, and Platinum blocks arrive at Tier 3 ([Sportskeeda](https://www.sportskeeda.com/roblox-news/grass-cutting-incremental-a-beginner-s-guide)). Pecorella's 2-hour model runs are far too long for a ~30-minute Roblox sitting. Here is a starting spec to hand to a simulation and tune *(rule of thumb throughout)*:

| Parameter | Starting value |
|---|---|
| Core upgrade cost | `base × 1.12^level`; "many small buys" 1.07-1.10; capped, powerful upgrades 1.15-1.5 |
| Milestones | ×2 production every 25 levels of an upgrade |
| Regrow (prestige 1) points | `total = floor(sqrt(lifetimeGrass / T))`; gain = total − already claimed (AdCap-style, lifetime-based) |
| Regrow bonus | production × (1 + RP), or × (1 + RP)^0.5 if it runs away |
| First Regrow | 10-20 min into session one; next run reaches the old wall 1.5-3× faster |
| Season (prestige 2) | harsher: `floor(log10(RP / 1e3)) + 1`, or a cube root |
| Each new layer | automates the previous layer's busywork and adds **one** new mechanic |
| Offline earnings | capped; Egg, Inc.'s 2 h is the only sourced cap |
| Display | rates shown as "×N" once raw numbers lose meaning; soft-cap (exponent 0.5) past thresholds |
| Monetisation | timed ×2 dev products; an *earlier* auto-mower pass, with automation still earnable in play; never sell prestige currency |

Numbers break at 1e308: Roblox developers report leaderstats turning into `inf` ([DevForum](https://devforum.roblox.com/t/after-1e308-leaderstat-game-breaks/3740242)). If the design stays below about 1e300, use plain Luau numbers, a suffix formatter (K, M, B, T, Qa, Qi, then scientific notation) and a StringValue for display *(rule of thumb)*. Past that, use a mantissa-exponent library. **Quicknum** stores a 16-byte buffer, saves as 32-character hex, and self-reports roughly twice BigNum's add speed ([DevForum: Quicknum](https://devforum.roblox.com/t/quicknum-fastest-big-number-library/3878728)). Exact big-integer libraries like APInt lack log and pow, so they don't suit incrementals ([DevForum: APInt](https://devforum.roblox.com/t/a-pint-unlimited-numbers-library-for-incremental-games-and-simulators/3936725)). Track sources and sinks with a daily ledger. If sources greatly exceed sinks there is no challenge, and if sinks greatly exceed sources the game becomes a frustrating grind. Make sure "no single item is useless at all stages of the game" ([Unity economy guide](https://unity.com/how-to/what-game-economy-guide-part-1)).

The recurring failures in this genre are linear costs, unlocks that come too fast or too slow, revealing everything up front, demanding constant clicking and having no balancing tool ([Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)). Choose between showing locked features ("known unknowns") and hiding them ("unknown unknowns") on purpose. Showing everything at once kills discovery.

---

## 3. Sound: action feedback first, through a mixer you build once

### The evidence supports your instinct, with a priority order

You treat sound as core, and the research backs that, but it also sets an order. In a 2×2 study of n=32 per experiment, **character/action sounds** raised immersion (3.13 vs 2.83, p=.01), avatar identification (p=.01) and fun (3.92 vs 3.66, p=.03). **Ambient sound** showed only trends ([Preprints.org](https://www.preprints.org/manuscript/202312.0324); [DOAJ](https://doaj.org/article/ddde88ba732a4177853dd2f4b4cbd6a6)). The effects are about 0.3 points on a 5-point scale. Sound multiplies the quality of a good loop. It cannot rescue a weak one. So the lift, the footstep, the wall smash and the coin come before music and ambience. No study links game audio to D1/D7 retention, and the widely quoted "80% of players" statistic has no source behind it ([RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge), *low reliability*).

### Build on the Audio API, not legacy Sound

The graph-based Audio API **left beta on 10 Sep 2024**, and Roblox's docs now say `Sound`, `SoundGroup` and `SoundEffect` are "discouraged in favor of" audio objects ([Audio objects](https://create.roblox.com/docs/en-us/audio/objects); [DevForum](https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454)). The pieces are AudioPlayer, Wire, AudioFader (a gain node with only `Volume` and `Bypass`, i.e. a bus), AudioEmitter and AudioListener for 3D, and AudioDeviceOutput. Inserting audio from the Toolbox still creates a legacy `Sound`. The recommended route is to copy the asset ID into an AudioPlayer ([Audio assets](https://create.roblox.com/docs/en-us/audio/assets)). Useful AudioPlayer details from the docs ([AudioPlayer](https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPlayer.md)):

- `Volume` (0-10) is a plain property, so TweenService can fade or duck it directly.
- `LoopRegion` lets music loop its body without replaying the intro, and `PlaybackRegion` plays one slice of a sound sheet.
- `Play(atTime)` can be scheduled against `GetMixerTime()` for beat-aligned transitions.
- With `AutoLoad = false`, the first play can lag, so keep reward and UI sounds auto-loaded.
- `Ended` does not fire on looping sounds.

`SoundService.AcousticSimulationEnabled` now switches automatic occlusion and reverb on for emitters ([SoundService](https://create.roblox.com/docs/en-us/reference/engine/classes/SoundService.md)). A simulator rarely needs it.

The mixer to ask Claude Code for *(rule of thumb, standard game-audio practice)*:

```
SoundService
├─ MasterOut   (AudioDeviceOutput)
├─ MasterComp  (AudioCompressor – safety net so 30 coin dings never clip)
├─ Bus_Music   (AudioFader, Volume 0.4)  ─┐
├─ Bus_SFX     (AudioFader, Volume 1.0)  ─┤→ MasterComp → MasterOut
├─ Bus_UI      (AudioFader, Volume 0.8)  ─┤
└─ Bus_Amb     (AudioFader, Volume 0.3)  ─┘
   every AudioPlayer is wired to exactly one bus; settings sliders set bus Volume
```

A secondary source says `AudioLimiter` was added around December 2024 and that about **30 simultaneous spatial sources** is a practical ceiling on older hardware. Roblox publishes no voice or audio-memory limit, so treat both as unverified ([RoWatcher](https://rowatcher.com/news/sound-design-roblox-s-most-underrated-competitive-edge), *low reliability*). Keep UI, reward and music sounds **2D and client-side**. Use 3D only for world objects such as machines, other players' wall smashes and eggs.

### Loudness and mix targets

The only published game loudness references are industry ones, and they are a decade old but still standard. Mobile and handheld: **-16 LUFS integrated ±2 LU**, loudness range 10-15 LU. Console and home: **-24 LUFS**, true peak at or below **-1 dBTP** ([IESD Mix Reference Levels](https://www.audiogang.org/wp-content/uploads/2015/04/IESD-Mix-Ref-Levels-v03.02.pdf)). Sony's mobile target is -18 LUFS, and children's educational apps have been mixed as quietly as **about -28 LUFS**, rising toward -24 in noisy settings ([Audio Media International](https://audiomediainternational.com/mobile-loudness-an-adaptive-approach/)). Mobile games should keep a narrower loudness range than console games. Gentle compression for that is a ratio of 1:1.2-1:1.5 with a release over 1 s ([Designing Sound](https://designingsound.org/2013/02/20/different-loudness-ranges-for-console-and-mobile-games)). In practice, normalise every file to roughly -16 to -18 LUFS before upload, for example with Audacity's Loudness Normalization, because Creator Store assets vary wildly in level *(rule of thumb)*. Then always check the mix on a cheap phone's speaker. Phone speakers lose almost everything below about 200-300 Hz, so put each important sound's identity in the 1-5 kHz range, avoid piercing squeaks, and treat bass as a headphone bonus *(rule of thumb)*.

### The recipe sheet

Bjørn Jacobsen's working rules are the best-sourced craft guidance. Keep "identity" sounds (coin, alert) consistent. Give frequent sounds "ten variations that are almost indistinguishable". Voice-limit loud layers so they can't stack. Keep UI sounds **in the music's key**: his A# UI sounds over A-minor music were dissonant, and in an informal 19-player test those players quit a minute or two earlier. Use silence deliberately, because players notice it "like a fridge switching off" ([A Sound Effect](https://www.asoundeffect.com/game-audio-immersion/)). The rest is standard practice *(rule of thumb)*:

| Element | Recipe |
|---|---|
| Reward sound layers | Transient click/snap 0-30 ms + tonal body 100-400 ms (identity) + sparkle/reverb tail 0.3-1.5 s |
| High-repeat sounds (footsteps, lifts, clicks) | 3-5 sample variants, ±3-8% `PlaybackSpeed`, ±1-2 dB volume jitter |
| Signature sounds (coin, level-up, hatch, wall smash) | Fixed; vary only by deliberate escalation |
| Pooling and voice limits | 4-8 pooled AudioPlayers per frequent sound, round-robin; minimum retrigger gap 40-60 ms for coin ticks; big pickups play a short "cash roll" plus one final ding, not 100 dings |
| Coin combo pitch | `PlaybackSpeed = 2^(step/12)` stepping through major-pentatonic semitones (0, 2, 4, 7, 9, 12); reset after ~1 s idle. Simpler version: `1 + 0.05 × combo`, capped at 1.5 |
| Priority | rarity stinger > error/confirm > gameplay SFX > UI > ambience > music |
| Ducking | Tween `Bus_Music` to 0.5-0.6 (about −4 to −6 dB) with a 50-100 ms attack, then release over 0.5-1.5 s |
| Bus balance | Music around 0.3-0.5 against SFX 1.0 |
| UI family (one timbre, one key) | tap: short dry click; open: soft rising whoosh; close: falling whoosh; confirm/buy: two-note rising major interval; error: low dull thud or falling two notes, **never a harsh buzzer**; toggle: two pitches for on and off; reward: chime + sparkle. No hover sounds on mobile |
| Rarity ladder | Common: pop. Uncommon: pop + chime. Rare: rising arpeggio. Epic: arpeggio + whoosh + music duck. Legendary: 0.5-1 s of silence or drum-roll during the egg shake, then a big stinger + duck + optional server announcement |
| Music | 1-3 loops per zone; `LoopRegion` past the intro; 1-2 s crossfade on zone change; never restart on respawn; lighter loop or lowered bus in shops |

For SPEED ARC specifically: footsteps whose rate follows run speed, a wind layer whose volume rises with speed, and a distinct wall-smash stinger that escalates for the final "Go Pro" wall *(rule of thumb)*. One sourcing note: SPEED ARC is going into a different group from GYM ARC, so **upload its audio as a group asset of that group** by passing the group ID at upload. Uploaded audio is private to its owner until shared, and assets uploaded under the wrong owner need re-uploading or permission grants ([Audio assets](https://create.roblox.com/docs/en-us/audio/assets)). Songs are auto-classified, and only songs that pass copyright checks from ID-verified uploaders can appear as a 15-second preview on the game page ([Audio assets](https://create.roblox.com/docs/en-us/audio/assets)).

---

## 4. VFX: short additive bursts, under 100 particles a second

### The hard limits

The official numbers are few, and they all matter on a cheap phone. An emitter can produce **up to 400 particles/s, or 100 on mobile**. Bigger particles cost more fill-rate, and stacked transparent layers multiply GPU cost through overdraw ([Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)). Particles, decals and textures "don't batch well and introduce additional draw calls". Changing emitter properties at runtime "can have a dramatic impact on performance" ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)). Live particle count = `Rate × Lifetime`, and Lifetime caps at 20 s ([ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)). Flipbooks take square power-of-two sheets **from 8×8 to 1024×1024** in 2×2, 4×4 or 8×8 grids, play at most **30 fps**, and **switch off automatically when a client is low on memory**, which is likely on older phones ([Flipbook release](https://devforum.roblox.com/t/particles’-flipbook-release/2029388); [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)).

Highlights changed in November 2025. The limit rose from about 31 to **255**, but **the first visible Highlight costs up to 1 ms of mobile GPU** time, cost grows with the screen area covered, a *disabled* Highlight still uses a slot, and adding or removing one can trigger geometry rebuilds ([DevForum](https://devforum.roblox.com/t/lights-camera-more-highlights/4061534); [Highlighting](https://create.roblox.com/docs/effects/highlighting)). Use one Highlight for one focused thing, like the selected pet or the next wall, and change its properties rather than recreating it. Never put one on every coin.

### The properties that do the craft work

| Property | What it gives you | Source |
|---|---|---|
| `Emit(n)` (default 16) on a disabled emitter | Bursts for coins and impacts | [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md) |
| `LightEmission = 1` | Additive glow; black areas vanish, so it gives a "premium" glow without Bloom | same |
| `LightInfluence` | **Gotcha:** 1 when inserted in Studio, **0 via `Instance.new`**, so set it explicitly or code-built effects look brighter | same |
| `Squash` over lifetime | Stretched sparks, squash-and-stretch pops | same |
| `Orientation` | VelocityParallel for speed streaks; VelocityPerpendicular for flat rings and shockwaves; FacingCameraWorldUp for auras | same |
| `TimeScale` (0-1) | 0 freezes particles, giving native hit-stop | same |
| `Drag` | Seconds to lose half the speed; makes bursts "hang" then settle | same |
| `ZOffset` | Layer fire over smoke without changing size | same |
| Flipbook `OneShot` | Plays once over the particle's life, ideal for puffs and explosions | same |
| Sphere/Cylinder shapes | **Broken on Attachments**; use them only on parts | [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) |

Paint textures as white-on-transparent or white-on-black, upload one, and tint it with `Color`. A grayscale texture with no alpha needs `LightEmission = 1` so its dark areas disappear ([Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)). Use 256×256 for single sprites and at most 512-1024 for flipbooks, with 2-4 px of padding per cell *(rule of thumb)*. Roblox recommends some spacing between cells to stop bleeding ([Flipbook release](https://devforum.roblox.com/t/particles’-flipbook-release/2029388)). ViewportFrames handle VFX poorly, and Highlights lose colour inside them ([DevForum](https://devforum.roblox.com/t/improvements-to-viewportframes/2897582)). A hatch screen should get its sparkle from UI layers (rays, gradients, flashes) drawn over the viewport, which is also what top simulators appear to do *(rule of thumb)*.

### Recipes and a budget

Real-time VFX follows three phases: **anticipation** (0.1-0.3 s charge-up), **impact** (a 1-3 frame bright additive flash) and **dissipation** (0.4-1.0 s of slower particles fading out). Kids' games read best with a big impact and a short tail. Round shapes and stars mean reward. Sharp shards mean impact or danger *(rule of thumb, standard VFX practice)*. Starting recipes *(rule of thumb)*:

| Effect | Recipe |
|---|---|
| Coin burst | Disabled emitter, `Emit(10-16)`, Sphere shape on a part, Speed 15-25, Acceleration (0, −60, 0), Drag 0.5, Lifetime 0.6-0.9, spinning-coin flipbook (Grid4x4, Loop), Size pops up then shrinks; pair with a UI "+N" |
| Level up / rebirth | Upward ring (VelocityPerpendicular), a fading column Beam, `Emit(~20)` sparkles, FOV +5-8° for 0.15 s |
| Wall smash (SPEED ARC) | 3-6 small debris MeshParts with an impulse, a dust OneShot flipbook, a flat ring shockwave (VelocityPerpendicular, Size 0→10+, Lifetime 0.3-0.5), `TimeScale = 0` hit-stop for 0.05-0.08 s, small camera shake |
| Speed lines | VelocityParallel + Squash > 0, or a camera-attached emitter with a few long thin sprites; Trail on the feet |
| Aura | 1 emitter, Rate 8-15, LightEmission 1, small Size, LockedToPart, FacingCameraWorldUp; switch off by distance |
| Rarity hatch | Escalating shake → white UI flash (Frame fading 0→1 over 0.2 s) → rotating rarity-coloured rays → confetti `Emit`; longer anticipation for rarer pulls |
| Card shine | 2-4 twinkling stars (Random flipbook) + a UIGradient sweep |

Budget for a cheap phone *(rule of thumb)*: coin pop 8-16 particles, level-up 30-60 across 2-3 emitters, aura 10-20 alive, and about **300 or fewer particles alive on screen in total**. When over budget, **shrink particle size before cutting count**, because fill-rate is the mobile bottleneck. Keep one pre-built emitter set per effect, move its attachment and call `Emit` rather than cloning and destroying per event. Turn off persistent emitters more than a set distance from the camera, with a client check every 0.25-0.5 s. A client can read `UserSettings():GetService("UserGameSettings").SavedQualityLevel` to cut burst counts and secondary layers below about level 4, though that API's behaviour still needs checking in your own tests. Shadows switch off entirely below quality 4 ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)). Roblox doesn't document whether Bloom survives low settings, which is one more reason to get glow from additive particles.

Camera juice *(rule of thumb)*: shake of 0.1-0.5 studs decaying within 0.2-0.4 s, FOV punch of ±5-10°, hit-stop of 40-80 ms, and **no full-screen white flashes faster than about 3 per second** (a photosensitivity guideline). Gate all of it behind `GuiService.ReducedMotionEnabled`, which Roblox maps to the player's Reduce Motion setting ([Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)), and add an in-game "Screen shake" toggle.

---

## 5. UI: tokens and native modifiers, not images and one-off buttons

### Why your buttons keep looking like placeholders

The repeated "redesign the buttons" problem in GYM ARC comes from having no **kit**: each button gets built fresh from code defaults. Current Roblox can draw most of a premium kit natively, and stays crisp at every resolution ([Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)):

- **UIStroke.** On text, the default `Contextual` mode outlines glyphs and `Border` strokes the box, so one label can carry *both*. `BorderStrokePosition` sets Inner, Center or Outer. A child UIGradient on the stroke gives a gradient outline, for example a rainbow edge on a legendary card. **Don't tween `Thickness` on text**: it re-renders glyph sizes every frame and can flicker or lag.
- **UICorner.** Scale 0.5+ makes a pill at any size, and the new per-corner radii allow tabs rounded only on top.
- **UIGradient.** Beta adds **Radial, Elliptical and Conical** types plus `TileMode` Mirror. Conical gives a rarity sunburst and Radial gives a glow, with no images.
- **UIShadow (beta).** Drop and inner shadows that follow UICorner shapes or text glyphs.
- **ZIndex.** Siblings that share one render in undefined order, so give layered elements unique values.

The built-in font families include display faces **Fredoka One, Luckiest Guy, Bangers and Denk One**, and text faces Builder Sans, Montserrat and Nunito. Set them with `FontFace = Font.fromName("FredokaOne")` ([Font](https://create.roblox.com/docs/reference/engine/datatypes/Font.md)). Roblox deprecated Gotham and Arial in favour of Builder in 2024 ([DevForum](https://devforum.roblox.com/t/2868222)). Builder Sans headings read as "default Roblox". Save uploaded images for what modifiers can't draw: illustrated icons and textured 9-slice frames. A 9-slice `SliceCenter` is the stretchable rectangle in source pixels, for example `Rect.new(30, 30, 34, 34)` in the reference sample ([9-slice](https://create.roblox.com/docs/en-us/ui/9-slice)). A community formula keeps 9-slice corners resolution-independent: `SliceScale = ViewportSize.Y / 2700`, calibrated so 0.4 looks right at 1080p ([DevForum](https://devforum.roblox.com/t/slicescale-formula/1338744)). Keep each image at or under 1024 px per side. Larger uploads have been downscaled and blurred ([DevForum, 2020](https://devforum.roblox.com/t/imported-uis-are-blurry/727482)), although Roblox's 3D texture spec now mentions 4096 ([Texture specs](https://create.roblox.com/docs/en-us/art/modeling/texture-specifications)).

### The kit, with numbers

Define these tokens once in a `UITheme` module and forbid anything outside them *(rule of thumb)*:

| Token | Value |
|---|---|
| Fonts | 1 display (Luckiest Guy or Fredoka One) + 1 body (Nunito or Builder Sans); never more than 2 |
| Stroke | 3 px on buttons and panels; 2-3 px Contextual stroke on display text |
| Corner | Scale 0.25 on buttons and cards; pills at 0.5 |
| Padding | 8 / 12 / 16 px |
| Colours | 4 functional colours + the rarity ladder. Dark strokes are **tinted darks of the fill colour, never #000**; slightly desaturated fills, not pure RGB |
| Meaning | green = go/claim/buy; red = close/danger/notification; gold = premium/best value; blue = info; purple = rare/pass |
| Rarity | grey, green, blue, purple, gold/orange, animated rainbow, always paired with a label or border shape |

**The chunky button** *(rule of thumb)*: a Frame with UICorner 0.25-0.3; a vertical UIGradient (Rotation 90) about 15-25% lighter at the top; an outer UIStroke of 3-4 px in a near-black tint of the button colour; and a second, darker "lip" frame offset 4-6 px below, so it reads as tappable. The label is the display font, white, with a 2-3 px dark Contextual stroke. For SPEED ARC's black-blue-gold theme, gold is the primary call-to-action fill with a dark-bronze stroke, blue is secondary, and near-black panels get a subtle blue gradient. A shine sweep runs on **one** button per screen at most.

**States and motion** *(rule of thumb)*:

| State / motion | Values |
|---|---|
| Hover (PC only) | scale 1.05, +10% brightness |
| Press | scale 0.92, face drops 4 px into the lip; down 0.06 s Quad Out, release 0.15 s Back Out |
| Disabled | grey, 60% opacity, a "no" shake of ±4 px × 3 in 0.2 s + the error thud |
| Panel open / close | scale 0.8 → 1, Back Out, 0.25-0.3 s, dimmer to 0.4 transparency / close faster, 0.15 s Quad In |
| Toast | slide in 0.3 s Quint Out, hold 2 s, fade |
| Count-up | tween a NumberValue over 0.4-0.8 s Quad Out, then pop the counter to 1.15× |
| Shine sweep | white UIGradient band (transparency 1 → 0.4 → 1), rotated ~20°, Offset.X −1 → 1 over 0.6 s every 3-4 s |
| Red dot | 16-20 px, white stroke, top-right with AnchorPoint (0.5, 0.5), pulse 1 → 1.15 every 1.5 s, driven by state and cleared when the screen opens |
| Elastic easing | never on anything frequent |

The **reward screen** *(rule of thumb)*: dim the background; show a "YOU GOT!" title; the item scales in from 0 with Back Out over a rotating conical sunburst in the rarity colour; add the rarity tag and a stat count-up; then show a big green Collect button **delayed 0.5 s** so kids don't skip it by accident, with an optional secondary "×2 with pass".

### Layout, layering and architecture

Use `UIListLayout` with flex (`HorizontalFlex`, `Wraps`, a child `UIFlexItem` set to Fill or Grow) for bars and tab rows, and `UIGridLayout` for inventories. Flex costs a little performance when items resize or change ([List and flex layouts](https://create.roblox.com/docs/en-us/ui/list-flex-layouts)). A layout's `AbsoluteContentSize` can read (0,0) until it updates, so size ScrollingFrame canvases in its changed-signal handler ([DevForum](https://devforum.roblox.com/t/gui-optimization-tips/3986563)). If you author in pixels at 1080p, one `UIScale` per ScreenGui set to `clamp(viewportY / 1080, 0.6, 1.4)`, plus a `UISizeConstraint` on modals, stops UI from becoming giant on tablets or tiny on phones *(rule of thumb)*. Use separate ScreenGuis by layer with `DisplayOrder`: HUD 0, menus 10, rewards 20, toasts 30, transitions 100 *(rule of thumb)*. On gamepad, A accepts and B cancels ([Gamepad input](https://create.roblox.com/docs/en-us/input/gamepad)). Set `GuiService.SelectedObject` when a menu opens and provide a thick custom `SelectionImageObject`, because the default outline looks cheap *(rule of thumb)*.

On text size, the sources conflict. The earlier playbook says avoid `TextScaled` because it ignores the player's text-size preference. UI practitioners allow it on short single-line labels with a `UITextSizeConstraint`. Default to fixed `TextSize` with `AutomaticSize`, and use `TextScaled` plus a constraint only for short numbers in fixed boxes.

For architecture, you don't use Rojo, and Studio is your source of truth. Code-first frameworks (React-Lua, Fusion, Vide, roblox-ts) mostly assume a file-based workflow, and even their users say small visual tweaks are easier in Studio's editor and iteration is slow without hot reload ([DevForum: react-lua users](https://devforum.roblox.com/t/question-for-react-lua-users/3709550)). Build visuals in Studio as templates in `ReplicatedStorage.UITemplates`, and let small client modules clone and fill them: a **WindowManager** (one modal at a time, B/Escape to close) and a **PopupQueue** (one popup at a time, never interrupting a hatch or purchase) *(rule of thumb)*. Performance points, sourced from the forums rather than Roblox staff: Roblox caches GUI appearance until something changes, so static UI is cheap and constantly animating UI is not. Frames with UICorner and UIGradient beat ImageLabels. **CanvasGroups cost a lot of memory**, blur at low graphics levels and can render as a white texture on out-of-memory phones ([DevForum](https://devforum.roblox.com/t/gui-optimization-tips/3986563); [DevForum: mobile](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119)). Use a CanvasGroup only for a panel that must fade as one unit, never nest them, and hide closed menus with `Visible = false`. Any TextBox where players name pets or write notes must be filtered through TextService, or the game can be removed ([Text input](https://create.roblox.com/docs/en-us/ui/text-input)).

---

## 6. Optimization: read the bar colour before you delete anything

### The measuring loop

Measure in four steps. (1) The **Performance dashboard** (needs ≥100 DAU) shows FPS, CPU time, crash rate, **unexpected out-of-memory exits** and **memory as a percentage of device memory** by platform. Its **Breakdown by Place Version** compares a release with earlier ones ([Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)). (2) Reproduce on a real cheap phone. (3) Run the **MicroProfiler on the phone itself**: enable it in the in-game Settings, open the IP:port it shows in a PC browser on the same Wi-Fi, append `/90` for 90 frames, and save the dump ([MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)). (4) Only if scripts are to blame, use the Script Profiler (start with 1 minute at 1 kHz) and Luau heap snapshots ([Script Profiler](https://create.roblox.com/docs/studio/optimization/scriptprofiler)).

The bar colour tells you where to look ([MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)):

- **Orange:** worker jobs are the bottleneck (scripts, physics, animation).
- **Blue:** the render thread is the bottleneck (object count, movement, lighting).
- **Red:** render-bound with **GPU wait above 2.5 ms** (too much geometry, texture or effects).

Steady frame times matter more than the average. **Combine & Compare** on two dumps gives a before/after diff flame graph, the proof that a change worked. The tags that matter most for simulators ([Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)):

| Tag | Means | Do this |
|---|---|---|
| Pass3dAdorn | BillboardGuis, adornments, name labels | Fewer visible in-world GUIs |
| fillGuiVertices | Building UI geometry | Less UI on screen; no UIGradient/UICorner on text labels |
| UpdateUILayouts / Layout | Layout-managed and tweened UI | Fixed sizes on BillboardGuis; fewer layouts |
| computeLightingPerform / LightGridCPU | Lighting near the camera; voxel lighting at low quality | Fewer lights |
| queryFrustumOrdered | Too many objects to cull | Fewer, larger meshes |
| UpdateInvalidParts / updateInstancedClusters | Mass property or CFrame changes | Spread updates over frames |
| updateParticles / updateDynamicParts | Particles, beams, humanoids | Lower rate, lifetime, emitter count |
| Present / waitUntilCompleted | GPU-bound | Render less |
| WaitingHybridScriptJob | `WaitForChild`/`wait` resumes, ~30×/s under a budget | Replace waits with events |
| GC | Luau garbage collection | Reuse tables and objects in hot loops |

### Fixing the 31-FPS game (24,000 parts, 421 lights, 681 SurfaceGuis)

No one has published before/after numbers for cuts like these, so the order below comes from where the tag table assigns cost, and the impact estimates are mine *(rule of thumb)*. Do one capture before each step and one after.

1. **Baseline.** A 90-frame phone capture during normal play, plus F9 Memory and Shift+F2 render stats, saved.
2. **Lights (likely the biggest win).** Even with shadows off below quality 4, every light still costs voxel lighting ([Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)). Roblox's lighting team says to have "as few local lights as possible". Shadow cost runs **narrow SpotLight < SurfaceLight < PointLight**, with point shadows by far the most expensive ([Future Is Bright Phase 3](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)). Cut the 421 to a few dozen, set `Shadows = false` on the rest, shrink Range, and fake glow with Neon or emissive textures.
3. **SurfaceGuis.** Bake static signs into textures (one shared atlas), set `MaxDistance` or toggle `Enabled` by distance every 0.5 s, and strip UIStroke, UIGradient and UICorner from in-world text.
4. **Parts.** Merge repeated decor into reused MeshParts. Historically Roblox's instancing treated size, CFrame and colour as per-instance data that doesn't break batching ([Rendering Updates 2017](https://devforum.roblox.com/t/rendering-updates-september-2017/54148)), but the current batching rules aren't published. Convert repeated unions to meshes, set `LevelOfDetail` on distant models, and tighten streaming radius.
5. **Particles and transparency.** See the budget in section 4.
6. **Scripts, only if bars are orange.** Run one central client Heartbeat loop for all pets and coins rather than one connection each. Disconnect connections, because "the engine never garbage collects events connected to an instance" ([Improve](https://create.roblox.com/docs/performance-optimization/improve)). `--!native` with type annotations helps only hot, math-heavy server code, and has a per-game budget ([Native codegen](https://create.roblox.com/docs/luau/native-code-gen)). Parallel Luau needs **more Actors than cores** and suits server NPC or raycast work, not phone rendering ([Parallel Luau](https://create.roblox.com/docs/scripting/multithreading)).

SPEED ARC is meant to be light, so give it budgets from day one rather than cleaning up later *(rule of thumb)*: a few thousand visible parts, under 20 lights, no SurfaceGuis outside the lobby, and at most ~300 particles on screen.

### Memory, network and load

Mobile crashes are mostly out-of-memory exits. Investigate any **crash rate above 2-3%**, especially right after an update ([Identify](https://create.roblox.com/docs/performance-optimization/identify)). On the phone's F9 Memory tab, check **GraphicsTexture, GraphicsMeshParts and Sounds** first. To find leaks, take a Luau heap snapshot, play 10 minutes (respawn, shops, hatches), take another, and read **Unparented Instances / Unique References**. Those views show instances kept alive only by scripts, with the reference path that holds them ([Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)). Server memory capacity is **6.25 GiB + 100 MiB × peak players**. Keep use under 50%, and remember servers don't release memory when players leave ([Identify](https://create.roblox.com/docs/performance-optimization/identify)). For networking, `UnreliableRemoteEvent` silently **drops payloads over 1,000 bytes** and has no ordering or resend, so use it only for cosmetic, continuously changing data ([UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)). If data ping is much higher than network ping (Shift+F3), replication is congested ([Identify](https://create.roblox.com/docs/performance-optimization/identify)). For load time, turn on **Studio > Settings > Network > Print Join Size Breakdown** to list the 20 heaviest instances. `PreloadAsync` one asset at a time gives an honest progress bar, should cover only the loading screen, UI and starting area, and must allow skipping. It does not preload SurfaceAppearance or MaterialVariant ([ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider)).

The audience justifies all this effort. About **65% of a typical game's players are on Android, and about 60% of those phones have 2-4 GB RAM**. Over half the player base uses devices scoring 10k-20k on Passmark, such as the Infinix Smart 9, Moto G05 or Oppo A18 ([Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)). Play 10-15 minutes per test, so thermal throttling shows up.

---

## 7. Quality is a release process, not a final coat

### What Roblox actually reads

Roblox has no visual-quality rubric. Its Feedback dashboard is the direct sentiment channel. It holds up/down votes since 1 Feb 2025 and filtered comments since 17 Mar 2025, shows upvote percentage over 7-90 days against the previous period with device and platform per comment, and exports to CSV. Roblox advises watching for drops after each update and reading every comment ([Feedback](https://create.roblox.com/docs/production/analytics/feedback.md)). The Discovery page does not list like ratio as a ranking signal ([Discovery](https://create.roblox.com/docs/discovery)). Use it as a diagnostic, not as a lever.

### A solo QA pipeline with Roblox's 2025-2026 tools

| Stage | Tool | Key facts |
|---|---|---|
| Every build | Studio Test / Server & Clients | Client output blue, server green; up to 8 clients, "usually 1-2 is sufficient" ([Testing modes](https://create.roblox.com/docs/studio/testing-modes)) |
| Screens | Device Simulator (beta) | Screen size, DPI, keyboard; switching form factors exposes "safe area, overflow, and anchoring problems" ([Device Simulator](https://create.roblox.com/docs/studio/device-simulator)) |
| Text | Player Emulator | Locale, **pseudolocalization and text elongation** ([Testing modes](https://create.roblox.com/docs/studio/testing-modes)) |
| Lag | Network Simulator | Latency, jitter, packet loss |
| Automation | StudioTestService, StudioDeviceSimulatorService, VirtualInput (May 2026) | Scripted multiplayer tests, device presets and simulated input; per-client control not yet available ([DevForum](https://devforum.roblox.com/t/new-studio-testing-apis-and-assistant-improvements/4657854)) |
| Real device | Your cheapest Android | 10-15 min sessions, phone MicroProfiler, F9 Memory |
| Pre-launch | Experience Betas (Dec 2025) | Public but kept out of recommendation sorts; reachable by link, search and ads; Private mode + group "Tester" role; Player Feedback API; focus on D1 first ([DevForum](https://devforum.roblox.com/t/a-new-way-to-test-before-launch-experience-betas/4144485)) |
| Ship | Version notes | Restoring creates a new version but **does not publish**; you must publish it and restart servers ([Version History](https://create.roblox.com/docs/projects/version-history)) |
| After ship | Error Report | Client and server errors with version markers and a **"New errors since"** filter; 100 ignore/group rules; tracks 500 unique errors; dynamic values like user IDs split entries ([Error Report](https://create.roblox.com/docs/production/analytics/error-report)) |
| Logging | Structured LogService (Jun 2026) | `LogService:Info("{player} leveled up", {...})` groups variants by template ([DevForum](https://devforum.roblox.com/t/full-release-debug-faster-with-new-structured-logging-methods/4668415)) |

Playtesting with real kids needs a parent's permission and **the parent present for the whole session**, ideally at home. Ask children to narrate and watch rather than question them ([PlaytestCloud](https://start.playtestcloud.com/blog/playtesting-with-children)). Use a private or beta copy, and never contact child testers you don't know.

### The polish checklist and the vertical-slice bar

The quality bar that best protects a solo developer is the **vertical slice**: one complete loop (earn → upgrade → rebirth or hatch → see progress) at final art, audio, UI and juice quality, *on a cheap phone*, before any second area or system *(rule of thumb)*. The checklist is synthesized from Roblox's hardware-testing guidance (tap targets, readability at arm's length on the lowest device, audio on speaker *and* headphones, input switching mid-session) ([Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)) plus standard practice *(rule of thumb)*:

- **Every action:** a visual response within one frame, a sound, a "+N" or burst, a button tween. Test the loop once muted and once with sound.
- **Consistency:** one kit, one icon style, one currency icon, the same number format everywhere.
- **Five UI states on every screen:** loading (branded, never blank); empty ("Hatch your first pet!"); error (a friendly message, never silent progress loss); disabled (greyed out with the reason shown); success.
- **Edge cases:** leaving mid-purchase or mid-hatch, rejoining, two players claiming one reward, spam-tapping, max level, number overflow, rotation, notches.
- **Art:** a one-page style guide (6-10 hex colours, a material list, bevel size, proportions, one saved Lighting preset), a 10-20 screenshot reference board, a modular kit on a 4-stud grid, and free or AI-generated models re-coloured to the guide and checked for scripts.

### Working with Claude Code without getting "AI slop"

AI coders fail on Roblox in predictable ways: weak Roblox context, wrong script placement and replication, client-trusting remotes, hallucinated or deprecated APIs, duplicated logic, context loss on big projects, and code that looks right but fails in live multiplayer. The mitigations are persistent project docs, server authority, ModuleScripts, checking against the docs and frequent multi-client tests ([Nilo](https://nilo.io/articles/vibe-coding-pain-points-roblox), *vendor source*). The slop look itself comes from default grey frames and fonts, mismatched assets and no juice. A style guide and UI kit in the AI's context prevent all three *(rule of thumb)*. Because your Claude Code connects to Studio, it can start and stop playtests, read the console and take screen captures. Make "ran a 2-client test, read client and server output, captured the screen on a phone-sized viewport" part of every task's definition of done *(rule of thumb)*.

---

## Hand these to Claude Code

Paste these one at a time. Each one makes a reusable system rather than a one-off fix *(rule of thumb throughout)*.

**Project setup (once per game)**

- [ ] "Create `GAME_BIBLE.md` and `ARCHITECTURE.md` from our decisions: palette hex codes, fonts, UI tokens, rarity colours, folder layout, which scripts are server/client/shared. Read both at the start of every task."
- [ ] "Build a `UITheme` module and a `UIKit` of templates in ReplicatedStorage.UITemplates: Button (primary/secondary/danger/disabled, with lip, gradient, tinted stroke, press/hover/disabled animations), Panel, CurrencyPill, Card (6 rarity variants with gradient stroke on legendary+), Toast, RedDot, RewardScreen. No default grey frames, no Builder Sans or Gotham headings, no #000 strokes. Then show me a screenshot of every template on a phone-sized viewport."
- [ ] "Add a WindowManager (one modal at a time, B/Escape closes) and a PopupQueue (one popup at a time, never during a hatch or purchase)."
- [ ] "Build the audio mixer in SoundService with the Audio API: MasterOut, MasterComp, and Music/SFX/UI/Ambience AudioFader buses at 0.4/1.0/0.8/0.3. Add a `Sound` module: `play(name)` from pools of 4-8 AudioPlayers, ±5% pitch jitter for tagged repeat sounds, a 50 ms retrigger gap for coins, a pentatonic combo pitch, and `duckMusic(seconds)`. Wire the settings sliders to bus volumes."
- [ ] "Build a `VFX` module with pre-built emitter sets for CoinBurst, LevelUp, Shockwave, Aura and HatchFlash. Call `Emit` only, never clone per event. Set LightInfluence explicitly. Scale counts down when SavedQualityLevel < 4 and skip camera shake and FOV punch when ReducedMotionEnabled or our Screen shake toggle is off."

**Design and balance**

- [ ] "Write a headless simulation of our economy (costs `base × r^level`, milestone ×2 every 25, prestige formula X). Have a greedy bot buy by the `cost/income + cost/(income+gain)` rule and output a table of minutes-to-each-unlock and minutes-to-first-prestige. Flag any gap over 5 minutes in the first 20 minutes."
- [ ] "List every random outcome bought with Robux or Robux-purchasable currency, including upgrade-chance buttons and luck boosts, and confirm each has an odds panel and a PolicyService alternative."

**Performance (on the heavy game)**

- [ ] "Report counts of lights (with Shadows on/off and Range), SurfaceGuis and BillboardGuis (with modifiers), parts vs MeshParts, ParticleEmitters with Rate × Lifetime over 30, and Highlights (including disabled ones). Do not change anything yet."
- [ ] "Remove decorative lights except the N I approve, set Shadows false on the rest, and add a client distance toggle (0.5 s) for SurfaceGuis and auras. Then tell me exactly what to capture on my phone's MicroProfiler before and after."
- [ ] "Find every `wait()`/polling loop, per-object Heartbeat connection and undisconnected connection; replace with events or one central loop."

**Every feature (definition of done)**

- [ ] "Before building: write a 5-10 line test plan (happy path, edge cases, rejoin/data, 2-client)."
- [ ] "After building: run a 2-client playtest, read client and server output, screenshot on a phone viewport, and list 'what could break'. Use `LogService` message templates for any new errors."

---

## Numbers to remember (new in this note)

| Area | Number | Status |
|---|---|---|
| Particles per emitter | 400/s, **100/s on mobile** | Sourced ([Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)) |
| Flipbook | 8-1024 px square, ≤30 fps, auto-off on low memory | Sourced (same) |
| Highlights | 255 max; first costs ≤1 ms mobile GPU; disabled still uses a slot | Sourced ([Highlighting](https://create.roblox.com/docs/effects/highlighting)) |
| GPU-bound signal | GPU wait >2.5 ms (red bars) | Sourced ([MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)) |
| Crash rate to investigate | >2-3% | Sourced ([Identify](https://create.roblox.com/docs/performance-optimization/identify)) |
| Server memory | 6.25 GiB + 100 MiB × peak players; keep <50% | Sourced (same) |
| Unreliable remote | drops >1,000 bytes | Sourced ([UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)) |
| Android share / low-RAM share | ~65% / ~60% of those at 2-4 GB | Sourced ([Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)) |
| Mobile loudness | −16 LUFS ±2, true peak ≤ −1 dBTP | Sourced, 2015 industry ([IESD](https://www.audiogang.org/wp-content/uploads/2015/04/IESD-Mix-Ref-Levels-v03.02.pdf)) |
| Roblox D1 / D7 / D30 median (1M+ MAU) | 10.3% / 1.6% / 0.5% | Sourced ([GameAnalytics via Game Dev Reports](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)) |
| Cost growth rate | 1.07-1.15 | Sourced ([Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)) |
| Float limit | 1.79e308 | Sourced |
| Grass Cutting Incremental | 32.6-min sessions, prestige at level 31, 0 passes | Sourced ([RoTrends](https://rotrends.com/game/3478678937); [Sportskeeda](https://www.sportskeeda.com/roblox-news/grass-cutting-incremental-a-beginner-s-guide)) |
| On-screen particle budget | ~300 alive | Rule of thumb |
| Music duck | −4 to −6 dB (fader 0.5-0.6), 0.5-1.5 s release | Rule of thumb |
| First prestige | 10-20 min, inside session one | Rule of thumb |
| Hit-stop / shake / FOV | 40-80 ms / 0.1-0.5 studs / ±5-10° | Rule of thumb |
| Button press | 0.92 scale, 0.06 s down, 0.15 s Back Out up | Rule of thumb |

## Conflicts and unknowns to check yourself

- **Not published by Roblox:** simultaneous-sound and audio-memory limits (the "~30 sources" figure is a blog's); whether Bloom, SunRays or DoF survive low quality on mobile; the current mesh batching key; per-light cost or light limits; a mobile memory ceiling in MB; an instance-count guideline; a join-time target; the 2D GUI image maximum (1024 in a 2020 answer, 4096 in the 3D texture spec).
- **Unverified engine details:** whether `SavedQualityLevel` reliably reflects automatic quality, whether off-screen emitters keep simulating, whether `PreloadAsync` covers AudioPlayer assets, and whether `AudioLimiter` exists as a class. Have Claude Code check each in Studio before relying on it.
- **Docs disagree:** the MicroProfiler hotkey is Ctrl+F6 on one page and Ctrl+Alt+F6 on another. `TextScaled` is "avoid" for accessibility but acceptable with a constraint on short labels. Forum users dispute whether one big ScreenGui or many small ones is cheaper, and nobody has measured it.
- **Retention benchmarks disagree:** GameAnalytics' 10.3% median D1 against a vendor's 32% for simulators. Prefer GameAnalytics until your own Creator Hub benchmark band is available.
- **No sourced teardowns** of the audio, VFX or UI of Pet Simulator 99, Grow a Garden, Bee Swarm or Muscle Legends. Statements about "what top simulators do" in this note are observations, not evidence. Play them with a stopwatch and screen recorder to calibrate your own timings.

## Conclusion

The research changes where a solo developer should spend craft effort. "Premium" is not a property of individual screens. It is what a game gains when every screen, sound and burst comes from the same small set of tokens, buses and emitters. That is also why the "redesign the buttons again" loop with Claude Code keeps recurring: the AI has nothing to be consistent *with*. Build the kits once, in a vertical slice, and later work turns into reuse rather than redesign. The second shift is that the measurable constraints all sit on the cheap phone: 100 particles per second, one costly Highlight, and the out-of-memory exits that make up most crashes. So the phone MicroProfiler capture is a design tool, not a final check.

For the three games, the order this implies differs. GYM ARC's gains now come from subtraction (lights, SurfaceGuis) and from a kit that replaces ad-hoc UI. SPEED ARC should start with budgets and kits in place, and spend its craft effort on the feel of accelerating movement and the wall smash. MOW ARC is the one where the maths *is* the design, so it should exist as a simulation that hits a 10-20 minute first prestige before a single blade of grass is modelled.
