# Break A Bed: Content Plan

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

**Problem (owner, 2026-10-13):** the average player finishes the game (all 25 beds) in about **30 minutes**, and then there's nothing left to do. The 17 training posts also all look alike (stacked cylinders in different colors).

**Goal:** a first finish takes about **2–3 hours** over several sessions, and rebirths add many more hours on top. Minutes 0–10 stay fast (see [[Break A Bed/Charts Plan|Charts Plan]]). Only the later game gets longer, and always with something new to chase, never just bigger numbers.

## 1. Unique training posts
Every post gets its own model, punch effect and sound, so each new post feels like a reward. Use each post's name as its theme, with the [[Break A Bed/UI Kit/UI Kit|UI Kit]] colors and chunky low-poly parts. The posts get bigger and fancier toward the end of the row.

| Theme in the name | Look | Punch effect |
|---|---|---|
| Straw | hay bale tied with rope on a stick | straw bits fly off |
| Wooden | a wooden training dummy with arms (wing chun style) | wood chips |
| Bamboo | a bundle of bamboo stalks with a red cloth band | green leaves |
| Brick | a short brick pillar with a cracked top | brick dust |
| Stone | a carved stone totem with a face | small rocks |
| Iron / metal | a heavy punching bag hanging from an iron frame | the bag swings + metal clang |
| Gold | a gold punching bag with a crown on the frame | gold coins pop out |
| Gems (Emerald, Ruby, Sapphire, Diamond…) | a floating crystal cluster in that gem color, slowly spinning | crystal shards + sparkle |
| Ice / frost | an ice pillar with a frost mist | snowflakes + frost ring |
| Fire / lava | a lava rock with glowing cracks and drips | embers + small fire burst |
| Electric / thunder | a tesla coil with arcs | lightning spark |
| Galaxy / cosmic | a floating planet with a ring and orbiting stars | star burst |
| Void / dark | a black orb with a purple swirl | purple shockwave |
| Rainbow / infinity (last post) | a big glowing rainbow crystal on a gold base | rainbow ring + screen flash |

- Names that don't fit a theme: Claude Code picks a fitting look and adds it to this table.
- Every post keeps its glowing pad, sign, price, ProximityPrompt and name, and only the model changes. The effects are client-side and pooled, using the same no-lag rules as bed breaks.
- Phones with Low Graphics: smaller effects, no extra lights.

## 2. Rebirths (the main replay loop)
- **Unlocked** after breaking bed 15 the first time. A gold **REBIRTH** button appears on the left (under Boosts) with a "!" when it's ready.
- **Cost:** reaching a Strength goal (rebirth 1 = the bed 15 requirement, then ×3 each rebirth). It's shown in the menu with a progress bar.
- **Resets:** Cash, Strength, beds completed, posts owned. **Keeps:** auras, passes, codes, gifts, Level, daily streak.
- **Gives, forever:** **+50% Strength and +25% Cash per rebirth** (stacking), plus **1 Rebirth Token** each time.
- **Rebirth Token shop** (inside the rebirth menu): permanent upgrades, like start with $1K, +1 auto-punch speed, posts 10% cheaper, +5% crit chance and +1 free Spin a day. Each costs 1–3 tokens.
- **Shows off:** the rebirth count on the leaderboard and over the head ("⟳ 3"), with a new name-tag color at 1/5/10/25.
- **Menu:** UI Kit dark window, rainbow title "REBIRTH". It has a "You lose / You keep / You get" layout and a big gold REBIRTH button with a confirm step, then a white flash, rays and a fanfare.
- Rebirth also replays the bed path fast (the multiplier makes the early beds instant), so the second run takes about 15–20 min and the later ones get longer.

## 3. Gloves (a second thing to buy with Cash)
- 12 gloves bought with Cash at a **Glove Shop** stand by the training area: Boxing → Wooden → Spiked → Iron → Gold → Ice → Fire → Thunder → Emerald → Galaxy → Void → Infinity.
- Each one **multiplies all Strength from punching** (x1.5, x2, x3… up to about x50). They're priced so each takes 3–8 minutes of play at that stage, and they're spread between the post prices so there's always something to buy.
- The equipped glove shows on both hands and changes the punch effect color. Owned gloves are saved.

## 4. Bed Mastery (a reason to re-break beds)
- Each bed has **3 mastery stars**: break it 10 / 50 / 200 times.
- Each star = **+5% Cash forever** from that bed, plus a one-time Cash reward. The stars show on the bed's sign and in an **Index** menu (all beds, stars, best time).
- "Master all 25 beds" is a long goal with a special title and aura reward.

## 5. World 2 (next week's update)
- A second path of 15 beds past the Infinity Bed (a Halloween/haunted theme while October lasts, e.g. Coffin Bed, Haunted Bed, Pumpkin Bed…), unlocked at **Rebirth 1**.
- It comes with 6 new posts and gloves. Announce it with a group shout and a new code.

## Pacing targets (check after building)
- First 10 minutes: unchanged (new thing every 45–75 s).
- Beds 10–15: about 3–5 min each.
- Beds 16–25: about 6–10 min each, with gloves and posts filling the gaps.
- First rebirth: about 60–90 min in.
- Claude Code measures this with a fresh-save test bot and writes the real times here.

## Build order
1. Unique posts + Gloves + the late-game pacing retune (one update).
2. Rebirths + the token shop (next).
3. Bed Mastery + Index.
4. World 2 (weekly update).
