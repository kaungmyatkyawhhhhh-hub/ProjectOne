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
