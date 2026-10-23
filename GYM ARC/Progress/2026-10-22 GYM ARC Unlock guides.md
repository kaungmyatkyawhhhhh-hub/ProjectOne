---
date: 2026-10-22
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Unlock guides (prompt 39)

Prompt: [[2026-10-22 GYM ARC Prompt - 39 Unlock guides]]. Feature note (how it works, the config): [[GYM ARC - Unlock Guides]].

## Done
- **Locked menu tiles** (section 5): all 8 tiles always show; locked ones are dimmed with a gold padlock; a tap shakes it and says when it opens + a teaser ("LOCKED · Unlocks at Growth Spurt 2 / Real coaches who train you while you train. Some are legendary..."). When a feature opens: the padlock pops, a gold NEW tag + glow until tapped once.
- **Unlock guides** (sections 1-4): the tutorial's Coach Dex box (same look) + a gold glow and arrow on the new button (screen dims a little), or for a place the gold path + named gold marker + a teleporting GO TO button. +25 coins for a first-time guide (server checked), SKIP pill, 40 s timeout, one at a time with 30 / 60 s gaps, never while busy. Once per player; existing players get none for what they already have. Settings "Show Tips". Analytics per guide and per locked tap.
- Every line is in `Config/Guides`.

## Tested (Studio, 844x390, temporary saves)
- New player: 6 tiles locked, Stats / Muscles open; the Trainers lock toast.
- Growth Spurt ready: READY TO GROW first, then (after "Later" and closing the daily window) the guide "You can GROWTH SPURT!" with the gold glow on TAP TO GROW; it timed out after 40 s as it should.
- After Growth Spurt 1: Shop, Poses, Crew, Inventory, Genetics open with NEW tags; Trainers still locked.
- World guide: "The BEACH GYM is open!" -> GO TO BEACH GYM -> teleported there, guide done, +25 coins, "+25 Coach Dex's reward".
- UI guide: "The SHOP is open" -> gold glow on SHOP, screen dimmed -> tapped it -> Store opened, guide done, +25.
- Fixed while testing: the pointer sat one top-bar height too high; the arrow covered the next tile (now outside the menu).

![[GYM ARC/Screenshots/guides39/locked_tiles_new_player.jpg]]
![[GYM ARC/Screenshots/guides39/locked_trainers_toast.jpg]]
![[GYM ARC/Screenshots/guides39/guide_spurt_ready_dialog.jpg]]
![[GYM ARC/Screenshots/guides39/world_guide_beach_dialog.jpg]]
![[GYM ARC/Screenshots/guides39/world_guide_beach_go_to.jpg]]
![[GYM ARC/Screenshots/guides39/world_guide_beach_arrived_reward.jpg]]
![[GYM ARC/Screenshots/guides39/ui_guide_shop_pointer.jpg]] (before the arrow moved off the Stats tile)
![[GYM ARC/Screenshots/guides39/ui_guide_shop_done_reward.jpg]]

## Not done / not tested
- Locked tabs inside menus (e.g. Alters before 7'0") with padlock + teaser: not done yet.
- Not tested: Growth Spurt 2 (Pro Gym, trainers, agency, arm wrestling guides), a 7'0" save's first alter, a real phone, an existing player's first join after the update (their open features should count as seen).
- Once in the test, TAP TO GROW didn't respond to one tap (the server grew fine when asked); couldn't reproduce. Worth a look on a phone.

## Follow-up (owner, [[2026-10-22 GYM ARC Prompt - 39b Unlock guides follow-up]]) - done
- **Tiles in the earlier style** (left_nav_badges.png): graphite with a faint hex mesh (a new image, Downloads\gym_arc_ui_hex), a thin gold inner outline, a thick dark bottom edge, GOLD line icons, chunky white labels with a dark stroke. STATS = dumbbell, MUSCLES = flexed arm, POSES = the flexing stick figure (was STATS').
- **Locked:** darker, grey outline, a GREY padlock in place of the icon, grey label. **One badge** inside the top-right corner: LOCKED > the small gold NEW tag > the red "!" chip (gentle pulse; it replaces the old red dot).
- **Locked tabs:** all tabs there from the start. Inventory ITEMS / GEAR / AURAS / LOOKS (AURAS is its own tab now; LOOKS has ALTERS / TITLES, the ALL chip is gone), Physique MUSCLES / LIFTS / GENES. Locked = padlock + dimmed, a tap shakes it and shows the teaser ("LOCKED · Unlocks at Growth Spurt 2 / Belts, wraps and straps..."); never an empty page; a menu opens on its first open tab. The Store's 4 tabs have no unlock condition, so none is locked.
- Teaser lines rewritten in the owner's tone (no "legendary", no "...").
- **Fixed while testing:** the first-alter guide started under the BODY ALTER READY popup (it waits now); an offer card and a guide could show together (never now); the Trainer Agency teleport put the player behind the desk at the wall (now the room side).

## Tested (844x390, temporary saves)
- Growth Spurt 1 save: tiles with NEW tags, TRAINERS locked; Inventory GEAR / AURAS locked, GEAR tap = teaser with "0% there", LOOKS opens on TITLES (ALTERS locked).
- **Existing player** (Studio hook TestExisting, Growth Spurt 1, tutorial done): **no guides, no NEW tags**, only TRAINERS locked; 13 guides marked seen at join.
- **Growth Spurt 2:** the short "next Growth Spurt is ready" reminder (no reward), a real tap on TAP TO GROW worked; then PRO GYM (teleported, +25), TRAINERS (tile glow + arrow; it unlocked with NEW), TRAINER AGENCY (fixed teleport), ARM WRESTLING (teleported, +25), one after another.
- **7'0" save, first alter:** BODY ALTER READY popup first, then the guide "You've hit 7'0"..."; every tile and tab open; LOOKS opens on ALTERS.

![[GYM ARC/Screenshots/guides39b/tiles_new_locked.jpg]]
![[GYM ARC/Screenshots/guides39b/inventory_locked_tabs.jpg]]
![[GYM ARC/Screenshots/guides39b/inventory_gear_locked_toast.jpg]]
![[GYM ARC/Screenshots/guides39b/looks_alters_locked_opens_titles.jpg]]
![[GYM ARC/Screenshots/guides39b/existing_player_no_guides.jpg]]
![[GYM ARC/Screenshots/guides39b/spurt2_ready_reminder.jpg]]
![[GYM ARC/Screenshots/guides39b/pro_gym_guide.jpg]]
![[GYM ARC/Screenshots/guides39b/pro_gym_arrived_reward.jpg]]
![[GYM ARC/Screenshots/guides39b/trainers_tile_guide.jpg]]
![[GYM ARC/Screenshots/guides39b/arm_wrestling_go_to.jpg]]
![[GYM ARC/Screenshots/guides39b/arm_wrestling_arrived.jpg]]
![[GYM ARC/Screenshots/guides39b/agency_teleport_fixed.jpg]]
![[GYM ARC/Screenshots/guides39b/first_alter_guide.jpg]]
![[GYM ARC/Screenshots/guides39b/looks_alters_open_at_7ft.jpg]]
