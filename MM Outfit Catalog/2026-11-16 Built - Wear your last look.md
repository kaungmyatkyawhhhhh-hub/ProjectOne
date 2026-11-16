---
tags: [mm-outfit-catalog, build-log]
created: 2026-11-16
plan: "[[2026-11-16 CAC lessons - MM build list]]"
---
# Built: "Wear your last look?" on rejoin (build list item 4)

- **Not saved or published by Claude.** File > Save, then publish, is the owner's step.
- **Backup:** `ServerStorage.ScriptBackups.pre_LastLook_16Nov` (OutfitShowcaseServer, ShowroomCollection).

## What it does
- If you left the game wearing a whole MM outfit, the next time you join a small card appears at the bottom centre after the loading screen.
- The card reads **"Wear your last look? Sakura · ID 03"** with **Wear it** / **No thanks**.
- It goes away on its own after 20 s.
- **Opt-in, never forced:** nothing changes unless you tap Wear it. CAC auto-equips; we ask.
- **Wear it** uses the normal whole-outfit Try, so Undo / My avatar / Buy outfit and the worn-by count all work as usual.

## How (`OutfitShowcaseServer`)
- **`state.pureLook`:**
  - Set by a whole-outfit Try.
  - Cleared by a single-piece try, Undo, My avatar and respawn.
- **Saving:** the profile save (`MMShowroomProfiles_v1`) writes it as `lastLook` every time it saves, including when the player leaves.
  - Leaving in your own avatar saves nothing, so there's no offer next time.
- **Offering:** on join, once the profile loads, the server sets the player attribute `MMLastLook`, but only if that outfit still exists.
- **Client (`ShowroomCollection`):**
  - Waits for that attribute and for the loading screen to finish.
  - Skips the card if you're already trying something on.
- **Known limit:** an Undo back to a whole outfit isn't remembered. Marked `shortcut:` in the code.

## Tested (Studio Play; the offer was simulated by setting `MMLastLook`, since Studio doesn't load profiles)
- The card appears about 7 s after join, once the loading screen is gone.
- **Wear it** (real click): Sakura went on, and the Undo · My avatar · Buy outfit bar appeared.
- **No thanks** (real click): the card closed and the avatar was unchanged.
- **On phone (A06):** the card first covered the top dock, so it was moved to the bottom centre, clear of the dock, thumbstick and jump button.
- 0 console errors.

![[Screenshots/2026-11-16 last look offer (phone A06).jpg]]
![[Screenshots/2026-11-16 last look - after Wear it (PC).jpg]]

## Not tested
- The real save → rejoin loop. It needs the published game, because Studio never writes or reads profiles.
