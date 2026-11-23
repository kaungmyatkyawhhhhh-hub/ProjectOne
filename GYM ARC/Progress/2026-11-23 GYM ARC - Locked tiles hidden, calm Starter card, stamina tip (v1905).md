# GYM ARC - Locked tiles hidden, calm Starter card, stamina tip (v1905, 23 Nov 2026)

Owner: "ok change", about the 3 items left open in [[2026-11-23 GYM ARC - Unlikeable things sweep + lighter training screen (v1903)]].
Saved as **v1905, NOT published**. New-player phone test: 0 errors.

1. **Locked menu tiles are hidden** (`SideMenu.HideLocked = true`).
   - They used to show dimmed with a padlock.
   - A tile now appears, with its pop, when it unlocks.
   - After Growth Spurt 1 the left menu shows 4 tiles (Shop, Stats, Muscles, Poses) instead of 9.
   - This replaces prompt 39's "never hidden" (owner's newer call).
2. **Calm Starter / Premium side card** (fair-money pass):
   - The sub line is "New player deal" instead of "Worth R$ 199".
   - The button reads "R$ 29" instead of "Only R$ 29".
   - No ticking countdown pill (`STICKY_COUNTDOWN = false` in StarterPackClient brings it back).
   - The WORTH line stays inside the offer window, where the contents are listed (owner, 1 Nov).
3. **Out-of-stamina tip:**
   - On a machine, it's now a short line in the top band that goes by itself, instead of the Dex box with "Tap to continue" covering the lifter.
   - The gold path + TREADMILL marker still show.
   - Off a machine, Dex says it and the box closes by itself after 5 s.

## Still open
- Your own trainer fades to see-through when it stands between the camera and you (TrainerCameraFade). It can look like a yellow ghost next to you; it's by design.
