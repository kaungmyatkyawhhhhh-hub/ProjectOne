---
tags: [mega-bite, build-log, ui, slots, fossilize, evolution]
date: 2026-11-24
---
# 2026-11-24 MEGA BITE - Title screen, slots, Evolutions window, fossil sharks

From Zev's list (relayed by the owner 24 Nov 05:52). Research: [[2026-11-24 Research - Ant Evolution (evolution + rebirth system) and Deepwoken-style slots]].
Zev makes the models and the world map, so none were touched here.

- **Testing:** in Studio Play, 0 script errors.
- **Not published. Not saved this time.** The roblox-ui-pro rule says no saving without the owner's OK. This is Team Create, so the edits stay in the session; the owner saves and publishes.
- **Backups:** in ServerStorage, `*_preSlots_24Nov` copies of GameConfig, MB_Data, MB_SwimServer, MB_FishServer, MB_HUD and ClientBus.

## 1. Title screen (`StarterPlayerScripts.MB_Title`, new)
- **Look:**
  - a slow orbiting camera over the spawn reef, with a dark gradient on the left;
  - the "MEGA BITE" title in the v6 title style, with "EAT · GROW · EVOLVE" in gold;
  - a big lime **PLAY** button, which plays your last slot in one tap;
  - a slot line ("SLOT 1 · LEVIATHAN"), and a blue **SLOTS** button.
- **Behaviour:**
  - All other screens are hidden while it is up.
  - Nothing spawns until you pick. On PLAY it waits for your shark, hands the camera back to MB_Swim, restores the HUD and fades out.
- **Studio test hooks:** player attribute `TitleTest` = `slots` / `close` / `select:2` / `play:1`. Workspace attribute `MB_NoTitle = true` skips the menu by picking the last slot.

## 2. Save slots (`ServerStorage.MB_Data`, `GameConfig.C.Slots`, RemoteFunction `Remotes.Slots`)
- **What a slot holds:**
  - 3 slots per account. Each slot is its own shark: evolution, EXP, fossil, Index, quests, cards, landmarks and chests.
  - **Shared across slots** (`C.Slots.Account`): Settings, Codes, Streak/StreakDay, PlayDay/PlaySecs/PlayGot, DailyDay/Daily, BoostUntil, and owned Skins.
- **The record:**
  - Account fields sit at the top level, with `Slots["1".."3"]` and `ActiveSlot`.
  - The picked slot is **mirrored to the top level** on every save, so an older server build still loads the shark played last.
- **Migration:** an old save becomes Slot 1 on its first load. A one-time copy of the old record is kept under `bak_slots_u_<id>`.
- **Remote ops:**
  - `list`: slot summaries for the cards.
  - `pick n`: once per visit (Deepwoken style; to change slots you rejoin).
  - `delete n`: only before picking. The client makes you **hold DELETE for 1.5 s**.
- **Bug found and fixed during the test:**
  - A first session that left without picking saved an empty `Slots` table over the in-memory migration, so the owner's Slot 1 showed as NEW SHARK.
  - Nothing was lost (the top-level fields and the backup were intact).
  - Fixes: Save now merges every slot the session knows, and an empty `Slots` with an old shark at the top level migrates again. Slot 1 came back as the Leviathan.
- **Slot cards:** each card shows the real 3D shark, the stage n/10, FOSSIL n, EXP and last played; an empty slot reads "+ NEW SHARK, start as a Yellow Fish". The selected card is gold.

## 3. Evolutions window (`StarterPlayerScripts.MB_Evolutions`, new) = Ant's EVOLUTIONS
- A v6 slab with the title "Evolutions", a STAGE n / top chip, and K.Tabs **SHARKS** | **FOSSILIZE**. It opens with `Bus.EvolutionsOpen:Fire("ladder"|"fossil")`.
- **SHARKS ladder:**
  - Rows show a number circle, a round portrait of the **real 3D shark** (a dark silhouette with "?" until reached), the name ("???" beyond the next one), and chips for size, speed and the ability with its icon.
  - Status pills:
    - ✓ REACHED in lime;
    - **YOU** in gold, with a bar inside the row ("FOSSIL 746.4K / 840K" at your top shark);
    - the EXP needed in grey ("next!" / "evolve to find out");
    - **FOSSIL II** in purple ("Fossilize to unlock").
  - The fossil sharks sit under their own "FOSSIL SHARKS" header (Ant's "REBIRTH ANTS").
  - It scrolls to your row on open, and the meshes are preloaded.
- **FOSSILIZE tab** (Ant's rebirth panel):
  - a purple banner with a gold tooth medal, **x1 » x2** and "EXP FOREVER";
  - reward chips: NEW SHARK: DUNKLEOSTEUS (or "... STAYS YOURS" for an old save already past it), the FOSSIL I badge, and every fish giving x2 EXP;
  - ✓ YOU KEEP / RESETS boxes;
  - "REACH THE MEGALODON AND FILL ITS BAR" with a gold bar;
  - the button: NOT READY YET (grey), then FOSSILIZE x2 (lime), then **TAP AGAIN!** (gold, 3 s), then the server.

## 4. Fossil sharks (GameConfig `C.Fossil`, MB_FishServer, MB_SwimServer)
- **Unlocks:** `Gate = true`, `UnlockAt = {Dunkleosteus = 1, Mosasaurus = 2, Leviathan = 3}`. Fossil 0 tops out at the Megalodon.
- **New helpers:** `C.Fossil.TopFor(tier)`, `C.Fossil.Need(top)` (the next shark's EXP threshold, or `LastBar` 840K for the Leviathan), and `C.Fossil.State(evo, tier, exp)`.
- **Evolving:** `evolveCheck` never goes past the top shark (old saves keep what they reached). `growCheck` treats the top shark like the last one, growing by bites.
- **Fossilize:** the server now needs the top shark **and** a full bar (it was "any Megalodon").
- **Tested:**
  - Slot 2: EXP 99K → Megalodon; 150K → still Megalodon (gated).
  - Fossilize → Yellow Fish, FOSSIL I, "NEW SHARK: DUNKLEOSTEUS · EXP x2 forever".
  - EXP 250K → Dunkleosteus and it stops (Mosasaurus is Fossil II).
  - The test slot was deleted afterwards.

## 5. HUD (`MB_HUD`)
- **EVOLVE square** (purple) next to Shop. Its icon is your own shark, live in 3D, and it updates when you evolve.
- **FOSSILIZE pill:**
  - shows at your top shark;
  - reads **FOSSIL 77%** until the bar is full, then **FOSSILIZE!**, with a "FOSSIL BAR FULL!" key toast once;
  - opens the Fossilize tab (the old confirm stays as a fallback).
- The Fossilized celebration now names the new shark.

## Open / for the owner and Zev
- Slot 3 and above as a Robux product (Deepwoken / Slayers sell slots) was **not** added.
- A MAIN MENU button to switch slots without rejoining was not added.
- The Ant mechanics listed in the research note's "Not taken yet" list need a call.
- Phone check: only the slot panel was emulated at 844×390 (it fits). The Evolutions window wasn't checked on a real device.
