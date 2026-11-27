---
tags: [gym-arc, icon]
date: 2026-11-27
---
# GYM ARC: new icons (normal + Christmas)

**Why:** the owner's current icon (a tanned bodybuilder with a 1000 LB dumbbell) looks almost like Power Lifters. Its logo is hard to read, it's busy, it doesn't show our hook (growing), and it isn't seasonal.

**How they were made:**
- Gemini drew the art; the logo was added in code (`Assets/icon_2026-11-27/compose_icons.py`).
- The real avatar came from `HallOfFame launch art/GYMARC_thumb_4ft_to_7ft.jpg`.

**The two icons:**
- **Normal, `gymarc_icon_normal_logo.png`:** the small avatar looks up, amazed, at his own huge golden future self flexing behind him, with a height ruler beside them. Blue and cyan against gold.
- **Christmas, `gymarc_icon_xmas_logo.png`** (for 5 Dec): the same avatar, huge, in a Santa hat, lifts the giant red Mega Gift overhead in the snow at night with string lights.
  - The first try had four arms (a small body in front of giant arms behind). I asked Gemini for one body with two arms and it fixed it (`raw2`).

**The logo:** `gymarc_logo_v10_blue_simple`, 44% wide, bottom-left, on a dark fade. Centred, it covered both faces.

**Size test:** `icon_size_test.png` shows both icons next to the real competitor icons (from the owner's Continue row) at 150, 100 and 60 px.

**Numbers at 64 px:**

| Icon | Near-white | Near-black | Mean luminance |
|---|---|---|---|
| Normal | 6.7% | 42.6% | 0.35 |
| Christmas | 2.8% | 42.4% | 0.30 |
| Old icon | 2.5% | 39.3% | 0.33 |

- Darkness is on target.
- Near-white is below the 10-15% guide, because the faces are small.

**Not done:** uploading. That's the owner's job: Creator Dashboard > Places > Thumbnails / Icon. Swap to the Christmas icon on 5 Dec and back after 7 Jan.

## v2 (two passes, owner: v1 "look very bad")
- ChatGPT enhanced each draft (`*_gpt.png`), then Gemini made it look less AI-made and enhanced it again (`*_final_art.png`). The logo is added in code, as before.
- The Christmas Gemini pass was first sent the normal image by mistake; I resent it with the right file.
- At 64 px: normal is 3.8% near-white and 32.3% near-black; Christmas is 3.1% and 35.8%.

## v3 (after the icon study, 27 Nov 2026)
Study: [[2026-11-27 GYM ARC - Icon study (gym icons + top CTR)]]. Files in `Assets/icon_2026-11-27/v3/`.
- Reference: `layout_mock_normal.png`, our real avatar cut from the 4'0" -> 7'0" render and placed at the icon layout (giant waist-up right, small kid bottom-left, empty logo zone top-left, bright blue).
- ChatGPT pass (`*_gpt.png`) with the prompt in `prompts.md`, Christmas in the same chat; Gemini de-AI pass (`*_final_art.png`); code grade (`grade_v3.py`: background deeper and more saturated, characters kept); logo top-left at 50% width (`compose_v3.py`).
- Finals: `gymarc_v3_normal_logo(_512).png`, `gymarc_v3_xmas_logo(_512).png`. Size test: `icon_size_test_v3.png`.
- 64 px: normal lum 0.52 / 4% dark, Christmas 0.53 / 4% dark (gym median 0.51 / 11%). v2 was 0.34 / 33%.
- Known weak spot: at 60 px the Christmas cue (tree, presents) is small; the two icons look alike at a glance.

## v4 (owner on v3: "way better but other game icons still look better")
- Gap, measured against the top 5 gym icons (`v3/compare_v3_vs_top.png`): head 18% of the width vs 34-37%, character saturation half theirs, flat light, three things to read (giant, tiny kid, logo).
- Fix (same ChatGPT chat, comparison sheet attached): waist-up, head ~35%, double-biceps flex filling both edges, eyes to camera, hard warm key + cyan rim, royal-blue radial background, height ruler on the right edge, no small kid. Christmas: festive red, snow, string lights, candy-cane ruler.
- Gemini pass on the normal one only (Gemini's image limit was hit until 1:28 PM; ChatGPT's Christmas one was already clean).
- Logo top-left at 40% width. Files: `Assets/icon_2026-11-27/v4/gymarc_v4_*_logo(_512).png`, size test `icon_size_test_v4.png`. 64 px: normal lum 0.49 / 9% dark, Christmas 0.50 / 16% dark (gym median 0.51 / 11%).

## v5 (owner on v4: "our character's build look ugly because its not aesthetic" + "study about bodybuilding aesthetics first")
- Study: [[2026-11-27 GYM ARC - Bodybuilding aesthetics study (for character art)]].
- Reference: `v5/proportion_guide.png` (shoulders 3 heads, waist half the shoulders, biceps about head-sized) + the v4 art for identity. One follow-up narrowed the waist (the V was only 1.36 : 1).
- Front double biceps, mid-thigh crop, fitted white tee, sculpted gold arms, same blue / festive-red backgrounds and ruler. ChatGPT then Gemini for both; logo top-left at 36%.
- Files: `v5/gymarc_v5_*_logo(_512).png`, `v5/icon_size_test_v5.png`. 64 px: normal lum 0.43 / 5% dark, Christmas 0.41 / 23% dark.

## v6 (27 Nov, after "arms and waist too small" + "build should look robust")
- ChatGPT edit of the v5 art in a new chat. Two builds, normal only so far, files in `Assets/icon_2026-11-27/v6/`:
  - **v6a aesthetic**: natural waist about 2/3 of the shoulders with obliques, biceps about head-wide (`gymarc_v6a_aesthetic_normal_logo.png`).
  - **v6b robust**: the same, plus a thick neck, wider deeper torso, heavier shoulders and thighs (`gymarc_v6b_robust_normal_logo.png`).
- Gemini's pass turned the gold arms into skin, so it was dropped; ChatGPT art is used as is.
- 64 px: lum 0.43–0.44, near-black 4–5%. Size test: `icon_size_test_v6.png`.
- Next: the owner picks a build, then the Christmas version in the same ChatGPT chat.

## v7 (27 Nov, live owner notes while iterating)
Owner notes, in order:
- picked the aesthetic build, with bigger legs;
- "the icon dont make much sense";
- legs and arms must be the same skin;
- the Muscle Legends small-vs-giant layout is "sloppy, i want professionalism";
- "focused like 30% character, 30% logo, 30% background, which is bad";
- one skin tone that suits the colours;
- the torso looked short, so he looked fat.

Steps in `Assets/icon_2026-11-27/v7/`:
- `gymarc_v7_normal_gpt.png`: small kid vs giant (rejected as sloppy).
- `v7b`: single full-body hero (face too small).
- `v7c`: knee-up hero.
- `v7d`: waist-up close-up with gold arms.
- **`v7e`, current**: waist-up, character about 80% of the frame, one warm tan skin, long torso with a V-taper, small logo (28%), blurred blue background, a thin ruler with a gold head mark. Logo version: `gymarc_v7e_normal_logo.png`; size test: `gymarc_v7e_normal_logo_sizetest.png`.
- 64 px: lum 0.44, near-black 5%.
- `compose_v7.py <art> <out> [logo_frac]` uses the cached `ref_icons/`.
- Christmas comes next, from v7e, after the owner's OK.

## v7f (27 Nov, owner: "looks bad. just try to have gym star's character physique")
- Attached `v7/ref_icons/Gym_Star_512.png` as a physique-only reference. Output: `v7/gymarc_v7f_gymstar_build_gpt.png`, logo: `gymarc_v7f_normal_logo.png`. 64 px: lum 0.46, near-black 8%.

## v7g / v7h (27 Nov, owner: "the obliques, waist should look like the guy on the right", from a transformation photo)
- The photo was not uploaded anywhere. The waist was described in words: wide lats, a narrow tight waist, carved obliques into a V-cut, serratus.
- `v7g_shirtless`: the waist and V-cut read clearly. `v7h_tee`: the tight tee hides most of the taper.
- The owner picks the clothing.
