---
date: 2026-11-13
tags: [galaxy, icon, thumbnails, chatgpt, decision]
---
# Galaxy Incremental: new icon + thumbnails v2 (13 Nov, night autopilot)

Owner (12 Nov, 23:56): "lets fix galaxy incremental thumbnail and icons first, they suck so much rn".
Followed: [[2026-11-05 PLAYBOOK - Roblox icon, thumbnail and logo recipe]] and the skill roblox-icon-thumbnail. ChatGPT chat: **"Create Space Roblox Icon"** (owner's ChatGPT).

## Why the old set sucked (measured, recipe grade tests)
| Old file | Mean (target 0.25-0.32) | Near-black at small size (target 40-50%) | Main hues (target 2) |
|---|---|---|---|
| galaxy_icon_512 | **0.46** (washed out) | **29%** | **5** |
| thumb1 before/after | 0.39 | 37% | 3 |
| thumb2 reward 1.2Qa/s | 0.41 | 33% | 4 |
| thumb3 supernova | **0.52** | **23%** | 3 |
| thumb4 black hole | 0.34 | 45% | 4 |
- The old icon IS the "left" icon from the 9 Nov test: the one that got ~23x fewer clicks. It shows a bright bacon on a bright rainbow starburst, with no story and no dark.

## Reference check (live top incrementals, 13 Nov)
- The biggest new games show bacon + a story, in one colour family:
  - Depth (20k) and Cut a Rock (16k): the action plus the reward;
  - +1 Venom (24k): a split-face transformation;
  - Tap REBORN (41k): a big creature.
- Letter icons ("NI" Noob Incremental 5k, "RI" Regrowth 2.5k) belong to older games whose fans know the letters. A new game needs the hook.
- **Owner asked whether we need a "GI" letter logo icon like Regrowth/Noob → no for the main icon. A "GI" icon could be a cheap third A/B option later.**

## New set (in the owner's Downloads → move to `Celestial Incremental/Assets/thumbs/v2/`)
| File | What | Grade (mean / black / white / corners / hues) | Verdict |
|---|---|---|---|
| galaxy_icon_v2_A_splitface.png | The GYM ARC 23x-winner composition: left = normal bright bacon, right = bacon turned into a living galaxy (black starry skin, violet nebula, blazing white star eye, cyan crack edge). Face brightened in code (face mask +55% toward white) | 0.22 / 64% / 8.2% / 0.017 / violet + cyan | **USE: main icon** |
| galaxy_icon_v2_B_planet.png | Bacon holding a tiny planet about to go supernova | 0.27 / 52% / 6.3% / 0.006 | Backup only: the face came out pink and the story is weaker |
| galaxy_thumb_v2_1_supernova_1-2Qa.png | Bacon dives at the camera, his island + a star going supernova behind him, huge "1.2Qa/s" (the ad creative that scaled best) | 0.30 / 56% / 13.9% / 0.018 / one violet family 81% | **USE: thumbnail 1** (no logo: the number fills the top) |
| galaxy_thumb_v2_2_blackhole.png | Bacon clings to his island's edge while a black hole (cyan ring) sucks in planets, "???" | 0.26 / 61% / 9.5% / 0.05 | **USE: thumbnail 2** (logo top-left optional) |

## Still to do
1. **Owner:** move the 4 files from Downloads into the vault folder above. Or connect the Downloads folder in the Claude app so Claude can do it.
2. Upload: Creator Dashboard > Galaxy > Places > Thumbnails.
   - Icon = A.
   - Home page: thumbnails 1 + 2, plus keep the old "1.2Qa/s" one 2-3 days as a baseline.
   - Then judge by click rate in the ads / the experience page.
3. Next thumbnails, same chat, "same exact style":
   - #3 your island built up with pads (before → after);
   - #4 the Forge roll.
   (Growth plan order.)
4. Ads: run the new icon A against the old icon for 5,000 impressions each. Judge on cost per PLAY, not click rate.

## Prompts used (same chat, one try each)
- Icon A: the recipe icon template + "Image 2 is my best-performing icon (GYM ARC icon_chatgpt_v6_pink): copy its composition EXACTLY, only the theme changes to SPACE". Attachments:
  - `GYM ARC/Assets/thumbs_nov/bacon_real_v1.png`;
  - `icon_chatgpt_v6_pink.png`.
- Then icon B, thumb 1 and thumb 2, all as follow-ups with "same exact style, grade and darkness". The full text is in the chat.
