---
date: 2026-11-01
tags: [celestial, supernova, ui, sound, psychology, plan]
status: plan (discussing, not building yet)
---
# Supernova Incremental - UI, sound and psychology plan (UI first, then the whole game)

Owner (1 Nov night, screenshot of the HUD: "so bad"): "remember the UI research and sfx and psychology. use those on fixing the ui and after ui, the entire game".
Built only from the vault: [[Roblox Playbook - Rules for every game]], [[Roblox Playbook - Game craft deep dive]] (sections 3 sound, 5 UI), [[Playbook notes - UI deep dive]], [[Playbook notes - Sound and music]] (section 4 psychology), [[2026-11-01 Supernova Incremental - Why players keep playing]], [[2026-11-01 Research - Do cutscenes help, what makes a good one]], [[2026-11-01 Celestial Incremental - 10 incrementals played]].

## What's wrong now (owner's screenshot)
1. Collides with Roblox's own UI: shop / settings under the player list (top right), giant left buttons over the chat.
2. A tower in the top centre: counter + rate + SUPERNOVA bar + STAR SURGE bar + the name tag.
3. Pills for nothing happening: "CLEAR SKIES 6m 43s", "LOST STARS 0/15 back in 14m", "GROUP +10%".
4. The biggest thing on screen is a hint ("Keep collecting!").
5. No hierarchy: one font, one size, one navy pill for everything; navy on a navy world.
6. Candy green / blue / yellow tiles fight the space look; ~150 px buttons.
7. HUD explains itself ("(whole server)").
8. World glows / neon compete with the UI.

## PART 1 - UI
### Screen budget (top incrementals show ~5 things; each corner one job; keep out of Roblox's zones)
| Zone | Element | Shown |
|---|---|---|
| Top centre | ONE compact pill: stardust icon, number (count-up), "+0.8/s" small beside it | always |
| Under it | thin goal bar "SUPERNOVA 64%" (the one main goal, always visible = the "point") | always |
| Left, below the chat | 4 icon buttons ~80 px, icon + 1-word label: TREE, QUESTS, SHOP, + FORGE when unlocked | always; locked features hidden until close |
| Right, below the player list | one chip "BOOSTS x1.1" -> tap = list (group, friends, server, weather...) | always, one line |
| Under the chip | event pill (METEOR SHOWER 1:23 / AURORA / STAR SURGE 80%) | only while running or close |
| Bottom centre | big glowing SUPERNOVA button | only when ready |
| Toasts | one at a time, 2 s, under the top pill | on events |
| Hints | small one-line strip, tutorial / stuck only, stays until done | tutorial |
Gone from the HUD: Lost Stars timer (the stars glow in the world instead), "Clear skies", the always-on surge bar, the giant tip bar, the Mote Index button (inside the Tree).

### Kit tokens (one UITheme module; nothing outside it)
- Fonts: 1 display (Luckiest Guy for numbers + titles) + 1 body (Nunito / Builder Sans for small text). Never more than 2.
- Panels: near-black indigo, slight vertical gradient, 3 px stroke in a LIGHT rim (pale violet) so panels separate from the navy world; tinted darks, never #000; corner 0.25, pills 0.5; padding 8/12/16.
- Colour = meaning: green buy/go, gold premium/claim/SUPERNOVA, red close/notification, purple rare, blue info, grey locked. Rarity ladder grey/green/blue/purple/gold/rainbow + label.
- Chunky button: gradient 15-25% lighter on top, 3-4 px tinted stroke, darker lip 4-6 px below; white display text with 2-3 px stroke. One shine sweep per screen max.
- Sizes: one UIScale per ScreenGui = clamp(viewportY/1080, 0.6, 1.4); UISizeConstraint on windows; test at 667x375.
- Layers: HUD 0, windows 10, rewards 20, toasts 30, transitions 100. WindowManager (one window at a time, X / tap outside closes) + PopupQueue (one popup at a time, none on join, none in the tutorial).

### Motion (feel)
Press 0.92 + drop into the lip; open 0.8 -> 1 Back Out 0.25 s, close 0.15 s; toast slide 0.3 s, hold 2 s; count-up 0.4-0.8 s then pop 1.15x; red dot pulse every 1.5 s, cleared when opened; locked button = small "no" shake + soft thud. Reduced Motion: no shake / flash.

## PART 2 - Sound (action sounds first: the study showed action sounds raised fun and immersion; ambience much less)
- Mixer on the Audio API: Music 0.4, SFX 1.0, UI 0.8, Ambience 0.3 -> compressor -> out; Settings sliders per bus.
- Income: NOT a ding per tick (automatic income would spam). A soft tick every ~1 s whose pitch steps up the major pentatonic as income grows, a "cash roll" + one ding for big moments; min retrigger gap 40-60 ms; 4-8 pooled players.
- Buying a tree node / body: two-note rising interval (confirm) + the body's own "arrival" sound when it appears in orbit (each tier its own, deeper/bigger as tiers rise).
- Can't afford: low soft thud, never a buzzer.
- UI family in the music's key (out-of-key UI sounds lost players 1-2 min early in an informal test): tap click, open rising whoosh, close falling whoosh, claim chime + sparkle. No hover sounds on mobile.
- Rarity ladder (Star Forge): pop / pop+chime / rising arpeggio / +whoosh + duck / Legendary+: 0.5-1 s silence then the big stinger + server message.
- SUPERNOVA: music ducks to silence as the star swells (silence is noticed), then the burst stinger; then a NEW music loop per layer (Supernova -> Black Hole -> Ring Nebula) so each layer sounds new.
- Comet fly-by: a rising whoosh you hear before you see it (sound directs attention).
- Every file normalised to ~-16 to -18 LUFS, checked on a phone speaker (identity in 1-5 kHz).

## PART 3 - Psychology across the whole game (what keeps them playing; all from the vault)
1. Number always up + check-ins pay: automatic income from second 1, offline earnings shown on return ("While you were away: +X").
2. A new thing every few minutes, first Supernova in session one (~12 min); first action <15 s, first reward <60 s.
3. Curiosity (the strongest driver of playtime, CHI 2024): "?" tree nodes, locked things shown with what opens them, the Ring Nebula visible, every cutscene ends on a tease.
4. Choices not chores: several tree branches whose best pick keeps shifting; comets optional.
5. A wall, then a reset clearly worth it (~2-3x faster), each layer one new mechanic.
6. Luck with shown odds (Star Forge), never sold.
7. Progress others see: rank over the head, your star system grows around you, Supernova burst in the sky for the server.
8. Together: Star Surge (from everyone's income), shared sky, friend / group bonus.
9. Reasons for tomorrow: streak, quests that fit a session (not "play 2h53m"), weekly Saturday event.
10. A finish line: Cosmos Charted %.
Banned (Rules for every game): fake timers, resetting countdowns, false scarcity, "BUY NOW!", offers in the tutorial, paid luck.

## PART 4 - Then the whole game, in this order
1. UI kit + HUD (Part 1) on the current game, so every later screen reuses it.
2. Sound mixer + action sounds (Part 2).
3. Core swap: star system earning + Constellation Tree main screen (Revamp 2).
4. Supernova cinematic + quick version + tease; Star Forge with odds + rarity ladder.
5. Black Hole layer + automation; Ring Nebula + fusion.
6. World pass: fewer glows / neon so the star system and the UI read; thumbnails / icon (chain idea).
7. Test: 667x375 screenshots, 2-player test, FPS on a phone, onboarding funnel.
