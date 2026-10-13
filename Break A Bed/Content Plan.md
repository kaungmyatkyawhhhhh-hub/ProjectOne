# Break A Bed: Content Plan

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

**Problem (owner, 2026-10-13):** the average player finishes the game (all 25 beds) in about **30 minutes**, and then there's nothing left to do. The 17 training posts also all look alike (stacked cylinders in different colors).

**Goal:** a first finish takes about **2–3 hours** over several sessions, and rebirths add many more hours on top. Minutes 0–10 stay fast (see [[Break A Bed/Charts Plan|Charts Plan]]). Only the later game gets longer, and always with something new to chase, never just bigger numbers.

## 1. Unique training posts
**Built 2026-10-13**, see [[Break A Bed/2026-10-13|2026-10-13]].
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
| Steel (added by Claude Code) | a riveted steel I-beam on a yellow/black hazard-striped base | orange sparks + steel chips, metal box clang |
| Neon (added by Claude Code) | a tower of pink and cyan neon tubes with a yellow lightning bolt sign | pink + cyan sparks and a ring, electric zap |

- Names that don't fit a theme: Claude Code picks a fitting look and adds it to this table.
- Every post keeps its glowing pad, sign, price, ProximityPrompt and name, and only the model changes. The effects are client-side and pooled, using the same no-lag rules as bed breaks.
- Phones with Low Graphics: smaller effects, no extra lights.

## 2. Rebirths (the main replay loop)
**Built 2026-10-13**, see [[Break A Bed/2026-10-13|2026-10-13]].
- **Unlocked** after breaking bed 15 the first time. A gold **REBIRTH** button appears on the left (under Boosts) with a "!" when it's ready.
- **Cost:** reaching a Strength goal (rebirth 1 = the bed 15 requirement, then ×3 each rebirth). It's shown in the menu with a progress bar.
- **Resets:** Cash, Strength, beds completed, posts owned. **Keeps:** auras, passes, codes, gifts, Level, daily streak.
- **Gives, forever:** **+50% Strength and +25% Cash per rebirth** (stacking), plus **1 Rebirth Token** each time.
- **Rebirth Token shop** (inside the rebirth menu): permanent upgrades, like start with $1K, +1 auto-punch speed, posts 10% cheaper, +5% crit chance and +1 free Spin a day. Each costs 1–3 tokens.
- **Shows off:** the rebirth count on the leaderboard and over the head ("⟳ 3"), with a new name-tag color at 1/5/10/25.
- **Menu:** UI Kit dark window, rainbow title "REBIRTH". It has a "You lose / You keep / You get" layout and a big gold REBIRTH button with a confirm step, then a white flash, rays and a fanfare.
- Rebirth also replays the bed path fast (the multiplier makes the early beds instant), so the second run takes about 15–20 min and the later ones get longer.

## 3. Gloves (a second thing to buy with Cash)
**Built 2026-10-13**, see [[Break A Bed/2026-10-13|2026-10-13]].
- 12 gloves bought with Cash at a **Glove Shop** stand by the training area: Boxing → Wooden → Spiked → Iron → Gold → Ice → Fire → Thunder → Emerald → Galaxy → Void → Infinity.
- Each one **multiplies all Strength from punching** (x1.5, x2, x3… up to about x50). They're priced so each takes 3–8 minutes of play at that stage, and they're spread between the post prices so there's always something to buy.
- The equipped glove shows on both hands and changes the punch effect color. Owned gloves are saved.

- **Glove model fix (owner, 2026-10-13):** the first build was wrong. The owner's screenshot shows huge green blobs made of stacked balls, covering the arms and chest, with bright white glow dots on them. Rules for the glove model:
  - **Shape:** a real boxing-glove shape built from a few parts: a rounded main fist (slightly egg-shaped, flatter on the palm side), a **thumb** bump on the inner side, a **cuff** (a short cylinder at the wrist in a darker or white trim color) and a thin lace/strap line. No clusters of spheres.
  - **Size:** about **1.4× the hand** (around 1.1 × 1.0 × 1.3 studs on a normal R15 avatar). It never covers the forearm, chest or face. It scales with the avatar's hand size.
  - **Fit:** welded (`WeldConstraint`/`Motor6D`) to `LeftHand`/`RightHand` (R15) or the bottom of `Left Arm`/`Right Arm` (R6), centered on the hand, knuckles facing forward, thumb up. It follows punches exactly, with no gap or offset. `CanCollide`, `CanTouch` and `CanQuery` off, `Massless` on.
  - **Look:** SmoothPlastic, or a soft shine for higher tiers. Each glove has its own color (Boxing red, Wooden brown, Spiked black with silver spikes, Iron grey, Gold, Ice light blue, Fire orange with an ember trail, Thunder yellow with sparks, Emerald green, Galaxy purple with stars, Void black with a purple glow, Infinity rainbow).
    - **Effects stay small.** No big neon balls or white dots. Higher gloves only get a soft `PointLight` or a light particle at the knuckles.
  - Hide the player's normal hand under the glove (`LocalTransparencyModifier` or a cut-off), and keep hats, hair and accessories as they are.
  - Check on R15 and R6, on a small and a big avatar, and in first person.
  - **Changed again (owner, 2026-10-13): blocky, not round.** The round glove looked like a red blob stuck under the arm. Now the glove is a **square block that fits the player's hand**, matching Roblox's blocky arms:
    - **Main block:** a `Part` (Block) sized from the player's actual hand part: hand size × about 1.15 on each side (on R6, the bottom ~0.8 stud of the arm × 1.15), so it wraps the hand exactly with a small even rim. Small rounded edges are fine (a slight bevel), but no balls.
    - **Cuff:** a thin block band at the wrist in a trim color (white or darker), the same width as the main block.
    - **Thumb:** a small block on the inner side of the fist. Optional, and only if it doesn't stick out.
    - **Fit:** the block's center sits exactly on the hand's center and turns with it. There's no gap under the arm and nothing floating below the hand.
    - Colors and the small effects stay as described above.
  - **Final look (owner, 2026-10-13, from 4 reference pictures of blocky Roblox boxing gloves):** **Built 2026-10-13** with the owner's Toolbox mesh, see [[Break A Bed/2026-10-13|2026-10-13]]. this replaces the shape rules above.
    - **Size and place:** the glove covers the **hand and the bottom ~40% of the arm** and is about **1.25× the arm's width and depth**. It's chunky and clearly bigger than the arm, like a real boxing glove on a blocky avatar. The top edge of the cuff is flat and straight.
    - **Shape:** a **cube-like fist with soft rounded edges and slightly puffy sides** (padded, not a sharp brick). There's a padded knuckle bump at the front and a **molded thumb bump on the inner side**, plus a **cuff band** at the top with 2–3 stitch/seam lines.
    - **How to make it:** a **MeshPart** looks best.
      - **Option A:** the owner inserts a free blocky boxing-glove mesh from the Toolbox (search "blocky boxing gloves"). Claude Code then recolors, resizes and welds it for every tier, with a left and a right version.
      - **Option B:** if there's no good mesh, Claude Code builds it from parts: a main block with `SpecialMesh`/bevel or rounded Union, a padded front, a thumb wedge and a cuff block. It must still read as a padded glove, not a plain box.
    - **Tier looks (like the references):** basic gloves are a plain color with a darker cuff. Mid tiers get trims, stripes or spikes, and some get **chains wrapped around the cuff**. Top tiers get **an energy aura on the gloves**: small crackling sparks or lightning (e.g. purple for Void, rainbow for Infinity), kept small so it doesn't hide the avatar.
    - Welded to the hand/lower arm, it moves with every punch, with no gap and nothing hanging below. It works on R15 and R6.
- **Glove Shop stand (owner, 2026-10-13, from a reference picture of a "Pickaxe Shop" market stall):**
  - **No ProximityPrompt.** A glowing **blue circle pad** on the ground in front of the stall is a touch sensor. Stepping into it opens the Glove Shop window, and stepping out (or the X) closes it. A 1 s cooldown stops it reopening right after closing while still standing in it.
  - **Our own design (not a copy):** a chunky low-poly boxing-themed stall.
    - **Awning:** red-and-white striped, scalloped edge.
    - **Counter:** dark wood, with a pair of giant red boxing gloves hanging from the front beam on a rope and slowly swinging.
    - **Display:** 3–4 of the real gloves on hooks/stands on the counter, slowly spinning.
    - **Pad:** a cyan glowing ring with a soft pulse and rising sparkles.
    - **Title:** "Glove Shop" floating above in big rounded white text with a blue gradient and a thick dark outline (same style as the reference).
  - It sits by the training area, visible from spawn.
  - **Pad look (owner, 2026-10-13, from a "SELL" stall reference):** **Built 2026-10-13** (both stands; yellow for Invite Friend).
    - **Shape:** a **big flat circle** on the ground, about 1.5× the stall's width, so the stall stands at its back edge and the player walks into it from the front.
    - **Edge:** a **thick glowing neon ring**, about 0.8 stud wide, bright cyan, with a soft glow bleeding outward.
    - **Inside:** **see-through** with a light cyan tint (about 80% transparent), so the ground shows through.
    - **How:** a thin flat `Cylinder` (or a flat part with a `SurfaceGui`) for the tinted fill, plus the ring as a glowing circle-outline image (`ImageLabel`, `LightInfluence` 0, high `Brightness`) or a Neon ring mesh. It sits just above the ground so it never flickers.
    - **Movement:** a slow gentle pulse of the ring's brightness. When a player stands in it, it gets a bit brighter.
    - The whole circle is the touch sensor (as above).

## 4. Bed Mastery (a reason to re-break beds)
- Each bed has **3 mastery stars**: break it 10 / 50 / 200 times.
- Each star = **+5% Cash forever** from that bed, plus a one-time Cash reward. The stars show on the bed's sign and in an **Index** menu (all beds, stars, best time).
- "Master all 25 beds" is a long goal with a special title and aura reward.

## 5. World 2 (next week's update)
- A second path of 15 beds past the Infinity Bed (a Halloween/haunted theme while October lasts, e.g. Coffin Bed, Haunted Bed, Pumpkin Bed…), unlocked at **Rebirth 1**.
- It comes with 6 new posts and gloves. Announce it with a group shout and a new code.

## 6. Undiscovered beds are black (owner, 2026-10-13)
**Built 2026-10-13**, see [[Break A Bed/2026-10-13|2026-10-13]].
Beds you haven't broken yet are **black silhouettes**, so you want to keep playing to find out what they look like.
- **Look:** every part of an undiscovered bed turns near-black (`#0E0E14`, SmoothPlastic). Textures and decals are hidden, and its glow, sparkles and particles are off. A faint dark-purple `Highlight` outline makes it look mysterious, not broken.
- **Name:** the sign and prompt show **"???"** instead of the name. The Strength needed still shows ("??? · Need 1M Strength"). The next-bed pill says "Next: ???" and the Index shows "???" too.
- **Discover moment:** the first time you break a bed, the black shell **cracks off**. Black shards fly out, then a white flash and the real colors fade in over 0.5 s, with a "NEW BED DISCOVERED!" banner, its name in big text and a reveal sound. Then the normal break effects play.
- **Per player:** it's done on each player's own screen (client-side), so everyone sees their own progress. The server sends the list of discovered beds.
- **Saved forever:** a separate `DiscoveredBeds` list that **isn't reset by Rebirth**, so beds stay revealed after rebirthing. Old saves: every completed bed counts as discovered.
- The first bed (Cardboard) is always revealed, so the tutorial target is clear.
- The bed path's colored tiles and the COMPLETED signs stay as they are.
- **Training posts too (owner, 2026-10-13):** posts you don't own yet are black silhouettes in the same style. Their pad glow is grey and the name sign says "???", but the **price still shows** ("??? · $1.2K") so players know what to save for. The Straw Post (the first, free one) is always revealed.
  - **On buying:** the black shell cracks off with the same reveal (shards, white flash, colors fade in over 0.5 s, "NEW POST UNLOCKED!" banner with the name and its "+X 💪 per punch").
  - **Saved:** a `DiscoveredPosts` list that Rebirth doesn't reset (owned posts count as discovered in old saves). After a rebirth, a discovered but not-yet-rebought post shows in full color with its lock and price.
  - The same applies to the new unique post models from section 1.

## 7. Invite Friend stand (owner, 2026-10-13, from a reference picture)
**Built 2026-10-13**, see [[Break A Bed/2026-10-13|2026-10-13]].
- **A figure** (an R15 rig wearing a cash/money outfit, with a cheerful idle and a wave every few seconds) stands on a **glowing yellow ring pad** near spawn. Cash bills and dumbbell icons float and swirl around them.
- **Above it**, a floating title "**INVITE FRIEND**" in big yellow text with a thick dark outline and a 👥 icon on each side, and a green line under it: "**Each Friend = +10% Strength**".
- **Stepping on the yellow ring** (a touch sensor, no prompt) opens Roblox's invite window (`SocialService:PromptGameInvite`), with a 5 s cooldown.
- **The bonus:** +10% Strength for each friend in the same server, max +30%. It shows as a small chip on the HUD ("Friends +20%"). This is item 3 of "Next retention features" in [[Break A Bed/Retention Plan|Retention Plan]].

- **Fix (owner, 2026-10-13):** **Built 2026-10-13** (rongstrix's avatar, userId 1834504124). the first build had no figure, just dumbbells and cash bills stacked in a column. Now:
  - **The figure is the Roblox avatar of the user "rongstrix".** On the server, use `Players:GetUserIdFromNameAsync("rongstrix")` and then `Players:CreateHumanoidModelFromUserId(id)`. Wrap both in pcall with a retry, and save the userId as a constant once found so the name lookup isn't needed every server.
    - The figure stands in the middle of the yellow ring facing spawn. Its HumanoidRootPart is anchored, its name tag is hidden, and it can't be pushed.
    - It plays an idle animation, and a wave every ~6 s (a looping `Animator` animation, or the default "wave" emote).
    - If loading fails, it falls back to a plain R15 rig, so the stand never looks empty.
  - **Cash and dumbbells** orbit the figure in a loose ring at different heights (6–8 items, small, slowly circling and bobbing). They aren't stacked in a column, and they never cover the figure's face.

## Pacing targets (check after building)
- First 10 minutes: unchanged (new thing every 45–75 s).
- Beds 10–15: about 3–5 min each.
- Beds 16–25: about 6–10 min each, with gloves and posts filling the gaps.
- First rebirth: about 60–90 min in.
- Claude Code measures this with a fresh-save test bot and writes the real times here.

**Real times (test bot, fresh save, 2026-10-13):** a scripted player that trains, breaks each new bed with To Bed, re-breaks its best bed for Cash, and buys posts and gloves as soon as it can.

| | Time | Gap | | Time | Gap |
|---|---|---|---|---|---|
| Bed 5 | 3:25 | | Bed 16 | 31:31 | 6.9 min |
| Bed 10 | 5:03 | | Bed 17 | 36:11 | 4.7 min |
| Bed 11 | 6:25 | 1.4 min | Bed 18 | 43:27 | 7.3 min |
| Bed 12 | 11:11 | 4.8 min | Bed 19 | 45:33 | 2.1 min |
| Bed 13 | 16:12 | 5.0 min | **Bed 20** | **1:17:52** | **32.3 min** |
| Bed 14 | 18:48 | 2.6 min | Bed 21 | 1:26:09 | 8.3 min |
| Bed 15 | 24:39 | 5.9 min | | | |

- First 10 minutes: the bot reached bed 10 at 5:03 (the model: 6:22). It was a bit faster than before thanks to the Starter Quest rewards; the minutes 2–10 pacing is unchanged.
- Beds 11–15: 1.4–5.9 min each (target 3–5). Beds 16–19: 2.1–7.3 min.
- **Bed 20 is a wall (32 min).** To fix next: lower bed 20's need or the price of posts 13–14, then re-run.
- Gloves and posts filled the gaps (gloves 1–11 and posts 7–14 came between beds).
- The run was stopped at bed 21 (1:26) for other work, so the first rebirth time (target 60–90 min) is **not measured yet**. The model says about 1 h 45 to bed 25 before the bed 20 fix.
- Rebirth costs (real): 450M, 1.35B, 4.05B, 12.2B, 36.5B Strength (×3 each). Second run from the model: about 27 min to 1.35B.

## Build order
1. Unique posts + Gloves + the late-game pacing retune (one update).
2. Rebirths + the token shop (next).
3. Bed Mastery + Index.
4. World 2 (weekly update).
