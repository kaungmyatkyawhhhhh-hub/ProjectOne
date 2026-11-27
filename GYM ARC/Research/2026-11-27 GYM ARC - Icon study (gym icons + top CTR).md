---
tags: [gym-arc, icon, research]
date: 2026-11-27
---
# GYM ARC: icon study (gym icons + top-chart icons)

**Why:** the owner rejected two icon rounds (Gemini only, then ChatGPT → Gemini) and said the reference image and the prompt were the problem. This is icons only, not thumbnails.

**Sheets (live, 27 Nov 2026, from the public thumbnails API):**
- `icon_study_2026-11-27/icons_gym_genre.png`: 20 gym games sorted by players.
- `icon_study_2026-11-27/icons_top_charts.png`: 21 icons from Top Playing Now, Trending and Up-and-Coming.
- Scripts: `make_sheet.py` (sheet), `measure.py` (64 px numbers).

## What the public sources say (thin evidence)
- Roblox docs: 512x512 square, sharp; it shows at about 150 px, so check it there; show the theme and genre through colour and contrast; avoid small ambiguous symbols in corners. No rule on text, crop or faces. ([Icons docs](https://create.roblox.com/docs/production/publishing/experience-icons))
- DevForum guide (one creator, 2022): a warm low-contrast icon disappeared on the light Discover page; quoted CTR benchmarks: about 1% decent, 1.5–2% good. ([guide](https://devforum.roblox.com/t/creating-a-proper-roblox-icon-a-guide-based-on-my-preliminary-research/1774810))
- RoWatcher (vendor blog, unsourced numbers): one face front and centre with readable emotion (shock, joy) beats neutral; one dominant subject; show the fantasy, not the title; test one change for at least 7 days. ([article](https://rowatcher.com/news/your-roblox-game-icon-is-losing-you-players-before-they-click))
- There is no public controlled icon CTR data. The best evidence is what the top games actually run, so most of this note comes from the two sheets.

## Measured at 64 px (gym median vs ours)
| | mean luminance | near-black | near-white | saturation |
|---|---|---|---|---|
| Gym icons, median of 19 | **0.51** | **11%** | 5% | 0.62 |
| Our rejected v2 icons | 0.34 | 33% | 4% | 0.61–0.65 |
| Our old icon | 0.37 | 32% | 3% | 0.77 |

**Our icons are far darker than the genre.** Only Gym League (0.31) and Power Lifters (0.36) are as dark, and they are mid-chart. The skill's "40–50% near-black, luminance 0.28" target came from dark monster thumbnails; it is wrong for a bright, kid gym icon.

## Patterns in the gym icons that win
1. **One big character, waist-up or closer, filling 70–90% of the frame.** The head is in the top half and big. Gym Star, Gym Universe, Muscle Parade, Strongman Sim.
2. **A face that reads at 60 px with a clear emotion:** a wide grin, a shout or shock (Gym Star, Muscle Transform "AGHHH!!!", Power Grid). Neutral faces are rare at the top.
3. **Bright, saturated, simple background:** sky blue, red, orange or a lit gym, softly blurred. Hardly any dark navy.
4. **The hook drawn as a before → after:** Muscle Legends "WEAK → STRONG" (small noob next to a giant), 1 Muscle "skeleton → muscled" with lock icons, Gym Evolution blue vs red. That is the clearest way to show a growth game.
5. **Text is rare and huge:** one or two words ("STRONG", "UPD!", "OFFLINE STRENGTH") or "+1" / "+100" stickers. Never small text.
6. **Seasonal = the same character, swapped props and background.** Arm Wrestle (turkey vs chef), 1 Arm Length (turkey + pumpkins + autumn leaves), Gym League (Thanksgiving feast). The tag goes in the title ("[HARVEST FEST]"), and the icon keeps its usual layout so returning players still recognise it.
7. **The Roblox avatar looks like a cartoon toy:** clean plastic shading, big simple shapes, crisp outline, a bright white key light on the face. No painterly texture, no grime.

## Top-chart icons (all genres)
- Big brands use the logo as the icon (Brookhaven, Adopt Me, Blox Fruits, MM2). New games show **one idea in one object** at huge size (Throw a Seed's tree, Dig Deep's drill, the Ragdoll ice face).
- Every one of them reads at 60 px as one shape on a plain or lightly blurred background.
- Seasonal tie-ins are everywhere this week (turkeys in Steal An Egg, Throw Food For Animals and Arm Wrestle).

## Why our two rejected rounds failed
- **The reference was wrong.** The 4'0" → 7'0" render puts two full-body avatars small in a wide frame, with hair over the eyes and a tiny ":3" mouth. No face could carry emotion, so the AI copied small figures with no expression.
- **Dark navy background:** 33% near-black, against a genre median of 11%.
- **The hook didn't read at 60 px:** two small figures plus gold arms read as a gold blob.
- **The logo covered the lower third.**

## Rules for the new GYM ARC icons
- Layout: the **giant 7'0" version, waist-up, fills the right 2/3**, its head big in the upper half, with a proud open grin and a flex. The **small 4'0" version** sits bottom-left, looking up in shock. That is the Muscle Legends "weak → strong" pattern, done with height, which is our hook.
- Bright background: a lit, softly blurred gym in sky blue and white, and gold. Target at 64 px: luminance 0.45–0.55, near-black ≤ 15%.
- Keep the real avatar's look (black messy hair, white shirt, grey shorts, gold muscles) but show the eyes and mouth, so the face can carry emotion.
- One big gold "7'0"" number at most. The logo goes in code, in the top-left zone the layout leaves empty, at a readable size.
- Christmas: the **same layout**, with props and background swapped: snow falling, warm string lights, a candy-cane barbell, presents, red and green with gold. No Santa hat on the avatar (the owner picks clothing).
- Reference image: a **layout mock built from our real avatar** at the exact positions and sizes, on the bright background, not a finished thumbnail.
