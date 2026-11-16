---
tags: [roblox-playbook, research, monetization, sound, ui, vfx, animation]
date: 2026-11-17
---

# Research - monetization psychology, crate reveals, and sound / UI / animation / VFX feel

Done 16-17 Nov 2026 for the City Legends import crates (see [[2026-11-17 Car economy and Skyfreight crate design]]). Also read [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] which already holds the owner's own feel lessons. Most of the sound/UI numbers below come from blog posts and developer articles, not controlled studies - treat them as starting values to test.

## The line we draw (the players are mostly kids)
Fair tactics only. Researchers define predatory monetization in user-generated games like Roblox and Minecraft as purchasing systems that hide or postpone the full financial consequences. Regulators acted: FTC ordered the Genshin Impact publisher to pay 20 million dollars and stop selling loot boxes to kids; Epic paid 245 million dollars in refunds over dark-pattern purchase design (Fortnite). Child advocates argue kids have immature executive function, which makes dark patterns worse for them.

### Fair tactics that work
- Visible progress to a goal: pity bar written as the gap ("6 crates until a guaranteed Legendary"). Design the UI around the gap, not the total.
- Anticipation and a staged reveal (below). A modest reward after a well-paced build can feel better than a big instant one.
- Show-off value: cars visible in the world, rare-car badge, garage-value leaderboard.
- Collection completion: variant families, family bonus.
- A free taste: daily free Basic crate or earned keys.
- One genuinely good starter offer, shown once.
- Honest price choices: 1 / 5 / 10 crates, bigger bundles cheaper per crate.
- Real limited events only (seasonal cars with true end dates).
- Duplicates must have a designed fallback value (cash refund).
- Odds shown, honest, per policy.

### Avoid (kids, legal and reputation risk)
Fake countdowns or fake scarcity; hiding odds or the Robux amount; rigged near-miss reveals (animation that almost lands a better item on purpose); repeated purchase popups or guilt messages; making the free path deliberately miserable; peer pressure messages ("your friend just bought this"); confusing multi-currency pricing.

## Crate / reveal design (anticipation is the product)
- The moment before the reveal is where engagement peaks (spinning, drumroll). Anticipation first, reward second.
- Overwatch-style: box bursts, items shoot up, rarity shown by coloured streaks before the reveal. Light glowing from the crate's cracks before opening builds anticipation. Colored light preceding the item can hint rarity.
- Escalation: animation gets louder and flashier with rarity; sound builds tension. Each rarity can have its own opening animation (Crash Force did one per tier).
- Sound for crates: physical sounds for the crate (key, lid, latches), then a subtle chime as each item is revealed one by one. Cookie Run designer story: cutting a 5-second intro to 1.5 seconds raised daily pulls by 12% (anecdote, unverified) - keep it short.
- Length: long enough to feel important for one pull, not tedious for many in a row. Offer a Skip toggle after a few opens. Overwatch's later animation was criticized as "build-up of a sneeze" - never build up and then fizzle; the payoff must match the build.
- Server rolls the result; the client only animates the outcome (anti-exploit).
- Use probability tiers, make the reveal an event, keep the action low-effort (one tap).

## UI feedback
- 100 ms rule: a visual or sound reaction within 100 ms of a tap, otherwise it feels laggy.
- Buttons slightly scale up/change on hover or press; make interaction feel responsive.
- Appearing UI should ease out (fast start, soft stop); use ease-in/out on others. Popups scale in/out with short tweens.
- Keep sound and vibration within about 15 ms of each other; flash 50-100 ms; shake 0.08-0.12 s.
- Rarity colour language: Common grey, Uncommon green, Rare blue, Epic purple, Legendary gold, Mythic red, Hypercar cyan/white. Use it on tiles, glows, text, and sounds.
- Mobile: keep taps away from joystick and jump button; large text.

## Sound
- Sound is processed faster than visuals - fastest way to reinforce an action.
- Micro-sounds: small, well-timed sounds for every press, pickup, confirm. No sound = no confidence.
- Avoid ear-piercing buzzers, long negative sounds, repeated error spam. Failure sounds should be short and neutral.
- Layered sounds (several samples stacked) create depth; escalating pitch/volume with rarity.
- Our own code-synthesized sounds, not Fish Audio, not ElevenLabs (owner preference).

## Animation, motion and VFX
- Juice = layers of animation and audio on mechanics that already work; it should echo the core gameplay. Test feel early with a prototype before final art.
- Particles: 3 phases (spread, collide/bounce, fade); 20-30 particles are enough, more gets cluttered; 0.5-1 s lifetime.
- Camera work: slight zoom or shake on the rare reveal only; save the big effects for Legendary and above so they stay special.
- Different animations per crate/rarity make each opening feel special.
- Do not use a spiky sunburst circle (owner rule). Use soft glow, light beams from the crate cracks, sparkles, confetti, plane/cargo-themed effects for Skyfreight.
- Juice overload: too many particles, shakes, zooms and chimes hurts gameplay and causes reward fatigue (constant celebration becomes routine). Scale effects with rarity.

## Sources
- Penn State, predatory monetization in user-generated games: https://pure.psu.edu/en/publications/more-than-just-microtransactions-predatory-monetization-in-user-g/
- PC Gamer, FTC and Genshin Impact: https://www.pcgamer.com/games/rpg/ftc-says-genshin-impact-deceived-children-and-orders-its-publisher-to-pay-a-usd20-million-fine-and-stop-selling-loot-boxes-to-kids
- Loeb, Fortnite FTC settlement: https://www.loeb.com/zh-hans/insights/publications/2023/01/fortnite-video-game-maker-settles-ftc-privacy-deception-claims-for-record-$520-million
- Fair Play for Kids, dark patterns and children: https://fairplayforkids.org/?p=27091
- Kotaku, loot box opening design: https://kotaku.com/1793450096
- PC Gamer, psychology and art of loot boxes: https://www.pcgamer.com/behind-the-addictive-psychology-and-seductive-art-of-loot-boxes
- Yu-kai Chou, mystery box reward design: https://yukaichou.com/gamification-analysis/decoding-the-mystery-box-a-dive-into-the-intricacies-of-reward-design/
- Roblox DevForum, what makes a good loot box animation: https://devforum.roblox.com/t/what-makes-a-good-loot-box-opening-animation/1999029
- Roblox crate system script guide (server-side roll, skip toggle): https://robloxcrateopeningsystemscript.pages.dev
- Roblox paid random items policy: https://create.roblox.com/docs/production/monetization/paid-random-items
- Rowatcher, card-game reward loops for Roblox (pity, duplicates): https://rowatcher.com/news/what-card-games-can-teach-you-about-roblox-reward-loops
- Game Developer, squeezing more juice: https://gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-
- Wayline, juice overload: https://www.wayline.io/blog/juice-overload-sensory-feedback-hurts-gameplay
- Creator Sounds Pro, sound effects for game juice: https://creatorsoundspro.com/creating-game-juice-using-sound-effects-to-improve-player-feedback
- Easton Dev, feedback timing numbers (Japanese): https://eastondev.com/blog/ja/posts/dev/20260521-game-feedback-feel/
- Grow a Garden shop loop (5-minute restock): https://allthings.how/grow-a-garden-seeds-and-seed-packs-how-to-get-every-type
