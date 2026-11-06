---
date: 2026-11-06
tags: [galaxy, progress, phase-3]
status: built and tested in Studio; NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - Phase 3.1: the BLACK HOLE (6 Nov, Claude Code)

Step 3.1 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]].

Design: [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]] §1 + §4.

Checklist rows: **#26 #58 #258 #299 #417**.

## What it is
- **Opens:** at **100K shards earned since the last Black Hole** (EconConfig.BlackHole).
- **Pays:** **Dark Matter = floor(sqrt(those shards / 1,000))**. 100K = 10 DM. Each DM = **+25% shards**, for good.
- **Resets:**
  - stardust + bodies
  - ring 1, shards
  - ring 2 + the capstone (its **AUTOMATION branch stays**)
  - the **Supernova climb**
- **Keeps:**
  - your Supernova count + rank
  - Cosmic Level + perks
  - pads, Ignition
  - the Forge + Essence
  - Dark Matter

**Why the climb resets** (my decision, flagged):
- The Supernova costs and shard growth were counted on your total Supernovas.
- If they kept going after a Black Hole, the next Supernova would cost what Supernova 30 costs, with ring 2 gone. Nobody could make it.
- So they now count the **Supernovas since the last Black Hole** (new `NovaRun`). Your total still shows everywhere (rank, leaderboard, quests).
- Dark Matter is what makes the second climb faster.

**AUTO-SUPERNOVA (#417):**
- Opens at Black Hole 1, an ON/OFF in the window (off until you turn it on).
- When on, the server goes Supernova by itself as soon as it's ready. The world sees the burst; you get "AUTO SUPERNOVA +n SHARDS" and your rank lands.

**Old saves:** save version 4 → 5. Your old Supernovas become the climb, and **every shard ever earned counts toward Black Hole 1**.
- Your test save had 586K, so it's ready with **24 Dark Matter**.

## The window (BLACK HOLE)
- **Opens from:**
  - your island's BLACK HOLE board: it opens at Ignition 1 and its beacon lights when you can collapse
  - the plaza's Black Hole gate (a new "Open BLACK HOLE" prompt; its sign now says 100K SHARDS)
- **Shows:**
  - your Dark Matter and shard multiplier, and Black Holes done
  - a bar of shards since the last one / 100K
  - what the next one pays (and the new multiplier)
  - RESETS / STAYS lists
  - **COLLAPSE** (a 2nd tap confirms, because it resets a lot)
  - AUTO-SUPERNOVA
- **Kit:** Kit.window, panel, buttons, our black_hole_swirl as its icon.
- **Screens** (`Progress/screens/2026-11-06-blackhole/`):
  - `pc-window-old-save-ready-24dm`
  - `pc-window-ready-10dm`
  - `phone-window-not-yet`

## The WOAH moment (#299 #258)
- The camera goes to the plaza's gate and slowly pushes in. The world dims and the music fades out.
- **The hole:** VfxLibrary.BlackHole opens at the gate, x1.4: swirl, portal, stardust pulled in, violet smoke. The words are EVERYTHING / FALLS / IN.
- **Sound:** a low suck (the riser pitched down to 0.55), then the held silence, then the **dark pulse** (the boom an octave down) with two dark rings.
- The climax title is "BLACK HOLE 1 · +10 DARK MATTER". The Dark Matter is given **on the pulse** (#318), and SKIP works after 1 s.
- Everyone in the server gets a chat line + a banner.
- **Screens:** `pc-moment-1-pull-in`, `pc-moment-2-climax`.

## Tests (Studio)
- **Migration (v4 test save → v5):** ShardsHole 586K, BlackHoleReady, gain 24.
- **Fresh save + 100K shards, COLLAPSE ×2 (the real button):** 10 DM, Black Holes 1, climb 0, shards 0, ring 2 empty. Kept: Supernovas 12, pads 20, Ignition 1, level 19, Essence.
- **AUTO-SUPERNOVA:** turned on, then +2M stardust gave Supernova 13 by itself: 136 shards with x3.5 Dark Matter (matches the formula).
- **First try:** the camera looked down from behind the gate (it used the ring's axis). Fixed to stand on the plaza side.
- Vault = Studio (41 scripts); test switches cleared.

## Not done / flags
1. **When a real player reaches Black Hole 1:** the bot ends at 90 min with ~11K shards total, so 100K is a few hours in (design: ~2:00). Not measured; the Phase 3 report's 0-4 h bot will show it.
2. **The Pulsar tier (Black Hole 1)** is in 3.4, and **ring 3** in 3.2: not part of this step.
3. **No dedicated Black Hole sound files:** made from the existing riser + boom, pitched down. A proper "reverse Supernova" stinger is still needed (#258 PARTLY).
4. **Phone:** the RESETS / STAYS lines are small (~11 px).
