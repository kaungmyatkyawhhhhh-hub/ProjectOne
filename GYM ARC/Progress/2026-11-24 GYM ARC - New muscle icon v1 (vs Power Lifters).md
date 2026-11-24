---
date: 2026-11-24
tags: [gymarc, icon, thumbnails, chatgpt]
---
# GYM ARC: new "muscle bacon" icon v1 (24 Nov)

Owner: "is it because of the icon", then "power lifters icon is very good, how do we change".

## What the live icon actually shows (looked at, 24 Nov)
A yellow Roblox guy with dark messy hair and a sleepy/flat face, in a black tank top, golden lightning covering his arm, a bright purple Greek temple with purple lightning, and the GYM ARC logo top-left. No weight, muscles hidden, face not the bright focus.

## The numbers
Measured on the crop from the owner's screenshot, contrast at 64 px:

| Icon | Mean | Near-black | Near-white | Clipped |
|---|---|---|---|---|
| Power Lifters | 0.34 | 37.8% | 2.3% | 18.9% |
| GYM ARC live | **0.47** | 29.2% | 5.7% | **36.6%** |
| **New v1** | 0.34 | 38.4% | 6.2% | 25.1% |

The live icon has the washed-out profile of the old galaxy icon that got 23x fewer clicks.

## New v1
- ChatGPT, one try. Attached:
  - `bacon_real_v1.png`;
  - `refs/ref_powerlifters_icon.png` (quality/clarity ref only);
  - `icon_chatgpt_v6_pink.png` (our 23x winner, colour family).
- Result:
  - the classic Bacon Hair head, white face, smile;
  - a huge shirtless blocky-plastic bodybuilder (8-pack, giant arms);
  - a knurled steel barbell, a gigantic glowing hot-pink crystal plate filling the lower left;
  - a dark gym, pink glow; no text.
- 1254x1254. Saved by Chrome to the owner's **Downloads\gymarc_icon_muscle_v1.png**. Claude was not allowed to read Downloads, so the owner moves it to `GYM ARC\Assets\thumbs_nov\`.
- In a mock of the real Roblox row (from the owner's screenshot) it reads as a gym game at row size.
- **Risk:** the composition (bodybuilder + giant plate on the left) is close to Power Lifters'. The Bacon head and pink keep it ours, but a v2 could move the plate or change the pose if it reads as a copy.
- Chat: chatgpt.com/c/6b056324-09e8-83ec-8676-3c2c3afa666a (follow-ups "same exact style").

## Prompt (one try)
Square 1024 icon, Roblox Blender GFX. Image 1 = my character's head exactly. Image 2 = quality ref only, don't copy. Image 3 = my best icon, match its hot pink + near-black. HUGE shirtless Roblox bodybuilder, waist up, low camera, leaning in. Rigid knurled barbell in both hands, mid-lift. One gigantic glowing hot-pink crystal plate with a dark steel rim filling the lower-left quarter. Face pure white key light, the brightest thing. Pink rim light. Dark gym, pink glow behind the head, near-black corners. Sparks only around the plate. 8% margins. No text or logo. Must read at 60 px.

## v2 "violet overhead" (owner: "the powerlifter icon color scheme and the gradients are so good too, but dont copy exactly")
- Same chat, one try.
- **Colour (Power Lifters' idea, our own colours):**
  - warm glossy golden-tan skin;
  - a smooth gradient from deep indigo corners to electric violet behind him;
  - violet rim light, hot-pink crystal plates as the only accent.
- **Layout (not theirs):**
  - front view, a giant barbell locked out OVERHEAD;
  - the two plates cut off by the top corners;
  - the head and a huge chest/abs in the middle.
- **Measured at 64 px:** mean 0.32, near-black 43.6%, near-white 4.1%, clipped 20.7%. Passes the grade.
- The face is small, so white% is low. A v3 could push in closer.
- In the real row mock it looks clearly different from Power Lifters (v1 looked like its layout).
- **Pick: v2.**
- File: owner's Downloads\gymarc_icon_muscle_v2_violet.png. Move it to thumbs_nov.

## Owner: "i dont like both of them, think with an artist's brain"
**Artist critique of v1/v2:**
- The flat classic smile on a straining body reads as a meme or pool toy.
- The muscles are inflated balloons with a glossy all-over sheen (the AI look).
- Static frontal, symmetrical poses.
- No story (the 23x winner asked "what does he become?").
- Flat front light, with a sticker-like rim on everything.

**Concept sheet** (new chat chatgpt.com/c/6b05653d-7634-83ec-a2f8-76b1a5d3ca7c, one try; Downloads\gymarc_icon_concepts_ABC.png). Asked for: one idea per icon, asymmetry and a diagonal, one directional key light, an emotional face, satin skin, Power Lifters' warm-vs-cool colour idea.
- **A, the shadow:** skinny bacon in a grey tee, gritted teeth, a small dumbbell, a warm spotlight; on the violet wall his shadow is a giant flexing titan with pink eyes. The best story, but at 60 px the shadow goes murky.
- **B, the lift:** a low 3/4 view of a huge bacon mid-deadlift, an effort face (squeezed eyes, gritted teeth, an anger vein), pink plates, the floor cracking pink. The most energy; the clearest gym read at 60 px.
- **C, before/after:** a nervous skinny bacon (sweat) and a smirking titan with a glowing eye, split by a diagonal pink crack. The clear hook, but it reads as 2 people, not one head.
- Claude leans **B**, or **B with A's idea** (the deadlift with the titan shadow behind). Waiting for the owner's pick, then a full-size polish + grade + 60 px test.

## FINAL: deadlift + titan shadow (owner: "this is way better")
- Same chat, one try.
- **The picture:**
  - huge Bacon Hair mid-deadlift, low 3/4 camera, effort face (squeezed eyes, gritted teeth, anger vein, sweat);
  - a bent barbell, giant hot-pink plates, the floor cracking with pink energy;
  - behind him on the violet brick wall, his shadow is a giant flexing titan with glowing pink eyes;
  - a warm spotlight from the top left; indigo corners.
- **Grade:**
  - raw mean 0.22 / near-black 60%;
  - in-browser lift (gamma 0.85 + soft edge falloff) gives mean 0.24 / 55.6%;
  - the body is the bright warm shape; the face is tan by design (warm-vs-cool scheme), not white.
- **In the real Roblox row mock** it reads as "strong guy deadlifting + giant shadow". Clearly ours, not Power Lifters.
- **Files** (owner's Downloads; move them to thumbs_nov):
  - `gymarc_icon_deadlift_shadow_final.png` (graded);
  - `gymarc_icon_deadlift_shadow_raw.png`;
  - `gymarc_icon_concepts_ABC.png`.
- **Next:**
  - upload it as the icon with the v1903 + v1905 publish;
  - matching thumbnails in the same chat ("same exact style", 16:9, logo top-left in code);
  - compare the click rate after 3-4 days against 3.7%.

## v4 "smirk + 1000 LB" (owner: "that one is better but power lifter one still better")
**Why Power Lifters still won:** it's SIMPLER and a POWER FANTASY.
- one cool, confident guy kids want to BE (not a pained effort face);
- one huge prop with a number that says HEAVY;
- a tight crop;
- a clean background;
- the warm orange body pops on cool purple.

The deadlift + shadow icon had too many things (shadow monster, cracks, rays) and a pained face.

**v4:**
- huge orange-tan Bacon Hair cropped at the waist, a 3/4 pose;
- a cool smirk with a raised eyebrow, looking at the viewer;
- a barbell resting across his shoulders, one hand on it;
- one giant hot-pink plate top-right with "1000 LB";
- a plain indigo→violet gradient, a violet rim.

**Measured:** mean 0.31 / near-black 42.5% at 64 px.

**Logo test in the row mock:** our detailed Japanese-style logo (v9 pink) turns into an unreadable red blob at row size and covers his hair. Power Lifters' logo works because it's 2 plain bold words. → **Use v4 WITHOUT the logo.** For a logo-on-icon later, we'd need a simple 2-word bold version.

**Files** (Downloads):
- `gymarc_icon_v4_smirk_1000lb.png` (pick)
- `gymarc_icon_v4_smirk_1000lb_logo.png`

## v5 + new logo v10 (owner: "powerlifters still look way better. i think our logo is worse than theirs too")
**Side-by-side read of Power Lifters vs v4:**
1. Their background is DARK (a dark gym, warm bokeh), so the body is the brightest thing. Ours was bright violet.
2. They use only TWO colour families: purple logo + plates + background vs the orange body. We had 3 (orange, violet, pink).
3. A full powerful pose (head to knees, wide stance) vs our cropped bust.
4. A complete, balanced weight with the number printed like a real plate vs ours cut off.
5. Their logo is 2 bold slanted words, 2 colours, a thin glow frame, readable at any size. Ours (manga style: sparks, barbell, katakana) is noise when small.

**New logo v10** (chat chatgpt.com/c/6b057956-4624-83ec-9227-9a950aca2d13, one try, green-key background keyed in the browser):
- "GYM" in white-silver chrome over a bigger "ARC" in electric-blue chrome;
- heavy forward-slanted block letters, a thick black outline, a thin cyan glow;
- readable at 70 px.
- File: Downloads\gymarc_logo_v10_blue_simple.png (transparent).

**Icon v5** (same chat, one try). Our own colour pair: orange's opposite, BLUE.
- a dark navy gym with warm bokeh, a blue rim;
- the Bacon Hair head with a cool sideways smirk;
- a huge orange bodybuilder head to knees, wide stance;
- curling a giant blue chrome dumbbell printed "1000 LB";
- black shorts.

Logo in code at 42% width, top-left (clear of the dumbbell). At 64 px: mean 0.30, near-black 50%. Next to Power Lifters in the row mock it holds up and is clearly a different game (blue vs purple).

**Files** (Downloads):
- `gymarc_icon_v5_blue_dumbbell_logo.png` (pick)
- `gymarc_icon_v5_blue_dumbbell_nologo.png`

**If chosen:** the brand moves to the blue logo. Thumbnails and the in-game logo should follow later.

## 12 alternatives (owner: "that icon way better but i want like 10 alternatives and i will choose the best one")
Same chat as v5, 3 one-try 2x2 sheets. The new blue logo was added in code, hue-matched to each colour.

| # | Idea |
|---|---|
| 1 | double-biceps flex, a 1000 LB dumbbell at his feet |
| 2 | one-arm overhead dumbbell press |
| 3 | barbell squat, 1000 LB plates both sides |
| 4 | farmer's walk toward the camera with two dumbbells |
| 5 | the v5 curl, emerald green |
| 6 | the v5 curl, crimson red |
| 7 | the v5 curl, magenta pink |
| 8 | the v5 curl, frost white/cyan |
| 9 | before/after: a tiny grey-tee noob looks up at his huge future self |
| 10 | close-up: smirking face + giant flexed bicep (the face came out styled, not the classic decal) |
| 11 | arm wrestling: slamming a sweating rival (the game's own feature) |
| 12 | champion: barbell overhead under a spotlight, crowd silhouettes |

- **Files** (Downloads): `gymarc_icon_choices_board.png`, `gymarc_icon_choice_01..12.png` (600 px previews). The board screenshot is in the vault.
- **After the owner picks:** a full-size render of that one, the logo placed clear of the weights, the 60 px test.
