---
tags: [research, watch-study, vfx, ui, 3d, rng]
date: 2026-11-16
skill: ytdlp-video-watch
---
# Watch study: Claude Roblox VFX, exploded-diagram 3D, RNG reveal, UI design hacks

- **Watched:** 2026-11-16, downloaded with yt-dlp on the PC.
- **Method:** frames + scene cuts with ffmpeg; Whisper (base, CPU) for the transcripts.
- **Audio:** v1 and v3 are music only (no speech). The sound was measured, not heard.
- **Skills updated from this:**
  - [[Skills/roblox-ui-pro/SKILL|roblox-ui-pro]]
  - [[Skills/roblox-game-lighting/SKILL|roblox-game-lighting]]
  - [[Skills/roblox-3d-model-from-sheet/SKILL|roblox-3d-model-from-sheet]]
  - [[Skills/roblox-game-sounds/SKILL|roblox-game-sounds]]
  - **New:** [[Skills/roblox-vfx-reveal/SKILL|roblox-vfx-reveal]]

| # | Creator | Link | Length | Views | Likes | Saves | Posted |
|---|---|---|---|---|---|---|---|
| v1 | @bbstudios4 | https://www.tiktok.com/@bbstudios4/video/7708065367733636366 | 8 s | 324K | 31.2K | 6,847 | 2026-11-14 |
| v2 | @oddblockstudios | https://www.tiktok.com/@oddblockstudios/video/7707791600797109517 | 61 s | 22.8K | 1,796 | 1,737 | 2026-11-13 |
| v3 | @usaaa804 | https://www.tiktok.com/@usaaa804/video/7701017387746839840 | 25 s | 628K | 31.7K | 7,474 | 2026-10-26 |
| v4 | @charles.unemployed | https://www.tiktok.com/@charles.unemployed/video/7708439548958723348 | 48 s | 37.1K | 2,415 | 2,222 | 2026-11-15 |

Save rate (saves ÷ views):
- v2: 7.6%
- v4: 6.0%
- v1: 2.1%
- v3: 1.2%

The how-to videos get saved and the VFX videos get viewed. Tutorials earn saves; spectacle earns reach.

---

## v1: "Claude now has the skills of a pro Roblox dev" (@bbstudios4, 8 s)
![[2026-11-16 Watch4 - v1 bbstudios Claude VFX grid.jpg]]

- **Hook (0 s):** a white caption on a black bar above a raw Studio capture. The capture is the claim: it's Studio with the toolbar showing, so it reads as "real, not edited".
- **Structure:** one continuous screen recording, no cuts, 8 s, looped. The beats are:
  1. A punch.
  2. A **red impact frame**: red world, black silhouettes, white rim, and "HA HA" text in the background.
  3. A blue energy vortex.
  4. A blue burst with ground cracks.
  5. A second red impact frame.
  6. Pink sparks fading out.
- **Audio:** "original sound by SoundMan" (music/SFX bed, no voice).
- **Why it works:**
  - A curiosity title tied to a hot topic (Claude).
  - 8 s, so it loops many times.
  - The impact frames are high-contrast flashes the eye can't skip.
  - 727 comments: people ask "how?" and argue AI vs devs.
- **For us:** an 8-second Studio capture of OUR VFX, with a claim caption, is a cheap, high-reach format. The impact frame is the money shot. It's reproducible with `VFXKit.impactFrame` (tested, below).

## v2: "Exploded Diagram Method" (@oddblockstudios, 61 s)
![[2026-11-16 Watch4 - v2 exploded diagram sheet.jpg]]

- **Hook (0–4 s):** a talking head with the overlay "Exploded Diagram Method (how we build our roblox game's 3d models)" and Claude/Cursor/Blender logos. First line: "a method I call the exploded diagram method that allows me to get perfect one to one 3D models using Claude Code."
- **Structure:** 8 cuts in 61 s (one every ~7.6 s, a calm tutorial pace). The beats are:
  1. OpenRouter key (9–30 s). One key reaches every image model (Nano Banana 2, GPT Image 2, Gemini 3.8 Flash), so you need no separate ChatGPT account.
  2. The agent makes **exploded-view reference images**. The example is a "GOBBLE RAIL - EXPLODED VIEW" turkey-gun sheet with every part pulled apart and labelled (30–45 s).
  3. The Blender render, with shooting effects (45–50 s).
  4. The in-game result in their game "Spirit of Fish", a boss fight "CLAWDIUS" (50–58 s).
  5. "In total this took me about 20 minutes."
- **Why it works:** a named method (ownable, searchable), a concrete before/after, and a time claim. A 7.6% save rate.
- **What's new for us:** our [[Skills/roblox-3d-model-from-sheet/SKILL|3D-from-sheet]] skill uses turnaround sheets (front/side/back). For **hard-surface props made of parts** (guns, tools, vehicles, machines), an **exploded diagram** is better:
  - every piece is shown separately, at its true shape, with no overlap to guess through;
  - each part becomes one Blender object (or one Roblox part/MeshPart), placed back along the explosion axis;
  - the labels give the part names, which become the Blender object names.

  Added to the skill as step 1c.
- **Not adopted:** the OpenRouter API key. The owner's rule is that Claude never enters keys or spends credits. Our image route stays ChatGPT in Chrome (art pipeline). If the owner wants OpenRouter, the owner sets the key up.

## v3: Roll a Ball RNG, transcendent reveal (@usaaa804, 25 s)
![[2026-11-16 Watch4 - v3 Roll a Ball RNG reveal grid.jpg]]

- **Hook (0–2 s):** an avatar with a purple "???" orb over its head (the roll is in progress) and the overlay "OPUS 5.5 + BLENDER + VFX STUDIO".
- **Structure:** 6 cuts. A **ladder of reveals that escalates**:
  1. **LEGENDARY:** a gold starburst.
  2. **RADIANT.**
  3. **SECRET:** a red starburst in a ring, on a black/magenta background.
  4. **TRANSCENDENT:** blue/green starbursts.
  5. The final roll becomes a **cutscene**:
     - the world swaps to a heaven gate (gold rings, wings, clouds, pillars);
     - a serif subtitle: "Every roll you ever made led here." then "Nothing comes after this.";
     - a white flash;
     - the title card "TRANSCENDENT / [ THE LEGENDARY WARRIOR ] / SUPER WARRIOR BALL / 1 in 1,000x".
- **Audio:** "son original" by misako_edit (an edit song; cuts land on its hits).
- **Why it works:**
  - Each tier adds **one more** layer: colour → burst → background swap → flash → full cutscene. The viewer feels the climb.
  - The top tier breaks the format (a new location plus story text), which is the payoff.
  - The odds line ("1 in 1,000x") makes it a brag.
- **For us:** any game with rolls or eggs (GYM ARC, Galaxy Incremental, MEGA BITE evolutions) can:
  - escalate on one axis per tier;
  - hide the HUD during the reveal;
  - give the rarest tier its own cutscene and one line of text;
  - end on a title card with name + [ subtitle ] + odds.

  Built as `VFXKit.Tiers` / `VFXKit.reveal` / `VFXKit.titleCard` (tested).

## v4: "10 Niche Design Hacks" (@charles.unemployed, 48 s)
![[2026-11-16 Watch4 - v4 design hacks sheet.jpg]]

- **Hook:** a talking head plus a visual for each tip, one tip about every 4.5 s. The caption repeats all 10 as a copy-paste prompt "for your AI agent" (a big save driver: 6.0%).
- **The 10 tips (web CSS) → what each means in Roblox** (tested 16 Nov in Studio Play, screenshot below):

| Web tip | Roblox version | Tested |
|---|---|---|
| Nested radius: inner = outer − padding | Same with UICorner: inner CornerRadius = outer − the gap (UIPadding). Our skill had "− outline thickness", which is only right when there's no gap. Fixed. | by rule |
| Alpha borders instead of solid hex | UIStroke white or black at Transparency 0.85–0.9 (clean/dark styles) blends into any plate. Kid style keeps its ink outline. | ✅ F |
| Build palettes in OKLCH, not HSL | No OKLCH in Roblox: use the `oklch(L,C,h)` → Color3 helper (in VFXKit and the UI skill). Rarity colours at equal L read equally bright. | ✅ D |
| Gradients "in oklch" so the middle isn't grey | UIGradient blends in sRGB: blue→orange goes grey-mauve in the middle (147,115,137). Use 5–9 keypoints computed in OKLCH and it stays vivid (222,74,180). | ✅ A vs B |
| Icon stroke = text weight | Drawn icons (bars/frames): bar thickness ≈ the text's stroke weight (Bold 18 px ≈ 2.5–3 px bars). | by rule |
| Carousel edge fade with a mask | Put the ScrollingFrame inside a CanvasGroup with a UIGradient Transparency (1 → 0 at 0.15 → 0 at 0.85 → 1). Works. | ✅ C |
| Blur the outgoing icon on swap | Roblox UI has no blur. Do a fade + scale 1 → 0.8 out, then 0.8 → 1 in (0.12–0.15 s each), crossfaded. | by rule |
| Dark mode: lighter surfaces for depth | Shadows barely show on dark plates. Each raised level gets a lighter surface (+0.04 OKLCH L per level). | by rule |
| 100dvh, not 100vh | Size from the ScreenGui's AbsoluteSize (inset-aware), not Camera.ViewportSize. | already in skill |
| Multiply blend for white product shots | No blend modes in Roblox UI: cut the white out in the art pipeline (transparent PNG) before uploading. | by rule |

![[2026-11-16 Watch4 - roblox design tests.jpg]]

**Also confirmed in the same test:** a UIGradient on a TextLabel tints the **text too**, not only the background (row E). This matches the bug we hit on the MM Buy All button.

---

## Shared patterns across the batch
- **Length:** 8–61 s (mean 36 s). The two VFX/spectacle videos are short (8 s, 25 s) and get the views. The two how-to videos are long (48 s, 61 s) and get the saves.
- **Hooks:** a claim caption on the first frame, in all 4. Two are "Claude/Opus + tool" claims: AI-for-Roblox is a hot hook right now.
- **Cut pace:**
  - VFX: one continuous take (v1); hard cuts on the music (v3).
  - Tutorials: about one cut every 5–8 s.
- **Music:** original/edit sounds on the spectacle videos; voice only on the tutorials.
- **Studio UI left visible** in v1 and v3, which works as proof it's real.

## What we built from this (16 Nov)
- **New skill `roblox-vfx-reveal`:** `scripts/VFXKit.luau` (impact frame, shake, FOV punch, flash, shockwave, starburst, debris, title card, tier ladder, reveal). Tested in MM Outfit Catalog Play (Client). Nothing saved to the place.

![[2026-11-16 Watch4 - VFXKit red impact + legendary card.jpg]]
![[2026-11-16 Watch4 - VFXKit white impact.jpg]]

- **Known limits of the kit:**
  - the shockwave is a filled disc, not a ring;
  - starburst spikes are lit by the scene, so an impact-frame tint colours them too;
  - no flipbook/texture effects yet (those come from the art pipeline).

## Video idea for our games
An 8-second Studio capture: a roll → the tier ladder → a TRANSCENDENT title card, with a caption like "Claude made our RNG reveal". It copies the format of v1 and v3, not their content.
